{ config, lib, pkgs, ... }:

# Cross-platform CLI tooling (mostly ported from the old .Brewfile).
let
  cfg = config.dotfiles.task;

  # Shipped as a store file rather than a heredoc so the activation script
  # stays trivial. Content is non-secret by construction: it is the
  # instructions for filling the real values in, never the values.
  syncSecretsStub = pkgs.writeText "task-sync-secrets-stub" ''
    # Taskwarrior sync credentials -- fill these in BY HAND.
    # Deliberately not managed by nix: the store is world-readable.
    #
    # Both values come from a single 1Password API Credential item, and must be
    # reused VERBATIM on every machine: a different client_id is a separate,
    # invisible database, and the encryption secret cannot be rotated -- a new
    # one orphans all synced history.
    #
    #   sync.server.client_id=<the item's username field>
    #   sync.encryption_secret=<the item's credential field>
  '';
in
{
  # Taskwarrior sync is a generic mechanism here; WHICH server to talk to is
  # site data, supplied by the identity flake (same spirit as modules/step.nix).
  # The credentials are never managed by nix -- the store is world-readable --
  # so they are filled in by hand; nix only guarantees the FILE exists, because
  # taskwarrior treats an `include` of a missing file as fatal (every command
  # exits 2, not just `task sync`). With the stub in place a machine that has
  # not been given credentials yet degrades to just `task sync` failing.
  options.dotfiles.task = {
    syncServerUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "https://task.example.com";
      description = ''
        taskchampion-sync-server URL. Enables the sync lines in taskrc and the
        credentials stub. Inert until credentials are filled in: taskwarrior
        only contacts the server on an explicit `task sync`.
      '';
    };
    syncSecretsFile = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.configHome}/task/sync.secrets";
      description = ''
        File holding sync.server.client_id and sync.encryption_secret, pulled
        into taskrc with `include`. Created as a commented 0600 stub at
        activation if absent, and never overwritten once it has content.
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
      # sops/age toolchain lives in modules/sops.nix, with the user identity
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
        include ${cfg.syncSecretsFile}
      '';

    # The include above is only safe because this guarantees the file exists.
    # Create-if-absent ONLY: the credentials are unrotatable (a wrong
    # sync.encryption_secret orphans the synced history), so this must never
    # touch a file that already has content. install -m 600 copies the stub
    # straight to its final mode, with no world-readable window.
    home.activation.taskSyncSecretsStub =
      lib.mkIf (cfg.syncServerUrl != null)
        (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          if [ ! -e "${cfg.syncSecretsFile}" ]; then
            run mkdir -p "$(dirname "${cfg.syncSecretsFile}")"
            run install -m 600 ${syncSecretsStub} "${cfg.syncSecretsFile}"
            warnEcho "taskwarrior: wrote a credentials stub at ${cfg.syncSecretsFile}; 'task sync' fails until it is filled in by hand"
          fi
        '');
  };
}
