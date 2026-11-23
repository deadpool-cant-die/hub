---
name: how-is-deploy
description: 배포 현황 — 레포별 열린 PR, CI, 최신 태그, 배포 실행, stage/운영 버전, 멈춘 곳은 왜 멈췄는지까지. Trigger words - /hub:how-is-deploy, 배포 어디까지, 배포 현황, 운영 버전, 태그 찍었어, 릴리스 상태.
---

# 배포 현황 (hub:how-is-deploy)

> 같은 폴더에 `reference.local.md`가 있으면 먼저 읽는다(회사·이 컴퓨터 전용: 레포·도구 경로·사람·채팅 번호). 공개 사본엔 없다.
> `HUB_SCRIPTS` = 이 플러그인의 `scripts/`(이 스킬 폴더 기준 `../../scripts`).

공통: 답은 짧게, 쉬운 한국어, 맨 앞에 `[HUB]`(레포 하나 얘기면 `[레포이름]`). **실제로 확인한 사실만** 쓴다(이슈 트래커, git, gh, orca, 메모리, TODO.md). 확인 못 한 건 "확인 못 함"이라고 적는다.

대상 레포·태그 이름·stage/운영 주소는 `reference.local.md`의 표. 없으면 `~/Hub/repos/*` 전부.

## 레포마다 (읽기만)
- 열린 PR: `gh pr list --state open --json number,title,isDraft,reviewDecision,mergeStateStatus`
- CI: 기본 브랜치 최신 실행 `gh run list -b <main|master> -L3`, 열린 PR은 `gh pr checks <번호>`
- 최신 태그: `git fetch --tags -q && git tag --sort=-creatordate | grep '^<태그 접두>' | head -2`, 그 태그와 기본 브랜치 차이 `git log --oneline <태그>..origin/<기본>`
- 배포 실행: 태그·stage 워크플로 최근 실행(`gh run list -w <배포 워크플로> -L3`)
- stage/운영 버전: 버전·헬스 주소가 있으면 `curl -s <주소>` 1회.

## 답
```
[HUB] 배포
<레포>  운영 <태그>(<날짜>) · stage <커밋> · 대기 PR N · CI <✓/✗/진행>
  멈춤: <무엇> — <왜: 검사 대기 / 리뷰어 답 대기 / 승인 대기 / worker 막힘 / 권한(룰셋)>
```
- "왜"는 실제로 본 근거로만(실행 상태, 마지막 메시지, PR 리뷰). 모르면 "원인 확인 못 함".
- 이미 끝났는데 기다리는 것처럼 남아 있으면 맨 위에 "끝났는데 안 넘어감"으로 따로.
