# ============================================================
#  TerminalHero - Story: Neks Beerdigung (getimte Quest)
# ------------------------------------------------------------
#  Nach dem Abschluss der Nek-Quest setzt Simon Guard die Beerdigung
#  an. Die Frist hängt davon ab, wo die Leiche geblieben ist:
#
#    cave  : Leiche liegt noch in der Molerathöhle
#            -> Beerdigung 5 Spieltage nach dem Nek-Abschluss, 16:00
#    simon : Leiche wurde zum Haupttor gebracht
#            -> Beerdigung 5 Spieltage nach dem Nek-Abschluss, 16:00
#    lost  : Leiche wurde irgendwo anders abgelegt
#            -> wird 2 Spieltage nach dem Abschluss gefunden,
#               Beerdigung 5 Spieltage nach dem Fund, 16:00
#
#  Am Beerdigungstag stehen auf dem Friedhof:
#     Francesco Dellamorte, Pixi, Jack Nullpunkt, Rachel,
#     Sherlock Holmes, Simon Guard (Torwächter), Simple Jon,
#     Börty Smiles sowie Neks Familie:
#        Gregor Molerat   - Vater, ernst und wortkarg
#        Marlene Molerat  - Mutter, traurig und still
#        Chantal Molerat  - Schwester, verwöhnt und gelangweilt
#
#  Vor 16:00 haben alle Anwesenden einen kurzen Standard-Dialog, der
#  sich auf die anstehende Beerdigung bezieht. Wurde Nek vorher
#  irgendwo in der Welt liegen gelassen (»lost«), sind die Dialoge
#  deutlich empört.
#
#  Ab 16:00 beginnt auf dem Friedhof automatisch die lange Trauerfeier.
#  Francesco hält die Rede; alle Anwesenden kommen zu Wort. Danach ist
#  die Quest abgeschlossen und es gibt 1000 EXP. Bis Mitternacht
#  bleiben die Gäste am Grab und haben einen kurzen Nachgespräch-Dialog.
#  Um Mitternacht verschwinden die temporären Gäste-Dateien wieder aus
#  dem Friedhof; die kanonischen Figuren stehen dann wieder an ihren
#  regulären Plätzen in der Welt (Pixi/Jack/Rachel im Verlag, Simon am
#  Tor, Simple Jon im Wachhaus, Börty im Ostdistrikt usw.). Die Familie
#  Molerat kehrt außerhalb des sichtbaren Friedhofs nach Hause zurück.
#
#  Wer den Tag verstreichen lässt, scheitert. Bis dahin gibt es beim
#  Betreten der fünf Stadtteile oder des Haupteingangs Gemunkel mit
#  dem Beerdigungsdatum. Bei »lost« nennt das Gemunkel zusätzlich,
#  dass der Spieler die Leiche hat liegen lassen.
# ============================================================

NEK_FUNERAL_HOUR=16
NEK_FUNERAL_START_MIN=$(( NEK_FUNERAL_HOUR * 60 ))
NEK_FUNERAL_REWARD_EXP=1000

# --- Die Gäste der Trauerfeier -------------------------------------
# Die Schlüssel sind klein und ASCII; Dateinamen und Anzeigenamen
# stehen in den Tabellen. Francesco ist bereits als statische Datei
# im Friedhof vorhanden und wird hier nicht noch einmal angelegt.
declare -ga NEK_FUNERAL_GUESTS=(
    pixi jack rachel sherlockholmes torwaechter simplejon
    boerty gregor marlene chantal
)

declare -gA NEK_FUNERAL_GUEST_FILE=(
    [pixi]="Pixi"
    [jack]="Jack"
    [rachel]="Rachel"
    [sherlockholmes]="SherlockHolmes"
    [torwaechter]="Torwächter"
    [simplejon]="SimpleJon"
    [boerty]="Börty"
    [gregor]="GregorMolerat"
    [marlene]="MarleneMolerat"
    [chantal]="ChantalMolerat"
)

declare -gA NEK_FUNERAL_GUEST_LABEL=(
    [pixi]="Pixi Nullpunkt"
    [jack]="Jack Nullpunkt"
    [rachel]="Rachel Nullpunkt"
    [sherlockholmes]="Sherlock Holmes"
    [torwaechter]="Simon Guard"
    [simplejon]="Simple Jon"
    [boerty]="Börty Smiles"
    [gregor]="Gregor Molerat"
    [marlene]="Marlene Molerat"
    [chantal]="Chantal Molerat"
)

declare -gA NEK_FUNERAL_GUEST_ROLE=(
    [pixi]="Reporterin, DailyPulse"
    [jack]="Redaktion, DailyPulse"
    [rachel]="Chefredakteurin, DailyPulse"
    [sherlockholmes]="Detektiv"
    [torwaechter]="Torwächter, Neks Freund"
    [simplejon]="Stadtwache, Simons Freund"
    [boerty]="Wirt, Zum Goldenen Lächeln"
    [gregor]="Neks Vater"
    [marlene]="Neks Mutter"
    [chantal]="Neks Schwester"
)

declare -gA NEK_FUNERAL_GUEST_DIALOG=(
    [pixi]="dialog_nek_funeral_pixi"
    [jack]="dialog_nek_funeral_jack"
    [rachel]="dialog_nek_funeral_rachel"
    [sherlockholmes]="dialog_nek_funeral_sherlockholmes"
    [torwaechter]="dialog_nek_funeral_torwaechter"
    [simplejon]="dialog_nek_funeral_simplejon"
    [boerty]="dialog_nek_funeral_boerty"
    [gregor]="dialog_nek_funeral_gregor"
    [marlene]="dialog_nek_funeral_marlene"
    [chantal]="dialog_nek_funeral_chantal"
)

declare -gA NEK_FUNERAL_GUEST_NOTE=(
    [pixi]="Sie hat einen Notizblock dabei und noch keine Überschrift."
    [jack]="Er hält den Fotoapparat, macht aber noch kein Bild."
    [rachel]="Sie prüft die Reihen, als wären es Zeilen einer Seite."
    [sherlockholmes]="Er steht abseits und beobachtet die Trauernden."
    [torwaechter]="Er steht still am Grab und lässt niemanden an sich heran."
    [simplejon]="Er hat seinen besten Mantel angezogen. Er riecht nach Kaffee."
    [boerty]="Er hat eine Flasche Bier mitgebracht. Nur eine."
    [gregor]="Er steht gerade, die Hände gefaltet, den Blick auf das Grab."
    [marlene]="Sie hält ein Taschentuch, benutzt es aber noch nicht."
    [chantal]="Sie sieht auf ihr Handy, obwohl hier keins funktioniert."
)

# Wenn der Agent Nek in der Welt liegen ließ (Disposition »lost«),
# bekommt jede Figur vor 16:00 eine eigene, empörte Zeile. Die Zeilen
# sind bewusst kurz; der restliche Standard-Dialog bleibt unverändert.
declare -gA NEK_FUNERAL_GUEST_OUTRAGE=(
    [pixi]="Du hast ihn liegen lassen. Ich schreibe sonst über Leute wie dich. Heute fällt mir das schwer."
    [jack]="Ich habe ein Bild von ihm. Du hast ihn vergammeln lassen. Ich weiß nicht, ob ich es zeigen soll."
    [rachel]="Keine Tränen auf Seite eins. Aber eine Frage: Warum hast du ihn liegen lassen?"
    [sherlockholmes]="Es gibt keinen Fall. Es gibt nur eine Frage, die du beantworten musst: Warum hast du ihn liegen lassen?"
    [torwaechter]="Du hast ihn gefunden und bist gegangen. Ich stand am Tor. Wir haben beide versagt – aber du hattest ihn."
    [simplejon]="Nek lag da draußen. Du hast ihn gesehen. Und bist gegangen. Ich versuche, nicht wütend zu sein."
    [boerty]="Nek hat immer pünktlich gezahlt. Du hast ihn liegen lassen. Heute Abend gibt es trotzdem ein Bier für ihn. Für dich nicht."
    [gregor]="Du hast meinen Sohn liegen lassen. Steh hier nicht herum und tu, als wärst du traurig."
    [marlene]="Du hast ihn gefunden. Du hättest ihn mitbringen können. Ich versuche, dir das nicht ins Gesicht zu sagen."
    [chantal]="Du hast ihn vergammeln lassen? Echt? Das ist ... widerlich. Und ich dachte, ich wäre heute genervt."
)

# Wo findet die Beerdigung statt?
nek_funeral_cemetery_path() {
    if [ -n "${TH_NEK_FRIEDHOF:-}" ]; then
        printf '%s' "$TH_NEK_FRIEDHOF"
        return 0
    fi
    if [ -n "${NEK_FRIEDHOF_PATH:-}" ]; then
        printf '%s' "$NEK_FRIEDHOF_PATH"
        return 0
    fi
    printf '%s/Schreibtisch/Brachland/Friedhof' "$HOME_DIR"
}

# Ordner, in dem Simon Guard steht (Haupttor).
nek_funeral_simon_dir() {
    printf '%s/Schreibtisch/DesktopCity/Haupteingang' "$HOME_DIR"
}

# Wo ist die Leiche beim Nek-Abschluss? -> cave | simon | lost
nek_funeral_disposition_now() {
    local p cave simon
    cave="$(neks_leiche_default_path 2>/dev/null)"
    simon="$(nek_funeral_simon_dir)/NeksLeiche"

    if [ "${NEK_CORPSE_BROUGHT:-0}" = "1" ]; then
        printf 'simon'
        return 0
    fi
    if p="$(neks_leiche_path_of 2>/dev/null)"; then
        if [ -n "$cave" ] && [ "$p" = "$cave" ]; then
            printf 'cave'
        elif [ "$p" = "$simon" ]; then
            printf 'simon'
        else
            printf 'lost'
        fi
        return 0
    fi
    printf 'lost'
}

# Ist die Beerdigungsquest gerade offen?
nek_funeral_active() {
    [ "${NEK_FUNERAL_GIVEN:-0}" = "1" ] \
        && [ "${NEK_FUNERAL_DONE:-0}" != "1" ] \
        && [ "${NEK_FUNERAL_FAILED:-0}" != "1" ]
}

# Beerdigungsdatum als TT.MM.JJJJ (leer, wenn noch keins gesetzt ist).
nek_funeral_date_text() {
    local d="${NEK_FUNERAL_DAY:--1}"
    case "$d" in
        ''|*[!0-9]*) return 0 ;;
    esac
    if declare -F cal_date_text_for_day >/dev/null 2>&1; then
        cal_date_text_for_day "$d"
    fi
}

# Aktuelle Spielminute innerhalb des Tages (0..1439).
nek_funeral_day_minute() {
    if declare -F uhrzeit_minutes >/dev/null 2>&1; then
        printf '%s' $(( ( CLOCK_START_MIN + $(uhrzeit_minutes) ) % CLOCK_DAY_MIN ))
    else
        printf '0'
    fi
}

# Aktueller Spieltag (-1, wenn die Uhr nicht verfügbar ist).
nek_funeral_day_now() {
    if declare -F uhrzeit_day >/dev/null 2>&1; then
        uhrzeit_day
    else
        printf '%s' -1
    fi
}

# Ist heute der Beerdigungstag? Gilt auch nach der Trauerfeier, solange
# die Gäste noch für die Nachgespräche am Grab stehen.
nek_funeral_day_is_today() {
    [ "${NEK_FUNERAL_GIVEN:-0}" = "1" ] || return 1
    [ "${NEK_FUNERAL_FAILED:-0}" = "1" ] && return 1
    [ "$(nek_funeral_day_now)" = "${NEK_FUNERAL_DAY:--1}" ] || return 1
    return 0
}

# Ist die Trauerfeier an diesem Tag bereits vorbei? Dann bleiben die
# Gäste bis Mitternacht für die kurzen Nachgespräche.
nek_funeral_after() {
    [ "${NEK_FUNERAL_DONE:-0}" = "1" ] || return 1
    nek_funeral_day_is_today
}

# Ist heute der Beerdigungstag und ist es noch vor 16:00?
nek_funeral_before_start() {
    nek_funeral_day_is_today || return 1
    [ "$(nek_funeral_day_minute)" -lt "$NEK_FUNERAL_START_MIN" ] 2>/dev/null
}

# Hat der Agent Nek in der Welt liegen gelassen? Das ist die »lost«-
# Variante; die Standard-Dialoge vor 16:00 werden dann empört.
nek_funeral_corpse_neglected() {
    [ "${NEK_FUNERAL_DISPOSITION:-}" = "lost" ]
}

# Startet die getimte Quest. <disposition> wird beim Abschluss aus dem
# tatsächlichen Leichenort bestimmt.
nek_funeral_start() {
    [ "${NEK_FUNERAL_GIVEN:-0}" = "1" ] && return 1

    local disp day date
    disp="$(nek_funeral_disposition_now)"
    day="$(uhrzeit_day 2>/dev/null || printf '0')"
    case "$day" in
        ''|*[!0-9]*) day=0 ;;
    esac

    NEK_FUNERAL_DISPOSITION="$disp"
    NEK_FUNERAL_FOUND=0
    NEK_FUNERAL_DONE=0
    NEK_FUNERAL_FAILED=0
    case "$disp" in
        lost)
            NEK_FUNERAL_DISCOVERY_DAY=$(( day + 2 ))
            NEK_FUNERAL_DAY=$(( day + 7 ))
            ;;
        *)
            NEK_FUNERAL_DISCOVERY_DAY=-1
            NEK_FUNERAL_DAY=$(( day + 5 ))
            ;;
    esac

    # quest_gain_once muss VOR NEK_FUNERAL_GIVEN laufen: der Status ist
    # dann noch »verborgen«, die neue Quest wird also gemeldet.
    if declare -F quest_gain_once >/dev/null 2>&1; then
        quest_gain_once nek_beerdigung
    fi
    NEK_FUNERAL_GIVEN=1

    date="$(nek_funeral_date_text)"
    if declare -F quest_note >/dev/null 2>&1; then
        quest_note "Nek wird am ${date} um 16:00 beerdigt."
    fi
    return 0
}

# Ist der aktuelle Ordner der Friedhof (oder darunter)?
nek_funeral_at_cemetery() {
    local cem
    cem="$(nek_funeral_cemetery_path)"
    [ -n "$cem" ] || return 1
    case "${CWD:-}" in
        "$cem"|"$cem"/*) return 0 ;;
    esac
    return 1
}

# ============================================================
#  Gäste im Friedhof
# ============================================================
# Die Gäste sind dynamische Dateien: Sie erscheinen am Beerdigungstag
# und verschwinden danach wieder. Die Inhalte und Dialoge werden bei
# jedem Abgleich neu gesetzt, damit ein geladener Spielstand keine
# veralteten Texte behält.
nek_funeral_guest_path() {   # <gast-id>
    printf '%s/%s' "$(nek_funeral_cemetery_path)" "${NEK_FUNERAL_GUEST_FILE[$1]}"
}

nek_funeral_guest_content() {   # <gast-id>
    local id="$1"
    local label="${NEK_FUNERAL_GUEST_LABEL[$id]:-$id}"
    local role="${NEK_FUNERAL_GUEST_ROLE[$id]:-Gast}"
    local file="${NEK_FUNERAL_GUEST_FILE[$id]:-$id}"
    local note="${NEK_FUNERAL_GUEST_NOTE[$id]:-}"
    local status="wartet auf 16:00"
    local hint="Wer ihn/sie berührt (touch $file), hört, was vor der Beerdigung gesagt wird."
    if [ "${NEK_FUNERAL_DONE:-0}" = "1" ]; then
        status="Beerdigung vorbei"
        hint="Wer ihn/sie berührt (touch $file), hört ein kurzes Wort nach der Beerdigung."
    fi
    printf '========================================\n  FRIEDHOF  //  %s\n========================================\nRolle  : %s\nAnlass : Neks Beerdigung\nStatus : %s\n\n%s\n\n%s (cat %s · file %s)' \
        "$label" "$role" "$status" "$note" "$hint" "$file" "$file"
}

nek_funeral_guests_should_exist() {
    # Am Beerdigungstag bleiben die Gäste auch nach der Trauerfeier noch
    # bis Mitternacht. Erst am Folgetag (oder nach einem Scheitern)
    # verschwinden ihre temporären Dateien.
    [ "${NEK_FUNERAL_GIVEN:-0}" = "1" ] || return 1
    [ "${NEK_FUNERAL_FAILED:-0}" = "1" ] && return 1
    [ "$(nek_funeral_day_now)" = "${NEK_FUNERAL_DAY:--1}" ] || return 1
    return 0
}

nek_funeral_guests_present() {
    local id p
    for id in "${NEK_FUNERAL_GUESTS[@]}"; do
        p="$(nek_funeral_guest_path "$id")"
        [ -n "${TYPE[$p]:-}" ] && return 0
    done
    return 1
}

nek_funeral_guests_sync() {
    local id p
    if ! nek_funeral_guests_should_exist; then
        nek_funeral_guests_remove
        return 1
    fi
    for id in "${NEK_FUNERAL_GUESTS[@]}"; do
        p="$(nek_funeral_guest_path "$id")"
        declare -F fs_add >/dev/null 2>&1 && fs_add f "$p"
        CONTENT["$p"]="$(nek_funeral_guest_content "$id")"
        DIALOG["$p"]="${NEK_FUNERAL_GUEST_DIALOG[$id]}"
    done
    return 0
}

nek_funeral_guests_remove() {
    local id p
    for id in "${NEK_FUNERAL_GUESTS[@]}"; do
        p="$(nek_funeral_guest_path "$id")"
        declare -F fs_remove >/dev/null 2>&1 && fs_remove "$p"
        unset "CONTENT[$p]" "DIALOG[$p]"
    done
    return 0
}

# ============================================================
#  Textausgabe
# ============================================================
# In der laufenden TUI nutzt die Beerdigung dasselbe say() wie alle
# Dialoge. In Unit-Tests (ohne render/sleep) landen die Zeilen direkt
# in OUT.
nek_funeral_speak() {   # <sprecher|-> <text>
    if declare -F say >/dev/null 2>&1; then
        say "$1" "$2"
    elif [ "$1" = "-" ]; then
        OUT+=("$2")
    else
        OUT+=("$1: $2")
    fi
}

# ============================================================
#  Standard-Dialoge vor 16:00
# ============================================================
nek_funeral_guest_standard() {   # <gast-id>
    local id="$1"
    local label="${NEK_FUNERAL_GUEST_LABEL[$id]:-$id}"
    local role="${NEK_FUNERAL_GUEST_ROLE[$id]:-}"

    # Nach der Trauerfeier, aber noch am selben Tag: kurzes Nachgespräch.
    if nek_funeral_after; then
        nek_funeral_guest_after "$id"
        return 0
    fi

    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ BRACHLAND · FRIEDHOF ═════")
    OUT+=("${label}    ${role}")
    OUT+=("")
    declare -F render >/dev/null 2>&1 && render

    # »lost«: Der Agent hat Nek in der Welt liegen lassen. Jede Figur
    # bringt ihre Empörung auf ihre eigene Art an.
    if nek_funeral_corpse_neglected; then
        nek_funeral_speak "-" "Die Trauergäste wissen, dass du Nek liegen gelassen hast. Die Blicke sind kalt."
        nek_funeral_speak "$label" "${NEK_FUNERAL_GUEST_OUTRAGE[$id]:-Du hast ihn liegen lassen. Das vergessen wir hier nicht.}"
    fi

    case "$id" in
        pixi)
            nek_funeral_speak "Pixi" "Ich schreibe seinen Namen auf. Nicht den Virus. Nicht die Stadt. Nek."
            nek_funeral_speak "Pixi" "Rachel will keinen Sensationsartikel. Ich auch nicht. Aber jemand muss später wissen, dass er hier war."
            nek_funeral_speak "Pixi" "Vor 16:00 sammle ich noch Sätze. Danach schreibe ich. Das ist meine Art, Abschied zu nehmen."
            ;;
        jack)
            nek_funeral_speak "Jack" "Ich habe ein Foto von ihm, auf dem er wegsieht. Es ist nicht gut. Aber es ist er."
            nek_funeral_speak "Jack" "Pixi schreibt, Rachel prüft, ich setze. Heute ist das keine Redaktionssitzung. Heute ist es Familie."
            nek_funeral_speak "Jack" "Ich habe den Fotoapparat dabei. Ich mache aber erst ein Bild, wenn alle gesprochen haben."
            ;;
        rachel)
            nek_funeral_speak "Rachel" "Keine Tränen auf Seite eins. Nur der Name. Und das Datum. Alles andere ist unsere Arbeit."
            nek_funeral_speak "Rachel" "Nek hat diese Stadt beschützt, ohne dafür in der Zeitung zu stehen. Das ändern wir heute – aber leise."
            nek_funeral_speak "Rachel" "Pixi und Jack sind wegen des Nachrufs hier. Ich bin wegen Nek hier. Das ist ein Unterschied."
            ;;
        sherlockholmes)
            nek_funeral_speak "Sherlock Holmes" "Es gibt keinen Fall. Es gibt nur einen Menschen, der nicht mehr da ist."
            nek_funeral_speak "Sherlock Holmes" "Ich habe Nek nie gesprochen. Ich habe Akten gesehen, die seinen Namen tragen. Das ist nicht dasselbe."
            nek_funeral_speak "Sherlock Holmes" "Ich bleibe bis zum Ende. Nicht als Detektiv. Als Zeuge."
            ;;
        torwaechter)
            nek_funeral_speak "Simon Guard" "Nek war mein Freund. Heute stehe ich hier, weil ich ihm das schuldig bin."
            nek_funeral_speak "Simon Guard" "Ich habe ihn nicht gefunden. Ich stand am Tor. Vielleicht war das mein Platz. Vielleicht war es der falsche."
            nek_funeral_speak "Simon Guard" "Um 16:00 rede ich. Bis dahin versuche ich, nicht daran zu denken, was ich hätte sagen sollen."
            ;;
        simplejon)
            nek_funeral_speak "Simple Jon" "Sein Stuhl im Wachhaus ist noch leer. Ich habe ihn nicht verrückt. Heute Abend setze ich mich nicht drauf."
            nek_funeral_speak "Simple Jon" "Nek und ich haben zusammen Dienst gemacht. Er hat mehr Kaffee gekocht, als er getrunken hat. Ich habe mehr getrunken, als ich zugeben wollte."
            nek_funeral_speak "Simple Jon" "Simon und ich stehen hier. Das ist das Mindeste. Nek hätte dasselbe für uns getan."
            ;;
        boerty)
            nek_funeral_speak "Börty" "Nek hat immer pünktlich gezahlt. Heute Abend gebe ich einen aus. Auf seinen Namen."
            nek_funeral_speak "Börty" "Er hat an der Theke gesessen und zugehört. Nicht jeder Wirt bekommt so einen Gast. Ich schon."
            nek_funeral_speak "Börty" "Die Flasche da ist für ihn. Nicht zum Trinken. Für den Weg."
            ;;
        gregor)
            nek_funeral_speak "Gregor Molerat" "Wir beerdigen meinen Sohn. Mehr gibt es vorher nicht zu sagen."
            nek_funeral_speak "Gregor Molerat" "Nek war ein Molerat. Molerats stehen gerade. Molerats jammern nicht. Heute halten wir das aus."
            nek_funeral_speak "Gregor Molerat" "Wer etwas zu sagen hat, sagt es nachher. Vorher ist keine Zeit für große Worte."
            ;;
        marlene)
            nek_funeral_speak "Marlene Molerat" "Ich habe seine Uniform gebügelt. Ich weiß nicht, warum. Es hat sich richtig angefühlt."
            nek_funeral_speak "Marlene Molerat" "Er hat immer gesagt, die Stadt braucht ihn. Ich habe gesagt, ich brauche ihn. Er hat nur gelacht."
            nek_funeral_speak "Marlene Molerat" "Ich habe noch nicht geweint. Ich weiß nicht, ob ich es vor allen kann."
            ;;
        chantal)
            nek_funeral_speak "Chantal Molerat" "Wie lange dauert das? Ich habe danach noch was vor."
            nek_funeral_speak "Chantal Molerat" "Mama sagt, ich soll traurig sein. Ich bin nicht traurig. Ich bin genervt. Das ist auch ein Gefühl."
            nek_funeral_speak "Chantal Molerat" "Nek hat mir immer billige Schokolade mitgebracht. Er war der Einzige, der das lustig fand. Ich nicht."
            ;;
    esac

    nek_funeral_speak "-" "Bis 16:00 ist noch Zeit. Dann beginnt die Beerdigung."
    declare -F dialog_pause >/dev/null 2>&1 && dialog_pause
    DIALOG_ACTIVE=0
    DIALOG_HINT=""
}

# Kurzes Nachgespräch am selben Tag nach der Trauerfeier. Die Gäste
# bleiben bis Mitternacht am Grab, bevor ihre temporären Dateien
# verschwinden.
nek_funeral_guest_after() {   # <gast-id>
    local id="$1"
    local label="${NEK_FUNERAL_GUEST_LABEL[$id]:-$id}"
    local role="${NEK_FUNERAL_GUEST_ROLE[$id]:-}"

    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ BRACHLAND · FRIEDHOF ═════")
    OUT+=("${label}    ${role}    nach der Beerdigung")
    OUT+=("")
    declare -F render >/dev/null 2>&1 && render

    case "$id" in
        pixi)
            nek_funeral_speak "Pixi" "Der Nachruf steht. Ohne Schlagzeile, mit Namen. So wie es sein soll."
            nek_funeral_speak "Pixi" "Ich bleibe noch einen Moment. Dann gehen wir zurück in die Redaktion."
            ;;
        jack)
            nek_funeral_speak "Jack" "Ich habe das Bild genommen. Das, auf dem er wegsieht. Es ist das richtige."
            nek_funeral_speak "Jack" "Pixi schreibt. Rachel prüft. Ich setze. Heute Abend ist die Seite fertig."
            ;;
        rachel)
            nek_funeral_speak "Rachel" "Die Seite ist ruhig. Genau so, wie sie sein soll."
            nek_funeral_speak "Rachel" "Wir gehen zurück. Die Arbeit wartet, aber sie wartet heute ausnahmsweise."
            ;;
        sherlockholmes)
            nek_funeral_speak "Sherlock Holmes" "Der Fall ist geschlossen. Nicht der, den du suchst. Der hier. Nek kann jetzt ruhen."
            nek_funeral_speak "Sherlock Holmes" "Ich gehe zurück in die Detektei. Die Stadt wird heute Nacht wieder unruhig sein."
            ;;
        torwaechter)
            nek_funeral_speak "Simon Guard" "Die Erde ist noch weich. Ich bleibe noch einen Moment. Dann gehe ich zurück ans Tor."
            nek_funeral_speak "Simon Guard" "Danke, dass du ihn gefunden hast. Auch wenn ich es dir vorher nicht sagen konnte."
            ;;
        simplejon)
            nek_funeral_speak "Simple Jon" "Ich gehe zurück ins Wachhaus. Sein Stuhl bleibt erst mal leer. Aber ich werde ihn nicht vergessen."
            nek_funeral_speak "Simple Jon" "Wenn du vorbeikommst, setz dich nicht drauf. Das ist alles, was ich verlange."
            ;;
        boerty)
            nek_funeral_speak "Börty" "Heute Abend ist die Kneipe offen. Ein Bier auf Nek. Du kannst kommen. Aber nicht zu spät."
            nek_funeral_speak "Börty" "Er hat immer pünktlich gezahlt. Ich werde nicht damit anfangen, ihn jetzt zu vergessen."
            ;;
        gregor)
            nek_funeral_speak "Gregor Molerat" "Die Beerdigung ist vorbei. Jetzt gehen wir nach Hause. Nek bleibt hier. Das ist in Ordnung."
            nek_funeral_speak "Gregor Molerat" "Du hast getan, was nötig war. Mehr verlange ich nicht."
            ;;
        marlene)
            nek_funeral_speak "Marlene Molerat" "Ich habe geweint. Endlich. Es war leiser, als ich dachte."
            nek_funeral_speak "Marlene Molerat" "Danke, dass du ihn gefunden hast. Wir gehen jetzt nach Hause."
            ;;
        chantal)
            nek_funeral_speak "Chantal Molerat" "Endlich vorbei. Ich gehe nach Hause. Und nein, ich werde nicht traurig gucken."
            nek_funeral_speak "Chantal Molerat" "Aber seine blöde Schokolade werde ich vermissen. Sag das bloß nicht Mama."
            ;;
    esac

    declare -F dialog_pause >/dev/null 2>&1 && dialog_pause
    DIALOG_ACTIVE=0
    DIALOG_HINT=""
}

nek_funeral_francesco_standard() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ BRACHLAND · FRIEDHOF ═════")
    OUT+=("Francesco Dellamorte    Totengräber    Stimmung: feierlich")
    OUT+=("")
    declare -F render >/dev/null 2>&1 && render

    nek_funeral_speak "Francesco" "Ah. Du bist früh. Gut. Pünktlichkeit ist bei mir keine Tugend, sondern eine Arbeitsanweisung."
    nek_funeral_speak "Francesco" "Um 16:00 legen wir Nek Molerat in die Erde. Bis dahin kontrolliere ich die Reihen und tue so, als hätte ich alles im Griff."
    nek_funeral_speak "Francesco" "Die Familie ist da. Simon Guard. Simple Jon. Die Redaktion. Börty. Sogar Holmes. Der Tod zieht offenbar mehr Publikum als meine Predigten."
    if nek_funeral_corpse_neglected; then
        nek_funeral_speak "Francesco" "Ich habe gehört, du hast ihn liegen lassen. Ich grabe heute ein Loch für einen Mann, den du im Dreck vergessen hast. Das ist keine gute Arbeitsgrundlage."
    fi
    nek_funeral_speak "Francesco" "Wenn du etwas sagen willst, sag es vorher. Nachher hört niemand mehr zu. Das ist bei Beerdigungen so."
    nek_funeral_speak "-" "Er klopft sich die Erde von den Handschuhen und sieht zum offenen Grab."
    nek_funeral_speak "-" "Bis 16:00 ist noch Zeit. Dann beginnt die Beerdigung."

    declare -F dialog_pause >/dev/null 2>&1 && dialog_pause
    DIALOG_ACTIVE=0
    DIALOG_HINT=""
}

nek_funeral_francesco_after() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ BRACHLAND · FRIEDHOF ═════")
    OUT+=("Francesco Dellamorte    Totengräber    nach der Beerdigung")
    OUT+=("")
    declare -F render >/dev/null 2>&1 && render

    nek_funeral_speak "Francesco" "Die Erde ist geschlossen. Die Reihe ist wieder in Ordnung."
    nek_funeral_speak "Francesco" "Du kannst gehen. Ich bleibe noch ein bisschen bei ihm. Die Toten beschweren sich nie – aber manchmal ist es ganz angenehm, nicht allein zu sein."
    nek_funeral_speak "Francesco" "Und wenn du das nächste Mal jemanden findest: Bring ihn mir, bevor er vergammelt. Ich grabe schneller, als ich rede."

    declare -F dialog_pause >/dev/null 2>&1 && dialog_pause
    DIALOG_ACTIVE=0
    DIALOG_HINT=""
}

# --- Kleine Dialog-Einstiege für die dynamischen Gäste-Dateien -----
dialog_nek_funeral_pixi()           { nek_funeral_guest_standard pixi; }
dialog_nek_funeral_jack()           { nek_funeral_guest_standard jack; }
dialog_nek_funeral_rachel()         { nek_funeral_guest_standard rachel; }
dialog_nek_funeral_sherlockholmes() { nek_funeral_guest_standard sherlockholmes; }
dialog_nek_funeral_torwaechter()    { nek_funeral_guest_standard torwaechter; }
dialog_nek_funeral_simplejon()      { nek_funeral_guest_standard simplejon; }
dialog_nek_funeral_boerty()         { nek_funeral_guest_standard boerty; }
dialog_nek_funeral_gregor()         { nek_funeral_guest_standard gregor; }
dialog_nek_funeral_marlene()        { nek_funeral_guest_standard marlene; }
dialog_nek_funeral_chantal()        { nek_funeral_guest_standard chantal; }

# ============================================================
#  Die Trauerfeier ab 16:00
# ============================================================
nek_funeral_attend() {
    NEK_FUNERAL_GIVEN=1
    NEK_FUNERAL_DONE=1
    NEK_FUNERAL_FAILED=0

    play_sound online
    OUT+=("")
    OUT+=("═════ FRIEDHOF · NEKS BEERDIGUNG ═════")

    nek_funeral_speak "-" "Der Friedhof liegt still unter einem grauen Himmel. Zwischen den Gräbern stehen die Menschen, die Nek Molerat gekannt haben."
    nek_funeral_speak "-" "Vorne, an einem offenen Grab, wartet Francesco Dellamorte. Die Schaufel steht neben ihm wie ein Zeremonienstab."

    # --- Der Totengräber hält die Rede -----------------------------
    nek_funeral_speak "Francesco" "Freunde, Kollegen, Familie. Und der Agent, der Nek gefunden hat. Danke, dass Sie gekommen sind. Pünktlich. Das ist mehr, als viele meiner Kunden schaffen."
    nek_funeral_speak "Francesco" "Ich bin Francesco Dellamorte. Ich grabe die Löcher, ich schließe sie wieder, und dazwischen sage ich ein paar Worte. Meistens mehr, als nötig."
    nek_funeral_speak "Francesco" "Nek Molerat war Stadtwache. Er hat die Stadt beschützt. Und er hat es geschafft, dabei so unauffällig zu bleiben, dass man ihn erst vermisst hat, als sein Stuhl im Wachhaus leer blieb."
    nek_funeral_speak "Francesco" "Ich habe heute Morgen ein Loch gegraben. Sechs Fuß tief. In Bits gerechnet sind das ungefähr viele. Ich habe nicht nachgezählt. Die Toten beschweren sich nie über die Größe."
    nek_funeral_speak "Francesco" "Ich habe Nek nicht gekannt. Aber ich kenne die Namen, die auf den Steinen stehen. Und ich weiß: Ein Mensch ist nicht tot, solange jemand seinen Namen ausspricht."
    nek_funeral_speak "Francesco" "Also sprechen wir ihn aus: Nek Molerat."

    # --- Torwächter: mehr Text -------------------------------------
    nek_funeral_speak "Simon Guard" "Nek und ich haben zusammen Dienst gemacht. Am Tor, im Regen, in Nächten, in denen niemand durchwollte und wir trotzdem stehen blieben."
    nek_funeral_speak "Simon Guard" "Er war derjenige, der mir Kaffee brachte, wenn ich zu stolz war, Pause zu machen. Er hat nie darüber geredet. Er hat einfach den Becher hingestellt."
    nek_funeral_speak "Simon Guard" "Ich habe ihn nicht gefunden. Ich habe es versucht. Aber die Stadt ist groß, und ich stand am Tor, weil ich dachte, das wäre meine Aufgabe."
    nek_funeral_speak "Simon Guard" "Heute weiß ich: Meine Aufgabe war nicht nur das Tor. Sie war auch, auf ihn aufzupassen. Das habe ich nicht getan. Es tut mir leid, Nek."
    nek_funeral_speak "Simon Guard" "Du warst mein Freund. Der beste, den ich hatte. Und ich werde dafür sorgen, dass dein Stuhl im Wachhaus nicht einfach weggeräumt wird."

    # --- Simple Jon, sein Freund aus dem Wachhaus ------------------
    nek_funeral_speak "Simple Jon" "Nek war mein Kollege. Und mein Freund. Er hat mir beigebracht, wie man Kaffee macht, ohne die Maschine zu töten. Das war keine kleine Leistung."
    nek_funeral_speak "Simple Jon" "Er hat immer gesagt: »Jon, du musst nicht viel reden. Du musst nur da sein.« Ich war da. Ich war da, als er ging. Ich wusste nur nicht, dass es für immer ist."
    nek_funeral_speak "Simple Jon" "Sein Stuhl im Wachhaus steht noch genau so da, wie er ihn verlassen hat. Ich habe ihn nicht verrückt. Ich habe ihn auch nicht abgewischt. Ich warte noch ein bisschen."
    nek_funeral_speak "Simple Jon" "Nek, du hast mir gefehlt, bevor ich wusste, dass du weg bist. Das klingt dumm. Aber du warst der Einzige, der das verstanden hätte."

    # --- Familie Molerat: ernst, traurig, gelangweilt --------------
    nek_funeral_speak "Gregor Molerat" "Nek war mein Sohn. Ich habe ihn nicht oft gelobt. Das war nicht meine Art."
    nek_funeral_speak "Gregor Molerat" "Ein Molerat steht gerade. Ein Molerat jammert nicht. Ein Molerat erledigt seine Arbeit. Nek hat das verstanden."
    nek_funeral_speak "Gregor Molerat" "Ich hätte ihm sagen sollen, dass ich stolz bin. Ich habe es nicht getan. Das ist mein Fehler, und ich werde ihn nicht schönreden."
    nek_funeral_speak "Gregor Molerat" "Er war ein guter Junge. Ein guter Mann. Und ein Molerat. Das ist alles, was ich sagen kann."

    nek_funeral_speak "Marlene Molerat" "Mein Junge. Mein Nek."
    nek_funeral_speak "Marlene Molerat" "Ich habe seine Uniform gebügelt, bevor er ging. Ich weiß nicht, warum. Vielleicht weil ich dachte, dass er zurückkommt und sie braucht."
    nek_funeral_speak "Marlene Molerat" "Er hat immer gesagt, die Stadt braucht ihn. Ich habe ihm gesagt, dass ich ihn brauche. Er hat gelacht und gesagt: »Dann komme ich zurück, Mama.«"
    nek_funeral_speak "Marlene Molerat" "Er ist nicht zurückgekommen. Und ich habe so lange gewartet, dass ich schon vergessen habe, wie seine Stimme klingt, wenn er müde ist."
    nek_funeral_speak "Marlene Molerat" "Sei vorsichtig da, wo du jetzt bist. Und grüß deinen Großvater. Er hat immer gesagt, du wirst ein guter Wächter."

    nek_funeral_speak "Chantal Molerat" "Ich hasse Beerdigungen. Alle stehen rum und gucken traurig. Das dauert ewig."
    nek_funeral_speak "Chantal Molerat" "Mama hat gesagt, ich soll ein schwarzes Kleid anziehen. Ich habe keins. Das hier ist dunkelblau. Wo ist der Unterschied?"
    nek_funeral_speak "Chantal Molerat" "Nek hat mir immer diese eine Schokolade mitgebracht. Nicht die gute. Die billige. Er hat gesagt, die schmeckt besser. Hat sie nicht."
    nek_funeral_speak "Chantal Molerat" "Er war mein Bruder. Ich weiß, dass ich jetzt was Nettes sagen soll. Aber ich bin hier. Das muss reichen."
    nek_funeral_speak "Chantal Molerat" "Wie lange dauert das noch? Ich habe danach noch was vor."

    # --- Börty, die Redaktion und Holmes ---------------------------
    nek_funeral_speak "Börty" "Nek war keiner von denen, die laut reden. Er hat sich an die Theke gesetzt, ein Bier bestellt und zugehört. Das ist selten."
    nek_funeral_speak "Börty" "Er hat immer pünktlich gezahlt. Sogar als er kein Geld hatte. Er hat gesagt: »Börty, schreib es an. Ich bin Wache. Ich komme wieder.«"
    nek_funeral_speak "Börty" "Ich habe es angeschrieben. Und ich habe nie erwartet, dass ich es ausstreichen muss. Heute Abend gebe ich einen aus. Auf seinen Namen."

    nek_funeral_speak "Pixi" "Nek Molerat. Stadtwache. Freund. Bruder. Sohn. Ein Name, der nicht in die Berichte passt, die ich sonst schreibe."
    nek_funeral_speak "Pixi" "Ich soll einen Artikel über ihn schreiben. Ich weiß noch nicht, wie. Ich weiß nur, dass es keine Schlagzeile wird. Es wird ein Nachruf."
    nek_funeral_speak "Pixi" "Er war nicht laut. Aber er war da. Manchmal ist das genug."

    nek_funeral_speak "Jack Nullpunkt" "Ich habe Bilder von den Wachen gemacht. Nek war auf keinem gern. Er stand immer am Rand und hat weggeschaut."
    nek_funeral_speak "Jack Nullpunkt" "Ich werde trotzdem eins nehmen. Das, auf dem er weggeschaut hat. Das ist am ehesten er. Pixi, ich setze den Text, wenn du fertig bist."

    nek_funeral_speak "Rachel" "Ein Nachruf, keine Sensation. Das sage ich einmal und dann nie wieder."
    nek_funeral_speak "Rachel" "Nek war Teil dieser Stadt. Er hat sie beschützt, ohne dafür in der Zeitung zu stehen. Das ändert sich heute."
    nek_funeral_speak "Rachel" "Pixi, Jack: Keine Tränen auf Seite eins. Nur der Name. Und das Datum. Der Rest ist unsere Arbeit."

    nek_funeral_speak "Sherlock Holmes" "Ich bin nicht hier, um einen Fall zu lösen. Es gibt keinen Fall. Es gibt nur einen Menschen, der nicht mehr da ist."
    nek_funeral_speak "Sherlock Holmes" "Ich habe Nek nie gesprochen. Ich habe Akten gesehen, die seinen Namen tragen. Das ist nicht dasselbe."
    nek_funeral_speak "Sherlock Holmes" "Ein Mann ist mehr als das, was er getan hat. Er ist auch das, was er für andere getan hat, ohne es zu erwähnen."

    nek_funeral_speak "$AGENT_NAME" "Ich habe Nek gefunden. Ich wünschte, ich hätte ihn lebend gefunden."
    nek_funeral_speak "$AGENT_NAME" "Er war nicht allein. Das kann ich sagen. Er war nicht allein."

    # --- Francesco schließt die Rede ------------------------------
    nek_funeral_speak "Francesco" "Danke, Simon. Danke, Simple Jon. Danke, Familie Molerat. Danke, Börty, Pixi, Jack, Rachel, Mister Holmes. Und danke, Agent."
    nek_funeral_speak "Francesco" "Jetzt kommt der Teil, für den ich hier bin. Nicht der mit der Schaufel. Der mit der Stille."
    nek_funeral_speak "Francesco" "Nek Molerat. Er war Wache. Er war Freund. Er war ein Molerat. Und er war pünktlich. Das ist mehr, als man von den meisten behaupten kann."
    nek_funeral_speak "Francesco" "Seine letzte Nachricht an mich war: »Francesco, mach die Gräber gerade.« Ich habe sie gerade gemacht. Extra für ihn."
    nek_funeral_speak "Francesco" "Wenn du jetzt aufwachst, Nek, dann bitte in der richtigen Reihe. Die anderen warten schon. Ruhe in Frieden. Und mach keinen Ärger."

    # --- Beisetzung ------------------------------------------------
    nek_funeral_speak "-" "Francesco lässt den Sarg langsam in die Erde. Das Seil knarrt."
    nek_funeral_speak "-" "Simon Guard wirft die erste Handvoll Erde. Seine Hand zittert."
    nek_funeral_speak "-" "Simple Jon tritt vor und wirft eine zweite. Er sagt nichts."
    nek_funeral_speak "-" "Gregor Molerat wirft eine dritte, ohne ein Wort. Marlene hält sich an Chantal fest. Chantal lässt es zu."
    nek_funeral_speak "-" "Börty legt eine Flasche Bier neben den Sarg. »Für den Weg«, sagt er."
    nek_funeral_speak "-" "Pixi schreibt nichts. Zum ersten Mal. Jack hält den Fotoapparat still. Rachel nickt langsam."
    nek_funeral_speak "-" "Sherlock Holmes zieht den Hut. Der Agent wirft die letzte Handvoll Erde."
    nek_funeral_speak "-" "Nek Molerat ist nicht allein geblieben."

    if declare -F quest_reward >/dev/null 2>&1; then
        quest_reward nek_beerdigung "$NEK_FUNERAL_REWARD_EXP"
    fi

    # --- Nachruf und Abschied der Gäste ----------------------------
    OUT+=("")
    OUT+=("[ TRAUERFEIER ]  Die Beerdigung ist beendet. Die Redaktion bleibt noch einen Moment.")
    nek_funeral_speak "Rachel" "Pixi, Jack. Wir haben Arbeit."
    nek_funeral_speak "Pixi" "Ein Nachruf. Mit Namen. Ohne Schlagzeile."
    nek_funeral_speak "-" "Die Gäste bleiben noch am Grab. Bis Mitternacht werden sie den Friedhof nicht verlassen."

    declare -F questlog_refresh >/dev/null 2>&1 && questlog_refresh

    # Die temporären Gäste-Dateien bleiben bis Mitternacht stehen: Dort
    # bekommen sie ihre kurzen Nachgespräche, danach räumt der Tick sie
    # weg. So sind Pixi, Simon & Co. in der Stadt wieder an ihrem
    # regulären Platz.
    declare -F dialog_pause >/dev/null 2>&1 && dialog_pause
    # dialog_pause setzt DIALOG_ACTIVE/DIALOG_HINT; nach der Trauerfeier
    # muss der Dialog wieder sauber enden, sonst bleibt der »Enter
    # weiter«-Hinweis über der Kommandozeile stehen.
    DIALOG_ACTIVE=0
    DIALOG_HINT=""
    return 0
}

# Beerdigung verpasst: Der Beerdigungstag ist vorbei.
nek_funeral_fail() {
    NEK_FUNERAL_GIVEN=1
    NEK_FUNERAL_DONE=0
    NEK_FUNERAL_FAILED=1

    play_sound error
    if declare -F quest_failed >/dev/null 2>&1; then
        quest_failed nek_beerdigung
    fi
    OUT+=("Du hast Neks Beerdigung verpasst.")
    nek_funeral_guests_remove
    declare -F questlog_refresh >/dev/null 2>&1 && questlog_refresh
    return 0
}

# Wird im Hauptloop und beim Leerlauf aufgerufen. Rückgabe 0 = Zustand
# hat sich geändert (bzw. es gibt eine neue Meldung), 1 = nichts zu tun.
nek_funeral_tick() {
    [ "${NEK_FUNERAL_GIVEN:-0}" = "1" ] || return 1
    declare -F uhrzeit_day >/dev/null 2>&1 || return 1

    local day now changed=0
    day="$(uhrzeit_day)"
    case "$day" in
        ''|*[!0-9]*) return 1 ;;
    esac

    # Nach der Trauerfeier bleiben die Gäste bis Mitternacht am Grab.
    # Am nächsten Tag werden ihre temporären Dateien entfernt; damit
    # stehen die kanonischen Figuren wieder an ihren regulären Plätzen.
    if [ "${NEK_FUNERAL_FAILED:-0}" = "1" ] \
       || { [ "${NEK_FUNERAL_DONE:-0}" = "1" ] \
            && [ "$day" -gt "${NEK_FUNERAL_DAY:--1}" ] 2>/dev/null; }; then
        local extra_started=0 removed=0
        if nek_funeral_guests_present; then
            nek_funeral_guests_remove
            removed=1
            # Die Familie Molerat kehrt auf die Farm zurück, sobald die
            # temporären Gäste den Friedhof verlassen. Der Aufruf ist
            # weich, damit isolierte Tests ohne Orte/Farm.sh laufen.
            if declare -F farm_build >/dev/null 2>&1; then
                farm_build >/dev/null 2>&1 || true
            fi
            if nek_funeral_at_cemetery; then
                OUT+=("")
                OUT+=("Mitternacht. Die Trauergäste verlassen den Friedhof und kehren an ihre Plätze zurück.")
            fi
        fi
        # Sind alle vom Friedhof zurück, erscheint die Extra-Ausgabe.
        # Das passiert auch dann, wenn die Gäste schon in einem früheren
        # Tick entfernt wurden (z. B. nach einem geladenen Spielstand).
        if [ "${NEK_FUNERAL_FAILED:-0}" != "1" ] \
           && [ "${NEK_FUNERAL_DONE:-0}" = "1" ] \
           && declare -F zeitung_extra_maybe_start >/dev/null 2>&1; then
            zeitung_extra_maybe_start && extra_started=1
        fi
        if [ "$removed" = "1" ] || [ "$extra_started" = "1" ]; then
            return 0
        fi
        return 1
    fi

    # Ist die Feier an diesem Tag bereits vorbei, bleiben die Gäste für
    # die Nachgespräche stehen. Es gibt keinen zweiten Automatik-Start.
    if [ "${NEK_FUNERAL_DONE:-0}" = "1" ]; then
        nek_funeral_guests_sync >/dev/null 2>&1 || true
        return 1
    fi

    nek_funeral_active || return 1

    # Gäste erscheinen genau am Beerdigungstag. Der Abgleich ist
    # idempotent und entfernt sie auch aus einem geladenen Spielstand,
    # wenn der Termin vorbei ist.
    nek_funeral_guests_sync >/dev/null 2>&1 || true
    # Am Beerdigungstag gehört die Familie Molerat zum Friedhof und
    # nicht zusätzlich auf die Farm.
    if declare -F farm_build >/dev/null 2>&1; then
        farm_build >/dev/null 2>&1 || true
    fi

    # Bei »lost« wird die Leiche zwei Tage nach dem Abschluss gefunden.
    # Der Fund ist eine Quest-Notiz; die Beerdigung folgt fünf Tage später.
    if [ "${NEK_FUNERAL_DISPOSITION:-}" = "lost" ] \
       && [ "${NEK_FUNERAL_FOUND:-0}" != "1" ] \
       && [ "${NEK_FUNERAL_DISCOVERY_DAY:--1}" -ge 0 ] 2>/dev/null \
       && [ "$day" -ge "${NEK_FUNERAL_DISCOVERY_DAY:--1}" ]; then
        NEK_FUNERAL_FOUND=1
        changed=1
        if declare -F quest_note >/dev/null 2>&1; then
            quest_note "Neks Leiche wurde in der Welt gefunden."
        fi
    fi

    case "${NEK_FUNERAL_DAY:--1}" in
        ''|*[!0-9]*) [ "$changed" = "1" ] && return 0; return 1 ;;
    esac
    if [ "$day" -gt "$NEK_FUNERAL_DAY" ]; then
        nek_funeral_fail
        return 0
    fi
    if [ "$day" -eq "$NEK_FUNERAL_DAY" ]; then
        now="$(nek_funeral_day_minute)"
        if [ "$now" -ge "$NEK_FUNERAL_START_MIN" ] && nek_funeral_at_cemetery; then
            nek_funeral_attend
            return 0
        fi
    fi
    [ "$changed" = "1" ] && return 0
    return 1
}

# Ist <pfad> einer der sechs Orte, an denen gemunkelt wird?
nek_funeral_is_rumor_place() {
    local p="${1:-}" base
    base="$(nek_funeral_simon_dir)"
    case "$p" in
        "$base"|"$base/Süddistrikt"|"$base/Norddistrikt"|"$base/Westdistrikt"|"$base/Ostdistrikt"|"$base/Zentrum")
            return 0 ;;
    esac
    return 1
}

# Gemunkeltext mit Datum. Bei »lost« mit dem Zusatz über den Spieler.
nek_funeral_rumor_text() {
    local date
    date="$(nek_funeral_date_text)"
    [ -n "$date" ] || date="einem unbekannten Tag"
    if [ "${NEK_FUNERAL_DISPOSITION:-}" = "lost" ]; then
        printf 'Du hörst jemand sagen: "Nek wurde gefunden. Er soll wohl am %s um 16 Uhr beerdigt werden. Man erzählt sich, der Spieler hätte Nek gefunden und die Leiche einfach irgendwo in der Welt vergammeln lassen."' "$date"
    else
        printf 'Du hörst jemand sagen: "Nek wurde gefunden. Er soll wohl am %s um 16 Uhr beerdigt werden."' "$date"
    fi
}

# Beim Betreten eines der sechs Orte: Gemunkel ausgeben. Der zuletzt
# geprüfte Ordner verhindert Wiederholungen bei jedem Befehl im selben Ort.
nek_funeral_rumor_maybe() {
    if [ -z "${NEK_RUMOR_LAST_CWD+x}" ]; then
        NEK_RUMOR_LAST_CWD="${CWD:-}"
        return 1
    fi
    [ "${CWD:-}" = "$NEK_RUMOR_LAST_CWD" ] && return 1
    NEK_RUMOR_LAST_CWD="${CWD:-}"

    nek_funeral_active || return 1
    nek_funeral_is_rumor_place "$CWD" || return 1

    case "${NEK_FUNERAL_DAY:--1}" in
        ''|*[!0-9]*) return 1 ;;
    esac
    if declare -F uhrzeit_day >/dev/null 2>&1; then
        [ "$(uhrzeit_day)" -le "$NEK_FUNERAL_DAY" ] || return 1
    fi

    OUT+=("")
    OUT+=("$(nek_funeral_rumor_text)")
    return 0
}
