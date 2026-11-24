---
name: aside-ops
description: 봇·에이전트가 Aside 브라우저를 쓸 때 먼저 쓰는 래퍼 — 한 번에 한 봇(lock), 연 탭은 끝에 반드시 닫기, exec 세션 정리, 결과 JSON, 하위 명령 오타 거부, 사용자 탭 attach 금지, 읽기 전용 모드, 계정 지도. Aside, 브라우저, 웹 확인, 로그인, 스크린샷, 탭 정리, aside exec, aside repl 요청 때 aside-browser보다 먼저.
---

# aside-ops

> 같은 폴더에 `reference.local.md`가 있으면 먼저 읽는다(이 컴퓨터 전용: 계정·레포·시험 레포). 공개 사본엔 없다.

봇·에이전트는 `aside`를 직접 부르지 말고 `aside-ops`(이 폴더의 `bin/aside-ops`, PATH에 링크해 두기: `ln -s <이 폴더>/bin/aside-ops ~/.local/bin/`)를 쓴다. Aside 자체 사용법(snapshot, 스킬 등)은 `aside guide`, `aside guide repl`.

## 고르기
- `exec`: 일을 Aside 에이전트에 맡길 때(로그인, 여러 단계, Gmail 코드 읽기). 대부분 이것.
- `repl`: 화면·DOM을 직접 봐야 할 때. 탭은 `openTab()`으로만 연다.
- `read`: 보기만 하는 확인(본문·스냅샷·스크린샷). 화면을 바꾸지 않는다.

```sh
aside-ops exec --who <봇이름> --timeout 5m "example.com 설정 화면의 언어 값을 읽어서 알려줘"
aside-ops repl --who <봇이름> --file job.js          # 또는 --code '...'
aside-ops read https://example.com --as text --screenshot home --out-dir ./shots
aside-ops repl --readonly --code "await ro.goto('https://example.com'); console.log(await ro.snapshot({interactive:true}))"
aside-ops status     # 지금 lock 쥔 봇, 실행 중 세션, 탭 수
aside-ops tabs       # 탭 목록(붙지 않음)
aside-ops accounts   # 로그인된 Google 계정 uid 목록 + 계정 지도 위치(없으면 hint)
aside-ops memory "cloudflare login"
aside-ops cleanup    # 표식 붙은 남은 탭·남은 CLI 세션 회수
```

결과는 stdout 한 줄 JSON: `ok`, `session_id`, `waited_s`, `elapsed_s`, `tabs_opened`, `tabs_closed`, `tabs_left`, `sessions_archived`, `output`, `error`. `ok`와 `tabs_left`가 빈지 보고 끝낸다.

## 래퍼가 해 주는 것
- 전역 lock(`~/.agents/run/aside-ops/`): 다른 봇이 쓰는 중이면 누가·언제부터인지 stderr에 찍고 기다린다(`--wait` 초, 기본 600; 넘으면 rc 3). 죽은 봇의 lock은 다음 실행이 자동 회수한다.
- 하위 명령은 허용 목록만. 오타는 rc 2로 거부(맨 `aside status`가 프롬프트로 가서 세션이 생기던 문제). exec 프롬프트가 세 단어 미만이면 거부.
- repl: `openTab`이 연 탭에 표식(`window.name='aside-ops'`)을 붙이고, 끝·오류·중단(SIGTERM/Ctrl-C) 때 모두 닫는다. `attachBrowserTab`·`attachActiveBrowserTab`·`page.close()`는 막는다.
- exec: 끝나면 세션을 archive, 시간 초과면 stop 뒤 archive. exec가 새로 연 탭(비활성, 3개 이하)은 닫는다.
- 읽기 전용(`read`, `repl --readonly`): `ro.goto/snapshot/text/title/url/screenshot`만. 클릭·입력·evaluate·원본 page는 실행 전 검사와 실행 중 둘 다에서 거부.

## 금지
- 사용자 탭 attach·조작. 사용자가 "이 탭 봐" 하면 그 URL을 `read`로 새 탭에 연다.
- 래퍼 없이 `aside`를 동시에 돌리기.
- 결제·카드 등록·유료 전환, 계정·데이터 삭제, 키 폐기, 권한 변경, 메시지 보내기 → 멈추고 묻는다(exec 프롬프트에도 래퍼가 이 규칙을 붙인다).
- 비밀번호·토큰·키 값을 출력·메모리·문서에 적기.

## 계정
사이트별 계정·uid·들어가는 법은 개인 파일 `~/.config/aside-ops/accounts.md`(환경 변수 `ASIDE_OPS_ACCOUNTS`로 바꿀 수 있음)에 둔다. 처음엔 이 폴더의 `accounts.example.md`를 복사해 채운다. 레포에는 넣지 않는다. 로그인 전에 `aside-ops memory "<사이트> login"`과 계정 지도부터 본다. 새로 성공하면 표를 고친다.

## 막혔을 때
- lock 시간 초과(rc 3): JSON `holder`의 봇에 물어보거나 기다린다. `status`에서 `alive:false`면 다음 실행이 자동 회수한다.
- `tabs_left`가 있음: `aside-ops cleanup`. 그래도 남으면 그 탭은 표식이 없는 것(사용자 탭일 수 있음) → 건드리지 말고 보고.
- 세션이 남음(`status`의 `ephemeral_cli_sessions`): `aside-ops cleanup`. 실행 중인 남의 세션은 멈추지 않는다.
- `Could not connect to Aside`: Aside 앱이 꺼졌거나 재시작 중. `aside-ops status`가 응답할 때까지 기다렸다가 그 판만 다시. 재시작이 감지되면(`aside_restarted`) 래퍼는 사용자 탭을 지키려고 표식 없는 탭을 안 닫는다.
- 로그인 풀림: 계정 지도 순서대로(기존 세션 → OAuth → 이메일) exec로 다시 로그인, 성공하면 계정 지도 갱신.

시험: `aside-ops selftest`(브라우저 안 씀).
