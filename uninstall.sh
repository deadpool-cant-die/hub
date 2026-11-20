#!/bin/sh
# hub 지우기: 플러그인 제거 + 마켓플레이스 제거 + (물어보고) hub가 만든 폴더 지우기.
#   curl -fsSL https://raw.githubusercontent.com/deadpool-cant-die/hub/main/uninstall.sh | sh
#   sh uninstall.sh [--yes]     (--yes: 기본 폴더 ~/.hub·~/.config/hub는 묻지 않고 지움. 직접 정한 HUB_PRIVATE는 항상 물어봄)
set -u
MKT=deadpool-skills
yes=; [ "${1:-}" = --yes ] && yes=1
have() { command -v "$1" >/dev/null 2>&1; }
if have claude; then
  echo "== Claude Code"
  claude plugin uninstall "hub@$MKT" --scope user 2>/dev/null && echo "  플러그인 지움" || echo "  플러그인 없음"
  claude plugin marketplace remove "$MKT" 2>/dev/null && echo "  마켓플레이스 지움" || echo "  마켓플레이스 없음"
fi
if have codex; then
  echo "== Codex"
  codex plugin remove "hub@$MKT" 2>/dev/null && echo "  플러그인 지움" || echo "  플러그인 없음"
  codex plugin marketplace remove "$MKT" 2>/dev/null && echo "  마켓플레이스 지움" || echo "  마켓플레이스 없음"
fi

# hub가 만든 것: 비공개 폴더(HUB_PRIVATE, 기본 ~/.hub)와 설정 파일 ~/.config/hub
CFG=$HOME/.config/hub/config
P=${HUB_PRIVATE:-}
[ -z "$P" ] && [ -f "$CFG" ] && P=$(sed -n 's/^HUB_PRIVATE=//p' "$CFG" | tail -1)
P=${P:-$HOME/.hub}
for d in "$P" "$HOME/.config/hub"; do
  [ -e "$d" ] || continue
  # --yes는 hub가 직접 만든 기본 자리(~/.hub, ~/.config/hub)만. 직접 고른 폴더는 꼭 물어본다
  if [ -n "$yes" ] && { [ "$d" = "$HOME/.hub" ] || [ "$d" = "$HOME/.config/hub" ]; }; then a=y
  elif [ -t 0 ] || [ -r /dev/tty ]; then printf "%s 도 지울까요? 로그·메모가 들어 있을 수 있어요 [y/N] " "$d"; read a < /dev/tty || a=n
  else a=n; fi
  case "$a" in y|Y) rm -rf "$d" && echo "  지움: $d" ;; *) echo "  남겨 둠: $d" ;; esac
done
echo
echo "지우기 끝. 이미 켜 둔 세션은 /reload-plugins 를 한 번 입력하거나 다시 켜면 hub 스킬이 사라집니다."
