# ============================================================
#  TerminalHero - Interior: Einrichtung & benutzbare Objekte
# ------------------------------------------------------------
#  "Interior" beschreibt DINGE IN DER WELT, die man BENUTZEN kann:
#  Möbel und Einrichtung (Matratze, Bett, Doppelbett, Stuhl, Sitzbank ...).
#
#  Anders als Items wandern Interior-Objekte NICHT ins Inventar: Sie
#  stehen fest an ihrem Ort. Sie sind aber ansprechbar (»touch«),
#  lesbar (»cat«), haben Metadaten (»file«) und lassen sich BENUTZEN
#  (»use«, InGameBefehle/use.sh). Beispiel: die Matratze in der
#  eingestürzten Baracke - »use Matratze« öffnet das Schlaf-Fenster.
#
#  Angemeldet werden sie - wie Items - von eigenen Dateien:
#     Interior/<Kategorie>/<Objekt>.sh   ->   interior_define ...
#  Der Loader lädt sie beim Start einmalig (loader.sh: require_interior).
#
#  Anmelden:
#     interior_define <id> <möbel|...> "<Name>" "<Beschreibung>"
#  Eigenschaften (optional, nach interior_define):
#     interior_talk <id> <funktion>    -> »touch« mustert/spricht es an
#     interior_use  <id> <funktion>    -> »use« benutzt es (z. B. schlafen/sitzen)
#     interior_sleep_rate <id> <n>     -> Tokens, die EINE Schlafstunde hier
#                                         bringt (Schlafplatz-Wert; die
#                                         Mechanik liest ihn von hier)
#     interior_sit_rate <id> <n>       -> Tokens, die EINE Sitzstunde hier
#                                         bringt (Sitzgelegenheit-Wert; die
#                                         Mechanik liest ihn von hier)
#     interior_file_text  <id> "<text>"-> Zusatztext für »file« (mehrzeilig)
#
#  Orte melden ihre Objekte an wie Fundorte:
#     interior_place <id> <pfad>
#  interior_world_refresh legt sie danach ins Dateisystem (nur solange
#  der Elternordner überhaupt existiert - also nur im geladenen Stadtteil).
#
#  Nur Funktionsdefinitionen + Register. Die Fenster/Primate kommen aus
#  ui.sh, die Kategorien-Anzeige aus diesem Register.
# ============================================================

# ============================================================
#  Kategorien
# ============================================================
declare -gA INTERIOR_KIND_LABEL=(                 # id -> Anzeigename
    [möbel]="Möbel"
    [stadt]="Stadt"
)

# ============================================================
#  Katalog (von Interior/<Kategorie>/<Objekt>.sh gefüllt)
# ============================================================
declare -gA INTERIOR_NAME=()      # id -> Name
declare -gA INTERIOR_KIND=()      # id -> Kategorie
declare -gA INTERIOR_DESC=()      # id -> Beschreibung
declare -gA INTERIOR_TALK=()      # id -> Dialogfunktion (»touch«)
declare -gA INTERIOR_USE=()       # id -> Benutzungs-Funktion (»use«)
declare -gA INTERIOR_REST=()      # id -> Tokens je geschlafener Stunde (Schlafplatz)
declare -gA INTERIOR_SIT=()       # id -> Tokens je Sitzstunde (Sitzgelegenheit)
declare -gA INTERIOR_FILE=()      # id -> Zusatztext für »file«
declare -ga INTERIOR_IDS=()       # Anmelde-Reihenfolge (Katalog)

# Objekt anmelden (idempotent).
#   interior_define <id> <möbel|...> "<Name>" "<Beschreibung>"
interior_define() {
    local id="$1" kind="$2" name="$3" desc="$4"
    [ -n "${INTERIOR_NAME[$id]:-}" ] && return 0
    INTERIOR_NAME["$id"]="$name"
    INTERIOR_DESC["$id"]="$desc"
    INTERIOR_KIND["$id"]="$kind"
    INTERIOR_IDS+=("$id")
}

interior_exists() { [ -n "${INTERIOR_NAME[$1]:-}" ]; }
interior_name()   { printf '%s' "${INTERIOR_NAME[$1]:-$1}"; }
interior_kind()   { printf '%s' "${INTERIOR_KIND[$1]:-}"; }
interior_desc()   { printf '%s' "${INTERIOR_DESC[$1]:-}"; }
interior_kind_label() { printf '%s' "${INTERIOR_KIND_LABEL[$1]:-$1}"; }

# Beseelt/betrachtbar: »touch« ruft <funktion> auf.
interior_talk() { INTERIOR_TALK["$1"]="$2"; }
# Benutzbar: »use« ruft <funktion> auf (bekommt die id als $1, den Pfad als $2).
interior_use()  { INTERIOR_USE["$1"]="$2"; }

# Schlafplatz-Wert: Tokens je geschlafener Stunde (0 = kein Schlafplatz).
interior_sleep_rate()    { INTERIOR_REST["$1"]="${2:-0}"; }
interior_sleep_rate_of() { printf '%s' "${INTERIOR_REST[$1]:-0}"; }

# Sitzgelegenheit-Wert: Tokens je Sitzstunde (0 = keine Sitzgelegenheit).
interior_sit_rate()    { INTERIOR_SIT["$1"]="${2:-0}"; }
interior_sit_rate_of() { printf '%s' "${INTERIOR_SIT[$1]:-0}"; }

# Zusatztext für »file« (mehrzeilig; \n werden beim Lesen übersetzt).
interior_file_text()    { INTERIOR_FILE["$1"]="$2"; }
interior_file_text_of() { printf '%b' "${INTERIOR_FILE[$1]:-}"; }

# ============================================================
#  Welt-Objekte (Aufstellung)
# ------------------------------------------------------------
#  Ein Objekt wird von seinem Ort angemeldet:
#     interior_place <id> <pfad>
#  interior_world_refresh legt es ins Dateisystem, sobald der
#  Elternordner existiert (Stadtteil geladen).
# ============================================================
declare -ga INTERIOR_PLACES=()    # "id|pfad" – von den Weltdateien registriert
declare -gA INTERIOR_AT=()        # pfad -> id   (was GERADE in der Welt steht)

interior_place() { INTERIOR_PLACES+=("$1|$2"); }

# Grundausstattung außerhalb der fünf Distrikte: je eine Sitzbank im
# DesktopCity-Ordner und im Haupteingang. Wird beim Start registriert;
# interior_world_refresh stellt sie auf, sobald die Ordner existieren.
interior_place_base_benches() {
    interior_place sitzbank "$HOME_DIR/Schreibtisch/DesktopCity/Sitzbank"
    interior_place sitzbank "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Sitzbank"
}

# Text, den »cat« an einem Interior-Objekt zeigt.
interior_text() {   # $1 = Dateiname, $2 = id
    local name="$1" id="$2"
    printf '%s\n' \
        "[ EINRICHTUNG ]  ${name}" \
        "$(interior_desc "$id")" \
        "" \
        "»use ${name}«    →   benutzen" \
        "»touch ${name}«  →   ansehen"
}

# Objekt ins Dateisystem legen (idempotent).
interior_add() {   # $1 = id, $2 = pfad
    local id="$1" p="$2" parent name talk
    name="${p##*/}"
    if [ -z "${TYPE[$p]:-}" ]; then
        TYPE["$p"]="f"
        parent="${p%/*}"; [ -z "$parent" ] && parent="/"
        case $'\n'"${CHILDREN[$parent]}" in
            *$'\n'"$name"$'\n'*) ;;
            *) CHILDREN["$parent"]+="$name"$'\n' ;;
        esac
    fi
    CONTENT["$p"]="$(interior_text "$name" "$id")"
    INTERIOR_AT["$p"]="$id"
    # Betrachtbare Objekte reagieren auf »touch«.
    talk="${INTERIOR_TALK[$id]:-}"
    if [ -n "$talk" ]; then DIALOG["$p"]="$talk"; else unset "DIALOG[$p]"; fi
}

# Objekt wieder entfernen (aus Dateisystem und Registern).
interior_remove() {   # $1 = pfad
    local p="$1" parent name e new=""
    unset "INTERIOR_AT[$p]" "CONTENT[$p]" "DIALOG[$p]"
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

# Alle angemeldeten Objekte mit der Welt abgleichen.
# Nur aufstellen, wenn der Elternordner existiert (Stadtteil geladen).
interior_world_refresh() {
    local rec id p parent
    for rec in "${INTERIOR_PLACES[@]}"; do
        id="${rec%%|*}"; p="${rec#*|}"
        [ -n "$id" ] && [ -n "$p" ] || continue
        parent="${p%/*}"; [ -z "$parent" ] && parent="/"
        if [ -z "${TYPE[$parent]:-}" ]; then
            interior_remove "$p"
        else
            interior_add "$id" "$p"
        fi
    done
}
