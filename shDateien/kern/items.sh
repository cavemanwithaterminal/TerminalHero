# ============================================================
#  TerminalHero - Items & Inventar (Register)
#
#  Der KATALOG beschreibt alle Items der Welt; das INVENTAR hält fest,
#  was der Agent gerade bei sich trägt. Katalog und Inventar sind bewusst
#  getrennt: Der Katalog ist Code, das Inventar Spielzustand (wird im
#  Spielstand gesichert).
#
#  Items werden - wie Quests - von eigenen Dateien angemeldet:
#     Items/<Kategorie>/<Item>.sh   ->   item_define ...
#  Die Datei wird beim Start einmalig geladen (loader.sh: require_items).
#
#  Anmelden:
#     item_define <id> <spezial|quest|plunder|schmuck|waffen|ruestung> "<Name>" "<Beschreibung>" [<Wert>]
#  Der optionale <Wert> ist für das Handels-/Währungssystem reserviert und
#  wird derzeit nur mitgespeichert, nicht angezeigt. Die Währung selbst
#  heißt »Bit«/»Bits« (eigener Zähler BITS, KEIN Inventar-Item) - siehe den
#  Abschnitt »Währung (Bits)« weiter unten.
#
#  Eigenschaften (optional, nach item_define):
#     item_flag <id> unique   1     -> nur EIN Exemplar möglich (inv_add deckelt)
#     item_flag <id> sellable 0     -> unverkäuflich (fürs Handelssystem)
#     item_talk <id> <funktion>     -> beseelt: »touch« spricht den Gegenstand an
#     item_readable <id> "<text>"   -> lesbar: »benutzen« öffnet das Lesefenster
#                                     (InGameBefehle/Lesen.sh) und zeigt <text>
#     item_pickup_<id>()           -> übernimmt das Aufheben selbst (z. B. die
#                                     Bits: kein Inventar, sondern Kontostand)
#
#  Fundorte: Ein Item kann an mehreren Orten in der Welt liegen. Die Orte
#  melden sich beim Aufbau ihres Stadtteils an (world_item_place) - siehe
#  den Abschnitt »Welt-Gegenstände (Fundorte)« weiter unten. Aufgehoben wird
#  mit »grep« (TerminalBefehle/grep.sh); »cat« zeigt Inhalt, »file« Metadaten.
#
#  Kategorien (Reiter im Inventar, feste Reihenfolge):
#     spezial  - besondere, oft einmalige Gegenstände (z. B. die Armbanduhr)
#     quest    - Quest-Gegenstände (oft einmalig, an eine Aufgabe gebunden)
#     plunder  - Allerweltskram (»Plunder«), den man zuhauf findet und nur
#                für ein paar Bits verscherbelt
#     schmuck  - anlegbare Schmuckstücke (z. B. NeksAmulett), die trotz
#                Questbezug im Schmuck-Reiter liegen
#     waffen   - Kampfwaffen, die eine Zielkategorie (z. B. Viren) löschen
#     ruestung - tragbare Rüstung (Kopf, Oberkörper, Beine, Schild)
#
#  Nur Funktionsdefinitionen + Startwerte. Die Zeichenprimitive für das
#  Fenster liefert InGameBefehle/Inventar.sh.
# ============================================================

# ============================================================
#  Kategorien
# ============================================================
ITEM_CATS=(spezial quest plunder schmuck waffen ruestung)  # Reihenfolge = Reiter-Reihenfolge
declare -gA ITEM_CAT_LABEL=(                      # id -> Anzeigename
    [spezial]="Spezial"
    [quest]="Quest"
    [plunder]="Plunder"
    [schmuck]="Schmuck"
    [waffen]="Waffen"
    [ruestung]="Rüstung"
)

# ============================================================
#  Katalog (von Items/<Kategorie>/<Item>.sh gefüllt)
# ============================================================
declare -gA ITEM_NAME=()      # id -> Name
declare -gA ITEM_DESC=()      # id -> Beschreibung
declare -gA ITEM_CAT=()       # id -> Kategorie
declare -gA ITEM_VALUE=()     # id -> Wert (reserviert fürs Handelssystem)
declare -gA ITEM_UNIQUE=()    # id -> 1 = nur EINMAL besitzbar (z. B. Armbanduhr)
declare -gA ITEM_SELLABLE=()  # id -> 0 = unverkäuflich (fürs spätere Handelssystem)
declare -gA ITEM_TALK=()      # id -> Dialogfunktion (»touch« spricht den Gegenstand an)
declare -gA ITEM_READABLE=()  # id -> 1 = im Inventar lesbar
declare -gA ITEM_READ_TEXT=() # id -> vollständiger Text für das Lesefenster
declare -ga ITEM_IDS=()       # Anmelde-Reihenfolge (Katalog)

# Item anmelden (idempotent).
#   item_define <id> <spezial|quest|plunder|schmuck|waffen|ruestung> "<Name>" "<Beschreibung>" [<Wert>]
item_define() {
    local id="$1" cat="$2" name="$3" desc="$4" val="${5:-0}"
    [ -n "${ITEM_NAME[$id]:-}" ] && return 0
    ITEM_NAME["$id"]="$name"
    ITEM_DESC["$id"]="$desc"
    ITEM_CAT["$id"]="$cat"
    ITEM_VALUE["$id"]="$val"
    ITEM_IDS+=("$id")
}

item_exists() { [ -n "${ITEM_NAME[$1]:-}" ]; }
item_name()   { printf '%s' "${ITEM_NAME[$1]:-$1}"; }
item_desc()   { printf '%b' "${ITEM_DESC[$1]:-}"; }
item_cat()    { printf '%s' "${ITEM_CAT[$1]:-}"; }
item_value()  { printf '%s' "${ITEM_VALUE[$1]:-0}"; }

# Eigenschaften setzen/lesen: item_flag <id> <unique|sellable> <0|1>
item_flag() {
    case "$2" in
        unique)   ITEM_UNIQUE["$1"]="$3" ;;
        sellable) ITEM_SELLABLE["$1"]="$3" ;;
    esac
}
item_is_unique()   { [ "${ITEM_UNIQUE[$1]:-0}" = "1" ]; }
item_is_sellable() { [ "${ITEM_SELLABLE[$1]:-1}" = "1" ]; }

# Beseelten Gegenstand anmelden: item_talk <id> <funktion>
# Die Funktion läuft, wenn der Agent den Gegenstand anspricht (»touch«).
item_talk() { ITEM_TALK["$1"]="$2"; }

# Lesbaren Gegenstand anmelden: item_readable <id> "<text>"
# Der Text erscheint im Lesefenster, wenn im Inventar »benutzen« gewählt
# wird. Die kurze item_define-Beschreibung bleibt für die Detailspalte
# des Inventars; der hier hinterlegte Text darf deutlich länger sein.
item_readable() {
    ITEM_READABLE["$1"]=1
    ITEM_READ_TEXT["$1"]="$2"
}
item_is_readable() { [ "${ITEM_READABLE[$1]:-0}" = "1" ]; }
item_read_text()   { printf '%s' "${ITEM_READ_TEXT[$1]:-}"; }

# Anzeigename einer Kategorie (Fallback: die id selbst).
item_cat_label() { printf '%s' "${ITEM_CAT_LABEL[$1]:-$1}"; }

# Alle Katalog-IDs einer Kategorie (Reihenfolge der Anmeldung), je Zeile eine.
item_ids_in_cat() {
    local cat="$1" id
    for id in "${ITEM_IDS[@]}"; do
        [ "${ITEM_CAT[$id]:-}" = "$cat" ] && printf '%s\n' "$id"
    done
}

# ============================================================
#  Inventar des Spielers (Spielzustand, wird gespeichert)
# ============================================================
declare -gA INV_COUNT=()      # id -> Stückzahl
declare -ga INV_ORDER=()      # id in Erwerbs-Reihenfolge (stabile Anzeige)

# Item ins Inventar legen: inv_add <id> [Anzahl]  (nur bekannte Items)
# Einmalige Items (item_flag … unique 1) bleiben bei EINEM Exemplar.
# Rückgabe: 0 ok · 1 unbekanntes Item · 2 schon vorhanden (einmaliges Item)
inv_add() {
    local id="$1" n="${2:-1}"
    item_exists "$id" || return 1
    [ "$n" -gt 0 ] 2>/dev/null || return 0
    if item_is_unique "$id"; then
        inv_has "$id" && return 2      # nur EIN Exemplar möglich
        n=1
    fi
    [ -n "${INV_COUNT[$id]:-}" ] || INV_ORDER+=("$id")
    INV_COUNT[$id]=$(( ${INV_COUNT[$id]:-0} + n ))
    # Optionaler Haken: item_on_add_<id> darf auf den Zugriff reagieren
    local hook="item_on_add_${id}"
    if declare -F "$hook" >/dev/null 2>&1; then "$hook" "$n"; fi
    return 0
}

# Item aus dem Inventar nehmen: inv_remove <id> [Anzahl]
# Fällt die Stückzahl auf 0, verschwindet das Item auch aus der Reihenfolge.
inv_remove() {
    local id="$1" n="${2:-1}"
    [ -n "${INV_COUNT[$id]:-}" ] || return 1
    INV_COUNT[$id]=$(( INV_COUNT[$id] - n ))
    if [ "${INV_COUNT[$id]}" -le 0 ]; then
        unset "INV_COUNT[$id]"
        local out=() x
        for x in "${INV_ORDER[@]}"; do [ "$x" = "$id" ] || out+=("$x"); done
        INV_ORDER=("${out[@]}")
        # Ausrüstung, die das Inventar verlässt (verkauft, verschenkt,
        # abgelegt), wird automatisch abgelegt. Das gilt für JEDES
        # ausrüstbare Item, nicht nur für solche mit eigenem Haken.
        if declare -F equip_unwear >/dev/null 2>&1 \
           && equip_item_worn "$id"; then
            equip_unwear "$id"
        fi
        # Optionaler Haken: item_on_remove_<id> (z. B. Bierkiste verloren).
        local hook="item_on_remove_${id}"
        if declare -F "$hook" >/dev/null 2>&1; then "$hook" "$n"; fi
    fi
    return 0
}

inv_has()   { [ -n "${INV_COUNT[$1]:-}" ]; }
inv_count() { printf '%s' "${INV_COUNT[$1]:-0}"; }

# Stückzahl aller Items einer Kategorie (Summe).
inv_cat_count() {
    local cat="$1" id n=0
    for id in "${INV_ORDER[@]}"; do
        [ "${ITEM_CAT[$id]:-}" = "$cat" ] || continue
        n=$(( n + ${INV_COUNT[$id]:-0} ))
    done
    printf '%s' "$n"
}

# Besessene IDs einer Kategorie in Erwerbs-Reihenfolge (je Zeile eine).
inv_ids_in_cat() {
    local cat="$1" id
    for id in "${INV_ORDER[@]}"; do
        [ -n "${INV_COUNT[$id]:-}" ] || continue
        [ "${ITEM_CAT[$id]:-}" = "$cat" ] && printf '%s\n' "$id"
    done
}

# Inventar zurücksetzen (Frischstart).
inv_reset() { INV_COUNT=(); INV_ORDER=(); WORLD_ITEM=(); WORLD_N=(); WORLD_MODE=(); WORLD_TAKEN=(); WORLD_DROPS=(); }

# ============================================================
#  Welt-Gegenstände (Fundorte)
# ------------------------------------------------------------
#  Ein Item kann an mehreren Orten in der Welt "liegen". Die Orte melden
#  sich beim Aufbau ihres Stadtteils an:
#     world_item_place <id> <pfad> [<Anzahl>] [grep|use]
#  Ohne 4. Angabe wird der Fundort mit »grep <name>« herausgezogen. Mit
#  »use« gehört er zu den Gegenständen, die man BENUTZEN muss. Bits sind
#  ausdrücklich grep-Fundorte; der use-Modus bleibt für Sonderfälle frei.
#  items_world_refresh gleicht danach die Welt mit dem Inventar ab:
#     - schon aufgenommen (WORLD_TAKEN)      -> liegt NICHT mehr da
#     - einmaliges Item, das der Agent hat   -> liegt NICHT mehr da
#     - sonst                                -> liegt da
#  »cat« zeigt den Inhalt, »file« die Metadaten, »touch« spricht den
#  Gegenstand an (wenn er über item_talk beseelt ist).
# ============================================================
declare -ga ITEM_PLACES=()    # "id|anzahl|pfad|modus" – von den Weltdateien registriert
declare -gA WORLD_ITEM=()     # pfad -> id   (was GERADE in der Welt liegt)
declare -gA WORLD_N=()        # pfad -> Anzahl im Fundort
declare -gA WORLD_MODE=()     # pfad -> grep|use (wie man ihn aufnimmt)
declare -gA WORLD_TAKEN=()    # pfad -> 1    (schon aufgenommen; wird gespeichert)
# Vom Spieler ABGELEGTE Gegenstände (Inventar -> Welt). Anders als die
# festen Fundorte (ITEM_PLACES) entstehen sie zur Laufzeit und werden
# deshalb als eigener Spielzustand gespeichert:
#     pfad -> "id|anzahl"
declare -gA WORLD_DROPS=()

world_item_place() { ITEM_PLACES+=("$1|${3:-1}|$2|${4:-grep}"); }   # <id> <pfad> [<Anzahl>] [grep|use]

# Text, den »cat« an einem Fundort zeigt.
world_item_text() {   # $1 = Dateiname, $2 = id, $3 = Anzahl, $4 = modus
    local name="$1" id="$2" n="${3:-1}" mode="${4:-grep}" head
    if [ "$n" -gt 1 ]; then head="[ GEGENSTAND ]  ${name}  ×${n}"
    else                    head="[ GEGENSTAND ]  ${name}"; fi
    if [ "$mode" = "use" ]; then
        printf '%s\n' \
            "$head" \
            "$(item_desc "$id")" \
            "" \
            "»use ${name}«    →   einsammeln" \
            "»touch ${name}«  →   ansprechen"
    else
        printf '%s\n' \
            "$head" \
            "$(item_desc "$id")" \
            "" \
            "»grep ${name}«   →   herausziehen" \
            "»touch ${name}«  →   ansprechen"
    fi
}

# Fundort ins Dateisystem legen (idempotent).
world_item_add() {   # $1 = id, $2 = pfad, $3 = Anzahl, $4 = modus
    local id="$1" p="$2" n="${3:-1}" mode="${4:-grep}" parent name talk
    name="${p##*/}"
    if [ -z "${TYPE[$p]:-}" ]; then
        TYPE["$p"]="f"
        parent="${p%/*}"; [ -z "$parent" ] && parent="/"
        case $'\n'"${CHILDREN[$parent]}" in
            *$'\n'"$name"$'\n'*) ;;
            *) CHILDREN["$parent"]+="$name"$'\n' ;;
        esac
    fi
    CONTENT["$p"]="$(world_item_text "$name" "$id" "$n" "$mode")"
    WORLD_ITEM["$p"]="$id"
    WORLD_N["$p"]="$n"
    WORLD_MODE["$p"]="$mode"
    # Beseelte Gegenstände (item_talk) reagieren auf »touch« wie Figuren.
    talk="${ITEM_TALK[$id]:-}"
    if [ -n "$talk" ]; then DIALOG["$p"]="$talk"; else unset "DIALOG[$p]"; fi
}

# Fundort wieder entfernen (aus Dateisystem und Registern).
world_item_remove() {   # $1 = pfad
    local p="$1" parent name e new=""
    unset "WORLD_ITEM[$p]" "WORLD_N[$p]" "WORLD_MODE[$p]" "CONTENT[$p]" "DIALOG[$p]"
    [ -z "${TYPE[$p]:-}" ] && return 0
    [ -z "${TYPE[$p]:-}" ] && return 0
    unset "TYPE[$p]"
    parent="${p%/*}"; [ -z "$parent" ] && parent="/"
    name="${p##*/}"
    while IFS= read -r e; do
        [ -z "$e" ] && continue
        [ "$e" = "$name" ] || new+="$e"$'\n'
    done <<< "${CHILDREN[$parent]}"
    CHILDREN["$parent"]="$new"
}

# Dateiname eines abgelegten Gegenstands: der Anzeigename ohne Leerzeichen.
# »Einfacher Schlafsack« -> »EinfacherSchlafsack«. So bleibt der Name im
# Ordner lesbar, und »grep EinfacherSchlafsack« findet ihn direkt.
world_drop_filename() {   # $1 = Item-id
    local n
    n="$(item_name "$1")"
    n="${n// /}"
    n="${n//\//_}"
    [ -n "$n" ] || n="$1"
    printf '%s' "$n"
}

# Ablege-Datensatz entfernen (nach dem Aufheben oder beim Aufräumen).
world_drop_remove() {   # $1 = pfad
    [ -n "${WORLD_DROPS[$1]:-}" ] || return 0
    unset "WORLD_DROPS[$1]"
    return 0
}

# Abgelegte Gegenstände wieder in die Welt legen. Wird nach dem Laden
# eines Spielstands und nach dem Betreten eines Stadtteils aufgerufen.
# Nur Orte, deren Elternordner bereits existiert, werden aufgebaut.
world_drops_refresh() {
    local p rec id n parent
    for p in "${!WORLD_DROPS[@]}"; do
        rec="${WORLD_DROPS[$p]:-}"
        id="${rec%%|*}"; n="${rec#*|}"
        [ -n "$id" ] || continue
        [ -n "$n" ] || n=1
        parent="${p%/*}"; [ -z "$parent" ] && parent="/"
        [ -n "${TYPE[$parent]:-}" ] || continue
        world_item_add "$id" "$p" "$n" grep
    done
    return 0
}

# EINEN Gegenstand aus dem Inventar in den aktuellen Ordner legen.
# Mehrere Exemplare bleiben im Inventar; abgelegt wird genau eines.
world_item_drop() {   # $1 = Item-id, [$2 = Anzahl]
    local id="$1" n="${2:-1}" base p i=1 name
    item_exists "$id" || return 1
    [ "${INV_COUNT[$id]:-0}" -ge "$n" ] 2>/dev/null || return 1
    [ -n "${TYPE[$CWD]:-}" ] && [ "${TYPE[$CWD]}" = "d" ] || return 1
    name="$(world_drop_filename "$id")"
    base="$CWD/$name"
    p="$base"
    while [ -n "${TYPE[$p]:-}" ]; do
        i=$(( i + 1 ))
        p="${base}${i}"
    done
    world_item_add "$id" "$p" "$n" grep
    WORLD_DROPS["$p"]="$id|$n"
    unset "WORLD_TAKEN[$p]"
    inv_remove "$id" "$n"
    play_sound select
    OUT+=("")
    OUT+=("» $(item_name "$id") abgelegt.")
    return 0
}

# Alle Fundorte mit dem aktuellen Inventar abgleichen.
items_world_refresh() {
    local rec id n p parent mode
    for rec in "${ITEM_PLACES[@]}"; do
        id="${rec%%|*}"; rec="${rec#*|}"
        n="${rec%%|*}";  rec="${rec#*|}"
        p="${rec%%|*}"
        mode="grep"
        case "$rec" in *"|"*) mode="${rec#*|}" ;; esac
        [ -n "$mode" ] || mode="grep"
        [ -n "$id" ] && [ -n "$p" ] || continue
        parent="${p%/*}"; [ -z "$parent" ] && parent="/"
        if [ -n "${WORLD_TAKEN[$p]:-}" ] \
           || { item_is_unique "$id" && inv_has "$id"; } \
           || [ -z "${TYPE[$parent]:-}" ]; then
            world_item_remove "$p"
        else
            world_item_add "$id" "$p" "$n" "$mode"
        fi
    done
}

# Fundort aufheben: Item ins Inventar, Ort verschwindet. Rückgabe 0 = behandelt.
world_item_pickup() {   # $1 = pfad
    local p="$1" id="${WORLD_ITEM[$1]:-}" n="${WORLD_N[$1]:-1}"
    [ -n "$id" ] || return 1
    local _bn="${p##*/}"
    if [[ "$_bn" == .* ]]; then
        if [ "${SHOW_LS:-0}" != "1" ] || [ "${LS_SHOW_ALL:-0}" != "1" ] || [ "${VIEW_DIR:-}" != "${p%/*}" ]; then
            return 1
        fi
    fi
    world_drop_remove "$p"
    # Optionaler Haken: ein Item darf das Aufheben selbst übernehmen
    # (item_pickup_<id>, Rückgabe 0 = erledigt). So kommen die Bits auf den
    # Kontostand statt ins Inventar (Items/Spezial/Bits.sh).
    local pickup_hook="item_pickup_${id}"
    if declare -F "$pickup_hook" >/dev/null 2>&1; then
        "$pickup_hook" "$id" "$p" "$n" && return 0
    fi
    inv_add "$id" "$n"
    WORLD_TAKEN["$p"]=1
    world_item_remove "$p"
    play_sound select
    OUT+=("")
    if [ "$n" -gt 1 ]; then OUT+=("» ${n}× $(item_name "$id") aufgenommen.")
    else                    OUT+=("» $(item_name "$id") aufgenommen."); fi
    # Optionaler Haken: ein Item darf selbst etwas zum Aufheben sagen
    # (item_on_take_<id>, z. B. die Armbanduhr → Uhrzeit im GUI).
    local hook="item_on_take_${id}"
    if declare -F "$hook" >/dev/null 2>&1; then "$hook"; fi
    return 0
}

# ============================================================
#  Währung (Bits)
# ------------------------------------------------------------
#  Die Währung der Stadt heißt »Bit« (Einzahl) / »Bits« (Mehrzahl).
#  Geld ist KEIN Inventar-Gegenstand: Es gibt keinen Bits-Eintrag im
#  Inventar, sondern nur den Zähler BITS. Angezeigt wird er oben rechts
#  im Inventar-Fenster (InGameBefehle/Inventar.sh).
#
#  In der Welt liegt Geld als eigene Datei »Bits« (Items/Spezial/Bits.sh).
#  Alle Haufen werden mit »grep Bits« eingesammelt; wie viel ein Haufen
#  bringt, steht am Fundort:
#     world_item_place bits <pfad> <menge>  (z. B. 10 in der Baracke)
#
#  Preise/Bezahlung (z. B. Börtys Auskunft) bauen später auf bits_take auf.
# ============================================================
BITS=0                        # Spielzustand (wird im Spielstand gesichert)
BITS_EARNED=""                # Summe aller je gutgeschriebenen Bits (Statistik)
                              # leer = Altstand ohne diesen Wert (Migration)

bits_count() { printf '%s' "${BITS:-0}"; }
bits_total_earned() { printf '%s' "${BITS_EARNED:-0}"; }

# »1 Bit« / »7 Bits« – nur die Einzahl ist unregelmäßig.
bits_text() {   # $1 = Anzahl
    if [ "${1:-0}" = "1" ]; then printf '%s' "1 Bit"; else printf '%s' "${1:-0} Bits"; fi
}

bits_has() { [ "${BITS:-0}" -ge "${1:-0}" ] 2>/dev/null; }

bits_add() {   # $1 = Betrag einnehmen
    [ "${1:-0}" -gt 0 ] 2>/dev/null || return 0
    BITS=$(( ${BITS:-0} + $1 ))
    BITS_EARNED=$(( ${BITS_EARNED:-0} + $1 ))
    return 0
}

# Geld ausgeben: 0 = bezahlt, 1 = zu wenig Bits (dann wird nichts abgezogen).
bits_take() {   # $1 = Betrag
    [ "${1:-0}" -gt 0 ] 2>/dev/null || return 0
    [ "${BITS:-0}" -ge "$1" ] || return 1
    BITS=$(( BITS - $1 ))
    return 0
}

bits_reset() { BITS=0; BITS_EARNED=0; }
