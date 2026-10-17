import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


class FedoraInstallTests(unittest.TestCase):
    def test_main_neovim_installs_complete_common_config_without_experiment(self):
        repo = Path(__file__).resolve().parents[1]
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            env = os.environ.copy()
            env['HOME'] = str(home)
            result = subprocess.run([sys.executable, str(repo / 'install.py'), '--profile', 'fedora', '--apply'],
                                    env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            common = repo / 'common/.config/nvim'
            files = [p for p in common.rglob('*') if p.is_file()]
            self.assertGreater(len(files), 1)
            for source in files:
                target = home / '.config/nvim' / source.relative_to(common)
                self.assertTrue(target.is_symlink(), str(target))
                self.assertEqual(target.resolve(), source)
            for name in ('.config/dotfiles/env.sh', '.config/dotfiles/bash.sh',
                         '.config/dotfiles/zsh.zsh', '.config/sheldon/plugins.toml',
                         '.config/ghostty/dotfiles.conf'):
                self.assertEqual((home / name).resolve(), repo / 'common' / name)
            self.assertTrue((home / '.config/ghostty/config').is_symlink())
            self.assertFalse((home / '.config/ghostty/config.ghostty').exists())
            self.assertFalse((home / '.config/nvim-personal').exists())
            self.assertFalse((home / '.config/nvim/lua/omarchy').exists())
            self.assertFalse((home / '.config/nvim-experiment').exists())


if __name__ == '__main__':
    unittest.main()
