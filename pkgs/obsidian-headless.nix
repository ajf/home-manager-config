# obsidian-headless — headless client for Obsidian Sync and Publish, as `ob`.
#
# Belphemur/obsidian-headless is a Go implementation of obsidianmd's Node
# client of the same name; this is the Go one, which is what the fleet runs.
# Not in nixpkgs as of 26.05.
#
# Unlike the various community "obsidian-cli" tools, which only manipulate
# vault files on disk, this speaks the actual Sync and Publish protocols --
# `ob login`, `ob sync`, `ob publish`. That makes it the only way to get a
# vault onto a machine that has no Obsidian GUI session.
#
# Layout notes: the Go module lives in src/ (hence modRoot), and the binary is
# named `ob` rather than the package name, matching upstream's goreleaser
# (`binary: ob`, `main: ./cmd/ob-go`).

{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "obsidian-headless";
  version = "0.3.6";

  src = fetchFromGitHub {
    owner = "Belphemur";
    repo = "obsidian-headless";
    tag = "v${version}";
    hash = "sha256-nVIfJsVQGNXma5zWTFlxQlqCySlNGSXhPm+0KllGMoM=";
  };

  modRoot = "src";
  subPackages = [ "cmd/ob-go" ];

  vendorHash = "sha256-Qj5/jCqqfTgSL7wOg8FICN4pgY7lMrMKYlQCAb9ius8=";

  # Without these the binary reports "ob version dev". Upstream injects them
  # via goreleaser; Commit/Date are deliberately left out rather than faked,
  # since a nix build has no meaningful values for them.
  ldflags = [
    "-s"
    "-w"
    "-X github.com/Belphemur/obsidian-headless/internal/buildinfo.Version=${version}"
  ];

  postInstall = ''
    mv "$out/bin/ob-go" "$out/bin/ob"
  '';

  meta = {
    description = "Headless client for Obsidian Sync and Publish";
    homepage = "https://github.com/Belphemur/obsidian-headless";
    license = lib.licenses.mit;
    mainProgram = "ob";
    platforms = lib.platforms.unix;
  };
}
