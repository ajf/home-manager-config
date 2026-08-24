# vim:filetype=fish

# Prefer the 1Password SSH agent when the app provides it (keys sync across
# machines); fall back to the systemd-managed ssh-agent unit.
if test -S "$HOME/.1password/agent.sock"
	set -gx SSH_AUTH_SOCK "$HOME/.1password/agent.sock"
else
	set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/ssh-agent.socket"

	if ! test -S $SSH_AUTH_SOCK
		echo "No SSH auth socket found @ $SSH_AUTH_SOCK, is systemd running the ssh-agent user unit?"
	end
end
