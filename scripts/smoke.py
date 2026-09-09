"""Exercise real CLI/file IO, not mocks. Run from any directory."""
import argparse
import json
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser()
p.add_argument('--target', default='wasm-gc', choices=['wasm-gc', 'wasm', 'js', 'native'])
args = p.parse_args()

def run(command, path, *options, expected=None, fails=False):
    cmd = ['moon', 'run', 'cmd/moonpetri', '--target', args.target, '--', command, str(path), *options]
    result = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, encoding='utf-8')
    out = result.stdout.strip()
    if fails:
        assert result.returncode != 0 and out.startswith('error:'), (cmd, result.returncode, out, result.stderr)
    else:
        assert result.returncode == 0, (cmd, out, result.stderr)
        if expected is not None:
            assert out == expected, (cmd, out, expected)
    print(command, Path(path).name, 'PASS')
    return out

producer = 'examples/producer-consumer.pnml'
run('validate', producer, expected='valid places=2 transitions=2 enabled=1')
run('explore', producer, '--max-states', '100', expected='states=3 edges=4 deadlocks=0 max_tokens=2 truncated=false')
run('fire', producer, 't_produce', expected='marking=[1,1]')
run('fire', producer, 't_produce', 't_consume', expected='marking=[2,0]')
run('fire', producer, 't_produce', 't_produce', 't_produce', fails=True)
run('explore', producer, '--max-states', '1', expected='states=1 edges=1 deadlocks=0 max_tokens=2 truncated=true')
traffic = 'examples/traffic-light.pnml'
run('explore', traffic, expected='states=3 edges=3 deadlocks=0 max_tokens=1 truncated=false')
run('fire', traffic, 't_green', 't_yellow', 't_red', expected='marking=[1,0,0]')
deadlock = 'examples/deadlock.pnml'
run('validate', deadlock, expected='valid places=2 transitions=2 enabled=0')
report = json.loads(run('report', deadlock))
assert report == dict(states=1, edges=0, deadlocks=1, max_tokens=0, truncated=False)
with tempfile.TemporaryDirectory(prefix='moonpetri-smoke-') as d:
    bad = Path(d) / 'malformed.pnml'
    bad.write_text('<pnml><net id="broken">', encoding='utf-8')
    first = run('validate', bad, fails=True)
    second = run('validate', bad, fails=True)
    assert first == second == 'error: ParseError("XML offset 23: unclosed element")'
    run('validate', Path(d) / 'missing.pnml', fails=True)
print('All scenario and invalid-input checks passed:', args.target)
