# home-manager configuration

Flake-based [home-manager](https://github.com/nix-community/home-manager)
config for NixOS, other Linux (Arch), and macOS.

## Usage

Two flakes: this repo holds the shared configuration and exports
`lib.mkHome`; a small **untracked per-machine flake** at
`~/.config/home-manager-local` supplies the personal bits (username, home
directory, system, git identity) and instantiates a role. Evaluation stays
pure — no `--impure`.

```sh
git clone <this repo> ~/.config/home-manager
# scaffold the per-machine flake and fill in the CHANGEMEs:
nix --extra-experimental-features 'nix-command flakes' \
  flake new -t ~/.config/home-manager ~/.config/home-manager-local
$EDITOR ~/.config/home-manager-local/flake.nix
# first switch:
nix --extra-experimental-features 'nix-command flakes' \
  run home-manager -- switch --flake ~/.config/home-manager-local -b backup
# afterwards just:
hm
```

`hm` (a managed fish function) re-locks the local flake's `dotfiles` input
and switches; the re-lock matters because a `path:` input is pinned by
content hash and would otherwise keep using a stale copy of this repo.
Naming the local flake's entry `<username>@<hostname>` lets a bare
`home-manager switch --flake ~/.config/home-manager-local` find it.

Roles (defaults a per-machine flake picks from):

- `DMS-desktop` — graphical Linux desktop (Hyprland + DMS), NixOS or not
- `macos` — darwin: CLI environment + app configs
- `headless` — servers/VMs: no GUI packages or desktop units

`mkHome` also accepts `homeDirectory`, `genericLinux` (non-NixOS Linux),
`desktop`, and `identity` overrides per machine.

## Layout

- `flake.nix` — roles + the `lib.mkHome` constructor
- `templates/local` — scaffold for the per-machine flake
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

Only nix itself is required — nothing here depends on NixOS. Non-NixOS
Linux is auto-detected (no `/etc/NIXOS`) and gets `targets.genericLinux`,
which wires up session vars, XDG paths, and the locale archive.

1. Install nix (multi-user). The [Determinate installer](https://determinate.systems/nix-installer)
   enables flakes out of the box; with the upstream installer the
   `--extra-experimental-features` flags in the bootstrap command above cover
   the first run.
2. Clone and switch as in Usage, picking the right role in the local flake
   (`DMS-desktop`, `macos`, `headless`).
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
  pass `identity = { name = ...; email = ...; signingKey = ...; }` to
  `mkHome` in the per-machine flake — equally untracked, and declarative.
  Values set via `mkHome` win over the identity file.
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
- Project checkouts are managed by `git-workspace` under `~/workspace`
  (`git-workspace update` clones/syncs everything). Providers come from the
  per-machine flake (`workspace` argument to `mkHome`); a fish wrapper
  exports GITHUB_TOKEN per invocation from `gh auth token` by default
  (`gh auth login` once per machine), overridable via
  `workspace.tokenCommand` (e.g. an `op read` 1Password reference).
- Hyprland uses the Lua config (`config/hypr/hyprland.lua`) with
  DankMaterialShell; the polkit agent and DMS run as systemd user units.
- Neovim plugins come from `pkgs.vimPlugins` (pinned by the flake, linked at
  `~/.local/share/nvim/site/pack/hm`); config lives in `config/nvim`, and
  edits to its `lua/` tree take effect after a `home-manager switch`.
