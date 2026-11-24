#!/usr/bin/env bash
# admin-merge-window 자체 시험(네트워크 안 씀, 가짜 gh). 실행: admin-merge-window selftest
set -u
HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
AMW="$HERE/admin-merge-window"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail=0; ok() { echo "ok  $1"; }; bad() { echo "FAIL $1"; fail=1; }

# 1) GET 응답 → PUT 본문 변환
cat >"$T/get.json" <<'EOF'
{"url":"u","required_status_checks":{"url":"u","strict":true,"contexts":["ci"],"checks":[{"context":"ci","app_id":15368},{"context":"lint","app_id":null}]},
 "required_pull_request_reviews":{"url":"u","dismiss_stale_reviews":true,"require_code_owner_reviews":false,"required_approving_review_count":2,"require_last_push_approval":false,
   "dismissal_restrictions":{"users":[{"login":"a"}],"teams":[{"slug":"t"}],"apps":[]}},
 "required_signatures":{"url":"u","enabled":false},"enforce_admins":{"url":"u","enabled":true},
 "required_linear_history":{"enabled":true},"allow_force_pushes":{"enabled":false},"allow_deletions":{"enabled":false},
 "block_creations":{"enabled":false},"required_conversation_resolution":{"enabled":true},"lock_branch":{"enabled":false},"allow_fork_syncing":{"enabled":false},
 "restrictions":null}
EOF
got=$(jq -c -f "$HERE/to-put.jq" "$T/get.json")
want='{"required_status_checks":{"strict":true,"checks":[{"context":"ci","app_id":15368},{"context":"lint"}]},"enforce_admins":true,"required_pull_request_reviews":{"dismiss_stale_reviews":true,"require_code_owner_reviews":false,"required_approving_review_count":2,"require_last_push_approval":false,"dismissal_restrictions":{"users":["a"],"teams":["t"],"apps":[]}},"restrictions":null,"required_linear_history":true,"allow_force_pushes":false,"allow_deletions":false,"block_creations":false,"required_conversation_resolution":true,"lock_branch":false,"allow_fork_syncing":false,"required_signatures":false}'
[ "$got" = "$want" ] && ok "to-put 변환" || { bad "to-put 변환"; echo "$got"; }

# 가짜 gh: 호출을 기록, 보호 상태를 파일로 흉내. FAKE_MERGE_FAIL=1이면 머지 실패.
cat >"$T/gh" <<'EOF'
#!/usr/bin/env bash
echo "$*" >>"$FAKE_DIR/calls"
case "$*" in
  "api repos/o/r -q .default_branch") echo main;;
  "pr view 1 -R o/r --json state,baseRefName,headRefName,title") echo '{"state":"OPEN","baseRefName":"main","headRefName":"x","title":"t"}';;
  "pr view 2 -R o/r --json state,baseRefName,headRefName,title") echo '{"state":"OPEN","baseRefName":"dev","headRefName":"x","title":"t"}';;
  "api repos/o/r/branches/main/protection") jq --argjson on "$(cat "$FAKE_DIR/ea")" '.enforce_admins.enabled=$on' "$FAKE_DIR/get.json";;
  "api -X DELETE repos/o/r/branches/main/protection/enforce_admins") echo false >"$FAKE_DIR/ea";;
  "api -X POST repos/o/r/branches/main/protection/enforce_admins") echo true >"$FAKE_DIR/ea";;
  "pr merge 1 -R o/r --admin --merge") [ "${FAKE_MERGE_FAIL:-0}" = 1 ] && exit 1; echo merged;;
  "pr view 1 -R o/r --json mergeCommit -q .mergeCommit.oid // \"\"") echo abc123;;
  *) echo "fake gh: 모르는 호출 $*" >&2; exit 9;;
esac
EOF
chmod +x "$T/gh"
export AMW_GH="$T/gh" AMW_STATE="$T/run" FAKE_DIR="$T"
reset() { echo true >"$T/ea"; : >"$T/calls"; }

# 2) 승인 원문 없음 → 거부, gh 호출 없음
reset; out=$("$AMW" --repo o/r --pr 1 --check true --approval "  " 2>/dev/null); rc=$?
[ $rc = 2 ] && [ ! -s "$T/calls" ] && grep -q approval <<<"$out" && ok "승인 없음 거부" || bad "승인 없음 거부 rc=$rc $out"

# 3) 기본 브랜치 아닌 PR → 거부
reset; "$AMW" --repo o/r --pr 2 --check true --approval "머지해" >/dev/null 2>&1; rc=$?
[ $rc = 2 ] && ! grep -q DELETE "$T/calls" && ok "기본 브랜치 외 거부" || bad "기본 브랜치 외 거부 rc=$rc"

# 4) 로컬 검사 실패 → 보호 안 건드림
reset; "$AMW" --repo o/r --pr 1 --check false --approval "머지해" >/dev/null 2>&1; rc=$?
[ $rc = 1 ] && ! grep -q DELETE "$T/calls" && ok "검사 실패면 안 끔" || bad "검사 실패 rc=$rc"

# 5) 정상 경로
reset; out=$("$AMW" --repo o/r --pr 1 --check true --approval "머지해" 2>/dev/null); rc=$?
[ $rc = 0 ] && [ "$(cat "$T/ea")" = true ] && jq -e '.ok and .merged and .merge_commit=="abc123" and .compare=="same" and .off_at!="" and .on_at!=""' <<<"$out" >/dev/null \
  && ok "정상 경로" || bad "정상 경로 rc=$rc $out"

# 6) 머지 실패 → trap이 다시 켬
reset; out=$(FAKE_MERGE_FAIL=1 "$AMW" --repo o/r --pr 1 --check true --approval "머지해" 2>/dev/null); rc=$?
[ $rc = 1 ] && [ "$(cat "$T/ea")" = true ] && jq -e '(.ok|not) and (.merged|not) and .on_at!="" and .compare=="same"' <<<"$out" >/dev/null \
  && ok "머지 실패에도 다시 켬" || bad "머지 실패 trap rc=$rc $out"

# 7) dry-run → 끄지 않음
reset; out=$("$AMW" --repo o/r --pr 1 --check true --approval "머지해" --dry-run 2>/dev/null); rc=$?
[ $rc = 0 ] && ! grep -q DELETE "$T/calls" && jq -e .dry_run <<<"$out" >/dev/null && ok "dry-run" || bad "dry-run rc=$rc"

[ $fail = 0 ] && echo "selftest 통과" || { echo "selftest 실패"; exit 1; }
