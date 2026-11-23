# ============================================================
#  TerminalHero - Gegner
# ------------------------------------------------------------
#  Gegner sind dynamische Dateien im Dateisystem (Kategorie »Virus«
#  oder später auch »Datei«). Sie greifen automatisch an, sobald der
#  Agent ihren Ordner betritt - aber erst nach einer kurzen Wartezeit.
#  Der Schaden wird in Tokens abgezogen; er läuft nur, solange der Agent
#  im selben Ordner steht. Fällt er dadurch im Kampf auf 0 Tokens, stirbt
#  er (kern/leben.sh) - es gibt kein automatisches Flüchten.
#
#  Eine Gegnerart meldet sich selbst an (z. B. Gegner/Molerats.sh):
#     gegner_define_type <id> <kategorie> <label> <wartezeit> <dps> \
#                        <rm-kosten> <loot-id> <loot-anzahl> \
#                        <on-kill-funktion> "<betretenstext>"
#  Danach setzt die Weltdatei ihre Exemplare mit
#     gegner_place <typ> <pfad>
#  in den Baum. Kampfbefehle (z. B. »rm«) fragen die Register hier ab.
#
#  Zustand:
#    GEGNER_AT[pfad]      -> Typ-ID
#    GEGNER_NAME[pfad]    -> Anzeigename (Dateiname)
#  Die Register sind Code/abgeleiteter Zustand und werden beim Start
#  bzw. nach dem Laden von den Gegnerdateien neu aufgebaut. Nur der
#  Tod eines Gegners ist echte Spielzustand (MOLERATS_DEAD).
#
#  Flüchtige Angriffsanker stehen in kern/state.sh:
#    GEGNER_ACTIVE_CWD, GEGNER_AGGRO_AT, GEGNER_LAST_ATTACK_AT,
#    GEGNER_LAST_CWD.
# ============================================================

# Grundkosten eines Kampfbefehls. Die Gegnerkosten kommen je Ziel dazu.
GEGNER_RM_BASE=50

# --- Typ-Register (Code, nicht gespeichert) --------------------------
declare -gA GEGNER_TYPE_CAT=()       # typ -> virus|datei
declare -gA GEGNER_TYPE_LABEL=()     # typ -> Anzeigename (z. B. Molerat)
declare -gA GEGNER_TYPE_WAIT=()      # typ -> Wartezeit in Sekunden
declare -gA GEGNER_TYPE_DPS=()       # typ -> Tokens Schaden pro Sekunde
declare -gA GEGNER_TYPE_RM_COST=()   # typ -> zusätzliche rm-Kosten
declare -gA GEGNER_TYPE_LOOT=()      # typ -> Item-ID
declare -gA GEGNER_TYPE_LOOT_N=()    # typ -> Loot-Anzahl
declare -gA GEGNER_TYPE_ON_KILL=()   # typ -> Haken nach dem Löschen
declare -gA GEGNER_TYPE_ENTER=()     # typ -> Zeile beim Betreten (z. B. Oink)

# --- Exemplar-Register (abgeleitet, nicht gespeichert) ----------------
declare -gA GEGNER_AT=()             # pfad -> typ
declare -gA GEGNER_NAME=()           # pfad -> Anzeigename

# Eine Gegnerart anmelden (idempotent; erneutes Anmelden aktualisiert).
gegner_define_type() {
    local id="$1" cat="${2:-virus}" label="${3:-$1}" wait="${4:-3}"
    local dps="${5:-0}" rmcost="${6:-0}" loot="${7:-}" lootn="${8:-1}"
    local killfn="${9:-}" enter="${10:-}"
    [ -n "$id" ] || return 1
    case "$wait" in ''|*[!0-9]*) wait=3 ;; esac
    case "$dps" in ''|*[!0-9]*) dps=0 ;; esac
    case "$rmcost" in ''|*[!0-9]*) rmcost=0 ;; esac
    case "$lootn" in ''|*[!0-9]*) lootn=1 ;; esac
    GEGNER_TYPE_CAT["$id"]="$cat"
    GEGNER_TYPE_LABEL["$id"]="$label"
    GEGNER_TYPE_WAIT["$id"]="$wait"
    GEGNER_TYPE_DPS["$id"]="$dps"
    GEGNER_TYPE_RM_COST["$id"]="$rmcost"
    GEGNER_TYPE_LOOT["$id"]="$loot"
    GEGNER_TYPE_LOOT_N["$id"]="$lootn"
    GEGNER_TYPE_ON_KILL["$id"]="$killfn"
    GEGNER_TYPE_ENTER["$id"]="$enter"
    return 0
}

gegner_type_exists() { [ -n "${GEGNER_TYPE_CAT[$1]:-}" ]; }

gegner_type_cat()    { printf '%s' "${GEGNER_TYPE_CAT[$1]:-}"; }
gegner_type_label()  { printf '%s' "${GEGNER_TYPE_LABEL[$1]:-}"; }
gegner_type_wait()   { printf '%s' "${GEGNER_TYPE_WAIT[$1]:-3}"; }
gegner_type_dps()    { printf '%s' "${GEGNER_TYPE_DPS[$1]:-0}"; }
gegner_type_rm_cost(){ printf '%s' "${GEGNER_TYPE_RM_COST[$1]:-0}"; }

# Anzeigeform für Kategorien (Einzahl/Mehrzahl).
gegner_cat_label() {
    case "$1" in
        virus) printf 'Virus' ;;
        datei) printf 'Datei' ;;
        *)     printf '%s' "$1" ;;
    esac
}
gegner_cat_plural() {
    case "$1" in
        virus) printf 'Viren' ;;
        datei) printf 'Dateien' ;;
        *)     printf '%s' "$1" ;;
    esac
}

# Inhalt für »cat« an einer Gegnerdatei.
gegner_file_text() {
    local p="$1" type name cat label wait dps
    type="${GEGNER_AT[$p]:-}"
    [ -n "$type" ] || return 1
    name="${GEGNER_NAME[$p]:-${p##*/}}"
    cat="$(gegner_type_cat "$type")"
    label="$(gegner_type_label "$type")"
    wait="$(gegner_type_wait "$type")"
    dps="$(gegner_type_dps "$type")"
    printf '%s\n' \
        "[GEGNER]  ${name}   ::   Kategorie ${cat}" \
        "${label} – kein gewöhnlicher Text, sondern ein Angreifer." \
        "──────────────────────────────────────────────" \
        "Status       : aktiv" \
        "Wartezeit    : ${wait} Sekunden beim Betreten" \
        "Angriff      : ${dps} Tokens pro Sekunde" \
        "Kampfbefehl  : rm ${name}" \
        "" \
        "Zum Löschen braucht der Agent eine ausgerüstete Waffe," \
        "die ${cat} vernichten kann." \
        "" \
        "cat ${name}    →  den Befund lesen" \
        "rm ${name}     →  den Gegner löschen"
}

# Gegner in den Baum setzen. fs_add ist idempotent; Inhalt/Register
# werden bei jedem Aufruf aufgefrischt.
gegner_place() {
    local type="$1" p="$2"
    [ -n "$p" ] || return 1
    gegner_type_exists "$type" || return 1
    fs_add f "$p"
    GEGNER_AT["$p"]="$type"
    GEGNER_NAME["$p"]="${p##*/}"
    CONTENT["$p"]="$(gegner_file_text "$p")"
    unset "DIALOG[$p]" 2>/dev/null
    return 0
}

# Gegner aus dem Baum und allen Nebenregistern entfernen.
gegner_remove_path() {
    local p="$1"
    [ -n "$p" ] || return 1
    fs_remove "$p"
    unset "CONTENT[$p]" "DIALOG[$p]" "GEGNER_AT[$p]" "GEGNER_NAME[$p]" 2>/dev/null
    if declare -F search_forget >/dev/null 2>&1; then
        search_forget "$p"
    fi
    return 0
}

# Gegner im AKTUELLEN Ordner (nur direkte Kinder, nur existierende Dateien).
gegner_count_current() {
    local n=0 e
    while IFS= read -r e; do
        [ -n "$e" ] || continue
        [ -n "${GEGNER_AT[$CWD/$e]:-}" ] || continue
        [ "${TYPE[$CWD/$e]:-}" = "f" ] || continue
        n=$(( n + 1 ))
    done <<< "${CHILDREN[$CWD]:-}"
    printf '%s' "$n"
}

gegner_current_names() {
    local e out="" sep=""
    while IFS= read -r e; do
        [ -n "$e" ] || continue
        [ -n "${GEGNER_AT[$CWD/$e]:-}" ] || continue
        [ "${TYPE[$CWD/$e]:-}" = "f" ] || continue
        out+="${sep}${e}"
        sep=", "
    done <<< "${CHILDREN[$CWD]:-}"
    printf '%s' "$out"
}

gegner_current_dps() {
    local e t sum=0
    while IFS= read -r e; do
        [ -n "$e" ] || continue
        t="${GEGNER_AT[$CWD/$e]:-}"
        [ -n "$t" ] || continue
        [ "${TYPE[$CWD/$e]:-}" = "f" ] || continue
        sum=$(( sum + $(gegner_type_dps "$t") ))
    done <<< "${CHILDREN[$CWD]:-}"
    printf '%s' "$sum"
}

gegner_current_wait() {
    local e t w wait=-1
    while IFS= read -r e; do
        [ -n "$e" ] || continue
        t="${GEGNER_AT[$CWD/$e]:-}"
        [ -n "$t" ] || continue
        [ "${TYPE[$CWD/$e]:-}" = "f" ] || continue
        w="$(gegner_type_wait "$t")"
        if [ "$wait" -lt 0 ] || [ "$w" -lt "$wait" ]; then wait="$w"; fi
    done <<< "${CHILDREN[$CWD]:-}"
    [ "$wait" -lt 0 ] && wait=3
    printf '%s' "$wait"
}

gegner_current_enter_text() {
    local e t txt
    while IFS= read -r e; do
        [ -n "$e" ] || continue
        t="${GEGNER_AT[$CWD/$e]:-}"
        [ -n "$t" ] || continue
        [ "${TYPE[$CWD/$e]:-}" = "f" ] || continue
        txt="${GEGNER_TYPE_ENTER[$t]:-}"
        if [ -n "$txt" ]; then printf '%s' "$txt"; return 0; fi
    done <<< "${CHILDREN[$CWD]:-}"
    return 1
}

gegner_is_enemy_path() {
    [ -n "${GEGNER_AT[$1]:-}" ] || return 1
    [ "${TYPE[$1]:-}" = "f" ] || return 1
    return 0
}

gegner_category_of() {
    local t="${GEGNER_AT[$1]:-}"
    [ -n "$t" ] || return 1
    gegner_type_cat "$t"
}

# Kosten eines rm-Aufrufs: Grundkosten + gültige, eindeutige Ziele.
# Ungültige Namen kosten nur die Grundkosten - sie kosten aber keine
# Gegnerkosten, weil sie kein Ziel sind.
gegner_rm_cost_of_args() {
    local rest="${1:-}" total="$GEGNER_RM_BASE" a np t seen=" "
    local -a args=()
    read -ra args <<< "$rest"
    for a in "${args[@]}"; do
        [ -n "$a" ] || continue
        if declare -F resolve_path >/dev/null 2>&1; then
            np="$(resolve_path "$a" "$CWD")"
        else
            np="$CWD/$a"
        fi
        [ "${TYPE[$np]:-}" = "f" ] || continue
        t="${GEGNER_AT[$np]:-}"
        [ -n "$t" ] || continue
        case "$seen" in *" $np "*) continue ;; esac
        seen+="$np "
        total=$(( total + $(gegner_type_rm_cost "$t") ))
    done
    printf '%s' "$total"
}

# Testbarer Zeitanker (die echten Sekunden, sofern TH_GEGNER_NOW fehlt).
gegner_now() {
    if [ -n "${TH_GEGNER_NOW:-}" ]; then
        printf '%s' "$TH_GEGNER_NOW"
    else
        date +%s
    fi
}

gegner_reset_encounter() {
    GEGNER_ACTIVE_CWD=""
    GEGNER_AGGRO_AT=0
    GEGNER_LAST_ATTACK_AT=0
}

# Beim Betreten eines Ordners: Gegner bemerken und Angriff ankündigen.
# Der Vergleich mit GEGNER_LAST_CWD verhindert, dass jede Eingabe im
# selben Raum erneut »Oink« auslöst.
gegner_maybe_enter() {
    [ "${CWD:-}" = "${GEGNER_LAST_CWD:-}" ] && return 1
    GEGNER_LAST_CWD="${CWD:-}"
    gegner_reset_encounter

    local n; n="$(gegner_count_current)"
    [ "$n" -gt 0 ] || return 1
    local wait dps enter
    wait="$(gegner_current_wait)"
    dps="$(gegner_current_dps)"
    GEGNER_ACTIVE_CWD="$CWD"
    GEGNER_AGGRO_AT=$(( $(gegner_now) + wait ))
    GEGNER_LAST_ATTACK_AT="$GEGNER_AGGRO_AT"

    OUT+=("")
    enter="$(gegner_current_enter_text)" && OUT+=("$enter")
    OUT+=("[ GEGNER ] ${n} Gegner: $(gegner_current_names).")
    OUT+=("           Angriff nach ${wait}s · ${dps} Tokens/s · nur in diesem Ordner.")
    return 0
}

# Fälligen Gegnerschaden anwenden. Rückgabe 0 = etwas geändert (neu zeichnen).
gegner_tick() {
    [ -n "${GEGNER_ACTIVE_CWD:-}" ] || return 1
    if [ "${CWD:-}" != "$GEGNER_ACTIVE_CWD" ]; then
        gegner_reset_encounter
        return 1
    fi

    local n; n="$(gegner_count_current)"
    if [ "$n" -le 0 ]; then
        gegner_reset_encounter
        return 1
    fi

    local now; now="$(gegner_now)"
    [ "$now" -ge "${GEGNER_AGGRO_AT:-0}" ] || return 1
    local last="${GEGNER_LAST_ATTACK_AT:-$GEGNER_AGGRO_AT}"
    [ "$last" -lt "${GEGNER_AGGRO_AT:-0}" ] && last="$GEGNER_AGGRO_AT"
    local steps=$(( now - last ))
    [ "$steps" -ge 1 ] || return 1

    local dps red=0 block=0 eff total names roll
    dps="$(gegner_current_dps)"
    if declare -F equip_damage_reduction_total >/dev/null 2>&1; then
        red="$(equip_damage_reduction_total)"
    fi
    if declare -F equip_block_chance_total >/dev/null 2>&1; then
        block="$(equip_block_chance_total)"
    fi
    GEGNER_LAST_ATTACK_AT="$now"

    # Ohne angreifenden Gegner gibt es keinen Treffer (und auch keinen
    # Block). Ein Gegner mit 0 DPS ist kein Angriff.
    [ "$dps" -gt 0 ] || return 1

    # Schild & Co.: einmal pro Angriff würfeln. TH_BLOCK_ROLL (0–99) ist
    # ein Test-Haken; im normalen Spiel würfelt $RANDOM.
    if [ "$block" -gt 0 ]; then
        roll="${TH_BLOCK_ROLL:-$(( RANDOM % 100 ))}"
        case "$roll" in ''|*[!0-9]*) roll=$(( RANDOM % 100 )) ;; esac
        if [ "$roll" -lt "$block" ]; then
            names="$(gegner_current_names)"
            OUT+=("")
            OUT+=("[ GEGNER ] ${names}: Angriff geblockt (${TOKENS_CUR}/${TOKENS_MAX}).")
            return 0
        fi
    fi

    # Mindestens 1 Schadenspunkt pro Angriff, auch wenn die Rüstung den
    # Gegnerschaden rechnerisch auf 0 oder darunter drückt.
    eff=$(( dps - red )); [ "$eff" -lt 1 ] && eff=1
    total=$(( steps * eff ))
    names="$(gegner_current_names)"

    if [ "${TOKENS_CUR:-0}" -le "$total" ]; then
        local lost="${TOKENS_CUR:-0}"
        TOKENS_CUR=0
        OUT+=("")
        OUT+=("[ GEGNER ] ${names}: -${lost} Tokens. Deine Energie ist aufgebraucht.")
        play_sound error
        # Im Kampf ist der letzte Token immer tödlich - kein Entkommen
        # durch automatisches Flüchten.
        declare -F leben_die >/dev/null 2>&1 && leben_die
        return 0
    fi

    TOKENS_CUR=$(( TOKENS_CUR - total ))
    OUT+=("")
    OUT+=("[ GEGNER ] ${names}: -${total} Tokens (${TOKENS_CUR}/${TOKENS_MAX}).")
    play_sound error
    return 0
}

# Einen Gegner löschen: Datei entfernen, Loot vergeben, Todes-Haken rufen.
gegner_kill() {
    local p="$1" type name loot lootn fn
    type="${GEGNER_AT[$p]:-}"
    [ -n "$type" ] || return 1
    name="${GEGNER_NAME[$p]:-${p##*/}}"
    loot="${GEGNER_TYPE_LOOT[$type]:-}"
    lootn="${GEGNER_TYPE_LOOT_N[$type]:-1}"

    gegner_remove_path "$p"
    play_sound select
    OUT+=("")
    OUT+=("[ KAMPF ] ${name} wurde gelöscht.")

    if [ -n "$loot" ] && declare -F inv_add >/dev/null 2>&1; then
        if inv_add "$loot" "$lootn"; then
            OUT+=("[ LOOT ] $(item_name "$loot") ×${lootn}")
        fi
    fi

    fn="${GEGNER_TYPE_ON_KILL[$type]:-}"
    if [ -n "$fn" ] && declare -F "$fn" >/dev/null 2>&1; then
        "$fn" "$p" "$type"
    fi

    [ "$(gegner_count_current)" -le 0 ] && gegner_reset_encounter
    return 0
}
