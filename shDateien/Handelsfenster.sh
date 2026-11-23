# ============================================================
#  TerminalHero - Handelsfenster (Shop / Trade Table)
#
#  Ein eigenes, vollflächiges Fenster - bewusst NICHT in die
#  4-Fenster-Spiel-GUI geladen. Es teilt den Bildschirm in DREI
#  große Fenster:
#
#     ┌ DEIN INVENTAR ──── 42 Bits ┐ ┌ TRADE TABLE ┐ ┌ Händler ─┐
#     │ [Spez] [Quest] [Plun]      │ │ ┌VERK┐┌KAUF┐ │ │ Reiter  │
#     │  ▸ LightBeer ×67     3 B   │ │ │ ×3 ││ ×1 │ │ │ ▸ Ware  │
#     │  ⊘ Armbanduhr              │ │ └────┘└────┘ │ │  ×10    │
#     └────────────────────────────┘ └─────────────┘ └─────────┘
#            Unter dem Mittelfenster: wer wem wie viele Bits zahlt
#
#  LINKS  (Spieler):   das Inventar des Agenten - dieselben Reiter
#                      (Kategorien) wie das Inventar-Fenster.
#  MITTE  (TradeTable): zweigeteilt. Links, was der Spieler VERKAUFEN
#                      will, rechts, was er KAUFEN will. Es wird erst
#                      beim Bestätigen wirklich getauscht: bis dahin ist
#                      alles nur "hingelegt" (nichts ist weg).
#  RECHTS (Händler):   das Lager des Händlers - dieselben Reiter.
#
#  BEDIENTASTEN
#     q              Fenster wechseln: Spieler <-> Händler
#                    (im TradeTable: linke <-> rechte Hälfte)
#     a/d, ←/→       Reiter wechseln (bzw. im TradeTable: Hälfte)
#     w/s, ↑/↓       Item wählen
#     e / Enter      EIN Item ins TradeTable schieben (bzw. zurück)
#     e / Enter HALTEN  nach 1 Sekunde läuft es von selbst: 10 Items
#                    je Sekunde, solange die Taste gedrückt bleibt
#     Tab            hinein ins TradeTable / wieder heraus
#     Esc            Handel abschließen?  (fragt nach: mit ↑/↓ wählen,
#                                              Enter bestätigen, 1/2/3 als
#                                              Abkürzung; Esc = zurück)
#
#  PREISE (shDateien/Items/...): Der <Wert> eines Items ist der
#  KAUFPREIS (so viel zahlt der Spieler beim Händler). Verkauft der
#  Spieler, zahlt der Händler den HALBEN Wert (mindestens 1 Bit).
#  Nicht handelbar sind Quest-Gegenstände und alles mit
#  item_flag <id> sellable 0 - sie tragen ein ⊘.
#
#  Der Händler hat IMMER genug Bits; sein Lager frischt sich jeden
#  neuen Spieltag wieder auf den Grundbestand auf (uhrzeit_day).
#
#  ============================================================
#  ANMELDEN EINES HÄNDLERS (in seiner Charakter-Datei, z. B.
#  Charakter/BörtySmiles.sh):
#
#     handel_define  <id> "<Anzeigename>"
#     handel_alias   <id> "Börty" "Börtys"      # wie man ihn tippt
#     handel_stock   <id> <item> <anzahl>       # Grundbestand je Tag
#
#  Damit »trade <name>« den Händler findet, ohne die halbe Welt zu
#  laden, gilt die Konvention: die Charakter-Datei stellt eine
#  Funktion handel_lager_<id> bereit (hier: handel_lager_boerty), die
#  den Händler anmeldet. Der Funktionsindex (kern/loader.sh) findet
#  sie - und lädt die Datei erst dann.
#
#  HANDELN NUR VOR ORT: Der Händler steht als beseelte Datei in einem
#  Ordner; »trade <name>« funktioniert nur, wenn genau dieser Ordner
#  der aktuelle ist (handel_here, geprüft in InGameBefehle/Trade.sh).
#  Angesprochen wird er dort mit »touch« - dessen Dialog bietet dann
#  »Handeln.« an (handel_start). Ein Orts-Check im Fenster selbst gibt
#  es nicht: wer den Dialog führt, steht ohnehin davor.
# ============================================================
#  Nur Funktionsdefinitionen; Zeichenprimitive (put_text, draw_box,
#  put_right, center_text, clear_region, repeat) aus kern/ui.sh.
# ============================================================

# ============================================================
#  Händler-Register
# ============================================================
declare -gA HANDEL_NAME=()     # id -> Anzeigename
declare -gA HANDEL_ALIAS=()    # id -> erlaubte Tippwörter (je Zeile eins, klein)
declare -gA HANDEL_BASE=()     # "id/item" -> Grundbestand (jeden Spieltag neu)
declare -gA HANDEL_STOCK=()    # "id/item" -> aktuelles Lager (im Spielstand)
declare -gA HANDEL_ORDER=()    # id -> Item-IDs des Lagers (je Zeile eins)
declare -gA HANDEL_DAY=()      # id -> Spieltag der letzten Auffrischung

# Händler anmelden (idempotent): handel_define <id> "<Name>"
handel_define() {
    local id="$1" name="$2"
    [ -n "$id" ] || return 1
    [ -n "${HANDEL_NAME[$id]:-}" ] && return 0
    HANDEL_NAME["$id"]="$name"
    HANDEL_ORDER["$id"]=""
    HANDEL_ALIAS["$id"]="${id,,}"$'\n'
    HANDEL_DAY["$id"]="$(uhrzeit_day)"
    return 0
}

# Weitere Tippwörter: handel_alias <id> <wort...>
handel_alias() {
    local id="$1"; shift
    [ -n "${HANDEL_NAME[$id]:-}" ] || return 1
    local w
    for w in "$@"; do
        [ -n "$w" ] || continue
        w="${w,,}"
        case "${HANDEL_ALIAS[$id]:-}" in
            *$'\n'"$w"$'\n'*) continue ;;
        esac
        HANDEL_ALIAS["$id"]="${HANDEL_ALIAS[$id]:-}${w}"$'\n'
    done
    return 0
}

# Ware ins Lager aufnehmen (Grundbestand): handel_stock <id> <item> <anzahl>
# Der Grundbestand ist, was der Händler an einem neuen Spieltag hat.
handel_stock() {
    local id="$1" item="$2" n="${3:-1}"
    [ -n "${HANDEL_NAME[$id]:-}" ] || return 1
    item_exists "$item" || return 1
    HANDEL_BASE["$id/$item"]="$n"
    case $'\n'"${HANDEL_ORDER[$id]}" in
        *$'\n'"$item"$'\n'*) ;;
        *) HANDEL_ORDER["$id"]="${HANDEL_ORDER[$id]}${item}"$'\n' ;;
    esac
    # Das LAUFENDE Lager nur setzen, wenn es noch keinen Eintrag gibt:
    # sonst würde jeder erneute Aufruf der Datei einen geladenen
    # Spielstand überschreiben.
    [ -n "${HANDEL_STOCK["$id/$item"]:-}" ] || HANDEL_STOCK["$id/$item"]="$n"
    return 0
}

handel_name()        { printf '%s' "${HANDEL_NAME[$1]:-$1}"; }
handel_defined()     { [ -n "${HANDEL_NAME[$1]:-}" ]; }
handel_stock_count() { printf '%s' "${HANDEL_STOCK["$1/$2"]:-0}"; }

# Gelagerte Item-IDs einer Kategorie (Lager-Reihenfolge, je Zeile eine).
handel_stock_in_cat() {
    local id="$1" cat="$2" item
    while IFS= read -r item; do
        [ -n "$item" ] || continue
        [ "${ITEM_CAT[$item]:-}" = "$cat" ] || continue
        printf '%s\n' "$item"
    done <<< "${HANDEL_ORDER[$id]:-}"
}

# Summe aller gelagerten Stücke einer Kategorie (für den Reiter).
handel_stock_cat_count() {
    local id="$1" cat="$2" item n=0
    while IFS= read -r item; do
        [ -n "$item" ] || continue
        n=$(( n + $(handel_stock_count "$id" "$item") ))
    done < <(handel_stock_in_cat "$id" "$cat")
    printf '%s' "$n"
}

handel_stock_add() {   # <id> <item> <n> - Ware kommt dazu (Verkauf des Spielers)
    local k="$1/$2" n="${3:-1}"
    HANDEL_STOCK["$k"]=$(( ${HANDEL_STOCK["$k"]:-0} + n ))
    return 0
}

handel_stock_take() {  # <id> <item> <n> - 0 = genommen, 1 = zu wenig
    local k="$1/$2" n="${3:-1}" have
    have="${HANDEL_STOCK["$k"]:-0}"
    [ "$have" -ge "$n" ] || return 1
    HANDEL_STOCK["$k"]=$(( have - n ))
    return 0
}

# Lager auf den Grundbestand zurücksetzen (neuer Spieltag).
handel_stock_reset() {
    local id="$1" k
    for k in "${!HANDEL_BASE[@]}"; do
        case "$k" in
            "$id/"*) HANDEL_STOCK["$k"]="${HANDEL_BASE[$k]}" ;;
        esac
    done
    return 0
}

# Jeden neuen Spieltag: Lager wieder auffüllen. Wird beim Öffnen des
# Handelsfensters aufgerufen - kauft der Agent den Laden leer, ist am
# nächsten Spieltag alles wieder da.
handel_day_sync() {
    local id="$1" today last
    today="$(uhrzeit_day)"
    last="${HANDEL_DAY[$id]:-}"
    if [ -z "$last" ]; then HANDEL_DAY["$id"]="$today"; return 0; fi
    [ "$last" = "$today" ] && return 0
    HANDEL_DAY["$id"]="$today"
    handel_stock_reset "$id"
    return 0
}

# Händler nach einem getippten Wort finden: "" = keiner.
handel_find() {
    local w="${1,,}" id a
    [ -n "$w" ] || return 0
    for id in "${!HANDEL_NAME[@]}"; do
        while IFS= read -r a; do
            [ -n "$a" ] || continue
            [ "$a" = "$w" ] && { printf '%s' "$id"; return 0; }
        done <<< "${HANDEL_ALIAS[$id]:-}"
    done
    for id in "${!HANDEL_NAME[@]}"; do            # zweite Runde: Wortanfang
        while IFS= read -r a; do
            [ -n "$a" ] || continue
            case "$a" in "$w"*) printf '%s' "$id"; return 0 ;; esac
        done <<< "${HANDEL_ALIAS[$id]:-}"
    done
    return 0
}

# Alle Händler-IDs (sortiert, für die Meldung "wen meinst du?").
handel_ids() { local k; for k in "${!HANDEL_NAME[@]}"; do printf '%s\n' "$k"; done | sort; }

# Handeln geht nur VOR ORT: Der Händler muß als beseelte Datei in genau dem
# Ordner liegen, in dem der Agent steht (der Dialog-Befehl »trade« ist kein
# Telefon). Die Welt weiß, wer wo steht - DIALOG[<pfad>] = dialog_<id>;
# geprüft wird nur der aktuelle Ordner, also nur das, was der Agent sieht.
handel_here() {   # <id> -> 0 = steht hier im Ordner
    local id="$1" fn="dialog_$1" name p
    [ -n "$id" ] || return 1
    for name in ${CHILDREN[$CWD]}; do
        p="$CWD/$name"
        [ "${DIALOG[$p]:-}" = "$fn" ] && return 0
    done
    return 1
}

# Alle Händler, die im aktuellen Ordner stehen (je Zeile).
handel_here_ids() {
    local id
    for id in $(handel_ids); do
        handel_here "$id" && printf '%s\n' "$id"
    done
    return 0
}

# ============================================================
#  Preise & Handelbarkeit
# ============================================================
# Kauf = voller Wert des Items (der Händler verkauft). Verkauf = halber
# Wert, mindestens 1 Bit - so ist auch Plunder für 1 Bit noch etwas wert.
handel_buy_price()  { printf '%s' "$(item_value "$1")"; }
handel_sell_price() {
    local v; v="$(item_value "$1")"
    [ "$v" -gt 0 ] 2>/dev/null || { printf '0'; return 0; }
    local h=$(( v / 2 ))
    [ "$h" -lt 1 ] && h=1
    printf '%s' "$h"
}

# Darf dieses Item überhaupt gehandelt werden? 0 = ja.
# Gesperrt sind Quest-Gegenstände und alles mit sellable 0 - AUSSER ein
# Gegenstand sagt ausdrücklich »sellable 1«: dann schlägt das die
# Quest-Sperre (so ist »Börtys Bierlieferung« handelbar, obwohl sie eine
# Quest ist - wer sie nicht ausliefert, darf sie verkaufen).
handel_tradable() {
    item_exists "$1" || return 1
    [ "${ITEM_SELLABLE[$1]:-}" = "1" ] && return 0
    [ "$(item_cat "$1")" = "quest" ] && return 1
    item_is_sellable "$1" || return 1
    return 0
}

# Warum nicht? (für die Meldung)
handel_block_text() {
    if [ "$(item_cat "$1")" = "quest" ]; then
        printf 'Das ist ein Quest-Gegenstand – das behalte ich.'
    else
        printf 'Das ist unverkäuflich.'
    fi
}

# ============================================================
#  Fensterzustand (flüchtig - nur während das Fenster offen ist)
# ============================================================
# Achtung: Diese Datei kann aus einer Funktion heraus nachgeladen werden
# (th_source_if_fn handel_define) - deshalb hier ALLES mit declare -g.
declare -g HS_ID=""            # Händler-id
declare -g HS_ZONE=0           # 0 = Seite (Inventar), 1 = TradeTable (Mitte)
declare -g HS_SIDE=0           # 0 = Spieler, 1 = Händler (in der Seiten-Zone)
declare -g HS_MID=0            # 0 = linke Hälfte (Verkauf), 1 = rechte (Kauf)
declare -ga HS_CAT=(0 0)       # Reiter je Seite
declare -ga HS_SEL=(0 0)       # Auswahl je Seite
declare -ga HS_MSEL=(0 0)      # Auswahl im TradeTable (je Hälfte)
declare -g HS_NOTICE=""        # kurze Meldung (z.B. "Das ist unverkäuflich.")

declare -gA HS_SELL_Q=()   # item -> Stück im Verkaufsfach
declare -ga HS_SELL_O=()   # Reihenfolge im Verkaufsfach
declare -gA HS_BUY_Q=()    # item -> Stück im Kauf-Fach
declare -ga HS_BUY_O=()    # Reihenfolge im Kauf-Fach

declare -ga HS_LIST_P=()   # sichtbare Items Spieler (vom Zeichnen gefüllt)
declare -ga HS_LIST_H=()   # sichtbare Items Händler (vom Zeichnen gefüllt)
declare -ga HS_TAB_LABELS=()  # Reiterbeschriftungen (vom Zeichnen gefüllt)

# --- Fächer (TradeTable) -------------------------------------------------
hs_sell_add() {   # <item> <n>
    local i="$1" n="${2:-1}"
    [ -n "${HS_SELL_Q[$i]:-}" ] || HS_SELL_O+=("$i")
    HS_SELL_Q[$i]=$(( ${HS_SELL_Q[$i]:-0} + n ))
}
hs_sell_take() {  # <item> <n> ; 1 = war nicht so viel drin
    local i="$1" n="${2:-1}" h
    h="${HS_SELL_Q[$i]:-0}"
    [ "$h" -ge "$n" ] || return 1
    h=$(( h - n ))
    if [ "$h" -le 0 ]; then
        unset "HS_SELL_Q[$i]"; hs_forget HS_SELL_O "$i"
    else
        HS_SELL_Q[$i]="$h"
    fi
    return 0
}
hs_buy_add() {
    local i="$1" n="${2:-1}"
    [ -n "${HS_BUY_Q[$i]:-}" ] || HS_BUY_O+=("$i")
    HS_BUY_Q[$i]=$(( ${HS_BUY_Q[$i]:-0} + n ))
}
hs_buy_take() {
    local i="$1" n="${2:-1}" h
    h="${HS_BUY_Q[$i]:-0}"
    [ "$h" -ge "$n" ] || return 1
    h=$(( h - n ))
    if [ "$h" -le 0 ]; then
        unset "HS_BUY_Q[$i]"; hs_forget HS_BUY_O "$i"
    else
        HS_BUY_Q[$i]="$h"
    fi
    return 0
}
# Ein Item aus einer Reihenfolge-Liste werfen (Liste per Namen).
hs_forget() {
    local name="$1" item="$2" x out=()
    local -n __o="$name"
    for x in "${__o[@]}"; do [ "$x" = "$item" ] || out+=("$x"); done
    __o=("${out[@]}")
}

# Cursor auf leere Listen schieben.
hs_clamp() {
    local n
    n="${#HS_LIST_P[@]}"; [ "${HS_SEL[0]}" -ge "$n" ] && HS_SEL[0]=$(( n > 0 ? n - 1 : 0 ))
    n="${#HS_LIST_H[@]}"; [ "${HS_SEL[1]}" -ge "$n" ] && HS_SEL[1]=$(( n > 0 ? n - 1 : 0 ))
    n="${#HS_SELL_O[@]}"; [ "${HS_MSEL[0]}" -ge "$n" ] && HS_MSEL[0]=$(( n > 0 ? n - 1 : 0 ))
    n="${#HS_BUY_O[@]}" ; [ "${HS_MSEL[1]}" -ge "$n" ] && HS_MSEL[1]=$(( n > 0 ? n - 1 : 0 ))
}

# Welche Items zeigen die beiden Inventar-Fenster? (nach Kategorie)
hs_fill_lists() {
    local cat id
    HS_LIST_P=()
    cat="${ITEM_CATS[${HS_CAT[0]:-0}]:-}"
    while IFS= read -r id; do
        [ -n "$id" ] && HS_LIST_P+=("$id")
    done < <(inv_ids_in_cat "$cat")
    HS_LIST_H=()
    cat="${ITEM_CATS[${HS_CAT[1]:-0}]:-}"
    while IFS= read -r id; do
        [ -n "$id" ] && HS_LIST_H+=("$id")
    done < <(handel_stock_in_cat "$HS_ID" "$cat")
    hs_clamp
}

# Wie viele Stücke sind in einem der beiden Inventar-Fenster noch zu
# haben? (Bestand minus das, was schon im TradeTable liegt.)
#   $1 = 0 Spieler | 1 Händler
hs_remain_of() {
    local i="$2"
    if [ "$1" = 0 ]; then
        printf '%s' $(( $(inv_count "$i") - ${HS_SELL_Q[$i]:-0} ))
    else
        printf '%s' $(( $(handel_stock_count "$HS_ID" "$i") - ${HS_BUY_Q[$i]:-0} ))
    fi
}

# Item unter dem Cursor ("" = keins).
hs_cursor() {
    local sel
    if [ "$HS_ZONE" = 1 ]; then
        if [ "$HS_MID" = 0 ]; then
            sel="${HS_MSEL[0]}"
            [ "${#HS_SELL_O[@]}" -gt 0 ] && [ "$sel" -lt "${#HS_SELL_O[@]}" ] && printf '%s' "${HS_SELL_O[$sel]}"
        else
            sel="${HS_MSEL[1]}"
            [ "${#HS_BUY_O[@]}" -gt 0 ] && [ "$sel" -lt "${#HS_BUY_O[@]}" ] && printf '%s' "${HS_BUY_O[$sel]}"
        fi
        return 0
    fi
    sel="${HS_SEL[$HS_SIDE]}"
    if [ "$HS_SIDE" = 0 ]; then
        [ "${#HS_LIST_P[@]}" -gt 0 ] && [ "$sel" -lt "${#HS_LIST_P[@]}" ] && printf '%s' "${HS_LIST_P[$sel]}"
    else
        [ "${#HS_LIST_H[@]}" -gt 0 ] && [ "$sel" -lt "${#HS_LIST_H[@]}" ] && printf '%s' "${HS_LIST_H[$sel]}"
    fi
}

# EIN Stück verschieben. 0 = verschoben, 1 = nichts (mehr) zu tun.
hs_move_one() {
    local i
    i="$(hs_cursor)"
    [ -n "$i" ] || return 1

    if [ "$HS_ZONE" = 1 ]; then                    # zurück aus dem TradeTable
        if [ "$HS_MID" = 0 ]; then hs_sell_take "$i" 1 || return 1
        else                       hs_buy_take  "$i" 1 || return 1; fi
        hs_clamp
        HS_NOTICE=""
        return 0
    fi

    if ! handel_tradable "$i"; then                # Quest / unverkäuflich
        HS_NOTICE="$(handel_block_text "$i")"
        play_sound error
        return 1
    fi
    if [ "$(hs_remain_of "$HS_SIDE" "$i")" -le 0 ]; then
        HS_NOTICE="Mehr habe ich davon nicht."
        return 1
    fi
    if [ "$HS_SIDE" = 0 ]; then                    # Spieler -> Verkaufsfach
        hs_sell_add "$i" 1
    else                                            # Händler -> Kauf-Fach
        hs_buy_add "$i" 1
    fi
    HS_NOTICE=""
    return 0
}

# --- Summen --------------------------------------------------------------
hs_sum_of() {   # <sell|buy> -> Bits
    local sum=0 i n p
    if [ "$1" = sell ]; then
        for i in "${HS_SELL_O[@]}"; do
            n="${HS_SELL_Q[$i]:-0}"; [ "$n" -gt 0 ] || continue
            p="$(handel_sell_price "$i")"
            sum=$(( sum + n * p ))
        done
    else
        for i in "${HS_BUY_O[@]}"; do
            n="${HS_BUY_Q[$i]:-0}"; [ "$n" -gt 0 ] || continue
            p="$(handel_buy_price "$i")"
            sum=$(( sum + n * p ))
        done
    fi
    printf '%s' "$sum"
}

# Saldo: > 0 = der Spieler ZAHLT, < 0 = der Spieler BEKOMMT.
hs_balance() { printf '%s' $(( $(hs_sum_of buy) - $(hs_sum_of sell) )); }

hs_staged() { [ "${#HS_SELL_O[@]}" -gt 0 ] || [ "${#HS_BUY_O[@]}" -gt 0 ]; }

# Wer schuldet wem wie viel? (eine Zeile fürs Fenster)
hs_tally_text() {
    local bal; bal="$(hs_balance)"
    if [ "$bal" -gt 0 ]; then
        printf 'Du zahlst %s.' "$(bits_text "$bal")"
    elif [ "$bal" -lt 0 ]; then
        printf '%s zahlt dir %s.' "$(handel_name "$HS_ID")" "$(bits_text $(( -bal )))"
    elif hs_staged; then
        printf 'Tausch ausgeglichen – niemand zahlt.'
    else
        printf 'Noch nichts hingelegt – Items mit e/Enter hinüber.'
    fi
}

# ============================================================
#  Zeichnen
# ============================================================
declare -g HS_GAP=1
declare -g HS_W=0              # Breite der beiden Inventarfenster
declare -g HS_MW=0             # Breite des Trade Table (Mitte)

hs_geom() {
    geom
    # Links und rechts die Inventarfenster, dazwischen das Trade Table.
    # Die Mitte trägt ZWEI Fächer nebeneinander (VERKAUF | KAUF) und muss
    # deshalb breiter sein als die Inventarfenster - sonst bleibt in einer
    # Fachzeile vom Item-Namen nichts übrig.
    local avail=$(( COLS - 2 - 2 * HS_GAP ))
    HS_MW=$(( avail / 3 + 8 ))
    [ "$HS_MW" -lt 37 ] && HS_MW=37                # Mindestbreite der Mitte
    HS_W=$(( (avail - HS_MW) / 2 ))
    [ "$HS_W" -lt 18 ] && HS_W=18
    [ "$HS_MW" -gt $(( avail - 2 * HS_W )) ] && HS_MW=$(( avail - 2 * HS_W ))
    HS_H=$(( ROWS - 3 ))
    [ "$HS_H" -lt 12 ] && HS_H=12
    HS_X1=1
    HS_X2=$(( HS_X1 + HS_W + HS_GAP ))
    HS_X3=$(( HS_X2 + HS_MW + HS_GAP ))
}

# Reiterbeschriftungen eines Inventars einsammeln (mit Stückzahl).
hs_tab_labels() {   # $1 = 0 Spieler | 1 Händler
    HS_TAB_LABELS=()
    local i c n lbl
    for i in "${!ITEM_CATS[@]}"; do
        c="${ITEM_CATS[i]}"
        if [ "$1" = 0 ]; then n="$(inv_cat_count "$c")"
        else                  n="$(handel_stock_cat_count "$HS_ID" "$c")"; fi
        lbl="$(item_cat_label "$c")"
        [ "$n" -gt 0 ] && lbl="${lbl} ${n}"
        HS_TAB_LABELS+=("$lbl")
    done
    return 0
}

# Reiter eines Inventars: in ein Drittel des Bildschirms passen nie alle,
# deshalb ◀ ▶ als Hinweis, dass es weitergeht.
hs_paint_tabs() {   # <zeile> <x> <breite> <aktiv> <fokus(0|1)>
    local row="$1" x0="$2" w="$3" act="$4" foc="$5"
    local n=${#HS_TAB_LABELS[@]} i t col x used first last
    local wid=()
    for i in "${!HS_TAB_LABELS[@]}"; do
        wid[i]=$(( ${#HS_TAB_LABELS[i]} + 4 ))     # "[ " + Label + " ]"
    done
    first="$act"; last="$act"; used="${wid[act]:-0}"
    local avail=$(( w - 3 ))                       # links "◀ " + rechts "▶"
    while [ "$first" -gt 0 ] && [ $(( used + 2 + wid[first - 1] )) -le "$avail" ]; do
        first=$(( first - 1 )); used=$(( used + 2 + wid[first] ))
    done
    while [ "$last" -lt $(( n - 1 )) ] && [ $(( used + 2 + wid[last + 1] )) -le "$avail" ]; do
        last=$(( last + 1 )); used=$(( used + 2 + wid[last] ))
    done

    x="$x0"
    if [ "$first" -gt 0 ]; then put_text "$row" "$x" 2 "◀ " "$MUTED"
    else                        put_text "$row" "$x" 2 "  "; fi
    x=$(( x + 2 ))
    for ((i = first; i <= last; i++)); do
        t="[ ${HS_TAB_LABELS[i]} ]"
        if [ "$i" = "$act" ]; then
            if [ "$foc" = "1" ]; then col="$ACCENT$BOLD"; else col="$TITLE$BOLD"; fi
        else
            col="$MUTED"
        fi
        put_text "$row" "$x" "${#t}" "$t" "$col"
        x=$(( x + ${#t} + 2 ))
    done
    [ "$last" -lt $(( n - 1 )) ] && put_right "$row" "$x0" "$w" "▶ " "$MUTED"
    return 0
}

# Eine Item-Liste zeichnen.
#   hs_paint_list <zeile> <x> <breite> <hoehe> <listen-name> <auswahl> <fokus> <art>
#   art: pl      = Inventar des Spielers (Restmenge, Verkaufspreis)
#        lager   = Lager des Händlers  (Restmenge, Kaufpreis)
#        sellfach= Verkaufsfach        (hingelegte Stück, Zeilensumme)
#        kauffach= Kauf-Fach           (hingelegte Stück, Zeilensumme)
hs_paint_list() {
    local row0="$1" x="$2" w="$3" h="$4" listname="$5" sel="$6" foc="$7" art="$8"
    local -n __l="$listname"
    local inner=$(( w - 2 ))
    local maxr=$(( row0 + h - 1 ))
    local row="$row0" j first=0 id mark col n price pcol label sum=0 p right textw
    [ "$h" -lt 1 ] && return 0

    if [ "${#__l[@]}" -eq 0 ]; then
        put_text "$row" "$((x + 2))" "$((inner - 2))" "(nichts)" "$MUTED"
        return 0
    fi
    [ "$sel" -ge "$h" ] && first=$(( sel - h + 1 ))

    for ((j = first; j < ${#__l[@]} && row <= maxr; j++)); do
        id="${__l[j]}"; mark="  "; col="$FG"
        if [ "$j" = "$sel" ]; then
            if [ "$foc" = "1" ]; then mark="▸ "; col="$ACCENT$BOLD"; else mark="· "; col="$TITLE$BOLD"; fi
        fi
        case "$art" in
            pl)       n="$(hs_remain_of 0 "$id")"; p="$(handel_sell_price "$id")"
                      price="${p} B" ;;
            lager)    n="$(hs_remain_of 1 "$id")"; p="$(handel_buy_price "$id")"
                      price="${p} B" ;;
            sellfach) n="${HS_SELL_Q[$id]:-0}"; p="$(handel_sell_price "$id")"
                      sum=$(( n * p )); price="${sum} B" ;;
            kauffach) n="${HS_BUY_Q[$id]:-0}"; p="$(handel_buy_price "$id")"
                      sum=$(( n * p )); price="${sum} B" ;;
            *)        n=0; price="-" ;;
        esac
        # Rechts steht immer die Stückzahl; der Preis nur, wenn Platz ist
        # (im schmalen Mittelfenster bleibt sonst kein Platz für den Namen).
        right="×${n}"
        if [ "$inner" -ge 26 ]; then right="×${n}  ${price}"; fi

        label="${mark}$(item_name "$id")"
        if ! handel_tradable "$id"; then
            label="${label} ⊘"; col="$MUTED"; pcol="$MUTED"
        else
            pcol="$GOOD"
        fi
        textw=$(( inner - 3 - ${#right} ))
        [ "$textw" -lt 4 ] && textw=4
        put_text "$row" "$((x + 2))" "$textw" "$label" "$col"
        [ "$inner" -ge 10 ] && \
            put_right "$row" "$((x + 2))" "$((inner - 2))" "$right" "$pcol"
        row=$(( row + 1 ))
    done
    return 0
}

# Infofenster unter dem Trade Table: Name und Beschreibung des Gegenstands,
# auf den der Cursor gerade zeigt. hs_cursor kennt alle vier Listen (Spieler,
# Händler, Verkaufsfach, Kauf-Fach), deshalb folgt der Text überall dem Cursor.
#   hs_paint_info <x> <y> <breite> <hoehe>
hs_paint_info() {
    local x="$1" y="$2" w="$3" h="$4"
    local id desc rest line inner row maxrow
    [ "$h" -lt 3 ] && return 0
    inner=$(( w - 4 ))                     # zwei Zellen Rand je Seite
    [ "$inner" -lt 4 ] && inner=4
    row=$(( y + 1 ))
    maxrow=$(( y + h - 2 ))

    id="$(hs_cursor)"
    if [ -z "$id" ]; then
        draw_box "$x" "$y" "$w" "$h" "BESCHREIBUNG" "$FRAME"
        put_text "$row" "$(( x + 2 ))" "$inner" "(kein Gegenstand gewählt)" "$MUTED"
        return 0
    fi
    draw_box "$x" "$y" "$w" "$h" "$(item_name "$id")" "$FRAME"

    # item_desc liefert die \n bereits als echte Zeilenumbrüche. Absätze und
    # lange Sätze werden einzeln umbrochen; was nicht mehr passt, fällt weg.
    desc="$(item_desc "$id")"
    rest="$desc"
    while [ -n "$rest" ] && [ "$row" -le "$maxrow" ]; do
        if [[ "$rest" == *$'\n'* ]]; then
            line="${rest%%$'\n'*}"
            rest="${rest#*$'\n'}"
        else
            line="$rest"; rest=""
        fi
        while IFS= read -r line; do
            [ "$row" -le "$maxrow" ] || break
            put_text "$row" "$(( x + 2 ))" "$inner" "$line" "$FG"
            row=$(( row + 1 ))
        done < <(wrap_line "$line" "$inner")
    done
    return 0
}

handel_paint() {
    # Das ganze Fenster in einem Rutsch schreiben (siehe ui_begin/ui_flush).
    # Ist bereits ein Puffer offen (Bestätigungsfenster), nur hineinzeichnen.
    local _own=0
    if [ "${UI_BATCH:-0}" != "1" ]; then ui_begin; _own=1; fi
    hs_geom
    hs_fill_lists
    local w="$HS_W" h="$HS_H" inner=$(( HS_W - 2 ))
    local mw="$HS_MW" minner=$(( HS_MW - 2 ))
    local foc_p=0 foc_h=0 foc_pl foc_hl
    if [ "$HS_ZONE" = 0 ] && [ "$HS_SIDE" = 0 ]; then foc_p=1; fi
    if [ "$HS_ZONE" = 0 ] && [ "$HS_SIDE" = 1 ]; then foc_h=1; fi
    foc_pl="$([ "$foc_p" = 1 ] && echo 1 || echo 0)"
    foc_hl="$([ "$foc_h" = 1 ] && echo 1 || echo 0)"

    # ---------- LINKS: Inventar des Spielers ----------
    local fcol="$FRAME"; [ "$foc_p" = "1" ] && fcol="$FRAME_HI"
    clear_region 2 2 "$inner" "$(( h - 2 ))"
    draw_box "$HS_X1" 1 "$w" "$h" "" "$fcol"
    # Titel und Bits teilen sich die Kopfzeile: der Titel bleibt links
    # zentriert, die Bits sitzen rechts. (In sehr schmalen Fenstern fallen
    # die Bits weg, damit der Titel nicht zerschnitten wird.)
    if [ "$inner" -lt 26 ]; then
        put_text 2 "$(( HS_X1 + 1 ))" "$inner" \
            "$(center_text '◤ DEIN INVENTAR ◢' "$inner")" "$TITLE$BOLD"
    else
        local hdr=$(( inner - 10 ))
        put_text 2 "$(( HS_X1 + 1 ))" "$hdr" \
            "$(center_text '◤ DEIN INVENTAR ◢' "$hdr")" "$TITLE$BOLD"
        put_right 2 "$(( HS_X1 + 1 ))" "$(( inner - 1 ))" \
            "$(bits_text "$(bits_count)")  " "$GOOD$BOLD"
    fi
    hs_tab_labels 0
    hs_paint_tabs 3 "$(( HS_X1 + 3 ))" "$(( inner - 2 ))" "${HS_CAT[0]}" "$foc_pl"
    put_text 4 "$(( HS_X1 + 1 ))" "$inner" "$(repeat '─' "$inner")" "$FRAME"
    hs_paint_list 5 "$HS_X1" "$w" "$(( h - 6 ))" HS_LIST_P "${HS_SEL[0]}" "$foc_pl" pl

    # ---------- RECHTS: Lager des Händlers ----------
    fcol="$FRAME"; [ "$foc_h" = "1" ] && fcol="$FRAME_HI"
    clear_region 2 "$(( HS_X3 + 1 ))" "$inner" "$(( h - 2 ))"
    draw_box "$HS_X3" 1 "$w" "$h" "" "$fcol"
    if [ "$inner" -lt 26 ]; then
        put_text 2 "$(( HS_X3 + 1 ))" "$inner" \
            "$(center_text "◤ $(handel_name "$HS_ID") ◢" "$inner")" "$TITLE$BOLD"
    else
        local hdr=$(( inner - 10 ))
        put_text 2 "$(( HS_X3 + 1 ))" "$hdr" \
            "$(center_text "◤ $(handel_name "$HS_ID") ◢" "$hdr")" "$TITLE$BOLD"
        put_right 2 "$(( HS_X3 + 1 ))" "$(( inner - 1 ))" "∞ Bits  " "$MUTED"
    fi
    hs_tab_labels 1
    hs_paint_tabs 3 "$(( HS_X3 + 3 ))" "$(( inner - 2 ))" "${HS_CAT[1]}" "$foc_hl"
    put_text 4 "$(( HS_X3 + 1 ))" "$inner" "$(repeat '─' "$inner")" "$FRAME"
    hs_paint_list 5 "$HS_X3" "$w" "$(( h - 6 ))" HS_LIST_H "${HS_SEL[1]}" "$foc_hl" lager

    # ---------- MITTE: Trade Table (zweigeteilt) ----------
    local fmid="$FRAME"
    if [ "$HS_ZONE" = 1 ]; then
        [ "$HS_MID" = 0 ] && fmid="$FRAME_HI"
    fi
    clear_region 2 "$(( HS_X2 + 1 ))" "$minner" "$(( h - 2 ))"
    draw_box "$HS_X2" 1 "$mw" "$h" "TRADE TABLE" "$fmid"

    local iw=$(( (minner - 3) / 2 ))
    [ "$iw" -lt 8 ] && iw=$(( minner / 2 - 1 ))
    local ix1 ix2
    ix1=$(( HS_X2 + 1 + (minner - (2 * iw + 1)) / 2 ))   # mittig im Fenster
    ix2=$(( ix1 + iw + 1 ))
    local iy=2 ih
    # Das untere Drittel des Trade Table gehört der Beschreibung; die beiden
    # Fächer bleiben darüber. Innen stehen h-2 Zeilen zur Verfügung.
    local innerh=$(( h - 2 ))
    local info_h=$(( innerh / 3 ))
    [ "$info_h" -lt 4 ] && info_h=4
    local info_y=$(( 2 + innerh - info_h ))
    ih=$(( info_y - iy ))
    local info_w=$(( 2 * iw + 1 ))
    local f1="$FRAME" f2="$FRAME"
    if [ "$HS_ZONE" = 1 ]; then
        if [ "$HS_MID" = 0 ]; then f1="$FRAME_HI"; else f2="$FRAME_HI"; fi
    fi
    draw_box "$ix1" "$iy" "$iw" "$ih" "VERKAUF" "$f1"
    draw_box "$ix2" "$iy" "$iw" "$ih" "KAUF"    "$f2"
    hs_paint_list $(( iy + 1 )) "$ix1" "$iw" "$(( ih - 2 ))" HS_SELL_O "${HS_MSEL[0]}" \
        "$([ "$HS_ZONE" = 1 ] && [ "$HS_MID" = 0 ] && echo 1 || echo 0)" sellfach
    hs_paint_list $(( iy + 1 )) "$ix2" "$iw" "$(( ih - 2 ))" HS_BUY_O "${HS_MSEL[1]}" \
        "$([ "$HS_ZONE" = 1 ] && [ "$HS_MID" = 1 ] && echo 1 || echo 0)" kauffach
    hs_paint_info "$ix1" "$info_y" "$info_w" "$info_h"

    # ---------- Unter dem Mittelfenster: die Verrechnung ----------
    local brow=$(( h + 1 ))
    clear_region "$brow" 1 "$COLS" 3
    local bal tcol
    bal="$(hs_balance)"; tcol="$MENU_C"
    [ "$bal" -gt 0 ] && tcol="$WARN"
    if [ "$bal" -gt 0 ] && ! bits_has "$bal"; then tcol="$DANGER"; fi
    put_text "$brow" "$HS_X2" "$mw" "$(hs_tally_text)" "$tcol"
    put_text $(( brow + 1 )) "$HS_X2" "$mw" \
        "Verkauf $(hs_sum_of sell) B · Kauf $(hs_sum_of buy) B · du hast $(bits_count) B" "$MUTED"
    if [ "$bal" -gt 0 ] && ! bits_has "$bal"; then
        put_text "$brow" "$HS_X2" "$mw" "$(hs_tally_text)" "$DANGER"
    fi
    if [ -n "$HS_NOTICE" ]; then
        put_text "$brow" "$HS_X1" "$w" "$HS_NOTICE" "$DANGER"
    fi

    # ---------- Fußzeile ----------
    local hint
    if [ "$HS_ZONE" = 1 ]; then
        hint="TRADE TABLE · q Hälfte · w/s Item · e zurücknehmen · Tab raus · Esc abschließen"
    else
        hint="q andere Seite · a/d Reiter · w/s Item · e hinlegen (halten = schnell) · Tab Tauschen · Esc abschließen"
    fi
    put_text "$ROWS" 1 "$COLS" "$(center_text "$hint" "$COLS")" "$MENU_C"
    [ "$_own" = "1" ] && ui_flush
    return 0
}

# ============================================================
#  Tasten
# ============================================================
hs_move_sel() {   # $1 = +/-1
    local n
    if [ "$HS_ZONE" = 1 ]; then
        if [ "$HS_MID" = 0 ]; then
            n="${#HS_SELL_O[@]}"
            [ "$n" -gt 0 ] && HS_MSEL[0]=$(( (HS_MSEL[0] + $1 + n) % n ))
        else
            n="${#HS_BUY_O[@]}"
            [ "$n" -gt 0 ] && HS_MSEL[1]=$(( (HS_MSEL[1] + $1 + n) % n ))
        fi
        return 0
    fi
    if [ "$HS_SIDE" = 0 ]; then n="${#HS_LIST_P[@]}"; else n="${#HS_LIST_H[@]}"; fi
    [ "$n" -gt 0 ] || return 0
    HS_SEL[$HS_SIDE]=$(( (HS_SEL[$HS_SIDE] + $1 + n) % n ))
    return 0
}

hs_move_cat() {   # $1 = +/-1
    if [ "$HS_ZONE" = 1 ]; then
        HS_MID=$(( (HS_MID + ($1 > 0 ? 1 : -1) + 2) % 2 ))
        return 0
    fi
    local n=${#ITEM_CATS[@]}
    local c=$(( HS_CAT[$HS_SIDE] + $1 ))
    [ "$c" -lt 0 ] && c=0
    [ "$c" -ge "$n" ] && c=$(( n - 1 ))
    HS_CAT[$HS_SIDE]="$c"
    HS_SEL[$HS_SIDE]=0
    return 0
}

hs_toggle_target() {   # q
    if [ "$HS_ZONE" = 1 ]; then HS_MID=$(( 1 - HS_MID ))
    else                        HS_SIDE=$(( 1 - HS_SIDE )); fi
    HS_NOTICE=""
    return 0
}

hs_toggle_zone() {     # Tab
    HS_ZONE=$(( 1 - HS_ZONE ))
    HS_NOTICE=""
    if [ "$HS_ZONE" = 1 ] && [ "$HS_MID" = 0 ] && [ "${#HS_SELL_O[@]}" -eq 0 ] && [ "${#HS_BUY_O[@]}" -gt 0 ]; then
        HS_MID=1                            # gleich dahin, wo etwas liegt
    fi
    return 0
}

# --- Tasten HALTEN: nach 1 s Schnellverschieben (10 Items/s) --------------
#  Ein Terminal meldet kein "losgelassen" - es schickt nur, solange die
#  Taste gedrückt ist, immer neue Zeichen (Autorepeat). Diese Wiederholungen
#  sind hier der Beweis, dass die Taste noch liegt: bleibt ein Zeichen länger
#  aus als das Dreifache des bisher größten Abstands (mind. 150 ms), gilt sie
#  als losgelassen.
hs_now_ms() {
    if [ -n "${EPOCHREALTIME:-}" ]; then printf '%s' $(( ${EPOCHREALTIME/./} / 1000 ))
    else                                 printf '%s' "$(date +%s%3N)"; fi
}
declare -g HS_FAST_DELAY=1000   # ms, bis es von selbst läuft
declare -g HS_FAST_STEP=100     # ms je Stück im Schnellmodus (=> 10/s)

hs_hold_run() {   # $1 = die gedrückte Taste
    local key="$1" t0 t_prev t_last t_move now gap gap_max=0 grace=700

    hs_move_one || { handel_paint; return 0; }
    handel_paint

    t0="$(hs_now_ms)"; t_prev="$t0"; t_last="$t0"; t_move="$t0"
    while :; do
        if read_key_t 0.05; then
            if [ "$LAST_KEY" = "$key" ]; then
                now="$(hs_now_ms)"
                gap=$(( now - t_prev ))
                t_prev="$now"; t_last="$now"
                [ "$gap" -gt "$gap_max" ] && gap_max="$gap"
                grace=$(( gap_max * 3 ))
                [ "$grace" -lt 150 ] && grace=150
                [ "$grace" -gt 900 ] && grace=900
            else
                KEYQ+=("$LAST_KEY")          # andere Taste: losgelassen
                return 0
            fi
        fi
        now="$(hs_now_ms)"
        [ $(( now - t_last )) -gt "$grace" ] && return 0     # losgelassen
        if [ $(( now - t0 )) -ge "$HS_FAST_DELAY" ]; then    # Schnellmodus
            if [ $(( now - t_move )) -ge "$HS_FAST_STEP" ]; then
                hs_move_one || return 0                       # nichts mehr da
                t_move="$now"
                handel_paint
            fi
        fi
    done
}

# ============================================================
#  Abschluss: fragen, rechnen, tauschen
# ============================================================
# Kleines Fenster über dem Handel: 1 bestätigen / 2 zurück / 3 abbrechen.
# Esc im Fenster = zurück (nichts passiert).
handel_confirm() {   # 1 = bestätigt | 2 = zurück | 3 = abgebrochen
    local w=48 h=9 x y
    [ "$COLS" -lt 56 ] && w=$(( COLS - 6 ))
    x=$(( (COLS - w) / 2 + 1 )); [ "$x" -lt 1 ] && x=1
    y=$(( (ROWS - h) / 2 + 1 )); [ "$y" -lt 1 ] && y=1

    local err="" sel=0 act i mark col text
    while true; do
        printf '%s' "$UI_BG"; clear
        ui_begin
        handel_paint
        clear_region "$(( y + 1 ))" "$(( x + 1 ))" "$(( w - 2 ))" "$(( h - 2 ))"
        draw_box "$x" "$y" "$w" "$h" "HANDEL ABSCHLIESSEN?" "$TITLE"
        local iw=$(( w - 4 )) row=$(( y + 1 ))
        put_text "$row" "$(( x + 2 ))" "$iw" "$(hs_tally_text)" "$MENU_C"; row=$(( row + 1 ))

        # Auswahl mit ↑/↓ (oder w/s) und Enter; 1/2/3 bleiben als Abkürzung.
        for i in 0 1 2; do
            case "$i" in
                0) text="Handel bestätigen" ;;
                1) text="zurück ins Handelsfenster" ;;
                2) text="Handel abbrechen (nichts ändert sich)" ;;
            esac
            if [ "$i" = "$sel" ]; then mark="▸"; col="$ACCENT$BOLD"
            else                       mark=" "; col="$FG"; fi
            put_text "$row" "$(( x + 2 ))" "$iw" "${mark} $(( i + 1 ))) ${text}" "$col"
            row=$(( row + 1 ))
        done

        if [ -n "$err" ]; then
            put_text "$row" "$(( x + 2 ))" "$iw" "$err" "$DANGER"
        else
            put_text "$row" "$(( x + 2 ))" "$iw" "↑/↓ wählen · Enter bestätigen · Esc zurück" "$MUTED"
        fi
        ui_flush

        read_key_t "" || return 2
        act=""
        case "$LAST_KEY" in
            $'\x1b[A'|$'\x1bOA'|w|W) [ "$sel" -gt 0 ] && sel=$(( sel - 1 )); continue ;;
            $'\x1b[B'|$'\x1bOB'|s|S) [ "$sel" -lt 2 ] && sel=$(( sel + 1 )); continue ;;
            1) act=0 ;;
            2) act=1 ;;
            3) act=2 ;;
            $'\n'|$'\r') act="$sel" ;;
            $'\x1b') return 2 ;;
            *) continue ;;
        esac

        case "$act" in
            0)
                if ! hs_staged; then err="Es liegt nichts im Trade Table."; continue; fi
                if handel_execute; then return 1; fi
                err="Dafür reichen meine Bits nicht."
                play_sound error ;;
            1) return 2 ;;
            2) return 3 ;;
        esac
    done
}

# Den Handel wirklich abwickeln. 0 = getauscht, 1 = zu wenig Bits.
# Bis hierher war alles nur "hingelegt": Hier wandern die Items und die
# Bits. Der Händler hat immer genug Geld.
handel_execute() {
    local bal; bal="$(hs_balance)"
    if [ "$bal" -gt 0 ] && ! bits_has "$bal"; then
        play_sound error
        return 1
    fi

    local i n name sell_lines=() buy_lines=() l
    # Verkauf: Spieler -> Händler
    for i in "${HS_SELL_O[@]}"; do
        n="${HS_SELL_Q[$i]:-0}"; [ "$n" -gt 0 ] || continue
        inv_remove "$i" "$n"
        handel_stock_add "$HS_ID" "$i" "$n"
        sell_lines+=("   verkauft: $(item_name "$i") ×${n}   (+$(( n * $(handel_sell_price "$i") )) Bits)")
    done
    # Kauf: Händler -> Spieler
    for i in "${HS_BUY_O[@]}"; do
        n="${HS_BUY_Q[$i]:-0}"; [ "$n" -gt 0 ] || continue
        if handel_stock_take "$HS_ID" "$i" "$n"; then
            if inv_add "$i" "$n"; then
                buy_lines+=("   gekauft : $(item_name "$i") ×${n}   (-$(( n * $(handel_buy_price "$i") )) Bits)")
            else
                handel_stock_add "$HS_ID" "$i" "$n"     # doch nicht (z. B. einmalig)
            fi
        fi
    done
    # Bits verrechnen
    if [ "$bal" -gt 0 ]; then bits_take "$bal"; else bits_add $(( -bal )); fi

    name="$(handel_name "$HS_ID")"
    play_sound select
    OUT+=("")
    OUT+=("[ HANDEL ]  Übergabe an ${name} – abgeschlossen.")
    for l in "${sell_lines[@]}"; do OUT+=("$l"); done
    for l in "${buy_lines[@]}"; do OUT+=("$l"); done
    if [ "$bal" -gt 0 ]; then
        OUT+=("   Saldo  : $(bits_text "$bal") gezahlt – neuer Stand: $(bits_text "$(bits_count)")")
    elif [ "$bal" -lt 0 ]; then
        OUT+=("   Saldo  : $(bits_text $(( -bal ))) erhalten – neuer Stand: $(bits_text "$(bits_count)")")
    else
        OUT+=("   Saldo  : ausgeglichen – Stand: $(bits_text "$(bits_count)")")
    fi
    return 0
}

# ============================================================
#  Das Fenster
# ============================================================
handel_screen() {
    play_sound select
    printf '%s' "$UI_BG"
    clear
    while true; do
        handel_paint
        read_key_t "" || break
        case "$LAST_KEY" in
            $'\x1b')                                   # abschließen?
                handel_confirm
                case "$?" in
                    1) break ;;                        # getauscht -> Fenster zu
                    3) break ;;                        # abgebrochen -> nichts
                esac ;;                                # 2 = weiter handeln
            q|Q)  hs_toggle_target ;;
            $'\t') hs_toggle_zone ;;
            $'\x1b[A'|$'\x1bOA'|w|W) hs_move_sel -1 ;;
            $'\x1b[B'|$'\x1bOB'|s|S) hs_move_sel  1 ;;
            $'\x1b[D'|$'\x1bOD'|a|A) hs_move_cat -1 ;;
            $'\x1b[C'|$'\x1bOC'|d|D) hs_move_cat  1 ;;
            $'\n'|$'\r'|e|E) hs_hold_run "$LAST_KEY" ;;
        esac
    done
    FIRST_RENDER=1
    return 0
}

# Handel mit einem Händler eröffnen: handel_start <id>
# Frischt zuvor das Lager auf, wenn ein neuer Spieltag begonnen hat.
handel_start() {
    local id="$1"
    if ! handel_defined "$id"; then
        OUT+=("Keinen Händler namens »${id}« gefunden.")
        return 1
    fi
    handel_day_sync "$id"
    HS_ID="$id"
    HS_ZONE=0; HS_SIDE=0; HS_MID=0
    HS_CAT=(0 0); HS_SEL=(0 0); HS_MSEL=(0 0)
    HS_SELL_Q=(); HS_SELL_O=()
    HS_BUY_Q=();  HS_BUY_O=()
    HS_NOTICE=""
    handel_screen
    return 0
}
