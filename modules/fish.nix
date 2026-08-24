{ config, lib, pkgs, ... }:

{
  programs.fish = {
    enable = true;

    shellAliases.more = "less";

    shellInit = ''
      # The desktop session exports __HM_SESS_VARS_SOURCED at login, which
      # makes every descendant shell skip hm-session-vars — so vars added by
      # a newer HM generation never appear until re-login. Force-source the
      # current generation's vars in every fish instead.
      if test -f ~/.nix-profile/etc/profile.d/hm-session-vars.fish
          set -e __HM_SESS_VARS_SOURCED
          source ~/.nix-profile/etc/profile.d/hm-session-vars.fish
      end

      # NixOS setgid wrappers (op, …) must beat the plain binaries in
      # /run/current-system/sw/bin; sessions started via uwsm/greetd don't
      # go through a login shell and lack /run/wrappers/bin entirely.
      if test -d /run/wrappers/bin
          set -gx PATH /run/wrappers/bin (string match -v /run/wrappers/bin $PATH)
      end
    '';

    interactiveShellInit = ''
      fish_vi_key_bindings

      fish_add_path ~/bin
      fish_add_path ~/.cargo/bin
      fish_add_path ~/.local/bin

      if type -q rustup
        rustup completions fish | source
      end

      set -x T_SESSION_USE_GIT_ROOT true
      set -x LIBPROC_HIDE_KERNEL 1
    '';
  };

  # These files define several functions each (cat/catp/batp/..., ls/ll/la/...,
  # ff/fbr/flog/...), so fish autoload-by-filename doesn't cover them; loading
  # them from conf.d makes them available in every session.
  xdg.configFile."fish/conf.d/bat.fish".source = ../config/fish/conf.d/bat.fish;
  xdg.configFile."fish/conf.d/eza.fish".source = ../config/fish/conf.d/eza.fish;
  xdg.configFile."fish/conf.d/fzf.fish".source = ../config/fish/conf.d/fzf.fish;

  xdg.configFile."fish/functions/fish_ssh_agent.fish".source =
    ../config/fish/functions/fish_ssh_agent.fish;
  xdg.configFile."fish/functions/hm.fish".source =
    ../config/fish/functions/hm.fish;
}
