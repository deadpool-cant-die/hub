#!/bin/zsh
# hub 플러그인을 원본 레포(공개 skills 레포 사본)와 맞추고, 설치·연결을 갱신하고, 떠 있는 세션에 다시 읽힌다.
#   1) 원본 레포 git pull --ff-only (작업 중 변경이 없을 때만)
#   2) skills/·scripts/ 파일을 양쪽 비교: 한쪽에만 있으면 복사, 둘 다 있는데 다르면 더 최근에 바뀐 쪽이 이긴다
#      (덮어쓰는 파일은 먼저 백업). 지운 파일은 따라 지우지 않고 알리기만. 로컬 전용(hooks/, types/, *.local.md, 매니페스트)은 안 건드림
#   3) 다른 툴(Codex 등)이 읽는 ~/.agents/skills/hub-<이름> 심링크 중 빠진 것 추가
#   4) reload-all.sh 로 떠 있는 Claude 세션에 /reload-plugins
# 레포 쪽에 생긴 변경은 커밋·push하지 않는다(공개 검사 → 커밋 → push는 따로, 승인 뒤).
# usage: update.sh [--dry-run] [--no-reload]     환경: HUB_REPO(기본 ~/Dev/skills), HUB_LOCAL(기본 이 플러그인 폴더)
D=${0:A:h}; LOCAL=${HUB_LOCAL:-${D:h}}; REPO=${HUB_REPO:-$HOME/Dev/skills}; RP=$REPO/plugins/hub
dry=; reload=1; for a in $@; do [[ $a == --dry-run ]] && dry=1; [[ $a == --no-reload ]] && reload=; done
BK=$HOME/.agents/disabled/hub-update-$(date +%Y%m%d-%H%M%S)
say() { print -r -- "$*"; }
[[ -d $RP ]] || { say "FAIL: 원본 레포 없음 ($RP)"; exit 1; }

# 1) pull
if [[ -n $(git -C $REPO status --porcelain) ]]; then say "pull 건너뜀: 레포에 커밋 안 한 변경 있음"
elif [[ -n $dry ]]; then say "pull: (dry-run) git -C $REPO pull --ff-only"
else out=$(git -C $REPO pull --ff-only -q 2>&1) && say "pull: $(git -C $REPO log -1 --format='%h %s')" || say "pull 실패: $out"; fi

# 2) 비교·복사
mtime() { stat -f %m "$1"; }
cp_bk() { # cp_bk <원본> <대상>
  if [[ -e $2 ]]; then mkdir -p "$BK/${2:h}"; cp -p "$2" "$BK/$2"; fi
  mkdir -p "${2:h}"; cp -p "$1" "$2"; }
changed=0
for sub in skills scripts; do
  files=(${(f)"$( { cd $LOCAL && find $sub -type f; cd $RP && find $sub -type f; } | grep -vE '\.local\.md$|__pycache__|\.pyc$' | sort -u)"})
  for f in $files; do
    l=$LOCAL/$f r=$RP/$f
    if [[ ! -e $l ]]; then say "  레포→로컬 (새 파일) $f"; [[ -z $dry ]] && cp_bk $r $l; ((changed++))
    elif [[ ! -e $r ]]; then say "  로컬→레포 (새 파일) $f"; [[ -z $dry ]] && cp_bk $l $r; ((changed++))
    elif ! cmp -s $l $r; then
      if (( $(mtime $l) >= $(mtime $r) )); then say "  로컬→레포 (로컬이 더 새것) $f"; [[ -z $dry ]] && cp_bk $l $r
      else say "  레포→로컬 (레포가 더 새것) $f"; [[ -z $dry ]] && cp_bk $r $l; fi
      ((changed++))
    fi
  done
done
(( changed )) || say "  skills·scripts 같음"
[[ -d $BK ]] && say "  덮어쓴 파일 백업: $BK"
[[ -z $dry ]] && rs=$(git -C $REPO status --porcelain plugins/hub) && [[ -n $rs ]] && say "  레포에 커밋 안 한 변경 $(wc -l <<<"$rs" | tr -d ' ')개 → check-public 뒤 커밋(승인 받고 push)"

# 3) 다른 툴용 심링크
for s in $LOCAL/skills/*(/); do
  ln=$HOME/.agents/skills/hub-${s:t}
  [[ -e $ln ]] && continue
  say "  심링크 추가: $ln"; [[ -z $dry ]] && ln -s $s $ln
done

# 4) 다시 읽히기
if [[ -n $dry || -z $reload ]]; then say "reload: (건너뜀) ${D}/reload-all.sh"
else say "reload:"; $D/reload-all.sh | sed 's/^/  /'; fi
say "버전: 로컬 $(jq -r .version $LOCAL/.claude-plugin/plugin.json) / 레포 $(jq -r .version $RP/.claude-plugin/plugin.json)"
