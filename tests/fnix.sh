#!/usr/bin/env bash
# Run with: bash tests/fnix.sh (requires python3, fnox, age and nix)
set -euo pipefail
umask 077
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export XDG_CONFIG_HOME="$tmp/config dir" HOME="$tmp/home" FNIX_HOST=wsl
repo="$XDG_CONFIG_HOME/nixos"
module="$repo/modules/secrets/fnox.nix"
mkdir -p "$repo/modules/secrets" "$HOME" "$tmp/bin" "$XDG_CONFIG_HOME/fnox"
cd "$tmp"

# Use a disposable recipient, never the user's private key or installed config.
age-keygen -o identity 2>/dev/null
recipient=$(age-keygen -y identity)
sed -E "s/^( *)recipients = .*/\1recipients = [\"$recipient\"]/" \
  "$root/modules/secrets/fnox.nix" > "$module"
printf 'invalid toml!' | tee fnox.toml > "$XDG_CONFIG_HOME/fnox/config.toml"
export FNOX_PROFILE=unrelated
fnix() { python3 "$root/modules/secrets/fnix.py" "$@"; }

# Observe the rebuild arguments without activating anything.
export PATH="$tmp/bin:$PATH" SWITCH_LOG="$tmp/switched"
cat > bin/sudo <<'SH'
#!/bin/sh
printf '%s\n' "$@" > "$SWITCH_LOG"
SH
chmod +x bin/sudo

read_back() {
  nix --extra-experimental-features nix-command eval --raw --file "$module" --apply \
    'm: (m { config = {}; pkgs = {}; osConfig = {}; }).programs.fnox.settings.secrets.FNIX_TEST.value' |
    python3 -c 'import base64, sys; sys.stdout.buffer.write(base64.b64decode(sys.stdin.buffer.read()))' |
    age -d -i identity
}

printf %s "fixture-first" | fnix set FNIX_TEST
[[ ! -e $SWITCH_LOG && $(read_back) == fixture-first ]]
for flag in --switch --rebuild; do
  printf %s "fixture-$flag" | fnix --repo "$repo" set FNIX_TEST "$flag"
  [[ $(read_back) == "fixture-$flag" ]]
  [[ $(<"$SWITCH_LOG") == "$(printf '%s\n' nixos-rebuild switch --flake "path:$repo#wsl")" ]]
  rm "$SWITCH_LOG"
done
if grep -q 'fixture-' "$module"; then exit 1; fi

# Failed encryption must neither edit the module nor start a switch.
sed "s/$recipient/age1invalid/" "$module" > invalid.nix
cp invalid.nix "$module"
if printf %s ignored | fnix set FNIX_TEST --switch; then exit 1; fi
cmp invalid.nix "$module"
[[ ! -e $SWITCH_LOG ]]
echo "fnix smoke test passed"
