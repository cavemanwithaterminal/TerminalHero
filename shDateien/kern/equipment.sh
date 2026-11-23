# ============================================================
#  TerminalHero - Ausrüstung
# ------------------------------------------------------------
#  Der Charakterbogen hat acht feste Ausrüstungs-Slots:
#
#     Kopf · Oberkörper · Beine · Linke Hand · Rechte Hand ·
#     Amulett · Ring1 · Ring2
#
#  Items melden ihre passenden Slots selbst an:
#     equip_define_item <item-id> <slot> [<slot> ...]
#  Ein Item darf in mehreren passenden Slots getragen werden
#  (z. B. ein Ring in Ring1 und Ring2). Zusätzlich lassen sich
#  Stat-Effekte hinterlegen:
#     equip_effect_tokens_max <item-id> <betrag>
#     equip_effect_damage_reduction <item-id> <betrag>
#     equip_effect_block_chance <item-id> <prozent>
#     equip_effect_token_regen <item-id> <betrag>
#     equip_effect_combat <item-id> <zielkategorie> [<zielkategorie> ...]
#  Beim Anlegen/Ersetzen/Ablegen rechnet dieses Modul die Effekte
#  direkt auf TOKENS_MAX an; der eingehende Schaden und die
#  Blockchance werden als Werte bereitgestellt. Kampfwaffen melden an,
#  welche Ziele sie löschen dürfen – z. B. »virus«, aber nicht die
#  freundliche Kategorie »datei«.
#
#  Ausrüstungs-Sets:
#     equip_define_set <set-id> <token-bonus> <item-id> ...
#     equip_set_effect_token_regen <set-id> <betrag>
#     equip_set_effect_damage_reduction <set-id> <betrag>
#  Ein Set ist vollständig, wenn ALLE gelisteten Items getragen werden.
#  Der Token-Bonus wird genau einmal auf TOKENS_MAX angewendet. Weil
#  TOKENS_MAX im Spielstand steht, merkt sich EQUIP_SET_APPLIED, welche
#  Set-Boni bereits enthalten sind; so kann ein Laden den Bonus nicht
#  doppeln. Regen- und Schadensreduktions-Boni werden dagegen bei jeder
#  Abfrage aus dem vollständigen Set abgeleitet.
#
#  Zustand: EQUIP_SLOT_ITEM (slot -> Item-ID) und EQUIP_SET_APPLIED
#  (set-id -> 1), beide werden im Spielstand gesichert. Die
#  Slot-Reihenfolge EQUIP_SLOTS ist auch die Anzeige-Reihenfolge im
#  Charakterbogen.
# ============================================================

# Kanonische Slot-IDs in Anzeige-Reihenfolge.
declare -ga EQUIP_SLOTS=(
    kopf
    oberkoerper
    beine
    linke_hand
    rechte_hand
    amulett
    ring1
    ring2
)

# Anzeigenamen der Slots.
declare -gA EQUIP_SLOT_LABEL=(
    [kopf]="Kopf"
    [oberkoerper]="Oberkörper"
    [beine]="Beine"
    [linke_hand]="Linke Hand"
    [rechte_hand]="Rechte Hand"
    [amulett]="Amulett"
    [ring1]="Ring1"
    [ring2]="Ring2"
)

# Spielzustand: Slot-ID -> Item-ID. Leer = nichts ausgerüstet.
declare -gA EQUIP_SLOT_ITEM=()

# Text für einen leeren Slot (auch in Tests verwendet).
EQUIP_EMPTY="— leer —"

# Ausrüstungs-Metadaten der Items: Item-ID -> " kopf oberkoerper "
# (Leerzeichen an den Enden machen die Prüfung ohne Wortzerlegung möglich.)
declare -gA EQUIP_ITEM_SLOTS=()

# Stat-Effekte der Items (nur solange sie getragen werden).
declare -gA EQUIP_ITEM_TOKENS_MAX=()       # Item-ID -> +maximale Tokens
declare -gA EQUIP_ITEM_DAMAGE_REDUCTION=() # Item-ID -> −eingehender Schaden
declare -gA EQUIP_ITEM_BLOCK_CHANCE=()     # Item-ID -> Blockchance in Prozent
declare -gA EQUIP_ITEM_TOKEN_REGEN=()      # Item-ID -> +Tokens je Regen-Intervall

# Kampf-Metadaten. Nur ausgerüstete Items mit einem Kampf-Eintrag zählen
# als Waffe; EQUIP_ITEM_COMBAT_TARGETS hält die erlaubten Zielkategorien
# als " virus datei " (Leerzeichen an den Enden für exakte Wortprüfung).
declare -gA EQUIP_ITEM_COMBAT=()           # Item-ID -> 1
declare -gA EQUIP_ITEM_COMBAT_TARGETS=()   # Item-ID -> " ziel1 ziel2 "

# Ausrüstungs-Sets. Die Item-Liste steht als " item1 item2 " (Leerzeichen
# an den Enden), damit die Prüfung ohne Wortzerlegung auskommt.
declare -gA EQUIP_SET_ITEMS=()             # Set-ID -> " item1 item2 "
declare -gA EQUIP_SET_TOKENS=()            # Set-ID -> +maximale Tokens
declare -gA EQUIP_SET_TOKEN_REGEN=()       # Set-ID -> +Tokens je Regen-Intervall
declare -gA EQUIP_SET_DAMAGE_REDUCTION=()  # Set-ID -> −eingehender Schaden
declare -gA EQUIP_SET_APPLIED=()           # Set-ID -> 1 = Bonus in TOKENS_MAX

# Frischstart/Reset.
equip_reset() {
    EQUIP_SLOT_ITEM=()
    EQUIP_SET_APPLIED=()
}

# Ist <slot> ein bekannter Slot?
equip_slot_valid() {
    [ -n "${EQUIP_SLOT_LABEL[$1]:-}" ]
}

# Anzeigename eines Slots (Fallback: die ID selbst).
equip_slot_label() {
    printf '%s' "${EQUIP_SLOT_LABEL[$1]:-$1}"
}

# Item-ID eines Slots (leer, wenn nichts ausgerüstet ist).
equip_get() {
    printf '%s' "${EQUIP_SLOT_ITEM[$1]:-}"
}

# Anzeigename des ausgerüsteten Gegenstands. Ist noch kein Item
# eingetragen, steht dort »— leer —«. Der Item-Name kommt aus dem
# Item-Katalog; unbekannte IDs bleiben als ID sichtbar.
equip_item_label() {
    local id="${EQUIP_SLOT_ITEM[$1]:-}"
    if [ -z "$id" ]; then
        printf '%s' "$EQUIP_EMPTY"
        return 0
    fi
    if declare -F item_name >/dev/null 2>&1; then
        item_name "$id"
    else
        printf '%s' "$id"
    fi
}

# Item in einen Slot legen/entfernen (niedrige Ebene, ohne Inventar-
# Prüfung). Die spätere Ausrüst-Aktion baut darauf auf.
equip_set() {   # <slot> <item-id>
    equip_slot_valid "$1" || return 1
    [ -n "${2:-}" ] || return 1
    EQUIP_SLOT_ITEM["$1"]="$2"
}

equip_clear() {   # <slot>
    equip_slot_valid "$1" || return 1
    unset 'EQUIP_SLOT_ITEM[$1]'
}

# Ein Item aus allen Slots entfernen (z. B. beim Ablegen/Verkaufen).
equip_remove_item() {   # <item-id>
    local slot
    for slot in "${EQUIP_SLOTS[@]}"; do
        [ "${EQUIP_SLOT_ITEM[$slot]:-}" = "$1" ] || continue
        unset 'EQUIP_SLOT_ITEM[$slot]'
    done
}

# Welche Slots darf ein Item tragen? (Registrierung für spätere Items.)
#   equip_define_item <item-id> <slot> [<slot> ...]
equip_define_item() {
    local id="$1" slot rec=""
    shift
    [ -n "$id" ] || return 1
    [ "$#" -gt 0 ] || return 1
    for slot in "$@"; do
        equip_slot_valid "$slot" || return 1
        case " $rec " in
            *" $slot "*) ;;
            *) rec+="$slot " ;;
        esac
    done
    EQUIP_ITEM_SLOTS["$id"]="$rec"
    return 0
}

# Stat-Effekt registrieren: +maximale Tokens, solange das Item getragen wird.
equip_effect_tokens_max() {   # <item-id> <betrag>
    [ -n "${1:-}" ] || return 1
    EQUIP_ITEM_TOKENS_MAX["$1"]="${2:-0}"
}

# Stat-Effekt registrieren: so viel weniger eingehender Schaden.
equip_effect_damage_reduction() {   # <item-id> <betrag>
    [ -n "${1:-}" ] || return 1
    EQUIP_ITEM_DAMAGE_REDUCTION["$1"]="${2:-0}"
}

# Stat-Effekt registrieren: Chance (in Prozent), einen Angriff komplett
# zu blocken. Mehrere getragene Teile addieren sich (Obergrenze 100).
equip_effect_block_chance() {   # <item-id> <prozent>
    local p="${2:-0}"
    [ -n "${1:-}" ] || return 1
    case "$p" in ''|*[!0-9]*) p=0 ;; esac
    [ "$p" -gt 100 ] && p=100
    EQUIP_ITEM_BLOCK_CHANCE["$1"]="$p"
}

# Stat-Effekt registrieren: zusätzliche Tokens pro Regenerationsintervall.
# Das Intervall ist normalerweise 60 s (TOKENS_REGEN_SECS); die Anzeige
# und tokens_tick lesen den Wert über equip_token_regen_total.
equip_effect_token_regen() {   # <item-id> <betrag>
    local r="${2:-0}"
    [ -n "${1:-}" ] || return 1
    case "$r" in ''|*[!0-9]*) r=0 ;; esac
    EQUIP_ITEM_TOKEN_REGEN["$1"]="$r"
}

# Kampf-Effekt registrieren: Das Item ist eine Waffe und darf die
# genannten Zielkategorien (z. B. virus, datei) löschen.
equip_effect_combat() {   # <item-id> <zielkategorie> [<zielkategorie> ...]
    local id="${1:-}" target rec=""
    shift || true
    [ -n "$id" ] || return 1
    for target in "$@"; do
        [ -n "$target" ] || continue
        case " $rec " in
            *" $target "*) ;;
            *) rec+="$target " ;;
        esac
    done
    EQUIP_ITEM_COMBAT["$id"]=1
    EQUIP_ITEM_COMBAT_TARGETS["$id"]="$rec"
    return 0
}

equip_item_tokens_max() {
    printf '%s' "${EQUIP_ITEM_TOKENS_MAX[$1]:-0}"
}
equip_item_damage_reduction() {
    printf '%s' "${EQUIP_ITEM_DAMAGE_REDUCTION[$1]:-0}"
}
equip_item_block_chance() {
    printf '%s' "${EQUIP_ITEM_BLOCK_CHANCE[$1]:-0}"
}
equip_item_token_regen() {
    printf '%s' "${EQUIP_ITEM_TOKEN_REGEN[$1]:-0}"
}

# Ist <item-id> eine Waffe?
equip_item_combat() {
    [ "${EQUIP_ITEM_COMBAT[$1]:-}" = "1" ]
}

# Darf <item-id> Ziele der Kategorie <ziel> löschen?
equip_item_can_destroy() {   # <item-id> <zielkategorie>
    equip_item_combat "$1" || return 1
    case " ${EQUIP_ITEM_COMBAT_TARGETS[$1]:-} " in
        *" $2 "*) return 0 ;;
    esac
    return 1
}

# Darf <item-id> in <slot> getragen werden?
equip_item_allowed() {   # <item-id> <slot>
    equip_slot_valid "$2" || return 1
    case " ${EQUIP_ITEM_SLOTS[$1]:-} " in
        *" $2 "*) return 0 ;;
    esac
    return 1
}

# Ist <item-id> ausrüstbar (hat mindestens einen passenden Slot)?
equip_item_equippable() {
    [ -n "${EQUIP_ITEM_SLOTS[$1]:-}" ]
}

# Wird <item-id> gerade getragen?
equip_item_worn() {   # <item-id>
    local slot
    for slot in "${EQUIP_SLOTS[@]}"; do
        [ "${EQUIP_SLOT_ITEM[$slot]:-}" = "$1" ] && return 0
    done
    return 1
}

# Ein Ausrüstungs-Set anmelden:
#   equip_define_set <set-id> <token-bonus> <item-id> [<item-id> ...]
# Die Reihenfolge der Items ist egal; doppelte Einträge werden entfernt.
# Ein Set mit nur einem Ring-Eintrag ist auch dann vollständig, wenn der
# Ring nur in Ring1 steckt – Ring2 muss nicht zusätzlich belegt sein.
equip_define_set() {   # <set-id> <token-bonus> <item-id> ...
    local id="${1:-}" tok="${2:-0}" item rec=""
    shift 2 || true
    [ -n "$id" ] || return 1
    case "$tok" in ''|*[!0-9]*) tok=0 ;; esac
    for item in "$@"; do
        [ -n "$item" ] || continue
        case " $rec " in
            *" $item "*) ;;
            *) rec+="$item " ;;
        esac
    done
    [ -n "$rec" ] || return 1
    EQUIP_SET_ITEMS["$id"]="$rec"
    EQUIP_SET_TOKENS["$id"]="$tok"
    return 0
}

# Zusätzlicher Set-Effekt: flache Tokens pro Regenerationsintervall.
equip_set_effect_token_regen() {   # <set-id> <betrag>
    local r="${2:-0}"
    [ -n "${1:-}" ] || return 1
    case "$r" in ''|*[!0-9]*) r=0 ;; esac
    EQUIP_SET_TOKEN_REGEN["$1"]="$r"
}

# Zusätzlicher Set-Effekt: weniger eingehender Schaden.
equip_set_effect_damage_reduction() {   # <set-id> <betrag>
    local d="${2:-0}"
    [ -n "${1:-}" ] || return 1
    case "$d" in ''|*[!0-9]*) d=0 ;; esac
    EQUIP_SET_DAMAGE_REDUCTION["$1"]="$d"
}

# Ist <set-id> vollständig getragen?
equip_set_complete() {   # <set-id>
    local id="${1:-}" item
    [ -n "$id" ] || return 1
    [ -n "${EQUIP_SET_ITEMS[$id]:-}" ] || return 1
    for item in ${EQUIP_SET_ITEMS[$id]}; do
        equip_item_worn "$item" || return 1
    done
    return 0
}

# Token-Bonus, den ein vollständiges Set insgesamt vergibt.
equip_set_bonus_total() {
    local id tok sum=0
    for id in "${!EQUIP_SET_ITEMS[@]}"; do
        equip_set_complete "$id" || continue
        tok="${EQUIP_SET_TOKENS[$id]:-0}"
        case "$tok" in ''|*[!0-9]*) tok=0 ;; esac
        sum=$(( sum + tok ))
    done
    printf '%s' "$sum"
}

# Set-Boni mit den getragenen Teilen abgleichen. Wird nach jedem
# Anlegen/Ablegen und einmal nach dem Laden aufgerufen. EQUIP_SET_APPLIED
# verhindert, dass ein bereits im Spielstand enthaltener Bonus erneut
# auf TOKENS_MAX addiert wird.
equip_set_refresh_all() {
    local id tok applied
    for id in "${!EQUIP_SET_ITEMS[@]}"; do
        tok="${EQUIP_SET_TOKENS[$id]:-0}"
        case "$tok" in ''|*[!0-9]*) tok=0 ;; esac
        [ "$tok" -gt 0 ] || continue
        applied="${EQUIP_SET_APPLIED[$id]:-0}"
        if equip_set_complete "$id"; then
            if [ "$applied" != "1" ]; then
                TOKENS_MAX=$(( ${TOKENS_MAX:-0} + tok ))
                [ "${TOKENS_CUR:-0}" -gt "$TOKENS_MAX" ] && TOKENS_CUR="$TOKENS_MAX"
                EQUIP_SET_APPLIED["$id"]=1
            fi
        elif [ "$applied" = "1" ]; then
            TOKENS_MAX=$(( ${TOKENS_MAX:-0} - tok ))
            [ "$TOKENS_MAX" -lt 1 ] && TOKENS_MAX=1
            [ "${TOKENS_CUR:-0}" -gt "$TOKENS_MAX" ] && TOKENS_CUR="$TOKENS_MAX"
            EQUIP_SET_APPLIED["$id"]=0
        fi
    done
}

# Erster passender Slot, in dem das Item noch nicht liegt (sonst der erste
# passende überhaupt). So werden Ring1/Ring2 nacheinander belegt.
equip_slot_for_item() {   # <item-id>
    local slots rec slot first=""
    rec="${EQUIP_ITEM_SLOTS[$1]:-}"
    [ -n "$rec" ] || return 1
    for slot in "${EQUIP_SLOTS[@]}"; do
        case " $rec " in *" $slot "*) ;; *) continue ;; esac
        [ -n "$first" ] || first="$slot"
        [ -z "${EQUIP_SLOT_ITEM[$slot]:-}" ] && { printf '%s' "$slot"; return 0; }
    done
    printf '%s' "$first"
    return 0
}

# Effekte eines Items anwenden. <richtung> = +1 beim Anlegen, -1 beim Ablegen.
equip_apply_effects() {   # <item-id> <+1|-1>
    local id="$1" dir="${2:-1}" t d
    t="$(equip_item_tokens_max "$id")"
    case "$t" in ''|*[!0-9]*) t=0 ;; esac
    if [ "$t" -gt 0 ]; then
        TOKENS_MAX=$(( ${TOKENS_MAX:-0} + dir * t ))
        [ "$TOKENS_MAX" -lt 1 ] && TOKENS_MAX=1
        [ "${TOKENS_CUR:-0}" -gt "$TOKENS_MAX" ] && TOKENS_CUR="$TOKENS_MAX"
    fi
    # Die Schadensreduktion wird bei Gegnerangriffen über
    # equip_damage_reduction_total abgefragt; hier nur validieren.
    d="$(equip_item_damage_reduction "$id")"
    : "$d"
    return 0
}

# Item anlegen. Ist der Zielslot belegt, wird der alte Gegenstand automatisch
# abgelegt und ersetzt. Rückgabe: 0 angelegt · 1 nicht ausrüstbar ·
# 2 bereits getragen.
equip_wear() {   # <item-id> [<slot>]
    local id="$1" slot="${2:-}" old worn_count=0 s
    equip_item_equippable "$id" || return 1
    for s in "${EQUIP_SLOTS[@]}"; do
        [ "${EQUIP_SLOT_ITEM[$s]:-}" = "$id" ] && worn_count=$(( worn_count + 1 ))
    done
    [ "$worn_count" -ge 1 ] && return 2
    if [ -n "$slot" ]; then
        equip_item_allowed "$id" "$slot" || slot=""
    fi
    [ -n "$slot" ] || slot="$(equip_slot_for_item "$id")" || return 1
    [ -n "$slot" ] || return 1
    # Falls der Zielslot bereits dieses Item enthält (sollte nicht vorkommen), nichts tun
    [ "${EQUIP_SLOT_ITEM[$slot]:-}" = "$id" ] && return 0
    old="${EQUIP_SLOT_ITEM[$slot]:-}"
    if [ -n "$old" ] && [ "$old" != "$id" ]; then
        equip_apply_effects "$old" -1
    fi
    equip_set "$slot" "$id" || return 1
    equip_apply_effects "$id" +1
    equip_set_refresh_all
    return 0
}

# Item ablegen (aus allen Slots, in denen es steckt). Rückgabe 0 = abgelegt,
# 1 = war nicht getragen.
equip_unwear() {   # <item-id>
    local id="$1" slot worn=1
    for slot in "${EQUIP_SLOTS[@]}"; do
        [ "${EQUIP_SLOT_ITEM[$slot]:-}" = "$id" ] || continue
        unset 'EQUIP_SLOT_ITEM[$slot]'
        equip_apply_effects "$id" -1
        worn=0
    done
    [ "$worn" = "0" ] && equip_set_refresh_all
    return "$worn"
}

# Summe aller Token-Boni der getragenen Gegenstände plus vollständiger Sets
# (für Anzeige/Tests).
equip_tokens_bonus_total() {
    local slot id sum=0
    for slot in "${EQUIP_SLOTS[@]}"; do
        id="${EQUIP_SLOT_ITEM[$slot]:-}"
        [ -n "$id" ] || continue
        sum=$(( sum + $(equip_item_tokens_max "$id") ))
    done
    sum=$(( sum + $(equip_set_bonus_total) ))
    printf '%s' "$sum"
}

# Schadensreduktion, die vollständige Ausrüstungs-Sets zusätzlich geben.
equip_set_damage_reduction_total() {
    local id d sum=0
    for id in "${!EQUIP_SET_ITEMS[@]}"; do
        equip_set_complete "$id" || continue
        d="${EQUIP_SET_DAMAGE_REDUCTION[$id]:-0}"
        case "$d" in ''|*[!0-9]*) d=0 ;; esac
        sum=$(( sum + d ))
    done
    printf '%s' "$sum"
}

# Zusätzliche Tokens, die vollständige Ausrüstungs-Sets pro Intervall geben.
equip_set_token_regen_total() {
    local id r sum=0
    for id in "${!EQUIP_SET_ITEMS[@]}"; do
        equip_set_complete "$id" || continue
        r="${EQUIP_SET_TOKEN_REGEN[$id]:-0}"
        case "$r" in ''|*[!0-9]*) r=0 ;; esac
        sum=$(( sum + r ))
    done
    printf '%s' "$sum"
}

# Summe aller Schadensreduktionen der getragenen Gegenstände und Sets.
equip_damage_reduction_total() {
    local slot id sum=0
    for slot in "${EQUIP_SLOTS[@]}"; do
        id="${EQUIP_SLOT_ITEM[$slot]:-}"
        [ -n "$id" ] || continue
        sum=$(( sum + $(equip_item_damage_reduction "$id") ))
    done
    sum=$(( sum + $(equip_set_damage_reduction_total) ))
    printf '%s' "$sum"
}

# Summe aller Blockchancen der getragenen Gegenstände (höchstens 100 %).
equip_block_chance_total() {
    local slot id sum=0
    for slot in "${EQUIP_SLOTS[@]}"; do
        id="${EQUIP_SLOT_ITEM[$slot]:-}"
        [ -n "$id" ] || continue
        sum=$(( sum + $(equip_item_block_chance "$id") ))
    done
    [ "$sum" -gt 100 ] && sum=100
    printf '%s' "$sum"
}

# Zusätzliche Tokens, die getragene Gegenstände und vollständige Sets
# pro Regen-Intervall geben.
equip_token_regen_total() {
    local slot id sum=0
    for slot in "${EQUIP_SLOTS[@]}"; do
        id="${EQUIP_SLOT_ITEM[$slot]:-}"
        [ -n "$id" ] || continue
        sum=$(( sum + $(equip_item_token_regen "$id") ))
    done
    sum=$(( sum + $(equip_set_token_regen_total) ))
    printf '%s' "$sum"
}

# Ist eine Waffe ausgerüstet? (Irgendein getragenes Item mit Kampf-Eintrag.)
equip_combat_ready() {
    local slot id
    for slot in "${EQUIP_SLOTS[@]}"; do
        id="${EQUIP_SLOT_ITEM[$slot]:-}"
        [ -n "$id" ] || continue
        equip_item_combat "$id" && return 0
    done
    return 1
}

# Kann eine ausgerüstete Waffe Ziele der Kategorie <ziel> löschen?
equip_combat_can_destroy() {   # <zielkategorie>
    local slot id
    for slot in "${EQUIP_SLOTS[@]}"; do
        id="${EQUIP_SLOT_ITEM[$slot]:-}"
        [ -n "$id" ] || continue
        equip_item_can_destroy "$id" "$1" && return 0
    done
    return 1
}

# Erste ausgerüstete Waffe (für Meldungen/Tests).
equip_combat_weapon() {
    local slot id
    for slot in "${EQUIP_SLOTS[@]}"; do
        id="${EQUIP_SLOT_ITEM[$slot]:-}"
        [ -n "$id" ] || continue
        if equip_item_combat "$id"; then
            printf '%s' "$id"
            return 0
        fi
    done
    return 1
}

# Kurze Bonuszeile für den Charakterbogen ("" = keine Boni).
equip_bonus_summary() {
    local tok dmg block regen parts=()
    tok="$(equip_tokens_bonus_total)"
    dmg="$(equip_damage_reduction_total)"
    block="$(equip_block_chance_total)"
    regen="$(equip_token_regen_total)"
    [ "$tok" -gt 0 ] && parts+=("+${tok} max. Tokens")
    [ "$dmg" -gt 0 ] && parts+=("−${dmg} eingehender Schaden")
    [ "$block" -gt 0 ] && parts+=("${block} % Blockchance")
    [ "$regen" -gt 0 ] && parts+=("+${regen} Token/60 s")
    local out="" p
    for p in "${parts[@]}"; do
        [ -n "$out" ] && out+=" · "
        out+="$p"
    done
    printf '%s' "$out"
}
