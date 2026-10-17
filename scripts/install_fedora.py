#!/usr/bin/env python3
"""Install the explicitly managed dotfiles as symlinks into the home directory."""

import argparse
import os
import shutil
import sys
from pathlib import Path


FILES = (
    ".bashrc",
    ".zshrc",
    ".config/ghostty/config.ghostty",
    ".config/mise/config.toml",
    ".config/nvim/init.lua",
    ".config/sheldon/plugins.toml",
    ".config/starship.toml",
)


def same_contents(a: Path, b: Path) -> bool:
    return a.is_file() and b.is_file() and a.read_bytes() == b.read_bytes()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--import-existing",
        action="store_true",
        help="copy existing settings into the repository before linking (first run)",
    )
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    repo = root / "fedora"
    home = Path.home()
    actions = []
    errors = []

    # Check every path before changing anything, so a conflict cannot cause a
    # partially installed configuration.
    for name in FILES:
        source = (root / "common" / name) if name in (".config/nvim/init.lua", ".config/starship.toml") else repo / name
        target = home / name
        if target.is_symlink():
            if target.resolve() == source and source.is_file():
                actions.append(("already linked", source, target))
            else:
                errors.append(f"{target}: symlink points elsewhere")
        elif target.exists():
            if not target.is_file():
                errors.append(f"{target}: not a regular file")
            elif source.exists():
                if same_contents(source, target):
                    actions.append(("link", source, target))
                else:
                    errors.append(f"{target}: differs from {source}; resolve manually")
            elif args.import_existing:
                actions.append(("import and link", source, target))
            else:
                errors.append(f"{target}: run with --import-existing or resolve manually")
        elif source.is_file():
            actions.append(("link", source, target))
        else:
            actions.append(("skip", source, target))

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    for action, source, target in actions:
        if action == "import and link":
            source.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(target, source)
    for action, source, target in actions:
        if action in ("link", "import and link"):
            target.parent.mkdir(parents=True, exist_ok=True)
            if target.exists():
                target.unlink()
            os.symlink(source, target)
        print(f"{action}: {target}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
