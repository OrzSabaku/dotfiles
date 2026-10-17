"""Small, backed-up Omarchy overlay; never writes package-owned defaults."""
import hashlib
import json
import os
import shutil
import uuid
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parent
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
        path.symlink_to(original['link'])
    else:
        write(path, (backup / entry['saved']).read_bytes(), original['mode'])


def plan():
    changes = []
    links = {
        '.config/dotfiles/bash.sh': REPO / 'common/bash.sh',
        '.config/ghostty/dotfiles.conf': REPO / 'profiles/omarchy/ghostty.conf',
        '.config/starship.toml': REPO / 'common/starship.toml',
        '.config/nvim-personal/init.lua': REPO / 'home/.config/nvim/init.lua',
    }
    for name, source in links.items():
        if not source.is_file():
            raise ValueError(f'Missing source: {source}')
        path = HOME / name
        before = fingerprint(path)
        if before and before.get('link') == str(source):
            continue
        if path.is_symlink():
            raise ValueError(f'Refusing to replace an unrelated symlink: {path}')
        changes.append({'path': name, 'before': before, 'link': str(source)})
    additions = {
        '.bashrc': '\n# Personal dotfiles (after Omarchy initialization)\n[[ -r "$HOME/.config/dotfiles/bash.sh" ]] && source "$HOME/.config/dotfiles/bash.sh"\n',
        '.config/ghostty/config': '\n# Personal dotfiles (after Omarchy defaults)\nconfig-file = ?"~/.config/ghostty/dotfiles.conf"\n',
    }
    for name, addition in additions.items():
        path = HOME / name
        before = fingerprint(path)
        if before is None or path.is_symlink():
            raise ValueError(f'Expected an existing regular Omarchy config: {path}')
        data = path.read_text()
        if addition.strip() in data:
            continue
        if ('dotfiles/bash.sh' if name == '.bashrc' else 'ghostty/dotfiles.conf') in data:
            raise ValueError(f'An existing custom include needs review: {path}')
        changes.append({'path': name, 'before': before, 'text': data + addition})
    # A symlink in any parent could redirect writes outside the intended directory.
    for entry in changes:
        for parent in (HOME / entry['path']).parents:
            if parent == HOME:
                break
            if parent.is_symlink():
                raise ValueError(f'Refusing a symlinked parent: {parent}')
    return changes


def install(apply=False):
    if 'ID=omarchy' not in Path('/etc/os-release').read_text():
        raise ValueError('This profile requires Omarchy')
    changes = plan()
    for entry in changes:
        print(('LINK ' if 'link' in entry else 'APPEND ') + str(HOME / entry['path']))
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
                temp.symlink_to(entry['link'])
                os.replace(temp, path)
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
