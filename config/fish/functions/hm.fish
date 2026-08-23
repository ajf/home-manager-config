function hm --description 'Refresh dotfiles input and switch home-manager (pure, two-flake setup)'
    # The local flake locks the dotfiles path input by content hash, so it
    # must be re-locked to pick up edits to ~/.config/home-manager.
    nix flake update dotfiles --flake ~/.config/home-manager-local
    and home-manager switch --flake ~/.config/home-manager-local $argv
end
