{ config, lib, pkgs, ... }:

{
  # Headless machines get config only, no package. Darwin gets the upstream
  # binary build (pkgs.ghostty doesn't build from source on darwin).
  home.packages = lib.optionals config.dotfiles.desktop.enable
    (if pkgs.stdenv.isDarwin then [ pkgs.ghostty-bin ] else [ pkgs.ghostty ]);

  xdg.configFile."ghostty/config".source = ../config/ghostty/config;

  # The main config ends with `config-file = config.local` for per-OS bits.
  xdg.configFile."ghostty/config.local".source =
    if pkgs.stdenv.isDarwin
    then ../config/ghostty/config.local.darwin
    else ../config/ghostty/config.local.linux;

  # Out-of-store: DMS/matugen regenerates themes/dankcolors at runtime and
  # those writes should land in the git worktree.
  xdg.configFile."ghostty/themes".source =
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/config/ghostty/themes";
}
