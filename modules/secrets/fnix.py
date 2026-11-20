"""fnix set: update the literal fnox settings in the writable Nix module."""

import argparse
import base64
import fcntl
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import textwrap
import tomllib


BLOCK = re.compile(r"^( *)# BEGIN fnix\n(?P<body>.*?)^\1# END fnix$", re.M | re.S)


def set_with_fnox(settings, key):
    config = tomllib.loads(settings)
    provider = config.get("providers", {}).get("age", {})
    if provider.get("type") != "age" or not provider.get("recipients"):
        raise ValueError("expected an age provider with public recipients")

    # Encryption needs only the checkout's public recipients. Don't discover a
    # project/global config, inherit fnox overrides or use the user's daemon.
    with tempfile.TemporaryDirectory(prefix="fnix-") as home:
        path = Path(home) / "fnox.toml"
        path.write_text(settings)
        subprocess.run(
            ["fnox", "--no-daemon", "-c", "./fnox.toml", "set", "--provider", "age", key],
            cwd=home, env={"HOME": home, "PATH": os.environ["PATH"]}, check=True,
        )
        result = path.read_text()

    updated = tomllib.loads(result)
    entry = updated.get("secrets", {}).get(key, {})
    if not isinstance(entry, dict) or entry.get("provider") != "age":
        raise ValueError("fnox did not use the age provider")
    ciphertext = base64.b64decode(entry.get("value", ""), validate=True)
    if not ciphertext.startswith(b"age-encryption.org/v1\n"):
        raise ValueError("fnox did not produce an age ciphertext")
    config.setdefault("secrets", {})[key] = entry
    if updated != config:
        raise ValueError("fnox changed settings other than the requested secret")
    return result


def update(module, key):
    if not module.is_file() or module.is_symlink() or not os.access(module, os.W_OK):
        raise ValueError(f"expected a writable checkout with {module}; check --repo")
    source = module.read_text()
    blocks = list(BLOCK.finditer(source))
    if len(blocks) != 1:
        raise ValueError(f"expected one marked fnix TOML block in {module}")
    block = blocks[0]
    settings = set_with_fnox(textwrap.dedent(block["body"]), key)
    start, end = block.span("body")
    result = source[:start] + textwrap.indent(settings, block[1]) + source[end:]

    # Stage on the same filesystem for atomic replacement. Don't clobber an
    # edit made while the user was at the prompt.
    with tempfile.TemporaryDirectory(dir=module.parent, prefix=".fnix-") as stage:
        new = Path(stage) / module.name
        new.write_text(result)
        shutil.copymode(module, new)
        with module.open() as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            if module.read_text() != source:
                raise ValueError(f"{module} changed during encryption; retry")
            new.replace(module)


def main():
    parser = argparse.ArgumentParser(prog="fnix", description=__doc__, allow_abbrev=False)
    parser.add_argument("command", choices=["set"])
    parser.add_argument("key", metavar="KEY", help="environment variable name")
    parser.add_argument("--switch", "--rebuild", action="store_true",
                        help="rebuild and switch this host after saving")
    config_home = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
    parser.add_argument("--repo", type=Path, default=config_home / "nixos",
                        help="writable flake checkout (default: %(default)s)")
    args, extra = parser.parse_known_args()
    if extra:
        parser.error("unexpected argument; supply the secret via the hidden prompt or stdin")
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", args.key):
        parser.error("KEY must be an environment variable name")

    repo = args.repo.expanduser().resolve()
    module = repo / "modules/secrets/fnox.nix"
    update(module, args.key)
    print(f"Saved {args.key} in {module}", flush=True)
    if args.switch:
        host = os.environ["FNIX_HOST"]  # set by the Home Manager wrapper
        rebuild = "darwin-rebuild" if host == "mac" else "nixos-rebuild"
        subprocess.run(["sudo", rebuild, "switch", "--flake", f"path:{repo}#{host}"], check=True)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        sys.exit(f"fnix: {exc}")
