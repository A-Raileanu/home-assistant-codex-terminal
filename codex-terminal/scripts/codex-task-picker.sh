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
# Shared confirmation gate appended to every actionable preset: Codex must
# summarise the proposed changes and wait for explicit approval before writing.
PROMPT_CONFIRM='Foarte important: înainte de a modifica orice pe /config, oprește-te și afișează-mi un sumar clar, sub formă de listă, cu toate modificările pe care intenționezi să le faci — pentru fiecare element arată ce se schimbă și din ce în ce. Apoi întreabă-mă explicit dacă vreau să le aplici exact așa sau vreau să ajustez ceva și așteaptă răspunsul meu. Nu scrie nimic pe /config înainte să confirm. Dacă cer modificări, actualizează sumarul și întreabă din nou până confirm.'

PROMPT_RENAME='Citește home-assistant/SKILL.md, ha-devices-areas.md, ha-entities.md și inventory.yaml. Apoi identifică toate device-urile și entitățile care nu respectă convenția: device-uri ca "[Area] Producător Model [#N]", iar friendly_name pe fiecare entitate ca "[Area] Nume dispozitiv - Funcție" (sau doar "[Area] Nume dispozitiv" pentru entitatea principală). Ignoră complet device-urile și entitățile care deja respectă convenția — nu le include în plan. '"$PROMPT_CONFIRM"' După ce confirm, aplică redenumirile folosind ha-safe-edit pentru orice scriere pe /config. La final, actualizează inventory.yaml cu o intrare nouă în change_log: și raportează lista a ce ai schimbat.'

PROMPT_NEW_DEVICE='Am adăugat unul sau mai multe dispozitive noi în Home Assistant și vreau să le aduc la convenție. Citește mai întâi home-assistant/SKILL.md, ha-devices-areas.md, ha-entities.md și inventory.yaml ca să cunoști convenția și ce există deja. Apoi ÎNTREABĂ-MĂ exact ce dispozitiv sau dispozitive am adăugat (nume/producător/model și în ce cameră) și AȘTEAPTĂ răspunsul meu — nu presupune și nu începe înainte să-ți spun. După ce îți dau numele, identifică device-urile respective în /config și pregătește planul de aducere la convenție DOAR pentru acelea, atât pentru device cât și pentru entitățile lui: device name ca "[Cameră] Producător Model [#N]" (folosește #N doar dacă mai există unul identic în aceeași cameră), atribuie label-ul de tip potrivit din lista canonică și setează friendly_name pe FIECARE entitate ca "[Cameră] Nume dispozitiv - Funcție" (sau doar "[Cameră] Nume dispozitiv" pentru entitatea principală). Include în plan și corectarea entity_id-urilor cu sufixe random la "<slug_cameră>_<funcție>", dezactivarea entităților auto-create pe care nu le folosești și orice automatizare/script/scenă/grup/helper/dashboard care trebuie actualizat. '"$PROMPT_CONFIRM"' După ce confirm, aplică modificările folosind ha-safe-edit pentru orice scriere pe /config. La final, adaugă device-urile noi în inventory.yaml (în devices: și o intrare nouă în change_log:) și raportează lista a ce ai schimbat.'

PROMPT_AUTOMATIONS='Citește home-assistant/SKILL.md și ha-automations.md. Apoi parcurge toate automatizările din /config (automations.yaml + fișierele din .storage/automation) și stabilește ce ajustări sunt necesare conform convențiilor: alias descriptiv în română cu diacritice, mode corect pentru tipul de trigger (restart pentru motion/timeouts, queued pentru secvențiale, parallel pentru per-entity independente, single doar pentru one-shot), description pe cele complexe, trigger IDs pe multi-trigger, condiții native în loc de template unde se poate. Ignoră complet automatizările care deja respectă convenția — nu le include în plan. '"$PROMPT_CONFIRM"' După ce confirm, aplică ajustările folosind ha-safe-edit pentru orice scriere. La final, raportează lista a ce ai schimbat.'

PROMPT_FIX='Citește home-assistant/SKILL.md, ha-automations.md, ha-dashboards.md și ha-refactoring.md. Apoi caută în automatizări (automations.yaml + .storage/automation) și în dashboard-uri (.storage/lovelace*, lovelace YAML mode dacă există) toate entitățile declarate greșit: entity_id-uri inexistente, sintaxă invalidă, referințe la integrări vechi care nu mai există, device_id-uri orfane. Pentru fiecare problemă găsită, pregătește corecția propusă (entity nou cu unique_id stabil, înlocuire entity_id, ștergere referință moartă). '"$PROMPT_CONFIRM"' După ce confirm, aplică corecțiile folosind ha-safe-edit. La final, raportează lista completă a entităților reparate și a referințelor șterse.'

TITLES=(
    "Sesiune nouă"
    "Am adăugat un dispozitiv nou"
    "Redenumește dispozitivele și senzorii"
    "Ajustează automatizările"
    "Repară referințele sparte"
)
DESCRIPTIONS=(
    "Pornește o conversație liberă cu Codex despre Home Assistant."
    "Spune-i ce dispozitiv ai adăugat și îl redenumește pe el și senzorii lui conform convenției."
    "Pune nume clare pe toate dispozitivele și senzorii. Sare peste ce arată deja bine."
    "Face ordine în automatizările tale. Sare peste cele care arată deja bine."
    "Caută în automatizări și dashboard-uri trimiterile spre dispozitive care nu mai există și le repară."
)
PROMPTS=(
    ""
    "$PROMPT_NEW_DEVICE"
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

    printf '  %s%s↑↓%s%s navighează    %s%s1-5%s%s salt rapid    %s%sEnter%s%s pornește    %s%sQ / Esc%s%s părăsește%s\n' \
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

main() {
    if tmux has-session -t "$TMUX_SESSION_NAME" 2>/dev/null; then
        exec tmux attach-session -t "$TMUX_SESSION_NAME"
    fi

    printf '\033[?25l'                                  # hide cursor
    stty -echo -icanon time 0 min 1 2>/dev/null || true

    render

    local key rest
    while true; do
        key=""
        rest=""
        IFS= read -rsn1 key
        if [ "$key" = $'\033' ]; then
            IFS= read -rsn2 -t 0.05 rest 2>/dev/null || true
            if [ -n "${rest}" ]; then
                key="${key}${rest}"
            fi
        fi

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
            ''|$'\n'|$'\r')
                launch_with_prompt "${PROMPTS[$SELECTED]}"
                ;;
            'q'|'Q')
                cleanup_term
                printf '\033[H\033[J'
                exit 0
                ;;
            [1-5])
                SELECTED=$((10#$key - 1))
                render
                sleep 0.1
                launch_with_prompt "${PROMPTS[$SELECTED]}"
                ;;
        esac
    done
}

main "$@"
