---
name: setup
description: Hub(에이전트 작업 관제 본부)가 무엇이고 어떻게 짜여 있는지, 처음 세팅하는 순서. 기본 구조는 Herdr 앱(herdr-app으로 탭·칸, hc로 세션·메시지)과 ~/Hub 폴더, tower 탭과 탭별 head/worker. 권장 도구는 pstack-claude(작업 엔진, poteto-mode)와 ponytail(가장 단순한 해법). 세부 절차는 hub:session·hub:layout·hub:control·hub:delegate·hub:what-should-i-do·hub:status로 넘긴다. Trigger words - hub setup, hub, Hub, 허브, 관제 본부, 허브 세팅, 허브 구조, 허브 처음, herdr 세팅, herdr 구조, tower, 관제 구조, 작업 방식, 어떻게 일해.
---

# Hub — 에이전트 작업 관제 본부

> `HUB_SCRIPTS` = 이 플러그인의 `scripts/` 폴더(이 스킬 폴더 기준 `../../scripts`). 예: `HUB_SCRIPTS=<스킬 Base directory>/../../scripts`

## 1. Hub가 무엇인가

여러 레포에 걸친 일을 에이전트 세션 여러 개로 나눠 돌리는 **관제 본부**다.

- Hub(관제) 세션은 **지시·조율·판단만** 한다. 코드는 고치지 않는다.
- 구현은 각 레포의 **worker** 세션이 실제 레포 폴더에서 한다.
- 사용자는 tower 탭의 창구 세션과만 대화하고, 나머지 세션은 서로 `hc send`로 메시지를 주고받는다.

## 2. 기본 구조

### Herdr 앱
- `herdr-app` — 창: 스페이스·탭·칸·핀. `herdr-app ls`, `herdr-app do <명령> '{json}'`, `herdr-app commands`
- `hc` (herdr-core) — 터미널·에이전트 실행과 대화. `hc run / ls / get / read / send / wait / kill`. 앱 창을 닫아도 세션은 계속 돈다.
- 원본 매뉴얼: `herdr-app --skill`, `hc --skill`

### ~/Hub 폴더
```
~/Hub/
  AGENTS.md   Hub 규칙(관제 원칙, tower 역할, 문서 지도). CLAUDE.md는 @AGENTS.md
  TODO.md     오늘 할 일 판(관제 세션들이 같이 고침)
  repos/      쓰는 레포 심링크 → ~/Dev/<레포>   (코드는 심링크 말고 실제 폴더에서 고친다)
  docs/       업무 문서·공용 메모리 심링크
  private/    비공개 메모·지시서·스크립트 (git에 안 올림, 비밀값은 위치만 적음)
```

### tower 탭 (관제 탭)
| 칸 | 역할 |
|---|---|
| `hub-secretary` | 사용자 창구. 지시를 받아 나눠 주고 사용자 승인을 전달한다 |
| `hub-admin` | 다른 탭 head·worker와 소통, 진행 수집, TODO.md 관리 |
| `hub-atlassian` | 이슈 트래커(티켓) 반영 전담 |
| `hub-resource` | 컴퓨터가 느려질 때 원인 진단 |

배치·다시 켜기·역할 상세는 `~/Hub/AGENTS.md`와 `hub:control`.

### 일 탭 (탭 하나 = 일 하나)
- 왼쪽 칸 = 그 일의 **head**(`<일>-head`, cwd `~/Hub`), 오른쪽 = **worker**(`<일>-worker`, cwd `~/Dev/<레포>`)를 쌓는다.
- 칸은 1:1로 나눈다. head는 자기 탭 안에서만 칸을 늘린다.
- 세션 이름은 `<일>-<역할>`(역할: head·worker·review·shell), 이름으로 부른다(터미널 번호는 다시 켜면 바뀜).

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

- [ ] Herdr 앱 설치 후 `herdr-app --version`, `hc --version` 확인. 앱은 Dock·Finder로 띄운다(에이전트 셸 안에서 띄우면 환경 변수를 물려받아 터미널 색이 꺼질 수 있음)
- [ ] `~/Hub` 만들기: `mkdir -p ~/Hub/{repos,docs,private}`, `AGENTS.md`(관제 원칙)·`CLAUDE.md`(`@AGENTS.md` 한 줄)·`TODO.md`, `private/`는 `.gitignore`에
- [ ] 레포 심링크: `ln -s ~/Dev/<레포> ~/Hub/repos/<레포>`
- [ ] Herdr에 `Hub` 스페이스와 `tower` 탭을 만들고 tower 세션들을 부모 없이 띄우기 → `hub:session`, 칸 배치는 `hub:layout`
- [ ] Claude Code·Codex 폴더 신뢰는 `~/Dev`, `~/Hub`처럼 일하는 폴더만(홈 전체 신뢰 금지)
- [ ] pstack-claude·ponytail 설치(3절)

## 5. 세부는 여기서

| 하려는 일 | 스킬 |
|---|---|
| 세션 켜기·다시 켜기·옮기기·끄기 | `hub:session` |
| 탭 만들기, 칸 배치(왼쪽 head·오른쪽 worker, tower), 핀 | `hub:layout` |
| 지시·보고 흐름, 승인 전달, TODO.md 운영, 답 형식 | `hub:control` |
| worker에게 일 맡기는 지시서, 위임 전후 점검 | `hub:delegate` |
| 지금 할 일과 진행 상황 | `hub:what-should-i-do` |
| 지금 떠 있는 세션·탭·하는 일 한눈에 | `hub:status` |
| 놀고 있는 세션 자동으로 끄기 | `hub:dont-waste-sessions` |
| ClawPod 에이전트를 MCP로 부리기 | `hub:clawpod` |

스크립트는 모두 `${HUB_SCRIPTS}/`에 있다.
