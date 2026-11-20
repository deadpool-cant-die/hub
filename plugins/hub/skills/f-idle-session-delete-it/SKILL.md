---
name: f-idle-session-delete-it
description: 일 없이 대기 중인 세션 정리 — hc ls에서 대기 세션 중 열린 일·맡은 PR·사용자 결정 대기가 없는 것만 골라, resume id·폴더·탭을 세션 명단 메모리에 남기고 끔. tower·일하는 세션·사용자 셸은 안 끔. Trigger words - /hub:f-idle-session-delete-it, 노는 세션 꺼, 세션 정리해, 대기 세션 지워, 세션 너무 많아.
---

# 노는 세션 정리 (hub:f-idle-session-delete-it)

> 같은 폴더에 `reference.local.md`가 있으면 먼저 읽는다(회사·이 컴퓨터 전용: 레포·도구 경로·사람·채팅 번호). 공개 사본엔 없다.
> `HUB_SCRIPTS` = 이 플러그인의 `scripts/`(이 스킬 폴더 기준 `../../scripts`).

공통: 답은 짧게, 쉬운 한국어, 맨 앞에 `[HUB]`(레포 하나 얘기면 `[레포이름]`). **실제로 확인한 사실만** 쓴다(이슈 트래커, git, gh, hc, 메모리, TODO.md). 확인 못 한 건 "확인 못 함"이라고 적는다.

`hub:dont-waste-sessions`(시간 기준 자동)와 달리, **지금 한 번** "맡은 일이 없는" 세션을 고른다.

## 1. 후보
```sh
DWS_IDLE_MIN=0 python3 -I ${HUB_SCRIPTS}/dont_waste_sessions.py sweep --dry-run
```
→ 이미 빠지는 것: 핀(tower 4칸 포함), tower 이름, `-head`, working·blocked, 질문 화면, 자식 있는 세션, 이름 없는 칸(사용자 셸·이름 없는 Claude), 부른 세션 자신.

## 2. 더 걸러내기 (후보마다)
- `~/Hub/TODO.md`에 이 세션 이름이 `[~]`·`[?]`·`[!]` 항목의 담당으로 있으면 남긴다.
- 그 세션 폴더 레포에 내가 연 PR이 열려 있으면(`gh pr list --author @me --state open`) 남긴다.
- 세션 화면 마지막 답(`hc read <이름> --lines 30`)이 사용자 결정·승인을 기다리면 남긴다.

## 3. 끄기 (사용자가 확인한 뒤에만)
1. 끌 목록을 먼저 보여 준다: `이름 / 폴더 / 탭 / 남길 이유 없음 근거`.
2. 확인되면 세션 명단 메모리(`reference-hub-sessions-<오늘>.md`, 없으면 최근 것을 복사해 새로)에 각 세션의 이름·도구·모델·폴더·탭·resume id를 적는다. `relaunch.sh <이름>`이 이 표로 되살린다.
3. `hub:session` 5절대로: 자식 확인 → `hc kill <이름>` → `hc ls`로 다른 세션 그대로인지 확인.

## 답
```
[HUB] 정리 후보 N개 (안 끔 — "꺼"라고 하면 끔)
- <이름> <폴더> <탭> — <근거>
남김: <이름> — <이유> …
```
끈 뒤에는 `[HUB] 끔 N개: … / 명단 메모리 <파일>`.
