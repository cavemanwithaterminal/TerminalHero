# ============================================================
#  TerminalHero - Charakterbogen (Spieler-Status)
#
#  Verwaltet Level und Erfahrung des Agenten und zeichnet das
#  Charakter-Menü (Befehl »character«): ein eigenes, vollflächiges
#  RPG-Fenster - bewusst NICHT in die 4-Fenster-Spiel-GUI geladen.
#
#  Aufstiegsleiter: 0 -> 1 = 100 EXP, 1 -> 2 = 200 EXP, usw.
#  (je Stufe 100 mehr, also (Level+1)*100). Jeder Aufstieg erhöht
#  TOKENS_MAX um 1, gibt 8 Bits (BITS) und bringt 1 SKILLPUNKT
#  (SKILL_POINTS) - die Punkte werden im Bogen angezeigt, aber noch
#  nirgends ausgegeben: eine Skillliste gibt es (noch) nicht.
#  Obergrenze: Stufe 9999 (nur Grenze - nirgends fest hinterlegt).
#
#  Solange das Fenster offen ist, läuft die Token-Regeneration weiter
#  und die Anzeige wird live nachgezogen.
#
#  Nur Funktionsdefinitionen + Startwerte; die Zeichenprimitive
#  (put_text, draw_box, repeat) kommen aus ui.sh, die Farben aus
#  theme.sh, die Token-Werte aus tokens.sh.
#
#  Seit der Höhlen-/Ausrüstungs-Erweiterung zeigt der Bogen zusätzlich
#  die acht Slots aus kern/equipment.sh (Kopf, Oberkörper, Beine,
#  Linke/Rechte Hand, Amulett, Ring1/Ring2). Tragbare Items (Neks
#  Amulett, das Einfache Set u. a.) belegen ihren Slot und zeigen ihre
#  Boni. Vollständige Sets erhöhen TOKENS_MAX zusätzlich.
# ============================================================

# --- Startwerte ------------------------------------------------------
LEVEL=0            # Spielerlevel (Tutorial-Start: 0)
EXP=0              # Erfahrungspunkte INNERHALB der aktuellen Stufe
SKILL_POINTS=0     # Skillpunkte: je Aufstieg +1. Werden u. a. bei
                   # Guy Sus für »search« ausgegeben (2 Punkte + 25 Bits).
CHAR_UPS=0         # Aufstiege des letzten char_gain_exp (Ergebnis-Ausgabe)

# Setzt Level/EXP auf den Startzustand zurück.
# Dev-/Test-Haken: TH_LEVEL / TH_EXP / TH_SKILL_POINTS überschreiben die Startwerte.
char_reset() {
    LEVEL="${TH_LEVEL:-0}"
    EXP="${TH_EXP:-0}"
    SKILL_POINTS="${TH_SKILL_POINTS:-0}"
    CHAR_UPS=0
}

# Für den Aufstieg von <level> auf <level+1> nötige EXP.
# 0 -> 1: 100, 1 -> 2: 200, 2 -> 3: 300, ...
char_exp_needed() {
    local lvl="${1:-0}"
    [ "$lvl" -lt 0 ] && lvl=0
    printf '%s' "$(( (lvl + 1) * 100 ))"
}

# Fügt Erfahrung hinzu und steigt so oft auf, wie es reicht.
# WICHTIG: Ergebnis steht in CHAR_UPS (Anzahl der Aufstiege) - die
# Funktion NICHT per $(...) aufrufen, sonst gingen Level/Tokens in
# einer Subshell verloren. Meldungen landen im Dialogfenster (OUT).
char_gain_exp() {
    local gain="${1:-0}" need
    CHAR_UPS=0
    [ "$gain" -gt 0 ] || return 0
    EXP=$(( EXP + gain ))
    while :; do
        need="$(char_exp_needed "$LEVEL")"
        [ "$EXP" -ge "$need" ] || break
        EXP=$(( EXP - need ))
        LEVEL=$(( LEVEL + 1 ))
        TOKENS_MAX=$(( TOKENS_MAX + 1 ))        # Aufstieg: +1 MaxTokens
        SKILL_POINTS=$(( SKILL_POINTS + 1 ))    # Aufstieg: +1 Skillpunkt
        CHAR_UPS=$(( CHAR_UPS + 1 ))
        declare -F bits_add >/dev/null 2>&1 && bits_add 8
        declare -F play_sound >/dev/null 2>&1 && play_sound online
        OUT+=("")
        OUT+=("   ▲ LEVEL UP  ■  Stufe ${LEVEL} erreicht")
        OUT+=("   Max. Tokens jetzt ${TOKENS_MAX}.  Nächste Stufe: $(char_exp_needed "$LEVEL") EXP")
        OUT+=("   +1 Skillpunkt  ·  +8 Bits")
    done
    return 0
}

# ============================================================
#  Zeichenhelfer für das Charakter-Fenster
# ============================================================

# Balken aufteilen: setzt CB_PCT (Prozent), CB_FILL und CB_EMPTY (Zellen).
char_bar_parts() {   # $1 = aktuell, $2 = max, $3 = Breite
    local cur="$1" max="$2" w="$3"
    [ "$max" -lt 1 ] && max=1
    [ "$cur" -lt 0 ] && cur=0
    [ "$cur" -gt "$max" ] && cur="$max"
    CB_PCT=$(( cur * 100 / max ))
    CB_FILL=$(( CB_PCT * w / 100 ))
    [ "$CB_FILL" -gt "$w" ] && CB_FILL=$w
    CB_EMPTY=$(( w - CB_FILL ))
}

# ============================================================
#  Ausrüstungs-Panel
# ============================================================
# Ein Slot: links der Name, rechts der ausgerüstete Gegenstand
# (oder »— leer —«). Leere und belegte Slots unterscheiden sich
# farblich, damit man den Zustand auf einen Blick sieht.
character_equip_cell() {   # <zeile> <x> <labelbreite> <wertbreite> <slot>
    local row="$1" x="$2" labw="$3" valw="$4" slot="$5"
    local id col
    id="$(equip_get "$slot")"
    col="$MUTED"
    [ -n "$id" ] && col="$ACCENT"
    put_text "$row" "$x" "$labw" "$(equip_slot_label "$slot")" "$MUTED"
    put_text "$row" "$((x + labw))" "$valw" "$(equip_item_label "$slot")" "$col"
}

# Panel zeichnen: <x> <y> <w> <h> <seite|breit>
#   »seite« = eine Spalte unter/neben den Werten (schmale Bildschirme)
#   »breit« = zwei Spalten unter dem Profil (hohe Bildschirme)
character_equip_panel() {
    local x="$1" y="$2" w="$3" h="$4" mode="${5:-breit}"
    local inner=$(( w - 2 )) i
    draw_box "$x" "$y" "$w" "$h" "AUSRÜSTUNG" "$FRAME"

    if [ "$mode" = "seite" ]; then
        local labw=12
        local valw=$(( inner - labw - 2 ))
        [ "$valw" -lt 6 ] && valw=6
        for i in "${!EQUIP_SLOTS[@]}"; do
            character_equip_cell "$((y + 1 + i))" "$((x + 2))" \
                "$labw" "$valw" "${EQUIP_SLOTS[i]}"
        done
        return 0
    fi

    local gap=2
    local colw=$(( (inner - gap) / 2 ))
    local labw=12
    local valw=$(( colw - labw - 1 ))
    [ "$valw" -lt 6 ] && valw=6
    for i in 0 1 2 3; do
        character_equip_cell "$((y + 1 + i))" "$((x + 2))" \
            "$labw" "$valw" "${EQUIP_SLOTS[i]}"
        character_equip_cell "$((y + 1 + i))" "$((x + 2 + colw + gap))" \
            "$labw" "$valw" "${EQUIP_SLOTS[i + 4]}"
    done

    # Nur bei genug Höhe: Trennlinie und kurze Hinweise. Auf kleinen
    # Terminals bleibt das Panel schlank und zeigt nur die acht Slots.
    if [ "$h" -ge 10 ]; then
        local bonus
        bonus="$(equip_bonus_summary 2>/dev/null || true)"
        put_text "$((y + 6))" "$((x + 2))" "$((inner - 2))" \
            "$(repeat '─' "$((inner - 2))")" "$FRAME"
        if [ -n "$bonus" ]; then
            put_text "$((y + 7))" "$((x + 2))" "$((inner - 2))" \
                "Aktive Boni: ${bonus}" "$ACCENT$BOLD"
            put_text "$((y + 8))" "$((x + 2))" "$((inner - 2))" \
                "Getragene Teile sind im Inventar mit ${INV_WORN_MARK:-♦} markiert." "$MUTED"
        else
            put_text "$((y + 7))" "$((x + 2))" "$((inner - 2))" \
                "Noch keine Ausrüstungsteile gefunden." "$MUTED"
            put_text "$((y + 8))" "$((x + 2))" "$((inner - 2))" \
                "Ausrüstung wirkt auf Tokens, Regeneration, Kampf und Verteidigung." "$MUTED"
        fi
    fi
}

# --- ASCII-Portrait (12 Zeichen breit, 8 Zeilen) ---------------------
declare -ga CHAR_ART=(
    '  ▄▄▄▄▄▄▄▄  '
    ' ▄████████▄ '
    ' ██▄▄▄▄▄▄██ '
    ' ██ ◉  ◉ ██ '
    ' ██  ██  ██ '
    ' ██████████ '
    ' ▀████████▀ '
    '   ▀▀▀▀▀▀   '
)

# ============================================================
#  Befehls-Eingang (Verdrahtung für TerminalShell.sh)
# ============================================================
# Ist <wort> der Charakter-Befehl? (character / charakter, Groß-/Kleinschreibung egal)
character_is_command() {
    case "${1,,}" in
        character|charakter) return 0 ;;
    esac
    return 1
}

# Öffnet das Charakter-Fenster, wenn <wort> der Befehl ist – aber nur, wenn der
# General den Befehl im README-Gespräch (Tutorial) beigebracht hat.
# Rückgabe 0 = war der Charakter-Befehl (Fenster bzw. Absage).
# Rückgabe 1 = kein Charakter-Befehl (Zeile läuft normal weiter).
character_handles() {
    character_is_command "$1" || return 1
    if knows character; then
        character_screen
    else
        play_sound error
        OUT+=("»character« …? Nein. Diesen Befehl hat der Virus mir genommen. Noch.")
    fi
    return 0
}

# ============================================================
#  Das Charakter-Fenster (vollflächig, eigenes Layout)
# ============================================================
# Zeichnet den Charakterbogen: Innenraum leeren und alles neu aufbauen.
# Nutzt das große, feste Overlay-Fenster (overlay_geom) - die Größe hängt
# NICHT vom Inhalt ab und springt daher nicht beim Aktualisieren.
character_paint() {
    overlay_geom                # großes, festes Fenster + frische Bildschirmgröße

    local pw="$OV_W" ph="$OV_H" px="$OV_X" py="$OV_Y" iw="$OV_INNER"
    local ix=$(( px + 1 ))

    clear_region "$((py + 1))" "$ix" "$iw" "$((ph - 2))"

    # --- Rahmen + Titel ---
    draw_box "$px" "$py" "$pw" "$ph" "" "$FRAME_HI"
    put_text "$((py + 1))" "$ix" "$iw" \
        "$(center_text '◤  CHARAKTERBOGEN  ◢' "$iw")" "$TITLE$BOLD"
    put_text "$((py + 2))" "$ix" "$iw" "$(repeat '─' "$iw")" "$FRAME"

    # --- Layout: Ausrüstung breit unten oder seitlich ---
    # Bei hohen Fenstern steht unter dem Profil genug Platz für ein
    # zweispaltiges Panel. Auf niedrigen Terminals (z. B. 24 Zeilen)
    # wandert die Ausrüstung stattdessen rechts neben die Werte; auf
    # sehr schmalen Terminals entfällt das Portrait, damit die acht
    # Slots vollständig sichtbar bleiben.
    local pboxw=16 pboxh=10 show_portrait=1
    local eq_mode="keine" eqw=0 eqx=0 eqh=0
    local eq_top=$(( py + 15 ))
    local eq_avail=$(( py + ph - 4 - eq_top + 1 ))
    if [ "$eq_avail" -ge 8 ]; then
        eq_mode="breit"
        eqh=$eq_avail
        [ "$eqh" -gt 12 ] && eqh=12
    else
        eqw=24
        [ "$iw" -ge 86 ] && eqw=28
        [ "$iw" -ge 100 ] && eqw=32
        if [ $(( iw - pboxw - 2 - eqw - 2 )) -ge 20 ]; then
            eq_mode="seite"
        elif [ $(( iw - eqw - 2 )) -ge 20 ]; then
            eq_mode="seite"; show_portrait=0; pboxw=0
        fi
    fi

    # --- links: Portrait (entfällt nur auf sehr schmalen Terminals) ---
    local a
    if [ "$show_portrait" = "1" ]; then
        draw_box "$ix" "$((py + 3))" "$pboxw" "$pboxh" "PROFIL" "$FRAME"
        for a in "${!CHAR_ART[@]}"; do
            put_text "$((py + 4 + a))" "$((ix + 2))" "$((pboxw - 3))" "${CHAR_ART[a]}" "$GOOD"
        done
    fi

    # --- rechts: Daten ---
    local ix2 iw2
    if [ "$show_portrait" = "1" ]; then
        ix2=$(( ix + pboxw + 2 )); iw2=$(( iw - pboxw - 2 ))
    else
        ix2="$ix"; iw2="$iw"
    fi
    if [ "$eq_mode" = "seite" ]; then
        eqx=$(( ix + iw - eqw ))
        iw2=$(( eqx - 2 - ix2 ))
    fi
    local need r barw
    need="$(char_exp_needed "$LEVEL")"
    r=$(( py + 4 ))

    put_text "$r" "$ix2" "$iw2" "  NAME      ${AGENT_NAME}" "$FG";  ((r++))
    put_text "$r" "$ix2" "$iw2" "  KLASSE    Anti-Virus-Agent" "$MUTED"; ((r++))
    put_text "$r" "$ix2" "$iw2" "  $(repeat '─' $(( iw2 - 4 )))" "$FRAME"; ((r++))
    put_text "$r" "$ix2" "$iw2" "  LEVEL     ${LEVEL}" "$TITLE$BOLD"; ((r++))
    put_text "$r" "$ix2" "$iw2" "  EXP       ${EXP} / ${need}" "$ACCENT"; ((r++))

    # EXP-Balken
    barw=$(( iw2 - 10 )); [ "$barw" -gt 26 ] && barw=26; [ "$barw" -lt 8 ] && barw=8
    char_bar_parts "$EXP" "$need" "$barw"
    local c=$ix2 bcol="$GOOD"
    [ "$CB_PCT" -lt 50 ] && bcol="$TITLE"
    [ "$CB_PCT" -lt 20 ] && bcol="$DANGER"
    put_text "$r" "$c" 3 "  [" "$MUTED"; c=$(( c + 3 ))
    put_text "$r" "$c" "$CB_FILL" "$(repeat '█' "$CB_FILL")" "$bcol"; c=$(( c + CB_FILL ))
    put_text "$r" "$c" "$CB_EMPTY" "$(repeat '▒' "$CB_EMPTY")" "$MUTED"; c=$(( c + CB_EMPTY ))
    put_text "$r" "$c" $(( ix2 + iw2 - c )) "]  ${CB_PCT}%" "$FG"
    ((r++))

    put_text "$r" "$ix2" "$iw2" "  SKILLPUNKTE  ${SKILL_POINTS}" "$ACCENT"; ((r++))

    put_text "$r" "$ix2" "$iw2" "  TOKENS    ${TOKENS_CUR} / ${TOKENS_MAX}" "$ACCENT"; ((r++))

    # Token-Balken (gleiche Farblogik wie die Token-Leiste im Spiel)
    char_bar_parts "$TOKENS_CUR" "$TOKENS_MAX" "$barw"
    c=$ix2; bcol="$GOOD"
    [ "$CB_PCT" -lt 50 ] && bcol="$TITLE"
    [ "$CB_PCT" -lt 20 ] && bcol="$DANGER"
    put_text "$r" "$c" 3 "  [" "$MUTED"; c=$(( c + 3 ))
    put_text "$r" "$c" "$CB_FILL" "$(repeat '█' "$CB_FILL")" "$bcol"; c=$(( c + CB_FILL ))
    put_text "$r" "$c" "$CB_EMPTY" "$(repeat '▒' "$CB_EMPTY")" "$MUTED"; c=$(( c + CB_EMPTY ))
    put_text "$r" "$c" $(( ix2 + iw2 - c )) "]  ${CB_PCT}%" "$FG"
    ((r++))
    local flavor="  ▸ ${AGENT_NAME} – Einheit aus dem Root-Krieg"
    [ "$iw2" -lt 46 ] && flavor="  ▸ ${AGENT_NAME} – Root-Krieg"
    put_text "$r" "$ix2" "$iw2" "$flavor" "$MUTED"

    # --- Ausrüstung ---
    if [ "$eq_mode" = "breit" ]; then
        character_equip_panel "$ix" "$eq_top" "$iw" "$eqh" breit
    elif [ "$eq_mode" = "seite" ]; then
        character_equip_panel "$eqx" "$((py + 3))" "$eqw" 10 seite
    fi

    # --- Fußzeile ---
    put_text "$((py + ph - 3))" "$ix" "$iw" "$(repeat '─' "$iw")" "$FRAME"
    put_text "$((py + ph - 2))" "$ix" "$iw" \
        "$(center_text 'Esc / Q   ·   zurück zur Shell' "$iw")" "$MENU_C"
}

# Öffnet den Charakterbogen und hält ihn offen. Solange das Fenster steht,
# läuft die Token-Regeneration weiter und die Anzeige wird live nachgezogen
# (sonst bliebe die Token-Zahl stehen, bis man das Menü verlässt).
character_screen() {
    play_sound select

    # Eigener Bildschirm: Spiel-GUI komplett überdecken.
    printf '%s' "$UI_BG"
    clear

    local need_paint=1 k
    while true; do
        if [ "$need_paint" = "1" ]; then
            character_paint
            need_paint=0
        fi
        # 1 s Timeout: tippt niemand, werden fällige Tokens eingesammelt.
        if ! read_key_t 1; then
            [ "$LAST_KEY_RC" = "2" ] && break      # EOF
            tokens_tick && need_paint=1            # nur bei echter Regeneration neu zeichnen
            continue
        fi
        k="$LAST_KEY"
        case "$k" in
            $'\x1b'|q|Q) break ;;                       # schließen (Esc oder Q)
        esac
    done

    # Danach die Spiel-GUI vollständig neu aufbauen (CHARAKTER-Fenster weg).
    FIRST_RENDER=1
    return 0
}
