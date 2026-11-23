# ============================================================
#  TerminalHero - Speichern & Laden
#
#  Spielstände:
#    quick    / "Quicksave"   - automatisch alle 10 Minuten (im Spiel), nur 1 Slot
#    manual1-3 / "Spielstand" - vom Spieler per "save" ausgelöst, 3 Slots
#
#  Ablage:  <projekt>/saves/quicksave.save bzw. manual1.save/manual2.save/manual3.save
#  Format:  eine per "source" einlesbare Bash-Datei
# ============================================================

TH_SAVE_VERSION=1

# --- Pfade -----------------------------------------------------------
# saves/ liegt in der PROJEKTWURZEL (Ebene über shDateien/), nicht bei den
# Skripten. PROJ_DIR wird von TerminalHero.sh / TerminalShell.sh gesetzt.
th_saves_dir() {
    local root="${PROJ_DIR:-${SCRIPT_DIR:-.}}"
    local d="${TH_SAVES_DIR:-$root/saves}"
    [ -d "$d" ] || mkdir -p "$d" 2>/dev/null
    printf '%s' "$d"
}

# Typ normalisieren: quick|manual1|manual2|manual3 (oder Rückgabefehler)
th_norm_type() {
    case "${1,,}" in
        quick|quicksave|schnell)     printf 'quick' ;;
        manual|manuell|save|speichern|manual1|slot1|1) printf 'manual1' ;;
        manual2|slot2|2) printf 'manual2' ;;
        manual3|slot3|3) printf 'manual3' ;;
        *) return 1 ;;
    esac
}

th_save_file() {   # $1 = quick|manual1|manual2|manual3 -> kanonischer Schreibpfad
    local t
    t="$(th_norm_type "$1")" || return 1
    case "$t" in
        quick)    printf '%s/quicksave.save'  "$(th_saves_dir)" ;;
        manual1)  printf '%s/manual1.save'    "$(th_saves_dir)" ;;
        manual2)  printf '%s/manual2.save'    "$(th_saves_dir)" ;;
        manual3)  printf '%s/manual3.save'    "$(th_saves_dir)" ;;
        *) return 1 ;;
    esac
}

# Lesepfad: berücksichtigt Altstände (Slot 1 früher als manual.save).
th_read_save_file() {
    local t f
    t="$(th_norm_type "$1")" || return 1
    f="$(th_save_file "$t")" || return 1
    if [ "$t" = "manual1" ] && [ ! -s "$f" ]; then
        local legacy; legacy="$(th_saves_dir)/manual.save"
        [ -s "$legacy" ] && { printf '%s' "$legacy"; return 0; }
    fi
    printf '%s' "$f"
}

th_have_save() {   # 0, wenn ein (nicht-leerer) Speicherstand existiert
    local f; f="$(th_read_save_file "$1")" || return 1
    [ -s "$f" ]
}

# Kopfzeilen-Info ohne die Datei auszuführen:  "WHEN|user@host|agent|type"
th_save_info() {
    local f; f="$(th_read_save_file "$1")" || return 1
    [ -s "$f" ] || return 1
    sed -n 's/^#TH_SAVE_INFO|//p' "$f" | head -n1
}

th_save_when() {   # nur der Zeitstempel (für die Anzeige)
    local i; i="$(th_save_info "$1")" || return 1
    printf '%s' "${i%%|*}"
}

# --- Serialisierung --------------------------------------------------
# Bewusst OHNE "declare": die Ausgabe wird später per "source" eingelesen,
# teils aus Funktionen heraus - dort würden "declare"-Zuweisungen nur
# lokale Variablen erzeugen. Einfache Zuweisungen wirken global.
th_dump_indexed() {   # $1 = Name eines indizierten Arrays
    declare -p "$1" >/dev/null 2>&1 || return 0
    local name="$1"; local -n __arr="$name"
    printf '%s=(' "$name"
    local i
    for i in "${!__arr[@]}"; do printf '[%s]=%q ' "$i" "${__arr[$i]}"; done
    printf ')\n'
}

th_dump_assoc() {     # assoziatives Array; erzwingt -g (Laden passiert in einer Funktion)
    declare -p "$1" >/dev/null 2>&1 || return 0
    local name="$1"; local -n __arr="$name"
    printf 'declare -g -A %s\n' "$name"
    printf '%s=(' "$name"
    local k
    for k in "${!__arr[@]}"; do printf '[%q]=%q ' "$k" "${__arr[$k]}"; done
    printf ')\n'
}

# Nur die DYNAMISCHEN Einträge des Dateisystems sichern (alles, was nicht zum
# statischen Grundgerüst aus fs.sh gehört). So bleibt das Grundgerüst
# jederzeit aktuell, auch wenn sich der Spielstand noch auf einen alten Baum
# bezieht.
th_dump_dyn_type() {
    printf 'declare -g -A TH_DYN_TYPE=('
    local k
    for k in "${!TYPE[@]}"; do
        [ -n "${FS_BASE_TYPE[$k]:-}" ] && continue
        printf '[%q]=%q ' "$k" "${TYPE[$k]}"
    done
    printf ')\n'
}

# --- Speichern -------------------------------------------------------
th_save() {   # $1 = quick|manual ; Rückgabe 0 = ok
    local type f tmp now v
    type="$(th_norm_type "$1")" || return 1
    f="$(th_save_file "$type")" || return 1
    tmp="${f}.tmp.$$"
    now="$(date '+%Y-%m-%d %H:%M:%S')"

    # Echte Spielzeit bis zum Speichern festschreiben (kern/playtime.sh).
    if declare -F playtime_snapshot >/dev/null 2>&1; then
        playtime_snapshot
    fi

    {
        printf '# TerminalHero Spielstand v%s\n' "$TH_SAVE_VERSION"
        printf '#TH_SAVE_INFO|%s|%s@%s|%s|%s\n' \
               "$now" "$USERNAME_" "$HOSTNAME_" "$AGENT_NAME" "$type"
        printf 'TH_SAVE_VERSION=%q\n' "$TH_SAVE_VERSION"
        printf 'TH_SAVE_TYPE=%q\n' "$type"
        printf 'TH_SAVE_WHEN=%q\n' "$now"

        # Skalare (nur die, die es gerade gibt)
        for v in USERNAME_ HOSTNAME_ AGENT_NAME START_DIR_NAME CWD OLDPWD VIEW_DIR \
                 SHOW_PATH SHOW_LS TUT_STAGE TUT_HINTED TUT_DONE README_DONE \
                 CONAN_DONE DETEKTIV_DONE SAVE_LEARNED TOUCH_CREATE_KNOWN CD_BARE_KNOWN AGENT_ATTITUDE AGENT_APPROACH LS_SHOW_ALL \
                 HOME_FIRST_VISIT PIXI_DESKTOP_DONE PIXI_GATE_DONE PIXI_HALL_DONE TORWAEHTER_DONE \
                 VERLAG_DONE PIXI_GUIDE_DONE BARACKE_SCENE_DONE \
                 PIXI_LETTER_DONE AMANDA_INTRO_DONE AMANDA_DONE \
                 AMANDA_HELP_GIVEN AMANDA_HELP_ASKED AMANDA_HELP_JACK AMANDA_HELP_DONE \
                 SHERLOCK_DONE BOERTY_SH_DONE BOERTY_INTRO_DONE BOERTY_INFO \
                 SHERLOCK_HUNT SHERLOCK_NORD SHERLOCK_BRIEF ERMITTLER_DONE \
                 RELIGION_GIVEN BILL_MET BILL_TOLD \
                 TAGEBUCH_FOUND TAGEBUCH_READ RELIGION_BOOK_FIRST \
                 BILL_BOOK_DONE SHERLOCK_BOOK_DONE SHERLOCK_LS_A_DONE \
                 BOERTY_FAVOR_DONE VERMISSTE_GIVEN BIER_GIVEN BIER_TAKEN BIER_DONE \
                 SIMON_NEK_INFO NEK_GIVEN JON_NEK_INFO JON_NEK_FOUND_INFO \
                 BIER_FAILED BIER_LOST_AT SAMY_INTRO_DONE FRANCESCO_MET \
                 ZEITUNG_EDITION ZEITUNG_EMPTIED ZEITUNG_GIVEN ZEITUNG_DONE \
                 ZEITUNG_EXTRA_DAY ZEITUNG_EXTRA_UNTIL ZEITUNG_EXTRA_SHOWN \
                 RUNDGANG_GIVEN RUNDGANG_DONE \
                 AUFLAGE_GIVEN AUFLAGE_DONE \
                 TRACEY_GIVEN TRACEY_FOUND TRACEY_DONE TRACEY_TOUR_START \
                 JIMMY_INTRO_DONE JIMMY_TRACEY_DONE JIMMY_GIVEN JIMMY_LAST_SOLD \
                 JIMMY_FIRST_SALE TRACEY_RIVAL_SEEN \
                 MITCH_GIVEN MITCH_TALKED MITCH_DONE GEHILFE_GIVEN \
                 BOERTY_VERMISSTE_INFO SAMY_VERMISSTE_INFO SAMY_MITCH_INFO \
                 MICHAEL_INTRO_DONE \
                 NEKS_LEICHE_PATH NEKS_LEICHE_SEARCHED DRAGGED_CORPSE \
                 NEK_FOUND NEK_REPORTED NEK_MUST_SEARCH NEK_CORPSE_BROUGHT \
                 NEK_SIMON_SEARCHED NEK_AMULET_SOLD NEK_AMULET_KEPT NEK_DONE \
                 NEK_FUNERAL_GIVEN NEK_FUNERAL_DISPOSITION NEK_FUNERAL_DAY \
                 NEK_FUNERAL_DISCOVERY_DAY NEK_FUNERAL_FOUND \
                 NEK_FUNERAL_DONE NEK_FUNERAL_FAILED NEK_FAMILY_GIVEN \
                 GREGOR_CODE_GIVEN GREGOR_CODE_DELIVERED \
                 GREGOR_CODE_DONE GREGOR_BOOK_DONE \
                 MOLERATS_DEAD MOLERAT_KOENIGIN_DEAD GUY_SUS_MET GUY_SUS_GONE \
                 GUY_SUS_CAVE_DONE GUY_SUS_OUTSIDE_DONE \
                 SLEEP_HOURS_TODAY SLEEP_DAY \
                 SIT_HOURS_TODAY SIT_DAY \
                 TORCH_UNTIL_MIN CAL_UNTIL_MIN \
                 ARCHIVE_KAP1 ARCHIVE_ORT_DESKTOPCITY \
                 TOKENS_CUR TOKENS_MAX TOKENS_REGEN_PCT TOKEN_COST_CMD \
                 BITS BITS_EARNED \
                 LEVEL EXP SKILL_POINTS \
                 WORLD_SECS WORLD_STARTED PLAYTIME_BASE \
                 LAST_CAT_PATH LAST_CAT_OK; do
            [ -n "${!v+x}" ] && printf '%s=%q\n' "$v" "${!v}"
        done

        # Arrays
        th_dump_indexed LEARNED
        th_dump_indexed CMD_HIST
        th_dump_indexed OUT
        th_dump_indexed INV_ORDER
        th_dump_assoc INV_COUNT
        th_dump_assoc EQUIP_SLOT_ITEM
        th_dump_assoc EQUIP_SET_APPLIED
        th_dump_assoc WORLD_TAKEN
        th_dump_assoc WORLD_DROPS
        th_dump_assoc ACH_UNLOCKED
        # Moleratgebiete im Brachland/Steppe: Todeszähler und Respawn-Timer
        # pro Gebiet. Die Höhlen-Molerats bleiben in MOLERATS_DEAD.
        th_dump_assoc MOLERAT_AREA_DEAD
        th_dump_assoc MOLERAT_AREA_NEXT
        # MoleratKrieger der Großen Höhlenkammer (eigener 48h-Takt).
        th_dump_assoc MOLERAT_KRIEGER_DEAD
        th_dump_assoc MOLERAT_KRIEGER_NEXT
        # Händler-Lager (Handelsfenster.sh): nur vorhanden, wenn das Fenster
        # im Spielverlauf schon einmal geladen wurde - dann aber mit.
        th_dump_assoc HANDEL_STOCK
        th_dump_assoc HANDEL_DAY
        th_dump_dyn_type
    } > "$tmp" 2>/dev/null || { rm -f "$tmp"; return 1; }

    mv -f "$tmp" "$f" 2>/dev/null || { rm -f "$tmp"; return 1; }
    return 0
}

# --- Migration alter Spielstände -------------------------------------
# Wird nach jedem erfolgreichen Laden aufgerufen und repariert Zustände,
# die in älteren Versionen durch inzwischen geschlossene Lücken entstanden
# sind. Die Funktion ist idempotent und ändert nur Spielzustand, nie Dateien.
th_save_migrate() {
    # 0) Schreibtisch-Umbau: Der alte Friedhof direkt auf dem Schreibtisch
    #    ist nach Brachland/Friedhof umgezogen. Alte Spielstände, die dort
    #    standen oder die Leiche dort abgelegt haben, werden mitgezogen.
    local _home _old_cem _new_cem _old_canyon _new_canyon _p _v _k _nk
    _home="/home/${USERNAME_:-benutzer}"
    _old_cem="$_home/Schreibtisch/Friedhof"
    _new_cem="$_home/Schreibtisch/Brachland/Friedhof"
    for _v in CWD OLDPWD VIEW_DIR NEKS_LEICHE_PATH DRAGGED_CORPSE; do
        _p="${!_v:-}"
        case "$_p" in
            "$_old_cem"|"$_old_cem"/*)
                printf -v "$_v" '%s' "$_new_cem${_p#"$_old_cem"}"
                ;;
        esac
    done
    if declare -p TH_DYN_TYPE >/dev/null 2>&1; then
        for _k in "${!TH_DYN_TYPE[@]}"; do
            case "$_k" in
                "$_old_cem"|"$_old_cem"/*)
                    _nk="$_new_cem${_k#"$_old_cem"}"
                    TH_DYN_TYPE["$_nk"]="${TH_DYN_TYPE[$_k]}"
                    unset 'TH_DYN_TYPE[$_k]'
                    ;;
            esac
        done
    fi

    # 0b) Brachland-Umbau: Der Canyon lag früher direkt im Brachland und
    #     gehört jetzt unter die Steppe. Alte Stände werden mitgezogen.
    _old_canyon="$_home/Schreibtisch/Brachland/Canyon"
    _new_canyon="$_home/Schreibtisch/Brachland/Steppe/Canyon"
    for _v in CWD OLDPWD VIEW_DIR; do
        _p="${!_v:-}"
        case "$_p" in
            "$_old_canyon"|"$_old_canyon"/*)
                printf -v "$_v" '%s' "$_new_canyon${_p#"$_old_canyon"}"
                ;;
        esac
    done
    if declare -p TH_DYN_TYPE >/dev/null 2>&1; then
        for _k in "${!TH_DYN_TYPE[@]}"; do
            case "$_k" in
                "$_old_canyon"|"$_old_canyon"/*)
                    _nk="$_new_canyon${_k#"$_old_canyon"}"
                    TH_DYN_TYPE["$_nk"]="${TH_DYN_TYPE[$_k]}"
                    unset 'TH_DYN_TYPE[$_k]'
                    ;;
            esac
        done
    fi

    # 1) Bierlieferung: Die Kiste wurde bei Samy abgeholt (BIER_TAKEN=1),
    #    die Quest ist noch offen, aber das Item liegt nicht mehr im
    #    Inventar – z. B. weil es im Handelsfenster verkauft wurde. Bei
    #    einem alten Stand ohne BIER_LOST_AT beginnt die 24-Stunden-Frist
    #    beim Laden; Samy gibt weiterhin Ersatz (250 Bits), solange die
    #    Frist läuft. BIER_TAKEN bleibt gesetzt - die Erstkiste ist weg.
    if [ "${BIER_GIVEN:-0}" = "1" ] && [ "${BIER_DONE:-0}" != "1" ] \
       && [ "${BIER_FAILED:-0}" != "1" ] \
       && [ "${BIER_TAKEN:-0}" = "1" ] \
       && declare -F inv_count >/dev/null 2>&1 \
       && [ "$(inv_count bierlieferung)" -eq 0 ] \
       && [ "${BIER_LOST_AT:--1}" -lt 0 ]; then
        if declare -F uhrzeit_minutes >/dev/null 2>&1; then
            BIER_LOST_AT="$(uhrzeit_minutes)"
        else
            BIER_LOST_AT=0
        fi
    fi
    # 2) Keine offene Frist, wenn die Kiste wieder da ist, die Quest
    #    vorbei ist oder gar nicht läuft.
    if [ "${BIER_GIVEN:-0}" != "1" ] \
       || [ "${BIER_DONE:-0}" = "1" ] \
       || [ "${BIER_FAILED:-0}" = "1" ] \
       || { declare -F inv_count >/dev/null 2>&1 \
            && [ "$(inv_count bierlieferung)" -gt 0 ]; }; then
        BIER_LOST_AT=-1
    fi
    # 3) Amanda: Ältere Stände setzten AMANDA_DONE bei JEDEM Gespräch -
    #    auch vor der Sherlock-Quest. Die Vorstellung bleibt als
    #    AMANDA_INTRO_DONE erhalten; ohne Pixis Brief war es aber kein
    #    Quest-Gespräch, also AMANDA_DONE zurücknehmen.
    if [ "${AMANDA_DONE:-0}" = "1" ] && [ "${AMANDA_INTRO_DONE:-0}" != "1" ]; then
        AMANDA_INTRO_DONE=1
    fi
    if [ "${AMANDA_DONE:-0}" = "1" ] && [ "${PIXI_LETTER_DONE:-0}" != "1" ]; then
        AMANDA_DONE=0
    fi
    # 3b) Unterstützung für Amanda: Ältere Stände kennen die neue
    #     Nebenquest nicht. Ein umgezogener Jack setzt die Quest voraus,
    #     ein Abschluss zusätzlich seinen Umzug.
    : "${AMANDA_HELP_GIVEN:=0}"
    : "${AMANDA_HELP_ASKED:=0}"
    : "${AMANDA_HELP_JACK:=0}"
    : "${AMANDA_HELP_DONE:=0}"
    if [ "$AMANDA_HELP_JACK" = "1" ] || [ "$AMANDA_HELP_DONE" = "1" ]; then
        AMANDA_HELP_GIVEN=1
    fi
    if [ "$AMANDA_HELP_DONE" = "1" ]; then
        AMANDA_HELP_JACK=1
    fi
    if [ "$AMANDA_HELP_JACK" = "1" ]; then
        AMANDA_HELP_ASKED=1
    fi
    # 4) Zeitungskästen (DailyPulse): Ältere Stände kennen die Edition und
    #    die Leerungs-Bitmaske noch nicht. Die erste Ausgabe »Bezirke der
    #    Stadt« ist von Anfang an die aktuelle; alle fünf Kästen sind voll.
    : "${ZEITUNG_EDITION:=bezirke}"
    : "${ZEITUNG_EMPTIED:=0}"
    : "${ZEITUNG_GIVEN:=0}"
    : "${ZEITUNG_DONE:=0}"
    case "$ZEITUNG_EMPTIED" in
        ''|*[!0-9]*) ZEITUNG_EMPTIED=0 ;;
    esac
    [ "$ZEITUNG_EMPTIED" -lt 0 ] && ZEITUNG_EMPTIED=0
    [ "$ZEITUNG_EMPTIED" -gt 31 ] && ZEITUNG_EMPTIED=31
    # 4a0) Extra-Ausgabe nach Neks Beerdigung: Ältere Stände kennen sie
    #      noch nicht. -1 bedeutet »noch nicht erschienen«; der Tick nach
    #      der Beerdigung setzt den Verkaufszeitraum.
    : "${ZEITUNG_EXTRA_DAY:=-1}"
    : "${ZEITUNG_EXTRA_UNTIL:=-1}"
    : "${ZEITUNG_EXTRA_SHOWN:=0}"
    case "$ZEITUNG_EXTRA_DAY" in
        ''|*[!0-9-]*) ZEITUNG_EXTRA_DAY=-1 ;;
    esac
    case "$ZEITUNG_EXTRA_UNTIL" in
        ''|*[!0-9-]*) ZEITUNG_EXTRA_UNTIL=-1 ;;
    esac
    [ "$ZEITUNG_EXTRA_DAY" -lt 0 ] && ZEITUNG_EXTRA_UNTIL=-1
    [ "$ZEITUNG_EXTRA_UNTIL" -lt "$ZEITUNG_EXTRA_DAY" ] \
        && ZEITUNG_EXTRA_UNTIL="$ZEITUNG_EXTRA_DAY"
    # Nach Jacks Quest sind alle fünf Kästen leer. Seit Rachels Verteilung
    # (AUFLAGE_GIVEN) ist die Bitmaske aber auch der Fortschritt dieser
    # Quest: Ein befüllter Kasten hat sein Bit verloren. Deshalb darf die
    # alte Regel nur greifen, solange die neue Auflage noch nicht läuft.
    if [ "$ZEITUNG_DONE" = "1" ] \
       && [ "${AUFLAGE_GIVEN:-0}" != "1" ] \
       && [ "${AUFLAGE_DONE:-0}" != "1" ]; then
        ZEITUNG_EMPTIED=31
    fi
    # 4a) Stadtrundgang mit Pixi: Ältere Stände kennen die Quest noch
    #     nicht. Der Abschluss setzt den Beginn voraus.
    : "${RUNDGANG_GIVEN:=0}"
    : "${RUNDGANG_DONE:=0}"
    if [ "$RUNDGANG_DONE" = "1" ]; then
        RUNDGANG_GIVEN=1
    fi
    # 4a2) Die neueste Auflage: Sperrzone. Am Ende des Rundgangs ist die
    #      neue Ausgabe gedruckt; Rachels Quest setzt den Rundgang voraus.
    #      Ein abgeschlossener Auftrag bedeutet: alle fünf Kästen voll.
    : "${AUFLAGE_GIVEN:=0}"
    : "${AUFLAGE_DONE:=0}"
    if [ "$AUFLAGE_DONE" = "1" ]; then
        AUFLAGE_GIVEN=1
    fi
    if [ "$AUFLAGE_GIVEN" = "1" ]; then
        RUNDGANG_GIVEN=1
        RUNDGANG_DONE=1
    fi
    if [ "$RUNDGANG_DONE" = "1" ] && [ "${ZEITUNG_DONE:-0}" = "1" ]; then
        ZEITUNG_EDITION=sperrzone
        if [ "$AUFLAGE_DONE" = "1" ]; then
            ZEITUNG_EMPTIED=0
        elif [ "$AUFLAGE_GIVEN" != "1" ]; then
            # Neue Ausgabe gedruckt, aber noch nicht verteilt: alle Kästen
            # warten auf Rachels fünf Bündel.
            ZEITUNG_EMPTIED=31
        fi
    fi
    # 4b) Tracey Briggs & Jimmy Page: Ältere Stände kennen die neuen
    #     Gesprächsstufen noch nicht. Der Fund setzt die Quest voraus;
    #     der Abschluss setzt beides voraus; Jimmys Quest setzt Traceys
    #     Fund voraus.
    : "${TRACEY_GIVEN:=0}"
    : "${TRACEY_FOUND:=0}"
    : "${TRACEY_DONE:=0}"
    : "${TRACEY_TOUR_START:=-1}"
    : "${JIMMY_INTRO_DONE:=0}"
    : "${JIMMY_TRACEY_DONE:=0}"
    : "${JIMMY_GIVEN:=0}"
    : "${JIMMY_LAST_SOLD:=}"
    : "${JIMMY_FIRST_SALE:=0}"
    : "${TRACEY_RIVAL_SEEN:=0}"
    # Ein gespeicherter Verkauf belegt den ersten Verkauf auch in alten
    # Ständen. Traceys Konkurrenz-Dialog bleibt dort einmalig nachholbar.
    [ -n "$JIMMY_LAST_SOLD" ] && JIMMY_FIRST_SALE=1
    if [ "${TRACEY_FOUND:-0}" = "1" ] || [ "${TRACEY_DONE:-0}" = "1" ]; then
        TRACEY_GIVEN=1
    fi
    if [ "${TRACEY_DONE:-0}" = "1" ]; then
        TRACEY_FOUND=1
    fi
    if [ "${JIMMY_GIVEN:-0}" = "1" ]; then
        TRACEY_GIVEN=1
        TRACEY_FOUND=1
        JIMMY_TRACEY_DONE=1
    fi
    # 4c) Nek Molerat (Simon Guard & Simple Jon): Ältere Stände kennen
    #     die Nebenquest noch nicht. Jede der neuen Informationen zieht
    #     die vorherigen Stufen nach; die Hauptquest bleibt in jedem Fall
    #     bekannt, weil Simon sie bereits verlangt.
    : "${SIMON_NEK_INFO:=0}"
    : "${NEK_GIVEN:=0}"
    : "${JON_NEK_INFO:=0}"
    : "${JON_NEK_FOUND_INFO:=0}"
    if [ "$JON_NEK_INFO" = "1" ] || [ "$NEK_GIVEN" = "1" ] \
       || [ "$SIMON_NEK_INFO" = "1" ]; then
        SIMON_NEK_INFO=1
        NEK_GIVEN=1
        VERMISSTE_GIVEN=1
    fi
    # 4d) Neks Leiche: Ältere Stände kennen die Höhlen-Leiche noch nicht.
    #     Ohne Pfad wird sie beim Start in der Molerathöhle aufgebaut.
    #     Ein Amulett im Inventar gilt als bereits durchsucht; ein
    #     gespeicherter Zieh-Pfad bleibt nur gültig, wenn die Leiche
    #     wirklich dort liegt (die Prüfung macht neks_leiche_apply_state).
    : "${NEKS_LEICHE_PATH:=}"
    : "${NEKS_LEICHE_SEARCHED:=0}"
    : "${DRAGGED_CORPSE:=}"
    if [ "$NEKS_LEICHE_SEARCHED" != "1" ] \
       && declare -F inv_has >/dev/null 2>&1 \
       && inv_has neksamulett; then
        NEKS_LEICHE_SEARCHED=1
    fi
    # 4e) Nek-Quest-Abschluss: Ältere Stände kennen die neuen Zweige noch
    #     nicht. Wer die Leiche bereits durchsucht hat, hat sie auch
    #     gefunden; ein abgeschlossener Abschluss setzt alle Stufen voraus.
    : "${NEK_FOUND:=0}"
    : "${NEK_REPORTED:=0}"
    : "${NEK_MUST_SEARCH:=0}"
    : "${NEK_CORPSE_BROUGHT:=0}"
    : "${NEK_SIMON_SEARCHED:=0}"
    : "${NEK_AMULET_SOLD:=0}"
    : "${NEK_AMULET_KEPT:=0}"
    : "${NEK_DONE:=0}"
    if [ "$NEKS_LEICHE_SEARCHED" = "1" ]; then
        NEK_FOUND=1
    fi
    if [ "$NEK_MUST_SEARCH" = "1" ] || [ "$NEK_REPORTED" = "1" ] \
       || [ "$NEK_CORPSE_BROUGHT" = "1" ] || [ "$NEK_SIMON_SEARCHED" = "1" ]; then
        NEK_FOUND=1
        NEK_REPORTED=1
    fi
    if [ "$NEK_AMULET_SOLD" = "1" ] || [ "$NEK_AMULET_KEPT" = "1" ] \
       || [ "$NEK_DONE" = "1" ]; then
        NEK_FOUND=1
        NEK_REPORTED=1
        NEK_DONE=1
        SIMON_NEK_INFO=1
        NEK_GIVEN=1
        VERMISSTE_GIVEN=1
    fi
    if [ "$NEK_DONE" = "1" ]; then
        NEK_MUST_SEARCH=0
    fi
    # 4f) Neks Beerdigung & Familie: Ältere Stände kennen die getimte
    #     Folgequest noch nicht. Neue Flags starten sauber; ein alter
    #     abgeschlossener Nek-Stand bekommt KEINE rückwirkende Beerdigung
    #     (die Frist wäre ohnehin vorbei). Ein gespeicherter Abschluss/
    #     Fehlschlag setzt die Quest sichtbar.
    : "${NEK_FUNERAL_GIVEN:=0}"
    : "${NEK_FUNERAL_DISPOSITION:=}"
    : "${NEK_FUNERAL_DAY:=-1}"
    : "${NEK_FUNERAL_DISCOVERY_DAY:=-1}"
    : "${NEK_FUNERAL_FOUND:=0}"
    : "${NEK_FUNERAL_DONE:=0}"
    : "${NEK_FUNERAL_FAILED:=0}"
    : "${NEK_FAMILY_GIVEN:=0}"
    if [ "$NEK_FUNERAL_DONE" = "1" ] || [ "$NEK_FUNERAL_FAILED" = "1" ]; then
        NEK_FUNERAL_GIVEN=1
    fi
    if [ "$NEK_FUNERAL_DONE" = "1" ]; then
        NEK_FUNERAL_FAILED=0
    fi
    # 4g) Gegner & Guy Sus: Ältere Stände kennen die Molerats und die
    #     beiden Guy-Szenen noch nicht. Die Bitmaske startet sauber; ein
    #     gespeicherter Abschluss setzt die sichtbaren Flags konsistent,
    #     damit keine toten Molerats wieder auferstehen und Guy nicht
    #     doppelt Abschied nimmt.
    : "${MOLERATS_DEAD:=0}"
    case "${MOLERATS_DEAD:-}" in
        ''|*[!0-9]*) MOLERATS_DEAD=0 ;;
    esac
    [ "$MOLERATS_DEAD" -lt 0 ] && MOLERATS_DEAD=0
    [ "$MOLERATS_DEAD" -gt 7 ] && MOLERATS_DEAD=7
    : "${GUY_SUS_MET:=0}"
    : "${GUY_SUS_GONE:=0}"
    : "${GUY_SUS_CAVE_DONE:=0}"
    : "${GUY_SUS_OUTSIDE_DONE:=0}"
    if [ "$GUY_SUS_GONE" = "1" ]; then
        GUY_SUS_MET=1
    fi
    if [ "$GUY_SUS_CAVE_DONE" = "1" ] || [ "$GUY_SUS_OUTSIDE_DONE" = "1" ]; then
        GUY_SUS_MET=1
        GUY_SUS_GONE=1
    fi
    # Wer die Höhlen-Szene abgeschlossen hat, hat alle Molerats besiegt.
    if [ "$GUY_SUS_CAVE_DONE" = "1" ]; then
        MOLERATS_DEAD=7
    fi
    # 4h) Moleratgebiete im Brachland/Steppe: Ältere Stände kennen die
    #     per-Gebiet-Zähler noch nicht. Sie starten leer; ein vorhandener
    #     Zustand wird auf Maximalwert und gültige Spielminuten begrenzt.
    if declare -F molerats_normalize_state >/dev/null 2>&1; then
        molerats_normalize_state
    fi
    # 5) Statistik/Spielzeit: Ältere Stände kennen die Gesamtsumme der
    #    verdienten Bits und die echte Spielzeit noch nicht. Als Startwert
    #    zählt der aktuelle Kontostand; die Spielzeit beginnt bei 0.
    case "${BITS_EARNED:-}" in
        ''|*[!0-9]*) BITS_EARNED="${BITS:-0}" ;;
    esac
    case "${PLAYTIME_BASE:-}" in
        ''|*[!0-9]*) PLAYTIME_BASE=0 ;;
    esac
    : "${MICHAEL_INTRO_DONE:=0}"
    # 5b) Sitzen: Ältere Stände kennen den getrennten Sitz-Tageszähler
    #     noch nicht. Er startet bei 0 für den aktuellen Spieltag; der
    #     Code in kern/sitzen.sh setzt ihn beim ersten Benutzen ohnehin
    #     auf den richtigen Tag.
    : "${SIT_HOURS_TODAY:=0}"
    : "${SIT_DAY:=-1}"
    case "${SIT_HOURS_TODAY:-}" in
        ''|*[!0-9]*) SIT_HOURS_TODAY=0 ;;
    esac
    case "${SIT_DAY:-}" in
        ''|*[!0-9-]*) SIT_DAY=-1 ;;
    esac
    # 5c) Fackel: Ältere Stände kennen die Brenndauer noch nicht.
    case "${TORCH_UNTIL_MIN:-}" in
        ''|*[!0-9]*) TORCH_UNTIL_MIN=0 ;;
    esac
    # 5d) Kalender: Ältere Stände kennen die Anzeigedauer von »cal« noch
    #     nicht. Ohne gültigen Wert ist die Anzeige aus.
    case "${CAL_UNTIL_MIN:-}" in
        ''|*[!0-9]*) CAL_UNTIL_MIN=0 ;;
    esac
    [ "$CAL_UNTIL_MIN" -lt 0 ] && CAL_UNTIL_MIN=0
    # 5e) Archiv: Ältere Stände kennen Kapitel-/Ortsbilder noch nicht.
    : "${ARCHIVE_KAP1:=0}"
    case "${ARCHIVE_KAP1:-}" in 1) ARCHIVE_KAP1=1 ;; *) ARCHIVE_KAP1=0 ;; esac
    : "${ARCHIVE_ORT_DESKTOPCITY:=0}"
    case "${ARCHIVE_ORT_DESKTOPCITY:-}" in 1) ARCHIVE_ORT_DESKTOPCITY=1 ;; *) ARCHIVE_ORT_DESKTOPCITY=0 ;; esac
    # 6) Mitch-Quest: Ältere Stände kennen die neuen Gesprächsstufen noch
    #    nicht. Wer die Quest schon abgeschlossen hat, bekommt die Folge-
    #    Quest; wer Mitch getroffen hat, behält diesen Stand.
    : "${MITCH_GIVEN:=0}"
    : "${MITCH_TALKED:=0}"
    : "${MITCH_DONE:=0}"
    : "${GEHILFE_GIVEN:=0}"
    if [ "${MITCH_DONE:-0}" = "1" ]; then
        MITCH_GIVEN=1
        MITCH_TALKED=1
        GEHILFE_GIVEN=1
    elif [ "${MITCH_TALKED:-0}" = "1" ]; then
        MITCH_GIVEN=1
    fi
    # 7) Neue Lernpfade: Ältere Stände kennen weder »statistics« (Baracken-
    #    Szene) noch »achievements« (erster Downloads-Besuch). Wer die
    #    jeweilige Stelle bereits passiert hat, bekommt die Befehle still.
    if declare -F knows >/dev/null 2>&1; then
        if [ "${BARACKE_SCENE_DONE:-0}" = "1" ] && ! knows statistics; then
            LEARNED+=("statistics")
        fi
        local _agent="/home/$USERNAME_/Downloads/$AGENT_NAME"
        if [ "${README_DONE:-0}" = "1" ]; then
            case "${CWD:-}" in
                "$_agent"|"$_agent"/*) ;;
                *)
                    knows achievements || LEARNED+=("achievements")
                    if declare -p ACH_UNLOCKED >/dev/null 2>&1; then
                        ACH_UNLOCKED["kompass_geeicht"]=1
                    fi
                    ;;
            esac
        fi
    fi
    return 0
}

# --- Laden -----------------------------------------------------------
# Liest den Stand in die globalen Variablen. Der Aufrufer ist dafür
# verantwortlich, abgeleitete Werte (HOME_DIR, AGENT_DIR) neu zu bilden
# und CHILDREN/CONTENT neu aufzubauen.
th_load() {   # $1 = quick|manual ; Rückgabe 0 = ok
    local type f ver
    type="$(th_norm_type "$1")" || return 1
    f="$(th_read_save_file "$type")" || return 1
    [ -s "$f" ] || return 1

    ver="$(sed -n 's/^TH_SAVE_VERSION=//p' "$f" | head -n1 | tr -d "'\"")"
    [ "$ver" = "$TH_SAVE_VERSION" ] || return 1

    # shellcheck disable=SC1090
    . "$f" || return 1
    th_save_migrate
    return 0
}
