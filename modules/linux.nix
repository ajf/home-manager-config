{ config, lib, pkgs, ... }:

let
  desktop = config.dotfiles.desktop.enable;

  # 2.18.0 fixes the WebAuthn "security window" for passkey/security-key
  # sign-in (upstream #802); drop this override once nixpkgs catches up.
  teams-for-linux' = pkgs.teams-for-linux.overrideAttrs (old: rec {
    version = "2.18.0";
    src = pkgs.fetchFromGitHub {
      owner = "IsmaelMartinez";
      repo = "teams-for-linux";
      tag = "v${version}";
      hash = "sha256-Rw/NYfpwNQENCEHUzKQZWrM+nxvC3rCCtXnBZmQjIz4=";
    };
    npmDeps = pkgs.fetchNpmDeps {
      inherit src;
      hash = "sha256-MhaUtGkIoutibiu8Flmr8QqqxSEbI8gUJE4WuX9/1Ho=";
    };
  });

  # nixpkgs wraps cider-2 with libglvnd only; without libpulse Chromium's
  # audio service silently falls back to its fake null backend (playback
  # "works" but no sound). Drop once nixpkgs adds libpulseaudio itself.
  cider-2' = pkgs.symlinkJoin {
    name = "cider-2-with-libpulse";
    paths = [ pkgs.cider-2 ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/cider-2 \
        --prefix LD_LIBRARY_PATH : ${pkgs.libpulseaudio}/lib
    '';
  };

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
      foot
      hypridle
      hyprlock
      hyprpaper
      hyprsunset
      dms-shell # DankMaterialShell (`dms` CLI + quickshell config)
      kdePackages.dolphin # GUI file manager
      cider-2' # Apple Music client; wrapped with libpulse (see above)
      kdePackages.kasts # podcast player
      obsidian
      slack
      teams-for-linux' # official Linux client is discontinued; Electron wrapper
      libfido2 # fido2-{token,cred,assert}: teams-for-linux shells out to these for WebAuthn

      # Fonts referenced by ghostty/foot/hyprlock (darwin gets these via brew)
      nerd-fonts.caskaydia-cove
      nerd-fonts.jetbrains-mono
      nerd-fonts.ubuntu-mono
      inter
    ] ++ dmsDeps;

    fonts.fontconfig.enable = true;

    xdg.configFile."foot/foot.ini".source = ../config/foot/foot.ini;

    # Security-key (WebAuthn) sign-in is opt-in; see the override comment above.
    xdg.configFile."teams-for-linux/config.json".text = builtins.toJSON {
      auth.webauthn.enabled = true;
    };

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
