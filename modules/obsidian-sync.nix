{ config, lib, pkgs, ... }:

# Continuous Obsidian Sync via the headless Go client (`ob`), as a user unit.
#
# This is deliberately independent of modules/obsidian.nix: that installs the
# desktop app for desktops, whereas headless nodes need sync with no GUI at
# all. Pioneer has run exactly this arrangement by hand since 2026-09-18; it
# is packaged here so it survives a reinstall and so new nodes get it the same
# way every time.
#
# Why continuous rather than a timer: the shared claude-memory tree is
# writable from any node whose sync runs continuously, which is what keeps the
# conflict window down to seconds. A node that only syncs occasionally must
# NOT have its memory dirs symlinked into the vault -- get this running first,
# then symlink.
#
# Do not enable this on a machine where the Obsidian desktop app is also
# connected to Sync; run one or the other. Using the desktop app purely as an
# editor, with its own sync disconnected, is fine and is how the desktops run.
let
  cfg = config.dotfiles.obsidianSync;
in
{
  options.dotfiles.obsidianSync = {
    enable = lib.mkEnableOption "continuous Obsidian Sync via the headless client";

    vaultPath = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/notes/personal";
      description = "Local vault directory to keep in sync.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../pkgs/obsidian-headless.nix { };
      defaultText = lib.literalExpression "pkgs.callPackage ../pkgs/obsidian-headless.nix { }";
      description = "Package providing the `ob` binary.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # Not bound to graphical-session: headless nodes have none, and the point
    # is for sync to run whether or not anyone is logged in (pioneer relies on
    # lingering for exactly this).
    systemd.user.services.obsidian-sync = {
      Unit = {
        Description = "Obsidian Sync (headless)";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        ExecStart = "${cfg.package}/bin/ob sync --continuous --path ${cfg.vaultPath}";
        Restart = "always";
        RestartSec = 30;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
