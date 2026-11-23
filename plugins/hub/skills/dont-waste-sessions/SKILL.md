---
name: dont-waste-sessions
description: 놀고 있는 Orca worker·에이전트 터미널을 주기적으로 찾아 닫는 감시를 켜고 끈다. "/dont-waste-sessions on [분]", "off", "status", "dry-run". 봇 채팅·핀·봇 home·일하는 중·사람 답 대기·일이 안 끝난 worker는 안 닫고, 닫은 것은 dispatch·터미널을 로그에 남긴다. Trigger words - /hub:dont-waste-sessions, dont-waste-sessions, 노는 세션 꺼, 안 쓰는 세션 정리, 세션 너무 많아, 세션 낭비, 컴퓨터 느려.
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

- `on`은 지금 워크스페이스에 Orca 터미널 `dont-waste-sessions` 하나를 띄워(`orca terminal create`) [분]마다 훑는다(이 세션이 꺼져도 계속 돎). 다시 `on`하면 새 간격으로 바꾼다. 켠 터미널 handle은 `$HUB_PRIVATE/scripts/dont-waste-sessions.on`.
- 처음 켜기 전에 `dry-run`으로 대상이 맞는지 한 번 보여 준다.

## 끄는 기준 (기본값)
| 항목 | 값 |
|---|---|
| 대상 | worker(`orca orchestration worker-list`)와 봇 밖 에이전트 터미널(`orca agent list`, kind=terminal) |
| 놀고 있음 | worker: 일이 끝났고(completed) 터미널이 아직 열림, 끝난 지 **120분 이상**. 터미널: 상태 done, 마지막 변화 후 **120분 이상** (`DWS_IDLE_MIN`) |
| 안 닫음 | 봇 채팅(Orca 채팅 전부), 핀 꽂은 워크스페이스, 봇 home·봇 워크스페이스의 터미널, working·blocked·waiting, 일이 안 끝난 worker, 사람 답 기다리는 worker, 화면이 질문을 띄운 터미널(선택지·y/n·폴더 신뢰·훅·업데이트), 부른 터미널 자신 |
| 닫는 법 | worker는 `orca orchestration worker-release`(출력은 `worker-read`로 계속 읽힘), 터미널은 `orca terminal close` |
| 로그 | `$HUB_PRIVATE/scripts/dont-waste-sessions.log` (`DWS_LOG`): 시각·종류·이름·idle 분·dispatch/터미널·워크스페이스 |

닫은 일을 이어 하려면 그 봇에 `orca orchestration send --to bot:<이름> --type handoff …`(`hub:session` 3절).

## 주의
- 사용자가 글로만 질문하고 끝난 터미널(선택지 화면 없이 "할까요?")은 done으로 보인다. 120분 기준이 그 여유다. 더 짧게 하려면 사용자 확인 후 `DWS_IDLE_MIN`을 바꿔 `on`.
- "멈춰" 지시가 오면 `off`도 한다.
