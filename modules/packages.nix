{ pkgs, lib, config, ... }:

let
  hms = pkgs.writeShellApplication {
    name = "hms";
    runtimeInputs = [
      pkgs.cachix
      pkgs.home-manager
    ];
    text = ''
      exec cachix watch-exec thehuman -- \
        ${pkgs.coreutils}/bin/env -u CACHIX_AUTH_TOKEN home-manager switch \
          --flake ${lib.escapeShellArg "${config.xdg.configHome}/home-manager"} \
          -b backup
    '';
  };
in
{
  home.packages = [
    # home-manager management
    hms

    # cache management
    pkgs.cachix

    # language runtimes
    pkgs.nodejs_24

    # code quality tools
    ## nix
    pkgs.nixfmt
    pkgs.nixfmt-tree
    pkgs.nixd
    pkgs.nil
  ];
}
