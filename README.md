# home-manager configuration

Flake-based [home-manager](https://github.com/nix-community/home-manager)
config for NixOS, other Linux (Arch), and macOS.

## Usage

This is a base flake that implements my desktop environment but removes all the
hard-coded identity aspects.  The intent is this is reusable between different
machines (work login is different) or different people.

This should be instantiated by another flake with all the identity information
in it — scaffold one with `nix flake new -t <this-flake> <dir>`
(see [`templates/local`](templates/local/flake.nix)). The full contract —
`mkHome`'s inputs and outputs, and the options an identity flake can set — is
documented in [`docs/mkHome.md`](docs/mkHome.md).

## Roles (defaults a per-machine flake picks from)

- `DMS-desktop` — graphical Linux desktop (Hyprland + DMS), NixOS or not
- `macos` — darwin: CLI environment + app configs
- `headless` — servers/VMs: no GUI packages or desktop units

## Layout

- `flake.nix` — roles + the `lib.mkHome` constructor
- `templates/local` — scaffold for the per-machine flake
- `home.nix` — entry point, cross-platform basics
- `modules/` — one module per concern (fish, git, tmux, neovim, ghostty, hyprland/DMS…)
- `config/` — raw config files shipped or symlinked into `~`

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

## Notes

- Neovim and Tmux plugins are managed by `home-manager`, not their native
  package managers.
