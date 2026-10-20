import os
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class PublishPluginsTests(unittest.TestCase):
    def publish(self, delete=False, **overrides):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            tool = root / 'mock'
            tool.write_text('''#!/usr/bin/env python3
import os, sys
from pathlib import Path
args=sys.argv[1:]
name=Path(sys.argv[0]).name
with open(os.environ['CALLS'], 'a') as log:
    log.write(name+' '+' '.join(args)+'\\n')
if name=='git':
    if 'get-url' in args:
        print('https://github.com/Desert-sabaku/'+Path(args[1]).name+'.git')
    elif 'rev-parse' in args: print('new-head')
elif name=='gh':
    if args[:2]==['repo','view']:
        if 'visibility' in args: print('PUBLIC')
        else: print('{}')
    elif args[0]=='api':
        target=args[1] if args[1]!='--paginate' else args[2]
        if target.endswith('/branches'): print(os.environ.get('BRANCHES','main'))
        elif target.endswith('/tags'): print(os.environ.get('TAGS',''))
        elif '/omarchy-plugins/' in target:
            print(os.environ.get('LEGACY_HEAD','02fc5bbf6cb7e467f5d6a3686b3240a0f678c7bd'))
        else: print(os.environ.get('REMOTE_HEAD','new-head'))
''')
            tool.chmod(0o755)
            for name in ['git', 'gh', 'omarchy']:
                (root / name).symlink_to(tool)
            env=os.environ.copy()
            env.update(PATH=str(root)+':'+env['PATH'], CALLS=str(root/'calls'), **overrides)
            command=['bash',str(REPO/'scripts/publish-omarchy-plugins')]
            if delete: command.append('--delete-legacy')
            result=subprocess.run(command,env=env,text=True,capture_output=True,timeout=15)
            return result,(root/'calls').read_text()

    def test_default_never_deletes_legacy(self):
        result,calls=self.publish()
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertNotIn('gh repo delete',calls)

    def test_deletion_follows_both_verified_pushes(self):
        result,calls=self.publish(delete=True)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual(calls.count('push -u'),2)
        self.assertIn('gh repo delete Desert-sabaku/omarchy-plugins --yes',calls)
        self.assertGreater(calls.index('gh repo delete'),calls.rindex('git/ref/heads/main'))

    def test_remote_mismatch_prevents_deletion(self):
        result,calls=self.publish(delete=True,REMOTE_HEAD='different')
        self.assertNotEqual(result.returncode,0)
        self.assertNotIn('gh repo delete',calls)

    def test_new_legacy_work_prevents_deletion(self):
        result,calls=self.publish(delete=True,LEGACY_HEAD='unexpected')
        self.assertNotEqual(result.returncode,0)
        self.assertNotIn('gh repo delete',calls)

    def test_extra_legacy_tags_prevent_deletion(self):
        result,calls=self.publish(delete=True,TAGS='v1')
        self.assertNotEqual(result.returncode,0)
        self.assertNotIn('gh repo delete',calls)
