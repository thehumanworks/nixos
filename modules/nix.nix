{
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    extra-substituters = [ "https://thehuman.cachix.org" ];
    extra-trusted-public-keys = [ "thehuman.cachix.org-1:5e++Y7TlcHLBOmHnqv1bmgUp0QuFJn+XCzN/V0Y5/6w=" ];
  };
}
