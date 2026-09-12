# Obsidian + the standard vault (~/notes/personal, Obsidian Sync). The app
# rewrites its vault registry (obsidian.json) at runtime, so we SEED it via
# activation instead of managing the file read-only: create the vault dir,
# register it if absent, then leave the file to the app. Desktop-only —
# headless boxes can't run it and Sync never happens outside the app.
{ config, lib, pkgs, ... }:
let
  vault = "${config.home.homeDirectory}/notes/personal";
  cfgDir =
    if pkgs.stdenv.isDarwin
    then "Library/Application Support/obsidian"
    else ".config/obsidian";
in
{
  config = lib.mkIf config.dotfiles.desktop.enable {
    home.packages = [ pkgs.obsidian ];

    # The vault dir itself is created by Obsidian Sync when Andrew attaches
    # the vault — we deliberately do NOT mkdir it (an empty pre-made dir just
    # confuses first-sync). Registry is seeded only once the vault exists.
    home.activation.obsidianVault = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -d "${vault}" ]; then
      obsCfg="$HOME/${cfgDir}/obsidian.json"
      run mkdir -p "$(dirname "$obsCfg")"
      if [ ! -s "$obsCfg" ]; then
        vid=$(${pkgs.coreutils}/bin/head -c8 /dev/urandom | ${pkgs.coreutils}/bin/od -An -tx1 | ${pkgs.coreutils}/bin/tr -d ' \n')
        run ${pkgs.coreutils}/bin/printf '{"vaults":{"%s":{"path":"%s","open":true}}}' \
          "$vid" "${vault}" > "$obsCfg"
      elif ! ${pkgs.jq}/bin/jq -e --arg p "${vault}" \
             '.vaults[]? | select(.path == $p)' "$obsCfg" >/dev/null; then
        vid=$(${pkgs.coreutils}/bin/head -c8 /dev/urandom | ${pkgs.coreutils}/bin/od -An -tx1 | ${pkgs.coreutils}/bin/tr -d ' \n')
        tmp=$(${pkgs.coreutils}/bin/mktemp)
        ${pkgs.jq}/bin/jq --arg id "$vid" --arg p "${vault}" \
          '.vaults[$id] = {path: $p, open: true}' "$obsCfg" > "$tmp" \
          && run mv "$tmp" "$obsCfg"
      fi
      fi
    '';
  };
}
