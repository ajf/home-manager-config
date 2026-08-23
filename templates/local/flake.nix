{
  description = "Per-machine home-manager identity (not tracked in the dotfiles repo)";

  # Point at your dotfiles checkout (or its git URL).
  inputs.dotfiles.url = "path:/home/CHANGEME/.config/home-manager";

  outputs = { dotfiles, ... }: {
    # Name the entry "<username>@<hostname>" and a bare
    # `home-manager switch --flake <this-dir>` finds it automatically.
    homeConfigurations."CHANGEME@CHANGEME" = dotfiles.lib.mkHome {
      role = "DMS-desktop"; # DMS-desktop | macos | headless
      system = "x86_64-linux"; # x86_64-linux | aarch64-linux | aarch64-darwin
      username = "CHANGEME";

      # homeDirectory = "/home/CHANGEME"; # when not /home/<user> or /Users/<user>
      # genericLinux = true;              # non-NixOS Linux (e.g. Arch)
      # desktop = false;                  # override the role's default

      # Git identity; alternatively keep it in ~/.config/git/identity.
      # identity = {
      #   name = "Your Name";
      #   email = "you@example.com";
      #   signingKey = "key::ssh-ed25519 AAAA...";
      # };

      # git-workspace: `git-workspace update` clones/syncs everything under
      # ~/workspace. Token comes from 1Password at invocation time.
      # workspace = {
      #   providers = [
      #     { provider = "github"; name = "CHANGEME"; }
      #   ];
      #   tokenRef = "op://Personal/GitHub Personal Access Token/token";
      # };
    };
  };
}
