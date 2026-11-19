#!/bin/zsh
# usage: dont-waste-sessions.sh on [분] | off | status | dry-run
#   on [분]  : [분](기본 30, 최소 5)마다 놀고 있는 세션을 끄는 감시 터미널 'dont-waste-sessions'를 켠다(이미 있으면 새 간격으로 다시)
#   off      : 감시 터미널을 끈다
#   status   : 켜져 있는지, 최근 끈 기록
#   dry-run  : 지금 끌 대상만 보여 준다(아무것도 안 끔)
# 기준은 dont_waste_sessions.py 맨 위 설명. idle 기준은 DWS_IDLE_MIN(기본 120분).
H() { env -u HC_TERMINAL_ID -u HC_SCOPE hc "$@"; }
D=${0:A:h}; N=dont-waste-sessions; LOG=${DWS_LOG:-$HOME/Hub/private/scripts/dont-waste-sessions.log}
running() { [[ $(H get $N --json 2>/dev/null | jq -r '.state // ""') == live ]]; }
case ${1:-} in
  on)  min=${2:-30}; (( min < 5 )) && min=5
       running && H kill $N >/dev/null
       H run --bg --no-parent --name $N --cwd $HOME -- env DWS_IDLE_MIN=${DWS_IDLE_MIN:-120} python3 -I $D/dont_waste_sessions.py loop $min >/dev/null \
         && echo "on: ${min}분마다, idle ${DWS_IDLE_MIN:-120}분 이상 세션 끔 (터미널 $N, 로그 $LOG)" ;;
  off) running && { H kill $N >/dev/null; echo "off"; } || echo "이미 꺼져 있음" ;;
  status) running && echo "켜짐: $(H get $N --json | jq -r '.argv|join(" ")' | grep -o 'loop [0-9]*')분 간격" || echo "꺼짐"
       [[ -f $LOG ]] && { echo "최근 끈 세션:"; tail -5 $LOG; } ;;
  dry-run) python3 -I $D/dont_waste_sessions.py sweep --dry-run ;;
  *) sed -n '2,7p' $0; exit 2 ;;
esac
