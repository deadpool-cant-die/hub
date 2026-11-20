---
name: deadpools-mods-help
description: 내가 만든 Claude Code mod(~/.claude/my-mods) 목록 — 패널·탭·상태 표시 등 무엇이고, 여는 법(슬래시 명령)과 쓰는 법. Trigger words - /hub:deadpools-mods-help, 모드 뭐 있어, mod 목록, 패널 여는 법, 내 모드 도움말.
---

# 내 mod 목록 (hub:deadpools-mods-help)

> `HUB_SCRIPTS` = 이 플러그인의 `scripts/`(이 스킬 폴더 기준 `../../scripts`).

공통: 답은 짧게, 쉬운 한국어, 맨 앞에 `[HUB]`. 실제로 읽은 것만 쓴다.

```sh
${HUB_SCRIPTS}/list-mods.sh     # 이름 · 버전 · 켜짐 · 슬래시 명령 · 패널 제목 · 스킬 수 · 설명
```

## 쓰는 법을 더 알아야 하면
그 mod 폴더(`~/.claude/my-mods/mods/<이름>/`)의 `hooks/register.tsx` 맨 위 주석과 `command.register`·`ui.open` 부분만 읽는다(코드 전체를 설명하지 않음). 패널 안 버튼·단축키가 주석에 있으면 그것까지.

## 답
```
[HUB] 내 mod N개
<이름> (vX, 켜짐) — <무엇 한 줄>
  열기: /<명령>   패널: <제목>
  쓰는 법: <한두 줄>
…
세션 폴더 mod(그 세션에서만): <이름들> — 전역으로 옮기려면 my-mods로(메모리 feedback-mods-global-default)
```
- 바꾼 뒤 반영은 `/reload-plugins`(전 세션은 `/hub:reload-all-session-plugin`).
