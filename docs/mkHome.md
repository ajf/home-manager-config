# The flake contract

This flake exports a constructor, not configurations. An identity flake
(untracked, one per machine) has this repo as its `dotfiles` input and calls
`dotfiles.lib.mkHome` with the personal values.

## Outputs

| Output | What it is |
|---|---|
| `lib.mkHome` | Constructor: identity values in, `homeManagerConfiguration` out |
| `lib.roles` | The role table `mkHome` resolves `role` against |
| `templates.default` | Scaffold for the identity flake (`nix flake new -t <this-flake> <dir>`) |

## `mkHome` arguments

| Argument | Default | Meaning |
|---|---|---|
| `system` | required | Nix system string; darwin systems build from the `nixpkgs-darwin` input |
| `username` | required | `home.username` |
| `role` | `null` | `DMS-desktop`, `macos`, or `headless`; supplies platform and desktop defaults, and errors if `system` contradicts the role's platform |
| `homeDirectory` | `/home/<user>`, `/Users/<user>` on darwin | Override when the convention doesn't hold |
| `desktop` | from role (`true` unless `headless`) | Graphical machine: Hyprland/DMS, GUI packages, fonts, desktop units |
| `genericLinux` | `false` | Set on non-NixOS Linux (e.g. Arch): session vars, XDG paths, locale archive |
| `identity` | `{ }` | Git author `name`, `email`, `signingKey`; anything left unset defers to the untracked `~/.config/git/identity` file |
| `workspace` | `{ }` | git-workspace providers and token command (see options below) |
| `extraModules` | `[ ]` | Plain home-manager modules from the identity flake — mail accounts, work-only tools, machine quirks |

The return value is a `home-manager.lib.homeManagerConfiguration`; expose it
as `homeConfigurations."<username>@<hostname>"` and a bare
`home-manager switch --flake <identity-flake-dir>` finds it.

## Example identity flake

A real one looks like this — identity and account names inline, machine
quirks (GPU workarounds, a per-directory work git identity, mail accounts)
riding along as `extraModules`:

```nix
{
  description = "Per-machine home-manager identity (examplebox)";

  inputs.dotfiles.url = "github:alice/home-manager-config";

  outputs = { dotfiles, ... }: {
    homeConfigurations."alice@examplebox" = dotfiles.lib.mkHome {
      role = "DMS-desktop";
      system = "x86_64-linux";
      username = "alice";

      identity = {
        name = "Alice Example";
        email = "alice@example.com";
        signingKey = "key::ssh-ed25519 AAAAC3...";
      };

      workspace = {
        providers = [
          { provider = "github"; name = "alice"; }
        ];
        # auth: gh CLI's stored token (the tokenCommand default)
      };

      extraModules = [ ./gpu.nix ./work-git.nix ./mail.nix ];
    };
  };
}
```

## Options `extraModules` can set (`dotfiles.*`)

| Option | Default | Meaning |
|---|---|---|
| `dotfiles.path` | `~/.config/home-manager` | Checkout location of this repo; out-of-store symlinks (configs that tools rewrite at runtime) resolve against it |
| `dotfiles.desktop.enable` | from `mkHome` | Same switch as the `desktop` argument |
| `dotfiles.identity.{name,email,signingKey}` | `null` | Same values as the `identity` argument |
| `dotfiles.workspace.root` | `"workspace"` | git-workspace root, relative to home |
| `dotfiles.workspace.providers` | `[ ]` | Provider entries for `workspace.toml`, e.g. `{ provider = "github"; name = "you"; }` |
| `dotfiles.workspace.tokenCommand` | `"gh auth token"` | Command whose output becomes `GITHUB_TOKEN` per git-workspace run; `null` disables the wrapper |

## Local iteration

The identity flake pins `dotfiles` to a github rev; a plain
`home-manager switch` reproduces that rev everywhere. To build from the
local checkout instead (absolute `path:` inputs can't be shared across
machines, and relative ones don't survive the store copy), override the
input at switch time — the `hm` fish function does exactly this:

```sh
home-manager switch --flake ~/.config/home-manager-local \
  --override-input dotfiles path:$HOME/.config/home-manager
```

Push and `nix flake update dotfiles` to move the pin.
