#!/bin/bash

set -uo pipefail
export LC_ALL="${LC_ALL:-C.UTF-8}"

TMUX_SESSION_NAME="codex"
CODEX_WORKDIR="/config"

# Culori ANSI
RESET=$'\033[0m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
ACCENT=$'\033[38;5;51m'
ACCENT_DIM=$'\033[38;5;38m'
GREEN=$'\033[38;5;42m'
YELLOW=$'\033[38;5;221m'
BLUE=$'\033[38;5;75m'
WHITE=$'\033[38;5;254m'
GREY=$'\033[38;5;245m'
DARK_GREY=$'\033[38;5;240m'
ARROW='▶'
DOT='●'

# Cereri prestabilite
PROMPT_CONFIRM='Foarte important: înainte să modifici ceva în /config, oprește-te și arată-mi o listă clară cu toate schimbările propuse. Pentru fiecare element, spune ce există acum și cum va arăta după schimbare. Apoi întreabă-mă dacă vreau să pregătești planul tehnic sau dacă vreau să ajustez propunerea și așteaptă răspunsul meu. Nu scrie nimic definitiv în /config înainte să confirm. După ce confirm propunerea, folosește `ha-safe-edit plan <fișier> -- <comandă...>` pentru fiecare fișier, arată diferențele și identificatorul planului, apoi cere confirmarea finală. Aplică schimbările numai după confirmarea finală, cu `ha-safe-edit apply <plan_id>`. Dacă cer modificări, actualizează lista și cere din nou confirmarea.'

PROMPT_RENAME='Citește skill-ul home-assistant și ghidurile pentru dispozitive și entități. Rulează `python "$CODEX_HOME/skills/home-assistant/scripts/ha_rename_audit.py" --pending` sau folosește `/data/ha-context/rename_memory.json` dacă scriptul nu există. Găsește numai dispozitivele și entitățile care nu respectă regula: numele dispozitivului trebuie să fie „[Cameră] Producător Model [#N]”, iar `friendly_name` trebuie să fie „[Cameră] Nume dispozitiv - Funcție” sau doar „[Cameră] Nume dispozitiv” pentru entitatea principală. Nu include elementele care respectă deja regula sau au `skip_rename_by_default=true`, decât dacă cer explicit acest lucru. '"$PROMPT_CONFIRM"' După confirmare, folosește ha-safe-edit pentru orice scriere în /config. La final, rulează `ha-context --force`, verifică memoria de redenumire și arată exact ce ai schimbat.'

PROMPT_NEW_DEVICE='Am adăugat unul sau mai multe dispozitive în Home Assistant și vreau să le configurez corect. Citește skill-ul home-assistant și ghidurile pentru dispozitive și entități. Întreabă-mă ce dispozitiv am adăugat, inclusiv numele, producătorul, modelul și camera, apoi așteaptă răspunsul meu. După ce răspund, rulează `python "$CODEX_HOME/skills/home-assistant/scripts/ha_rename_audit.py" --query <nume-sau-model>` sau folosește memoria din /data/ha-context. Pregătește schimbări numai pentru dispozitivele indicate și entitățile lor: nume de forma „[Cameră] Producător Model [#N]”, eticheta potrivită și `friendly_name` complet pentru fiecare entitate. Nu modifica din nou elementele deja corecte sau marcate cu `skip_rename_by_default=true`, decât dacă cer explicit. Include și corectarea identificatorilor cu sufixe aleatorii, dezactivarea entităților create automat care nu sunt folosite și actualizarea tuturor referințelor afectate. '"$PROMPT_CONFIRM"' După confirmare, folosește ha-safe-edit pentru orice scriere în /config. La final, rulează `ha-context --force`, verifică memoria de redenumire și arată exact ce ai schimbat.'

PROMPT_AUTOMATIONS='Citește skill-ul home-assistant și ghidul pentru automatizări. Verifică automatizările din `automations.yaml` și din `.storage/automation`. Propune schimbări numai unde sunt necesare: nume clare în română, `mode` potrivit, descriere pentru automatizările complexe, identificatori pentru declanșatoare multiple și condiții native în locul șabloanelor când este posibil. Nu include automatizările care sunt deja corecte. '"$PROMPT_CONFIRM"' După confirmare, folosește ha-safe-edit pentru orice scriere și arată lista completă a schimbărilor.'

PROMPT_FIX='Citește skill-ul home-assistant și ghidurile pentru automatizări, panouri și refactorizare. Pentru identificatorii suspecți, rulează `python "$CODEX_HOME/skills/home-assistant/scripts/ha_reference_scan.py" <entity_id>`. Verifică automatizările și panourile pentru entități inexistente, sintaxă greșită, integrări eliminate și identificatori de dispozitiv fără corespondent. Pentru fiecare problemă, propune soluția clară: înlocuirea identificatorului, crearea unei entități stabile sau eliminarea referinței nefolosite. '"$PROMPT_CONFIRM"' După confirmare, folosește ha-safe-edit și arată lista completă a elementelor reparate sau eliminate.'

declare -a TITLES=() DESCRIPTIONS=() ACTIONS=()
declare -a PADDED_TITLES=() PADDED_DESCRIPTIONS=() PADDED_BANNER=()
COUNT=0
SELECTED=0
MENU_KIND="main"
SESSION_LABEL="nouă"
LAYOUT_DIRTY=1
BOX_WIDTH=88
MENU_FIRST_ROW=1
REST_ROW=1
RENDERED_BLOCK=""

ADDON_VER="$(cat /opt/scripts/addon-version 2>/dev/null || echo '?.?.?')"
if command -v codex >/dev/null 2>&1; then
    CODEX_VER="$(codex --version 2>/dev/null | awk '{print $NF}')"
    CODEX_VER="${CODEX_VER:-indisponibil}"
else
    CODEX_VER="indisponibil"
fi
FULL_PERMS="${CODEX_HA_FULL_PERMISSIONS:-true}"
MCP_MODE="${CODEX_HA_MCP_MODE:-necunoscut}"
CONTEXT_STATUS="nu există"
AUTH_STATUS="necesară"
LAYOUT_HELPER="${CODEX_PICKER_LAYOUT_HELPER:-/opt/scripts/codex-picker-layout.py}"
ESC_TIMEOUT=1
READ_TIMEOUT=1

if [ "${BASH_VERSINFO[0]}" -ge 4 ]; then
    ESC_TIMEOUT=0.03
    READ_TIMEOUT=0.1
fi

if [ ! -f "$LAYOUT_HELPER" ]; then
    LAYOUT_HELPER="$(dirname "${BASH_SOURCE[0]}")/codex-picker-layout.py"
fi

if [ -s "${CODEX_HOME:-$HOME/.codex}/auth.json" ] || [ -n "${OPENAI_API_KEY:-}" ]; then
    AUTH_STATUS="gata"
fi

cleanup_term() {
    printf '\033[?25h'
    stty echo icanon 2>/dev/null || true
}

on_winch() {
    LAYOUT_DIRTY=1
}

trap cleanup_term EXIT INT TERM
trap on_winch WINCH

update_context_status() {
    local manifest="/data/ha-context/manifest.json"
    local agents_md="${CODEX_HOME:-$HOME/.codex}/AGENTS.md"
    CONTEXT_STATUS="$(python3 - "$manifest" "$agents_md" <<'PY'
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
        pass
if not raw and agents_md.exists():
    match = re.search(
        r"^Last updated:\s*(.+)$",
        agents_md.read_text(encoding="utf-8", errors="replace"),
        re.M,
    )
    if match:
        raw = match.group(1).strip()
if not raw:
    print("nu există")
else:
    try:
        print(datetime.fromisoformat(raw.replace("Z", "+00:00")).strftime("%d.%m.%Y %H:%M"))
    except ValueError:
        print(raw)
PY
)"
}

configure_main_menu() {
    MENU_KIND="main"
    SELECTED=0
    if tmux has-session -t "$TMUX_SESSION_NAME" 2>/dev/null; then
        SESSION_LABEL="activă"
        TITLES=(
            "Continuă conversația"
            "Începe o conversație nouă"
            "Reia o conversație anterioară"
            "Instrumente"
        )
        DESCRIPTIONS=(
            "Revii imediat la conversația deschisă."
            "Închide conversația activă și pornește una nouă."
            "Închide conversația activă și deschide lista salvată."
            "Actualizare, verificare și diagnostic."
        )
        ACTIONS=("__ATTACH__" "__NEW__" "__RESUME__" "__TOOLS__")
    else
        SESSION_LABEL="nouă"
        TITLES=(
            "Începe o conversație nouă"
            "Reia o conversație anterioară"
            "Configurează un dispozitiv nou"
            "Verifică numele dispozitivelor"
            "Verifică automatizările"
            "Repară referințele greșite"
            "Instrumente"
        )
        DESCRIPTIONS=(
            "Deschide Codex fără o cerere prestabilită."
            "Alege o conversație salvată de Codex."
            "Pregătește corect un dispozitiv adăugat recent."
            "Găsește și corectează numai numele neclare."
            "Corectează numele, regulile și modul de rulare."
            "Găsește entități lipsă și legături care nu mai merg."
            "Actualizare, verificare și diagnostic."
        )
        ACTIONS=(
            "__NEW__"
            "__RESUME__"
            "$PROMPT_NEW_DEVICE"
            "$PROMPT_RENAME"
            "$PROMPT_AUTOMATIONS"
            "$PROMPT_FIX"
            "__TOOLS__"
        )
    fi
    COUNT=${#TITLES[@]}
    LAYOUT_DIRTY=1
}

configure_tools_menu() {
    MENU_KIND="tools"
    SELECTED=0
    TITLES=(
        "Actualizează datele Home Assistant"
        "Verifică fișierele Home Assistant"
        "Rulează diagnosticul complet"
        "Arată conexiunile MCP"
        "Înapoi"
    )
    DESCRIPTIONS=(
        "Citește din nou entitățile, integrările și erorile."
        "Verifică fișierele YAML și configurația Home Assistant."
        "Verifică programele, accesul, skill-urile și siguranța."
        "Arată serverele MCP cunoscute de Codex."
        "Revino la conversații și acțiuni."
    )
    ACTIONS=("__REFRESH__" "__CHECK__" "__DOCTOR__" "__MCP__" "__BACK__")
    COUNT=${#TITLES[@]}
    LAYOUT_DIRTY=1
}

detect_box_width() {
    local columns=0 rows=0
    read -r rows columns < <(stty size 2>/dev/null || true)
    : "$rows"
    if ! [[ "$columns" =~ ^[0-9]+$ ]] || [ "$columns" -lt 20 ]; then
        columns="${COLUMNS:-92}"
    fi
    if [ "$columns" -gt 92 ]; then
        BOX_WIDTH=88
    elif [ "$columns" -ge 32 ]; then
        BOX_WIDTH=$((columns - 4))
    else
        BOX_WIDTH=28
    fi
}

prepare_layout() {
    local -a values=()
    local banner_count=3
    local value
    detect_box_width
    while IFS= read -r value; do
        values+=("$value")
    done < <(
        python3 "$LAYOUT_HELPER" "$BOX_WIDTH" "$banner_count" "$COUNT" \
            "Codex Terminal pentru Home Assistant" \
            "Automatizări, fișiere YAML, panouri și depanare direct din /config" \
            "Aplicație v${ADDON_VER}  ·  Codex ${CODEX_VER}  ·  /config" \
            "${TITLES[@]}" -- "${DESCRIPTIONS[@]}"
    )
    PADDED_BANNER=("${values[@]:0:banner_count}")
    PADDED_TITLES=("${values[@]:banner_count:COUNT}")
    PADDED_DESCRIPTIONS=("${values[@]:banner_count+COUNT:COUNT}")
    LAYOUT_DIRTY=0
}

repeat_rule() {
    local output
    printf -v output '%*s' "$1" ''
    printf '%s' "${output// /─}"
}

render_item_block() {
    local index="$1"
    local selected="$2"
    local marker num_color title_color desc_color border_color line1 line2
    if [ "$selected" = "true" ]; then
        marker="$ARROW"; num_color="$BOLD$ACCENT"; title_color="$BOLD$WHITE"
        desc_color="$ACCENT_DIM"; border_color="$ACCENT"
    else
        marker=" "; num_color="$DIM$GREY"; title_color="$WHITE"
        desc_color="$DIM$GREY"; border_color="$DARK_GREY"
    fi
    printf -v line1 '  %s│%s %s%s%s %s%2d%s  %s%s%s%s│%s' \
        "$border_color" "$RESET" "$ACCENT" "$marker" "$RESET" \
        "$num_color" "$((index + 1))" "$RESET" "$title_color" \
        "${PADDED_TITLES[$index]}" "$RESET" "$border_color" "$RESET"
    printf -v line2 '  %s│%s      %s%s%s%s│%s' \
        "$border_color" "$RESET" "$desc_color" \
        "${PADDED_DESCRIPTIONS[$index]}" "$RESET" "$border_color" "$RESET"
    RENDERED_BLOCK="${line1}"$'\n'"${line2}"
}

render_full() {
    local screen=$'\033[?25l\033[H\033[J'
    local fill row=0 i
    if [ "$LAYOUT_DIRTY" -eq 1 ]; then
        prepare_layout
    fi
    fill="$(repeat_rule "$BOX_WIDTH")"
    append_line() { screen+="$1"$'\n'; row=$((row + 1)); }

    append_line ""
    append_line "  ${ACCENT_DIM}╭${fill}╮${RESET}"
    append_line "  ${ACCENT_DIM}│${RESET} ${BOLD}${WHITE}${PADDED_BANNER[0]}${RESET} ${ACCENT_DIM}│${RESET}"
    append_line "  ${ACCENT_DIM}│${RESET} ${GREY}${PADDED_BANNER[1]}${RESET} ${ACCENT_DIM}│${RESET}"
    append_line "  ${ACCENT_DIM}├${fill}┤${RESET}"
    append_line "  ${ACCENT_DIM}│${RESET} ${ACCENT}${PADDED_BANNER[2]}${RESET} ${ACCENT_DIM}│${RESET}"
    append_line "  ${ACCENT_DIM}╰${fill}╯${RESET}"
    append_line ""
    append_line "  ${GREEN}${DOT}${RESET} ${GREY}Autentificare:${RESET} ${WHITE}${AUTH_STATUS}${RESET}"
    append_line "  ${BLUE}${DOT}${RESET} ${GREY}Conversație:${RESET} ${WHITE}${SESSION_LABEL}${RESET}"
    append_line "  ${ACCENT}${DOT}${RESET} ${GREY}Date Home Assistant:${RESET} ${WHITE}${CONTEXT_STATUS}${RESET}"
    if [ "$FULL_PERMS" = "true" ]; then
        append_line "  ${YELLOW}${DOT}${RESET} ${GREY}Confirmări:${RESET} ${WHITE}dezactivate${RESET}  ${GREY}· MCP: ${MCP_MODE}${RESET}"
    else
        append_line "  ${GREEN}${DOT}${RESET} ${GREY}Confirmări:${RESET} ${WHITE}activate${RESET}  ${GREY}· MCP: ${MCP_MODE}${RESET}"
    fi
    append_line ""
    if [ "$MENU_KIND" = "tools" ]; then
        append_line "  ${BOLD}${WHITE}Instrumente${RESET}"
    else
        append_line "  ${BOLD}${WHITE}Alege ce vrei să faci${RESET}"
    fi
    append_line "  ${DARK_GREY}┌${fill}┐${RESET}"
    MENU_FIRST_ROW=$((row + 1))
    for ((i = 0; i < COUNT; i++)); do
        if [ "$i" -eq "$SELECTED" ]; then render_item_block "$i" true; else render_item_block "$i" false; fi
        screen+="${RENDERED_BLOCK}"$'\n'
        row=$((row + 2))
    done
    append_line "  ${DARK_GREY}└${fill}┘${RESET}"
    append_line ""
    if [ "$BOX_WIDTH" -lt 62 ]; then
        append_line "  ${ACCENT}↑↓${GREY} mută  ${ACCENT}Enter${GREY} alege  ${ACCENT}Q${GREY} ieșire${RESET}"
    else
        append_line "  ${ACCENT}↑↓${GREY} navighează   ${ACCENT}1-${COUNT}${GREY} alege direct   ${ACCENT}Enter${GREY} deschide   ${ACCENT}Q / Esc${GREY} ieșire${RESET}"
    fi
    REST_ROW=$row
    printf '%s' "$screen"
}

render_selection_change() {
    local previous="$1" current="$2"
    local previous_row=$((MENU_FIRST_ROW + previous * 2))
    local current_row=$((MENU_FIRST_ROW + current * 2))
    local output=""
    render_item_block "$previous" false
    output+=$'\033['"${previous_row}"';1H'"${RENDERED_BLOCK}"
    render_item_block "$current" true
    output+=$'\033['"${current_row}"';1H'"${RENDERED_BLOCK}"
    output+=$'\033['"${REST_ROW}"';1H'
    printf '%s' "$output"
}

move_selection() {
    local direction="$1"
    SELECTED=$(((SELECTED + direction + COUNT) % COUNT))
}

show_launching() {
    printf '\033[H\033[J\n\n  %s%s%s%s  %s%s%s\n\n' \
        "$ACCENT" "$BOLD" "$ARROW" "$RESET" "$BOLD$WHITE" "$1" "$RESET"
    printf '  %sPornesc Codex...%s\n\n' "$GREY" "$RESET"
}

build_codex_command() {
    local mode="$1" prompt="${2:-}"
    local -a args=(codex)
    if [ "$FULL_PERMS" = "true" ]; then args+=(--dangerously-bypass-approvals-and-sandbox); fi
    args+=(--cd "$CODEX_WORKDIR")
    if [ "$mode" = "resume" ]; then args+=(resume); elif [ -n "$prompt" ]; then args+=("$prompt"); fi
    printf -v CODEX_COMMAND '%q ' "${args[@]}"
    CODEX_COMMAND="${CODEX_COMMAND% }"
}

start_codex_session() {
    local mode="$1" title="$2" prompt="${3:-}"
    tmux kill-session -t "$TMUX_SESSION_NAME" 2>/dev/null || true
    build_codex_command "$mode" "$prompt"
    cleanup_term
    show_launching "$title"
    if [ "${CODEX_PICKER_NO_EXEC:-false}" = "true" ]; then printf '%s\n' "$CODEX_COMMAND"; return 0; fi
    exec tmux new-session -s "$TMUX_SESSION_NAME" "$CODEX_COMMAND"
}

run_tool() {
    local action="$1" title="$2" result=0
    printf '\033[?25h\033[H\033[J\n  %s%s%s\n\n' "$BOLD" "$title" "$RESET"
    case "$action" in
        "__REFRESH__") ha-context --force || result=$? ;;
        "__CHECK__") ha-safe-edit check || result=$? ;;
        "__DOCTOR__") codex-ha doctor || result=$? ;;
        "__MCP__") codex mcp list || result=$? ;;
    esac
    printf '\n'
    if [ "$result" -eq 0 ]; then
        printf '  %s✓%s %sOperațiunea s-a încheiat cu succes.%s\n' "$GREEN" "$RESET" "$GREY" "$RESET"
    else
        printf '  %s!%s %sOperațiunea nu s-a încheiat cu succes (cod %d).%s\n' \
            "$YELLOW" "$RESET" "$GREY" "$result" "$RESET"
    fi
    printf '  %sApasă orice tastă pentru a reveni.%s\033[?25l' "$GREY" "$RESET"
    IFS= read -rsn1 _ || true
    if [ "$action" = "__REFRESH__" ]; then update_context_status; fi
    LAYOUT_DIRTY=1
    render_full
}

activate_selected() {
    local action="${ACTIONS[$SELECTED]}" title="${TITLES[$SELECTED]}"
    case "$action" in
        "__ATTACH__")
            cleanup_term
            if [ "${CODEX_PICKER_NO_EXEC:-false}" = "true" ]; then printf 'tmux attach-session -t %q\n' "$TMUX_SESSION_NAME"; return 0; fi
            exec tmux attach-session -t "$TMUX_SESSION_NAME"
            ;;
        "__NEW__") start_codex_session new "$title" ;;
        "__RESUME__") start_codex_session resume "$title" ;;
        "__TOOLS__") configure_tools_menu; render_full ;;
        "__BACK__") configure_main_menu; render_full ;;
        "__REFRESH__"|"__CHECK__"|"__DOCTOR__"|"__MCP__") run_tool "$action" "$title" ;;
        *) start_codex_session new "$title" "$action" ;;
    esac
}

main() {
    local key rest final previous
    update_context_status
    configure_main_menu
    printf '\033[?25l'
    stty -echo -icanon time 0 min 1 2>/dev/null || true
    render_full
    while true; do
        if [ "$LAYOUT_DIRTY" -eq 1 ]; then render_full; fi
        key=""; rest=""
        IFS= read -rsn1 -t "$READ_TIMEOUT" key || continue
        if [ "$key" = $'\033' ]; then
            IFS= read -rsn1 -t "$ESC_TIMEOUT" rest 2>/dev/null || true
            if [ "$rest" = "[" ]; then
                final=""
                IFS= read -rsn1 -t "$ESC_TIMEOUT" final 2>/dev/null || true
                rest="${rest}${final}"
            fi
            if [ -n "$rest" ]; then key="${key}${rest}"; fi
        fi
        previous=$SELECTED
        case "$key" in
            $'\033[A'|'k'|'K') move_selection -1 ;;
            $'\033[B'|'j'|'J') move_selection 1 ;;
            ''|$'\n'|$'\r') activate_selected; continue ;;
            $'\033')
                if [ "$MENU_KIND" = "tools" ]; then configure_main_menu; render_full; continue; fi
                cleanup_term; printf '\033[H\033[J'; exit 0
                ;;
            'q'|'Q') cleanup_term; printf '\033[H\033[J'; exit 0 ;;
            [1-9])
                if [ "$key" -le "$COUNT" ]; then
                    SELECTED=$((10#$key - 1))
                    render_selection_change "$previous" "$SELECTED"
                    activate_selected
                fi
                continue
                ;;
            *) continue ;;
        esac
        if [ "$SELECTED" -ne "$previous" ]; then render_selection_change "$previous" "$SELECTED"; fi
    done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
