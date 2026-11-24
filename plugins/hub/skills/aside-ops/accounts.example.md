# Aside 계정 지도 (예시 — 개인 파일로 복사해 채우기)

복사: `mkdir -p ~/.config/aside-ops && cp accounts.example.md ~/.config/aside-ops/accounts.md`
(다른 곳에 두려면 환경 변수 `ASIDE_OPS_ACCOUNTS=<경로>`). 이 파일은 공개 레포에 올리지 않는다.
비밀번호·토큰·키 값은 적지 않는다(브라우저 보관함에만).

## 브라우저
- Aside 계정 `u0` = <업무 이메일>, 브라우저 프로필: <프로필 이름>. `--account`·`--profile`은 보통 안 넘긴다.

## Google 로그인 순서(uid = Gmail `/mail/u/<uid>/`)
| uid | 계정 | 쓰임 |
|---|---|---|
| 0 | <업무 이메일> | 업무 기본 |
| 1 | <개인 이메일> | 개인 |

uid 순서는 로그인 순서라 바뀔 수 있다. Gmail을 열기 전 `aside-ops accounts`로 다시 본다.

## 사이트별
| 사이트 | 계정 | 들어가는 법 | 메모 |
|---|---|---|---|
| GitHub | <아이디> | 기존 세션. gh는 기기 코드 + Aside 승인 | |
| <사이트> | <계정> | 기존 세션 → OAuth → 이메일 | |

## 규칙
1. 로그인·계정이 필요하면 먼저 `aside-ops memory "<사이트> login"`과 이 표를 본다.
2. 표에 있으면 그대로 쓴다. 없거나 틀리면 성공한 뒤 표에 한 줄 더한다.
3. 업무냐 개인이냐 문맥으로 안 정해지면 멈추고 묻는다.
