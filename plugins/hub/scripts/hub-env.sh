# hub 스크립트가 같이 쓰는 설정 (zsh/bash에서 source). 정하는 값: HUB_PRIVATE
#   비공개 메모·로그·지시서를 두는 폴더. 순서: 환경 변수 HUB_PRIVATE → ~/.config/hub/config 의 HUB_PRIVATE=… → 기본 ~/.hub
#   (hc run으로 띄운 세션엔 셸 설정이 안 들어가서, 컴퓨터별 값은 설정 파일에 둔다)
HUB_CONFIG=${HUB_CONFIG:-$HOME/.config/hub/config}
if [ -z "${HUB_PRIVATE:-}" ] && [ -f "$HUB_CONFIG" ]; then
  HUB_PRIVATE=$(sed -n 's/^HUB_PRIVATE=//p' "$HUB_CONFIG" | tail -1)
fi
HUB_PRIVATE=${HUB_PRIVATE:-$HOME/.hub}
HUB_PRIVATE=${HUB_PRIVATE/#\~/$HOME}
mkdir -p "$HUB_PRIVATE/scripts"
export HUB_PRIVATE
