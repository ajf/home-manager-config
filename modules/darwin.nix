{ config, lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.isDarwin {
  # Homebrew paths/completions (GUI apps and fonts stay in brew on macOS)
  xdg.configFile."fish/conf.d/homebrew.fish".source =
    ../config/fish/conf.d/homebrew.fish;
}
