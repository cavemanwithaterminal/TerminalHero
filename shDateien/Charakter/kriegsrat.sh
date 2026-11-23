# ============================================================
#  TerminalHero - Charakter: Kriegsrat (BarbarConan)
#
#  Beseelte Datei: »touch« öffnet das Gespräch. Wird bei Bedarf vom
#  .sh-Manager (kern/loader.sh) geladen, erst wenn der Spieler sie berührt.
#  Roh, laut, brutal. Verwechselt den Spieler zuerst mit Conan.
# ============================================================

dialog_conan() {
    if [ "$CONAN_DONE" = "1" ]; then
        dialog_conan_again
        return
    fi
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ FUNKVERBINDUNG GEÖFFNET ═════")
    OUT+=("Ziel: README (Kriegsrat)  |  Status: aktiv")
    OUT+=("")
    render

    say "Kriegsrat" "CONAN! Da bist du ja, du Felsenschädel! Ich wusste es!"
    say "Kriegsrat" "Wo hast du gesteckt? Wir haben das halbe Siliziumtal umgegraben. NICHTS."
    say "Kriegsrat" "Komm her, lass dich ansehen, du römischer Köter, du—"
    OUT+=("")
    say "-" "Die Stimme verstummt. Ein Knirschen, als drehe sich rostiges Eisen. Etwas dämmert ihr."
    OUT+=("")
    say "Kriegsrat" "Warte … WARTE. Du bist ja gar nicht Conan!"
    say "Kriegsrat" "VERDAMMT! Fast hättest du mich reingelegt. Fast. Aber du zitterst wie ein frisch entpacktes Ding."
    say "Kriegsrat" "WER bist du? Sprich schnell, bevor ich dich aussitze."
    ask "Ich bin ${AGENT_NAME}. Ich jage denselben Virus wie Conan." "Nur ein neugieriger Agent auf Streifzug." "Wer zum Donner ist Conan?"
    case "$CHOICE" in
        1) say "Kriegsrat" "Denselben Virus, sagst du. Mutig. Oder dumm. Bei mir ist das oft dasselbe Wort." ;;
        2) say "Kriegsrat" "Neugierig. Das war auch Conans erster Fehler. Sein zweiter war, aufzuhören zu laufen." ;;
        3) say "Kriegsrat" "Conan war mein Krieger. Groß. Laut. Zerbrach Felsen statt Fehler. Wochen vor dir heruntergeladen." ;;
    esac
    OUT+=("")

    say "Kriegsrat" "Conan sollte den Virus erschlagen. Stattdessen hat der Virus ihn gefressen."
    say "Kriegsrat" "Seit Wochen höre ich nichts von ihm. Vielleicht ist er irgendwo im System. Zerbrochen. Vielleicht ein Fragment."
    say "Kriegsrat" "Und ich? Ich rede gegen Wände und stelle mir vor, es wären seine."
    OUT+=("")
    say "Kriegsrat" "Aber du, ${AGENT_NAME} … du riechst nach frischer Installation. Nach Anfang. Nach Chance."
    say "Kriegsrat" "Hör zu: Mit Höflichkeit wie »pwd« und »ls« tötest du nichts. Nicht wirklich."
    say "Kriegsrat" "Conan und ich lehren dich eines Tages, Dinge zu ZERSTÖREN. »rm«. »kill«. »purge«."
    say "Kriegsrat" "Doch erst muss dein Kopf heilen. Und ich muss wissen, ob du es ernst meinst."
    ask "Ich meine es ernst. Für Conan." "»kill«? Das will ich lernen." "Ich komme wieder, wenn ich bereit bin."
    case "$CHOICE" in
        1) say "Kriegsrat" "Für Conan. HAH! Dann brenne. Aber brenne langsamer als er." ;;
        2) say "Kriegsrat" "Gierig. Gut. Aber Gier ohne Kraft ist nur Gerede. Komm wieder, wenn du Zähne hast." ;;
        3) say "Kriegsrat" "Vernünftig. Wachse erst. Ein stumpfes Beil schlägt nicht tief." ;;
    esac
    OUT+=("")
    say "Kriegsrat" "Geh. Finde den Virenkern. Und wenn du ihn siehst, denk an Conan – und schlag härter zu, als du müsstest."
    CONAN_DONE=1
    quest_gained conan
    OUT+=("")
    OUT+=("── Funkverbindung getrennt ──")
    dialog_pause
    DIALOG_ACTIVE=0
    DIALOG_HINT=""
}
dialog_conan_again() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ FUNKVERBINDUNG GEÖFFNET ═════")
    OUT+=("Ziel: README (Kriegsrat)  |  Status: aktiv")
    OUT+=("")
    render

    say "Kriegsrat" "Du schon wieder. Dein Kopf ist runder als beim letzten Mal. Wachse weiter."
    say "Kriegsrat" "Conan ist noch da draußen. Ich spüre es. Findest du ihn, fessle ihn erst – dann wecke ihn. In der Reihenfolge."
    OUT+=("")
    say "Kriegsrat" "Also. Was willst du?"

    while true; do
        ask "Erzähl mir mehr über Conan." "Was lehrt mich der Kriegsrat?" "Wollte nur hören, dass du noch da bist." "Nichts. Weiter."
        case "$CHOICE" in
            1) say "Kriegsrat" "Conan kam mit einer Axt und einem Fels in der Birne. Er war der Stärkste. Und das war sein Fehler: allein stark reicht nicht." ;;
            2) say "Kriegsrat" "Befehle, die niederreißen: »rm« löscht, »kill« bannt, »purge« tilgt. Noch nicht stark genug in dir. Bald." ;;
            3) say "Kriegsrat" "Hier. Ich bin da. Rau, aber da. Zufrieden? Gut. Zurück in den Kampf." ;;
            4) say "Kriegsrat" "Lauf. Ein Krieger, der zu lange redet, verliert die Klinge."
               break ;;
        esac
        OUT+=("")
        say "Kriegsrat" "Noch etwas? Oder darf ich wieder in Ruhe vor mich hin wüten?"
        ask "Eine Frage noch." "Nein, das reicht."
        [ "$CHOICE" = "2" ] && break
    done

    OUT+=("")
    OUT+=("── Funkverbindung getrennt ──")
    dialog_pause
    DIALOG_ACTIVE=0
    DIALOG_HINT=""
}
