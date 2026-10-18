import os
from pathlib import Path
import subprocess
import tempfile
import unittest


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
            result = subprocess.run(['bash', str(repo / 'scripts/setup-zsh')],
                                    env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 23, result.stderr)
            self.assertFalse(marker.exists())
            self.assertEqual(list(home.iterdir()), [])


if __name__ == '__main__':
    unittest.main()
