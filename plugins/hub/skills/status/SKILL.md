---
name: status
description: 지금 Orca에 떠 있는 에이전트를 봇별로 한눈에 — 어디(봇 home·워크스페이스), 에이전트, 제목, 상태(일하는 중·막힘·끝남), 핀, 마지막으로 한 말. 읽기만 한다. Trigger words - hub status, 세션 현황, 누가 떠 있어, 다들 뭐 해, 지금 뭐 돌아, 세션 목록, 봇 현황, 막힌 거 있어.
---

# 세션 현황 (읽기만)

> `HUB_SCRIPTS` = 이 플러그인의 `scripts/` 폴더(이 스킬 폴더 기준 `../../scripts`). 예: `HUB_SCRIPTS=<스킬 Base directory>/../../scripts`

```sh
python3 -I ${HUB_SCRIPTS}/status.py [봇 이름]
```
- `orca bot list`·`orca worktree ps`·`orca agent list`를 합쳐 봇마다(`[bot:<이름>]`, 봇 밖은 `[봇 없음]`) 에이전트 한 줄씩, 최근 순.
- 한 줄: 어디(`home` = 봇 자기 채팅, 아니면 워크스페이스 이름), 에이전트(claude·codex), 제목, 상태, 📌 핀, 마지막으로 한 말 70자.
- 상태: ▶ 일하는 중 / ■ 막힘·답 기다림(사람 답 필요) / ✓ 끝남. 봇이 멈춰 있으면 `(멈춤)`.

## 답하는 법
1. **막힘(■)부터** — 어느 봇 누가 왜 막혔는지(`orca agent read <orca_session_id> --limit 10`, worker면 `orca orchestration worker-read --dispatch <id>`).
2. **일하는 중(▶)** — 봇 / 이름 / 하는 일 한 줄.
3. 끝남은 개수만, 사용자가 물으면 펼친다.

할 일 목록(TODO.md)과 대조가 필요하면 `hub:what-should-i-do`.
