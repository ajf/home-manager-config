{ config, lib, pkgs, ... }:

{
  imports = [
    ./modules/cli.nix
    ./modules/fish.nix
    ./modules/git.nix
    ./modules/tmux.nix
    ./modules/neovim.nix
    ./modules/ghostty.nix
    ./modules/linux.nix
    ./modules/darwin.nix
  ];

  options.dotfiles = {
    path = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.config/home-manager";
      description = ''
        Absolute path to the checkout of this repository. Used for
        mkOutOfStoreSymlink targets (configs that tools rewrite at runtime,
        e.g. DMS-generated files) so those writes land in the git worktree.
      '';
    };

    desktop.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether this machine is a graphical desktop. Disable for headless
        machines to skip Hyprland/DMS/GUI packages, fonts, and desktop
        systemd units.
      '';
    };

    identity = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Andrew Forgue";
        description = "Git author name.";
      };
      email = lib.mkOption {
        type = lib.types.str;
        default = "andrew@forgue.io";
        description = "Git author email.";
      };
      signingKey = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "key::ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO9mWl3pPCPvpbbLZoseNee32Cst2FbV22zJqARVTydn";
        description = "SSH signing key for git; null disables signing.";
      };
    };
  };

  config = {
    # home.username / home.homeDirectory are set per-machine in flake.nix.
    home.stateVersion = "25.11"; # do not change casually; see HM release notes

    nixpkgs.config.allowUnfree = true;

    # Flakes for standalone `home-manager switch --flake` everywhere.
    xdg.configFile."nix/nix.conf".text = ''
      experimental-features = nix-command flakes
    '';

    programs.home-manager.enable = true;

    programs.claude-code = {
      enable = true;
      settings = { };
      mcpServers = { };
    };
  };
}
