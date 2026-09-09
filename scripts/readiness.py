"""Reproduce the engineering gate; skipping native runtime is explicit, never a pass."""
import argparse
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--skip-native-runtime', action='store_true', help='Still check native, but do not build/test/run it (no C compiler).')
args = parser.parse_args()

def run(*command, tests=False):
    print('+', ' '.join(command), flush=True)
    result = subprocess.run(command, cwd=ROOT, text=True, encoding='utf-8', stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    print(result.stdout, end='', flush=True)
    if result.returncode:
        raise SystemExit(result.returncode)
    if tests:
        match = re.search(r'Total tests: (\d+), passed: (\d+), failed: (\d+)', result.stdout)
        if not match or int(match[1]) == 0 or match[1] != match[2] or match[3] != '0':
            raise SystemExit('Test runner must execute a nonzero passing suite')

def interfaces():
    return {str(p.relative_to(ROOT)): p.read_bytes() for p in ROOT.rglob('*.mbti') if not any(part in ['_build', '.mooncakes'] for part in p.parts)}

run('moon', 'version', '--all')
run('moon', 'fmt', '--check')
for target in ['wasm-gc', 'wasm', 'js', 'native']:
    run('moon', 'check', '--target', target, '--deny-warn')
    if target == 'native' and args.skip_native_runtime:
        print('SKIPPED native build/test/CLI: explicitly requested; not a successful native runtime check')
        continue
    run('moon', 'build', '--target', target)
    run('moon', 'test', '--target', target, '--deny-warn', tests=True)
    run(sys.executable, 'scripts/smoke.py', '--target', target)
    run('moon', 'run', 'examples/api-demo', '--target', target)
before = interfaces()
run('moon', 'info')
if before != interfaces():
    raise SystemExit('Generated interfaces changed; review and commit them before retrying')
run(sys.executable, '-m', 'unittest', 'discover', '-s', 'scripts', '-p', '*_test.py')
run(sys.executable, 'scripts/package_check.py')
print('Engineering gate passed' + (' (native runtime explicitly skipped)' if args.skip_native_runtime else ' on all four targets'))
