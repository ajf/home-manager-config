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

  # 1Password holds the SSH keys (darwin equivalent of the Linux desktop's
  # ssh-auth-sock.fish).
  xdg.configFile."fish/conf.d/1password-agent.fish".source =
    ../config/fish/conf.d/1password-agent.fish;

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
