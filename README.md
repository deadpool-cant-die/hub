# skills

매일 쓰는 Claude Code · Codex 플러그인 모음. (Claude Code and Codex plugins I use every day. Korean-first.)

## 플러그인 · 스킬 목록

### hub — 에이전트 관제 본부 (Herdr 앱)

코딩 에이전트 세션 여러 개를 Herdr 앱 위에서 한 "관제 본부"로 굴리는 작업 방식. 세션 실행·메시지는 `hc`, 탭·칸은 `herdr-app`.

| 스킬 | 한 줄 설명 | 부르기 (Claude Code / Codex) |
|---|---|---|
| `hub:setup` | Hub 구조(Herdr 앱·`~/Hub` 폴더·tower 탭·head/worker)와 처음 세팅 순서, pstack·ponytail 권장 | `/hub:setup` / "허브 세팅 알려 줘" |
| `hub:session` | 세션 켜기·같은 이름·탭·대화로 다시 켜기(`relaunch.sh`)·다른 탭으로 옮기기·끄기, 부모 없이 켜기 | `/hub:session` / "worker 하나 켜 줘", "이 세션 다시 켜" |
| `hub:layout` | 탭 배치: 왼쪽 반 head, 오른쪽 반 worker 쌓기(4~6개면 두 열), head 없으면 같은 폭, tower 배치 — 이미 같으면 변화 없음 | `/hub:layout` / "탭 배치 맞춰" |
| `hub:control` | 관제 흐름: 누가 누구에게 지시·보고하나, `[사용자 승인]` 전달, `TODO.md` 운영, 답 형식 | `/hub:control` / "진행 상황 모아 줘" |
| `hub:delegate` | worker에게 줄 지시서 틀(규칙 원문 먼저·레포 컨벤션·공개 레포 주의)과 위임 전후 설정 파일 점검 | `/hub:delegate` / "이거 worker한테 시켜" |
| `hub:what-should-i-do` | 지금 내가 할 일과 전체 진행 상황을 짧게(TODO.md + 실제 세션 상태 대조) | `/hub:what-should-i-do` / "뭐 해야 돼?" |
| `hub:status` | 떠 있는 세션을 스페이스·탭별로 한눈에: 상태(일하는 중·막힘·끝남·대기)·핀·하는 일 | `/hub:status` / "다들 뭐 해?" |
| `hub:dont-waste-sessions` | 노는 세션을 주기적으로 찾아 끄기(`on [분]`/`off`/`status`/`dry-run`), 핀·head·tower·작업 중은 제외, resume id 로그 | `/hub:dont-waste-sessions on 30` / "노는 세션 정리해" |
| `hub:clawpod` | ClawPod 에이전트를 웹 없이 MCP로만 부리기: 일 시키기·답장 감시·안 되는 것 기록 | `/hub:clawpod` / "클로팟 에이전트한테 시켜" |
| `hub:to-say-during-scrum` | 스크럼에서 말할 것: 어제·오늘·블로커 각 2~4줄, 티켓 번호 | `/hub:to-say-during-scrum` / "스크럼 뭐 말하지" |
| `hub:what-did-i-do-today` | 오늘 한 일을 시간순으로: 끝남·진행 중·기다림 | `/hub:what-did-i-do-today` / "오늘 뭐 했지" |
| `hub:praise-me` | 오늘 해낸 것을 실제 기록 근거로 짧게 칭찬 | `/hub:praise-me` / "나 잘했지" |
| `hub:how-is-deploy` | 레포별 열린 PR·CI·최신 태그·배포 실행, 멈춘 곳과 이유 | `/hub:how-is-deploy` / "배포 어디까지" |
| `hub:why-stuck` | 왜 오래 걸리나: 무엇을 기다리는지 한 줄씩, 이미 끝난 기다림은 바로 알림 | `/hub:why-stuck` / "왜 이렇게 오래 걸려" |
| `hub:show-me` | 가장 최근 결과물을 바로 띄우고 달라진 점 세 줄 | `/hub:show-me` / "보여줘" |
| `hub:send-msg` | 메신저 보내기: 받는 사람 찾기, 말투 규칙, 초안 먼저, "보내"라고 하면 전송 | `/hub:send-msg` / "이거 보내" |
| `hub:update-jira` | 오늘 한 일 중 이슈 트래커에 빠진 것 채우기(댓글·완료·상태, 새 티켓은 초안) | `/hub:update-jira` / "지라 업뎃" |
| `hub:remember-this` | 방금 정한 규칙·선호를 공용 메모리에 저장 | `/hub:remember-this` / "기억해" |
| `hub:dont-piss-me-off` | 받은 피드백 규칙을 어긴 곳 점검, 고칠 건 고침 | `/hub:dont-piss-me-off` / "또 그러네" |
| `hub:f-idle-session-delete-it` | 맡은 일 없는 대기 세션을 명단에 남기고 끄기(확인 뒤) | `/hub:f-idle-session-delete-it` / "노는 세션 꺼" |
| `hub:restore-everything` | 꺼진 Hub 되살리기: 같은 대화로 다시 켜고 배치·감시 맞춤 | `/hub:restore-everything` / "다 살려" |
| `hub:reload-all-session-plugin` | 떠 있는 모든 Claude 세션에 `/reload-plugins` | `/hub:reload-all-session-plugin` / "전 세션 리로드" |
| `hub:update` | 플러그인을 원본 레포와 맞추고 전 세션에 다시 읽힘 | `/hub:update` / "hub 업데이트" |
| `hub:hub-help` | hub 스킬 전체 목록·언제·예시 | `/hub:hub-help` / "hub 뭐 할 수 있어" |
| `hub:deadpools-skills-help` | 이 컴퓨터에 깐 스킬 전부(폴더·플러그인) 무엇·언제 | `/hub:deadpools-skills-help` / "내 스킬 뭐 있어" |
| `hub:deadpools-mods-help` | 직접 만든 Claude Code mod(패널 등) 무엇·여는 법 | `/hub:deadpools-mods-help` / "내 모드 뭐 있어" |

## 설치

### Claude Code
```sh
claude plugin marketplace add deadpool-cant-die/skills
claude plugin install hub@deadpool-skills --scope user
```
새 세션부터 `/hub:` 로 보인다. 업데이트: `claude plugin marketplace update deadpool-skills`.

### Codex
```sh
codex plugin marketplace add https://github.com/deadpool-cant-die/skills.git
```
Codex를 다시 켠 뒤 `/plugins` → `deadpool skills` → `hub` 설치. 업데이트: `codex plugin marketplace upgrade deadpool-skills`.

### 같이 쓰면 좋은 것
- [pstack-claude](https://github.com/michael-denyer/pstack-claude) — 작업 엔진(poteto-mode)
- [ponytail](https://github.com/DietrichGebert/ponytail) — 가장 단순한 해법 모드
- Herdr 앱(`herdr-app`, `hc`) — hub 스킬의 전제

## 로컬 전용 메모

`*.local.md` 파일은 git이 무시한다. 회사·컴퓨터 전용 내용(사내 주소, 계정 이름, 채팅 번호)은 거기에 두면 스킬이 있을 때만 읽는다.

커밋 전: `scripts/check-public.sh`.

## 라이선스

MIT
