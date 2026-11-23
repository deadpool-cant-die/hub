#!/bin/zsh
# 떠 있는 모든 Claude Code 터미널 입력창에 /reload-plugins(옵션 --skills면 /reload-skills도)를 넣고 터미널마다 결과를 표로.
# Orca 터미널만 대상(orca terminal list). Codex 등 다른 에이전트·셸·질문 화면(blocked·waiting)은 건너뜀.
# 일하는 중이면 입력창에 넣어 두어 지금 일 뒤에 실행(대기열). Orca 채팅(봇 채팅 등)은 터미널이 아니라 개수만 알림.
# usage: reload-all.sh [--skills] [--dry-run]
skills=; dry=; for a in $@; do [[ $a == --skills ]] && skills=1; [[ $a == --dry-run ]] && dry=1; done
ag=$(orca agent list --json) || { echo "FAIL: orca agent list (Orca 앱이 떠 있나? orca status)"; exit 1; }
tl=$(orca terminal list --json) || { echo "FAIL: orca terminal list"; exit 1; }
typeset -A act state; names=()
# 터미널 ↔ 에이전트 상태: agent의 paneKey = 터미널의 tabId:leafId
for k v in $(jq -r '.result.agents[]|select(.kind=="terminal")|.paneKey, .state' <<<"$ag"); do state[$k]=$v; done
send() { orca terminal send --terminal $1 --text $2 --enter --json >/dev/null 2>&1; }
for row in ${(f)"$(jq -r '.result.terminals[]|select(.connected and .writable)|[.handle, (.agentIdentity // ""), .tabId+":"+.leafId, .title]|join("\u001f")' <<<"$tl")"}; do
  IFS=$'\x1f' read -r h app pk title <<<"$row"                # 탭은 빈 칸이 합쳐져서 안 씀
  [[ -z $app ]] && continue                                     # 에이전트 아님(셸)
  key="${title[1,30]} (${h[6,13]})"; names+=($key); st=${state[$pk]:-}
  if [[ $app != claude ]]; then act[$key]="건너뜀	$app 터미널"; continue; fi
  if [[ $st == blocked || $st == waiting ]]; then act[$key]="건너뜀	질문 화면이 떠 있음(답하지 않음)"; continue; fi
  if [[ -n $dry ]]; then act[$key]="할 일	/reload-plugins${skills:+ + /reload-skills} (${st:-상태 모름})"; continue; fi
  send $h /reload-plugins && ok=1 || ok=
  [[ -n $skills && -n $ok ]] && send $h /reload-skills
  if [[ -z $ok ]]; then act[$key]="실패	orca terminal send 거부"
  elif [[ $st == working ]]; then act[$key]="대기열	일하는 중이라 지금 일 뒤 실행"
  else act[$key]="확인 중	$h"; fi
done
[[ -z $dry ]] && /bin/sleep 6
for k in $names; do
  if [[ ${act[$k]} == 확인\ 중* ]]; then
    h=${act[$k]#*	}
    l=$(orca terminal read --terminal $h --screen --json 2>/dev/null | jq -r '.result.terminal.tail[]?' | grep -E "Reloaded|reloaded|Queued|queued|plugin" | tail -1 | sed 's/^[[:space:]]*//' | cut -c1-80)
    if [[ $l == *[Rr]eloaded* ]]; then act[$k]="완료	$l"
    elif [[ $l == *[Qq]ueued* ]]; then act[$k]="대기열	$l"
    else act[$k]="확인 못 함	화면에 Reloaded 줄 없음(orca terminal read --terminal $h --screen)"; fi
  fi
  printf '%s\t%s\n' $k "${act[$k]}"
done | column -t -s $'\t'
echo "Orca 채팅 $(jq '[.result.agents[]|select(.kind=="chat")]|length' <<<"$ag")개는 터미널이 아니라 건너뜀(채팅 안에서 /reload-plugins)"
