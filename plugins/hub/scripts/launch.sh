#!/bin/zsh
# usage: launch.sh <이름> <cwd> <space id> <tab id> <model> <effort> [--resume <session id>] [첫 지시]
# Claude Code 세션을 부모 없이(--no-parent), 잃어도 셸로 남게(--keep) 띄우고 Herdr 탭에 붙인다.
# 모델은 플래그로만 정한다(/model은 ~/.claude/settings.json 기본값을 바꾼다).
set -e
name=$1 cwd=$2 S=$3 T=$4 model=$5 effort=$6; shift 6
args=(claude --dangerously-skip-permissions --model "$model" --effort "$effort")
if [[ ${1:-} == --resume ]]; then args+=(--resume "$2"); shift 2; fi
[[ -n ${1:-} ]] && args+=("$1")
grep -q '"model": "opus"' ~/.claude/settings.json || echo "경고: ~/.claude/settings.json 기본 모델이 opus가 아님 — 세션 안 /model 금지(2026-11-19 사고), 되돌릴 것" >&2  # 재발 방지
env -u HC_TERMINAL_ID -u HC_SCOPE hc run --bg --json --no-parent --keep --name "$name" --cwd "$cwd" \
  --label herdr.space="$S" --label herdr.tab="$T" -- "${args[@]}"
