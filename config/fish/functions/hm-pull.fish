function hm-pull --description 'Pull the identity flake from github and apply this machine\'s home config'
    # The released config: identity repo @ github, dotfiles at whatever rev
    # its flake.lock pins (the lock is the release gate). Fetches over
    # git+ssh, so it works anywhere a github-capable agent is present —
    # locally via 1Password, on servers via the forwarded agent.
    # Local iteration stays with `hm` (path override, no lock semantics).
    #
    # The flake ref and username are substituted in by modules/fish.nix from
    # dotfiles.identityFlake and home.username — this file is a template, so
    # a fork points at its own identity repo without editing it.
    set -l flake '@identityFlake@'
    set -l user '@username@'
    # bust nix's flake-ref cache first — otherwise a recent release can be
    # silently skipped in favor of a stale cached copy (bit us 2026-09-12)
    nix flake metadata --refresh "$flake" >/dev/null
    or begin
        echo "hm-pull: cannot reach the identity flake on github" >&2
        return 1
    end
    set -l host (hostname)
    home-manager switch --flake "$flake#$user@$host" $argv
    or home-manager switch --flake "$flake#$user@"(string split -f1 . $host) $argv
end
