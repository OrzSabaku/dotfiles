import contextlib
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
import install_omarchy


REPO = Path(__file__).resolve().parents[1]


class Fcitx5InstallTests(unittest.TestCase):
    def test_existing_preferences_can_be_linked_and_restored_without_touching_private_data(self):
        entries = [entry for entry in json.loads((REPO / 'omarchy/files.json').read_text())['files']
                   if entry['path'].startswith('.config/fcitx5/')]
        self.assertEqual(len(entries), 7)
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary)
            originals = {}
            for entry in entries:
                source = REPO / entry['source']
                target = home / entry['path']
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(source.read_bytes())
                target.chmod(source.stat().st_mode & 0o777)
                originals[target] = (target.read_bytes(), target.stat().st_mode & 0o777)
            private = [home / name for name in (
                '.config/mozc/user_dictionary.db', '.config/mozc/config1.db',
                '.config/fcitx5/conf/cached_layouts', '.config/fcitx5/config.bak',
                '.local/share/fcitx5/clipboard/data',
            )]
            for target in private:
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(b'local test data\n')
            with patch.object(install_omarchy, 'HOME', home), contextlib.redirect_stdout(io.StringIO()):
                install_omarchy.install(False)
                self.assertTrue(all(not target.is_symlink() for target in originals))
                install_omarchy.install(True)
                for entry in entries:
                    target = home / entry['path']
                    self.assertTrue(target.is_symlink())
                    self.assertEqual(target.resolve(), REPO / entry['source'])
                self.assertEqual(install_omarchy.plan(), [])
                backup = next((home / '.local/state/dotfiles/backups').iterdir())
                install_omarchy.restore(backup, True)
            for target, (content, mode) in originals.items():
                self.assertFalse(target.is_symlink())
                self.assertEqual(target.read_bytes(), content)
                self.assertEqual(target.stat().st_mode & 0o777, mode)
            for target in private:
                self.assertFalse(target.is_symlink())
                self.assertEqual(target.read_bytes(), b'local test data\n')

    def test_private_data_is_ignored_but_managed_preferences_are_not(self):
        private = [
            'common/.config/mozc/user_dictionary.db',
            'common/.config/mozc/config1.db',
            'common/.local/share/fcitx5/clipboard/data',
            'common/.config/fcitx5/conf/cached_layouts',
            'common/.config/fcitx5/config.bak.20261106',
        ]
        result = subprocess.run(['git', 'check-ignore', '--no-index', '--stdin'],
                                cwd=REPO, input='\n'.join(private) + '\n',
                                capture_output=True, text=True, check=True)
        self.assertEqual(set(result.stdout.splitlines()), set(private))
        for source in (REPO / 'common/.config/fcitx5').rglob('*'):
            if source.is_file():
                result = subprocess.run(['git', 'check-ignore', '--no-index', str(source.relative_to(REPO))],
                                        cwd=REPO, capture_output=True, text=True)
                self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
