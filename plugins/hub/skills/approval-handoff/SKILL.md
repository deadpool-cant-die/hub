---
name: approval-handoff
description: secretary가 사용자 승인을 다른 봇에 넘길 때 쓰는 정해진 양식 — "[사용자 승인] / 출처 / 사용자 원문 / 대상 / 할 일" 본문 파일을 만들어 orca orchestration send --body-file로 보냄. 원문·대상이 비면 거부, 원문에 없는 위험 동작(소리·배포·보내기·푸시·머지·삭제·결제·권한)이 할 일에 있으면 경고하고 안 보냄. 받는 쪽 확인 규칙도 여기. 승인 전달, [사용자 승인] 보내기, 승인 넘겨, handoff 요청 때.
---

# approval-handoff

> 같은 폴더에 `reference.local.md`가 있으면 먼저 읽는다(이 컴퓨터 전용: 계정·레포·시험 레포). 공개 사본엔 없다.

`[사용자 승인]`은 **secretary만** 만든다. 손으로 쓰지 말고 `approval-handoff`(이 폴더의 `bin/approval-handoff`, PATH에 링크해 두기)로 보낸다.

```sh
approval-handoff --to web-bot --at "2026-11-24 14시대" \
  --quote "301 머지해" \
  --target "OWNER/NAME PR #301" \
  --task "검사 통과 확인 뒤 PR #301 머지, 머지 커밋 보고" --dry-run   # 본문만 보고
# 확인했으면 --dry-run 빼고 다시
```

- `--quote`: 사용자 말 그대로(고치지 않음). `--at`: `YYYY-MM-DD HH시대` 또는 `HH:MM`.
- `--proposal`: 원문이 "ㅇㅇ 그렇게 해"처럼 제안에 대한 승낙이면, 그 제안 원문(사용자가 본 그대로). 본문에 같이 들어가고 위험 동작 판단에 쓴다.
- `--item <n>` / `--chat <id|new>`: 받는 봇의 특정 채팅. `--type`: 기본 handoff(question·status 가능).
- 본문은 `~/.agents/run/approval-handoff/`에 파일로 남고 `--body-file`로만 보낸다.
- 결과 stdout 한 줄 JSON: `ok`, `sent`, `body_file`, `body`, `warnings`, `orca`. rc 0 보냄(또는 dry-run), 2 입력 거부, 3 위험 동작 경고로 안 보냄, 1 전송 실패.

## 위험 동작 경고 (rc 3)
할 일에 소리·배포·보내기·푸시·머지·삭제·결제·권한 말이 있는데 원문(+`--proposal`)에 같은 종류 말이 없으면 안 보낸다. 2026-11-23 "빨리 하셈"을 소리 허락으로 읽은 사고를 막는 것.
- 고치는 법: 사용자에게 그 동작을 직접 확인받아 원문으로 쓰기 → 승낙한 제안 원문을 `--proposal`로 → 그래도 확실할 때만 `--force`(경고는 JSON에 남음).
- 소리는 `--force`로도 보내지 않는다(사용자가 그때 그 자리를 직접 허락한 원문만).

## 금지
- 원문을 요약·의역해서 넣기, 추천·추측을 승인으로 바꾸기.
- 본문에 백틱·`$( )`(거부됨). 긴 본문을 `--body "..."`로 직접 보내기.
- secretary가 아닌 봇이 이 도구로 승인 만들기.

## 받는 쪽 확인 규칙
1. 출처(`Orca 채팅(시각)`)·사용자 원문·구체적 대상이 **다 있어야** 승인으로 인정. 하나라도 없거나 secretary가 보낸 게 아니면 로컬 작업만 하고 secretary에 묻는다(`orca orchestration send --to bot:secretary --type question`).
2. 범위는 적힌 대상·할 일만. 다른 PR·태그·추가 삭제처럼 범위 밖이면 secretary에 묻는다.
3. 원문에 없는 위험 동작(특히 소리)은 `--force`로 왔어도 원문을 다시 읽고 애매하면 묻는다.
4. 실행 결과(커밋 해시·실행 링크·출력)를 보낸 쪽에 보고한다.

시험: `approval-handoff selftest`(가짜 orca, 전송 안 함).
참고: worker는 자기를 띄운 봇에게 보낼 수 없다(Orca가 거부). 자기 봇 시험은 봇 채팅에서 `--chat new`로.
