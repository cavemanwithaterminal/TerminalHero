# ============================================================
#  Unit-Test-Teil: Neks Leiche, search, Ziehen, Loot & Schmuck
#  Wird von Kern/tests/unit.sh in fester Reihenfolge geladen.
# ============================================================
# ==================================================================
section "Neks Leiche: Ort, Inhalt, search & grep"
# ==================================================================
# Saubere Höhlen-Welt (vorherige Abschnitte haben TYPE/CHILDREN verändert).
TYPE=(); CHILDREN=(); CONTENT=(); DIALOG=(); FS_BASE_TYPE=()
SEARCH_TARGET_FN=()
fs_build_tree
build_children
load_contents
inv_reset
equip_reset
NEKS_LEICHE_PATH=""
NEKS_LEICHE_SEARCHED=0
DRAGGED_CORPSE=""
NEK_FOUND=0
NEK_REPORTED=0
NEK_MUST_SEARCH=0
NEK_CORPSE_BROUGHT=0
NEK_SIMON_SEARCHED=0
NEK_AMULET_SOLD=0
NEK_AMULET_KEPT=0
NEK_DONE=0
NEK_GIVEN=1
CWD="$HOME_DIR/Schreibtisch/Höhleneingang/Molerathöhle"
VIEW_DIR="$CWD"
LEARNED=(pwd ls cd cat touch grep use search)

. "$SCRIPT_DIR/Items/Schmuck/NeksAmulett.sh"
. "$SCRIPT_DIR/Charakter/NeksLeiche.sh"
. "$SCRIPT_DIR/InGameBefehle/search.sh"
. "$SCRIPT_DIR/InGameBefehle/Inventar.sh"

neks_leiche_apply_state
CAVE="$HOME_DIR/Schreibtisch/Höhleneingang/Molerathöhle/NeksLeiche"
chk "Neks Leiche liegt in der Molerathöhle" "f" "${TYPE[$CAVE]:-}"
chk "Neks Leiche steht in der Kinderliste" "1" \
    "$(printf '%s\n' "${CHILDREN[$HOME_DIR/Schreibtisch/Höhleneingang/Molerathöhle]:-}" | grep -cx NeksLeiche)"
chk "Neks Leiche hat einen Dialog" "dialog_neks_leiche" "${DIALOG[$CAVE]:-}"
chk "Neks Leiche ist durchsuchbar" "neks_leiche_search" "$(search_fn_of "$CAVE")"
chk "cat-Text nennt Nek Molerat" "1" \
    "$(printf '%s' "${CONTENT[$CAVE]:-}" | grep -c 'Nek Molerat')"
chk "cat-Text nennt das Amulett" "1" \
    "$(printf '%s' "${CONTENT[$CAVE]:-}" | grep -c 'Amulett')"
chk "Neks Pfad ist gemerkt" "$CAVE" "$NEKS_LEICHE_PATH"

# --- Item-Metadaten: Schmuck statt Quest, verkäuflich --------------
chk "Amulett ist Kategorie Schmuck" "schmuck" "$(item_cat neksamulett)"
chk "Schmuck-Reiter ist vorhanden" "1" \
    "$(printf '%s\n' "${ITEM_CATS[@]}" | grep -cx 'schmuck')"
chk "Schmuck-Reiter heißt Schmuck" "Schmuck" "$(item_cat_label schmuck)"
chk "Amulett-Wert ist 300 Bits" "300" "$(item_value neksamulett)"
chk "Amulett ist einmalig" "1" "$(item_is_unique neksamulett && echo 1 || echo 0)"
chk "Amulett ist verkäuflich" "1" "$(item_is_sellable neksamulett && echo 1 || echo 0)"
chk "Amulett passt in den Amulett-Slot" "1" \
    "$(equip_item_allowed neksamulett amulett && echo 1 || echo 0)"
chk "Amulett gibt +50 Max-Tokens" "50" "$(equip_item_tokens_max neksamulett)"
chk "Amulett gibt −1 Schaden" "1" "$(equip_item_damage_reduction neksamulett)"
_d="$(item_desc neksamulett)"
chk "Amulett-Beschreibung rendert echte Zeilenumbrüche" "1" \
    "$([ "$(printf '%s' "$_d" | wc -l)" -ge 2 ] && echo 1 || echo 0)"
chk "Amulett-Beschreibung ohne literales \\n" "0" \
    "$(printf '%s' "$_d" | grep -Fc '\n')"
chk "Amulett-Beschreibung nennt +50 Max-Tokens" "1" \
    "$(printf '%s' "$_d" | grep -Fc '+50 maximale Tokens')"
chk "Amulett-Beschreibung nennt −1 Schaden" "1" \
    "$(printf '%s' "$_d" | grep -Fc '−1 eingehender Schaden')"

# --- search: gesperrt, dann Loot ------------------------------------
LEARNED=(pwd ls cd cat touch grep use)
BITS=0; BITS_EARNED=0
OUT=()
builtin_search NeksLeiche
chk "search ohne Erlernen wird abgewiesen" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c 'Diesen Befehl kenne ich nicht')"
chk "ohne search kein Loot" "0" "$(inv_count neksamulett)"
chk "ohne search keine Bits" "0" "$BITS"

LEARNED+=(search)
OUT=()
builtin_search NeksLeiche
chk "search durchsucht die Leiche" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c 'Du durchsuchst Neks Leiche')"
chk "search findet Neks Amulett" "1" "$(inv_count neksamulett)"
chk "Loot-Meldung nennt das Amulett" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c 'Neks Amulett')"
chk "search gibt 30 Bits" "30" "$BITS"
chk "Bits-Meldung nennt +30" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c '\[ Bits \]  +30')"
chk "Suche ist vermerkt" "1" "$NEKS_LEICHE_SEARCHED"
chk "Fund ist im Questlog vermerkt" "1" "$NEK_FOUND"
chk "Questlog nennt den Fund" "1" \
    "$(quest_entries_nek | grep -c 'Hab Nek gefunden. Lag tot in einer Höhle')"
chk "Questziel nennt Simon" "1" \
    "$(quest_goal_nek | grep -c 'Simon Guard')"
chk "Queststatus ist aktuell" "aktuell" "$(quest_status_nek)"
OUT=()
builtin_search NeksLeiche
chk "zweite Suche legt kein zweites Amulett an" "1" "$(inv_count neksamulett)"
chk "zweite Suche gibt keine weiteren Bits" "30" "$BITS"
chk "zweite Suche meldet leere Taschen" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c 'Taschen sind leer')"

# --- Token/EXP: Leiche kostet doppelt -------------------------------
chk "grep auf Leiche kostet 20 Tokens" "20" "$(token_cost_of grep NeksLeiche)"
chk "grep auf Leiche gibt 4 EXP" "4" "$(token_exp_of grep NeksLeiche)"
chk "grep auf Fundort bleibt bei 10 Tokens" "10" "$(token_cost_of grep EinfacheFackel)"
chk "grep auf Fundort bleibt bei 2 EXP" "2" "$(token_exp_of grep EinfacheFackel)"
chk "grep-Textsuche auf der Leiche kostet normal" "10" \
    "$(token_cost_of grep 'NeksLeiche README')"

# --- Schmuck anlegen/ablegen/ersetzen ------------------------------
TOKENS_MAX=1000; TOKENS_CUR=1000
chk "vor dem Anlegen kein Bonus" "0" "$(equip_tokens_bonus_total)"
chk "Amulett ist nicht getragen" "0" "$(equip_item_worn neksamulett && echo 1 || echo 0)"
equip_wear neksamulett
chk "Anlegen füllt den Amulett-Slot" "neksamulett" "$(equip_get amulett)"
chk "Anlegen erhöht Max-Tokens um 50" "1050" "$TOKENS_MAX"
chk "Amulett gilt als getragen" "1" "$(equip_item_worn neksamulett && echo 1 || echo 0)"
chk "Token-Bonus wird summiert" "50" "$(equip_tokens_bonus_total)"
chk "Schadensreduktion wird summiert" "1" "$(equip_damage_reduction_total)"
chk "Bonuszeile nennt Tokens" "1" \
    "$(equip_bonus_summary | grep -c 'max. Tokens')"
equip_wear neksamulett
chk "doppeltes Anlegen stapelt nicht" "1050" "$TOKENS_MAX"

inventar_action_opts neksamulett
chk "Aktionsfenster hat vier Optionen" "4" "${#INV_ACTION_OPTS[@]}"
chk "Option 1 ist benutzen" "benutzen" "${INV_ACTION_OPTS[0]}"
chk "Option 2 ist abrüsten (getragen)" "abrüsten" "${INV_ACTION_OPTS[1]}"
chk "Option 3 ist ablegen" "ablegen" "${INV_ACTION_OPTS[2]}"
chk "Option 4 ist nichts tun" "nichts tun" "${INV_ACTION_OPTS[3]}"
chk "Aktionsschlüssel passen zu den Optionen" "4" "${#INV_ACTION_KEYS[@]}"
equip_unwear neksamulett
chk "Ablegen leert den Amulett-Slot" "" "${EQUIP_SLOT_ITEM[amulett]:-}"
chk "Ablegen senkt Max-Tokens wieder" "1000" "$TOKENS_MAX"
inventar_action_opts neksamulett
chk "Option 2 ist ausrüsten" "ausrüsten" "${INV_ACTION_OPTS[1]}"
chk "Option 4 ist nichts tun" "nichts tun" "${INV_ACTION_OPTS[3]}"

# Ein zweites Amulett ersetzt das erste im belegten Slot.
item_define testamulett schmuck "Test-Amulett" "Nur für den Unit-Test." 1
equip_define_item testamulett amulett
equip_wear neksamulett
equip_wear testamulett
chk "Ersatz füllt den Amulett-Slot" "testamulett" "$(equip_get amulett)"
chk "ersetztes Amulett ist nicht mehr getragen" "0" \
    "$(equip_item_worn neksamulett && echo 1 || echo 0)"
chk "Ersatz ohne Token-Effekt senkt den Bonus" "0" "$(equip_tokens_bonus_total)"
chk "Max-Tokens nach Ersatz wieder 1000" "1000" "$TOKENS_MAX"
equip_unwear testamulett
# Verkauf/Ablegen aus dem Inventar nimmt das getragene Amulett automatisch ab.
equip_wear neksamulett
chk "Amulett vor dem Verkauf getragen" "1050" "$TOKENS_MAX"
inv_remove neksamulett 1
chk "Entfernen legt das Amulett automatisch ab" "0" \
    "$(equip_item_worn neksamulett && echo 1 || echo 0)"
chk "Entfernen senkt Max-Tokens" "1000" "$TOKENS_MAX"
inv_add neksamulett

# --- grep: ziehen, folgen, ablegen ----------------------------------
OUT=()
neks_leiche_grep "$CAVE"
chk "grep zieht die Leiche" "$CAVE" "$DRAGGED_CORPSE"
chk "Ziehen meldet die Leiche" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c 'Du ziehst jetzt eine Leiche hinter dir her')"

CWD="$HOME_DIR/Downloads"; VIEW_DIR="$CWD"
neks_leiche_follow_cwd
DL="$HOME_DIR/Downloads/NeksLeiche"
chk "Leiche folgt in den neuen Ordner" "f" "${TYPE[$DL]:-}"
chk "alter Höhlen-Eintrag ist weg" "" "${TYPE[$CAVE]:-}"
chk "Leiche fehlt nicht mehr im Höhlen-Ordner" "0" \
    "$(printf '%s\n' "${CHILDREN[$HOME_DIR/Schreibtisch/Höhleneingang/Molerathöhle]:-}" | grep -cx NeksLeiche)"
chk "Leiche steht im neuen Ordner" "1" \
    "$(printf '%s\n' "${CHILDREN[$HOME_DIR/Downloads]:-}" | grep -cx NeksLeiche)"
chk "Zieh-Pfad ist aktualisiert" "$DL" "$DRAGGED_CORPSE"
chk "Dialog ist am neuen Ort registriert" "dialog_neks_leiche" "${DIALOG[$DL]:-}"
chk "Suche ist am neuen Ort registriert" "neks_leiche_search" "$(search_fn_of "$DL")"
chk "alter Such-Haken ist entfernt" "" "$(search_fn_of "$CAVE")"
chk "Leiche im aktuellen Ordner erkennbar" "1" \
    "$(neks_leiche_here && echo 1 || echo 0)"

OUT=()
neks_leiche_grep "$DL"
chk "zweites grep legt die Leiche ab" "" "$DRAGGED_CORPSE"
chk "Ablegen meldet die Leiche" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c 'Du hast eine Leiche abgelegt')"
chk "nach dem Ablegen liegt sie im aktuellen Ordner" "f" "${TYPE[$DL]:-}"

# --- Speichern & Migration ------------------------------------------
MIG_SAVE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/th-nek.XXXXXX")"
TH_SAVES_DIR="$MIG_SAVE_DIR"
th_save manual; chk_rc "Spielstand mit Neks Leiche speichern" "$?" 0
chk "Save enthält NEKS_LEICHE_PATH" "1" \
    "$(grep -c '^NEKS_LEICHE_PATH=' "$MIG_SAVE_DIR/manual1.save" 2>/dev/null)"
chk "Save enthält DRAGGED_CORPSE" "1" \
    "$(grep -c '^DRAGGED_CORPSE=' "$MIG_SAVE_DIR/manual1.save" 2>/dev/null)"
chk "Save enthält NEKS_LEICHE_SEARCHED" "1" \
    "$(grep -c '^NEKS_LEICHE_SEARCHED=1' "$MIG_SAVE_DIR/manual1.save" 2>/dev/null)"
chk "Save enthält NEK_FOUND" "1" \
    "$(grep -c '^NEK_FOUND=1' "$MIG_SAVE_DIR/manual1.save" 2>/dev/null)"
chk "Save enthält NEK_DONE" "1" \
    "$(grep -c '^NEK_DONE=' "$MIG_SAVE_DIR/manual1.save" 2>/dev/null)"
chk "Save enthält den dynamischen Leichenpfad" "1" \
    "$([ "$(grep -c 'NeksLeiche' "$MIG_SAVE_DIR/manual1.save" 2>/dev/null)" -ge 1 ] && echo 1 || echo 0)"
rm -rf "$MIG_SAVE_DIR"
unset TH_SAVES_DIR

# Alte Stände: Amulett im Inventar -> Suche gilt als erledigt.
unset NEKS_LEICHE_SEARCHED
NEKS_LEICHE_SEARCHED=0
NEK_FOUND=0
th_save_migrate
chk "Migration erkennt das Amulett" "1" "$NEKS_LEICHE_SEARCHED"
chk "Migration ergänzt NEK_FOUND" "1" "$NEK_FOUND"
chk "Migration ergänzt NEKS_LEICHE_PATH" "1" \
    "$([ -n "${NEKS_LEICHE_PATH:-}" ] && echo 1 || echo 0)"
chk "Migration ergänzt DRAGGED_CORPSE" "1" \
    "$([ -n "${DRAGGED_CORPSE+x}" ] && echo 1 || echo 0)"

# --- Übergabe an Simon: Leiche endgültig entfernen -------------------
NEK_CORPSE_BROUGHT=1
NEKS_LEICHE_PATH="$DL"
DRAGGED_CORPSE="$DL"
neks_leiche_remove
chk "Übergabe entfernt den FS-Eintrag" "" "${TYPE[$DL]:-}"
chk "Übergabe entfernt den Inhalt" "" "${CONTENT[$DL]:-}"
chk "Übergabe entfernt den Dialog" "" "${DIALOG[$DL]:-}"
chk "Übergabe entfernt den Such-Haken" "" "$(search_fn_of "$DL")"
chk "Übergabe leert NEKS_LEICHE_PATH" "" "$NEKS_LEICHE_PATH"
chk "Übergabe beendet das Ziehen" "" "$DRAGGED_CORPSE"
neks_leiche_apply_state
chk "Laden legt keine Leiche neu an" "1" \
    "$(neks_leiche_path_of >/dev/null 2>&1 && echo 0 || echo 1)"

# Aufräumen für spätere Abschnitte.
NEKS_LEICHE_PATH=""
NEKS_LEICHE_SEARCHED=0
DRAGGED_CORPSE=""
NEK_FOUND=0
NEK_REPORTED=0
NEK_MUST_SEARCH=0
NEK_CORPSE_BROUGHT=0
NEK_SIMON_SEARCHED=0
NEK_AMULET_SOLD=0
NEK_AMULET_KEPT=0
NEK_DONE=0
equip_reset
inv_reset
