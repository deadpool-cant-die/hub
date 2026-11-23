---
name: kill-slacker-sessions
description: 일 없이 대기 중인 세션 정리 — orca orchestration worker-list·orca agent list에서 끝난 worker·터미널 중 열린 일·맡은 PR·사용자 결정 대기가 없는 것만 골라, 이름·워크스페이스·dispatch를 세션 명단 메모리에 남기고 닫음(worker-stop·worker-release·terminal close). 봇 채팅·일하는 것·사용자 셸은 안 닫음. Trigger words - /hub:kill-slacker-sessions, 노는 세션 꺼, 세션 정리해, 대기 세션 지워, 세션 너무 많아.
---

# 노는 세션 정리 (hub:kill-slacker-sessions)

> 같은 폴더에 `reference.local.md`가 있으면 먼저 읽는다(회사·이 컴퓨터 전용: 레포·도구 경로·사람·채팅 번호). 공개 사본엔 없다.
> `HUB_SCRIPTS` = 이 플러그인의 `scripts/`(이 스킬 폴더 기준 `../../scripts`).

공통: 답은 짧게, 쉬운 한국어, 맨 앞에 `[HUB]`(레포 하나 얘기면 `[레포이름]`). **실제로 확인한 사실만** 쓴다(이슈 트래커, git, gh, orca, 메모리, TODO.md). 확인 못 한 건 "확인 못 함"이라고 적는다.

`hub:dont-waste-sessions`(시간 기준 자동)와 달리, **지금 한 번** "맡은 일이 없는" 세션을 고른다.

## 1. 후보
```sh
DWS_IDLE_MIN=0 python3 -I ${HUB_SCRIPTS}/dont_waste_sessions.py sweep --dry-run
```
→ 이미 빠지는 것: 봇 채팅(Orca 채팅 전부), 봇 home, 핀 꽂은 워크스페이스, working·blocked·waiting, 일이 안 끝난 worker, 사람 답 기다리는 worker, 질문 화면, 에이전트 아닌 셸, 부른 세션 자신.
직접 보려면: `orca orchestration worker-list`(worker와 터미널 상태), `orca agent list --state done`.

## 2. 더 걸러내기 (후보마다)
- `~/Hub/TODO.md`에 이 세션 이름이 `[~]`·`[?]`·`[!]` 항목의 담당으로 있으면 남긴다.
- 그 세션 폴더 레포에 내가 연 PR이 열려 있으면(`gh pr list --author @me --state open`) 남긴다.
- 마지막 답(worker는 `orca orchestration worker-read --dispatch <id>`, 그 밖은 `orca agent read <orca_session_id> --limit 5`)이 사용자 결정·승인을 기다리면 남긴다.

## 3. 끄기 (사용자가 확인한 뒤에만)
1. 닫을 목록을 먼저 보여 준다: `이름 / 봇 / 워크스페이스 / 남길 이유 없음 근거`.
2. 확인되면 세션 명단 메모리(`reference-hub-sessions-<오늘>.md`, 없으면 최근 것을 복사해 새로)에 각 세션의 이름·도구·모델·봇·워크스페이스·dispatch id를 적는다(닫아도 `worker-read`로 출력은 읽힘).
3. `hub:session` 4절대로: 일이 끝난 worker는 `orca orchestration worker-release --dispatch <id>`, 안 끝난 worker는 `worker-stop --dispatch <id>`(helper까지 멈춤), 봇 밖 터미널은 `orca terminal close --terminal <handle>` → `orca orchestration worker-list`·`orca agent list`로 다른 것들이 그대로인지 확인.

## 답
```
[HUB] 정리 후보 N개 (안 끔 — "꺼"라고 하면 끔)
- <이름> <봇> <워크스페이스> — <근거>
남김: <이름> — <이유> …
```
끈 뒤에는 `[HUB] 끔 N개: … / 명단 메모리 <파일>`.
