# vim:filetype=fish

# Prefer the systemd-managed cert agent (step certs live there; ssh config
# routes 1Password explicitly per-host where its keys are wanted). Fall back
# to 1Password, else leave any inherited socket (e.g. a forwarded agent)
# untouched. Darwin's equivalent preference lives in the launchd setup.
if test -S "$XDG_RUNTIME_DIR/ssh-agent.socket"
	set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/ssh-agent.socket"
else if test -S "$HOME/.1password/agent.sock"
	set -gx SSH_AUTH_SOCK "$HOME/.1password/agent.sock"
end
