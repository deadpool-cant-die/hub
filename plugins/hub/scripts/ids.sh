#!/bin/zsh
# (Herdr 시절) Herdr 앱 전용 — Orca엔 해당 없음(hub:session). Herdr를 끌 때 지운다.
# usage: ids.sh [스페이스 이름] [탭 이름 일부]
# Herdr 앱의 스페이스·탭·칸 id를 출력한다. 인수 없으면 전부.
herdr-app ls | SP="${1:-}" TB="${2:-}" python3 -c '
import json,sys,os
sp,tb=os.environ["SP"],os.environ["TB"]
for s in json.load(sys.stdin)["spaces"]:
  if sp and s.get("name")!=sp: continue
  for t in s["tabs"]:
    if tb and tb not in (t.get("name") or ""): continue
    print("space=%s tab=%s name=%s" % (s["id"], t["id"], t.get("name")))
    for x in t.get("terminals",[]):
      print("  %s pane=%s name=%s app=%s status=%s" % (x.get("terminal"), x.get("pane"), x.get("name"), x.get("app"), x.get("status")))
'
