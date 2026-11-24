#!/usr/bin/env python3
"""wait-then-act 자체 시험(가짜 gh·orca, 네트워크 안 씀). 실행: wait-then-act selftest"""
import json, os, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.realpath(__file__))
WTA = os.path.join(HERE, "wait-then-act")
T = tempfile.mkdtemp()
gh = os.path.join(T, "gh")
with open(gh, "w") as f:  # FAKE_STATE 값으로 조건 참/거짓 흉내
    f.write("""#!/bin/sh
echo "gh $*" >> "$FAKE/calls"
case "$*" in
  "pr checks 5 -R o/r") [ "$FAKE_STATE" = yes ] && exit 0; exit 8;;
  "pr view 5 -R o/r --json state -q .state") [ "$FAKE_STATE" = yes ] && echo MERGED || echo OPEN;;
  "api repos/o/r -q .permissions.admin") [ "$FAKE_STATE" = yes ] && echo true || echo false;;
  "api repos/o/r/git/ref/tags/v1 -q .ref") [ "$FAKE_STATE" = yes ] && echo refs/tags/v1 && exit 0; echo '{"message":"Not Found"}'; exit 1;;
  *) echo "fake gh: $*" >&2; exit 9;;
esac
""")
orca = os.path.join(T, "orca")
with open(orca, "w") as f:
    f.write("""#!/bin/sh
printf '%s\\n' "$*" >> "$FAKE/orca.log"
case "$2" in
  create) echo '{"ok":true,"result":{"automation":{"id":"auto-123","name":"x","prompt":"p"}}}';;
  edit) [ -n "$FAKE_EDIT_FAIL" ] && { echo '{"ok":false}'; exit 1; }; echo '{"ok":true}';;
  remove) echo '{"ok":true}';;
esac
""")
os.chmod(gh, 0o755); os.chmod(orca, 0o755)


def run(*args, state="no", **env):
    e = {**os.environ, "WTA_GH": gh, "ORCA_BIN": orca, "FAKE": T, "FAKE_STATE": state, **env}
    p = subprocess.run([sys.executable, WTA, *args], capture_output=True, text=True, env=e)
    return p.returncode, json.loads(p.stdout.strip().splitlines()[-1])


FUT, PAST = "2099-01-01T00:00+09:00", "2000-01-01T00:00+09:00"
CASES = [["--cond", "pr-checks", "--repo", "o/r", "--pr", "5"], ["--cond", "pr-merged", "--repo", "o/r", "--pr", "5"],
         ["--cond", "repo-admin", "--repo", "o/r"], ["--cond", "tag", "--repo", "o/r", "--tag", "v1"]]
# 조건 4종: 참이면 rc 0, 아니면 1
for c in CASES:
    assert run("check", *c, state="yes")[0] == 0, c
    assert run("check", *c, state="no")[0] == 1, c
# 입력 오류
assert run("check", "--cond", "pr-merged", "--repo", "o/r")[0] == 2
assert run("check", "--cond", "nope", "--repo", "o/r")[0] == 2
assert run("check", "--cond", "tag", "--repo", "bad repo", "--tag", "v1")[0] == 2
# gate: 조건 맞음 또는 기한 지남
assert run("gate", *CASES[1], "--by", FUT, state="yes")[0] == 0
assert run("gate", *CASES[1], "--by", FUT, state="no")[0] == 1
rc, j = run("gate", *CASES[1], "--by", PAST, state="no")
assert rc == 0 and j["why"] == "기한 지남", j
assert run("due", "--by", PAST)[0] == 0 and run("due", "--by", FUT)[0] == 1
# create dry-run: orca 안 부름
rc, j = run("create", "--bot", "hub-plugin", *CASES[1], "--by", FUT, "--do", "알려줘", "--dry-run", state="yes")
assert rc == 0 and j["dry_run"] and j["met_now"] and "gate" in j["precheck"] and not os.path.exists(os.path.join(T, "orca.log")), j
assert run("create", "--bot", "b", *CASES[1], "--by", PAST, "--do", "x")[0] == 2  # 기한 지난 것 거부
# create: 꺼진 채 만들고 → id 넣은 프롬프트로 고치며 켬
rc, j = run("create", "--bot", "hub-plugin", *CASES[1], "--by", FUT, "--do", "알려줘")
calls = open(os.path.join(T, "orca.log")).read()
assert rc == 0 and j["id"] == "auto-123", j
assert "--disabled" in calls.splitlines()[0] and "automations edit auto-123" in calls and "orca automations remove auto-123" in calls and "--enabled" in calls, calls
# 프롬프트 넣기 실패 → 만든 예약 지움
rc, j = run("create", "--bot", "hub-plugin", *CASES[1], "--by", FUT, "--do", "알려줘", FAKE_EDIT_FAIL="1")
assert rc == 1 and open(os.path.join(T, "orca.log")).read().strip().endswith("automations remove auto-123 --json"), j
print("selftest 통과")
