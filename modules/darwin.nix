{ config, lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.isDarwin {
  # Homebrew is retired on macOS: GUI apps and fonts come from nix too.
  # home-manager links .app bundles into ~/Applications/Home Manager Apps
  # and fonts into ~/Library/Fonts.
  home.packages = with pkgs; [
    mas # App Store CLI (Safari extensions, iWork, ...)
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
}
