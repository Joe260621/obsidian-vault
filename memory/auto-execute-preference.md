---
name: auto-execute-preference
description: User prefers direct execution without confirmation for non-destructive operations
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 01ba30f6-3357-49fc-9df6-0d3d22eae171
---

User wants me to execute directly without asking for confirmation during the process. Only ask when performing destructive/critical operations (deleting important files, etc.).

**Why:** User finds frequent permission prompts disruptive to workflow.

**How to apply:** For all non-destructive operations (install packages, start services, write configs, create files, PowerShell commands), just proceed without AskUserQuestion or permission prompts. Reserve confirmation for truly destructive actions (rm -rf, deleting project files, git destructive ops, etc.).
