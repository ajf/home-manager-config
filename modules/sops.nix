{ config, lib, pkgs, ... }:

# sops/age toolchain and this machine's USER age identity.
#
# Three kinds of age key exist in this fleet, and they must not be confused:
#
#   authoring  one personal key, recipient of everything, the only key that can
#              rekey. Lives on the machines you author from (plus a backup);
#              NOT managed here, and deliberately not installed by nix.
#   machine    a host's /etc/ssh/ssh_host_ed25519_key, used by the NixOS-level
#              sops module for system secrets. Root-only, so home-manager can
#              never read it -- which is exactly why a user identity exists.
#   user       THIS file. Per machine, generated locally by `sops-user-key`,
#              never transported; only its public half is published as a
#              recipient. A lost machine costs a rekey, nothing more.
#
# The private key is never a nix string and never in the store: the store is
# world-readable, and nix has no business holding a decryption identity.
let
  cfg = config.dotfiles.sops;
in
{
  options.dotfiles.sops.userKeyFile = lib.mkOption {
    type = lib.types.str;
    default = "${config.xdg.configHome}/sops/age/keys.txt";
    description = ''
      Per-machine user age identity, used to decrypt home-manager-level sops
      secrets. One definition so the sops CLI, the eventual sops-nix home
      manager module (sops.age.keyFile) and the generator helper cannot drift
      apart.

      Note this path is NOT where sops looks by default on darwin: it resolves
      its key through Go's UserConfigDir, which there is
      ~/Library/Application Support. SOPS_AGE_KEY_FILE below pins it.
    '';
  };

  config = {
    home.packages = with pkgs; [
      sops # edits the encrypted files
      age # the cipher underneath
      ssh-to-age # host ssh ed25519 key -> age recipient, for .sops.yaml
    ];

    # Without this sops resolves its age key through Go's UserConfigDir, which
    # on darwin is ~/Library/Application Support -- not ~/.config -- so a key
    # at the XDG path is silently not found and every decrypt fails with
    # "none were successful". Pinned so the path is identical on every platform.
    home.sessionVariables.SOPS_AGE_KEY_FILE = cfg.userKeyFile;

    # Generating this is a one-off per machine and must never clobber: an
    # existing identity is the only way to read whatever was encrypted to it.
    programs.fish.functions.sops-user-key = ''
      set -l keyfile ${cfg.userKeyFile}
      if test -e $keyfile
          echo "user age key already exists at $keyfile"
          echo "public half (this is what belongs in .sops.yaml):"
          age-keygen -y $keyfile
          return 0
      end
      mkdir -p (dirname $keyfile); chmod 700 (dirname $keyfile)
      begin
          umask 077
          age-keygen -o $keyfile
      end
      chmod 600 $keyfile
      echo ""
      echo "Add this PUBLIC key to home-manager-identity/.sops.yaml as "(hostname -s)"_user,"
      echo "then rekey from a machine that can already decrypt:  sops updatekeys secrets/*.yaml"
      age-keygen -y $keyfile
    '';

    # Say so rather than letting the first decrypt fail obscurely. A warning,
    # not an error: a machine with no user secrets yet is perfectly fine, and
    # this must not block an unrelated switch.
    home.activation.sopsUserKeyCheck =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -e "${cfg.userKeyFile}" ]; then
          warnEcho "sops: no user age key at ${cfg.userKeyFile} -- run 'sops-user-key' to create one, then add its public half to .sops.yaml. Harmless until this machine needs to decrypt a user secret."
        fi
      '';
  };
}
