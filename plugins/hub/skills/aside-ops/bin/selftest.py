#!/usr/bin/env python3
"""aside-ops 자체 시험(브라우저 안 씀). 실행: aside-ops selftest"""
import importlib.machinery, importlib.util, io, json, os, subprocess, sys, tempfile, contextlib

HERE = os.path.dirname(os.path.realpath(__file__))
loader = importlib.machinery.SourceFileLoader("aside_ops", os.path.join(HERE, "aside-ops"))
spec = importlib.util.spec_from_loader("aside_ops", loader)
ao = importlib.util.module_from_spec(spec)
loader.exec_module(ao)


def run(*args, env=None):
    p = subprocess.run([sys.executable, os.path.join(HERE, "aside-ops"), *args], capture_output=True, text=True, env={**os.environ, **(env or {})})
    return p.returncode, json.loads(p.stdout.strip().splitlines()[-1]) if p.stdout.strip() else {}


# 하위 명령 허용 목록: 오타는 aside로 안 넘어가고 rc 2
rc, j = run("statuz")
assert rc == 2 and "status" in j["error"], j
# 짧은 exec 프롬프트(하위 명령 오타 의심)는 lock도 안 잡고 거부
rc, j = run("exec", "status", env={"ASIDE_BIN": "/nonexistent"})
assert rc == 2 and "짧음" in j["error"], j

# attach·page.close 금지
assert ao.check_code("await attachBrowserTab('x')", False)
assert ao.check_code("const p = await attachActiveBrowserTab()", False)
assert ao.check_code("await page.close()", False)
assert ao.check_code("const p = await openTab('https://a'); console.log(await p.title())", False) is None
# 읽기 전용: 클릭·입력·평가·원본 page 금지, ro API만 허용
for bad in ["await ro.click('e1')", "await ro['fill']('x')", "page.locator('a').click()", "await ro.goto(u); await evaluate()", "globalThis.page", "keyboard.press('Enter')"]:
    assert ao.check_code(bad, True), bad
assert ao.check_code("await ro.goto('https://example.com'); console.log(await ro.snapshot({interactive:true}))", True) is None
# 생성 JS: 표식, attach 차단, 끝에 closeTab, 읽기 전용 그림자 변수
js = ao.build_js("console.log(1)", True)
assert "window.name = 'aside-ops'" in js and "attach 금지" in js and "closeTab(t)" in js and "(async (page, tabs," in js
assert ao.parse_dur("5m") == 300 and ao.parse_dur("30s") == 30

# lock: 두 번째는 기다리다 시간 초과(rc 3)하고 누가 쓰는지 보여 준다
with tempfile.TemporaryDirectory() as d:
    os.environ["ASIDE_OPS_STATE"] = d
    loader2 = importlib.machinery.SourceFileLoader("ao2", os.path.join(HERE, "aside-ops"))
    s2 = importlib.util.spec_from_loader("ao2", loader2)
    ao2 = importlib.util.module_from_spec(s2)
    loader2.exec_module(ao2)
    held = ao2.Lock("bot-a", "test", 5)
    code = "import sys; sys.path.insert(0,'');"
    p = subprocess.run([sys.executable, "-c", f"""
import importlib.machinery, importlib.util
l = importlib.machinery.SourceFileLoader('x', {os.path.join(HERE, 'aside-ops')!r}); s = importlib.util.spec_from_loader('x', l); m = importlib.util.module_from_spec(s); l.exec_module(m)
m.Lock('bot-b', 'test', 2)
"""], capture_output=True, text=True, env={**os.environ, "ASIDE_OPS_STATE": d})
    assert p.returncode == 3 and "bot-a" in p.stderr and json.loads(p.stdout)["error"] == "lock-timeout", (p.returncode, p.stdout, p.stderr)
    held.release()
    # 죽은 pid가 남긴 current.json → 다음 lock이 recover()를 부른다
    ao2.write_json(ao2.CURRENT, {"pid": 999999, "who": "dead", "start": "2026-01-01T00:00:00", "before": []})
    called = []
    ao2.recover = lambda prev: called.append(prev["who"]) or {"from": prev["who"]}
    lk = ao2.Lock("bot-c", "test", 2)
    assert called == ["dead"] and lk.recovered == {"from": "dead"}
    lk.release()

print(json.dumps({"ok": True, "selftest": "all passed"}))
