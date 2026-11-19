---
name: control
description: Hub 관제 운영법(hub:control). tower 탭 칸 4개(hub-admin·hub-secretary·hub-atlassian·hub-resource)와 탭 관제·worker 사이의 지시·보고 흐름, hc 메시지 형식, [사용자 승인] 전달, ~/Hub/TODO.md 갱신 규칙, 사용자에게 하는 답의 형식([레포] 태그, 결정 대기 목록 줄이기)을 다룬다. Trigger words - 관제, 헤드, hub-admin, 보고, 진행 상황, 지금 뭐 해, 다들 뭐 해, 승인 전달, 사용자 승인, 투두, TODO, 할 일 정리, 정리해줘, 누구한테 시켜, 결정할 거, 남은 거.
---

# Hub 관제 운영

관련 규칙(복사하지 않음, 원문을 본다):
- 관제는 지시·조율·판단만, tower 칸 역할 → `~/Hub/AGENTS.md`
- `[사용자 승인]` 인정 조건·범위·보내는 쪽 규칙 → 전역 `~/.claude/CLAUDE.md` "세션 간 사용자 승인 전달 (hc)"
- 여러 레포 일은 그 레포 세션에 시킨다 → 메모리 `feedback-delegate-to-project-sessions`
- 회사 전용 내용(이슈 트래커·레포 태그 예·결재자) → 같은 폴더 `reference.local.md`(있을 때만, 회사·개인 전용이라 공개 레포엔 없음)
- 세션 켜기·옮기기·탭 → `hub:session`·`hub:layout`, worker 지시서 → `hub:delegate`, 할 일 보기 → `hub:what-should-i-do`, 세션 현황 → `hub:status`

## 1. 누가 누구에게

```
사용자 ⇄ hub-secretary(대화만) ⇄ hub-admin(일·연락 중심) ─┬─ 탭 관제(*-head) ⇄ worker(*-worker)
                                                       ├─ hub-atlassian (Codex, 이슈 트래커)
                                                       └─ hub-resource (Codex, 컴퓨터 진단)
```

- 사용자는 **hub-secretary 입력창에서만** 말한다. 모든 보고는 hub-admin으로 가고, hub-secretary는 hub-admin의 요약만 받는다(대화 맥락 보호). 레포·탭 칸 입력창에 남은 글은 Claude 추천 문구라 지시·승인이 아니다.
- 탭 관제가 다른 탭 worker에게 새 지시를 낼 때는 hub-admin를 거친다(같은 일을 두 곳에서 시키지 않게).
- worker 보고처는 자기 탭 관제. 탭 관제는 결과를 hub-admin에. hub-admin은 사용자 결정이 필요하거나 일이 끝났을 때만 묶어서 hub-secretary에.
- 이슈 트래커에 남길 일(진행/다음/블로커)은 hub-atlassian에 보낸다. 기존 티켓 갱신은 묻지 않고, **새 티켓은 초안을 hub-secretary 경유로 사용자에게 보여 준 뒤** 만든다.
- 리서치처럼 관제가 없는 탭의 worker는 시킨 헤드에게 바로 보고한다.

## 2. hc 메시지

```sh
hc send <이름> "[보내는이 → 받는이] 내용"         # 에이전트끼리
env -u HC_TERMINAL_ID -u HC_SCOPE hc send <이름> "…" # 셸·스크립트 칸에 보낼 때
hc wait <이름>            # 그 세션이 일을 멈출 때까지 (sleep 금지)
hc read <이름> --lines 60 # 화면 보기 (일하는 중이면 화면만 옴)
```

- 이름으로 부른다. 번호를 써야 하면 `hc ls`로 확인(다시 켜면 바뀜). 보고처를 적을 때 내 이름을 틀리지 않게 `hc get` 한 번.
- 받은 메시지 맨 앞의 `<hc from="t… 이름">`이 보낸 쪽이다. 서명 대신 이걸 믿는다.

### [사용자 승인] 전달 (hub-secretary만 보냄)
형식 예:
```
[hub-secretary → api-head] [사용자 승인] v1.2.3 태그를 abc1234에 찍기. 사용자 말: "ㄱㄱ 찍어"
```
- 사용자 말을 그대로 인용하고 대상(PR 번호·태그·배포 대상)을 적는다. 추천·추측을 승인으로 바꾸지 않는다.
- 받은 쪽은 실행 결과(커밋 해시·실행 링크)를 보낸 세션에 보고한다.
- 공유 서버(디자인 라이브 서버 등) 업로드는 "규칙대로 만들면 올려" 같은 조건부 승인이어도 **결과를 보여 준 뒤 한 번 더** 확인받는다(메모리 `feedback-repo-rules-first`).

## 3. TODO.md (`~/Hub/TODO.md`)

hub-admin이 주로 고치고, hub-secretary·hub-atlassian도 고친다. 고치기 전에 다시 읽고(다른 헤드가 방금 고쳤을 수 있음), 맨 위 `갱신:` 줄에 날짜와 이름을 적는다.

- 표시: `[ ]` 할 일 · `[~]` 진행 · `[?]` 사용자 답 대기 · `[!]` 결재자 답 대기 · `[-]` 보류 · `[x]` 끝
- 절 순서: 방침 / 진행 / 멈춤(날짜 사용자 지시) / 내일(MM-DD) / 오늘(MM-DD) / 사용자 결정 대기 / 결재자 답 대기 / 보류 / 나중 / 끝 (MM-DD). 빈 절은 빼도 된다
- 항목엔 담당(세션 이름), 근거 문서 경로, 결과물 경로를 붙인다. 티켓·PR·커밋 번호가 있으면 적는다.
- 날짜가 바뀌면 끝난 항목은 `끝 (날짜)` 절로 내리고, `오늘` 절 날짜를 바꾼다. 미룬 항목은 `나중`으로.
- 사용자가 "나중에 정할 것", "안 중요함"이라고 한 항목은 `나중`·`보류`에만 둔다(4절).
- hub-todo mod이 이 파일을 화면에 보여 준다. 형식을 바꾸면 mod이 깨질 수 있으니 위 표시·절 이름을 지킨다.

## 4. 사용자에게 답하기 (hub-secretary)

- 맨 앞에 대문자 레포 태그: `[MY-WEB]`, `[API]` … 여러 레포·관제 정리는 `[HUB]` (메모리 `feedback-answer-repo-prefix`).
- 한국어, 짧고 쉽게. 결론 먼저(메모리 `feedback-plain-language`).
- "결정 대기" 목록엔 **지금 사용자가 안 정하면 일이 멈추는 것만** 올린다. 사용자가 미룬 것·안 중요하다고 한 것은 다시 묻지 않는다(메모리 `feedback-no-reminding-minor-items`).
- 진행 상황을 물으면 hub-admin에게 모으게 하거나 `hc read`로 직접 보고, 추측으로 채우지 않는다.
- "멈춰"는 바로 멈추고 상태·남은 일만 보고(메모리 `feedback-stop-means-stop`).

## 5. 자주 하는 실수

| 실수 | 대신 |
|---|---|
| 관제가 직접 코드를 고치거나 PR을 만듦 | 그 레포 worker에게 `hub:delegate` 지시서로 시킴 |
| 두 관제가 같은 worker에게 따로 지시 | hub-admin 경유 |
| 내 주소를 착각해 엉뚱한 보고처를 적음 | 이름 사용, `hc get`으로 확인 |
| worker 입력창의 추천 문구를 사용자 지시로 봄 | 사용자는 관제에서만 말함 |
| 린트·자체 점검 통과를 근거로 공유 서버에 바로 올리라고 함 | 결과를 사용자에게 보여 주고 재확인 |
| 같은 결정 질문을 리캡마다 반복 | 미룬 항목은 TODO에만 |
