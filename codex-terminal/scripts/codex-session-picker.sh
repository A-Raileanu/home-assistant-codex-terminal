#!/bin/bash

TMUX_SESSION_NAME="codex"
CODEX_BASE_COMMAND="codex --cd /config"

if [ "${CODEX_HA_FULL_PERMISSIONS:-false}" = "true" ]; then
    CODEX_BASE_COMMAND="codex --dangerously-bypass-approvals-and-sandbox --cd /config"
fi

CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

show_banner() {
    clear
    echo ""
    echo -e "  ${CYAN}Codex Terminal${NC} ${DIM}- Session Picker${NC}"
    echo ""
}

check_existing_session() {
    tmux has-session -t "$TMUX_SESSION_NAME" 2>/dev/null
}

show_menu() {
    echo "Choose a Codex session:"
    echo ""
    if check_existing_session; then
        echo "  0) Reconnect to existing session"
        echo ""
    fi
    echo "  1) New interactive session"
    echo "  2) Resume most recent conversation"
    echo "  3) Resume from conversation list"
    echo "  4) Exit"
    echo ""
}

get_choice() {
    local default="1"
    local choice

    if check_existing_session; then
        default="0"
    fi

    printf "Enter choice [0-4] (default: %s): " "$default" >&2
    read -r choice
    [ -n "$choice" ] || choice="$default"
    echo "$choice" | tr -d '[:space:]'
}

replace_session() {
    if check_existing_session; then
        tmux kill-session -t "$TMUX_SESSION_NAME" 2>/dev/null
    fi
}

main() {
    while true; do
        show_banner
        show_menu
        choice="$(get_choice)"

        case "$choice" in
            0)
                if check_existing_session; then
                    exec tmux attach-session -t "$TMUX_SESSION_NAME"
                fi
                ;;
            1)
                replace_session
                exec tmux new-session -s "$TMUX_SESSION_NAME" "$CODEX_BASE_COMMAND"
                ;;
            2)
                replace_session
                exec tmux new-session -s "$TMUX_SESSION_NAME" "${CODEX_BASE_COMMAND} resume --last"
                ;;
            3)
                replace_session
                exec tmux new-session -s "$TMUX_SESSION_NAME" "${CODEX_BASE_COMMAND} resume"
                ;;
            4)
                exit 0
                ;;
            *)
                echo "Invalid choice"
                sleep 1
                ;;
        esac
    done
}

trap 'exit 0' EXIT INT TERM
main "$@"
