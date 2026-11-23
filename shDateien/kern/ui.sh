# ============================================================
#  TerminalHero - TUI-Grundlagen
#
#  Terminal-Geometrie, Zeichenprimitive (Rahmen, Text, Datei-Icons ...)
#  und der wortweise Zeilenumbruch. Nur Funktionsdefinitionen - die
#  Farben kommen aus theme.sh, die Geometrie wird in geom() gesetzt.
# ============================================================

# ============================================================
#  TUI-Grundlagen
# ============================================================
COLS=80
ROWS=24
PATH_TOP=1
PATH_H=3
MAIN_TOP=4
MAIN_BOT=20
MAIN_H=17
LEFT_X=1
LEFT_W=48
RIGHT_X=50
RIGHT_W=31
HIST_TOP=21
TOKEN_ROW=20
PROMPT_ROW=24
HEADER_ROW=1

FIRST_RENDER=1
PREV_COLS=0
PREV_ROWS=0

# --- Bildschirm-Puffer -------------------------------------------------
# Vollflächige Fenster (Handel, Schlaf, ...) zeichnen viele Zeilen. Jede
# Zeile einzeln zu schreiben kostet spürbar Zeit. Mit ui_begin/ui_flush
# werden alle Ausgaben gesammelt und in EINEM Schreibvorgang abgesetzt.
UI_BUF=""
UI_BATCH=0
ui_begin() { UI_BUF=""; UI_BATCH=1; }
ui_flush() {
    [ -n "$UI_BUF" ] && printf '%s' "$UI_BUF"
    UI_BUF=""
    UI_BATCH=0
}
ui_out() {
    if [ "${UI_BATCH:-0}" = "1" ]; then UI_BUF+="$1"; else printf '%s' "$1"; fi
}

repeat() {
    local ch="$1" n="$2" out="" i
    for ((i = 0; i < n; i++)); do out+="$ch"; done
    printf '%s' "$out"
}

pos() { local _s; printf -v _s '\033[%d;%dH' "$1" "$2"; ui_out "$_s"; }
hide_cursor() { printf '\033[?25l'; }
show_cursor() { printf '\033[?25h'; }

geom() {
    local c r
    c=$(tput cols 2>/dev/null)
    r=$(tput lines 2>/dev/null)
    [ -n "$c" ] && [ "$c" -gt 0 ] && COLS=$c
    [ -n "$r" ] && [ "$r" -gt 0 ] && ROWS=$r
    [ "$ROWS" -lt 16 ] && ROWS=16
    [ "$COLS" -lt 60 ] && COLS=60

    HEADER_ROW=1
    PATH_TOP=2
    PATH_H=3
    MAIN_TOP=$((PATH_TOP + PATH_H))
    HIST_TOP=$((ROWS - 3))
    PROMPT_ROW=$ROWS
    # Token-Leiste liegt zwischen Dialogfenster und Verlauf/Kommandozeile.
    TOKEN_ROW=$((HIST_TOP - 1))
    MAIN_BOT=$((TOKEN_ROW - 1))
    MAIN_H=$((MAIN_BOT - MAIN_TOP + 1))
    [ "$MAIN_H" -lt 5 ] && MAIN_H=5

    LEFT_X=1
    LEFT_W=$(( COLS * 60 / 100 ))
    [ "$LEFT_W" -lt 42 ] && LEFT_W=42
    [ "$LEFT_W" -gt $((COLS - 21)) ] && LEFT_W=$((COLS - 21))
    RIGHT_X=$(( LEFT_W + 2 ))
    RIGHT_W=$(( COLS - LEFT_W - 1 ))
}

# Große, feste Overlay-Fenster (help / questlog / character / inventar).
# Bewusst UNABHÄNGIG vom Inhalt: die Fenstergröße springt nicht, wenn man
# durch Einträge scrollt. Setzt OV_W/OV_H/OV_X/OV_Y/OV_INNER.
overlay_geom() {
    geom
    local w=$(( COLS - 6 )) h=$(( ROWS - 4 ))
    [ "$w" -gt 116 ] && w=116
    [ "$w" -lt 56 ]  && w=56
    [ "$h" -gt 36 ]  && h=36
    [ "$h" -lt 16 ]  && h=16
    OV_W=$w; OV_H=$h
    OV_X=$(( (COLS - w) / 2 + 1 )); [ "$OV_X" -lt 1 ] && OV_X=1
    OV_Y=$(( (ROWS - h) / 2 + 1 )); [ "$OV_Y" -lt 1 ] && OV_Y=1
    OV_INNER=$(( w - 2 ))
}

# Zwei Reiter nebeneinander zeichnen (aktiv hervorgehoben).
#   tab_row <zeile> <x> <aktiv-index> <label...>
tab_row() {
    local row="$1" x="$2" active="$3"; shift 3
    local labels=("$@") i t col
    for i in "${!labels[@]}"; do
        t="[ ${labels[i]} ]"
        if [ "$i" = "$active" ]; then col="$ACCENT$BOLD"; else col="$MUTED"; fi
        put_text "$row" "$x" "${#t}" "$t" "$col"
        x=$(( x + ${#t} + 2 ))
    done
}

# Rahmen zeichnen: draw_box x y w h titel farbe  (Doppellinie + Titel-Notch)
draw_box() {
    local x=$1 y=$2 w=$3 h=$4 title="$5" color="$6"
    local inner=$((w - 2)) top bot r s side
    if [ -n "$title" ]; then
        local t="╡ ${title} ╞"
        local rem=$((inner - ${#t}))
        if [ "$rem" -lt 0 ]; then t="${t:0:inner}"; rem=0; fi
        top="╔${t}$(repeat '═' "$rem")╗"
    else
        top="╔$(repeat '═' "$inner")╗"
    fi
    bot="╚$(repeat '═' "$inner")╝"

    printf -v s '\033[%d;%dH%s%s%s%s' "$y" "$x" "$UI_BG" "$color" "$top" "$RESET"
    ui_out "$s"
    printf -v s '\033[%d;%dH%s%s%s%s' "$((y + h - 1))" "$x" "$UI_BG" "$color" "$bot" "$RESET"
    ui_out "$s"
    printf -v side '%s%s║%s' "$UI_BG" "$color" "$RESET"
    for ((r = 1; r < h - 1; r++)); do
        printf -v s '\033[%d;%dH%s' "$((y + r))" "$x" "$side"
        ui_out "$s"
        printf -v s '\033[%d;%dH%s' "$((y + r))" "$((x + w - 1))" "$side"
        ui_out "$s"
    done
}
# Dekorative Eckzeichen für ein Overlay. Sie liegen eine Zelle innerhalb
# des Rahmens und werden nach dem Inhalt gezeichnet, damit zentrierte
# Titel/Fußzeilen sie nicht mit Leerzeichen überschreiben.
ui_corners() {   # $1=x $2=y $3=w $4=h $5=Farbe oben $6=Farbe unten
    local x="$1" y="$2" w="$3" h="$4" top="${5:-$FRAME_HI}" bot="${6:-$FRAME}"
    put_text "$((y + 1))" "$((x + 1))" 1 "◤" "$top"
    put_text "$((y + 1))" "$((x + w - 2))" 1 "◢" "$top"
    put_text "$((y + h - 2))" "$((x + 1))" 1 "◥" "$bot"
    put_text "$((y + h - 2))" "$((x + w - 2))" 1 "◣" "$bot"
}

# Eine Zeile vollständig auf Hintergrundfarbe leeren
# WICHTIG: Das »H« in '\033[%d;1H' ist Pflicht. Ohne es ist die Sequenz
# kein Cursor-Sprung, und der anschließende Text landet an der aktuellen
# Cursor-Spalte (Prompt wandert nach rechts, Layout zerbricht).
clrline() {
    local s
    printf -v s '\033[%d;1H%s\033[2K' "$1" "$UI_BG"
    ui_out "$s"
}

# Text in eine Region schreiben (restliche Breite mit Leerzeichen füllen)
put_text() {
    local row="$1" col="$2" maxw="$3" text="$4" color="${5:-}"
    local len=${#text} pad s blank=""
    if [ "$len" -gt "$maxw" ]; then text="${text:0:maxw}"; len=$maxw; fi
    pad=$((maxw - len))
    [ "$pad" -gt 0 ] && printf -v blank '%*s' "$pad" ''
    printf -v s '\033[%d;%dH%s%s%s%s%s%s' "$row" "$col" \
        "$UI_BG" "$color" "$text" "$UI_BG" "$blank" "$RESET"
    ui_out "$s"
}

# Text rechtsbündig setzen (schreibt nur die Textzellen, kein Padding)
put_right() {
    local row="$1" x="$2" w="$3" text="$4" color="${5:-}"
    local len=${#text} s
    if [ "$len" -gt "$w" ]; then text="${text:0:w}"; len=$w; fi
    printf -v s '\033[%d;%dH%s%s%s%s' "$row" "$((x + w - len))" \
        "$UI_BG" "$color" "$text" "$RESET"
    ui_out "$s"
}

# Text in einer Breite zentrieren (nur führende Leerzeichen, keine Ausgabe).
center_text() {   # $1 = Text, $2 = Breite
    local t="$1" w="$2" p
    [ "${#t}" -ge "$w" ] && { printf '%s' "${t:0:w}"; return; }
    p=$(( (w - ${#t}) / 2 ))
    printf '%s%s' "$(repeat ' ' "$p")" "$t"
}

# Dateisymbol + Farbe anhand des Namens bestimmen.
# Setzt die Globals FI_ICON und FI_COLOR (keine Subshell -> schnell beim Blättern).
# Icons sind bewusst schmal (Breite 1) gewählt, damit die Spalte ausgerichtet bleibt.
# Ikone/Farbe für Einträge, die keine gewöhnlichen Dateien sind.
# Bits, Fackeln und andere Fundorte, Möbel, Stadtobjekte und beseelte
# Figuren stecken alle als endungslose Dateien im Ordner. Ohne diesen
# Blick in die Weltregister sähen sie alle gleich aus (◆, grau).
file_meta_special() {
    local path="$1" id
    id="${WORLD_ITEM[$path]:-}"
    if [ -n "$id" ]; then
        case "$(item_cat "$id")" in
            spezial) FI_ICON="✦"; FI_COLOR="$GOOD" ;;
            quest)   FI_ICON="◇"; FI_COLOR="$ACCENT" ;;
            *)       FI_ICON="◆"; FI_COLOR="$WARN" ;;
        esac
        return 0
    fi
    id="${INTERIOR_AT[$path]:-}"
    if [ -n "$id" ]; then
        case "$(interior_kind "$id")" in
            möbel) FI_ICON="▥"; FI_COLOR="$MENU_C" ;;
            stadt) FI_ICON="▣"; FI_COLOR="$TITLE" ;;
            *)     FI_ICON="▤"; FI_COLOR="$GENERAL_C" ;;
        esac
        return 0
    fi
    if [ -n "${DIALOG[$path]:-}" ]; then
        FI_ICON="◉"
        # Die beiden früheren Agenten liegen BEIDE als Datei »README« in
        # ihrem jeweiligen Download-Ordner. Nur der Pfad verrät, wer gemeint
        # ist – der Dateiname allein wäre für beide derselbe.
        case "$path" in
            */BarbarConan/README)   FI_COLOR="$RAT_C"; return 0 ;;
            */DetektivConan/README) FI_COLOR="$ERM_C"; return 0 ;;
        esac
        case "${path##*/}" in
            Pixi*)                        FI_COLOR="$PIXI_C" ;;
            Rachel*)                      FI_COLOR="$RACHEL_C" ;;
            JackBones*|Survival*)         FI_COLOR="$MENU_C" ;;
            Jack*)                        FI_COLOR="$JACK_C" ;;
            Amanda*)                      FI_COLOR="$AMANDA_C" ;;
            Börty*|Boerty*)               FI_COLOR="$BOERTY_C" ;;
            Sherlock*)                    FI_COLOR="$SHERLOCK_C" ;;
            Michael*)                     FI_COLOR="$MICHAEL_C" ;;
            Tracey*)                      FI_COLOR="$TRACEY_C" ;;
            Jimmy*)                       FI_COLOR="$JIMMY_C" ;;
            Torwächter*|SimonGuard*)      FI_COLOR="$TORW_C" ;;
            SimpleJon*)                   FI_COLOR="$TORW_C" ;;
            Stadtwache*|Wache*)           FI_COLOR="$TITLE" ;;
            Samy*)                        FI_COLOR="$GENERAL_C" ;;
            README*|General*)             FI_COLOR="$GENERAL_C" ;;
            *)                            FI_COLOR="$ACCENT" ;;
        esac
        return 0
    fi
    return 1
}

file_meta() {
    local name="$1" isdir="$2" path="${3:-}" ext
    if [ "$isdir" = "1" ] || [ "$isdir" = "d" ]; then
        FI_ICON="■"; FI_COLOR="$DIR_C"; return
    fi
    # Weltgegenstand, Einrichtung oder Figur? Nur der Pfad verrät es.
    [ -n "$path" ] && file_meta_special "$path" && return
    case "$name" in
        README*|LICENSE*|CHANGELOG*|*.md|*.markdown) FI_ICON="¶"; FI_COLOR="$FILE_C"; return ;;
        .?*rc|.profile|.bash_*|.zsh_*|.gitignore|.gitconfig) FI_ICON="§"; FI_COLOR="$CFG_C"; return ;;
        *log|messages|dmesg|wtmp|btmp|lastlog) FI_ICON="≣"; FI_COLOR="$LOG_C"; return ;;
    esac
    case "$name" in
        *.*) ext="${name##*.}" ;;
        *)   ext="" ;;
    esac
    case "${ext,,}" in
        "")                 FI_ICON="·"; FI_COLOR="$MUTED" ;;     # ohne Endung (Binär/System)
        txt|text|asc)       FI_ICON="≡"; FI_COLOR="$FILE_C" ;;
        pdf|doc|docx|odt|rtf|tex) FI_ICON="▤"; FI_COLOR="$FILE_C" ;;
        png|jpg|jpeg|gif|bmp|svg|webp|tif|tiff|ico) FI_ICON="▦"; FI_COLOR="$IMG_C" ;;
        mp3|wav|ogg|flac|m4a|aac|opus) FI_ICON="♪"; FI_COLOR="$AUD_C" ;;
        mp4|mkv|avi|mov|webm|wmv|flv) FI_ICON="▷"; FI_COLOR="$VID_C" ;;
        deb|rpm|pkg|tar|gz|bz2|xz|zip|7z|zst) FI_ICON="▣"; FI_COLOR="$WARN" ;;
        conf|cfg|ini|config|toml|yml|yaml|service) FI_ICON="§"; FI_COLOR="$CFG_C" ;;
        log|journal|out)    FI_ICON="≣"; FI_COLOR="$LOG_C" ;;
        c|h|cc|cpp|hpp|sh|bash|zsh|py|js|ts|go|rs|pl|rb|java) FI_ICON="#"; FI_COLOR="$GOOD" ;;
        img|iso|bin|so|o|a|run|AppImage) FI_ICON="▪"; FI_COLOR="$MUTED" ;;
        *)                  FI_ICON="·"; FI_COLOR="$FILE_C" ;;
    esac
}

# Dateizeile: Icon (nach Typ) + Name; Ordner behalten den abschließenden "/"
# <path> ist optional und nötig, um Weltgegenstände, Möbel und Figuren
# auseinanderzuhalten. Ohne Pfad bleibt es beim reinen Dateinamen-Muster.
put_file() {
    local row="$1" col="$2" maxw="$3" name="$4" isdir="$5" path="${6:-}"
    file_meta "$name" "$isdir" "$path"
    local label color="$FI_COLOR" drag=""
    # Eine gezogene Leiche wird zusätzlich markiert: Das Symbol »↳« rechts
    # am Namen zeigt, dass sie dem Agenten gerade folgt. Ohne das Symbol
    # sieht sie wie eine gewöhnliche Datei im Ordner aus.
    if [ -n "$path" ] && [ -n "${DRAGGED_CORPSE:-}" ] \
       && [ "$path" = "$DRAGGED_CORPSE" ]; then
        drag=" ↳"
    fi
    # Fundorte (Weltgegenstände) zeigen ihre Menge und den vollen Namen,
    # damit im Ordner sofort erkennbar ist, was und wie viel dort liegt:
    # »1x EinfacheFackel«, »12x Bits«. Gewöhnliche Dateien bleiben schlicht.
    if [ -n "$path" ] && [ -n "${WORLD_ITEM[$path]:-}" ] \
       && [ "$isdir" != "1" ] && [ "$isdir" != "d" ]; then
        local wn="${WORLD_N[$path]:-1}"
        [ "$wn" -gt 0 ] 2>/dev/null || wn=1
        label="$FI_ICON ${wn}x $name${drag}"
    else
        label="$FI_ICON $name${drag}"
        [ "$isdir" = "1" ] || [ "$isdir" = "d" ] && label="$FI_ICON $name/${drag}"
    fi
    local len=${#label}
    if [ "$len" -gt "$maxw" ]; then label="${label:0:maxw}"; len=$maxw; fi
    pos "$row" "$col"
    printf '%s%s%s%s' "$UI_BG" "$color" "$label" "$UI_BG"
    local pad=$((maxw - len))
    [ "$pad" -gt 0 ] && printf '%*s' "$pad" ''
    printf '%s' "$RESET"
}

# Region mit Leerzeichen leeren
clear_region() {
    local row="$1" col="$2" maxw="$3" rows="$4" i blank s
    printf -v blank '%*s' "$maxw" ''
    for ((i = 0; i < rows; i++)); do
        printf -v s '\033[%d;%dH%s%s%s' "$((row + i))" "$col" "$UI_BG" "$blank" "$RESET"
        ui_out "$s"
    done
}

# Wortweises Umbrechen: wrap_line <text> <breite>
wrap_line() {
    local t="$1" w="$2" chunk rest
    [ "$w" -lt 1 ] && w=1
    while [ "${#t}" -gt "$w" ]; do
        chunk="${t:0:w}"
        if [[ "$chunk" == *" "* ]]; then chunk="${chunk% *}"; fi
        [ -z "$chunk" ] && chunk="${t:0:w}"
        printf '%s\n' "$chunk"
        rest="${t:${#chunk}}"
        t="${rest# }"
    done
    printf '%s\n' "$t"
}
