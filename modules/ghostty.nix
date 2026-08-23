{ config, lib, pkgs, ... }:

{
  # On darwin ghostty is installed as an app (brew cask); nix only manages
  # the config there.
  home.packages = lib.optionals pkgs.stdenv.isLinux [ pkgs.ghostty ];

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
