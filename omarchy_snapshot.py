#!/usr/bin/env python3
"""Capture once, compare, or selectively restore Omarchy user configuration."""
import argparse
import difflib
import hashlib
import json
import os
from pathlib import Path
import shutil
import sys
from datetime import datetime
import uuid

import install_omarchy as support

REPO = Path(__file__).resolve().parent
SNAPSHOT = REPO / 'profiles/omarchy/snapshot'
HOME = Path.home()
ROOTS = ('.config/hypr', '.config/omarchy', '.config/alacritty', '.config/foot',
         '.config/kitty', '.config/ghostty', '.config/nvim', '.config/mise',
         '.config/btop', '.config/lazygit', '.config/tmux', '.config/fontconfig')
EXCLUDED = {'.config/btop/themes/current.theme', '.config/nvim/lua/plugins/theme.lua'}
SINGLES = ('.bashrc', '.bash_profile', '.config/starship.toml',
           '.config/dotfiles/bash.sh', '.config/nvim-personal/init.lua')


def digest(data):
    return hashlib.sha256(data).hexdigest()


def capture():
    if SNAPSHOT.exists():
        raise ValueError('Snapshot already exists; refusing to overwrite the baseline.')
    files = {HOME / name for name in SINGLES if (HOME / name).is_file()}
    for name in ROOTS:
        root = HOME / name
        if root.is_symlink():
            raise ValueError(f'Review symlinked root manually: {root}')
        if root.exists():
            for directory, dirs, names in os.walk(root, followlinks=False):
                dirs[:] = sorted(d for d in dirs if d != '.git' and not (Path(directory) / d).is_symlink())
                for filename in names:
                    path = Path(directory) / filename
                    if path.is_file():
                        files.add(path)
    entries = []
    staging = SNAPSHOT.with_name('snapshot.tmp-' + uuid.uuid4().hex)
    staging.mkdir(parents=True)
    try:
        for path in sorted(files):
            if str(path.relative_to(HOME)) in EXCLUDED:
                continue
            if path.is_symlink() and not path.resolve().is_relative_to(REPO):
                raise ValueError(f'Review external symlink manually: {path}')
            name = str(path.relative_to(HOME))
            data = path.read_bytes()
            target = staging / 'home' / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
            target.chmod(path.stat().st_mode & 0o777)
            entry = {'path': name, 'sha256': digest(data), 'mode': path.stat().st_mode & 0o777}
            if path.is_symlink():
                entry['source_link'] = os.readlink(path)
            entries.append(entry)
        versions = {}
        import subprocess
        result = subprocess.run(['pacman', '-Q', 'omarchy', 'hyprland', 'bash', 'ghostty', 'neovim', 'mise'], capture_output=True, text=True)
        versions['packages'] = result.stdout.splitlines()
        theme_file = HOME / '.local/state/omarchy/current/theme.name'
        versions['theme'] = theme_file.read_text().strip() if theme_file.is_file() else None
        manifest = {'captured_at': datetime.now().astimezone().isoformat(), 'home': str(HOME),
                    'versions': versions, 'excluded_generated_links': sorted(EXCLUDED), 'entries': entries}
        (staging / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
        staging.rename(SNAPSHOT)
    except Exception:
        shutil.rmtree(staging)
        raise
    print(f'Captured {len(entries)} files: {SNAPSHOT}')


def load():
    manifest = json.loads((SNAPSHOT / 'manifest.json').read_text())
    if manifest['home'] != str(HOME):
        raise ValueError('This machine snapshot belongs to another home directory.')
    for name in manifest.get('absent_paths', []):
        path = Path(name)
        if path.is_absolute() or '..' in path.parts:
            raise ValueError('Unsafe absent path')
    for entry in manifest['entries']:
        name = Path(entry['path'])
        if name.is_absolute() or '..' in name.parts:
            raise ValueError('Unsafe snapshot path')
        data = (SNAPSHOT / 'home' / name).read_bytes()
        if digest(data) != entry['sha256']:
            raise ValueError(f'Snapshot changed: {name}. Keep baseline immutable.')
    return manifest


def changed(entry):
    path = HOME / entry['path']
    if not path.is_file():
        return True
    return digest(path.read_bytes()) != entry['sha256'] or path.stat().st_mode & 0o777 != entry['mode']


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    action = parser.add_mutually_exclusive_group()
    action.add_argument('--capture', action='store_true')
    action.add_argument('--restore', action='store_true')
    parser.add_argument('--file', action='append', default=[], help='exact home-relative path; repeatable')
    parser.add_argument('--apply', action='store_true', help='apply selected restores; otherwise preview')
    parser.add_argument('--diff', action='store_true', help='show text differences (current vs baseline)')
    args = parser.parse_args()
    if args.capture:
        if args.apply or args.file or args.diff:
            parser.error('--capture must be used alone')
        capture()
        return 0
    if args.apply and not args.restore:
        parser.error('--apply requires --restore')
    manifest = load()
    entries = manifest['entries']
    known = {e['path'] for e in entries}
    if set(args.file) - known:
        raise ValueError('Unknown paths: ' + ', '.join(sorted(set(args.file) - known)))
    if args.restore and not args.file:
        parser.error('Restore requires explicit --file paths; whole-desktop restore is intentionally unsupported.')
    selected = [e for e in entries if not args.file or e['path'] in args.file]
    changes = [e for e in selected if changed(e)]
    additions = []
    if not args.restore and not args.file:
        additions = [name for name in manifest.get('absent_paths', [])
                     if (HOME / name).exists() or (HOME / name).is_symlink()]
        for name in additions:
            print('ADDED ' + name + ' (absent in baseline)')
    for entry in changes:
        print(('RESTORE ' if args.restore else 'CHANGED ') + entry['path'])
        if args.diff:
            path = HOME / entry['path']
            current = path.read_text(errors='replace') if path.is_file() else ''
            baseline = (SNAPSHOT / 'home' / entry['path']).read_text(errors='replace')
            print(''.join(difflib.unified_diff(current.splitlines(True), baseline.splitlines(True),
                                            fromfile='current/' + entry['path'], tofile='baseline/' + entry['path'])), end='')
    if not changes and not additions:
        print(f'All {len(selected)} selected files match the saved baseline.')
        return 0
    if not args.restore or not args.apply:
        print('No files changed.')
        return 1 if not args.restore else 0
    # Do not follow links during restoration. Shared settings have their own source.
    for entry in changes:
        path = HOME / entry['path']
        if path.is_symlink() or 'source_link' in entry:
            raise ValueError(f'Restore linked settings at their source after review: {path}')
        for parent in path.parents:
            if parent == HOME:
                break
            if parent.is_symlink():
                raise ValueError(f'Symlinked parent: {parent}')
    backup = HOME / '.local/state/dotfiles/backups' / ('snapshot-restore-' + datetime.now().strftime('%Y%m%d-%H%M%S-') + uuid.uuid4().hex[:8])
    backup.mkdir(parents=True, mode=0o700)
    rollback = {'home': str(HOME), 'entries': []}
    support.HOME = HOME
    for index, entry in enumerate(changes):
        path = HOME / entry['path']
        before = support.fingerprint(path)
        saved = {'path': entry['path'], 'before': before}
        if before is not None:
            saved['saved'] = str(index)
            shutil.copyfile(path, backup / str(index))
            (backup / str(index)).chmod(0o600)
        rollback['entries'].append(saved)
    support.write(backup / 'manifest.json', json.dumps(rollback, indent=2).encode(), 0o600)
    done = []
    try:
        for entry, saved in zip(changes, rollback['entries']):
            path = HOME / entry['path']
            if support.fingerprint(path) != saved['before']:
                raise ValueError(f'Changed during restore: {path}')
            support.write(path, (SNAPSHOT / 'home' / entry['path']).read_bytes(), entry['mode'])
            done.append(saved)
            saved['after'] = support.fingerprint(path)
        support.write(backup / 'manifest.json', json.dumps(rollback, indent=2).encode(), 0o600)
    except Exception:
        for saved in reversed(done):
            support.put_original(saved, backup)
        raise
    print(f'Restored selected files. Undo backup: {backup}')
    print('No applications restarted. Hyprland/shell files may automatically reload when written.')
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (ValueError, OSError) as error:
        sys.exit(str(error))
