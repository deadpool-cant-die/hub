---
name: status
description: 지금 Herdr에 떠 있는 세션을 스페이스·탭별로 한눈에 — 이름, 상태(일하는 중·막힘·끝남·대기), 핀, 지금 하는 일 한 줄. 읽기만 한다. Trigger words - hub status, 세션 현황, 누가 떠 있어, 다들 뭐 해, 지금 뭐 돌아, 세션 목록, 탭 현황, 막힌 거 있어.
---

# 세션 현황 (읽기만)

> `HUB_SCRIPTS` = 이 플러그인의 `scripts/` 폴더(이 스킬 폴더 기준 `../../scripts`). 예: `HUB_SCRIPTS=<스킬 Base directory>/../../scripts`

```sh
python3 -I ${HUB_SCRIPTS}/status.py [스페이스 이름]
```
- 탭마다 칸 순서대로: 주소, 이름(attach 래퍼 칸은 붙은 세션 이름 + `(attach)`, 그 세션의 상태·핀을 보여 줌), 상태, 📌 핀, 에이전트가 알린 지금 하는 일.
- 상태: ▶ 일하는 중 / ■ 막힘(사람 답 필요) / ✓ 끝남(아직 안 봄) / · 대기 / 셸(에이전트 아님).

## 답하는 법
1. **막힘(■)부터** — 어느 탭 누가 왜 막혔는지(`hc read <이름> --lines 40`으로 화면 확인).
2. **일하는 중(▶)** — 이름 / 하는 일 한 줄.
3. 끝남·대기는 개수만, 사용자가 물으면 펼친다.
4. 탭에 칸이 흐트러져 보이면 `hub:layout`의 `--check`로 확인만 하고, 고치는 건 맡은 head·hub-admin에게.

할 일 목록(TODO.md)과 대조가 필요하면 `hub:what-should-i-do`. 세션 명단 표(이름·모델·폴더·resume id)를 남길 땐 공용 메모리 `reference-hub-sessions-<날짜>.md` 형식을 따른다(`relaunch.sh`가 꺼진 세션을 이 표에서 찾음).
