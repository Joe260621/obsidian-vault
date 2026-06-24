// Codex Responses API → DeepSeek Chat Completions API proxy
// Run: node --env-file=.env codex-deepseek-proxy.mjs

import http from "node:http";

const PORT = parseInt(process.env.PROXY_PORT || "4000", 10);
const DEEPSEEK_BASE = process.env.DEEPSEEK_BASE_URL || "https://api.deepseek.com/v1";
const DEEPSEEK_KEY = process.env.DEEPSEEK_API_KEY;
const PROXY_ACCESS_KEY = process.env.PROXY_ACCESS_KEY || DEEPSEEK_KEY;

if (!DEEPSEEK_KEY) {
  console.error("DEEPSEEK_API_KEY is required");
  process.exit(1);
}

function chatToResponse(chatResp, originalModel) {
  const choice = chatResp.choices?.[0] ?? {};
  const message = choice.message ?? {};

  const output = [];
  if (message.content) {
    output.push({
      type: "message",
      role: "assistant",
      content: [{ type: "output_text", text: message.content }],
    });
  }
  if (message.tool_calls?.length) {
    for (const tc of message.tool_calls) {
      output.push({
        type: "function_call",
        call_id: tc.id,
        name: tc.function.name,
        arguments: tc.function.arguments,
      });
    }
  }

  return {
    id: chatResp.id,
    object: "response",
    created_at: chatResp.created,
    status: "completed",
    model: originalModel,
    output,
    usage: chatResp.usage,
  };
}

function chatToStreamChunk(chunk) {
  const choice = chunk.choices?.[0];
  if (!choice) return null;
  const delta = choice.delta ?? {};
  const events = [];

  if (delta.content !== undefined && delta.content !== null) {
    events.push({
      type: "response.output_text.delta",
      delta: delta.content,
      content_index: 0,
      output_index: 0,
    });
  }
  if (delta.tool_calls?.length) {
    for (const tc of delta.tool_calls) {
      if (tc.function?.name) {
        events.push({
          type: "response.function_call.name",
          call_id: tc.id ?? tc.index,
          name: tc.function.name,
        });
      }
      if (tc.function?.arguments) {
        events.push({
          type: "response.function_call.arguments.delta",
          call_id: tc.id ?? tc.index,
          delta: tc.function.arguments,
        });
      }
    }
  }
  if (choice.finish_reason) {
    events.push({ type: "response.completed", finish_reason: choice.finish_reason });
  }
  return events;
}

function buildChatRequest(body) {
  const chatBody = {
    model: body.model || "deepseek-chat",
    messages: [],
    stream: body.stream || false,
  };

  if (body.max_output_tokens) chatBody.max_tokens = body.max_output_tokens;
  if (body.temperature != null) chatBody.temperature = body.temperature;
  if (body.top_p != null) chatBody.top_p = body.top_p;

  // Always add system message for tool-aware behavior
  chatBody.messages.push({ role: "system", content: "You are a helpful coding assistant." });

  // Map input to messages
  if (body.input) {
    const input = Array.isArray(body.input) ? body.input : [body.input];
    for (const item of input) {
      if (item.type === "message" || item.role) {
        let role = item.role; if (role === "developer") role = "system"; const msg = { role, content: item.content };
        if (typeof msg.content === "string") {
          // pass through
        } else if (Array.isArray(msg.content)) {
          msg.content = msg.content.map((c) => c.text || c.content || "").join("");
        }
        chatBody.messages.push(msg);
      } else if (item.type === "function_call_output") {
        chatBody.messages.push({
          role: "tool",
          tool_call_id: item.call_id,
          content: item.output,
        });
      }
    }
  }

  // Map tools — defensive: handle both flat {name} and nested {function:{name}} formats
  if (body.tools?.length) {
    chatBody.tools = body.tools
      .filter((t) => {
        const name = t.name || t.function?.name;
        if (!name) { console.log(`  skip tool: missing name (type=${t.type})`); return false; }
        if (t.type && t.type !== "function") { console.log(`  skip tool: ${name} (type=${t.type})`); return false; }
        return true;
      })
      .map((t) => ({
        type: "function",
        function: {
          name: t.name || t.function?.name || "unknown",
          description: t.description || t.function?.description || "",
          parameters: t.parameters || t.function?.parameters || {},
        },
      }));
  }

  // For stream, add stream_options
  if (chatBody.stream) {
    chatBody.stream_options = { include_usage: true };
  }

  return chatBody;
}

async function proxyRequest(req, res) {
  const url = new URL(req.url, `http://localhost`);
  const isStream = Boolean(
    req.headers["x-stream"] || url.searchParams.get("stream") === "true"
  );

  const chunks = [];
  req.on("data", (c) => chunks.push(c));
  req.on("end", async () => {
    try {
      const raw = Buffer.concat(chunks).toString();
      let body = {};
      if (raw.trim()) body = JSON.parse(raw);

      body.stream = isStream;

      const chatReq = buildChatRequest(body);
      const apiPath = "/chat/completions";

      console.log(`→ POST ${apiPath}  model=${chatReq.model}  stream=${chatReq.stream}  tools=${chatReq.tools?.length ?? 0}`);
      console.log(`  req body keys: ${Object.keys(body).join(",")}`);
      console.log(`  raw: ${raw.slice(0,300)}`);

      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 300_000);

      const dsResp = await fetch(DEEPSEEK_BASE + apiPath, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${DEEPSEEK_KEY}`,
        },
        body: JSON.stringify(chatReq),
        signal: controller.signal,
      });
      clearTimeout(timeout);

      if (!dsResp.ok) {
        const errText = await dsResp.text();
        console.error(`DeepSeek error ${dsResp.status}: ${errText.slice(0, 500)}`);
        res.writeHead(dsResp.status, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ error: { message: errText } }));
        return;
      }

      if (chatReq.stream) {
        res.writeHead(200, {
          "Content-Type": "text/event-stream",
          "Cache-Control": "no-cache",
          Connection: "keep-alive",
        });

        let fullText = "";
        for await (const line of linesFrom(dsResp.body)) {
          const text = line.replace(/^data:\s*/, "").trim();
          if (!text || text === "[DONE]") {
            res.write(`data: ${text || "[DONE]"}\n\n`);
            continue;
          }
          try {
            const chunk = JSON.parse(text);
            const events = chatToStreamChunk(chunk);
            if (events) {
              for (const ev of events) {
                if (ev.type === "response.output_text.delta") {
                  fullText += ev.delta;
                }
                res.write(`data: ${JSON.stringify(ev)}\n\n`);
              }
            }
          } catch {
            res.write(`data: ${text}\n\n`);
          }
        }
        console.log(`← stream done  chars=${fullText.length}`);
        res.end();
      } else {
        const dsJson = await dsResp.json();
        console.log(`← ${dsResp.status}  tokens=${JSON.stringify(dsJson.usage)}`);
        const codexResp = chatToResponse(dsJson, chatReq.model);
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify(codexResp));
      }
    } catch (err) {
      console.error("Proxy error:", err.message);
      res.writeHead(502, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ error: { message: err.message } }));
    }
  });
}

async function* linesFrom(stream) {
  const decoder = new TextDecoder();
  let buf = "";
  for await (const chunk of stream) {
    buf += decoder.decode(chunk, { stream: true });
    while (buf.includes("\n")) {
      const idx = buf.indexOf("\n");
      yield buf.slice(0, idx).replace(/\r$/, "");
      buf = buf.slice(idx + 1);
    }
  }
  if (buf.trim()) yield buf;
}

// Main server
const server = http.createServer((req, res) => {
  console.log(`> ${req.method} ${req.url}`);
  // Auth check
  const auth = req.headers.authorization || "";
  const expected = `Bearer ${PROXY_ACCESS_KEY}`;
  if (auth !== expected) {
    res.writeHead(401, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ error: { message: "unauthorized" } }));
    return;
  }

  if (req.method === "POST" && req.url.startsWith("/v1/responses")) {
    proxyRequest(req, res);
  } else if (req.url === "/v1/models" || req.url === "/models") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({
      object: "list",
      data: [
        { id: "deepseek-chat", object: "model" },
        { id: "deepseek-reasoner", object: "model" },
        { id: "deepseek-v4-flash", object: "model" },
        { id: "deepseek-v4-pro", object: "model" },
      ],
    }));
  } else if (req.url === "/health" || req.url === "/") {
    res.writeHead(200, { "Content-Type": "text/plain" });
    res.end("codex-deepseek-proxy OK");
  } else {
    console.log(`404: ${req.method} ${req.url}`);
    res.writeHead(404);
    res.end("not found");
  }
});

server.listen(PORT, "127.0.0.1", () => {
  console.log(`codex-deepseek-proxy → DeepSeek API at ${DEEPSEEK_BASE}`);
  console.log(`Listening on http://127.0.0.1:${PORT}/v1/responses`);
});
