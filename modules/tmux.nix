{ config, lib, pkgs, ... }:

let
  clip = if pkgs.stdenv.isDarwin then "pbcopy" else "wl-copy";

  tmux-1password = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-1password";
    version = "unstable-2024";
    src = pkgs.fetchFromGitHub {
      owner = "yardnsm";
      repo = "tmux-1password";
      rev = "fee36493fe352e34f46f2e293a218a6667607b00";
      hash = "sha256-0ezD7TSNCFL+spPhbTHlITeyNOw/lyzZD6cdiT5NU/0=";
    };
  };

  tmux-cargo = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-cargo";
    version = "unstable-2024";
    src = pkgs.fetchFromGitHub {
      owner = "naqerl"; # formerly idevtier/tmux-cargo
      repo = "tmux-cargo";
      rev = "fadf001897868e924ea93593a47b9b66a60d1598";
      hash = "sha256-lxtU7aGtKa//+PyJVDqSTK2IFX2bhYp2z+zKEG5Pn+g=";
    };
  };
in
{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    mouse = true;
    # sensibleOnTop (default true) replaces the old tmux-sensible TPM plugin

    plugins = [
      {
        plugin = pkgs.tmuxPlugins.tokyo-night-tmux;
        extraConfig = "set -g @tokyo-night-tmux_theme night";
      }
      tmux-cargo
      tmux-1password
      {
        plugin = pkgs.tmuxPlugins.fzf-tmux-url;
        extraConfig = ''
          set -g @fzf-url-fzf-options '-w 50% -h 50% --multi -0 --no-preview --no-border'
        '';
      }
      {
        plugin = pkgs.tmuxPlugins.t-smart-tmux-session-manager;
        extraConfig = ''
          set -g @t-bind "t"
          set -g @t-fzf-default-results 'sessions'
        '';
      }
    ];

    extraConfig = ''
      set -g update-environment -r

      set -g set-clipboard on
      set -as terminal-features ',*:clipboard'
      bind-key -T copy-mode-vi y send -X copy-pipe-and-cancel "${clip}"
      bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "${clip}"

      set-option -g update-environment "SSH_AUTH_SOCK SSH_AGENT_PID SSH_CONNECTION DISPLAY"

      bind-key x kill-pane

      set -g default-terminal "''${TERM}"
      set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'  # undercurl support
      set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'  # underscore colours - needs tmux-3.0

      bind -T root F3 set prefix None \; set key-table off \; set status-left '#[bg=#C678DD,fg=#2C323C](pass-#S)' \; set status-style bg="#E06C75" \; set window-status-current-style bg=magenta,fg=black \; refresh-client -S;
      bind -T off F3 set -u prefix \; set -u key-table \; set -u status-left \; set -u status-style \; set -u window-status-current-style \; refresh-client -S;
    '';
  };
}
