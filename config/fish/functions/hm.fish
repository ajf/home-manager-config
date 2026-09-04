function hm --description 'Switch home-manager from the local dotfiles checkout'
    # The identity flake pins dotfiles to a github rev; iterate on the
    # local checkout by overriding that input (pure, no lock rewrite).
    home-manager switch --flake ~/.config/home-manager-local \
        --override-input dotfiles path:$HOME/.config/home-manager $argv
end
