# ============================================================
#  Unit-Test-Teil: Tracey/Jimmy, Pfade & Sperrzonen, Loader
#  Wird von Kern/tests/unit.sh in fester Reihenfolge geladen.
# ============================================================
# ==================================================================
section "Tracey Briggs & Jimmys Zeitungsbote"
# ==================================================================
. "$SCRIPT_DIR/Charakter/TraceyBriggs.sh"
. "$SCRIPT_DIR/Charakter/JimmyPage.sh"
chk "JimmysHaus ist ein Ordner" "d" "${TYPE[$BASE/Ostdistrikt/JimmysHaus]:-}"
chk "JimmyPage ist eine Datei" "f" "${TYPE[$BASE/Ostdistrikt/JimmysHaus/JimmyPage]:-}"
chk "JimmyPage-Dialog ist registriert" "dialog_jimmy" \
    "${DIALOG[$BASE/Ostdistrikt/JimmysHaus/JimmyPage]:-}"
chk "Zeitungspreis bei Tracey wie am Kasten" "10" "$(tracey_price)"
chk "Tracey kennt die aktuelle Edition" "bezirke" "$(tracey_current_edition)"
chk "Jimmy kennt die aktuelle Edition" "bezirke" "$(jimmy_current_edition)"
chk "Jimmy-EXP: 50 Bits" "250" "$(jimmy_sperrzone_exp 50)"
chk "Jimmy-EXP: 75 Bits" "100" "$(jimmy_sperrzone_exp 75)"
chk "Jimmy-EXP: 100 Bits" "0" "$(jimmy_sperrzone_exp 100)"
chk "Jimmy-EXP: unbekannter Preis" "0" "$(jimmy_sperrzone_exp 60)"

TRACEY_GIVEN=0; TRACEY_FOUND=0; TRACEY_DONE=0
JIMMY_GIVEN=0; JIMMY_INTRO_DONE=0; JIMMY_TRACEY_DONE=0
tracey_apply_state
chk "Tracey steht zunächst im Ostdistrikt" "f" \
    "${TYPE[$BASE/Ostdistrikt/TraceyBriggs]:-}"
chk "Tracey-Dialog ist im Ostdistrikt registriert" "dialog_tracey" \
    "${DIALOG[$BASE/Ostdistrikt/TraceyBriggs]:-}"
chk "Tracey ist noch nicht im Verlag" "" \
    "${TYPE[$BASE/Süddistrikt/DailyPulse/TraceyBriggs]:-}"
chk "Tracey-Quest anfangs verborgen" "verborgen" "$(quest_status_tracey)"
TRACEY_GIVEN=1
chk "Tracey-Quest nach Rachels Auftrag aktuell" "aktuell" "$(quest_status_tracey)"
chk "Tracey-Ziel nennt Jimmys Haus" "1" \
    "$(quest_goal_tracey | grep -c 'Jimmys Haus')"
TRACEY_FOUND=1
tracey_apply_state
chk "Tracey verschwindet aus dem Ostdistrikt" "" \
    "${TYPE[$BASE/Ostdistrikt/TraceyBriggs]:-}"
chk "Tracey steht jetzt im DailyPulse" "f" \
    "${TYPE[$BASE/Süddistrikt/DailyPulse/TraceyBriggs]:-}"
chk "Tracey-Ziel führt zurück zu Rachel" "1" \
    "$(quest_goal_tracey | grep -c 'Rachel')"
chk "Vermisste Bewohner: Tracey gefunden" "1" \
    "$(VERMISSTE_GIVEN=1 quest_entries_vermisste | grep -c 'Hab Tracey gefunden')"
TRACEY_DONE=1
chk "Tracey-Quest abgeschlossen" "abgeschlossen" "$(quest_status_tracey)"
chk "Tracey-Quest steht bei den Nebenquests" "tracey" \
    "$(printf '%s\n' "${QL_NEBEN[@]}" | grep -x tracey)"
chk "Tracey-Quest-Titel" "Finde Tracey" "${QL_TITLE[tracey]}"

# Nach Rachels Dank (TRACEY_DONE) beginnt Traceys Stadttour: alle
# 4 Spielstunden ein anderer Ort, sechs Orte im 24-Stunden-Rhythmus.
# Reihenfolge: Süddistrikt -> Zentrum -> Ostdistrikt -> Norddistrikt ->
# Westdistrikt -> Haupteingang.
WORLD_SECS=0                 # Spielzeit 06:00, Tourstart -> Süddistrikt
tracey_apply_state
chk "Tourstart wird gespeichert" "0" "${TRACEY_TOUR_START}"
chk "Nach der Quest ist Tracey aus dem Verlag verschwunden" "" \
    "${TYPE[$BASE/Süddistrikt/DailyPulse/TraceyBriggs]:-}"
chk "Tourstart: Tracey ist im Süddistrikt" "f" \
    "${TYPE[$BASE/Süddistrikt/TraceyBriggs]:-}"
chk "Traceys Status nennt die Stadttour" "1" \
    "$(printf '%s' "${CONTENT[$BASE/Süddistrikt/TraceyBriggs]:-}" | grep -c 'auf Stadttour')"
chk "Tracey-Datei nennt den 4-Stunden-Rhythmus" "1" \
    "$(printf '%s' "${CONTENT[$BASE/Süddistrikt/TraceyBriggs]:-}" | grep -c 'alle 4 Spielstunden')"

WORLD_SECS=600               # Spielzeit 10:00 = 240 Spielminuten -> Zentrum
tracey_schedule_apply
chk "Nach 4 Spielstunden zieht Tracey ins Zentrum" "f" \
    "${TYPE[$BASE/Zentrum/TraceyBriggs]:-}"
chk "Der Süddistrikt ist geräumt" "" \
    "${TYPE[$BASE/Süddistrikt/TraceyBriggs]:-}"

# Rachels Sperrzone-Bündel ändern an der Tour nichts mehr.
AUFLAGE_GIVEN=1
tracey_schedule_apply
chk "Mit Rachels Bündeln bleibt Tracey auf Tour" "f" \
    "${TYPE[$BASE/Zentrum/TraceyBriggs]:-}"
chk "Tracey bleibt aus dem Verlag verschwunden" "" \
    "${TYPE[$BASE/Süddistrikt/DailyPulse/TraceyBriggs]:-}"

# Aufräumen für die folgenden Abschnitte.
AUFLAGE_GIVEN=0; TRACEY_DONE=0; TRACEY_TOUR_START=-1; WORLD_SECS=0
tracey_apply_state
chk "Ohne Tour steht Tracey wieder im Verlag" "f" \
    "${TYPE[$BASE/Süddistrikt/DailyPulse/TraceyBriggs]:-}"
chk "Jimmy-Quest anfangs verborgen" "verborgen" "$(quest_status_jimmy)"
JIMMY_GIVEN=1
chk "Jimmy-Quest nach dem Gespräch aktuell" "aktuell" "$(quest_status_jimmy)"
chk "Jimmy-Quest steht bei den Nebenquests" "jimmy" \
    "$(printf '%s\n' "${QL_NEBEN[@]}" | grep -x jimmy)"
chk "Jimmy-Quest-Titel" "Jimmys Zeitungsbote" "${QL_TITLE[jimmy]}"
chk "Jimmy-Ziel nennt 50 Bits" "1" \
    "$(quest_goal_jimmy | grep -c '50 Bits')"

# --- Wachhaus, Simon Guard & Simple Jon ----------------------------
# Der Pausenraum im Haupteingang: statischer Ordner/Datei, Ortsmodul,
# Bett/Stuhl und die neue Nebenquest um Nek Molerat.
section "Wachhaus, Simon Guard & Nek Molerat"
. "$SCRIPT_DIR/Charakter/SimonGuard.sh"
. "$SCRIPT_DIR/Charakter/SimpleJon.sh"
. "$SCRIPT_DIR/Orte/Wachhaus.sh"
wachhaus_build
chk "Wachhaus gehört zum statischen Grundgerüst" "d" \
    "${FS_BASE_TYPE[$BASE/Wachhaus]:-}"
chk "SimpleJon gehört zum statischen Grundgerüst" "f" \
    "${FS_BASE_TYPE[$BASE/Wachhaus/SimpleJon]:-}"
chk "Simple-Jon-Dialog ist registriert" "dialog_simple_jon" \
    "${DIALOG[$BASE/Wachhaus/SimpleJon]:-}"
chk "Simple-Jon-Datei nennt die Stadtwache" "1" \
    "$(printf '%s' "${CONTENT[$BASE/Wachhaus/SimpleJon]:-}" | grep -c 'STADTWACHE')"
chk "Wachhaus-Bett registriert" "1" \
    "$(printf '%s\n' "${INTERIOR_PLACES[@]}" | grep -cx "bett|$BASE/Wachhaus/Bett")"
chk "Wachhaus-Stuhl registriert" "1" \
    "$(printf '%s\n' "${INTERIOR_PLACES[@]}" | grep -cx "stuhl|$BASE/Wachhaus/Stuhl")"
chk "Simon-Guard-Dialog ist definiert" "1" \
    "$(declare -F dialog_simon_guard >/dev/null 2>&1 && echo 1 || echo 0)"
chk "alter Torwächter-Name bleibt nutzbar" "1" \
    "$(declare -F dialog_torwaechter >/dev/null 2>&1 && echo 1 || echo 0)"

SIMON_NEK_INFO=0; NEK_GIVEN=0; JON_NEK_INFO=0; VERMISSTE_GIVEN=0
chk "Nek-Quest anfangs verborgen" "verborgen" "$(quest_status_nek)"
chk "Nek-Quest-Titel" "Wo ist Nek Molerat?" "${QL_TITLE[nek]}"
chk "Nek-Quest steht bei den Nebenquests" "nek" \
    "$(printf '%s\n' "${QL_NEBEN[@]}" | grep -x nek)"
NEK_GIVEN=1
chk "Nek-Quest nach Simons Auftrag aktuell" "aktuell" "$(quest_status_nek)"
chk "Nek-Ziel führt zu Simple Jon" "1" \
    "$(quest_goal_nek | grep -c 'Simple Jon im Wachhaus')"
chk "Nek-Verlauf nennt Simons Freund" "1" \
    "$(SIMON_NEK_INFO=1 quest_entries_nek | grep -c 'Nek Molerat ist seit Tagen verschwunden')"
chk "Hauptquest nennt den verschwundenen Nek" "1" \
    "$(SIMON_NEK_INFO=1 quest_entries_vermisste | grep -c 'Nek Molerat ist verschwunden')"
chk "Hauptquest bleibt ohne Jons Detailwissen" "0" \
    "$(SIMON_NEK_INFO=1 quest_entries_vermisste | grep -c 'Simple Jon')"
JON_NEK_INFO=1
chk "Nek-Ziel nach Jons Hinweis" "1" \
    "$(quest_goal_nek | grep -c 'Stadt verlassen')"
chk "Nek-Verlauf nennt Jons Wissen" "1" \
    "$(quest_entries_nek | grep -c 'Simple Jon: Nek ist Stadtwache')"
chk "Jons Hinweis bleibt aus der Hauptquest" "0" \
    "$(quest_entries_vermisste | grep -c 'Simple Jon')"
chk "Nek-Quest bleibt aktuell" "aktuell" "$(quest_status_nek)"

# Aufräumen: keine Spuren in späteren Testabschnitten.
SIMON_NEK_INFO=0; NEK_GIVEN=0; JON_NEK_INFO=0
VERMISSTE_GIVEN=0
TRACEY_GIVEN=0; TRACEY_FOUND=0; TRACEY_DONE=0
JIMMY_GIVEN=0; JIMMY_INTRO_DONE=0; JIMMY_TRACEY_DONE=0
JIMMY_LAST_SOLD=""
tracey_apply_state

# ==================================================================
section "Pfade & Sperrzonen"
# ==================================================================
CWD="$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang"
chk "normalize: leer -> Basis"        "$CWD" "$(normalize_path '' "$CWD")"
chk "normalize: '.' -> Basis"         "$CWD" "$(normalize_path '.' "$CWD")"
chk "normalize: '..' -> Elternordner" "$HOME_DIR/Schreibtisch/DesktopCity" "$(normalize_path '..' "$CWD")"
chk "normalize: a/./b"                "$CWD/a/b" "$(normalize_path 'a/./b' "$CWD")"
chk "normalize: a/../b"               "$CWD/b" "$(normalize_path 'a/../b' "$CWD")"
chk "normalize: absolut bleibt"       "/etc/passwd" "$(normalize_path '/etc/./passwd' "$CWD")"
chk "resolve: '~' -> HOME_DIR"        "$HOME_DIR" "$(resolve_path '~' "$CWD")"
chk "resolve: '~/Downloads'"          "$HOME_DIR/Downloads" "$(resolve_path '~/Downloads' "$CWD")"
chk "resolve: relativ ab CWD"         "$CWD/x" "$(resolve_path 'x' "$CWD")"

outside_home "$HOME_DIR";            chk_rc "HOME_DIR ist NICHT draußen" "$?" 1
outside_home "$HOME_DIR/Downloads";  chk_rc "unter HOME ist NICHT draußen" "$?" 1
outside_home "/etc";                 chk_rc "/etc ist draußen" "$?" 0
outside_home "/home/benutzer2";      chk_rc "ähnlicher Name ist draußen" "$?" 0
chk "short_path: HOME -> ~"          "~" "$(short_path "$HOME_DIR")"
chk "short_path: unter HOME -> ~/x"  "~/Downloads" "$(short_path "$HOME_DIR/Downloads")"
chk "short_path: außerhalb bleibt"   "/etc" "$(short_path /etc)"

OUT=()
zone_denied "cat" "Zugriff verweigert." "/etc/passwd"
chk_rc "zone_denied greift außerhalb" "$?" 0
chk "Sperrzonen-Meldung im Fenster" "1" "$(printf '%s\n' "${OUT[@]}" | grep -c 'Zugriff verweigert')"
OUT=()
zone_denied "cat" "x" "$HOME_DIR/Downloads"; chk_rc "innerhalb kein Verbot" "$?" 1

# --- Tutorial-Ausgang und Pixi-Sperre ------------------------------
# Nach dem General führt aus dem Agenten-Ordner nur »cd ..« in den
# Downloads-Ordner. Ein direkter Sprung in einen Geschwisterordner darf
# den ersten Downloads-Besuch (achievements/Kompass) nicht umgehen.
README_DONE=1; TUT_DONE=1; HOME_FIRST_VISIT=0
fs_build_tree
CWD="$AGENT_DIR"; OLDPWD="$HOME_DIR"; VIEW_DIR="$CWD"
th_load_cmd cd
OUT=()
builtin_cd "../DetektivConan"
chk "Tutorial: direkter Geschwisterordner bleibt gesperrt" "$AGENT_DIR" "$CWD"
chk "Tutorial: Hinweis auf den einzigen Ausgang" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c 'nur »cd ..«')"

OUT=()
builtin_cd ".."
chk "Tutorial: »cd ..« führt in den Downloads-Ordner" "$HOME_DIR/Downloads" "$CWD"

# Solange Pixi nicht getroffen wurde, darf der Downloads-Bereich nur
# Richtung ~ verlassen werden - nicht direkt in einen anderen Hausordner.
OUT=()
builtin_cd "~/Schreibtisch"
chk "Pixi: direkter Sprung nach ~/Schreibtisch bleibt gesperrt" \
    "$HOME_DIR/Downloads" "$CWD"
chk "Pixi: Hinweis auf die erste Begegnung" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c 'Pixi treffen')"

# Unterordner von Downloads bleiben ganz normal betretbar.
OUT=()
builtin_cd "DetektivConan"
chk "Downloads: Unterordner ist normal betretbar" \
    "$HOME_DIR/Downloads/DetektivConan" "$CWD"
builtin_cd ".."
chk "Downloads: Rückweg in den Downloads-Ordner" "$HOME_DIR/Downloads" "$CWD"
builtin_cd ".."
chk "Downloads: »cd ..« erreicht ~ und damit Pixi" "$HOME_DIR" "$CWD"

# ==================================================================
section "Loader"
# ==================================================================
chk "Alias hilfe -> help"        "help"      "$(th_canon_cmd hilfe)"
chk "Alias charakter -> character" "character" "$(th_canon_cmd Charakter)"
chk "Alias quests -> questlog"   "questlog"  "$(th_canon_cmd quests)"
chk "Alias inv -> inventar"      "inventar"  "$(th_canon_cmd inv)"
chk "Alias inventory -> inventar" "inventar" "$(th_canon_cmd inventory)"
chk "Alias speichern -> save"    "save"      "$(th_canon_cmd speichern)"
chk "Alias stats wurde entfernt" "stats"     "$(th_canon_cmd stats)"
chk "Alias cd.. -> cd"           "cd"        "$(th_canon_cmd 'cd..')"
chk "Alias cd. -> cd"            "cd"        "$(th_canon_cmd 'cd.')"
chk "Alias QUIT -> exit"         "exit"      "$(th_canon_cmd QUIT)"
chk "unbekannt bleibt (klein)"   "fizzbuzz"  "$(th_canon_cmd FizzBuzz)"

TH_DIR="$SCRIPT_DIR"
chk "Loader kennt den NutzbareItems-Ordner" "$SCRIPT_DIR/NutzbareItems" \
    "$(th_dir_nutzitems)"
chk "Schlafsack-Datei liegt in NutzbareItems" "1" \
    "$([ -f "$SCRIPT_DIR/NutzbareItems/EinfacherSchlafsack.sh" ] && echo 1 || echo 0)"
chk "Fackel-Datei liegt in NutzbareItems" "1" \
    "$([ -f "$SCRIPT_DIR/NutzbareItems/EinfacheFackel.sh" ] && echo 1 || echo 0)"
chk "Zeitungsordner liegt in NutzbareItems" "1" \
    "$([ -d "$SCRIPT_DIR/NutzbareItems/Zeitungen" ] && echo 1 || echo 0)"
chk "Bezirke-Ausgabe liegt bei den Zeitungen" "1" \
    "$([ -f "$SCRIPT_DIR/NutzbareItems/Zeitungen/BezirkeDerStadt.sh" ] && echo 1 || echo 0)"
chk "Sperrzone-Ausgabe liegt bei den Zeitungen" "1" \
    "$([ -f "$SCRIPT_DIR/NutzbareItems/Zeitungen/Sperrzone.sh" ] && echo 1 || echo 0)"
th_build_fn_index
chk "Funktionsindex: char_gain_exp" "InGameBefehle/character.sh" "${TH_FN_FILE[char_gain_exp]:-}"
chk "Funktionsindex: lesen_screen" "InGameBefehle/Lesen.sh" "${TH_FN_FILE[lesen_screen]:-}"
chk "Funktionsindex: dialog_boerty" "Charakter/BörtySmiles.sh"   "${TH_FN_FILE[dialog_boerty]:-}"
chk "Funktionsindex: district_build_sued" "Orte/Süddistrikt.sh"  "${TH_FN_FILE[district_build_sued]:-}"
th_source_if_fn char_gain_exp; chk_rc "th_source_if_fn lädt nach" "$?" 0
th_source_if_fn gibtsnicht;    chk_rc "th_source_if_fn: unbekannt -> Fehler" "$?" 1

