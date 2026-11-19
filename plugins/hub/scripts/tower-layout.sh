#!/bin/zsh
# tower 탭 배치: 위 얇은 띠(15%) = hub-resource | hub-atlassian, 아래(85%) = hub-admin | hub-secretary.
# 각 줄 1:1, 네 칸 핀, 탭 이름 tower. 이미 그 모양이면 아무것도 안 한다(여러 번 돌려도 같은 결과).
# 진짜 세션 칸을 그대로 옮긴다(빈 칸 → 자리 바꾸기, layout-lib.sh): 칸마다 이름·app·상태가 그대로 보인다.
# 옛 `hc attach` 래퍼 칸은 진짜 칸으로 되돌린다. 포커스 이동 명령은 쓰지 않는다. 세션은 다시 켜지 않는다.
# usage: tower-layout.sh [--check]     (--check: 판정만, 아무것도 안 바꿈. 다르면 종료 코드 2)
# 시험용: TAB=<tab id> NAMES="admin secretary resource atlassian" TAB_NAME=<이름>
D=${0:A:h}; PYT=(python3 -I "$D/herdr_tree.py"); source "$D/layout-lib.sh"
TAB=${TAB:-$(herdr-app ls | jq -r '[.spaces[].tabs[]|select(.name=="tower")][0].id // empty')}; [[ -z $TAB ]] && { echo "FAIL: tower 탭이 없음"; exit 1; }; TAB_NAME=${TAB_NAME:-tower}
N=(${=NAMES:-hub-admin hub-secretary hub-resource hub-atlassian}); A=$N[1] S=$N[2] R=$N[3] AT=$N[4]
shape() { $PYT shape $TAB $A $S $R $AT || { echo "FAIL: 칸 트리를 못 읽음" >&2; exit 1; }; }
addr() { H get "$1" --json 2>/dev/null | jq -r '.address // empty'; }

J=$(shape) || exit 1; why=$(jq -r .why <<<"$J"); struct=$(jq -r .struct_ok <<<"$J")
tabname=$(herdr-app ls | jq -r --arg t $TAB '.spaces[].tabs[]|select(.id==$t)|.name')
unpinned=(); for n in $N; do a=$(addr $n); [[ -z $a ]] && { echo "FAIL: $n 세션이 없음"; exit 1; }
  [[ $(H get $a --json | jq -r '.labels["herdr.pinned"] // ""') == 1 ]] || unpinned+=($n); done
nw=$($PYT shape-blocks $TAB | awk '$4=="true"' | wc -l | tr -d ' ')
if [[ $(jq -r .ok <<<"$J") == true && $tabname == $TAB_NAME && ${#unpinned} -eq 0 && $nw == 0 ]]; then echo "변화 없음 (모양·크기·핀·이름 같음)"; exit 0; fi
msg="다름: $why"; (( ${#unpinned} )) && msg+=" / 핀 없음: $unpinned"; [[ $tabname != $TAB_NAME ]] && msg+=" / 탭 이름: $tabname"; (( nw )) && msg+=" / 래퍼 칸 ${nw}개"; echo $msg
[[ ${1:-} == --check ]] && exit 2

SP=$(herdr-app ls | jq -r --arg t $TAB '.spaces[]|select(any(.tabs[];.id==$t))|.id')
readopt $SP $N || exit 1
J=$(shape) || exit 1
if [[ $(jq -r .struct_ok <<<"$J") != true ]]; then
  P_A=$(pane_of $A) || { echo "FAIL: $A 칸이 이 탭에 없음(기준 칸)"; exit 1; }
  # 빈 칸 뼈대: column[ row[A, Y], row[X, Z] ] → A를 X(아래 왼쪽)로, 위 왼쪽(X 자리)에 R, Y에 AT, Z에 S
  X=$(ph $P_A down) && Y=$(ph $P_A right) && Z=$(ph $X right) || { echo "FAIL: 칸 나누기 실패"; exit 1; }
  put $A $X && put $R $X && put $AT $Y && put $S $Z || exit 1
  finish $N
  /bin/sleep 1; J=$(shape) || exit 1
fi
jq -r '.resize[]|@json' <<<"$J" | while read -r x; do herdr-app do layout.resize "$(jq -c '{id:.[0],weight:.[1]}' <<<"$x")" >/dev/null; done
for n in $N; do herdr-app do terminal.pin "{\"terminal\":\"$(addr $n)\",\"pinned\":true}" >/dev/null; done
herdr-app do tab.rename "{\"id\":\"$TAB\",\"name\":\"$TAB_NAME\"}" >/dev/null
/bin/sleep 1; J=$(shape) || exit 1
[[ $(jq -r .ok <<<"$J") == true ]] && echo "OK: 배치 완료" || { echo "FAIL: $(jq -r .why <<<"$J")"; exit 1; }
