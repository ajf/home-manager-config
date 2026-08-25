{ config, lib, pkgs, ... }:

# Cross-platform CLI tooling (mostly ported from the old .Brewfile).
{
  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    eza # exa successor; the fish `ls` wrappers use it
    mtr
    sipcalc
    lazygit
    kubectx
    # gh as a plain package, NOT programs.gh: the HM module makes config.yml
    # a read-only store link, which breaks `gh auth login`'s config writes.
    gh
    zoxide
    rustup
    taskwarrior3
    taskwarrior-tui
    tectonic
    mermaid-cli
    podman
    # neomutt config is per-machine (home-manager-local); only the package here
    neomutt
    # From the Brewfile, re-add if wanted:
    # vault ansible pssh
  ];

  # -F: quit if output fits one screen; -X: don't clear screen on exit;
  # -R: pass through ANSI colors
  home.sessionVariables.LESS = "-FXR";

  programs.bat.enable = true;

  programs.fzf.enable = true; # `fzf --fish` integration handled by HM

  programs.zoxide.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.starship = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ../config/starship.toml);
  };

  # taskwarrior: HM's module wants to own the config; keep the raw taskrc.
  xdg.configFile."task/taskrc".source = ../config/task/taskrc;
}
