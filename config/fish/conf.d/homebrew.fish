# Transitional: Homebrew is being retired in favor of nix. While it's still
# installed keep its paths/completions available — appended, so nix wins any
# conflict. No-ops entirely once brew is gone.
if test -x /opt/homebrew/bin/brew
    fish_add_path --append /opt/homebrew/bin

    for d in /opt/homebrew/share/fish/completions /opt/homebrew/share/fish/vendor_completions.d
        if test -d $d
            set -a fish_complete_path $d
        end
    end
end
