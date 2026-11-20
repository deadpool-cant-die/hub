#!/bin/zsh
# 떠 있는 모든 Claude Code 세션 입력창에 /reload-plugins(옵션 --skills면 /reload-skills도)를 넣고 칸마다 결과를 표로.
# Codex 등 다른 앱·이름 없는 칸(사용자가 직접 쓰는 칸)·질문 화면(blocked)은 건너뜀. 일하는 중이면 입력창에 넣어 두어 지금 일 뒤에 실행(대기열).
# usage: reload-all.sh [--skills] [--dry-run]
H() { env -u HC_TERMINAL_ID -u HC_SCOPE hc "$@"; }
skills=; dry=; for a in $@; do [[ $a == --skills ]] && skills=1; [[ $a == --dry-run ]] && dry=1; done
typeset -A act; names=()
for a in $(H ls --json | jq -r '.terminals[]|select(.state=="live")|.address'); do
  g=$(H get $a --json 2>/dev/null) || continue
  n=$(jq -r '.name // ""' <<<"$g"); app=$(jq -r '.status.app // ""' <<<"$g"); st=$(jq -r '.status.state // ""' <<<"$g")
  [[ -z $app ]] && continue                                     # 에이전트 아님(셸·래퍼)
  key=${n:-$a}; names+=($key)
  if [[ $app != claude-code ]]; then act[$key]="건너뜀	$app 칸"; continue; fi
  if [[ -z $n ]]; then act[$key]="건너뜀	이름 없는 칸(사용자가 쓰는 칸일 수 있음)"; continue; fi
  if [[ $st == blocked ]]; then act[$key]="건너뜀	질문 화면이 떠 있음(답하지 않음)"; continue; fi
  if [[ -n $dry ]]; then act[$key]="할 일	/reload-plugins${skills:+ + /reload-skills} ($st)"; continue; fi
  H send $n '/reload-plugins' >/dev/null 2>&1 && ok=1 || ok=
  [[ -n $skills && -n $ok ]] && H send $n '/reload-skills' >/dev/null 2>&1
  if [[ -z $ok ]]; then act[$key]="실패	hc send 거부"
  elif [[ $st == working || $a == $HC_TERMINAL_ID ]]; then act[$key]="대기열	일하는 중이라 지금 일 뒤 실행"
  else act[$key]="확인 중	"; fi
done
[[ -z $dry ]] && /bin/sleep 6
for k in $names; do
  if [[ ${act[$k]} == "확인 중	" ]]; then
    l=$(H read $k --lines 0 2>/dev/null | grep -E "Reloaded|reloaded|Queued|queued|plugin" | tail -1 | sed 's/^[[:space:]]*//' | cut -c1-80)
    if [[ $l == *[Rr]eloaded* ]]; then act[$k]="완료	$l"
    elif [[ $l == *[Qq]ueued* ]]; then act[$k]="대기열	$l"
    else act[$k]="확인 못 함	화면에 Reloaded 줄 없음(hc read $k로 확인)"; fi
  fi
  printf '%s\t%s\n' $k "${act[$k]}"
done | column -t -s $'\t'
