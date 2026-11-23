# ============================================================
#  Unit-Test-Teil: TUI-Grundlagen, Tokens, Charakter, Quests, Hilfe, Achievements
#  Wird von Kern/tests/unit.sh in fester Reihenfolge geladen.
# ============================================================
# ==================================================================
section "TUI-Grundlagen"
# ==================================================================
# Regression: clrline muss den Cursor absolut auf Spalte 1 setzen (H).
# Fehlte das H, wurde nur die aktuelle Zeile geleert und der Prompt an
# der alten Cursor-Spalte ausgegeben - nach vorgeschickten Eingaben
# wanderte er nach rechts und das Layout zerbrach.
UI_BATCH=0
_clr_out="$(clrline 7)"
chk "clrline setzt Cursor absolut auf 7;1" "1" \
    "$(printf '%s' "$_clr_out" | grep -c $'\033\[7;1H')"

# ==================================================================
section "Tokens"
# ==================================================================
TOKENS_MAX=999 TOKENS_CUR=1        # damit tokens_reset wirklich zurücksetzt
tokens_reset
chk "reset: Start 1000/1000"  "1000/1000" "$TOKENS_CUR/$TOKENS_MAX"
chk "reset: Regen 1 %/Intervall" "1"       "$TOKENS_REGEN_PCT"
chk "reset: Grundbefehl kostet 5" "5"      "$TOKEN_COST_CMD"
chk "tokens_step = 10 (1 % von 1000)" "10" "$(tokens_step)"

for b in cd cd.. cd. ls pwd cat touch; do
    chk "Kosten $b = 5" "5" "$(token_cost_of "$b")"
done
LEARNED+=(grep)
chk "Kosten grep = 10"      "10" "$(token_cost_of grep)"
chk "Kosten help ohne Erlernen = 0" "0" "$(token_cost_of help)"
chk "Kosten save ohne Erlernen = 0" "0" "$(token_cost_of save)"
chk "Kosten unbekannt = 0"  "0"  "$(token_cost_of fizzbuzz)"
chk "EXP grep = 2"          "2"  "$(token_exp_of grep)"
chk "EXP cat = 1"           "1"  "$(token_exp_of cat)"
chk "EXP unbekannt = 0"     "0"  "$(token_exp_of fizzbuzz)"

# Alle Ingame-/Menü-Befehle kosten 5 Tokens und geben 1 EXP, sobald sie
# erlernt sind. Aliase werden auf den kanonischen Namen abgebildet.
LEARNED+=(help character questlog inventar statistics achievements trade save use search)
for c in help character questlog inventar statistics achievements trade save use search; do
    chk "Kosten $c = 5" "5" "$(token_cost_of "$c")"
    chk "EXP $c = 1"    "1" "$(token_exp_of "$c")"
done
chk "Kosten Alias hilfe = 5"      "5" "$(token_cost_of hilfe)"
chk "Kosten Alias quests = 5"     "5" "$(token_cost_of quests)"
chk "Kosten Alias inventory = 5"  "5" "$(token_cost_of inventory)"
chk "Kosten Alias speichern = 5"  "5" "$(token_cost_of speichern)"
chk "Kosten Alias statistik = 5"  "5" "$(token_cost_of statistik)"
chk "exit bleibt kostenlos"       "0" "$(token_cost_of exit)"
chk "exit gibt keine EXP"         "0" "$(token_exp_of exit)"

# Nicht erlernte Befehle sind kostenlos: Es erscheint nur die Absage.
LEARNED=()
chk "grep ohne Erlernen kostet 0" "0" "$(token_cost_of grep)"
chk "cal ohne Erlernen kostet 0"  "0" "$(token_cost_of cal)"
chk "rm ohne Erlernen kostet 0"   "0" "$(token_cost_of rm)"
chk "cd ohne Erlernen kostet 0"   "0" "$(token_cost_of cd)"
chk "cd.. ohne Erlernen kostet 0" "0" "$(token_cost_of cd..)"
chk "help ohne Erlernen gibt 0 EXP" "0" "$(token_exp_of help)"
LEARNED=(pwd ls cd cat touch)

TOKENS_CUR=100
tokens_spend; chk_rc "spend 5 bei 100 Tokens" "$?" 0
chk "spend zieht ab" "95" "$TOKENS_CUR"
TOKENS_CUR=4
tokens_spend; chk_rc "spend bei zu wenig -> Fehler" "$?" 1
chk "kein negativer Saldo" "4" "$TOKENS_CUR"

TOKENS_CUR=0; TOKENS_MAX=1000; TOKENS_REGEN_SECS=60
TH_NEXT_REGEN="$(date +%s)"     # fällig "jetzt" (das Spiel setzt das ebenso)
tokens_tick; chk_rc "tick regeneriert (0 = geändert)" "$?" 0
chk "tick +1 Schritt (10)" "10" "$TOKENS_CUR"
TOKENS_CUR=1000
tokens_tick; chk_rc "tick am Maximum: unverändert" "$?" 1
chk "Maximum wird nicht überschritten" "1000" "$TOKENS_CUR"

TH_TOKENS=250 TH_TOKENS_MAX=500
tokens_reset
chk "Dev-Haken TH_TOKENS/TH_TOKENS_MAX" "250/500" "$TOKENS_CUR/$TOKENS_MAX"
unset TH_TOKENS TH_TOKENS_MAX
tokens_reset

# ==================================================================
section "Charakter & EXP"
# ==================================================================
char_reset
chk "Frischstart Level 0"     "0" "$LEVEL"
chk "Frischstart EXP 0"       "0" "$EXP"
for n in 0:100 1:200 2:300 5:600 9:1000; do
    chk "EXP für Level ${n%%:*}→$(( ${n%%:*} + 1 )) = ${n##*:}" \
        "${n##*:}" "$(char_exp_needed "${n%%:*}")"
done

TOKENS_MAX=1000
char_reset
char_gain_exp 50
chk "50 EXP: kein Aufstieg"   "0/50"   "$LEVEL/$EXP"
chk "50 EXP: TOKENS_MAX bleibt" "1000" "$TOKENS_MAX"
chk "50 EXP: CHAR_UPS = 0"    "0"      "$CHAR_UPS"
char_gain_exp 50
chk "100 EXP: Level 1"        "1/0"    "$LEVEL/$EXP"
chk "Aufstieg gibt +1 MaxTokens" "1001" "$TOKENS_MAX"
chk "Aufstieg zählt in CHAR_UPS" "1"    "$CHAR_UPS"
char_gain_exp 1000
chk "1000 EXP: Levelaufstiege bis Stufe 4" "4/100" "$LEVEL/$EXP"
chk "4 Aufstiege = +4 MaxTokens (Start + Aufstiege)" "1004" "$TOKENS_MAX"
chk "CHAR_UPS = 3 im letzten Aufruf" "3" "$CHAR_UPS"
chk "Schwelle Stufe 4 = 500 EXP" "500" "$(char_exp_needed 4)"

# --- Skillpunkte: je Aufstieg +1 ------------------------------------
char_reset
chk "Frischstart: Skillpunkte 0" "0" "$SKILL_POINTS"
TOKENS_MAX=1000
OUT=()
char_gain_exp 100
chk "ein Aufstieg = 1 Skillpunkt" "1" "$SKILL_POINTS"
chk "Aufstieg meldet den Skillpunkt" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c '+1 Skillpunkt')"
chk "Aufstieg nennt keine gesammelte Anzahl" "0" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c 'gesammelt')"
OUT=()
char_gain_exp 1000
chk "Stufe 4 = 4 Skillpunkte" "4" "$SKILL_POINTS"
chk "jeder Aufstieg meldet einen (3 neue)" "3" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c '+1 Skillpunkt')"
char_reset
chk "char_reset setzt Skillpunkte zurück" "0" "$SKILL_POINTS"

# --- Bits: je Aufstieg +8 -------------------------------------------
char_reset
TOKENS_MAX=1000
bits_reset
OUT=()
char_gain_exp 100
chk "ein Aufstieg gibt 8 Bits" "8" "$BITS"
chk "Bits-Ertrag nach einem Aufstieg" "8" "$BITS_EARNED"
chk "Aufstieg meldet +8 Bits" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -cF '+8 Bits')"
char_gain_exp 1000
chk "vier Aufstiege geben 32 Bits" "32" "$BITS"
chk "vier Aufstiege melden viermal +8 Bits" "4" \
    "$(printf '%s\n' "${OUT[@]}" | grep -cF '+8 Bits')"
bits_reset
char_reset

chk_rc "character/CHARAKTER ist der Befehl" "$(character_is_command character; echo $?)" 0
chk_rc "CHARAKTER (groß) ist der Befehl"    "$(character_is_command CHARAKTER; echo $?)" 0
chk_rc "char ist NICHT der Befehl"          "$(character_is_command char; echo $?)" 1

# ==================================================================
section "Ausrüstungs-Slots & Höhlen"
# ==================================================================
# Die acht Slots kommen aus kern/equipment.sh. Items gibt es noch nicht;
# geprüft werden Reihenfolge, Anzeigenamen, Leerzustand, Item-Metadaten
# und die Speicherung des Slot-Zustands.
equip_reset
chk "acht Ausrüstungs-Slots" "8" "${#EQUIP_SLOTS[@]}"
chk "Slot-Reihenfolge" "kopf oberkoerper beine linke_hand rechte_hand amulett ring1 ring2" \
    "${EQUIP_SLOTS[*]}"
chk "Anzeige: Kopf" "Kopf" "$(equip_slot_label kopf)"
chk "Anzeige: Oberkörper" "Oberkörper" "$(equip_slot_label oberkoerper)"
chk "Anzeige: Linke Hand" "Linke Hand" "$(equip_slot_label linke_hand)"
chk "Anzeige: Ring1" "Ring1" "$(equip_slot_label ring1)"
chk "unbekannter Slot ist ungültig" "1" \
    "$(equip_slot_valid hals; echo $?)"
chk "leerer Slot zeigt den Leertext" "— leer —" "$(equip_item_label kopf)"

equip_set kopf testhelm
equip_set ring2 testring
chk "belegter Slot zeigt die Item-ID" "testhelm" "$(equip_item_label kopf)"
chk "zweiter belegter Slot" "testring" "$(equip_get ring2)"
chk "unbekannter Slot lässt sich nicht setzen" "1" \
    "$(equip_set hals testring; echo $?)"
equip_clear kopf
chk "Slot leeren" "" "$(equip_get kopf)"
equip_remove_item testring
chk "Item aus allen Slots entfernen" "" "$(equip_get ring2)"

equip_define_item testring ring1 ring2
chk "Ring passt in Ring1" "0" "$(equip_item_allowed testring ring1; echo $?)"
chk "Ring passt in Ring2" "0" "$(equip_item_allowed testring ring2; echo $?)"
chk "Ring passt nicht auf den Kopf" "1" \
    "$(equip_item_allowed testring kopf; echo $?)"
chk "unbekannter Slot wird bei der Registrierung abgelehnt" "1" \
    "$(equip_define_item testring hals; echo $?)"
equip_reset

# Serialisierung: Der Slot-Zustand muss im Spielstand landen.
. "$SCRIPT_DIR/kern/save.sh"
EQUIP_SLOT_ITEM=([kopf]=testhelm [ring1]=testring)
EQUIP_DUMP="$(th_dump_assoc EQUIP_SLOT_ITEM)"
chk "Spielstand kennt EQUIP_SLOT_ITEM" "1" \
    "$(printf '%s\n' "$EQUIP_DUMP" | grep -c 'declare -g -A EQUIP_SLOT_ITEM')"
chk "Spielstand enthält den Kopf-Slot" "1" \
    "$(printf '%s\n' "$EQUIP_DUMP" | grep -c '\[kopf\]=testhelm')"
EQUIP_SLOT_ITEM=()
eval "$EQUIP_DUMP"
chk "Laden stellt den Kopf-Slot wieder her" "testhelm" "${EQUIP_SLOT_ITEM[kopf]:-}"
chk "Laden stellt den Ring-Slot wieder her" "testring" "${EQUIP_SLOT_ITEM[ring1]:-}"
equip_reset

# th_save muss den Slot-Zustand wirklich in die Datei schreiben.
EQ_SAVE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/th-equip.XXXXXX")"
TH_SAVES_DIR="$EQ_SAVE_DIR"
EQUIP_SLOT_ITEM=([kopf]=testhelm)
th_save manual; chk_rc "Spielstand mit Ausrüstung speichern" "$?" 0
chk "Save-Datei enthält den Kopf-Slot" "1" \
    "$(grep -c '\[kopf\]=testhelm' "$EQ_SAVE_DIR/manual1.save" 2>/dev/null)"
rm -rf "$EQ_SAVE_DIR"
unset TH_SAVES_DIR
equip_reset

# Höhleneingang & Molerathöhle gehören zum statischen Grundgerüst.
build_children
chk "Höhleneingang ist ein statischer Ordner" "d" \
    "${FS_BASE_TYPE[$HOME_DIR/Schreibtisch/Höhleneingang]:-}"
chk "Molerathöhle ist ein statischer Ordner" "d" \
    "${FS_BASE_TYPE[$HOME_DIR/Schreibtisch/Höhleneingang/Molerathöhle]:-}"
chk "Höhleneingang liegt unter Schreibtisch" "1" \
    "$(printf '%s\n' "${CHILDREN[$HOME_DIR/Schreibtisch]:-}" | grep -cx 'Höhleneingang')"
chk "Molerathöhle liegt im Höhleneingang" "1" \
    "$(printf '%s\n' "${CHILDREN[$HOME_DIR/Schreibtisch/Höhleneingang]:-}" | grep -cx 'Molerathöhle')"
chk "Orte/Höhleneingang.sh existiert" "1" \
    "$([ -f "$SCRIPT_DIR/Orte/Höhleneingang.sh" ] && echo 1 || echo 0)"
chk "Orte/Molerathöhle.sh existiert" "1" \
    "$([ -f "$SCRIPT_DIR/Orte/Molerathöhle.sh" ] && echo 1 || echo 0)"

# Brachland mit Friedhof, Steppe, Canyon & Moleratgebieten gehört zum
# statischen Grundgerüst. Der Canyon liegt seit dem Umbau in der Steppe.
BL="$HOME_DIR/Schreibtisch/Brachland"
STEPPE="$BL/Steppe"
GEBIET="$STEPPE/Moleratgebiet"
chk "Brachland ist ein statischer Ordner" "d" \
    "${FS_BASE_TYPE[$BL]:-}"
chk "Friedhof ist ein statischer Ordner" "d" \
    "${FS_BASE_TYPE[$BL/Friedhof]:-}"
chk "Steppe ist ein statischer Ordner" "d" \
    "${FS_BASE_TYPE[$STEPPE]:-}"
chk "Canyon ist ein statischer Ordner" "d" \
    "${FS_BASE_TYPE[$STEPPE/Canyon]:-}"
chk "Moleratgebiet ist ein statischer Ordner" "d" \
    "${FS_BASE_TYPE[$GEBIET]:-}"
for _mg in "$GEBIET/Moleratgebiet1.1" \
           "$GEBIET/Moleratgebiet1.1/Moleratgebiet1.2" \
           "$GEBIET/Moleratgebiet2.1" \
           "$GEBIET/Moleratgebiet2.1/Moleratgebiet2.2" \
           "$GEBIET/Moleratgebiet3.1" \
           "$GEBIET/Moleratgebiet3.1/Moleratgebiet3.2"; do
    chk "${_mg##*/} ist ein statischer Ordner" "d" \
        "${FS_BASE_TYPE[$_mg]:-}"
done
chk "Brachland liegt unter Schreibtisch" "1" \
    "$(printf '%s\n' "${CHILDREN[$HOME_DIR/Schreibtisch]:-}" | grep -cx 'Brachland')"
chk "Brachland enthält Friedhof" "1" \
    "$(printf '%s\n' "${CHILDREN[$BL]:-}" | grep -cx 'Friedhof')"
chk "Brachland enthält Steppe" "1" \
    "$(printf '%s\n' "${CHILDREN[$BL]:-}" | grep -cx 'Steppe')"
chk "Brachland enthält keinen Canyon mehr" "0" \
    "$(printf '%s\n' "${CHILDREN[$BL]:-}" | grep -cx 'Canyon')"
chk "Steppe enthält Canyon" "1" \
    "$(printf '%s\n' "${CHILDREN[$STEPPE]:-}" | grep -cx 'Canyon')"
chk "Steppe enthält Moleratgebiet" "1" \
    "$(printf '%s\n' "${CHILDREN[$STEPPE]:-}" | grep -cx 'Moleratgebiet')"
chk "Steppe enthält Farmland" "1" \
    "$(printf '%s\n' "${CHILDREN[$STEPPE]:-}" | grep -cx 'Farmland')"
chk "Moleratgebiet enthält 1.1" "1" \
    "$(printf '%s\n' "${CHILDREN[$GEBIET]:-}" | grep -cx 'Moleratgebiet1.1')"
chk "Moleratgebiet1.1 enthält 1.2" "1" \
    "$(printf '%s\n' "${CHILDREN[$GEBIET/Moleratgebiet1.1]:-}" | grep -cx 'Moleratgebiet1.2')"
chk "Moleratgebiet2.1 enthält 2.2" "1" \
    "$(printf '%s\n' "${CHILDREN[$GEBIET/Moleratgebiet2.1]:-}" | grep -cx 'Moleratgebiet2.2')"
chk "Moleratgebiet3.1 enthält 3.2" "1" \
    "$(printf '%s\n' "${CHILDREN[$GEBIET/Moleratgebiet3.1]:-}" | grep -cx 'Moleratgebiet3.2')"

# Farmland/Farm, das Anwesen der Familie Molerat und die Canyon-
# Tunnelkette gehören ebenfalls zum statischen Grundgerüst. Die
# Familie im Erdgeschoss und die Molerats in den Tunneln werden
# dynamisch gesetzt.
FARMLAND="$STEPPE/Farmland"
FARM="$FARMLAND/Farm"
ANWESEN="$FARM/Anwesen"
HAUPTEINGANG="$ANWESEN/Haupteingang"
ERDGESCHOSS="$HAUPTEINGANG/Erdgeschoss"
HOLE="$STEPPE/Canyon/Höhleneingang"
T1="$HOLE/Höhlentunnel1"
T2="$T1/Höhlentunnel2"
T3="$T2/Höhlentunnel3"
KAMMER="$T3/GroßeHöhlenkammer"
chk "Farmland ist ein statischer Ordner" "d" \
    "${FS_BASE_TYPE[$FARMLAND]:-}"
chk "Farm ist ein statischer Ordner" "d" \
    "${FS_BASE_TYPE[$FARM]:-}"
chk "Farmland liegt in der Steppe" "1" \
    "$(printf '%s\n' "${CHILDREN[$STEPPE]:-}" | grep -cx 'Farmland')"
chk "Farm liegt im Farmland" "1" \
    "$(printf '%s\n' "${CHILDREN[$FARMLAND]:-}" | grep -cx 'Farm')"
chk "Anwesen ist ein statischer Ordner" "d" \
    "${FS_BASE_TYPE[$ANWESEN]:-}"
chk "Haupteingang ist ein statischer Ordner" "d" \
    "${FS_BASE_TYPE[$HAUPTEINGANG]:-}"
chk "Erdgeschoss ist ein statischer Ordner" "d" \
    "${FS_BASE_TYPE[$ERDGESCHOSS]:-}"
chk "Farm enthält Anwesen" "1" \
    "$(printf '%s\n' "${CHILDREN[$FARM]:-}" | grep -cx 'Anwesen')"
chk "Anwesen enthält Haupteingang" "1" \
    "$(printf '%s\n' "${CHILDREN[$ANWESEN]:-}" | grep -cx 'Haupteingang')"
chk "Haupteingang enthält Erdgeschoss" "1" \
    "$(printf '%s\n' "${CHILDREN[$HAUPTEINGANG]:-}" | grep -cx 'Erdgeschoss')"
for _t in "$HOLE" "$T1" "$T2" "$T3" "$KAMMER"; do
    chk "${_t##*/} ist ein statischer Ordner" "d" \
        "${FS_BASE_TYPE[$_t]:-}"
done
chk "Canyon enthält Höhleneingang" "1" \
    "$(printf '%s\n' "${CHILDREN[$STEPPE/Canyon]:-}" | grep -cx 'Höhleneingang')"
chk "Höhleneingang enthält Höhlentunnel1" "1" \
    "$(printf '%s\n' "${CHILDREN[$HOLE]:-}" | grep -cx 'Höhlentunnel1')"
chk "Höhlentunnel1 enthält Höhlentunnel2" "1" \
    "$(printf '%s\n' "${CHILDREN[$T1]:-}" | grep -cx 'Höhlentunnel2')"
chk "Höhlentunnel2 enthält Höhlentunnel3" "1" \
    "$(printf '%s\n' "${CHILDREN[$T2]:-}" | grep -cx 'Höhlentunnel3')"
chk "Höhlentunnel3 enthält GroßeHöhlenkammer" "1" \
    "$(printf '%s\n' "${CHILDREN[$T3]:-}" | grep -cx 'GroßeHöhlenkammer')"

chk "alter Friedhof auf dem Schreibtisch ist weg" "0" \
    "$(printf '%s\n' "${CHILDREN[$HOME_DIR/Schreibtisch]:-}" | grep -cx 'Friedhof')"
for _of in Brachland Friedhof Steppe Canyon Moleratgebiet \
           Moleratgebiet1.1 Moleratgebiet1.2 Moleratgebiet2.1 \
           Moleratgebiet2.2 Moleratgebiet3.1 Moleratgebiet3.2 \
           Farmland Farm Anwesen AnwesenHaupteingang AnwesenErdgeschoss \
           CanyonHoehleneingang Höhlentunnel1 \
           Höhlentunnel2 Höhlentunnel3 GroßeHöhlenkammer; do
    chk "Orte/$_of.sh existiert" "1" \
        "$([ -f "$SCRIPT_DIR/Orte/$_of.sh" ] && echo 1 || echo 0)"
done

# ==================================================================
section "Quests: Vermisste Bewohner & Bier für Börty"
# ==================================================================
# --- Quest-Erhalt: Ton ---------------------------------------------
# Jeder Quest-Erhalt (direkt über quest_gained oder über quest_gain_once)
# spielt einen kurzen Ton - nicht nur einige Szenen.
SAW_SOUND=()
play_sound() { SAW_SOUND+=("$1"); }
OUT=()
quest_gain_once tontest
chk "quest_gain_once spielt einen Ton" "online" "${SAW_SOUND[0]:-}"
SAW_SOUND=()
quest_gained tontest
chk "quest_gained spielt einen Ton" "online" "${SAW_SOUND[0]:-}"
play_sound() { :; }

# --- Dialogauswahl: jeder gültige Tastendruck spielt einen Ton ------
. "$SCRIPT_DIR/kern/dialog.sh"
render() { :; }
read_key2() { LAST_KEY=1; return 0; }
handle_scroll_key() { return 1; }
SAW_SOUND=(); OUT=(); CHOICE=0
play_sound() { SAW_SOUND+=("$1"); }
ask "Ja." "Nein."
chk "Dialogauswahl spielt einen Ton" "select" "${SAW_SOUND[0]:-}"
chk "Dialogauswahl setzt CHOICE" "1" "$CHOICE"
chk "Dialogauswahl zeigt die gewählte Option" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c '» Ja.')"
unset -f render read_key2 handle_scroll_key
play_sound() { :; }

# quest_gain_once darf eine Quest nur EINMAL vergeben - später soll es
# mehrere Wege geben, dieselbe Quest zu bekommen (Hauptquest aus dem
# Gespräch mit Börty, später evtl. aus einem Fund oder von einem Zeugen).
VERMISSTE_GIVEN=0; BIER_GIVEN=0; BOERTY_FAVOR_DONE=0
OUT=()
quest_gain_once vermisste; chk_rc "erste Vergabe: neu" "$?" 0
chk "Meldung [ NEUE QUEST ]" "1" "$(printf '%s\n' "${OUT[@]}" | grep -c 'NEUE QUEST')"
chk "Questlog-Status danach: aktuell" "aktuell" "${QL_STATUS[vermisste]:-}"
VERMISSTE_GIVEN=1                       # das setzt der Vergeber (Börty)
OUT=()
quest_gain_once vermisste; chk_rc "zweiter Weg: nichts passiert" "$?" 1
chk "keine zweite Meldung" "0" "$(printf '%s\n' "${OUT[@]}" | grep -c 'NEUE QUEST')"

chk "Status verborgen, solange nicht erhalten" "verborgen" \
    "$(VERMISSTE_GIVEN=0; quest_status_vermisste)"
chk "Status aktuell, sobald erhalten" "aktuell" "$(quest_status_vermisste)"
chk "Eintrag 1 nennt die Frage" "Vermisste Bewohner? Was ist hier los?" \
    "$(quest_entries_vermisste | head -n1)"
chk "Ziel (Vermisste) nennt den Kern" "Finde heraus, wohin die Vermissten verschwinden – Börty kennt die Namen." \
    "$(quest_goal_vermisste)"
chk "Titel der Hauptquest" "Vermisste Bewohner" "${QL_TITLE[vermisste]}"
chk "steht bei den Hauptquests" "vermisste" \
    "$(printf '%s\n' "${QL_HAUPT[@]}" | grep -x vermisste)"

chk "Status (Bier) verborgen" "verborgen" "$(quest_status_bier)"
BIER_GIVEN=1
chk "Status (Bier) aktuell nach Annahme" "aktuell" "$(quest_status_bier)"
chk "Ziel (Bier): Lagermeister + Ort" "Hol die Lieferung: Lagermeister Samy Cage, Lager am Marktplatz (Zentrum)" \
    "$(quest_goal_bier)"
chk "Eintrag (Bier) nennt die 250 Bits" "1" \
    "$(quest_entries_bier | grep -c '250 Bits')"
chk "Eintrag (Bier) nennt die 24-Stunden-Frist" "1" \
    "$(quest_entries_bier | grep -c '24 Spielstunden')"
chk "Titel der Nebenquest" "Bier für Börty" "${QL_TITLE[bier]}"
chk "steht bei den Nebenquests" "bier" \
    "$(printf '%s\n' "${QL_NEBEN[@]}" | grep -x bier)"

# Bierlieferung: holen (BIER_TAKEN) und abgeben (BIER_DONE)
BIER_TAKEN=1
chk "Ziel nach dem Kauf: zurück zu Börty" \
    "Bring »Börtys Bierlieferung« zurück: Börty Smiles, Kneipe (Ostdistrikt)" \
    "$(quest_goal_bier)"
BIER_DONE=1
chk "Status nach dem Abgeben: abgeschlossen" "abgeschlossen" "$(quest_status_bier)"
chk "erledigt: kein Ziel mehr" "" "$(quest_goal_bier)"
chk "Verlauf hat 3 Stationen" "3" "$(quest_entries_bier | grep -c .)"
chk "Verlauf nennt die Abgabe" "1" \
    "$(quest_entries_bier | grep -c 'Bei Börty abgeliefert: 100 EXP und 30 Bits')"
chk "Verlauf nennt den Kauf bei Samy" "1" \
    "$(quest_entries_bier | grep -c 'Bei Samy Cage im Lager: 250 Bits bezahlt')"

# --- Michael Mitch. Vermisst ---------------------------------------
# Entsteht am Ende der Bierlieferung (boerty_mitch_scene); der Hinweis des
# Lagermeisters (SAMY_MITCH_INFO) führt in den Westdistrikt.
MITCH_GIVEN=0; SAMY_MITCH_INFO=0; BOERTY_VERMISSTE_INFO=0; SAMY_VERMISSTE_INFO=0
chk "Status (Mitch) verborgen, solange nicht erhalten" "verborgen" "$(quest_status_mitch)"
chk "Titel der Mitch-Quest" "Michael Mitch. Vermisst" "${QL_TITLE[mitch]}"
chk "steht bei den Nebenquests" "mitch" \
    "$(printf '%s\n' "${QL_NEBEN[@]}" | grep -x mitch)"
OUT=()
quest_gain_once mitch; chk_rc "Mitch-Quest: erste Vergabe -> neu" "$?" 0
chk "Meldung [ NEUE QUEST ]" "1" "$(printf '%s\n' "${OUT[@]}" | grep -c 'NEUE QUEST')"
MITCH_GIVEN=1                       # das setzt der Vergeber (boerty_mitch_scene)
OUT=()
quest_gain_once mitch; chk_rc "Mitch-Quest: zweiter Weg -> nichts" "$?" 1
chk "Status (Mitch) danach: aktuell" "aktuell" "$(quest_status_mitch)"
chk "Ziel (Mitch) ohne Samy-Hinweis" \
    "Finde heraus, wo Michael Mitch geblieben ist – frag dich durch die Stadt" \
    "$(quest_goal_mitch)"
chk "Verlauf (Mitch) nennt Börtys Aussage" "1" \
    "$(quest_entries_mitch | grep -c 'Börty: Michael Mitch ist vor ein paar Tagen verschwunden')"
SAMY_MITCH_INFO=1
chk "Ziel (Mitch) führt nach dem Hinweis in den Westdistrikt" \
    "Frage im Westdistrikt nach Michael Mitch" "$(quest_goal_mitch)"
chk "Verlauf (Mitch) nennt den Westdistrikt" "1" \
    "$(quest_entries_mitch | grep -c 'Westdistrikt')"

# Mitch im Restaurant getroffen: Das Ziel führt zurück zu Börty, der
# Verlauf hält die Auflösung fest. Danach ist die Quest abgeschlossen.
MITCH_TALKED=1
chk "Ziel (Mitch) nach dem Treffen: zurück zu Börty" \
    "Geh zu Börty in die Kneipe (Ostdistrikt) und erzähle ihm von Mitch" \
    "$(quest_goal_mitch)"
chk "Verlauf (Mitch) nennt das Restaurant" "1" \
    "$(quest_entries_mitch | grep -c 'Im Restaurant im Westdistrikt')"
chk "Mitch-Quest bleibt nach dem Treffen aktuell" "aktuell" "$(quest_status_mitch)"
chk "Vermisste-Log meldet Mitchs Auftauchen" "1" \
    "$(quest_entries_vermisste | grep -c 'Mitch ist aufgetaucht')"

MITCH_DONE=1
chk "Status (Mitch) nach Börtys Info: abgeschlossen" "abgeschlossen" "$(quest_status_mitch)"
chk "erledigt: kein Mitch-Ziel mehr" "" "$(quest_goal_mitch)"
chk "Verlauf (Mitch) nennt die neue Gehilfen-Suche" "1" \
    "$(quest_entries_mitch | grep -c 'neuen Gehilfen')"
chk "Vermisste-Log nennt Börtys neuen Gehilfen" "1" \
    "$(quest_entries_vermisste | grep -c 'braucht Börty einen neuen Gehilfen')"

# --- Ein neuer Gehilfe für Börty ------------------------------------
GEHILFE_GIVEN=0
chk "Status (Gehilfe) verborgen, solange nicht erhalten" "verborgen" "$(quest_status_gehilfe)"
chk "Titel der Gehilfen-Quest" "Ein neuer Gehilfe für Börty" "${QL_TITLE[gehilfe]}"
chk "steht bei den Nebenquests" "gehilfe" \
    "$(printf '%s\n' "${QL_NEBEN[@]}" | grep -x gehilfe)"
OUT=()
quest_gain_once gehilfe; chk_rc "Gehilfen-Quest: erste Vergabe -> neu" "$?" 0
chk "Meldung [ NEUE QUEST ]" "1" "$(printf '%s\n' "${OUT[@]}" | grep -c 'NEUE QUEST')"
GEHILFE_GIVEN=1
OUT=()
quest_gain_once gehilfe; chk_rc "Gehilfen-Quest: zweiter Weg -> nichts" "$?" 1
chk "Status (Gehilfe) danach: aktuell" "aktuell" "$(quest_status_gehilfe)"
chk "Ziel (Gehilfe)" \
    "Halte Ausschau nach einem neuen Gehilfen für Börty" "$(quest_goal_gehilfe)"
chk "Verlauf (Gehilfe) nennt die Bitte" "1" \
    "$(quest_entries_gehilfe | grep -c 'Ich habe versprochen, mich umzusehen')"

# Das Log der Hauptquest »Vermisste Bewohner« wächst mit dem Mitch-Strang.
chk "Vermisste-Log nennt Mitch" "1" \
    "$(quest_entries_vermisste | grep -c 'Michael Mitch, der Gehilfe von Börty, ist verschwunden')"
BOERTY_VERMISSTE_INFO=1
chk "Vermisste-Log nennt Holmes" "1" \
    "$(quest_entries_vermisste | grep -c 'Sherlock Holmes arbeitet an dem Fall')"
SAMY_VERMISSTE_INFO=1
chk "Vermisste-Log nennt Samys Sicht" "1" \
    "$(quest_entries_vermisste | grep -c 'Auch im Lager hört man davon')"

BIER_TAKEN=0; BIER_DONE=0; BIER_GIVEN=0; VERMISSTE_GIVEN=0
MITCH_GIVEN=0; MITCH_TALKED=0; MITCH_DONE=0; GEHILFE_GIVEN=0
SAMY_MITCH_INFO=0; BOERTY_VERMISSTE_INFO=0; SAMY_VERMISSTE_INFO=0

# ==================================================================
section "Questlog: Titel rot, Fließtext grau"
# ==================================================================
quest_define testrot neben "Rottest" "Eine Testbeschreibung für die Farbe."
quest_set_status testrot aktuell
quest_goal_testrot() { printf 'Ein Testziel.'; }
quest_entries_testrot() { printf 'Ein Testeintrag.'; }
ql_build_details testrot 60
chk "Questlog-Details haben Zeilen" "1" \
    "$([ "${#QL_DCOL[@]}" -gt 0 ] && echo 1 || echo 0)"
_ql_title_red=1
_ql_body_gray=1
for _i in "${!QL_DCOL[@]}"; do
    case "${QL_DTXT[$_i]}" in
        "◈ "*|"── Verlauf ──")
            case "${QL_DCOL[$_i]}" in *"$DANGER"*) ;; *) _ql_title_red=0 ;; esac ;;
        *)
            [ "${QL_DCOL[$_i]}" = "$MUTED" ] || _ql_body_gray=0 ;;
    esac
done
chk "Questlog-Titel und Überschriften sind rot" "1" "$_ql_title_red"
chk "Questlog-Fließtext ist grau" "1" "$_ql_body_gray"
chk "Questlog-Titel ist fett rot" "$DANGER$BOLD" "${QL_DCOL[0]}"
unset _i _ql_title_red _ql_body_gray
# Testquest wieder entfernen, damit spätere Statistik-Checks unverändert bleiben.
_ql_keep=()
for _q in "${QL_NEBEN[@]}"; do
    [ "$_q" = "testrot" ] || _ql_keep+=("$_q")
done
QL_NEBEN=("${_ql_keep[@]}")
unset _q _ql_keep 'QL_TITLE[testrot]' 'QL_DETAIL[testrot]' 'QL_STATUS[testrot]'
unset -f quest_goal_testrot quest_entries_testrot

# ==================================================================
section "Erlernte Befehle"
# ==================================================================
LEARNED=()
knows pwd; chk_rc "knows: unbekannt -> Fehler" "$?" 1
OUT=()
learn_cmd ping; chk_rc "learn_cmd: neu gelernt" "$?" 0
knows ping;     chk_rc "knows: danach bekannt"  "$?" 0
learn_cmd ping; chk_rc "learn_cmd: zweimal -> schon bekannt" "$?" 1
chk "learn_cmd meldet es im Ausgabefenster" "1" "$(printf '%s\n' "${OUT[@]}" | grep -c 'Neuer Befehl erlernt: ping')"

LEARNED=(); OUT=()
general_teach_meta
for c in help character questlog inventar; do
    knows "$c"; chk_rc "General lehrt $c" "$?" 0
done
OUT=()
general_teach_meta
chk "General lehrt nichts doppelt" "0" "${#OUT[@]}"
chk "META_CMDS enthält vier Befehle" "4" "${#META_CMDS[@]}"

LEARNED=(); OUT=()
meta_learn_silently
knows questlog; chk_rc "meta_learn_silently ergänzt Menü-Befehle" "$?" 0
chk "meta_learn_silently schreibt nichts ins Fenster" "0" "${#OUT[@]}"

# ==================================================================
section "Hilfe-Register"
# ==================================================================
chk "use ist ein Spiel-Befehl" "1" \
    "$(printf '%s\n' "${HELP_GAME[@]}" | grep -cx use)"
chk "use steht nicht mehr bei Terminal-Befehlen" "0" \
    "$(printf '%s\n' "${HELP_TERM[@]}" | grep -cx use)"
chk "exit ist ein Spiel-Befehl" "1" \
    "$(printf '%s\n' "${HELP_GAME[@]}" | grep -cx exit)"
chk "exit steht nicht mehr bei Terminal-Befehlen" "0" \
    "$(printf '%s\n' "${HELP_TERM[@]}" | grep -cx exit)"
chk "Inventar nennt den Alias inventory" "inventar | inventory" \
    "${HELP_USAGE[inventar]}"
chk "ls nennt weder -a noch [pfad]" "ls" "${HELP_USAGE[ls]}"
chk "statistics ist ein Spiel-Befehl" "1" \
    "$(printf '%s\n' "${HELP_GAME[@]}" | grep -cx statistics)"
chk "statistics wird gelernt" "gelernt" "${HELP_AVAIL[statistics]:-}"
statistics_is_command statistik; chk_rc "statistik bleibt ein Alias" "$?" 0
statistics_is_command stats;      chk_rc "stats ist kein Alias mehr" "$?" 1
chk "achievements ist ein Spiel-Befehl" "1" \
    "$(printf '%s\n' "${HELP_GAME[@]}" | grep -cx achievements)"
chk "achievements wird gelernt" "gelernt" "${HELP_AVAIL[achievements]:-}"
LEARNED=(pwd ls cd cat touch grep use help character questlog inventar save)
help_build_rows 0
chk "Terminal-Liste zeigt use nicht" "0" \
    "$(printf '%s\n' "${HELP_ROWS[@]}" | grep -cx use)"
chk_rc "Terminal-Hilfe alphabetisch" \
    "$(printf '%s\n' "${HELP_ROWS[@]}" | LC_ALL=C sort -c >/dev/null 2>&1; echo $?)" 0
help_build_rows 1
chk "Spiel-Liste zeigt use, sobald gelernt" "1" \
    "$(printf '%s\n' "${HELP_ROWS[@]}" | grep -cx use)"
chk "Hilfe zeigt achievements vor dem Lernen nicht" "0" \
    "$(printf '%s\n' "${HELP_ROWS[@]}" | grep -cx achievements)"
chk "Hilfe zeigt statistics vor dem Lernen nicht" "0" \
    "$(printf '%s\n' "${HELP_ROWS[@]}" | grep -cx statistics)"
chk_rc "Spiel-Hilfe alphabetisch" \
    "$(printf '%s\n' "${HELP_ROWS[@]}" | LC_ALL=C sort -c >/dev/null 2>&1; echo $?)" 0
LEARNED+=(achievements statistics)
help_build_rows 1
chk "Hilfe zeigt achievements nach dem Lernen" "1" \
    "$(printf '%s\n' "${HELP_ROWS[@]}" | grep -cx achievements)"
chk "Hilfe zeigt statistics nach dem Lernen" "1" \
    "$(printf '%s\n' "${HELP_ROWS[@]}" | grep -cx statistics)"
chk_rc "Spiel-Hilfe mit neuen Befehlen alphabetisch" \
    "$(printf '%s\n' "${HELP_ROWS[@]}" | LC_ALL=C sort -c >/dev/null 2>&1; echo $?)" 0

# --- Tab: Befehlsnamen werden mit einem Leerzeichen abgeschlossen -----
. "$SCRIPT_DIR/kern/input.sh"
_OLD_LEARNED=("${LEARNED[@]}")
LEARNED=(help); TUT_STAGE=0
CMD_BUFFER="he"; COMP_SIG=""; OUT=()
complete_command he
chk "Tab-Ergänzung eines Befehls endet mit Leerzeichen" "help " "$CMD_BUFFER"
LEARNED=("${_OLD_LEARNED[@]}")
unset _OLD_LEARNED

# ==================================================================
section "Achievements"
# ==================================================================
achievements_reset
chk "Achievement ist registriert" "1" \
    "$(printf '%s\n' "${ACH_ORDER[@]}" | grep -cx kompass_geeicht)"
achievement_has kompass_geeicht
chk_rc "Achievement startet gesperrt" "$?" 1
char_reset
TOKENS_MAX=1000
OUT=()
achievement_unlock kompass_geeicht
chk_rc "Achievement lässt sich freischalten" "$?" 0
chk "Achievement-Titel" "Kompass Geeicht" "${ACH_TITLE[kompass_geeicht]}"
chk "Achievement-Text" "Jetzt weiß ich worum es hier geht" "${ACH_TEXT[kompass_geeicht]}"
chk "Dialog meldet das Achievement" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c 'Achievement erhalten')"
chk "Dialog meldet die 50 EXP" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c 'Belohnung: 50 EXP')"
chk "Achievement gibt 50 EXP" "50" "$EXP"
achievement_unlock kompass_geeicht
chk_rc "Achievement wird nur einmal vergeben" "$?" 1
chk "zweites Freischalten gibt keine weiteren EXP" "50" "$EXP"
achievements_build_shown
chk "Fenster zeigt freigeschaltete Einträge" "1" "${#ACH_SHOWN[@]}"
chk "Fenster enthält die ID" "kompass_geeicht" "${ACH_SHOWN[0]}"

# Auslöser: README fertig + Wechsel vom Agenten-Ordner nach Downloads.
achievements_reset
README_DONE=1
achievement_check_kompass_geeicht "$AGENT_DIR" "$HOME_DIR/Downloads"
achievement_has kompass_geeicht
chk_rc "erster Wechsel in den Downloads-Ordner schaltet frei" "$?" 0
achievements_reset
achievement_check_kompass_geeicht "$HOME_DIR" "$HOME_DIR/Downloads"
achievement_has kompass_geeicht
chk_rc "Downloads erreicht auch von anderswo frei" "$?" 0
achievements_reset
README_DONE=0
achievement_check_kompass_geeicht "$AGENT_DIR" "$HOME_DIR/Downloads"
achievement_has kompass_geeicht
chk_rc "ohne README schaltet nicht frei" "$?" 1
achievements_reset
char_reset

# ==================================================================
section "Sprecherfarben: Charaktere nie grau"
# ==================================================================
. "$SCRIPT_DIR/kern/render.sh"
chk "Francesco hat eine Sprecherfarbe" "1" \
    "$([ -n "${SPEAKER_COLOR[Francesco]:-}" ] && echo 1 || echo 0)"
chk "Francesco ist nicht grau" "1" \
    "$([ "${SPEAKER_COLOR[Francesco]:-}" != "$MUTED" ] && echo 1 || echo 0)"
chk "line_color färbt Francesco" "$FRANCESCO_C" \
    "$(line_color 'Francesco: Buongiorno.')"
chk "line_color färbt Gregor Molerat" "$GREGOR_C" \
    "$(line_color 'Gregor Molerat: Nek war mein Sohn.')"
chk "line_color färbt Marlene Molerat" "$MARLENE_C" \
    "$(line_color 'Marlene Molerat: Mein Junge.')"
chk "line_color färbt Chantal Molerat" "$CHANTAL_C" \
    "$(line_color 'Chantal Molerat: Wie lange dauert das?')"
chk "line_color färbt Samy" "$SAMY_C" \
    "$(line_color 'Samy: Kisten. Sechsundvierzig.')"
chk "line_color färbt Bruno" "$BRUNO_C" \
    "$(line_color 'Bruno: Bruno Amboss. Schmied.')"
chk "line_color färbt Jack Bones" "$JACK_BONES_C" \
    "$(line_color 'Jack Bones: Willkommen im SurvivalShop.')"
chk "line_color färbt die Armbanduhr" "$ARMBANDUHR_C" \
    "$(line_color 'Armbanduhr: Ich ticke.')"
chk "line_color färbt Jack Nullpunkt" "$JACK_C" \
    "$(line_color 'Jack Nullpunkt: Ich habe ein Bild.')"
chk "line_color färbt Sherlock Holmes" "$SHERLOCK_C" \
    "$(line_color 'Sherlock Holmes: Es gibt keinen Fall.')"
chk "line_color färbt Börty Smiles" "$BOERTY_C" \
    "$(line_color 'Börty Smiles: Auf seinen Namen.')"
chk "line_color färbt Simple Jon" "$JON_C" \
    "$(line_color 'Simple Jon: Ich halte die Stellung.')"
_bad_colors=0
for _sp in "${!SPEAKER_COLOR[@]}"; do
    [ "${SPEAKER_COLOR[$_sp]}" = "$MUTED" ] && _bad_colors=$((_bad_colors + 1))
done
chk "keine registrierte Sprecherfarbe ist grau" "0" "$_bad_colors"
chk "alle Charaktere des Spiels sind registriert" "0" \
    "$(for _sp in README Pixi 'Pixi Nullpunkt' Rachel 'Rachel Nullpunkt' \
                  Jack 'Jack Nullpunkt' Amanda Börty 'Börty Smiles' Sherlock \
                  'Sherlock Holmes' Michael Tracey Jimmy 'Guy Sus' Torwächter \
                  'Simon Guard' 'Simple Jon' Kriegsrat Ermittler Francesco Samy \
                  Bruno 'Jack Bones' Armbanduhr 'Gregor Molerat' \
                  'Marlene Molerat' 'Chantal Molerat'; do
            [ -n "${SPEAKER_COLOR[$_sp]:-}" ] || printf '%s\n' "$_sp"
        done | wc -l)"

