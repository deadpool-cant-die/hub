#!/bin/zsh
[ -n "$ZSH_VERSION" ] || exec zsh "$0" "$@"  # bash·sh로 불러도 zsh로(bash로는 배열 문법이 깨져 0개 검사가 됨)
# 공개 레포에 올리기 전 검사: 비밀값 모양, IP·.local 호스트, 개인 경로, (있으면) blocked-words.local.txt의 금지어.
# 사내 제품 이름도 금지(대소문자 무시, 글자별 [Xx]로 써서 이 파일 자체가 걸리지 않게).
# usage: scripts/check-public.sh   (git에 올라갈 파일만 검사, *.local.md는 .gitignore라 제외) — 하나라도 걸리면 종료 코드 1
cd ${0:A:h}/..
files=(${(f)"$(git ls-files -co --exclude-standard)"})
pat='(sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{20,}|github_pat_|xox[bp]-|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY|(api[_-]?key|token|password|secret)\s*[:=]\s*["'"'"'][^"'"'"' ]{8,}|([0-9]{1,3}\.){3}[0-9]{1,3}|[A-Za-z0-9-]\.local([^./a-z]|$)|/Users/[a-z]|/home/[a-z]|[Cc][Ll][Aa][Ww][Pp][Oo][Dd])'
# 회사·개인 전용 금지어(회사 이름, 사내 도메인, 사람 이름 등)는 공개하면 안 되니 git이 무시하는 파일에 한 줄에 하나씩 둔다
[[ -f scripts/blocked-words.local.txt ]] && pat="${pat%)}|$(grep -v '^#' scripts/blocked-words.local.txt | grep -v '^$' | paste -sd'|' -))"
hits=$(grep -nEH "$pat" $files 2>/dev/null | grep -v '^scripts/check-public.sh:')
[[ -z $hits ]] && { echo "check-public: 걸린 것 없음 (${#files}개 파일)"; exit 0; }
echo "$hits"; echo "check-public: 위 줄을 고치거나 *.local.md로 옮기세요"; exit 1
