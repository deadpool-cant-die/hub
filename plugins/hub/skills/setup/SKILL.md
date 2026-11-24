---
name: setup
description: Hub(에이전트 작업 관제 본부)가 무엇이고 어떻게 짜여 있는지, 처음 세팅하는 순서. 기본 구조는 Orca 앱(봇·worker, orca orchestration 메시지)과 ~/Hub 폴더, 관제 봇(secretary·atlassian·resource)과 레포 봇. 권장 도구는 pstack-claude(작업 엔진, poteto-mode)와 ponytail(가장 단순한 해법). 세부 절차는 hub:session·hub:control·hub:delegate·hub:what-should-i-do·hub:status로 넘긴다. Trigger words - hub setup, hub, Hub, 허브, 관제 본부, 허브 세팅, 허브 구조, 허브 처음, orca 세팅, orca 구조, 봇 만들기, 관제 구조, 작업 방식, 어떻게 일해.
---

# Hub — 에이전트 작업 관제 본부

> `HUB_SCRIPTS` = 이 플러그인의 `scripts/` 폴더(이 스킬 폴더 기준 `../../scripts`). 예: `HUB_SCRIPTS=<스킬 Base directory>/../../scripts`

## 1. Hub가 무엇인가

여러 레포에 걸친 일을 에이전트 세션 여러 개로 나눠 돌리는 **관제 본부**다.

- Hub(관제) 세션은 **지시·조율·판단만** 한다. 코드는 고치지 않는다.
- 구현은 각 레포의 **worker** 세션이 실제 레포 폴더에서 한다.
- 사용자는 창구 봇(`bot:secretary`)과만 대화하고, 나머지 봇·worker는 서로 `orca orchestration send`로 메시지를 주고받는다.

## 2. 기본 구조

### Orca 앱
- `orca` CLI — 봇·worker·메시지·터미널. `orca status`(앱이 떠 있는지), `orca bot list`, `orca agent list`, `orca orchestration send|check|reply|worker-start|worker-stop`. 앱을 닫아도 봇 채팅과 기록은 남는다.
- 원본 매뉴얼: `orca <명령> --help`, `orca skills get orchestration`
- Herdr 앱(`herdr-app`, `hc`)을 아직 쓰면 `hub:layout`과 `hub:session`의 "(Herdr 시절)" 절을 본다.

### ~/Hub 폴더
```
~/Hub/
  AGENTS.md   Hub 규칙(관제 원칙, 봇 역할, 문서 지도). CLAUDE.md는 @AGENTS.md
  TODO.md     오늘 할 일 판(관제 봇들이 같이 고침)
  repos/      쓰는 레포 심링크 → ~/Dev/<레포>   (코드는 심링크 말고 실제 폴더에서 고친다)
  docs/       업무 문서·공용 메모리 심링크
  private/    비공개 메모·지시서·스크립트 (git에 안 올림, 비밀값은 위치만 적음)
```

### 관제 봇
| 봇 | 역할 |
|---|---|
| `bot:secretary` | 사용자 창구. 지시를 받아 레포 봇에 나눠 주고, 사용자 승인을 전달하고, 봇 보고를 받는다. TODO.md 관리 |
| `bot:atlassian` | 이슈 트래커(티켓) 반영 전담 |
| `bot:resource` | 컴퓨터가 느려질 때 원인 진단 |

역할 상세는 `~/Hub/AGENTS.md`와 `hub:control`.

### 레포 봇과 worker (봇 하나 = 레포·일 하나)
- 레포마다 봇(`bot:<레포>`)이 관제를 맡고, 구현은 그 봇이 켠 **worker**가 새 워크트리에서 한다(`orca orchestration worker-start --worktree new-child --name <일>-<역할>`).
- 이름은 `<일>-<역할>`(역할: worker·review·shell), 영어 소문자·숫자·`-`만.

## 3. 권장 도구 (Claude Code 플러그인, user 범위)

- **pstack-claude** — 작업 엔진. poteto-mode 원칙으로 일하고, 끝나면 리뷰 스킬(thermos 또는 ponytail-review)로 셀프 리뷰한다. 역할별 모델은 `~/.claude/pstack-models.md`.
  ```sh
  claude plugin marketplace add michael-denyer/pstack-claude
  claude plugin install pstack@pstack-claude --scope user
  ```
- **ponytail** — 가장 단순한 해법 모드(필요 없는 코드·옵션을 안 만듦). `/ponytail lite|full|ultra|off`.
  ```sh
  claude plugin marketplace add DietrichGebert/ponytail
  claude plugin install ponytail@ponytail --scope user
  ```
- 둘 다 **새로 켜는 세션부터** 적용된다. 이미 켜진 세션은 다시 켤 때 적용.

## 4. 처음 세팅 체크리스트

- [ ] Orca 앱 설치 후 Dock·Finder로 한 번 띄우고 `orca --version`, `orca status` 확인(에이전트 셸 안에서 띄우면 환경 변수를 물려받을 수 있음)
- [ ] `~/Hub` 만들기: `mkdir -p ~/Hub/{repos,docs,private}`, `AGENTS.md`(관제 원칙)·`CLAUDE.md`(`@AGENTS.md` 한 줄)·`TODO.md`, `private/`는 `.gitignore`에
- [ ] 레포 심링크: `ln -s ~/Dev/<레포> ~/Hub/repos/<레포>`
- [ ] Orca에 `~/Hub`를 프로젝트로 추가(`orca repo add --path <경로> --kind folder`, git 레포면 `--kind git`)하고 관제 봇 만들기: 봇 채팅에서 `orca bot create --offer --name <이름> --purpose "<한 문장>"` → 사용자가 카드에서 Create bot. 봇 목록은 `orca bot list`
- [ ] Claude Code·Codex 폴더 신뢰는 `~/Dev`, `~/Hub`처럼 일하는 폴더만(홈 전체 신뢰 금지)
- [ ] pstack-claude·ponytail 설치(3절)

## 비공개 폴더 `HUB_PRIVATE`
hub 스크립트가 로그·지시서·메모를 두는 곳. 정하는 순서: 환경 변수 `HUB_PRIVATE` → `~/.config/hub/config`의 `HUB_PRIVATE=…` 한 줄 → 기본 `~/.hub`(없으면 만듦). 앱이 띄운 세션엔 셸 설정이 안 들어갈 수 있으니 컴퓨터별 값은 설정 파일에 둔다. 예: Hub 폴더 안 `private/`을 쓰려면
```sh
mkdir -p ~/.config/hub && echo "HUB_PRIVATE=<Hub 폴더>/private" >> ~/.config/hub/config
```

## 5. 세부는 여기서

| 하려는 일 | 스킬 |
|---|---|
| worker 켜기·이어 가기·끄기 | `hub:session` |
| (Herdr 시절) 탭 만들기, 칸 배치, 핀 | `hub:layout` |
| 지시·보고 흐름, 승인 전달, TODO.md 운영, 답 형식 | `hub:control` |
| worker에게 일 맡기는 지시서, 위임 전후 점검 | `hub:delegate` |
| 지금 할 일과 진행 상황 | `hub:what-should-i-do` |
| 지금 떠 있는 봇·worker·하는 일 한눈에 | `hub:status` |
| 놀고 있는 세션 자동으로 끄기 | `hub:dont-waste-sessions` |
| ClawPod 에이전트를 MCP로 부리기 | `hub:clawpod` |

스크립트는 모두 `${HUB_SCRIPTS}/`에 있다.
