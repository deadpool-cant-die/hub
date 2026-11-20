#!/bin/zsh
# my-mods(전역 Claude Code mod)와 세션 폴더 dev-mods 목록: 이름 · 버전 · 켜짐 · 슬래시 명령 · 패널 제목 · 설명. 읽기만.
MM=${MY_MODS:-$HOME/.claude/my-mods}
plist=$(claude plugin list --json 2>/dev/null)
jq -r '.plugins[]|"\(.name)\t\(.source)"' $MM/.claude-plugin/marketplace.json | while IFS=$'\t' read n src; do
  d=$MM/${src#./}; v=$(jq -r '.version // "?"' $d/.claude-plugin/plugin.json 2>/dev/null)
  on=$(jq -r --arg id "$n@my-mods" '.[]|select(.id==$id)|if .enabled then "켜짐" else "꺼짐" end' <<<"$plist"); on=${on:-설치 안 됨}
  cmds=$(grep -ho "command.register({ name: '[^']*'" $d/hooks/*.tsx 2>/dev/null | sed "s/.*name: '//;s/'$//" | sed 's#^#/#' | paste -sd' ' -)
  panes=$(grep -ho "title: '[^']*'" $d/hooks/*.tsx 2>/dev/null | sed "s/title: '//;s/'$//" | sort -u | paste -sd',' -)
  skills=$(ls $d/skills 2>/dev/null | wc -l | tr -d ' ')
  desc=$(jq -r '.description // ""' $d/.claude-plugin/plugin.json 2>/dev/null | cut -c1-90)
  print -r -- "$n	$v	$on	명령:${cmds:-없음}	패널:${panes:-없음}	스킬:$skills	$desc"
done
dm=(${(f)"$(ls -d $HOME/.claude/dev-mods/*/*/(N) 2>/dev/null | xargs -n1 basename 2>/dev/null | sort -u)"})
(( ${#dm} )) && echo "(세션 폴더 dev-mods ${#dm}종: 만든 세션에서만 로드 — ${dm[*]})"
