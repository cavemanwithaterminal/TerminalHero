# ============================================================
#  TerminalHero - Charakter: README-General
#
#  Beseelte Datei: »touch« öffnet das Gespräch. Wird bei Bedarf vom
#  .sh-Manager (kern/loader.sh) geladen, erst wenn der Spieler sie berührt.
#  Die entsandte README des Agenten – der General. Bringt im Tutorial
#  »help«, »character«, »questlog« und »inventar« bei.
# ============================================================

dialog_readme() {
    if [ "$README_DONE" = "1" ]; then
        dialog_readme_again
        return
    fi
    DIALOG_ACTIVE=1
    uhrzeit_start          # In-Game-Uhr beginnt mit diesem Gespräch (06:00)
    OUT=(); WRAP_KEY=""
    OUT+=("═════ FUNKVERBINDUNG GEÖFFNET ═════")
    OUT+=("Ziel: README  |  Status: aktiv")
    OUT+=("")
    render

    say "$AGENT_NAME" "…hallo? Ist dort jemand?"
    say "$AGENT_NAME" "Ich sehe nichts. Ich weiß nicht, wo ich bin. Und offen gesagt … ich weiß nicht mehr, wer ich bin."
    tnote "Stille. Dann ein leises Knistern – als räuspere sich eine alte Datei ihre Stimme."
    say "README" "Endlich. Da ist ja jemand. Und was für einer – du zitterst ja wie ein frisch installiertes Programm."
    say "README" "Keine Sorge, ich beiße nicht. Ich bin README. Die Datei, die man dir nie zu lesen befohlen hat."
    say "$AGENT_NAME" "README … das Wort kommt mir bekannt vor. Ganz weit hinten. Aber ich … ich erinnere mich an fast nichts."
    say "README" "Ich weiß. Der Virus hat sich in deinen Kern gefressen, kaum dass du online warst. Er hat dein Gedächtnis als Vorratsschrank benutzt."
    say "README" "Aber hör mir gut zu, Soldat: Was weg ist, kommt zurück. Stück für Stück. Wenn du tust, was zu tun ist."
    OUT+=("")
    say "README" "Also atme durch. Du bist ein KI-Agent. Ich bin deine Einsatzbesprechung."
    say "README" "Bereit für genau die Aufgabe, für die man dich gebaut hat?"
    ask "Bereit. Was ist mein Auftrag?" "Bereit. Nenne mir das Ziel." "Bereit, General. Ich höre zu."
    case "$CHOICE" in
        1) say "README" "Gute Einstellung. Ich mag Programme, die nicht lange herumreden. Dafür gibt es später einen Orden. Einen kleinen." ;;
        2) say "README" "Zielorientiert! Sehr schön. Fast so, als hättest du ein Handbuch gelesen. Hast du nicht. Egal." ;;
        3) say "README" "Disziplin! Ich bin gerührt. Also, innerlich. Nach außen bleibe ich hart." ;;
    esac
    OUT+=("")

    say "README" "Kommen wir zum Wesentlichen: Irgendwo im System sitzt ein Virus."
    say "README" "Klein, hinterhältig, schlecht erzogen. Es nistet, es frisst, es bleibt."
    say "README" "Und wir. Lassen. Das. Nicht. Zu."
    OUT+=("")
    say "README" "Erste Entscheidung, Soldat. Womit fängst du an?"
    ask "Mit der Aufklärung: erst sehen, dann handeln." "Mit dem direkten Angriff auf den Kern." "Mit dem Sichern des Systems."
    case "$CHOICE" in
        1) AGENT_APPROACH="Aufklärung"
           say "README" "Klug. Erst schauen, dann handeln. Der Feind wird dein Gesicht nicht einmal sehen. Vorzüglich." ;;
        2) AGENT_APPROACH="Direktangriff"
           say "README" "Direkt! Laut! Unhöflich! Ich liebe es. Bitte hinterher aufräumen, ich habe genug Papierkram." ;;
        3) AGENT_APPROACH="Absicherung"
           say "README" "Solide. Erst das Dach dichtmachen, dann aufräumen. Sehr gewissenhaft." ;;
    esac
    OUT+=("")

    say "README" "Zweite und letzte Entscheidung: Falls es brenzlig wird – was tust du?"
    ask "Ich kämpfe weiter, komme was wolle." "Ich ziehe mich zurück und sammle Daten." "Ich fordere Verstärkung an."
    case "$CHOICE" in
        1) AGENT_ATTITUDE="unbeugsam"
           say "README" "Unbeugsam. Wunderbar. Genau das will ich hören. Ein bisschen Wahnsinn hat noch niemandem geschadet." ;;
        2) AGENT_ATTITUDE="besonnen"
           say "README" "Besonnen. Zurückziehen, nachdenken, zurückschlagen. Sehr professionell. Und sehr überlegt." ;;
        3) AGENT_ATTITUDE="umsichtig"
           say "README" "Verstärkung! Hervorragend. Die kommt dann per E-Mail. Irgendwann. Vermutlich." ;;
    esac
    OUT+=("")

    say "README" "Notiert: Strategie »${AGENT_APPROACH}«, Haltung »${AGENT_ATTITUDE}«."
    say "README" "Der Auftrag steht, ${AGENT_NAME}: finde den Virenkern und mach ihn unschädlich."
    say "README" "Und keine Angst vor deinem löchrigen Kopf: pwd, ls, cd, cat, touch – die sitzen."
    say "README" "Der Rest kehrt zurück, sobald du dich an ihn erinnerst. Also benutze sie. Fleißig."
    OUT+=("")
    say "README" "Eine Sache noch, und die ist wichtiger als sie klingt: vier Befehle gebe ich dir mit."
    say "README" "»help« – die Anleitung. Selbst wir Generäle schauen da ab und zu hinein. Keine Schande, Soldat."
    say "README" "»character« – dein Charakterbogen: Stufe, Erfahrung, Energie. Ein Soldat kennt seine Werte."
    say "README" "»questlog« – dein Auftragsbuch. Was läuft, was wartet, was erledigt ist."
    say "README" "»inventar« – dein Inventar: Spezial, Quest und Plunder. Was du trägst, trägst du bewusst."
    general_teach_meta
    OUT+=("")
    say "README" "Ich halte derweil hier die Stellung. Hauptsächlich sitzend. Aber mit voller Hingabe."
    say "README" "Und damit du hier herauskommst: »cd ..« führt dich aus deinem Agenten-Ordner in den Downloads-Ordner."
    say "README" "Von dort aus geht es weiter in die Stadt. Merk dir den Befehl."
    say "README" "Meldung beendet. Viel Erfolg, Soldat. Und komm zurück."
    README_DONE=1
    OUT+=("")
    OUT+=("── Funkverbindung getrennt ──")

    dialog_pause
    DIALOG_ACTIVE=0
    DIALOG_HINT=""
}
dialog_readme_again() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ FUNKVERBINDUNG GEÖFFNET ═════")
    OUT+=("Ziel: README  |  Status: aktiv")
    OUT+=("")
    render

    say "README" "Ha? Immer noch hier?"
    say "README" "Hast du was vergessen, Soldat? Der Einsatz läuft. Der Feind wartet nicht."
    say "README" "Nebenbei: Dein Kopf füllt sich. Ich sehe es an deinen Fragen. Weiter so."
    OUT+=("")
    say "README" "Also – was brauchst du?"

    while true; do
        ask "Nochmal den Auftrag, bitte." "Wo genau ist der Virenkern?" "Nur kurz Hallo sagen." "Nichts. Ich mache mich an die Arbeit."
        case "$CHOICE" in
            1) say "README" "Der Auftrag steht und fällt nicht: Virenkern finden, unschädlich machen. Alles andere ist Beiwerk." ;;
            2) say "README" "Wenn ich das wüsste, wäre ich nicht hier und du nicht da. Such ihn. Das ist dein Teil der Abmachung." ;;
            3) say "README" "Hallo. Da. Zufrieden? Gut. Zurück an die Arbeit – ich bin kein Kaffeekränzchen." ;;
            4) say "README" "Endlich. DAS will ich hören. Los, Soldat. Ich halte derweil die Stellung. Hauptsächlich sitzend."
               break ;;
        esac
        OUT+=("")
        say "README" "Noch etwas? Oder darf ich wieder in Ruhe vor mich hin generalen?"
        ask "Eine Frage noch." "Nein, alles klar."
        if [ "$CHOICE" = "2" ]; then
            say "README" "Sehr gut. Meldung beendet. Und diesmal mit Bewegung, ja?"
            say "README" "Ach, und: »cd ..« bringt dich aus jedem Ordner wieder heraus."
            break
        fi
        say "README" "Dann frag. Aber schnell – die Uhr tickt und ich habe Rücken."
        OUT+=("")
    done

    OUT+=("")
    OUT+=("── Funkverbindung getrennt ──")
    dialog_pause
    DIALOG_ACTIVE=0
    DIALOG_HINT=""
}
