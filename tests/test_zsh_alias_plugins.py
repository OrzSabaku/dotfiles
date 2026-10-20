import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import tomllib
import unittest

REPO = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which('zsh') and shutil.which('sheldon'), 'Zsh and Sheldon are required')
class ZshAliasPluginTests(unittest.TestCase):
    def test_real_sheldon_template_preserves_plugin_names_and_removes_unsigned_aliases(self):
        config = tomllib.loads((REPO / 'common/.config/sheldon/plugins.toml').read_text())
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            fixture = root / 'plugin'
            sources = {
                'lib/clipboard.zsh': 'clipcopy() { :; }\n',
                'lib/git.zsh': 'git_current_branch() { print main; }\ngit_main_branch() { print main; }\n',
                'plugins/git/git.plugin.zsh': "alias gcm='git checkout $(git_main_branch)'\nalias gcmsg='git commit --message'\nalias gwip='git commit --no-gpg-sign'\nalias unsafe='git -c commit.gpgsign=false commit'\n",
                'plugins/docker/docker.plugin.zsh': "alias dps='docker ps'\n",
                'plugins/docker-compose/docker-compose.plugin.zsh': "alias dcupd='docker compose up -d'\n",
            }
            for name, content in sources.items():
                path = fixture / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(content)
            config_dir = root / 'config'
            config_dir.mkdir()
            (config_dir / 'plugins.toml').write_text(
                'shell = "zsh"\n[templates]\nomz-aliases = ' + json.dumps(config['templates']['omz-aliases']) +
                '\n[plugins.fixture]\nlocal = ' + json.dumps(str(fixture)) +
                '\nuse = ["plugins/git/git.plugin.zsh"]\napply = ["omz-aliases"]\n')
            rendered = subprocess.run(['sheldon', '--config-dir', str(config_dir), '--data-dir', str(root / 'data'), 'source'],
                                      capture_output=True, text=True)
            self.assertEqual(rendered.returncode, 0, rendered.stderr)
            generated = root / 'generated.zsh'
            generated.write_text(rendered.stdout)
            tools = root / 'bin'
            tools.mkdir()
            (tools / 'docker').write_text('#!/bin/sh\nexit 0\n')
            (tools / 'docker').chmod(0o755)
            env = os.environ.copy()
            env.update(HOME=str(root), ZDOTDIR=str(root), XDG_CACHE_HOME=str(root / 'cache'), PATH=str(tools) + ':' + env['PATH'])
            script = '''alias gcm='git commit -m'
alias gcad='git commit -a --amend'
source "$1"
zmodload zsh/parameter
[[ $aliases[gcm] == 'git checkout $(git_main_branch)' ]] || exit 1
[[ $aliases[gcmsg] == 'git commit --message' ]] || exit 2
(( ! ${+aliases[gcad]} && ! ${+aliases[gwip]} && ! ${+aliases[unsafe]} )) || exit 3
[[ $aliases[dps] == 'docker ps' && $aliases[dcupd] == 'docker compose up -d' ]] || exit 4
(( ${+functions[git_current_branch]} && ${+functions[clipcopy]} )) || exit 5
'''
            checked = subprocess.run(['zsh', '-f', '-c', script, 'test', str(generated)], env=env, capture_output=True, text=True)
            self.assertEqual(checked.returncode, 0, checked.stdout + checked.stderr)

    def assert_failed_update_preserves_cache(self, tool_body):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            tools = root / 'bin'
            tools.mkdir()
            (tools / 'sheldon').write_text('#!/bin/sh\n' + tool_body)
            (tools / 'sheldon').chmod(0o755)
            cache = root / 'cache/dotfiles/sheldon.zsh'
            cache.parent.mkdir(parents=True)
            cache.write_text('# working configuration\n')
            env = os.environ.copy()
            env.update(HOME=str(root), XDG_CACHE_HOME=str(root / 'cache'), PATH=str(tools) + ':' + env['PATH'])
            result = subprocess.run(['bash', str(REPO / 'scripts/update-zsh-plugins')], env=env, capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(cache.read_text(), '# working configuration\n')

    def test_failed_download_keeps_last_working_plugins(self):
        self.assert_failed_update_preserves_cache('exit 23\n')

    def test_invalid_generated_code_keeps_last_working_plugins(self):
        self.assert_failed_update_preserves_cache("printf '%s\\n' ')'\n")


if __name__ == '__main__':
    unittest.main()
