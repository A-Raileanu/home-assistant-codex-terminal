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
BLUE=$'\033[38;5;75m'
PURPLE=$'\033[38;5;141m'
WHITE=$'\033[38;5;254m'
GREY=$'\033[38;5;245m'
DARK_GREY=$'\033[38;5;240m'

ARROW='▶'
DOT='●'
BOX_WIDTH=88
declare -A PAD_CACHE=()

# ----- Preset prompts -----
# Shared confirmation gate appended to every actionable preset: Codex must
# summarise the proposed changes and wait for explicit approval before writing.
PROMPT_CONFIRM='Foarte important: înainte de a modifica orice pe /config, oprește-te și afișează-mi un sumar clar, sub formă de listă, cu toate modificările pe care intenționezi să le faci — pentru fiecare element arată ce se schimbă și din ce în ce. Apoi întreabă-mă explicit dacă vrei să pregătești planul tehnic sau vrei să ajustez ceva și așteaptă răspunsul meu. Nu scrie definitiv nimic pe /config înainte să confirm. După confirmarea planului conceptual, folosește `ha-safe-edit plan <file> -- <command...>` pentru fiecare fișier, arată diff-ul/plan_id-ul rezultat și cere confirmarea finală. Aplică doar după confirmarea finală cu `ha-safe-edit apply <plan_id>`. Dacă cer modificări, actualizează sumarul și întreabă din nou până confirm.'

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
    "Regenerează contextul"
)
DESCRIPTIONS=(
    "Conversație liberă despre HA."
    "Aduci un device nou la convenție."
    "Curăță numele care nu respectă regula."
    "Normalizează alias, mode și trigger-e."
    "Caută entități inexistente în config."
    "Citește din nou datele Home Assistant."
)
PROMPTS=(
    ""
    "$PROMPT_NEW_DEVICE"
    "$PROMPT_RENAME"
    "$PROMPT_AUTOMATIONS"
    "$PROMPT_FIX"
    "__REGENERATE_CONTEXT__"
)

COUNT=${#TITLES[@]}
SELECTED=0
SESSION_STATE="nouă"

ADDON_VER="$(cat /opt/scripts/addon-version 2>/dev/null || echo '?.?.?')"
CODEX_VER="$(codex --version 2>/dev/null | awk '{print $NF}' || echo 'n/a')"
FULL_PERMS="${CODEX_HA_FULL_PERMISSIONS:-true}"
CONTEXT_STATUS="nu există încă"

refresh_context_if_needed() {
    local refresh_minutes="${HA_CONTEXT_REFRESH_MINUTES:-30}"
    local pid frame status_file
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

    if command -v ha-context >/dev/null 2>&1; then
        status_file="/tmp/codex-ha-context-refresh.log"
        printf '\033[?25l'
        printf '\033[H\033[J'
        printf '\n\n'
        printf '  %s╭────────────────────────────────────────────────────────────╮%s\n' "$ACCENT_DIM" "$RESET"
        printf '  %s│%s  %s%sPregătesc contextul Home Assistant%s                    %s│%s\n' "$ACCENT_DIM" "$RESET" "$BOLD" "$WHITE" "$RESET" "$ACCENT_DIM" "$RESET"
        printf '  %s│%s  %sSe regenerează doar dacă este mai vechi de %s minute.%s  %s│%s\n' "$ACCENT_DIM" "$RESET" "$DIM$GREY" "$refresh_minutes" "$RESET" "$ACCENT_DIM" "$RESET"
        printf '  %s╰────────────────────────────────────────────────────────────╯%s\n\n' "$ACCENT_DIM" "$RESET"

        ha-context --refresh-minutes "$refresh_minutes" >"$status_file" 2>&1 &
        pid=$!
        frame=0
        while kill -0 "$pid" 2>/dev/null; do
            printf '\r  %s%s%s %sVerific datele instalării tale...%s' \
                "$ACCENT" "${frames[$((frame % ${#frames[@]}))]}" "$RESET" "$GREY" "$RESET"
            frame=$((frame + 1))
            sleep 0.08
        done

        if wait "$pid"; then
            printf '\r  %s✓%s %sContext pregătit.%s                         \n' "$GREEN" "$RESET" "$GREY" "$RESET"
        else
            printf '\r  %s!%s %sContextul nu a putut fi actualizat acum.%s\n' "$YELLOW" "$RESET" "$GREY" "$RESET"
        fi
        sleep 0.35
    fi
}

regenerate_context_now() {
    local status_file="/tmp/codex-ha-context-refresh.log"
    local pid frame
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

    printf '\033[?25l'
    printf '\033[H\033[J'
    printf '\n\n'
    printf '  %s╭────────────────────────────────────────────────────────────╮%s\n' "$ACCENT_DIM" "$RESET"
    printf '  %s│%s  %s%sRegenerez contextul Home Assistant%s                  %s│%s\n' "$ACCENT_DIM" "$RESET" "$BOLD" "$WHITE" "$RESET" "$ACCENT_DIM" "$RESET"
    printf '  %s│%s  %sCitesc entități, integrări, automatizări și erori.%s    %s│%s\n' "$ACCENT_DIM" "$RESET" "$DIM$GREY" "$RESET" "$ACCENT_DIM" "$RESET"
    printf '  %s╰────────────────────────────────────────────────────────────╯%s\n\n' "$ACCENT_DIM" "$RESET"

    if ! command -v ha-context >/dev/null 2>&1; then
        printf '  %s!%s %sha-context nu este disponibil.%s\n' "$YELLOW" "$RESET" "$GREY" "$RESET"
        sleep 1
        return 0
    fi

    ha-context --force >"$status_file" 2>&1 &
    pid=$!
    frame=0
    while kill -0 "$pid" 2>/dev/null; do
        printf '\r  %s%s%s %sActualizez contextul...%s' \
            "$ACCENT" "${frames[$((frame % ${#frames[@]}))]}" "$RESET" "$GREY" "$RESET"
        frame=$((frame + 1))
        sleep 0.08
    done

    if wait "$pid"; then
        printf '\r  %s✓%s %sContext regenerat.%s                         \n' "$GREEN" "$RESET" "$GREY" "$RESET"
    else
        printf '\r  %s!%s %sRegenerarea contextului a eșuat.%s          \n' "$YELLOW" "$RESET" "$GREY" "$RESET"
    fi
    sleep 0.8
}

update_context_status() {
    local manifest="/data/ha-context/manifest.json"
    local agents_md="${CODEX_HOME:-$HOME/.codex}/AGENTS.md"

    CONTEXT_STATUS="$(
        python3 - "$manifest" "$agents_md" <<'PY'
import json
import pathlib
import re
import sys
from datetime import datetime

manifest = pathlib.Path(sys.argv[1])
agents_md = pathlib.Path(sys.argv[2])
raw = ""

if manifest.exists():
    try:
        raw = json.loads(manifest.read_text(encoding="utf-8")).get("generated_at", "")
    except Exception:
        raw = ""

if not raw and agents_md.exists():
    match = re.search(r"^Last updated:\s*(.+)$", agents_md.read_text(encoding="utf-8", errors="replace"), re.M)
    if match:
        raw = match.group(1).strip()

if not raw:
    print("nu există încă")
    raise SystemExit

for fmt in ("%Y-%m-%dT%H:%M:%S%z", "%Y-%m-%d %H:%M:%S"):
    try:
        value = datetime.strptime(raw, fmt)
        print("actualizat la " + value.strftime("%d.%m.%Y %H:%M"))
        raise SystemExit
    except ValueError:
        pass

print("actualizat la " + raw)
PY
    )"
}

cleanup_term() {
    printf '\033[?25h'
    stty echo icanon 2>/dev/null || true
}
trap cleanup_term EXIT INT TERM

repeat_char() {
    local char="$1"
    local count="$2"
    local output=""

    while [ "$count" -gt 0 ]; do
        output="${output}${char}"
        count=$((count - 1))
    done

    printf '%s' "$output"
}

pad_text() {
    local text="$1"
    local target_width="$2"
    local cache_key="${target_width}|${text}"
    local padded

    if [ "${PAD_CACHE[$cache_key]+set}" = "set" ]; then
        printf '%s' "${PAD_CACHE[$cache_key]}"
        return 0
    fi

    padded="$(python3 - "$target_width" "$text" <<'PY'
import sys
import unicodedata

target = int(sys.argv[1])
text = sys.argv[2]

def cell_width(value: str) -> int:
    width = 0
    for char in value:
        if unicodedata.combining(char):
            continue
        if unicodedata.east_asian_width(char) in {"F", "W"}:
            width += 2
        else:
            width += 1
    return width

padding = max(target - cell_width(text), 0)
sys.stdout.write(text + (" " * padding))
PY
)"
    PAD_CACHE[$cache_key]="$padded"
    printf '%s' "$padded"
}

draw_rule() {
    local left="$1"
    local fill="$2"
    local right="$3"

    printf '  %s%s%s%s%s\n' "$ACCENT_DIM" "$left" "$(repeat_char "$fill" "$BOX_WIDTH")" "$right" "$RESET"
}

draw_box_text() {
    local text="$1"
    local color="${2:-$WHITE}"
    local padded

    padded="$(pad_text "$text" "$((BOX_WIDTH - 2))")"
    printf '  %s│%s %s%s%s %s│%s\n' "$ACCENT_DIM" "$RESET" "$color" "$padded" "$RESET" "$ACCENT_DIM" "$RESET"
}

intro_animation() {
    local i fill rest

    printf '\033[?25l'
    for ((i = 0; i <= 18; i++)); do
        fill="$(repeat_char '━' "$i")"
        rest="$(repeat_char '─' "$((18 - i))")"
        printf '\033[H\033[J'
        printf '\n\n'
        printf '  %s%sCodex Terminal%s\n\n' "$BOLD" "$WHITE" "$RESET"
        printf '  %s[%s%s%s%s]%s  %sHome Assistant workspace%s\n' \
            "$DARK_GREY" "$ACCENT" "$fill" "$DARK_GREY" "$rest" "$RESET" "$GREY" "$RESET"
        sleep 0.025
    done
}

draw_banner() {
    printf '\n'
    draw_rule '╭' '─' '╮'
    draw_box_text "Codex Terminal pentru Home Assistant" "$BOLD$WHITE"
    draw_box_text "Automatizări, YAML, dashboard-uri și depanare direct din /config" "$GREY"
    draw_rule '├' '─' '┤'
    draw_box_text "Add-on v${ADDON_VER}  ·  Codex ${CODEX_VER}  ·  /config" "$ACCENT"
    draw_rule '╰' '─' '╯'
}

draw_status() {
    local perms_marker perms_color perms_label session_color
    if [ "$FULL_PERMS" = "true" ]; then
        perms_marker="$DOT"
        perms_color="$YELLOW"
        perms_label="Permisiuni automate: pornite"
    else
        perms_marker="$DOT"
        perms_color="$GREEN"
        perms_label="Permisiuni automate: oprite (Codex va cere aprobare)"
    fi

    if [ "$SESSION_STATE" = "activă" ]; then
        session_color="$GREEN"
    else
        session_color="$BLUE"
    fi

    printf '\n'
    printf '  %s%s%s %s%s%s\n' "$perms_color" "$perms_marker" "$RESET" "$GREY" "$perms_label" "$RESET"
    printf '  %s%s%s %sSesiune terminal:%s %scodex%s %s(%s)%s\n' \
        "$session_color" "$DOT" "$RESET" "$GREY" "$RESET" "$BOLD$WHITE" "$RESET" "$DIM$GREY" "$SESSION_STATE" "$RESET"
    printf '  %s%s%s %sContext:%s %s%s%s\n' \
        "$ACCENT" "$DOT" "$RESET" "$GREY" "$RESET" "$DIM$GREY" "$CONTEXT_STATUS" "$RESET"
}

draw_menu_item() {
    local index="$1"
    local title="$2"
    local description="$3"
    local marker num_color title_color desc_color border_color
    local title_padded desc_padded

    if [ "$((index - 1))" -eq "$SELECTED" ]; then
        marker="${ARROW}"
        num_color="${BOLD}${ACCENT}"
        title_color="${BOLD}${WHITE}"
        desc_color="${ACCENT_DIM}"
        border_color="$ACCENT"
    else
        marker=" "
        num_color="${DIM}${GREY}"
        title_color="${WHITE}"
        desc_color="${DIM}${GREY}"
        border_color="$DARK_GREY"
    fi

    title_padded="$(pad_text "$title" "$((BOX_WIDTH - 7))")"
    desc_padded="$(pad_text "$description" "$((BOX_WIDTH - 6))")"

    printf '  %s│%s %s%s%s %s%2d%s  %s%s%s%s│%s\n' \
        "$border_color" "$RESET" "$ACCENT" "$marker" "$RESET" \
        "$num_color" "$index" "$RESET" \
        "$title_color" "$title_padded" "$RESET" "$border_color" "$RESET"
    printf '  %s│%s      %s%s%s%s│%s\n' \
        "$border_color" "$RESET" "$desc_color" "$desc_padded" "$RESET" "$border_color" "$RESET"
}

draw_footer() {
    printf '\n'
    printf '  %s↑↓%s navighează   %s1-%d%s salt rapid   %sEnter%s pornește   %sQ / Esc%s părăsește\n' \
        "$ACCENT" "$GREY" "$ACCENT" "$COUNT" "$GREY" "$ACCENT" "$GREY" "$ACCENT" "$RESET"
}

draw_menu() {
    local i

    printf '\n  %s%sAlege o acțiune%s\n' "$BOLD" "$WHITE" "$RESET"
    printf '  %s┌%s┐%s\n' "$DARK_GREY" "$(repeat_char '─' "$BOX_WIDTH")" "$RESET"

    for ((i = 0; i < COUNT; i++)); do
        draw_menu_item "$((i + 1))" "${TITLES[$i]}" "${DESCRIPTIONS[$i]}"
    done

    printf '  %s└%s┘%s\n' "$DARK_GREY" "$(repeat_char '─' "$BOX_WIDTH")" "$RESET"
    draw_footer
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

    case "$prompt" in
        "__ATTACH__")
            cleanup_term
            exec tmux attach-session -t "$TMUX_SESSION_NAME"
            ;;
        "__REGENERATE_CONTEXT__")
            regenerate_context_now
            update_context_status
            render
            return
            ;;
        "__RESTART__")
            restart_terminal
            ;;
    esac

    cleanup_term
    if [ -n "$prompt" ]; then
        cmd="${CODEX_BASE_COMMAND} $(printf '%q' "$prompt")"
    else
        cmd="$CODEX_BASE_COMMAND"
    fi
    show_launching
    exec tmux new-session -s "$TMUX_SESSION_NAME" "$cmd"
}

restart_terminal() {
    cleanup_term
    printf '\033[H\033[J'
    printf '\n  %s%sRepornește terminalul...%s\n\n' "$BOLD" "$WHITE" "$RESET"
    tmux kill-session -t "$TMUX_SESSION_NAME" 2>/dev/null || true
    exec "$0"
}

configure_menu() {
    if tmux has-session -t "$TMUX_SESSION_NAME" 2>/dev/null; then
        TITLES=(
            "Continuă sesiunea deschisă"
            "Regenerează contextul"
            "Repornește terminalul"
        )
        DESCRIPTIONS=(
            "Revii la conversația deja pornită."
            "Citește din nou datele Home Assistant."
            "Închide sesiunea și revine la meniu."
        )
        PROMPTS=(
            "__ATTACH__"
            "__REGENERATE_CONTEXT__"
            "__RESTART__"
        )
        COUNT=${#TITLES[@]}
        SESSION_STATE="activă"
    else
        SESSION_STATE="nouă"
    fi
}

main() {
    refresh_context_if_needed
    update_context_status
    configure_menu
    intro_animation

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
            [1-9])
                if [ "$key" -ge 1 ] && [ "$key" -le "$COUNT" ]; then
                    SELECTED=$((10#$key - 1))
                    render
                    sleep 0.1
                    launch_with_prompt "${PROMPTS[$SELECTED]}"
                fi
                ;;
        esac
    done
}

main "$@"
