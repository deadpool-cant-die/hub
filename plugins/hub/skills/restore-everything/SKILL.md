---
name: restore-everything
description: 꺼졌거나 망가진 Hub 되살리기 — 세션 명단 메모리와 hc·Herdr 상태를 맞춰 꺼진 세션을 같은 대화(resume)·이름·탭·모델로 다시 켜고, 탭·tower 배치를 맞추고, 감시 작업을 다시 켜고 확인. Trigger words - /hub:restore-everything, 다 살려, 다 꺼졌어, 복구해, 원래대로, 세션 다시 켜, tower 없어졌어.
---

# 되살리기 (hub:restore-everything)

> 같은 폴더에 `reference.local.md`가 있으면 먼저 읽는다(회사·이 컴퓨터 전용: 레포·도구 경로·사람·채팅 번호). 공개 사본엔 없다.
> `HUB_SCRIPTS` = 이 플러그인의 `scripts/`(이 스킬 폴더 기준 `../../scripts`).

공통: 답은 짧게, 쉬운 한국어, 맨 앞에 `[HUB]`(레포 하나 얘기면 `[레포이름]`). **실제로 확인한 사실만** 쓴다(이슈 트래커, git, gh, hc, 메모리, TODO.md). 확인 못 한 건 "확인 못 함"이라고 적는다.

## 1. 비교 (먼저 보여 줌)
- 명단: 공용 메모리 최신 `reference-hub-sessions-*.md`(이름·도구·모델·폴더·탭·resume id).
- 실제: `hc ls --json`(살아 있는 이름), `${HUB_SCRIPTS}/ids.sh Hub`(탭·칸·app·status).
- 명단이 오늘 것이 아니면, 그 뒤에 일부러 끈 세션(정리·`kill-slacker-sessions`·`dont-waste-sessions` 로그)일 수 있다. 그런 세션은 "끈 기록 있음"으로 표시하고 되살리기 전에 사용자에게 확인한다.
- 표로: `이름 / 명단 탭 / 지금(살아 있음·꺼짐·다른 탭·래퍼 칸) / 할 일`.
- 탭 자체가 없으면(예: tower 탭이 닫힘) 먼저 `herdr-app do tab.new '{"name":…,"space":…,"focus":false}'`.

## 2. 다시 켜기
- 꺼진 세션마다 `${HUB_SCRIPTS}/relaunch.sh <이름>`(명단 표에서 모델·폴더·탭·resume id를 읽음, 같은 대화가 이미 떠 있으면 거부).
- 자기 자신(이 세션)은 맨 마지막(relaunch가 응답 끝난 뒤 독립 실행).
- 금지: `hc attach` 래퍼 칸, 같은 resume id 두 곳, 화면 포커스 이동.

## 3. 배치
- tower: `${HUB_SCRIPTS}/tower-layout.sh`(4칸·핀). 일 탭: 탭마다 `${HUB_SCRIPTS}/tab-layout.sh <tab id>`.

## 4. 감시 작업
- 메신저 1분 감시(launchd, 이름은 `reference.local.md`): `launchctl list | grep <이름>` 없으면 도구의 `watch on`.
- 세션 안 Monitor로 돌던 감시(예: 리뷰 에이전트 채팅 감시)는 그 세션이 다시 켜지면 **첫 일로 다시 켜라고** 그 세션에 한 줄 보낸다.

## 5. 확인·보고
`${HUB_SCRIPTS}/ids.sh Hub`로 칸마다 이름·app·status가 보이는지 본다.
```
[HUB] 되살림: 켬 N(<이름>…) / 그대로 M / 실패 K(<이름> — <이유>)
배치: tower ✓ · 탭 <n>/<m> ✓   감시: <이름> ✓
```
시험할 땐 1절 표만 출력하고 2~4절은 "할 일"로만 적는다.
