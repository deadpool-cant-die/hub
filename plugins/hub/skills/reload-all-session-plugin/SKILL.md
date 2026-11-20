---
name: reload-all-session-plugin
description: 떠 있는 모든 Claude Code 세션에 /reload-plugins를 넣어 플러그인을 다시 읽힘 — Codex·이름 없는 칸·질문 화면은 건너뛰고, 일하는 세션은 지금 일 뒤 실행(대기열), 칸마다 결과 표. Trigger words - /hub:reload-all-session-plugin, 플러그인 다시 읽혀, 전 세션 리로드, reload plugins 다, 스킬 반영해.
---

# 전 세션 플러그인 다시 읽히기 (hub:reload-all-session-plugin)

> `HUB_SCRIPTS` = 이 플러그인의 `scripts/`(이 스킬 폴더 기준 `../../scripts`).

공통: 답은 짧게, 쉬운 한국어, 맨 앞에 `[HUB]`. 화면 포커스는 옮기지 않는다.

슬래시 명령은 세션이 스스로 실행하지 못한다. 그래서 각 세션 입력창에 넣어 준다(`hc send <이름> '/reload-plugins'`).

```sh
${HUB_SCRIPTS}/reload-all.sh --dry-run     # 누구에게 보낼지만
${HUB_SCRIPTS}/reload-all.sh [--skills]    # 보내고 결과 표(--skills면 /reload-skills도)
```

- 건너뜀: Codex 등 다른 앱 칸, 이름 없는 칸(사용자가 직접 쓰는 Claude일 수 있음 — 필요하면 사용자에게 묻기), 질문 화면이 뜬 칸(답을 대신 고르지 않음).
- 일하는 세션: 지금 일을 끊지 않는다. 입력창에 넣어 두면 지금 일이 끝난 뒤 실행되므로 "대기열"로 표시. 부른 세션 자신도 대기열.
- 확인: 보낸 뒤 화면(`hc read`)에서 "Reloaded" 줄을 찾는다. 안 보이면 "확인 못 함".

## 답
```
[HUB] 플러그인 다시 읽힘: 완료 N · 대기열 M · 건너뜀 K · 실패 L
이름 / 상태 / 근거
…
```
