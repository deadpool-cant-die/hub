---
name: session
description: Hub에서 에이전트 세션(Claude Code·Codex)을 Herdr 앱에 켜고, 같은 이름·탭·대화로 다시 켜고(relaunch.sh), 다른 탭으로 옮기고, 끄는 법. 부모 없이 켜기(--no-parent), herdr.space/tab 라벨로 탭에 붙이기, 켤 때 뜨는 질문 처리, 자기 자신 옮기기. Trigger words - 세션 켜, 새 worker, 다시 켜, relaunch, resume, 재시작, 옮겨, 이동, 세션 꺼, 죽었어, hc run, 이름 붙여, ~로 떠, 두 줄로 보여.
---

# 세션 켜기·다시 켜기·옮기기·끄기

> `HUB_SCRIPTS` = 이 플러그인의 `scripts/` 폴더(이 스킬 폴더 기준 `../../scripts`). 예: `HUB_SCRIPTS=<스킬 Base directory>/../../scripts`

창(스페이스·탭·칸)은 `herdr-app`, 그 안의 터미널·에이전트는 `hc`가 맡는다. 원본 매뉴얼: `hc --skill`, `herdr-app --skill`.
칸 배치·탭 만들기·핀은 `hub:layout`. 스크립트 위치: `${HUB_SCRIPTS}/`.

## 0. 지켜야 할 것 (모두 실제 사고에서 나옴)

1. **장기 세션은 `--no-parent --keep`.** `hc run`으로 켠 터미널은 켠 쪽이 부모가 되고, 부모가 끝나면 자식도 끝난다. 옛 세션 11개를 끄자 새 세션 10개와 끈 세션 자신까지 꺼진 일이 있다. 부모가 있으면 사이드바에도 두 줄로 묶인다.
2. **모델은 켤 때 `--model --effort` 플래그로만.** 세션 안에서 `/model`을 쓰면 `~/.claude/settings.json` 기본 모델까지 바뀐다(여러 번 실제로 바뀜). 켠 뒤 `grep '"model"' ~/.claude/settings.json`을 보고, 바뀌었으면 사용자에게 알린다(설정 파일은 이 스킬로 고치지 않는다).
3. **스페이스·탭은 id로 명시.** 칸이 어느 스페이스에 붙는지는 cwd가 아니라 라벨(`herdr.space`, `herdr.tab`)이 정한다. 빠뜨리면 `~` 스페이스에 붙는다.
4. **에이전트 안에서 셸·스크립트용으로 hc를 부를 땐 `env -u HC_TERMINAL_ID -u HC_SCOPE hc …`.** 아니면 `<hc from=…>` 태그가 붙어 셸이 파싱 오류를 내고, 내가 부모가 된다.
5. **같은 대화(resume id)를 두 칸에서 띄우지 않는다.** 기록이 꼬인다. 세션 안에서 자기 resume 명령을 실행하면 뒤에서 사본이 생긴다 → 바로 끈다.
6. **화면 포커스를 옮기지 않는다**(`tab.select`·`pane.focus`·`hc attach` 등). 보여 줄 게 있으면 탭 이름·세션 이름만 알린다.

## 1. 찾기

```sh
${HUB_SCRIPTS}/ids.sh [스페이스 이름] [탭 이름 일부]   # 스페이스·탭·칸 id
hc ls                                      # 살아 있는 세션(이름·주소·parent)
hc get <이름>                               # 상세(폴더·상태·argv)
```
터미널 번호(t4n 등)는 다시 켜면 바뀐다. 이름으로 부른다.

## 2. 켜기

```sh
${HUB_SCRIPTS}/launch.sh <이름> <cwd> <space id> <tab id> <model> <effort> [--resume <session id>] ["첫 지시"]
```
- 첫 지시는 실행할 때 같이 넣는다(부팅 중 `hc send`는 버려질 수 있음). `first_message.sent`가 false면 `hc read`로 보고 처리한다. 무작정 다시 보내지 않는다.
- cwd: head는 `~/Hub`, worker는 실제 레포 `~/Dev/<레포>`(심링크 경로 아님).
- Codex: `env -u HC_TERMINAL_ID -u HC_SCOPE hc run --bg --no-parent --keep --name <이름> --cwd <cwd> --label herdr.space=<S> --label herdr.tab=<T> -- codex --dangerously-bypass-approvals-and-sandbox [resume <id>] "<지시>"`
- 사내 CA가 필요한 MCP가 있으면 Claude는 `env NODE_EXTRA_CA_CERTS=<pem> claude …`로 켠다(hc run 세션엔 셸 설정이 안 들어감).
- 확인: `hc get <이름> --json | jq '{address,parent}'` → parent null, `ids.sh`에 그 탭 칸으로 보임.

### 켤 때 뜨는 질문
| 질문 | 답 |
|---|---|
| 폴더 신뢰("trust this folder") | Yes. 기본 선택이 No라 엔터만 치면 꺼진다. 일하는 폴더(`~/Dev`, `~/Hub` 등)가 아니면 먼저 묻는다 |
| Codex 업데이트 알림 | Skip |
| Codex "Hooks need review" | 우리가 깐 훅만 있다고 사용자가 승인했으면 "Trust all and continue", 아니면 "Continue without trusting" |

## 3. 다시 켜기 — relaunch.sh

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

## 4. 다른 탭으로 옮기기

남의 세션: `hc kill <이름>` 후 `launch.sh … <새 탭 id> … --resume <id>`. 자기 자신은 직접 못 옮긴다:
```sh
env -u HC_TERMINAL_ID -u HC_SCOPE hc run --bg --no-parent --name move-<이름> -- \
  ${HUB_SCRIPTS}/move-self.sh <이름> <cwd> <space id> <tab id> <model> <effort> <내 session id> [자리 바꿀 칸 이름]
```
내 session id = 이 세션 jsonl 파일 이름(`ls -t ~/.claude/projects/<폴더>/ | head -1`). 옛 칸엔 빈 셸이 남는다. 안 뜨면 `hc read move-<이름>`.

## 5. 끄기

1. 먼저 자식 확인: `hc ls --json | jq -r '.terminals[]|select(.parent=="<주소>")|"\(.address) \(.name)"'` — 자식은 같이 꺼진다.
2. `hc kill <이름>`(자식까지) 또는 칸째 `herdr-app do pane.close '{"pane":"<pane id>"}'`.
3. `hc ls`로 다른 세션이 그대로인지 확인.

## 6. 증상별

| 증상 | 원인 | 할 일 |
|---|---|---|
| 사이드바에 두 줄로 묶임 | 부모가 기록됨 | `relaunch.sh`(부모 없이 다시 켬) |
| 사이드바에 `~`로 나옴 | 칸이 `~` 스페이스에 있음 | 라벨로 원하는 탭에 다시 띄우기(4절) |
| 앱 터미널 색이 다 꺼짐 | 앱을 에이전트 셸 안에서 띄워 `NO_COLOR=1` 상속 | 사용자에게: 앱 ⌘Q → `hc server stop` → Dock에서 실행 |
| 입력창 회색 글자 | Claude 추천 문구 | 지시·승인으로 보지 않는다 |
| 기다리고 싶다 | — | `sleep` 말고 `hc wait <이름>` |
