# ============================================================
#  TerminalHero - Startbildschirm: Grundlagen
#
#  Block-Schrift, Terminalgröße, Cursor, Tastenlesen und kleine
#  Zeichenhelfer. Wird vom Skelett (TerminalHero.sh) geladen.
# ============================================================

# ---------- Block-Schrift (7 Zeilen) ----------
declare -gA FONT
FONT[T]="█████|  █  |  █  |  █  |  █  |  █  |  █  "
FONT[E]="█████|█    |█    |████ |█    |█    |█████"
FONT[R]="████ |█   █|█   █|████ |█  █ |█   █|█   █"
FONT[M]="█   █|██ ██|█ █ █|█   █|█   █|█   █|█   █"
FONT[I]="█████|  █  |  █  |  █  |  █  |  █  |█████"
FONT[N]="█   █|██  █|██  █|█ █ █|█  ██|█  ██|█   █"
FONT[A]="  █  | █ █ |█   █|█   █|█████|█   █|█   █"
FONT[L]="█    |█    |█    |█    |█    |█    |█████"
FONT[H]="█   █|█   █|█   █|█████|█   █|█   █|█   █"
FONT[O]=" ███ |█   █|█   █|█   █|█   █|█   █| ███ "

FONT_ROWS=7

# ---------- Spieler-Konfiguration (vom Setup gefüllt) ----------
USERNAME=""
HOSTNAME_=""
AGENT=""

# ---------- Terminal-Größe ----------
COLS=80
ROWS=24

update_size() {
    local c r
    c=$(tput cols 2>/dev/null)
    r=$(tput lines 2>/dev/null)
    [ -n "$c" ] && [ "$c" -gt 0 ] && COLS=$c
    [ -n "$r" ] && [ "$r" -gt 0 ] && ROWS=$r
}
hide_cursor() { printf '\033[?25l'; }
show_cursor() { printf '\033[?25h'; }
read_key() {
    local key seq ch
    IFS= read -rsN1 key
    if [[ $key == $'\x1b' ]]; then
        # Escape-Sequenz einsammeln, aber mit kurzem Timeout: So kommt ein
        # allein gedrücktes Esc als genau $'\x1b' an (und blockiert nicht)
        # und blockiert nicht auf zwei weitere Bytes.
        seq=""
        while IFS= read -rsN1 -t 0.03 ch; do
            seq+="$ch"
            case "$ch" in [A-Za-z]|'~') break ;; esac
        done
        key=$'\x1b'$seq
    fi
    LAST_KEY="$key"
}
repeat() {
    local ch="$1" n="$2" out="" i
    for ((i = 0; i < n; i++)); do out+="$ch"; done
    printf '%s' "$out"
}
print_centered() {
    local text="$1" color="${2:-}"
    local col=$(( (COLS - ${#text}) / 2 ))
    [ "$col" -lt 0 ] && col=0
    printf '%s%*s%s%s%s\n' "$UI_BG" "$col" '' "$color" "$text" "$RESET"
}
font_row() {
    local ch="$1" r="$2"
    local IFS='|'
    local rows=(${FONT[$ch]})
    printf '%s' "${rows[r]}"
}

# Startbildschirm-Stil: 0 = original (Backup), 1 = elaborate, 2 = elaborate mit Hintergrund
STARTSCREEN_STYLE=0
STARTSCREEN_STYLES=("Original" "Elaboriert" "Elaboriert mit Hintergrund")

# Startbildschirm-Stil laden
_startcfg="${PROJ_DIR:-.}/saves/.startscreen_style"
if [ -f "$_startcfg" ]; then
    read -r STARTSCREEN_STYLE < "$_startcfg" 2>/dev/null
    case "${STARTSCREEN_STYLE:-0}" in
        0|1|2) : ;;
        *) STARTSCREEN_STYLE=0 ;;
    esac
else
    STARTSCREEN_STYLE=0
fi
unset _startcfg
