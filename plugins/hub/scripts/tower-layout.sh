#!/bin/zsh
# tower 탭 배치: 위 얇은 띠(15%) = hub-resource | hub-atlassian (각 칸은 hc attach 셸), 아래(85%) = hub-admin | hub-secretary.
# 각 줄 1:1, 네 칸 핀, 탭 이름 tower. 이미 그 모양이면 아무것도 안 한다(여러 번 돌려도 같은 결과).
# 포커스 이동 명령(tab.select·pane.focus 등)은 쓰지 않는다. 다시 짜야 하면 hub-admin 칸만 남기고
# 나머지는 attach 래퍼 칸이면 닫고(세션은 안 꺼짐), 진짜 터미널 칸이면 park(계속 돎)한 뒤 pane.split(pane 지정)+pane.swap+hc attach로 만든다.
# usage: tower-layout.sh [--check]     (--check: 판정만, 아무것도 안 바꿈. 다르면 종료 코드 2)
# 시험용: TAB=<tab id> NAMES="admin secretary resource atlassian" TAB_NAME=<이름>
H() { env -u HC_TERMINAL_ID -u HC_SCOPE hc "$@"; }
D=${0:A:h}; PYT=(python3 -I "$D/herdr_tree.py")
TAB=${TAB:-$(herdr-app ls | jq -r '[.spaces[].tabs[]|select(.name=="tower")][0].id // empty')}; [[ -z $TAB ]] && { echo "FAIL: tower 탭이 없음"; exit 1; }; TAB_NAME=${TAB_NAME:-tower}
N=(${=NAMES:-hub-admin hub-secretary hub-resource hub-atlassian}); A=$N[1] S=$N[2] R=$N[3] AT=$N[4]
shape() { $PYT shape $TAB $A $S $R $AT || { echo "FAIL: 칸 트리를 못 읽음" >&2; exit 1; }; }
addr() { H get "$1" --json 2>/dev/null | jq -r '.address // empty'; }

J=$(shape) || exit 1; why=$(jq -r .why <<<"$J"); struct=$(jq -r .struct_ok <<<"$J")
tabname=$(herdr-app ls | jq -r --arg t $TAB '.spaces[].tabs[]|select(.id==$t)|.name')
unpinned=(); for n in $N; do a=$(addr $n); [[ -z $a ]] && { echo "FAIL: $n 세션이 없음"; exit 1; }
  [[ $(H get $a --json | jq -r '.labels["herdr.pinned"] // ""') == 1 ]] || unpinned+=($n); done
if [[ $(jq -r .ok <<<"$J") == true && $tabname == $TAB_NAME && ${#unpinned} -eq 0 ]]; then echo "변화 없음 (모양·크기·핀·이름 같음)"; exit 0; fi
echo "다름: $why${unpinned:+ / 핀 없음: $unpinned}${${tabname:#$TAB_NAME}:+ / 탭 이름: $tabname}"
[[ ${1:-} == --check ]] && exit 2

split() { # split <pane> <down|right> <세션 이름> -> 새 칸 id (pane.split 결과의 pane)
  herdr-app do pane.split "$(jq -nc --arg p "$1" --arg d "$2" --arg c "exec env -u HC_TERMINAL_ID -u HC_SCOPE hc attach $3" \
    '{direction:$d,pane:$p,argv:["zsh","-lc",$c]}')" | jq -er .pane; }

if [[ $struct != true ]]; then
  P_A=$($PYT pane $TAB $A) || { echo "FAIL: $A 칸이 이 탭에 없음(기준 칸)"; exit 1; }
  jq -c --arg pa "$P_A" '.blocks[]|select(.pane!=$pa)' <<<"$J" | while read -r b; do
    if [[ $(jq -r .wrapper <<<"$b") == true ]]; then herdr-app do pane.close "$(jq -c '{pane}' <<<"$b")" >/dev/null
    else herdr-app do terminal.park "$(jq -c '{terminal}' <<<"$b")" >/dev/null; echo "park(계속 돎): $(jq -r '.name // .terminal' <<<"$b")"; fi
  done; /bin/sleep 1
  # admin 아래로 띠 칸을 만들고 위로 올린 뒤, 아래 줄에 secretary, 위 줄에 atlassian
  P_R=$(split $P_A down $R) || { echo "FAIL: $R 칸 실패"; exit 1; }
  herdr-app do pane.swap "{\"pane\":\"$P_R\",\"target\":\"$P_A\"}" >/dev/null
  split $P_A right $S >/dev/null && split $P_R right $AT >/dev/null || { echo "FAIL: 칸 나누기 실패"; exit 1; }
  /bin/sleep 1; J=$(shape) || exit 1
fi
jq -r '.resize[]|@json' <<<"$J" | while read -r x; do herdr-app do layout.resize "$(jq -c '{id:.[0],weight:.[1]}' <<<"$x")" >/dev/null; done
for n in $N; do herdr-app do terminal.pin "{\"terminal\":\"$(addr $n)\",\"pinned\":true}" >/dev/null; done
herdr-app do tab.rename "{\"id\":\"$TAB\",\"name\":\"$TAB_NAME\"}" >/dev/null
/bin/sleep 1; J=$(shape) || exit 1
[[ $(jq -r .ok <<<"$J") == true ]] && echo "OK: 배치 완료" || { echo "FAIL: $(jq -r .why <<<"$J")"; exit 1; }
