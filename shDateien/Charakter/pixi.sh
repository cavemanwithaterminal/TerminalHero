# ============================================================
#  TerminalHero - Charakter & Quest: Pixi Nullpunkt
# ------------------------------------------------------------
#  Eine Datenjournalistin der Untergrund-Zeitung /var/log/daily-pulse.
#  Sie war in der abgeriegelten Root-Zone, wurde von einem Hunter gesehen
#  und flüchtet über den Schreibtisch in die Stadt (DesktopCity). Dort
#  tarnt sie sich als Datei »Pixi«; am Haupttor liefert sie sich mit dem
#  Torwächter ein Wortgefecht.
#
#  EAGER geladen: pixi_apply_state bringt beim (frischen) Start und nach
#  dem Laden eines Spielstands ihren Quest-Stand ins Dateisystem. Ihre
#  Datei liegt immer dort, wo sie gerade ist - nach der Baracken-Szene
#  (Charakter/verlag.sh) ist sie zurück im Verlag und schreibt am Artikel.
#  Dort wird sie mit »touch« angesprochen (pixi_letter_scene): sie gibt dem
#  Agenten den Brief für Sherlock Holmes mit (Hauptquest »Großer Ermittler«).
#  Ist der Brief bei Holmes abgegeben (SHERLOCK_BRIEF, siehe
#  Charakter/SherlockHolmes.sh), berichtet der Agent ihr die Nacht
#  (pixi_report_scene) - damit ist die Quest abgeschlossen (200 EXP).
#  Danach fehlt nur noch das Papier aus Jacks Zeitungsquest; sobald auch
#  die durch ist, bietet Pixi den Stadtrundgang an (pixi_after_article_scene,
#  RUNDGANG_GIVEN/RUNDGANG_DONE, 1000 EXP).
# ============================================================

# Pixi erscheint/verschwindet im Dateisystem. Die Mechanik (TYPE + CHILDREN)
# steckt in kern/fs.sh (fs_add/fs_remove) - sie wird auch von anderen
# Figuren gebraucht, die ihren Ort wechseln.
pixi_add()    { fs_add "$1" "$2"; }
pixi_remove() { fs_remove "$1"; }
pixi_dir() {
    if [ "${PIXI_GUIDE_DONE:-0}" = "1" ] && [ "${BARACKE_SCENE_DONE:-0}" != "1" ]; then
        # Sie geht in die Baracke voraus und wartet dort (Charakter/verlag.sh).
        printf '%s' "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Süddistrikt/EingestürzteBaracke"
    elif [ "${VERLAG_DONE:-0}" = "1" ] && [ "${PIXI_GUIDE_DONE:-0}" != "1" ]; then
        # Der Abschied im Verlag ist durch, aber die Baracken-Szene noch nicht
        # gelaufen: Pixi ist unterwegs. Dann liegt sie NIRGENDS (kein Pfad) -
        # sonst stünde sie im Verlag, obwohl sie laut Story längst raus ist.
        printf '%s' ""
    elif [ "${PIXI_HALL_DONE:-0}" = "1" ]; then
        printf '%s' "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Süddistrikt/DailyPulse"
    elif [ "${PIXI_GATE_DONE:-0}" = "1" ]; then
        printf '%s' "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang"
    else
        printf '%s' "$HOME_DIR/Schreibtisch/DesktopCity"
    fi
}
pixi_file_path() {
    local d; d="$(pixi_dir)"
    [ -n "$d" ] && printf '%s/Pixi' "$d"
}
pixi_file_text() {
    printf '%s\n' \
        "[DATEI]  Pixi Nullpunkt   ::   /var/log/daily-pulse" \
        "Reporterin. Zuletzt gesehen: hier – mitten in der Menge." \
        "──────────────────────────────────────────────" \
        "Status : in der Stadt (~/Schreibtisch/DesktopCity)" \
        "Form   : Datei. Ein User würde sagen: »getarnt«." \
        "" \
        "»Die Wahrheit hat keinen Pfad. Sie IST der Link.«" \
        "" \
        "cat Pixi  →  sie lesen"
}
# Pixi ist an einem Ort verschwunden: Datei, Inhalt UND Gespräch entfernen.
pixi_gone() { pixi_remove "$1"; unset "CONTENT[$1]" "DIALOG[$1]" 2>/dev/null; }
pixi_apply_state() {
    local in_city="$HOME_DIR/Schreibtisch/DesktopCity/Pixi"
    local in_hall="$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Pixi"
    local in_press="$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Süddistrikt/DailyPulse/Pixi"
    local in_baracke="$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Süddistrikt/EingestürzteBaracke/Pixi"
    local P; P="$(pixi_file_path)"

    if [ "${PIXI_DESKTOP_DONE:-0}" != "1" ]; then
        pixi_gone "$in_city"; pixi_gone "$in_hall"
        pixi_gone "$in_press"; pixi_gone "$in_baracke"
        return 0
    fi
    # Nur den aktuellen Standort behalten, die übrigen räumen.
    [ "$P" = "$in_city" ]  || pixi_gone "$in_city"
    [ "$P" = "$in_hall" ]  || pixi_gone "$in_hall"
    [ "$P" = "$in_press" ] || pixi_gone "$in_press"
    [ "$P" = "$in_baracke" ] || pixi_gone "$in_baracke"
    # Kein Pfad (sie ist unterwegs): dann bleibt sie überall geräumt.
    [ -n "$P" ] || return 0
    pixi_add f "$P"
    CONTENT["$P"]="$(pixi_file_text)"
    # Ansprechen (»touch Pixi«): erst der Brief an Holmes, sonst Smalltalk.
    DIALOG["$P"]="pixi_letter_scene"
}
pixi_intro_scene() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ UNBEKANNTER PROZESS · DIREKTVERBINDUNG ═════")
    OUT+=("Quelle : ???    Signatur: pixi@daily-pulse    Status: UNGEPRÜFT")
    OUT+=("")
    render

    say "-" "Kaum im Benutzerverzeichnis angekommen, rennt dir eine Datei über den Weg."
    say "-" "Keuchend. Sichtbar in Eile. Ihre Zeilen flattern wie ein zerrissener Feed."
    say "-" "Einen Lidschlag lang starrt sie dich an – dann reißt sie sich zusammen."
    OUT+=("")

    say "Pixi" "Okay, okay, okay – nicht panisch. Du bist der Neue, ja? Der aus dem Download-Archiv. Der nach den anderen."
    say "Pixi" "Hör zu: Ich war DORT. Im Root. In der Sperrzone. Nur kurz – gerade lang genug, um zu sehen, was da wirklich läuft."
    OUT+=("")
    say "-" "Ein leises PING. Nicht freundlich. Irgendwo hinter der Wand dieses Terminals."
    say "Pixi" "Und dann hat mich EINER angepingt. Ein Hunter-Killer-Daemon, getarnt als systemd-journal. Ich bin gerannt – Hardlink für Hardlink."
    say "Pixi" "Aber der Kerl hat meinen Inode markiert. Er WEISS, wo ich bin."
    OUT+=("")
    say "Pixi" "Ich bin Pixi. Pixel Nullpunkt. Reporterin bei /var/log/daily-pulse – die letzte Zeitung, die der Virus noch nicht gefressen hat."
    say "Pixi" "Du suchst den Virenkern, oder? Dann brauchst du AUGEN in der Stadt. Und ich kenne jeden Sektor."
    OUT+=("")
    say "Pixi" "Komm mit auf den Schreibtisch. Jetzt. Bevor der Hunter den Türrahmen sprengt."
    OUT+=("")
    OUT+=("── Verbindung bleibt instabil offen ──")
    OUT+=("[ NEUES ZIEL ]  Folge Pixi in den Schreibtisch:   cd Schreibtisch")
    dialog_pause
    DIALOG_ACTIVE=0
    DIALOG_HINT=""
}
pixi_desktop_scene() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ PIXI · FLÜCHTIGE VERBINDUNG ═════")
    OUT+=("Quelle : pixi@daily-pulse    Status : IN BEWEGUNG")
    OUT+=("")
    render

    say "-" "Der Schreibtisch ist still. Zwischen den Dateien keine Spur von Pixi – nur ein Flackern, als hätte eben noch jemand hier gestanden."
    say "-" "Dann ein Ruck im Datenstrom. Sie ist da. Halb. Angeschlagen."
    OUT+=("")
    say "Pixi" "Da bist du ja. Keine Zeit für lange Reden – der Hunter hat meine Spur aufgenommen."
    say "Pixi" "Hier sind wir nicht sicher. Der Schreibtisch steht offen wie ein Fenster im Sturm."
    say "Pixi" "Komm – folge mir in die Stadt. In den Ordner DesktopCity. Dort verliere ich mich in der Menge."
    OUT+=("")
    say "-" "Ein Zucken, ein Reißen – die Verbindung bricht ab. Pixi stürzt in den Ordner DesktopCity."
    OUT+=("")
    OUT+=("[ NEUES ZIEL ]  Folge Pixi in die Stadt:   cd DesktopCity")
    OUT+=("Dort:   ls   →   Pixi")
    dialog_pause
    DIALOG_ACTIVE=0
    DIALOG_HINT=""
    PIXI_DESKTOP_DONE=1
    pixi_apply_state
}
pixi_gate_scene() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ STADTTOR · HAUPTEINGANG ═════")
    OUT+=("Ort : ~/Schreibtisch/DesktopCity    Status : EINLASS GESPERRT")
    OUT+=("")
    render

    say "-" "Vor dir das Haupttor der Stadt. Davor ein alter Prozess – massiv, verbissen, seit Jahren auf demselben Posten: Simon Guard."
    say "-" "Pixi bremst kurz vor der Schwelle. Sie weiß, was jetzt kommt."
    OUT+=("")
    say "Simon Guard" "Halt. Immer dieselbe. Du warst doch bestimmt wieder im Sperrgebiet, Pixi."
    say "Simon Guard" "Ein Wunder, dass du überhaupt noch lebst."
    say "Simon Guard" "Und irgendwann werden dir die Viren folgen – hierher, mitten unter uns. Und dann sind wir alle in Gefahr."
    OUT+=("")
    say "Pixi" "Jemand muss das Risiko eingehen. Wir müssen doch Dinge in Erfahrung bringen."
    say "Pixi" "Ach, du bist doch bloß ein Feigling. Sei lieber froh, dass ich dir die gefährlichen Aufgaben abnehme."
    OUT+=("")
    say "Simon Guard" "Feigling? Ich nenne es Verantwortung. Hinter diesem Tor hängen Dateien, die auf mich zählen."
    say "-" "Der Wächter verschränkt die Arme. Pixi verdreht die Augen – und dreht sich zu dir."
    OUT+=("")
    say "Pixi" "Statt mit mir zu streiten: Wie siehst du das? Du bist doch auf meiner Seite, oder?"
    ask "Pixi hat recht. Ohne Risiko kein Fortschritt." \
        "Der Wächter hat recht. Sicherheit geht vor." \
        "Ich bin neu hier. Trotzdem will ich Antworten, keinen Stillstand."
    case "$CHOICE" in
        1) say "Simon Guard" "Begeisterung ist billig. Ihr redet, als wäre der Virus bloß eine weitere Aufgabe."
           say "Pixi" "Siehst du? Der Neue hat es verstanden. Er geht voraus – mit mir." ;;
        2) say "Simon Guard" "Endlich jemand, der den Kopf benutzt."
           say "Pixi" "Na toll. Da habe ich mir ja einen grandiosen Verbündeten geangelt." ;;
        3) say "Pixi" "Genau. Unwissen ist das, was der Virus am liebsten frisst."
           say "Simon Guard" "Kluge Worte für jemanden, der heute seinen ersten Tag hier hat." ;;
    esac
    OUT+=("")
    say "Simon Guard" "Und selbst wenn ihr recht hättet – wer haftet, wenn die Viren durch dieses Tor kommen? Ihr?"
    say "Pixi" "Ich. Es wäre mein Problem, nicht deins. Genau das versuche ich dir seit Jahren zu erklären."
    say "-" "Simon Guard schweigt lange. Sein Blick wandert von Pixi zu dir. Dann zu den fünf Distrikten hinter ihm."
    OUT+=("")
    say "Simon Guard" "Eine Bedingung."
    ask "Abgemacht. Wir halten uns daran." \
        "Ist das dein Ernst? Eine Bedingung?" \
        "»Irgendwer« ist eine ziemlich dehnbare Kategorie."
    case "$CHOICE" in
        1) say "Simon Guard" "Wenigstens einer, der Wort hält." ;;
        2) say "Simon Guard" "Mein Tor, meine Bedingung. So einfach ist das."
           say "Pixi" "Nimm sie an. Er sucht nur nach einem Grund, endlich ja zu sagen." ;;
        3) say "Simon Guard" "Nicht hier. Hinter diesem Tor ist jeder Einzelne »irgendwer«."
           say "Pixi" "Er hat recht. Leider." ;;
    esac
    say "Simon Guard" "Wenn hier irgendwer zu Schaden kommt – irgendwer –, dann rede ich kein zweites Mal mit euch."
    say "Pixi" "Abgemacht."
    OUT+=("")
    say "Simon Guard" "Also gut, Pixi. Du kannst rein. Und dein Begleiter auch."
    say "Simon Guard" "Aber merk dir eins: Irgendwann überleg ich es mir anders."
    OUT+=("")
    say "-" "Das Tor öffnet sich. Der Haupteingang atmet auf – und fällt hinter euch langsam wieder zu."
    say "Pixi" "Na also. Willkommen in der Stadt."
    say "Pixi" "Fünf Distrikte warten dahinter: Nord, Süd, West, Ost und das Zentrum. Jeder mit eigenen Regeln."
    say "Pixi" "Komm, folg mir in die Stadt!"
    OUT+=("")
    OUT+=("[ NEUES ZIEL ]  Folge Pixi in die Stadt:   cd Haupteingang")
    OUT+=("")
    OUT+=("─ Hinweis ───────────────────────────────────────")
    OUT+=("Du hast den Befehl »archive« gelernt.")
    OUT+=("Mit »archive« öffnest du dein Archiv und kannst")
    OUT+=("freigeschaltete Kapitelbilder wieder ansehen.")
    OUT+=("─────────────────────────────────────────────────")
    # »archive« am Ende des Gesprächs mit dem Torwächter und Pixi erlernen.
    require_gamecmd archive 2>/dev/null || th_source_once "$SCRIPT_DIR/InGameBefehle/archive.sh"
    local _learned_archive=0
    if ! knows archive 2>/dev/null; then
        LEARNED+=("archive")
        _learned_archive=1
    fi
    # Beim Erlernen von »archive«: Ortsbild "Desktop City" freischalten.
    # Anzeige erst NACH der Bestätigung mit Enter (nicht mitten im Dialog).
    if [ "$_learned_archive" = "1" ] && declare -F archive_ort_unlock >/dev/null 2>&1; then
        archive_ort_unlock desktopcity
    fi
    dialog_pause
    # Erst nach Enter: Desktop-City-Bild anzeigen (7s), dann zurück ins Spiel.
    if [ "$_learned_archive" = "1" ] && declare -F archive_show_ort_timed >/dev/null 2>&1; then
        archive_show_ort_timed desktopcity
        printf '%s' "$UI_BG"; clear
        FIRST_RENDER=1
    fi
    DIALOG_ACTIVE=0
    DIALOG_HINT=""
    # Das Wortgefecht am Tor WAR das ausführliche Gespräch mit dem
    # Torwächter: danach hat er nur noch seinen kurzen Standard-Dialog.
    TORWAEHTER_DONE=1
    PIXI_GATE_DONE=1
    pixi_apply_state
}
pixi_hall_scene() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ HAUPTEINGANG · ENDLICH DRIN ═════")
    OUT+=("Ort : ~/Schreibtisch/DesktopCity/Haupteingang    Status : SICHER (vorerst)")
    OUT+=("")
    render

    say "Pixi" "So, endlich in der Stadt. Jetzt sind wir vorerst sicher."
    OUT+=("")
    say "Pixi" "Ich hab's dir vorhin nur halb gesagt, also noch mal in Ruhe: Ich bin Pixi. Pixi Nullpunkt."
    say "Pixi" "Ich schreibe für /var/log/daily-pulse – die letzte Zeitung, die der Virus noch nicht gefressen hat."
    say "Pixi" "Und ich bin gut darin. Gut genug, dass man mich am Haupttor sofort erkennt."
    OUT+=("")
    say "Pixi" "Hey – ich muss zum Zeitungsverlag »DailyPulse«. Wenn du willst, kannst du ja vorbeikommen."
    say "Pixi" "Der Verlag liegt im Süddistrikt. Frag dort nach mir, dann sehen wir weiter."
    OUT+=("")
    say "-" "Ein kurzer Wink, ein Flackern – und Pixi ist zwischen den Dateien verschwunden. Diesmal in den Süden."
    OUT+=("")
    OUT+=("[ NEUES ZIEL ]  Pixi folgen:   cd Süddistrikt/DailyPulse")
    dialog_pause
    DIALOG_ACTIVE=0
    DIALOG_HINT=""
    PIXI_HALL_DONE=1
    pixi_apply_state
}
pixi_maybe_intro() {
    [ "${HOME_FIRST_VISIT:-0}" = "1" ] && return 0
    [ "${TUT_DONE:-0}" = "1" ] || return 0
    [ "$CWD" = "$HOME_DIR" ] || return 0
    HOME_FIRST_VISIT=1
    pixi_intro_scene
}
pixi_maybe_desktop() {
    [ "${HOME_FIRST_VISIT:-0}" = "1" ] || return 0
    [ "${PIXI_DESKTOP_DONE:-0}" = "1" ] && return 0
    [ "$CWD" = "$HOME_DIR/Schreibtisch" ] || return 0
    pixi_desktop_scene
}
pixi_maybe_gate() {
    [ "${PIXI_DESKTOP_DONE:-0}" = "1" ] || return 0
    [ "${PIXI_GATE_DONE:-0}" = "1" ] && return 0
    case "$CWD" in
        "$HOME_DIR/Schreibtisch/DesktopCity"|"$HOME_DIR/Schreibtisch/DesktopCity"/*) ;;
        *) return 0 ;;
    esac
    pixi_gate_scene
}
pixi_maybe_hall() {
    [ "${PIXI_GATE_DONE:-0}" = "1" ] || return 0
    [ "${PIXI_HALL_DONE:-0}" = "1" ] && return 0
    [ "$CWD" = "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang" ] || return 0
    pixi_hall_scene
}

# --- Gespräch: Pixi im Verlag (»touch Pixi«) ---------------------------
# Nach der Baracken-Szene ist Pixi zurück im Verlag und schreibt an ihrem
# Artikel über die Sperrzone. Hier bekommt der Agent den Brief für den
# Detektiv Sherlock Holmes (Detektei Holmes, Ostdistrikt) mit – die
# Hauptquest »Großer Ermittler« beginnt (siehe InGameBefehle/questlog.sh).
pixi_letter_scene() {
    # Bericht nach der Detektei: eigene Szene (siehe pixi_report_scene).
    if [ "${BARACKE_SCENE_DONE:-0}" = "1" ] \
       && [ "${SHERLOCK_BRIEF:-0}" = "1" ] \
       && [ "${ERMITTLER_DONE:-0}" != "1" ]; then
        pixi_report_scene
        return
    fi
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ DAILYPULSE · REDAKTION · AM ARTIKEL ═════")
    OUT+=("Ort : Süddistrikt    Pixi : am Schreiben")
    OUT+=("")
    render

    # Vor der Baracken-Szene hat sie keine Zeit dafür.
    if [ "${BARACKE_SCENE_DONE:-0}" != "1" ]; then
        say "Pixi" "Nicht jetzt – erst bringe ich dich unter. Danach reden wir."
        dialog_pause
        DIALOG_ACTIVE=0; DIALOG_HINT=""
        return
    fi

    # Quest ist durch: Standardgespräch mit Papier-Hinweis und Rundgang.
    if [ "${ERMITTLER_DONE:-0}" = "1" ]; then
        pixi_after_article_scene
        return
    fi

    # Schon erledigt: kurze Erinnerung statt der ganzen Szene.
    if [ "${PIXI_LETTER_DONE:-0}" = "1" ]; then
        say "Pixi" "Der Brief liegt bei dir. Holmes, Ostdistrikt, Detektei Holmes – persönlich abgeben, ja?"
        say "Pixi" "Und die Stadt zeige ich dir, sobald Seite eins steht."
        dialog_pause
        DIALOG_ACTIVE=0; DIALOG_HINT=""
        return
    fi

    say "-" "Über dem Schreibtisch brennt eine Lampe; ringsum Setzkästen, Korrekturbögen und ein kalter Kaffee. Pixi sitzt davor und merkt erst nach einem Moment, dass jemand hereinkommt."
    say "-" "Auf dem Tisch ein Block voller Notizen, ein kalter Kaffee, ein Stapel Korrekturbögen. Ihre Finger halten mitten im Wort inne."
    say "Pixi" "Du! Gut, dass du da bist. Ich schreibe gerade den Artikel über den Root."
    say "Pixi" "Rachel will Seite eins: Belege, Zahlen, keine Andeutungen. Also sitze ich hier, bis es stimmt."
    OUT+=("")
    say "$AGENT_NAME" "Du wolltest mir die Stadt zeigen."
    say "Pixi" "Will ich. Aber erst, wenn das hier draußen ist – sonst frisst mich Rachel bei lebendigem Inode."
    say "Pixi" "Bis dahin habe ich aber etwas für dich."
    OUT+=("")
    say "-" "Sie zieht einen Umschlag unter der Tastatur hervor, mit Klebeband umwickelt: gegen Feuchtigkeit und gegen neugierige Hände."
    say "Pixi" "Ein Brief. Für Sherlock Holmes."
    say "Pixi" "Detektei Holmes, im Ostdistrikt. Frag nicht nach dem Namen – den hat er sich selbst ausgesucht."
    OUT+=("")
    say "$AGENT_NAME" "Wer ist Holmes?"
    say "Pixi" "Ein Detektiv. Nicht der mit dem Dienstausweis, der mit dem Kopf."
    say "Pixi" "Er löst Fälle, die die Stadt längst zu den Akten gelegt hat. Wenn er etwas nicht glaubt, glaubt es niemand."
    OUT+=("")
    say "Pixi" "Ich war im Root. Und ich bin nicht sicher, ob ich gesehen habe, was ich gesehen habe."
    say "Pixi" "In einen Artikel gehört ein Beweis. In einen Brief gehört ein Verdacht. Deshalb Holmes."
    say "-" "Sie schiebt den Umschlag über den Tisch. Er ist ein Stück schwerer, als ein Umschlag sein sollte."
    say "Pixi" "Bring ihn hin. Persönlich. Holmes nimmt nichts an, was er nicht selbst angefasst hat."
    OUT+=("")
    PIXI_LETTER_DONE=1
    inv_add pixisbrief
    OUT+=("   [ Inventar ]  »Pixis Brief« – ansehen mit »inventar«.")
    quest_gained ermittler
    OUT+=("")
    OUT+=("[ NEUES ZIEL ]  Brief abgeben:   cd Ostdistrikt   →   cd DetekteiHolmes")
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# --- Gespräch: Bericht an Pixi (»touch Pixi« nach der Detektei) --------
# Der Agent hat Sherlock Holmes den Brief übergeben und erzählt Pixi, was in
# der Nacht passiert ist. Damit ist die Hauptquest »Großer Ermittler«
# abgeschlossen (Belohnung 200 EXP).
pixi_report_scene() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ DAILYPULSE · BERICHT AUS DER NACHT ═════")
    OUT+=("Ort : Süddistrikt    Pixi : wartet auf Antwort")
    OUT+=("")
    render

    say "-" "Pixi sitzt über ihrem Artikel, aber die Hände liegen still. Als du hereinkommst, steht sie auf."
    say "Pixi" "Du bist zurück. Und?"
    say "$AGENT_NAME" "Holmes hat den Brief. Er hat ihn noch in der Nacht gelesen."
    say "Pixi" "Gelesen. Und?"
    say "$AGENT_NAME" "»Interessant«, hat er gesagt. Und beunruhigend."
    say "-" "Pixi schnaubt kurz - halb Lachen, halb Erleichterung."
    say "Pixi" "Beunruhigend. Aus seinem Mund ist das ein ganzer Artikel."
    OUT+=("")
    say "-" "Du erzählst ihr den Rest: den getarnten Virus zwischen den Laternen, die Verfolgung, die Katze, den Sprung in den Norddistrikt."
    say "Pixi" "Er ist entwischt."
    say "Pixi" "Dann weiß er jetzt, dass ihm jemand folgt. Das ist kein Erfolg - das ist eine Warnung."
    say "Pixi" "Aber es beweist, dass da draußen etwas ist, das sich tarnt und wegläuft. Genau das habe ich gesehen."
    OUT+=("")
    say "Pixi" "Der Brief ist raus. Danke - wirklich."
    say "Pixi" "Ich kann den Bericht über das Sperrgebiet jetzt zu Ende schreiben. Mit Zeugen."
    if [ "${ZEITUNG_DONE:-0}" = "1" ]; then
        say "Pixi" "Und das Papier ist auch schon da. Jack hat die letzte Ausgabe zurückgeholt."
        say "Pixi" "Dann kann ich drucken – und danach habe ich endlich Zeit für den Rundgang."
    else
        say "Pixi" "Der Artikel ist so gut wie fertig. Es fehlt nur noch das Papier zum Drucken."
        say "Pixi" "Das kommt, sobald Jack seine letzte Zeitungsausgabe zurückgeholt hat. Danach hätte ich Zeit für den Stadtrundgang mit dir."
    fi
    say "-" "Sie zieht den Block heran und setzt sich hin. Diesmal ohne zu zögern."
    ERMITTLER_DONE=1
    quest_reward ermittler 200
    say "Pixi" "Wir sehen uns später."
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# ============================================================
#  Pixis Standardgespräch nach dem Artikel
# ------------------------------------------------------------
#  Nach »Großer Ermittler« ist der Artikel fertig, aber zum Drucken fehlt
#  das Papier aus Jacks Quest »Die langweiligste Ausgabe«. Erst wenn auch
#  ZEITUNG_DONE gesetzt ist, hat Pixi Zeit für den Stadtrundgang. Sie
#  macht ihn nur zwischen 06:00 und 14:00; danach schickt sie den Agenten
#  auf einen neuen Termin.
# ============================================================
pixi_tour_time_ok() {
    uhrzeit_running || return 1
    local m
    m=$(( ( CLOCK_START_MIN + $(uhrzeit_minutes) ) % CLOCK_DAY_MIN ))
    [ "$m" -ge 360 ] && [ "$m" -lt 840 ]
}

pixi_after_article_scene() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ DAILYPULSE · REDAKTION · NACH DEM ARTIKEL ═════")
    OUT+=("Ort : Süddistrikt    Pixi : zwischen Druck und Rundgang")
    OUT+=("")
    render

    # Der Rundgang ist vorbei: kurze Erinnerung, kein zweiter Durchlauf.
    # Danach richtet sich ihr Standardgespräch nach dem Stand der neuen
    # Sperrzone-Ausgabe.
    if [ "${RUNDGANG_DONE:-0}" = "1" ]; then
        if [ "${AUFLAGE_DONE:-0}" = "1" ]; then
            say "Pixi" "Die Sperrzone-Ausgabe ist raus. Überall in der Stadt."
            say "Pixi" "Ich habe heute Morgen drei Leute vor dem Kasten stehen sehen. Einer hat sie zweimal gekauft."
            say "Pixi" "Ich kann es immer noch nicht erwarten, die Meinung der Leute zu hören. Die werden ihren Augen nicht trauen!"
            say "Pixi" "Danke, dass du sie rausgebracht hast. Wirklich."
        elif [ "${AUFLAGE_GIVEN:-0}" = "1" ]; then
            say "Pixi" "Die Sperrzone-Ausgabe ist unterwegs. Rachel wartet auf deinen Bericht, sobald alle fünf Kästen voll sind."
            say "Pixi" "Und Jimmy Page wartet sicher auch schon. Der liest schneller, als wir drucken können."
        else
            say "Pixi" "Der Rundgang war gut. Du kennst jetzt die Orte, an denen die Stadt arbeitet, trinkt und schweigt."
            say "Pixi" "Mama hat die neue Ausgabe fertig gedruckt. Frag sie, ob sie noch jemanden für die Kästen braucht."
            say "Pixi" "Wenn du noch etwas wissen willst, frag die Leute. Die meisten reden lieber über sich als über den Virus."
        fi
        dialog_pause
        DIALOG_ACTIVE=0; DIALOG_HINT=""
        return
    fi

    # Der Artikel ist durch, aber das Papier fehlt noch.
    if [ "${ZEITUNG_DONE:-0}" != "1" ]; then
        say "Pixi" "Der Artikel ist geschrieben. Rachel hat ihn schon gelesen und will ihn drucken."
        say "Pixi" "Es fehlt nur noch das Papier. Jack muss dafür seine letzte Ausgabe aus den Kästen zurückholen."
        if [ "${ZEITUNG_GIVEN:-0}" = "1" ]; then
            say "Pixi" "Er hat die fünf Kästen noch nicht leer. Hilf ihm, dann können wir drucken."
        else
            say "Pixi" "Frag Jack im Verlag. Er weiß, wo die Kästen stehen – und warum er selbst nicht loskommt."
        fi
        say "Pixi" "Sobald das Papier da ist, mache ich den Rundgang mit dir. Versprochen."
        dialog_pause
        DIALOG_ACTIVE=0; DIALOG_HINT=""
        return
    fi

    # Beide Voraussetzungen sind erfüllt: Zeitfenster prüfen.
    if pixi_tour_time_ok; then
        say "Pixi" "Das Papier ist da, der Artikel ist gedruckt. Endlich."
        say "Pixi" "Ich würde dir die Stadt zeigen – die wichtigen Orte und die Leute, die dort etwas zu sagen haben."
        say "Pixi" "Aber nur morgens oder vormittags. Zwischen 06:00 und 14:00, solange ich noch klar denken kann."
        say "Pixi" "Willst du?"
        ask "Rundgang machen." "Ein andermal."
        if [ "$CHOICE" = "2" ]; then
            say "Pixi" "Gut. Aber nicht zu spät. Um 14:00 bin ich wieder an der Redaktion."
            dialog_pause
            DIALOG_ACTIVE=0; DIALOG_HINT=""
            return
        fi
        say "Pixi" "Bist du bereit? Es dauert ein Weilchen, und ich rede viel."
        ask "Ja, lass uns gehen." "Nein, noch nicht."
        if [ "$CHOICE" = "2" ]; then
            say "Pixi" "Dann ein andermal. Ich bin bis 14:00 hier."
            dialog_pause
            DIALOG_ACTIVE=0; DIALOG_HINT=""
            return
        fi
        # Das Gespräch kann das Zeitfenster gesprengt haben - lieber neu
        # terminieren als nach 14:00 loszulaufen.
        if ! pixi_tour_time_ok; then
            say "Pixi" "Es ist später geworden. Für heute ist es zu spät – komm morgen zwischen 06:00 und 14:00 wieder."
            dialog_pause
            DIALOG_ACTIVE=0; DIALOG_HINT=""
            return
        fi
        pixi_tour_scene
        return
    fi

    say "Pixi" "Das Papier ist da, der Artikel ist gedruckt. Jetzt hätte ich Zeit für den Rundgang."
    say "Pixi" "Aber nur morgens oder vormittags – zwischen 06:00 und 14:00. Danach gehört die Redaktion wieder mir."
    say "Pixi" "Komm in diesem Zeitfenster wieder, dann laufen wir los."
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# ============================================================
#  Stadtrundgang
# ------------------------------------------------------------
#  Pixi führt, der Agent folgt automatisch. Jeder Ortswechsel setzt CWD,
#  Pfadfenster und Ordnerfenster direkt - ohne »cd«/»pwd«/»ls« und damit
#  ohne Tokenkosten. An jedem Distriktende wartet Pixi per ask auf die
#  Bestätigung »Ja, lass uns weiter gehen.«
# ============================================================
pixi_tour_go() {   # $1 = Zielpfad
    local np="$1" k
    [ -n "$np" ] || return 0
    if [ "$np" != "$CWD" ]; then
        OLDPWD="$CWD"
        CWD="$np"
    fi
    VIEW_DIR="$CWD"
    SHOW_PATH=1
    SHOW_LS=1
    LS_SHOW_ALL=0
    # Eine gezogene Leiche folgt Pixi und dem Agenten durch die Stadt.
    declare -F neks_leiche_follow_cwd >/dev/null 2>&1 && neks_leiche_follow_cwd
    k="$(district_key_of_path "$CWD")"
    if [ "$k" != "${DISTRICT_ACTIVE:-}" ]; then
        DISTRICT_ACTIVE="$k"
        [ -n "$k" ] && district_load "$k"
    elif [ -n "$k" ]; then
        district_load "$k"
    fi
    return 0
}

pixi_tour_stop() {   # $1 = Überschrift des Distrikts
    OUT+=("")
    OUT+=("═════ STADTRUNDGANG · $1 ═════")
    OUT+=("")
    SCROLL=0
    render
}

pixi_tour_ready() {   # $1 = nächster Halt
    say "Pixi" "Das war der Rundgang durch diesen Bezirk. Bereit für $1?"
    ask "Ja, lass uns weiter gehen."
}

pixi_tour_scene() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ STADTRUNDGANG MIT PIXI ═════")
    OUT+=("Start : DailyPulse-Verlag    Führung: Pixi Nullpunkt")
    OUT+=("")
    quest_gain_once rundgang
    RUNDGANG_GIVEN=1
    render

    say "Pixi" "Also gut. Der Rundgang beginnt hier – im DailyPulse. Redaktion, Wohnung und der Ort, an dem die letzte Zeitung der Stadt entsteht."
    say "Pixi" "Wir gehen einmal durch alle fünf Distrikte. Ich zeige dir, wo man arbeitet, wo man trinkt und wo man besser nicht nachts allein langgeht."
    say "Pixi" "Eine Sache noch, damit du keine Umwege läufst: Du kannst jeden Stadtteil direkt ausschreiben."
    say "Pixi" "Also »cd Ostdistrikt«, »cd Westdistrikt«, »cd Zentrum« – von überall aus. Du musst nicht erst mit »cd ..« bis zum Haupteingang zurück."
    say "Pixi" "Du musst nichts eingeben. Bleib einfach hinter mir – pwd und ls übernehme ich."
    say "-" "Sie tritt aus der Redaktion auf die Straße. Du folgst ihr."

    # --- Süddistrikt -------------------------------------------------
    pixi_tour_go "$(district_path_by_name "Süddistrikt")"
    pixi_tour_stop "SÜDDISTRIKT"
    say "-" "Im Süddistrikt angekommen, bleibt Pixi vor dem Verlag stehen und dreht sich zu dir um."
    say "Pixi" "Süddistrikt. Der erste Bezirk hinter dem Tor – und der, in dem du gerade wohnst."
    if [ "${AMANDA_HELP_JACK:-0}" = "1" ]; then
        say "Pixi" "Hinter uns: der DailyPulse-Verlag. Rachel am Setztisch, Jack jetzt in der Detektei – und irgendwann die nächste Ausgabe."
    else
        say "Pixi" "Hinter uns: der DailyPulse-Verlag. Rachel am Setztisch, Jack am Papier – und irgendwann die nächste Ausgabe."
    fi
    say "Pixi" "Der Zeitungskasten davor gehört uns. Zehn Bits, und du weißt, was in der Stadt passiert ist."
    say "-" "Sie zeigt die Gasse hinunter."
    say "Pixi" "Die vier Wohnhäuser da hinten sind so alt wie das Tor. Wer hier wohnt, hat es nicht weit zur Arbeit – und noch weniger weit zum Lärm."
    say "Pixi" "Und die eingestürzte Baracke kennst du schon. Dein Nachtlager. Nicht schön, aber ein Dach."
    say "Pixi" "Der Süden ist kein Ort für große Pläne. Er ist der Ort, an dem man ankommt und merkt, dass die Stadt größer ist als das Tor."
    pixi_tour_ready "das Zentrum"

    # --- Zentrum -----------------------------------------------------
    pixi_tour_go "$(district_path_by_name "Zentrum")"
    pixi_tour_stop "ZENTRUM"
    say "-" "Im Zentrum angekommen, öffnet sich vor euch der Marktplatz. Zwischen den Ständen riecht es nach Brot, Öl und nassem Holz."
    say "Pixi" "Zentrum. Das Herz der Stadt – und der lauteste Ort, den der Virus noch übrig gelassen hat."
    say "Pixi" "Die Stände: Brot, Öl, Kabel, Ersatzteile. Was du nicht findest, findet Samy Cage."
    say "Pixi" "Samy ist Lagermeister. Er zählt jede Kiste, jede Lieferung und jede Ausrede. Wenn du etwas brauchst, das offiziell nicht existiert, frag ihn trotzdem."
    say "Pixi" "Da drüben: der SurvivalShop von Jack Bones. Fackeln, Schlafsäcke, Dinge für Leute, die zu oft nachts unterwegs sind."
    say "Pixi" "Und gleich daneben die Schmiede von Bruno Amboss. Ruß, Eisen und ein zweites Sortiment: das Einfache Set und sein Kampfset."
    say "Pixi" "Bruno repariert, was andere wegwerfen, und verkauft Klingen, Ketten und einen Ring, der die Tokens schneller zurückholt. Wenn du vorhast, öfter in dunkle Ecken zu gehen, ist er dein Mann."
    say "Pixi" "Und die Sitzbank am Rand? Setz dich nicht zu lange hin. Hier verkauft jeder seine Zeit – nur du hast noch keine."
    pixi_tour_ready "den Ostdistrikt"

    # --- Ostdistrikt -------------------------------------------------
    pixi_tour_go "$(district_path_by_name "Ostdistrikt")"
    pixi_tour_stop "OSTDISTRIKT"
    say "-" "Im Ostdistrikt angekommen, wird die Straße schmaler. Über einer Tür hängt ein Schild: Detektei Holmes."
    say "Pixi" "Ostdistrikt. Der Bezirk, in dem die Stadt ihre Geheimnisse aufbewahrt."
    say "Pixi" "Die Detektei Holmes. Amanda Nox führt das Vorzimmer und weiß mehr, als sie sagt. Holmes selbst ist nur nachts draußen – er glaubt, die Stadt gehört dann ihm."
    say "Pixi" "Ich bin gespannt, was Sherlock von meinem Artikel über die Sperrzone hält – sobald die Ausgabe zum Verkauf steht."
    say "Pixi" "Die Kneipe »Zum Goldenen Lächeln«. Börty Smiles steht seit drei Generationen hinter der Theke. Er hört alles, was die Stadt erzählt, und verkauft es weiter – wenn der Preis stimmt."
    say "Pixi" "Weiter hinten: Jimmys Haus. Jimmy Page sammelt Zeitungen und kommt selbst nicht mehr raus. Wenn du eine Ausgabe hast, bring sie ihm – er zahlt besser als die Kästen."
    say "Pixi" "Und die Gasse vor Jimmys Haus? Da hat Tracey ihre Übergaben gemacht. Frag Rachel, wenn du wissen willst, warum."
    pixi_tour_ready "den Norddistrikt"

    # --- Norddistrikt ------------------------------------------------
    pixi_tour_go "$(district_path_by_name "Norddistrikt")"
    pixi_tour_stop "NORDDISTRIKT"
    say "-" "Im Norddistrikt angekommen, wird es still. Keine Stände, keine Musik – nur Fenster, die zu lange zu sind."
    say "Pixi" "Norddistrikt. Der stillste Teil der Stadt. Hier hört man jeden Schritt."
    say "Pixi" "Deshalb ist Holmes während der Verfolgung hierher gekommen – und deshalb ist er fast entwischt."
    say "Pixi" "Noch ist hier nicht viel. Ein Zeitungskasten, eine Sitzbank, ein paar Straßen, die nirgendwohin führen. Aber die Stadt wächst. Irgendwann stehen hier andere Häuser."
    say "Pixi" "Wenn du nachts unterwegs bist, geh nicht allein. Nicht wegen der Viren. Wegen der Leute, die glauben, niemand sieht sie."
    pixi_tour_ready "den Westdistrikt"

    # --- Westdistrikt ------------------------------------------------
    pixi_tour_go "$(district_path_by_name "Westdistrikt")"
    pixi_tour_stop "WESTDISTRIKT"
    say "-" "Im Westdistrikt angekommen, werden die Straßen breiter. Vor dem Restaurant stehen Stühle, die jemand jeden Abend hinausträgt."
    say "Pixi" "Westdistrikt. Breitere Straßen, höhere Fenster – und das Restaurant."
    say "Pixi" "Dort arbeitet Michael Mitch. Börtys Lagergehilfe. Er wollte nicht zurück, und ich kann ihm das nicht mal übel nehmen."
    say "Pixi" "Das Essen ist gut. Die Stühle sind weich. Und die Hinterzimmer sind genau so dunkel, wie Leute sie brauchen, die nicht gesehen werden wollen."
    say "Pixi" "Wenn du jemanden suchst, der verschwunden ist, ist das ein guter Ort, um anzufangen. Oder aufzuhören."
    pixi_tour_ready "den Rückweg zum DailyPulse"

    # --- Zurück in den Verlag ---------------------------------------
    pixi_tour_go "$(verlag_dir)"
    pixi_tour_stop "ZURÜCK IM DAILYPULSE"
    say "-" "Wieder im DailyPulse angekommen, bleibt Pixi vor der Redaktion stehen. Rachel sieht kurz auf, nickt euch zu und tippt weiter."
    say "Pixi" "So. Das war der Rundgang. Süden, Zentrum, Osten, Norden, Westen – und wieder zurück."
    say "Pixi" "Jetzt kennst du die wichtigsten Orte und die Leute, die dort etwas zu sagen haben."
    say "Pixi" "Du weißt, wo du Bier bekommst, wo Akten liegen, wo Zeitungen gedruckt werden – und wo man nachts besser nicht allein langgeht."
    say "Pixi" "Danke, dass du mitgekommen bist. Ich hoffe, es hat dir gefallen."
    say "Pixi" "Ach, und bevor ich es vergesse: Mama müsste die neue Ausgabe inzwischen fertig gedruckt haben."
    say "Pixi" "Die über die Sperrzone. Sie liegt drinnen in der Redaktion. Frag sie, ob sie noch Hilfe beim Verteilen braucht."
    say "Rachel" "Ihr lebt noch. Gut."
    say "Pixi" "Immer."
    # Die neue Ausgabe ist jetzt Realität: Tracey und die Kästen kennen
    # sie, sobald Rachel die Verteilung freigibt. Bis dahin sind alle
    # fünf Kästen leer und warten auf die fünf Bündel.
    if declare -F zeitung_await_distribution >/dev/null 2>&1; then
        zeitung_await_distribution sperrzone
    else
        ZEITUNG_EDITION=sperrzone
        ZEITUNG_EMPTIED=31
    fi
    RUNDGANG_DONE=1
    quest_reward rundgang 1000
    pixi_apply_state
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}
