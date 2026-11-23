# ============================================================
#  TerminalHero - Charakter: Bruno Amboss (Schmied)
# ------------------------------------------------------------
#  Beseelte Datei: »touch BrunoAmboss« öffnet das Gespräch. Bruno
#  betreibt die Schmiede im Zentrum (Orte/Schmiede.sh) und verkauft
#  das Einfache Set sowie das Kampfset.
#
#  STANDARD-DIALOG:
#     1) Handeln   -> öffnet das Handelsfenster (Handelsfenster.sh)
#     2) Tschau    -> verabschiedet sich
#
#  Sein Lager (handel_lager_brunoamboss) wird über handel_stock
#  angemeldet:
#     1× jedes Teil des Einfachen Sets
#     1× jedes Teil des Kampfsets
#  Das Kampfset führt ausschließlich Bruno; Jack Bones bietet es
#  nicht an. Wie bei allen Händlern füllt handel_day_sync den
#  Grundbestand an jedem neuen Spieltag wieder auf.
#
#  Lazy geladen über DIALOG[] (kern/loader.sh), erst beim ersten
#  »touch BrunoAmboss«. Die Anmeldung unten macht den Laden auch
#  über »trade Bruno« oder »trade Schmied« erreichbar.
# ============================================================

# ============================================================
#  Brunos Lager (Handelsfenster.sh)
# ------------------------------------------------------------
#  Idempotent - die Anmeldung darf mehrfach laufen.
# ============================================================
handel_lager_brunoamboss() {
    th_source_if_fn handel_define           # Handelsfenster nachladen
    declare -F handel_define >/dev/null 2>&1 || return 1
    handel_define brunoamboss "Bruno Amboss"
    handel_alias  brunoamboss "Bruno" "Bruno Amboss" "Schmied" "Schmiede" "Amboss"

    # Das Einfache Set: Bruno hat es ebenso wie Jack Bones.
    handel_stock brunoamboss einfachesschwert 1
    handel_stock brunoamboss einfachemuetze 1
    handel_stock brunoamboss einfacheshemd 1
    handel_stock brunoamboss einfachehose 1
    handel_stock brunoamboss einfachesschild 1
    handel_stock brunoamboss einfacherring 1
    handel_stock brunoamboss einfachesamulett 1

    # Das Kampfset: ausschließlich beim Schmied.
    handel_stock brunoamboss kampfschwert 1
    handel_stock brunoamboss kampfhaube 1
    handel_stock brunoamboss kettenhemd 1
    handel_stock brunoamboss kettenhose 1
    handel_stock brunoamboss kampfschild 1
    handel_stock brunoamboss kampfring 1
    handel_stock brunoamboss kampfamulett 1

    # Beschützerset (erst ab Level 10)
    if [ "${LEVEL:-0}" -ge 10 ]; then
        handel_stock brunoamboss beschützerklinge 1
        handel_stock brunoamboss beschützerhelm 1
        handel_stock brunoamboss beschützerhemd 1
        handel_stock brunoamboss beschützerhose 1
        handel_stock brunoamboss beschützerschild 1
        handel_stock brunoamboss beschützerring 1
        handel_stock brunoamboss beschützeramulett 1
    fi

    # Frisches Obst
    handel_stock brunoamboss apfel 1
    handel_stock brunoamboss kl_token_fill 10
    return 0
}
handel_lager_brunoamboss

# ============================================================
#  Gespräch (»touch BrunoAmboss«)
# ============================================================
dialog_brunoamboss() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ SCHMIEDE · ZENTRUM ═════")
    OUT+=("Meister : Bruno Amboss    Status : die Esse ist heiß")
    OUT+=("")
    render

    say "-" "Die Luft in der Schmiede ist trocken und heiß. Funken steigen von der Esse auf, während ein breitschultriger Mann mit Lederschürze und rußigen Händen ein Stück Metall wendet."
    say "Bruno" "Bruno Amboss. Schmied. Wenn du etwas aus Eisen brauchst, bist du hier richtig."
    say "Bruno" "Das Einfache Set habe ich auch. Aber wenn du vorhast, länger draußen zu bleiben, nimm das Kampfset. Klinge, Haube, Kettenhemd, Kettenhose, Schild, Ring und Amulett."
    say "Bruno" "Der Ring ist kein Schmuck. Er zieht die Energie schneller zurück in deine Tokens. Und das Amulett hält mehr, als man ihm ansieht."
    say "Bruno" "Alles ist ehrliche Arbeit. Nichts davon macht dich unsterblich."
    OUT+=("")
    while true; do
        ask "Handeln" "Tschau"
        case "$CHOICE" in
            1)  # HANDELN: das Handelsfenster mit Brunos Lager öffnen.
                handel_lager_brunoamboss
                say "Bruno" "Dann schau dir an, was auf dem Amboss liegt."
                handel_start brunoamboss
                DIALOG_ACTIVE=1 ;;
            2)  # TSCHAU: Standardverabschiedung.
                say "Bruno" "Tschau. Und lass die Finger vom heißen Eisen."
                break ;;
        esac
    done
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}
