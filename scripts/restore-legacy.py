"""Read pre-chezmoi backups; new changes use chezmoi diff/apply."""
import hashlib
import json
import os
import uuid
from pathlib import Path

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


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('backup', type=Path)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    try:
        restore(args.backup, args.apply)
    except (OSError, ValueError) as error:
        parser.exit(1, str(error) + '\n')
