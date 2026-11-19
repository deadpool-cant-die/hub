#!/bin/zsh
# 일 탭 배치: 왼쪽 반 = head, 오른쪽 반 = worker. worker 1~3개면 오른쪽 한 열에 위아래 같은 높이,
# 4개 이상이면 오른쪽 반을 두 열 격자로(ㅣㅡㅡ ㅣㅡㅡ). head가 없는 탭은 worker를 같은 폭으로 나란히.
# 이미 그 모양이면 아무것도 안 한다(여러 번 돌려도 같은 결과). 세션은 다시 켜지 않고 칸만 옮긴다.
# 진짜 세션 칸을 그대로 옮기므로(빈 칸 → 자리 바꾸기, layout-lib.sh) 칸마다 이름·app·상태가 그대로 보인다.
# 옛 방식으로 `hc attach` 래퍼 칸에 붙어 있던 세션은 진짜 칸으로 되돌린다. 포커스 이동 명령은 쓰지 않는다.
# usage: tab-layout.sh [--check] <tab id> [head 이름 [worker 이름...]]
#   head·worker를 안 주면 탭에 보이는 칸에서 찾는다(head = 이름이 -head로 끝나는 칸, 나머지 = worker, 지금 순서대로).
#   head 자리에 '-'를 주면 head 없는 탭으로 본다.
D=${0:A:h}; PYT=(python3 -I "$D/herdr_tree.py"); source "$D/layout-lib.sh"
check=; [[ ${1:-} == --check ]] && { check=1; shift; }
TAB=${1:?usage: tab-layout.sh [--check] <tab id> [head [worker...]]}; shift
if (( $# )); then HEAD=$1; shift; W=($@)
else m=("${(@f)$($PYT members $TAB)}"); HEAD=$m[1]; W=(${=m[2]}); fi
HEAD=${HEAD:--}
(( ${#W} )) || { echo "변화 없음 (worker 없음)"; exit 0; }
shape() { $PYT tabshape $TAB $HEAD $W || { echo "FAIL: 칸 트리를 못 읽음" >&2; exit 1; }; }
wrappers() { $PYT shape-blocks $TAB | awk '$4=="true"' | wc -l | tr -d ' '; }

J=$(shape) || exit 1
if [[ $(jq -r .ok <<<"$J") == true && $(wrappers) == 0 ]]; then echo "변화 없음 ($HEAD | ${W[*]})"; exit 0; fi
nw=$(wrappers); extra=; (( nw )) && extra=" / 래퍼 칸 ${nw}개"; echo "다름: $(jq -r .why <<<"$J")$extra ($HEAD | ${W[*]})"
[[ -n $check ]] && exit 2

ALL=(${HEAD:#-} $W)
for n in $ALL; do H get $n >/dev/null 2>&1 || { echo "FAIL: $n 세션이 없음"; exit 1; }; done
SP=$(herdr-app ls | jq -r --arg t $TAB '.spaces[]|select(any(.tabs[];.id==$t))|.id')
readopt $SP $ALL || exit 1
J=$(shape) || exit 1

if [[ $(jq -r .struct_ok <<<"$J") != true ]]; then
  ANCHOR=$HEAD; [[ $HEAD == - ]] && ANCHOR=$W[1]
  A=$(pane_of $ANCHOR) || { echo "FAIL: $ANCHOR 칸이 이 탭에 없음(기준 칸)"; exit 1; }
  n=${#W}; k=$(( (n + 1) / 2 )); slot=()
  if [[ $HEAD == - ]]; then          # head 없음: 기준(w1) 오른쪽으로 차례로
    slot=($A); p=$A; for ((i=2;i<=n;i++)); do p=$(ph $p right) || exit 1; slot+=($p); done
  elif (( n <= 3 )); then            # head | 한 열
    p=$(ph $A right) || exit 1; slot=($p); for ((i=2;i<=n;i++)); do p=$(ph $p down) || exit 1; slot+=($p); done
  else                               # head | 두 열 (head 오른쪽에 나누면 head 바로 옆에 끼어들어서 둘째 열 먼저)
    b=$(ph $A right) && a=$(ph $A right) || exit 1; slot=($a)
    p=$a; for ((i=2;i<=k;i++)); do p=$(ph $p down) || exit 1; slot+=($p); done
    slot+=($b); p=$b; for ((i=k+2;i<=n;i++)); do p=$(ph $p down) || exit 1; slot+=($p); done
  fi
  for ((i=1;i<=n;i++)); do put $W[i] $slot[i] || exit 1; done
  finish $ALL
  /bin/sleep 1; J=$(shape) || exit 1
fi
jq -r '.resize[]|@json' <<<"$J" | while read -r x; do herdr-app do layout.resize "$(jq -c '{id:.[0],weight:.[1]}' <<<"$x")" >/dev/null; done
/bin/sleep 1; J=$(shape) || exit 1
[[ $(jq -r .ok <<<"$J") == true ]] && echo "OK: 배치 완료 ($HEAD | ${W[*]})" || { echo "FAIL: $(jq -r .why <<<"$J")"; exit 1; }
