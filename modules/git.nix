{ config, lib, pkgs, ... }:

let
  id = config.dotfiles.identity;
in
{
  programs.git = {
    enable = true;

    # Signing behavior via nix only when a key is set through dotfiles.identity;
    # otherwise ~/.config/git/identity carries signingkey + commit.gpgsign.
    # No explicit signer, so home-manager pins openssh's ssh-keygen, which
    # signs with whatever agent SSH_AUTH_SOCK names — including over ssh.
    signing = lib.mkIf (id.signingKey != null) {
      key = id.signingKey;
      signByDefault = true;
      format = "ssh";
    };

    settings = {
      # Per-machine identity lives OUTSIDE this repo, read by git at runtime:
      # user.name / user.email / user.signingkey / commit.gpgsign (see README).
      # Values set via dotfiles.identity win: git's [user] section is written
      # after this include.
      include.path = "~/.config/git/identity";

      # gpg.ssh.program is left to the signing block above (openssh's
      # ssh-keygen), which reaches the key through the agent. 1Password's
      # op-ssh-sign talked to the desktop app over its own IPC instead — it
      # needs a display, so it failed outright in an ssh session. Going
      # through the agent keeps one story: local, 1Password prompts here;
      # over ssh, the forwarded agent prompts on the machine we came from.
      gpg.format = "ssh";

      # Lets `git log --show-signature` verify our own commits (public key
      # only, derived from the untracked per-machine identity).
      gpg.ssh.allowedSignersFile =
        lib.mkIf (id.email != null && id.signingKey != null)
          "${pkgs.writeText "allowed_signers"
            "${id.email} ${lib.removePrefix "key::" id.signingKey}\n"}";

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
}
