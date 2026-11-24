#!/usr/bin/env python3
"""approval-handoff 자체 시험(전송 안 함, 가짜 orca). 실행: approval-handoff selftest"""
import json, os, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.realpath(__file__))
T = tempfile.mkdtemp()
fake = os.path.join(T, "orca")
with open(fake, "w") as f:
    f.write('#!/bin/sh\necho "$@" >> "%s/calls"\necho \'{"ok":true,"result":{"id":"msg_fake"}}\'\n' % T)
os.chmod(fake, 0o755)
ENV = {**os.environ, "ORCA_BIN": fake, "APPROVAL_HANDOFF_STATE": T}
BASE = ["--at", "2026-11-24 14시대", "--to", "bot:web-bot", "--target", "PR #301 (OWNER/NAME)"]


def run(*args):
    p = subprocess.run([sys.executable, os.path.join(HERE, "approval-handoff"), *args], capture_output=True, text=True, env=ENV)
    return p.returncode, json.loads(p.stdout)


def calls():
    try:
        return open(os.path.join(T, "calls")).read()
    except OSError:
        return ""


# 빈 원문·빈 대상 거부
rc, j = run(*BASE, "--quote", " ", "--task", "리뷰 반영")
assert rc == 2 and "--quote" in j["error"], j
rc, j = run("--at", "2026-11-24 14시대", "--to", "web-bot", "--quote", "해", "--task", "리뷰", "--target", "")
assert rc == 2 and "--target" in j["error"], j
# 시각 형식, 백틱·$( ) 거부
rc, j = run(*BASE[2:], "--at", "오늘", "--quote", "해", "--task", "리뷰")
assert rc == 2 and "--at" in j["error"], j
rc, j = run(*BASE, "--quote", "해", "--task", "`rm -rf ~` 리뷰")
assert rc == 2 and "백틱" in j["error"], j
rc, j = run(*BASE, "--quote", "$(id) 해", "--task", "리뷰")
assert rc == 2, j

# 오늘 사고: "빨리 하셈"으로 소리 내기 → 경고, 안 보냄
rc, j = run(*BASE, "--quote", "빨리 하셈", "--task", "사무실 맥 음소거 풀고 소리 시험")
assert rc == 3 and j["warnings"] == ["소리"] and not j["sent"], j
rc, j = run(*BASE, "--quote", "빨리 하셈", "--task", "스피커로 소리 시험", "--force", "--dry-run")
assert rc == 3 and "--force로도" in j["error"], j
# 원문에 "그렇게 하자"만 있고 할 일이 머지 → 경고
rc, j = run(*BASE, "--quote", "ㅇㅇ 좋은 듯. 그렇게 하자꾸나", "--task", "PR #301 머지")
assert rc == 3 and j["warnings"] == ["머지"], j
# 승인한 제안 원문에 머지가 있으면 통과
rc, j = run(*BASE, "--quote", "ㅇㅇ 좋은 듯. 그렇게 하자꾸나", "--proposal", "검사 통과하면 #301 머지할게요", "--task", "PR #301 머지", "--dry-run")
assert rc == 0 and j["warnings"] == [] and "승인한 제안 원문" in j["body"], j
# 원문에 명시돼 있으면 통과, --force는 경고 남기고 진행
rc, j = run(*BASE, "--quote", "301 머지해", "--task", "PR #301 머지", "--dry-run")
assert rc == 0 and j["dry_run"] and not j["sent"], j
rc, j = run(*BASE, "--quote", "빨리 하셈", "--task", "운영 배포", "--force", "--dry-run")
assert rc == 0 and j["warnings"] == ["배포"], j
assert calls() == "", "dry-run인데 orca를 불렀음"

# 본문 양식
b = j["body"].splitlines()
assert b[0] == "[사용자 승인]" and b[1] == "출처: Orca 채팅(2026-11-24 14시대)" and b[2] == '사용자 원문: "빨리 하셈"', b
assert b[3].startswith("대상: PR #301") and b[4] == "할 일: 운영 배포", b
assert open(j["body_file"]).read() == j["body"]

# 오탐 회귀(2026-11-24 secretary 실사용): 보고·질문 표현, 명사로만 쓴 말은 위험 동작이 아님
MERGE_OK = ["--quote", "ㅇㅇ.", "--proposal", "example-site #47: 머지할까요?"]
rc, j = run(*BASE, *MERGE_OK, "--task", "#47(담당자 배포 기록 옮김, 문서만)을 머지. 머지 커밋을 보고. "
            "#38·#40을 닫거나 댓글 다는 건 범위 밖이라 하지 말고, 닫을지 secretary에 물을 것.", "--dry-run")
assert rc == 0 and j["warnings"] == [], j
rc, j = run(*BASE, "--quote", "확인해 줘", "--task", "머지 커밋 해시를 secretary에 알려. 카드 단위 캡처, payload 확인, 목록 재생성, dropdown 고침", "--dry-run")
assert rc == 0 and j["warnings"] == [], j
# 진짜 보내기는 계속 걸림
for t, k in [("결과를 gchat으로 보내", "보내기"), ("담당자에게 메일 전송", "보내기"), ("send it to slack", "보내기"), ("PR #301 merge", "머지")]:
    rc, j = run(*BASE, "--quote", "확인해 줘", "--task", t)
    assert rc == 3 and j["warnings"] == [k], (t, j)


# 실제 전송 경로(가짜 orca): --body-file로만, handoff 타입
rc, j = run(*BASE, "--quote", "리뷰 반영해", "--task", "리뷰 반영 커밋", "--item", "3")
assert rc == 0 and j["sent"], j
c = calls()
assert "--type handoff" in c and "--to bot:web-bot" in c and "--body-file" in c and "--item 3" in c and "--body " not in c, c
print("selftest 통과")
