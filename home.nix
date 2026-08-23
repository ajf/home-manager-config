{ config, lib, pkgs, ... }:

{
  imports = [
    ./modules/cli.nix
    ./modules/fish.nix
    ./modules/git.nix
    ./modules/tmux.nix
    ./modules/neovim.nix
    ./modules/ghostty.nix
    ./modules/linux.nix
    ./modules/darwin.nix
  ];

  options.dotfiles.path = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/.config/home-manager";
    description = ''
      Absolute path to the checkout of this repository. Used for
      mkOutOfStoreSymlink targets (configs that tools rewrite at runtime,
      e.g. DMS-generated files) so those writes land in the git worktree.
    '';
  };

  config = {
    # home.username / home.homeDirectory are set per-machine in flake.nix.
    home.stateVersion = "25.11"; # do not change casually; see HM release notes

    nixpkgs.config.allowUnfree = true;

    # Flakes for standalone `home-manager switch --flake` everywhere.
    xdg.configFile."nix/nix.conf".text = ''
      experimental-features = nix-command flakes
    '';

    programs.home-manager.enable = true;

    programs.claude-code = {
      enable = true;
      settings = { };
      mcpServers = { };
    };
  };
}
