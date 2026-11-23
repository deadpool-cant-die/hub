#!/usr/bin/env python3
"""Orca에 떠 있는 에이전트를 봇별로 한 줄씩: 이름, 상태, 핀, 마지막으로 한 말. 읽기만 한다.
usage: status.py [봇 이름]
쓰는 명령: orca bot list --json, orca worktree ps --json, orca agent list --json"""
import json, subprocess, sys

MARK = {'working': '▶ 일하는 중', 'blocked': '■ 막힘', 'waiting': '■ 답 기다림', 'done': '✓ 끝남'}


def orca(*a):
    r = subprocess.run(['orca', *a, '--json'], capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit('orca %s 실패: %s' % (' '.join(a), (r.stderr or r.stdout).strip()[:200]))
    return json.loads(r.stdout)['result']


want = sys.argv[1] if len(sys.argv) > 1 else ''
bots = {b['name']: b for b in orca('bot', 'list')['bots']}
wts = {w['worktreeId']: w for w in orca('worktree', 'ps', '--limit', '500')['worktrees']}
groups = {}
for a in orca('agent', 'list')['agents']:
    w = wts.get(a['worktreeId']) or {}
    groups.setdefault(w.get('bot') or '', []).append((w, a))

for name in sorted(set(bots) | set(groups), key=lambda n: (n == '', n)):
    if want and name != want:
        continue
    b = bots.get(name)
    print('[bot:%s]%s' % (name, ' (멈춤)' if b and b.get('paused') else '') if name else '[봇 없음]')
    rows = groups.get(name, [])
    if not rows:
        print('    (열린 에이전트 없음)')
    for w, a in sorted(rows, key=lambda r: -(r[1].get('updatedAt') or 0)):
        where = 'home' if w.get('botHome') else (w.get('displayName') or a.get('workspace') or '')
        pin = ' 📌' if w.get('isPinned') else ''
        said = ' '.join((a.get('lastAssistantMessage') or '').split())[:70]
        print('    %-20s %-7s %-28s %s%s  %s' % (where[:20], a.get('agent') or a.get('kind'), (a.get('title') or '')[:28],
                                              MARK.get(a.get('state'), '· ' + str(a.get('state'))), pin, said))
