"""Backed-up per-file Omarchy links; never writes package-owned defaults."""
import hashlib
import json
import os
import shutil
import uuid
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
HOME = Path.home()


def fingerprint(path):
    if path.is_symlink():
        return {'link': os.readlink(path), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
    if path.exists():
        if not path.is_file():
            raise ValueError(f'Not a regular file: {path}')
        return {'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'mode': path.stat().st_mode & 0o777}
    return None


def write(path, data, mode=0o644):
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_name(path.name + '.dotfiles-' + uuid.uuid4().hex)
    try:
        temp.write_bytes(data)
        temp.chmod(mode)
        os.replace(temp, path)
    finally:
        temp.unlink(missing_ok=True)


def put_original(entry, backup):
    path = HOME / entry['path']
    original = entry['before']
    if original is None:
        path.unlink(missing_ok=True)
    elif 'link' in original:
        path.unlink(missing_ok=True)
        old_source = Path(original['link'])
        if not old_source.is_absolute():
            old_source = path.parent / old_source
        if old_source.is_file():
            path.symlink_to(original['link'])
        else:
            # A directory reorganization may have retired the old source.
            write(path, (backup / entry['saved']).read_bytes(), entry.get('before_mode') or 0o644)
    else:
        write(path, (backup / entry['saved']).read_bytes(), original['mode'])


def managed_files():
    manifest = json.loads((REPO / 'omarchy/files.json').read_text())
    if manifest.get('version') != 1:
        raise ValueError('Unsupported files manifest version')
    seen = set()
    for entry in manifest['files']:
        name, source_name = Path(entry['path']), Path(entry['source'])
        if (name.is_absolute() or '..' in name.parts or not name.parts
                or source_name.is_absolute() or '..' in source_name.parts):
            raise ValueError('Unsafe managed path')
        if entry['path'] in seen:
            raise ValueError('Duplicate managed path')
        seen.add(entry['path'])
        source = REPO / source_name
        if not source.is_file() or source.is_symlink() or not source.resolve().is_relative_to(REPO):
            raise ValueError(f'Expected a regular repository source: {source}')
        if 'migrate_from_repo' in entry:
            previous = Path(entry['migrate_from_repo'])
            if previous.is_absolute() or '..' in previous.parts or not previous.parts:
                raise ValueError('Unsafe migration source')
            entry = dict(entry, migrate_from=str(REPO / previous))
        yield entry, source


def plan():
    changes = []
    for entry, source in managed_files():
        name = entry['path']
        path = HOME / name
        for parent in path.parents:
            if parent == HOME:
                break
            if parent.is_symlink():
                raise ValueError(f'Refusing a symlinked parent: {parent}')
        before = fingerprint(path)
        if path.is_symlink():
            if path.resolve() == source.resolve():
                continue
            if os.readlink(path) != entry.get('migrate_from'):
                raise ValueError(f'Refusing an unrelated symlink: {path}')
        if before is not None and path.read_bytes() != source.read_bytes():
            raise ValueError(f'Content conflict: {path}; compare with {source} before installing')
        if before is not None and path.stat().st_mode & 0o777 != source.stat().st_mode & 0o777:
            raise ValueError(f'Permission conflict: {path}; review source permissions')
        changes.append({'path': name, 'before': before, 'before_mode': path.stat().st_mode & 0o777 if before else None, 'link': str(source)})
    return changes


def install(apply=False):
    if 'ID=omarchy' not in Path('/etc/os-release').read_text():
        raise ValueError('This profile requires Omarchy')
    changes = plan()
    for entry in changes:
        print('LINK ' + str(HOME / entry['path']))
    if not changes:
        print('Already installed; no changes.')
        return
    if not apply:
        print('Preview only. Use --profile omarchy --apply to install.')
        return
    backup = HOME / '.local/state/dotfiles/backups' / (datetime.now().strftime('%Y%m%d-%H%M%S-') + uuid.uuid4().hex[:8])
    backup.mkdir(parents=True, mode=0o700)
    manifest = {'home': str(HOME), 'entries': changes}
    for index, entry in enumerate(changes):
        path = HOME / entry['path']
        if fingerprint(path) != entry['before']:
            raise ValueError(f'Config changed during preflight: {path}')
        if entry['before'] is not None:
            entry['saved'] = str(index)
            shutil.copyfile(path, backup / entry['saved'])
            (backup / entry['saved']).chmod(0o600)
    write(backup / 'manifest.json', json.dumps(manifest, indent=2).encode(), 0o600)
    done = []
    try:
        for entry in changes:
            path = HOME / entry['path']
            if fingerprint(path) != entry['before']:
                raise ValueError(f'Config changed before write: {path}')
            if 'link' in entry:
                path.parent.mkdir(parents=True, exist_ok=True)
                temp = path.with_name(path.name + '.dotfiles-' + uuid.uuid4().hex)
                try:
                    temp.symlink_to(entry['link'])
                    os.replace(temp, path)
                finally:
                    temp.unlink(missing_ok=True)
            else:
                write(path, entry['text'].encode(), entry['before']['mode'])
            done.append(entry)
            entry['after'] = fingerprint(path)
        write(backup / 'manifest.json', json.dumps(manifest, indent=2).encode(), 0o600)
    except Exception:
        for entry in reversed(done):
            put_original(entry, backup)
        raise
    print(f'Backup: {backup}')
    print(f'Restore: python3 {REPO / "install.py"} --restore {backup} --apply')


def restore(backup, apply=False):
    backup = backup.expanduser().resolve()
    manifest = json.loads((backup / 'manifest.json').read_text())
    if manifest['home'] != str(HOME):
        raise ValueError('Backup belongs to another home directory')
    entries = manifest['entries']
    for entry in entries:
        name = Path(entry['path'])
        if name.is_absolute() or '..' in name.parts:
            raise ValueError('Invalid backup path')
        path = HOME / name
        for parent in path.parents:
            if parent == HOME:
                break
            if parent.is_symlink():
                raise ValueError(f'Symlinked parent: {parent}')
        if 'after' not in entry or fingerprint(path) != entry['after']:
            raise ValueError(f'Changed since installation; refusing to overwrite: {path}')
        if entry['before'] is not None:
            saved = backup / entry['saved']
            if hashlib.sha256(saved.read_bytes()).hexdigest() != entry['before']['sha256']:
                raise ValueError(f'Backup checksum mismatch: {saved}')
        print(f'RESTORE {path}')
    if not apply:
        print('Preview only. Add --apply to restore.')
        return
    for entry in reversed(entries):
        put_original(entry, backup)
    print('Restored. Empty directories may remain. Open a new shell/terminal to load the restored settings.')
