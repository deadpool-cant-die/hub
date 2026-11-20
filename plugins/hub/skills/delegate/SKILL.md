---
name: delegate
description: Hub 관제가(hub:delegate) worker 세션에게 일을 맡길 때 쓰는 지시서 틀과 위임 전후 점검. 레포 규칙 원문 목록 먼저 받기, 레포 컨벤션 언어(대개 영어 Conventional Commits)로 PR·커밋, 공개 레포에 개인 설정 쓰지 않기, 설정 파일 체크섬 비교, 공유 서버 업로드는 사용자 재확인 후, 결과물 경로·보고 형식을 다룬다. Trigger words - 시켜, 맡겨, 위임, worker 띄워, 리서치 시켜, 지시서, 에이전트 요청, 조사 시켜, PR 시켜, 작업 지시.
---

# worker에게 일 맡기기

관련(복사하지 않음):
- worker 켜는 명령 → `hub:session`, 칸 배치 → `hub:layout`
- 보고 흐름·승인 전달 → `hub:control`
- 회사 전용 내용(레포 컨벤션 예·공유 서버·파일 위치) → 같은 폴더 `reference.local.md`(있을 때만, 회사·개인 전용이라 공개 레포엔 없음)
- 웹 로그인·키 발급은 Aside(aside-browser 스킬)로 직접 → 전역 `~/.claude/CLAUDE.md` "웹 계정 작업은 직접 처리"
- 모델·effort 기본값 → 메모리 `feedback-model-effort-defaults`. 위임에 쓰지 않을 하네스가 있으면 메모리를 따른다

## 1. 지시서를 어디에

- 짧으면 `hub:session`의 `launch.sh` 첫 지시에 바로 넣는다.
- 길거나 여러 번 볼 것이면 `~/Hub/private/<내용> 지시서.md`로 쓰고, 첫 지시는 "이 파일을 읽고 그대로 진행해라 + 핵심 금지 2~3줄"로.

## 2. 지시서 틀

```markdown
# <일 이름> 지시서 (<세션 이름>, YYYY-MM-DD)

너는 <세션 이름>다. 일하는 곳: <실제 레포 폴더 ~/Dev/<이름> 또는 ~/Hub>.

## 목표
<한두 줄. 무엇을 끝내면 되나>

## 먼저 할 것: 규칙 원문 목록
손대기 전에 이 레포의 규칙 파일(AGENTS.md, CLAUDE.md, CONTRIBUTING, 관련 스킬)을 읽고
"규칙 원문(파일:줄) → 이 작업에서 할 일" 목록을 <보고처>에 먼저 보내라. 그 목록대로 한다.
자체 점검 스크립트나 해석으로 "규칙 통과"를 주장하지 마라.

## 읽을 것
- <문서·메모리·티켓 경로>

## 범위와 금지
- 할 것: <…>
- 하지 말 것: <예: 리서치만·파일 수정 금지 / 레포 생성 금지 / 머지·배포·태그·삭제 금지 / 다른 에이전트 띄우기 금지>
- PR·커밋·이슈는 이 레포 기존 언어·형식으로 (`gh pr list -L5`, `git log --oneline -5` 먼저 확인.)
- 공개 레포면 VPN·LiteLLM·모델 라우팅·로컬 경로 같은 개인 설정을 글에 쓰지 마라
- 공유 서버(디자인 라이브 서버 등)에는 올리지 말고 결과를 먼저 보여라. 사용자가 다시 확인한 뒤에만 올린다
- 설정 파일(~/.claude/settings.json, ~/.codex/config.toml, ~/.claude.json)은 건드리지 마라
- pstack poteto-mode로 진행하고, 끝나면 pstack 리뷰 스킬(최소 thermos 또는 ponytail-review)로 셀프 리뷰한 결과를 보고에 붙여라
- 범위를 줄이거나 바꿔야 하면 하지 말고 먼저 보고하라
- 워크트리는 `<레포>/.claude/worktrees/<이름>`에만 만들어라. /tmp·형제 폴더 사본 금지. 메인 체크아웃은 기본 브랜치에서 건드리지 마라. 체크아웃 하나에 worker 하나
- PR 머지를 보고할 때 그 워크트리·로컬 브랜치를 정리했는지 함께 적어라
- 확인 안 한 사실은 `[추정]`으로 표시하고 근거(파일·명령)를 붙여라

## 결과물
- <경로/파일 이름>, <형식: 쉬운 한국어, 결론→근거 등>

## 보고
끝나거나 막히면 `hc send <보고처> "[<세션 이름> → <보고처>] …"`로: 한 일 / 결과 경로·PR·커밋 / 남은 것 / 막힌 것.
```

## 3. 위임 전후 점검

위임 전:
```sh
cksum ~/.claude/settings.json ~/.codex/config.toml ~/.claude.json > /tmp/…/before-cksum.txt
```
결과를 받을 때마다:
```sh
cksum ~/.claude/settings.json ~/.codex/config.toml ~/.claude.json | diff /tmp/…/before-cksum.txt - && echo 같음
```
- 다르면 받아들이기 전에 무엇이 바뀌었는지 보고 사용자에게 알린다(2026-11-17 worker가 금지에도 `codex mcp remove <이름>`으로 사용자 MCP 항목을 지움, 메모리 `brgr-workers-touch-real-configs`). `~/.claude.json`은 세션마다 조금씩 바뀌므로 user 범위 키(`mcpServers` 등)만 비교해도 된다.
- MCP·클라이언트 테스트를 맡길 땐 임시 `CODEX_HOME`이나 다른 이름의 서버를 쓰게 한다.

받은 결과 확인:
- 규칙 원문 목록을 먼저 받았는지, 그 목록대로 했는지.
- PR이면 언어·형식이 레포와 같은지, 공개 레포면 본문에 개인 설정이 없는지(있으면 고친 뒤에도 GitHub 편집 기록에 남으니 올리기 전에 막는다).
- 결과물이 지시한 경로에만 있는지.
- 가능하면 직접 써 보며 확인(메모리 `feedback-review-by-using-it`).

## 4. 고정 문구 체크리스트

지시서에 빠졌으면 넣는다.
- [ ] 규칙 원문 목록 먼저
- [ ] 레포 컨벤션 언어로 PR·커밋
- [ ] 공개 레포 개인 설정 금지
- [ ] 공유 서버 업로드는 사용자 재확인 후
- [ ] 설정 파일 건드리지 않기
- [ ] 범위 밖 일·다른 에이전트 띄우기 금지
- [ ] 결과물 경로와 보고처
