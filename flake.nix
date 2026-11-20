{
  description = "Home Manager configuration of rodat";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  inputs.nixos-wsl.url = "github:nix-community/NixOS-WSL";
  inputs.nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nix-darwin.url = "github:nix-darwin/nix-darwin";
  inputs.nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nixvim.url = "github:nix-community/nixvim";
  inputs.nixvim.inputs.nixpkgs.follows = "nixpkgs";

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      nixos-wsl,
      nix-darwin,
      ...
    }:
    let
      username = "rodat";
      sharedHome = {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit inputs; };
        home-manager.users.${username} = import ./home.nix;
      };

      mkLinux = hostModules: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit username; };
        modules = [
          ./modules/nix.nix
          ./modules/nixos-user.nix
          home-manager.nixosModules.home-manager
          sharedHome
        ] ++ hostModules;
      };
    in {
      apps = nixpkgs.lib.genAttrs
        [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ]
        (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
            isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

            # Keep macOS bootstrap working even before darwin-rebuild
            # is installed in the system profile.
            rebuild =
              if isDarwin then
                "sudo nix run 'path:${nix-darwin.outPath}#darwin-rebuild' -- switch"
              else
                "sudo nixos-rebuild switch";

            apply = pkgs.writeShellApplication {
              name = "apply";
              text = ''
                case "''${1:-}" in
                  ${if isDarwin then "mac" else "wsl|linux"}) host="$1" ;;
                  *) echo "Usage: apply ${if isDarwin then "mac" else "{wsl|linux}"}" >&2; exit 2 ;;
                esac

                ${rebuild} --flake "path:${self.outPath}#$host"

                closure=$(${pkgs.coreutils}/bin/readlink -f /run/current-system)
                echo "Activated $host. Pushing the closure as the invoking user."
                # The calling shell may predate activation of the new fnox config.
                config_file="''${XDG_CONFIG_HOME:-$HOME/.config}/fnox/config.toml"
                CACHIX_AUTH_TOKEN=$(${pkgs.fnox}/bin/fnox -c "$config_file" get CACHIX_AUTH_TOKEN)
                export CACHIX_AUTH_TOKEN
                exec ${pkgs.cachix}/bin/cachix push thehuman "$closure"
              '';
            };
          in {
            apply = {
              type = "app";
              program = "${apply}/bin/apply";
            };
          });
      nixosConfigurations = {
        wsl = mkLinux [
          nixos-wsl.nixosModules.default
          ./hosts/wsl/configuration.nix
        ];
        linux = mkLinux [
          ./hosts/linux/configuration.nix
        ];
      };

      darwinConfigurations.mac = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit username; };
        modules = [
          ./modules/nix.nix
          ./hosts/mac/configuration.nix
          home-manager.darwinModules.home-manager
          sharedHome
        ];
      };
    };
}
