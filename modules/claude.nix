# Global Claude Code conventions, shipped to every machine. Read-only by
# design: changing the rules is a dotfiles commit, not a session side effect.
{ ... }:
{
  home.file.".claude/CLAUDE.md".text = ''
    # Global conventions

    ## Task tracking → Todoist
    - The canonical todo list is Todoist, project "Homelab" (sections:
      Quick wins / Projects / Ziply pre-activation / Hardware / Waiting on
      Andrew / Someday; label `homelab`).
    - Add, update, and complete action items THERE — never track open tasks
      in memory files or plan documents. Memory holds knowledge; plan docs
      hold design detail; Todoist holds what to do next.
    - Use the Todoist MCP tools when connected; otherwise the unified v1
      API (https://api.todoist.com/api/v1 — REST v2 is dead, returns 410).
      The API token is Andrew's: ask for it (1Password), don't store it.

    ## Memory / knowledge → Obsidian
    - Write memories through the normal Claude memory directories. On
      intrepid (the canonical session host for memory) they are symlinked
      into the Obsidian vault: ~/notes/personal/claude-memory/
      (home/ = user & environment, projects/ = project knowledge), and
      Obsidian Sync carries them to every device.
    - Do not break those symlinks; other machines hold stale or empty
      copies — treat intrepid's memory as the source of truth.
    - Link related memories with Obsidian-style [[wikilinks]]; they render
      as a real graph in Obsidian.

    ## Bootstrapping a fresh machine
    1. First home-manager activation (hm-pull doesn't exist yet):
       `nix run home-manager/release-26.05 -- switch --flake 'git+ssh://git@github.com/ajf/home-manager-identity#andrew@<hostname>'`
       Afterwards `hm-pull` applies releases; `hm` iterates on a local
       dotfiles checkout.
    2. Obsidian (UI-only, ~60s, needs Andrew): open Obsidian -> sign in ->
       Settings -> Sync -> Connect to existing remote vault `personal` at
       ~/notes/personal -> E2E passphrase. Sync creates the directory;
       nothing pre-creates it. Spotlight/launcher and vault registry are
       handled by home-manager.
    3. Memory wiring — ONLY when this machine becomes the canonical
       session host (one writer at a time; Sync is not append-safe for
       concurrent writers). After the vault has synced:
         ~/.claude/projects/-home-andrew/memory
           -> symlink to ~/notes/personal/claude-memory/home
         ~/.claude/projects/-home-andrew-projects/memory
           -> symlink to ~/notes/personal/claude-memory/projects
       (move any existing files into the vault first, then replace the
       dirs with symlinks). Update the `todoist-obsidian` memory to name
       the new canonical host. On non-canonical machines leave memory
       dirs alone — they may be stale; the vault copy is the truth.
    4. Session start: recall begins at the `homelab-overview` memory
       ("START HERE" in the index).
  '';
}
