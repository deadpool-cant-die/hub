---
name: dont-waste-sessions
description: 놀고 있는 에이전트 세션을 주기적으로 찾아 끄는 감시를 켜고 끈다. "/dont-waste-sessions on [분]", "off", "status", "dry-run". 핀·tower·head·일하는 중·사용자 답 대기·자식 있는 세션은 안 끄고, 끈 세션은 resume id를 로그에 남긴다. Trigger words - /hub:dont-waste-sessions, dont-waste-sessions, 노는 세션 꺼, 안 쓰는 세션 정리, 세션 너무 많아, 세션 낭비, 컴퓨터 느려.
---

# 노는 세션 끄기

> `HUB_SCRIPTS` = 이 플러그인의 `scripts/` 폴더(이 스킬 폴더 기준 `../../scripts`). 예: `HUB_SCRIPTS=<스킬 Base directory>/../../scripts`

사용자가 `on [분]` / `off` / `status` / `dry-run` 중 하나를 말하면 그대로 실행하고 결과 한 줄을 알린다.

```sh
${HUB_SCRIPTS}/dont-waste-sessions.sh on [분]   # 기본 30분 간격(최소 5분)
${HUB_SCRIPTS}/dont-waste-sessions.sh off
${HUB_SCRIPTS}/dont-waste-sessions.sh status    # 켜졌는지 + 최근 끈 5개
${HUB_SCRIPTS}/dont-waste-sessions.sh dry-run   # 지금 끌 대상만(아무것도 안 끔)
```

- `on`은 부모 없는 터미널 `dont-waste-sessions` 하나를 띄워 [분]마다 훑는다(이 세션이 꺼져도 계속 돎). 다시 `on`하면 새 간격으로 바꾼다.
- 처음 켜기 전에 `dry-run`으로 대상이 맞는지 한 번 보여 준다.

## 끄는 기준 (기본값)
| 항목 | 값 |
|---|---|
| 대상 | 이름 있는 에이전트 세션(Claude Code·Codex 등 상태를 알리는 것) |
| 놀고 있음 | 상태 idle 또는 done(끝났는데 아직 안 봄), 마지막 상태 변화 후 **120분 이상** (`DWS_IDLE_MIN`) |
| 안 끔 | 핀(📌), tower 탭 칸·hub-* tower 이름, 이름이 `-head`로 끝나는 칸, working·blocked, 화면이 질문을 띄운 상태(선택지·y/n·폴더 신뢰·훅·업데이트), 자식 세션이 있는 것, 부른 세션 자신 |
| 끄는 법 | `hc kill`(대화 기록은 남음) |
| 로그 | `$HUB_PRIVATE/scripts/dont-waste-sessions.log` (`DWS_LOG`): 시각·이름·idle 분·resume id·폴더·탭 |

꺼진 세션 되살리기: `relaunch.sh <이름>`(`hub:session`). 살아 있지 않으면 세션 명단 표에서 찾으니, 로그의 resume id가 표와 다르면 표를 먼저 고친다.

## 주의
- 사용자가 글로만 질문하고 끝난 세션(선택지 화면 없이 "할까요?")은 idle로 보인다. 120분 기준이 그 여유다. 더 짧게 하려면 사용자 확인 후 `DWS_IDLE_MIN`을 바꿔 `on`.
- "멈춰" 지시가 오면 `off`도 한다.
