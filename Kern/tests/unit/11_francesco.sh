# ============================================================
#  Unit-Test-Teil: Brachland/Friedhof & Francesco Dellamorte
#  Wird von Kern/tests/unit.sh in fester Reihenfolge geladen.
# ============================================================
# ==================================================================
section "Brachland/Friedhof: Francesco Dellamorte"
# ==================================================================
. "$SCRIPT_DIR/Orte/Friedhof.sh"
. "$SCRIPT_DIR/Charakter/FrancescoDellamorte.sh"

CEMETERY="$HOME_DIR/Schreibtisch/Brachland/Friedhof"
FRANCESCO="$CEMETERY/FrancescoDellamorte"

fs_build_tree
build_children
load_contents
friedhof_build

chk "FrancescoDellamorte ist ein statischer Eintrag" "f" \
    "${FS_BASE_TYPE[$FRANCESCO]:-}"
chk "FrancescoDellamorte liegt im Friedhof" "f" \
    "${TYPE[$FRANCESCO]:-}"
chk "Friedhof nennt Francesco im Ordner" "1" \
    "$(printf '%s\n' "${CHILDREN[$CEMETERY]:-}" | grep -cx 'FrancescoDellamorte')"
chk "Francesco hat einen Dialog" "dialog_francesco_dellamorte" \
    "${DIALOG[$FRANCESCO]:-}"
chk "Francesco-Datei nennt seinen Namen" "1" \
    "$(printf '%s' "${CONTENT[$FRANCESCO]:-}" | grep -c 'Francesco Dellamorte')"
chk "Francesco-Datei nennt Italien" "1" \
    "$(printf '%s' "${CONTENT[$FRANCESCO]:-}" | grep -c 'Italien')"
chk "Francesco-Datei nennt den Totengräber" "1" \
    "$(printf '%s' "${CONTENT[$FRANCESCO]:-}" | grep -c 'Totengräber')"
chk "Francesco-Datei verrät das Geheimnis nicht" "0" \
    "$(printf '%s' "${CONTENT[$FRANCESCO]:-}" | grep -Eic 'zombie|untot|wieder auf|aufersteh')"

# --- Erstes Treffen und Standard-Dialog ---------------------------
SAY_LOG=()
ASK_ANSWERS=(2 1)
say() { SAY_LOG+=("$1: $2"); }
render() { :; }
dialog_pause() { :; }
ask() {
    CHOICE="${ASK_ANSWERS[0]:-0}"
    ASK_ANSWERS=("${ASK_ANSWERS[@]:1}")
}

FRANCESCO_MET=0
OUT=()
dialog_francesco_dellamorte
chk "Erstes Treffen setzt FRANCESCO_MET" "1" "$FRANCESCO_MET"
chk "Erstes Treffen stellt ihn vor" "1" \
    "$(printf '%s\n' "${SAY_LOG[@]}" | grep -c 'Francesco Dellamorte. Totengräber.')"
chk "Erstes Treffen nennt seinen Beruf" "1" \
    "$(printf '%s\n' "${SAY_LOG[@]}" | grep -c 'Ich grabe, ich schließe, ich höre zu')"
chk "Erstes Treffen hat schwarzen Humor" "1" \
    "$(printf '%s\n' "${SAY_LOG[@]}" | grep -c 'Meine Kunden beschweren sich nie')"
chk "Erstes Treffen spricht von Ordnung" "1" \
    "$(printf '%s\n' "${SAY_LOG[@]}" | grep -c 'Ordnung ist eine Form von Respekt')"
chk "Erstes Treffen bietet Kaffee an" "1" \
    "$(printf '%s\n' "${SAY_LOG[@]}" | grep -c 'Kaffee? Er ist stark genug')"
chk "Erstes Treffen endet mit den Steinen" "1" \
    "$(printf '%s\n' "${SAY_LOG[@]}" | grep -c 'Grüß die Steine')"
chk "Francesco-Dialog verrät das Geheimnis nicht" "0" \
    "$(printf '%s\n' "${SAY_LOG[@]}" | grep -Eic 'zombie|untot|wieder auf|aufersteh')"

SAY_LOG=()
dialog_francesco_dellamorte
chk "Standard-Dialog läuft nach dem ersten Treffen" "1" \
    "$(printf '%s\n' "${SAY_LOG[@]}" | grep -c 'Zu ruhig, sagen die Leute')"
chk "Standard-Dialog wiederholt das erste Treffen nicht" "0" \
    "$(printf '%s\n' "${SAY_LOG[@]}" | grep -c 'Francesco Dellamorte. Totengräber.')"
chk "Standard-Dialog bleibt kurz" "1" \
    "$(printf '%s\n' "${SAY_LOG[@]}" | grep -c 'Der Kaffee ist noch warm')"

# --- FRANCESCO_MET wird gespeichert ------------------------------
FR_SAVE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/th-francesco.XXXXXX")"
TH_SAVES_DIR="$FR_SAVE_DIR"
FRANCESCO_MET=1
th_save manual; chk_rc "Spielstand mit Francesco-Flag speichern" "$?" 0
chk "Save enthält FRANCESCO_MET" "1" \
    "$(grep -c '^FRANCESCO_MET=1' "$FR_SAVE_DIR/manual1.save" 2>/dev/null)"
rm -rf "$FR_SAVE_DIR"
unset TH_SAVES_DIR
FRANCESCO_MET=0
