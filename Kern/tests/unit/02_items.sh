# ============================================================
#  Unit-Test-Teil: Items/Inventar, Interior und nutzbare Items
#  Wird von Kern/tests/unit.sh in fester Reihenfolge geladen.
# ============================================================
# ==================================================================
section "Items & Inventar"
# ==================================================================
ITEM_IDS=(); ITEM_NAME=(); ITEM_DESC=(); ITEM_CAT=(); ITEM_VALUE=(); ITEM_UNIQUE=()
item_define schluessel spezial "Schlüssel" "Ein alter Schlüssel." 12
item_define uhr spezial "Armbanduhr" "Zeigt die Zeit." 0
item_flag uhr unique 1
item_define brief quest "Pixis Brief" "Ein Brief." 0
item_define kiesel plunder "Kiesel" "Ein Kieselstein." 1
item_define schluessel spezial "ANDERS" "doppelt" 99
chk "item_define ist idempotent (Name)" "Schlüssel" "$(item_name schluessel)"
chk "item_value wird gemerkt" "12" "$(item_value schluessel)"
chk "item_ids_in_cat spezial (Reihenfolge)" "schluessel uhr" \
    "$(item_ids_in_cat spezial | tr '\n' ' ' | sed 's/ $//')"
chk_rc "item_is_unique uhr"     "$(item_is_unique uhr; echo $?)" 0
chk_rc "item_is_unique brief"   "$(item_is_unique brief; echo $?)" 1

INV_COUNT=(); INV_ORDER=()
chk_rc  "inv_add unbekanntes Item -> Fehler" "$(inv_add nix; echo $?)" 1
inv_add kiesel 3
chk "inv_count kiesel = 3" "3" "$(inv_count kiesel)"
inv_add uhr
chk_rc "einmaliges Item: 1. Aufruf -> 0 (ok)" "$(inv_add uhr; echo $?)" 2
chk "einmaliges Item bleibt 1 Exemplar" "1" "$(inv_count uhr)"
chk "INV_ORDER ohne Doppelte" "kiesel uhr" "${INV_ORDER[*]}"
chk "inv_cat_count plunder = 3" "3" "$(inv_cat_count plunder)"
inv_remove kiesel 3
chk "inv_remove bis 0 -> weg" "0" "$(inv_count kiesel)"
chk "INV_ORDER danach" "uhr" "${INV_ORDER[*]}"
inv_has uhr;   chk_rc "inv_has uhr" "$?" 0
inv_has kiesel; chk_rc "inv_has kiesel (leer)" "$?" 1

# --- Fundorte in der Welt -----------------------------------------
TYPE=(); CHILDREN=(); CONTENT=(); DIALOG=()
WORLD_ITEM=(); WORLD_N=(); WORLD_TAKEN=(); ITEM_PLACES=()
TYPE["/w"]="d"
world_item_place kiesel /w/Kiesel 3
items_world_refresh
chk "Fundort liegt in der Welt" "f" "${TYPE[/w/Kiesel]:-weg}"
chk "WORLD_N merkt die Menge"   "3" "${WORLD_N[/w/Kiesel]:-}"
chk "Fundort steht im Elternordner" "Kiesel" "$(printf '%s' "${CHILDREN[/w]}" | tr -d '\n')"
chk "cat-Text nennt grep als Aufheben" "1" "$(printf '%s' "${CONTENT[/w/Kiesel]}" | grep -c 'grep Kiesel')"

# Bits: der ECHTE Aufnahme-Haken aus dem Item (Items/Spezial/Bits.sh)
. "$SCRIPT_DIR/Items/Spezial/Bits.sh"
BITS=0
world_item_place bits /w/Bits 10
items_world_refresh
world_item_pickup /w/Bits; chk_rc "Bits aufheben -> behandelt" "$?" 0
chk "Bits auf dem Konto" "10" "$BITS"
chk "Bits NICHT im Inventar" "0" "$(inv_count bits)"
chk "aufgenommener Fundort ist markiert" "1" "${WORLD_TAKEN[/w/Bits]:-0}"
items_world_refresh
chk "aufgenommener Fundort liegt nicht mehr da" "" "${TYPE[/w/Bits]:-}"

# Währung
BITS=0
BITS_EARNED=0
bits_add 7;  chk "bits_add"           "7" "$(bits_count)"
chk "bits_add zählt verdiente Bits" "7" "$(bits_total_earned)"
bits_has 7;  chk_rc "bits_has 7"      "$?" 0
bits_has 8;  chk_rc "bits_has 8"      "$?" 1
bits_take 5; chk_rc "bits_take 5"     "$?" 0
chk "Kontostand nach Ausgabe" "2" "$(bits_count)"
chk "Ausgaben senken die Gesamtsumme nicht" "7" "$(bits_total_earned)"
bits_take 5; chk_rc "bits_take ohne Deckung -> Fehler" "$?" 1
chk "kein negativer Kontostand" "2" "$(bits_count)"
chk "bits_text 1 (Einzahl)" "1 Bit"  "$(bits_text 1)"
chk "bits_text 0 (Mehrzahl)" "0 Bits" "$(bits_text 0)"
chk "bits_text 5 (Mehrzahl)" "5 Bits" "$(bits_text 5)"

# ==================================================================
section "Interior"
# ==================================================================
INTERIOR_IDS=(); INTERIOR_NAME=(); INTERIOR_KIND=(); INTERIOR_DESC=()
INTERIOR_USE=(); INTERIOR_REST=(); INTERIOR_SIT=(); INTERIOR_FILE=()
INTERIOR_PLACES=(); INTERIOR_AT=()
interior_define matratze möbel "Matratze" "Eine durchgelegene Matratze."
interior_sleep_rate matratze 20
interior_define matratze möbel "ANDERS" "doppelt"
chk "interior_define idempotent" "Matratze" "$(interior_name matratze)"
chk "interior_kind" "möbel" "$(interior_kind matratze)"
chk "Schlafplatz-Wert" "20" "$(interior_sleep_rate_of matratze)"
chk "Kategorie-Anzeigename" "Möbel" "$(interior_kind_label möbel)"

TYPE=(); CHILDREN=(); CONTENT=(); DIALOG=()
TYPE["/baracke"]="d"
interior_place matratze /baracke/Matratze
interior_world_refresh
chk "Einrichtung liegt am Ort" "f" "${TYPE[/baracke/Matratze]:-weg}"
chk "cat erklärt use" "1" "$(printf '%s' "${CONTENT[/baracke/Matratze]}" | grep -c 'use Matratze')"
interior_world_refresh
chk "Aufstellen ist idempotent" "Matratze" "$(printf '%s' "${CHILDREN[/baracke]}" | tr -d '\n')"
unset 'TYPE[/baracke]'
interior_world_refresh
chk "ohne Elternordner verschwindet sie" "" "${TYPE[/baracke/Matratze]:-}"

# --- Die echten Möbeldateien (Schlafen & Sitzen) --------------------
# Der Loader findet sie rekursiv; hier werden sie direkt geladen, damit
# Preise/Werte und die Trennung von Schlafen und Sitzen prüfbar sind.
INTERIOR_IDS=(); INTERIOR_NAME=(); INTERIOR_KIND=(); INTERIOR_DESC=()
INTERIOR_USE=(); INTERIOR_REST=(); INTERIOR_SIT=(); INTERIOR_FILE=()
INTERIOR_PLACES=(); INTERIOR_AT=()
. "$SCRIPT_DIR/Interior/Möbel/Schlafgelegenheiten/Matratze.sh"
. "$SCRIPT_DIR/Interior/Möbel/Schlafgelegenheiten/Bett.sh"
. "$SCRIPT_DIR/Interior/Möbel/Schlafgelegenheiten/Doppelbett.sh"
. "$SCRIPT_DIR/Interior/Möbel/Sitzgelegenheiten/Stuhl.sh"
. "$SCRIPT_DIR/Interior/Möbel/Sitzgelegenheiten/Sitzbank.sh"
. "$SCRIPT_DIR/kern/sitzen.sh"

chk "Matratze: 20 Tokens je Schlafstunde" "20" "$(interior_sleep_rate_of matratze)"
chk "Bett: 35 Tokens je Schlafstunde" "35" "$(interior_sleep_rate_of bett)"
chk "Doppelbett: 50 Tokens je Schlafstunde" "50" "$(interior_sleep_rate_of doppelbett)"
chk "Matratze benutzt schlafen_start" "schlafen_start" "${INTERIOR_USE[matratze]:-}"
chk "Bett benutzt schlafen_start" "schlafen_start" "${INTERIOR_USE[bett]:-}"
chk "Doppelbett benutzt schlafen_start" "schlafen_start" "${INTERIOR_USE[doppelbett]:-}"
chk "Stuhl: 5 Tokens je Sitzstunde" "5" "$(interior_sit_rate_of stuhl)"
chk "Sitzbank: 5 Tokens je Sitzstunde" "5" "$(interior_sit_rate_of sitzbank)"
chk "Stuhl benutzt sitzen_start" "sitzen_start" "${INTERIOR_USE[stuhl]:-}"
chk "Sitzbank benutzt sitzen_start" "sitzen_start" "${INTERIOR_USE[sitzbank]:-}"
chk "Sitzgrenze am Stück" "12" "$SITZEN_MAX_STREAK"
chk "Sitzgrenze pro Spieltag" "12" "$SITZEN_MAX_DAY"
chk "Sitz-Bildschirm dauert 3 Sekunden" "3" "$SITZEN_BLACK_SECS"

# Sitzen verändert den Schlafzähler nicht und regeneriert 5 Tokens/Std.
uhrzeit_day() { printf '%s' "${TEST_DAY:-0}"; }
uhrzeit_advance_hours() { :; }
sitzen_black() { :; }
TOKENS_CUR=100; TOKENS_MAX=1000
SLEEP_HOURS_TODAY=7; SLEEP_DAY=0
SIT_HOURS_TODAY=0;  SIT_DAY=0
sitzen_do stuhl 5 3
chk "Sitzen regeneriert 5 Tokens je Stunde" "115" "$TOKENS_CUR"
chk "Sitzen zählt die Sitzstunden" "3" "$SIT_HOURS_TODAY"
chk "Sitzen setzt den Sitz-Tag" "0" "$SIT_DAY"
chk "Sitzen lässt Schlafstunden unberührt" "7" "$SLEEP_HOURS_TODAY"
chk "Sitzen lässt den Schlaf-Tag unberührt" "0" "$SLEEP_DAY"

# Das Sitzfenster bekommt nur noch das Tagesbudget (10 + 2 = 12).
SIT_HOURS_TODAY=10; SIT_DAY=0; SITZEN_TEST_MAX=""
sitzen_screen() { SITZEN_TEST_MAX="$3"; }
sitzen_start stuhl
chk "Sitzfenster begrenzt auf das Tagesbudget" "2" "$SITZEN_TEST_MAX"
SIT_HOURS_TODAY=12; SIT_DAY=0; OUT=()
sitzen_start stuhl
chk "mehr als 12 Sitzstunden am Tag wird abgelehnt" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c '12 Stunden gesessen')"

# Neuer Spieltag: der Sitzzähler wird zurückgesetzt, das volle Budget ist da.
TEST_DAY=1; SIT_HOURS_TODAY=12; SIT_DAY=0; SITZEN_TEST_MAX=""
sitzen_start stuhl
chk "neuer Spieltag setzt den Sitzzähler zurück" "0" "$SIT_HOURS_TODAY"
chk "neuer Spieltag gibt das volle Sitzbudget" "12" "$SITZEN_TEST_MAX"

# ==================================================================
section "Nutzbare Items: Schlafsack & Fackel"
# ==================================================================
# Die neuen Gegenstände liegen in NutzbareItems/ und werden - wie alle
# Items - über den Loader (require_items) angemeldet. Hier direkt geladen,
# damit Werte und Benutzungs-Haken ohne TUI prüfbar sind.
. "$SCRIPT_DIR/NutzbareItems/EinfacherSchlafsack.sh"
. "$SCRIPT_DIR/NutzbareItems/EinfacheFackel.sh"
. "$SCRIPT_DIR/NutzbareItems/Fackel2.sh"
. "$SCRIPT_DIR/kern/fackel.sh"

chk "Schlafsack heißt »Einfacher Schlafsack«" "Einfacher Schlafsack" \
    "$(item_name einfacherschlafsack)"
chk "Schlafsack ist Plunder" "plunder" "$(item_cat einfacherschlafsack)"
chk "Schlafsack kostet 200 Bits" "200" "$(item_value einfacherschlafsack)"
chk "Schlafsack hat einen Benutzen-Haken" "1" \
    "$(declare -F item_use_einfacherschlafsack >/dev/null && echo 1 || echo 0)"
chk "Fackel heißt »Einfache Fackel«" "Einfache Fackel" "$(item_name fackel)"
chk "Fackel ist Plunder" "plunder" "$(item_cat fackel)"
chk "Fackel kostet 20 Bits" "20" "$(item_value fackel)"
chk "Fackel hat einen Benutzen-Haken" "1" \
    "$(declare -F item_use_fackel >/dev/null && echo 1 || echo 0)"
chk "Fackel brennt 3 Spielstunden" "3" "$FACKEL_HOURS"
chk "Fackel-Brenndauer in Minuten" "180" "$FACKEL_MINUTES"
chk "Fackel heißt »Fackel«" "Fackel" "$(item_name fackel2)"
chk "Fackel ist Plunder" "plunder" "$(item_cat fackel2)"
chk "Fackel kostet 35 Bits" "35" "$(item_value fackel2)"
chk "Fackel hat einen Benutzen-Haken" "1" \
    "$(declare -F item_use_fackel2 >/dev/null && echo 1 || echo 0)"

# --- Zeitungen: lesbare Items --------------------------------------
# Die beiden DailyPulse-Ausgaben liegen in NutzbareItems/Zeitungen/.
# Sie sind weiterhin Quest-Items (Kästen/Tracey/Jimmy), lassen sich
# aber im Inventar über »benutzen« als vollständigen Artikel lesen.
. "$SCRIPT_DIR/NutzbareItems/Zeitungen/BezirkeDerStadt.sh"
. "$SCRIPT_DIR/NutzbareItems/Zeitungen/Sperrzone.sh"
. "$SCRIPT_DIR/InGameBefehle/Lesen.sh"
chk "Zeitungsordner existiert" "1" \
    "$([ -d "$SCRIPT_DIR/NutzbareItems/Zeitungen" ] && echo 1 || echo 0)"
chk "Bezirke-Ausgabe ist lesbar" "1" \
    "$(item_is_readable bezirke && echo 1 || echo 0)"
chk "Sperrzone-Ausgabe ist lesbar" "1" \
    "$(item_is_readable sperrzone && echo 1 || echo 0)"
chk "Bezirke-Artikel nennt den Norddistrikt" "2" \
    "$(item_read_text bezirke | grep -c 'Der Norddistrikt liegt im Norden')"
chk "Sperrzone-Artikel nennt den Kernsatz" "1" \
    "$(item_read_text sperrzone | grep -c 'Die Sperrzone ist kein Ort')"
chk "Fackel ist nicht lesbar" "1" \
    "$(item_is_readable fackel && echo 0 || echo 1)"
lesen_build_lines bezirke 40
chk "Lesefenster bricht den Artikel um" "1" \
    "$([ "${#LESEN_LINES[@]}" -gt 10 ] && echo 1 || echo 0)"
chk "Lesefenster behält Absätze" "1" \
    "$([ "$(printf '%s\n' "${LESEN_LINES[@]}" | grep -c '^$')" -gt 0 ] && echo 1 || echo 0)"

# --- Ablegen und wieder aufheben -----------------------------------
TYPE=(); CHILDREN=(); CONTENT=(); DIALOG=()
TYPE["/w"]="d"; CWD="/w"
inv_reset
inv_add einfacherschlafsack 2
OUT=()
world_item_drop einfacherschlafsack
chk "Ablegen nimmt genau 1 Exemplar aus dem Inventar" "1" \
    "$(inv_count einfacherschlafsack)"
chk "Schlafsack liegt im aktuellen Ordner" "f" \
    "${TYPE[/w/EinfacherSchlafsack]:-}"
chk "Ablegen merkt sich den Fundort" "einfacherschlafsack|1" \
    "${WORLD_DROPS[/w/EinfacherSchlafsack]:-}"
chk "Ablegen meldet sich im Ausgabefenster" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c 'Einfacher Schlafsack abgelegt')"
chk "cat verweist auf grep" "2" \
    "$(printf '%s' "${CONTENT[/w/EinfacherSchlafsack]}" | grep -c 'grep EinfacherSchlafsack')"

world_item_pickup /w/EinfacherSchlafsack
chk "grep hebt den Schlafsack wieder auf" "2" \
    "$(inv_count einfacherschlafsack)"
chk "Aufgehobener Ablege-Ort ist vergessen" "" \
    "${WORLD_DROPS[/w/EinfacherSchlafsack]:-}"
chk "Aufgehobener Schlafsack ist aus der Welt verschwunden" "" \
    "${TYPE[/w/EinfacherSchlafsack]:-}"

# »benutzen« beim Schlafsack ist dasselbe wie »ablegen«.
inv_reset
inv_add einfacherschlafsack 1
OUT=()
item_use_einfacherschlafsack
chk "Benutzen legt den Schlafsack in die Welt" "f" \
    "${TYPE[/w/EinfacherSchlafsack]:-}"
chk "Benutzen leert das Inventar" "0" "$(inv_count einfacherschlafsack)"

# Nach einem Neuladen werden abgelegte Gegenstände wieder aufgestellt.
world_item_remove /w/EinfacherSchlafsack
chk "vor dem Refresh: Datei weg" "" "${TYPE[/w/EinfacherSchlafsack]:-}"
world_drops_refresh
chk "Refresh stellt den abgelegten Schlafsack wieder auf" "f" \
    "${TYPE[/w/EinfacherSchlafsack]:-}"
chk "Refresh erhält den Fundort-Eintrag" "einfacherschlafsack|1" \
    "${WORLD_DROPS[/w/EinfacherSchlafsack]:-}"
inv_reset

# --- Fackel: Brenndauer und automatische Ordneransicht -------------
TEST_MIN=100
uhrzeit_minutes() { printf '%s' "$TEST_MIN"; }
TORCH_UNTIL_MIN=0
fackel_active; chk_rc "Fackel ist anfangs aus" "$?" 1
OUT=()
fackel_light
chk "Fackel brennt 180 Spielminuten" "280" "$TORCH_UNTIL_MIN"
chk "Fackel meldet »Fackel angezündet«" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c 'Fackel angezündet')"
fackel_active; chk_rc "Fackel ist nach dem Anzünden aktiv" "$?" 0
TEST_MIN=279
fackel_active; chk_rc "kurz vor Ablauf brennt sie noch" "$?" 0
TEST_MIN=280
fackel_active; chk_rc "genau nach 3 Stunden ist sie aus" "$?" 1
OUT=()
fackel_tick; chk_rc "Ablauf wird einmal gemeldet" "$?" 0
chk "Ablauf setzt die Brennzeit zurück" "0" "$TORCH_UNTIL_MIN"
chk "Ablauf-Meldung im Fenster" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c 'Fackel ist erloschen')"
fackel_tick; chk_rc "kein zweites Erlöschen" "$?" 1

# Benutzen-Haken zündet die Fackel an.
TEST_MIN=0; TORCH_UNTIL_MIN=0; OUT=()
item_use_fackel
chk "Fackel benutzen setzt die Brennzeit" "180" "$TORCH_UNTIL_MIN"
chk "Fackel benutzen meldet sich" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c 'Fackel angezündet')"
TORCH_UNTIL_MIN=0

# Die große Fackel brennt acht Stunden (480 Minuten).
fackel_light 8
chk "Fackel brennt 480 Spielminuten" "480" "$TORCH_UNTIL_MIN"
TORCH_UNTIL_MIN=0
OUT=(); inv_reset
inv_add fackel2 1
item_use_fackel2
chk "Fackel2 benutzen setzt die Brenndauer" "480" "$TORCH_UNTIL_MIN"
chk "Fackel2 benutzen verbraucht ein Exemplar" "0" "$(inv_count fackel2)"
TORCH_UNTIL_MIN=0

