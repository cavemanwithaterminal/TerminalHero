# ============================================================
#  TerminalHero - Charakter: Detektiv Sherlock Holmes
#
#  Die Detektei »Holmes« liegt im Ostdistrikt. Er selbst ist dort tagsüber
#  NICHT anzutreffen - im Vorzimmer sitzt seine Assistentin Amanda Nox
#  (Charakter/AmandaNox.sh). Zwischen 22:00 und 04:00 steht er draußen im
#  Ostdistrikt und lässt sich ansprechen (touch).
#
#  EAGER geladen (require_char SherlockHolmes): die Hauptschleife ruft
#  sherlock_schedule_apply bei jedem Wechsel der Spielminute auf, damit er
#  mit Einbruch der Nacht erscheint und am Morgen wieder verschwindet.
#  Die Mechanik dafür (TYPE + CHILDREN) steckt in kern/fs.sh (fs_add/fs_remove).
#
#  STORY (Hauptquest »Großer Ermittler«): Hat der Agent Pixis Brief dabei
#  und trifft Holmes nachts im Ostdistrikt, nimmt die Begegnung ihren Lauf:
#
#    1. VERFOLGUNG (SHERLOCK_HUNT) - Holmes verfolgt einen getarnten Virus
#       durch den Ostdistrikt. Eine schwarze Katze verrät die Verfolger; die
#       Datei flieht in den Norddistrikt. Holmes rennt hinterher, der Agent
#       folgt AUTOMATISCH (agent_move_to) - Holmes wartet drüben.
#    2. NORDDISTRIKT (SHERLOCK_NORD) - die Spur ist kalt. Holmes geht vor in
#       die Detektei; der Agent muss selbst folgen (cd Ostdistrikt).
#    3. DETEKTEI (sherlock_office_scene, automatisch beim Betreten) - Holmes
#       erzählt Amanda, was passiert ist; danach übergibt der Agent den Brief
#       (100 EXP) und bekommt den Auftrag, Pixi Bericht zu erstatten
#       (SHERLOCK_BRIEF).
#    4. VERLAG (Charakter/pixi.sh, pixi_report_scene) - der Agent berichtet
#       Pixi. Damit ist »Großer Ermittler« abgeschlossen (200 EXP).
#
#  Ohne Brief bleibt es beim kurzen »Nicht jetzt«-Auftritt (SHERLOCK_DONE).
# ============================================================

# --- Wo Holmes gerade ist ------------------------------------------------
# Normalerweise nachts im Ostdistrikt; während der Verfolgung im Norddistrikt
# und danach (Tag wie Nacht) in der Detektei.
sherlock_ost_dir()  { printf '%s' "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Ostdistrikt"; }
sherlock_nord_dir() { printf '%s' "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Norddistrikt"; }
sherlock_det_dir()  { printf '%s/DetekteiHolmes' "$(sherlock_ost_dir)"; }

sherlock_dir() {
    if [ "${SHERLOCK_HUNT:-0}" = "1" ] && [ "${SHERLOCK_NORD:-0}" != "1" ]; then
        # Die Verfolgung endete im Norden: er wartet mitten auf der Straße.
        sherlock_nord_dir
    elif [ "${SHERLOCK_NORD:-0}" = "1" ]; then
        # Zurück in der Detektei - dort arbeitet er weiter.
        sherlock_det_dir
    elif sherlock_night_now; then
        sherlock_ost_dir
    else
        printf '%s' ""
    fi
}
sherlock_file_path() {
    local d; d="$(sherlock_dir)"
    [ -n "$d" ] && printf '%s/Sherlock' "$d"
}

# Ist gerade Nacht (22:00–04:00)? Ohne laufende Uhr steht die Spielzeit
# still auf 06:00 (Spielbeginn) - dann ist er nicht unterwegs.
sherlock_night_now() {
    local m h
    m=$(( CLOCK_START_MIN + $(uhrzeit_minutes) ))
    m=$(( m % CLOCK_DAY_MIN ))
    h=$(( m / 60 ))
    [ "$h" -ge 22 ] || [ "$h" -lt 4 ]
}

sherlock_file_text() {
    local status="auf einer Spur"
    if [ "${SHERLOCK_HUNT:-0}" = "1" ] && [ "${SHERLOCK_NORD:-0}" != "1" ]; then
        status="im Norddistrikt - die Spur ist kalt"
    elif [ "${SHERLOCK_NORD:-0}" = "1" ]; then
        status="in der Detektei"
    fi
    printf '%s\n' \
        "[DATEI]  Sherlock Holmes   ::   Detektei Holmes, Ostdistrikt" \
        "Detektiv. Nachts im Bezirk unterwegs - die Stadt ist dann ruhiger als er." \
        "──────────────────────────────────────────────" \
        "Status : $status" \
        "Form   : Datei. Ein User würde sagen: »getarnt«." \
        "" \
        "»Wenn du alles ausschließt, was unmöglich ist," \
        " bleibt das Wahre übrig - und das Wahre schläft nie.«" \
        "" \
        "cat Sherlock  →  ihn lesen"
}

# Ihn erscheinen oder verschwinden lassen (idempotent). Wird aufgerufen,
# wenn sich die Spielminute ändert, und beim Aufbau des Ostdistrikts.
# Er kann an drei Orten stehen - die beiden anderen werden geräumt.
sherlock_schedule_apply() {
    local p q; p="$(sherlock_file_path)"
    for q in "$(sherlock_ost_dir)/Sherlock" "$(sherlock_nord_dir)/Sherlock" \
             "$(sherlock_det_dir)/Sherlock"; do
        [ "$q" = "$p" ] && continue
        fs_remove "$q"
        unset "CONTENT[$q]" "DIALOG[$q]" 2>/dev/null
    done
    [ -n "$p" ] || return 0
    fs_add f "$p"
    CONTENT["$p"]="$(sherlock_file_text)"
    DIALOG["$p"]="dialog_sherlock"
    return 0
}

# Den Agenten von einer Szene aus woandershin setzen (wie »cd«, nur ohne
# Eingabe): Am Ende der Verfolgung läuft er Holmes hinterher in den
# Norddistrikt. Der Stadtteilwechsel selbst passiert danach in der
# Hauptschleife (district_sync) - samt Betreten-Meldung.
agent_move_to() {
    local np="$1"
    [ -n "$np" ] || return 0
    [ "$np" = "$CWD" ] && return 0
    district_ensure "$np"
    OLDPWD="$CWD"
    CWD="$np"
    VIEW_DIR="$np"
    # Eine gezogene Leiche folgt auch bei automatischen Ortswechseln.
    declare -F neks_leiche_follow_cwd >/dev/null 2>&1 && neks_leiche_follow_cwd
    # Wie nach einem echten »cd«: Pfad und Ordnerinhalt erst wieder
    # mit »pwd«/»ls« zeigen.
    SHOW_PATH=0
    SHOW_LS=0
    return 0
}

# --- Gespräch (»touch Sherlock«) -----------------------------------------
# Wo er steht, entscheidet, was passiert (siehe Kopf dieser Datei).
# Das Antreffen wird in SHERLOCK_DONE festgehalten: Der Agent hat ihn
# gefunden - damit bietet Börty seine Holmes-Auskunft nicht mehr an
# (Charakter/BörtySmiles.sh).
dialog_sherlock() {
    SHERLOCK_DONE=1
    if [ "${SHERLOCK_HUNT:-0}" = "1" ] && [ "${SHERLOCK_NORD:-0}" != "1" ]; then
        sherlock_nord_scene
    elif [ "${SHERLOCK_NORD:-0}" = "1" ]; then
        sherlock_office_talk
    elif [ "${PIXI_LETTER_DONE:-0}" = "1" ]; then
        sherlock_hunt_scene
    else
        sherlock_short_scene
    fi
}

# Ohne Brief: der kurze Auftritt (unverändert).
sherlock_short_scene() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ OSTDISTRIKT · NACHT · DETEKTIV AUF SPUR ═════")
    OUT+=("Ziel : Sherlock Holmes    Status : auf einer Spur")
    OUT+=("")
    render

    say "-" "Unter einer flackernden Laterne hält jemand eine Akte ins Licht. Mantel, wacher Blick, jeder Schritt gemessen. Er sieht dich, bevor du ihn siehst."
    say "Sherlock" "Nicht jetzt."
    say "Sherlock" "Ich habe einen Fall - und er läuft nicht weg. Schlimmer: er läuft."
    say "Sherlock" "Der Ostdistrikt ist nachts kein Ort für lange Gespräche. Auch nicht für mich."
    say "-" "Er klappt die Akte zu, nickt dir knapp zu und geht weiter, ohne sich noch einmal umzudrehen."
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# Mit Brief: Holmes' Auftritt, die Übergabe-Ankündigung - und die Verfolgung.
sherlock_hunt_scene() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ OSTDISTRIKT · NACHT · DETEKTIV AUF SPUR ═════")
    OUT+=("Ziel : Sherlock Holmes    Status : auf einer Spur")
    OUT+=("")
    render

    say "-" "Unter einer flackernden Laterne hält jemand eine Akte ins Licht. Mantel, wacher Blick, jeder Schritt gemessen. Er sieht dich, bevor du ihn siehst."
    say "Sherlock" "Nicht jetzt."
    say "Sherlock" "Ich habe einen Fall - und er läuft nicht weg. Schlimmer: er läuft."
    say "Sherlock" "Der Ostdistrikt ist nachts kein Ort für lange Gespräche. Auch nicht für mich."
    say "-" "Er klappt die Akte zu und setzt zum Gehen an."
    OUT+=("")
    say "$AGENT_NAME" "Warten Sie. Ich habe einen Brief von Pixi - für Sie."
    say "-" "Er bleibt stehen. Nicht abrupt; eher, als hätte er die Frage erwartet."
    say "Sherlock" "Pixi, ja?"
    say "Sherlock" "Dann wird es wichtig sein. Sie schreibt nichts, was sie nicht meint."
    say "Sherlock" "Aber erst muss ich mich um etwas anderes kümmern."
    OUT+=("")
    say "-" "Er deutet mit dem Kinn die Straße hinunter. Zwischen den Laternen bewegt sich etwas - langsam, gleichmäßig, immer im Schatten der Hauswände. Eine Datei, die sich tarnt."
    say "Sherlock" "Siehst du das? Das ist kein Passant. Das ist ein Muster."
    say "Sherlock" "Folge mir. Aber mach keinen Mucks."
    OUT+=("")
    say "-" "Ihr folgt ihm durch die Gassen - zwei Straßen, drei Ecken, immer zwei Schritte dahinter. Holmes bleibt bei jeder Laterne stehen und wartet, bis die Datei weiterzieht."
    say "-" "Dann tritt er in der Dunkelheit auf etwas Weiches. Ein schwarzer Schatten schießt unter seinem Fuß hervor - und MIUAT so laut, dass der Schall von den Fassaden zurückkommt."
    say "-" "Die getarnte Datei hält inne. Dreht sich halb. Und sieht die beiden Verfolger zum ersten Mal."
    say "Sherlock" "Verdammt."
    say "-" "Ein Zucken, ein Reißen - und sie ist fort, schneller als vorher. Nicht verschwunden, nur nicht mehr einzuholen: auf dem Weg in den Norddistrikt."
    say "Sherlock" "Komm schnell. Folge mir!"
    say "-" "Du läufst Sherlock hinterher in den Norddistrikt."
    SHERLOCK_HUNT=1
    agent_move_to "$(sherlock_nord_dir)"
    sherlock_schedule_apply
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# Im Norddistrikt: die Spur ist kalt, Holmes geht vor in die Detektei.
sherlock_nord_scene() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ NORDDISTRIKT · NACHT · DIE SPUR IST KALT ═════")
    OUT+=("Ort : Norddistrikt    Status : entwischt")
    OUT+=("")
    render

    say "-" "Der Norddistrikt ist leer. Keine Laterne brennt, kein Fenster steht offen - nur Sherlock, der mitten auf der Straße steht und sich langsam umsieht."
    say "Sherlock" "Verdammt. Er ist mir entwischt."
    say "-" "Er bleibt stehen und atmet einmal aus. Kein Fluch, kein Tritt gegen die Wand. Er legt den Ärger nur woandershin."
    say "Sherlock" "Das lief nicht wie geplant. Aber ich habe keine Zeit, mich darüber zu ärgern."
    say "Sherlock" "Komm, folge mir in die Detektei."
    say "-" "Er geht vor, ohne sich umzudrehen - als wäre selbstverständlich, dass du folgst."
    OUT+=("")
    OUT+=("[ NEUES ZIEL ]  Folge Sherlock in die Detektei:   cd ../Ostdistrikt   →   cd DetekteiHolmes")
    SHERLOCK_NORD=1
    sherlock_schedule_apply
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# In der Detektei (»touch Sherlock«): nach »Großer Ermittler« hat er Arbeit
# für den Agenten. Vorher bleibt es beim knappen »Nicht jetzt.«
sherlock_office_talk() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ DETEKTEI HOLMES · BÜRO ═════")
    OUT+=("Ort : Ostdistrikt    Status : beschäftigt")
    OUT+=("")
    render

    if [ "${ERMITTLER_DONE:-0}" != "1" ]; then
        if [ "${SHERLOCK_BRIEF:-0}" = "1" ]; then
            say "Sherlock" "Nicht jetzt. Ich habe den Brief - und damit mehr Arbeit als vorher."
            say "Sherlock" "Pixi wartet auf eine Antwort. Amanda weiß, wo die Akten liegen."
        else
            say "Sherlock" "Nicht jetzt. Der Fall ist kalt und ich muss mir etwas ansehen - in Ruhe."
        fi
        say "-" "Er beugt sich wieder über den Tisch. Das Gespräch ist beendet - höflich und endgültig."
        dialog_pause
        DIALOG_ACTIVE=0; DIALOG_HINT=""
        return
    fi

    # Nach der abgeschlossenen Hauptquest darf der Agent seine Hilfe anbieten.
    say "-" "Holmes hebt den Blick von den Akten. Auf dem Tisch liegt ein Stapel, der höher ist als gestern."
    say "Sherlock" "Da bist du ja. Gut, dass du hereinschaust."
    local opts=() acts=()
    while true; do
        opts=(); acts=()
        opts+=("Kann ich dir helfen?"); acts+=("helfen")
        if [ "${SHERLOCK_BOOK_DONE:-0}" != "1" ] \
           && inv_has schweinepriesters_tagebuch; then
            opts+=("Ich habe dieses Buch gefunden."); acts+=("buch")
        fi
        opts+=("Nichts weiter.");       acts+=("zurueck")
        OUT+=("")
        ask "${opts[@]}"
        case "${acts[$((CHOICE - 1))]}" in
            helfen)
                sherlock_help_menu ;;
            buch)
                sherlock_book_scene ;;
            zurueck)
                say "Sherlock" "Dann entschuldige mich. Die Akten warten nicht."
                break ;;
        esac
    done
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# ============================================================
#  Das SchweinePriester's Tagebuch bei Sherlock Holmes
# ------------------------------------------------------------
#  Holmes ist verblüfft und belustigt, lacht kurz – und wird dann
#  wieder ganz Detektiv. Er rät, der Spur weiter zu folgen. Einmalig
#  +300 EXP und ein Questlog-Eintrag.
# ============================================================
sherlock_book_scene() {
    if [ "${SHERLOCK_BOOK_DONE:-0}" = "1" ]; then
        say "Sherlock" "Das Tagebuch? Ich habe es gelesen. Ein bemerkenswertes Dokument."
        say "Sherlock" "Folge der Spur. Und lass dich nicht von einem sprechenden Schwein aufhalten."
        return 0
    fi

    if declare -F tagebuch_ensure_religion_quest >/dev/null 2>&1; then
        tagebuch_ensure_religion_quest
    fi

    say "$AGENT_NAME" "Ich habe dieses Buch gefunden."
    say "-" "Holmes nimmt es, öffnet es mitten im Buch und liest eine halbe Seite, ohne mit der Wimper zu zucken."
    say "Sherlock" "Hm."
    say "-" "Dann liest er die nächste Seite. Und die nächste. Irgendwann entkommt ihm ein kurzes, trockenes Lachen."
    say "Sherlock" "Ha."
    say "$AGENT_NAME" "Was?"
    say "Sherlock" "Nichts. Nur … selten sowas zu lesen bekommen."
    say "-" "Er lacht noch einmal, leiser, und klappt das Buch zu."
    say "Sherlock" "Ein SchweinePriester. Der mit einer Molerat-Königin spricht und eine verlorene Zivilisation dokumentiert."
    say "Sherlock" "Entweder ist der Mann verrückt, oder er hat etwas gesehen, das die Stadt lieber nicht sehen will."
    OUT+=("")
    say "-" "Er streicht sich mit zwei Fingern über die Augenbraue. Das Lachen ist weg; der Detektiv ist wieder da."
    say "Sherlock" "Die Handschrift ist konsistent. Die Beobachtungen sind zu genau für Fantasie."
    say "Sherlock" "Und der Fundort passt zu dem, was du über die Tunnel gesagt hast."
    say "Sherlock" "Folge der Spur weiter. Wenn dieser Priester noch lebt, weiß er mehr als jede Akte in diesem Büro."
    say "Sherlock" "Aber sei vorsichtig. Wer eine Königin beschreibt, war nah genug, um sie zu wecken."

    SHERLOCK_BOOK_DONE=1
    if declare -F quest_note >/dev/null 2>&1; then
        quest_note "Sherlock: Das Tagebuch ist bemerkenswert. Der SchweinePriester könnte noch leben – der Spur weiter folgen."
    fi
    play_sound select
    OUT+=("")
    OUT+=("   [ Belohnung ]  300 EXP")
    char_gain_exp 300
    return 0
}

# ============================================================
#  Auftragsauswahl bei Sherlock Holmes
# ------------------------------------------------------------
#  Holmes hat nach »Großer Ermittler« mehr Aufträge als ihm lieb ist.
#  Die Auswahl läuft als eigene Schleife; »Zurück.« führt in das
#  Gespräch davor (sherlock_office_talk) zurück.
# ============================================================
sherlock_teach_ls_a() {
    if [ -n "${SHERLOCK_LS_A_DONE:-}" ]; then
        say "Sherlock" "Du beherrschst ls -a bereits. Versteckte Dinge verraten sich nur dem, der gezielt danach sucht."
        return 0
    fi
    if [ "${SKILL_POINTS:-0}" -lt 5 ] 2>/dev/null || ! bits_has 250; then
        play_sound error
        say "Sherlock" "Für ls -a brauchst du 5 Skillpunkte und 250 Bits."
        say "Sherlock" "Komm wieder, wenn du beides hast. Beobachtung ist nicht umsonst."
        return 1
    fi
    SKILL_POINTS=$(( ${SKILL_POINTS:-0} - 5 ))
    bits_take 250 || true
    OUT+=("   [ Skillpunkte ]  -5   ·   [ Bits ]  -250 Bits")
    if declare -F learn_cmd >/dev/null 2>&1; then
        learn_cmd "ls"
    fi
    SHERLOCK_LS_A_DONE=1
    play_sound select
    say "Sherlock" "Gut aufgepasst. Mit »ls -a« zeigst du auch versteckte Einträge an."
    say "Sherlock" "Manche Spuren sind absichtlich verborgen. Nur wer hinsieht, findet sie."
    return 0
}

sherlock_help_menu() {
    local opts=() acts=()
    say "Sherlock" "Mehr Aufträge, als mir lieb ist. Die Stadt produziert Fälle schneller, als ich sie abarbeiten kann."
    say "Sherlock" "Ich könnte jemanden gebrauchen, der mir etwas abnimmt - diskret und ohne große Fragen."
    while true; do
        opts=(); acts=()
        if [ "${ERMITTLER_DONE:-0}" = "1" ] && [ -z "${SHERLOCK_LS_A_DONE:-}" ]; then
            opts+=("ls -a lernen (5 Skillpunkte, 250 Bits)"); acts+=("lsa")
        elif [ "${ERMITTLER_DONE:-0}" = "1" ] && [ -n "${SHERLOCK_LS_A_DONE:-}" ]; then
            opts+=("ls -a (bereits erlernt)"); acts+=("lsadone")
        fi
        opts+=("Seltsame Religion"); acts+=("religion")
        opts+=("Zurück.");           acts+=("zurueck")
        OUT+=("")
        say "Sherlock" "Was willst du dir ansehen?"
        ask "${opts[@]}"
        case "${acts[$((CHOICE - 1))]}" in
            lsa) sherlock_teach_ls_a ;;
            lsadone) say "Sherlock" "Du kennst den Trick bereits." ;;
            religion) sherlock_religion_scene ;;
            zurueck)  return 0 ;;
        esac
    done
}

# ============================================================
#  Auftrag: »Seltsame Religion«
# ------------------------------------------------------------
#  Holmes' Gerücht: eine neue, verschlossene Religion mit Molerat-Bezug.
#  Die Quest wird nur einmal vergeben (quest_gain_once religion); das
#  Flag RELIGION_GIVEN hält das Ergebnis fest. Die Spur führt in die
#  Kneipe »Zum Goldenen Lächeln« zu Novize Bill.
# ============================================================
sherlock_religion_scene() {
    if [ "${RELIGION_GIVEN:-0}" = "1" ]; then
        say "Sherlock" "Wegen der seltsamen Religion? Die Spur ist noch dieselbe."
        say "Sherlock" "Wenn du etwas hörst, fang bei den Leuten an, die zu viel trinken und zu wenig sagen."
        return 0
    fi

    say "Sherlock" "Es gibt da etwas, das mir keine Ruhe lässt."
    say "Sherlock" "Eine relativ neue Religion. Ihre Mitglieder sind ziemlich verschlossen - sie reden nicht über ihren Glauben, nicht mit Fremden und schon gar nicht mit der Wache."
    say "Sherlock" "Gerüchten zufolge ist die Sache verstörend. Und nicht ungefährlich."
    say "-" "Er schiebt eine Akte über den Tisch. Sie ist dünn; fast alles darin ist durchgestrichen."
    say "Sherlock" "Und angeblich hat sie etwas mit Molerats zu tun."
    say "$AGENT_NAME" "Molerats? Die Viecher aus den Höhlen?"
    say "Sherlock" "Dieselben. Ich weiß nicht, ob das stimmt. Ich weiß nur, dass Leute, die darüber reden, plötzlich nicht mehr darüber reden."
    OUT+=("")
    say "Sherlock" "Erkundige dich. Leise, freundlich und ohne Uniform."
    OUT+=("")
    if declare -F quest_gain_once >/dev/null 2>&1 && quest_gain_once religion; then
        RELIGION_GIVEN=1
        quest_note "Sherlock Holmes: Eine neue, verschlossene Religion soll mit Molerats zu tun haben."
        OUT+=("[ NEUES ZIEL ]  Erkundige dich in der Kneipe »Zum Goldenen Lächeln« (Ostdistrikt).")
        OUT+=("                 Sprich dort mit den Gästen – zum Beispiel an der Theke.")
    else
        RELIGION_GIVEN=1
    fi
    return 0
}

# --- Szene: Detektei (Holmes erzählt Amanda, der Agent übergibt den Brief) --
# Läuft AUTOMATISCH beim Betreten der Detektei (sherlock_maybe_office).
sherlock_office_scene() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ DETEKTEI HOLMES · VORZIMMER ═════")
    OUT+=("Ort : Ostdistrikt    Zeit : nach der Verfolgung")
    OUT+=("")
    render

    say "-" "Die Detektei ist noch dunkel; nur über Amandas Schreibtisch brennt eine Lampe. Sie schreibt, als wäre es der hellste Nachmittag."
    say "-" "Holmes tritt ein, ohne sich den Mantel abzunehmen. Du bleibst im Türrahmen stehen."
    OUT+=("")
    say "Amanda" "Mr. Holmes. Sie sind zurück."
    say "Sherlock" "Ich bin zurück."
    say "Amanda" "Und der Fall?"
    say "Sherlock" "Weg. Er hat mich gesehen und ist in den Norden geflohen."
    say "Amanda" "Sie hatten ihn?"
    say "Sherlock" "Ich hatte ihn."
    say "-" "Pause. Draußen flackert eine Laterne."
    say "Sherlock" "Ich bin auf eine Katze getreten."
    say "-" "Amanda legt die Feder hin und sieht ihn an, ohne mit der Wimper zu zucken."
    say "Amanda" "Eine Katze."
    say "Sherlock" "Es war dunkel."
    say "Amanda" "Es ist immer dunkel, wenn Sie draußen sind. Das ist keine Entschuldigung, das ist ein Dienstplan."
    OUT+=("")
    say "-" "Dann zieht sie ein Formular unter dem Stapel hervor und streicht zwei Zeilen durch. Sehr zügig."
    say "Amanda" "Gut. Dann schreibe ich heute Nacht keinen Bericht."
    say "Sherlock" "Amanda."
    say "Amanda" "Ich habe nichts gesagt, Mr. Holmes. Ich habe etwas gestrichen."
    OUT+=("")
    say "-" "Holmes sieht kurz zu ihr hinüber - und lässt es dabei. Dann fällt sein Blick auf dich."
    say "Sherlock" "Ah, da bist du ja."
    say "Sherlock" "Du sagtest, du hättest einen Brief von Pixi. Für mich."
    say "$AGENT_NAME" "Persönlich. Sie hat mir eingeschärft, ihn nicht aus der Hand zu geben."
    say "-" "Du legst den Umschlag auf den Tisch. Holmes bricht das Klebeband auf, faltet den Bogen auseinander und liest."
    say "-" "Sein Gesicht verändert sich nicht. Seine Augen tun es."
    say "Sherlock" "Interessant. Und beunruhigend."
    OUT+=("")
    inv_remove pixisbrief
    OUT+=("   [ Belohnung ]  100 EXP")
    char_gain_exp 100
    say "Sherlock" "Du kannst Pixi ausrichten: Wenn sie Hilfe braucht, kann sie sich an mich wenden."
    say "Sherlock" "Und du hast meinen Dank - der ist hier selten und deshalb etwas wert."
    say "Sherlock" "Jetzt entschuldige mich. Ich muss mir ein paar Dinge ansehen, solange die Nacht noch dauert."
    say "-" "Er nickt dir zu. Dann verschwindet er in seinem Büro und lässt die Tür einen Spalt offen."
    OUT+=("")
    OUT+=("[ NEUES ZIEL ]  Berichte Pixi:   cd ../../Süddistrikt/DailyPulse")
    SHERLOCK_BRIEF=1
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# --- Auslöser (nach jedem Befehl in der Hauptschleife) -------------------
# Betritt der Agent die Detektei, während Holmes von der Verfolgung zurück
# ist, läuft das Gespräch mit Amanda - genau einmal.
sherlock_maybe_office() {
    [ "${SHERLOCK_NORD:-0}" = "1" ] || return 0
    [ "${SHERLOCK_BRIEF:-0}" = "1" ] && return 0
    [ "$CWD" = "$(sherlock_det_dir)" ] || return 0
    sherlock_office_scene
    return 0
}
