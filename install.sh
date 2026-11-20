#!/bin/sh
# hub 설치: Claude Code(와 있으면 Codex)에 hub 플러그인을 깐다.
#   curl -fsSL https://raw.githubusercontent.com/deadpool-cant-die/hub/main/install.sh | sh
#   sh install.sh [claude|codex|all]     (기본 all = 깔려 있는 쪽 전부)
set -u
REPO=deadpool-cant-die/hub
MKT=deadpool-skills
want=${1:-all}   # 시험용: HUB_SOURCE=<로컬 폴더나 주소> 로 설치 출처를 바꿀 수 있음
have() { command -v "$1" >/dev/null 2>&1; }

echo "== 필요한 것 확인"
miss=0
for t in git python3 jq; do
  if have "$t"; then echo "  ✓ $t"; else echo "  ✗ $t — 없음 (macOS: brew install $t)"; miss=1; fi
done
if have herdr-app && have hc; then echo "  ✓ Herdr 앱(herdr-app, hc)"
else echo "  ✗ Herdr 앱(herdr-app, hc) — 없음. 세션·탭 스킬에 필요: curl -fsSL https://releases.herdr.dev/app/install.sh | sh 후 앱을 한 번 열기"; miss=1; fi
have gh && echo "  ✓ gh (GitHub CLI)" || echo "  · gh — 없어도 됨(배포 현황·PR 스킬에서 씀)"
[ "$miss" = 1 ] && echo "  → 없는 것을 깔아도 되고, 플러그인 설치는 지금 계속합니다."

ok=0
if [ "$want" != codex ]; then
  if have claude; then
    echo "== Claude Code"
    claude plugin marketplace list 2>/dev/null | grep -q "$MKT" || claude plugin marketplace add "${HUB_SOURCE:-$REPO}" || exit 1
    claude plugin install "hub@$MKT" --scope user || exit 1
    ok=1
  else echo "== Claude Code 없음 — 건너뜀 (https://claude.com/claude-code)"; fi
fi
if [ "$want" != claude ]; then
  if have codex; then
    echo "== Codex"
    codex plugin marketplace list 2>/dev/null | grep -q "$MKT" || codex plugin marketplace add "${HUB_SOURCE:-https://github.com/$REPO.git}" || exit 1
    codex plugin add "hub@$MKT" || exit 1
    ok=1
  else [ "$want" = codex ] && echo "== Codex 없음 — 건너뜀"; fi
fi
[ "$ok" = 1 ] || { echo "설치할 곳(Claude Code·Codex)이 없습니다."; exit 1; }
echo
echo "설치 끝! 이제 /hub:hub-onboarding 을 실행하세요"
echo "(이미 켜 둔 세션은 /reload-plugins 를 한 번 입력하면 보입니다. 지우기: sh uninstall.sh)"
