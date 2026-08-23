function ls --wraps=eza --description 'ls replacement using eza'
    # Check if eza is available, fall back to regular ls if not
    if not command -q eza
        command ls $argv
        return
    end

    # If no arguments given, use a sensible default view
    if test (count $argv) -eq 0
        eza \
            --all \
            --long \
            --group \
            --header \
            --git \
            --icons \
            --group-directories-first \
            --time-style=long-iso \
            --color=always
    else
        eza \
            --all \
            --long \
            --group \
            --header \
            --git \
            --icons \
            --group-directories-first \
            --time-style=long-iso \
            --color=always \
            $argv
    end
end

# Convenience aliases
function ll --wraps=eza --description 'List with details'
    ls $argv
end

function la --wraps=eza --description 'List all including hidden'
    eza --all --icons --group-directories-first --color=always $argv
end

function lt --wraps=eza --description 'List as a tree'
    eza --tree --icons --git-ignore --color=always $argv
end

function lsize --wraps=eza --description 'List sorted by size'
    eza --all --long --sort=size --reverse --icons --color=always $argv
end

function lnew --wraps=eza --description 'List sorted by modified time, newest first'
    eza --all --long --sort=modified --reverse --icons --color=always $argv
end
