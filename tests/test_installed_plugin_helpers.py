import os
from pathlib import Path
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]
HELPERS = {
    'enable-browser-idle': 'dotfiles.idle',
    'enable-notification-timeout': 'dotfiles.notifications',
}


class InstalledPluginHelperTests(unittest.TestCase):
    def test_dispatches_to_installed_helper_and_preserves_arguments(self):
        for name, plugin_id in HELPERS.items():
            with self.subTest(helper=name), tempfile.TemporaryDirectory() as temporary:
                home = Path(temporary)
                helper = home / '.config/omarchy/plugins' / plugin_id / 'scripts' / name
                helper.parent.mkdir(parents=True)
                helper.write_text('printf "%s\\n" "$@"\nexit 23\n')
                result = subprocess.run(['bash', str(REPO / 'scripts' / name), 'two words', '--flag'],
                                        env={**os.environ, 'HOME': str(home)},
                                        capture_output=True, text=True, timeout=5)
                self.assertEqual(result.returncode, 23)
                self.assertEqual(result.stdout, 'two words\n--flag\n')

    def test_missing_installation_stops_without_using_development_checkout(self):
        for name in HELPERS:
            with self.subTest(helper=name), tempfile.TemporaryDirectory() as temporary:
                result = subprocess.run(['bash', str(REPO / 'scripts' / name)],
                                        env={**os.environ, 'HOME': temporary},
                                        capture_output=True, text=True, timeout=5)
                self.assertEqual(result.returncode, 1)
                self.assertIn('Install first: omarchy plugin add https://github.com/', result.stderr)
                self.assertEqual(list(Path(temporary).iterdir()), [])
