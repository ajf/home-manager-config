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
  '';
}
