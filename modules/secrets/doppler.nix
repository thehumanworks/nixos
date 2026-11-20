{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.doppler;
  inherit (lib) mkOption types;
  names = types.listOf (types.strMatching "[A-Za-z_][A-Za-z0-9_]*");
  doppler = lib.getExe' cfg.package "doppler";

  # Always use the user's home scope, not a project discovered from $PWD.
  selection = lib.escapeShellArgs (
    lib.optional (cfg.project != null) "--project=${cfg.project}"
    ++ lib.optional (cfg.config != null) "--config=${cfg.config}"
  );
  flags = ''--scope "$HOME" --no-read-env --no-check-version --no-fallback ${selection}'';

  homeRun = pkgs.writeShellScriptBin "doppler-home-run" ''
    exec ${doppler} run ${flags} "$@"
  '';

  filters = lib.escapeShellArgs (
    map builtins.toJSON [
      cfg.exportOnly
      cfg.exportExcept
    ]
  );
  wantExports = cfg.exportOnly == null || lib.subtractLists cfg.exportExcept cfg.exportOnly != [ ];
  hook = ''
    source ${./import-env.sh} \
      ${pkgs.python3}/bin/python3 -I ${./doppler-env.py} ${filters} \
      ${doppler} secrets download ${flags} --no-file --format json --attempts 1 --timeout 3s
  '';
in
{
  options.programs.doppler = {
    enable = lib.mkEnableOption "Doppler secrets";
    package = lib.mkPackageOption pkgs "doppler" { };
    enableBashIntegration = lib.mkEnableOption "importing Doppler secrets in interactive Bash";
    enableZshIntegration = lib.mkEnableOption "importing Doppler secrets in interactive Zsh";

    project = mkOption {
      type = types.nullOr types.nonEmptyStr;
      default = null;
      example = "workstation";
      description = "Doppler project, or null to use the CLI selection scoped to the home directory.";
    };
    config = mkOption {
      type = types.nullOr types.nonEmptyStr;
      default = null;
      example = "dev";
      description = "Doppler config, or null to use the CLI selection scoped to the home directory.";
    };
    exportOnly = mkOption {
      type = types.nullOr names;
      default = null;
      description = "Names to export into interactive shells. Null selects all valid names; an empty list exports none.";
    };
    exportExcept = mkOption {
      type = names;
      default = [ ];
      description = "Names never to import into interactive shells. Takes precedence over exportOnly.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package
      homeRun
    ];
    programs.bash.initExtra = lib.mkIf (wantExports && cfg.enableBashIntegration) hook;
    programs.zsh.initContent = lib.mkIf (wantExports && cfg.enableZshIntegration) hook;
  };
}
