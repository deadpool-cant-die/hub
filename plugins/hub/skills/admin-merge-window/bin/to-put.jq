# GET .../branches/<b>/protection 응답 → PUT 같은 주소 본문. required_signatures는 별도 주소라 여기 없음.
def logins: [.users[]?.login];
def slugs(k): [.[k][]?.slug];
def actors: {users: logins, teams: slugs("teams"), apps: slugs("apps")};
def on(k): (.[k].enabled // false);
{
  required_status_checks: (if .required_status_checks then
      {strict: (.required_status_checks.strict // false),
       checks: [(.required_status_checks.checks // [])[] | {context} + (if .app_id then {app_id} else {} end)]}
    else null end),
  enforce_admins: on("enforce_admins"),
  required_pull_request_reviews: (if .required_pull_request_reviews then
      (.required_pull_request_reviews
       | {dismiss_stale_reviews: (.dismiss_stale_reviews // false),
          require_code_owner_reviews: (.require_code_owner_reviews // false),
          required_approving_review_count: (.required_approving_review_count // 0),
          require_last_push_approval: (.require_last_push_approval // false)}
         + (if .dismissal_restrictions then {dismissal_restrictions: (.dismissal_restrictions | actors)} else {} end)
         + (if .bypass_pull_request_allowances then {bypass_pull_request_allowances: (.bypass_pull_request_allowances | actors)} else {} end))
    else null end),
  restrictions: (if .restrictions then (.restrictions | actors) else null end),
  required_linear_history: on("required_linear_history"),
  allow_force_pushes: on("allow_force_pushes"),
  allow_deletions: on("allow_deletions"),
  block_creations: on("block_creations"),
  required_conversation_resolution: on("required_conversation_resolution"),
  lock_branch: on("lock_branch"),
  allow_fork_syncing: on("allow_fork_syncing"),
  required_signatures: on("required_signatures")
}
