---
name: deadpools-skills-help
description: 이 컴퓨터에 깐 스킬 전부 — ~/.claude/skills, ~/.agents/skills, 설치된 플러그인(pstack·ponytail·unslop·hub 등)의 스킬이 무엇이고 언제 쓰는지. Trigger words - /hub:deadpools-skills-help, 스킬 뭐 깔려 있어, 내 스킬 목록, 스킬 도움말, 어떤 스킬 써.
---

# 깐 스킬 전부 (hub:deadpools-skills-help)

> `HUB_SCRIPTS` = 이 플러그인의 `scripts/`(이 스킬 폴더 기준 `../../scripts`).

공통: 답은 짧게, 쉬운 한국어, 맨 앞에 `[HUB]`. 실제로 읽은 것만 쓴다.

```sh
python3 -I ${HUB_SCRIPTS}/list-skills.py all    # 이름 · 어디서(폴더/플러그인) · 설명, 같은 폴더(심링크)는 한 번
```

## 답
어디서 온 것끼리 묶고, 묶음마다 "언제 꺼내 쓰나" 한 줄. 스킬마다 한 줄(이름 — 언제).
```
[HUB] 깐 스킬 N개
hub 플러그인 (N) — Hub 관제·세션·하루 일 → 자세히는 /hub:hub-help
pstack (N) — 작업 엔진: 큰 일은 poteto-mode, 리뷰는 thermos·interrogate …
  pstack:poteto-mode — 여러 파일·설계·원인 모르는 버그
  …
ponytail (N) — 가장 단순하게: ponytail-review(셀프 리뷰) …
그 밖의 플러그인 (unslop 등)
~/.claude/skills · ~/.agents/skills (N) — 업무 도구: 브라우저·이슈 트래커·사내 망 연결·디자인 서버 …
```
- 많으면(30개 넘는 묶음) 자주 쓰는 것 5~8개만 펼치고 "외 N개"로 줄인다. 사용자가 묶음을 말하면 그 묶음 전체.
- 꺼진 플러그인은 목록에 안 나온다(켜진 것만).
