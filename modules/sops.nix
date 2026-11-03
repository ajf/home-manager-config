{ config, lib, pkgs, ... }:

# sops/age toolchain, and where this user's age identity lives.
#
# TWO key roles in this fleet, split by layer — and the asymmetry is deliberate:
#
#   system (NixOS repos)  each machine is a recipient via its OWN
#                         /etc/ssh/ssh_host_ed25519_key, converted with
#                         ssh-to-age. root decrypts at boot with nobody
#                         present, so it must not depend on a human's key.
#                         Set via sops.age.sshKeyPaths over there, not here.
#
#   user (home-manager)   ONE recipient: the authoring key. Per-machine user
#                         keys were tried and dropped (2026-11-03) — on a
#                         machine holding the authoring key they decrypt
#                         nothing extra, since it is a recipient of
#                         everything, and both want the same path. The
#                         private half is placed BY HAND on the machines that
#                         need it.
#
# So nix never generates, stores or manages a decryption identity here: it only
# says where one belongs, and tells you what it finds. The store is
# world-readable, so a private key must never be a nix string.
let
  cfg = config.dotfiles.sops;
in
{
  options.dotfiles.sops = {
    identityFile = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.configHome}/sops/age/keys.txt";
      description = ''
        Where this user's age identity lives, pinned into SOPS_AGE_KEY_FILE.

        Needed because sops otherwise resolves its key through Go's
        UserConfigDir, which on darwin is ~/Library/Application Support rather
        than ~/.config — a key at the XDG path is then silently not found and
        every decrypt fails with "none were successful", which looks exactly
        like a bad key.
      '';
    };

    authoringPublicKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "age1abc…";
      description = ''
        Public half of the authoring key, so `sops-identity` can confirm that
        what a machine holds is in fact that key rather than some stale
        leftover. Site data: supplied by the identity flake, never hardcoded
        in this repo.
      '';
    };
  };

  config = {
    home.packages = with pkgs; [
      sops # edits the encrypted files
      age # the cipher underneath
      ssh-to-age # host ssh ed25519 key -> age recipient, for the NixOS repos
    ];

    home.sessionVariables.SOPS_AGE_KEY_FILE = cfg.identityFile;

    # Reports, never generates: under the one-recipient model there is no
    # per-machine key to make, and the authoring key must not be created by a
    # helper -- it already exists and is backed up.
    programs.fish.functions.sops-identity = ''
      set -l keyfile ${cfg.identityFile}
      set -l authoring '${if cfg.authoringPublicKey == null then "" else cfg.authoringPublicKey}'
      if not test -e $keyfile
          echo "no age identity at $keyfile"
          echo ""
          echo "That is fine unless this machine has to decrypt user secrets. If it"
          echo "does, copy the authoring private key there by hand and chmod 600 it:"
          echo "  install -m 600 /dev/null $keyfile; and \$EDITOR $keyfile"
          echo "Do not generate a new one -- a fresh key is a recipient of nothing."
          return 0
      end
      echo "age identity at $keyfile"
      for p in (age-keygen -y $keyfile 2>/dev/null)
          if test -n "$authoring" -a "$p" = "$authoring"
              echo "  $p  <-- authoring key (expected; decrypts user AND system secrets)"
          else
              echo "  $p  <-- UNEXPECTED: not the authoring key."
              echo "      Probably a stale per-machine key from before 2026-11-03. It is a"
              echo "      recipient of nothing, so sops will fail here. Replace it with the"
              echo "      authoring key, or remove it if this machine need not decrypt."
          end
      end
    '';

    # No activation-time identity check on purpose: sops fails loudly by itself
    # when the key is wrong or missing, and an extra guard here would be one
    # more thing to keep true. `sops-identity` is there when you want to look.
  };
}
