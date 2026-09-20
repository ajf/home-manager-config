# notesmd-cli — community Obsidian CLI (open/search/create/move/delete notes,
# frontmatter handling). Not in nixpkgs as of 26.05, so it is built here.
#
# Formerly Yakitrak/obsidian-cli; the repo was renamed and the binary with it,
# so `obsidian-cli` is now `notesmd-cli` (see MIGRATION.md upstream). The old
# GitHub path still redirects.
#
# It operates on a vault *directory* on disk -- it has no knowledge of Obsidian
# Sync and cannot authenticate to it.

{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "notesmd-cli";
  version = "0.3.7";

  src = fetchFromGitHub {
    owner = "Yakitrak";
    repo = "notesmd-cli";
    tag = "v${version}";
    hash = "sha256-dENOPkEeKTYPFf467Isoi7kaa8Bh78PqNyzjU8Q6BEc=";
  };

  # Upstream commits its vendor/ directory, so there is nothing to fetch.
  vendorHash = null;

  meta = {
    description = "Interact with Obsidian vaults from the terminal";
    homepage = "https://github.com/Yakitrak/notesmd-cli";
    license = lib.licenses.mit;
    mainProgram = "notesmd-cli";
    platforms = lib.platforms.unix;
  };
}
