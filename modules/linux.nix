{ config, lib, pkgs, ... }:

let
  desktop = config.dotfiles.desktop.enable;

  # Tools DMS shells out to (quickshell as `qs`, plus theming/screenshot/etc.)
  dmsDeps = with pkgs; [
    quickshell
    matugen
    dgop
    grim
    slurp
    brightnessctl
    cliphist
    wl-clipboard
  ];
in
lib.mkMerge [

  # All Linux machines, headless included
  (lib.mkIf pkgs.stdenv.isLinux {
    # ssh-agent on a fixed socket; fish's ssh-auth-sock.fish expects this path.
    systemd.user.services.ssh-agent = {
      Unit.Description = "SSH key agent";
      Service = {
        Type = "simple";
        Environment = "SSH_AUTH_SOCK=%t/ssh-agent.socket";
        ExecStart = "${pkgs.openssh}/bin/ssh-agent -D -a $SSH_AUTH_SOCK";
      };
      Install.WantedBy = [ "default.target" ];
    };

    xdg.configFile."fish/conf.d/ssh-auth-sock.fish".source =
      ../config/fish/conf.d/ssh-auth-sock.fish;
  })

  # Graphical desktops only (Hyprland + DMS)
  (lib.mkIf (pkgs.stdenv.isLinux && desktop) {
    home.packages = with pkgs; [
      firefox
      foot
      hypridle
      hyprlock
      hyprpaper
      hyprsunset
      dms-shell # DankMaterialShell (`dms` CLI + quickshell config)

      # Fonts referenced by ghostty/foot/hyprlock (darwin gets these via brew)
      nerd-fonts.caskaydia-cove
      nerd-fonts.jetbrains-mono
      nerd-fonts.ubuntu-mono
      inter
    ] ++ dmsDeps;

    fonts.fontconfig.enable = true;

    xdg.configFile."foot/foot.ini".source = ../config/foot/foot.ini;

    # A real cursor theme; without one Wayland apps fall back to the legacy
    # X11 cursor. DMS's cursor setting is left at "System Default".
    home.pointerCursor = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
      size = 24;
      gtk.enable = true;
    };

    # Whole ~/.config/hypr is an out-of-store symlink into this repo: DMS
    # rewrites config/hypr/dms/* at runtime and hyprland.lua edits apply
    # without a switch. Uses the Lua config (hyprland.lua), not hyprland.conf.
    # dms/outputs.* is machine-local (gitignored) — see hyprland.lua's pcall.
    xdg.configFile."hypr".source =
      config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/config/hypr";

    # Machine-local DMS state (settings.json is gitignored; DMS rewrites it
    # with absolute paths).
    xdg.configFile."DankMaterialShell".source =
      config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/config/DankMaterialShell";

    # Polkit auth agent (replaces the old mate-polkit exec-once)
    services.hyprpolkitagent.enable = true;

    # DMS bar/shell, bound to the graphical session (mirrors the unit shipped
    # in the dms-shell package).
    systemd.user.services.dms = {
      Unit = {
        Description = "Dank Material Shell (DMS)";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        Requisite = [ "graphical-session.target" ];
      };
      Service = {
        Type = "dbus";
        BusName = "org.freedesktop.Notifications";
        Environment = "PATH=${lib.makeBinPath dmsDeps}:/run/current-system/sw/bin:%h/.nix-profile/bin";
        ExecStart = "${pkgs.dms-shell}/bin/dms run --session";
        ExecReload = "${pkgs.procps}/bin/pkill -USR1 -x dms";
        Restart = "on-failure";
        RestartSec = "1";
        TimeoutStopSec = "10";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    xdg.dataFile."applications/factorio.desktop".text = ''
      [Desktop Entry]
      Version=1.0
      Type=Application
      Name=Factorio
      Comment=Factorio
      Icon=${config.home.homeDirectory}/games/factorio/data/base/thumbnail.png
      Exec=${config.home.homeDirectory}/games/factorio/bin/x64/factorio
      Categories=Game;
    '';
  })
]
