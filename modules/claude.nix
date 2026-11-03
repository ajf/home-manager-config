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

  # Claude Code keeps per-project state in ~/.claude/projects/<mangled cwd>,
  # where the mangling is just / -> -. So /home/you -> -home-you, and the name
  # is platform-dependent: a mac's -Users-you-Projects is the same logical
  # directory as a linux box's -home-you-projects. Deriving it from the real
  # path keeps both right without a per-OS table.
  mangle = path: lib.replaceStrings [ "/" ] [ "-" ] path;
in
{
  options.dotfiles.claude = {
    conventions = lib.mkOption {
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

        Note that this file is the ONLY thing loaded in every session
        regardless of directory. Memory directories are per-project, so a rule
        that must always apply belongs here, not in a memory file.
      '';
    };

    memory = {
      vaultDir = lib.mkOption {
        type = lib.types.str;
        default = "${config.home.homeDirectory}/notes/personal/claude-memory";
        description = ''
          Directory in the notes vault holding the memory trees that
          memory.links point at. One definition, so every machine agrees on
          where the vault lives.
        '';
      };

      links = lib.mkOption {
        default = [ ];
        type = lib.types.listOf (lib.types.submodule {
          options = {
            projectPath = lib.mkOption {
              type = lib.types.str;
              example = "/home/you/projects";
              description = ''
                Absolute path of the directory Claude Code is started from.
                Its ~/.claude/projects/<mangled>/memory is replaced with a
                symlink. Must match the real path, including case: a mac's
                ~/Projects and a linux box's ~/projects mangle differently.
              '';
            };
            vaultSubdir = lib.mkOption {
              type = lib.types.str;
              example = "projects";
              description = "Subdirectory of memory.vaultDir to link to.";
            };
          };
        });
        example = lib.literalExpression ''
          [ { projectPath = config.home.homeDirectory; vaultSubdir = "home"; }
            { projectPath = "''${config.home.homeDirectory}/projects"; vaultSubdir = "projects"; }
          ]
        '';
        description = ''
          Memory directories to redirect into the notes vault, so memories
          written on this machine land in the vault and sync to every device.

          Out-of-store symlinks on purpose: Claude Code writes to these at
          runtime, so the targets must stay mutable.

          EMPTY BY DEFAULT, and that default is a safety property, not laziness:
          every machine with links set is another writer to the same vault, and
          Obsidian Sync is not append-safe for concurrent writers. Set it only
          where that is understood, and expect conflict files if two machines
          write the same memory at once.
        '';
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.conventions != null) {
      home.file.".claude/CLAUDE.md".text = cfg.conventions;
    })

    (lib.mkIf (cfg.memory.links != [ ]) {
      home.file = lib.listToAttrs (map (l: {
        name = ".claude/projects/${mangle l.projectPath}/memory";
        value.source = config.lib.file.mkOutOfStoreSymlink
          "${cfg.memory.vaultDir}/${l.vaultSubdir}";
      }) cfg.memory.links);

      # A link whose target does not exist yet is worse than no link: Claude
      # Code writes memories into a dangling path and they vanish. The vault
      # dir is created by Obsidian Sync attaching the vault, which is a manual
      # step, so warn rather than fail -- failing here would block an unrelated
      # activation on a machine that simply has not been synced yet.
      home.activation.claudeMemoryVaultCheck =
        lib.hm.dag.entryAfter [ "writeBoundary" ] (lib.concatMapStrings (l: ''
          if [ ! -d "${cfg.memory.vaultDir}/${l.vaultSubdir}" ]; then
            warnEcho "claude memory: ${cfg.memory.vaultDir}/${l.vaultSubdir} is missing, so ~/.claude/projects/${mangle l.projectPath}/memory dangles. Attach the vault in Obsidian, then re-run home-manager."
          fi
        '') cfg.memory.links);
    })
  ];
}
