"""Run with python3 tests/test_doppler.py (bash and zsh on PATH). No credentials needed."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


MODULE = Path(__file__).resolve().parents[1] / "modules/secrets"
VALUE = "literal 'quotes' \"$HOME\" $(printf nope) \\\nsecond line\n"
PAYLOAD = json.dumps({"TEST_TEXT": VALUE, "TEST_EMPTY": "", "TEST_DENY": "denied",
                      "TEST_OTHER": "other", "TEST_BAD-NAME": "invalid name"})
HOOK = """
source "$MODULE/import-env.sh" "$PY" -I "$MODULE/doppler-env.py" "$ONLY" "$EXCEPT" \
    "$PY" fetch.py "$STATUS"
exec "$PY" -c 'import json,os; print(json.dumps({k:v for k,v in os.environ.items() if k.startswith("TEST_")}))'
"""


class DopplerTest(unittest.TestCase):
    def check(self, expected, *, only=None, exclude=(), payload=PAYLOAD, status=0,
              flags="-ic", failure=False, skipped=False):
        for shell, clean in [("bash", ["--noprofile", "--norc"]), ("zsh", ["-f"])]:
            with self.subTest(shell=shell, only=only, flags=flags), tempfile.TemporaryDirectory() as tmp:
                (Path(tmp) / "response").write_text(payload)
                (Path(tmp) / "fetch.py").write_text(
                    'import pathlib, sys\n'
                    'pathlib.Path("fetched").touch()\n'
                    'sys.stdout.write(pathlib.Path("response").read_text())\n'
                    'sys.stderr.write("private CLI diagnostic")\n'
                    'sys.exit(int(sys.argv[1]))\n'
                )
                out = subprocess.run(
                    [shutil.which(shell) or shell, *clean, flags, HOOK], cwd=tmp,
                    env={"PATH": os.defpath, "HOME": tmp, "MODULE": str(MODULE),
                         "PY": sys.executable, "ONLY": json.dumps(only),
                         "EXCEPT": json.dumps(exclude), "STATUS": str(status)},
                    capture_output=True, text=True, check=True,
                )
                self.assertEqual(json.loads(out.stdout), expected)
                self.assertEqual((Path(tmp) / "fetched").exists(), not skipped)
                self.assertEqual("imports skipped" in out.stderr, failure)
                self.assertNotIn("private CLI diagnostic", out.stderr)
                self.assertNotIn(VALUE, out.stderr)

    def test_selection_and_literal_values(self):
        self.check({"TEST_TEXT": VALUE, "TEST_EMPTY": ""},
                   only=["TEST_TEXT", "TEST_EMPTY", "TEST_MISSING"])
        self.check({"TEST_OTHER": "other", "TEST_EMPTY": ""}, exclude=["TEST_TEXT", "TEST_DENY"])
        self.check({}, only=[])

    def test_errors_do_not_partially_update_the_shell(self):
        self.check({}, status=1, failure=True)
        self.check({}, payload="not json", failure=True)
        self.check({}, payload=json.dumps({"TEST_FIRST": "ok", "TEST_NUL": "a\0b"}), failure=True)

    def test_noninteractive_and_tracing_shells_do_not_fetch(self):
        self.check({}, flags="-c", skipped=True)
        self.check({}, flags="-ixc", skipped=True)


if __name__ == "__main__":
    unittest.main()
