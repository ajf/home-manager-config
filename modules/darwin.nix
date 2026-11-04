{ config, lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.isDarwin {
  # Homebrew is retired on macOS: GUI apps and fonts come from nix too.
  # home-manager links .app bundles into ~/Applications/Home Manager Apps
  # and fonts into ~/Library/Fonts.
  home.packages = with pkgs; [
    mas # App Store CLI (Safari extensions, iWork, ...)
    # macOS ships bash 3.2; anything `#!/usr/bin/env bash` with modern
    # bashisms (tokyo-night-tmux's associative arrays, for one) needs this.
    # Linux systems already have a current bash.
    bash
  ]
  # the whole nerd-fonts family (what the old Brewfile's font casks were)
  ++ lib.filter lib.isDerivation (lib.attrValues pkgs.nerd-fonts);

  # Transitional: keep brew's paths/completions wired while it's still
  # installed; the file no-ops once brew is gone.
  xdg.configFile."fish/conf.d/homebrew.fish".source =
    ../config/fish/conf.d/homebrew.fish;

  # Spotlight is lazy about indexing the copied .app bundles — nudge it
  # after every generation so Cmd+Space finds nix-installed apps
  # (Obsidian et al) without waiting for a re-login.
  home.activation.spotlightIndexApps = lib.hm.dag.entryAfter [ "copyApps" ] ''
    if [ -d "$HOME/Applications/Home Manager Apps" ]; then
      run /usr/bin/mdimport "$HOME/Applications/Home Manager Apps" 2>/dev/null || true
    fi
  '';

  # Darwin twin of config/fish/conf.d/ssh-auth-sock.fish: a forwarded
  # agent wins, otherwise 1Password — it holds the regular keys (GitHub,
  # signing); ssh_config's `IdentityAgent SSH_AUTH_SOCK` for Host * follows
  # this variable. The launchd cert agent is only a fallback: cert hosts
  # pin its socket by path and `step-ssh-login` sets the variable itself,
  # so nothing needs it to be the shell default — making it the default
  # handed GitHub an agent with no keys (hm-pull fell back to a stale
  # cached flake every time).
  xdg.configFile."fish/conf.d/ssh-auth-sock.fish".text = ''
    if set -q SSH_CONNECTION; and test -S "$SSH_AUTH_SOCK"
      # forwarded agent — leave it
    else if test -S "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
      set -gx SSH_AUTH_SOCK "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    else if test -S "${config.dotfiles.ssh.certAgentSocket}"
      set -gx SSH_AUTH_SOCK "${config.dotfiles.ssh.certAgentSocket}"
    end
  '';

  # `op` decides whether desktop-app integration is on by READING the app's
  # settings.json inside ~/Library/Group Containers/2BUA8C4S2C.com.1password,
  # which macOS gates behind Full Disk Access for the responsible app (the
  # terminal). Without it op reports "No accounts configured" even with the
  # integration checkbox ticked -- it never asks the app. Setting this skips
  # that file check and goes straight to the native-messaging channel, which
  # is NOT gated, so op works without granting the terminal FDA.
  home.sessionVariables.OP_BIOMETRIC_UNLOCK_ENABLED = "true";

  # Cert-holding ssh-agent on a stable socket — darwin twin of linux.nix's
  # systemd unit (launchd's own agent has an unpredictable socket path, and
  # 1Password's agent can't store certificates). The socket file survives
  # reboots under ~/.ssh, so clear it before binding.
  launchd.agents.ssh-agent = lib.mkIf config.dotfiles.desktop.enable {
    enable = true;
    config = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "rm -f ${config.dotfiles.ssh.certAgentSocket}; exec ${pkgs.openssh}/bin/ssh-agent -D -a ${config.dotfiles.ssh.certAgentSocket}"
      ];
      KeepAlive = true;
      RunAtLoad = true;
    };
  };
}
