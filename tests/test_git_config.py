from pathlib import Path
import subprocess
import unittest


class SharedGitConfigTests(unittest.TestCase):
    def setUp(self):
        self.repo = Path(__file__).resolve().parents[1]
        self.config = self.repo / 'home/dot_config/git/config'

    def get(self, key):
        return subprocess.check_output(['git', 'config', '--file', str(self.config),
                                        '--no-includes', '--get', key], text=True).strip()

    def test_public_config_enables_signing_without_identity_or_key(self):
        keys = subprocess.check_output(['git', 'config', '--file', str(self.config),
                                         '--no-includes', '--name-only', '--list'], text=True).splitlines()
        for key in keys:
            self.assertNotIn(key.lower(), ('user.name', 'user.email', 'user.signingkey'))
            self.assertFalse(key.lower().startswith('credential.'))
        self.assertEqual(self.get('commit.gpgsign'), 'true')
        self.assertEqual(self.get('gpg.format'), 'ssh')
        self.assertEqual(self.get('user.useconfigonly'), 'true')
        self.assertEqual(self.get('include.path'), '~/.config/git/config.private')

    def test_private_files_are_ignored(self):
        for path in ('home/dot_config/git/config.private', 'home/dot_config/git/allowed_signers',
                     'home/dot_git-credentials', 'home/dot_ssh/id_ed25519'):
            result = subprocess.run(['git', '-C', str(self.repo), 'check-ignore', '--no-index', path],
                                    capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, path)


if __name__ == '__main__':
    unittest.main()
