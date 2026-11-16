from ruby_runtime import RUBY
import os
import json
import sys
from pathlib import Path
import subprocess
import tempfile
import unittest


@unittest.skipUnless(RUBY, 'Ruby is required')
class ZshSetupTests(unittest.TestCase):
    def test_package_failure_does_not_install_configs_or_change_login_shell(self):
        if os.geteuid() == 0:
            self.skipTest('Setup intentionally refuses root')
        repo = Path(__file__).resolve().parents[1]
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            home, bin_dir = root / 'home', root / 'bin'
            home.mkdir()
            bin_dir.mkdir()
            marker = root / 'chsh-called'
            (bin_dir / 'omarchy').write_text('#!/bin/sh\nexit 23\n')
            (bin_dir / 'chsh').write_text(f'#!/bin/sh\ntouch "{marker}"\n')
            for tool in bin_dir.iterdir():
                tool.chmod(0o755)
            env = os.environ.copy()
            env['HOME'] = str(home)
            env['PATH'] = str(bin_dir) + ':' + env['PATH']
            result = subprocess.run([RUBY, str(repo / 'scripts/setup-zsh')],
                                    env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 23, result.stderr)
            self.assertFalse(marker.exists())
            self.assertEqual(list(home.iterdir()), [])

    def test_shell_change_waits_for_configuration_plugins_and_startup(self):
        if os.geteuid() == 0:
            self.skipTest('Setup intentionally refuses root')
        repo = Path(__file__).resolve().parents[1]
        stub = r"""import json, os, sys
from pathlib import Path
home = Path(os.environ['HOME'])
name = Path(sys.argv[0]).name
args = sys.argv[1:]
with (home / 'calls.jsonl').open('a') as log:
    log.write(json.dumps([name, *args]) + '\n')
failure = os.environ['FAIL_STAGE']
if name == 'id':
    print('test-user')
elif name == 'getent':
    print('test-user:x:1000:1000::/home/test:' + (home / 'current-shell').read_text())
elif name == 'chezmoi':
    action = args[2]
    if action == failure:
        sys.exit(23)
    if action == 'execute-template':
        print('omarchy' if '.profile' in args[-1] else 'true')
    elif action == 'cat':
        print('export EDITOR=nvim')
elif name == 'zsh':
    if (args[0] == '-n' and failure == 'syntax') or (args[0] == '-lic' and failure == 'startup'):
        sys.exit(23)
elif name == 'update-zsh-plugins' and failure == 'plugins':
    sys.exit(23)
elif name == 'chsh':
    (home / 'current-shell').write_text(args[-1])
"""
        runner = """load ARGV.shift
ZshSetup.send(:remove_const, :REPO)
ZshSetup.const_set(:REPO, ARGV.shift)
class ZshSetup
  # Exercise ordering independently of installed tools and /etc/shells.
  def check_dependencies
    '/usr/bin/zsh'
  end
end
ScriptCommands.main { ZshSetup.new.run }
"""
        for failure in ('none', 'init', 'syntax', 'apply', 'plugins', 'startup'):
            with self.subTest(failure=failure), tempfile.TemporaryDirectory() as directory:
                home = Path(directory)
                tools = home / 'bin'
                tools.mkdir()
                fixture_repo = home / 'fixture-repo'
                scripts = fixture_repo / 'scripts'
                scripts.mkdir(parents=True)
                for name in ('id', 'getent', 'omarchy', 'chezmoi', 'zsh', 'chsh', 'update-zsh-plugins'):
                    path = scripts / name if name == 'update-zsh-plugins' else tools / name
                    path.write_text('#!' + sys.executable + '\n' + stub)
                    path.chmod(0o755)
                current_shell = home / 'current-shell'
                current_shell.write_text('/bin/bash')
                env = os.environ | {'HOME': str(home), 'FAIL_STAGE': failure,
                                    'PATH': str(tools) + ':' + os.environ['PATH']}
                result = subprocess.run([RUBY, '-e', runner, str(repo / 'scripts/setup-zsh'), str(fixture_repo)],
                                        env=env, capture_output=True, text=True)
                self.assertTrue((home / 'calls.jsonl').exists(), result.stderr)
                calls = [json.loads(line) for line in (home / 'calls.jsonl').read_text().splitlines()]
                shell_changes = [call for call in calls if call[0] == 'chsh']
                if failure != 'none':
                    self.assertEqual(result.returncode, 23, result.stderr)
                    self.assertEqual(shell_changes, [])
                    self.assertEqual(current_shell.read_text(), '/bin/bash')
                    self.assertFalse((home / '.local/state/dotfiles').exists())
                else:
                    self.assertEqual(result.returncode, 0, result.stderr)
                    apply_at = next(i for i, call in enumerate(calls) if call[0] == 'chezmoi' and call[3] == 'apply')
                    plugins_at = next(i for i, call in enumerate(calls) if call[0] == 'update-zsh-plugins')
                    startup_at = next(i for i, call in enumerate(calls) if call[:2] == ['zsh', '-lic'])
                    chsh_at = next(i for i, call in enumerate(calls) if call[0] == 'chsh')
                    self.assertLess(apply_at, plugins_at)
                    self.assertLess(plugins_at, startup_at)
                    self.assertLess(startup_at, chsh_at)
                    audit = next((home / '.local/state/dotfiles').iterdir())
                    self.assertEqual(audit.read_text(), '/bin/bash\n')
                    self.assertEqual(audit.stat().st_mode & 0o777, 0o600)


if __name__ == '__main__':
    unittest.main()
