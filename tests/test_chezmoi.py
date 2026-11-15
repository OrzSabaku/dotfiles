import os
import tomllib
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]
CHEZMOI = shutil.which('chezmoi')
# A mise shim would re-resolve tools against the temporary HOME below.
if CHEZMOI and Path(CHEZMOI).parent.name == 'shims':
    CHEZMOI = subprocess.check_output(['mise', 'which', 'chezmoi'], text=True).strip()


@unittest.skipUnless(CHEZMOI, 'chezmoi is required')
class ChezmoiTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.home = self.root / 'home'
        self.home.mkdir()
        self.config = self.root / 'chezmoi.toml'
        self.env = os.environ | {
            'HOME': str(self.home),
            'XDG_CONFIG_HOME': str(self.home / '.config'),
            'XDG_DATA_HOME': str(self.root / 'data'),
            'XDG_STATE_HOME': str(self.root / 'state'),
            'XDG_CACHE_HOME': str(self.root / 'cache'),
        }

    def run_chezmoi(self, *args, check=True):
        return subprocess.run([
            CHEZMOI, '--source', str(REPO), '--destination', str(self.home),
            '--config', str(self.config), '--persistent-state', str(self.root / 'state.boltdb'),
            '--cache', str(self.root / 'cache'), '--no-tty', *args,
        ], env=self.env, check=check, capture_output=True, text=True)

    def initialize(self, profile, apps=True):
        self.run_chezmoi('init', '--promptDefaults', '--promptChoice', 'Environment=' + profile)
        self.assertNotIn('sourceDir', tomllib.loads(self.config.read_text()))
        if not apps:
            self.config.write_text(self.config.read_text().replace('= true', '= false'))

    def test_both_profiles_apply_idempotently_without_installing_tools(self):
        for profile, count in [('omarchy', 75), ('fedora', 39)]:
            with self.subTest(profile=profile):
                self.initialize(profile)
                self.run_chezmoi('apply', '--dry-run')
                self.assertEqual(list(self.home.iterdir()), [])
                self.run_chezmoi('apply')
                managed = self.run_chezmoi('managed', '--include', 'files').stdout.splitlines()
                self.assertEqual(len(managed), count)
                for name in managed:
                    target = self.home / name
                    self.assertTrue(target.is_file(), name)
                    self.assertFalse(target.is_symlink(), name)
                self.assertEqual(self.run_chezmoi('diff').stdout, '')
                self.run_chezmoi('apply')
                self.run_chezmoi('verify')
                self.assertFalse((self.home / '.local').exists())
                self.assertFalse((self.home / '.config/nvim-experiment').exists())
                # Start the next profile from a clean virtual home, not a profile switch.
                shutil.rmtree(self.home)
                self.home.mkdir()
                self.config.unlink()
                (self.root / 'state.boltdb').unlink()

    def test_os_variants_and_optional_neovim_integrations(self):
        for profile in ('omarchy', 'fedora'):
            self.initialize(profile)
            self.run_chezmoi('apply')
            for target, fragment in [('.zshrc', 'zshrc'), ('.bashrc', 'bashrc'),
                                     ('.config/ghostty/config', 'config/ghostty/config'),
                                     ('.config/mise/config.toml', 'config/mise/config.toml')]:
                expected = REPO / 'home/.chezmoitemplates' / profile / fragment
                self.assertEqual((self.home / target).read_bytes(), expected.read_bytes())
            self.assertEqual((self.home / '.config/nvim/lua/omarchy').exists(), profile == 'omarchy')
            self.assertEqual((self.home / '.config/hypr').exists(), profile == 'omarchy')
            self.assertEqual((self.home / '.zshenv').exists(), profile == 'omarchy')
            if profile == 'omarchy':
                self.assertEqual((self.home / '.config/omarchy/shell.json').stat().st_mode & 0o777, 0o600)
                self.assertEqual((self.home / '.config/lazygit/config.yml').read_bytes(), b'')
                hook = self.home / '.config/omarchy/hooks/post-update.d/setup-agent.hook'
                self.assertEqual(hook.stat().st_mode & 0o777, 0o755)
            shutil.rmtree(self.home)
            self.home.mkdir()
            self.config.unlink()
            (self.root / 'state.boltdb').unlink()

    def test_unselected_apps_are_not_created(self):
        self.initialize('omarchy', apps=False)
        self.run_chezmoi('apply')
        for name in ('.zshrc', '.zshenv', '.config/sheldon', '.config/dotfiles/zsh.zsh',
                     '.config/nvim', '.config/ghostty', '.config/fcitx5'):
            self.assertFalse((self.home / name).exists(), name)
        self.assertTrue((self.home / '.config/dotfiles/env.sh').is_file())
        self.assertTrue((self.home / '.config/git/config').is_file())

    def test_private_and_unmanaged_app_data_survive(self):
        self.initialize('omarchy')
        names = ('.config/git/config.private', '.config/mozc/user_dictionary.db',
                 '.config/fcitx5/conf/cached_layouts', '.config/fcitx5/config.bak',
                 '.local/share/fcitx5/clipboard/data', '.config/omarchy/plugins/custom/data')
        for name in names:
            path = self.home / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(b'local data\n')
        self.run_chezmoi('apply')
        for name in names:
            self.assertEqual((self.home / name).read_bytes(), b'local data\n')
        for name in ('.config/fcitx5/config', '.config/fcitx5/profile', '.config/fcitx5/conf/xcb.conf'):
            self.assertEqual((self.home / name).stat().st_mode & 0o777, 0o600)

    def test_existing_links_become_files_without_changing_old_sources(self):
        self.initialize('omarchy')
        source = self.root / 'old-starship.toml'
        data = (REPO / 'home/dot_config/starship.toml').read_bytes()
        source.write_bytes(data)
        target = self.home / '.config/starship.toml'
        target.parent.mkdir()
        target.symlink_to(source)
        self.run_chezmoi('apply')
        self.assertFalse(target.is_symlink())
        self.assertEqual(target.read_bytes(), data)
        self.assertEqual(source.read_bytes(), data)

    def test_invalid_profile_is_rejected(self):
        self.initialize('omarchy')
        self.config.write_text(self.config.read_text().replace('profile = "omarchy"', 'profile = "other"'))
        result = self.run_chezmoi('apply', check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_private_runtime_files_are_git_ignored(self):
        names = ('home/dot_config/mozc/user_dictionary.db',
                 'home/dot_config/fcitx5/config.bak', 'home/dot_config/fcitx5/conf/cached_layouts',
                 'home/dot_config/git/private_config.private', 'home/dot_ssh/private_id_ed25519')
        result = subprocess.run(['git', 'check-ignore', '--no-index', '--stdin'], cwd=REPO,
                                input='\n'.join(names) + '\n', capture_output=True, text=True, check=True)
        self.assertEqual(set(result.stdout.splitlines()), set(names))
        for path in (REPO / 'home').rglob('*'):
            if path.is_file():
                result = subprocess.run(['git', 'check-ignore', '--no-index', str(path)], capture_output=True)
                self.assertEqual(result.returncode, 1, str(path))
