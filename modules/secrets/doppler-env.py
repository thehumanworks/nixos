"""Fetch once; emit validated NUL-delimited name/value pairs to the shell hook."""

import json
import re
import subprocess
import sys


def records(payload, only, excluded):
    secrets = json.loads(payload)
    if not isinstance(secrets, dict):
        raise ValueError("expected a JSON object")

    result = bytearray()
    for key, value in secrets.items():
        if (only is not None and key not in only) or key in excluded:
            continue
        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", key):
            continue
        if not isinstance(value, str) or "\0" in value:
            raise ValueError("not an environment string")
        result.extend(key.encode("ascii") + b"\0" + value.encode("utf-8") + b"\0")
    return result


if __name__ == "__main__":
    only, excluded = map(json.loads, sys.argv[1:3])
    try:
        payload = subprocess.run(
            sys.argv[3:], stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL, check=True, timeout=5,
        ).stdout
        # Don't emit partial exports on a failed fetch or malformed response.
        output = records(payload, only, excluded)
    except (OSError, ValueError, subprocess.SubprocessError):
        sys.exit("doppler: shell imports skipped; check login, project/config and connectivity.")
    sys.stdout.buffer.write(output)
