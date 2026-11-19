---
name: what-should-i-do
description: 지금 사용자가 할 일과 Hub 전체 진행 상황을 한 번에 보여 준다 — 할 일 목록(TODO.md), 어디까지 했는지, 사용자가 정하거나 해야 할 것. Trigger words - /hub:what-should-i-do, /what-should-i-do, 뭐 해야 돼, 할 일, 어디까지 했어, 지금 상황, 투두, 남은 거.
---

# 할 일·진행 상황 (hub:what-should-i-do)

사용자가 부르면 아래를 읽고 **짧게** 답한다. 새 일을 시작하거나 세션에 지시하지 않는다(읽기만).

## 읽을 것
1. `~/Hub/TODO.md` — 할 일 목록(정본)
2. `~/.agents/memory/MEMORY.md`에서 최근 `project-paused-work-*`, `reference-hub-sessions-*` 같은 진행 상태 메모리
3. `hc ls` — 지금 돌고 있는(`working`) 세션 이름. **TODO.md의 `[~]` 진행 항목은 담당 세션이 실제로 working인지 대조**해서, 아니면 "멈춤/끝남(표시만 남음)"으로 바로잡아 보여 주고 hub-admin에게 TODO 수정을 알린다.

## 답하는 형식(이 순서, 한국어, 쉬운 말)
1. **지금 사용자가 할 것** — 사용자가 정하거나 직접 해야 하는 것만. 없으면 "없음". 번호를 붙여 한 줄씩(사용자가 "1 ㅇㅇ"처럼 답할 수 있게).
2. **돌아가는 일** — 일 이름 / 담당 세션 / 지금 단계(가능하면 n/m).
3. **끝난 일(오늘)** — 한 줄씩, 많으면 5개까지.
4. **기다리는 일** — 남(결재자·팀원·에이전트)의 답을 기다리는 것.

규칙: 사용자가 중요하지 않다고 했거나 미뤄 둔 항목은 넣지 않는다([[feedback-no-reminding-minor-items]]). 답 맨 앞에 `[HUB]`. 표는 짧을 때만.

세션별 지금 상태가 더 필요하면 `hub:status`(status.sh)를 같이 본다.
