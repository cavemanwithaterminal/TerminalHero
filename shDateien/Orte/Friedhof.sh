# ============================================================
#  TerminalHero - Ort: ~/Schreibtisch/Brachland/Friedhof
# ------------------------------------------------------------
#  Der Friedhof liegt im Brachland. Hier findet Neks Beerdigung
#  statt (Charakter/NeksBeerdigung.sh): Am Beerdigungstag stehen
#  die Trauergäste zwischen den Gräbern, vor 16:00 mit kurzen
#  Standard-Dialogen. Ab 16:00 beginnt automatisch die Trauerfeier;
#  danach ist die Quest abgeschlossen.
#
#  Zwischen den Gräbern arbeitet Francesco Dellamorte, der
#  Totengräber (Charakter/FrancescoDellamorte.sh). Seine beseelte
#  Datei wird hier aufgebaut; angesprochen wird er mit
#  »touch FrancescoDellamorte«.
#
#  Die Trauergäste (Pixi, Jack, Rachel, Sherlock, Torwächter,
#  Simple Jon, Börty und Neks Familie) sind dynamische Dateien:
#  nek_funeral_guests_sync legt sie am Beerdigungstag an. Nach der
#  Trauerfeier bleiben sie bis Mitternacht für Nachgespräche; erst
#  danach entfernt sie der Tick wieder.
#
#  Der Ordner und die Datei gehören zum statischen Grundgerüst
#  (kern/fs.sh). Diese Ortsdatei setzt nach load_contents den
#  Inhalt und den Dialog. Gräber und weitere Ausgestaltung folgen
#  später.
# ============================================================

friedhof_prefix() {
    printf '%s/Schreibtisch/Brachland/Friedhof' "$HOME_DIR"
}

friedhof_build() {
    local _f
    _f="$(friedhof_prefix)/FrancescoDellamorte"

    CONTENT["$_f"]="========================================\n  FRIEDHOF  //  FRANCESCO DELLAMORTE\n========================================\nName    : Francesco Dellamorte\nHerkunft: Italien\nBeruf   : Totengräber\nStatus  : arbeitet. Wie immer.\n\nZuständig:\n  Bestattungen, Gräber und die Ordnung\nder Reihen. Er nimmt seinen Beruf sehr\npersönlich – und ein wenig anders als die\nmeisten.\n\nNotiz:\n  »Die Toten beschweren sich nie.\n   Das ist einer der Gründe, warum ich\n   den Job mag.«\n\nWer ihn berührt (touch FrancescoDellamorte),\nlernt einen seltsamen, aber freundlichen\nMann kennen. (cat FrancescoDellamorte · file FrancescoDellamorte)"
    DIALOG["$_f"]="dialog_francesco_dellamorte"

    # Am Beerdigungstag erscheinen hier die Trauergäste. Der Aufruf ist
    # absichtlich weich: Wird Friedhof.sh einmal ohne NeksBeerdigung.sh
    # geladen (z. B. in einem isolierten Test), bleibt der Ort trotzdem
    # benutzbar.
    if declare -F nek_funeral_guests_sync >/dev/null 2>&1; then
        nek_funeral_guests_sync >/dev/null 2>&1 || true
    fi
}
