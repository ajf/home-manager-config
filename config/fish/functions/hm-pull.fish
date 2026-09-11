function hm-pull --description 'Pull the identity flake from github and apply this machine\'s home config'
    # The released config: identity repo @ github, dotfiles at whatever rev
    # its flake.lock pins (the lock is the release gate). Fetches over
    # git+ssh, so it works anywhere a github-capable agent is present —
    # locally via 1Password, on servers via the forwarded agent.
    # Local iteration stays with `hm` (path override, no lock semantics).
    set -l flake 'git+ssh://git@github.com/ajf/home-manager-identity'
    set -l host (hostname)
    home-manager switch --flake "$flake#andrew@$host" $argv
    or home-manager switch --flake "$flake#andrew@"(string split -f1 . $host) $argv
end
