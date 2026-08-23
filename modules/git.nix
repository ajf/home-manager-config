{ config, lib, pkgs, ... }:

{
  programs.git = {
    enable = true;

    signing = {
      key = "key::ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO9mWl3pPCPvpbbLZoseNee32Cst2FbV22zJqARVTydn";
      signByDefault = true;
      format = "ssh";
      signer = "${config.home.homeDirectory}/bin/op-ssh-sign";
    };

    settings = {
      user = {
        name = "Andrew Forgue";
        email = "andrew@forgue.io";
      };
      push.autoSetupRemote = true;
      pull.rebase = true;
      log.showSignature = true;
      includeIf."gitdir:~/work/".path = "~/work/gitconfig";
    };
  };

  # 1Password's ssh signer lives in a different place on every OS; the old
  # dotfiles carried per-OS symlinks in ~/bin. This shim finds it at runtime.
  home.file."bin/op-ssh-sign" = {
    executable = true;
    text = ''
      #!/bin/sh
      # Locate 1Password's op-ssh-sign across platforms.
      if command -v op-ssh-sign >/dev/null 2>&1; then
        exec op-ssh-sign "$@"
      fi
      for c in \
        /opt/1Password/op-ssh-sign \
        /Applications/1Password.app/Contents/MacOS/op-ssh-sign \
        /run/current-system/sw/share/1password/op-ssh-sign; do
        [ -x "$c" ] && exec "$c" "$@"
      done
      echo "op-ssh-sign: 1Password not found" >&2
      exit 1
    '';
  };
}
