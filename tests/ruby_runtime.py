"""Resolve Ruby before tests replace HOME (mise shims depend on HOME)."""
from pathlib import Path
import shutil
import subprocess

RUBY = shutil.which('ruby')
if RUBY and Path(RUBY).parent.name == 'shims':
    RUBY = subprocess.check_output(['mise', 'which', 'ruby'], text=True).strip()
