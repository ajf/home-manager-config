{ config, lib, pkgs, ... }:

let
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
lib.mkIf pkgs.stdenv.isLinux {
  home.packages = with pkgs; [
    firefox
    foot
    hypridle
    hyprlock
    hyprpaper
    hyprsunset
    dms-shell # DankMaterialShell (`dms` CLI + quickshell config)

    # Fonts referenced by ghostty/hyprlock (darwin gets these via brew casks)
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
  # rewrites config/hypr/dms/*.lua at runtime and hyprland.lua edits apply
  # without a switch. Uses the Lua config (hyprland.lua), not hyprland.conf.
  xdg.configFile."hypr".source =
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/config/hypr";

  # Same deal: DMS rewrites settings.json in place.
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
}
