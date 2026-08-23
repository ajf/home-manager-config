{
  description = "ajf's home-manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      # One entry per machine/user. homeDirectory is derived from the platform
      # unless overridden; genericLinux is for non-NixOS Linux (e.g. Arch).
      machines = {
        "andrew@intrepid" = {
          system = "x86_64-linux";
          username = "andrew";
        };
        "andrew@mac" = {
          system = "aarch64-darwin";
          username = "andrew";
        };
        "andrew@arch" = {
          system = "x86_64-linux";
          username = "andrew";
          genericLinux = true;
        };
      };

      mkHome =
        { system
        , username
        , homeDirectory ? null
        , genericLinux ? false
        }:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home.nix
            {
              home.username = username;
              home.homeDirectory =
                if homeDirectory != null then homeDirectory
                else if pkgs.stdenv.isDarwin then "/Users/${username}"
                else "/home/${username}";
              targets.genericLinux.enable = genericLinux;
            }
          ];
        };
    in
    {
      homeConfigurations = builtins.mapAttrs (_: mkHome) machines;
    };
}
