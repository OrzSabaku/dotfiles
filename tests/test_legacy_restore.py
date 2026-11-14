import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest


spec = importlib.util.spec_from_file_location('legacy_restore', Path(__file__).resolve().parents[1] / 'scripts/restore-legacy.py')
legacy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(legacy)


class LegacyRestoreTests(unittest.TestCase):
    def test_retired_link_restores_contents_and_permissions(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            home, backup = root / 'home', root / 'backup'
            home.mkdir()
            backup.mkdir()
            target = home / 'config'
            target.write_bytes(b'current\n')
            saved = backup / '0'
            saved.write_bytes(b'before\n')
            manifest = {'home': str(home), 'entries': [{
                'path': 'config',
                'before': {'link': str(root / 'retired-source'),
                           'sha256': hashlib.sha256(saved.read_bytes()).hexdigest()},
                'before_mode': 0o600, 'saved': '0', 'after': legacy.fingerprint(target),
            }]}
            (backup / 'manifest.json').write_text(json.dumps(manifest))
            old_home = legacy.HOME
            self.addCleanup(setattr, legacy, 'HOME', old_home)
            legacy.HOME = home
            legacy.restore(backup)
            self.assertEqual(target.read_bytes(), b'current\n')
            target.write_bytes(b'changed\n')
            with self.assertRaisesRegex(ValueError, 'Changed since installation'):
                legacy.restore(backup, True)
            target.write_bytes(b'current\n')
            legacy.restore(backup, True)
            self.assertFalse(target.is_symlink())
            self.assertEqual(target.read_bytes(), b'before\n')
            self.assertEqual(target.stat().st_mode & 0o777, 0o600)
