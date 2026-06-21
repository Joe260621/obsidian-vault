import sys, re, html
content = sys.stdin.read()
# Try to find result links in sogou
# Search for result blocks with titles
results = re.findall(r'<a[^>]*id="sogou_vr_[^"]*title_\d+"[^>]*href="(https?://[^"]+)"[^>]*class="[^"]*link__saLink[^"]*"[^>]*>', content)
print(f"Found {len(results)} result links")
for i, url in enumerate(results[:10]):
    print(f"{i+1}. {url}")
