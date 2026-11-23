# ============================================================
#  Unit-Test-Teil: Gegner, Guy Sus & Kampfbefehl rm
#  Wird von Kern/tests/unit.sh in fester Reihenfolge geladen.
# ============================================================
# ==================================================================
section "Gegner: Molerats, Guy Sus & rm"
# ==================================================================
# Die Gegner-Engine, die Molerat-Datei, Guy Sus und der Kampfbefehl
# werden hier ohne TUI geladen. »say« wird für die Lernkosten-Stichprobe
# durch eine einfache Ausgabe ersetzt.
. "$SCRIPT_DIR/kern/gegner.sh"
. "$SCRIPT_DIR/Gegner/Molerats.sh"
. "$SCRIPT_DIR/Charakter/GuySus.sh"
. "$SCRIPT_DIR/Items/Waffen/Trainingsklinge.sh"
. "$SCRIPT_DIR/GegnerLoot/MoleratCode.sh"
. "$SCRIPT_DIR/Items/Plunder/KopfMoleratKoenigin.sh"
. "$SCRIPT_DIR/Gegner/MoleratKoenigin.sh"
. "$SCRIPT_DIR/TerminalBefehle/rm.sh"

say() { OUT+=("$1: $2"); }
dialog_pause() { :; }
# In der Unit-Prüfung soll rm nicht die lange Höhlen-Szene starten.
guy_sus_maybe_cave_clear() { :; }

CAVE="$HOME_DIR/Schreibtisch/Höhleneingang/Molerathöhle"
ENTRY="$HOME_DIR/Schreibtisch/Höhleneingang"
CWD="$CAVE"
fs_build_tree
build_children
load_contents
MOLERATS_DEAD=0
GUY_SUS_MET=0
GUY_SUS_GONE=0
GUY_SUS_CAVE_DONE=0
GUY_SUS_OUTSIDE_DONE=0
GEGNER_LAST_CWD=""
GEGNER_ACTIVE_CWD=""
TOKENS_CUR=1000
TOKENS_MAX=1000
inv_reset
equip_reset

molerats_apply_state
guy_sus_apply_state

chk "drei Molerats im Höhlen-Ordner" "3" "$(gegner_count_current)"
chk "Molerat-Namen" "Molerat1, Molerat2, Molerat3" "$(gegner_current_names)"
chk "Molerat1 ist eine Datei" "f" "${TYPE[$CAVE/Molerat1]:-}"
chk "Molerat2 ist eine Datei" "f" "${TYPE[$CAVE/Molerat2]:-}"
chk "Molerat3 ist eine Datei" "f" "${TYPE[$CAVE/Molerat3]:-}"
chk "Molerat-Kategorie" "virus" "$(gegner_category_of "$CAVE/Molerat1")"
chk "Molerat-Angriff" "30" "$(gegner_current_dps)"
chk "Molerat-Wartezeit" "3" "$(gegner_current_wait)"
chk "Molerat-Code ist Plunder" "plunder" "$(item_cat moleratcode)"
chk "Molerat-Code kostet 4 Bits" "4" "$(handel_buy_price moleratcode)"
chk "Molerat-Code bringt 2 Bits" "2" "$(handel_sell_price moleratcode)"
chk "GuySus-Datei liegt im Höhleneingang" "f" "${TYPE[$ENTRY/GuySus]:-}"
chk "GuySus hat einen Dialog" "dialog_guy_sus" "${DIALOG[$ENTRY/GuySus]:-}"
chk "GuySus-Datei nennt die Molerats" "1" \
    "$(grep -c 'Molerats' <<< "${CONTENT[$ENTRY/GuySus]:-}")"

# --- Betreten & Angriff ---------------------------------------------
OUT=()
TH_GEGNER_NOW=100
gegner_maybe_enter
chk "Betreten zeigt Oink, Oink" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c '^Oink, Oink$')"
chk "Angriff beginnt nach 3 Sekunden" "103" "$GEGNER_AGGRO_AT"

TOKENS_CUR=1000
TH_GEGNER_NOW=105
OUT=()
gegner_tick
chk "zwei Sekunden Angriff = 60 Tokens" "940" "$TOKENS_CUR"
chk "Angriff wird gemeldet" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c 'Molerat1, Molerat2, Molerat3: -60 Tokens')"

# --- Rüstung: mindestens 1 Schaden, Schild blockt 5 % ---------------
# Ein Testpanzer mit sehr hoher Reduktion: Der Gegner trifft trotzdem
# immer mit mindestens 1 Token pro Sekunde.
. "$SCRIPT_DIR/Items/Rüstung/EinfachesSchild.sh"
equip_define_item testpanzer kopf
equip_effect_damage_reduction testpanzer 100
equip_wear testpanzer
chk "Testpanzer reduziert mehr als der Molerat-Schaden" "100" \
    "$(equip_damage_reduction_total)"
TOKENS_CUR=1000
GEGNER_AGGRO_AT=200
GEGNER_LAST_ATTACK_AT=200
TH_GEGNER_NOW=201
OUT=()
gegner_tick
chk "Mindestschaden: trotz Rüstung 1 Token" "999" "$TOKENS_CUR"
chk "Mindestschaden wird gemeldet" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c 'Molerat1, Molerat2, Molerat3: -1 Tokens')"
equip_unwear testpanzer
equip_reset

# Das echte Schild: 1 Schadensreduktion und 5 % Blockchance.
chk "Schild senkt den Schaden um 1" "1" \
    "$(equip_item_damage_reduction einfachesschild)"
chk "Schild hat 5 % Blockchance" "5" \
    "$(equip_item_block_chance einfachesschild)"
equip_wear einfachesschild
TOKENS_CUR=1000
GEGNER_AGGRO_AT=300
GEGNER_LAST_ATTACK_AT=300
TH_GEGNER_NOW=301
TH_BLOCK_ROLL=0
OUT=()
gegner_tick
chk "Block verhindert den gesamten Schaden" "1000" "$TOKENS_CUR"
chk "Block wird gemeldet" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c 'Angriff geblockt')"

TOKENS_CUR=1000
GEGNER_AGGRO_AT=400
GEGNER_LAST_ATTACK_AT=400
TH_GEGNER_NOW=401
TH_BLOCK_ROLL=99
OUT=()
gegner_tick
chk "Ohne Block: 30 - 1 = 29 Schaden" "971" "$TOKENS_CUR"
unset TH_BLOCK_ROLL
equip_unwear einfachesschild
equip_reset
TOKENS_CUR=1000
TOKENS_MAX=1000

# Außerhalb des Ordners greift nichts an.
CWD="$ENTRY"
TOKENS_CUR=940
TH_GEGNER_NOW=120
gegner_tick
chk "außerhalb der Höhle kein Schaden" "940" "$TOKENS_CUR"
chk "Angriff ist beendet" "" "$GEGNER_ACTIVE_CWD"
# Die Hauptschleife meldet den neuen Ordner auch ohne Gegner an.
gegner_maybe_enter

# Zurück in die Höhle: neuer Angriff, neue Wartezeit.
CWD="$CAVE"
TH_GEGNER_NOW=200
OUT=()
gegner_maybe_enter
chk "erneutes Betreten kündigt erneut an" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c '^Oink, Oink$')"
chk "neuer Angriff beginnt nach 3 Sekunden" "203" "$GEGNER_AGGRO_AT"

# --- 0 Tokens: Ohnmacht außerhalb, Tod im Kampf ----------------------
CWD="$CAVE"
GEGNER_ACTIVE_CWD="$CAVE"
chk_rc "im Kampf: aktive Begegnung erkannt" "$(leben_in_combat; echo $?)" 0
CWD="$ENTRY"
chk_rc "außerhalb: keine Kampfbegegnung" "$(leben_in_combat; echo $?)" 1
CWD="$CAVE"

# Gegnerschaden auf 0 -> Tod, kein automatisches Flüchten.
_death_out="$(
    CWD="$CAVE"
    GEGNER_ACTIVE_CWD="$CAVE"
    GEGNER_AGGRO_AT=300
    GEGNER_LAST_ATTACK_AT=300
    TOKENS_CUR=10
    TOKENS_MAX=1000
    TH_GEGNER_NOW=301
    TH_LEBEN_NO_SCREEN=1
    TH_DEATH_SECS=0
    gegner_tick
)"; _death_rc=$?
chk "Gegnerschaden auf 0 beendet das Spiel" "0" "$_death_rc"
chk "Tod durch Gegnerschaden meldet »Du bist tot«" "1" \
    "$(printf '%s\n' "$_death_out" | grep -c '^Du bist tot$')"
chk "kein automatisches Flüchten mehr" "1" \
    "$(declare -F gegner_flee >/dev/null 2>&1 && echo 0 || echo 1)"

# 0 Tokens im Kampf durch einen Befehl -> ebenfalls Tod.
_cmd_death_out="$(
    CWD="$CAVE"
    GEGNER_ACTIVE_CWD="$CAVE"
    TOKENS_CUR=0
    TOKENS_MAX=1000
    TH_LEBEN_NO_SCREEN=1
    TH_DEATH_SECS=0
    leben_token_zero
)"; _cmd_death_rc=$?
chk "0 Tokens im Kampf durch Befehl -> Tod" "0" "$_cmd_death_rc"
chk "Befehls-Tod meldet »Du bist tot«" "1" \
    "$(printf '%s\n' "$_cmd_death_out" | grep -c '^Du bist tot$')"

# Ohne Kampf -> Ohnmacht, 6 Ingame-Stunden, 15 % Tokens.
CWD="$ENTRY"
GEGNER_ACTIVE_CWD=""
TOKENS_MAX=1000
TOKENS_CUR=0
WORLD_STARTED=1
WORLD_SECS=0
WORLD_LAST=0
OUT=()
TH_LEBEN_NO_SCREEN=1
TH_FAINT_SECS=0
leben_token_zero >/dev/null 2>&1; _faint_rc=$?
chk "0 Tokens ohne Kampf -> Ohnmacht" "0" "$_faint_rc"
chk "Ohnmacht gibt 15 % Max-Tokens" "150" "$TOKENS_CUR"
chk "Ohnmacht: sechs Ingame-Stunden" "900" "$WORLD_SECS"
chk "Ohnmacht wird gemeldet" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c 'Sechs Stunden später')"
unset TH_LEBEN_NO_SCREEN TH_FAINT_SECS
CWD="$CAVE"
TOKENS_CUR=1000
TOKENS_MAX=1000
WORLD_STARTED=0
WORLD_SECS=0
OUT=()

# --- Tokenkosten ----------------------------------------------------
LEARNED=()
chk "rm ohne Erlernen kostet 0" "0" "$(token_cost_of rm "Molerat1")"
chk "rm ohne Erlernen gibt 0 EXP" "0" "$(token_exp_of rm "Molerat1")"
LEARNED=(rm)
chk "rm mit einem Molerat kostet 100" "100" "$(token_cost_of rm "Molerat1")"
chk "rm mit zwei Molerats kostet 150" "150" "$(token_cost_of rm "Molerat1 Molerat2")"
chk "rm mit drei Molerats kostet 200" "200" "$(token_cost_of rm "Molerat1 Molerat2 Molerat3")"
chk "doppeltes Ziel kostet nur einmal" "100" "$(token_cost_of rm "Molerat1 Molerat1")"
chk "unbekanntes Ziel kostet nur Grundkosten" "50" "$(token_cost_of rm "Molerat9")"
chk "rm mit einem Molerat gibt 20 EXP" "20" "$(token_exp_of rm "Molerat1")"
chk "rm mit drei Molerats gibt 40 EXP" "40" "$(token_exp_of rm "Molerat1 Molerat2 Molerat3")"
chk "doppeltes Ziel gibt nur einmal Gegner-EXP" "20" "$(token_exp_of rm "Molerat1 Molerat1")"
chk "unbekanntes Ziel gibt nur Grund-EXP" "10" "$(token_exp_of rm "Molerat9")"

# --- Waffe & Zielkategorien -----------------------------------------
inv_add trainingsklinge
equip_wear trainingsklinge; chk_rc "Trainingsklinge anlegen" "$?" 0
equip_combat_ready; chk_rc "Waffe ist ausgerüstet" "$?" 0
equip_combat_can_destroy virus; chk_rc "Waffe darf Viren löschen" "$?" 0
equip_combat_can_destroy datei; chk_rc "Waffe darf keine freundlichen Dateien löschen" "$?" 1
chk "Trainingsklinge im linken Slot" "trainingsklinge" "${EQUIP_SLOT_ITEM[linke_hand]:-}"

# --- rm tötet alle drei, Loot & Todesbits ---------------------------
MOLERATS_DEAD=0
molerats_apply_state
CWD="$CAVE"
LEARNED=(rm)
TOKENS_CUR=1000
OUT=()
builtin_rm "Molerat1 Molerat2 Molerat3"
chk "nach rm sind keine Molerats mehr da" "0" "$(gegner_count_current)"
chk "rm zeigt die EXP für die Molerats" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c '^\[ EXP \]  +40 EXP für die besiegten Molerats erhalten\.$')"
chk "Todesmaske ist 7" "7" "$MOLERATS_DEAD"
chk "alle drei sind tot" "1" "$(molerats_all_dead && echo 1 || echo 0)"
chk "sechs MoleratCodes im Inventar (2 je Molerat)" "6" "$(inv_count moleratcode)"
chk "Molerat1-Datei ist entfernt" "0" "$([ -n "${TYPE[$CAVE/Molerat1]:-}" ] && echo 1 || echo 0)"
chk "Molerat2-Datei ist entfernt" "0" "$([ -n "${TYPE[$CAVE/Molerat2]:-}" ] && echo 1 || echo 0)"
chk "Molerat3-Datei ist entfernt" "0" "$([ -n "${TYPE[$CAVE/Molerat3]:-}" ] && echo 1 || echo 0)"

# Getötete Molerats werden beim Neuaufbau nicht wiederbelebt.
molerats_apply_state
chk "nach Neuaufbau bleibt die Höhle leer" "0" "$(gegner_count_current)"

# --- Moleratgebiete im Brachland/Steppe -----------------------------
# Jedes Gebiet hat ein eigenes Maximum und einen eigenen Respawn-Timer.
GEBIET="$HOME_DIR/Schreibtisch/Brachland/Steppe/Moleratgebiet"
G11="$GEBIET/Moleratgebiet1.1"
G12="$G11/Moleratgebiet1.2"
G21="$GEBIET/Moleratgebiet2.1"
G22="$G21/Moleratgebiet2.2"
G31="$GEBIET/Moleratgebiet3.1"
G32="$G31/Moleratgebiet3.2"
MOLERATS_DEAD=7
MOLERAT_AREA_DEAD=()
MOLERAT_AREA_NEXT=()
WORLD_STARTED=0
WORLD_SECS=0
molerats_apply_state

CWD="$GEBIET"
chk "Moleratgebiet hat zwei Molerats" "2" "$(gegner_count_current)"
chk "Moleratgebiet-Namen" "Molerat1, Molerat2" "$(gegner_current_names)"
chk "Moleratgebiet-Angriff" "20" "$(gegner_current_dps)"
for _d in "$G11" "$G12" "$G21" "$G22" "$G31" "$G32"; do
    CWD="$_d"
    chk "Moleratgebiet${_d##*/Moleratgebiet} hat drei Molerats" "3" "$(gegner_count_current)"
done

# Zwei Kills im Basislager: eigener Zähler, Höhlenmaske bleibt unberührt.
CWD="$GEBIET"
gegner_kill "$GEBIET/Molerat1"
chk "Basisgebiet zählt einen Toten" "1" "${MOLERAT_AREA_DEAD[Moleratgebiet]:-}"
chk "Höhlen-Todesmaske bleibt unberührt" "7" "$MOLERATS_DEAD"
chk "Basisgebiet hat noch einen Molerat" "1" "$(gegner_count_current)"
chk "Basisgebiet-Respawn in 24h" "1440" "${MOLERAT_AREA_NEXT[Moleratgebiet]:-}"
gegner_kill "$GEBIET/Molerat2"
chk "Basisgebiet zählt zwei Tote" "2" "${MOLERAT_AREA_DEAD[Moleratgebiet]:-}"
chk "Basisgebiet ist leer" "0" "$(gegner_count_current)"
chk "Basisgebiet-Timer bleibt beim ersten Toten" "1440" "${MOLERAT_AREA_NEXT[Moleratgebiet]:-}"

# Nach 23:59 Ingame-Stunden passiert noch nichts, nach 24:00 kommt genau
# ein Molerat zurück; der nächste folgt erst wieder 24 Stunden später.
WORLD_STARTED=1
WORLD_SECS=3598            # 1439 Spielminuten
molerats_respawn_tick; _mr=$?
chk_rc "vor Ablauf kein Nachspawn" "$_mr" 1
chk "vor Ablauf bleibt das Gebiet leer" "0" "$(gegner_count_current)"
WORLD_SECS=3600            # 1440 Spielminuten
molerats_respawn_tick; _mr=$?
chk_rc "nach 24h kommt ein Molerat" "$_mr" 0
chk "nach 24h lebt wieder einer" "1" "$(gegner_count_current)"
chk "ein Toter bleibt" "1" "${MOLERAT_AREA_DEAD[Moleratgebiet]:-}"
chk "nächster Spawn in weiteren 24h" "2880" "${MOLERAT_AREA_NEXT[Moleratgebiet]:-}"
WORLD_SECS=7199            # 2879 Spielminuten
molerats_respawn_tick; _mr=$?
chk_rc "vor dem zweiten Ablauf kein Nachspawn" "$_mr" 1
chk "weiterhin nur ein Molerat" "1" "$(gegner_count_current)"
WORLD_SECS=7200            # 2880 Spielminuten
molerats_respawn_tick; _mr=$?
chk_rc "nach weiteren 24h kommt der zweite" "$_mr" 0
chk "Basisgebiet ist wieder voll" "2" "$(gegner_count_current)"
chk "kein Toter mehr im Basisgebiet" "0" "${MOLERAT_AREA_DEAD[Moleratgebiet]:-}"
chk "Respawn-Timer ist aus" "0" "${MOLERAT_AREA_NEXT[Moleratgebiet]:-}"

# Große Zeitverschiebung (z. B. mehrere Tage Schlaf): Der absolute Takt
# bleibt erhalten, überfällige Spawns werden in den Folgeschleifen nachgeholt.
CWD="$GEBIET"
MOLERAT_AREA_DEAD[Moleratgebiet]=2
MOLERAT_AREA_NEXT[Moleratgebiet]=1440
molerats_place_area Moleratgebiet 0
WORLD_SECS=10800           # 4320 Spielminuten (drei Tage)
molerats_respawn_tick; _mr=$?
chk_rc "überfälliger Spawn 1 kommt" "$_mr" 0
chk "nach dem ersten Nachholen bleibt ein Toter" "1" "${MOLERAT_AREA_DEAD[Moleratgebiet]:-}"
chk "der absolute Takt läuft weiter" "2880" "${MOLERAT_AREA_NEXT[Moleratgebiet]:-}"
molerats_respawn_tick; _mr=$?
chk_rc "überfälliger Spawn 2 kommt" "$_mr" 0
chk "Basisgebiet ist nach dem Aufholen voll" "2" "$(gegner_count_current)"
chk "kein überfälliger Timer mehr" "0" "${MOLERAT_AREA_NEXT[Moleratgebiet]:-}"
MOLERAT_AREA_DEAD[Moleratgebiet]=0
MOLERAT_AREA_NEXT[Moleratgebiet]=0
WORLD_SECS=7200            # zurück auf 2880 Spielminuten für die Folgetests
molerats_apply_state

# Die Untergebiete zählen unabhängig: Ein Kill in 1.1 lässt 2.1 und 1.2 voll.
CWD="$G11"
gegner_kill "$G11/Molerat2"
chk "1.1 zählt einen Toten" "1" "${MOLERAT_AREA_DEAD[Moleratgebiet1.1]:-}"
chk "1.1 hat noch zwei Molerats" "2" "$(gegner_count_current)"
CWD="$G21"
chk "2.1 bleibt bei drei Molerats" "3" "$(gegner_count_current)"
CWD="$G12"
chk "1.2 bleibt bei drei Molerats" "3" "$(gegner_count_current)"
chk "Basisgebiet bleibt ohne Tote" "0" "${MOLERAT_AREA_DEAD[Moleratgebiet]:-0}"
CWD="$G11"
chk "1.1-Respawn in 24h" "4320" "${MOLERAT_AREA_NEXT[Moleratgebiet1.1]:-}"

# Neuaufbau aus dem gespeicherten Zustand: nur lebende Tiere entstehen.
molerats_apply_state
chk "1.1 hat nach Neuaufbau zwei Molerats" "2" "$(gegner_count_current)"
chk "2.1 hat nach Neuaufbau drei Molerats" "3" \
    "$(CWD="$G21"; gegner_count_current)"
chk "Basisgebiet hat nach Neuaufbau zwei Molerats" "2" \
    "$(CWD="$GEBIET"; gegner_count_current)"

# --- Höhlentunnel im Canyon -----------------------------------------
# Drei verschachtelte Tunnel, in jedem genau ein Molerat. Ein Kill
# startet den 24-Stunden-Timer; danach kommt höchstens ein Tier nach.
T1="$HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1"
T2="$T1/Höhlentunnel2"
T3="$T2/Höhlentunnel3"
for _t in "$T1" "$T2" "$T3"; do
    CWD="$_t"
    chk "${_t##*/} hat genau einen Molerat" "1" "$(gegner_count_current)"
    chk "${_t##*/} nennt ihn Molerat1" "Molerat1" "$(gegner_current_names)"
done
chk "Tunnel-Gebiet 2 verweist auf Höhlentunnel2" "$T2" \
    "$(molerats_area_path Hoehlentunnel2)"
chk "Tunnel-Gebiet 3 verweist auf Höhlentunnel3" "$T3" \
    "$(molerats_area_path Hoehlentunnel3)"
chk "Tunnel-Maximum ist 1" "1" "$(molerats_area_max Hoehlentunnel1)"

CWD="$T1"
gegner_kill "$T1/Molerat1"
chk "Höhlentunnel1 zählt einen Toten" "1" "${MOLERAT_AREA_DEAD[Hoehlentunnel1]:-}"
chk "Höhlentunnel1 ist leer" "0" "$(gegner_count_current)"
chk "Höhlentunnel1-Respawn in 24h" "4320" "${MOLERAT_AREA_NEXT[Hoehlentunnel1]:-}"
chk "Höhlentunnel2 bleibt unberührt" "0" "${MOLERAT_AREA_DEAD[Hoehlentunnel2]:-0}"

WORLD_STARTED=1
WORLD_SECS=10800           # 4320 Spielminuten: Timer ist fällig
molerats_respawn_tick; _mr=$?
chk_rc "Tunnel-Respawn kommt nach 24h" "$_mr" 0
chk "Höhlentunnel1 ist wieder besetzt" "1" "$(gegner_count_current)"
chk "Höhlentunnel1 hat keinen Toten mehr" "0" "${MOLERAT_AREA_DEAD[Hoehlentunnel1]:-}"
chk "Höhlentunnel1-Timer ist aus" "0" "${MOLERAT_AREA_NEXT[Hoehlentunnel1]:-}"

# Aufräumen: alle Gebiete wieder auffüllen, Höhle bleibt für Guy leer.
MOLERAT_AREA_DEAD=()
MOLERAT_AREA_NEXT=()
WORLD_STARTED=0
WORLD_SECS=0
molerats_apply_state
chk "Basisgebiet nach Reset voll" "2" "$(CWD="$GEBIET"; gegner_count_current)"

# --- Guy Sus lehrt search -------------------------------------------
LEARNED=()
SKILL_POINTS=2
BITS=25
OUT=()
guy_sus_teach_search
chk_rc "genug Punkte & Bits: Lernen klappt" "$?" 0
chk "search ist gelernt" "1" "$(knows search && echo 1 || echo 0)"
chk "2 Skillpunkte bezahlt" "0" "$SKILL_POINTS"
chk "25 Bits bezahlt" "0" "$BITS"
chk "Lernmeldung im Fenster" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c 'Neuer Befehl erlernt: search')"

LEARNED=()
SKILL_POINTS=1
BITS=25
OUT=()
guy_sus_teach_search
chk_rc "zu wenig Skillpunkte: Lernen scheitert" "$?" 1
chk "keine Punkte abgebucht" "1" "$SKILL_POINTS"
chk "keine Bits abgebucht" "25" "$BITS"
chk "search bleibt gesperrt" "1" "$(knows search && echo 0 || echo 1)"
chk "Guy nennt den Preis" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c '2 Skillpunkte und 25 Bits')"

# --- Guy verschwindet ------------------------------------------------
GUY_SUS_GONE=1
guy_sus_apply_state
chk "verschwundener Guy hat keine Datei" "0" "$([ -n "${TYPE[$ENTRY/GuySus]:-}" ] && echo 1 || echo 0)"
chk "verschwundener Guy hat keinen Dialog" "0" "$([ -n "${DIALOG[$ENTRY/GuySus]:-}" ] && echo 1 || echo 0)"

# --- Save-Felder & Migration ----------------------------------------
MIG_SAVE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/th-gegner.XXXXXX")"
TH_SAVES_DIR="$MIG_SAVE_DIR"
MOLERATS_DEAD=7
MOLERAT_AREA_DEAD=([Moleratgebiet]=1)
MOLERAT_AREA_NEXT=([Moleratgebiet]=1440)
GUY_SUS_MET=1
GUY_SUS_GONE=1
GUY_SUS_CAVE_DONE=1
GUY_SUS_OUTSIDE_DONE=0
th_save manual
chk_rc "Spielstand mit Gegner-Flags speichern" "$?" 0
chk "Save enthält MOLERATS_DEAD" "1" \
    "$(grep -c '^MOLERATS_DEAD=7' "$MIG_SAVE_DIR/manual1.save" 2>/dev/null)"
chk "Save enthält den Gebiets-Todeszähler" "1" \
    "$(grep -c '^MOLERAT_AREA_DEAD=.*Moleratgebiet.*=1' "$MIG_SAVE_DIR/manual1.save" 2>/dev/null)"
chk "Save enthält den Gebiets-Respawn-Timer" "1" \
    "$(grep -c '^MOLERAT_AREA_NEXT=.*Moleratgebiet.*=1440' "$MIG_SAVE_DIR/manual1.save" 2>/dev/null)"
chk "Save enthält GUY_SUS_MET" "1" \
    "$(grep -c '^GUY_SUS_MET=1' "$MIG_SAVE_DIR/manual1.save" 2>/dev/null)"
chk "Save enthält GUY_SUS_GONE" "1" \
    "$(grep -c '^GUY_SUS_GONE=1' "$MIG_SAVE_DIR/manual1.save" 2>/dev/null)"
chk "Save enthält GUY_SUS_CAVE_DONE" "1" \
    "$(grep -c '^GUY_SUS_CAVE_DONE=1' "$MIG_SAVE_DIR/manual1.save" 2>/dev/null)"
rm -rf "$MIG_SAVE_DIR"
unset TH_SAVES_DIR

MOLERATS_DEAD=0
GUY_SUS_MET=0
GUY_SUS_GONE=0
GUY_SUS_CAVE_DONE=1
GUY_SUS_OUTSIDE_DONE=0
th_save_migrate
chk "Migration: Höhlen-Szene setzt alle Molerats tot" "7" "$MOLERATS_DEAD"
chk "Migration: Höhlen-Szene setzt Guy als getroffen" "1" "$GUY_SUS_MET"
chk "Migration: Höhlen-Szene setzt Guy als verschwunden" "1" "$GUY_SUS_GONE"

GUY_SUS_MET=0
GUY_SUS_GONE=0
GUY_SUS_CAVE_DONE=0
GUY_SUS_OUTSIDE_DONE=1
th_save_migrate
chk "Migration: Außen-Szene setzt Guy als getroffen" "1" "$GUY_SUS_MET"
chk "Migration: Außen-Szene setzt Guy als verschwunden" "1" "$GUY_SUS_GONE"

# Migration begrenzt alte/fremde Gebietswerte auf Maximum und Timer.
MOLERAT_AREA_DEAD=([Moleratgebiet]=99 [Moleratgebiet1.1]=-2)
MOLERAT_AREA_NEXT=([Moleratgebiet]=-5 [Moleratgebiet1.1]=123)
WORLD_STARTED=1
WORLD_SECS=0
th_save_migrate
chk "Migration begrenzt Todeszähler auf Maximum" "2" "${MOLERAT_AREA_DEAD[Moleratgebiet]:-}"
chk "Migration setzt fehlenden Timer auf 24h" "1440" "${MOLERAT_AREA_NEXT[Moleratgebiet]:-}"
chk "Migration korrigiert negative Todeszähler" "0" "${MOLERAT_AREA_DEAD[Moleratgebiet1.1]:-}"
chk "Migration löscht Timer ohne Tote" "0" "${MOLERAT_AREA_NEXT[Moleratgebiet1.1]:-}"

# --- MoleratKönigin: Werte und zweite Beute -------------------------
section "MoleratKönigin: Kopf als Beute"
molerat_koenigin_define_type
chk "Königin braucht 3 Sekunden" "3" "$(gegner_type_wait moleratkoenigin)"
chk "Königin macht 50 Tokens Schaden" "50" "$(gegner_type_dps moleratkoenigin)"
chk "Königin kostet 500 rm-Tokens" "500" "$(gegner_type_rm_cost moleratkoenigin)"
chk "Königin droppt 20 MoleratCode" "moleratcode" "${GEGNER_TYPE_LOOT[moleratkoenigin]:-}"
chk "Kopf kostet 200 Bits" "200" "$(handel_buy_price kopf_moleratkoenigin)"
chk "Kopf bringt 100 Bits" "100" "$(handel_sell_price kopf_moleratkoenigin)"

_kk="$(molerat_koenigin_path)"
gegner_place moleratkoenigin "$_kk"
inv_reset
MOLERAT_KOENIGIN_DEAD=0
OUT=()
gegner_kill "$_kk"
chk "Königin lässt 20 MoleratCode fallen" "20" "$(inv_count moleratcode)"
chk "Königin lässt ihren Kopf fallen" "1" "$(inv_count kopf_moleratkoenigin)"
chk "Königin ist endgültig tot" "1" "$MOLERAT_KOENIGIN_DEAD"
chk "Loot-Meldung nennt den Kopf" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -Fc 'Kopf einer Molerat Königin')"

# Aufräumen für spätere Abschnitte.
CWD="$HOME_DIR/Downloads/Neugier"
MOLERATS_DEAD=0
MOLERAT_AREA_DEAD=()
MOLERAT_AREA_NEXT=()
WORLD_STARTED=0
WORLD_SECS=0
GUY_SUS_MET=0
GUY_SUS_GONE=0
GUY_SUS_CAVE_DONE=0
GUY_SUS_OUTSIDE_DONE=0
GEGNER_LAST_CWD=""
equip_reset
inv_reset
