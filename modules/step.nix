{ config, lib, pkgs, ... }:

# smallstep client. The CLI is generic tooling (`step ssh login`, cert
# inspection) and is always installed; which CA to talk to is data, supplied
# by the per-machine identity flake through these options.
let
  cfg = config.dotfiles.step;
in
{
  options.dotfiles.step = {
    caUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "https://ca.example.com:9000";
      description = "step-ca URL; null skips writing ~/.step/config/defaults.json.";
    };
    fingerprint = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Root CA fingerprint recorded in defaults.json.";
    };
    rootCert = lib.mkOption {
      type = lib.types.nullOr lib.types.lines;
      default = null;
      description = "Root CA certificate (PEM), written to ~/.step/certs/root_ca.crt.";
    };
    sshProvisioner = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "kanidm";
      description = "Provisioner passed to `step ssh login` by the step-ssh-login function.";
    };
  };

  config = {
    home.packages = [ pkgs.step-cli ];

    # Declarative equivalent of `step ca bootstrap --ca-url ... --fingerprint ...`.
    home.file.".step/config/defaults.json" = lib.mkIf (cfg.caUrl != null) {
      text = builtins.toJSON (lib.filterAttrs (_: v: v != null) {
        ca-url = cfg.caUrl;
        fingerprint = cfg.fingerprint;
        # absolute on purpose: step does not expand ~ in defaults.json
        root = "${config.home.homeDirectory}/.step/certs/root_ca.crt";
      });
    };

    home.file.".step/certs/root_ca.crt" = lib.mkIf (cfg.rootCert != null) {
      text = cfg.rootCert;
    };

    # Desktop machines only: loads an SSH cert into the agent ssh actually
    # authenticates with — the systemd agent unit on Linux, the launchd
    # default agent on darwin. (1Password's agent can't hold certificates,
    # and interactive shells may point SSH_AUTH_SOCK at it.)
    programs.fish.functions.step-ssh-login =
      lib.mkIf (cfg.caUrl != null && config.dotfiles.desktop.enable) (
        (if pkgs.stdenv.isDarwin then ''
          set -l sock (launchctl getenv SSH_AUTH_SOCK)
          test -n "$sock"; or set sock $SSH_AUTH_SOCK
        '' else ''
          set -l sock $XDG_RUNTIME_DIR/ssh-agent.socket
        '') + ''
          SSH_AUTH_SOCK=$sock step ssh login ${config.home.username}${
            lib.optionalString (cfg.sshProvisioner != null)
              " --provisioner ${cfg.sshProvisioner}"} $argv
        ''
      );
  };
}
