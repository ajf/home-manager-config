{
  description = "ajf's home-manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # Darwin gets its own branch: same release, better binary-cache coverage.
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-darwin, home-manager, ... }:
    let
      # One entry per machine/user.
      #   system        - nix system string
      #   username      - login name on that machine
      #   homeDirectory - override when it isn't /home/<user> or /Users/<user>
      #   desktop       - false for headless machines (no Hyprland/DMS/GUI)
      #   genericLinux  - true on non-NixOS Linux (e.g. Arch)
      #   identity      - override dotfiles.identity (git name/email/key)
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
        "andrew@headless" = {
          system = "x86_64-linux";
          username = "andrew";
          desktop = false;
          genericLinux = true;
        };
      };

      mkHome =
        { system
        , username
        , homeDirectory ? null
        , desktop ? true
        , genericLinux ? false
        , identity ? { }
        }:
        let
          isDarwin = nixpkgs.lib.hasSuffix "darwin" system;
          pkgs = (if isDarwin then nixpkgs-darwin else nixpkgs).legacyPackages.${system};
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home.nix
            {
              home.username = username;
              home.homeDirectory =
                if homeDirectory != null then homeDirectory
                else if isDarwin then "/Users/${username}"
                else "/home/${username}";
              targets.genericLinux.enable = genericLinux;
              dotfiles.desktop.enable = desktop;
              dotfiles.identity = identity;
            }
          ];
        };
    in
    {
      homeConfigurations = builtins.mapAttrs (_: mkHome) machines;
    };
}
