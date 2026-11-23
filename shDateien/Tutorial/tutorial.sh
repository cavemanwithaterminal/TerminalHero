# ============================================================
#  TerminalHero - Zweites Intro: Der Agent erwacht  (Tutorial)
#
#  Der Virus hat den Agenten geschwächt: Er "sieht" zunächst nichts.
#  Kein Pfad, kein Ordnerinhalt. Erst wenn der Spieler die Grundbefehle
#  benutzt, erwacht die Oberfläche Stück für Stück:
#     pwd          -> PFAD-Fenster erwacht
#     ls           -> ORDNER-Fenster erwacht
#     cat README   -> Auftrag sickert zurück
#     touch README -> Gespräch beginnt
#  Der Tutorial-Zustand (TUT_*) lebt in kern/state.sh.
# ============================================================

tsay()  { say "$AGENT_NAME" "$1" 0.32; }   # Agent (innerer Monolog)
tnote() { say "-" "$1" 0.32; }             # reine Erzählstimme
tutorial_intro() {
    TUT_STAGE=1
    TUT_HINTED=0
    OUT=(); WRAP_KEY=""
    tnote "Ein System bootet. Tief zwischen den Prozessen öffnet ein Agent die Augen."
    tnote "Doch was er sieht, ist nichts. Kein Licht. Keine Daten. Nur Schwarz."
    tsay "…"
    tsay "…wo … wo bin ich?"
    tsay "Alles ist schwarz. Ich sehe nicht einmal den Boden unter mir."
    tsay "Und je mehr ich nachdenke, desto leerer wird es. Als hätte mir jemand den Kopf ausgeräumt."
    OUT+=("")
    tnote "Ein Flüstern aus der Dunkelheit: Ein Virus hat sich in seinen Kern gefressen."
    tnote "Und mit dem Virus ging fast alles verloren, was der Agent einmal wusste."
    OUT+=("")
    tsay "Ich muss einen Fuß fassen. Irgendetwas muss mir sagen, wo ich stehe."
    tsay "»pwd« … ja. Diesen Befehl kenne ich noch. Er zeigt mir meinen Standort."
}
tutorial_after_pwd() {
    tnote "Der PFAD-Bildschirm erwacht und zeigt zum ersten Mal einen Ort."
    tsay "Da! Ein Umriss. Ein Pfad: $(short_path "$CWD")."
    tsay "Also bin ich doch irgendwo. In einem Verzeichnis. Aber ringsum … nichts."
    tsay "Bin ich hier allein? Diese Stille macht mir Angst."
    OUT+=("")
    tsay "Ich muss mich umsehen. Ob hier etwas ist – das zeigt mir »ls«."
}
tutorial_after_ls() {
    tnote "Der ORDNER-Bildschirm füllt sich. Ein Stück Dunkelheit weicht."
    tsay "Da ist etwas! Eine einzige Datei: README."
    tsay "Sonst nichts. Kein Müll, keine Reste. Nur sie. Bin ich … allein mit ihr?"
    OUT+=("")
    tsay "Und was mache ich hier überhaupt? Was ist meine Aufgabe?"
    tsay "Ich erinnere mich nur noch dunkel … an etwas Wichtiges. An etwas Gefährliches."
    tsay "Vielleicht steht es in dieser README. Ich sollte sie lesen – mit »cat README«."
}
tutorial_after_cat() {
    OUT+=("")
    tnote "Zeile für Zeile sickert Erinnerung zurück. Ein Einsatzbefehl."
    tsay "Ich bin also ein Anti-Virus-Agent. Und da steht: »Wer sie berührt, beginnt ein Gespräch.«"
    tsay "Eine Datei, die spricht? Ich sollte es wagen – mit »touch README«."
}
tutorial_after_touch() {
    TUT_DONE=1
    tnote "Die README verstummt. Die Funkverbindung ist getrennt."
    tsay "Gut. Der Auftrag steht: den Virenkern finden und unschädlich machen."
    tsay "Mein Kopf ist noch halb leer, aber die Befehle kommen zurück. Stück für Stück."
    tsay "Für den Anfang reicht, was ich habe: pwd, ls, cd, cat, touch."
    tsay "Und die vier Werkzeuge des Generals: »help«, »character«, »questlog« und »inventar«."
    tsay "Der Rest wird sich zeigen. Los geht's."
    # Das Tutorial ist durch: die Hauptquest »Aller Anfang ist schwer«
    # ist abgeschlossen - mit Belohnung (50 EXP, siehe InGameBefehle/questlog.sh).
    quest_reward anfang 50
}
tut_expected() {
    case "$TUT_STAGE" in
        1) printf 'pwd' ;;
        2) printf 'ls' ;;
        3) printf 'cat' ;;
        4) printf 'touch' ;;
        *) printf '' ;;
    esac
}
tutorial_block() {
    play_sound error
    case "$TUT_STAGE" in
        1) OUT+=("Nein. Mein Kopf lässt gerade nur eine Sache zu: »pwd« – wo bin ich?") ;;
        2) OUT+=("Nein. Ich muss mich erst umsehen. Nur »ls« hilft mir gerade.") ;;
        3) OUT+=("Nein. Meine Aufgabe steckt in der README. Nur »cat README« hilft mir gerade.") ;;
        4) OUT+=("Nein. Ich muss erst mit der README sprechen. Nur »touch README« hilft mir gerade.") ;;
    esac
}
tutorial_hint() {
    local c="$1"
    [ "$TUT_HINTED" = "$TUT_STAGE" ] && return 0
    case "$TUT_STAGE" in
        1) [ "$c" = "pwd" ]   && return 0; tsay "Ich muss herausfinden, wo ich bin. »pwd« zeigt mir meinen Standort." ;;
        2) [ "$c" = "ls" ]    && return 0; tsay "Ich bin nicht allein – da muss etwas sein. »ls« zeigt mir, was hier ist." ;;
        3) [ "$c" = "cat" ]   && return 0; tsay "Meine Aufgabe … vielleicht steht sie in der README. »cat README«." ;;
        4) [ "$c" = "touch" ] && return 0; tsay "Ich sollte die README berühren. »touch README« – dann beginnt das Gespräch." ;;
        *) return 0 ;;
    esac
    TUT_HINTED="$TUT_STAGE"
}
