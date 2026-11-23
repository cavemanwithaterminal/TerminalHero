# ============================================================
#  Unit-Test-Teil: Handelsfenster
#  Wird von Kern/tests/unit.sh in fester Reihenfolge geladen.
# ============================================================
# ==================================================================
section "Handel"
# ==================================================================
# Handelsfenster-Logik ohne TUI (shDateien/Handelsfenster.sh): Händler-
# Lager, Preise, Fächer, Saldo-Verrechnung, Abwicklung, Tagesauffrischung.
. "$SCRIPT_DIR/kern/Uhrzeit.sh"
. "$SCRIPT_DIR/Items/Spezial/Armbanduhr.sh"
. "$SCRIPT_DIR/Items/Plunder/LightBeer.sh"
. "$SCRIPT_DIR/Handelsfenster.sh"

# --- Händler anmelden & Preise ------------------------------------
WORLD_SECS=0
BITS=100
inv_reset
handel_define testy "Testy Handelsmann"
handel_alias testy "Testy"
handel_stock testy lightbeer 10
chk "Händler-Name"                "Testy Handelsmann" "$(handel_name testy)"
chk "Startlager"                  "10" "$(handel_stock_count testy lightbeer)"
chk "Kaufpreis = Item-Wert"       "7"  "$(handel_buy_price lightbeer)"
chk "Verkaufspreis = halber Wert" "3"  "$(handel_sell_price lightbeer)"

# --- Fackel (Survival Jack): 35 Bits kaufen, 17 Bits verkaufen ------
. "$SCRIPT_DIR/NutzbareItems/Fackel2.sh"
chk "Fackel: Kaufpreis 35"     "35" "$(handel_buy_price fackel2)"
chk "Fackel: Verkaufspreis 17" "17" "$(handel_sell_price fackel2)"
chk "handel_find über Alias"      "testy" "$(handel_find Testy)"
chk "handel_find über id"         "testy" "$(handel_find testy)"
chk "handel_find: unbekannt"      ""      "$(handel_find Klaus)"
chk "Lager nach Kategorie"        "lightbeer" "$(handel_stock_in_cat testy plunder)"

# --- Handelbar oder gesperrt --------------------------------------
handel_tradable lightbeer;  chk_rc "LightBeer ist handelbar"          "$?" 0
handel_tradable armbanduhr; chk_rc "Armbanduhr gesperrt (sellable 0)" "$?" 1
handel_tradable brief;      chk_rc "Quest-Gegenstand gesperrt"        "$?" 1

# --- Ausnahme: »Börtys Bierlieferung« -------------------------------
# Ein Quest-Gegenstand, der ausdrücklich »sellable 1« sagt: Wer die Kiste
# nicht ausliefert, darf sie verkaufen (Wert 250, wie Börtys Vorschuss).
. "$SCRIPT_DIR/Items/Quest/Bierlieferung.sh"
chk "Bierlieferung: Name"           "Börtys Bierlieferung" "$(item_name bierlieferung)"
chk "Bierlieferung: Wert"           "250" "$(item_value bierlieferung)"
chk "Bierlieferung: Kategorie"      "quest" "$(item_cat bierlieferung)"
chk_rc "Bierlieferung ist einmalig" "$(item_is_unique bierlieferung; echo $?)" 0
handel_tradable bierlieferung; chk_rc "Quest-Item, aber ausdrücklich handelbar" "$?" 0
chk "Kauf kostet den vollen Wert"   "250" "$(handel_buy_price bierlieferung)"
chk "Verkauf bringt den halben Wert" "125" "$(handel_sell_price bierlieferung)"
chk_rc "andere Quest-Items bleiben gesperrt" \
    "$(item_flag brief sellable 0; handel_tradable brief; echo $?)" 1

# --- Bierkiste verloren: 24-Stunden-Frist & Ersatz -----------------
# Verliert der Agent die Kiste, merkt sich das Item die Spielminute.
# Eine wieder vorhandene Kiste hebt die Frist auf.
WORLD_SECS=0
BIER_GIVEN=1; BIER_TAKEN=1; BIER_DONE=0; BIER_FAILED=0; BIER_LOST_AT=-1
INV_COUNT=(); INV_ORDER=()
inv_add bierlieferung
chk "Bierkiste: Hinzufügen löscht keine alte Frist" "-1" "$BIER_LOST_AT"
inv_remove bierlieferung
chk "Bierkiste: Verlust merkt sich die Spielminute" "0" "$BIER_LOST_AT"
chk_rc "Frist bei 0 Minuten noch nicht abgelaufen" "$(bier_loss_due; echo $?)" 1
WORLD_SECS=3599
chk "Spielminute 1439: Frist noch nicht abgelaufen" "1439" "$(uhrzeit_minutes)"
chk_rc "Frist bei 1439 Minuten noch nicht abgelaufen" "$(bier_loss_due; echo $?)" 1
WORLD_SECS=3600
chk "Spielminute 1440: 24 Stunden sind um" "1440" "$(uhrzeit_minutes)"
chk_rc "Frist nach 24 Spielstunden abgelaufen" "$(bier_loss_due; echo $?)" 0
inv_add bierlieferung
chk "Ersatzkiste hebt die Verlustfrist auf" "-1" "$BIER_LOST_AT"
chk_rc "mit Kiste ist keine Frist offen" "$(bier_loss_due; echo $?)" 1
BIER_FAILED=1
chk "Queststatus nach dem Scheitern" "gescheitert" "$(quest_status_bier)"
chk "gescheiterte Quest hat kein Ziel" "" "$(quest_goal_bier)"
chk "Verlauf nennt das Scheitern" "1" \
    "$(quest_entries_bier | grep -c 'Die Quest ist gescheitert')"
OUT=()
quest_failed bier
chk "quest_failed meldet den Status" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c 'QUEST GESCHEITERT')"
INV_COUNT=(); INV_ORDER=()
BIER_TAKEN=0; BIER_DONE=0; BIER_FAILED=0; BIER_LOST_AT=-1; BIER_GIVEN=0
WORLD_SECS=0

# --- Save-Migration: alte Spielstände reparieren --------------------
# Nach dem Laden wird ein Altstand still repariert: Ist die Bierkiste
# abgeholt, aber nicht mehr im Inventar (z. B. verkauft), beginnt die
# 24-Stunden-Frist. BIER_TAKEN bleibt gesetzt - die Erstkiste ist weg;
# Samy gibt weiterhin Ersatz, solange die Frist läuft.
. "$SCRIPT_DIR/kern/save.sh"
TMP_SAVE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/th-migrate.XXXXXX")"
TH_SAVES_DIR="$TMP_SAVE_DIR"

cat > "$TMP_SAVE_DIR/manual1.save" <<'SAVE'
TH_SAVE_VERSION=1
BIER_GIVEN=1
BIER_TAKEN=1
BIER_DONE=0
BIER_FAILED=0
BIER_LOST_AT=-1
SAVE
INV_COUNT=(); INV_ORDER=()
WORLD_SECS=0
th_load manual; chk_rc "Save-Migration: alter Stand lädt" "$?" 0
chk "Save-Migration: Erstkiste bleibt als abgeholt markiert" "1" "$BIER_TAKEN"
chk "Save-Migration: Verlustfrist beginnt beim Laden" "0" "$BIER_LOST_AT"

# Altstand ohne Statistik: Die Summe der verdienten Bits ist unbekannt.
# Als Startwert zählt der aktuelle Kontostand, die echte Spielzeit bei 0.
cat > "$TMP_SAVE_DIR/manual1.save" <<'SAVE'
TH_SAVE_VERSION=1
BITS=42
SAVE
BITS_EARNED=""
PLAYTIME_BASE=""
th_load manual
chk "Save-Migration: BITS_EARNED startet beim Kontostand" "42" "$BITS_EARNED"
chk "Save-Migration: echte Spielzeit startet bei 0" "0" "$PLAYTIME_BASE"

cat > "$TMP_SAVE_DIR/manual1.save" <<'SAVE'
TH_SAVE_VERSION=1
BIER_GIVEN=1
BIER_TAKEN=1
BIER_DONE=0
BIER_FAILED=0
BIER_LOST_AT=0
INV_ORDER=(bierlieferung)
INV_COUNT=([bierlieferung]=1)
SAVE
INV_COUNT=(); INV_ORDER=()
th_load manual
chk "Save-Migration: vorhandene Kiste bleibt unangetastet" "1" "$BIER_TAKEN"
chk "Save-Migration: Kiste bleibt im Inventar" "1" "$(inv_count bierlieferung)"
chk "Save-Migration: vorhandene Kiste löscht die Frist" "-1" "$BIER_LOST_AT"

# Altstand: Amanda hat sich vor der Sherlock-Quest vorgestellt und dabei
# fälschlich AMANDA_DONE gesetzt. Die Vorstellung bleibt, der Quest-Flag
# fällt weg.
cat > "$TMP_SAVE_DIR/manual1.save" <<'SAVE'
TH_SAVE_VERSION=1
PIXI_LETTER_DONE=0
AMANDA_DONE=1
AMANDA_INTRO_DONE=0
BIER_GIVEN=0
SAVE
INV_COUNT=(); INV_ORDER=()
th_load manual
chk "Save-Migration: früher Amanda-Besuch behält die Vorstellung" "1" "$AMANDA_INTRO_DONE"
chk "Save-Migration: früher Amanda-Besuch löscht AMANDA_DONE" "0" "$AMANDA_DONE"

# Mit Pixis Brief war es ein Quest-Gespräch: Flag bleibt.
cat > "$TMP_SAVE_DIR/manual1.save" <<'SAVE'
TH_SAVE_VERSION=1
PIXI_LETTER_DONE=1
AMANDA_DONE=1
AMANDA_INTRO_DONE=0
BIER_GIVEN=0
SAVE
INV_COUNT=(); INV_ORDER=()
th_load manual
chk "Save-Migration: Quest-Gespräch behält AMANDA_DONE" "1" "$AMANDA_DONE"
chk "Save-Migration: Quest-Gespräch merkt die Vorstellung" "1" "$AMANDA_INTRO_DONE"
AMANDA_DONE=0; AMANDA_INTRO_DONE=0; PIXI_LETTER_DONE=0

# Altstand mit umgezogenem Jack: Quest und Nachfrage werden nachgezogen.
unset AMANDA_HELP_GIVEN AMANDA_HELP_ASKED AMANDA_HELP_JACK AMANDA_HELP_DONE
cat > "$TMP_SAVE_DIR/manual1.save" <<'SAVE'
TH_SAVE_VERSION=1
AMANDA_HELP_JACK=1
SAVE
INV_COUNT=(); INV_ORDER=()
th_load manual
chk "Save-Migration: Jacks Umzug setzt die Amanda-Quest" "1" "$AMANDA_HELP_GIVEN"
chk "Save-Migration: Jacks Umzug merkt die Nachfrage" "1" "$AMANDA_HELP_ASKED"
chk "Save-Migration: Jacks Umzug lässt die Quest offen" "0" "$AMANDA_HELP_DONE"

# Altstand mit abgeschlossener Amanda-Quest: alles wird nachgezogen.
unset AMANDA_HELP_GIVEN AMANDA_HELP_ASKED AMANDA_HELP_JACK AMANDA_HELP_DONE
cat > "$TMP_SAVE_DIR/manual1.save" <<'SAVE'
TH_SAVE_VERSION=1
AMANDA_HELP_DONE=1
SAVE
INV_COUNT=(); INV_ORDER=()
th_load manual
chk "Save-Migration: Amanda-Abschluss setzt die Quest" "1" "$AMANDA_HELP_GIVEN"
chk "Save-Migration: Amanda-Abschluss setzt Jacks Umzug" "1" "$AMANDA_HELP_JACK"
chk "Save-Migration: Amanda-Abschluss merkt die Nachfrage" "1" "$AMANDA_HELP_ASKED"
AMANDA_HELP_GIVEN=0; AMANDA_HELP_ASKED=0
AMANDA_HELP_JACK=0; AMANDA_HELP_DONE=0

# Altstand mit abgeschlossener Mitch-Quest, aber ohne die neuen
# Gesprächsstufen: Quest, Treffen und Gehilfen-Quest werden nachgezogen.
unset MITCH_GIVEN MITCH_TALKED MITCH_DONE GEHILFE_GIVEN
cat > "$TMP_SAVE_DIR/manual1.save" <<'SAVE'
TH_SAVE_VERSION=1
MITCH_DONE=1
SAVE
th_load manual
chk "Save-Migration: Mitch-Quest nach Abschluss gesetzt" "1" "$MITCH_GIVEN"
chk "Save-Migration: Mitch-Treffen nach Abschluss gesetzt" "1" "$MITCH_TALKED"
chk "Save-Migration: Gehilfen-Quest nach Abschluss gesetzt" "1" "$GEHILFE_GIVEN"

# Altstand direkt nach dem Restaurant-Gespräch: Die Quest läuft weiter,
# aber die Gehilfen-Quest darf noch nicht da sein.
unset MITCH_GIVEN MITCH_TALKED MITCH_DONE GEHILFE_GIVEN
cat > "$TMP_SAVE_DIR/manual1.save" <<'SAVE'
TH_SAVE_VERSION=1
MITCH_TALKED=1
SAVE
th_load manual
chk "Save-Migration: Mitch-Treffen zieht die Quest nach" "1" "$MITCH_GIVEN"
chk "Save-Migration: Mitch-Treffen schließt nichts ab" "0" "$MITCH_DONE"
chk "Save-Migration: Gehilfen-Quest bleibt verborgen" "0" "$GEHILFE_GIVEN"

# Ganz alter Stand ohne Mitch-Flags: alles bleibt beim Standard.
unset MITCH_GIVEN MITCH_TALKED MITCH_DONE GEHILFE_GIVEN
cat > "$TMP_SAVE_DIR/manual1.save" <<'SAVE'
TH_SAVE_VERSION=1
BITS=0
SAVE
th_load manual
chk "Save-Migration: Mitch-Flags starten verborgen" "0" "$MITCH_GIVEN"
chk "Save-Migration: Mitch-Treffen startet offen" "0" "$MITCH_TALKED"
chk "Save-Migration: Mitch-Abschluss startet offen" "0" "$MITCH_DONE"
chk "Save-Migration: Gehilfen-Quest startet verborgen" "0" "$GEHILFE_GIVEN"

# Altstand mit aktiver Nek-Quest, aber ohne die neuen Gesprächsflags:
# Simon hat die Quest vergeben, also gehören Hauptquest-Hinweis und
# Quest-Verlauf dazu. Simple Jon bleibt zunächst ungefragt.
unset SIMON_NEK_INFO NEK_GIVEN JON_NEK_INFO VERMISSTE_GIVEN
cat > "$TMP_SAVE_DIR/manual1.save" <<'SAVE'
TH_SAVE_VERSION=1
NEK_GIVEN=1
SAVE
th_load manual
chk "Save-Migration: Nek-Quest setzt Simons Info" "1" "$SIMON_NEK_INFO"
chk "Save-Migration: Nek-Quest setzt die Hauptquest" "1" "$VERMISSTE_GIVEN"
chk "Save-Migration: Jon bleibt zunächst ungefragt" "0" "$JON_NEK_INFO"

# Altstand direkt nach Jons Gespräch: Seine Spur zieht die Nek-Quest
# und den Simon-Hinweis nach, weil beides Voraussetzung war.
unset SIMON_NEK_INFO NEK_GIVEN JON_NEK_INFO VERMISSTE_GIVEN
cat > "$TMP_SAVE_DIR/manual1.save" <<'SAVE'
TH_SAVE_VERSION=1
JON_NEK_INFO=1
SAVE
th_load manual
chk "Save-Migration: Jons Info setzt die Nek-Quest" "1" "$NEK_GIVEN"
chk "Save-Migration: Jons Info setzt Simons Info" "1" "$SIMON_NEK_INFO"
chk "Save-Migration: Jons Info setzt die Hauptquest" "1" "$VERMISSTE_GIVEN"
SIMON_NEK_INFO=0; NEK_GIVEN=0; JON_NEK_INFO=0; VERMISSTE_GIVEN=0

rm -rf "$TMP_SAVE_DIR"

# --- Nur vor Ort handeln (Händler muß im selben Ordner stehen) -----
# Die Welt meldet beseelte Dateien über DIALOG[]: <ordner>/<datei> ->
# dialog_<id>. handel_here prüft genau den aktuellen Ordner.
TYPE=(); CHILDREN=(); DIALOG=(); CONTENT=()
CWD="/welt/Kneipe"
CHILDREN[$CWD]="Testy Theke"
DIALOG["$CWD/Testy"]="dialog_testy"
DIALOG["$CWD/Theke"]="interior_theke"          # kein Händler
handel_here testy;  chk_rc "Testy steht hier"                     "$?" 0
chk "handel_here_ids hier"        "testy" "$(handel_here_ids | tr '\n' ' ' | sed 's/ $//')"
CWD="/welt/Bar"
handel_here testy;  chk_rc "einen Ordner weiter -> nicht hier"     "$?" 1
chk "handel_here_ids dort: keiner" ""      "$(handel_here_ids)"

# --- Ein Stück ins Verkaufsfach -----------------------------------
inv_add lightbeer 4
HS_ID=testy; HS_ZONE=0; HS_SIDE=0; HS_MID=0
HS_CAT=(2 2); HS_SEL=(0 0); HS_MSEL=(0 0)     # Reiter »Plunder« auf beiden Seiten
HS_SELL_Q=(); HS_SELL_O=(); HS_BUY_Q=(); HS_BUY_O=(); HS_NOTICE=""
hs_fill_lists
chk "Spielerfenster zeigt LightBeer" "lightbeer" "${HS_LIST_P[0]:-}"
hs_move_one; chk_rc "ein Stück hingelegt" "$?" 0
chk "im Verkaufsfach"     "1" "${HS_SELL_Q[lightbeer]:-0}"
chk "Rest im Inventar"    "3" "$(hs_remain_of 0 lightbeer)"
chk "Saldo: Agent bekommt" "-3" "$(hs_balance)"
chk "Verrechnungszeile"   "Testy Handelsmann zahlt dir 3 Bits." "$(hs_tally_text)"

# --- Drei Stück einkaufen -----------------------------------------
HS_SIDE=1
hs_fill_lists
chk "Händlerfenster zeigt LightBeer" "lightbeer" "${HS_LIST_H[0]:-}"
hs_move_one; hs_move_one; hs_move_one
chk "im Kauf-Fach"      "3"  "${HS_BUY_Q[lightbeer]:-0}"
chk "Lager-Rest"        "7"  "$(hs_remain_of 1 lightbeer)"
chk "Kaufsumme"         "21" "$(hs_sum_of buy)"
chk "Verkaufsumme"      "3"  "$(hs_sum_of sell)"
chk "Saldo: Agent zahlt" "18" "$(hs_balance)"
chk "Verrechnungszeile" "Du zahlst 18 Bits." "$(hs_tally_text)"

# --- Zu wenig Bits: nichts passiert -------------------------------
BITS=10
handel_execute; chk_rc "Abwicklung ohne Deckung -> Fehler" "$?" 1
chk "Bits unverändert"     "10" "$BITS"
chk "Inventar unverändert" "4"  "$(inv_count lightbeer)"
chk "Lager unverändert"    "10" "$(handel_stock_count testy lightbeer)"

# --- Genug Bits: echter Tausch ------------------------------------
BITS=50
OUT=()
handel_execute; chk_rc "Abwicklung klappt" "$?" 0
chk "Bits 50-18=32"    "32" "$BITS"
chk "Inventar 4-1+3=6" "6"  "$(inv_count lightbeer)"
chk "Lager 10-3+1=8"   "8"  "$(handel_stock_count testy lightbeer)"
chk "Bericht im Fenster" "1" "$(printf '%s\n' "${OUT[@]}" | grep -c 'HANDEL')"

# --- Gesperrtes lässt sich nicht hinlegen -------------------------
HS_ZONE=0; HS_SIDE=0; HS_MID=0
HS_SELL_Q=(); HS_SELL_O=(); HS_BUY_Q=(); HS_BUY_O=()
HS_CAT=(0 0)                                       # Reiter »Spezial«
inv_add armbanduhr
hs_fill_lists
chk "Spezial-Reiter zeigt Armbanduhr" "armbanduhr" "${HS_LIST_P[0]:-}"
hs_move_one; chk_rc "Armbanduhr lässt sich nicht hinlegen" "$?" 1
chk "nichts im Verkaufsfach" "0" "${HS_SELL_Q[armbanduhr]:-0}"
chk "Meldung im Fenster"     "Das ist unverkäuflich." "$HS_NOTICE"

# --- Lager leerkaufen & aus dem Fach zurücknehmen -----------------
HS_CAT=(2 2); HS_SIDE=1
hs_fill_lists
for _ in 1 2 3 4 5 6 7 8; do hs_move_one; done
chk "Kauf-Fach 8 (Lager leer)" "8" "${HS_BUY_Q[lightbeer]:-0}"
hs_move_one; chk_rc "kein Rest -> nichts mehr" "$?" 1
chk "Lager-Rest 0" "0" "$(hs_remain_of 1 lightbeer)"
HS_ZONE=1; HS_MID=1; HS_MSEL=(0 0)
hs_move_one; chk_rc "aus dem Fach zurück ins Lager" "$?" 0
chk "Kauf-Fach wieder 7" "7" "${HS_BUY_Q[lightbeer]:-0}"
chk "Rest wieder 1"      "1" "$(hs_remain_of 1 lightbeer)"

# --- Neuer Spieltag: Lager frischt auf ----------------------------
handel_stock_take testy lightbeer 1
chk "Lager nach Entnahme"    "7" "$(handel_stock_count testy lightbeer)"
HANDEL_DAY[testy]=-99
handel_day_sync testy
chk "neuer Spieltag -> voll" "10" "$(handel_stock_count testy lightbeer)"
handel_day_sync testy
chk "gleicher Tag bleibt"    "10" "$(handel_stock_count testy lightbeer)"

# --- Börty führt keine Ausrüstung mehr ----------------------------
. "$SCRIPT_DIR/Charakter/BörtySmiles.sh"
handel_lager_boerty
chk "Börty: Name" "Börty Smiles" "$(handel_name boerty)"
chk "Börty: 10 LightBeer" "10" "$(handel_stock_count boerty lightbeer)"
chk "Börty: keine Fackeln" "0" "$(handel_stock_count boerty fackel)"
chk "Börty: keine Schlafsäcke" "0" \
    "$(handel_stock_count boerty einfacherschlafsack)"

# --- Jack Bones (SurvivalShop, Zentrum) ---------------------------
. "$SCRIPT_DIR/Charakter/JackBones.sh"
handel_lager_jackbones
chk "Jack Bones: Name" "Jack Bones" "$(handel_name jackbones)"
chk "Jack Bones über Spitzname gefunden" "jackbones" \
    "$(handel_find "Survival Jack")"
chk "Jack Bones: 10 Fackeln" "10" \
    "$(handel_stock_count jackbones fackel)"
chk "Jack Bones: 1 Schlafsack" "1" \
    "$(handel_stock_count jackbones einfacherschlafsack)"
chk "Jack Bones: Fackel kostet 20 Bits" "20" \
    "$(handel_buy_price fackel)"
chk "Jack Bones: Schlafsack kostet 200 Bits" "200" \
    "$(handel_buy_price einfacherschlafsack)"
HANDEL_STOCK["jackbones/fackel"]=0
HANDEL_STOCK["jackbones/einfacherschlafsack"]=0
HANDEL_DAY[jackbones]=0
WORLD_SECS=86400
handel_day_sync jackbones
chk "Jack Bones: Fackeln am neuen Tag wieder da" "10" \
    "$(handel_stock_count jackbones fackel)"
chk "Jack Bones: Schlafsack am neuen Tag wieder da" "1" \
    "$(handel_stock_count jackbones einfacherschlafsack)"
WORLD_SECS=0
HANDEL_DAY[jackbones]="$(uhrzeit_day)"

