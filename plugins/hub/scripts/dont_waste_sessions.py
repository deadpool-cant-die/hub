#!/usr/bin/env python3
"""놀고 있는 에이전트 세션을 찾아 끈다(hub:dont-waste-sessions).

usage:
  dont_waste_sessions.py sweep [--dry-run]   한 번 훑기 (--dry-run: 끌 목록만 출력)
  dont_waste_sessions.py loop <분>           <분>마다 sweep (on이 이걸 띄움)

끄는 조건(모두 맞아야 끔):
  - 에이전트(상태를 알리는 터미널)이고 이름이 있음
  - 상태가 idle 또는 done이고, 마지막 상태 변화가 DWS_IDLE_MIN분(기본 120) 이상 전
끄지 않는 것: 핀, tower 탭 칸, 이름이 -head로 끝나는 칸, hub-* tower 이름, working·blocked,
  화면이 사용자 답을 기다리는 질문(선택지·y/n·신뢰·훅·업데이트), 자식 세션이 있는 것, 이 스크립트를 부른 세션.
끈 세션은 로그에 이름·resume id·폴더·탭을 남긴다(relaunch.sh <이름>로 되살릴 수 있게).
"""
import json, os, subprocess, sys, time

ENV = {k: v for k, v in os.environ.items() if k not in ('HC_TERMINAL_ID', 'HC_SCOPE')}
IDLE_MIN = float(os.environ.get('DWS_IDLE_MIN', '120'))
LOG = os.path.expanduser(os.environ.get('DWS_LOG', '~/Hub/private/scripts/dont-waste-sessions.log'))
TOWER_NAMES = {'hub-admin', 'hub-secretary', 'hub-atlassian', 'hub-resource', 'hub-chat'}
ASKING = ('Doyouwant', '❯1.', '›1.', '(y/n)', '[Y/n]', '[y/N]', 'trustthisfolder', 'Hooksneedreview',
          'Updateavailable', 'Pressenter', 'Enter to confirm', 'Entertoconfirm')
ME = os.environ.get('HC_TERMINAL_ID', '')


def hc(*a):
    return subprocess.run(['hc', *a], capture_output=True, text=True, env=ENV)


def get(a):
    r = hc('get', a, '--json')
    return json.loads(r.stdout) if r.returncode == 0 and r.stdout.strip() else {}


def tower_tab():
    try:
        sp = json.loads(subprocess.run(['herdr-app', 'ls'], capture_output=True, text=True).stdout)['spaces']
        return {t['id'] for s in sp for t in s['tabs'] if t.get('name') == 'tower'}
    except Exception:
        return set()


def why_keep(g, children, towers, now):
    st = g.get('status') or {}
    lab = g.get('labels') or {}
    name = g.get('name') or ''
    if not st.get('app'): return '에이전트 아님'
    if not name: return '이름 없음'
    if g.get('address') == ME or name.startswith('dont-waste'): return '자기 자신'
    if st.get('state') not in ('idle', 'done'): return 'state=%s' % st.get('state')
    idle = (now - (g.get('status_ms') or now)) / 60000
    if idle < IDLE_MIN: return 'idle %d분' % idle
    if lab.get('herdr.pinned') == '1': return '핀'
    if name in TOWER_NAMES or lab.get('herdr.tab') in towers or (lab.get('where') or '').endswith('/ tower'): return 'tower'
    if name.endswith('-head'): return 'head'
    if children.get(g['address']): return '자식 있음(%s)' % ','.join(children[g['address']])
    scr = hc('read', g['address'], '--lines', '0').stdout.replace(' ', '').replace('\n', '')
    if any(p.replace(' ', '') in scr for p in ASKING): return '사용자 답 기다리는 화면'
    return None


def sweep(dry):
    now = time.time() * 1000
    towers = tower_tab()
    addrs = [t['address'] for t in json.loads(hc('ls', '--json').stdout)['terminals'] if t.get('state') == 'live']
    gs = [g for g in (get(a) for a in addrs) if g]
    children = {}
    for g in gs:
        if g.get('parent'):
            children.setdefault(g['parent'], []).append(g.get('name') or g['address'])
    killed = 0
    for g in gs:
        if why_keep(g, children, towers, now):
            continue
        argv, lab = g.get('argv') or [], g.get('labels') or {}
        sid = argv[argv.index('--resume') + 1] if '--resume' in argv[:-1] else \
            argv[argv.index('resume') + 1] if 'resume' in argv[:-1] else lab.get('revive.session', '')
        idle = int((now - g['status_ms']) / 60000)
        line = '%s\t%s\t%s\tidle %d분\tresume %s\t%s\t%s' % (
            time.strftime('%F %T'), 'DRY' if dry else 'KILL', g['name'], idle, sid,
            lab.get('revive.cwd') or g.get('cwd'), lab.get('where', ''))
        print(line)
        if not dry:
            hc('kill', g['address'])
            os.makedirs(os.path.dirname(LOG), exist_ok=True)
            open(LOG, 'a').write(line + '\n')
        killed += 1
    print('%s: %d개 %s (기준 idle %d분 이상)' % (time.strftime('%T'), killed, '끌 대상' if dry else '끔', IDLE_MIN))


if __name__ == '__main__':
    cmd = sys.argv[1] if len(sys.argv) > 1 else ''
    if cmd == 'sweep':
        sweep('--dry-run' in sys.argv)
    elif cmd == 'loop':
        every = max(5.0, float(sys.argv[2]))  # 5분보다 자주 돌지 않음
        while True:
            sweep(False)
            time.sleep(every * 60)
    else:
        print(__doc__)
        sys.exit(2)
