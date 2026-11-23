#!/usr/bin/env python3
"""(Herdr 시절) Herdr 앱 전용 — Orca엔 해당 없음(hub:session). Herdr를 끌 때 지운다.
Herdr 탭의 칸 트리를 읽는 도우미. relaunch.sh·tower-layout-v2.sh가 쓴다.

usage:
  herdr_tree.py find <이름>            -> "<space> <tab> <pane> <wrapper|direct>" (그 세션을 보여 주는 칸)
  herdr_tree.py pane <tab> <이름>      -> 그 탭에서 이름을 보여 주는 칸 id
  herdr_tree.py shape <tab> <admin> <secretary> <resource> <atlassian>
      -> tower 모양 판정 JSON {ok, struct_ok, why, resize:[[id,w]..], blocks:[{pane,terminal,name,wrapper}]}
"""
import json, os, subprocess, sys

DOCS = os.path.expanduser('~/.local/state/herdr-core/default/docs.json')


ENV = {k: v for k, v in os.environ.items() if k not in ('HC_TERMINAL_ID', 'HC_SCOPE')}


class Terms(dict):
    """주소 -> `hc get` JSON (hc ls에는 argv가 없어서 하나씩 묻는다)."""
    def __missing__(self, a):
        r = subprocess.run(['hc', 'get', a, '--json'], capture_output=True, text=True, env=ENV)
        self[a] = json.loads(r.stdout) if r.returncode == 0 and r.stdout.strip() else None
        return self[a]


def hc_terms():
    return Terms()


def eff_name(term):
    """칸에 보이는 세션 이름: 터미널 이름, 또는 `hc attach X` 래퍼면 X."""
    if not term:
        return None, False
    argv = ' '.join(term.get('argv') or [])
    if 'hc attach ' in argv:
        return argv.rsplit('hc attach ', 1)[1].split()[0], True
    return term.get('name'), False


def tabs():
    d = json.load(open(DOCS))['herdr-app']['value']
    for s in d['spaces']:
        for t in s['tabs']:
            yield s['id'], t


def blocks(node):
    if node.get('type') == 'block':
        yield node
    else:
        for c in node.get('children', []):
            yield from blocks(c)


def squash(node):
    while node.get('type') != 'block' and len(node.get('children', [])) == 1:
        node = node['children'][0]
    return node


def main():
    cmd, args = sys.argv[1], sys.argv[2:]
    terms = hc_terms()

    def info(b):
        t = b['content'].get('terminal')
        term = terms[t] if t else None
        n, w = eff_name(term)
        return {'pane': b['id'], 'terminal': b['content'].get('terminal'), 'name': n, 'wrapper': w}

    if cmd in ('find', 'pane'):
        want = args[-1]
        for sid, t in tabs():
            if cmd == 'pane' and t['id'] != args[0]:
                continue
            for b in blocks(t['root']):
                i = info(b)
                if i['name'] == want:
                    print(i['pane'] if cmd == 'pane' else
                          f"{sid} {t['id']} {i['pane']} {'wrapper' if i['wrapper'] else 'direct'}")
                    return
        sys.exit(1)

    if cmd == 'shape':
        # tower 모양: 위 띠(15%) = r | at, 아래(85%) = a | s, 각 줄 1:1
        tab, a, s_, r, at = args
        tree = next(t for _, t in tabs() if t['id'] == tab)
        res = {'blocks': [info(b) for b in blocks(tree['root'])], 'resize': [], 'struct_ok': False}
        root = squash(tree['root'])

        def names(x):
            x = squash(x)
            return [info(c)['name'] if c.get('type') == 'block' else None for c in x.get('children', [])] if x.get('type') == 'row' else None

        k = root.get('children', [])
        if root.get('type') != 'column' or len(k) != 2:
            res['why'] = '위띠+아래 두 줄 구조가 아님'
        elif names(k[0]) != [r, at] or names(k[1]) != [a, s_]:
            res['why'] = '칸 이름·순서가 다름'
        else:
            res['struct_ok'] = True

            def want(nodes, ws):
                tot = sum(x.get('size', {}).get('weight', 1) for x in nodes)
                for x, w in zip(nodes, ws):
                    if abs(x.get('size', {}).get('weight', 1) / tot - w) > 0.03:
                        res['resize'].append([x['id'], w])
            want(k, [0.15, 0.85])
            want(squash(k[0])['children'], [0.5, 0.5])
            want(squash(k[1])['children'], [0.5, 0.5])
            res['why'] = '크기만 다름' if res['resize'] else '모양 같음'
        res['ok'] = res['struct_ok'] and not res['resize']
        print(json.dumps(res, ensure_ascii=False))

    if cmd == 'tabshape':
        # 일 탭 모양. head가 있으면 왼쪽 반 = head, 오른쪽 반 = worker(1~3개 한 열 위아래, 4개 이상 두 열 격자).
        # head가 없으면(head 자리에 '-') worker를 같은 폭으로 나란히.
        tab, head, ws = args[0], args[1], args[2:]
        tree = next(t for _, t in tabs() if t['id'] == tab)
        res = {'blocks': [info(b) for b in blocks(tree['root'])], 'resize': [], 'struct_ok': False}
        n = len(ws); k = (n + 1) // 2
        if head == '-':
            cols, lead, weights = [[w] for w in ws], [], [1 / n] * n
        else:
            cols = [ws] if n <= 3 else [ws[:k], ws[k:]]
            lead, weights = [head], [0.5] + [0.5 / len(cols)] * len(cols)
        root = squash(tree['root'])

        def nm(x):
            x = squash(x)
            return info(x)['name'] if x.get('type') == 'block' else None

        def col_names(x):
            x = squash(x)
            if x.get('type') == 'block': return [nm(x)]
            return [nm(c) for c in x.get('children', [])] if x.get('type') == 'column' else None

        kids = root.get('children', []) if root.get('type') == 'row' else ([root] if n == 1 and not lead else [])
        if len(kids) != len(lead) + len(cols) or [nm(x) for x in kids[:len(lead)]] != lead:
            res['why'] = '왼쪽 head + 오른쪽 worker 구조가 아님' if lead else 'worker가 같은 폭으로 나란히 있지 않음'
        elif [col_names(c) for c in kids[len(lead):]] != cols:
            res['why'] = 'worker 칸 이름·순서가 다름'
        else:
            res['struct_ok'] = True

            def want(nodes, ws_):
                tot = sum(x.get('size', {}).get('weight', 1) for x in nodes)
                for x, w in zip(nodes, ws_):
                    if abs(x.get('size', {}).get('weight', 1) / tot - w) > 0.03:
                        res['resize'].append([x['id'], w])
            if len(kids) > 1: want(kids, weights)
            for c in kids[len(lead):]:
                c = squash(c)
                if c.get('type') == 'column': want(c['children'], [1 / len(c['children'])] * len(c['children']))
            res['why'] = '크기만 다름' if res['resize'] else '모양 같음'
        res['ok'] = res['struct_ok'] and not res['resize']
        print(json.dumps(res, ensure_ascii=False))

    if cmd == 'shape-blocks':
        # 탭의 칸마다 "pane terminal 이름 wrapper" 한 줄 (이름 없으면 '-')
        tree = next(t for _, t in tabs() if t['id'] == args[0])
        for b in blocks(tree['root']):
            i = info(b)
            print(i['pane'], i['terminal'], i['name'] or '-', 'true' if i['wrapper'] else 'false')
        return

    if cmd == 'members':
        # 탭에 보이는 세션 이름: head(이름이 -head로 끝나는 첫 칸) 한 줄, 나머지 worker 한 줄
        tree = next(t for _, t in tabs() if t['id'] == args[0])
        names = [i['name'] for i in (info(b) for b in blocks(tree['root'])) if i['name']]
        heads = [x for x in names if x.endswith('-head')]
        print(heads[0] if heads else '-')
        print(' '.join(x for x in names if x not in heads[:1]))


if __name__ == '__main__':
    main()
