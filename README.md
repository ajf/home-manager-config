<div align="center">

# ❄️ home-manager-config

** Nix flake for configuring a full desktop environment **

[![NixOS 26.05](https://img.shields.io/badge/NixOS-26.05-5277C3?logo=nixos&logoColor=white)](https://nixos.org)
[![home-manager](https://img.shields.io/badge/home--manager-release--26.05-41439A?logo=nix&logoColor=white)](https://github.com/nix-community/home-manager)
[![Hyprland](https://img.shields.io/badge/Hyprland-DMS-58E1FF?logo=hyprland&logoColor=white)](https://hypr.land)
[![platforms](https://img.shields.io/badge/runs%20on-NixOS%20·%20Arch%20·%20macOS-success)](#roles)
[![flake](https://img.shields.io/badge/flake-pure%2C%20no%20--impure-blueviolet?logo=nix&logoColor=white)](docs/mkHome.md)
[![license: MIT](https://img.shields.io/badge/license-MIT-yellow)](LICENSE)

</div>

---

This flake implements my desktop environment, and nothing personal is
hard-coded in it. Identity — username, git author, work accounts, machine
quirks — lives in a separate **identity flake** (yours, untracked, one per
machine) that has this repo as an input and instantiates it with the personal
values. The same configuration serves different machines (work login is
different) or different people.

## ✨ What you get

- 🖥️ **Hyprland + [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell)** — Lua-configured compositor, Material shell, hypridle/hyprpaper
- 🐟 **fish** with vi bindings, starship prompt, fzf/zoxide/eza/bat wired in
- ✏️ **neovim** — LSP, treesitter, rust tooling; plugins pinned by the flake
- 🪟 **tmux** — server runs as a user service that survives logouts; sesh session manager
- 🔏 **1Password everywhere** — SSH agent, git commit signing, tmux item picker
- 📦 **git-workspace** — every project checkout cloned and synced under `~/workspace`

## 🚀 Use it

```sh
git clone https://github.com/ajf/home-manager-config ~/.config/home-manager
# scaffold your identity flake and fill in the CHANGEMEs:
nix flake new -t ~/.config/home-manager ~/.config/home-manager-local
$EDITOR ~/.config/home-manager-local/flake.nix
# switch:
nix run home-manager -- switch --flake ~/.config/home-manager-local
```

The full contract — `mkHome`'s inputs and outputs, the options an identity
flake can set, and an example identity flake — is documented in
[`docs/mkHome.md`](docs/mkHome.md).

## 🎭 Roles

Defaults an identity flake picks from:

| Role | For |
|---|---|
| `DMS-desktop` | graphical Linux desktop (Hyprland + DMS), NixOS or not |
| `macos` | darwin: CLI environment + app configs |
| `headless` | servers/VMs: no GUI packages or desktop units |

## 🗺️ Layout

- `flake.nix` — roles + the `lib.mkHome` constructor
- `templates/local` — scaffold for the identity flake
- `home.nix` — entry point, cross-platform basics
- `modules/` — one module per concern (fish, git, tmux, neovim, ghostty, hyprland/DMS…)
- `config/` — raw config files shipped or symlinked into `~`
- `docs/` — the flake contract ([`mkHome.md`](docs/mkHome.md))

## 📓 Notes

- Runs on non-NixOS too: only nix itself is required. Non-NixOS Linux is
  auto-detected and gets `targets.genericLinux` (session vars, XDG paths,
  locale archive). On macOS, GUI apps come from Homebrew; nix manages their
  configs and the CLI environment.
- Neovim and tmux plugins are managed by `home-manager`, not their native
  package managers.
