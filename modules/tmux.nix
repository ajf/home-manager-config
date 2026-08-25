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
      # The server starts at boot as a user service, before any graphical or
      # SSH session exists. On attach, copy these from the attaching client
      # into the session environment (-a appends to tmux's defaults, which
      # already cover DISPLAY and the SSH_* variables) so new panes see the
      # live session's sockets.
      set -ga update-environment "WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE HYPRCURSOR_THEME HYPRCURSOR_SIZE XDG_CURRENT_DESKTOP XDG_SESSION_TYPE DBUS_SESSION_BUS_ADDRESS"

      set -g set-clipboard on
      set -as terminal-features ',*:clipboard'
      bind-key -T copy-mode-vi y send -X copy-pipe-and-cancel "${clip}"
      bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "${clip}"

      # Click a URL to open it in the browser. tmux owns the mouse (mouse on),
      # so foot never sees the click; instead grab the word under the pointer
      # (or the OSC-8 hyperlink target, if any) and hand it to xdg-open.
      # Whitespace-only word-separators keep URLs with ?&=; in one piece —
      # side effect: double-click selects whole whitespace-delimited chunks.
      set -g word-separators " \t"
      set -as terminal-features ',foot*:hyperlinks'
      bind-key -n MouseDown1Pane select-pane -t = \; run-shell -b 'u="#{mouse_hyperlink}"; [ -n "$u" ] || u="#{mouse_word}"; u=$(printf "%s" "$u" | sed "s/[),.;]*$//"); case "$u" in https://*|http://*) xdg-open "$u" >/dev/null 2>&1 ;; www.*) xdg-open "https://$u" >/dev/null 2>&1 ;; esac'
      bind-key -T copy-mode-vi MouseDown1Pane select-pane \; run-shell -b 'u="#{mouse_hyperlink}"; [ -n "$u" ] || u="#{mouse_word}"; u=$(printf "%s" "$u" | sed "s/[),.;]*$//"); case "$u" in https://*|http://*) xdg-open "$u" >/dev/null 2>&1 ;; www.*) xdg-open "https://$u" >/dev/null 2>&1 ;; esac'

      bind-key x kill-pane

      set -g default-terminal "''${TERM}"
      set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'  # undercurl support
      set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'  # underscore colours - needs tmux-3.0

      bind -T root F3 set prefix None \; set key-table off \; set status-left '#[bg=#C678DD,fg=#2C323C](pass-#S)' \; set status-style bg="#E06C75" \; set window-status-current-style bg=magenta,fg=black \; refresh-client -S;
      bind -T off F3 set -u prefix \; set -u key-table \; set -u status-left \; set -u status-style \; set -u window-status-current-style \; refresh-client -S;
    '';
  };

  # Run the tmux server as a user service so it survives session teardown.
  # A server started from a terminal inside the uwsm graphical session lives
  # in that session's cgroup and is killed when the session ends — linger
  # only protects user services, not session-scoped processes.
  systemd.user.services.tmux = lib.mkIf pkgs.stdenv.isLinux {
    Unit = {
      Description = "tmux server";
      # deliberately not tied to graphical-session.target
      # Never restart on home-manager switch — ExecStop kills the server and
      # every session in it. New unit versions take effect at next boot.
      X-RestartIfChanged = "false";
      X-StopIfChanged = "false";
    };
    Service = {
      Type = "forking";
      # hm-session-vars puts the socket under XDG_RUNTIME_DIR; the user
      # manager doesn't inherit that, so pin it here (%t = runtime dir) or
      # the service would run a second server on /tmp that clients never see.
      Environment = "TMUX_TMPDIR=%t";
      ExecStart = "${config.programs.tmux.package}/bin/tmux new-session -d -s main";
      ExecStop = "${config.programs.tmux.package}/bin/tmux kill-server";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
