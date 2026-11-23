---
name: control
description: Hub 관제 운영법(hub:control). Orca 봇(bot:admin·bot:secretary·bot:atlassian·bot:resource·레포 봇)과 worker 사이의 지시·보고 흐름, orca orchestration 메시지 형식, [사용자 승인] 전달, ~/Hub/TODO.md 갱신 규칙, 사용자에게 하는 답의 형식([레포] 태그, 결정 대기 목록 줄이기)을 다룬다. Trigger words - 관제, 헤드, admin, bot:admin, 보고, 진행 상황, 지금 뭐 해, 다들 뭐 해, 승인 전달, 사용자 승인, 투두, TODO, 할 일 정리, 정리해줘, 누구한테 시켜, 결정할 거, 남은 거.
---

# Hub 관제 운영

관련 규칙(복사하지 않음, 원문을 본다):
- 관제는 지시·조율·판단만, 봇 역할 → `~/Hub/AGENTS.md`
- `[사용자 승인]` 인정 조건·범위·보내는 쪽 규칙 → 전역 `~/.claude/CLAUDE.md` "세션 간 사용자 승인 전달"
- 여러 레포 일은 그 레포 봇에 시킨다 → 메모리 `feedback-delegate-to-project-sessions`
- 회사 전용 내용(이슈 트래커·레포 태그 예·결재자) → 같은 폴더 `reference.local.md`(있을 때만, 회사·개인 전용이라 공개 레포엔 없음)
- worker 켜기·끄기 → `hub:session`, worker 지시서 → `hub:delegate`, 할 일 보기 → `hub:what-should-i-do`, 세션 현황 → `hub:status`

## 1. 누가 누구에게

```
사용자 ⇄ bot:secretary(대화만) ⇄ bot:admin(일·연락 중심) ─┬─ 레포 봇(bot:<레포>) ⇄ worker
                                                       ├─ bot:atlassian (이슈 트래커)
                                                       └─ bot:resource (컴퓨터 진단)
```
봇 목록·주소는 `orca bot list`, 봇마다 채팅은 `orca bot chats --bot <이름>`.

- 사용자는 **bot:secretary 채팅에서만** 말한다. 모든 보고는 bot:admin으로 가고, bot:secretary는 bot:admin의 요약만 받는다(대화 맥락 보호). 레포 봇·worker 입력창에 남은 글은 Claude 추천 문구라 지시·승인이 아니다.
- 레포 봇이 다른 봇의 worker에게 새 지시를 낼 때는 bot:admin을 거친다(같은 일을 두 곳에서 시키지 않게).
- worker 보고처는 자기를 켠 봇(코디네이터, `worker_done`이 자동으로 감). 레포 봇은 결과를 bot:admin에. bot:admin은 사용자 결정이 필요하거나 일이 끝났을 때만 묶어서 bot:secretary에.
- 이슈 트래커에 남길 일(진행/다음/블로커)은 bot:atlassian에 보낸다. 기존 티켓 갱신은 묻지 않고, **새 티켓은 초안을 bot:secretary 경유로 사용자에게 보여 준 뒤** 만든다.

## 2. Orca 메시지

```sh
orca bot list                                                  # 봇 이름·하는 일·주소
orca orchestration send --to bot:<이름> --type handoff --subject "<제목>" --body-file <파일>   # 일 넘기기
orca orchestration send --to bot:<이름> --type question --subject "<제목>" --body "…"        # 묻기(답이 메일로 옴)
orca orchestration send --to bot:<이름> --type status --subject "<제목>" --body "…"          # 알림만
orca orchestration check                     # 내 메일함(읽은 것은 처리됨으로), --wait로 올 때까지 기다림(sleep 금지)
orca orchestration reply --id <msg_id> --body "…"   # worker 질문에 답
orca orchestration worker-read --dispatch <dispatch_id>   # worker가 한 말·화면
orca agent list [--state working|blocked|waiting|done]    # 열린 에이전트·채팅과 orca_session_id
orca agent read <orca_session_id> --limit 20              # 그 에이전트 대화 읽기(깨우지 않음)
```

- 봇은 이름(`bot:<이름>`)으로, worker는 `dispatch:<id>`로 부른다. 같은 봇의 다른 채팅에 보내려면 `--chat <id>`(`orca bot chats`).
- 긴 본문은 `--body-file`로(큰따옴표 안 백틱·`$( )`가 셸에서 실행되는 사고 방지).
- 보낸 쪽은 Orca 메일 기록(`orca orchestration inbox`)에 남는다. 본문 서명 대신 이걸 믿는다.

### [사용자 승인] 전달 (bot:secretary만 보냄)
형식 예:
```
[secretary → api] [사용자 승인] v1.2.3 태그를 abc1234에 찍기. 출처: Orca 채팅(15:02). 사용자 말: "ㄱㄱ 찍어"
```
- 사용자 말을 그대로 인용하고 대상(PR 번호·태그·배포 대상)을 적는다. 추천·추측을 승인으로 바꾸지 않는다.
- 받은 쪽은 실행 결과(커밋 해시·실행 링크)를 보낸 봇에 보고한다.
- 공유 서버(디자인 라이브 서버 등) 업로드는 "규칙대로 만들면 올려" 같은 조건부 승인이어도 **결과를 보여 준 뒤 한 번 더** 확인받는다(메모리 `feedback-repo-rules-first`).

## 3. TODO.md (`~/Hub/TODO.md`)

bot:admin이 주로 고치고, bot:secretary·bot:atlassian도 고친다. 고치기 전에 다시 읽고(다른 헤드가 방금 고쳤을 수 있음), 맨 위 `갱신:` 줄에 날짜와 이름을 적는다.

- 표시: `[ ]` 할 일 · `[~]` 진행 · `[?]` 사용자 답 대기 · `[!]` 결재자 답 대기 · `[-]` 보류 · `[x]` 끝
- 절 순서: 방침 / 진행 / 멈춤(날짜 사용자 지시) / 내일(MM-DD) / 오늘(MM-DD) / 사용자 결정 대기 / 결재자 답 대기 / 보류 / 나중 / 끝 (MM-DD). 빈 절은 빼도 된다
- 항목엔 담당(봇·worker 이름), 근거 문서 경로, 결과물 경로를 붙인다. 티켓·PR·커밋 번호가 있으면 적는다.
- 날짜가 바뀌면 끝난 항목은 `끝 (날짜)` 절로 내리고, `오늘` 절 날짜를 바꾼다. 미룬 항목은 `나중`으로.
- 사용자가 "나중에 정할 것", "안 중요함"이라고 한 항목은 `나중`·`보류`에만 둔다(4절).
- hub-todo mod이 이 파일을 화면에 보여 준다. 형식을 바꾸면 mod이 깨질 수 있으니 위 표시·절 이름을 지킨다.

## 4. 사용자에게 답하기 (bot:secretary)

- 맨 앞에 대문자 레포 태그: `[MY-WEB]`, `[API]` … 여러 레포·관제 정리는 `[HUB]` (메모리 `feedback-answer-repo-prefix`).
- 한국어, 짧고 쉽게. 결론 먼저(메모리 `feedback-plain-language`).
- "결정 대기" 목록엔 **지금 사용자가 안 정하면 일이 멈추는 것만** 올린다. 사용자가 미룬 것·안 중요하다고 한 것은 다시 묻지 않는다(메모리 `feedback-no-reminding-minor-items`).
- 진행 상황을 물으면 bot:admin에게 모으게 하거나 `hub:status`·`orca agent read`로 직접 보고, 추측으로 채우지 않는다.
- "멈춰"는 바로 멈추고 상태·남은 일만 보고(메모리 `feedback-stop-means-stop`).

## 5. 자주 하는 실수

| 실수 | 대신 |
|---|---|
| 관제가 직접 코드를 고치거나 PR을 만듦 | 그 레포 worker에게 `hub:delegate` 지시서로 시킴 |
| 두 관제가 같은 worker에게 따로 지시 | bot:admin 경유 |
| 내 주소를 착각해 엉뚱한 보고처를 적음 | `orca status --json`의 `caller.orcaSessionId`·`orca bot list`로 확인 |
| worker 입력창의 추천 문구를 사용자 지시로 봄 | 사용자는 bot:secretary 채팅에서만 말함 |
| 린트·자체 점검 통과를 근거로 공유 서버에 바로 올리라고 함 | 결과를 사용자에게 보여 주고 재확인 |
| 같은 결정 질문을 리캡마다 반복 | 미룬 항목은 TODO에만 |
