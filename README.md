# home-manager configuration

Flake-based [home-manager](https://github.com/nix-community/home-manager)
config for NixOS, other Linux (Arch), and macOS.

## Usage

```sh
git clone <this repo> ~/.config/home-manager
nix --extra-experimental-features 'nix-command flakes' \
  run home-manager -- switch --flake ~/.config/home-manager#<name> -b backup
# afterwards just (flakes are enabled via the managed ~/.config/nix/nix.conf):
home-manager switch --flake ~/.config/home-manager#<name>
```

`<name>` is a `username@host` entry from `machines` in `flake.nix` (username
is parsed from the entry name); add new machines there (system, optional
homeDirectory / genericLinux / `desktop = false` for headless / `identity`
to override git name/email/key). On a machine not in the map,
`home-manager switch --flake .#current --impure` derives username, home
directory, and system from the environment.

## Layout

- `flake.nix` — machine list
- `home.nix` — entry point, cross-platform basics
- `modules/` — one module per concern (fish, git, tmux, neovim, ghostty, hyprland/DMS…)
- `config/` — raw config files shipped or symlinked into `~`

Configs that tools rewrite at runtime (`config/hypr`, `config/DankMaterialShell`,
`config/ghostty/themes`) and configs that are edited often (`config/nvim`) are
linked out-of-store: writes land in this repo's worktree — review and commit
them when they drift. Machine-local state (monitor layout in
`config/hypr/dms/outputs.*`, `config/DankMaterialShell/settings.json`) is
gitignored: DMS regenerates it per machine. Those links assume the repo is
checked out at `~/.config/home-manager` (override with the `dotfiles.path`
option).

## Running without NixOS (Arch, macOS, other Linux)

Only nix itself is required — nothing here depends on NixOS. Use a machine
entry with `genericLinux = true` on non-NixOS Linux (it wires up session
vars, XDG paths, and the locale archive).

1. Install nix (multi-user). The [Determinate installer](https://determinate.systems/nix-installer)
   enables flakes out of the box; with the upstream installer the
   `--extra-experimental-features` flags in the bootstrap command above cover
   the first run.
2. Clone and switch as in Usage, picking the right `machines` entry
   (`andrew@arch`, `andrew@mac`, `andrew@headless`, …).
3. Make fish the login shell — home-manager installs it but cannot register
   it:

   ```sh
   echo ~/.nix-profile/bin/fish | sudo tee -a /etc/shells
   chsh -s ~/.nix-profile/bin/fish
   ```

Platform notes:

- **Arch**: the compositor and session are the distro's job — install
  `hyprland` (plus a greeter) with pacman; this repo supplies the Hyprland
  config, DMS, hypridle/hyprlock/hyprpaper, and all CLI tooling. GPU-facing
  programs generally come from pacman, nix handles the rest.
- **macOS**: GUI apps and fonts come from Homebrew (`ghostty`, `1password`,
  nerd-font casks); nix manages their configs and the CLI environment. The
  systemd units and desktop modules are Linux-gated and simply don't apply.
- **1Password**: the git signing shim (`~/bin/op-ssh-sign`) probes the
  standard install locations on NixOS, Arch (`/opt/1Password`), and macOS
  (`/Applications`), so signing works wherever the app is installed.

## Per-machine bootstrap (not managed here)

- **Git identity**: personal data is not tracked in this repo. Create
  `~/.config/git/identity` on each machine (git reads it via an include):

  ```ini
  [user]
      name = Your Name
      email = you@example.com
      signingkey = key::ssh-ed25519 AAAA...
  [commit]
      gpgsign = true
  ```

  Omit `signingkey`/`gpgsign` on machines without 1Password. Alternatively
  set `identity = { name = ...; email = ...; signingKey = ...; }` on a
  machine entry in `flake.nix` to manage it declaratively (tracked in git).
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
