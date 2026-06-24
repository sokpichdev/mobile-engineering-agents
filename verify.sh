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
check "agents/ (≥14 files)"    "[ \$(ls agents/*.md 2>/dev/null | wc -l) -ge 14 ]"
check "skills/ (≥31 files)"    "[ \$(find skills -name '*.md' 2>/dev/null | wc -l) -ge 31 ]"
check "workflows/ (≥12 files)" "[ \$(ls workflows/*.md 2>/dev/null | wc -l) -ge 12 ]"
check "checklists/ (≥8 files)" "[ \$(ls checklists/*.md 2>/dev/null | wc -l) -ge 8 ]"
check "standards/ (≥7 files)"  "[ \$(ls standards/*.md 2>/dev/null | wc -l) -ge 7 ]"
check "templates/"             "[ -d templates ]"
check "architecture/"          "[ -d architecture ]"

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
