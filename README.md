# home-manager configuration

Flake-based [home-manager](https://github.com/nix-community/home-manager)
config for NixOS, other Linux (Arch), and macOS.

## Usage

```sh
git clone <this repo> ~/.config/home-manager
nix run home-manager -- switch --flake ~/.config/home-manager#<name> -b backup
# afterwards just:
home-manager switch --flake ~/.config/home-manager#<name>
```

`<name>` is a `username@host` entry from `machines` in `flake.nix`; add new
machines there (system, username, optional homeDirectory / genericLinux).

## Layout

- `flake.nix` — machine list
- `home.nix` — entry point, cross-platform basics
- `modules/` — one module per concern (fish, git, tmux, neovim, ghostty, hyprland/DMS…)
- `config/` — raw config files shipped or symlinked into `~`

Configs that tools rewrite at runtime (`config/hypr`, `config/DankMaterialShell`,
`config/ghostty/themes`) and configs that are edited often (`config/nvim`) are
linked out-of-store: writes land in this repo's worktree — review and commit
them when they drift. Those links assume the repo is checked out at
`~/.config/home-manager` (override with the `dotfiles.path` option).

## Per-machine bootstrap (not managed here)

- **1Password**: system-level install. On NixOS:
  `programs._1password.enable = true; programs._1password-gui.enable = true;`
  in the system config. Git signing uses the `~/bin/op-ssh-sign` shim, which
  locates the binary on any OS.
- **Wallpapers**: hyprpaper/hyprlock read from `~/.local/share/backgrounds/`
  (`wallhaven-l8lzpq_3840x1600.png`, `antarctica-huge.png`).
- **Rust**: `rustup` is installed; run
  `rustup default stable && rustup component add rust-analyzer` once.
- **DMS custom theme**: `settings.json` points at
  `~/.config/DankMaterialShell/themes/tokyoNightNightMoon/theme.json`; export
  it from DMS or pick a registry theme if missing.
- **macOS**: GUI apps and fonts come from Homebrew; capslock→ctrl remap via
  `hidutil`.

## Notes

- Prompt is starship; shell is fish with vi bindings.
- Fish helper functions (`cat`/`ls`/`ff`/`fbr`/…) load from `conf.d` and wrap
  bat, eza, and fzf.
- tmux plugins are nix-managed (tmux-1password and tmux-cargo pinned via
  `fetchFromGitHub`).
- Hyprland uses the Lua config (`config/hypr/hyprland.lua`) with
  DankMaterialShell; the polkit agent and DMS run as systemd user units.
- Neovim plugins are managed by native `vim.pack` (cloned under
  `~/.local/share/nvim` on first launch).
