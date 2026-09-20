{ config, lib, ... }:

# Global Claude Code conventions, shipped to every machine. Read-only by
# design: changing the rules is a dotfiles commit, not a session side effect.
#
# The mechanism is generic; the conventions themselves are not. Which tracker
# holds the todo list, which vault holds memory, which host is canonical, what
# the runbooks are called -- that is all site-specific data, supplied by the
# per-machine identity flake through this option, in the same spirit as
# modules/step.nix. Keeping it out of here means this repo stays forkable and
# does not publish someone's infrastructure.
let
  cfg = config.dotfiles.claude;
in
{
  options.dotfiles.claude.conventions = lib.mkOption {
    type = lib.types.nullOr lib.types.lines;
    default = null;
    example = ''
      # Global conventions

      ## Task tracking
      - The canonical todo list is <tracker>; add and complete items there
        rather than tracking them in memory files or plan documents.

      ## Memory / knowledge
      - Write memories through the normal Claude memory directories; on
        <canonical-host> they are symlinked into the notes vault.
    '';
    description = ''
      Markdown written to ~/.claude/CLAUDE.md, which Claude Code loads as
      standing instructions for every session on this machine. null (the
      default) writes no file, which is the right answer for a fresh fork.
    '';
  };

  config = lib.mkIf (cfg.conventions != null) {
    home.file.".claude/CLAUDE.md".text = cfg.conventions;
  };
}
