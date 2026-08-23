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

    tokenRef = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "op://Personal/GitHub Personal Access Token/token";
      description = ''
        1Password secret reference for the forge token. When set, a fish
        wrapper fetches it with `op read` per invocation and exports it as
        GITHUB_TOKEN, so the token never lands on disk or in the session
        environment.
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
          provider = cfg.providers;
        };
      };

    programs.fish.functions.git-workspace =
      lib.mkIf (cfg.tokenRef != null) ''
        GITHUB_TOKEN=(op read "${cfg.tokenRef}") command git-workspace $argv
      '';
  };
}
