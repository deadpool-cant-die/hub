---
name: session
description: Hub에서 에이전트(Claude Code·Codex)를 Orca에서 켜고 끄는 법 — 봇 아래 worker 켜기(orca orchestration worker-start --worktree new-child --name), 이어서 일 시키기(봇 채팅은 이어짐), 끄기(worker-stop), 상태 확인. Herdr 시절 relaunch.sh·move-self.sh 방법도 아래에 남겨 둠. Trigger words - 세션 켜, 새 worker, 다시 켜, relaunch, resume, 재시작, 옮겨, 이동, 세션 꺼, 죽었어, worker-start, 이름 붙여.
---

# 세션(worker) 켜기·이어 가기·끄기 — Orca

> `HUB_SCRIPTS` = 이 플러그인의 `scripts/` 폴더(이 스킬 폴더 기준 `../../scripts`). 예: `HUB_SCRIPTS=<스킬 Base directory>/../../scripts`

Orca에선 일 단위가 **봇(`bot:<이름>`)과 그 worker**다. 봇은 오래 사는 채팅, worker는 봇이 일 하나를 맡기려고 켜는 에이전트. 원본 매뉴얼: `orca <명령> --help`, `orca skills get orchestration`.

## 0. 지켜야 할 것

1. **모델은 켤 때 `--model --effort`로만.** 세션 안에서 `/model`을 쓰면 `~/.claude/settings.json` 기본 모델까지 바뀐다. 켠 뒤 `grep '"model"' ~/.claude/settings.json`을 보고, 바뀌었으면 사용자에게 알린다.
2. **worker는 이름을 붙여 켠다.** `--name <일>-<역할>`(영어 소문자·숫자·`-`, 32자 이내).
3. **다른 에이전트 입력창에 직접 치지 않는다.** 말은 `orca orchestration send`로. (`orca terminal send`는 셸·내 칸, 그리고 `/reload-plugins` 같은 슬래시 명령에만.)
4. **화면 포커스를 옮기지 않는다**(`orca terminal switch`·`--focus` 금지). 보여 줄 게 있으면 봇·worker 이름만 알린다.

## 1. 찾기

```sh
orca bot list                                  # 봇 이름·하는 일·주소
orca agent list [--state working|blocked|waiting|done]   # 열린 에이전트·채팅, orca_session_id
orca orchestration worker-list                 # 내가 켠 worker와 터미널 상태(active·reclaimable·released …)
orca worktree ps                               # 워크스페이스별 봇·PR·에이전트 마지막 말
python3 -I ${HUB_SCRIPTS}/status.py [봇 이름]    # 위 셋을 봇별로 한눈에 (hub:status)
```

## 2. 켜기 — worker-start

```sh
orca orchestration worker-start --spec-file <지시서.md> --worktree new-child --name <일>-<역할> \
  --agent claude|codex [--model <id> --effort <level>] [--repo <selector>] --json
```
- 지시서는 `hub:delegate` 틀로. 첫 지시는 `--spec`/`--spec-file`로 같이 넣는다(따로 보내지 않음).
- `--worktree new-child`: 새 워크트리(브랜치)에서 일한다. 지금 폴더에서 하려면 `--worktree current`.
- 새 워크트리 worker는 끝나도 열려 있다. 아무도 그 채팅을 안 쓰면 `worker-release`로 닫는다.
- 확인: 받은 `dispatch` id로 `orca orchestration worker-show --dispatch <id>`.
- 봇 없이 그냥 에이전트 하나: `orca agent launch --agent claude --worktree <selector> --prompt "…"`.

### 켤 때 뜨는 질문
| 질문 | 답 |
|---|---|
| 폴더 신뢰("trust this folder") | Yes. 일하는 폴더(`~/Dev`, `~/Hub` 등)가 아니면 먼저 묻는다 |
| Codex 업데이트 알림 | Skip |
| Codex "Hooks need review" | 우리가 깐 훅만 있다고 사용자가 승인했으면 "Trust all and continue", 아니면 "Continue without trusting" |

## 3. 이어 가기 (Herdr 시절 relaunch·resume 대신)

- **봇 채팅은 이어진다.** 앱을 다시 켜도 봇의 Home Chat과 기록이 남으니 다시 켤 필요가 없다. 새 일은 `orca orchestration send --to bot:<이름> --type handoff …`.
- 끝난 worker에 이어서 시키기: `worker-start --terminal <그 worker의 터미널 handle> --spec …`(자동 닫힘 전이면 닫힘이 취소됨).
- 다른 봇에게 넘기기(Herdr 시절 "옮기기"): `--type handoff`로 그 봇에 보낸다. 같은 일을 두 곳에서 하지 않게 원래 worker는 4절로 끈다.

## 4. 끄기

```sh
orca orchestration worker-stop --dispatch <dispatch_id>    # 그 worker와 그 worker가 켠 helper까지
orca orchestration worker-release --dispatch <dispatch_id> # 끝난 worker의 터미널 닫기(기록은 남음)
orca terminal close --terminal <handle>                    # 봇 밖에서 켠 터미널 하나
```
- `worker-stop`은 워크트리·설정 터미널은 지우지 않는다. 결과에 `closed_agent_terminal`이면 `terminal close`를 또 하지 않는다.
- 끈 뒤 `orca orchestration worker-list`·`orca agent list`로 다른 것들이 그대로인지 확인.

## 5. 증상별

| 증상 | 할 일 |
|---|---|
| worker가 답이 없음 | `orca orchestration worker-read --dispatch <id>`로 화면 확인, 질문이면 `reply` |
| 봇이 일을 안 받음 | `orca bot list`에서 멈춤(paused) 여부 확인 |
| 입력창 회색 글자 | Claude 추천 문구라 지시·승인으로 보지 않는다 |
| 기다리고 싶다 | `sleep` 말고 `orca orchestration check --wait` |

## (Herdr 시절) 세션 켜기·다시 켜기·옮기기·끄기

> Herdr를 끌 때 이 절과 `launch.sh`·`relaunch.sh`·`move-self.sh`·`ids.sh`를 지운다. 그 전까지는 Herdr 칸을 다룰 때만 쓴다.

창(스페이스·탭·칸)은 `herdr-app`, 그 안의 터미널·에이전트는 `hc`가 맡는다. 원본 매뉴얼: `hc --skill`, `herdr-app --skill`.
칸 배치·탭 만들기·핀은 `hub:layout`. 스크립트 위치: `${HUB_SCRIPTS}/`.

### H0. 지켜야 할 것 (모두 실제 사고에서 나옴)

1. **장기 세션은 `--no-parent --keep`.** `hc run`으로 켠 터미널은 켠 쪽이 부모가 되고, 부모가 끝나면 자식도 끝난다. 옛 세션 11개를 끄자 새 세션 10개와 끈 세션 자신까지 꺼진 일이 있다. 부모가 있으면 사이드바에도 두 줄로 묶인다.
2. **모델은 켤 때 `--model --effort` 플래그로만.** 세션 안에서 `/model`을 쓰면 `~/.claude/settings.json` 기본 모델까지 바뀐다(여러 번 실제로 바뀜). 켠 뒤 `grep '"model"' ~/.claude/settings.json`을 보고, 바뀌었으면 사용자에게 알린다(설정 파일은 이 스킬로 고치지 않는다).
3. **스페이스·탭은 id로 명시.** 칸이 어느 스페이스에 붙는지는 cwd가 아니라 라벨(`herdr.space`, `herdr.tab`)이 정한다. 빠뜨리면 `~` 스페이스에 붙는다.
4. **에이전트 안에서 셸·스크립트용으로 hc를 부를 땐 `env -u HC_TERMINAL_ID -u HC_SCOPE hc …`.** 아니면 `<hc from=…>` 태그가 붙어 셸이 파싱 오류를 내고, 내가 부모가 된다.
5. **같은 대화(resume id)를 두 칸에서 띄우지 않는다.** 기록이 꼬인다. 세션 안에서 자기 resume 명령을 실행하면 뒤에서 사본이 생긴다 → 바로 끈다.
6. **화면 포커스를 옮기지 않는다**(`tab.select`·`pane.focus`·`hc attach` 등). 보여 줄 게 있으면 탭 이름·세션 이름만 알린다.

### H1. 찾기

```sh
${HUB_SCRIPTS}/ids.sh [스페이스 이름] [탭 이름 일부]   # 스페이스·탭·칸 id
hc ls                                      # 살아 있는 세션(이름·주소·parent)
hc get <이름>                               # 상세(폴더·상태·argv)
```
터미널 번호(t4n 등)는 다시 켜면 바뀐다. 이름으로 부른다.

### H2. 켜기

```sh
${HUB_SCRIPTS}/launch.sh <이름> <cwd> <space id> <tab id> <model> <effort> [--resume <session id>] ["첫 지시"]
```
- 첫 지시는 실행할 때 같이 넣는다(부팅 중 `hc send`는 버려질 수 있음). `first_message.sent`가 false면 `hc read`로 보고 처리한다. 무작정 다시 보내지 않는다.
- cwd: head는 `~/Hub`, worker는 실제 레포 `~/Dev/<레포>`(심링크 경로 아님).
- Codex: `env -u HC_TERMINAL_ID -u HC_SCOPE hc run --bg --no-parent --keep --name <이름> --cwd <cwd> --label herdr.space=<S> --label herdr.tab=<T> -- codex --dangerously-bypass-approvals-and-sandbox [resume <id>] "<지시>"`
- 사내 CA가 필요한 MCP가 있으면 Claude는 `env NODE_EXTRA_CA_CERTS=<pem> claude …`로 켠다(hc run 세션엔 셸 설정이 안 들어감).
- 확인: `hc get <이름> --json | jq '{address,parent}'` → parent null, `ids.sh`에 그 탭 칸으로 보임.

#### 켤 때 뜨는 질문
| 질문 | 답 |
|---|---|
| 폴더 신뢰("trust this folder") | Yes. 기본 선택이 No라 엔터만 치면 꺼진다. 일하는 폴더(`~/Dev`, `~/Hub` 등)가 아니면 먼저 묻는다 |
| Codex 업데이트 알림 | Skip |
| Codex "Hooks need review" | 우리가 깐 훅만 있다고 사용자가 승인했으면 "Trust all and continue", 아니면 "Continue without trusting" |

### H3. 다시 켜기 — relaunch.sh

```sh
${HUB_SCRIPTS}/relaunch.sh <이름>
```
- 살아 있는 세션의 argv·폴더·탭 라벨에서 모델·effort·resume id·사내 CA를 읽는다. 꺼진 세션은 세션 명단 표(`HUB_SESSIONS_TABLE`, 기본: 공용 메모리의 최근 `reference-hub-sessions-*.md`)에서.
- 같은 대화가 다른 곳에 떠 있으면(`pgrep -f "--resume <id>"`) **거부**하고 이유를 출력한다.
- 일하는 중이면 끝날 때까지(최대 5분) 기다린 뒤 옛 칸을 끄고, 같은 이름·같은 탭으로 켠다. 첫 지시는 다시 보내지 않는다.
- 2절 질문은 자동으로 답한다. OK/FAIL은 화면 너비가 아니라 `hc get`의 status·foreground로 판정, 로그 `HUB_LOG`(기본 `$HUB_PRIVATE/scripts/relaunch.log`).
- 끝에 tower 탭이면 `tower-layout.sh`, 다른 탭이면 `tab-layout.sh`로 칸 배치를 맞춘다(새 칸이 탭 끝에 붙기 때문).
- **자기 자신**이면 독립 터미널로 넘겨, 지금 응답이 끝난 뒤 실행된다. 사용자에게 "답이 끝나면 다시 켜진다"고 먼저 알린다.
- 여러 세션을 한꺼번에: 이름마다 차례로 부르고, 자기 자신은 맨 마지막.

### H4. 다른 탭으로 옮기기

남의 세션: `hc kill <이름>` 후 `launch.sh … <새 탭 id> … --resume <id>`. 자기 자신은 직접 못 옮긴다:
```sh
env -u HC_TERMINAL_ID -u HC_SCOPE hc run --bg --no-parent --name move-<이름> -- \
  ${HUB_SCRIPTS}/move-self.sh <이름> <cwd> <space id> <tab id> <model> <effort> <내 session id> [자리 바꿀 칸 이름]
```
내 session id = 이 세션 jsonl 파일 이름(`ls -t ~/.claude/projects/<폴더>/ | head -1`). 옛 칸엔 빈 셸이 남는다. 안 뜨면 `hc read move-<이름>`.

### H5. 끄기

1. 먼저 자식 확인: `hc ls --json | jq -r '.terminals[]|select(.parent=="<주소>")|"\(.address) \(.name)"'` — 자식은 같이 꺼진다.
2. `hc kill <이름>`(자식까지) 또는 칸째 `herdr-app do pane.close '{"pane":"<pane id>"}'`.
3. `hc ls`로 다른 세션이 그대로인지 확인.

### H6. 증상별

| 증상 | 원인 | 할 일 |
|---|---|---|
| 사이드바에 두 줄로 묶임 | 부모가 기록됨 | `relaunch.sh`(부모 없이 다시 켬) |
| 사이드바에 `~`로 나옴 | 칸이 `~` 스페이스에 있음 | 라벨로 원하는 탭에 다시 띄우기(4절) |
| 앱 터미널 색이 다 꺼짐 | 앱을 에이전트 셸 안에서 띄워 `NO_COLOR=1` 상속 | 사용자에게: 앱 ⌘Q → `hc server stop` → Dock에서 실행 |
| 입력창 회색 글자 | Claude 추천 문구 | 지시·승인으로 보지 않는다 |
| 기다리고 싶다 | — | `sleep` 말고 `hc wait <이름>` |
