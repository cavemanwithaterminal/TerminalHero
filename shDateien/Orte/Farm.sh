# ============================================================
#  TerminalHero - Ort: .../Steppe/Farmland/Farm
# ------------------------------------------------------------
#  Die Farm gehört der Familie Molerat. Wohnhaus ist das Anwesen
#  auf dem Farmgelände:
#
#    Farm/Anwesen
#      └── Haupteingang
#            └── Erdgeschoss   (Gregor, Marlene, Chantal)
#
#  Die drei Figuren sind dynamische Dateien: anwesen_build
#  (Orte/Anwesen.sh) legt sie nach load_contents im Erdgeschoss an.
#  Am Tag von Neks Beerdigung stehen sie stattdessen als Trauergäste
#  im Friedhof; dann entfernt anwesen_build sie dort. Nach
#  Mitternacht bzw. nach der Beerdigung kehren sie ins Anwesen zurück.
#
#  Die Dialoge stehen in Charakter/MoleratFamilie.sh und haben zwei
#  Varianten: vor und nach Neks Beerdigung.
#
#  Der Ordner gehört zum statischen Grundgerüst (kern/fs.sh).
# ============================================================

farm_prefix() {
    printf '%s/Schreibtisch/Brachland/Steppe/Farmland/Farm' "$HOME_DIR"
}

# Steht die Familie gerade auf dem Friedhof? Dann darf sie nicht
# zusätzlich im Anwesen stehen.
farm_family_should_exist() {
    if declare -F nek_funeral_guests_should_exist >/dev/null 2>&1; then
        nek_funeral_guests_should_exist && return 1
    fi
    return 0
}

# Kompatibilitätsname: Die Familie wohnt inzwischen im Erdgeschoss
# des Anwesens. Ältere Aufrufer (NeksBeerdigung, TerminalShell) dürfen
# weiterhin farm_build rufen.
farm_build() {
    if ! declare -F anwesen_build >/dev/null 2>&1 \
       && declare -F require_ort >/dev/null 2>&1; then
        require_ort Anwesen
    fi
    if declare -F anwesen_build >/dev/null 2>&1; then
        anwesen_build
        return 0
    fi
    declare -F fs_add >/dev/null 2>&1 && fs_add d "$(farm_prefix)"
    return 0
}
