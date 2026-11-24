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
if have orca; then echo "  ✓ Orca 앱(orca)"
else echo "  ✗ Orca 앱(orca) — 없음. 봇·worker 스킬에 필요: Orca 앱을 깔고 한 번 열기(orca status로 확인)"; miss=1; fi
# (Herdr 시절) Herdr는 선택·옛 방식: 없어도 경고하지 않는다
have herdr-app && have hc && echo "  · Herdr 앱(herdr-app, hc) — 있음(선택·옛 방식, hub:layout에서만 씀)"
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
echo "== 직접 채울 설정 (개인 값은 레포에 없고, 이 파일들에만 둡니다. 없어도 기본값으로 동작)"
cfg() { # cfg <파일> <설명>
  if [ -s "$1" ]; then echo "  ✓ $1"; else echo "  · $1 — 비어 있음: $2"; fi
}
cfg "$HOME/.config/hub/config" "HUB_PRIVATE=<비공개 메모 폴더> 한 줄(기본 ~/.hub)"
cfg "${ASIDE_OPS_ACCOUNTS:-$HOME/.config/aside-ops/accounts.md}" "aside-ops 계정 지도. 스킬 폴더 aside-ops/accounts.example.md를 복사해 채우세요"
echo
echo "설치 끝! 이제 /hub:hub-onboarding 을 실행하세요"
echo "(이미 켜 둔 세션은 /reload-plugins 를 한 번 입력하면 보입니다. 지우기: sh uninstall.sh)"
