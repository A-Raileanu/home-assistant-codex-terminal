#!/usr/bin/with-contenv bashio

set -e

PERSIST_CONFIG="/data/persistent-packages.json"

init_config() {
    if [ ! -f "$PERSIST_CONFIG" ]; then
        echo '{"apk_packages":[],"pip_packages":[]}' > "$PERSIST_CONFIG"
    fi
}

show_help() {
    echo "persist-install - instalează pachete la fiecare pornire a aplicației"
    echo ""
    echo "Utilizare:"
    echo "  persist-install apk <package...>"
    echo "  persist-install pip <package...>"
    echo "  persist-install remove <apk|pip> <package>"
    echo "  persist-install list"
}

list_packages() {
    init_config
    echo "Pachete APK:"
    jq -r '.apk_packages[]? | "  - " + .' "$PERSIST_CONFIG"
    echo ""
    echo "Pachete pip:"
    jq -r '.pip_packages[]? | "  - " + .' "$PERSIST_CONFIG"
}

install_apk() {
    init_config
    [ "$#" -gt 0 ] || { echo "Nu ai indicat niciun pachet APK" >&2; exit 1; }
    apk add --no-cache "$@"
    for pkg in "$@"; do
        jq --arg pkg "$pkg" 'if .apk_packages | index($pkg) then . else .apk_packages += [$pkg] end' \
            "$PERSIST_CONFIG" > "${PERSIST_CONFIG}.tmp"
        mv "${PERSIST_CONFIG}.tmp" "$PERSIST_CONFIG"
    done
}

install_pip() {
    init_config
    [ "$#" -gt 0 ] || { echo "Nu ai indicat niciun pachet pip" >&2; exit 1; }
    pip3 install --break-system-packages --no-cache-dir "$@"
    for pkg in "$@"; do
        jq --arg pkg "$pkg" 'if .pip_packages | index($pkg) then . else .pip_packages += [$pkg] end' \
            "$PERSIST_CONFIG" > "${PERSIST_CONFIG}.tmp"
        mv "${PERSIST_CONFIG}.tmp" "$PERSIST_CONFIG"
    done
}

remove_package() {
    init_config
    local type="$1"
    local pkg="$2"

    [ -n "$type" ] && [ -n "$pkg" ] || { echo "Utilizare: persist-install remove <apk|pip> <pachet>" >&2; exit 1; }

    case "$type" in
        apk)
            jq --arg pkg "$pkg" 'del(.apk_packages[] | select(. == $pkg))' "$PERSIST_CONFIG" > "${PERSIST_CONFIG}.tmp"
            ;;
        pip)
            jq --arg pkg "$pkg" 'del(.pip_packages[] | select(. == $pkg))' "$PERSIST_CONFIG" > "${PERSIST_CONFIG}.tmp"
            ;;
        *)
            echo "Tip de pachet necunoscut: $type" >&2
            exit 1
            ;;
    esac

    mv "${PERSIST_CONFIG}.tmp" "$PERSIST_CONFIG"
}

command="${1:-help}"
shift || true

case "$command" in
    apk) install_apk "$@" ;;
    pip) install_pip "$@" ;;
    list) list_packages ;;
    remove) remove_package "$@" ;;
    help|--help|-h) show_help ;;
    *) echo "Comandă necunoscută: $command" >&2; show_help; exit 1 ;;
esac
