---
name: restore-everything
description: 꺼졌거나 망가진 Hub 되살리기 — Orca는 봇 채팅이 남으므로 봇 목록·worker 상태를 확인하고, 멈춘 봇·끊긴 worker·꺼진 감시 작업만 다시 맞추고 확인. Herdr 시절 relaunch 방법도 남겨 둠. Trigger words - /hub:restore-everything, 다 살려, 다 꺼졌어, 복구해, 원래대로, 세션 다시 켜, 봇 없어졌어.
---

# 되살리기 (hub:restore-everything)

> 같은 폴더에 `reference.local.md`가 있으면 먼저 읽는다(회사·이 컴퓨터 전용: 레포·도구 경로·사람·채팅 번호). 공개 사본엔 없다.
> `HUB_SCRIPTS` = 이 플러그인의 `scripts/`(이 스킬 폴더 기준 `../../scripts`).

공통: 답은 짧게, 쉬운 한국어, 맨 앞에 `[HUB]`(레포 하나 얘기면 `[레포이름]`). **실제로 확인한 사실만** 쓴다(이슈 트래커, git, gh, orca, 메모리, TODO.md). 확인 못 한 건 "확인 못 함"이라고 적는다.

## 1. 비교 (먼저 보여 줌)
Orca는 앱을 다시 켜도 **봇 채팅과 기록이 남는다.** 그래서 "다시 켜기"보다 "봇 목록·worker 상태 확인"이 먼저다.
- 앱: `orca status`가 안 되면 사용자에게 Dock에서 Orca를 열어 달라고 한다(에이전트 셸에서 띄우지 않음).
- 명단: 공용 메모리 최신 `reference-hub-sessions-*.md`(봇·worker 이름·워크스페이스·dispatch).
- 실제: `orca bot list`(봇·멈춤 여부), `orca orchestration worker-list`(worker·터미널 상태), `python3 -I ${HUB_SCRIPTS}/status.py`(봇별 에이전트).
- 명단에만 있고 지금 없는 worker는 일부러 닫은 것(`kill-slacker-sessions`·`dont-waste-sessions` 로그)일 수 있다. "닫은 기록 있음"으로 표시하고 다시 켜기 전에 사용자에게 확인한다.
- 표로: `이름 / 봇 / 지금(열림·끝남·닫힘·봇 멈춤) / 할 일`.

## 2. 다시 맞추기
- 봇이 없으면: 봇 채팅에서 `orca bot create --offer --name <이름> --purpose "<한 문장>"`(사용자가 카드에서 승인해야 만들어짐).
- 봇이 멈춰 있으면(`(멈춤)`): 사용자에게 알린다(풀지 말지는 사용자가).
- 일이 안 끝났는데 worker가 닫혔으면: 그 봇에 `orca orchestration send --to bot:<이름> --type handoff …`로 이어서 하라고 보낸다(봇이 새 worker를 켬). 같은 일을 두 곳에서 하지 않게 먼저 `worker-list`로 확인.
- 금지: 같은 일을 worker 둘에게, 화면 포커스 이동(`--focus`, `orca terminal switch`).

## 3. 배치
- Orca엔 칸 배치가 없다. Herdr를 아직 쓰면 아래 "(Herdr 시절)".

## 4. 감시 작업
- 메신저 1분 감시(launchd, 이름은 `reference.local.md`): `launchctl list | grep <이름>` 없으면 도구의 `watch on`.
- 세션 안 Monitor로 돌던 감시(예: 리뷰 에이전트 채팅 감시)는 그 세션이 다시 켜지면 **첫 일로 다시 켜라고** 그 세션에 한 줄 보낸다.

## 5. 확인·보고
`orca bot list`·`python3 -I ${HUB_SCRIPTS}/status.py`로 봇마다 보이는지 본다.
```
[HUB] 되살림: 이어 보냄 N(<봇>…) / 그대로 M / 실패 K(<이름> — <이유>)
봇: <n>개 ✓ (멈춤 <이름>)   감시: <이름> ✓
```
시험할 땐 1절 표만 출력하고 2~4절은 "할 일"로만 적는다.

## (Herdr 시절) 세션 다시 켜기
- 명단 표의 꺼진 세션마다 `${HUB_SCRIPTS}/relaunch.sh <이름>`(같은 대화가 이미 떠 있으면 거부), 자기 자신은 맨 마지막. 살아 있는 이름은 `hc ls --json`, 탭·칸은 `${HUB_SCRIPTS}/ids.sh Hub`.
- 탭이 없으면 `herdr-app do tab.new '{"name":…,"space":…,"focus":false}'`, 배치는 `tower-layout.sh`·`tab-layout.sh <tab id>`(`hub:layout`).
- 금지: `hc attach` 래퍼 칸, 같은 resume id 두 곳.
