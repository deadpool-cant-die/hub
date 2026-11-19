#!/usr/bin/env python3
"""Herdr 스페이스·탭별로 떠 있는 세션과 지금 하는 일을 한 줄씩. 읽기만 한다.
usage: status.py [스페이스 이름]"""
import json, os, subprocess, sys

ENV = {k: v for k, v in os.environ.items() if k not in ('HC_TERMINAL_ID', 'HC_SCOPE')}
MARK = {'working': '▶ 일하는 중', 'blocked': '■ 막힘', 'done': '✓ 끝남(안 봄)', 'idle': '· 대기'}


def get(a):
    r = subprocess.run(['hc', 'get', a, '--json'], capture_output=True, text=True, env=ENV)
    return json.loads(r.stdout) if r.returncode == 0 and r.stdout.strip() else {}


want = sys.argv[1] if len(sys.argv) > 1 else ''
spaces = json.loads(subprocess.run(['herdr-app', 'ls'], capture_output=True, text=True).stdout)['spaces']
for s in spaces:
    if want and s.get('name') != want:
        continue
    print('[%s]' % s.get('name'))
    for t in s['tabs']:
        print('  ' + (t.get('name') or ''))
        for x in t.get('terminals', []):
            g = get(x['terminal'])
            st = g.get('status') or {}
            argv = ' '.join(g.get('argv') or [])
            if x.get('name'):
                name = x['name']
            elif 'hc attach ' in argv:
                target = argv.rsplit('hc attach ', 1)[1].split()[0]
                name, g = target + ' (attach)', get(target)  # 래퍼 말고 붙은 세션의 상태·핀
                st = g.get('status') or {}
            else:
                name = (g.get('foreground') or {}).get('name', '셸')
            pin = ' 📌' if (g.get('labels') or {}).get('herdr.pinned') == '1' else ''
            print('    %-5s %-28s %s%s  %s' % (x['terminal'], name, MARK.get(st.get('state'), '  셸/알 수 없음'), pin, (st.get('msg') or '')[:70]))
