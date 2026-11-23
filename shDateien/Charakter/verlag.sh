# ============================================================
#  TerminalHero - Story: Zeitungsverlag DailyPulse (Familie)
# ------------------------------------------------------------
#  Der Verlag im Süddistrikt ist Redaktion UND Zuhause von Pixis
#  Familie:
#     Rachel Nullpunkt - Besitzerin & Chefredakteurin. Professionell,
#                        direkt, eine Frau, die aus allem eine Ausgabe
#                        macht.
#     Jack Nullpunkt   - Pixis Bruder. Ruhig, vorsichtig, rechnet
#                        lieber zweimal als einmal zu hoffen.
#
#  Diese Datei bringt die Story-Kette nach Pixis Ankunft in der Stadt:
#     1. verlag_family_scene  - Betreten des Verlags: Familiengespräch
#                               (Pixi berichtet aus dem Sperrgebiet, Rachel
#                               lehnt die Übernachtung ab -> Baracke).
#     2. verlag_sued_scene    - Süddistrikt: Pixi entschuldigt sich und
#                               geht in die Baracke voraus.
#     3. verlag_baracke_scene - Baracke: Pixi entdeckt die Armbanduhr und
#                               bringt dem Agenten »grep« bei; sie weist auf
#                               die Matratze hin und lehrt »use« (Schlafen),
#                               dann geht sie zurück in den Verlag.
#
#  Danach: Jacks Rückholquest »Die langweiligste Ausgabe« (die fünf
#  Zeitungskästen, Interior/Stadt/Zeitungskasten.sh), der clear-Unterricht
#  (1 Skillpunkt, vor der Quest zusätzlich 50 Bits) und die 3-Stunden-
#  Abgabe der fünf Zeitungsbündel.
#
#  Die Auslöser (verlag_maybe) hängen wie die Pixi-Trigger in der
#  Hauptschleife (TerminalShell.sh) und prüfen nur $CWD + Fortschritts-Flags
#  - dadurch feuert nach dem Laden eines Spielstands nichts doppelt.
#
#  EAGER geladen (require_char verlag): die Trigger müssen in der Schleife
#  bekannt sein; Rachel/Jack stehen als Dateien im Verlag (Orte/DailyPulse.sh)
#  und verweisen per DIALOG[] auf die Gespräche hier. Jack wechselt später
#  mit der Amanda-Nebenquest in die Detektei (jack_apply_state).
# ============================================================

# --- Orte ---------------------------------------------------------------
verlag_dir()      { printf '%s' "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Süddistrikt/DailyPulse"; }
verlag_sued_dir() { printf '%s' "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Süddistrikt"; }
verlag_baracke_dir() {
    printf '%s' "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Süddistrikt/EingestürzteBaracke"
}

# --- Wo Jack gerade ist ------------------------------------------------
# Bis zur Nebenquest »Unterstützung für Amanda« steht Jack im DailyPulse.
# Danach arbeitet er in der Detektei Holmes (Ostdistrikt) und wird dort
# mit »touch Jack« angesprochen. jack_apply_state hält den Stand idempotent
# - beim Start, beim Laden, beim Stadtteil-Aufbau und direkt nach dem Umzug.
jack_detektei_dir() {
    printf '%s/Schreibtisch/DesktopCity/Haupteingang/Ostdistrikt/DetekteiHolmes' "$HOME_DIR"
}

jack_press_file()  { printf '%s/Jack' "$(verlag_dir)"; }
jack_det_file()    { printf '%s/Jack' "$(jack_detektei_dir)"; }

jack_file_text() {
    local status="im DailyPulse-Verlag"
    [ "${AMANDA_HELP_JACK:-0}" = "1" ] && status="in der Detektei Holmes"

    printf '%s\n' \
        "[DATEI]  Jack Nullpunkt   ::   Bruder, Rechner, Papierhändler" \
        "Ruhig, vorsichtig, rechnet lieber zweimal als einmal zu hoffen." \
        "──────────────────────────────────────────────" \
        "Status : $status" \
        "Form   : Datei. Ein User würde sagen: »steht mit beiden Beinen im Satz«." \
        "" \
        "»Ich rechne lieber zweimal," \
        " als einmal zu hoffen.«" \
        "" \
        "touch Jack  →  mit ihm sprechen"
}

jack_gone() {   # $1 = Pfad
    fs_remove "$1"
    unset "CONTENT[$1]" "DIALOG[$1]" 2>/dev/null
}

jack_apply_state() {
    local press det p pdir
    press="$(jack_press_file)"
    det="$(jack_det_file)"

    if [ "${AMANDA_HELP_JACK:-0}" = "1" ]; then
        p="$det"
    else
        p="$press"
    fi

    [ "$p" = "$press" ] || jack_gone "$press"
    [ "$p" = "$det" ]   || jack_gone "$det"

    # Die Detektei bzw. der Verlag entstehen erst mit ihrem Stadtteil. Wer
    # noch nie dort war, bekommt Jack dort auch noch nicht angezeigt - der
    # jeweilige Stadtteil-Aufbau ruft jack_apply_state dann erneut auf.
    pdir="${p%/*}"
    [ -n "${TYPE[$pdir]:-}" ] || return 0
    [ -n "$p" ] || return 0

    fs_add f "$p"
    CONTENT["$p"]="$(jack_file_text)"
    if [ "$p" = "$det" ]; then
        DIALOG["$p"]="dialog_jack_detektei"
    else
        DIALOG["$p"]="dialog_jack"
    fi
    return 0
}

# --- Jacks Papierlager (Handelsfenster.sh) ----------------------------
# Jack verkauft leeres Papier an der Redaktion: pro Spieltag 100 einzelne
# Blätter und genau ein Bündel mit 100 Blättern. Der Grundbestand wird
# von handel_day_sync jeden neuen Spieltag wieder aufgefüllt.
handel_lager_jack() {
    th_source_if_fn handel_define
    declare -F handel_define >/dev/null 2>&1 || return 1
    handel_define jack "Jack Nullpunkt"
    handel_alias  jack "Jack" "Jacks" "Drucker"
    handel_stock  jack leeresblatt 100
    handel_stock  jack papierbuendel 1
    return 0
}

# Die Datei im Verlag heißt »Jack«; ihre Gesprächsfunktion ist aus der
# Familiengeschichte heraus benannt. Der Händler-Check (handel_here)
# sucht dagegen die Konvention dialog_<id> - dieser kurze Einstieg
# verbindet beides, damit auch »trade Jack« vor Ort funktioniert.
dialog_jack() {
    verlag_gespraech_jack
}

# --- Rachels Nebenquest: Finde Tracey ---------------------------------
# Nach der Baracken-Szene fragt sich Rachel, wo ihre Zeitungsausträgerin
# Tracey Briggs bleibt. Der Agent hat keine Wahl: Rachel besteht darauf,
# dass er sich darum kümmert. Die Quest ist absichtlich ohne ask() - es
# gibt kein »Ablehnen«.
verlag_rachel_tracey_offer() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ DAILYPULSE · CHEFREDAKTION ═════")
    OUT+=("Rachel Nullpunkt    Rolle: Besitzerin & Chefredakteurin")
    OUT+=("")
    render

    say "-" "Rachel tippt nicht mehr. Ihr Blick hängt an der Tür, als hätte sie dort etwas verloren."
    say "Rachel" "Sag mal – hast du Tracey gesehen? Tracey Briggs?"
    say "$AGENT_NAME" "Tracey Briggs?"
    say "Rachel" "Meine Zeitungsausträgerin. Sie sollte längst von ihrer Tour zurück sein."
    say "Rachel" "Sie hat heute Morgen die Ausgabe rausgebracht und ist nicht wieder aufgetaucht."
    say "Rachel" "Ich habe keine Zeit, ihr hinterherzulaufen. Du hast Beine. Also gehst du."
    say "$AGENT_NAME" "Und wenn sie einfach nur länger braucht?"
    say "Rachel" "Dann sagst du ihr, dass sie sich bei mir meldet. Persönlich."
    say "Rachel" "Sie steckt meistens im Ostdistrikt fest. Vor Jimmys Haus, dort hat sie eine Übergabe."
    say "Rachel" "Ich bestehe darauf, dass du dich darum kümmerst. Verstanden?"
    say "-" "Es ist keine Frage. Rachel hat schon wieder eine Seite aufgezogen, bevor du antworten kannst."

    # Rachels Vermisstenfall ist ein zweiter Weg in die Hauptquest
    # »Vermisste Bewohner« (questlog.sh erlaubt bewusst mehrere Vergabewege).
    if [ "${VERMISSTE_GIVEN:-0}" != "1" ]; then
        if quest_gain_once vermisste; then VERMISSTE_GIVEN=1; fi
    fi
    quest_gain_once tracey
    TRACEY_GIVEN=1
    quest_note "Rachel sucht Tracey Briggs – zuletzt im Ostdistrikt, vor Jimmys Haus."

    OUT+=("")
    OUT+=("[ NEUES ZIEL ]  Suche Tracey im Ostdistrikt:   cd Ostdistrikt   →   JimmysHaus")
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# Rachel erinnert nur, solange Tracey noch nicht gefunden wurde.
verlag_rachel_tracey_reminder() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ DAILYPULSE · CHEFREDAKTION ═════")
    OUT+=("Rachel Nullpunkt    Rolle: Besitzerin & Chefredakteurin")
    OUT+=("")
    render

    say "Rachel" "Tracey ist immer noch nicht zurück."
    say "Rachel" "Ostdistrikt. Vor Jimmys Haus. Ich warte nicht ewig."
    say "-" "Sie tippt weiter, ohne dich anzusehen."
    # Traceys Vermisstenfall bleibt Rachels dringendste Sorge, aber die
    # neue Auflage darf dadurch nicht unerreichbar werden.
    if [ "${RUNDGANG_DONE:-0}" = "1" ]; then
        if [ "${AUFLAGE_DONE:-0}" = "1" ]; then
            say "Rachel" "Die Sperrzone-Ausgabe liegt in allen fünf Kästen. Die Stadt liest wieder."
            ask "Neuste Auflage." "Später."
            if [ "$CHOICE" = "1" ]; then
                verlag_rachel_auflage_after
                return 0
            fi
        elif [ "${AUFLAGE_GIVEN:-0}" = "1" ]; then
            say "Rachel" "Und wie weit bist du mit den Kästen?"
            ask "Neuste Auflage." "Später."
            if [ "$CHOICE" = "1" ]; then
                verlag_rachel_auflage_status
                return 0
            fi
        else
            say "Rachel" "Wo du schon hier bist: Die neue Ausgabe ist fertig. Die über die Sperrzone."
            ask "Neuste Auflage." "Später."
            if [ "$CHOICE" = "1" ]; then
                verlag_rachel_auflage_offer
                return 0
            fi
        fi
    fi
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# Der Agent hat Tracey gefunden: Rachel bedankt sich, Tracey meldet sich
# zu Wort - und die Nebenquest ist abgeschlossen (100 EXP).
verlag_rachel_tracey_complete() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ DAILYPULSE · CHEFREDAKTION ═════")
    OUT+=("Rachel Nullpunkt    Rolle: Besitzerin & Chefredakteurin")
    OUT+=("")
    render

    say "-" "Tracey steht schon neben dem Setzkasten, den Korb an der Hüfte. Rachel sieht von ihrem Bildschirm auf."
    say "Rachel" "Du hast sie gefunden. Danke."
    say "Rachel" "Tracey. Das nächste Mal meldest du dich, bevor ich jemanden losschicke."
    say "Tracey" "Als hätte man mich suchen müssen. Du weißt doch, dass sich eh keiner mit mir anlegt."
    say "Rachel" "Tracey hat mir erzählt, dass sie alle Ausgaben losgeworden ist."
    say "Rachel" "Ehrlich gesagt wäre es mir lieber gewesen, sie hätte es nicht geschafft."
    say "$AGENT_NAME" "Warum das denn?"
    say "Rachel" "Weil ich dann wüsste, dass die Leute wenigstens Geschmack haben."
    say "Rachel" "Diese Ausgabe war eine langweilige Stadttour. Straßen, Karten, nichts. Ich hätte nicht gedacht, dass die jemals jemand kauft."
    say "Rachel" "Aber sie hat es tatsächlich geschafft. Überraschend."
    say "Tracey" "Ich bin gut."
    say "Rachel" "Hast bestimmt wieder bei Jimmy abkassiert?"
    say "Tracey" "Betriebsgeheimnis."
    say "-" "Rachel sieht sie lange an. Dann seufzt sie."
    say "Rachel" "Ich weiß, dass du mit deinen Verkäufen an Jimmy gutes Geld verdienst."
    say "Rachel" "Ich finde es nicht in Ordnung, so hohe Summen von ihm zu verlangen."
    say "Rachel" "Aber ich weiß auch, dass du als Tagelöhnerin nicht viel verdienst und sehen musst, wie du über die Runden kommst."
    say "Tracey" "Dann verstehst du es ja."
    say "Rachel" "Verstehen heißt nicht gutheißen."
    say "-" "Tracey grinst. Rachel schüttelt den Kopf, ohne wirklich böse zu sein."
    OUT+=("")
    OUT+=("[ NEUES ZIEL ]  Rachel hat wieder eine Ausgabe zu füllen. Frage sie nach der neuen Auflage.")

    TRACEY_DONE=1
    # Ab jetzt ist Tracey auf Stadttour. Die Startzeit wird gespeichert,
    # damit jede Station exakt 4 Spielstunden dauert (auch nach dem Laden).
    TRACEY_TOUR_START="$(uhrzeit_minutes)"
    declare -F tracey_apply_state >/dev/null 2>&1 && tracey_apply_state
    quest_reward tracey 100
    quest_note "Tracey ist wieder unterwegs. Rachel hat sich bedankt – Tracey zieht jetzt alle vier Spielstunden weiter."

    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# --- Rachels Hauptquest: Die neueste Auflage --------------------------
# Am Ende des Stadtrundgangs ist Pixis Artikel gedruckt. Rachel gibt dem
# Agenten fünf Bündel und den Zeitungskastenschlüssel; er muss jeden der
# fünf Kästen genau einmal befüllen. Es gibt keine Ablehnung: Rachel
# besteht darauf, dass die Stadt die neue Ausgabe liest.
verlag_auflage_boxes_filled() {
    if declare -F zeitung_boxes_filled >/dev/null 2>&1; then
        zeitung_boxes_filled
        return 0
    fi
    local i n=0
    for i in 0 1 2 3 4; do
        [ $(( ${ZEITUNG_EMPTIED:-0} & (1 << i) )) -eq 0 ] && n=$(( n + 1 ))
    done
    printf '%s' "$n"
}

verlag_rachel_auflage_offer() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ DAILYPULSE · CHEFREDAKTION ═════")
    OUT+=("Rachel Nullpunkt    Rolle: Besitzerin & Chefredakteurin")
    OUT+=("")
    render

    say "-" "Auf Rachels Tisch liegt ein frischer Stapel Zeitungen. Der Druck ist noch warm, die Kanten sind scharf."
    say "Rachel" "Da bist du ja. Die neue Ausgabe. Die über die Sperrzone."
    say "Rachel" "Pixi hat den Artikel geschrieben, Jack hat das Papier besorgt, ich habe gedruckt. Jetzt fehlt nur noch die Stadt."
    say "$AGENT_NAME" "Und was soll ich tun?"
    say "Rachel" "Du bringst sie raus. Fünf Bündel, fünf Zeitungskästen. Einer in jedem Bezirk."
    say "Rachel" "Den Schlüssel kennst du. Und bevor du fragst: Nein, du kannst nicht ablehnen. Die Stadt wartet nicht, und ich auch nicht."
    say "-" "Sie schiebt dir fünf verschnürte Pakete über den Tisch und legt den Schlüssel obenauf."
    say "Rachel" "Süden, Zentrum, Osten, Norden, Westen. Jeder Kasten genau einmal. Danach kommst du zurück und berichtest."
    say "Rachel" "Und lass dich nicht aufhalten. Jimmy Page wartet sicher schon auf ein Exemplar."

    quest_gain_once auflage
    AUFLAGE_GIVEN=1
    # Tracey ist nicht mehr im Verlag: Ist ihre eigene Quest schon
    # abgeschlossen, läuft ihre Stadttour weiter; sonst steht sie wieder
    # im Ostdistrikt. tracey_apply_state entscheidet das.
    declare -F tracey_apply_state >/dev/null 2>&1 && tracey_apply_state
    if declare -F zeitung_await_distribution >/dev/null 2>&1; then
        zeitung_await_distribution sperrzone
    else
        ZEITUNG_EDITION=sperrzone
        ZEITUNG_EMPTIED=31
    fi
    if ! inv_has zeitungsschluessel; then
        inv_add zeitungsschluessel
    fi
    inv_add sperrzonebuendel 5

    OUT+=("")
    OUT+=("   [ Zeitungskastenschlüssel ]  erhalten")
    OUT+=("   [ Sperrzone-Bündel ]         +5")
    OUT+=("[ NEUES ZIEL ]  Fülle die fünf Zeitungskästen:   use Zeitungskasten")
    quest_note "Rachel: Die Sperrzone-Ausgabe muss in alle fünf Zeitungskästen – je ein Bündel."

    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# Zwischenstand, solange noch nicht alle fünf Kästen befüllt sind. Sind
# alle voll, kann der Agent den Bericht hier abschließen.
verlag_rachel_auflage_status() {
    local n bundles missing
    n="$(verlag_auflage_boxes_filled)"
    bundles="$(inv_count sperrzonebuendel)"

    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ DAILYPULSE · CHEFREDAKTION ═════")
    OUT+=("Rachel Nullpunkt    Rolle: Besitzerin & Chefredakteurin")
    OUT+=("")
    render

    say "Rachel" "Wie weit bist du?"

    if [ "$n" -ge 5 ] 2>/dev/null; then
        say "$AGENT_NAME" "Alle fünf Kästen sind befüllt. Die Sperrzone-Ausgabe liegt in der ganzen Stadt."
        say "Rachel" "Alle fünf? Dann her mit dem Bericht."
        ask "Bericht erstatten." "Später."
        if [ "$CHOICE" = "1" ]; then
            verlag_rachel_auflage_complete
            return 0
        fi
        say "Rachel" "Gut. Aber lass mich nicht zu lange warten."
    else
        say "$AGENT_NAME" "Ich habe ${n} von 5 Kästen befüllt."
        say "Rachel" "Dann sind noch $(( 5 - n )) offen. Süden, Zentrum, Osten, Norden, Westen."
        # Sicherheitsnetz: Questbündel können nicht verkauft werden. Falls
        # ein alter Stand sie dennoch verloren hat, gibt Rachel den Rest.
        if [ "$bundles" -lt "$(( 5 - n ))" ] 2>/dev/null; then
            missing=$(( 5 - n - bundles ))
            inv_add sperrzonebuendel "$missing"
            OUT+=("")
            OUT+=("   [ Sperrzone-Bündel ]  +${missing}   (fehlende Bündel von Rachel)")
            say "Rachel" "Und nimm die fehlenden Bündel mit. Zähl sie diesmal."
        fi
        say "Rachel" "Die Kästen stehen in den Bezirken. Du weißt, wo."
    fi

    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

verlag_rachel_auflage_complete() {
    local rpath ppath
    rpath="$(verlag_dir)/Rachel"
    ppath="$(verlag_dir)/Pixi"

    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ DAILYPULSE · CHEFREDAKTION ═════")
    OUT+=("Rachel Nullpunkt    Rolle: Besitzerin & Chefredakteurin")
    OUT+=("")
    render

    say "-" "Rachel hört zu, ohne dich zu unterbrechen. Als du fertig bist, legt sie den Stift weg."
    say "Rachel" "Alle fünf. Gut."
    say "Rachel" "Dann weiß die Stadt jetzt, was hinter ihrem Tor liegt. Ob sie es lesen will oder nicht."
    say "Rachel" "Danke. Hier sind 50 Bits – nicht für die Zeitung, für den Weg."
    say "Rachel" "Und ein Exemplar für dich. Du hast es verdient."
    say "Rachel" "Den Zeitungskastenschlüssel brauche ich zurück. Die Kästen sind voll – und der nächste, der daran dreht, bist vielleicht wieder du."

    bits_add 50
    inv_add sperrzone
    if inv_has zeitungsschluessel; then
        inv_remove zeitungsschluessel 1
        OUT+=("   [ Zeitungskastenschlüssel ]  -1")
    fi
    AUFLAGE_DONE=1
    ZEITUNG_EMPTIED=0

    OUT+=("")
    OUT+=("   [ Bits ]     +50   (noch $(bits_text "$(bits_count)"))")
    OUT+=("   [ Zeitung ]  Die Sperrzone")

    say "Rachel" "Ich bin gespannt, was die Stadt sagt. Und ich bin gespannt, was Pixi als Nächstes schreibt."
    if [ -n "${TYPE[$ppath]:-}" ]; then
        say "Pixi" "Und ich erst! Ich kann es kaum erwarten, die Meinung der Leute zu hören. Die werden ihren Augen nicht trauen!"
        say "Pixi" "Danke, dass du die Ausgabe rausgebracht hast. Ohne dich würde sie noch auf dem Tisch liegen."
    fi

    quest_reward auflage 500

    if [ "${JIMMY_GIVEN:-0}" = "1" ] && [ "${JIMMY_LAST_SOLD:-}" != "sperrzone" ]; then
        OUT+=("")
        OUT+=("[ NEUES ZIEL ]  Ich sollte Jimmy ein Exemplar bringen.")
        quest_note "Ich sollte Jimmy die Sperrzone-Ausgabe bringen."
    fi

    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# Rachels Standardgespräch nach der Verteilung.
verlag_rachel_auflage_after() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ DAILYPULSE · CHEFREDAKTION ═════")
    OUT+=("Rachel Nullpunkt    Rolle: Besitzerin & Chefredakteurin")
    OUT+=("")
    render

    say "Rachel" "Die Sperrzone-Ausgabe liegt in allen fünf Kästen. Die Stadt liest wieder."
    say "Rachel" "Pixi zählt seit heute Morgen die Leute, die vor den Kästen stehen. Sie nennt es Leserforschung."
    if [ "${JIMMY_GIVEN:-0}" = "1" ] && [ "${JIMMY_LAST_SOLD:-}" != "sperrzone" ]; then
        say "Rachel" "Jimmy wartet sicher noch auf sein Exemplar. Er hat sich heute schon zweimal gemeldet."
    elif [ "${JIMMY_LAST_SOLD:-}" = "sperrzone" ]; then
        say "Rachel" "Jimmy hat sich gemeldet. Er fand die Ausgabe … interessant. Das ist bei ihm fast ein Lob."
    fi
    say "Rachel" "Wenn du noch ein Exemplar brauchst: Die Kästen verkaufen sie für zehn Bits. Tracey hat auch welche."
    say "-" "Sie zieht die nächste Seite auf. Das Gespräch ist beendet – freundlich, aber beendet."

    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# --- Gespräch: Rachel (»touch Rachel«) ---------------------------------
verlag_gespraech_rachel() {
    # Nach der Baracken-Szene hat Rachel zuerst ihre eigene Sorge.
    if [ "${BARACKE_SCENE_DONE:-0}" = "1" ] \
       && [ "${TRACEY_GIVEN:-0}" != "1" ]; then
        verlag_rachel_tracey_offer
        return 0
    fi
    if [ "${TRACEY_GIVEN:-0}" = "1" ] \
       && [ "${TRACEY_FOUND:-0}" = "1" ] \
       && [ "${TRACEY_DONE:-0}" != "1" ]; then
        verlag_rachel_tracey_complete
        return 0
    fi
    if [ "${TRACEY_GIVEN:-0}" = "1" ] \
       && [ "${TRACEY_FOUND:-0}" != "1" ]; then
        verlag_rachel_tracey_reminder
        return 0
    fi

    # Nach dem Rundgang hat Rachel die neue Ausgabe. Erst der Auftrag,
    # danach der Zwischenstand; nach dem Abschluss ein eigener Standard.
    if [ "${AUFLAGE_DONE:-0}" = "1" ]; then
        verlag_rachel_auflage_after
        return 0
    fi
    if [ "${AUFLAGE_GIVEN:-0}" = "1" ]; then
        verlag_rachel_auflage_status
        return 0
    fi

    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ DAILYPULSE · CHEFREDAKTION ═════")
    OUT+=("Rachel Nullpunkt    Rolle: Besitzerin & Chefredakteurin")
    OUT+=("")
    render

    [ "${TRACEY_DONE:-0}" = "1" ] && \
        say "Rachel" "Tracey ist wieder da. Danke noch mal."
    say "Rachel" "Du bist der Agent, den Pixi angeschleppt hat."
    say "Rachel" "Unten wird gearbeitet, oben wird geschlafen. Beides ist heilig, und beides ist eng."
    say "Rachel" "Wenn du hier sein willst, dann mit einer Geschichte. Wer nichts weiß, ist ein Gast. Wer etwas weiß, ist eine Quelle."

    if [ "${RUNDGANG_DONE:-0}" = "1" ]; then
        say "Rachel" "Die neue Ausgabe ist fertig. Die über die Sperrzone. Sie liegt auf dem Tisch."
        say "Rachel" "Ich brauche jemanden, der sie in die Kästen bringt."
        ask "Neuste Auflage." "Nichts weiter."
        if [ "$CHOICE" = "1" ]; then
            verlag_rachel_auflage_offer
            return 0
        fi
    fi

    say "-" "Sie wendet sich wieder dem flackernden Bildschirm zu. Das Gespräch ist beendet – freundlich, aber beendet."
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# --- Gespräch: Jack (»touch Jack«) -------------------------------------
# Jack ist mehr als eine Warnung am Fenster: Er verkauft die erste
# DailyPulse-Ausgabe »Bezirke der Stadt« (langweilig, aber gründlich),
# bringt gegen Bezahlung den »clear«-Befehl bei und vergibt nach der
# Baracken-Szene die Rückhol-Quest »Die langweiligste Ausgabe«.
VERLAG_CLEAR_PRICE=50

# Was kostet »clear« bei Jack? Vor dem Questabschluss 50 Bits, danach
# nichts mehr - der eine Skillpunkt bleibt in beiden Fällen.
verlag_jack_clear_cost_bits() {
    if [ "${ZEITUNG_DONE:-0}" = "1" ]; then
        printf '0'
    else
        printf '%s' "$VERLAG_CLEAR_PRICE"
    fi
}

# »clear« tatsächlich beibringen (ohne eigene Frage). Rückgabe 0 =
# gelernt/bereits bekannt, 1 = zu wenig Skillpunkte oder Bits.
verlag_jack_teach_clear() {
    local cost_bits
    cost_bits="$(verlag_jack_clear_cost_bits)"
    if declare -F knows >/dev/null 2>&1 && knows clear; then
        say "Jack" "»clear« kennst du doch längst. Dafür nehme ich kein Geld."
        return 0
    fi
    if [ "${SKILL_POINTS:-0}" -lt 1 ] 2>/dev/null; then
        play_sound error
        say "Jack" "Dafür brauchst du einen Skillpunkt. Ohne Punkt kein Befehl – so funktioniert das bei mir."
        return 1
    fi
    if [ "$cost_bits" -gt 0 ] && ! bits_has "$cost_bits"; then
        play_sound error
        say "Jack" "Es fehlen die ${cost_bits} Bits. Ich bringe dir nichts bei, was du nicht bezahlen kannst."
        return 1
    fi

    SKILL_POINTS=$(( ${SKILL_POINTS:-0} - 1 ))
    if [ "$cost_bits" -gt 0 ]; then
        bits_take "$cost_bits" || true
        OUT+=("   [ Skillpunkte ]  -1   ·   [ Bits ]  -$(bits_text "$cost_bits")")
    else
        OUT+=("   [ Skillpunkte ]  -1   ·   [ Bits ]  ±0")
    fi
    learn_cmd clear
    say "Jack" "Dann gehört »clear« wieder dir. Benutz es sparsam. Ein leerer Bildschirm ist auch nur eine Seite ohne Inhalt."
    OUT+=("   [ TIPP ]  Bei Performance-Problemen – wenn das Dialogfenster zu voll wird – einfach »clear« anwenden: Es leert das Fenster und das Spiel läuft wieder flüssiger.")
    return 0
}

# »cal« bei Jack Nullpunkt: 2 Skillpunkte + 50 Bits. Der Kalender ist
# kein Dankeschön und auch bei Jimmy nicht kostenlos.
verlag_jack_teach_cal() {
    if declare -F knows >/dev/null 2>&1 && knows cal; then
        say "Jack" "»cal« kennst du schon. Ich wiederhole es nur ungern umsonst."
        return 0
    fi
    if [ "${SKILL_POINTS:-0}" -lt 2 ] 2>/dev/null || ! bits_has 50; then
        play_sound error
        say "Jack" "Für »cal« brauchst du 2 Skillpunkte und 50 Bits. Das ist kein Papierkram, das ist Kalenderwissen."
        return 1
    fi
    SKILL_POINTS=$(( ${SKILL_POINTS:-0} - 2 ))
    bits_take 50 || true
    OUT+=("   [ Skillpunkte ]  -2   ·   [ Bits ]  -$(bits_text 50)")
    learn_cmd cal
    say "Jack" "»cal« zeigt dir das Datum. Oben im PFAD-Fenster, vierundzwanzig Spielstunden lang."
    return 0
}

# Untermenü: »clear« lernen.
verlag_jack_learn_clear() {
    local cost_bits label
    cost_bits="$(verlag_jack_clear_cost_bits)"
    if [ "$cost_bits" -gt 0 ]; then
        label="clear Befehl lernen (Kosten 1 Skillpunkt, ${cost_bits} Bits)"
    else
        label="clear Befehl lernen (Kosten 1 Skillpunkt)"
    fi

    say "Jack" "Der clear-Befehl löscht das Dialogfenster. Kein Papier, kein Radiergummi – nur ein leerer Bildschirm."
    say "Jack" "Ich habe ihn lange nicht gebraucht. Aber ich erinnere mich noch, wie er geht."
    ask "$label" "Hab es mir anders überlegt."

    if [ "$CHOICE" = "2" ]; then
        say "Jack" "Schon gut. Er rennt dir nicht weg."
        return 0
    fi
    verlag_jack_teach_clear
}

# Lernmenü: clear und/oder cal, je nachdem, was noch fehlt.
verlag_jack_learn_menu() {
    local -a opts=() acts=()
    local act="" cost_bits label

    if ! declare -F knows >/dev/null 2>&1 || ! knows clear; then
        cost_bits="$(verlag_jack_clear_cost_bits)"
        if [ "$cost_bits" -gt 0 ]; then
            label="clear Befehl lernen (Kosten 1 Skillpunkt, ${cost_bits} Bits)"
        else
            label="clear Befehl lernen (Kosten 1 Skillpunkt)"
        fi
        opts+=("$label"); acts+=("clear")
    fi
    if ! declare -F knows >/dev/null 2>&1 || ! knows cal; then
        opts+=("cal Befehl lernen (2 Skillpunkte, 50 Bits)"); acts+=("cal")
    fi
    if [ "${#opts[@]}" -eq 0 ]; then
        say "Jack" "Du kennst bereits alles, was ich dir beibringen kann."
        return 0
    fi
    opts+=("Nichts weiter."); acts+=("back")
    OUT+=("")
    say "Jack" "Was willst du lernen?"
    ask "${opts[@]}"
    if [ "${CHOICE:-0}" -ge 1 ] && [ "${CHOICE:-0}" -le "${#acts[@]}" ]; then
        act="${acts[$((CHOICE - 1))]}"
    fi
    case "$act" in
        clear)
            if [ "$(verlag_jack_clear_cost_bits)" -gt 0 ]; then
                say "Jack" "Der clear-Befehl löscht das Dialogfenster. Kein Papier, kein Radiergummi – nur ein leerer Bildschirm."
            fi
            verlag_jack_teach_clear ;;
        cal)
            say "Jack" "Der Kalender ist kein Geschenk. Ich zeige dir »cal« für 2 Skillpunkte und 50 Bits."
            verlag_jack_teach_cal ;;
        *)
            say "Jack" "Schon gut. Das Angebot bleibt stehen." ;;
    esac
}

# Jacks Rückhol-Quest anbieten. Rachel und Pixi kommentieren nur, wenn sie
# GERADE körperlich im Verlag stehen (TYPE[]), nicht bloß laut Queststand.
verlag_jack_offer_quest() {
    local verlag teased=0 rpath ppath
    verlag="$(verlag_dir)"
    rpath="$verlag/Rachel"
    ppath="$verlag/Pixi"

    say "Jack" "Es geht um die neue Ausgabe. »Bezirke der Stadt«."
    say "Jack" "Sie verkauft sich nicht. Nicht ein bisschen. Nicht mal an die Leute, die im Bezirk wohnen."
    say "Jack" "Ich habe jeden Bezirk einzeln beschrieben. Mit Einwohnerzahlen. Mit Straßen, die längst niemand mehr benutzt."
    if [ -n "${TYPE[$rpath]:-}" ]; then
        say "Rachel" "Jack. Du hast eine Karte abgeschrieben und danach sieben Mal erklärt, wo Norden liegt."
        teased=1
    fi
    if [ -n "${TYPE[$ppath]:-}" ]; then
        say "Pixi" "Ich habe sie gelesen. Zweimal. Beim zweiten Mal war ich sicher, dass ich beim ersten Mal etwas verpasst habe. Ich hatte nichts verpasst."
        teased=1
    fi
    [ "$teased" = "1" ] && say "Jack" "Hey, lasst das!"

    say "Jack" "Mama will die Restexemplare zurück. Aus allen fünf Kästen. Den Inhalt soll ich löschen, das Papier behalten."
    say "Jack" "Sie sagt, Papier ist teurer als meine Zeit. Bei den Preisen hat sie vermutlich recht."
    say "Jack" "Ich soll die Kästen leeren – aber ich komme hier nicht weg. Jemand muss die nächste Ausgabe setzen. Und ich will nicht durch die halbe Stadt laufen und meinen eigenen Namen auf jedem Titelblatt sehen."
    say "Jack" "Hilfst du mir? Ich gebe dir den Schlüssel zu den Kästen. Und ich bringe dir dafür »clear« bei."

    ask "Ich helfe dir." "Nein, jetzt nicht."

    if [ "$CHOICE" = "2" ]; then
        say "Jack" "Noch hast du Zeit es dir zu überlegen."
        return 0
    fi

    quest_gain_once zeitung
    ZEITUNG_GIVEN=1
    if ! inv_has zeitungsschluessel; then
        inv_add zeitungsschluessel
    fi
    OUT+=("")
    OUT+=("   [ Zeitungskastenschlüssel ]  erhalten")
    say "Jack" "Hier. Der Schlüssel passt auf alle fünf. Süden, Norden, Westen, Osten, Zentrum."
    say "Jack" "Leere sie mit »use Zeitungskasten«. Nimm die Bündel mit. Und lass nichts liegen, was Rachel noch als Ausgabe verkaufen könnte."
    OUT+=("[ NEUES ZIEL ]  Leere die fünf Zeitungskästen:   use Zeitungskasten")
}

# Kurz schwarz werden: nach der Rückgabe arbeitet Jack drei Stunden.
# Dev-/Test-Haken: TH_ZEITUNG_BLACK_SECS überschreibt die Dauer.
zeitung_black_three_hours() {
    local secs="${TH_ZEITUNG_BLACK_SECS:-3}"
    geom
    printf '\033[48;5;16m\033[38;5;250m'   # schwarzer Grund, heller Text
    clear
    local msg="3 Stunden später"
    local rr=$(( ROWS / 2 ))
    local cc=$(( (COLS - ${#msg}) / 2 + 1 )); [ "$cc" -lt 1 ] && cc=1
    pos "$rr" "$cc"
    printf '%s' "$msg"
    sleep "$secs"
    printf '%s' "$UI_BG"
    FIRST_RENDER=1
}

# Fünf Zeitungsbündel abgeben: Arbeit ansehen, drei Stunden vorspulen,
# Quest abschließen (200 EXP) und danach »clear« vergünstigt anbieten.
verlag_jack_deliver_bundles() {
    local bundles
    bundles="$(inv_count zeitungsbuendel)"
    if [ "$bundles" -lt 5 ] 2>/dev/null; then
        say "Jack" "Das sind noch nicht alle. Fünf Kästen, fünf Bündel. Zähl lieber zweimal."
        return 0
    fi

    say "Jack" "Du hast sie. Alle fünf."
    say "-" "Jack nimmt die Bündel, eines nach dem anderen, und legt sie auf den Setztisch. Die Knoten löst er mit zwei Fingern."
    inv_remove zeitungsbuendel 5
    OUT+=("   [ Zeitungsbündel ]  -5")
    say "Jack" "Drei Stunden. Wenn ich schneller bin, habe ich etwas falsch gemacht."
    say "-" "Er zieht die erste Ausgabe aus dem Bündel, legt sie glatt und beginnt, den Inhalt zu löschen. Zeile für Zeile. Ohne Eile."

    zeitung_black_three_hours
    uhrzeit_advance_hours 3

    ZEITUNG_DONE=1
    quest_reward zeitung 200
    OUT+=("")
    say "-" "Drei Stunden später: Auf dem Tisch liegen fünf ordentliche Stapel leeres Papier. Jack blinzelt, als käme er aus einem langen Satz."
    say "Jack" "Fertig. Der Inhalt ist weg, das Papier ist heil. Mama kann es neu bedrucken."
    if inv_has zeitungsschluessel; then
        inv_remove zeitungsschluessel
        OUT+=("   [ Zeitungskastenschlüssel ]  -1   (an Jack zurückgegeben)")
        say "Jack" "Und den Schlüssel brauche ich zurück. Mama würde sonst fragen, warum ich ihn verschenkt habe."
    fi
    if knows clear; then
        say "Jack" "Und du hast »clear« schon. Dann bleibt mir nur der Dank."
    else
        say "Jack" "Wegen »clear«: Jetzt kostet es dich nur noch einen Skillpunkt. Die 50 Bits sind meine Sache."
    fi
    say "Jack" "Danke. Wirklich. Ich hätte sonst bis Mitternacht an den Kästen gestanden und mir vorgerechnet, wie viele Exemplare pro Minute ich schaffe."
    if [ "${AMANDA_HELP_GIVEN:-0}" = "1" ] && [ "${AMANDA_HELP_ASKED:-0}" = "1" ] \
       && [ "${AMANDA_HELP_JACK:-0}" != "1" ]; then
        say "Jack" "Wegen Amanda: Jetzt hätte ich Zeit. Frag mich noch einmal, dann gehe ich rüber."
    fi
}

# Jacks Umzug in die Detektei Holmes: erst zusagen, dann (falls Rachel
# körperlich im Verlag steht) ihr Einwand, dann der Wechsel.
verlag_jack_amanda_help() {
    local rpath
    rpath="$(verlag_dir)/Rachel"

    say "Jack" "Amanda Nox? Die Assistentin von Holmes?"
    say "Jack" "Ich kenne sie nur vom Hörensagen. Aber die Idee ist … interessant."
    say "-" "Er legt das Papier weg und sieht zum ersten Mal nicht daran vorbei."
    say "Jack" "Sie sucht jemanden für die Akten? Ich bin gut mit Papier. Vielleicht ist das keine so verrückte Idee."

    # Solange Jacks eigene Rückholquest läuft, kann er den Verlag nicht
    # verlassen. Der Spieler muss sie erst abschließen und ihn erneut
    # ansprechen.
    if [ "${ZEITUNG_DONE:-0}" != "1" ]; then
        say "Jack" "Ich würde ihr gern helfen. Wirklich."
        if [ "${ZEITUNG_GIVEN:-0}" = "1" ]; then
            say "Jack" "Aber erst muss die aktuelle Ausgabe aus dem Verkehr. Solange die fünf Kästen voll sind, kann ich hier nicht weg."
        else
            say "Jack" "Aber erst muss die aktuelle Ausgabe aus dem Verkehr. Rachel will die Restexemplare zurück, und das bleibt an mir hängen."
        fi
        say "Jack" "Wenn das erledigt ist, habe ich Zeit. Frag mich dann noch einmal."
        AMANDA_HELP_ASKED=1
        quest_note "Jack würde Amanda helfen, muss aber erst die langweilige Ausgabe aus dem Verkehr ziehen."
        return 0
    fi

    say "Jack" "Die Ausgabe ist aus dem Verkehr. Das Papier ist neu, die Kästen sind leer. Hier hält mich nichts mehr."
    say "Jack" "Ich geh zu Amanda."
    if [ -n "${TYPE[$rpath]:-}" ]; then
        say "Rachel" "Hey, du willst mir doch nicht etwa meinen Sohn abwerben?"
        say "Jack" "Keine Sorge, Mom. Ich helf bloß ein wenig. Ich bin bald wieder zurück."
    fi
    say "-" "Jack nimmt seine Jacke vom Haken, steckt einen Stift ein und geht. Die Tür zum Vorzimmer fällt hinter ihm zu."

    AMANDA_HELP_ASKED=1
    AMANDA_HELP_JACK=1
    declare -F jack_apply_state >/dev/null 2>&1 && jack_apply_state
    quest_note "Jack ist in die Detektei Holmes gewechselt, um Amanda bei den Akten zu helfen."
    OUT+=("")
    OUT+=("   [ Detektei Holmes ]  Jack steht jetzt im Vorzimmer.")
    OUT+=("[ NEUES ZIEL ]  Sprich mit Amanda in der Detektei Holmes.")
}

verlag_gespraech_jack() {
    local action n bundles
    local -a opts=() actions=()

    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ DAILYPULSE · JACK ═════")
    OUT+=("Jack Nullpunkt    Rolle: der ruhige Bruder")
    OUT+=("")
    render

    if [ "${ZEITUNG_DONE:-0}" = "1" ]; then
        say "Jack" "Danke noch mal. Wegen der Ausgabe. Wegen des Papiers. Wegen allem."
    elif [ "${ZEITUNG_GIVEN:-0}" = "1" ]; then
        say "Jack" "Die Kästen stehen in allen fünf Bezirken. Süden, Norden, Westen, Osten, Zentrum."
        say "Jack" "Ich habe sie damals alle beliefert. Damals klang das noch nach einer guten Idee."
    else
        say "Jack" "Du bist also mit ihr da rausgekommen."
        say "Jack" "Pass auf sie auf. Sie sagt, sie passt auf sich selbst auf. Sie irrt sich."
        say "Jack" "Und wenn du nachts draußen bist: Rücken zur Wand. Nach Einbruch läuft hier mehr Viehzeug als Leute."
    fi

    while true; do
        opts=(); actions=()
        if ! knows clear || ! knows cal; then
            opts+=("Befehl lernen"); actions+=("learn")
        fi
        if [ "${BARACKE_SCENE_DONE:-0}" = "1" ] && [ "${ZEITUNG_DONE:-0}" != "1" ]; then
            if [ "${ZEITUNG_GIVEN:-0}" != "1" ]; then
                opts+=("Kann ich dir irgendwie helfen?"); actions+=("help")
            else
                bundles="$(inv_count zeitungsbuendel)"
                if [ "$bundles" -ge 5 ] 2>/dev/null; then
                    opts+=("Ich habe die Zeitungsbündel."); actions+=("deliver")
                else
                    opts+=("Wie komme ich voran?"); actions+=("status")
                fi
            fi
        fi
        if [ "${AMANDA_HELP_GIVEN:-0}" = "1" ] && [ "${AMANDA_HELP_JACK:-0}" != "1" ] \
           && [ "${AMANDA_HELP_DONE:-0}" != "1" ]; then
            opts+=("Amanda helfen"); actions+=("amanda")
        fi
        opts+=("Handeln."); actions+=("handeln")
        opts+=("Nichts weiter."); actions+=("leave")

        OUT+=("")
        OUT+=("Was möchtest du?")
        render
        ask "${opts[@]}"
        action="${actions[$((CHOICE - 1))]}"

        case "$action" in
            learn)
                verlag_jack_learn_menu
                dialog_pause
                ;;
            help)
                verlag_jack_offer_quest
                dialog_pause
                ;;
            deliver)
                verlag_jack_deliver_bundles
                dialog_pause
                ;;
            status)
                n="$(zeitung_boxes_emptied)"
                say "Jack" "Du hast ${n} von 5 Kästen geleert. Die Bündel trägst du mit dir."
                if [ "$n" = "0" ]; then
                    say "Jack" "Fang im Süden an. Der Kasten steht direkt vor dem Verlag."
                elif [ "$n" -ge 5 ]; then
                    say "Jack" "Alle fünf? Dann her damit. Ich brauche das Papier."
                else
                    say "Jack" "Die restlichen Kästen stehen in den anderen Bezirken. Du findest sie mit »cd« und einem Blick mit »ls«."
                fi
                dialog_pause
                ;;
            amanda)
                verlag_jack_amanda_help
                dialog_pause
                # Nach dem Umzug steht Jack nicht mehr im Verlag - das
                # laufende Gespräch sauber beenden.
                [ "${AMANDA_HELP_JACK:-0}" = "1" ] && break
                ;;
            handeln)
                handel_lager_jack
                say "Jack" "Papier? Ich hab Papier. Leere Blätter und ein Bündel. Alles, was du brauchst – solange du es bezahlst."
                handel_start jack
                DIALOG_ACTIVE=1
                ;;
            leave)
                break
                ;;
        esac
    done

    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# Jacks neuer Standard-Dialog in der Detektei Holmes. Er arbeitet jetzt
# mit Amanda an den Akten und ist dort jeden Tag ansprechbar.
dialog_jack_detektei() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ DETEKTEI HOLMES · AKTENRAUM ═════")
    OUT+=("Jack Nullpunkt    Rolle: Amandas neue Unterstützung")
    OUT+=("")
    render

    say "Jack" "Gibt viel zu tun hier, macht aber auch irgendwie Spaß."
    say "Jack" "Amanda hat mich sofort an die Ablage gesetzt. Nach zwei Stunden wusste ich, wie ihr System funktioniert. Nach drei habe ich es sortiert."
    say "-" "Auf dem Tisch liegt ein Stapel Akten, ordentlicher als alles im Verlag. Jack blättert weiter, während er spricht."
    say "Jack" "Sag Amanda nicht, dass ich das sage: Die Arbeit hier ist tatsächlich interessanter als die Stadttour."
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}


# --- Szene 1: Familiengespräch im Verlag -------------------------------
verlag_family_scene() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ ZEITUNGSVERLAG »DAILYPULSE« · REDAKTION & WOHNUNG ═════")
    OUT+=("Ort : Süddistrikt    Status : TÜR OFFEN    Ausgabe : in Arbeit")
    OUT+=("")
    render

    say "-" "Der Verlag ist zugleich Wohnung: unten die Redaktion – Setzkästen, ein flackernder Bildschirm, Kaffee mit Inode-Resten –, oben zwei Zimmer unter dem Dach."
    say "-" "Pixi ist schon da. Mitten im Raum steht eine Frau, die aussieht, als hätte sie diese Zeitung eigenhändig aus einem Haufen Datenmüll gezogen: Rachel."
    say "-" "Am Fenster lehnt ein junger Mann, still, mit dem Rücken zur Wand: Jack."
    OUT+=("")
    say "Pixi" "Mama! Jack! Ich bin wieder da."
    say "Rachel" "Pixi."
    say "-" "Ein Wort, ein Blick. Rachel hat in einer Sekunde alles gesehen: den Riss im Mantel, die unruhige Hand, den fremden Agenten hinter ihrer Tochter."
    say "Rachel" "Setz dich. Und dann erzähl. Von Anfang an. Ohne Heldengeschichten."
    OUT+=("")
    say "Pixi" "Ich war im Root. In der Sperrzone. Nur kurz."
    say "Pixi" "Ich wollte sehen, was da wirklich läuft. Nicht das, was im Log steht – das, was dahinter steht."
    say "Pixi" "Und ich habe es gesehen: Der Kern ist kein Prozess. Er ist ein Muster. Er frisst Befehle und lässt nur die Erinnerung übrig, dass es sie mal gab."
    say "Pixi" "Dann hat mich einer angepingt. Ein Hunter-Killer-Daemon, getarnt als systemd-journal."
    say "Pixi" "Ich bin gerannt – Hardlink für Hardlink. Aber er hat meinen Inode markiert. Er WEISS, wo ich bin."
    OUT+=("")
    say "-" "Rachel hat die Arme verschränkt. Ihre Hände zittern nicht. Sie zittern nie."
    say "Rachel" "Er hat deinen Inode markiert."
    say "Pixi" "Ja."
    say "Rachel" "Dann bist du nicht entkommen. Du bist nur noch nicht eingeholt."
    say "-" "Einen Moment ist es still im Verlag. Nur der alte Lüfter unter der Decke surrt."
    say "Rachel" "Gut. Du lebst. Bei dir ist das offenbar eine Leistung."
    OUT+=("")
    say "Rachel" "Aber kommen wir zum Geschäftlichen."
    say "Pixi" "Mama—"
    say "Rachel" "Nein. Du hast eine Geschichte. Eine, die sonst niemand hat. Das ist nicht nur dein Leben, das ist unsere Auflage."
    say "Rachel" "Wir sind die letzte Zeitung, die der Virus noch nicht gefressen hat. Jede Ausgabe ist der Beweis, dass es uns noch gibt."
    say "Rachel" "Also: Was frisst der Kern? Befehle, sagst du. Welche? Wie viele? Wächst er? Ich will das morgen Abend auf Seite eins."
    say "Rachel" "Keine Andeutungen, keine Gerüchte. Belege. Notfalls gehst du noch mal hin."
    say "Pixi" "Ich weiß. Ich schreibe es heute Nacht."
    OUT+=("")
    say "-" "Jack löst sich vom Fenster. Er spricht leise; man muss ihm zuhören, um ihn zu hören."
    say "Jack" "Du warst am Rand der Zone?"
    say "Pixi" "Am Rand. Ja."
    say "Jack" "Und ein Hunter hat dich markiert."
    say "-" "Er sieht nicht Pixi an, sondern den Boden. Er rechnet."
    say "Jack" "Wenn er deinen Inode hat, muss er nicht mehr suchen. Er muss nur noch laufen."
    say "Jack" "Wie lange läuft er schon?"
    say "Pixi" "Ein paar Stunden."
    say "Jack" "Dann sollten wir nicht hier stehen und über Auflagen reden."
    say "Rachel" "Wir reden über alles, Jack. Immer. Das ist, was wir tun."
    OUT+=("")
    say "-" "Dann fällt Rachels Blick auf dich. Zum ersten Mal richtig."
    say "Rachel" "Und wer ist das?"
    say "Pixi" "Das ist der Neue. Der Anti-Virus-Agent aus dem Download-Archiv. Er ist mit mir durch das Tor gekommen."
    say "Pixi" "Mama, er hat keinen Ort. Er steht im Nichts mit einem Koffer voller Befehle, die der Virus halb gefressen hat."
    say "Pixi" "Kann er eine Nacht hier bleiben? Oben ist Platz. Nur eine Nacht."
    say "-" "Jack schaut auf. Rachel nicht."
    say "Rachel" "Nein."
    say "Pixi" "Mama!"
    say "Rachel" "Der Verlag ist unsere Redaktion und unser Zuhause. Beides ist verletzlich."
    say "Rachel" "Ich lade keine Fremden über Nacht ein – nicht, während ein Hunter im Netz unterwegs ist und schon einmal einen Inode gefunden hat."
    say "Rachel" "Keine Ausnahmen. Nicht für dich. Nicht für ihn."
    say "Pixi" "Aber er ist kein Fremder! Er ist mit mir durch das Tor."
    say "Rachel" "Und das rechne ich ihm an. Deshalb schläft er nicht auf der Straße."
    OUT+=("")
    say "Rachel" "Die eingestürzte Baracke. Zwei Straßen weiter, im Süddistrikt."
    say "Pixi" "Die Bruchbude?! Da steht das Wasser auf dem Boden!"
    say "Rachel" "Der hintere Raum hat ein Dach. Vier Wände, eine Tür, keine Zeugen."
    say "Rachel" "Für eine Nacht ist das mehr, als die meisten in dieser Stadt haben."
    say "Pixi" "Das ist nicht fair."
    say "Rachel" "Fair ist, wenn die Ausgabe pünktlich rauskommt. Alles andere ist Verhandlung."
    OUT+=("")
    say "-" "Pixi atmet hörbar aus. Sie kennt diese Mauer. Sie ist daran aufgewachsen."
    say "Pixi" "Gut. Aber ich bringe ihn hin. Kein Weg allein durch den Süddistrikt nach Einbruch."
    say "Rachel" "Einverstanden. Und danach schreibst du. Seite eins."
    say "Pixi" "Ich schreibe."
    say "-" "Jack tritt neben dich. Er spricht so leise, dass nur du es hörst."
    say "Jack" "Nimm die hintere Ecke, unter dem Balken. Da zieht es am wenigsten."
    say "Jack" "Und schlaf mit dem Rücken zur Wand. Nicht aus Angst. Aus Gewohnheit."
    say "-" "Du nickst. Pixi hat schon die Hand am Türrahmen."
    say "$AGENT_NAME" "Zeig mir den Weg."
    say "Pixi" "Los. Erst raus, dann nach links."
    OUT+=("")
    OUT+=("[ NEUES ZIEL ]  Verlasse den Verlag – Pixi wartet im Süddistrikt:   cd ..")
    # Das Familiengespräch ist durch: die Pixi-Quest ist hier abgeschlossen
    # (Belohnung 100 EXP, Dialogmeldung noch im offenen Fenster).
    VERLAG_DONE=1
    quest_reward pixi 100
    # Pixi hat den Verlag verlassen (»Los. Erst raus, dann nach links.«):
    # sie ist ab jetzt unterwegs und wird hier NICHT mehr gelistet.
    pixi_apply_state
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# --- Szene 2: Süddistrikt - Pixi geht in die Baracke voraus ------------
verlag_sued_scene() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ SÜDDISTRIKT · VOR DEM VERLAG ═════")
    OUT+=("Ort : Süddistrikt    Status : DÄMMERUNG")
    OUT+=("")
    render

    say "-" "Kaum bist du draußen, wartet Pixi schon an der Hauswand. Hände in den Taschen, Blick die Straße hinunter."
    say "Pixi" "Sorry. Wegen meiner Mutter."
    say "Pixi" "Sie ist nicht herzlos. Sie ist Chefredakteurin. Da ist kein Platz für »vielleicht«."
    say "Pixi" "Jack ist schlimmer. Der rechnet die halbe Nacht durch. Der hat mir schon dreimal gesagt, ich soll das Sperrgebiet nie wieder betreten."
    say "-" "Sie stößt sich von der Wand ab, zwei Schritte in Richtung des alten Gebäudes."
    say "Pixi" "Die Baracke ist gleich da. Kaputtes Dach, nasse Wände – aber die hintere Ecke ist trocken."
    say "Pixi" "Wenn du es dort nicht aushältst, sag es mir morgen. Dann frage ich Rachel noch mal. Sie wird nein sagen, aber ich frage."
    say "Pixi" "Ich geh schon vor und sehe nach, ob dort jemand haust."
    OUT+=("")
    say "-" "Bevor du etwas sagen kannst, ist sie zwischen den Häusern verschwunden – hinein in die eingestürzte Baracke."
    OUT+=("[ NEUES ZIEL ]  Folge Pixi:   cd EingestürzteBaracke")
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
    PIXI_GUIDE_DONE=1
    pixi_apply_state
}

# --- Szene 3: Baracke - Armbanduhr, »grep«, Abschied -------------------
verlag_baracke_scene() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ EINGESTÜRZTE BARACKE · NOTQUARTIER ═════")
    OUT+=("Ort : Süddistrikt    Status : NOTDÜRFTIG")
    OUT+=("")
    render

    say "-" "Es riecht nach nassem Putz und altem Papier. Durch das halbe Dach fällt blasses Licht; am Boden steht das Wasser in Rinnen."
    say "Pixi" "Mein Gott, was für eine Bruchbude."
    say "Pixi" "Aber aktuell hast du nicht wirklich eine Wahl."
    OUT+=("")
    say "$AGENT_NAME" "Wo schlafe ich?"
    say "Pixi" "Hinten. Da ist das Dach noch ganz. Der Wind pfeift durch die Ritzen, aber es regnet nicht rein."
    say "-" "Sie tritt zur Seite, damit du sehen kannst: ein Verschlag, ein paar Balken, ein Haufen Schutt – und in der Ecke, halb im Dreck, ein kleiner metallischer Glanz."
    OUT+=("")
    say "Pixi" "Hey – ist das da etwa eine Armbanduhr?"
    say "-" "Sie kniet sich hin, ohne sie anzufassen."
    say "Pixi" "Hast du eine?"
    say "Pixi" "Nein?"
    say "Pixi" "Dann solltest du diese vielleicht nehmen."
    say "-" "Sie deutet mit dem Kinn auf die Uhr."
    say "Pixi" "Der Befehl dafür ist »grep«. Er zieht heraus, was du suchst. Merk ihn dir – ohne ihn stehst du vor jedem Fundstück wie vor einer Wand."
    learn_cmd grep
    OUT+=("")
    say "-" "Auf dem Weg nach draußen bleibt ihr Blick an etwas Hässlichem hängen: eine Matratze, halb unter Schutt, mit Wasserflecken und Stockflecken."
    say "Pixi" "Sieht zwar ziemlich ecklig aus, das Teil, aber was Besseres steht gerade nicht zur Verfügung."
    say "Pixi" "Zum Schlafen reicht sie. Du musst ihr nur sagen, dass sie benutzt werden soll."
    say "Pixi" "Dafür gibt es einen Befehl: »use«. Damit benutzt du, was in der Welt steht – Matratze, Stuhl, Türklinke. Alles, was man anfassen und benutzen kann."
    say "Pixi" "use Matratze – und du legst dich hin. Immerhin ein Dach über dem Kopf."
    learn_cmd use
    OUT+=("")
    say "Pixi" "Eine letzte Sache noch: »statistics« zeigt dir, was du bisher geschafft hast – Spielzeit, Quests, Zeitungen, gesammelte Bits."
    say "Pixi" "Ein Blick lohnt sich. Auch wenn Zahlen manchmal gemein sind."
    learn_cmd statistics
    OUT+=("")
    say "Pixi" "So. Und jetzt muss ich los."
    say "Pixi" "Komm bei Gelegenheit bei mir im Verlag vorbei. Ich könnte dir die Stadt zeigen."
    say "Pixi" "Jetzt muss ich erst mal an meinem Artikel über die Sperrzone schreiben!"
    say "-" "Ein Wink, ein Flackern – dann läuft Pixi zurück durch die Gasse, in Richtung Verlag."
    OUT+=("")
    OUT+=("[ NEUES ZIEL ]  Richte dich in der Baracke ein.   (Schlafen: use Matratze · Uhr: grep Armbanduhr)")
    # Pixi verlässt die Baracke: die Nebenquest »Ein Dach über dem Kopf«
    # ist abgeschlossen (Belohnung 50 EXP, Meldung noch im offenen Fenster).
    # Danach fehlt sonst jeder Hinweis, wie es weitergeht – der nächste
    # Story-Schritt ist das Gespräch mit Pixi im Verlag (Pixis Brief).
    BARACKE_SCENE_DONE=1
    quest_reward nachtlager 50
    OUT+=("")
    say "$AGENT_NAME" "Ich sollte noch mal mit Pixi sprechen."
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
    pixi_apply_state
}

# --- Auslöser (nach jedem Befehl in der Hauptschleife) -----------------
verlag_maybe() {
    # 1) Verlag betreten (nachdem Pixi dort angekommen ist)
    if [ "${VERLAG_DONE:-0}" != "1" ] && [ "${PIXI_HALL_DONE:-0}" = "1" ] \
       && [ "$CWD" = "$(verlag_dir)" ]; then
        verlag_family_scene
        return 0
    fi
    # 2) Süddistrikt: Pixi verabschiedet sich und geht in die Baracke
    if [ "${VERLAG_DONE:-0}" = "1" ] && [ "${PIXI_GUIDE_DONE:-0}" != "1" ] \
       && [ "$CWD" = "$(verlag_sued_dir)" ]; then
        verlag_sued_scene
        return 0
    fi
    # 3) Baracke: Armbanduhr, »grep«, Abschied
    if [ "${PIXI_GUIDE_DONE:-0}" = "1" ] && [ "${BARACKE_SCENE_DONE:-0}" != "1" ] \
       && [ "$CWD" = "$(verlag_baracke_dir)" ]; then
        verlag_baracke_scene
        return 0
    fi
    return 0
}
