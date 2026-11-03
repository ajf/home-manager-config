{ config, lib, pkgs, ... }:

# Cross-platform CLI tooling (mostly ported from the old .Brewfile).
let
  cfg = config.dotfiles.task;
in
{
  # Taskwarrior sync is a generic mechanism here; WHICH server and WHERE the
  # credentials live is site data, supplied by the identity flake (same spirit
  # as modules/step.nix). The secrets file itself is never managed by nix --
  # the store is world-readable -- so it is written out of band.
  options.dotfiles.task = {
    syncServerUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "https://task.example.com";
      description = ''
        taskchampion-sync-server URL. Harmless on its own: taskwarrior only
        contacts it on an explicit `task sync`.
      '';
    };
    syncSecretsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/home/you/.config/task/sync.secrets";
      description = ''
        Path to a file holding sync.server.client_id and
        sync.encryption_secret, pulled into taskrc with `include`.

        Set this ONLY on machines where that file already exists: taskwarrior
        treats an include of a missing file as fatal (every command exits 2),
        so a premature setting here bricks the CLI rather than degrading it.
      '';
    };
  };

  config = {
    home.packages = with pkgs; [
      ripgrep
      fd
      jq
      eza # exa successor; the fish `ls` wrappers use it
      mtr
      sipcalc
      lazygit
      kubectx
      # gh as a plain package, NOT programs.gh: the HM module makes config.yml
      # a read-only store link, which breaks `gh auth login`'s config writes.
      gh
      _1password-cli # `op`; the tmux 1password plugin and SSH/signing flows use it
      zoxide
      yazi # TUI file manager
      rustup
      taskwarrior3
      taskwarrior-tui
      tectonic
      mermaid-cli
      podman
      ipmitool
      htop

      # neomutt/senpai configs are per-machine (identity repo); packages only here
      neomutt
      w3m # HTML rendering for neomutt's mailcap
      senpai # IRC client
      # From the Brewfile, re-add if wanted:
      # vault ansible pssh
    ]
    # terminfo for the terminals we ssh in from (ssh sends TERM with the pty
    # request; headless boxes just need the entries to exist remotely).
    # linux-only: the packages don't evaluate on darwin, and the mac is the
    # machine we ssh FROM, not into.
    ++ lib.optionals pkgs.stdenv.isLinux [
      pkgs.foot.terminfo # TERM=foot / foot-direct
      pkgs.ghostty.terminfo # TERM=xterm-ghostty
    ];

    # -F: quit if output fits one screen; -X: don't clear screen on exit;
    # -R: pass through ANSI colors
    home.sessionVariables.LESS = "-FXR";

    # procps-ng (ps/top/pgrep): never show kernel threads. Also set system-wide
    # on the NixOS fleet; this follows the user to any other machine.
    home.sessionVariables.LIBPROC_HIDE_KERNEL = "1";

    programs.bat.enable = true;

    programs.fzf.enable = true; # `fzf --fish` integration handled by HM

    programs.zoxide = {
      enable = true;
      # take over `cd` (and add `cdi` for interactive fzf picking); plain
      # paths still work, plus fuzzy jumps to any previously visited dir
      options = [ "--cmd" "cd" ];
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    programs.starship = {
      enable = true;
      settings = builtins.fromTOML (builtins.readFile ../config/starship.toml);
    };

    # taskwarrior: HM's module wants to own the config; keep the raw taskrc.
    # Sync lines are appended from the identity flake's site data.
    xdg.configFile."task/taskrc".text =
      builtins.readFile ../config/task/taskrc
      + lib.optionalString (cfg.syncServerUrl != null) ''
        sync.server.url=${cfg.syncServerUrl}
      ''
      + lib.optionalString (cfg.syncSecretsFile != null) ''
        include ${cfg.syncSecretsFile}
      '';
  };
}
