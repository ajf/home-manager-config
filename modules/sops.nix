{ config, lib, pkgs, ... }:

# sops/age toolchain, and where this user's age identity lives.
#
# nix does not generate or manage a decryption identity: the store is
# world-readable, so a private key must never be a nix string. Each machine's
# identity is generated ON that machine with age-keygen and never transported;
# only its public half is published as a recipient. One key per machine, so a
# lost machine is revoked by dropping its recipient and rekeying, rather than
# by rotating a shared key everywhere.
#
# The NixOS repos work differently, and should: there each host decrypts with
# its own /etc/ssh/ssh_host_ed25519_key via sops.age.sshKeyPaths, because root
# decrypts at boot with nobody present.
let
  cfg = config.dotfiles.sops;
in
{
  options.dotfiles.sops.identityFile = lib.mkOption {
    type = lib.types.str;
    default = "${config.xdg.configHome}/sops/age/keys.txt";
    description = ''
      Where this user's age identity lives, pinned into SOPS_AGE_KEY_FILE.

      Needed because sops otherwise resolves its key through Go's
      UserConfigDir, which on darwin is ~/Library/Application Support rather
      than ~/.config -- a key at the XDG path is then silently not found and
      every decrypt fails with "none were successful", which looks exactly
      like a bad key rather than a bad path.
    '';
  };

  config = {
    home.packages = with pkgs; [
      sops # edits the encrypted files
      age # the cipher underneath
      ssh-to-age # host ssh ed25519 key -> age recipient, for the NixOS repos
    ];

    home.sessionVariables.SOPS_AGE_KEY_FILE = cfg.identityFile;
  };
}
