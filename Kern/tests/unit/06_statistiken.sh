# ============================================================
#  Unit-Test-Teil: Statistiken
#  Wird von Kern/tests/unit.sh in fester Reihenfolge geladen.
# ============================================================
# ==================================================================
section "Statistiken"
# ==================================================================
# Echte Spielzeit: Format und gespeicherter Grundwert.
chk "Spielzeit 3723 s -> 01 h 02 min 03 s" "01 h 02 min 03 s" "$(playtime_text 3723)"
PLAYTIME_BASE=123; PLAYTIME_START=0
chk "Spielzeit ohne laufende Sitzung" "123" "$(playtime_seconds)"
PLAYTIME_BASE=0

# Questzahlen kommen aus dem Questregister (alle definierten Quests).
TUT_DONE=1; VERLAG_DONE=1; BARACKE_SCENE_DONE=1
DETEKTIV_DONE=0; CONAN_DONE=0; PIXI_LETTER_DONE=0; VERMISSTE_GIVEN=0
BIER_FAILED=1; BIER_DONE=0
MITCH_GIVEN=0; ZEITUNG_GIVEN=0; ZEITUNG_DONE=0
statistics_count_quests haupt
chk "Statistik: Hauptquests erledigt" "2" "$STAT_DONE"
chk "Statistik: Hauptquests gescheitert" "0" "$STAT_FAILED"
chk "Statistik: Hauptquests gesamt" "7" "$STAT_TOTAL"
statistics_count_quests neben
chk "Statistik: Nebenquests erledigt" "1" "$STAT_DONE"
chk "Statistik: Nebenquests gescheitert" "1" "$STAT_FAILED"
chk "Statistik: Nebenquests gesamt" "14" "$STAT_TOTAL"

# Zeitungen zählen Ausgaben, nicht gekaufte Exemplare.
INV_COUNT=(); INV_ORDER=()
chk "Statistik: Zeitungen gesamt" "3" "$(statistics_newspapers_total)"
chk "Statistik: keine Zeitung im Besitz" "0" "$(statistics_newspapers_owned)"
inv_add bezirke 2
chk "Statistik: Zeitung im Besitz" "1" "$(statistics_newspapers_owned)"
inv_add sperrzone
chk "Statistik: beide Ausgaben im Besitz" "2" "$(statistics_newspapers_owned)"
inv_add extraausgabe
chk "Statistik: alle drei Ausgaben im Besitz" "3" "$(statistics_newspapers_owned)"
BIER_FAILED=0; TUT_DONE=0; VERLAG_DONE=0; BARACKE_SCENE_DONE=0
INV_COUNT=(); INV_ORDER=()

