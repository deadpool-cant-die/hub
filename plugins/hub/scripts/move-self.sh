#!/bin/zsh
# (Herdr 시절) Herdr 앱 전용 — Orca엔 해당 없음(hub:session). Herdr를 끌 때 지운다.
# usage: move-self.sh <이름> <cwd> <space id> <tab id> <model> <effort> <session id> [바꿀 상대 칸 이름]
# 세션이 자기 자신을 다른 탭으로 옮길 때 쓴다. 반드시 독립 터미널로 띄운다:
#   env -u HC_TERMINAL_ID -u HC_SCOPE hc run --bg --no-parent --name move-<이름> -- <이 스크립트> ...
# 순서: 일이 끝날 때까지 기다림 → /exit → 셸 확인 → 같은 기록으로 새 탭에 resume → (선택) 자리 바꾸기
name=$1 cwd=$2 S=$3 T=$4 model=$5 effort=$6 sid=$7 swap=${8:-}
H() { env -u HC_TERMINAL_ID -u HC_SCOPE hc "$@"; }
dir=${0:A:h}
/bin/sleep 6
for i in {1..150}; do st=$(H get "$name" --json | python3 -c 'import json,sys;print((json.load(sys.stdin).get("status") or {}).get("state"))'); [[ $st != working ]] && break; /bin/sleep 2; done
/bin/sleep 3
old=$(H get "$name" --json | jq -r .address)
H send "$name" "/exit" >/dev/null
for i in {1..40}; do fg=$(H get "$old" --json | python3 -c 'import json,sys;print((json.load(sys.stdin).get("foreground") or {}).get("name"))'); [[ $fg == zsh || $fg == bash ]] && break; /bin/sleep 1; done
/bin/sleep 2
"$dir/launch.sh" "$name" "$cwd" "$S" "$T" "$model" "$effort" --resume "$sid"
/bin/sleep 5
if [[ -n $swap ]]; then
  pane_of() { herdr-app ls | N="$1" python3 -c 'import json,sys,os
for s in json.load(sys.stdin)["spaces"]:
  for t in s["tabs"]:
    for x in t.get("terminals",[]):
      if x.get("name")==os.environ["N"]: print(x["pane"])'; }
  herdr-app do pane.swap "{\"pane\":\"$(pane_of $name)\",\"target\":\"$(pane_of $swap)\"}"
fi
# (포커스 이동 금지: tab.select 안 함)
echo "옮김: $name → tab $T (옛 칸 $old 에는 빈 셸이 남음)"
