OPENCODE_TERMUX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

alias opencode_web="$OPENCODE_TERMUX_DIR/bin/opencode-web.sh"
alias opencode_web_stop="$OPENCODE_TERMUX_DIR/bin/opencode-web-stop.sh"
alias termux_ssh="$OPENCODE_TERMUX_DIR/bin/termux-ssh.sh"
alias termux_ssh_stop="$OPENCODE_TERMUX_DIR/bin/termux-ssh-stop.sh"
