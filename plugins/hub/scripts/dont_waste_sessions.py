#!/usr/bin/env python3
"""놀고 있는 Orca worker·에이전트 터미널을 찾아 닫는다(hub:dont-waste-sessions).

usage:
  dont_waste_sessions.py sweep [--dry-run]   한 번 훑기 (--dry-run: 닫을 목록만 출력)
  dont_waste_sessions.py loop <분>           <분>마다 sweep (on이 이걸 띄움)

닫는 것(모두 맞아야):
  - worker(orca orchestration worker-list): 일이 끝났고(completed) 터미널이 아직 열려 있으며,
    끝난 지 DWS_IDLE_MIN분(기본 120) 이상 → orca orchestration worker-release (출력은 남음)
  - 봇 밖 에이전트 터미널(orca agent list, kind=terminal): 상태 done, 마지막 변화가 DWS_IDLE_MIN분 이상 전
    → orca terminal close
닫지 않는 것: 봇 채팅(Orca 채팅은 전부), 핀 꽂은 워크스페이스, 봇 home, working·blocked·waiting,
  일이 안 끝난 worker, 사람 답을 기다리는 worker, 화면이 질문을 띄운 터미널(선택지·y/n·신뢰·훅·업데이트),
  이 스크립트를 부른 터미널.
닫은 것은 로그에 시각·이름·idle 분·dispatch/터미널·워크스페이스를 남긴다(worker 출력은 worker-read로 계속 읽힘).
"""
import json, os, subprocess, sys, time
from datetime import datetime

IDLE_MIN = float(os.environ.get('DWS_IDLE_MIN', '120'))


def _hub_private():
    # hub-env.sh와 같은 순서: 환경 변수 → ~/.config/hub/config → ~/.hub
    v = os.environ.get('HUB_PRIVATE')
    cfg = os.path.expanduser(os.environ.get('HUB_CONFIG', '~/.config/hub/config'))
    if not v and os.path.exists(cfg):
        for line in open(cfg):
            if line.startswith('HUB_PRIVATE='):
                v = line.strip().split('=', 1)[1]
    return os.path.expanduser(v or '~/.hub')


LOG = os.path.expanduser(os.environ.get('DWS_LOG') or os.path.join(_hub_private(), 'scripts', 'dont-waste-sessions.log'))
ASKING = ('Doyouwant', '❯1.', '›1.', '(y/n)', '[Y/n]', '[y/N]', 'trustthisfolder', 'Hooksneedreview',
          'Updateavailable', 'Pressenter', 'Entertoconfirm')
ME = os.environ.get('ORCA_TERMINAL_HANDLE', '')


def orca(*a):
    r = subprocess.run(['orca', *a, '--json'], capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError('orca %s: %s' % (' '.join(a), (r.stderr or r.stdout).strip()[:200]))
    return json.loads(r.stdout)['result']


def asking(handle):
    try:
        tail = orca('terminal', 'read', '--terminal', handle, '--screen')['terminal'].get('tail') or []
    except RuntimeError:
        return False
    scr = ''.join(tail).replace(' ', '')
    return any(p in scr for p in ASKING)


def candidates(now):
    """(종류, 이름, idle분, 대상 id, 워크스페이스) 목록. 종류: worker | terminal"""
    wts = {w['worktreeId']: w for w in orca('worktree', 'ps', '--limit', '500')['worktrees']}
    keep = lambda wt: (wts.get(wt) or {}).get('isPinned') or (wts.get(wt) or {}).get('botHome')
    out, worker_terms = [], set()
    for w in orca('orchestration', 'worker-list', '--limit', '100')['workers']:
        worker_terms.add(w.get('terminal'))
        if w.get('state') not in ('succeeded', 'failed') or w.get('liveness') != 'live' or w.get('terminal') == ME:
            continue
        if w.get('terminalState') not in ('retained', 'reclaimable') or keep(w.get('workspace')):
            continue
        r = orca('orchestration', 'worker-show', '--dispatch', w['dispatchId'], '--full')
        done = (r.get('dispatch') or {}).get('completedAt')
        if not done or r.get('waitingOnHuman'):
            continue
        idle = (now - datetime.fromisoformat(done.replace('Z', '+00:00')).timestamp()) / 60
        if idle >= IDLE_MIN:
            name = (wts.get(w.get('workspace')) or {}).get('displayName') or w['dispatchId']
            out.append(('worker', name, idle, w['dispatchId'], w.get('workspace', '')))
    handles = {t['tabId'] + ':' + t['leafId']: t['handle'] for t in orca('terminal', 'list')['terminals']}
    for a in orca('agent', 'list')['agents']:
        h = handles.get(a.get('paneKey'))
        if a.get('kind') != 'terminal' or a.get('state') != 'done' or not h or h == ME or h in worker_terms:
            continue
        if keep(a.get('worktreeId')) or (wts.get(a.get('worktreeId')) or {}).get('bot'):
            continue
        idle = (now - (a.get('updatedAt') or now * 1000) / 1000) / 60
        if idle >= IDLE_MIN and not asking(h):
            out.append(('terminal', a.get('title') or h, idle, h, a.get('worktreeId', '')))
    return out


def sweep(dry):
    n = 0
    for kind, name, idle, target, ws in candidates(time.time()):
        line = '%s\t%s\t%s\t%s\tidle %d분\t%s\t%s' % (time.strftime('%F %T'), 'DRY' if dry else 'CLOSE', kind, name, idle, target, ws)
        print(line)
        if not dry:
            try:
                if kind == 'worker':
                    orca('orchestration', 'worker-release', '--dispatch', target)
                else:
                    orca('terminal', 'close', '--terminal', target)
            except RuntimeError as e:
                line += '\t실패: %s' % e
                print('  실패: %s' % e)
            os.makedirs(os.path.dirname(LOG), exist_ok=True)
            open(LOG, 'a').write(line + '\n')
        n += 1
    print('%s: %d개 %s (기준 idle %d분 이상)' % (time.strftime('%T'), n, '닫을 대상' if dry else '닫음', IDLE_MIN))


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
