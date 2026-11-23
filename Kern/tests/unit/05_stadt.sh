# ============================================================
#  Unit-Test-Teil: Stadtteile und DailyPulse-Zeitungskästen
#  Wird von Kern/tests/unit.sh in fester Reihenfolge geladen.
# ============================================================
# ==================================================================
section "Stadtteile"
# ==================================================================
BASE="$(district_base)"
CITY="$HOME_DIR/Schreibtisch/DesktopCity"
chk "district_base unter DesktopCity/Haupteingang" \
    "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang" "$BASE"
chk "Süddistrikt -> sued"    "sued"    "$(district_key_of_path "$BASE/Süddistrikt")"
chk "Ostdistrikt/tief -> ost" "ost"    "$(district_key_of_path "$BASE/Ostdistrikt/Detektei/x")"
chk "Zentrum -> zentrum"     "zentrum" "$(district_key_of_path "$BASE/Zentrum")"
chk "Westdistrikt -> west"   "west"    "$(district_key_of_path "$BASE/Westdistrikt/Bar")"
chk "Haupteingang selbst -> keiner" ""  "$(district_key_of_path "$BASE")"
chk "Haupteingang ist direktes Stadtziel" "$BASE" \
    "$(district_path_by_name Haupteingang)"
chk "Haupteingang auch klein geschrieben" "$BASE" \
    "$(district_path_by_name haupteingang)"
chk "Ostdistrikt ist direktes Stadtziel" "$BASE/Ostdistrikt" \
    "$(district_path_by_name Ostdistrikt)"
chk "außerhalb -> keiner"    ""        "$(district_key_of_path /etc/passwd)"
chk "fünf Stadtteile registriert" "5"  "${#DISTRICT_KEYS[@]}"
for k in "${DISTRICT_KEYS[@]}"; do
    chk "Datei für $k existiert" "1" \
        "$([ -f "$SCRIPT_DIR/Orte/${DISTRICT_FILE[$k]}" ] && echo 1 || echo 0)"
done

# ==================================================================
section "DailyPulse: Zeitungskästen & Jacks Rückholquest"
# ==================================================================
# Die neuen Item-/Interior-Dateien werden wie im Spiel geladen. Die
# Stadtteil-Dateien werden anschließend nur aufgerufen, um die fünf
# Kästen zu registrieren (Sherlock-Terminplanung wird gestubbt).
. "$SCRIPT_DIR/NutzbareItems/Zeitungen/BezirkeDerStadt.sh"
. "$SCRIPT_DIR/NutzbareItems/Zeitungen/Sperrzone.sh"
. "$SCRIPT_DIR/NutzbareItems/Zeitungen/ExtraAusgabe.sh"
. "$SCRIPT_DIR/Items/Quest/SperrzoneBuendel.sh"
. "$SCRIPT_DIR/Items/Quest/Zeitungsbündel.sh"
. "$SCRIPT_DIR/Items/Quest/Zeitungsschluessel.sh"
. "$SCRIPT_DIR/Items/Plunder/LeeresBlattPapier.sh"
. "$SCRIPT_DIR/Items/Plunder/BuendelLeeresPapier.sh"
. "$SCRIPT_DIR/Interior/Stadt/Zeitungskasten.sh"
. "$SCRIPT_DIR/Charakter/verlag.sh"

chk "erste Ausgabe heißt »Bezirke der Stadt«" "Bezirke der Stadt" "$(item_name bezirke)"
chk "Leeres Papier heißt »Leeres Blatt Papier«" "Leeres Blatt Papier" \
    "$(item_name leeresblatt)"
chk "Leeres Papier ist Plunder" "plunder" "$(item_cat leeresblatt)"
chk "Leeres Papier kostet 2 Bits" "2" "$(handel_buy_price leeresblatt)"
chk "Leeres Papier bringt 1 Bit beim Verkauf" "1" \
    "$(handel_sell_price leeresblatt)"
chk "Papierbündel heißt »Bündel Leeres Papier«" "Bündel Leeres Papier" \
    "$(item_name papierbuendel)"
chk "Papierbündel ist Plunder" "plunder" "$(item_cat papierbuendel)"
chk "Papierbündel kostet 200 Bits" "200" "$(handel_buy_price papierbuendel)"
chk "Papierbündel bringt 100 Bits beim Verkauf" "100" \
    "$(handel_sell_price papierbuendel)"

# Jacks Papierlager: pro Spieltag 100 einzelne Blätter und ein Bündel.
handel_lager_jack
chk "Jack ist als Händler angemeldet" "Jack Nullpunkt" "$(handel_name jack)"
chk "Jack über Alias gefunden" "jack" "$(handel_find Jack)"
chk "Jack: 100 Blätter am Tag" "100" \
    "$(handel_stock_count jack leeresblatt)"
chk "Jack: 1 Papierbündel am Tag" "1" \
    "$(handel_stock_count jack papierbuendel)"
HANDEL_STOCK["jack/leeresblatt"]=0
HANDEL_STOCK["jack/papierbuendel"]=0
HANDEL_DAY[jack]=0
WORLD_SECS=86400
handel_day_sync jack
chk "Jack: Blätter am nächsten Tag wieder da" "100" \
    "$(handel_stock_count jack leeresblatt)"
chk "Jack: Bündel am nächsten Tag wieder da" "1" \
    "$(handel_stock_count jack papierbuendel)"
WORLD_SECS=0
HANDEL_DAY[jack]="$(uhrzeit_day)"
chk "Zeitungsbündel-Item" "Zeitungsbündel" "$(item_name zeitungsbuendel)"
chk "Schlüssel-Item" "Zeitungskastenschlüssel" "$(item_name zeitungsschluessel)"
chk_rc "Schlüssel ist einmalig" "$(item_is_unique zeitungsschluessel; echo $?)" 0
chk "Zeitung ist nicht einmalig" "0" "${ITEM_UNIQUE[bezirke]:-0}"
chk "zweite Ausgabe heißt »Die Sperrzone«" "Die Sperrzone" "$(item_name sperrzone)"
chk "Sperrzone ist nicht einmalig" "0" "${ITEM_UNIQUE[sperrzone]:-0}"
chk "Sperrzone ist unverkäuflich" "0" "${ITEM_SELLABLE[sperrzone]:-1}"
chk "Extra-Ausgabe heißt »Extra-Ausgabe: Nek Molerat«" \
    "Extra-Ausgabe: Nek Molerat" "$(item_name extraausgabe)"
chk "Extra-Ausgabe ist nicht einmalig" "0" "${ITEM_UNIQUE[extraausgabe]:-0}"
chk "Extra-Ausgabe ist unverkäuflich" "0" "${ITEM_SELLABLE[extraausgabe]:-1}"
ZEITUNG_EXTRA_DAY=7
ZEITUNG_EXTRA_UNTIL=11
zeitung_extra_available_on 6; chk_rc "Extra-Ausgabe vor dem Start" "$?" 1
zeitung_extra_available_on 7; chk_rc "Extra-Ausgabe am ersten Tag" "$?" 0
zeitung_extra_available_on 9; chk_rc "Extra-Ausgabe mittendrin" "$?" 0
zeitung_extra_available_on 11; chk_rc "Extra-Ausgabe am letzten Tag" "$?" 0
zeitung_extra_available_on 12; chk_rc "Extra-Ausgabe nach dem Zeitraum" "$?" 1
ZEITUNG_EXTRA_DAY=-1; ZEITUNG_EXTRA_UNTIL=-1
chk "Sperrzone-Bündel-Item" "Sperrzone-Bündel" "$(item_name sperrzonebuendel)"
chk "Sperrzone-Bündel ist nicht einmalig" "0" "${ITEM_UNIQUE[sperrzonebuendel]:-0}"
chk "Sperrzone-Bündel ist unverkäuflich" "0" "${ITEM_SELLABLE[sperrzonebuendel]:-1}"
chk "Kasten kostet 10 Bits" "10" "$ZEITUNG_PRICE"
chk "Kasten ist Interior »stadt«" "stadt" "$(interior_kind zeitungskasten)"
chk "Kasten hat eine use-Funktion" "zeitungskasten_use" "${INTERIOR_USE[zeitungskasten]:-}"

BASE="$(district_base)"
P_SUED="$BASE/Süddistrikt/Zeitungskasten"
P_NORD="$BASE/Norddistrikt/Zeitungskasten"
P_WEST="$BASE/Westdistrikt/Zeitungskasten"
P_OST="$BASE/Ostdistrikt/Zeitungskasten"
P_ZENTRUM="$BASE/Zentrum/Zeitungskasten"
chk "Kasten Süd = Bit 0" "0" "$(zeitung_box_index "$P_SUED")"
chk "Kasten Nord = Bit 1" "1" "$(zeitung_box_index "$P_NORD")"
chk "Kasten West = Bit 2" "2" "$(zeitung_box_index "$P_WEST")"
chk "Kasten Ost = Bit 3" "3" "$(zeitung_box_index "$P_OST")"
chk "Kasten Zentrum = Bit 4" "4" "$(zeitung_box_index "$P_ZENTRUM")"
chk "Kasten außerhalb = kein Bezirk" "-1" "$(zeitung_box_index /tmp/Kasten)"
chk "Bezirksname am Kasten" "Ostdistrikt" "$(zeitung_box_label "$P_OST")"

ZEITUNG_EDITION=bezirke
chk "aktuelle Edition" "bezirke" "$(zeitung_current_edition)"
ZEITUNG_EMPTIED=0
zeitung_box_mark_empty "$P_SUED"
chk "Süd leer" "1" "$(zeitung_boxes_emptied)"
zeitung_box_is_empty "$P_SUED"; chk_rc "Süd meldet leer" "$?" 0
zeitung_box_is_empty "$P_NORD"; chk_rc "Nord ist noch voll" "$?" 1
zeitung_box_mark_empty "$P_NORD"; chk "zwei Kästen leer" "2" "$(zeitung_boxes_emptied)"
zeitung_box_mark_empty "$P_NORD"; chk_rc "zweites Leeren -> schon leer" "$?" 1
chk "zweites Leeren gibt kein Extra-Bündel" "2" "$(zeitung_boxes_emptied)"
zeitung_set_edition bezirke
chk "neue Edition füllt alle Kästen" "0" "$(zeitung_boxes_emptied)"
chk "fünf Kästen sind gefüllt" "5" "$(zeitung_boxes_filled)"

# Rachels neue Auflage: Edition setzen, aber alle Kästen warten auf die
# fünf Bündel. Jeder Kasten wird genau einmal befüllt.
zeitung_await_distribution sperrzone
chk "Verteilung: Edition ist sperrzone" "sperrzone" "$ZEITUNG_EDITION"
chk "Verteilung: alle fünf Kästen leer" "31" "$ZEITUNG_EMPTIED"
chk "Verteilung: noch kein Kasten befüllt" "0" "$(zeitung_boxes_filled)"
zeitung_box_mark_filled "$P_SUED"; chk_rc "Süden befüllen" "$?" 0
chk "ein Kasten befüllt" "1" "$(zeitung_boxes_filled)"
zeitung_box_is_empty "$P_SUED"; chk_rc "Süden ist jetzt gefüllt" "$?" 1
zeitung_box_mark_filled "$P_SUED"; chk_rc "Süden nicht doppelt befüllen" "$?" 1
chk "weiterhin ein Kasten befüllt" "1" "$(zeitung_boxes_filled)"
for p in "$P_NORD" "$P_WEST" "$P_OST" "$P_ZENTRUM"; do zeitung_box_mark_filled "$p"; done
chk "alle fünf Kästen befüllt" "5" "$(zeitung_boxes_filled)"
chk "keine leeren Kästen mehr" "0" "$ZEITUNG_EMPTIED"
zeitung_set_edition bezirke
chk "Edition wechseln füllt alle Kästen" "0" "$(zeitung_boxes_emptied)"

INTERIOR_PLACES=()
sherlock_schedule_apply() { :; }
. "$SCRIPT_DIR/Orte/Süddistrikt.sh"
. "$SCRIPT_DIR/Orte/Norddistrikt.sh"
. "$SCRIPT_DIR/Orte/Westdistrikt.sh"
. "$SCRIPT_DIR/Orte/Ostdistrikt.sh"
. "$SCRIPT_DIR/Orte/Zentrum.sh"
district_build_sued
district_build_nord
district_build_west
district_build_ost
district_build_zentrum
chk "fünf Zeitungskästen registriert" "5" \
    "$(printf '%s\n' "${INTERIOR_PLACES[@]}" | grep -c '^zeitungskasten|')"
for p in "$P_SUED" "$P_NORD" "$P_WEST" "$P_OST" "$P_ZENTRUM"; do
    chk "Kasten registriert: ${p##*/Haupteingang/}" "1" \
        "$(printf '%s\n' "${INTERIOR_PLACES[@]}" | grep -cx "zeitungskasten|$p")"
done

# --- SurvivalShop im Zentrum ---------------------------------------
SHOP="$BASE/Zentrum/SurvivalShop"
chk "SurvivalShop ist ein Ordner" "d" "${TYPE[$SHOP]:-}"
chk "JackBones steht im SurvivalShop" "f" "${TYPE[$SHOP/JackBones]:-}"
chk "JackBones-Dialog ist registriert" "dialog_jackbones" \
    "${DIALOG[$SHOP/JackBones]:-}"
chk "SurvivalShop hat eine eigene Ortsdatei" "1" \
    "$([ -f "$SCRIPT_DIR/Orte/SurvivalShop.sh" ] && echo 1 || echo 0)"
chk "JackBones hat eine eigene Charakterdatei" "1" \
    "$([ -f "$SCRIPT_DIR/Charakter/JackBones.sh" ] && echo 1 || echo 0)"

# --- Schmiede im Zentrum -------------------------------------------
SCHMIEDE="$BASE/Zentrum/Schmiede"
chk "Schmiede ist ein Ordner" "d" "${TYPE[$SCHMIEDE]:-}"
chk "BrunoAmboss steht in der Schmiede" "f" \
    "${TYPE[$SCHMIEDE/BrunoAmboss]:-}"
chk "BrunoAmboss-Dialog ist registriert" "dialog_brunoamboss" \
    "${DIALOG[$SCHMIEDE/BrunoAmboss]:-}"
chk "Schmiede hat eine eigene Ortsdatei" "1" \
    "$([ -f "$SCRIPT_DIR/Orte/Schmiede.sh" ] && echo 1 || echo 0)"
chk "BrunoAmboss hat eine eigene Charakterdatei" "1" \
    "$([ -f "$SCRIPT_DIR/Charakter/BrunoAmboss.sh" ] && echo 1 || echo 0)"

# --- Sitzbänke: fünf Distrikte + DesktopCity + Haupteingang ---------
interior_place_base_benches
chk "sieben Sitzbänke registriert" "7" \
    "$(printf '%s\n' "${INTERIOR_PLACES[@]}" | grep -c '^sitzbank|')"
for p in "$BASE/Süddistrikt/Sitzbank" "$BASE/Norddistrikt/Sitzbank" \
         "$BASE/Westdistrikt/Sitzbank" "$BASE/Ostdistrikt/Sitzbank" \
         "$BASE/Zentrum/Sitzbank" "$CITY/Sitzbank" \
         "$BASE/Sitzbank"; do
    chk "Sitzbank registriert: ${p#$CITY/}" "1" \
        "$(printf '%s\n' "${INTERIOR_PLACES[@]}" | grep -cx "sitzbank|$p")"
done

# --- Dateisymbole: Weltitem, Möbel, Stadtobjekt, Figur --------------
TYPE[/sym/Bits]=f;          WORLD_ITEM[/sym/Bits]=bits
TYPE[/sym/Sitzbank]=f;      INTERIOR_AT[/sym/Sitzbank]=sitzbank
TYPE[/sym/Zeitungskasten]=f; INTERIOR_AT[/sym/Zeitungskasten]=zeitungskasten
TYPE[/sym/TraceyBriggs]=f;   DIALOG[/sym/TraceyBriggs]=dialog_tracey
TYPE[/sym/Notiz]=f
file_meta Bits f /sym/Bits
chk "Bits: eigenes Symbol" "✦" "$FI_ICON"
chk "Bits: eigene Farbe" "$GOOD" "$FI_COLOR"
TYPE[/sym/EinfacheFackel]=f; WORLD_ITEM[/sym/EinfacheFackel]=fackel
file_meta EinfacheFackel f /sym/EinfacheFackel
chk "Fackel: Plunder-Symbol" "◆" "$FI_ICON"
chk "Fackel: Plunder-Farbe" "$WARN" "$FI_COLOR"
file_meta Sitzbank f /sym/Sitzbank
chk "Sitzbank: eigenes Symbol" "▥" "$FI_ICON"
chk "Sitzbank: eigene Farbe" "$MENU_C" "$FI_COLOR"
file_meta Zeitungskasten f /sym/Zeitungskasten
chk "Zeitungskasten: eigenes Symbol" "▣" "$FI_ICON"
chk "Zeitungskasten: eigene Farbe" "$TITLE" "$FI_COLOR"
file_meta TraceyBriggs f /sym/TraceyBriggs
chk "TraceyBriggs: eigenes Symbol" "◉" "$FI_ICON"
chk "TraceyBriggs: eigene Farbe" "$TRACEY_C" "$FI_COLOR"
file_meta Notiz f /sym/Notiz
chk "gewöhnliche Datei ohne Endung: Punkt" "·" "$FI_ICON"
chk "gewöhnliche Datei ohne Endung: grau" "$MUTED" "$FI_COLOR"
unset 'TYPE[/sym/Bits]' 'TYPE[/sym/EinfacheFackel]' 'TYPE[/sym/Sitzbank]' \
      'TYPE[/sym/Zeitungskasten]' 'TYPE[/sym/TraceyBriggs]' 'TYPE[/sym/Notiz]'
unset 'WORLD_ITEM[/sym/Bits]' 'WORLD_ITEM[/sym/EinfacheFackel]' 'INTERIOR_AT[/sym/Sitzbank]' \
      'INTERIOR_AT[/sym/Zeitungskasten]' 'DIALOG[/sym/TraceyBriggs]'

# --- Fackel in der Baracke -----------------------------------------
P_FACKEL_BARACKE="$BASE/Süddistrikt/EingestürzteBaracke/EinfacheFackel"
chk "Fackel in der Baracke registriert" "1" \
    "$(printf '%s\n' "${ITEM_PLACES[@]}" | grep -cx "fackel|1|$P_FACKEL_BARACKE|grep")"
chk "Restaurant-Ordner im Westdistrikt" "d" \
    "${TYPE[$BASE/Westdistrikt/Restaurant]:-}"
chk "MichaelMitch steht im Restaurant" "f" \
    "${TYPE[$BASE/Westdistrikt/Restaurant/MichaelMitch]:-}"
chk "Michael-Dialog ist registriert" "dialog_michael" \
    "${DIALOG[$BASE/Westdistrikt/Restaurant/MichaelMitch]:-}"

# DailyPulse hat eine eigene Ortsdatei; der Verlag baut Rachel, Jack und
# den Stuhl darüber auf. Die drei Stühle stehen in Baracke, Verlag und
# Jimmys Haus und teilen sich die Sitz-Mechanik.
chk "DailyPulse hat eine eigene Ortsdatei" "1" \
    "$([ -f "$SCRIPT_DIR/Orte/DailyPulse.sh" ] && echo 1 || echo 0)"
chk "Rachel steht im DailyPulse" "f" \
    "${TYPE[$BASE/Süddistrikt/DailyPulse/Rachel]:-}"
chk "Jack steht im DailyPulse" "f" \
    "${TYPE[$BASE/Süddistrikt/DailyPulse/Jack]:-}"
chk "DailyPulse-Stuhl registriert" "1" \
    "$(printf '%s\n' "${INTERIOR_PLACES[@]}" | grep -cx "stuhl|$BASE/Süddistrikt/DailyPulse/Stuhl")"
chk "Baracken-Stuhl registriert" "1" \
    "$(printf '%s\n' "${INTERIOR_PLACES[@]}" | grep -cx "stuhl|$BASE/Süddistrikt/EingestürzteBaracke/Stuhl")"
chk "Jimmys-Stuhl registriert" "1" \
    "$(printf '%s\n' "${INTERIOR_PLACES[@]}" | grep -cx "stuhl|$BASE/Ostdistrikt/JimmysHaus/Stuhl")"
# Auch die Wurzelordner der fünf Stadtteile anlegen: fs_build_tree läuft
# in den Unit-Tests erst später, und interior_world_refresh räumt Objekte
# ohne vorhandenen Elternordner wieder ab.
for k in "${DISTRICT_KEYS[@]}"; do
    addp d "$BASE/${DISTRICT_DIRNAME[$k]}"
done
addp d "$CITY"
addp d "$BASE"
interior_world_refresh
chk "Stuhl steht in der Baracke" "f" \
    "${TYPE[$BASE/Süddistrikt/EingestürzteBaracke/Stuhl]:-}"
chk "Stuhl steht im DailyPulse" "f" \
    "${TYPE[$BASE/Süddistrikt/DailyPulse/Stuhl]:-}"
chk "Stuhl steht in Jimmys Haus" "f" \
    "${TYPE[$BASE/Ostdistrikt/JimmysHaus/Stuhl]:-}"
chk "Stuhl reagiert auf touch" "stuhl_gespraech" \
    "${DIALOG[$BASE/Süddistrikt/DailyPulse/Stuhl]:-}"
chk "Matratze liegt weiter in der Baracke" "f" \
    "${TYPE[$BASE/Süddistrikt/EingestürzteBaracke/Matratze]:-}"
for p in "$BASE/Süddistrikt/Sitzbank" "$BASE/Norddistrikt/Sitzbank" \
         "$BASE/Westdistrikt/Sitzbank" "$BASE/Ostdistrikt/Sitzbank" \
         "$BASE/Zentrum/Sitzbank" "$CITY/Sitzbank" \
         "$BASE/Sitzbank"; do
    chk "Sitzbank steht: ${p#$CITY/}" "f" "${TYPE[$p]:-}"
done

build_children
items_world_refresh
chk "Fackel liegt in der Baracke" "f" "${TYPE[$P_FACKEL_BARACKE]:-}"
chk "Fackel-Fundort gehört zum Item" "fackel" "${WORLD_ITEM[$P_FACKEL_BARACKE]:-}"
CWD="$BASE/Süddistrikt/DailyPulse"
handel_here jack
chk_rc "Jack steht im Verlag als Händler (trade Jack)" "$?" 0

# Queststand & Ziele
ZEITUNG_GIVEN=0; ZEITUNG_DONE=0; ZEITUNG_EMPTIED=0
chk "Quest anfangs verborgen" "verborgen" "$(quest_status_zeitung)"
ZEITUNG_GIVEN=1
chk "Quest nach Annahme aktuell" "aktuell" "$(quest_status_zeitung)"
chk "Ziel nennt 5 offene Kästen" \
    "Leere die Zeitungskästen in den fünf Bezirken (use Zeitungskasten) – noch 5 offen." \
    "$(quest_goal_zeitung)"
zeitung_box_mark_empty "$P_SUED"
chk "Ziel zählt geleerte Kästen" \
    "Leere die Zeitungskästen in den fünf Bezirken (use Zeitungskasten) – noch 4 offen." \
    "$(quest_goal_zeitung)"
INV_COUNT=(); INV_ORDER=(); inv_add zeitungsbuendel 5
for p in "$P_NORD" "$P_WEST" "$P_OST" "$P_ZENTRUM"; do zeitung_box_mark_empty "$p"; done
chk "Ziel nach fünf Kästen: zu Jack" \
    "Bring die fünf Zeitungsbündel zu Jack: DailyPulse-Verlag (Süddistrikt)" \
    "$(quest_goal_zeitung)"
chk "Verlauf nennt Jacks Auftrag" "1" \
    "$(quest_entries_zeitung | grep -c 'Zeitungskastenschlüssel')"
chk "Verlauf nennt alle fünf Bezirke" "5" \
    "$(quest_entries_zeitung | grep -c 'Zeitungskasten im')"
ZEITUNG_DONE=1
chk "Quest abgeschlossen" "abgeschlossen" "$(quest_status_zeitung)"
chk " kein Ziel nach Abschluss" "" "$(quest_goal_zeitung)"
chk "Verlauf nennt 200 EXP" "1" \
    "$(quest_entries_zeitung | grep -c '200 EXP')"
chk "Quest steht bei den Nebenquests" "zeitung" \
    "$(printf '%s\n' "${QL_NEBEN[@]}" | grep -x zeitung)"
chk "Quest-Titel" "Die langweiligste Ausgabe" "${QL_TITLE[zeitung]}"

# clear-Preis: vor dem Abschluss 50 Bits, danach 0 Bits (1 Skillpunkt bleibt).
ZEITUNG_DONE=0
chk "clear vor der Quest: 50 Bits" "50" "$(verlag_jack_clear_cost_bits)"
ZEITUNG_DONE=1
chk "clear nach der Quest: 0 Bits" "0" "$(verlag_jack_clear_cost_bits)"

# --- Unterstützung für Amanda: Queststand und Jacks Umzug -----------
AMANDA_HELP_GIVEN=0; AMANDA_HELP_ASKED=0
AMANDA_HELP_JACK=0;  AMANDA_HELP_DONE=0
ZEITUNG_DONE=0
P_JACK_PRESS="$BASE/Süddistrikt/DailyPulse/Jack"
P_JACK_DET="$BASE/Ostdistrikt/DetekteiHolmes/Jack"
chk "Amanda-Quest anfangs verborgen" "verborgen" "$(quest_status_amanda)"
chk "Jack steht anfangs im Verlag" "f" "${TYPE[$P_JACK_PRESS]:-}"
chk "Jack fehlt anfangs in der Detektei" "" "${TYPE[$P_JACK_DET]:-}"

AMANDA_HELP_GIVEN=1
chk "Amanda-Quest nach Vergabe aktuell" "aktuell" "$(quest_status_amanda)"
chk "Amanda-Ziel: Helfer suchen" \
    "Suche jemanden, der Amanda bei den Akten helfen kann – frag dich durch die Stadt" \
    "$(quest_goal_amanda)"
AMANDA_HELP_ASKED=1
chk "Amanda-Ziel nach Jacks Vorbehalt" \
    "Schließe Jacks Quest »Die langweiligste Ausgabe« ab und frag ihn danach noch einmal" \
    "$(quest_goal_amanda)"
chk "Verlauf nennt Jacks Vorbehalt" "1" \
    "$(quest_entries_amanda | grep -c 'aus dem Verkehr')"
ZEITUNG_DONE=1
chk "Amanda-Ziel nach der Zeitungsquest" \
    "Frag Jack Nullpunkt im DailyPulse-Verlag, ob er Amanda jetzt helfen kann" \
    "$(quest_goal_amanda)"

AMANDA_HELP_JACK=1
jack_apply_state
chk "Jack verschwindet aus dem Verlag" "" "${TYPE[$P_JACK_PRESS]:-}"
chk "Jack steht jetzt in der Detektei" "f" "${TYPE[$P_JACK_DET]:-}"
chk "Jack-Dialog in der Detektei ist registriert" "dialog_jack_detektei" \
    "${DIALOG[$P_JACK_DET]:-}"
chk "Jacks Detektei-Text nennt die neue Arbeit" "1" \
    "$(printf '%s\n' "${CONTENT[$P_JACK_DET]:-}" | grep -c 'Detektei Holmes')"
chk "Amanda-Ziel führt zur Detektei" \
    "Sprich mit Amanda Nox in der Detektei Holmes (Ostdistrikt)" \
    "$(quest_goal_amanda)"

AMANDA_HELP_DONE=1
chk "Amanda-Quest abgeschlossen" "abgeschlossen" "$(quest_status_amanda)"
chk "kein Amanda-Ziel nach Abschluss" "" "$(quest_goal_amanda)"
chk "Verlauf nennt 200 EXP" "1" \
    "$(quest_entries_amanda | grep -c '200 EXP')"
chk "Amanda-Quest steht bei den Nebenquests" "amanda" \
    "$(printf '%s\n' "${QL_NEBEN[@]}" | grep -x amanda)"
chk "Amanda-Quest-Titel" "Unterstützung für Amanda" "${QL_TITLE[amanda]}"

# Reset für die folgenden Tests: Jack steht wieder im Verlag.
AMANDA_HELP_GIVEN=0; AMANDA_HELP_ASKED=0
AMANDA_HELP_JACK=0;  AMANDA_HELP_DONE=0
ZEITUNG_DONE=0
jack_apply_state
chk "Jack steht nach dem Reset wieder im Verlag" "f" "${TYPE[$P_JACK_PRESS]:-}"
chk "Jack ist nach dem Reset aus der Detektei verschwunden" "" "${TYPE[$P_JACK_DET]:-}"

# --- Stadtrundgang mit Pixi: Queststand ----------------------------
RUNDGANG_GIVEN=0; RUNDGANG_DONE=0
chk "Rundgang anfangs verborgen" "verborgen" "$(quest_status_rundgang)"
chk "kein Rundgang-Ziel vor der Vergabe" "" "$(quest_goal_rundgang)"
RUNDGANG_GIVEN=1
chk "Rundgang nach der Vergabe aktuell" "aktuell" "$(quest_status_rundgang)"
chk "Rundgang-Ziel nennt Ort und Zeitfenster" \
    "Sprich mit Pixi im DailyPulse-Verlag (Süddistrikt) – zwischen 06:00 und 14:00" \
    "$(quest_goal_rundgang)"
chk "Verlauf nennt das Zeitfenster" "1" \
    "$(quest_entries_rundgang | grep -c '06:00–14:00')"
RUNDGANG_DONE=1
chk "Rundgang abgeschlossen" "abgeschlossen" "$(quest_status_rundgang)"
chk "kein Rundgang-Ziel nach Abschluss" "" "$(quest_goal_rundgang)"
chk "Verlauf nennt 1000 EXP" "1" \
    "$(quest_entries_rundgang | grep -c '1000 EXP')"
chk "Rundgang steht bei den Nebenquests" "rundgang" \
    "$(printf '%s\n' "${QL_NEBEN[@]}" | grep -x rundgang)"
chk "Rundgang-Titel" "Stadtrundgang mit Pixi" "${QL_TITLE[rundgang]}"
RUNDGANG_GIVEN=0; RUNDGANG_DONE=0

# --- Die neueste Auflage: Sperrzone -------------------------------
AUFLAGE_GIVEN=0; AUFLAGE_DONE=0
ZEITUNG_EDITION=bezirke; ZEITUNG_EMPTIED=0
chk "Auflage anfangs verborgen" "verborgen" "$(quest_status_auflage)"
chk "kein Auflage-Ziel vor der Vergabe" "" "$(quest_goal_auflage)"
AUFLAGE_GIVEN=1
zeitung_await_distribution sperrzone
chk "Auflage nach Vergabe aktuell" "aktuell" "$(quest_status_auflage)"
chk "Auflage-Ziel nennt fünf offene Kästen" \
    "Fülle die fünf Zeitungskästen mit der Sperrzone-Ausgabe (use Zeitungskasten) – noch 5 offen." \
    "$(quest_goal_auflage)"
chk "Verlauf nennt Rachels fünf Bündel" "1" \
    "$(quest_entries_auflage | grep -c 'fünf Bündel')"
for p in "$P_SUED" "$P_NORD" "$P_WEST" "$P_OST" "$P_ZENTRUM"; do
    zeitung_box_mark_filled "$p"
done
chk "Auflage-Ziel nach fünf Kästen: zu Rachel" \
    "Bring Rachel den Bericht: DailyPulse-Verlag (Süddistrikt)" \
    "$(quest_goal_auflage)"
chk "Verlauf nennt alle fünf befüllten Kästen" "5" \
    "$(quest_entries_auflage | grep -c 'Zeitungskasten im')"
chk "Verlauf fordert den Bericht" "1" \
    "$(quest_entries_auflage | grep -c 'Bericht erstatten')"
AUFLAGE_DONE=1
chk "Auflage abgeschlossen" "abgeschlossen" "$(quest_status_auflage)"
chk "kein Auflage-Ziel nach Abschluss" "" "$(quest_goal_auflage)"
chk "Verlauf nennt 500 EXP" "1" \
    "$(quest_entries_auflage | grep -c '500 EXP')"
chk "Auflage steht bei den Hauptquests" "auflage" \
    "$(printf '%s\n' "${QL_HAUPT[@]}" | grep -x auflage)"
chk "Auflage-Titel" "Die neueste Auflage: Sperrzone" "${QL_TITLE[auflage]}"

# Jimmy verhandelt die Sperrzone-Ausgabe. Die EXP-Staffel wird im
# Abschnitt »Tracey Briggs & Jimmys Zeitungsbote« geprüft, wo die
# Charakterdatei geladen ist. Die Quest bleibt offen.
JIMMY_GIVEN=1; JIMMY_LAST_SOLD=""
chk "Jimmy-Ziel nennt die Sperrzone" "1" \
    "$(quest_goal_jimmy | grep -c 'Sperrzone')"
chk "Jimmy-Verlauf: ich sollte ihm eine bringen" "1" \
    "$(quest_entries_jimmy | grep -c 'Ich sollte Jimmy die Sperrzone-Ausgabe bringen')"
JIMMY_LAST_SOLD=sperrzone
chk "Jimmy-Verlauf: Ausgabe gebracht" "1" \
    "$(quest_entries_jimmy | grep -c 'Hab Jimmy die Sperrzone-Ausgabe gebracht')"
chk "Jimmy-Quest bleibt aktuell" "aktuell" "$(quest_status_jimmy)"
AUFLAGE_GIVEN=0; AUFLAGE_DONE=0
ZEITUNG_EDITION=bezirke; ZEITUNG_EMPTIED=0
JIMMY_LAST_SOLD=""

# Auch ein erneuter Verlag-Aufbau darf den umgezogenen Jack nicht
# zurückbringen.
AMANDA_HELP_JACK=1
fs_remove "$P_JACK_PRESS"
daily_pulse_build "$BASE/Süddistrikt/DailyPulse"
chk "Verlags-Aufbau lässt Jack nach dem Umzug draußen" "" \
    "${TYPE[$P_JACK_PRESS]:-}"
AMANDA_HELP_JACK=0
daily_pulse_build "$BASE/Süddistrikt/DailyPulse"
chk "Verlags-Aufbau bringt Jack vor dem Umzug zurück" "f" \
    "${TYPE[$P_JACK_PRESS]:-}"

# Save-Migration: alte Stände bekommen Edition und volle Kästen.
ZEITUNG_EDITION=""; ZEITUNG_EMPTIED=""; ZEITUNG_GIVEN=""; ZEITUNG_DONE=1
th_save_migrate
chk "Migration: Edition fällt auf bezirke zurück" "bezirke" "$ZEITUNG_EDITION"
chk "Migration: abgeschlossene Quest = alle Kästen leer" "31" "$ZEITUNG_EMPTIED"

# Nach dem Rundgang ist die Sperrzone-Ausgabe gedruckt: Edition wechselt,
# alle Kästen warten auf Rachels fünf Bündel.
ZEITUNG_EDITION=bezirke; ZEITUNG_EMPTIED=31
ZEITUNG_GIVEN=1; ZEITUNG_DONE=1
RUNDGANG_GIVEN=1; RUNDGANG_DONE=1
AUFLAGE_GIVEN=0; AUFLAGE_DONE=0
th_save_migrate
chk "Migration: nach Rundgang Edition sperrzone" "sperrzone" "$ZEITUNG_EDITION"
chk "Migration: nach Rundgang alle Kästen leer" "31" "$ZEITUNG_EMPTIED"
chk "Migration: Auflage bleibt unbegonnen" "0" "$AUFLAGE_GIVEN"

# Eine laufende Verteilung darf ihren Fortschritt nicht verlieren.
AUFLAGE_GIVEN=1; AUFLAGE_DONE=0; ZEITUNG_EMPTIED=7
th_save_migrate
chk "Migration: laufende Auflage behält Edition" "sperrzone" "$ZEITUNG_EDITION"
chk "Migration: laufende Auflage behält Fortschritt" "7" "$ZEITUNG_EMPTIED"
chk "Migration: laufende Auflage bleibt aktiv" "1" "$AUFLAGE_GIVEN"

# Eine abgeschlossene Auflage bedeutet: alle fünf Kästen sind gefüllt.
AUFLAGE_DONE=1; ZEITUNG_EMPTIED=31
th_save_migrate
chk "Migration: abgeschlossene Auflage setzt Kästen voll" "0" "$ZEITUNG_EMPTIED"
chk "Migration: Abschluss setzt Vergabe voraus" "1" "$AUFLAGE_GIVEN"

ZEITUNG_EDITION=bezirke; ZEITUNG_EMPTIED=0; ZEITUNG_GIVEN=0; ZEITUNG_DONE=0
RUNDGANG_GIVEN=0; RUNDGANG_DONE=0; AUFLAGE_GIVEN=0; AUFLAGE_DONE=0
INV_COUNT=(); INV_ORDER=()

# Save-Migration: alte Stände nach Baracke/Downloads bekommen die neuen
# Lernpfade still, ohne den Dialog erneut zu zeigen.
LEARNED=(pwd ls cd cat touch); ACH_UNLOCKED=()
README_DONE=1; BARACKE_SCENE_DONE=1; CWD="$HOME_DIR/Schreibtisch"
th_save_migrate
knows statistics;  chk_rc "Migration: statistics nach Baracke gelernt" "$?" 0
knows achievements; chk_rc "Migration: achievements nach Downloads gelernt" "$?" 0
achievement_has kompass_geeicht
chk_rc "Migration: Kompass nach Downloads freigeschaltet" "$?" 0
LEARNED=(pwd ls cd cat touch); ACH_UNLOCKED=()
README_DONE=1; BARACKE_SCENE_DONE=0; CWD="$HOME_DIR/Downloads/$AGENT_NAME"
th_save_migrate
knows achievements; chk_rc "Migration: im Agenten-Ordner bleibt achievements gesperrt" "$?" 1
achievement_has kompass_geeicht
chk_rc "Migration: im Agenten-Ordner bleibt der Kompass gesperrt" "$?" 1
LEARNED=(pwd ls cd cat touch); ACH_UNLOCKED=()
README_DONE=0; BARACKE_SCENE_DONE=0; CWD="$HOME_DIR/Downloads"

