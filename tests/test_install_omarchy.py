import contextlib
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import install_omarchy as m


class LinkInstallTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        base = Path(self.temp.name)
        self.home, self.repo = base / 'home', base / 'repo'
        self.home.mkdir()
        self.repo.mkdir()
        self.addCleanup(patch.stopall)
        patch.object(m, 'HOME', self.home).start()
        patch.object(m, 'REPO', self.repo).start()
        self.output = contextlib.redirect_stdout(io.StringIO())
        self.output.__enter__()
        self.addCleanup(self.output.__exit__, None, None, None)
        self.manifest = self.repo / 'omarchy/files.json'
        self.manifest.parent.mkdir(parents=True)
        self.entries = []

    def add(self, name, data=b'settings\n', existing=True):
        source = self.repo / 'omarchy' / name
        source.parent.mkdir(parents=True, exist_ok=True)
        source.write_bytes(data)
        source.chmod(0o600)
        target = self.home / name
        if existing:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
            target.chmod(0o600)
        entry = {'path': name, 'source': str(source.relative_to(self.repo))}
        self.entries.append(entry)
        self.manifest.write_text(json.dumps({'version': 1, 'files': self.entries}))
        return target, source

    def test_preview_install_idempotence_restore(self):
        target, source = self.add('.config/app/config')
        missing, _ = self.add('.config/new/config', existing=False)
        m.install(False)
        self.assertFalse(target.is_symlink())
        self.assertFalse(missing.exists())
        m.install(True)
        self.assertEqual(target.resolve(), source)
        self.assertEqual(target.stat().st_mode & 0o777, 0o600)
        self.assertEqual(m.plan(), [])
        backup = next((self.home / '.local/state/dotfiles/backups').iterdir())
        m.restore(backup, True)
        self.assertFalse(target.is_symlink())
        self.assertEqual(target.read_bytes(), b'settings\n')
        self.assertEqual(target.stat().st_mode & 0o777, 0o600)
        self.assertFalse(missing.exists())

    def test_conflict_prevents_all_changes(self):
        first, _ = self.add('.config/first/config')
        second, _ = self.add('.config/second/config')
        second.write_bytes(b'local change\n')
        with self.assertRaises(ValueError):
            m.install(True)
        self.assertFalse(first.is_symlink())
        self.assertEqual(second.read_bytes(), b'local change\n')

    def test_symlink_parent_rejected(self):
        target, _ = self.add('.config/app/config', existing=False)
        elsewhere = self.home / 'elsewhere'
        elsewhere.mkdir()
        target.parent.parent.mkdir(parents=True)
        target.parent.symlink_to(elsewhere)
        with self.assertRaises(ValueError):
            m.plan()
        self.assertEqual(list(elsewhere.iterdir()), [])

    def test_known_migration_and_undo(self):
        target, _ = self.add('.config/app/config')
        old = self.repo / 'old.conf'
        old.write_bytes(target.read_bytes())
        old.chmod(0o600)
        target.unlink()
        target.symlink_to(old)
        with self.assertRaises(ValueError):
            m.plan()
        self.entries[0]['migrate_from'] = str(old)
        self.manifest.write_text(json.dumps({'version': 1, 'files': self.entries}))
        m.install(True)
        backup = next((self.home / '.local/state/dotfiles/backups').iterdir())
        m.restore(backup, True)
        self.assertEqual(target.resolve(), old)

    def test_retired_source_restores_as_regular_file(self):
        target, _ = self.add('.config/app/config')
        old = self.repo / 'retired.conf'
        old.write_bytes(target.read_bytes())
        old.chmod(0o600)
        target.unlink()
        target.symlink_to(old)
        self.entries[0]['migrate_from'] = str(old)
        self.manifest.write_text(json.dumps({'version': 1, 'files': self.entries}))
        m.install(True)
        backup = next((self.home / '.local/state/dotfiles/backups').iterdir())
        old.unlink()
        m.restore(backup, True)
        self.assertFalse(target.is_symlink())
        self.assertEqual(target.read_bytes(), b'settings\n')
        self.assertEqual(target.stat().st_mode & 0o777, 0o600)

    def test_restore_refuses_source_edits(self):
        target, source = self.add('.config/app/config')
        m.install(True)
        backup = next((self.home / '.local/state/dotfiles/backups').iterdir())
        source.write_bytes(b'new settings\n')
        with self.assertRaises(ValueError):
            m.restore(backup, True)
        self.assertTrue(target.is_symlink())
        self.assertEqual(target.read_bytes(), b'new settings\n')

    def test_partial_failure_rolls_back(self):
        first, _ = self.add('.config/first/config')
        second, _ = self.add('.config/second/config')
        original_replace = m.os.replace
        failed = False
        def replace(source, target):
            nonlocal failed
            if target == second and not failed:
                failed = True
                raise OSError('simulated write failure')
            return original_replace(source, target)
        with patch.object(m.os, 'replace', replace):
            with self.assertRaises(OSError):
                m.install(True)
        self.assertFalse(first.is_symlink())
        self.assertFalse(second.is_symlink())
        self.assertEqual(first.read_bytes(), b'settings\n')


if __name__ == '__main__':
    unittest.main()
