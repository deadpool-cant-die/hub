---
name: hub-onboarding
description: hub를 처음 깐 사람을 단계별로 안내 — 필요한 도구 확인, 세션 하나 켜 보기, 탭 배치, 주요 스킬 5개 맛보기, 토큰을 많이 쓴다는 주의. Trigger words - /hub:hub-onboarding, hub 처음, 온보딩, 시작하기, 처음 써 봐, 어떻게 시작해.
---

# hub 시작하기 (hub:hub-onboarding)

> `HUB_SCRIPTS` = 이 플러그인의 `scripts/`(이 스킬 폴더 기준 `../../scripts`).

처음 쓰는 사람 기준. **한 단계씩** 하고, 단계마다 결과를 보여 준 뒤 "다음으로 갈까요?"라고 묻는다. 쉬운 한국어, 짧게, 맨 앞에 `[HUB]`. 사용자가 보고 있는 화면을 바꾸는 명령(탭 고르기·창 앞으로)은 쓰지 않는다 — 결과는 탭 이름으로 알려 준다.

## 0. 먼저 알릴 것 (꼭)
> hub는 여러 에이전트 세션을 동시에 띄우고 서로 보고·감시하게 하는 방식이라 **토큰을 많이 씁니다.** 아직 토큰 최적화를 하지 않았어요. 사용량·요금을 보면서 쓰세요. 세션 수는 처음엔 2~3개로 시작하는 걸 권해요.

## 1. 필요한 도구 확인
```sh
for t in claude herdr-app hc git python3 jq gh; do command -v $t >/dev/null && echo "✓ $t" || echo "✗ $t"; done
herdr-app --version; hc --version
```
- 없으면 무엇을 깔아야 하는지 한 줄씩(Herdr 앱: `curl -fsSL https://releases.herdr.dev/app/install.sh | sh` 후 앱을 Dock/Finder에서 한 번 열기, `jq`·`gh`: Homebrew). Herdr가 없으면 2~3단계는 건너뛰고 4단계로.
- 비공개 폴더: `${HUB_SCRIPTS}/hub-env.sh`를 읽어 `HUB_PRIVATE`(기본 `~/.hub`)가 어디인지 알려 준다. 바꾸고 싶으면 `~/.config/hub/config`에 `HUB_PRIVATE=<경로>` 한 줄.

## 2. 세션 하나 켜 보기
1. Hub 스페이스·시험 탭 만들기(화면은 안 바뀜):
   ```sh
   herdr-app do space.new '{"name":"Hub","folder":"'"$HOME"'","focus":false}'    # 이미 있으면 건너뜀
   herdr-app do tab.new '{"name":"hub 시험","space":"<Hub 스페이스 id>","focus":false}'
   ${HUB_SCRIPTS}/ids.sh Hub "hub 시험"     # space·tab id
   ```
2. 가벼운 모델로 일회용 세션 하나:
   ```sh
   ${HUB_SCRIPTS}/launch.sh try-worker "$HOME" <space id> <tab id> haiku low "시험 세션이다. 'ok'라고만 답해."
   ```
3. `hc get try-worker`로 부모 없음(`parent: null`), `ids.sh`로 그 탭 칸에 이름·app이 보이는지 확인. 사용자에게 "Herdr 앱의 'hub 시험' 탭을 열어 보세요"라고만 알린다.
- 배울 점: 세션은 이름으로 부른다(`hc send try-worker "…"`, `hc read try-worker`), 장기 세션은 부모 없이 켠다 → `/hub:session`.

## 3. 탭 배치
같은 탭에 세션을 하나 더 켜고(`try-head`, 이름이 `-head`로 끝나면 왼쪽), 배치를 맞춘다:
```sh
${HUB_SCRIPTS}/tab-layout.sh --check <tab id>    # 어떻게 다른지
${HUB_SCRIPTS}/tab-layout.sh <tab id>            # 왼쪽 반 head, 오른쪽 worker
```
→ 규칙은 `/hub:layout`.

## 4. 주요 스킬 5개 맛보기 (읽기만 하는 것)
하나씩 직접 불러 보게 한다:
1. `/hub:hub-help` — hub 스킬 전체 목록
2. `/hub:status` — 떠 있는 세션 한눈에
3. `/hub:what-should-i-do` — 할 일 정리(`<Hub 폴더>/TODO.md`가 있으면)
4. `/hub:what-did-i-do-today` — 오늘 한 일(git·PR 기준)
5. `/hub:why-stuck` — 무엇을 기다리는지

## 5. 정리
- 시험 세션 끄기: `hc kill try-worker; hc kill try-head`, 시험 탭 닫기 `herdr-app do tab.close '{"id":"<tab id>","confirmed":true}'`.
- 다음 할 일: Hub 폴더 만들기·tower(관제) 탭 세팅은 `/hub:setup`, 일 맡기기는 `/hub:delegate`.
- 지우고 싶으면: 레포의 `uninstall.sh`(플러그인·마켓플레이스 제거, 폴더는 물어보고 지움).

## 답 (끝날 때)
```
[HUB] 시작하기 끝: 도구 ✓N ✗M · 세션 켜기 ✓ · 배치 ✓ · 스킬 5개 ✓
다음: /hub:setup
```
