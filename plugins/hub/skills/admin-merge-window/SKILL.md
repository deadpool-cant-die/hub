---
name: admin-merge-window
description: GitHub 기본 브랜치 보호의 enforce_admins만 잠깐 끄고 PR을 admin 머지한 뒤 바로 켬 — 보호 설정 저장, 로컬 검사 통과 확인, 끈·켠 시각 기록, trap으로 실패·중단에도 다시 켬, 끝나면 저장본과 비교해 다르면 되돌림, 결과 JSON. 보호 잠깐 해제 머지, admin 머지, enforce_admins, 리뷰 없이 머지 요청 때. 사용자 승인 원문 필수.
---

# admin-merge-window

> 같은 폴더에 `reference.local.md`가 있으면 먼저 읽는다(이 컴퓨터 전용: 계정·레포·시험 레포). 공개 사본엔 없다.

```sh
admin-merge-window --repo OWNER/NAME --pr 123 \
  --approval "<사용자 원문 그대로>" \
  --check "npm run check" [--method merge|squash|rebase] [--dry-run]
```
(이 폴더의 `bin/admin-merge-window`, PATH에 링크해 두기. 필요: `gh`(admin 권한), `jq`)

순서: PR이 열려 있고 base가 기본 브랜치인지 확인 → 보호 설정 전체를 `~/.agents/run/admin-merge-window/<시각>-<레포>-<PR>/protection-before.json`에 저장 → `--check`(현재 폴더에서) 통과 확인 → enforce_admins 끔(시각) → `gh pr merge --admin` → 켬(시각) → 지금 보호 설정을 저장본과 비교, 다르면 크게 경고하고 저장본으로 PUT.

- trap(EXIT·INT·TERM·HUP)이 어떤 경우에도 다시 켠다. 켜기는 5번까지 재시도, 그래도 실패하면 손으로 켤 명령을 크게 찍는다. 중단 신호는 지금 돌던 gh 명령이 끝난 뒤 처리된다.
- enforce_admins가 원래 꺼져 있었으면 끄고 켜지 않고 머지만 한다(원래 상태 유지).
- `--dry-run`: 저장·검사까지만, 끄지도 머지하지도 않음.
- 결과 마지막 줄 JSON: `ok`, `off_at`, `on_at`, `merged`, `merge_commit`, `compare`(same·restored·restore_failed·read_failed), `diff`, `dir`, `error`. rc 0 성공, 1 실패, 2 입력 거부.
- `admin-merge-window restore --repo R --from <저장본.json>`: 저장본으로 손 복구.

## 금지
- `--approval` 없이(거부됨), 또는 [사용자 승인](approval-handoff 규칙)에 그 레포·PR이 없는데 쓰기.
- 기본 브랜치 외 브랜치 보호 건드리기(base가 다르면 거부).
- 보호가 없는 브랜치에 쓰기(필요 없음, 거부됨). 다른 보호 항목(리뷰 수·검사)을 바꾸기.
- 남의·회사 레포로 시험하기. 시험은 내 개인 시험 레포에서(이름은 `reference.local.md`).

## 막혔을 때
- `compare: restore_failed` 또는 켜기 실패: 바로 `restore`로 복구하고 secretary에 보고(저장본 경로 포함).
- `보호 설정을 못 읽음`: admin 권한이 없거나 보호가 없음. 권한 문제면 레포 관리자에게.

시험: `admin-merge-window selftest`(가짜 gh, 네트워크 안 씀).
