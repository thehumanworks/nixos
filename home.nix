{ inputs, ... }:

{
  home.stateVersion = "26.05";

  imports = [
    # packages
    ./modules/packages.nix

    # agent modules
    ./modules/agents/pi-coding-agent.nix
    ./modules/agents/claude-code.nix
    ./modules/agents/mcp.nix

    # secret modules
    ./modules/secrets/fnox.nix

    # shell modules
    ./modules/shell.nix

    # tools modules
    ./modules/git.nix
    inputs.nixvim.homeModules.nixvim
    ./modules/tools/neovim.nix
  ];

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/rodat/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "neovim";
  };

  programs.home-manager.enable = true;
}
