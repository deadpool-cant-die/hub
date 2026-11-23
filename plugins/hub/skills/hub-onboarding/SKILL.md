---
name: hub-onboarding
description: hub를 처음 깐 사람을 단계별로 안내 — 필요한 도구(Orca) 확인, worker 하나 켜 보기, 봇 만들기, 주요 스킬 5개 맛보기, 토큰을 많이 쓴다는 주의. Trigger words - /hub:hub-onboarding, hub 처음, 온보딩, 시작하기, 처음 써 봐, 어떻게 시작해.
---

# hub 시작하기 (hub:hub-onboarding)

> `HUB_SCRIPTS` = 이 플러그인의 `scripts/`(이 스킬 폴더 기준 `../../scripts`).

처음 쓰는 사람 기준. **한 단계씩** 하고, 단계마다 결과를 보여 준 뒤 "다음으로 갈까요?"라고 묻는다. 쉬운 한국어, 짧게, 맨 앞에 `[HUB]`. 사용자가 보고 있는 화면을 바꾸는 명령(`--focus`, `orca terminal switch`, 창 앞으로)은 쓰지 않는다 — 결과는 봇·worker 이름으로 알려 준다.

## 0. 먼저 알릴 것 (꼭)
> hub는 여러 에이전트 세션을 동시에 띄우고 서로 보고·감시하게 하는 방식이라 **토큰을 많이 씁니다.** 아직 토큰 최적화를 하지 않았어요. 사용량·요금을 보면서 쓰세요. 세션 수는 처음엔 2~3개로 시작하는 걸 권해요.

## 1. 필요한 도구 확인
```sh
for t in claude orca git python3 jq gh; do command -v $t >/dev/null && echo "✓ $t" || echo "✗ $t"; done
orca --version; orca status
```
- 없으면 무엇을 깔아야 하는지 한 줄씩(Orca 앱: 설치 후 Dock/Finder에서 한 번 열기 — `orca status`가 앱이 떠 있는지 알려 줌, `jq`·`gh`: Homebrew). Orca가 없으면 2~3단계는 건너뛰고 4단계로.
- 비공개 폴더: `${HUB_SCRIPTS}/hub-env.sh`를 읽어 `HUB_PRIVATE`(기본 `~/.hub`)가 어디인지 알려 준다. 바꾸고 싶으면 `~/.config/hub/config`에 `HUB_PRIVATE=<경로>` 한 줄.

## 2. worker 하나 켜 보기
1. 지금 폴더에서 가벼운 모델로 일회용 worker 하나(화면은 안 바뀜):
   ```sh
   orca orchestration worker-start --spec "시험 worker다. 'ok'라고 worker_done으로만 답해." \
     --worktree current --agent claude --model haiku --effort low --json
   ```
2. 받은 `dispatch` id로 확인: `orca orchestration worker-show --dispatch <id>`, 답은 `orca orchestration check --wait`로 받는다.
3. `orca agent list`에 그 worker가 보이는지 보고, 사용자에게 "Orca에서 이 워크스페이스의 새 탭을 열어 보세요"라고만 알린다.
- 배울 점: 말은 `orca orchestration send`로, 다른 에이전트 입력창에 직접 치지 않는다 → `/hub:session`.

## 3. 봇 만들기
봇은 오래 사는 채팅이다(레포 하나·역할 하나). 봇 채팅에서 제안하고 사용자가 카드에서 승인해야 만들어진다:
```sh
orca bot create --offer --name try-bot --purpose "hub 시험용 봇. 읽기만 하고 보고만 한다."
orca bot list        # 만들어졌는지, 주소(bot:try-bot)
```
→ 관제 봇 구성은 `/hub:setup`, 흐름은 `/hub:control`.

## 4. 주요 스킬 5개 맛보기 (읽기만 하는 것)
하나씩 직접 불러 보게 한다:
1. `/hub:hub-help` — hub 스킬 전체 목록
2. `/hub:status` — 봇별로 떠 있는 에이전트 한눈에
3. `/hub:what-should-i-do` — 할 일 정리(`<Hub 폴더>/TODO.md`가 있으면)
4. `/hub:what-did-i-do-today` — 오늘 한 일(git·PR 기준)
5. `/hub:how-is-deploy` — 배포 어디까지 갔는지

## 5. 정리
- 시험 worker가 남았으면 끄기: `orca orchestration worker-stop --dispatch <id>`. 시험 봇은 Orca 앱에서 지운다(지우기는 되돌릴 수 없으니 사용자가 직접).
- 다음 할 일: Hub 폴더 만들기·관제 봇 세팅은 `/hub:setup`, 일 맡기기는 `/hub:delegate`.
- 지우고 싶으면: 레포의 `uninstall.sh`(플러그인·마켓플레이스 제거, 폴더는 물어보고 지움).

## 답 (끝날 때)
```
[HUB] 시작하기 끝: 도구 ✓N ✗M · worker 켜기 ✓ · 봇 ✓ · 스킬 5개 ✓
다음: /hub:setup
```
