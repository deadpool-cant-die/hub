#!/bin/zsh
# usage: dont-waste-sessions.sh on [분] | off | status | dry-run
#   on [분]  : [분](기본 30, 최소 5)마다 놀고 있는 worker·터미널을 닫는 감시 터미널 'dont-waste-sessions'를 지금 워크스페이스에 켠다(이미 있으면 새 간격으로 다시)
#   off      : 감시 터미널을 끈다
#   status   : 켜져 있는지, 최근 닫은 기록
#   dry-run  : 지금 닫을 대상만 보여 준다(아무것도 안 닫음)
# 기준은 dont_waste_sessions.py 맨 위 설명. idle 기준은 DWS_IDLE_MIN(기본 120분).
D=${0:A:h}; source $D/hub-env.sh; N=dont-waste-sessions; LOG=${DWS_LOG:-$HUB_PRIVATE/scripts/dont-waste-sessions.log}; ST=$HUB_PRIVATE/scripts/$N.on
# 상태 파일 $ST: "<분> <터미널 handle>" (실행한 명령이 탭 제목을 덮어써서 제목으로는 못 찾음)
handle() { local h=$(cut -d' ' -f2 $ST 2>/dev/null); [[ -n $h ]] && orca terminal list --json 2>/dev/null | jq -e --arg h $h 'any(.result.terminals[]; .handle==$h and .connected)' >/dev/null && echo $h; }
case ${1:-} in
  on)  min=${2:-30}; (( min < 5 )) && min=5
       h=$(handle); [[ -n $h ]] && orca terminal close --terminal $h >/dev/null
       mkdir -p ${ST:h}
       h=$(orca terminal create --title $N --command "env HUB_PRIVATE=${(q)HUB_PRIVATE} DWS_LOG=${(q)LOG} DWS_IDLE_MIN=${DWS_IDLE_MIN:-120} python3 -I ${(q)D}/dont_waste_sessions.py loop $min" --json | jq -r '.result.terminal.handle // empty')
       [[ -n $h ]] && echo "$min $h" > $ST && echo "on: ${min}분마다, idle ${DWS_IDLE_MIN:-120}분 이상 닫음 (터미널 $N, 로그 $LOG)" ;;
  off) h=$(handle); rm -f $ST; [[ -n $h ]] && { orca terminal close --terminal $h >/dev/null; echo "off"; } || echo "이미 꺼져 있음" ;;
  status) [[ -n $(handle) ]] && echo "켜짐: $(cut -d' ' -f1 $ST)분 간격 (터미널 $(handle))" || echo "꺼짐"
       [[ -f $LOG ]] && { echo "최근 닫은 것:"; tail -5 $LOG; } ;;
  dry-run) python3 -I $D/dont_waste_sessions.py sweep --dry-run ;;
  *) sed -n '2,7p' $0; exit 2 ;;
esac
