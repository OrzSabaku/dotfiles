#!/usr/bin/env python3
"""Explicit OS profiles. Preview by default; apply only with --apply."""
import argparse
import subprocess
import sys
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--profile', choices=['omarchy', 'fedora'])
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('--restore', type=Path, help='restore an Omarchy backup directory')
    parser.add_argument('--import-existing', action='store_true')
    args = parser.parse_args()
    if args.apply and args.dry_run:
        parser.error('--apply and --dry-run are mutually exclusive')
    if args.restore:
        if args.import_existing or args.profile:
            parser.error('--restore cannot be combined with profile/import')
        from install_omarchy import restore
        restore(args.restore, args.apply)
    elif args.profile == 'omarchy':
        if args.import_existing:
            parser.error('--import-existing is only for Fedora')
        from install_omarchy import install
        install(args.apply)
    elif args.profile == 'fedora':
        if not args.apply:
            print('Fedora legacy installer: no changes. Use --profile fedora --apply to run.')
            return 0
        command = [sys.executable, str(Path(__file__).with_name('install_fedora.py'))]
        if args.import_existing:
            command.append('--import-existing')
        return subprocess.call(command)
    else:
        parser.error('choose --profile omarchy/fedora or --restore PATH')
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (OSError, ValueError) as error:
        sys.exit(str(error))
