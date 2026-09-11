{ config, lib, pkgs, ... }:

# SSH host-CA trust: hosts presenting certs signed by a listed CA verify
# without TOFU prompts or known_hosts churn (reinstalls included). Written to
# known_hosts2 (a default secondary database) so the primary known_hosts stays
# mutable. CA keys are infra data, supplied by the per-machine identity flake.
let
  cas = config.dotfiles.ssh.hostCertAuthorities;
in
{
  options.dotfiles.ssh.hostCertAuthorities = lib.mkOption {
    type = lib.types.listOf (lib.types.submodule {
      options = {
        hosts = lib.mkOption {
          type = lib.types.str;
          example = "*.example.com,10.0.0.*";
          description = "Comma-separated host patterns the CA may vouch for.";
        };
        publicKey = lib.mkOption {
          type = lib.types.str;
          example = "ecdsa-sha2-nistp256 AAAA... my-host-ca";
          description = "The CA public key: type, base64 blob, optional comment.";
        };
      };
    });
    default = [ ];
    description = "SSH host certificate authorities to trust via ~/.ssh/known_hosts2.";
  };

  # The local agent that holds step certificates (1Password's agent can't):
  # the systemd user unit on Linux (linux.nix), a launchd agent on darwin
  # (darwin.nix). step-ssh-login loads into it; identity ssh configs point
  # cert-auth hosts at it via IdentityAgent.
  options.dotfiles.ssh.certAgentSocket = lib.mkOption {
    type = lib.types.str;
    default =
      if pkgs.stdenv.isDarwin
      then "${config.home.homeDirectory}/.ssh/agent.sock"
      else "/run/user/1000/ssh-agent.socket";
    description = "Socket of the local cert-holding ssh-agent.";
  };

  config.home.file.".ssh/known_hosts2" = lib.mkIf (cas != [ ]) {
    text = lib.concatMapStrings
      (ca: "@cert-authority ${ca.hosts} ${ca.publicKey}\n")
      cas;
  };
}
