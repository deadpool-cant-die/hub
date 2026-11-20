---
name: hub-help
description: hub 플러그인 스킬 전체 목록 — 스킬마다 무엇·언제 쓰는지·예시 한 줄. Trigger words - /hub:hub-help, hub 도움말, hub 스킬 뭐 있어, 허브 명령어, 뭐 할 수 있어.
---

# hub 스킬 목록 (hub:hub-help)

> `HUB_SCRIPTS` = 이 플러그인의 `scripts/`(이 스킬 폴더 기준 `../../scripts`).

공통: 답은 짧게, 쉬운 한국어, 맨 앞에 `[HUB]`. 실제로 읽은 것만 쓴다.

```sh
python3 -I ${HUB_SCRIPTS}/list-skills.py hub     # 이름 · hub · 설명
```

목록을 그대로 옮기지 말고 아래 모양으로 정리한다. 설명은 SKILL.md에서 읽은 것, 예시는 사용자가 실제로 칠 말 한 줄.

```
[HUB] hub 스킬 N개
세션·탭
  /hub:session — <무엇> · 예) "worker 하나 켜 줘"
  /hub:layout — …
관제·보고
  …
하루 일
  /hub:to-say-during-scrum · /hub:what-did-i-do-today · …
정리·복구
  …
도움말
  /hub:hub-help · /hub:deadpools-skills-help · /hub:deadpools-mods-help · /hub:update
```
묶음은 스킬 이름·설명을 보고 정한다. 새 스킬이 생겨도 이 파일은 고칠 필요 없다(목록을 매번 읽음).
