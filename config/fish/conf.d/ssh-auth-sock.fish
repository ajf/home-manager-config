# vim:filetype=fish

# An agent forwarded in over ssh wins: it belongs to the machine we came
# from, and clobbering it strands the session with keys it can't reach.
# Otherwise prefer the systemd-managed cert agent (step certs live there;
# ssh config routes 1Password explicitly per-host where its keys are
# wanted), then 1Password. Darwin's twin lives in the launchd setup.
if set -q SSH_CONNECTION; and test -S "$SSH_AUTH_SOCK"
	# forwarded agent — leave it
else if test -S "$XDG_RUNTIME_DIR/ssh-agent.socket"
	set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/ssh-agent.socket"
else if test -S "$HOME/.1password/agent.sock"
	set -gx SSH_AUTH_SOCK "$HOME/.1password/agent.sock"
end
