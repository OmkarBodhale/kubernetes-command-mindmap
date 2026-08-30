#!/usr/bin/env bash
# Repository quality gate. Run from the repo root: ./scripts/verify.sh
# Checks documentation invariants; no cluster required except where noted.
set -uo pipefail

FAIL=0
pass() { printf '  ✅ %s\n' "$1"; }
fail() { printf '  ❌ %s\n' "$1"; FAIL=1; }
head2() { printf '\n\033[1m%s\033[0m\n' "$1"; }

head2 "1. Internal links resolve"
BROKEN=0
while IFS= read -r line; do
  file="${line%%:*}"; link="${line#*:}"
  target="$(dirname "$file")/${link%%#*}"
  [ -z "${link%%#*}" ] && continue
  if [ ! -e "$target" ]; then printf '     broken: %s -> %s\n' "$file" "$link"; BROKEN=$((BROKEN+1)); fi
done < <(grep -rhoE '\]\(([^)]+\.(md|yaml))(#[^)]*)?\)' --include='*.md' . \
         | sed 's/](\(.*\))/\1/' > /dev/null 2>&1; \
         grep -rnoE '\]\((\.\.?/[^)#]+\.(md|yaml))' --include='*.md' . \
         | sed -E 's/^([^:]+):[0-9]+:\]\((.*)$/\1:\2/')
[ "$BROKEN" -eq 0 ] && pass "all relative links point at existing files" || fail "$BROKEN broken link(s)"

head2 "2. Every markdown file has a navigation footer"
MISSING=0
for f in $(find . -name '*.md' -not -path './.git/*' -not -name 'CLAUDE.md'); do
  grep -q '<!-- NAV-FOOTER -->' "$f" || { printf '     missing: %s\n' "$f"; MISSING=$((MISSING+1)); }
done
[ "$MISSING" -eq 0 ] && pass "all files carry a NAV-FOOTER" || fail "$MISSING file(s) without a nav footer"

head2 "3. Mermaid blocks are balanced"
BAD=0
for f in $(find . -name '*.md' -not -path './.git/*' -not -name 'CLAUDE.md'); do
  t=$(grep -c '^```$' "$f" || true)
  a=$(grep -cE '^```[a-z]' "$f" || true)
  [ "$a" -ne "$t" ] && { printf '     unbalanced fences: %s (%s open, %s close)\n' "$f" "$a" "$t"; BAD=$((BAD+1)); }
done
[ "$BAD" -eq 0 ] && pass "code fences balanced in every file" || fail "$BAD file(s) with unbalanced fences"

head2 "4. Placeholder convention (<angle-brackets>)"
if grep -rnE '\$[A-Z_]{3,}_NAME|\bPOD_NAME\b|\bNAMESPACE_NAME\b' --include='*.md' --exclude='CLAUDE.md' . >/dev/null 2>&1; then
  fail "found non-angle-bracket placeholders"
  grep -rnE '\$[A-Z_]{3,}_NAME|\bPOD_NAME\b' --include='*.md' --exclude='CLAUDE.md' . | head -5
else
  pass "placeholders use <angle-bracket> form"
fi

head2 "5. No deprecated APIs recommended"
if sed 's/#.*//' examples/*.yaml | grep -q 'extensions/v1beta1'; then
  fail "extensions/v1beta1 found in a manifest"
else
  pass "no deprecated API versions in examples"
fi

head2 "6. Example manifests are valid YAML"
if command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' 2>/dev/null; then
  BADY=0
  for f in examples/*.yaml; do
    python3 -c "import yaml,sys; list(yaml.safe_load_all(open('$f')))" 2>/dev/null \
      || { printf '     invalid: %s\n' "$f"; BADY=$((BADY+1)); }
  done
  [ "$BADY" -eq 0 ] && pass "all example manifests parse" || fail "$BADY invalid manifest(s)"
else
  printf '  ⏭️  skipped (python3 + pyyaml not available)\n'
fi

head2 "7. Example manifests validate against the API (needs a cluster)"
if kubectl cluster-info >/dev/null 2>&1; then
  BADK=0
  for f in examples/*.yaml; do
    kubectl apply -f "$f" --dry-run=client >/dev/null 2>&1 \
      || { printf '     rejected: %s\n' "$f"; BADK=$((BADK+1)); }
  done
  [ "$BADK" -eq 0 ] && pass "all manifests accepted by kubectl --dry-run=client" || fail "$BADK rejected"
else
  printf '  ⏭️  skipped (no cluster reachable)\n'
fi

head2 "8. No image pinned to :latest in examples"
if sed 's/#.*//' examples/*.yaml | grep -qE 'image:.*:latest'; then
  fail ":latest tag found in an example"
else
  pass "all example images use pinned tags"
fi

head2 "9. Destructive commands carry a warning"
for f in cheatsheets/*.md; do
  if grep -qE '^\s*kubectl (delete namespace|drain |taint nodes)' "$f"; then
    grep -q 'Production Impact' "$f" \
      || fail "$f has a destructive command with no ⚠️ Production Impact callout"
  fi
done
pass "destructive-command warnings checked"

head2 "10. Heading anchors resolve"
if command -v python3 >/dev/null 2>&1; then
  python3 - <<'PYEOF'
import re,os,glob,sys
def slug(t):
    t=re.sub(r'`','',t).lower()
    t=re.sub(r'[^\w\s-]','',t)
    return re.sub(r'\s','-',t.strip('\n'))
def slugs(path):
    out=set(); fence=False
    for line in open(path):
        if line.startswith('```'): fence=not fence; continue
        if fence: continue
        m=re.match(r'#{1,6}\s+(.*)',line)
        if m: out.add(slug(m.group(1).rstrip()))
    return out
bad=0
for f in sorted(glob.glob('**/*.md',recursive=True)):
    if 'CLAUDE' in f: continue
    for m in re.finditer(r'\]\(([^)\s]*?)#([^)\s]+)\)',open(f).read()):
        tgt,anc=m.group(1),m.group(2)
        path=f if tgt=='' else os.path.normpath(os.path.join(os.path.dirname(f),tgt))
        if not os.path.exists(path): continue
        if anc.lower() not in slugs(path):
            print(f"     unresolved: {f} -> {tgt}#{anc}"); bad+=1
sys.exit(1 if bad else 0)
PYEOF
  [ $? -eq 0 ] && pass "all heading anchors resolve" || fail "unresolved anchor link(s)"
else
  printf '  ⏭️  skipped (python3 not available)\n'
fi

printf '\n'
if [ "$FAIL" -eq 0 ]; then
  printf '\033[1;32m✅ All checks passed.\033[0m\n'
else
  printf '\033[1;31m❌ Some checks failed.\033[0m\n'
fi
exit "$FAIL"
