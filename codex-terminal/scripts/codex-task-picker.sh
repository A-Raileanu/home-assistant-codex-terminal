#!/bin/bash

set -uo pipefail

TMUX_SESSION_NAME="codex"
CODEX_BASE_COMMAND="codex --cd /config"

if [ "${CODEX_HA_FULL_PERMISSIONS:-true}" = "true" ]; then
    CODEX_BASE_COMMAND="codex --dangerously-bypass-approvals-and-sandbox --cd /config"
fi

# ----- Theme (ANSI) -----
RESET=$'\033[0m'
BOLD=$'\033[1m'
DIM=$'\033[2m'

ACCENT=$'\033[38;5;51m'        # bright cyan (matches ttyd theme)
ACCENT_DIM=$'\033[38;5;38m'    # darker cyan
GREEN=$'\033[38;5;42m'         # success green
YELLOW=$'\033[38;5;221m'       # warning yellow
WHITE=$'\033[38;5;254m'
GREY=$'\033[38;5;245m'
DARK_GREY=$'\033[38;5;240m'

ARROW='▶'
DOT='●'

# ----- Preset prompts -----
PROMPT_RENAME='Citește home-assistant/SKILL.md, ha-devices-areas.md, ha-entities.md și inventory.yaml. Apoi redenumește toate device-urile și entitățile conform convenției: device-uri ca "[Area] Producător Model [#N]", iar friendly_name pe fiecare entitate ca "[Area] Nume dispozitiv - Funcție" (sau doar "[Area] Nume dispozitiv" pentru entitatea principală). Ignoră complet device-urile și entitățile care deja respectă convenția — nu modifica nimic acolo. Folosește ha-safe-edit pentru orice scriere pe /config. La final, actualizează inventory.yaml cu o intrare nouă în change_log: și raportează lista a ce ai schimbat.'

PROMPT_AUTOMATIONS='Citește home-assistant/SKILL.md și ha-automations.md. Apoi parcurge toate automatizările din /config (automations.yaml + fișierele din .storage/automation) și ajustează-le conform convențiilor: alias descriptiv în română cu diacritice, mode corect pentru tipul de trigger (restart pentru motion/timeouts, queued pentru secvențiale, parallel pentru per-entity independente, single doar pentru one-shot), description pe cele complexe, trigger IDs pe multi-trigger, condiții native în loc de template unde se poate. Ignoră complet automatizările care deja respectă convenția — nu modifica nimic acolo. Folosește ha-safe-edit pentru orice scriere. La final, raportează lista a ce ai schimbat.'

PROMPT_FIX='Citește home-assistant/SKILL.md, ha-automations.md, ha-dashboards.md și ha-refactoring.md. Apoi caută în automatizări (automations.yaml + .storage/automation) și în dashboard-uri (.storage/lovelace*, lovelace YAML mode dacă există) toate entitățile declarate greșit: entity_id-uri inexistente, sintaxă invalidă, referințe la integrări vechi care nu mai există, device_id-uri orfane. Pentru fiecare problemă găsită, propune corecția (entity nou cu unique_id stabil, înlocuire entity_id, ștergere referință moartă) și aplica-o folosind ha-safe-edit. La final, raportează lista completă a entităților reparate și a referințelor șterse.'

TITLES=(
    "Sesiune nouă"
    "Redenumește device-uri și entități"
    "Ajustează automatizările"
    "Repară automatizări + dashboard-uri"
)
DESCRIPTIONS=(
    "Codex pornește fără prompt prestabilit. Conversație liberă."
    "Aplică [Area] Producător Model · friendly_name [Area] Nume - Funcție. Idempotent."
    "Refactorizează alias, mode, description, trigger IDs. Idempotent."
    "Entități declarate greșit, referințe moarte, integrări vechi."
)
PROMPTS=(
    ""
    "$PROMPT_RENAME"
    "$PROMPT_AUTOMATIONS"
    "$PROMPT_FIX"
)

COUNT=${#TITLES[@]}
SELECTED=0

ADDON_VER="$(cat /opt/scripts/addon-version 2>/dev/null || echo '?.?.?')"
CODEX_VER="$(codex --version 2>/dev/null | awk '{print $NF}' || echo 'n/a')"
FULL_PERMS="${CODEX_HA_FULL_PERMISSIONS:-true}"

cleanup_term() {
    printf '\033[?25h'
    stty echo icanon 2>/dev/null || true
}
trap cleanup_term EXIT INT TERM

draw_banner() {
    printf '\n'
    printf '  %s▌%s  %s%sCodex Terminal%s %s— Home Assistant Add-on%s\n' \
        "$ACCENT" "$RESET" "$BOLD" "$ACCENT" "$RESET" "$WHITE" "$RESET"
    printf '  %s▌%s  %sv%s · codex %s%s\n' \
        "$ACCENT" "$RESET" "$DIM$GREY" "$ADDON_VER" "$CODEX_VER" "$RESET"
}

draw_status() {
    local perms_marker perms_color perms_label
    if [ "$FULL_PERMS" = "true" ]; then
        perms_marker="$DOT"
        perms_color="$GREEN"
        perms_label="Full permissions: ON"
    else
        perms_marker="$DOT"
        perms_color="$YELLOW"
        perms_label="Full permissions: OFF (Codex va cere aprobare)"
    fi
    printf '\n  %s%s%s %s%s%s     %s%s%s %sSesiune tmux: %scodex%s%s (nouă)%s\n' \
        "$perms_color" "$perms_marker" "$RESET" \
        "$DIM$GREY" "$perms_label" "$RESET" \
        "$ACCENT_DIM" "$DOT" "$RESET" "$DIM$GREY" "$BOLD$WHITE" "$RESET" "$DIM$GREY" "$RESET"
}

draw_menu() {
    printf '\n  %s%sSelectează ce vrei să faci:%s\n\n' "$BOLD" "$WHITE" "$RESET"

    local i marker num_color title_color desc_color desc_line
    for ((i = 0; i < COUNT; i++)); do
        if [ "$i" -eq "$SELECTED" ]; then
            marker="${ACCENT}${BOLD}${ARROW}${RESET}"
            num_color="${BOLD}${ACCENT}"
            title_color="${BOLD}${ACCENT}"
            desc_color="${ACCENT_DIM}"
        else
            marker=" "
            num_color="${DIM}${GREY}"
            title_color="${WHITE}"
            desc_color="${DIM}${GREY}"
        fi
        printf '  %s  %s%d.%s  %s%s%s\n' \
            "$marker" "$num_color" "$((i + 1))" "$RESET" "$title_color" "${TITLES[$i]}" "$RESET"
        printf '       %s%s%s\n\n' "$desc_color" "${DESCRIPTIONS[$i]}" "$RESET"
    done

    printf '  %s%s↑↓%s%s navighează    %s%s1-4%s%s salt rapid    %s%sEnter%s%s pornește    %s%sQ / Esc%s%s părăsește%s\n' \
        "$BOLD" "$ACCENT" "$RESET" "${DIM}${GREY}" \
        "$BOLD" "$ACCENT" "$RESET" "${DIM}${GREY}" \
        "$BOLD" "$ACCENT" "$RESET" "${DIM}${GREY}" \
        "$BOLD" "$ACCENT" "$RESET" "${DIM}${GREY}" "$RESET"
}

render() {
    # Cursor home + clear screen (smoother than `clear`, no flicker in ttyd)
    printf '\033[H\033[J'
    draw_banner
    draw_status
    draw_menu
}

show_launching() {
    printf '\033[H\033[J'
    printf '\n\n'
    printf '  %s%s%s%s  %s%s%s\n\n' "$ACCENT" "$BOLD" "$ARROW" "$RESET" "$BOLD$WHITE" "${TITLES[$SELECTED]}" "$RESET"
    printf '  %s%sInițializare sesiune tmux...%s\n\n' "$DIM" "$GREY" "$RESET"
}

launch_with_prompt() {
    local prompt="$1"
    local cmd
    cleanup_term
    if [ -n "$prompt" ]; then
        cmd="${CODEX_BASE_COMMAND} $(printf '%q' "$prompt")"
    else
        cmd="$CODEX_BASE_COMMAND"
    fi
    show_launching
    exec tmux new-session -s "$TMUX_SESSION_NAME" "$cmd"
}

read_key() {
    local key rest
    IFS= read -rsn1 key
    if [ "$key" = $'\033' ]; then
        IFS= read -rsn2 -t 0.05 rest 2>/dev/null || true
        if [ -n "${rest:-}" ]; then
            key="${key}${rest}"
        fi
    fi
    printf '%s' "$key"
}

main() {
    if tmux has-session -t "$TMUX_SESSION_NAME" 2>/dev/null; then
        exec tmux attach-session -t "$TMUX_SESSION_NAME"
    fi

    printf '\033[?25l'                                  # hide cursor
    stty -echo -icanon time 0 min 1 2>/dev/null || true

    render

    while true; do
        local key
        key="$(read_key)"
        case "$key" in
            $'\033[A')
                SELECTED=$(((SELECTED - 1 + COUNT) % COUNT))
                render
                ;;
            $'\033[B')
                SELECTED=$(((SELECTED + 1) % COUNT))
                render
                ;;
            $'\033')
                cleanup_term
                printf '\033[H\033[J'
                exit 0
                ;;
            $'\n'|$'\r')
                launch_with_prompt "${PROMPTS[$SELECTED]}"
                ;;
            'q'|'Q')
                cleanup_term
                printf '\033[H\033[J'
                exit 0
                ;;
            [1-4])
                SELECTED=$((10#$key - 1))
                render
                sleep 0.1
                launch_with_prompt "${PROMPTS[$SELECTED]}"
                ;;
        esac
    done
}

main "$@"
