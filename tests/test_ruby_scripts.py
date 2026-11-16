import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

from ruby_runtime import RUBY

REPO = Path(__file__).resolve().parents[1]


@unittest.skipUnless(RUBY, 'Ruby is required')
class RubyScriptTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.tools = self.root / 'bin'
        self.tools.mkdir()
        self.env = os.environ | {
            'HOME': str(self.root), 'XDG_DATA_HOME': str(self.root / 'data'),
            'XDG_CACHE_HOME': str(self.root / 'cache'),
            'PATH': str(self.tools) + ':' + os.environ['PATH'],
        }

    def tool(self, name, body):
        path = self.tools / name
        path.write_text('#!/usr/bin/python3\n' + body)
        path.chmod(0o755)

    def run_script(self, name, *args):
        return subprocess.run([RUBY, str(REPO / 'scripts' / name), *args],
                              env=self.env, capture_output=True, text=True)

    def plugin_fixture(self, validation_status=0):
        self.tool('sheldon', '''import sys
from pathlib import Path
location = sys.argv[sys.argv.index('--data-dir') + 1]
Path(location, 'downloaded').write_text('plugin repositories')
print('# validated plugins from ' + location)
''')
        self.tool('zsh', f'''import sys
from pathlib import Path
if '-i' in sys.argv:
    assert __import__('os').environ['ZDOTDIR'] == sys.argv[-1]
    sys.exit({validation_status})
''')
        self.cache = self.root / 'cache/dotfiles/sheldon.zsh'
        self.cache.parent.mkdir(parents=True)
        self.cache.write_text('# previous plugins\n')
        self.cache.chmod(0o600)

    def test_successful_plugin_update_keeps_generation_and_private_backup(self):
        self.plugin_fixture()
        result = self.run_script('update-zsh-plugins')
        self.assertEqual(result.returncode, 0, result.stderr)
        generations = list((self.root / 'data/dotfiles/sheldon').iterdir())
        self.assertEqual(len(generations), 1)
        self.assertIn(str(generations[0]), self.cache.read_text())
        self.assertTrue((generations[0] / 'downloaded').exists())
        backups = list((self.root / '.local/state/dotfiles/backups').iterdir())
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].stat().st_mode & 0o777, 0o700)
        self.assertEqual((backups[0] / 'sheldon.zsh').read_text(), '# previous plugins\n')
        self.assertEqual(self.cache.stat().st_mode & 0o777, 0o600)
        self.assertEqual(list(self.cache.parent.glob('.sheldon.*')), [])

    def test_plugin_validation_failure_removes_only_failed_generation(self):
        self.plugin_fixture(validation_status=29)
        result = self.run_script('update-zsh-plugins')
        self.assertEqual(result.returncode, 29, result.stderr)
        self.assertEqual(self.cache.read_text(), '# previous plugins\n')
        self.assertEqual(list((self.root / 'data/dotfiles/sheldon').iterdir()), [])
        self.assertFalse((self.root / '.local/state/dotfiles/backups').exists())

    def test_neovim_launcher_passes_environment_arguments_and_exit_code(self):
        self.tool('nvim', '''import json, os, sys
print(json.dumps({'config': os.environ['XDG_CONFIG_HOME'],
                  'app': os.environ['NVIM_APPNAME'], 'args': sys.argv[1:]}))
sys.exit(17)
''')
        arguments = ['file with spaces.txt', '$(touch should-not-exist)', '--', '-literal']
        result = self.run_script('nvim-experiment', *arguments)
        self.assertEqual(result.returncode, 17, result.stderr)
        data = json.loads(result.stdout)
        self.assertEqual(data['args'], arguments)
        self.assertEqual(data['config'], str(REPO / 'experiments'))
        self.assertEqual(data['app'], 'nvim-experiment')
        self.assertFalse((REPO / 'should-not-exist').exists())

    def test_command_helper_preserves_literal_arguments_and_failure_status(self):
        self.tool('record', '''import json, sys
print(json.dumps(sys.argv[1:]))
sys.exit(31)
''')
        code = '''require ARGV.shift
ScriptCommands.main { ScriptCommands.run!('record', *ARGV) }
'''
        args = ['space in argument', '$(touch should-not-exist)', '; exit 0']
        result = subprocess.run([RUBY, '-e', code, str(REPO / 'scripts/lib/commands.rb'), *args],
                                env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 31, result.stderr)
        self.assertEqual(json.loads(result.stdout), args)
