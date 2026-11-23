# hub

계속 개선 중!!!!!!!!!!!!!!!

> [!WARNING]
> 여러 에이전트 세션을 동시에 띄우고 서로 보고·감시하는 방식이라 토큰을 많이 씁니다.
> 아직 토큰 사용량을 줄이는 작업(최적화)은 하지 않았습니다. 사용량과 요금을 감안하고 쓰세요.

매일 쓰는 Claude Code · Codex 플러그인 모음. (Claude Code and Codex plugins I use every day. Korean-first.)

## 플러그인 · 스킬 목록

### hub — 에이전트 관제 본부 (Orca 앱)

코딩 에이전트 여러 개를 Orca 앱 위에서 한 "관제 본부"로 굴리는 작업 방식. 봇(`bot:<이름>`)과 worker, 메시지는 `orca orchestration`. (Herdr 시절) Herdr 앱(`hc`, `herdr-app`)은 선택·옛 방식으로 남아 있고, `hub:layout`과 각 스킬의 "(Herdr 시절)" 절에서 씁니다.

| 스킬 | 한 줄 설명 | 부르기 (Claude Code / Codex) |
|---|---|---|
| `hub:hub-onboarding` | 처음 깐 사람용 단계별 안내: 도구(Orca) 확인, worker 하나 켜 보기, 봇 만들기, 주요 스킬 5개, 토큰 주의 | `/hub:hub-onboarding` / "처음인데 어떻게 시작해" |
| `hub:setup` | Hub 구조(Orca 앱·`~/Hub` 폴더·관제 봇·레포 봇·worker)와 처음 세팅 순서, pstack·ponytail 권장 | `/hub:setup` / "허브 세팅 알려 줘" |
| `hub:session` | worker 켜기(`worker-start --worktree new-child --name`)·이어 가기(봇 채팅은 이어짐)·끄기(`worker-stop`), Herdr 시절 relaunch 방법도 | `/hub:session` / "worker 하나 켜 줘" |
| `hub:layout` | (Herdr 시절, 선택) Herdr 탭 배치: 왼쪽 반 head, 오른쪽 반 worker 쌓기(4~6개면 두 열), head 없으면 같은 폭, tower 배치 — 이미 같으면 변화 없음 | `/hub:layout` / "탭 배치 맞춰" |
| `hub:control` | 관제 흐름: 누가 누구에게 지시·보고하나, `[사용자 승인]` 전달, `TODO.md` 운영, 답 형식 | `/hub:control` / "진행 상황 모아 줘" |
| `hub:delegate` | worker에게 줄 지시서 틀(규칙 원문 먼저·레포 컨벤션·공개 레포 주의)과 위임 전후 설정 파일 점검 | `/hub:delegate` / "이거 worker한테 시켜" |
| `hub:what-should-i-do` | 지금 내가 할 일과 전체 진행 상황을 짧게(TODO.md + 실제 세션 상태 대조) | `/hub:what-should-i-do` / "뭐 해야 돼?" |
| `hub:status` | Orca에 떠 있는 에이전트를 봇별로 한눈에: 상태(일하는 중·막힘·끝남)·핀·마지막으로 한 말 | `/hub:status` / "다들 뭐 해?" |
| `hub:dont-waste-sessions` | 끝난 worker·노는 터미널을 주기적으로 닫기(`on [분]`/`off`/`status`/`dry-run`), 봇 채팅·핀·작업 중은 제외, 로그 남김 | `/hub:dont-waste-sessions on 30` / "노는 세션 정리해" |
| `hub:clawpod` | ClawPod 에이전트를 웹 없이 MCP로만 부리기: 일 시키기·답장 감시·안 되는 것 기록 | `/hub:clawpod` / "클로팟 에이전트한테 시켜" |
| `hub:to-say-during-scrum` | 스크럼에서 말할 것: 어제·오늘·블로커 각 2~4줄, 티켓 번호 | `/hub:to-say-during-scrum` / "스크럼 뭐 말하지" |
| `hub:what-did-i-do-today` | 오늘 한 일을 시간순으로: 끝남·진행 중·기다림 | `/hub:what-did-i-do-today` / "오늘 뭐 했지" |
| `hub:praise-me` | 오늘 해낸 것을 실제 기록 근거로 짧게 칭찬 | `/hub:praise-me` / "나 잘했지" |
| `hub:how-is-deploy` | 레포별 열린 PR·CI·최신 태그·배포 실행, 멈춘 곳과 이유 | `/hub:how-is-deploy` / "배포 어디까지" |
| `hub:show-me` | 가장 최근 결과물을 바로 띄우고 달라진 점 세 줄 | `/hub:show-me` / "보여줘" |
| `hub:update-jira` | 오늘 한 일 중 이슈 트래커에 빠진 것 채우기(댓글·완료·상태, 새 티켓은 초안) | `/hub:update-jira` / "지라 업뎃" |
| `hub:dont-piss-me-off` | 받은 피드백 규칙을 어긴 곳 점검, 고칠 건 고침 | `/hub:dont-piss-me-off` / "또 그러네" |
| `hub:kill-slacker-sessions` | 맡은 일 없는 대기 세션을 명단에 남기고 끄기(확인 뒤) | `/hub:kill-slacker-sessions` / "노는 세션 꺼" |
| `hub:restore-everything` | 꺼진 Hub 되살리기: 같은 대화로 다시 켜고 배치·감시 맞춤 | `/hub:restore-everything` / "다 살려" |
| `hub:reload-all-session-plugin` | 떠 있는 모든 Claude 세션에 `/reload-plugins` | `/hub:reload-all-session-plugin` / "전 세션 리로드" |
| `hub:update` | 플러그인을 원본 레포와 맞추고 전 세션에 다시 읽힘 | `/hub:update` / "hub 업데이트" |
| `hub:hub-help` | hub 스킬 전체 목록·언제·예시 | `/hub:hub-help` / "hub 뭐 할 수 있어" |
| `hub:deadpools-skills-help` | 이 컴퓨터에 깐 스킬 전부(폴더·플러그인) 무엇·언제 | `/hub:deadpools-skills-help` / "내 스킬 뭐 있어" |
| `hub:deadpools-mods-help` | 직접 만든 Claude Code mod(패널 등) 무엇·여는 법 | `/hub:deadpools-mods-help` / "내 모드 뭐 있어" |

## 설치

한 줄이면 됩니다(Claude Code와, 깔려 있으면 Codex에도):
```sh
curl -fsSL https://raw.githubusercontent.com/deadpool-cant-die/hub/main/install.sh | sh
```
필요한 것(Orca 앱·`orca`·`jq` 등)이 없으면 무엇이 없는지 알려 줍니다. Herdr 앱은 선택(옛 방식)이라 없어도 됩니다. 끝나면:

> 설치 끝! 이제 /hub:hub-onboarding 을 실행하세요

이미 켜 둔 세션은 `/reload-plugins`를 한 번 입력하면 보입니다.

직접 하려면:
- Claude Code: `claude plugin marketplace add deadpool-cant-die/hub && claude plugin install hub@deadpool-skills --scope user`
- Codex: `codex plugin marketplace add https://github.com/deadpool-cant-die/hub.git && codex plugin add hub@deadpool-skills`

업데이트: `claude plugin marketplace update deadpool-skills` / `codex plugin marketplace upgrade deadpool-skills`.

## 지우기

한 줄로 플러그인과 마켓플레이스를 지웁니다. hub가 만든 폴더(`HUB_PRIVATE`, 기본 `~/.hub`)와 설정(`~/.config/hub`)은 지울지 물어봅니다:
```sh
curl -fsSL https://raw.githubusercontent.com/deadpool-cant-die/hub/main/uninstall.sh | sh
```

### 같이 쓰면 좋은 것
- [pstack-claude](https://github.com/michael-denyer/pstack-claude) — 작업 엔진(poteto-mode)
- [ponytail](https://github.com/DietrichGebert/ponytail) — 가장 단순한 해법 모드
- Orca 앱(`orca`) — hub 스킬의 전제
- (Herdr 시절) Herdr 앱(`herdr-app`, `hc`) — 선택·옛 방식, `hub:layout`과 "(Herdr 시절)" 절에서만

## 로컬 전용 메모

`*.local.md` 파일은 git이 무시한다. 회사·컴퓨터 전용 내용(사내 주소, 계정 이름, 채팅 번호)은 거기에 두면 스킬이 있을 때만 읽는다.

커밋 전: `scripts/check-public.sh`.

## 라이선스

MIT
