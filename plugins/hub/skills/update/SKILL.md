---
name: update
description: hub 플러그인·스킬을 원본 레포와 동기화하고 설치·연결을 갱신한 뒤 떠 있는 모든 세션에 다시 읽힘(reload-all-session-plugin), 바뀐 것 요약. Trigger words - /hub:update, hub 업데이트, 스킬 동기화, 플러그인 갱신, 최신으로.
---

# hub 업데이트 (hub:update)

> `HUB_SCRIPTS` = 이 플러그인의 `scripts/`(이 스킬 폴더 기준 `../../scripts`).

공통: 답은 짧게, 쉬운 한국어, 맨 앞에 `[HUB]`. 실제로 읽은 것만 쓴다.

```sh
${HUB_SCRIPTS}/update.sh --dry-run    # 무엇이 바뀔지만
${HUB_SCRIPTS}/update.sh              # 맞추고 다시 읽히기 (--no-reload: 다시 읽히기 빼기)
```

하는 일:
1. 원본 레포(`HUB_REPO`, 기본 `~/Dev/hub`)를 `git pull --ff-only`(커밋 안 한 변경이 있으면 건너뜀).
2. `skills/`·`scripts/` 비교: 한쪽에만 있으면 복사, 다르면 더 최근에 바뀐 쪽으로. 덮어쓰는 파일은 `~/.agents/disabled/hub-update-<시각>/`에 백업. 지운 파일은 따라 지우지 않는다. 로컬 전용(`hooks/`, `types/`, `*.local.md`, 매니페스트)은 안 건드림.
3. 다른 툴(Codex 등)이 읽는 `~/.agents/skills/hub-<이름>` 심링크 중 빠진 것 추가.
4. `reload-all.sh`로 떠 있는 Claude 세션에 `/reload-plugins`.

**레포 쪽 변경은 커밋·push하지 않는다.** 남으면 "레포에 커밋 안 한 변경 N개"로 알리고, 공개 검사(`scripts/check-public.sh`) → 커밋 → push는 사용자 승인 뒤 따로.

## 답
```
[HUB] 업데이트: pull <커밋> · 로컬→레포 N · 레포→로컬 M · 심링크 +K
다시 읽힘: 완료 a · 대기열 b · 건너뜀 c
레포에 커밋 안 한 변경 N개(승인 뒤 커밋·push) / 없음
```
