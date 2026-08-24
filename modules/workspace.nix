{ config, lib, pkgs, ... }:

let
  cfg = config.dotfiles.workspace;
  tomlFormat = pkgs.formats.toml { };
in
{
  options.dotfiles.workspace = {
    root = lib.mkOption {
      type = lib.types.str;
      default = "workspace";
      description = "git-workspace root, relative to the home directory.";
    };

    providers = lib.mkOption {
      type = lib.types.listOf (lib.types.attrsOf (lib.types.oneOf [
        lib.types.str
        lib.types.bool
        lib.types.int
        (lib.types.listOf lib.types.str)
      ]));
      default = [ ];
      example = [{ provider = "github"; name = "you"; }];
      description = ''
        Provider entries for workspace.toml. Personal (account names), so
        normally supplied by the per-machine flake via mkHome.
      '';
    };

    tokenCommand = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "gh auth token";
      example = "op read 'op://Private/GitHub Personal Access Token/password'";
      description = ''
        Command whose output is exported as GITHUB_TOKEN for each
        git-workspace invocation (via a fish wrapper), so the token never
        lands on disk or in the session environment. Defaults to the gh
        CLI's stored OAuth token; null disables the wrapper.
      '';
    };
  };

  config = {
    home.packages = [ pkgs.git-workspace ];

    home.sessionVariables.GIT_WORKSPACE =
      "${config.home.homeDirectory}/${cfg.root}";

    home.file."${cfg.root}/workspace.toml" =
      lib.mkIf (cfg.providers != [ ]) {
        source = tomlFormat.generate "workspace.toml" {
          # `path` (clone subdirectory) is required by git-workspace;
          # default it to the provider type, e.g. github → ~/workspace/github/…
          provider = map (p: { path = p.provider; } // p) cfg.providers;
        };
      };

    programs.fish.functions.git-workspace =
      lib.mkIf (cfg.tokenCommand != null) ''
        set -q GIT_WORKSPACE; or set -lx GIT_WORKSPACE "${config.home.homeDirectory}/${cfg.root}"
        GITHUB_TOKEN=(${cfg.tokenCommand}) command git-workspace $argv
      '';
  };
}
