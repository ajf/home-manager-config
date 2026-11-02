{ config, lib, pkgs, ... }:

# SSH host trust: hosts presenting certs signed by a listed CA verify without
# TOFU prompts or known_hosts churn (reinstalls included), and pinned host keys
# (github.com by default) are known from the first connection. Both are written
# to known_hosts2 (a default secondary database) so the primary known_hosts
# stays mutable. CA keys are infra data, supplied by the per-machine identity
# flake.
let
  cas = config.dotfiles.ssh.hostCertAuthorities;
  hostKeys = config.dotfiles.ssh.knownHosts;
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

  options.dotfiles.ssh.knownHosts = lib.mkOption {
    type = lib.types.listOf (lib.types.submodule {
      options = {
        hosts = lib.mkOption {
          type = lib.types.str;
          example = "github.com";
          description = "Comma-separated host patterns the key belongs to.";
        };
        publicKey = lib.mkOption {
          type = lib.types.str;
          example = "ssh-ed25519 AAAA...";
          description = "The host public key: type and base64 blob.";
        };
      };
    });
    # github.com's three published host keys (ED25519 SHA256:+DiY3wvv…COqU, ECDSA
    # SHA256:p2QAMXNI…gUfQM, RSA SHA256:uNiVztks…D2s). All three, not just one: when
    # the server advertises keys the file lacks, OpenSSH (UpdateHostKeys) "learns"
    # them by rewriting the file, which replaces this read-only symlink with an
    # empty file. Check against https://api.github.com/meta before changing.
    default = [
      { hosts = "github.com"; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl"; }
      { hosts = "github.com"; publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg="; }
      { hosts = "github.com"; publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk="; }
    ];
    description = "Pinned SSH host keys, written to ~/.ssh/known_hosts2.";
  };

  config.home.file.".ssh/known_hosts2" = lib.mkIf (cas != [ ] || hostKeys != [ ]) {
    text =
      lib.concatMapStrings
        (ca: "@cert-authority ${ca.hosts} ${ca.publicKey}\n")
        cas
      + lib.concatMapStrings
        (k: "${k.hosts} ${k.publicKey}\n")
        hostKeys;
  };
}
