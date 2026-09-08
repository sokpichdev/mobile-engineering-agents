#!/usr/bin/env bash
# Mobile Engineering Agents — local setup verification

PASS=0; FAIL=0
GREEN='\033[0;32m'; RED='\033[0;31m'; RESET='\033[0m'

check() {
  local label="$1"; shift
  if eval "$@" > /dev/null 2>&1; then
    printf "  ${GREEN}✓${RESET} %s\n" "$label"; ((PASS++))
  else
    printf "  ${RED}✗${RESET} %s\n" "$label"; ((FAIL++))
  fi
}

echo ""
echo "Mobile Engineering Agents — Verification"
echo "========================================="
echo ""

echo "Entry points:"
check "CLAUDE.md"       "[ -f CLAUDE.md ]"
check "GEMINI.md"       "[ -f GEMINI.md ]"
check ".cursorrules"    "[ -f .cursorrules ]"
check ".windsurfrules"  "[ -f .windsurfrules ]"
check "AGENTS.md"       "[ -f AGENTS.md ]"

echo ""
echo "Core directories:"
check "agents/ (≥17 files)"     "[ \$(ls agents/*.md 2>/dev/null | wc -l) -ge 17 ]"
check "skills/ (≥53 files)"     "[ \$(find skills -name '*.md' 2>/dev/null | wc -l) -ge 53 ]"
check "workflows/ (≥13 files)"  "[ \$(ls workflows/*.md 2>/dev/null | wc -l) -ge 13 ]"
check "checklists/ (≥10 files)" "[ \$(ls checklists/*.md 2>/dev/null | wc -l) -ge 10 ]"
check "standards/ (≥10 files)"  "[ \$(ls standards/*.md 2>/dev/null | wc -l) -ge 10 ]"
check "templates/"              "[ -d templates ]"
check "architecture/"           "[ -d architecture ]"

echo ""
echo "Platform coverage:"
check "skills/*/ios/ (≥34)"     "[ \$(find skills -path '*/ios/*' -name '*.md' 2>/dev/null | wc -l) -ge 34 ]"
check "skills/*/flutter/ (≥17)" "[ \$(find skills -path '*/flutter/*' -name '*.md' 2>/dev/null | wc -l) -ge 17 ]"
check "templates/ios/"          "[ -d templates/ios ]"
check "templates/flutter/"      "[ -d templates/flutter ]"

echo ""
if [ "$FAIL" -eq 0 ]; then
  printf "${GREEN}✅ All checks passed (%d/%d)${RESET}\n" "$PASS" "$PASS"
  echo ""
  echo "Smoke test — type this in your AI agent session:"
  echo "  !verify"
else
  printf "${RED}❌ %d check(s) failed. See items above.${RESET}\n" "$FAIL"
  echo ""
  echo "Try: git status   (check for missing or untracked files)"
fi
echo ""
exit $FAIL
