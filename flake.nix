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

      # Machine ROLES, not machines: username, home directory, system, and
      # NixOS-vs-generic-Linux are all taken from the environment at switch
      # time, so every invocation needs --impure:
      #
      #   home-manager switch --flake ~/.config/home-manager#<role> --impure
      #
      # Per-role (or per-machine, by adding an entry) overrides:
      #   desktop       - false for headless machines (no Hyprland/DMS/GUI)
      #   system        - pin a nix system string (default: current system)
      #   username      - pin a login name       (default: $USER)
      #   homeDirectory - pin a home path        (default: $HOME)
      #   genericLinux  - pin non-NixOS Linux    (default: auto-detect)
      #   identity      - override dotfiles.identity (git name/email/key);
      #                   normally left to the untracked ~/.config/git/identity
      machines = {
        DMS-desktop = { platform = "linux"; }; # graphical Linux desktop: Hyprland + DMS
        macos = { platform = "darwin"; }; # darwin: CLI environment + app configs
        headless = { desktop = false; platform = "linux"; }; # servers, VMs, work boxes
      };

      mkHome =
        { desktop ? true
        , platform ? null
        , system ? null
        , username ? null
        , homeDirectory ? null
        , genericLinux ? null
        , identity ? { }
        }:
        let
          env = name:
            let v = builtins.getEnv name;
            in if v == "" then
              throw "env var ${name} is empty; run home-manager with --impure"
            else v;

          rawSys = if system != null then system else builtins.currentSystem;
          sys =
            if platform == null || lib.hasSuffix platform rawSys then rawSys
            else throw "this role is for ${platform}, but the system is ${rawSys}";
          isDarwin = lib.hasSuffix "darwin" sys;
          pkgs = (if isDarwin then nixpkgs-darwin else nixpkgs).legacyPackages.${sys};
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home.nix
            {
              home.username =
                if username != null then username else env "USER";
              home.homeDirectory =
                if homeDirectory != null then homeDirectory else env "HOME";
              targets.genericLinux.enable =
                if genericLinux != null then genericLinux
                else !isDarwin && !(builtins.pathExists /etc/NIXOS);
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
