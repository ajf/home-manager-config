{ config, lib, ... }:

# Wallpapers deployed into ~/.local/share/backgrounds.
#
# Mechanism only: the images themselves are site data and live in the identity
# flake, not here -- this repo is public and forkable, and nobody's fork wants
# someone else's photographs in its git history. Same split as claude.nix and
# step.nix.
#
# Note nothing in this repo *reads* these; DMS owns wallpaper selection and
# stores it in its own machine-local settings.json. Deploying them just means
# a fresh machine has the files to choose from, rather than a config pointing
# at paths that do not exist -- which is exactly how galaxy ended up
# referencing antarctica-panorama.jpg with no such file on disk.
let
  cfg = config.dotfiles;
in
{
  options.dotfiles.wallpapers = lib.mkOption {
    type = lib.types.attrsOf lib.types.path;
    default = { };
    example = lib.literalExpression ''
      {
        "beach.jpg" = ./wallpapers/beach.jpg;
      }
    '';
    description = ''
      Images to place in ~/.local/share/backgrounds, keyed by the filename to
      write. Empty (the default) deploys nothing, which is correct for a fork
      and for headless hosts.
    '';
  };

  config.home.file = lib.mapAttrs'
    (name: src: lib.nameValuePair ".local/share/backgrounds/${name}" { source = src; })
    cfg.wallpapers;
}
