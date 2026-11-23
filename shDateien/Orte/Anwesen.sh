# ============================================================
#  TerminalHero - Ort: .../Farmland/Farm/Anwesen
# ------------------------------------------------------------
#  Das Wohnhaus der Familie Molerat. Über den Haupteingang gelangt
#  der Agent ins Erdgeschoss, wo Gregor, Marlene und Chantal zu
#  Hause sind.
#
#  Die Familie wird nicht hier, sondern im Erdgeschoss angelegt
#  (anwesen_build). Am Beerdigungstag verschwindet sie aus dem
#  Erdgeschoss und steht stattdessen auf dem Friedhof.
#
#  Der Ordner gehört zum statischen Grundgerüst (kern/fs.sh).
# ============================================================

anwesen_prefix() {
    printf '%s/Anwesen' "$(farm_prefix)"
}

anwesen_haupteingang_prefix() {
    printf '%s/Haupteingang' "$(anwesen_prefix)"
}

anwesen_erdgeschoss_prefix() {
    printf '%s/Erdgeschoss' "$(anwesen_haupteingang_prefix)"
}

anwesen_family_should_exist() {
    if declare -F farm_family_should_exist >/dev/null 2>&1; then
        farm_family_should_exist && return 0
        return 1
    fi
    if declare -F nek_funeral_guests_should_exist >/dev/null 2>&1; then
        nek_funeral_guests_should_exist && return 1
    fi
    return 0
}

anwesen_remove_family() {
    local file p
    for file in GregorMolerat MarleneMolerat ChantalMolerat; do
        p="$(anwesen_erdgeschoss_prefix)/$file"
        declare -F fs_remove >/dev/null 2>&1 && fs_remove "$p"
        unset "CONTENT[$p]" "DIALOG[$p]"
    done
    return 0
}

# Ältere Spielstände (und alte Dynamik-Einträge) tragen die Familie noch
# direkt im Farm-Ordner. Dort ist sie falsch: Sie wohnt im Erdgeschoss
# des Anwesens. Diese Altlasten werden bei jedem Aufbau entfernt.
anwesen_remove_legacy_family() {
    local file p
    for file in GregorMolerat MarleneMolerat ChantalMolerat; do
        p="$(farm_prefix)/$file"
        declare -F fs_remove >/dev/null 2>&1 && fs_remove "$p"
        unset "CONTENT[$p]" "DIALOG[$p]"
    done
    return 0
}

anwesen_place_family() {   # <dateiname> <anzeigename> <rolle> <notiz> <dialog>
    local file="$1" label="$2" role="$3" note="$4" dlg="$5"
    local p; p="$(anwesen_erdgeschoss_prefix)/$file"
    declare -F fs_add >/dev/null 2>&1 && fs_add f "$p"
    CONTENT["$p"]="========================================
  ANWESEN  //  ${label}
  ERDGESCHOSS
========================================
Rolle   : ${role}
Zuhause : Anwesen der Familie Molerat
          (Farm im Farmland, Erdgeschoss)

${note}

Wer diese Datei berührt (touch ${file}),
hört, was die Familie zu sagen hat.
(cat ${file} · file ${file})"
    DIALOG["$p"]="$dlg"
}

anwesen_build() {
    declare -F fs_add >/dev/null 2>&1 && fs_add d "$(anwesen_prefix)"
    declare -F fs_add >/dev/null 2>&1 && fs_add d "$(anwesen_haupteingang_prefix)"
    declare -F fs_add >/dev/null 2>&1 && fs_add d "$(anwesen_erdgeschoss_prefix)"

    # Alte Familie-Dateien direkt auf der Farm entfernen (nur noch im
    # Erdgeschoss des Anwesens).
    anwesen_remove_legacy_family

    if ! anwesen_family_should_exist; then
        anwesen_remove_family
        return 0
    fi

    anwesen_place_family GregorMolerat "Gregor Molerat" \
        "Vater, ernst und wortkarg" \
        "Status : arbeitet. Wie jeden Tag.
Notiz  : »Der Boden fragt nicht, wie du
         dich fühlst. Er wartet einfach.«" \
        dialog_farm_gregor

    anwesen_place_family MarleneMolerat "Marlene Molerat" \
        "Mutter, traurig und still" \
        "Status : hält das Haus in Ordnung.
Notiz  : »Ein Teller bleibt gedeckt.
         Auch wenn niemand kommt.«" \
        dialog_farm_marlene

    anwesen_place_family ChantalMolerat "Chantal Molerat" \
        "Tochter, verwöhnt und gelangweilt" \
        "Status : wartet auf besseres Netz.
Notiz  : »Diese Farm ist ein einziger
         Flugmodus.«" \
        dialog_farm_chantal

    return 0
}
