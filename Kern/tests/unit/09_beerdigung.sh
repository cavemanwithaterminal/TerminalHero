# ============================================================
#  Unit-Test-Teil: Neks Beerdigung & Neks Familie
#  Wird von Kern/tests/unit.sh in fester Reihenfolge geladen.
# ============================================================
# ==================================================================
section "Neks Beerdigung: Termin, Leichenort & Gemunkel"
# ==================================================================
NEK_DONE=1
NEK_FOUND=1
NEK_GIVEN=1
NEK_CORPSE_BROUGHT=0
TYPE=(); CHILDREN=(); CONTENT=(); DIALOG=()
NEKS_LEICHE_PATH=""
DRAGGED_CORPSE=""
WORLD_STARTED=1
WORLD_SECS=0
CWD="$HOME_DIR/Schreibtisch"
VIEW_DIR="$CWD"
OUT=()

CAVE="$HOME_DIR/Schreibtisch/Höhleneingang/Molerathöhle/NeksLeiche"
SIMON="$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/NeksLeiche"
LOST="$HOME_DIR/Schreibtisch/DesktopCity/Westdistrikt/NeksLeiche"
CEMETERY="$HOME_DIR/Schreibtisch/Brachland/Friedhof"
BASE="$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang"

reset_funeral_test() {
    NEK_FUNERAL_GIVEN=0
    NEK_FUNERAL_DISPOSITION=""
    NEK_FUNERAL_DAY=-1
    NEK_FUNERAL_DISCOVERY_DAY=-1
    NEK_FUNERAL_FOUND=0
    NEK_FUNERAL_DONE=0
    NEK_FUNERAL_FAILED=0
    NEK_FAMILY_GIVEN=0
    NEK_CORPSE_BROUGHT=0
    TYPE=(); CHILDREN=(); CONTENT=(); DIALOG=()
    NEKS_LEICHE_PATH=""
    DRAGGED_CORPSE=""
    OUT=()
}

set_world_day_minute() {   # <tag> <minute>
    local day="$1" min="$2"
    WORLD_STARTED=1
    WORLD_SECS=$(( ( day * CLOCK_DAY_MIN + min - CLOCK_START_MIN ) * CLOCK_MIN_DEN / CLOCK_MIN_NUM ))
    WORLD_SHOWN_MIN=-1
}

place_corpse() {   # <pfad>
    TYPE=()
    NEKS_LEICHE_PATH="$1"
    TYPE["$1"]=f
    NEK_CORPSE_BROUGHT=0
}

out_count() { printf '%s\n' "${OUT[@]}" | grep -cF -- "$1"; }
out_has() { printf '%s\n' "${OUT[@]}" | grep -qF -- "$1" && printf '1' || printf '0'; }

chk "Datum Starttag" "25.01.240" "$(cal_date_text_for_day 0)"
chk "Datum Beerdigung nach 5 Tagen" "30.01.240" "$(cal_date_text_for_day 5)"
chk "Datum Beerdigung nach 7 Tagen" "01.02.240" "$(cal_date_text_for_day 7)"

# --- Leichenort erkennen ------------------------------------------
place_corpse "$CAVE"
chk "Leiche in der Molerathöhle" "cave" "$(nek_funeral_disposition_now)"
place_corpse "$SIMON"
chk "Leiche beim Haupttor" "simon" "$(nek_funeral_disposition_now)"
place_corpse "$LOST"
chk "Leiche irgendwo anders" "lost" "$(nek_funeral_disposition_now)"
TYPE=(); NEKS_LEICHE_PATH=""; NEK_CORPSE_BROUGHT=1
chk "gebrachte Leiche bleibt simon" "simon" "$(nek_funeral_disposition_now)"

# --- Höhle: Beerdigung fünf Tage später ---------------------------
reset_funeral_test
place_corpse "$CAVE"
set_world_day_minute 0 360
nek_funeral_start
chk_rc "Beerdigung startet" "$?" "0"
chk "Quest ist vergeben" "1" "$NEK_FUNERAL_GIVEN"
chk "Ablage ist cave" "cave" "$NEK_FUNERAL_DISPOSITION"
chk "Beerdigung an Tag 5" "5" "$NEK_FUNERAL_DAY"
chk "kein Fundtag nötig" "-1" "$NEK_FUNERAL_DISCOVERY_DAY"
chk "Queststatus aktuell" "aktuell" "$(quest_status_nek_beerdigung)"
chk "Questziel nennt den 30.01.240" "1" \
    "$(quest_goal_nek_beerdigung | grep -c '30.01.240')"
chk "Questziel nennt 16:00" "1" \
    "$(quest_goal_nek_beerdigung | grep -c '16:00')"
chk "Eintrag nennt die Molerathöhle" "1" \
    "$(quest_entries_nek_beerdigung | grep -c 'Molerathöhle')"
chk "Neue Quest wird gemeldet" "1" \
    "$(out_count 'Neks Beerdigung')"
chk "Datum steht in der Questnotiz" "1" \
    "$(out_count '30.01.240')"
nek_funeral_start
chk_rc "zweiter Start wird abgewiesen" "$?" "1"
chk "Tag bleibt unverändert" "5" "$NEK_FUNERAL_DAY"

# --- Simon: gleicher Termin ----------------------------------------
reset_funeral_test
place_corpse "$SIMON"
set_world_day_minute 0 360
nek_funeral_start
chk "gebrachte Leiche: Ablage simon" "simon" "$NEK_FUNERAL_DISPOSITION"
chk "gebrachte Leiche: Tag 5" "5" "$NEK_FUNERAL_DAY"
chk "Eintrag nennt das Haupttor" "1" \
    "$(quest_entries_nek_beerdigung | grep -c 'Haupttor')"

# --- Zurückgelassen: Fund nach zwei Tagen, Beerdigung nach sieben --
reset_funeral_test
place_corpse "$LOST"
set_world_day_minute 0 360
nek_funeral_start
chk "zurückgelassen: Ablage lost" "lost" "$NEK_FUNERAL_DISPOSITION"
chk "zurückgelassen: Fund an Tag 2" "2" "$NEK_FUNERAL_DISCOVERY_DAY"
chk "zurückgelassen: Beerdigung an Tag 7" "7" "$NEK_FUNERAL_DAY"
chk "Queststatus aktuell" "aktuell" "$(quest_status_nek_beerdigung)"
chk "Eintrag nennt den Fundtag" "1" \
    "$(quest_entries_nek_beerdigung | grep -c '27.01.240')"
chk "Eintrag nennt das Vergammeln" "1" \
    "$(quest_entries_nek_beerdigung | grep -c 'vergammeln')"

# --- Gemunkel: sechs Orte, Datum und Variante ----------------------
reset_funeral_test
place_corpse "$CAVE"
set_world_day_minute 0 360
nek_funeral_start
CWD="$BASE/Süddistrikt"
NEK_RUMOR_LAST_CWD="$BASE"
OUT=()
nek_funeral_rumor_maybe
chk_rc "Gemunkel beim Betreten" "$?" "0"
chk "Gemunkel nennt das Datum" "1" "$(out_count '30.01.240')"
chk "Gemunkel nennt 16 Uhr" "1" "$(out_count '16 Uhr')"
chk "Höhlen-Variante ohne Vergammeln" "0" "$(out_count 'vergammeln')"
chk "Gemunkel steht im Dialogfenster" "2" "${#OUT[@]}"
chk_rc "kein zweites Gemunkel im selben Ort" "$(nek_funeral_rumor_maybe; echo $?)" "1"
chk "kein doppelter Eintrag" "2" "${#OUT[@]}"

reset_funeral_test
place_corpse "$LOST"
set_world_day_minute 0 360
nek_funeral_start
CWD="$BASE/Zentrum"
NEK_RUMOR_LAST_CWD="$BASE"
OUT=()
nek_funeral_rumor_maybe
chk "Lost-Gemunkel nennt das Vergammeln" "1" \
    "$(out_count 'vergammeln lassen')"
chk "Lost-Gemunkel nennt das Beerdigungsdatum" "1" \
    "$(out_count '01.02.240')"
chk "Lost-Gemunkel nennt den Spieler" "1" \
    "$(out_count 'der Spieler')"

CWD="$HOME_DIR/Schreibtisch/Höhleneingang"
NEK_RUMOR_LAST_CWD="$BASE"
OUT=()
chk_rc "kein Gemunkel außerhalb der sechs Orte" "$(nek_funeral_rumor_maybe; echo $?)" "1"
chk "kein Eintrag außerhalb" "0" "${#OUT[@]}"

CWD="$BASE"
NEK_RUMOR_LAST_CWD="$BASE/Süddistrikt"
OUT=()
nek_funeral_rumor_maybe
chk_rc "Gemunkel im Haupteingang" "$?" "0"
chk "Haupteingang nennt das Datum" "1" "$(out_count '01.02.240')"

reset_funeral_test
place_corpse "$CAVE"
set_world_day_minute 0 360
nek_funeral_start
set_world_day_minute 6 360
CWD="$BASE/Norddistrikt"
NEK_RUMOR_LAST_CWD="$BASE"
OUT=()
chk_rc "nach dem Termin kein Gemunkel" "$(nek_funeral_rumor_maybe; echo $?)" "1"
chk "nach dem Termin kein Eintrag" "0" "${#OUT[@]}"

# --- Fund der zurückgelassenen Leiche ------------------------------
reset_funeral_test
place_corpse "$LOST"
set_world_day_minute 0 360
nek_funeral_start
set_world_day_minute 1 720
nek_funeral_tick
chk "vor dem Fundtag noch nicht gefunden" "0" "$NEK_FUNERAL_FOUND"
set_world_day_minute 2 360
nek_funeral_tick
chk_rc "Fundtag meldet den Fund" "$?" "0"
chk "Leiche ist gefunden" "1" "$NEK_FUNERAL_FOUND"
chk "Fund wird im Questlog vermerkt" "1" \
    "$(out_count 'Neks Leiche wurde in der Welt gefunden')"

# --- Gäste & Standarddialoge vor 16:00 ----------------------------
guest_standard_key() {
    case "$1" in
        pixi)           printf '%s' "Ich schreibe seinen Namen auf" ;;
        jack)           printf '%s' "auf dem er wegsieht" ;;
        rachel)         printf '%s' "Nur der Name. Und das Datum" ;;
        sherlockholmes) printf '%s' "Es gibt keinen Fall" ;;
        torwaechter)    printf '%s' "Nek war mein Freund" ;;
        simplejon)      printf '%s' "Sein Stuhl im Wachhaus" ;;
        boerty)         printf '%s' "Heute Abend gebe ich einen aus" ;;
        gregor)         printf '%s' "Wir beerdigen meinen Sohn" ;;
        marlene)        printf '%s' "seine Uniform gebügelt" ;;
        chantal)        printf '%s' "Ich habe danach noch was vor" ;;
    esac
}

guest_outrage_key() {
    case "$1" in
        pixi)           printf '%s' "Heute fällt mir das schwer" ;;
        jack)           printf '%s' "ob ich es zeigen soll" ;;
        rachel)         printf '%s' "Warum hast du ihn liegen lassen" ;;
        sherlockholmes) printf '%s' "Warum hast du ihn liegen lassen" ;;
        torwaechter)    printf '%s' "aber du hattest ihn" ;;
        simplejon)      printf '%s' "nicht wütend zu sein" ;;
        boerty)         printf '%s' "Für dich nicht" ;;
        gregor)         printf '%s' "Steh hier nicht herum" ;;
        marlene)        printf '%s' "Du hättest ihn mitbringen können" ;;
        chantal)        printf '%s' "widerlich" ;;
    esac
}

guest_after_key() {
    case "$1" in
        pixi)           printf '%s' "Der Nachruf steht" ;;
        jack)           printf '%s' "Das, auf dem er wegsieht" ;;
        rachel)         printf '%s' "Die Seite ist ruhig" ;;
        sherlockholmes) printf '%s' "Der Fall ist geschlossen" ;;
        torwaechter)    printf '%s' "Die Erde ist noch weich" ;;
        simplejon)      printf '%s' "Ich gehe zurück ins Wachhaus" ;;
        boerty)         printf '%s' "Heute Abend ist die Kneipe offen" ;;
        gregor)         printf '%s' "Jetzt gehen wir nach Hause" ;;
        marlene)        printf '%s' "Ich habe geweint" ;;
        chantal)        printf '%s' "Endlich vorbei" ;;
    esac
}

reset_funeral_test
place_corpse "$CAVE"
set_world_day_minute 0 360
nek_funeral_start
CWD="$CEMETERY"
TYPE["$CEMETERY"]=d
CHILDREN["$CEMETERY"]=""
set_world_day_minute 5 600
nek_funeral_guests_sync

for id in "${NEK_FUNERAL_GUESTS[@]}"; do
    p="$(nek_funeral_guest_path "$id")"
    chk "Gastdatei ${NEK_FUNERAL_GUEST_FILE[$id]} steht im Friedhof" \
        "f" "${TYPE[$p]:-}"
    chk "Gastdialog ${NEK_FUNERAL_GUEST_FILE[$id]} ist gesetzt" \
        "1" "$([ -n "${DIALOG[$p]:-}" ] && printf '1' || printf '0')"
    chk "Gastinhalt ${NEK_FUNERAL_GUEST_FILE[$id]} nennt den Anlass" \
        "1" "$(printf '%s' "${CONTENT[$p]:-}" | grep -c 'Neks Beerdigung')"
done
chk "zehn Gäste im Friedhof" "10" \
    "$(printf '%s\n' "${CHILDREN[$CEMETERY]}" | grep -c .)"

for id in "${NEK_FUNERAL_GUESTS[@]}"; do
    nek_funeral_guest_standard "$id" >/dev/null 2>&1
    chk "Standarddialog ${NEK_FUNERAL_GUEST_FILE[$id]} nennt die Beerdigung" \
        "1" "$(out_count 'Beerdigung')"
    chk "Standarddialog ${NEK_FUNERAL_GUEST_FILE[$id]} hat eigenen Text" \
        "1" "$(out_count "$(guest_standard_key "$id")")"
done

nek_funeral_francesco_standard >/dev/null 2>&1
chk "Francesco-Standarddialog vor 16:00" \
    "1" "$(out_count 'Arbeitsanweisung')"
chk "Francesco nennt den Termin" \
    "1" "$(out_count 'Um 16:00 legen wir Nek Molerat')"

# »lost«: Der Agent hat Nek liegen gelassen. Jede Figur wird empört.
NEK_FUNERAL_DISPOSITION=lost
for id in "${NEK_FUNERAL_GUESTS[@]}"; do
    nek_funeral_guest_standard "$id" >/dev/null 2>&1
    chk "lost-Empörung bei ${NEK_FUNERAL_GUEST_FILE[$id]}" \
        "1" "$(out_count "$(guest_outrage_key "$id")")"
done
nek_funeral_francesco_standard >/dev/null 2>&1
chk "lost-Empörung bei Francesco" \
    "1" "$(out_count 'im Dreck vergessen')"

# --- Beerdigung: nur am Tag ab 16:00 am Friedhof -------------------
reset_funeral_test
place_corpse "$CAVE"
set_world_day_minute 0 360
nek_funeral_start
LEVEL=0; EXP=0; TOKENS_MAX=1000; SKILL_POINTS=0
BITS=0; BITS_EARNED=0
CWD="$CEMETERY"
TYPE["$CEMETERY"]=d
CHILDREN["$CEMETERY"]=""
set_world_day_minute 5 959
nek_funeral_tick
chk "vor 16:00 nicht abgeschlossen" "0" "$NEK_FUNERAL_DONE"
chk "vor 16:00 nicht gescheitert" "0" "$NEK_FUNERAL_FAILED"
chk "vor 16:00 stehen die Gäste bereit" "10" \
    "$(printf '%s\n' "${CHILDREN[$CEMETERY]}" | grep -c .)"
set_world_day_minute 5 960
nek_funeral_tick
chk_rc "16:00 auf dem Friedhof schließt ab" "$?" "0"
chk "Beerdigung abgeschlossen" "1" "$NEK_FUNERAL_DONE"
chk "Beerdigung nicht gescheitert" "0" "$NEK_FUNERAL_FAILED"
chk "1000 EXP Belohnung" "1" "$(out_count 'Questbelohnung: 1000 EXP')"
chk "Queststatus abgeschlossen" "abgeschlossen" "$(quest_status_nek_beerdigung)"
chk "1000 EXP: Level 4" "4" "$LEVEL"
chk "1000 EXP: EXP 0" "0" "$EXP"
chk "vier Aufstiege: MaxTokens 1004" "1004" "$TOKENS_MAX"
chk "vier Aufstiege: 4 Skillpunkte" "4" "$SKILL_POINTS"
chk "vier Aufstiege: 32 Bits" "32" "$BITS"
chk "Bits-Ertrag verbucht" "32" "$BITS_EARNED"
chk "Level-Up nennt +8 Bits" "4" "$(out_count '+8 Bits')"
chk "Rede nennt alle Gäste: Simon" "1" "$(out_has 'Simon Guard')"
chk "Rede nennt alle Gäste: Simple Jon" "1" "$(out_has 'Simple Jon')"
chk "Rede nennt alle Gäste: Pixi" "1" "$(out_has 'Pixi')"
chk "Rede nennt alle Gäste: Jack" "1" "$(out_has 'Jack Nullpunkt')"
chk "Rede nennt alle Gäste: Rachel" "1" "$(out_has 'Rachel')"
chk "Rede nennt alle Gäste: Sherlock" "1" "$(out_has 'Sherlock Holmes')"
chk "Rede nennt alle Gäste: Börty" "1" "$(out_has 'Börty')"
chk "Rede nennt alle Gäste: Gregor" "1" "$(out_has 'Gregor Molerat')"
chk "Rede nennt alle Gäste: Marlene" "1" "$(out_has 'Marlene Molerat')"
chk "Rede nennt alle Gäste: Chantal" "1" "$(out_has 'Chantal Molerat')"
chk "Totengräber hält die Rede" "1" "$(out_count 'Die Toten beschweren sich nie')"

# Nach der Feier bleiben die Gäste bis Mitternacht am Grab und haben
# kurze Nachgespräche.
for id in "${NEK_FUNERAL_GUESTS[@]}"; do
    p="$(nek_funeral_guest_path "$id")"
    chk "Gast ${NEK_FUNERAL_GUEST_FILE[$id]} bleibt nach der Feier" \
        "f" "${TYPE[$p]:-}"
    nek_funeral_guest_standard "$id" >/dev/null 2>&1
    chk "Nachgespräch ${NEK_FUNERAL_GUEST_FILE[$id]}" \
        "1" "$(out_count "$(guest_after_key "$id")")"
done
nek_funeral_francesco_after >/dev/null 2>&1
chk "Francesco-Nachgespräch" "1" "$(out_count 'Die Erde ist geschlossen')"

# Mitternacht: Die temporären Gäste-Dateien verschwinden.
set_world_day_minute 6 0
nek_funeral_tick
chk_rc "Mitternacht räumt den Friedhof" "$?" "0"
chk "Mitternacht wird angekündigt" "1" "$(out_count 'Mitternacht')"
for id in "${NEK_FUNERAL_GUESTS[@]}"; do
    p="$(nek_funeral_guest_path "$id")"
    chk "Gast ${NEK_FUNERAL_GUEST_FILE[$id]} ist nach Mitternacht fort" \
        "" "${TYPE[$p]:-}"
done
chk "Quest bleibt nach Mitternacht abgeschlossen" "1" "$NEK_FUNERAL_DONE"
chk "Quest scheitert nach Abschluss nicht" "0" "$NEK_FUNERAL_FAILED"

# Falscher Ort: an Tag 5 passiert nichts, an Tag 6 scheitert es.
reset_funeral_test
place_corpse "$CAVE"
set_world_day_minute 0 360
nek_funeral_start
CWD="$BASE"
set_world_day_minute 5 960
nek_funeral_tick
chk "falscher Ort: nicht abgeschlossen" "0" "$NEK_FUNERAL_DONE"
chk "falscher Ort: noch nicht gescheitert" "0" "$NEK_FUNERAL_FAILED"
set_world_day_minute 6 0
nek_funeral_tick
chk_rc "Tag danach lässt die Quest scheitern" "$?" "0"
chk "Beerdigung gescheitert" "1" "$NEK_FUNERAL_FAILED"
chk "nicht abgeschlossen" "0" "$NEK_FUNERAL_DONE"
chk "Queststatus gescheitert" "gescheitert" "$(quest_status_nek_beerdigung)"
chk "Scheitern wird gemeldet" "1" "$(out_count 'QUEST GESCHEITERT')"

# Auch die Lost-Variante kann am Friedhof abgeschlossen werden.
reset_funeral_test
place_corpse "$LOST"
set_world_day_minute 0 360
nek_funeral_start
CWD="$CEMETERY"
set_world_day_minute 7 960
nek_funeral_tick
chk "Lost-Beerdigung abgeschlossen" "1" "$NEK_FUNERAL_DONE"
chk "Lost-Leiche vorher gefunden" "1" "$NEK_FUNERAL_FOUND"

# --- Neks Familie -------------------------------------------------
NEK_DONE=1
NEK_FAMILY_GIVEN=0
chk "Familienquest zunächst verborgen" "verborgen" "$(quest_status_nek_familie)"
chk "Familienziel leer" "0" "$(quest_goal_nek_familie | grep -c 'Molerat')"
NEK_FAMILY_GIVEN=1
chk "Familienquest aktuell" "aktuell" "$(quest_status_nek_familie)"
chk "Familienziel nennt Nek" "1" \
    "$(quest_goal_nek_familie | grep -c 'Nek Molerat')"
chk "Familieneintrag nennt den Nachnamen" "1" \
    "$(quest_entries_nek_familie | grep -c 'Nachname')"
chk "Familieneintrag nennt Fleischerei" "1" \
    "$(quest_entries_nek_familie | grep -c 'Fleischerei')"
chk "Familieneintrag nennt Metzgerei" "1" \
    "$(quest_entries_nek_familie | grep -c 'Metzgerei')"

# ==================================================================
section "Neks Beerdigung: Save-Felder & Migration"
# ==================================================================
# Die neuen Flags müssen im Spielstand auftauchen (Serialize in save.sh).
NEK_FUNERAL_GIVEN=1
NEK_FUNERAL_DISPOSITION=lost
NEK_FUNERAL_DAY=7
NEK_FUNERAL_DISCOVERY_DAY=2
NEK_FUNERAL_FOUND=1
NEK_FUNERAL_DONE=0
NEK_FUNERAL_FAILED=0
NEK_FAMILY_GIVEN=1
MIG_SAVE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/th-funeral.XXXXXX")"
TH_SAVES_DIR="$MIG_SAVE_DIR"
th_save manual; chk_rc "Spielstand mit Beerdigung speichern" "$?" "0"
chk "Save enthält NEK_FUNERAL_GIVEN" "1" \
    "$(grep -c '^NEK_FUNERAL_GIVEN=1' "$MIG_SAVE_DIR/manual1.save" 2>/dev/null)"
chk "Save enthält NEK_FUNERAL_DISPOSITION" "1" \
    "$(grep -c '^NEK_FUNERAL_DISPOSITION=lost' "$MIG_SAVE_DIR/manual1.save" 2>/dev/null)"
chk "Save enthält NEK_FUNERAL_DAY" "1" \
    "$(grep -c '^NEK_FUNERAL_DAY=7' "$MIG_SAVE_DIR/manual1.save" 2>/dev/null)"
chk "Save enthält NEK_FUNERAL_DISCOVERY_DAY" "1" \
    "$(grep -c '^NEK_FUNERAL_DISCOVERY_DAY=2' "$MIG_SAVE_DIR/manual1.save" 2>/dev/null)"
chk "Save enthält NEK_FUNERAL_FOUND" "1" \
    "$(grep -c '^NEK_FUNERAL_FOUND=1' "$MIG_SAVE_DIR/manual1.save" 2>/dev/null)"
chk "Save enthält NEK_FAMILY_GIVEN" "1" \
    "$(grep -c '^NEK_FAMILY_GIVEN=1' "$MIG_SAVE_DIR/manual1.save" 2>/dev/null)"
rm -rf "$MIG_SAVE_DIR"
unset TH_SAVES_DIR

# Alte Stände ohne Funeral-Flags bekommen saubere Defaults; ein alter
# Nek-Abschluss startet keine rückwirkende Beerdigung.
unset NEK_FUNERAL_GIVEN NEK_FUNERAL_DISPOSITION NEK_FUNERAL_DAY \
      NEK_FUNERAL_DISCOVERY_DAY NEK_FUNERAL_FOUND NEK_FUNERAL_DONE \
      NEK_FUNERAL_FAILED NEK_FAMILY_GIVEN
th_save_migrate
chk "Migration ergänzt NEK_FUNERAL_GIVEN" "0" "$NEK_FUNERAL_GIVEN"
chk "Migration ergänzt NEK_FUNERAL_DAY" "-1" "$NEK_FUNERAL_DAY"
chk "Migration ergänzt NEK_FUNERAL_DISCOVERY_DAY" "-1" "$NEK_FUNERAL_DISCOVERY_DAY"
chk "Migration ergänzt NEK_FUNERAL_FOUND" "0" "$NEK_FUNERAL_FOUND"
chk "Migration ergänzt NEK_FUNERAL_DONE" "0" "$NEK_FUNERAL_DONE"
chk "Migration ergänzt NEK_FUNERAL_FAILED" "0" "$NEK_FUNERAL_FAILED"
chk "Migration ergänzt NEK_FAMILY_GIVEN" "0" "$NEK_FAMILY_GIVEN"

# Alter Friedhof auf dem Schreibtisch -> Brachland/Friedhof. Das betrifft
# nicht nur den Aufenthaltsort, sondern auch die dort abgelegte Leiche.
CWD="$HOME_DIR/Schreibtisch/Friedhof"
OLDPWD="$CWD"
VIEW_DIR="$CWD"
NEKS_LEICHE_PATH="$CWD/NeksLeiche"
DRAGGED_CORPSE="$NEKS_LEICHE_PATH"
declare -gA TH_DYN_TYPE=(["$NEKS_LEICHE_PATH"]="f")
th_save_migrate
chk "Migration verschiebt CWD in den Brachland-Friedhof" \
    "$HOME_DIR/Schreibtisch/Brachland/Friedhof" "$CWD"
chk "Migration verschiebt OLDPWD in den Brachland-Friedhof" \
    "$HOME_DIR/Schreibtisch/Brachland/Friedhof" "$OLDPWD"
chk "Migration verschiebt VIEW_DIR in den Brachland-Friedhof" \
    "$HOME_DIR/Schreibtisch/Brachland/Friedhof" "$VIEW_DIR"
chk "Migration verschiebt die Leiche in den Brachland-Friedhof" \
    "$HOME_DIR/Schreibtisch/Brachland/Friedhof/NeksLeiche" "$NEKS_LEICHE_PATH"
chk "Migration verschiebt die gezogene Leiche mit" \
    "$HOME_DIR/Schreibtisch/Brachland/Friedhof/NeksLeiche" "$DRAGGED_CORPSE"
chk "Migration verschiebt den dynamischen Leichen-Eintrag" "f" \
    "${TH_DYN_TYPE[$HOME_DIR/Schreibtisch/Brachland/Friedhof/NeksLeiche]:-}"
chk "Migration lässt den alten dynamischen Eintrag nicht zurück" "0" \
    "$(printf '%s\n' "${!TH_DYN_TYPE[@]}" | grep -cx "$HOME_DIR/Schreibtisch/Friedhof/NeksLeiche")"
unset TH_DYN_TYPE

# Canyon: früher direkt im Brachland, jetzt unter der Steppe. Alte Stände
# werden samt dynamischer Einträge mitgezogen.
CWD="$HOME_DIR/Schreibtisch/Brachland/Canyon"
OLDPWD="$CWD"
VIEW_DIR="$CWD"
declare -gA TH_DYN_TYPE=(["$CWD/Spur"]="f")
th_save_migrate
chk "Migration verschiebt CWD in die Steppe" \
    "$HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon" "$CWD"
chk "Migration verschiebt OLDPWD in die Steppe" \
    "$HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon" "$OLDPWD"
chk "Migration verschiebt VIEW_DIR in die Steppe" \
    "$HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon" "$VIEW_DIR"
chk "Migration verschiebt den Canyon-Eintrag" "f" \
    "${TH_DYN_TYPE[$HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Spur]:-}"
chk "Migration lässt den alten Canyon-Eintrag nicht zurück" "0" \
    "$(printf '%s\n' "${!TH_DYN_TYPE[@]}" | grep -cx "$HOME_DIR/Schreibtisch/Brachland/Canyon/Spur")"
unset TH_DYN_TYPE
CWD="$HOME_DIR/Schreibtisch"
VIEW_DIR="$CWD"
OLDPWD="$HOME_DIR"
NEKS_LEICHE_PATH=""
DRAGGED_CORPSE=""
