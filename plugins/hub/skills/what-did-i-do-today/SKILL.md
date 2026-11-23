---
name: what-did-i-do-today
description: 오늘 한 일 보기 — 레포·PR·배포·이슈 트래커·문서·디자인 게시를 시간순으로, 끝난 것 / 진행 중 / 기다림으로 나눠. Trigger words - /hub:what-did-i-do-today, 오늘 뭐 했지, 오늘 한 일, 오늘 정리, 하루 정리.
---

# 오늘 한 일 (hub:what-did-i-do-today)

> 같은 폴더에 `reference.local.md`가 있으면 먼저 읽는다(회사·이 컴퓨터 전용: 레포·도구 경로·사람·채팅 번호). 공개 사본엔 없다.
> `HUB_SCRIPTS` = 이 플러그인의 `scripts/`(이 스킬 폴더 기준 `../../scripts`).

공통: 답은 짧게, 쉬운 한국어, 맨 앞에 `[HUB]`(레포 하나 얘기면 `[레포이름]`). **실제로 확인한 사실만** 쓴다(이슈 트래커, git, gh, orca, 메모리, TODO.md). 확인 못 한 건 "확인 못 함"이라고 적는다.

## 모으기 (읽기만, 오늘 00:00부터)
- 커밋·PR: 레포마다 `git log --since=midnight --all --format='%ci %h %s'`, `gh pr list --author @me --state all --search "updated:>=<오늘>"` (머지 시각 포함).
- 배포: `gh run list --created ">=<오늘>"`, 오늘 만든 태그.
- 이슈 트래커: 오늘 내가 단 댓글·상태 변경.
- 문서: 업무 문서 폴더·`$HUB_PRIVATE`에서 오늘 바뀐 파일(`find … -newermt <오늘>`).
- 디자인 게시: 디자인 서버에 오늘 올린 페이지(탭 README·보고 기록).
- `~/Hub/TODO.md` 오늘 절·끝 절.

## 답
```
[HUB] 오늘 (MM-DD)
끝남
  HH:MM <레포/도구> <무엇> (<PR·태그·티켓>)
진행 중
  <무엇> — <담당 세션> <단계>
기다림
  <무엇> — <누구 답>
```
시간순. 같은 일은 한 줄로 묶는다. 시각을 모르면 시각을 빼고 적는다.
