{ config, lib, pkgs, ... }:

# Plain neovim package, not programs.neovim: the HM module generates its own
# ~/.config/nvim/init.lua, which conflicts with linking the config directory
# below. Plugins are managed by nvim's native vim.pack (cloned under
# ~/.local/share/nvim on first launch).
{
  home.packages = [ pkgs.neovim ];

  home.sessionVariables.EDITOR = "nvim";

  # Out-of-store symlink: edit config/nvim in this repo and changes apply
  # immediately, no `home-manager switch` needed.
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/config/nvim";
}
