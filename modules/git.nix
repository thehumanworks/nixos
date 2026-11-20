{
  config,
  lib,
  pkgs,
  ...
}:
let
  workHost = "leadforensics.ghe.com";
  workIdentityFor = url: {
    condition = "hasconfig:remote.*.url:${url}";
    contents.user.email = "rodat@leadforensics.com";
  };

  # Shell expansions: hosts and tokens are read at invocation, not at build time.
  profileHosts = ''
    personal_host="''${GITHUB_HOST:-github.com}"
    work_host="''${GITHUB_ENTERPRISE_HOST:-${workHost}}"
    if [[ $personal_host == "$work_host" ]]; then
      echo 'GITHUB_HOST and GITHUB_ENTERPRISE_HOST must be distinct' >&2
      exit 1
    fi
  '';

  credentialHelper = pkgs.writeShellScript "git-credential-github-env" ''
    [[ $1 == get ]] || exit 0
    ${profileHosts}
    host= protocol=
    while IFS= read -r field && [[ -n $field ]]; do
      case "$field" in
        protocol=*) protocol=''${field#protocol=} ;;
        host=*) host=''${field#host=} ;;
      esac
    done
    [[ $protocol == https ]] || exit 0
    case "$host" in
      "$personal_host") token="''${GITHUB_TOKEN:-}" ;;
      "$work_host") token="''${GITHUB_ENTERPRISE_TOKEN:-}" ;;
      *) exit 0 ;;
    esac

    if [[ -n $token ]]; then
      printf 'username=x-access-token\npassword=%s\n\n' "$token"
    fi
  '';

  ghFor =
    profile: selectProfile:
    pkgs.writeShellScriptBin "gh-${profile}" ''
      ${profileHosts}
      unset GH_TOKEN GH_ENTERPRISE_TOKEN
      ${selectProfile}
      # gh treats *.ghe.com as Enterprise Cloud, not Enterprise Server.
      case "$GH_HOST" in
        github.com|*.ghe.com|github.localhost) export GH_TOKEN="$token" ;;
        *) export GH_ENTERPRISE_TOKEN="$token" ;;
      esac
      # Aliases and extensions that call gh again should inherit this profile.
      export PATH="${config.programs.gh.package}/bin:$PATH"
      exec ${lib.getExe config.programs.gh.package} "$@"
    '';

  ghPersonal = ghFor "personal" ''
    export GH_HOST="$personal_host"
    token="''${GITHUB_TOKEN:?set GITHUB_TOKEN to use the personal profile}"
    unset GITHUB_ENTERPRISE_TOKEN
  '';
in
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Tomas Roda";
        email = "rodat.dev@proton.me";
      };
      credential.helper = "${credentialHelper}";
    };

    # Match the clone URL rather than requiring a particular checkout directory.
    includes = map workIdentityFor [
      "https://${workHost}/**"
      "git@${workHost}:*/**"
      "ssh://git@${workHost}/**"
    ];
  };

  programs.gh = {
    enable = true;
    # The stock helper would use GITHUB_TOKEN for both github.com and *.ghe.com.
    gitCredentialHelper.enable = false;
  };

  # Authentication comes from the environment; leave gh's own files writable.
  xdg.configFile."gh/config.yml".enable = false;
  home.packages = [
    ghPersonal
    # Shadow only bin/gh; keep the upstream package's man pages and completions.
    (lib.hiPrio (pkgs.linkFarm "gh-default-personal" { "bin/gh" = lib.getExe ghPersonal; }))
    (ghFor "work" ''
      export GH_HOST="$work_host"
      token="''${GITHUB_ENTERPRISE_TOKEN:?set GITHUB_ENTERPRISE_TOKEN to use gh-work}"
      unset GITHUB_TOKEN
    '')
  ];
}
