# vim:filetype=fish

# This variable is what ssh actually follows: ssh_config says
# `IdentityAgent SSH_AUTH_SOCK` for Host *, so git/GitHub and any unlisted
# host authenticate with whatever we pick here.
#
# An agent forwarded in over ssh wins — it belongs to the machine we came
# from, and clobbering it strands the session with keys it can't reach.
# Otherwise 1Password, which holds the regular keys and the signing key.
# The systemd cert agent is only a fallback: step certs live there, but the
# cert hosts pin it explicitly by path and `step-ssh-login` sets this
# variable itself, so nothing needs it to be the shell default.
# Darwin's twin lives in the launchd setup.
if set -q SSH_CONNECTION; and test -S "$SSH_AUTH_SOCK"
	# forwarded agent — leave it
else if test -S "$HOME/.1password/agent.sock"
	set -gx SSH_AUTH_SOCK "$HOME/.1password/agent.sock"
else if test -S "$XDG_RUNTIME_DIR/ssh-agent.socket"
	set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/ssh-agent.socket"
end
