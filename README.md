# Secrets

`programs.fnox.enable = true` installs `fnox` and makes Home Manager generate a read-only
`$XDG_CONFIG_HOME/fnox/config.toml` from [the Nix module](modules/secrets/fnox.nix).
The checkout contains public age recipients and ciphertext, not private keys.
On each host, provision the matching identity at `~/.config/fnox/age.txt`
(mode `0600`), or point `FNOX_AGE_KEY_FILE` at an identity outside the checkout.
Keep private keys and plaintext outside the checkout: a `path:` flake can copy
even Git-ignored files into the Nix store.

**Add or rotate a secret:** switch to this configuration once to install `fnix`
(e.g. `sudo nixos-rebuild switch --flake "path:$PWD#wsl"` from the checkout on WSL).
Then, from any directory:

```sh
fnix set EXAMPLE_API_KEY             # hidden prompt; edits the checkout only
fnix set EXAMPLE_API_KEY --switch    # save, then rebuild and switch this host
# For automation: secret-producing-command | fnix set EXAMPLE_API_KEY --rebuild
```

`fnix set` runs the real `fnox set` against a private temporary copy of the
module's TOML settings. It uses the **checkout's** age recipients, needs no
private key to encrypt, and writes the ciphertext back to
`modules/secrets/fnox.nix`. Pass the value at the prompt or on stdin, **not**
as a command-line argument. Don't use `fnox set --global` on the installed file.

The checkout defaults to `${XDG_CONFIG_HOME:-$HOME/.config}/nixos` regardless
of the current directory. Use `fnix --repo /path/to/checkout set KEY` to select
another. `--rebuild` and `--switch` are aliases: they switch from the **updated
checkout** using `nixos-rebuild` (`#wsl` or `#linux`) or `darwin-rebuild` (`#mac`).
Without either flag, the installed config is unchanged until your next switch.
If a rebuild fails, the encrypted edit stays in the checkout. Review and commit
`modules/secrets/fnox.nix` to share it; `fnix` doesn't stage, commit or push.

**Beelink:** `#linux` is a placeholder until its hardware configuration is
added. Its missing root filesystem blocks that target and the full flake check,
but not `#wsl` or `#mac`.

**Use secrets:** the fnox shell integration exports them into interactive shells;
`pi`, `claude`, Git and `gh` need no secret-loading aliases. Child processes of
that shell inherit the exported values. Outside an integrated shell use, for
example, `fnox exec -- gh-work pr list` or `fnox exec -- hms`. The flake's
`apply` app reads the Cachix token from the activated fnox config before pushing.

# Git and GitHub CLI

fnox supplies these environment variables to Git and `gh`.
No `gh auth login` is needed.

| Profile | Host variable | Default host | Token variable |
| --- | --- | --- | --- |
| Personal | `GITHUB_HOST` | `github.com` | `GITHUB_TOKEN` |
| Work | `GITHUB_ENTERPRISE_HOST` | `leadforensics.ghe.com` | `GITHUB_ENTERPRISE_TOKEN` |

Use distinct, lower-case hostnames (no `https://` or path). Git's HTTPS credential
helper reads the variables on each request and only supplies the matching
host's token. It doesn't store tokens. SSH remotes still use SSH keys.

Use **`gh`** for personal and **`gh-work`** for work. `gh-personal` is an
explicit synonym for `gh`. In interactive Bash:

```sh
gh api user --jq .login         # personal account
gh-work repo clone OWNER/REPO
gh-work pr list                 # in a work clone
```

Use `gh-work` even inside a work clone: the profile does not switch with the
directory. The upstream CLI doesn't recognize the two host variables and normally reads
`GITHUB_TOKEN` for both `github.com` and `*.ghe.com`. The profile commands set
`GH_HOST` and the appropriate CLI token for that invocation only. `GH_HOST`
is a default, not a restriction: don't pass another profile's repo or host.

**Commit authorship is separate from authentication.** Git defaults to
`Tomas Roda <rodat.dev@proton.me>`. Any standard HTTPS or Git SSH remote on
`leadforensics.ghe.com` selects `Tomas Roda <rodat@leadforensics.com>`.
Add the work remote before the first commit. For a repo on a different work
hostname, set `git config --local user.email rodat@leadforensics.com`.
Check the effective author with `git var GIT_AUTHOR_IDENT`.
