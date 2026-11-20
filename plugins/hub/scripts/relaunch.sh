#!/bin/zsh
# 세션 하나를 같은 이름·같은 탭·같은 대화(resume)로 다시 켠다.  usage: relaunch.sh <이름>
# - 정보: 살아 있으면 hc get(argv·폴더·탭 라벨), 없으면 세션 명단 표(HUB_SESSIONS_TABLE).
# - 같은 대화가 다른 곳에 이미 떠 있으면(pgrep "--resume <id>" / "resume <id>") 아무것도 안 하고 거부한다.
# - 옛 칸을 먼저 끄고 나서 켠다(같은 대화 두 칸 금지). 첫 지시(프롬프트)는 다시 보내지 않는다.
# - 호출한 세션 자신이면 독립 터미널로 넘겨, 지금 응답이 끝난 뒤 실행된다.
# - 질문 자동 처리: 폴더 신뢰 → Yes, Codex 업데이트 → Skip, Codex 훅 확인 → Trust all and continue
#   (우리가 깐 훅만 있다고 사용자가 승인한 환경 기준. 아니면 HUB_TRUST_CODEX_HOOKS=0 → "Continue without trusting")
# - Claude는 옛 argv의 NODE_EXTRA_CA_CERTS(사내 CA 등)를 그대로 넘긴다. 없으면 지금 환경의 값.
# - OK/FAIL은 화면 너비와 상관없이 hc get의 status·foreground로 판정. 끝에 tower 탭이면 tower-layout.sh, 다른 탭이면 tab-layout.sh로 칸을 맞춘다.
name=${1:?usage: relaunch.sh <이름>}
H() { env -u HC_TERMINAL_ID -u HC_SCOPE hc "$@"; }
D=${0:A:h}; source $D/hub-env.sh; LOG=${HUB_LOG:-$HUB_PRIVATE/scripts/relaunch.log}
# 세션 명단 표(꺼진 세션용): 기본은 공용 메모리의 가장 최근 reference-hub-sessions-*.md
MEM=${HUB_SESSIONS_TABLE:-$(ls -t $HOME/.agents/memory/reference-hub-sessions-*.md 2>/dev/null | head -1)}
TOWER=$(herdr-app ls | jq -r '[.spaces[].tabs[]|select(.name=="tower")][0].id // empty')
say() { print -r -- "$(date +%H:%M:%S) $name $*" | tee -a $LOG; }
fail() { say "FAIL: $*"; [[ -n $RELAUNCH_DETACHED ]] && H send hub-admin "[relaunch] FAIL $name: $*" >/dev/null; exit 1; }

j=$(H get $name --json 2>/dev/null | tr -d '\000-\010\013\014\016-\037')
if [[ -n $j ]]; then
  addr=$(jq -r .address <<<"$j"); fgpid=$(jq -r '.foreground.pid // empty' <<<"$j")
  read tool model effort id <<<"$(python3 -I -c '
import json,sys
d=json.load(sys.stdin); a=d.get("argv") or []; l=d.get("labels") or {}
def after(k): return a[a.index(k)+1] if k in a and a.index(k)+1 < len(a) else ""
if "codex" in a: print("codex - -", after("resume"))
else: print("claude", after("--model") or "opus", after("--effort") or "medium", after("--resume") or l.get("revive.session",""))' <<<"$j")"
  [[ -z $id || $id == null ]] && id=$(jq -r '.labels["revive.session"] // empty' <<<"$j")
  cwd=$(jq -r '.labels["revive.cwd"] // .foreground.cwd // .cwd' <<<"$j")
  CA=$(jq -r '[.argv[]|select(startswith("NODE_EXTRA_CA_CERTS="))][0] // "" | sub("^NODE_EXTRA_CA_CERTS=";"")' <<<"$j")
  S=$(jq -r '.labels["herdr.space"] // empty' <<<"$j"); T=$(jq -r '.labels["herdr.tab"] // empty' <<<"$j")
else
  read tool model effort id cwd tabname <<<"$(python3 -I - "$MEM" "$name" <<'PY'
import os, sys
sec = tab = None
for line in open(sys.argv[1]):
    if line.startswith('## '): sec = 'tower' if 'tower' in line else 'tabs'
    if not line.startswith('|'): continue
    c = [x.strip() for x in line.strip().strip('|').split('|')]
    if len(c) < 5 or c[0] in ('이름', '탭') or set(c[0]) <= set('-:'): continue
    if sec == 'tower': tab, (n, tool, cwd, sid) = 'tower', c[:4]
    else:
        tab = tab if c[0] == '〃' else c[0]
        n, tool, cwd, sid = c[1:5]
    if n != sys.argv[2]: continue
    t = tool.split()
    kind = 'codex' if t[0] == 'Codex' else 'claude'
    model = t[1].lower() if kind == 'claude' and len(t) > 1 else 'opus'
    effort = t[2] if len(t) > 2 and t[2] in ('low', 'medium', 'high') else 'medium'
    last = (kind, model, effort, '' if sid == '없음' else sid, os.path.expanduser(cwd), tab)  # 같은 이름이 여러 번이면 아래(나중) 줄
if 'last' in dir(): print(*last)
PY
)"
  [[ -z $tool ]] && fail "살아 있지 않고 메모리 표에도 없음"
  read S T <<<"$(herdr-app ls | jq -r --arg n "$tabname" '.spaces[] as $s|$s.tabs[]|select(.name==$n)|"\($s.id) \(.id)"' | head -1)"
fi
[[ -z $id ]] && fail "이어받을 대화 id가 없음"
# 탭 라벨이 없으면(attach 래퍼 칸으로 보이는 세션) 칸 트리에서 찾는다
kind=direct; f=$(python3 -I $D/herdr_tree.py find $name 2>/dev/null) && { read fs ft fp kind <<<"$f"; S=${S:-$fs}; T=${T:-$ft}; }
# hub-admin·hub-secretary는 Claude Code(Opus)만 허용 (2026-11-19 사용자 지시)
[[ $name == (hub-admin|hub-secretary) && $tool != claude ]] && fail "$name 은 Claude만 허용(지금 $tool)"
# 모델은 세션별 --model 플래그로만 고정(settings.json 기본값은 opus 유지, 세션 안 /model 금지). 2026-11-19 사용자: hub-secretary만 sonnet
[[ $name == hub-admin ]] && model=opus
[[ $name == hub-secretary ]] && model=sonnet
pat="--resume $id"; [[ $tool == codex ]] && pat="resume $id"

# 같은 대화가 이 세션 말고 다른 곳에 떠 있으면 거부
others=$(pgrep -f -- "$pat" | grep -vx "${fgpid:-x}")
[[ -n $others ]] && fail "같은 대화($id)가 이미 다른 곳에 떠 있음(pid $others) — 실행 거부"

# 자기 자신이면 독립 실행으로 넘김
if [[ -z $RELAUNCH_DETACHED && -n $addr && $addr == $HC_TERMINAL_ID ]]; then
  H run --bg --no-parent --name relaunch-$name -- env RELAUNCH_DETACHED=1 $0 $name >/dev/null && say "자기 자신: 이 응답이 끝나면 다시 켜짐(로그 $LOG)"; exit 0
fi

# 일하는 중이면 끝날 때까지(최대 5분) 기다렸다가 끈다
if [[ -n $addr ]]; then
  for i in {1..150}; do [[ $(H get $addr --json | jq -r '.status.state // ""') != working ]] && break; /bin/sleep 2; done
  /bin/sleep 2; H kill $addr >/dev/null 2>&1
  for i in {1..20}; do [[ $(H get $addr --json 2>/dev/null | jq -r '.state // "gone"') != live ]] && break; /bin/sleep 1; done
  [[ $(H get $addr --json 2>/dev/null | jq -r '.state // "gone"') == live ]] && fail "옛 칸($addr)이 안 꺼짐"
  /bin/sleep 1; others=$(pgrep -f -- "$pat"); [[ -n $others ]] && fail "끈 뒤에도 같은 대화가 떠 있음(pid $others) — 실행 거부"
fi

if [[ $tool == codex ]]; then argv=(codex --dangerously-bypass-approvals-and-sandbox resume $id)
else [[ -n $model && -n $effort && $model != -* && $effort != -* ]] || fail "모델·effort를 못 읽음"
  CA=${CA:-$NODE_EXTRA_CA_CERTS}; argv=(${CA:+env} ${CA:+NODE_EXTRA_CA_CERTS=$CA} claude --dangerously-skip-permissions --model $model --effort $effort --resume $id); fi
labels=(); [[ $kind == direct && -n $S && -n $T ]] && labels=(--label herdr.space=$S --label herdr.tab=$T)
H run --bg --json --no-parent --keep --name $name --cwd "$cwd" $labels -- $argv >/dev/null || fail "hc run 실패"

pick() { # 화면의 선택지에서 글자가 든 줄로 커서를 옮겨 Enter
  local n=$(H read $name --lines 0 | python3 -I -c '
import sys; L=sys.stdin.read().splitlines(); want=sys.argv[1]
opt=lambda l: l.strip().lstrip("❯›>*· 0123456789.)").startswith(want)  # 번호 있든 없든 선택지 줄
tgt=[i for i,l in enumerate(L) if opt(l)]
cur=[i for i,l in enumerate(L) if ("❯" in l or "›" in l) and tgt and abs(i-tgt[0]) <= 6]  # 입력창 › 말고 선택지 근처 커서
print(tgt[0]-cur[0] if cur and tgt else "x")' "$1")
  [[ $n == x ]] && return 1
  local k=down; (( n < 0 )) && { k=up; n=$(( -n )); }
  repeat $n H keys $name $k >/dev/null; H keys $name enter >/dev/null; }
ok=; for i in {1..60}; do /bin/sleep 2
  g=$(H get $name --json 2>/dev/null) || continue
  scr=$(H read $name --lines 0 2>/dev/null | tr -d ' \n')
  if [[ $scr == *trustthisfolder* ]]; then pick "Yes"; continue; fi
  if [[ $scr == *Updateavailable* && $tool == codex ]]; then pick "Skip" ; continue; fi
  if [[ $scr == *Hooksneedreview* ]]; then [[ ${HUB_TRUST_CODEX_HOOKS:-1} == 1 ]] && pick "Trust all and continue" || pick "Continue without trusting"; continue; fi
  fg=$(jq -r '.foreground.name // ""' <<<"$g"); st=$(jq -r '.status.state // ""' <<<"$g")
  [[ $fg != (zsh|bash|sh) && $st == (idle|done|working) ]] && { ok=1; break; }
done
new=$(H get $name --json 2>/dev/null | jq -r .address)
[[ -z $ok ]] && fail "준비 안 됨(새 주소 $new). 화면 끝: $(H read $name --lines 0 | grep -v '^\s*$' | tail -3 | tr '\n' ' ')"
msg="OK: $addr → $new, $tool${model:+ $model} ${effort} resume $id, 탭 ${T:-없음}($kind)"
if [[ $T == $TOWER || $kind == wrapper ]]; then msg+=" / tower 배치: $($D/tower-layout.sh 2>&1 | tail -1)"
elif [[ -n $T ]]; then msg+=" / 탭 배치: $($D/tab-layout.sh $T 2>&1 | tail -1)"; fi
say "$msg"
[[ -n $RELAUNCH_DETACHED ]] && H send $name "[relaunch] 다시 켜짐: $msg" >/dev/null
grep -q '"model": "opus"' ~/.claude/settings.json || echo "경고: ~/.claude/settings.json 기본 모델이 opus가 아님 — 세션 안 /model 금지(2026-11-19 사고), 되돌릴 것" >&2  # 재발 방지
exit 0
