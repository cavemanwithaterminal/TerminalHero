# ============================================================
#  TerminalHero - Charakter: Jack Bones (»Survival Jack«)
# ------------------------------------------------------------
#  Beseelte Datei: »touch JackBones« öffnet das Gespräch. Jack betreibt
#  den SurvivalShop im Zentrum (Orte/SurvivalShop.sh) und verkauft
#  Ausrüstung für draußen.
#
#  STANDARD-DIALOG:
#     1) Handeln          -> öffnet das Handelsfenster (Handelsfenster.sh)
#     2) Befehl lernen    -> Untermenü für grep/search/rm (nur solange
#                            mindestens einer dieser Befehle fehlt)
#     3) Tschau           -> verabschiedet sich
#
#  Unterricht: grep 1 Skillpunkt + 25 Bits, search 2 + 50, rm 3 + 100.
#  Bei »rm« nennt Jack zusätzlich die Benutzungskosten: 50 Tokens
#  Grundkosten plus gegnerabhängige Zusatzkosten, die von Gegner zu
#  Gegner verschieden sind. »cal« lehrt Jack Nullpunkt im Verlag,
#  nicht Survival Jack.
#  Im Untermenü steht als letzte Option »zurück«; sie führt zurück in
#  den Standard-Dialog.
#
#  Sein Lager (handel_lager_jackbones) wird über handel_stock angemeldet:
#     10× Einfache Fackel
#      5× Fackel
#      1× Einfacher Schlafsack
#      1× jedes Teil des Einfachen Sets (Schwert, Mütze, Hemd, Hose,
#         Schild, Ring, Amulett)
#  Wie bei allen Händlern füllt handel_day_sync den Grundbestand an
#  jedem neuen Spieltag wieder auf.
#
#  Lazy geladen über DIALOG[] (kern/loader.sh), erst beim ersten
#  »touch JackBones«. Die Anmeldung unten macht den Laden auch über
#  »trade Survival Jack« erreichbar.
# ============================================================

# ============================================================
#  Jacks Lager (Handelsfenster.sh)
# ------------------------------------------------------------
#  Die Funktion meldet Jack Bones als Händler an. Der Name
#  »handel_lager_jackbones« folgt derselben Konvention wie
#  handel_lager_boerty; der Funktionsindex findet sie ohne die
#  halbe Welt zu laden.
#  Idempotent - die Anmeldung darf mehrfach laufen.
# ============================================================
handel_lager_jackbones() {
    th_source_if_fn handel_define           # Handelsfenster nachladen
    declare -F handel_define >/dev/null 2>&1 || return 1
    handel_define jackbones "Jack Bones"
    handel_alias  jackbones "JackBones" "Jack Bones" "Survival Jack" "SurvivalJack"
    handel_stock  jackbones fackel 10
    handel_stock  jackbones fackel2 5
    handel_stock  jackbones einfacherschlafsack 1
    handel_stock  jackbones moleratcode 10
    handel_stock  jackbones kl_token_fill 10
    # Level-abhängige Token-Fills (erst ab entsprechendem Spielerlevel).
    if [ "${LEVEL:-0}" -ge 10 ]; then
        handel_stock  jackbones token_fill 10
    fi
    if [ "${LEVEL:-0}" -ge 20 ]; then
        handel_stock  jackbones gr_token_fill 10
    fi
    if [ "${LEVEL:-0}" -ge 30 ]; then
        handel_stock  jackbones r_token_fill 10
    fi
    # Das erste Ausrüstungs-Set. Ein Teil je Tag - wer das ganze Set
    # will, muss entweder sparen oder mehrere Spieltage vorbeikommen.
    handel_stock  jackbones einfachesschwert 1
    handel_stock  jackbones einfachemuetze 1
    handel_stock  jackbones einfacheshemd 1
    handel_stock  jackbones einfachehose 1
    handel_stock  jackbones einfachesschild 1
    handel_stock  jackbones einfacherring 1
    handel_stock  jackbones einfachesamulett 1
    return 0
}
handel_lager_jackbones

# ============================================================
#  Unterricht (»Befehl lernen«)
# ============================================================
jackbones_skillpunkt_text() {   # <anzahl>
    if [ "${1:-0}" = "1" ]; then
        printf 'Skillpunkt'
    else
        printf 'Skillpunkte'
    fi
}

# Einen Befehl beibringen. Rückgabe 0 = gelernt/bereits bekannt,
# 1 = zu wenig Skillpunkte oder Bits (dann wird nichts abgezogen).
jackbones_teach_cmd() {   # <befehl> <skillpunkte> <bits>
    local cmd="$1" sp="$2" cost="$3"
    if declare -F knows >/dev/null 2>&1 && knows "$cmd"; then
        say "Jack Bones" "»${cmd}« kennst du doch längst. Dafür nehme ich kein Geld."
        return 0
    fi

    if [ "${SKILL_POINTS:-0}" -lt "$sp" ] 2>/dev/null \
       || ! bits_has "$cost"; then
        play_sound error
        say "Jack Bones" "Dafür brauchst du ${sp} $(jackbones_skillpunkt_text "$sp") und $(bits_text "$cost")."
        say "Jack Bones" "Komm wieder, wenn du beides hast. Ich laufe nicht weg."
        return 1
    fi

    SKILL_POINTS=$(( ${SKILL_POINTS:-0} - sp ))
    bits_take "$cost" || true
    if [ "$sp" -gt 0 ] || [ "$cost" -gt 0 ]; then
        OUT+=("   [ Skillpunkte ]  -${sp}   ·   [ Bits ]  -$(bits_text "$cost")")
    fi
    learn_cmd "$cmd"
    say "Jack Bones" "Dann gehört »${cmd}« jetzt dir. Benutz ihn draußen, nicht auf meinem Laden."
    return 0
}

# Untermenü: nur noch nicht gelernte Befehle anbieten; »zurück« steht
# immer am Ende und führt in den Standard-Dialog zurück.
jackbones_learn_menu() {
    local opts=() acts=() cmd sp cost label act
    while true; do
        opts=(); acts=()
        for cmd in grep search rm; do
            case "$cmd" in
                grep)   sp=1; cost=25  ;;
                search) sp=2; cost=50  ;;
                rm)     sp=3; cost=100 ;;
            esac
            if declare -F knows >/dev/null 2>&1 && knows "$cmd"; then
                continue
            fi
            label="${cmd} lernen (${sp} $(jackbones_skillpunkt_text "$sp"), $(bits_text "$cost"))"
            opts+=("$label")
            acts+=("$cmd")
        done
        if [ "${#opts[@]}" -eq 0 ]; then
            say "Jack Bones" "Du kennst bereits alles, was ich dir beibringen kann."
            return 0
        fi

        opts+=("zurück"); acts+=("back")
        OUT+=("")
        say "Jack Bones" "Was willst du lernen?"
        if ! declare -F knows >/dev/null 2>&1 || ! knows rm; then
            say "Jack Bones" "Bei »rm« kommen zu den 50 Tokens Grundkosten noch die Kosten des Gegners. Die sind von Gegner zu Gegner verschieden."
        fi
        ask "${opts[@]}"

        act="back"
        if [ "${CHOICE:-0}" -ge 1 ] && [ "${CHOICE:-0}" -le "${#acts[@]}" ]; then
            act="${acts[$((CHOICE - 1))]}"
        fi

        case "$act" in
            back)
                say "Jack Bones" "Dann zurück. Das Angebot bleibt stehen."
                return 0 ;;
            grep)   jackbones_teach_cmd grep 1 25 ;;
            search) jackbones_teach_cmd search 2 50 ;;
            rm)     jackbones_teach_cmd rm 3 100 ;;
        esac
        # Nach dem Unterricht (oder einer Absage) bleibt das Menü offen,
        # bis der Agent »zurück« wählt.
    done
}

# ============================================================
#  Gespräch (»touch JackBones«)
# ============================================================
dialog_jackbones() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ SURVIVALSHOP · ZENTRUM ═════")
    OUT+=("Inhaber : Jack Bones    Ruf : »Survival Jack«")
    OUT+=("Status : offen. Solange das Licht reicht.")
    OUT+=("")
    render

    say "-" "Zwischen Regalen aus zusammengenagelten Kisten steht ein Mann mit einer abgewetzten Jacke. Er mustert dich einmal von oben bis unten."
    say "Jack Bones" "Willkommen im SurvivalShop. Ich bin Jack Bones. Manche sagen Survival Jack."
    say "Jack Bones" "Fackeln, Schlafsäcke, einfache Ausrüstung. Alles für die Nacht und für den ersten Kampf. Kein Schnickschnack, kein Papierkram."
    say "Jack Bones" "Wenn du draußen nicht frierst und nicht im Dunkeln stehst, hast du bei mir gekauft. Oder Glück gehabt."
    OUT+=("")
    while true; do
        local opts=() acts=() act="bye"
        opts+=("Handeln"); acts+=("trade")
        if ! knows grep || ! knows search || ! knows rm; then
            opts+=("Befehl lernen"); acts+=("learn")
        fi
        opts+=("Tschau"); acts+=("bye")
        ask "${opts[@]}"

        if [ "${CHOICE:-0}" -ge 1 ] && [ "${CHOICE:-0}" -le "${#acts[@]}" ]; then
            act="${acts[$((CHOICE - 1))]}"
        fi

        case "$act" in
            trade)  # HANDELN: das Handelsfenster mit Jacks Lager öffnen.
                handel_lager_jackbones
                say "Jack Bones" "Dann leg los. Schau dir an, was du brauchst."
                handel_start jackbones
                DIALOG_ACTIVE=1 ;;
            learn)  # BEFEHL LERNEN: Untermenü mit »zurück«.
                jackbones_learn_menu ;;
            bye)    # TSCHAU: Standardverabschiedung.
                say "Jack Bones" "Tschau. Und denk dran: Draußen wird es früh dunkel."
                break ;;
        esac
    done
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}
