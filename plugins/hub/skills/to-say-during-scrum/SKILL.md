---
name: to-say-during-scrum
description: 스크럼에서 말할 것 정리 — 어제 한 것 / 오늘 할 것 / 블로커를 각 2~4줄, 티켓 번호 붙여 말하듯이. 이슈 트래커·git·배포 기록으로 확인한 것만. Trigger words - /hub:to-say-during-scrum, 스크럼, 데일리, 스탠드업, 오늘 뭐 말하지, 어제 뭐 했지.
---

# 스크럼 말할 거 (hub:to-say-during-scrum)

> 같은 폴더에 `reference.local.md`가 있으면 먼저 읽는다(회사·이 컴퓨터 전용: 레포·도구 경로·사람·채팅 번호). 공개 사본엔 없다.
> `HUB_SCRIPTS` = 이 플러그인의 `scripts/`(이 스킬 폴더 기준 `../../scripts`).

공통: 답은 짧게, 쉬운 한국어, 맨 앞에 `[HUB]`(레포 하나 얘기면 `[레포이름]`). **실제로 확인한 사실만** 쓴다(이슈 트래커, git, gh, orca, 메모리, TODO.md). 확인 못 한 건 "확인 못 함"이라고 적는다.

## 모으기 (읽기만)
1. 어제·오늘 내 커밋·PR: 쓰는 레포마다 `git log --since="yesterday 00:00" --author=<내 계정> --oneline --all`, `gh pr list --author @me --state all --search "updated:>=<어제>"`.
2. 배포: 레포별 최신 태그·배포 실행(`gh run list -L5`, `git tag --sort=-creatordate | head -3`).
3. 이슈 트래커: 내 티켓 중 어제 이후 바뀐 것과 댓글(진행/다음/블로커).
4. `~/Hub/TODO.md`의 진행·대기 항목.

## 답 (이 모양 그대로)
```
[HUB] 스크럼
어제: ① <한 일> (<티켓>) ② …
오늘: ① <할 일> (<티켓>) ② …
블로커: <누구·무엇 기다림> (<티켓>) / 없음
```
- 각 2~4줄, 말로 읽기 좋게 짧게. 티켓 번호가 없으면 "(티켓 없음)"이라고 붙이고 지어내지 않는다.
- 확인 안 된 진행률·숫자는 넣지 않는다.
