---
name: wait-then-act
description: GitHub 조건(PR 검사 통과·PR 머지됨·레포 admin 권한·태그 생김)을 Orca 예약(cron)으로 gh 직접 확인하다가, 맞으면 지시한 일을 하고 예약을 스스로 지움. 기한(--by) 넘으면 사용자에게 알리고 지움. GitHub를 Orca Cloud에 잇지 않을 때 이벤트 대신 쓴다. 기다렸다 처리, 머지되면, 검사 통과하면, 태그 생기면, 권한 생기면 요청 때.
---

# wait-then-act

> 같은 폴더에 `reference.local.md`가 있으면 먼저 읽는다(이 컴퓨터 전용: 계정·레포·시험 레포). 공개 사본엔 없다.

```sh
wait-then-act create --bot web-bot --cond pr-checks --repo OWNER/NAME --pr 301 \
  --by 2026-11-25T18:00+09:00 --do "secretary에 '#301 검사 통과' 알림" [--every "*/10 * * * *"] [--dry-run]
wait-then-act check --cond pr-merged --repo OWNER/NAME --pr 12      # 지금 맞는지만(rc 0 맞음, 1 아님)
```
(이 폴더의 `bin/wait-then-act`, PATH에 링크해 두기. 필요: `gh`, `orca`)

조건(각각 gh 한 줄):
| `--cond` | 인자 | 확인 |
|---|---|---|
| `pr-checks` | `--pr` | `gh pr checks N -R R` rc 0(검사 없음·대기·실패는 아님) |
| `pr-merged` | `--pr` | `gh pr view N -R R --json state` = MERGED |
| `repo-admin` | | `gh api repos/R` `.permissions.admin` = true |
| `tag` | `--tag` | `gh api repos/R/git/ref/tags/T` 정확히 그 이름 |

만드는 방식: `orca automations create --bot <봇> --trigger <cron> --precheck "wait-then-act gate ..." --disabled`로 만들고, 응답에서 id를 받아 그 id를 넣은 프롬프트로 `automations edit --prompt ... --enabled`. 넣기가 실패하면 만든 예약을 지운다.
- precheck(`gate`)가 조건이 아직이고 기한 전이면 실행을 건너뛴다(에이전트 안 뜸, 기록엔 skipped_precheck).
- 실행되면 프롬프트대로: 조건 다시 확인 → 맞으면 할 일 → 기한 지났으면 알리기만 → 마지막에 `orca automations remove <id>`.
- `--dry-run`: 지금 조건 결과, precheck, create 명령, 프롬프트만 보여 줌.
- 결과 stdout 한 줄 JSON: `ok`, `id`, `met_now`, `precheck`.

## 금지
- Orca Cloud에 잇지 않기로 한 GitHub를 커넥터 이벤트(`--on github.*`)로 기다리기. 예약 + gh로만.
- 남의·회사 레포 쓰기(머지·태그·댓글·보내기)를 `--do`에 넣을 땐 [사용자 승인] 원문·대상을 `--do`에 같이 적는다. 없으면 알림만.
- 1분 cron(`* * * * *`)은 시험 때만. 기본 10분.

## 막혔을 때
- 남은 예약: `orca automations list`에서 이름 `wait:`로 찾아 `orca automations remove <id>`.
- `orca automations run <id>`는 precheck를 건너뛴다(조건과 상관없이 돎).

시험: `wait-then-act selftest`(가짜 gh·orca).
