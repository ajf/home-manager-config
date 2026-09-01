function nixos-rebuild --description 'nixos-rebuild via doas (doas drops NIX_PATH, so pin the root channel)'
    doas nixos-rebuild \
        -I nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos \
        -I nixos-config=/etc/nixos/configuration.nix \
        $argv
end
