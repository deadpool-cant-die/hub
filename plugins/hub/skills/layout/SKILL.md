---
name: layout
description: (Herdr 시절) Herdr 앱 탭·칸 배치 — Orca에는 해당 없음. 새 탭 만들기, 탭 배치(왼쪽 반 head, 오른쪽 반 worker 위아래 쌓기, 4~6개면 두 열 격자, head 없으면 같은 폭)를 tab-layout.sh로, tower 탭 배치를 tower-layout.sh로 맞추기(이미 같으면 변화 없음), 칸 크기·자리·핀·탭 이름. 포커스 이동 없이. Trigger words - 탭 만들어, 탭 배치, 칸 배치, 칸 정리, 레이아웃, 칸 나눠, 반반, 1:1, 칸 크기, 자리 바꿔, 쌓아, 2열, 핀, 탭 이름, tower 배치.
---

# (Herdr 시절) 탭·칸 배치

> **Orca에는 해당 없음.** Orca는 봇·worker 단위로 일하고 칸 배치를 맞출 필요가 없다(`hub:session`). 이 스킬과 `tab-layout.sh`·`tower-layout.sh`·`layout-lib.sh`는 Herdr 앱을 쓸 때만, Herdr를 끌 때 지운다.

> `HUB_SCRIPTS` = 이 플러그인의 `scripts/` 폴더(이 스킬 폴더 기준 `../../scripts`). 예: `HUB_SCRIPTS=<스킬 Base directory>/../../scripts`

스크립트 위치: `${HUB_SCRIPTS}/`. 세션 켜기·다시 켜기는 `hub:session`.

## 0. 원칙
- **화면 포커스를 옮기지 않는다.** `tab.select`·`pane.focus`·`pane.go`·`terminal.show`·`terminal.peek`·`tab.new`의 `focus:true`·`hc attach`(사용자 터미널에서)·앱 창 앞으로 가져오기 금지. 결과는 탭 이름만 알린다.
- **세션을 다시 켜지 않고 진짜 칸을 그대로 옮긴다.** 배치 스크립트는 원하는 모양의 빈 칸(`sleep`)을 `pane.split`으로 만들고, 진짜 세션 칸을 `pane.swap`으로 그 자리에 옮긴 뒤 빈 칸을 닫는다(`layout-lib.sh`). 그래서 칸마다 이름·app·상태가 그대로 보인다.
- **park + `hc attach` 래퍼 칸으로 붙이지 않는다.** 래퍼 칸은 Herdr가 에이전트로 못 알아본다(이름·app·상태가 비어 보임). 옛 방식으로 붙은 래퍼 칸은 스크립트가 진짜 칸으로 되돌린다: 래퍼 칸을 닫고 그 세션에 `hc label <이름> herdr.space=<S> herdr.tab=<T>`를 다시 붙이면 Herdr가 탭에 다시 붙인다.
- **이미 같으면 아무것도 안 한다.** 두 스크립트 모두 여러 번 돌려도 같은 결과. `--check`는 판정만(다르면 종료 코드 2).
- 칸은 같은 크기로(두 칸 1:1, 세 칸 1:1:1).
- head는 자기 탭 안에서만 칸을 늘린다. 다른 탭에 칸을 붙이지 않는다.

## 1. 탭 배치 — tab-layout.sh

규칙: **왼쪽 반 = head, 오른쪽 반 = worker.** worker는 위아래 같은 높이로 쌓고, 4개 이상이면 오른쪽 반을 두 열 격자로(ㅣㅡㅡ ㅣㅡㅡ). head가 없는 탭은 worker를 같은 폭으로 나란히. tower 탭은 따로(2절).

```
worker 1개        worker 2~3개        worker 4~6개              head 없음
┌────┬────┐      ┌────┬────┐        ┌────┬──┬──┐              ┌──┬──┬──┐
│    │    │      │    │ w1 │        │    │w1│w4│              │  │  │  │
│head│ w1 │      │head├────┤        │head├──┼──┤              │w1│w2│w3│
│    │    │      │    │ w2 │        │    │w2│w5│              │  │  │  │
└────┴────┘      └────┴────┘        │    ├──┼──┤              └──┴──┴──┘
  50 : 50          50 : 50          │    │w3│w6│
                                    └────┴──┴──┘
                                     50 : 25 : 25
```
```sh
${HUB_SCRIPTS}/tab-layout.sh [--check] <tab id> [head|- [worker...]]
```
- 이름을 안 주면 탭 칸에서 찾는다: head = 이름이 `-head`로 끝나는 칸, 나머지 = worker(지금 순서대로). head 자리에 `-`를 주면 head 없는 탭.
- 이미 그 모양이면 "변화 없음". `--check`는 판정만(다르면 종료 코드 2).
- 다시 짤 때 세션 칸은 자리만 바뀐다(다시 켜지 않음). 목록에 없는 이름 없는 셸 칸은 park(종료 안 함). 래퍼 칸이 남아 있으면 모양이 같아도 "다름"으로 보고 되돌린다.
- `relaunch.sh`는 끝에 이 스크립트(tower면 tower-layout.sh)를 불러 새 칸 자리를 맞춘다.
- Hub 탭 전부 맞추기:
  ```sh
  X=${HUB_SCRIPTS}
  herdr-app ls | jq -r '.spaces[]|select(.name=="Hub")|.tabs[]|"\(.id)\t\(.name)"' | while IFS=$'\t' read id nm; do
    [[ $nm == tower ]] && $X/tower-layout.sh || $X/tab-layout.sh $id; done
  ```

## 2. tower 탭 — tower-layout.sh

```
┌─────────────┬───────────────┐  15%
│ hub-resource│ hub-atlassian │
├─────────────┼───────────────┤
│  hub-admin  │ hub-secretary │  85%
└─────────────┴───────────────┘
```
```sh
${HUB_SCRIPTS}/tower-layout.sh [--check]
```
- 이름이 `tower`인 탭을 찾아 맞추고, 네 칸 핀·탭 이름까지 확인한다. 기준 칸은 hub-admin(이 탭에 있어야 함).
- 모양이 바뀌면 이 스크립트와 `herdr_tree.py`의 `shape` 판정을 같이 고친다.

## 3. 손으로 하는 명령

```sh
herdr-app do tab.new '{"name":"<탭 이름 (레포)>","space":"<S>","folder":"<~/Hub 절대 경로>","focus":false}'  # 빈 셸 하나 생김
herdr-app do tab.rename '{"id":"<T>","name":"<이름>"}'
herdr-app do layout.resize '{"id":"<pane id>","weight":0.5}'
herdr-app do pane.swap '{"pane":"<pane id>","target":"<pane id>"}'
herdr-app do pane.split '{"direction":"down","pane":"<pane id>","argv":["sleep","3600"]}'   # 빈 칸
herdr-app do pane.swap '{"pane":"<진짜 칸>","target":"<빈 칸>"}'                          # 진짜 칸을 빈 칸 자리로
hc label <이름> herdr.space=<S> herdr.tab=<T>                                              # park된 세션을 탭에 다시 붙이기
herdr-app do terminal.park '{"terminal":"<t>"}'     # 칸만 치움, 세션은 계속(라벨이 지워짐 → 위 hc label로 다시 붙임)
herdr-app do terminal.pin '{"terminal":"<t>","pinned":true}'   # 핀은 터미널에 붙음: 다시 켜면 또
herdr-app shot /tmp/shot.png                           # 눈으로 확인
```
- 탭 트리(칸 구조·크기)는 `python3 -I ${HUB_SCRIPTS}/herdr_tree.py tabshape|shape …` 또는 `~/.local/state/herdr-core/default/docs.json`.
- 구조를 바꾸는 방법은 "빈 칸 만들기 → 진짜 칸과 자리 바꾸기 → 빈 칸 닫기"다. 스크립트가 이걸 한다.
- `tab.new`·라벨에 스페이스를 빠뜨리면 `~` 스페이스에 생긴다. 인수 이름이 틀리면 오류(`herdr-app commands`로 확인).
- 옛 `herdr pane …`(TUI용)은 앱 안에서 실패한다.
