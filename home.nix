{ config, lib, pkgs, pkgsUnstable, ... }:

{
  imports = [
    ./modules/cli.nix
    ./modules/ssh.nix
    ./modules/step.nix
    ./modules/sops.nix
    ./modules/workspace.nix
    ./modules/fish.nix
    ./modules/git.nix
    ./modules/tmux.nix
    ./modules/neovim.nix
    ./modules/ghostty.nix
    ./modules/firefox.nix
    ./modules/obsidian.nix
    ./modules/claude.nix
    ./modules/wallpapers.nix
    ./modules/obsidian-sync.nix
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

    obsidianApp = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install the Obsidian desktop app, seed its vault registry and autostart
        it. Disable on a desktop that keeps its vault in sync with the headless
        client instead (dotfiles.obsidianSync) and has no use for the editor.
        Never run both against one vault.
      '';
    };

    signal = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install Signal Desktop and autostart it into the tray at login.
        Disable on machines where a personal messenger does not belong, such as
        a work laptop.
      '';
    };

    tailscaleTray = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install the Tailscale tray client (tail-tray) and autostart it with
        the session. Disable on machines that run no tailscaled — the tray
        has nothing to talk to there.
      '';
    };

    identity = {
      name = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Git author name. Left null, identity comes from the untracked
          per-machine file ~/.config/git/identity instead.
        '';
      };
      email = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Git author email; null defers to ~/.config/git/identity.";
      };
      signingKey = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          SSH signing key for git; null defers signing configuration to
          ~/.config/git/identity.
        '';
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
      # 26.05 is stuck on 2.1.223; take the current release from unstable,
      # same as dms-shell in modules/linux.nix.
      package = pkgsUnstable.claude-code;
      settings = { };
      mcpServers = { };
    };

    # OpenAI's terminal agent, the counterpart to claude-code above. From
    # unstable for the same reason (26.05 has 0.146; unstable moves weekly), and
    # so the desktop app in modules/linux.nix, which nixpkgs wires to the codex
    # it is built against, runs the same CLI. `settings` is left empty on
    # purpose: home-manager then writes no config.toml, and Codex keeps its own
    # (it records trusted projects and model choices there at runtime, which a
    # read-only store symlink would break).
    programs.codex = {
      enable = true;
      package = pkgsUnstable.codex;
    };
  };
}
