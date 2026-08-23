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
      lib = nixpkgs.lib;

      # Machine roles: defaults a per-machine flake picks from.
      roles = {
        DMS-desktop = { platform = "linux"; }; # graphical Linux desktop: Hyprland + DMS
        macos = { platform = "darwin"; }; # darwin: CLI environment + app configs
        headless = { desktop = false; platform = "linux"; }; # servers, VMs, work boxes
      };

      # Pure constructor for a home configuration. Personal data (username,
      # home directory, identity) is supplied by an UNTRACKED per-machine
      # flake that has this flake as an input and calls:
      #
      #   dotfiles.lib.mkHome {
      #     role = "DMS-desktop";
      #     system = "x86_64-linux";
      #     username = "you";
      #   }
      #
      # See templates/local (nix flake new -t <this-flake> <dir>).
      mkHome =
        { system
        , username
        , role ? null
        , homeDirectory ? null
        , desktop ? null
        , genericLinux ? false # set true on non-NixOS Linux (e.g. Arch)
        , identity ? { }
        , workspace ? { } # dotfiles.workspace: git-workspace providers/tokenRef
        }:
        let
          roleCfg = if role != null then roles.${role} else { };
          platform = roleCfg.platform or null;
          sys =
            if platform == null || lib.hasSuffix platform system then system
            else throw "role ${toString role} is for ${platform}, but the system is ${system}";
          isDarwin = lib.hasSuffix "darwin" sys;
          pkgs = (if isDarwin then nixpkgs-darwin else nixpkgs).legacyPackages.${sys};
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
              dotfiles.desktop.enable =
                if desktop != null then desktop
                else roleCfg.desktop or true;
              dotfiles.identity = identity;
              dotfiles.workspace = workspace;
            }
          ];
        };
    in
    {
      lib = { inherit mkHome roles; };

      templates.default = {
        path = ./templates/local;
        description = "Per-machine identity flake wrapping this configuration";
      };
    };
}
