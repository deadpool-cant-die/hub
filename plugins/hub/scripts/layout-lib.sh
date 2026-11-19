# tab-layout.sh·tower-layout.sh가 같이 쓰는 칸 다시 짜기 도구 (zsh에서 source).
# 방법: 진짜 세션 칸은 park하지 않는다(park하면 Herdr가 에이전트로 못 알아봄).
#   1) 원하는 모양의 빈 칸(placeholder, `sleep`)을 pane.split(pane 지정)으로 만든다
#   2) 진짜 칸을 pane.swap(pane↔target)으로 빈 칸 자리에 옮긴다 → 빈 칸은 진짜 칸의 옛 자리로 감
#   3) 빈 칸을 닫는다. 이름 없는 남는 셸 칸은 park(종료 안 함)
# 옛 방식(park + `hc attach` 래퍼 칸)으로 붙어 있던 세션은 readopt로 진짜 칸으로 되돌린다:
#   래퍼 칸을 닫고(붙어 있던 attach만 끝남) 그 세션에 herdr.space/tab 라벨을 다시 붙이면 Herdr가 탭에 다시 붙인다.
# 모두 pane id·terminal id를 지정해서 부르므로 화면 포커스와 상관없다.
H() { env -u HC_TERMINAL_ID -u HC_SCOPE hc "$@"; }
PHFILE=$(mktemp)  # ph는 $( )(하위 셸) 안에서 불리므로 빈 칸 목록을 파일에 모은다

pane_of() { $PYT pane $TAB "$1"; }

readopt() { # readopt <space id> <이름...> — 래퍼 칸으로만 보이는 세션을 진짜 칸으로
  local sp=$1; shift; local n f p kind
  for n in $@; do
    f=$($PYT find "$n" 2>/dev/null) || continue
    read -r _ _ p kind <<<"$f"
    [[ $kind == wrapper ]] || continue
    herdr-app do pane.close "{\"pane\":\"$p\"}" >/dev/null
    H label "$n" herdr.space=$sp herdr.tab=$TAB >/dev/null
    for i in {1..20}; do /bin/sleep 0.5; f=$($PYT find "$n" 2>/dev/null) && [[ ${f##* } == direct ]] && break; done
    [[ ${f##* } == direct ]] && echo "진짜 칸으로 되돌림: $n" || { echo "FAIL: $n 을 탭에 다시 못 붙임" >&2; return 1; }
  done
}

ph() { # ph <기준 pane> <right|down> -> 새 빈 칸 id (1시간 뒤 스스로 끝나서 남아도 사라짐)
  local p; p=$(herdr-app do pane.split "{\"direction\":\"$2\",\"pane\":\"$1\",\"argv\":[\"sleep\",\"3600\"]}" | jq -er .pane) || return 1
  echo $p >> $PHFILE; echo $p
}

put() { # put <세션 이름> <빈 칸> — 진짜 칸을 빈 칸 자리로
  local real; real=$(pane_of "$1") || { echo "FAIL: $1 칸이 이 탭에 없음" >&2; return 1; }
  [[ $real == $2 ]] || herdr-app do pane.swap "{\"pane\":\"$real\",\"target\":\"$2\"}" >/dev/null
}

finish() { # finish <원하는 이름...> — 빈 칸 닫기, 그 밖의 칸은 park
  local p b keep=" $* "
  for p in $(<$PHFILE); do herdr-app do pane.close "{\"pane\":\"$p\"}" >/dev/null; done
  : > $PHFILE; /bin/sleep 0.5
  $PYT shape-blocks $TAB | while read -r p t name wrapper; do
    [[ $keep == *" $name "* ]] && continue
    if [[ $wrapper == true ]]; then herdr-app do pane.close "{\"pane\":\"$p\"}" >/dev/null
    else herdr-app do terminal.park "{\"terminal\":\"$t\"}" >/dev/null; echo "park(계속 돎): ${name:-$t}"; fi
  done
}

# 중간에 실패해도 빈 칸을 남기지 않는다
trap 'for _p in $(<$PHFILE); do herdr-app do pane.close "{\"pane\":\"$_p\"}" >/dev/null 2>&1; done; rm -f $PHFILE' EXIT
