{
  description = "Per-machine home-manager identity (not tracked in the dotfiles repo)";

  # Pin the dotfiles repo; iterate on a local checkout with
  #   home-manager switch --flake <this-dir> \
  #     --override-input dotfiles path:$HOME/.config/home-manager
  # (the `hm` fish function does exactly that).
  inputs.dotfiles.url = "github:CHANGEME/home-manager-config";

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
      # ~/workspace. Auth defaults to `gh auth token` (run `gh auth login`
      # once per machine); set workspace.tokenCommand to override.
      # workspace = {
      #   providers = [
      #     { provider = "github"; name = "CHANGEME"; }
      #   ];
      # };

      # Per-machine modules that are too personal for the dotfiles repo
      # (mail accounts, work-only tools, ...). Plain home-manager modules.
      # extraModules = [ ./neomutt.nix ];
    };
  };
}
