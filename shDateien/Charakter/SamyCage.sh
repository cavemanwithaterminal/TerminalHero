# ============================================================
#  TerminalHero - Charakter: Lagermeister Samy Cage
#
#  Beseelte Datei: »touch« öffnet das Gespräch. Er steht im Lager am
#  Marktplatz im Zentrum der Stadt (Orte/Zentrum.sh, Ordner »Lager«) und
#  ist die Station zwischen Börty und seiner Bierlieferung (Nebenquest
#  »Bier für Börty«, InGameBefehle/questlog.sh).
#
#  Ein kurzes Standardgespräch, in zwei Fassungen:
#
#    1. BEIM ERSTEN MAL (SAMY_INTRO_DONE): kurze Vorstellung - er heißt
#       Samy Cage, er ist der Lagermeister hier im Zentrum, und er ist
#       schwer beschäftigt. Wer nichts Wichtiges will, geht zur Seite.
#
#    2. DANACH: dieselbe Ansage, eine Kiste kürzer.
#
#  Dazu die Auswahl-Optionen, die sich dem Spielverlauf anpassen:
#
#    - Hat der Agent die Nebenquest »Bier für Börty« (BIER_GIVEN), fragt er
#      nach der Lieferung: »Bier für Börty.« -> samy_beer_scene. Dort wird
#      geprüft, ob die 250 Bits noch da sind (er kann sie längst ausgegeben
#      haben!): Reichen sie nicht, gibt es KEIN Bier. Reichen sie, wird
#      abgebucht (bits_take) und die Kiste wandert ins Inventar
#      (Items/Quest/Bierlieferung.sh). Solange der Agent keine Kiste mehr
#      hat und die Quest offen ist, gibt es gegen erneute 250 Bits eine
#      Ersatzkiste. Nach dem Abschluss (oder Scheitern) nie wieder.
#    - Sonst steht dort »Es ist wichtig!« wie bisher.
#    - Ist die Hauptquest »Vermisste Bewohner« bekannt (VERMISSTE_GIVEN),
#      fragt er »Vermisste Bewohner?« -> samy_vermisste_scene: knapp, wie
#      es seine Art ist - er zählt Kisten, keine Namen.
#    - Kennt er die Nebenquest »Michael Mitch. Vermisst« (MITCH_GIVEN) -
#      oder ist die Bierlieferung längst abgeschlossen (BIER_DONE, z. B.
#      bei älteren Spielständen) -, gibt es »Michael Mitch?« ->
#      samy_mitch_scene: Er hat Michael manchmal im Westdistrikt gesehen
#      (Flag SAMY_MITCH_INFO) - dort weiß vielleicht jemand mehr.
#
#  Die Optionen laufen als Paar (opts/acts); case wertet die Aktion aus,
#  damit die Nummern nicht verrutschen.
#
#  Lazy geladen über DIALOG[] (kern/loader.sh), erst beim ersten »touch«.
# ============================================================

dialog_samy() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ ZENTRUM · MARKTPLATZ · LAGER ═════")
    OUT+=("Lagermeister : Samy Cage      Status : schwer beschäftigt")
    OUT+=("")
    render

    if [ "${SAMY_INTRO_DONE:-0}" != "1" ]; then
        SAMY_INTRO_DONE=1
        say "Samy" "Hi. Ich bin Samy Cage. Der Lagermeister hier im Zentrum der Stadt."
        say "-" "Er hat eine Kiste auf der Schulter, einen Stift zwischen den Zähnen und beide Hände voll."
        say "Samy" "Und ich bin schwer beschäftigt."
        say "-" "Er stellt die Kiste ab, mustert dich von oben bis unten und hakt dich mit einem Nicken ab."
        say "Samy" "Wenn es nicht wichtig ist, geh doch bitte zur Seite."
        say "Samy" "Das hier ist ein Lager, kein Wartezimmer."
        OUT+=("")
        say "Samy" "Kisten. Sechsundvierzig. Wenn du mitzählst, kommen wir schneller voran."
    else
        say "Samy" "Du schon wieder."
        say "-" "Er streicht eine Zahl auf seiner Liste durch und schreibt sie daneben neu."
        say "Samy" "Ich bin immer noch schwer beschäftigt. Wenn es nicht wichtig ist, geh doch bitte zur Seite."
    fi

    # Die Optionen hängen am Spielverlauf und werden mit ihrer AKTION
    # geführt (opts/acts): case wertet den Namen aus, nicht die Ziffer -
    # so verrutschen die Nummern nicht, wenn eine Option dazukommt.
    #
    #   - Mit der offenen Bierlieferung (BIER_GIVEN, noch nicht BIER_DONE)
    #     ist die erste Option Börtys Bestellung, sonst der übliche Anlauf.
    #   - Ist die Hauptquest »Vermisste Bewohner« bekannt (VERMISSTE_GIVEN),
    #     fragt der Agent danach (samy_vermisste_scene).
    #   - Kennt er die Quest »Michael Mitch. Vermisst« (MITCH_GIVEN), fragt
    #     er nach Michael - und Samy erinnert sich an den Westdistrikt
    #     (samy_mitch_scene, Flag SAMY_MITCH_INFO).
    local opts=() acts=()
    while true; do
        opts=(); acts=()
        if bier_quest_open; then
            opts+=("Bier für Börty.");   acts+=("bier")
        else
            opts+=("Es ist wichtig!");   acts+=("wichtig")
        fi
        if [ "${VERMISSTE_GIVEN:-0}" = "1" ]; then
            opts+=("Vermisste Bewohner?"); acts+=("vermisste")
        fi
        if [ "${MITCH_GIVEN:-0}" = "1" ] || [ "${BIER_DONE:-0}" = "1" ]; then
            opts+=("Michael Mitch?");      acts+=("mitch")
        fi
        opts+=("Sonst nichts. Ich geh zur Seite."); acts+=("gehen")
        OUT+=("")
        ask "${opts[@]}"
        case "${acts[$((CHOICE - 1))]}" in
            bier)      samy_beer_scene
                       DIALOG_ACTIVE=1 ;;
            wichtig)   say "Samy" "Wichtig ist hier alles. Deshalb steht es ja hier."
                       say "Samy" "Dann sag's. Aber schnell – Kisten und ich haben keine Zeit zum Raten."
                       dialog_pause ;;
            vermisste) samy_vermisste_scene
                       DIALOG_ACTIVE=1 ;;
            mitch)     samy_mitch_scene
                       DIALOG_ACTIVE=1 ;;
            gehen)     say "Samy" "Sehr vernünftig."
                       say "-" "Er hat sich schon wieder seiner Liste zugewandt, bevor du fertig gesprochen hast."
                       break ;;
        esac
    done
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# ============================================================
#  Die Bierlieferung herausgeben (Option »Bier für Börty.«)
# ------------------------------------------------------------
#  250 Bits - VORHER wird geprüft, ob der Agent sie überhaupt noch hat
#  (bits_has): Börty hat sie ihm mitgegeben, aber ausgeben kann man sie
#  überall. Reicht das Geld nicht, bleibt die Kiste im Lager und Samy sagt
#  es deutlich. Reicht es, wird abgebucht (bits_take), die »Börtys
#  Bierlieferung« wandert ins Inventar (inv_add) und BIER_TAKEN hält fest,
#  dass die Erstkiste schon abgeholt wurde. Ist sie wieder weg, gibt es
#  für 250 Bits Ersatz - aber nur, solange die Quest offen ist.
# ============================================================
samy_beer_scene() {
    local preis=250 ersatz=0

    # ---- Quest vorbei: keine Kiste mehr --------------------------------
    if [ "${BIER_DONE:-0}" = "1" ]; then
        say "Samy" "Die Lieferung ist längst durch. Börty hat sein Bier."
        say "Samy" "Für dich gibt es hier nichts mehr abzuholen."
        dialog_pause
        DIALOG_ACTIVE=0; DIALOG_HINT=""
        return
    fi
    if [ "${BIER_FAILED:-0}" = "1" ]; then
        say "Samy" "Für dich gibt es hier kein Bier mehr."
        say "Samy" "Die Lieferung ist geplatzt. Frag Börty, wenn du wissen willst, warum."
        dialog_pause
        DIALOG_ACTIVE=0; DIALOG_HINT=""
        return
    fi

    # ---- Schon eine Kiste dabei: keine zweite --------------------------
    if [ "$(inv_count bierlieferung)" -gt 0 ]; then
        say "Samy" "Du hast deine Kiste doch noch."
        say "Samy" "Eine reicht. Lager ist Lager."
        dialog_pause
        DIALOG_ACTIVE=0; DIALOG_HINT=""
        return
    fi

    # ---- Ersatzkiste: erste war schon da, ist aber verloren -----------
    if [ "${BIER_TAKEN:-0}" = "1" ]; then
        ersatz=1
        # Nach Ablauf der 24-Stunden-Frist gibt es keinen Ersatz mehr.
        if bier_loss_due; then
            play_sound error
            say "Samy" "Zu spät."
            say "Samy" "Börty wartet seit vierundzwanzig Stunden. Da stelle ich nichts mehr in die Ecke."
            say "Samy" "Geh zu ihm. Das musst du mit ihm klären, nicht mit mir."
            dialog_pause
            DIALOG_ACTIVE=0; DIALOG_HINT=""
            return
        fi
        say "Samy" "Deine Kiste ist weg?"
        say "-" "Er mustert dich kurz, dann greift er unter die Theke."
        say "Samy" "Ersatz gibt es. Kostet wieder 250 Bits."
        say "Samy" "Und nur, solange Börty die Lieferung noch erwartet."
    else
        say "Samy" "Ah, du bist also der neue Gehilfe von Börty?"
        say "Samy" "Hab das von Mitch gehört. Der ist wohl irgendwo verschwunden."
        say "-" "Er sagt es so beiläufig, dass man fast überhört, was daran nicht stimmt."
        say "Samy" "Aber kann mir egal sein. Hast du die Bits? 250?"
    fi

    # --- Zu wenig Bits: keine Lieferung --------------------------------
    if ! bits_has "$preis"; then
        play_sound error
        say "-" "Der Agent dreht sein Inventar einmal um – es wird nicht mehr."
        say "Samy" "Nein. Das sind keine 250."
        if [ "$ersatz" = "1" ]; then
            say "Samy" "Kein Geld, keine Ersatzkiste. So einfach ist das hier."
        else
            say "Samy" "Kein Geld, kein Bier. So einfach ist das hier."
        fi
        say "Samy" "Komm wieder, wenn du es zusammen hast. Und dann schnell – so lange stelle ich deinem Wirt nichts in die Ecke."
        dialog_pause
        DIALOG_ACTIVE=0; DIALOG_HINT=""
        return
    fi

    # --- Bezahlen und einpacken ----------------------------------------
    say "$AGENT_NAME" "250 Bits. Zähl sie ruhig nach."
    say "-" "Samy zählt nicht nach. Er wischt die Bits mit einer Handbewegung beiseite und wuchtet mit der anderen eine Kiste auf die Theke."
    bits_take "$preis"
    inv_add bierlieferung
    BIER_TAKEN=1
    BIER_LOST_AT=-1
    play_sound select
    OUT+=("")
    OUT+=("   [ Bits ]  -${preis} Bits an Samy Cage.")
    if [ "$ersatz" = "1" ]; then
        OUT+=("   [ Ersatzkiste ]  »Börtys Bierlieferung« – abgeben bei Börty (Kneipe, Ostdistrikt).")
    else
        OUT+=("   [ Inventar ]  »Börtys Bierlieferung« – abgeben bei Börty (Kneipe, Ostdistrikt).")
    fi
    say "Samy" "Lass die Flaschen bloß nicht fallen."
    say "-" "Er tippt mit zwei Fingern gegen die Kiste, prüfend."
    say "Samy" "Bruch zahlt der Bote. Und Bruch bin ich leid."
    OUT+=("")
    say "Samy" "Und jetzt geh. Sechsundvierzig werden ohne dich schneller fertig."
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# ============================================================
#  »Vermisste Bewohner?« (Option mit bekannter Hauptquest)
# ------------------------------------------------------------
#  Samy bleibt, wer er ist: kurz, praktisch, mit beiden Händen voll.
#  Er gibt zu, dass man in seinem Lager mehr davon hört als einem lieb
#  ist - wissen tut er nichts. Flag SAMY_VERMISSTE_INFO hält die Antwort
#  für den Questlog-Verlauf fest (quest_entries_vermisste).
# ============================================================
samy_vermisste_scene() {
    say "Samy" "Vermisste."
    say "-" "Er hält kurz inne, den Stift zwischen den Zähnen - und zählt schon weiter."
    say "Samy" "Ja. Davon hört man hier öfter, als mir lieb ist."
    say "Samy" "Erst fehlt einer, dann zwei. Und keiner kommt wieder mit einer Kiste."
    say "Samy" "Aber ich zähle Bestand, keine Namen. Ich weiß nicht mehr als du."
    say "Samy" "Wenn du's genau wissen willst, frag die, die mit den Leuten zu tun haben. Ich seh hier nur Kisten."
    SAMY_VERMISSTE_INFO=1
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# ============================================================
#  »Michael Mitch?« (Option mit bekannter Nebenquest)
# ------------------------------------------------------------
#  Der erste konkrete Hinweis auf Mitch: Samy hat ihn manchmal im
#  Westdistrikt gesehen - bei den alten Ladenzeilen. Er schickt den
#  Agenten dorthin (»vielleicht weiß dort jemand mehr«). Flag
#  SAMY_MITCH_INFO hält die Spur und das neue Ziel fest
#  (quest_goal_mitch / quest_entries_mitch).
# ============================================================
samy_mitch_scene() {
    # Sicherheitsnetz für Spielstände, in denen die Bierlieferung schon
    # abgeschlossen ist, das Mitch-Flag aber (aus einer älteren Version)
    # fehlt: Die Quest wird hier nachgeholt, damit Option und Questlog
    # zusammenpassen.
    if [ "${MITCH_GIVEN:-0}" != "1" ]; then
        quest_gain_once mitch
        MITCH_GIVEN=1
    fi
    say "Samy" "Mitch?"
    say "-" "Zum ersten Mal seit dem Gespräch legt er den Stift weg. Eine Sekunde lang."
    say "Samy" "Ruhiger Kerl. Pünktlich wie ein Ladeplan. Holt hier regelmäßig was ab."
    say "Samy" "Wo er steckt? Keine Ahnung. Aber ich hab ihn manchmal im Westdistrikt gesehen - hinten bei den alten Ladenzeilen."
    say "Samy" "Wenn dich einer kennt, dann dort. Frag da rum. Ich bin Lagermeister, kein Detektiv."
    SAMY_MITCH_INFO=1
    quest_note "Samy Cage: Michael Mitch wurde zuletzt im Westdistrikt gesehen (alte Ladenzeilen)"
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}
