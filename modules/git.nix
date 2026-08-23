{ config, lib, pkgs, ... }:

let
  id = config.dotfiles.identity;
in
{
  programs.git = {
    enable = true;

    # Signing behavior via nix only when a key is set through dotfiles.identity;
    # otherwise ~/.config/git/identity carries signingkey + commit.gpgsign.
    signing = lib.mkIf (id.signingKey != null) {
      key = id.signingKey;
      signByDefault = true;
      format = "ssh";
      signer = "${config.home.homeDirectory}/bin/op-ssh-sign";
    };

    settings = {
      # Per-machine identity lives OUTSIDE this repo, read by git at runtime:
      # user.name / user.email / user.signingkey / commit.gpgsign (see README).
      # Values set via dotfiles.identity win: git's [user] section is written
      # after this include.
      include.path = "~/.config/git/identity";

      gpg.format = "ssh";
      gpg.ssh.program = "${config.home.homeDirectory}/bin/op-ssh-sign";

      push.autoSetupRemote = true;
      pull.rebase = true;
      log.showSignature = true;
      includeIf."gitdir:~/work/".path = "~/work/gitconfig";
    }
    // (
      let
        user = lib.filterAttrs (_: v: v != null) {
          name = id.name;
          email = id.email;
        };
      in
      lib.optionalAttrs (user != { }) { inherit user; }
    );
  };

  # 1Password's ssh signer lives in a different place on every OS; this shim
  # finds it at runtime. Absolute paths only: a PATH lookup would find the
  # shim itself.
  home.file."bin/op-ssh-sign" = {
    executable = true;
    text = ''
      #!/bin/sh
      for c in \
        /run/current-system/sw/bin/op-ssh-sign \
        /opt/1Password/op-ssh-sign \
        /Applications/1Password.app/Contents/MacOS/op-ssh-sign; do
        [ -x "$c" ] && exec "$c" "$@"
      done
      echo "op-ssh-sign: 1Password not found" >&2
      exit 1
    '';
  };
}
