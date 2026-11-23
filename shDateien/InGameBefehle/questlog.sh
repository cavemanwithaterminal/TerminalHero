# ============================================================
#  TerminalHero - Questlog
#
#  Sammelt alle Quests (Haupt- und Nebenquests) und zeichnet das
#  Questlog-Fenster (Befehl »questlog«): ein eigenes, vollflächiges
#  Fenster - bewusst NICHT in die 4-Fenster-Spiel-GUI geladen.
#
#  Aufbau:
#    ┌ QUESTLOG ──────────────────────────────────────────┐
#    │  [ Hauptquest ]  [ Nebenquest ]                    │  Reiter 1 (←/→, Enter)
#    │    [ Aktuell ] [ Abgeschlossen ] [ Gescheitert ]   │  Reiter 2 (←/→, Enter)
#    │  ┌ DETAILS ─────────┐  ┌ QUESTS [n] ─────────────┐ │
#    │  │ Details zum      │  │ Quest-Liste (↑/↓ wählen)│ │
#    │  │ gewählten Quest  │  │                         │ │
#    │  └──────────────────┘  └─────────────────────────┘ │
#    └────────────────────────────────────────────────────┘
#
#  Bedienung: ←/→ Reiter wählen · Enter bestätigen · ↑/↓ Quest wählen
#             Bild↑/↓ Details blättern · Tab weiterschalten · Esc/Q schließen
#
#  Das Fenster nutzt das große, feste Overlay (overlay_geom) - die Größe
#  hängt NICHT vom Text ab und springt daher nicht beim Blättern.
#
#  Neue Quests (z. B. aus einem Stadtteil) melden sich so an:
#     quest_define <id> haupt|neben "<Titel>" "<Detailtext mit \\n>"
#     quest_status_<id>()  -> aktuell | abgeschlossen | gescheitert | verborgen
#     quest_goal_<id>()    -> optionale einzeilige Zielvorgabe (wird angezeigt)
#     quest_entries_<id>() -> optionaler Verlauf: je Zeile ein Log-Eintrag,
#                             der sich aus dem Spielfortschritt ergibt
#
#  Meldungen im Dialogfenster (am Ende eines Gesprächs):
#     quest_gained <id>          -> »[ NEUE QUEST ]  »Titel« erhalten«
#     quest_reward <id> <exp>    -> Abschluss + »Questbelohnung: n EXP«
#                                   (schreibt die EXP über char_gain_exp gut)
#     quest_note <text>          -> »[ QUESTLOG ]  Neue Spur: …« (neue Erkenntnis)
#
#  Nur Funktionsdefinitionen + Quest-Daten; Zeichenprimitive (put_text,
#  draw_box, clear_region, center_text, wrap_line) kommen aus ui.sh.
# ============================================================

# ============================================================
#  Register
# ============================================================
declare -ga QL_HAUPT=()      # Quest-IDs der Hauptquests (Anzeige-Reihenfolge)
declare -ga QL_NEBEN=()      # Quest-IDs der Nebenquests
declare -gA QL_TITLE=()      # id -> Titel
declare -gA QL_DETAIL=()     # id -> Detailtext (echte Zeilenumbrüche)
declare -gA QL_STATUS=()     # id -> aktuell|abgeschlossen|gescheitert|verborgen

QL_SHOWN=()                 # aktuell gefilterte IDs (von ql_build_list gefüllt)
QL_DTXT=()                  # Detailzeilen des gewählten Quests (Text, scrollbar)
QL_DCOL=()                  # Detailzeilen (Farbe), parallel zu QL_DTXT
QL_DMAX=0                   # maximaler Detail-Scroll (ql_draw)
QL_DCAP=0                   # sichtbare Detailzeilen (ql_draw)

# Quest anlegen (idempotent): quest_define <id> <haupt|neben> <Titel> <Detail>
quest_define() {
    local id="$1" typ="$2" titel="$3" detail="$4"
    [ -n "${QL_TITLE[$id]:-}" ] && return 0
    QL_TITLE["$id"]="$titel"
    QL_DETAIL["$id"]="$detail"
    QL_STATUS["$id"]="verborgen"
    if [ "$typ" = "haupt" ]; then
        QL_HAUPT+=("$id")
    else
        QL_NEBEN+=("$id")
    fi
}

# Status setzen (für Erzähl-Hooks; sonst bestimmt questlog_refresh ihn).
quest_set_status() { QL_STATUS["$1"]="$2"; }

# ============================================================
#  Meldungen im Dialogfenster
# ============================================================
# Eine Quest wird erhalten (z. B. am Ende eines Gesprächs):
#    [ NEUE QUEST ]  »Titel« erhalten
quest_gained() {   # $1 = Quest-ID
    # Jeder Quest-Erhalt bekommt denselben kurzen Ton - egal, ob die Szene
    # quest_gained direkt aufruft oder über quest_gain_once geht.
    play_sound online
    OUT+=("")
    OUT+=("[ NEUE QUEST ]  »${QL_TITLE[$1]:-$1}« erhalten")
}

# Eine Quest ist abgeschlossen. Die Belohnung wird gutgeschrieben und
# ausgewiesen (genau dann, wenn es die EXP gibt):
#    [ QUEST ABGESCHLOSSEN ]  »Titel«
#       Questbelohnung: 50 EXP
quest_reward() {   # $1 = Quest-ID, $2 = EXP-Belohnung (0 = keine)
    local id="$1" exp="${2:-0}"
    OUT+=("")
    OUT+=("[ QUEST ABGESCHLOSSEN ]  »${QL_TITLE[$id]:-$id}«")
    if [ "$exp" -gt 0 ] 2>/dev/null; then
        OUT+=("   Questbelohnung: ${exp} EXP")
        char_gain_exp "$exp"
    fi
}

# Eine Quest ist gescheitert (z. B. die Bierlieferung nach 24 Spielstunden):
#    [ QUEST GESCHEITERT ]  »Titel«
quest_failed() {   # $1 = Quest-ID
    OUT+=("")
    OUT+=("[ QUEST GESCHEITERT ]  »${QL_TITLE[$1]:-$1}«")
}

# Eine Quest bekommt eine neue Spur/Erkenntnis (z. B. eine bezahlte Auskunft):
#    [ QUESTLOG ]  Neue Spur: …
quest_note() {   # $1 = Meldung
    OUT+=("")
    OUT+=("[ QUESTLOG ]  Neue Spur: $1")
}

# Eine Quest nur vergeben, wenn sie noch NICHT bekannt ist ("verborgen").
# Mehrere Stellen dürfen dieselbe Quest anbieten (später z. B. Börty UND
# eine Anzeige, ein Fund oder ein anderer Zeuge) - bekommen wird sie
# trotzdem nur einmal. Rückgabe 0 = neu vergeben, 1 = war schon bekannt.
quest_gain_once() {   # $1 = Quest-ID
    local id="$1" fn st
    fn="quest_status_$id"
    if declare -F "$fn" >/dev/null 2>&1; then
        st="$("$fn")"
    else
        st="${QL_STATUS[$id]:-verborgen}"
    fi
    [ "$st" = "verborgen" ] || return 1
    quest_gained "$id"
    QL_STATUS["$id"]="aktuell"
    return 0
}

# Status aller Quests neu aus dem Spielzustand bestimmen: existiert zu einer
# Quest eine Funktion quest_status_<id>, liefert sie den aktuellen Wert.
questlog_refresh() {
    local id fn
    for id in "${QL_HAUPT[@]}" "${QL_NEBEN[@]}"; do
        fn="quest_status_$id"
        if declare -F "$fn" >/dev/null 2>&1; then
            QL_STATUS["$id"]="$("$fn")"
        fi
    done
}

# ============================================================
#  Befehls-Eingang (Verdrahtung für TerminalShell.sh)
# ============================================================
# Ist <wort> der Questlog-Befehl? (questlog / quests, Groß-/Kleinschreibung egal)
questlog_is_command() {
    case "${1,,}" in
        questlog|quests) return 0 ;;
    esac
    return 1
}

# Öffnet das Questlog-Fenster, wenn <wort> der Befehl ist – aber nur, wenn der
# General den Befehl im README-Gespräch (Tutorial) beigebracht hat.
# Rückgabe 0 = war der Questlog-Befehl (Fenster bzw. Absage).
# Rückgabe 1 = kein Questlog-Befehl (Zeile läuft normal weiter).
questlog_handles() {
    questlog_is_command "$1" || return 1
    if knows questlog; then
        questlog_screen
    else
        play_sound error
        OUT+=("»questlog« …? Nein. Diesen Befehl hat der Virus mir genommen. Noch.")
    fi
    return 0
}

# ============================================================
#  Fenster
# ============================================================
# Liste anhand der Reiter füllen: $1 = 0 Hauptquest/1 Nebenquest, $2 = 0|1|2 Status
ql_build_list() {
    QL_SHOWN=()
    local ids=() id want
    if [ "$1" = "0" ]; then ids=("${QL_HAUPT[@]}"); else ids=("${QL_NEBEN[@]}"); fi
    case "$2" in
        0) want="aktuell" ;;
        1) want="abgeschlossen" ;;
        2) want="gescheitert" ;;
        *) want="aktuell" ;;
    esac
    for id in "${ids[@]}"; do
        [ "${QL_STATUS[$id]:-verborgen}" = "$want" ] && QL_SHOWN+=("$id")
    done
}

ql_stat_label() {   # $1 = Status -> Anzeigetext
    case "$1" in
        aktuell)       printf 'aktuell' ;;
        abgeschlossen) printf 'abgeschlossen' ;;
        gescheitert)   printf 'gescheitert' ;;
        *)             printf 'unbekannt' ;;
    esac
}

# Eine Reiterzeile: $1=Zeile $2=x $3=fokussiert(0|1) $4=Auswahl  $5.. = Beschriftungen
ql_tab_row() {
    local row="$1" x="$2" foc="$3" sel="$4"; shift 4
    local labels=("$@") i t col
    [ "$foc" = "1" ] && put_text "$row" "$((x - 2))" 1 "▸" "$ACCENT$BOLD"
    for i in "${!labels[@]}"; do
        t="[ ${labels[i]} ]"
        if [ "$i" = "$sel" ]; then
            if [ "$foc" = "1" ]; then col="$ACCENT$BOLD"; else col="$TITLE$BOLD"; fi
        else
            col="$MUTED"
        fi
        put_text "$row" "$x" "${#t}" "$t" "$col"
        x=$(( x + ${#t} + 2 ))
    done
}

# Eine Detailzeile anhängen (parallel: Text + Farbe).
ql_dline() { QL_DTXT+=("$1"); QL_DCOL+=("$2"); }

# Dynamischer Verlauf eines Quests: quest_entries_<id>() gibt je Zeile einen
# Log-Eintrag aus (aus dem aktuellen Spielfortschritt abgeleitet, damit die
# Einträge sich automatisch aktualisieren). Ohne Funktion -> leer.
ql_entries_of() {   # $1 = Quest-ID
    local fn="quest_entries_$1"
    declare -F "$fn" >/dev/null 2>&1 && "$fn"
    return 0
}

# Details des gewählten Quests aufbauen: $1 = Quest-ID (leer = keiner),
# $2 = Innenbreite. Ergebnis in QL_DTXT/QL_DCOL.
ql_build_details() {
    QL_DTXT=(); QL_DCOL=()
    local qid="$1" cw="$2"
    if [ -z "$qid" ]; then
        ql_dline "(kein Quest in dieser Kategorie)" "$MUTED"
        return 0
    fi

    # Titel und Überschriften sind rot; Status, Ziel, Verlauf und
    # Fließtext bleiben grau. So hebt sich die Struktur ab, ohne dass
    # das ganze Buch wie eine einzige Warnung aussieht.
    local wl dline gfn goal
    while IFS= read -r wl; do ql_dline "$wl" "$DANGER$BOLD"; done \
        < <(wrap_line "◈ ${QL_TITLE[$qid]}" "$cw")
    ql_dline "Status: $(ql_stat_label "${QL_STATUS[$qid]:-unbekannt}")" "$MUTED"
    gfn="quest_goal_$qid"
    if declare -F "$gfn" >/dev/null 2>&1; then
        goal="$("$gfn")"
        # Das Ziel darf umbrechen (wie Titel und Verlauf) - sonst schneidet
        # das Fenster lange Ziele einfach ab.
        if [ -n "$goal" ]; then
            while IFS= read -r wl; do ql_dline "$wl" "$MUTED"; done \
                < <(wrap_line "Ziel: ${goal}" "$cw")
        fi
    fi

    ql_dline "" "$MUTED"

    # Verlauf ZUERST: neue Einträge sollen sofort sichtbar sein, ohne zu
    # blättern (der lange Hintergrund-Text folgt darunter).
    local entries el
    entries="$(ql_entries_of "$qid")"
    if [ -n "$entries" ]; then
        ql_dline "── Verlauf ──" "$DANGER$BOLD"
        while IFS= read -r el; do
            [ -n "$el" ] || continue
            while IFS= read -r wl; do ql_dline "$wl" "$MUTED"; done \
                < <(wrap_line "◆ $el" "$cw")
        done <<< "$entries"
        ql_dline "" "$MUTED"
    fi

    # Hintergrund/Beschreibung
    while IFS= read -r dline; do
        while IFS= read -r wl; do ql_dline "$wl" "$MUTED"; done < <(wrap_line "$dline" "$cw")
    done <<< "${QL_DETAIL[$qid]}"
}

ql_draw() {   # $1=Fokus(0 Haupt,1 Status,2 Liste) $2=Haupt $3=Status $4=Quest $5=Detail-Scroll
    local foc="$1" msel="$2" ssel="$3" isel="$4" dscroll="$5"
    overlay_geom                # großes, festes Fenster

    local pw="$OV_W" ph="$OV_H" px="$OV_X" py="$OV_Y" inner="$OV_INNER"

    clear_region "$((py + 1))" "$((px + 1))" "$inner" "$((ph - 2))"
    draw_box "$px" "$py" "$pw" "$ph" "" "$FRAME_HI"
    put_text "$((py + 1))" "$((px + 1))" "$inner" \
        "$(center_text '◤  QUESTLOG  ◢' "$inner")" "$TITLE$BOLD"

    # --- Reiter ---
    local f1=0 f2=0
    [ "$foc" = "0" ] && f1=1
    [ "$foc" = "1" ] && f2=1
    ql_tab_row "$((py + 2))" "$((px + 4))" "$f1" "$msel" "Hauptquest" "Nebenquest"
    ql_tab_row "$((py + 3))" "$((px + 4))" "$f2" "$ssel" "Aktuell" "Abgeschlossen" "Gescheitert"

    # --- zwei Kästen (wie Dialog links / ls rechts in der Spiel-GUI) ---
    local ptop=$(( py + 5 )) phgt=$(( ph - 8 ))
    [ "$phgt" -lt 3 ] && phgt=3
    local avail=$(( pw - 4 )) gap=1
    local lw=$(( (avail - gap) * 58 / 100 ))
    [ "$lw" -lt 20 ] && lw=20
    local rw=$(( avail - gap - lw ))
    [ "$rw" -lt 16 ] && { rw=16; lw=$(( avail - gap - rw )); }
    local lx=$(( px + 2 )) rx=$(( px + 2 + lw + gap ))
    local rmax=$(( ptop + phgt - 2 ))

    # --- links: Details zum gewählten Quest (bei Bedarf scrollbar) ---
    local qid=""
    [ "${#QL_SHOWN[@]}" -gt 0 ] && qid="${QL_SHOWN[$isel]}"
    local dcw=$(( lw - 4 )); [ "$dcw" -lt 5 ] && dcw=5
    ql_build_details "$qid" "$dcw"

    local dcap=$(( phgt - 2 )); [ "$dcap" -lt 1 ] && dcap=1
    local dtotal=${#QL_DTXT[@]}
    local dmax=$(( dtotal - dcap )); [ "$dmax" -lt 0 ] && dmax=0
    [ "$dscroll" -gt "$dmax" ] && dscroll="$dmax"; [ "$dscroll" -lt 0 ] && dscroll=0

    local dtitle="DETAILS"
    [ "$dmax" -gt 0 ] && dtitle="DETAILS ▲${dscroll}"
    draw_box "$lx" "$ptop" "$lw" "$phgt" "$dtitle" "$FRAME"
    local rr=$(( ptop + 1 )) di
    for ((di = dscroll; di < dtotal && di < dscroll + dcap; di++)); do
        put_text "$rr" "$((lx + 2))" "$dcw" "${QL_DTXT[di]}" "${QL_DCOL[di]}"
        ((rr++))
    done

    # --- rechts: Quest-Liste ---
    draw_box "$rx" "$ptop" "$rw" "$phgt" "QUESTS [${#QL_SHOWN[@]}]" "$FRAME"
    local rcw=$(( rw - 4 )); [ "$rcw" -lt 5 ] && rcw=5
    local inner_h=$(( phgt - 2 )); [ "$inner_h" -lt 1 ] && inner_h=1
    local rrow=$(( ptop + 1 ))
    if [ "${#QL_SHOWN[@]}" -eq 0 ]; then
        put_text "$rrow" "$((rx + 2))" "$rcw" "(keine)" "$MUTED"
    else
        local first=0
        [ "$isel" -ge "$inner_h" ] && first=$(( isel - inner_h + 1 ))
        local j="$first" iid mark col
        while [ "$j" -lt "${#QL_SHOWN[@]}" ] && [ "$rrow" -le "$rmax" ]; do
            iid="${QL_SHOWN[$j]}"; mark="  "; col="$DANGER"
            if [ "$j" = "$isel" ]; then
                if [ "$foc" = "2" ]; then mark="▸ "; col="$DANGER$BOLD"; else mark="· "; col="$DANGER$BOLD"; fi
            fi
            put_text "$rrow" "$((rx + 2))" "$rcw" "${mark}${QL_TITLE[$iid]}" "$col"
            j=$(( j + 1 )); ((rrow++))
        done
    fi

    # --- Fußzeile ---
    local hint
    if [ "$inner" -ge 76 ]; then
        hint='←/→ Reiter · ↑/↓ Liste · Bild↑/↓ Details · Esc schließen'
    else
        hint='←/→ · ↑/↓ · Bild↑/↓ · Esc'
    fi
    put_text "$((py + ph - 2))" "$((px + 1))" "$inner" "$(center_text "$hint" "$inner")" "$MENU_C"

    QL_DMAX=$dmax
    QL_DCAP=$dcap
}

# Das Questlog-Fenster: eigene Schleife mit Reiter- und Listen-Navigation.
questlog_screen() {
    play_sound select
    local foc=0 msel=0 ssel=0 isel=0 dscroll=0

    questlog_refresh
    ql_build_list "$msel" "$ssel"

    while true; do
        ql_draw "$foc" "$msel" "$ssel" "$isel" "$dscroll"
        read_key_t "" || break
        local sel_before="$isel"
        case "$LAST_KEY" in
            $'\x1b[A'|$'\x1bOA')                        # hoch
                case "$foc" in
                    2) if [ "$isel" -gt 0 ]; then isel=$(( isel - 1 )); else foc=1; fi ;;
                    1) foc=0 ;;
                esac ;;
            $'\x1b[B'|$'\x1bOB')                        # runter
                case "$foc" in
                    0) foc=1 ;;
                    1) foc=2; isel=0 ;;
                    2) [ "$isel" -lt $(( ${#QL_SHOWN[@]} - 1 )) ] && isel=$(( isel + 1 )) ;;
                esac ;;
            $'\x1b[D'|$'\x1bOD')                        # links
                case "$foc" in
                    0) [ "$msel" -gt 0 ] && msel=$(( msel - 1 )) ;;
                    1) [ "$ssel" -gt 0 ] && ssel=$(( ssel - 1 )) ;;
                esac
                ql_build_list "$msel" "$ssel"
                [ "$isel" -ge "${#QL_SHOWN[@]}" ] && isel=0 ;;
            $'\x1b[C'|$'\x1bOC')                        # rechts
                case "$foc" in
                    0) [ "$msel" -lt 1 ] && msel=$(( msel + 1 )) ;;
                    1) [ "$ssel" -lt 2 ] && ssel=$(( ssel + 1 )) ;;
                esac
                ql_build_list "$msel" "$ssel"
                [ "$isel" -ge "${#QL_SHOWN[@]}" ] && isel=0 ;;
            $'\x1b[5~')                                 # Bild hoch: Details blättern
                dscroll=$(( dscroll - QL_DCAP )); [ "$dscroll" -lt 0 ] && dscroll=0 ;;
            $'\x1b[6~')                                 # Bild runter: Details blättern
                dscroll=$(( dscroll + QL_DCAP )); [ "$dscroll" -gt "$QL_DMAX" ] && dscroll="$QL_DMAX" ;;
            $'\t')                                      # weiterschalten
                foc=$(( (foc + 1) % 3 )); isel=0 ;;
            ''|$'\n'|$'\r')                             # bestätigen
                case "$foc" in
                    0) foc=1 ;;
                    1) foc=2; isel=0 ;;
                esac ;;
            $'\x1b'|q|Q)                                # schließen
                break ;;
        esac
        [ "$isel" != "$sel_before" ] && dscroll=0       # Questwechsel: Details nach oben
    done

    # Danach die Spiel-GUI vollständig neu aufbauen (Questlog-Fenster weg).
    FIRST_RENDER=1
    return 0
}

# ============================================================
#  Die Quests dieser Welt
# ============================================================
quest_init() {
    # --- Hauptquest: Aller Anfang ist schwer (Tutorial/README) ---------
    # Startet mit dem Spiel selbst: Der Agent weiß nichts und muss erst
    # dem General (README) begegnen. Abgeschlossen, sobald das Tutorial
    # durch ist; die Belohnung gibt es beim Abschluss (50 EXP).
    quest_define anfang haupt "Aller Anfang ist schwer" \
        $'Du bist aufgewacht, ohne zu wissen, wer du bist. Dein Gedächtnis\n'\
$'ist ein leerer Ordner – der Virus hat ihn geräumt.\n\n'\
$'Das Einzige, was dir geblieben ist, ist die README in deinem\n'\
$'Agenten-Ordner: der General. Er sagt dir, wer du bist und was auf\n'\
$'dem Spiel steht. Und er gibt dir die ersten Werkzeuge zurück:\n'\
$'»help«, »character«, »questlog« und »inventar«.\n\n'\
$'Kein großer Auftrag – nur der erste Schritt. Aber ohne ihn bleibt\n'\
$'jeder weitere Weg im Dunkeln.'

    # --- Hauptquest: die Reporterin aus dem Root ----------------------
    quest_define pixi haupt "Die Reporterin aus dem Root" \
        $'Pixi Nullpunkt - Datenjournalistin bei /var/log/daily-pulse, der\n'\
$'letzten Zeitung, die der Virus noch nicht gefressen hat.\n\n'\
$'Sie war in der Root-Sperrzone und hat gesehen, was dort wirklich läuft.\n'\
$'Seither ist ein Hunter-Killer-Daemon - getarnt als systemd-journal -\n'\
$'hinter ihr her; er hat ihren Inode markiert.\n\n'\
$'Sie flieht durch den Schreibtisch in die Stadt und will ihre Redaktion\n'\
$'erreichen. Sie weiß mehr über den Virenkern als jeder Log.'


    # --- Nebenquest: Ein Dach über dem Kopf (Verlag / Baracke) --------
    quest_define nachtlager neben "Ein Dach über dem Kopf" \
        $'Pixi hat dich in den Zeitungsverlag DailyPulse gebracht. Die\n'\
$'Redaktion ist zugleich das Zuhause ihrer Familie: Rachel - Besitzerin\n'\
$'und Chefredakteurin der letzten Zeitung, die der Virus noch nicht\n'\
$'gefressen hat - und Jack, ihr Bruder, der lieber zweimal rechnet als\n'\
$'einmal zu hoffen.\n\n'\
$'Rachel schickt dich nicht fort, aber sie lässt dich auch nicht im\n'\
$'Verlag schlafen. Dein Nachtlager wird die eingestürzte Baracke im\n'\
$'Süddistrikt - und Pixi bringt dich hin.'


    # --- Hauptquest: Finde Detektiv Conan (Chefermittler) -------------
    # Wird erst vergeben, wenn der Chefermittler (DetektivConan/README)
    # angesprochen wurde. Belohnung für den Abschluss steht noch nicht fest.
    quest_define detektiv haupt "Finde Detektiv Conan" \
        $'Der Chefermittler führt nur noch Akten – er ist die README eines\n'\
$'Agenten, der selbst nicht mehr zurückkam.\n\n'\
$'DetektivConan wurde nach BarbarConan entsandt: kein Krieger, ein\n'\
$'Analytiker. Er wollte den Virus überführen statt ihn zu erschlagen,\n'\
$'und folgte einer Spur bis in eine Sackgasse. Sie war gestellt. Für\n'\
$'ihn.\n\n'\
$'Seither fehlt von ihm jede Spur. Ein Ermittler verschwindet nicht\n'\
$'einfach. Er wartet – irgendwo im System.'

    # --- Hauptquest: Finde Barbar Conan (Kriegsrat) -------------------
    # Wird erst vergeben, wenn der Kriegsrat (BarbarConan/README)
    # angesprochen wurde. Belohnung für den Abschluss steht noch nicht fest.
    quest_define conan haupt "Finde Barbar Conan" \
        $'Der Kriegsrat wütet in der README von BarbarConan – und hält\n'\
$'dich im ersten Moment für seinen verlorenen Krieger.\n\n'\
$'BarbarConan wurde Wochen vor dir entsandt. Er trat Türen ein, wo er\n'\
$'hätte lauschen sollen, und zerschlug die halbe Festplatte. Der Virus\n'\
$'war ihm immer einen Schritt voraus – bis er ihn fraß.\n\n'\
$'Seit Wochen schweigt der Funk. Vielleicht liegt Conan irgendwo im\n'\
$'System. Zerbrochen. Vielleicht nur noch ein Fragment.\n\n'\
$'Der Kriegsrat will ihn zurück.'

    # --- Hauptquest: Großer Ermittler (Pixis Brief / Sherlock Holmes) --
    # Beginnt, wenn Pixi im Verlag den Brief übergibt (Charakter/pixi.sh,
    # pixi_letter_scene), und führt über die Detektei Holmes (Ostdistrikt,
    # Amanda Nox) zu Sherlock Holmes selbst: Verfolgung im Ostdistrikt,
    # Norddistrikt, Detektei (Briefübergabe, 100 EXP) und Bericht an Pixi
    # (Abschluss, 200 EXP). Siehe Charakter/SherlockHolmes.sh.
    quest_define ermittler haupt "Großer Ermittler" \
        $'Pixi schreibt an ihrem Artikel über die Sperrzone – und hat für die\n'\
$'Zwischenzeit einen Auftrag für dich: einen Brief.\n\n'\
$'Der Empfänger ist kein Amt und keine Redaktion, sondern ein Detektiv:\n'\
$'Sherlock Holmes, Detektei Holmes im Ostdistrikt. Er löst Fälle, die die\n'\
$'Stadt längst zu den Akten gelegt hat.\n\n'\
$'Was Pixi im Root gesehen hat, gehört in keine Ausgabe – es gehört in\n'\
$'die Hände von jemandem, der aus einem Verdacht einen Beweis macht.\n'\
$'Der Brief muss persönlich abgegeben werden.'

    # --- Hauptquest: Vermisste Bewohner (Börtys Bitte) ----------------
    # Erst nach der abgeschlossenen Quest »Großer Ermittler« und nur über
    # Börtys Standardgespräch (Option »Kann ich dir irgendwie behilflich
    # sein?«, Charakter/BörtySmiles.sh). Bewusst über quest_gain_once:
    # später soll es MEHRERE Wege geben, dieselbe Quest zu bekommen.
    quest_define vermisste haupt "Vermisste Bewohner" \
        $'Seit Monaten werden in der Stadt immer wieder Leute vermisst\n'\
$'gemeldet. Sie verschwinden spurlos: kein Kampf, keine Spur, kein\n'\
$'Abschied. Die Wache schreibt es in eine Liste und legt die Liste weg.\n\n'\
$'Börty Smiles kennt diese Liste besser als jedes Amt – in seinem Laden\n'\
$'redet die halbe Stadt. Ein Name steht ganz oben, und der ist seiner:\n'\
$'Michael Mitch, sein Lagergehilfe. Seit Tagen nicht mehr aufgetaucht.\n\n'\
$'»Vermisste Bewohner? Was ist hier los?« Börty hat es ausgesprochen,\n'\
$'und seitdem liegt es bei dir.'

    # --- Nebenquest: Bier für Börty (Lieferung vom Marktplatz) --------
    # Börty vergibt sie zusammen mit der Hauptquest: Er kann die Kneipe
    # nicht verlassen und braucht Nachschub. 250 Bits bekommt der Agent
    # DIREKT mit (BIER_GIVEN, Charakter/BörtySmiles.sh); die Lieferung
    # liegt im Lager am Marktplatz im Zentrum (Lagermeister Samy Cage).
    quest_define bier neben "Bier für Börty" \
        $'Börty kann seinen Laden nicht verlassen – und ihm geht das Bier\n'\
$'aus. Die Lieferung steht im Lager am Marktplatz im Zentrum der Stadt;\n'\
$'Lagermeister ist Samy Cage.\n\n'\
$'Die 250 Bits dafür hat Börty dir direkt mitgegeben. Er vertraut dir –\n'\
$'weil Pixi dir vertraut. Das ist keine Kleinigkeit, nicht bei ihm.\n\n'\
$'Hol das Bier und bring es zurück, bevor die Stammgäste das Fass selbst\n'\
$'auseinandernehmen.'

    # --- Nebenquest: Michael Mitch. Vermisst -------------------------
    # Entsteht am Ende der Bierlieferung (Charakter/BörtySmiles.sh,
    # boerty_beer_return): Der Agent fragt nach Mitch, Börty weiß nichts –
    # und aus dem offenen Thema wird die eigene Quest. Mit ihr wandert der
    # Eintrag »Michael Mitch, der Gehilfe von Börty, ist verschwunden« in
    # die Hauptquest »Vermisste Bewohner« (quest_entries_vermisste).
    quest_define mitch neben "Michael Mitch. Vermisst" \
        $'Michael Mitch ist Börtys Lagergehilfe – ein großer, ruhiger Kerl,\n'\
$'der Kisten so einsortiert, wie sie heißen. Seit Tagen ist er\n'\
$'verschwunden: kein Wort, keine Nachricht, keine Spur.\n\n'\
$'Börty hat es dir am Ende der Bierlieferung selbst gesagt: Er weiß\n'\
$'nicht, wo Mitch steckt, und er will es wissen. Wer etwas von ihm hört,\n'\
$'soll sich bei ihm melden.\n\n'\
$'Mitch ist nicht der Erste, der in dieser Stadt verschwindet – sein\n'\
$'Name steht ganz oben auf der Liste der Vermissten.'

    # --- Nebenquest: Wo ist Nek Molerat? ------------------------------
    # Entsteht im Standardgespräch von Simon Guard am Haupttor, sobald
    # die Hauptquest »Vermisste Bewohner« bekannt ist. Simon ist mit Nek
    # befreundet; Nek ist seit Tagen verschwunden. Simple Jon im Wachhaus
    # (Haupteingang) weiß, dass Nek die Stadt verlassen hat, um etwas zu
    # erledigen - und nicht zurückkam. Der Hinweis aktualisiert NUR diese
    # Nebenquest, nicht die Hauptquest.
    quest_define nek neben "Wo ist Nek Molerat?" \
        $'Nek Molerat ist Stadtwache – und ein Freund von Simon Guard.\n'\
$'Seit Tagen ist er verschwunden. Niemand weiß, wo er steckt.\n\n'\
$'Simon bittet mich, ihm Bescheid zu sagen, wenn ich Nek finde oder\n'\
$'erfahre, was mit ihm passiert ist. Die Wache führt eine Liste der\n'\
$'Vermissten. Nek steht jetzt auch darauf.\n\n'\
$'Simple Jon im Wachhaus im Haupteingang ist eine der anderen Wachen.\n'\
$'Er kannte Nek. Vielleicht weiß er, wohin Nek gegangen ist.'

    # --- Nebenquest: Ein neuer Gehilfe für Börty ----------------------
    # Entsteht, wenn der Agent Börty erzählt, dass Mitch nicht zurück-
    # kommt (MITCH_DONE). Börty kann die Kneipe nicht verlassen und bittet
    # um einen neuen Gehilfen. Die Suche selbst ist noch offen.
    quest_define gehilfe neben "Ein neuer Gehilfe für Börty" \
        $'Mitch lässt Börty sitzen: Er will nicht mehr für ihn arbeiten und\n'\
$'bleibt im Restaurant im Westdistrikt. Börty tobt – und sitzt dann\n'\
$'wieder allein hinter seiner Theke. Er kann den Laden nicht verlassen\n'\
$'und braucht dringend einen neuen Gehilfen.\n\n'\
$'Ich habe ihm versprochen, mich umzusehen – ohne Garantie.\n'\
$'Vielleicht kennt jemand in der Stadt einen, der Kisten zählen kann.'

    # --- Nebenquest: Die langweiligste Ausgabe (Jacks Rückholaktion) ---
    # Wird erst nach der Baracken-Szene bei Jack angeboten (Charakter/
    # verlag.sh): Die erste DailyPulse-Ausgabe »Bezirke der Stadt«
    # verkauft sich nicht. Rachel will die Restexemplare aus den fünf
    # Zeitungskästen zurück und das Papier wiederverwenden. Jack gibt
    # den Schlüssel; jedes Bündel kommt aus einem Bezirk.
    quest_define zeitung neben "Die langweiligste Ausgabe" \
        $'Jack Nullpunkt hat die erste DailyPulse-Ausgabe geschrieben:\n'\
$'»Bezirke der Stadt«. Gründlich recherchiert, ordentlich gesetzt –\n'\
$'und ungefähr so spannend wie ein Verzeichnis von Verzeichnissen.\n\n'\
$'Kaum jemand kauft sie. Rachel will die Restexemplare deshalb aus\n'\
$'allen fünf Zeitungskästen zurückholen und den Inhalt löschen, damit\n'\
$'das Papier für die nächste Ausgabe reicht.\n\n'\
$'Jack kommt selbst nicht weg. Du hast den Schlüssel zu den Kästen in\n'\
$'Süden, Norden, Westen, Osten und Zentrum. Leere sie, bring ihm die\n'\
$'fünf Zeitungsbündel – und er bringt dir dafür »clear« bei.'

    # --- Nebenquest: Finde Tracey (Rachels Zeitungsausträgerin) --------
    # Nach der Baracken-Szene fragt Rachel, wo Tracey bleibt; der Agent
    # muss sie im Ostdistrikt suchen. Kein Ablehnen. Gefunden wird sie vor
    # Jimmys Haus; danach geht sie zurück in den Verlag (100 EXP).
    quest_define tracey neben "Finde Tracey" \
        $'Tracey Briggs trägt für Rachel die DailyPulse aus. Meistens.\n'\
$'Manchmal arbeitet sie im Restaurant, manchmal nimmt sie kleinere\n'\
$'Jobs an - aber heute sollte sie längst von ihrer Tour zurück sein.\n\n'\
$'Rachel hat keine Geduld für Erklärungen: Ich soll Tracey im\n'\
$'Ostdistrikt suchen, vor Jimmys Haus. Dort hat sie noch eine Übergabe.\n\n'\
$'Tracey ist keine Vermisste im Sinne der großen Liste. Sie ist\n'\
$'einfach jemand, der seine Tour nicht zu Ende gebracht hat.'

    # --- Nebenquest: Jimmys Zeitungsbote ------------------------------
    # Entsteht nach dem Fund von Tracey bei Jimmy Page im Ostdistrikt:
    # Er hat ihr 100 Bits für die seltene, langweilige Ausgabe gezahlt und
    # bietet dem Agenten 50 Bits pro neuer Ausgabe.
    quest_define jimmy neben "Jimmys Zeitungsbote" \
        $'Jimmy Page sitzt im Rollstuhl und verlässt das Haus nicht. Er\n'\
$'sammelt DailyPulse-Ausgaben, kommt aber selbst nie an die Kästen.\n\n'\
$'Normalerweise bringt Tracey ihm jede neue Ausgabe - für den\n'\
$'dreifachen Preis. Bei der aktuellen »Stadttour von Jack« hat sie\n'\
$'100 Bits verlangt, weil die Ausgabe aus dem Verkehr gezogen werden\n'\
$'soll. Jimmy hat sie gekauft. Und sich danach maßlos geärgert.\n\n'\
$'Sein Angebot: 50 Bits pro neuer Ausgabe, die ich ihm bringe.\n'\
$'Das Haus steht im Ostdistrikt.'

    # --- Nebenquest: Unterstützung für Amanda ------------------------
    # Entsteht nach der Hauptquest »Großer Ermittler« im Gespräch mit
    # Amanda Nox (Charakter/AmandaNox.sh). Sie sucht jemanden für ihre
    # angestauten Akten; den Kandidaten muss der Spieler selbst finden.
    quest_define amanda neben "Unterstützung für Amanda" \
        $'Amanda Nox führt das Vorzimmer der Detektei Holmes. Zwischen\n'\
$'Terminen, Zeugen und den Akten von Mr. Holmes wächst ihr ein\n'\
$'Stapel über den Kopf.\n\n'\
$'Sie sucht jemanden, der sie bei der angestauten Arbeit unterstützt -\n'\
$'zuverlässig, geduldig und nicht auf der Suche nach Ruhm. Jemand,\n'\
$'der Akten ernst nimmt und nicht nach einer Woche aufgibt.\n\n'\
$'Ich habe versprochen, die Augen offen zu halten. Den passenden\n'\
$'Helfer muss ich selbst finden.'

    # --- Nebenquest: Seltsame Religion ---------------------------------
    # Nach »Großer Ermittler« bietet Sherlock Holmes in der Detektei eine
    # seiner liegengebliebenen Aufgaben an: eine neue, verschlossene
    # Religion, über die es nur Gerüchte gibt – verstörend, nicht
    # ungefährlich und angeblich mit Molerats verbunden. Die Spur führt in
    # die Kneipe »Zum Goldenen Lächeln« zu Novize Bill
    # (Charakter/NovizeBill.sh).
    quest_define religion neben "Seltsame Religion" \
        $'Sherlock Holmes hat mehr Aufträge, als ihm lieb ist. Einer davon\n'\
$'ist kaum mehr als ein Gerücht: Eine relativ neue Religion soll in der\n'\
$'Stadt Fuß fassen.\n\n'\
$'Ihre Mitglieder sind verschlossen und sprechen nicht über ihren\n'\
$'Glauben. Gerüchten zufolge ist die Religion verstörend – und nicht\n'\
$'ungefährlich. Angeblich soll sie etwas mit Molerats zu tun haben.\n\n'\
$'Holmes will, dass ich mich erkundige. Er hat keinen Namen, keinen Ort\n'\
$'und keine Spur – nur das Gefühl, dass hier etwas nicht stimmt.'

    # --- Nebenquest: Stadtrundgang mit Pixi --------------------------
    # Erst nach »Großer Ermittler« (ERMITTLER_DONE) und Jacks Zeitungsquest
    # (ZEITUNG_DONE) bietet Pixi den Rundgang an. Sie führt den Agenten
    # durch alle fünf Distrikte und zurück in den DailyPulse-Verlag
    # (1000 EXP). Der Rundgang ist nur zwischen 06:00 und 14:00 möglich.
    quest_define rundgang neben "Stadtrundgang mit Pixi" \
        $'Pixis Artikel über die Root-Sperrzone ist endlich gedruckt –\n'\
$'das Papier dafür hat Jack aus den Zeitungskästen zurückgeholt.\n\n'\
$'Jetzt hat Pixi Zeit für das, was sie mir schon lange versprochen\n'\
$'hat: einen Rundgang durch die Stadt. Sie will mir die wichtigen\n'\
$'Orte und die Leute zeigen, die dort etwas zu sagen haben.\n\n'\
$'Sie macht das nur morgens oder vormittags, zwischen 06:00 und\n'\
$'14:00. Der Weg führt durch alle fünf Distrikte und endet wieder\n'\
$'im DailyPulse-Verlag. Belohnung: 1000 EXP.'

    # --- Hauptquest: Die neueste Auflage: Sperrzone -------------------
    # Am Ende des Rundgangs hat Rachel die neue Ausgabe gedruckt. Sie
    # gibt dem Agenten fünf Bündel und den Zeitungskastenschlüssel;
    # jeder der fünf Kästen wird genau einmal befüllt. Abschluss bei
    # Rachel (50 Bits, ein Exemplar, 500 EXP).
    quest_define auflage haupt "Die neueste Auflage: Sperrzone" \
        $'Pixi hat ihren Artikel über die Sperrzone geschrieben, Jack hat\n'\
$'das Papier besorgt – und Rachel hat die neue DailyPulse-Ausgabe\n'\
$'gedruckt.\n\n'\
$'Die Stadt muss sie lesen. Rachel gibt mir fünf Bündel und den\n'\
$'Zeitungskastenschlüssel: Süden, Zentrum, Osten, Norden, Westen.\n'\
$'Jeder Kasten nimmt genau ein Bündel auf, dann verkauft er die neue\n'\
$'Ausgabe.\n\n'\
$'Danach zurück zu Rachel: 50 Bits, ein Exemplar für mich und 500 EXP.\n'\
$'Wenn ich Jimmys Zeitungsboten-Quest schon habe, sollte ich ihm auch\n'\
$'eine Sperrzone-Ausgabe bringen.'

    # --- Nebenquest: Neks Beerdigung ---------------------------------
    # Entsteht nach dem Nek-Abschluss (Charakter/NeksBeerdigung.sh).
    # Die Frist hängt vom Leichenort ab; die Trauerfeier beginnt am
    # Beerdigungstag ab 16:00 automatisch auf dem Friedhof.
    quest_define nek_beerdigung neben "Neks Beerdigung" \
        $'Nek Molerat ist tot. Simon Guard setzt die Beerdigung an.\n\n'\
$'Ob die Leiche noch in der Molerathöhle liegt, zum Haupttor gebracht\n'\
$'wurde oder irgendwo anders zurückblieb, ändert den Ablauf: Wer sie\n'\
$'liegen ließ, hört erst zwei Tage später, dass sie gefunden wurde.\n\n'\
$'Am Beerdigungstag warten auf dem Friedhof Francesco, Pixi, Jack,\n'\
$'Rachel, Sherlock, der Torwächter, Simple Jon, Börty und Neks Familie.\n'\
$'Vor 16:00 erzählen sie, was sie über Nek denken (bei »lost« mit\n'\
$'deutlicher Empörung); ab 16:00 beginnt die Trauerfeier automatisch.\n'\
$'Danach ist die Quest abgeschlossen und es gibt 1000 EXP. Bis\n'\
$'Mitternacht bleiben die Gäste für kurze Nachgespräche am Grab.\n'\
$'Verpasse ich den Tag, ist die Quest gescheitert.'

    # --- Nebenquest: Neks Familie ------------------------------------
    # Simon beantwortet nach dem Nek-Abschluss die Frage nach dem
    # Nachnamen und verweist auf die Familie. Die Metzgerei folgt später.
    quest_define nek_familie neben "Neks Familie" \
        $'Simon Guard sagt, »Molerat« ist Neks echter Nachname und hängt\n'\
$'mit seiner Familiengeschichte zusammen. Die Molerats sind im großen\n'\
$'Stil in der Fleischerei und Metzgerei tätig - besonders die Molerats\n'\
$'gehören zu diesem Handwerk.\n\n'\
$'Wenn ich mehr wissen will, soll ich die Familie aufsuchen. Ihre Farm\n'\
$'liegt im Farmland in der Steppe; das Wohnhaus ist das Anwesen. Gregor,\n'\
$'Marlene und Chantal wohnen im Erdgeschoss.'

    # --- Nebenquest: Von den Molerats, für die Molerats --------------
    # Gregor Molerat im Erdgeschoss des Anwesens (Farm im Farmland)
    # braucht 120 MoleratCode. Der Agent kann 10 Stück oder alles
    # abgeben; Gregor zahlt den normalen Verkaufspreis (2 Bits je Stück)
    # und gibt 10 EXP je Stück (1200 EXP). Abschluss: 1000 EXP.
    quest_define moleratcode neben "Von den Molerats, für die Molerats" \
        $'Gregor Molerat hat immer Bedarf an MoleratCode. Aktuell braucht\n'\
$'die Familie 120 Stück – Fleisch, wie er es nennt.\n\n'\
$'Ich kann ihm 10 Stück auf einmal oder alles abgeben, was ich habe.\n'\
$'Er zahlt den normalen Verkaufspreis (2 Bits je Stück), nicht den\n'\
$'Einkaufspreis – aber jedes abgegebene Stück bringt mir 10 EXP.\n\n'\
$'Wer 120 Stück abliefert, bekommt 1000 EXP und ein Gut bei einer\n'\
$'einflussreichen Familie. Das Anwesen steht auf der Farm im Farmland;\n'\
$'Gregor wohnt im Erdgeschoss.'
}

# Status der Hauptquest aus dem Spielfortschritt.
quest_status_pixi() {
    if [ "${VERLAG_DONE:-0}" = "1" ]; then
        printf 'abgeschlossen'
    elif [ "${HOME_FIRST_VISIT:-0}" != "1" ]; then
        printf 'verborgen'
    else
        printf 'aktuell'
    fi
}
quest_goal_pixi() {
    if [ "${PIXI_HALL_DONE:-0}" = "1" ]; then
        printf 'Pixi folgen: cd Süddistrikt/DailyPulse'
    elif [ "${PIXI_GATE_DONE:-0}" = "1" ]; then
        printf 'Hinein in den Haupteingang: cd Haupteingang'
    elif [ "${PIXI_DESKTOP_DONE:-0}" = "1" ]; then
        printf 'Durch das Haupttor in DesktopCity'
    else
        printf 'Pixi nach: cd Schreibtisch'
    fi
}

# --- Quest »Aller Anfang ist schwer« (Tutorial) ----------------------
# Sichtbar ab dem ersten Moment; abgeschlossen mit dem Tutorial.
quest_status_anfang() {
    [ "${TUT_DONE:-0}" = "1" ] && printf 'abgeschlossen' || printf 'aktuell'
}
quest_goal_anfang() {
    [ "${TUT_DONE:-0}" = "1" ] && return 0
    printf 'Sprich mit dem General: cat README, dann touch README'
}
quest_entries_anfang() {
    [ "${TUT_DONE:-0}" = "1" ] && \
        printf 'Beim General: Mein Auftrag steht – und die ersten Befehle sind zurück.\n'
    return 0
}

# --- Quest »Finde Detektiv Conan« (Chefermittler) --------------------
# Verborgen, bis der Chefermittler sie vergibt (touch README).
quest_status_detektiv() {
    [ "${DETEKTIV_DONE:-0}" = "1" ] && printf 'aktuell' || printf 'verborgen'
}
quest_goal_detektiv() {
    [ "${DETEKTIV_DONE:-0}" = "1" ] || return 0
    printf 'Finde DetektivConan – sein Verbleib ist unbekannt.'
}

# --- Quest »Finde Barbar Conan« (Kriegsrat) --------------------------
# Verborgen, bis der Kriegsrat sie vergibt (touch README).
quest_status_conan() {
    [ "${CONAN_DONE:-0}" = "1" ] && printf 'aktuell' || printf 'verborgen'
}
quest_goal_conan() {
    [ "${CONAN_DONE:-0}" = "1" ] || return 0
    printf 'Finde BarbarConan – sein Verbleib ist unbekannt.'
}

# --- Quest »Großer Ermittler« (Pixis Brief) --------------------------
# Verborgen, bis Pixi den Brief übergibt. Sie läuft über Sherlock Holmes
# (Nacht im Ostdistrikt, Verfolgung, Detektei) bis zum Bericht an Pixi.
quest_status_ermittler() {
    if [ "${ERMITTLER_DONE:-0}" = "1" ]; then
        printf 'abgeschlossen'
    elif [ "${PIXI_LETTER_DONE:-0}" = "1" ]; then
        printf 'aktuell'
    else
        printf 'verborgen'
    fi
}
quest_goal_ermittler() {
    [ "${PIXI_LETTER_DONE:-0}" = "1" ] || return 0
    if [ "${ERMITTLER_DONE:-0}" = "1" ]; then
        return 0
    elif [ "${SHERLOCK_BRIEF:-0}" = "1" ]; then
        printf 'Berichte Pixi im Verlag (Süddistrikt)'
    elif [ "${SHERLOCK_NORD:-0}" = "1" ]; then
        printf 'Folge Sherlock in die Detektei (Ostdistrikt)'
    elif [ "${SHERLOCK_HUNT:-0}" = "1" ]; then
        printf 'Folge Sherlock – er wartet im Norddistrikt'
    elif [ "${BOERTY_INFO:-0}" = "1" ]; then
        printf 'Holmes nachts (22:00–04:00) im Ostdistrikt'
    elif [ "${AMANDA_DONE:-0}" = "1" ]; then
        printf 'Suche den Wirt Börty – KneipeZumGoldenenLächeln (Ostdistrikt)'
    else
        printf 'Bringe Pixis Brief zur Detektei Holmes (Ostdistrikt)'
    fi
}
quest_entries_ermittler() {
    local preis="${BOERTY_PREIS:-10}"
    [ "${PIXI_LETTER_DONE:-0}" = "1" ] && \
        printf 'Pixi hat mir einen Brief für Detektiv Sherlock Holmes mitgegeben – Detektei Holmes, Ostdistrikt.\n'
    [ "${AMANDA_DONE:-0}" = "1" ] && \
        printf 'In der Detektei: Amanda Nox führt das Büro. Sie weiß nicht genau, wo Holmes steckt – ich soll es bei Börty Smiles versuchen (Kneipe Zum Goldenen Lächeln, Ostdistrikt).\n'
    [ "${BOERTY_SH_DONE:-0}" = "1" ] && [ "${BOERTY_INFO:-0}" != "1" ] && \
        printf 'Börty hat Holmes gehört: von einem getarnten Virus in der Stadt, den er im Ostdistrikt verfolgen will – Details will er bezahlt wissen.\n'
    [ "${BOERTY_INFO:-0}" = "1" ] && \
        printf 'Börty hat mir für %s Bits verraten: Holmes ist nachts unterwegs – zwischen 22:00 und 04:00 im Ostdistrikt.\n' "$preis"
    [ "${SHERLOCK_HUNT:-0}" = "1" ] && \
        printf 'Holmes nachts im Ostdistrikt getroffen: Wir haben einen getarnten Virus verfolgt – bis eine Katze die Verfolger verraten hat. Er ist in den Norddistrikt geflohen.\n'
    [ "${SHERLOCK_NORD:-0}" = "1" ] && \
        printf 'Im Norddistrikt: Die Spur ist kalt. Holmes geht zurück in die Detektei.\n'
    [ "${SHERLOCK_BRIEF:-0}" = "1" ] && \
        printf 'In der Detektei: Ich habe Sherlock Holmes Pixis Brief übergeben. Er will, dass ich Pixi Bescheid gebe.\n'
    [ "${ERMITTLER_DONE:-0}" = "1" ] && \
        printf 'Bei Pixi im Verlag: Bericht abgegeben – sie kann ihren Artikel über die Sperrzone zu Ende schreiben. Quest abgeschlossen.\n'
    return 0
}

# --- Quest »Vermisste Bewohner« (Börtys Bitte) -----------------------
# Verborgen, bis Börty die Bitte erzählt und die Quest vergeben hat
# (quest_gain_once in Charakter/BörtySmiles.sh).
quest_status_vermisste() {
    [ "${VERMISSTE_GIVEN:-0}" = "1" ] && printf 'aktuell' || printf 'verborgen'
}
quest_goal_vermisste() {
    [ "${VERMISSTE_GIVEN:-0}" = "1" ] || return 0
    if [ "${TRACEY_GIVEN:-0}" = "1" ] && [ "${TRACEY_FOUND:-0}" != "1" ]; then
        printf 'Finde Tracey Briggs im Ostdistrikt – zuletzt vor Jimmys Haus.'
    elif [ "${TRACEY_FOUND:-0}" = "1" ] && [ "${TRACEY_DONE:-0}" != "1" ]; then
        printf 'Sag Rachel im DailyPulse-Verlag, dass Tracey gefunden ist.'
    else
        printf 'Finde heraus, wohin die Vermissten verschwinden – Börty kennt die Namen.'
    fi
}
quest_entries_vermisste() {
    [ "${VERMISSTE_GIVEN:-0}" = "1" ] && \
        printf 'Vermisste Bewohner? Was ist hier los?\n'
    [ "${TRACEY_GIVEN:-0}" = "1" ] && \
        printf 'Rachel sucht Tracey Briggs. Sie sollte längst von ihrer Zeitungstour zurück sein – zuletzt im Ostdistrikt, vor Jimmys Haus.\n'
    [ "${TRACEY_FOUND:-0}" = "1" ] && \
        printf 'Hab Tracey gefunden.\n'
    [ "${TRACEY_DONE:-0}" = "1" ] && \
        printf 'Tracey ist zurück im DailyPulse-Verlag. Rachel hat sich bedankt.\n'
    [ "${MITCH_GIVEN:-0}" = "1" ] && \
        printf 'Michael Mitch, der Gehilfe von Börty, ist verschwunden.\n'
    [ "${MITCH_TALKED:-0}" = "1" ] && \
        printf 'Mitch ist aufgetaucht. Ich habe ihn im Restaurant im Westdistrikt getroffen – er arbeitet dort und will nicht zu Börty zurück.\n'
    [ "${MITCH_DONE:-0}" = "1" ] && \
        printf 'Börty weiß jetzt Bescheid: Mitch kommt nicht zurück. Dafür braucht Börty einen neuen Gehilfen.\n'
    [ "${BOERTY_VERMISSTE_INFO:-0}" = "1" ] && \
        printf 'Börty: Seit Monaten verschwinden Leute – Detektiv Sherlock Holmes arbeitet an dem Fall.\n'
    [ "${SAMY_VERMISSTE_INFO:-0}" = "1" ] && \
        printf 'Samy Cage: Auch im Lager hört man davon. Leute kommen nicht wieder – mehr weiß er nicht.\n'
    [ "${SIMON_NEK_INFO:-0}" = "1" ] && \
        printf 'Simon Guard: Auch sein Freund Nek Molerat ist verschwunden – seit Tagen fehlt jede Spur.\n'
    return 0
}

# --- Quest »Michael Mitch. Vermisst« (Börtys Lagergehilfe) -----------
# Verborgen, bis der Agent am Ende der Bierlieferung nach Mitch fragt
# (Charakter/BörtySmiles.sh, boerty_mitch_scene). Danach: der Hinweis
# des Lagermeisters (SAMY_MITCH_INFO) führt in den Westdistrikt.
quest_status_mitch() {
    if [ "${MITCH_DONE:-0}" = "1" ]; then
        printf 'abgeschlossen'
    elif [ "${MITCH_GIVEN:-0}" = "1" ]; then
        printf 'aktuell'
    else
        printf 'verborgen'
    fi
}
quest_goal_mitch() {
    [ "${MITCH_DONE:-0}" = "1" ] && return 0
    [ "${MITCH_GIVEN:-0}" = "1" ] || return 0
    if [ "${MITCH_TALKED:-0}" = "1" ]; then
        printf 'Geh zu Börty in die Kneipe (Ostdistrikt) und erzähle ihm von Mitch'
    elif [ "${SAMY_MITCH_INFO:-0}" = "1" ]; then
        printf 'Frage im Westdistrikt nach Michael Mitch'
    else
        printf 'Finde heraus, wo Michael Mitch geblieben ist – frag dich durch die Stadt'
    fi
}
quest_entries_mitch() {
    [ "${MITCH_GIVEN:-0}" = "1" ] && \
        printf 'Börty: Michael Mitch ist vor ein paar Tagen verschwunden. Er hat keine Ahnung, wo er steckt – ich soll mich melden, wenn ich etwas höre.\n'
    [ "${SAMY_MITCH_INFO:-0}" = "1" ] && \
        printf 'Samy Cage hat Michael manchmal im Westdistrikt gesehen – bei den alten Ladenzeilen. Dort soll ich nach ihm fragen.\n'
    [ "${MITCH_TALKED:-0}" = "1" ] && \
        printf 'Im Restaurant im Westdistrikt: Mitch ist aufgetaucht. Er will nicht mehr für Börty arbeiten – der Lohn sei zu schlecht, und er hatte Angst, es ihm persönlich zu sagen. Ich soll Börty Bescheid geben.\n'
    [ "${MITCH_DONE:-0}" = "1" ] && \
        printf 'Börty habe ich es erzählt. Mitch kommt nicht zurück. Börty braucht jetzt einen neuen Gehilfen – ich soll mich umsehen.\n'
    return 0
}

# --- Quest »Wo ist Nek Molerat?« (Simon Guard & Simple Jon) -----------
# Verborgen, bis Simon Guard sie im Haupttor-Gespräch vergibt
# (SIMON_NEK_INFO, NEK_GIVEN). Simple Jon im Wachhaus ergänzt den
# Verlauf (JON_NEK_INFO) - ausdrücklich nur hier, nicht in der
# Hauptquest »Vermisste Bewohner«.
quest_status_nek() {
    if [ "${NEK_DONE:-0}" = "1" ]; then
        printf 'abgeschlossen'
    elif [ "${NEK_GIVEN:-0}" = "1" ]; then
        printf 'aktuell'
    else
        printf 'verborgen'
    fi
}
quest_goal_nek() {
    [ "${NEK_GIVEN:-0}" = "1" ] || return 0
    if [ "${NEK_DONE:-0}" = "1" ]; then
        printf 'Nek ist gefunden. Simon Guard weiß jetzt, was mit seinem Freund passiert ist.'
    elif [ "${NEK_MUST_SEARCH:-0}" = "1" ]; then
        printf 'Geh zurück in die Molerathöhle und durchsuche Neks Leiche.'
    elif [ "${NEK_FOUND:-0}" = "1" ]; then
        printf 'Berichte Simon Guard am Haupttor von Nek. Bring ihm die Leiche oder das Amulett.'
    elif [ "${JON_NEK_INFO:-0}" = "1" ]; then
        printf 'Weitere Hinweise sammeln – Nek hat die Stadt verlassen, um etwas zu erledigen.'
    else
        printf 'Frag Simple Jon im Wachhaus (Haupteingang) nach Nek Molerat.'
    fi
}
quest_entries_nek() {
    [ "${SIMON_NEK_INFO:-0}" = "1" ] && \
        printf 'Simon Guard: Nek Molerat ist seit Tagen verschwunden. Niemand weiß, wo er ist.\n'
    [ "${JON_NEK_INFO:-0}" = "1" ] && \
        printf 'Simple Jon: Nek ist Stadtwache und mit Simon Guard befreundet. Er hat die Stadt verlassen, um etwas zu erledigen – seitdem fehlt jede Spur.\n'
    [ "${NEK_FOUND:-0}" = "1" ] && \
        printf 'Hab Nek gefunden. Lag tot in einer Höhle\n'
    [ "${NEK_MUST_SEARCH:-0}" = "1" ] && \
        printf 'Simon Guard: Geh zurück und durchsuche ihn. Komm dann wieder.\n'
    [ "${NEK_CORPSE_BROUGHT:-0}" = "1" ] && \
        printf 'Ich habe Neks Leiche zu Simon Guard gebracht.\n'
    [ "${NEK_SIMON_SEARCHED:-0}" = "1" ] && \
        printf 'Simon Guard hat Nek selbst durchsucht und dabei das Amulett gefunden.\n'
    [ "${NEK_AMULET_SOLD:-0}" = "1" ] && \
        printf 'Simon Guard: Ich habe ihm Neks Amulett für 150 Bits verkauft.\n'
    [ "${NEK_AMULET_KEPT:-0}" = "1" ] && \
        printf 'Ich behalte Neks Amulett. Simon Guard weiß jetzt, was mit Nek passiert ist.\n'
    [ "${NEK_DONE:-0}" = "1" ] && \
        printf 'Simon Guard hat Gewissheit. Die Suche nach Nek Molerat ist abgeschlossen.\n'
    return 0
}

# --- Quest »Neks Beerdigung« (getimte Folgequest) --------------------
# Entsteht nach dem Abschluss von »Wo ist Nek Molerat?«. Je nachdem, wo
# die Leiche liegt, wird die Beerdigung fünf Tage später angesetzt; bei
# einer zurückgelassenen Leiche kommt der Fund nach zwei Tagen dazwischen.
# Ab 16:00 startet die Trauerfeier automatisch, sobald der Agent auf dem
# Friedhof ist. Abschluss: 1000 EXP.
quest_status_nek_beerdigung() {
    if [ "${NEK_FUNERAL_FAILED:-0}" = "1" ]; then
        printf 'gescheitert'
    elif [ "${NEK_FUNERAL_DONE:-0}" = "1" ]; then
        printf 'abgeschlossen'
    elif [ "${NEK_FUNERAL_GIVEN:-0}" = "1" ]; then
        printf 'aktuell'
    else
        printf 'verborgen'
    fi
}
quest_goal_nek_beerdigung() {
    [ "${NEK_FUNERAL_GIVEN:-0}" = "1" ] || return 0
    [ "${NEK_FUNERAL_DONE:-0}" = "1" ] && return 0
    [ "${NEK_FUNERAL_FAILED:-0}" = "1" ] && return 0

    local date="unbekannt"
    declare -F nek_funeral_date_text >/dev/null 2>&1 && \
        date="$(nek_funeral_date_text)"
    [ -n "$date" ] || date="unbekannt"
    printf 'Geh am %s um 16:00 zum Friedhof (Schreibtisch/Brachland/Friedhof)' "$date"
}
quest_entries_nek_beerdigung() {
    local date="unbekannt" disc="unbekannt"
    declare -F nek_funeral_date_text >/dev/null 2>&1 && \
        date="$(nek_funeral_date_text)"
    [ -n "$date" ] || date="unbekannt"

    if [ "${NEK_FUNERAL_GIVEN:-0}" = "1" ]; then
        case "${NEK_FUNERAL_DISPOSITION:-}" in
            cave)
                printf 'Simon Guard schickt jemanden in die Molerathöhle. Er holt Nek und übergibt ihn dem Totengräber.\n'
                ;;
            simon)
                printf 'Ich habe Neks Leiche zum Haupttor gebracht. Simon Guard übergibt sie dem Totengräber.\n'
                ;;
            lost)
                if [ "${NEK_FUNERAL_FOUND:-0}" = "1" ]; then
                    printf 'Neks Leiche wurde in der Welt gefunden. Der Totengräber kümmert sich um sie.\n'
                else
                    if [ "${NEK_FUNERAL_DISCOVERY_DAY:--1}" -ge 0 ] 2>/dev/null && \
                       declare -F cal_date_text_for_day >/dev/null 2>&1; then
                        disc="$(cal_date_text_for_day "${NEK_FUNERAL_DISCOVERY_DAY}")"
                    fi
                    printf 'Ich habe Nek gefunden, aber seine Leiche liegen lassen. Sie wird am %s gefunden.\n' "$disc"
                fi
                printf 'Die Stadt redet darüber, dass ich die Leiche einfach vergammeln ließ.\n'
                ;;
        esac
        printf 'Beerdigung: %s um 16:00 auf dem Friedhof.\n' "$date"
    fi

    [ "${NEK_FUNERAL_DONE:-0}" = "1" ] && \
        printf 'Ich war auf Neks Beerdigung. Nek Molerat ist nicht allein geblieben.\n'
    [ "${NEK_FUNERAL_FAILED:-0}" = "1" ] && \
        printf 'Ich habe Neks Beerdigung verpasst.\n'
    return 0
}

# --- Quest »Neks Familie« (Folgequest nach dem Nek-Gespräch) ---------
# Simon erklärt, dass »Molerat« Neks Nachname ist und mit seiner Familie
# zusammenhängt. Die Familie lebt auf der Farm im Farmland der Steppe.
quest_status_nek_familie() {
    [ "${NEK_FAMILY_GIVEN:-0}" = "1" ] && printf 'aktuell' || printf 'verborgen'
}
quest_goal_nek_familie() {
    [ "${NEK_FAMILY_GIVEN:-0}" = "1" ] || return 0
    printf 'Such die Familie von Nek Molerat'
}
quest_entries_nek_familie() {
    [ "${NEK_FAMILY_GIVEN:-0}" = "1" ] || return 0
    printf 'Simon Guard: »Molerat« ist Neks Nachname. Das hat auch mit seiner Familiengeschichte zu tun.\n'
    printf 'Die Molerats sind im großen Stil in der Fleischerei und Metzgerei tätig. Besonders die Molerats gehören zu ihrem Handwerk.\n'
    printf 'Wenn ich mehr erfahren will, soll ich die Familie aufsuchen. Ihre Farm liegt im Farmland in der Steppe, das Wohnhaus ist das Anwesen.\n'
    return 0
}

# --- Quest »Von den Molerats, für die Molerats« ----------------------
# Gregor Molerat im Erdgeschoss des Anwesens. Er braucht 120
# MoleratCode; die Abgabe läuft über sein Gespräch (Charakter/
# MoleratFamilie.sh). Der Fortschritt steckt in GREGOR_CODE_*.
quest_status_moleratcode() {
    if [ "${GREGOR_CODE_DONE:-0}" = "1" ]; then
        printf 'abgeschlossen'
    elif [ "${GREGOR_CODE_GIVEN:-0}" = "1" ]; then
        printf 'aktuell'
    else
        printf 'verborgen'
    fi
}

quest_goal_moleratcode() {
    local remaining
    [ "${GREGOR_CODE_GIVEN:-0}" = "1" ] || return 0
    [ "${GREGOR_CODE_DONE:-0}" = "1" ] && return 0
    remaining="$(( 120 - ${GREGOR_CODE_DELIVERED:-0} ))"
    [ "$remaining" -lt 0 ] && remaining=0
    if [ "$remaining" -le 0 ]; then
        printf 'Sprich mit Gregor Molerat im Anwesen (Farm, Erdgeschoss)'
    elif [ "$(inv_count moleratcode 2>/dev/null || printf '0')" -ge "$remaining" ]; then
        printf 'Bringe Gregor noch %s MoleratCode ins Anwesen (Erdgeschoss)' "$remaining"
    else
        printf 'Sammle MoleratCode für Gregor – noch %s von 120 Stück (Anwesen, Erdgeschoss)' "$remaining"
    fi
}

quest_entries_moleratcode() {
    local delivered="${GREGOR_CODE_DELIVERED:-0}"
    case "$delivered" in ''|*[!0-9]*) delivered=0 ;; esac
    [ "${GREGOR_CODE_GIVEN:-0}" = "1" ] && \
        printf 'Gregor Molerat: Die Familie hat immer Bedarf an MoleratCode – aktuell 120 Stück. Er zahlt den normalen Verkaufspreis, dafür gibt es 10 EXP pro Stück.\n'
    [ "${GREGOR_CODE_GIVEN:-0}" = "1" ] && [ "$delivered" -gt 0 ] && \
        printf 'Bei Gregor abgegeben: %s von 120 MoleratCode.\n' "$delivered"
    [ "${GREGOR_CODE_DONE:-0}" = "1" ] && \
        printf 'Alle 120 MoleratCode abgegeben. Gregor hat sich bedankt – die Familie vergisst so etwas nicht. Quest abgeschlossen: 1000 EXP.\n'
    return 0
}

# --- Quest »Ein neuer Gehilfe für Börty« -----------------------------
# Entsteht am Ende von »Michael Mitch. Vermisst« (MITCH_DONE,
# Charakter/BörtySmiles.sh, boerty_mitch_return_scene).
quest_status_gehilfe() {
    [ "${GEHILFE_GIVEN:-0}" = "1" ] && printf 'aktuell' || printf 'verborgen'
}
quest_goal_gehilfe() {
    [ "${GEHILFE_GIVEN:-0}" = "1" ] || return 0
    printf 'Halte Ausschau nach einem neuen Gehilfen für Börty'
}
quest_entries_gehilfe() {
    [ "${GEHILFE_GIVEN:-0}" = "1" ] && \
        printf 'Börty: Mitch lässt ihn sitzen, und er kann die Kneipe nicht verlassen. Er braucht einen neuen Gehilfen. Ich habe versprochen, mich umzusehen – ohne Garantie.\n'
    return 0
}

# --- Quest »Bier für Börty« (Lieferung vom Marktplatz) ---------------
# Verborgen, bis der Agent den Auftrag bei Börty ANNIMMT (BIER_GIVEN).
# Danach: erst die Kiste beim Lagermeister holen (BIER_TAKEN), dann bei
# Börty abgeben - damit ist die Quest abgeschlossen (BIER_DONE).
# Geht die Kiste verloren, läuft eine 24-Stunden-Frist (BIER_LOST_AT);
# danach scheitert die Quest beim Wirt (BIER_FAILED).
quest_status_bier() {
    if [ "${BIER_FAILED:-0}" = "1" ]; then
        printf 'gescheitert'
    elif [ "${BIER_DONE:-0}" = "1" ]; then
        printf 'abgeschlossen'
    elif [ "${BIER_GIVEN:-0}" = "1" ]; then
        printf 'aktuell'
    else
        printf 'verborgen'
    fi
}
quest_goal_bier() {
    [ "${BIER_DONE:-0}" = "1" ] && return 0     # erledigt: kein Ziel mehr
    [ "${BIER_FAILED:-0}" = "1" ] && return 0   # gescheitert: kein Ziel mehr
    [ "${BIER_GIVEN:-0}" = "1" ] || return 0
    if [ "${BIER_TAKEN:-0}" = "1" ]; then
        printf 'Bring »Börtys Bierlieferung« zurück: Börty Smiles, Kneipe (Ostdistrikt)'
    else
        printf 'Hol die Lieferung: Lagermeister Samy Cage, Lager am Marktplatz (Zentrum)'
    fi
}
quest_entries_bier() {
    [ "${BIER_GIVEN:-0}" = "1" ] && \
        printf 'Börty hat mir 250 Bits für die Lieferung mitgegeben: Ich soll beim Lagermeister Samy Cage am Marktplatz im Zentrum sein Bier abholen. Geht die Kiste verloren, bleiben mir 24 Spielstunden für Ersatz.\n'
    [ "${BIER_TAKEN:-0}" = "1" ] && \
        printf 'Bei Samy Cage im Lager: 250 Bits bezahlt, die Kiste eingepackt. »Lass die Flaschen bloß nicht fallen.«\n'
    [ "${BIER_LOST_AT:--1}" -ge 0 ] 2>/dev/null && \
        [ "${BIER_DONE:-0}" != "1" ] && [ "${BIER_FAILED:-0}" != "1" ] && \
        printf 'Die Kiste ist weg. Samy gibt gegen 250 Bits Ersatz – aber nur, solange Börty noch wartet.\n'
    [ "${BIER_FAILED:-0}" = "1" ] && \
        printf 'Börty hat die Lieferung abgeschrieben: Die Kiste kam nicht an. Die Quest ist gescheitert.\n'
    [ "${BIER_DONE:-0}" = "1" ] && \
        printf 'Bei Börty abgeliefert: 100 EXP und 30 Bits. Ein Problem gelöst – bleibt nur noch herauszufinden, wo Mitch abgeblieben ist.\n'
    return 0
}

# --- Quest »Ein Dach über dem Kopf« ---------------------------------
# Nebenquest: sichtbar, sobald das Familiengespräch im Verlag gelaufen ist.
# Abgeschlossen, sobald Pixi die Baracke wieder verlässt (und der Agent
# dort sein Nachtlager hat).
quest_status_nachtlager() {
    if [ "${BARACKE_SCENE_DONE:-0}" = "1" ]; then
        printf 'abgeschlossen'
    elif [ "${VERLAG_DONE:-0}" = "1" ]; then
        printf 'aktuell'
    else
        printf 'verborgen'
    fi
}
quest_goal_nachtlager() {
    [ "${VERLAG_DONE:-0}" = "1" ] || return 0
    [ "${BARACKE_SCENE_DONE:-0}" = "1" ] && return 0
    if [ "${PIXI_GUIDE_DONE:-0}" = "1" ]; then
        printf 'Pixi folgen: cd EingestürzteBaracke'
    else
        printf 'Verlasse den Verlag – Pixi wartet im Süddistrikt: cd ..'
    fi
}
quest_entries_nachtlager() {
    [ "${VERLAG_DONE:-0}" = "1" ] && \
        printf 'Im Verlag DailyPulse: Rachel lässt mich nicht übernachten – sie schickt mich in die eingestürzte Baracke.\n'
    [ "${PIXI_GUIDE_DONE:-0}" = "1" ] && \
        printf 'Pixi hat sich entschuldigt und ist in die Baracke vorausgegangen.\n'
    [ "${BARACKE_SCENE_DONE:-0}" = "1" ] && \
        printf 'Die Baracke ist mein Nachtlager. Pixi hat mir »grep« beigebracht (Fundstücke herausziehen) und ist zurück zum Verlag.\n'
    [ "${BARACKE_SCENE_DONE:-0}" = "1" ] && \
        printf 'Hier in dieser Bruchbude habe ich erstmal einen dauerhaften Schlafplatz.\n'
    return 0
}

# --- Quest »Die langweiligste Ausgabe« (Jacks Zeitungskästen) --------
# Verborgen, bis Jack sie nach der Baracken-Szene anbietet und der Agent
# annimmt (ZEITUNG_GIVEN). Abgeschlossen, wenn alle fünf Bündel bei Jack
# abgegeben und die drei Stunden vergangen sind (ZEITUNG_DONE).
quest_status_zeitung() {
    if [ "${ZEITUNG_DONE:-0}" = "1" ]; then
        printf 'abgeschlossen'
    elif [ "${ZEITUNG_GIVEN:-0}" = "1" ]; then
        printf 'aktuell'
    else
        printf 'verborgen'
    fi
}

# Zählt die geleerten Kästen direkt aus der Bitmaske - unabhängig davon,
# ob das Interior-Modul gerade geladen ist.
_quest_zeitung_boxes() {
    local i n=0
    for i in 0 1 2 3 4; do
        [ $(( ${ZEITUNG_EMPTIED:-0} & (1 << i) )) -ne 0 ] && n=$(( n + 1 ))
    done
    printf '%s' "$n"
}

quest_goal_zeitung() {
    local n bundles
    [ "${ZEITUNG_DONE:-0}" = "1" ] && return 0
    [ "${ZEITUNG_GIVEN:-0}" = "1" ] || return 0
    n="$(_quest_zeitung_boxes)"
    bundles="$(inv_count zeitungsbuendel 2>/dev/null || printf '0')"
    if [ "$n" -ge 5 ] 2>/dev/null && [ "$bundles" -ge 5 ] 2>/dev/null; then
        printf 'Bring die fünf Zeitungsbündel zu Jack: DailyPulse-Verlag (Süddistrikt)'
    else
        printf 'Leere die Zeitungskästen in den fünf Bezirken (use Zeitungskasten) – noch %s offen.' \
            "$(( 5 - n ))"
    fi
}

quest_entries_zeitung() {
    local i n=0 labels=(Süddistrikt Norddistrikt Westdistrikt Ostdistrikt Zentrum)
    [ "${ZEITUNG_GIVEN:-0}" = "1" ] && \
        printf 'Jack hat mir den Zeitungskastenschlüssel gegeben: Ich soll die Restexemplare von »Bezirke der Stadt« aus allen fünf Kästen holen.\n'
    for i in 0 1 2 3 4; do
        if [ $(( ${ZEITUNG_EMPTIED:-0} & (1 << i) )) -ne 0 ]; then
            n=$(( n + 1 ))
            printf 'Zeitungskasten im %s geleert (%s/5).\n' "${labels[$i]}" "$n"
        fi
    done
    if [ "${ZEITUNG_GIVEN:-0}" = "1" ] && [ "${ZEITUNG_DONE:-0}" != "1" ] && [ "$n" -ge 5 ]; then
        printf 'Alle fünf Zeitungskästen sind leer. Die fünf Bündel müssen zu Jack in den DailyPulse-Verlag.\n'
    fi
    [ "${ZEITUNG_DONE:-0}" = "1" ] && \
        printf 'Jack hat den Inhalt gelöscht und das Papier behalten. Quest abgeschlossen: 200 EXP.\n'
    return 0
}

# --- Quest »Finde Tracey« (Rachels Zeitungsausträgerin) --------------
# Verborgen, bis Rachel sie nach der Baracken-Szene vergibt
# (Charakter/verlag.sh, TRACEY_GIVEN). Gefunden wird Tracey vor Jimmys
# Haus (TRACEY_FOUND); der Abschluss passiert bei Rachel im Verlag
# (TRACEY_DONE, 100 EXP).
quest_status_tracey() {
    if [ "${TRACEY_DONE:-0}" = "1" ]; then
        printf 'abgeschlossen'
    elif [ "${TRACEY_GIVEN:-0}" = "1" ]; then
        printf 'aktuell'
    else
        printf 'verborgen'
    fi
}
quest_goal_tracey() {
    [ "${TRACEY_DONE:-0}" = "1" ] && return 0
    [ "${TRACEY_GIVEN:-0}" = "1" ] || return 0
    if [ "${TRACEY_FOUND:-0}" = "1" ]; then
        printf 'Geh zurück zu Rachel in den DailyPulse-Verlag (Süddistrikt)'
    else
        printf 'Finde Tracey Briggs im Ostdistrikt – vor Jimmys Haus'
    fi
}
quest_entries_tracey() {
    [ "${TRACEY_GIVEN:-0}" = "1" ] && \
        printf 'Rachel: Tracey Briggs ist auf ihrer Zeitungstour nicht zurückgekommen. Ich soll sie im Ostdistrikt suchen – vor Jimmys Haus.\n'
    [ "${TRACEY_FOUND:-0}" = "1" ] && \
        printf 'Hab Tracey gefunden. Sie hat Jimmy gerade die aktuelle Ausgabe verkauft und macht sich auf den Weg zu Rachel.\n'
    [ "${TRACEY_DONE:-0}" = "1" ] && \
        printf 'Tracey ist wieder im DailyPulse-Verlag. Rachel hat sich bedankt. Quest abgeschlossen: 100 EXP.\n'
    return 0
}

# --- Quest »Jimmys Zeitungsbote« -------------------------------------
# Entsteht nach dem Fund von Tracey bei Jimmy Page; bleibt offen, bis
# eine neue Edition erscheint (50 Bits je Ausgabe).
quest_status_jimmy() {
    [ "${JIMMY_GIVEN:-0}" = "1" ] && printf 'aktuell' || printf 'verborgen'
}
quest_goal_jimmy() {
    [ "${JIMMY_GIVEN:-0}" = "1" ] || return 0
    if [ "${AUFLAGE_DONE:-0}" = "1" ] && [ "${JIMMY_LAST_SOLD:-}" != "sperrzone" ]; then
        printf 'Bringe Jimmy Page die Sperrzone-Ausgabe – er verhandelt den Preis (JimmysHaus, Ostdistrikt)'
    else
        printf 'Bringe Jimmy Page neue DailyPulse-Ausgaben – 50 Bits je Ausgabe (JimmysHaus, Ostdistrikt)'
    fi
}
quest_entries_jimmy() {
    [ "${TRACEY_FOUND:-0}" = "1" ] && \
        printf 'Jimmy hat Tracey 100 Bits für die langweilige »Stadttour von Jack« gezahlt – viel zu viel, wie er findet.\n'
    [ "${JIMMY_GIVEN:-0}" = "1" ] && \
        printf 'Jimmy zahlt mir 50 Bits je neuer DailyPulse-Ausgabe (einmal pro Edition). Er verlässt das Haus nicht und ist auf Boten angewiesen.\n'
    if [ "${JIMMY_GIVEN:-0}" = "1" ] && [ "${AUFLAGE_DONE:-0}" = "1" ] \
       && [ "${JIMMY_LAST_SOLD:-}" = "sperrzone" ]; then
        printf 'Hab Jimmy die Sperrzone-Ausgabe gebracht. Die Quest bleibt offen – die nächste Ausgabe kommt bestimmt.\n'
    elif [ "${AUFLAGE_DONE:-0}" = "1" ] && [ "${JIMMY_GIVEN:-0}" = "1" ]; then
        printf 'Ich sollte Jimmy die Sperrzone-Ausgabe bringen.\n'
    fi
    return 0
}

# --- Quest »Unterstützung für Amanda« --------------------------------
# Verborgen, bis Amanda sie nach »Großer Ermittler« vergibt
# (Charakter/AmandaNox.sh, AMANDA_HELP_GIVEN). Jack zieht für die Hilfe
# in die Detektei um (AMANDA_HELP_JACK); bei Amanda endet sie mit 200 EXP
# (AMANDA_HELP_DONE).
quest_status_amanda() {
    if [ "${AMANDA_HELP_DONE:-0}" = "1" ]; then
        printf 'abgeschlossen'
    elif [ "${AMANDA_HELP_GIVEN:-0}" = "1" ]; then
        printf 'aktuell'
    else
        printf 'verborgen'
    fi
}

quest_goal_amanda() {
    [ "${AMANDA_HELP_DONE:-0}" = "1" ] && return 0
    [ "${AMANDA_HELP_GIVEN:-0}" = "1" ] || return 0
    if [ "${AMANDA_HELP_JACK:-0}" = "1" ]; then
        printf 'Sprich mit Amanda Nox in der Detektei Holmes (Ostdistrikt)'
    elif [ "${ZEITUNG_DONE:-0}" = "1" ]; then
        printf 'Frag Jack Nullpunkt im DailyPulse-Verlag, ob er Amanda jetzt helfen kann'
    elif [ "${AMANDA_HELP_ASKED:-0}" = "1" ]; then
        printf 'Schließe Jacks Quest »Die langweiligste Ausgabe« ab und frag ihn danach noch einmal'
    else
        printf 'Suche jemanden, der Amanda bei den Akten helfen kann – frag dich durch die Stadt'
    fi
}

quest_entries_amanda() {
    [ "${AMANDA_HELP_GIVEN:-0}" = "1" ] && \
        printf 'Amanda Nox ertrinkt in Akten. Ich soll jemanden finden, der sie bei der angestauten Arbeit unterstützt – zuverlässig, geduldig und ohne Ruhmsucht.\n'
    [ "${AMANDA_HELP_ASKED:-0}" = "1" ] && [ "${ZEITUNG_DONE:-0}" != "1" ] && \
        printf 'Jack Nullpunkt würde Amanda gern helfen, muss aber erst die langweilige Ausgabe aus dem Verkehr ziehen. Danach hätte er Zeit.\n'
    [ "${ZEITUNG_DONE:-0}" = "1" ] && [ "${AMANDA_HELP_JACK:-0}" != "1" ] && \
        printf 'Jacks Zeitungsausgabe ist erledigt. Jetzt hätte er Zeit für Amanda – ich muss ihn nur noch einmal fragen.\n'
    [ "${AMANDA_HELP_JACK:-0}" = "1" ] && \
        printf 'Jack ist in die Detektei Holmes gewechselt und arbeitet jetzt mit Amanda an den Akten.\n'
    [ "${AMANDA_HELP_DONE:-0}" = "1" ] && \
        printf 'Amanda hat sich bedankt: Jack war eine gute Wahl, der Berg an Akten wird kleiner. Quest abgeschlossen: 200 EXP.\n'
    return 0
}

# --- Quest »Seltsame Religion« --------------------------------------
# Holmes vergibt sie nach »Großer Ermittler«. Sie bleibt aktuell, bis der
# Agent den Molerats folgt und mehr über den verschwundenen Priester
# erfährt; Novize Bill liefert nach einem Bier den ersten Hinweis.
quest_status_religion() {
    if [ "${RELIGION_GIVEN:-0}" = "1" ]; then
        printf 'aktuell'
    else
        printf 'verborgen'
    fi
}

quest_goal_religion() {
    [ "${RELIGION_GIVEN:-0}" = "1" ] || return 0
    if [ "${SHERLOCK_BOOK_DONE:-0}" = "1" ]; then
        printf 'Folge der Spur des SchweinePriesters und den Molerats in die Tiefe'
    elif [ "${TAGEBUCH_FOUND:-0}" = "1" ]; then
        printf 'Zeige das Tagebuch Novize Bill (Kneipe, Ostdistrikt) und Sherlock Holmes (Detektei)'
    elif [ "${BILL_TOLD:-0}" = "1" ]; then
        printf 'Folge den Molerats und finde den verschwundenen Priester der MoleratAnhänger'
    elif [ "${BILL_MET:-0}" = "1" ]; then
        printf 'Novize Bill in der Kneipe »Zum Goldenen Lächeln« (Ostdistrikt) wirkt verschlossen – vielleicht hilft ein Bier'
    else
        printf 'Erkundige dich in der Kneipe »Zum Goldenen Lächeln« (Ostdistrikt) nach der seltsamen Religion'
    fi
}

quest_entries_religion() {
    if [ "${RELIGION_BOOK_FIRST:-0}" = "1" ]; then
        printf 'In der KöniginnenKammer habe ich das Tagebuch eines SchweinePriesters gefunden. Die Spur zur seltsamen Religion beginnt bei seinen Aufzeichnungen.\n'
    elif [ "${RELIGION_GIVEN:-0}" = "1" ]; then
        printf 'Holmes hat mir von einer neuen, verschlossenen Religion erzählt: verstörend, nicht ungefährlich und angeblich mit Molerats verbunden.\n'
    fi
    [ "${TAGEBUCH_FOUND:-0}" = "1" ] && [ "${RELIGION_BOOK_FIRST:-0}" != "1" ] && \
        printf 'In der KöniginnenKammer habe ich das »SchweinePriester'\''s Tagebuch« gefunden – eine neue Spur zur seltsamen Religion.\n'
    [ "${TAGEBUCH_READ:-0}" = "1" ] && \
        printf 'Im Tagebuch beschreibt der SchweinePriester Forschungen über Molerats und eine verlorene Molerat-Zivilisation, die den Dateien ebenbürtig war und spurlos verschwand.\n'
    [ "${BILL_MET:-0}" = "1" ] && [ "${BILL_TOLD:-0}" != "1" ] && \
        printf 'In der Kneipe sitzt Novize Bill. Er gehört einer seltenen Religion an, nennt sie aber nicht und trauert um seinen verschwundenen Meister, einen Priester.\n'
    [ "${BILL_TOLD:-0}" = "1" ] && \
        printf 'Bill hat nach einem Bier gestanden: Er ist Teil der MoleratAnhänger. Die Religion dreht sich um eine Molerat-Königin und einen Priester, der mit ihr sprechen kann. Der Priester ist verschwunden.\n'
    [ "${BILL_TOLD:-0}" = "1" ] && \
        printf 'Bill bittet mich, ihm Bescheid zu geben, falls ich etwas über den Priester erfahre. Um mehr zu erfahren, muss ich den Molerats folgen.\n'
    [ "${BILL_BOOK_DONE:-0}" = "1" ] && \
        printf 'Novize Bill ist beim Anblick des Tagebuchs fast ausgeflippt: Es ist ein heiliges Buch der MoleratAnhänger. Der SchweinePriester könnte noch am Leben sein.\n'
    [ "${SHERLOCK_BOOK_DONE:-0}" = "1" ] && \
        printf 'Sherlock Holmes war verblüfft und belustigt über das Tagebuch – dann wieder ganz Detektiv. Ich soll der Spur weiter folgen.\n'
    [ "${GREGOR_BOOK_DONE:-0}" = "1" ] && \
        printf 'Gregor Molerat redet ungern über das Tagebuch: Seine Familie hat nichts mit der seltsamen Religion zu tun. Er weiß nur, dass es in DesktopCity Vertreter gibt, die Molerats anbeten.\n'
    return 0
}

# --- Quest »Stadtrundgang mit Pixi« ---------------------------------
# Verborgen, bis Pixi den Rundgang nach beiden Vorquests anbietet und der
# Agent zusagt (RUNDGANG_GIVEN). Abgeschlossen, sobald beide wieder im
# DailyPulse-Verlag stehen (RUNDGANG_DONE, 1000 EXP).
quest_status_rundgang() {
    if [ "${RUNDGANG_DONE:-0}" = "1" ]; then
        printf 'abgeschlossen'
    elif [ "${RUNDGANG_GIVEN:-0}" = "1" ]; then
        printf 'aktuell'
    else
        printf 'verborgen'
    fi
}

quest_goal_rundgang() {
    [ "${RUNDGANG_DONE:-0}" = "1" ] && return 0
    [ "${RUNDGANG_GIVEN:-0}" = "1" ] || return 0
    printf 'Sprich mit Pixi im DailyPulse-Verlag (Süddistrikt) – zwischen 06:00 und 14:00'
}

quest_entries_rundgang() {
    [ "${RUNDGANG_GIVEN:-0}" = "1" ] && \
        printf 'Pixi will mir die Stadt zeigen. Wir treffen uns im DailyPulse-Verlag, solange es noch Morgen ist (06:00–14:00).\n'
    [ "${RUNDGANG_GIVEN:-0}" = "1" ] && [ "${RUNDGANG_DONE:-0}" != "1" ] && \
        printf 'Der Rundgang führt vom Süddistrikt ins Zentrum, dann nach Osten, Norden und Westen – und wieder zurück in den Verlag.\n'
    [ "${RUNDGANG_DONE:-0}" = "1" ] && \
        printf 'Rundgang beendet: Pixi hat mir die wichtigsten Orte und Leute gezeigt. Quest abgeschlossen: 1000 EXP.\n'
    return 0
}

# --- Quest »Die neueste Auflage: Sperrzone« -------------------------
# Rachels Hauptquest nach dem Rundgang. Fünf Bündel, fünf Kästen; die
# Bitmaske zählt, wie viele Kästen noch leer sind.
quest_status_auflage() {
    if [ "${AUFLAGE_DONE:-0}" = "1" ]; then
        printf 'abgeschlossen'
    elif [ "${AUFLAGE_GIVEN:-0}" = "1" ]; then
        printf 'aktuell'
    else
        printf 'verborgen'
    fi
}

_quest_auflage_boxes() {
    local i n=0
    for i in 0 1 2 3 4; do
        [ $(( ${ZEITUNG_EMPTIED:-0} & (1 << i) )) -eq 0 ] && n=$(( n + 1 ))
    done
    printf '%s' "$n"
}

quest_goal_auflage() {
    local n
    [ "${AUFLAGE_DONE:-0}" = "1" ] && return 0
    [ "${AUFLAGE_GIVEN:-0}" = "1" ] || return 0
    n="$(_quest_auflage_boxes)"
    if [ "$n" -ge 5 ] 2>/dev/null; then
        printf 'Bring Rachel den Bericht: DailyPulse-Verlag (Süddistrikt)'
    else
        printf 'Fülle die fünf Zeitungskästen mit der Sperrzone-Ausgabe (use Zeitungskasten) – noch %s offen.' \
            "$(( 5 - n ))"
    fi
}

quest_entries_auflage() {
    local i n=0 labels=(Süddistrikt Norddistrikt Westdistrikt Ostdistrikt Zentrum)
    [ "${AUFLAGE_GIVEN:-0}" = "1" ] && \
        printf 'Rachel hat mir fünf Bündel der Sperrzone-Ausgabe und den Zeitungskastenschlüssel gegeben. Ich soll alle fünf Kästen befüllen.\n'
    for i in 0 1 2 3 4; do
        if [ $(( ${ZEITUNG_EMPTIED:-0} & (1 << i) )) -eq 0 ]; then
            n=$(( n + 1 ))
            printf 'Zeitungskasten im %s mit der Sperrzone-Ausgabe befüllt (%s/5).\n' "${labels[$i]}" "$n"
        fi
    done
    if [ "${AUFLAGE_GIVEN:-0}" = "1" ] && [ "${AUFLAGE_DONE:-0}" != "1" ] && [ "$n" -ge 5 ]; then
        printf 'Alle fünf Kästen sind befüllt. Ich sollte Rachel im DailyPulse-Verlag Bericht erstatten.\n'
    fi
    [ "${AUFLAGE_DONE:-0}" = "1" ] && \
        printf 'Rachel hat sich bedankt: 50 Bits, ein Exemplar der Sperrzone-Ausgabe und 500 EXP. Quest abgeschlossen.\n'
    return 0
}

# --- Verlauf: wächst mit dem Spielfortschritt -----------------------
# quest_entries_<id>() gibt je Zeile einen Log-Eintrag aus. Da die Werte aus
# den (im Spielstand gesicherten) Fortschritts-Flags abgeleitet werden,
# aktualisiert sich der Questlog automatisch - ohne eigene Speicherung.
quest_entries_pixi() {
    [ "${HOME_FIRST_VISIT:-0}" = "1" ] && \
        printf 'Folge Pixi – sie kennt jeden Sektor der Stadt.\n'
    [ "${PIXI_DESKTOP_DONE:-0}" = "1" ] && \
        printf 'Pixi ist in die Stadt geflohen – folge ihr nach DesktopCity.\n'
    [ "${PIXI_GATE_DONE:-0}" = "1" ] && \
        printf 'Simon Guard hat uns am Haupttor eingelassen – weiter in den Haupteingang.\n'
    [ "${PIXI_HALL_DONE:-0}" = "1" ] && \
        printf 'Pixi wartet in der Zeitungsredaktion (Süddistrikt/DailyPulse) auf mich. Sie hat bestimmt nützliche Informationen für mich.\n'
    [ "${VERLAG_DONE:-0}" = "1" ] && \
        printf 'Im Verlag angekommen – Pixi ist wieder bei ihrer Familie (Rachel, Jack).\n'
    return 0
}

quest_init
