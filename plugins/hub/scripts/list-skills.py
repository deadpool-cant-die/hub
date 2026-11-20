#!/usr/bin/env python3
"""깐 스킬 목록: 이름 · 어디서 · 한 줄 설명(Trigger words 앞까지). 읽기만.
usage: list-skills.py hub          → 이 hub 플러그인 스킬만
       list-skills.py all          → ~/.claude/skills, ~/.agents/skills, 설치된 Claude Code 플러그인 전부
"""
import json, os, re, subprocess, sys

HUB = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'skills')


def front(p):
    try:
        s = open(p, encoding='utf-8').read()
    except OSError:
        return None, None
    m = re.match(r'---\n(.*?)\n---', s, re.S)
    if not m:
        return None, None
    name = re.search(r'^name:\s*(.+)$', m.group(1), re.M)
    desc = re.search(r'^description:\s*(.+)$', m.group(1), re.M)
    d = (desc.group(1).strip().strip('"') if desc else '')
    d = re.split(r'\s*Trigger words', d)[0].strip()
    return (name.group(1).strip() if name else None), d


def scan(root, where, prefix=''):
    out = []
    if not os.path.isdir(root):
        return out
    for e in sorted(os.listdir(root)):
        n, d = front(os.path.join(root, e, 'SKILL.md'))
        if n:
            out.append((prefix + n, where, d, os.path.realpath(os.path.join(root, e))))
    return out


rows = []
if sys.argv[1:] == ['hub']:
    rows = scan(HUB, 'hub', 'hub:')
else:
    rows += scan(os.path.expanduser('~/.claude/skills'), '~/.claude/skills')
    rows += scan(os.path.expanduser('~/.agents/skills'), '~/.agents/skills')
    try:
        plugins = json.loads(subprocess.run(['claude', 'plugin', 'list', '--json'], capture_output=True, text=True).stdout)
    except Exception:
        plugins = []
    for p in plugins:
        if not p.get('enabled'):
            continue
        base = p.get('readFromFolder') or p.get('installPath') or ''
        pid = p['id'].split('@')[0]
        rows += scan(os.path.join(base, 'skills'), 'plugin ' + p['id'], pid + ':')
    seen, uniq = set(), []
    for r in rows:  # 같은 폴더(심링크)는 한 번만
        if r[3] in seen:
            continue
        seen.add(r[3]); uniq.append(r)
    rows = uniq
for n, w, d, _ in rows:
    print('%s\t%s\t%s' % (n, w, d[:110]))
print('# %d개' % len(rows), file=sys.stderr)
