#!/bin/zsh
# 일 탭 배치: 왼쪽 반 = head, 오른쪽 반 = worker. worker 1~3개면 오른쪽 한 열에 위아래 같은 높이,
# 4개 이상이면 오른쪽 반을 두 열 격자로(ㅣㅡㅡ ㅣㅡㅡ). head가 없는 탭은 worker를 같은 폭으로 나란히. 이미 그 모양이면 아무것도 안 한다(여러 번 돌려도 같은 결과).
# 세션은 다시 켜지 않고 칸만 바꾼다. 포커스 이동 명령은 쓰지 않는다.
# 다시 짤 때: head 칸만 남기고 나머지는 attach 래퍼 칸이면 닫고, 진짜 터미널 칸이면 park(계속 돎) →
#   pane.split(pane 지정)+hc attach 래퍼로 다시 만든다. 이름 없는 빈 셸 칸도 park된다(종료 안 함).
# usage: tab-layout.sh [--check] <tab id> [head 이름 [worker 이름...]]
#   head·worker를 안 주면 탭에 보이는 칸에서 찾는다(head = 이름이 -head로 끝나는 칸, 나머지 = worker, 지금 순서대로).
#   head 자리에 '-'를 주면 head 없는 탭으로 본다.
H() { env -u HC_TERMINAL_ID -u HC_SCOPE hc "$@"; }
D=${0:A:h}; PYT=(python3 -I "$D/herdr_tree.py")
check=; [[ ${1:-} == --check ]] && { check=1; shift; }
TAB=${1:?usage: tab-layout.sh [--check] <tab id> [head [worker...]]}; shift
if (( $# )); then HEAD=$1; shift; W=($@)
else m=("${(@f)$($PYT members $TAB)}"); HEAD=$m[1]; W=(${=m[2]}); fi
HEAD=${HEAD:--}
(( ${#W} )) || { echo "변화 없음 (worker 없음)"; exit 0; }
[[ $HEAD == - && ${#W} -eq 1 ]] && { echo "변화 없음 (칸 하나)"; exit 0; }
shape() { $PYT tabshape $TAB $HEAD $W || { echo "FAIL: 칸 트리를 못 읽음" >&2; exit 1; }; }

J=$(shape) || exit 1
[[ $(jq -r .ok <<<"$J") == true ]] && { echo "변화 없음 ($HEAD | ${W[*]})"; exit 0; }
echo "다름: $(jq -r .why <<<"$J") ($HEAD | ${W[*]})"
[[ -n $check ]] && exit 2

split() { herdr-app do pane.split "$(jq -nc --arg p "$1" --arg d "$2" --arg c "exec env -u HC_TERMINAL_ID -u HC_SCOPE hc attach $3" \
    '{direction:$d,pane:$p,argv:["zsh","-lc",$c]}')" | jq -er .pane; }
stack() { local p=$1; shift; for n in $@; do p=$(split $p down $n) || return 1; done; }  # p 아래로 차례로 쌓기

if [[ $(jq -r .struct_ok <<<"$J") != true ]]; then
  for n in ${HEAD:#-} $W; do H get $n >/dev/null 2>&1 || { echo "FAIL: $n 세션이 없음"; exit 1; }; done
  ANCHOR=$HEAD; [[ $HEAD == - ]] && ANCHOR=$W[1]
  P_H=$($PYT pane $TAB $ANCHOR) || { echo "FAIL: $ANCHOR 칸이 이 탭에 없음(기준 칸)"; exit 1; }
  jq -c --arg ph "$P_H" '.blocks[]|select(.pane!=$ph)' <<<"$J" | while read -r b; do
    if [[ $(jq -r .wrapper <<<"$b") == true ]]; then herdr-app do pane.close "$(jq -c '{pane}' <<<"$b")" >/dev/null
    else herdr-app do terminal.park "$(jq -c '{terminal}' <<<"$b")" >/dev/null; echo "park(계속 돎): $(jq -r '.name // .terminal' <<<"$b")"; fi
  done; /bin/sleep 1
  n=${#W}; k=$(( (n + 1) / 2 ))
  if [[ $HEAD == - ]]; then  # head 없음: 오른쪽으로 차례로
    p=$P_H; for w in ${W[2,-1]}; do p=$(split $p right $w) || { echo "FAIL: 칸 나누기 실패"; exit 1; }; done
  elif (( n <= 3 )); then
    P1=$(split $P_H right $W[1]) && stack $P1 ${W[2,-1]} || { echo "FAIL: 칸 나누기 실패"; exit 1; }
  else
    # head 오른쪽으로 나누면 head 바로 옆에 끼어든다: 둘째 열 맨 위를 먼저, 첫째 열 맨 위를 나중에
    PB=$(split $P_H right $W[k+1]) && PA=$(split $P_H right $W[1]) && stack $PA ${W[2,k]} && stack $PB ${W[k+2,-1]} \
      || { echo "FAIL: 칸 나누기 실패"; exit 1; }
  fi
  /bin/sleep 1; J=$(shape) || exit 1
fi
jq -r '.resize[]|@json' <<<"$J" | while read -r x; do herdr-app do layout.resize "$(jq -c '{id:.[0],weight:.[1]}' <<<"$x")" >/dev/null; done
/bin/sleep 1; J=$(shape) || exit 1
[[ $(jq -r .ok <<<"$J") == true ]] && echo "OK: 배치 완료 ($HEAD | ${W[*]})" || { echo "FAIL: $(jq -r .why <<<"$J")"; exit 1; }
