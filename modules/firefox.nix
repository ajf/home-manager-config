{ config, lib, pkgs, ... }:

# Firefox with declaratively-installed extensions via enterprise policies:
# Firefox fetches them from addons.mozilla.org and keeps them updated.
# normal_installed = installed automatically but the user can disable them
# (force_installed would lock them on).
lib.mkIf (pkgs.stdenv.isLinux && config.dotfiles.desktop.enable) {
  programs.firefox = {
    enable = true;

    policies = {
      # 1Password handles passwords; turn off the built-in manager and its
      # save-login prompts.
      PasswordManagerEnabled = false;
      OfferToSaveLogins = false;

      ExtensionSettings = {
        # uBlock Origin
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "normal_installed";
        };
        # 1Password
        "{d634138d-c276-4fc8-924b-40a0ea21d284}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/1password-x-password-manager/latest.xpi";
          installation_mode = "normal_installed";
        };
      };
    };
  };
}
