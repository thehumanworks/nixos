# Secrets

Doppler stores the values. Home Manager installs the CLI and declares **which
names** interactive Bash and Zsh import in [home.nix](home.nix), using the
[local Doppler module](modules/secrets/doppler.nix). No token or secret value
belongs in Nix, Git or the Nix store.

**First setup / migration**

1. Choose your Doppler project and config. Populate it securely (dashboard or
   CLI via stdin) **before switching**. Nothing here copies values to Doppler.
   For the previous age-backed setup, keep your identity outside the checkout;
   the encrypted fnox settings are recoverable from commit `1873a38`.
2. Authenticate as the invoking user on each host, not under `sudo`. If the CLI
   isn't installed yet, use `nix shell nixpkgs#doppler` for bootstrap:
   ```sh
   doppler login --scope "$HOME"
   doppler setup --scope "$HOME" --project YOUR_PROJECT --config YOUR_CONFIG
   ```
   Alternatively, pin `programs.doppler.project` and `programs.doppler.config`
   in `home.nix` and skip `setup`. The managed commands use the home scope even
   outside your home directory and ignore Doppler environment overrides.
3. Switch Home Manager via your host flake and start a **fresh login session**.
   A shell descended from the old setup can still inherit its tokens. Bash
   and Zsh are managed by Home Manager; back up any conflicting hand-written
   startup files before the first switch.

**Shell policy** (example):

```nix
programs.doppler = {
  enable = true;
  enableBashIntegration = true;
  enableZshIntegration = true;
  project = "workstation";
  config = "dev";
  exportOnly = [ "EXA_API_KEY" "GITHUB_TOKEN" ];
};
```

With an allowlist, **only** the listed names are imported; no exclusion list
is needed. `exportOnly = []` imports nothing. For a denylist instead, omit
`exportOnly` (or set it to `null`) and use `exportExcept = [ "CACHIX_AUTH_TOKEN" ];`.

Shell imports are opt-in. Prefer an explicit allowlist: children inherit
exported variables, and names such as `PATH` affect shell behavior. Filters
apply to imports, **not** to inherited variables or Doppler access permissions.
Use a least-privileged account/config.

On interactive startup the hook fetches JSON once, without a fallback file,
and imports the selected entries as data (no `eval`). Missing names are
skipped. An unavailable CLI/API or invalid response leaves the shell usable
without applying the download; tracing shells skip the hook. Rotate values in
the dashboard or supply the value on stdin to `doppler secrets set NAME
--project YOUR_PROJECT --config YOUR_CONFIG`. Open a new shell — no rebuild.
Changing the declarative selection or adding a name to the allowlist requires
a switch.

For scripts, `doppler-home-run` is `doppler run` with the same home scope and
project/config selection. For example:

```sh
doppler-home-run --only-secrets GITHUB_ENTERPRISE_TOKEN,GITHUB_ENTERPRISE_HOST -- gh-work pr list
```

Both `hms` and the flake's `apply` app request only `CACHIX_AUTH_TOKEN` from
Doppler for Cachix. The checked-in allowlist does not import that token into
the interactive shell, and the rebuild does not need it during Nix evaluation.

**Beelink:** `#linux` is a placeholder until its hardware configuration is
added. Its missing root filesystem blocks that target and the full flake check,
but not `#wsl` or `#mac`.

# Git and GitHub CLI

The Doppler shell integration supplies these environment variables to Git and `gh`.
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
