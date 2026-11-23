#!/bin/bash

# ============================================================
#  TerminalHero - In-Game-Shell (Skelett)
#
#  Diese Datei ist NUR noch das Gerüst: Projektpfade, das Laden der Module
#  und die Hauptschleife. Alles andere steckt in eigenen .sh-Dateien, die
#  der .sh-Manager (kern/loader.sh) BEDARFSGERECHT nachlädt:
#
#    kern/             Engine (theme, ui, state, fs, render, input, ...)
#    TerminalBefehle/  echte Shell-Befehle (pwd, ls, cd, cat, touch, file, grep, clear,
#                       rm als Kampfbefehl)
#    InGameBefehle/    Spiel-Befehle (use, help, character, questlog, inventar, save,
#                       statistics, achievements, search)
#    Interior/         Einrichtung & benutzbare Objekte (Möbel, Schlafen, Sitzen)
#    NutzbareItems/    tragbare Gegenstände mit Benutzen-Haken (Zeitungen, Schlafsack, Fackel)
#    Gegner/           Gegnerarten & ihre Exemplare (Molerats)
#    GegnerLoot/       Beute aus Kämpfen, z. B. MoleratCode
#    Charakter/        beseelte Dateien (README-General, Kriegsrat, Pixi, Guy Sus, ...)
#    Orte/             Stadtteile und In-Game-Ordner
#    Tutorial/         das zweite Intro
#
#  Start:  bash shDateien/TerminalHero.sh   (Startbildschirm)
#          bash shDateien/TerminalShell.sh  (direkt ins Spiel)
# ============================================================

# ---------- Projektpfade ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# ---------- Konfiguration (von TerminalHero.sh übergeben; sonst Standard) ----------
USERNAME_="${TERMINALHERO_USER:-${TH_USER:-benutzer}}"
HOSTNAME_="${TERMINALHERO_HOST:-${TH_HOST:-pc}}"
AGENT_NAME="${TERMINALHERO_AGENT:-${TH_AGENT:-Agent}}"
START_DIR_NAME="${TERMINALHERO_START:-Downloads}"
HOME_DIR="/home/$USERNAME_"
AGENT_DIR="$HOME_DIR/Downloads/$AGENT_NAME"

# ---------- Engine (immer geladen) ----------
# Hinweis: ab hier über den Manager laden (require_*), damit jede Datei
# GENAU EINMAL geladen wird. Würde z. B. character.sh per "." geladen und
# später noch einmal über th_load_cmd, liefe ihr Kopf erneut – und würde
# LEVEL/EXP zurücksetzen.
. "$SCRIPT_DIR/kern/loader.sh"      # .sh-Dateien-Manager (lädt bei Bedarf)
require_kern theme                  # Farbpalette
require_kern ui                     # TUI-Geometrie & Zeichenprimitive
require_kern state                  # gemeinsamer Spielzustand (Globals)
require_kern equipment              # acht Ausrüstungs-Slots im Charakterbogen
require_kern playtime               # echte Spielzeit (Statistik)
require_kern sound                  # Soundeffekte
require_kern tokens                 # Token-Wirtschaft
require_kern leben                  # Ohnmacht bei 0 Tokens, Tod im Kampf
require_kern fs                     # virtuelles Dateisystem
require_kern district               # Stadtteile (Orte/<Bezirk>.sh bei Bedarf)
require_kern render                 # 4-Fenster-Oberfläche zeichnen
require_kern input                  # Tastatur, Scrollen, Vervollständigung
require_kern path                   # Pfad-Auflösung & Sperrzonen
require_kern dialog                 # say / ask
require_kern learn                  # erlernte Befehle
require_kern util                   # kleine Helfer
require_kern tui                    # TUI an/aus, sauberes Beenden
require_kern save                   # Speichern/Laden (th_save/th_load)
require_kern save_hooks             # Autosave & »save«-Freischaltung
require_kern items                  # Items & Inventar (Katalog + Bestand)
require_kern search                 # durchsuchbare Objekte (search_define)
require_kern interior               # Interior: Einrichtung & benutzbare Objekte
require_kern Uhrzeit                # In-Game-Uhrzeit (läuft ab dem General)
require_kern kalender               # In-Game-Datum & »cal«-Anzeige
require_kern fackel                 # Fackel: Brenndauer & automatische Ordneransicht
require_kern gegner                 # Gegner-Register, Angriffe, Kampf-Loot

# ---------- Items (Katalog aus Items/<Kategorie>/*.sh) ----------
require_items                       # meldet alle Items der Welt an (item_define)

# ---------- Interior (Einrichtung aus Interior/<Kategorie>/*.sh) ----------
require_interior                    # meldet alle benutzbaren Objekte an (interior_define)

# ---------- Zustands-/Hook-Module (eager) ----------
require_gamecmd character   # Level/EXP + Charakter-Fenster
require_gamecmd questlog    # Quest-Register + Fenster
require_gamecmd help        # Hilfe-Register + Fenster
require_gamecmd Inventar    # Inventar-Fenster (Spezial/Quest/Plunder/Schmuck/Waffen/Rüstung)
require_gamecmd Lesen       # Lesefenster für item_readable-Gegenstände
require_gamecmd Statistics  # Statistik-Fenster (Spielzeit, Quests, Bits)
require_gamecmd Achievements # Achievement-Fenster + Register
require_gamecmd Trade       # Handels-Befehl »trade« (Handelsfenster.sh)
require_gamecmd search      # Spiel-Befehl »search« (durchsuchbare Objekte)
require_achievements        # Achievements/<Name>.sh (Titel, Text, ASCII-Bild)
require_char pixi           # Pixi-Quest (Start-Stand ins FS)
require_char verlag         # Story: Zeitungsverlag (Rachel/Jack, Nachtlager-Quest)
require_char TraceyBriggs   # Rachels Zeitungsausträgerin (Stand ins FS)
require_char SherlockHolmes # Tagesablauf: Holmes ist nur nachts im Ostdistrikt
require_char NeksLeiche     # Leiche in der Molerathöhle, ziehbar mit »grep«
require_char NeksBeerdigung # getimte Folgequest, Gemunkel & Friedhofs-Event
require_char GuySus         # Informant im Höhleneingang, lehrt »search«
require_gegner Molerats     # drei Molerats in der Molerathöhle
require_tut tutorial        # zweites Intro

# ============================================================
#  Hauptschleife
# ============================================================
run_shell() {
    local load_type="${TERMINALHERO_LOAD:-}"
    local loaded=0 load_failed=0

    # --- Spielstand laden (vom Startbildschirm angefordert) ------------
    if [ -n "$load_type" ]; then
        if th_load "$load_type"; then
            loaded=1
            # Abgeleitete Pfade aus dem geladenen Stand neu bilden.
            HOME_DIR="/home/$USERNAME_"
            AGENT_DIR="$HOME_DIR/Downloads/$AGENT_NAME"
            START_DIR_NAME="${START_DIR_NAME:-Downloads}"
        else
            load_failed=1
            load_type=""
        fi
    fi

    # Grundgerüst IMMER mit der (ggf. geladenen) Identität neu aufbauen.
    # Danach – nur bei einem Spielstand – die dynamischen FS-Einträge mergen.
    fs_build_tree
    if declare -p TH_DYN_TYPE >/dev/null 2>&1; then
        local _k
        for _k in "${!TH_DYN_TYPE[@]}"; do TYPE["$_k"]="${TH_DYN_TYPE[$_k]}"; done
        unset TH_DYN_TYPE
    fi

    build_children
    load_contents
    # Das Wachhaus im Haupteingang ist kein Distrikt, sondern Teil der
    # Basis. Es setzt nach load_contents seine Inhalte und den Dialog für
    # Simple Jon; die Möbel werden über interior_place angemeldet.
    require_ort Wachhaus
    declare -F wachhaus_build >/dev/null 2>&1 && wachhaus_build
    # Der Brachland-Friedhof ist ebenfalls Teil der Basis. Er setzt die
    # beseelte Datei von Francesco Dellamorte (Orte/Friedhof.sh).
    require_ort Friedhof
    declare -F friedhof_build >/dev/null 2>&1 && friedhof_build
    # Die Farm im Farmland ist Teil der Basis. Das Wohnhaus der Familie
    # Molerat ist das Anwesen; die drei Figuren stehen im Erdgeschoss
    # (Orte/Anwesen.sh, Dialoge in Charakter/MoleratFamilie.sh) und
    # werden am Beerdigungstag ausgeblendet.
    require_ort Farm
    require_ort Anwesen
    require_ort AnwesenHaupteingang
    require_ort AnwesenErdgeschoss
    declare -F anwesen_build >/dev/null 2>&1 && anwesen_build
    interior_place_base_benches
    # Stadtteil laden, in dem der Spieler steht - ohne Betreten-Szene,
    # damit ein geladener Stand nicht bei jedem Start eine Szene zeigt.
    district_prepare
    pixi_apply_state
    tracey_apply_state
    declare -F jack_apply_state >/dev/null 2>&1 && jack_apply_state
    items_world_refresh
    world_drops_refresh
    interior_world_refresh

    if [ "$loaded" = "1" ]; then
        # Geladener Stand kann auf einen Pfad zeigen, den es im (neuen)
        # Grundgerüst nicht mehr gibt – dann auf ~ ausweichen.
        [ "${TYPE[$CWD]:-}" = "d" ] || CWD="$HOME_DIR"
        [ -n "${TYPE[$VIEW_DIR]:-}" ] || VIEW_DIR="$CWD"
        [ -n "${TYPE[$OLDPWD]:-}" ] || OLDPWD="$CWD"
    fi

    if [ "$loaded" = "0" ]; then
        # --- Frischer Start ------------------------------------------
        LS_SHOW_ALL=0
        CWD="$AGENT_DIR"
        [ -z "${TYPE[$CWD]}" ] && CWD="$HOME_DIR/${START_DIR_NAME:-Downloads}"
        [ -z "${TYPE[$CWD]}" ] && CWD="$HOME_DIR"
        OLDPWD="$HOME_DIR"
        VIEW_DIR="$CWD"

        OUT=(); WRAP_KEY=""
        CMD_HIST=()
        README_DONE=0
        # Dev-/Test-Haken: General-Gespräch als erledigt markieren (verkürzt Tests).
        [ -n "${TH_README_DONE:-}" ] && README_DONE=1
        CONAN_DONE=0
        DETEKTIV_DONE=0
        SAVE_LEARNED=0
        TOUCH_CREATE_KNOWN=0
        HOME_FIRST_VISIT=0
        PIXI_DESKTOP_DONE=0
        PIXI_GATE_DONE=0
        PIXI_HALL_DONE=0
        TORWAEHTER_DONE=0
        VERLAG_DONE=0
        PIXI_GUIDE_DONE=0
        BARACKE_SCENE_DONE=0
        PIXI_LETTER_DONE=0
        AMANDA_INTRO_DONE=0
        AMANDA_DONE=0
        AMANDA_HELP_GIVEN=0
        AMANDA_HELP_ASKED=0
        AMANDA_HELP_JACK=0
        AMANDA_HELP_DONE=0
        BOERTY_SH_DONE=0
        BOERTY_INTRO_DONE=0
        SHERLOCK_DONE=0
        SHERLOCK_HUNT=0
        SHERLOCK_NORD=0
        SHERLOCK_BRIEF=0
        ERMITTLER_DONE=0
        RELIGION_GIVEN=0
        BILL_MET=0
        BILL_TOLD=0
        TAGEBUCH_FOUND=0
        TAGEBUCH_READ=0
        RELIGION_BOOK_FIRST=0
        BILL_BOOK_DONE=0
        SHERLOCK_BOOK_DONE=0
        MOLERAT_KOENIGIN_DEAD=0
        BOERTY_INFO=0
        BOERTY_FAVOR_DONE=0
        VERMISSTE_GIVEN=0
        SIMON_NEK_INFO=0
        NEK_GIVEN=0
        JON_NEK_INFO=0
        JON_NEK_FOUND_INFO=0
        BIER_GIVEN=0
        BIER_TAKEN=0
        BIER_DONE=0
        BIER_FAILED=0
        BIER_LOST_AT=-1
        ZEITUNG_EDITION=bezirke
        ZEITUNG_EMPTIED=0
        ZEITUNG_GIVEN=0
        ZEITUNG_DONE=0
        RUNDGANG_GIVEN=0
        RUNDGANG_DONE=0
        AUFLAGE_GIVEN=0
        AUFLAGE_DONE=0
        TRACEY_GIVEN=0
        TRACEY_FOUND=0
        TRACEY_DONE=0
        JIMMY_INTRO_DONE=0
        JIMMY_TRACEY_DONE=0
        JIMMY_GIVEN=0
        JIMMY_LAST_SOLD=""
        JIMMY_FIRST_SALE=0
        TRACEY_RIVAL_SEEN=0
        SAMY_INTRO_DONE=0
        FRANCESCO_MET=0
        MITCH_GIVEN=0
        MICHAEL_INTRO_DONE=0
        NEKS_LEICHE_PATH=""
        NEKS_LEICHE_SEARCHED=0
        DRAGGED_CORPSE=""
        NEK_FOUND=0
        NEK_REPORTED=0
        NEK_MUST_SEARCH=0
        NEK_CORPSE_BROUGHT=0
        NEK_SIMON_SEARCHED=0
        NEK_AMULET_SOLD=0
        NEK_AMULET_KEPT=0
        NEK_DONE=0
        NEK_FUNERAL_GIVEN=0
        NEK_FUNERAL_DISPOSITION=""
        NEK_FUNERAL_DAY=-1
        NEK_FUNERAL_DISCOVERY_DAY=-1
        NEK_FUNERAL_FOUND=0
        NEK_FUNERAL_DONE=0
        NEK_FUNERAL_FAILED=0
        NEK_FAMILY_GIVEN=0
        GREGOR_CODE_GIVEN=0
        GREGOR_CODE_DELIVERED=0
        GREGOR_CODE_DONE=0
        GREGOR_BOOK_DONE=0
        MOLERATS_DEAD=0
        MOLERAT_AREA_DEAD=()
        MOLERAT_AREA_NEXT=()
        MOLERAT_KRIEGER_DEAD=()
        MOLERAT_KRIEGER_NEXT=()
        GUY_SUS_MET=0
        GUY_SUS_GONE=0
        GUY_SUS_CAVE_DONE=0
        GUY_SUS_OUTSIDE_DONE=0
        GEGNER_ACTIVE_CWD=""
        GEGNER_AGGRO_AT=0
        GEGNER_LAST_ATTACK_AT=0
        GEGNER_LAST_CWD=""
        MITCH_TALKED=0
        MITCH_DONE=0
        GEHILFE_GIVEN=0
        SLEEP_HOURS_TODAY=0
        SLEEP_DAY=-1
        SIT_HOURS_TODAY=0
        SIT_DAY=-1
        TORCH_UNTIL_MIN=0
        CAL_UNTIL_MIN=0
        ARCHIVE_KAP1=0
        ARCHIVE_ORT_DESKTOPCITY=0
        SHOW_PATH=0
        SHOW_LS=0
        TUT_STAGE=0
        TUT_HINTED=0
        TUT_DONE=0
        # Ohne Tutorial gilt es als abgeschlossen – sonst bliebe »save«
        # (das ein abgeschlossenes Tutorial voraussetzt) für immer gesperrt.
        [ "${TH_TUTORIAL:-1}" = "0" ] && TUT_DONE=1
        LAST_CAT_PATH=""
        LAST_CAT_OK=0
        LEARNED=(pwd ls cd cat touch)
        # Entwickler-/Test-Haken: Startmenge der erlernten Befehle überschreiben
        # (z. B. TH_LEARNED="pwd ls cd cat touch file"). Im normalen Spiel unberührt.
        [ -n "${TH_LEARNED:-}" ] && read -ra LEARNED <<< "$TH_LEARNED"
        CD_BARE_KNOWN=0
        AGENT_ATTITUDE="unbekannt"
        AGENT_APPROACH="unbekannt"
        tokens_reset
        char_reset
        equip_reset
        inv_reset
        bits_reset
        achievements_reset
        uhrzeit_reset
        PLAYTIME_BASE=0
        # Ohne Tutorial gibt es kein General-Gespräch -> die Uhr läuft ab
        # Spielbeginn. Mit Tutorial startet sie erst, wenn README spricht.
        [ "$TUT_DONE" = "1" ] && uhrzeit_start
        # Kapitel 1 wurde ggf. im Startbildschirm (direkt nach dem Introtext)
        # gezeigt – dann im neuen Spielstand als freigeschaltet markieren.
        [ -n "${TERMINALHERO_CHAPTER1_SEEN:-}" ] && ARCHIVE_KAP1=1
        # Dev-/Test-Haken: zusätzliche Start-Items, z. B. TH_INV="armbanduhr"
        if [ -n "${TH_INV:-}" ]; then
            local _it _n
            for _it in $TH_INV; do
                _n=1; [ "$_it" = "${_it%%:*}" ] || _n="${_it##*:}"
                inv_add "${_it%%:*}" "$_n"
            done
        fi
        # Dev-/Test-Haken: Startguthaben in Bits, z. B. TH_BITS=25
        [ -n "${TH_BITS:-}" ] && bits_add "$TH_BITS"
    fi

    # Ausrüstungs-Sets: Nach dem Laden steht TOKENS_MAX bereits inklusive
    # der gespeicherten Boni im Speicher; EQUIP_SET_APPLIED sagt, welche
    # Set-Boni darin schon enthalten sind. Der Abgleich ist idempotent und
    # ergänzt nur fehlende Boni (z. B. bei einem älteren Stand).
    declare -F equip_set_refresh_all >/dev/null 2>&1 && equip_set_refresh_all

    # Neks Leiche: erst nach dem Frischstart-Reset aufbauen (der Reset leert
    # ihren Pfad), dann Inhalt, Dialog und Such-Haken setzen. Bei einem
    # geladenen Stand steht sie bereits an ihrem gespeicherten Ort.
    declare -F neks_leiche_apply_state >/dev/null 2>&1 && neks_leiche_apply_state

    # Gegner & Guy Sus: tote Molerats nicht wieder aufbauen, Guy nur,
    # solange er noch nicht verschwunden ist. Beides ist idempotent und
    # arbeitet auf dem nach dem Laden neu aufgebauten FS-Baum.
    declare -F molerats_apply_state >/dev/null 2>&1 && molerats_apply_state
    declare -F guy_sus_apply_state >/dev/null 2>&1 && guy_sus_apply_state

    # --- Menü-Befehle nachreichen -------------------------------------
    # »help«, »character«, »questlog« und »inventar« bringt der General im Tutorial bei.
    # Läuft kein Tutorial (TH_TUTORIAL=0) oder kommt der Stand aus einer
    # älteren Version, in der das Gespräch längst vorbei ist, werden sie hier
    # still ergänzt - sonst bliebe der Spieler ohne Anleitung, Bogen und
    # Auftragsbuch. Im frischen Tutorial bleiben sie gesperrt (TUT_DONE=0).
    [ "$TUT_DONE" = "1" ] && meta_learn_silently

    # --- Fundorte außerhalb der Stadtteile -----------------------------
    # Die Stadtteile melden ihre Fundorte selbst an (Orte/<Bezirk>.sh); alles
    # außerhalb – hier der Download-Ordner, in dem auch die Erinnerung an
    # »save« zurückkehrt – wird hier angemeldet. Aufgesammelt wird der
    # Bits-Haufen mit »grep Bits«, sobald der Befehl erlernt ist
    # (Items/Spezial/Bits.sh, Währung in kern/items.sh).
    #
    # Die neuen Bits-Haufen liegen auf dem Weg durch die Basis und die Stadt.
    # Sie werden wie alle Fundorte mit »grep Bits« eingesammelt - dafür muss
    # »grep« erst erlernt sein. Die Menge steht am Fundort, nicht am Item.
    world_item_place bits "$HOME_DIR/Bits" 15
    world_item_place bits "$HOME_DIR/Schreibtisch/Bits" 7
    world_item_place bits "$HOME_DIR/Schreibtisch/DesktopCity/Bits" 11
    world_item_place bits "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Bits" 9
    # In der Molerathöhle liegt neben Neks Leiche ein kleiner Bits-Haufen.
    world_item_place bits "$HOME_DIR/Schreibtisch/Höhleneingang/Molerathöhle/Bits" 11
    # Erst HIER und nicht oben: ein frischer Start räumt mit inv_reset die
    # Weltregister (WORLD_*) wieder leer – der Abgleich muss danach laufen.
    world_item_place bits "$HOME_DIR/Downloads/Bits" 10

    # --- Bits in jedem Ort ---------------------------------------------
    # In der KöniginnenKammer liegt ein größerer Haufen (50 Bits).
    world_item_place bits "$HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Nordtunnel1/Nordtunnel2/Nordtunnel3/GroßerHöhleneingang/BreiterTunnel/KöniginnenKammer/Bits" 50

    # Jeder Ort ohne eigenen Bits-Haufen bekommt einen kleinen Haufen
    # (5–25 Bits). Die Verteilung bleibt günstig: 65 Orte × 7 Bits,
    # davon die ersten fünf mit 6 = 450 Bits. Zusammen mit den 50 Bits
    # der KöniginnenKammer sind das genau 500 Bits neue Fundorte.
    local _bits_path _bits_n _bits_i=0
    for _bits_path in \
        Bilder \
        Dokumente \
        Dokumente/Steuer \
        Downloads/BarbarConan \
        Downloads/DetektivConan \
        Downloads/Neugier \
        Musik \
        Öffentlich \
        Videos \
        Vorlagen \
        Schreibtisch/Höhleneingang \
        Schreibtisch/Brachland \
        Schreibtisch/Brachland/Friedhof \
        Schreibtisch/Brachland/Steppe \
        Schreibtisch/Brachland/Steppe/Canyon \
        Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang \
        Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1 \
        Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2 \
        Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3 \
        Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer \
        Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Nordtunnel1 \
        Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Nordtunnel1/Nordtunnel2 \
        Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Nordtunnel1/Nordtunnel2/NebenkammerNord \
        Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Nordtunnel1/Nordtunnel2/Nordtunnel3 \
        Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Nordtunnel1/Nordtunnel2/Nordtunnel3/GroßerHöhleneingang \
        Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Nordtunnel1/Nordtunnel2/Nordtunnel3/GroßerHöhleneingang/BreiterTunnel \
        Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Osttunnel1 \
        Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Osttunnel1/Osttunnel2 \
        Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Osttunnel1/Osttunnel2/NebenkammerOst \
        Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Osttunnel1/Osttunnel2/Osttunnel3 \
        Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Osttunnel1/Osttunnel2/Osttunnel3/KammerEndeOst \
        Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Westtunnel1 \
        Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Westtunnel1/Westtunnel2 \
        Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Westtunnel1/Westtunnel2/NebenkammerWest \
        Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Westtunnel1/Westtunnel2/Westtunnel3 \
        Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Westtunnel1/Westtunnel2/Westtunnel3/KammerEndeWest \
        Schreibtisch/Brachland/Steppe/Farmland \
        Schreibtisch/Brachland/Steppe/Farmland/Farm \
        Schreibtisch/Brachland/Steppe/Farmland/Farm/Anwesen \
        Schreibtisch/Brachland/Steppe/Farmland/Farm/Anwesen/Haupteingang \
        Schreibtisch/Brachland/Steppe/Farmland/Farm/Anwesen/Haupteingang/Erdgeschoss \
        Schreibtisch/Brachland/Steppe/Moleratgebiet \
        Schreibtisch/Brachland/Steppe/Moleratgebiet/Moleratgebiet1.1 \
        Schreibtisch/Brachland/Steppe/Moleratgebiet/Moleratgebiet1.1/Moleratgebiet1.2 \
        Schreibtisch/Brachland/Steppe/Moleratgebiet/Moleratgebiet2.1 \
        Schreibtisch/Brachland/Steppe/Moleratgebiet/Moleratgebiet2.1/Moleratgebiet2.2 \
        Schreibtisch/Brachland/Steppe/Moleratgebiet/Moleratgebiet3.1 \
        Schreibtisch/Brachland/Steppe/Moleratgebiet/Moleratgebiet3.1/Moleratgebiet3.2 \
        Schreibtisch/DesktopCity/Haupteingang/Norddistrikt \
        Schreibtisch/DesktopCity/Haupteingang/Süddistrikt/Haus1 \
        Schreibtisch/DesktopCity/Haupteingang/Süddistrikt/Haus2 \
        Schreibtisch/DesktopCity/Haupteingang/Süddistrikt/Haus3 \
        Schreibtisch/DesktopCity/Haupteingang/Süddistrikt/Haus4 \
        Schreibtisch/DesktopCity/Haupteingang/Süddistrikt/DailyPulse \
        Schreibtisch/DesktopCity/Haupteingang/Westdistrikt \
        Schreibtisch/DesktopCity/Haupteingang/Westdistrikt/Restaurant \
        Schreibtisch/DesktopCity/Haupteingang/Ostdistrikt/DetekteiHolmes \
        Schreibtisch/DesktopCity/Haupteingang/Ostdistrikt/KneipeZumGoldenenLächeln \
        Schreibtisch/DesktopCity/Haupteingang/Ostdistrikt/JimmysHaus \
        Schreibtisch/DesktopCity/Haupteingang/Zentrum \
        Schreibtisch/DesktopCity/Haupteingang/Zentrum/Marktplatz \
        Schreibtisch/DesktopCity/Haupteingang/Zentrum/Lager \
        Schreibtisch/DesktopCity/Haupteingang/Zentrum/SurvivalShop \
        Schreibtisch/DesktopCity/Haupteingang/Zentrum/Schmiede \
        Schreibtisch/DesktopCity/Haupteingang/Wachhaus
    do
        _bits_n=7
        [ "$_bits_i" -lt 5 ] && _bits_n=6
        world_item_place bits "$HOME_DIR/$_bits_path/Bits" "$_bits_n"
        _bits_i=$(( _bits_i + 1 ))
    done
    unset _bits_path _bits_n _bits_i

    # Versteckte Bits in jedem Ordner (nur mit ls -a sichtbar)
    local _hpath _hval _htotal=0
    local _hlist=(
        "$HOME_DIR"
        "$HOME_DIR/Downloads"
        "$HOME_DIR/Vorlagen"
        "$HOME_DIR/Bilder"
        "$HOME_DIR/Musik"
        "$HOME_DIR/Dokumente"
        "$HOME_DIR/Schreibtisch"
        "$HOME_DIR/Schreibtisch/DesktopCity"
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang"
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Norddistrikt"
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Ostdistrikt"
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Ostdistrikt/DetekteiHolmes"
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Ostdistrikt/KneipeZumGoldenenLächeln"
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Ostdistrikt/JimmysHaus"
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Süddistrikt"
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Süddistrikt/EingestürzteBaracke"
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Süddistrikt/DailyPulse"
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Süddistrikt/Haus1"
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Süddistrikt/Haus2"
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Süddistrikt/Haus3"
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Süddistrikt/Haus4"
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Westdistrikt"
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Westdistrikt/Restaurant"
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Zentrum"
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Zentrum/Marktplatz"
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Zentrum/Lager"
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Zentrum/SurvivalShop"
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Zentrum/Schmiede"
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Wachhaus"
        "$HOME_DIR/Schreibtisch/Höhleneingang"
        "$HOME_DIR/Schreibtisch/Höhleneingang/Molerathöhle"
        "$HOME_DIR/Schreibtisch/Brachland"
        "$HOME_DIR/Schreibtisch/Brachland/Friedhof"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Nordtunnel1"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Nordtunnel1/Nordtunnel2"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Nordtunnel1/Nordtunnel2/NebenkammerNord"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Nordtunnel1/Nordtunnel2/Nordtunnel3"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Nordtunnel1/Nordtunnel2/Nordtunnel3/GroßerHöhleneingang"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Nordtunnel1/Nordtunnel2/Nordtunnel3/GroßerHöhleneingang/BreiterTunnel"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Osttunnel1"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Osttunnel1/Osttunnel2"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Osttunnel1/Osttunnel2/NebenkammerOst"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Osttunnel1/Osttunnel2/Osttunnel3"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Osttunnel1/Osttunnel2/Osttunnel3/KammerEndeOst"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Westtunnel1"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Westtunnel1/Westtunnel2"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Westtunnel1/Westtunnel2/NebenkammerWest"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Westtunnel1/Westtunnel2/Westtunnel3"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Westtunnel1/Westtunnel2/Westtunnel3/KammerEndeWest"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Farmland"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Farmland/Farm"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Farmland/Farm/Anwesen"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Farmland/Farm/Anwesen/Haupteingang"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Farmland/Farm/Anwesen/Haupteingang/Erdgeschoss"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Moleratgebiet"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Moleratgebiet/Moleratgebiet1.1"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Moleratgebiet/Moleratgebiet1.1/Moleratgebiet1.2"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Moleratgebiet/Moleratgebiet2.1"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Moleratgebiet/Moleratgebiet2.1/Moleratgebiet2.2"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Moleratgebiet/Moleratgebiet3.1"
        "$HOME_DIR/Schreibtisch/Brachland/Steppe/Moleratgebiet/Moleratgebiet3.1/Moleratgebiet3.2"
    )
    for _hpath in "${_hlist[@]}"; do
        _hval=$(( 15 + RANDOM % 16 ))
        if [ "$_htotal" -ge 1500 ]; then break; fi
        if [ $(( _htotal + _hval )) -gt 1500 ]; then _hval=$(( 1500 - _htotal )); fi
        [ "$_hval" -lt 1 ] && continue
        world_item_place bits "$_hpath/.Bits" "$_hval"
        _htotal=$(( _htotal + _hval ))
    done
    unset _hpath _hval _htotal _hlist

    # Eine einfache Fackel liegt im Download-Ordner (NutzbareItems/EinfacheFackel.sh).
    # Aufgehoben wird sie wie jeder Fundort mit »grep EinfacheFackel«.
    world_item_place fackel "$HOME_DIR/Downloads/EinfacheFackel"
    items_world_refresh
    world_drops_refresh

    # --- Flüchtiger Zustand (nie aus dem Speicherstand) ----------------
    DIALOG_ACTIVE=0
    DIALOG_HINT=""
    FIRST_RENDER=1
    SCROLL=0
    CMD_BUFFER=""
    # Regeneration startet frisch bei Spielbeginn/Laden (Zeitanker, flüchtig).
    TH_NEXT_REGEN=$(( $(date +%s) + TOKENS_REGEN_SECS ))

    # In-Game-Uhr: der Zeitanker ist flüchtig - beim Laden läuft die
    # Spielzeit dort weiter, wo sie im Spielstand stand (nicht nach Wanduhr).
    WORLD_LAST="$(date +%s)"
    WORLD_SHOWN_MIN=-1
    # Gemunkel wird nur beim BETRETEN eines der sechs Orte ausgegeben. Der
    # zuletzt geprüfte Ordner ist flüchtig (kein Save-Feld); beim Start
    # steht er auf dem aktuellen Ordner, damit ein geladener Stand nicht
    # sofort eine Betreten-Meldung zeigt.
    NEK_RUMOR_LAST_CWD="$CWD"
    # Gegner: Beim Laden darf ein Stand direkt in der Molerathöhle den
    # Angriff neu ankündigen; der flüchtige Betreten-Anker startet leer.
    GEGNER_ACTIVE_CWD=""
    GEGNER_AGGRO_AT=0
    GEGNER_LAST_ATTACK_AT=0
    GEGNER_LAST_CWD=""
    # Echte Spielzeit: Anker der aktuellen Sitzung. Der gespeicherte Stand
    # (PLAYTIME_BASE) kommt aus dem Spielstand bzw. ist beim Frischstart 0.
    PLAYTIME_START="$(date +%s)"
    # Spielstände aus der Zeit VOR der Uhrzeit (ohne WORLD_STARTED), in denen
    # das General-Gespräch längst vorbei ist: Uhr beim Laden starten (06:00).
    [ "$loaded" = "1" ] && [ "${README_DONE:-0}" = "1" ] && uhrzeit_start

    TH_NEXT_AUTOSAVE=$(( $(date +%s) + TH_SAVE_INTERVAL ))

    tui_start
    trap 'shell_cleanup' EXIT
    trap 'on_signal' INT TERM

    if [ "$loaded" = "1" ]; then
        OUT+=("")
        OUT+=("── Spielstand geladen ──")
    elif [ "${TH_TUTORIAL:-1}" = "1" ] && [ "$TUT_DONE" = "0" ]; then
        # Zweites Intro: Der Agent erwacht "blind" in seinem Ordner.
        tutorial_intro
    else
        # Kein Tutorial: Oberfläche verhält sich dennoch "blind" –
        # Pfad und Ordnerinhalt erscheinen erst nach pwd bzw. ls.
        TUT_STAGE=0
        OUT+=("TerminalHero gestartet.")
        OUT+=("KI-Agent ${AGENT_NAME} online – einsatzbereit.")
        OUT+=("Tipp: 'touch README' zum Reden, 'cat README' zum Lesen.")
        if [ "$load_failed" = "1" ]; then
            OUT+=("")
            OUT+=("!! Der angeforderte Spielstand konnte nicht geladen werden.")
        fi
    fi

    # Steht der geladene/frische Start bereits bei Guy, einer Leiche oder
    # Gegnern, werden die Szenen/Angriffe jetzt angekündigt. Das ist
    # dieselbe Reihenfolge wie nach jedem Befehl.
    declare -F guy_sus_maybe_intro >/dev/null 2>&1 && guy_sus_maybe_intro
    declare -F guy_sus_maybe_corpse >/dev/null 2>&1 && guy_sus_maybe_corpse
    declare -F guy_sus_maybe_cave_clear >/dev/null 2>&1 && guy_sus_maybe_cave_clear
    declare -F gegner_maybe_enter >/dev/null 2>&1 && gegner_maybe_enter

    # Ein geladener Stand kann bereits mit 0 Tokens ankommen (z. B. aus
    # einer älteren Version). Dann sofort dieselbe Weiche nehmen.
    if [ "${TOKENS_CUR:-1}" -le 0 ]; then
        leben_token_zero
    fi

    local line cmd rest st_before
    while true; do
        SCROLL=0
        CMD_BUFFER=""
        tokens_tick      # ggf. fällige Regeneration anwenden
        uhrzeit_tick     # In-Game-Zeit fortschreiben
        molerats_respawn_tick # fällige Molerat-Nachspawns in den Gebieten
        nek_funeral_tick # fällige Beerdigung abschließen oder scheitern lassen
        fackel_tick      # abgelaufene Fackel ausblenden/melden
        sherlock_schedule_apply   # Tagesablauf: Holmes ist nur nachts draußen
        tracey_schedule_apply     # Tracey zieht alle 4 Spielstunden weiter (nach ihrer Quest)
        gegner_tick      # fälligen Gegnerschaden anwenden
        render
        if ! read_command; then
            break
        fi
        line="$CMD_BUFFER"

        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [ -z "$line" ] && continue

        CMD_HIST+=("$line")
        [ "${#CMD_HIST[@]}" -gt 3 ] && CMD_HIST=("${CMD_HIST[@]:1}")

        cmd="${line%% *}"
        rest="${line#* }"
        [ "$rest" = "$line" ] && rest=""

        # Anführungszeichen um das Argument entfernen: »cd "Ostdistrikt"« soll
        # genauso funktionieren wie ohne. Nur ein passendes Paar ganz außen
        # wird entfernt.
        case "$rest" in
            \"*\"|\'*\')
                [ "${#rest}" -ge 2 ] && rest="${rest:1:${#rest}-2}" ;;
        esac

        # --- Tutorial: nur der gerade benötigte Befehl ist erlaubt ---
        # (Das Spiel verlassen bleibt jederzeit möglich; »save« wird erst
        #  nach dem Tutorial im Downloads-Bereich wiedererlangt.)
        if [ "$TUT_STAGE" -ge 1 ] && [ "$TUT_STAGE" -le 4 ]; then
            case "$cmd" in
                exit|quit|logout|beenden) : ;;
                *)
                    if [ "$cmd" != "$(tut_expected)" ]; then
                        tutorial_block
                        continue
                    fi ;;
            esac
        fi

        # --- Tokens: jeder eingegebene Grundbefehl kostet ---
        # Gilt für genau die Eingabe (auch wenn sie danach scheitert - z. B.
        # gesperrte Zone); reicht das Guthaben nicht, wird nichts ausgeführt.
        # Kosten und EXP hängen vom Befehl ab (»grep«: 10 Tokens, 2 EXP;
        # auf einer Leiche 20 Tokens, 4 EXP; »cal«: 50 Tokens, 10 EXP -
        # erst nach dem Erlernen; »rm«: 1 EXP je 5 Tokens inkl.
        # Gegnerkosten). Nicht erlernte Befehle kosten 0; ihre
        # Virus-Absage wird ohne Tokenabzug und ohne EXP ausgegeben.
        local cmd_cost
        cmd_cost="$(token_cost_of "$cmd" "$rest")"
        if [ "$cmd_cost" -gt 0 ]; then
            if ! tokens_spend "$cmd_cost"; then
                play_sound error
                OUT+=("[ TOKENS ] Zu wenig Energie für »${cmd}« – ${cmd_cost} nötig, nur ${TOKENS_CUR} übrig.")
                OUT+=("           Regeneration läuft: +$(tokens_step) alle ${TOKENS_REGEN_SECS}s.")
                continue
            fi
            # Der letzte Token ist weg: außerhalb eines Kampfs ohnmächtig,
            # im Kampf tot. Der Befehl selbst wird dann nicht mehr ausgeführt.
            if [ "${TOKENS_CUR:-0}" -le 0 ]; then
                leben_token_zero
                continue
            fi
            char_gain_exp "$(token_exp_of "$cmd" "$rest")"   # bezahlter Befehl = EXP (siehe character.sh)
        fi

        # --- Menü-Befehle: help / character / questlog / inventar / statistics / achievements
        # Erst das passende Befehlsmodul bei Bedarf laden (Lazy Loading):
        # z. B. TerminalBefehle/cd.sh oder InGameBefehle/save.sh erst, wenn
        # der Befehl wirklich benutzt wird.
        th_load_cmd "$cmd"

        # Die Menü-Befehle sind zu Spielbeginn gesperrt – der General
        # (README) bringt sie im Tutorial bei (general_teach_meta); im
        # Tutorial sagt weiterhin der Tutorial-Wächter, was zu tun ist.
        # (Erkennung, Sperre und Fenster stecken in den jeweiligen Modulen.)
        case "$(th_canon_cmd "$cmd")" in
            help)       help_handles "$cmd"      && continue ;;
            character)  character_handles "$cmd" && continue ;;
            questlog)   questlog_handles "$cmd"  && continue ;;
            inventar)   inventar_handles "$cmd"  && continue ;;
            statistics) statistics_handles "$cmd" && continue ;;
            achievements) achievements_handles "$cmd" && continue ;;
            trade)      trade_handles "$cmd" "$rest" && continue ;;
        esac

        st_before="$TUT_STAGE"
        case "$cmd" in
            cd)    builtin_cd "$rest" ;;
            cd..)  builtin_cd ".." ;;
            cd.)   builtin_cd "." ;;
            ls)    builtin_ls $rest
                   if [ "$TUT_STAGE" = "2" ] && [ "$SHOW_LS" = "1" ]; then
                       TUT_STAGE=3; TUT_HINTED=0; tutorial_after_ls
                   fi ;;
            pwd)   builtin_pwd
                   if [ "$TUT_STAGE" = "1" ]; then
                       TUT_STAGE=2; TUT_HINTED=0; tutorial_after_pwd
                   fi ;;
            cat)   builtin_cat "$rest"
                   if [ "$TUT_STAGE" = "3" ] && [ "$LAST_CAT_OK" = "1" ] \
                      && [ "$LAST_CAT_PATH" = "$AGENT_DIR/README" ]; then
                       TUT_STAGE=4; TUT_HINTED=0; tutorial_after_cat
                   fi ;;
            touch) builtin_touch "$rest"
                   if [ "$TUT_STAGE" = "4" ] && [ "$README_DONE" = "1" ]; then
                       TUT_STAGE=0; TUT_HINTED=0; tutorial_after_touch
                   fi ;;
            clear) builtin_clear ;;
            cal)   builtin_cal ;;
            save|speichern) builtin_save ;;
            archive) builtin_archive ;;
            file) builtin_file "$rest" ;;
            grep) builtin_grep "$rest" ;;
            use)  builtin_use "$rest" ;;
            search) builtin_search "$rest" ;;
            rm)   builtin_rm "$rest" ;;
            exit|quit|logout|beenden)
                break ;;
            "")
                : ;;
            *)
                play_sound error
                OUT+=("$cmd …? Diesen Befehl kenne ich nicht mehr. Der Virus hat ihn mir genommen.")
                ;;
        esac

        # Erster Besuch im Downloads-Bereich (nach dem Tutorial): »save« freischalten.
        maybe_unlock_save

        # Erster Besuch von ~ (nach dem Tutorial): Pixi begegnet dem Agenten.
        pixi_maybe_intro

        # Schreibtisch betreten: Pixi flieht in die Stadt (einmalige Szene).
        pixi_maybe_desktop

        # Haupttor betreten: Wortgefecht mit dem Torwächter (einmalig).
        pixi_maybe_gate

        # Haupteingang betreten: Pixi stellt sich vor und geht zum Verlag (einmalig).
        pixi_maybe_hall

        # Story: Verlag betreten (Familiengespräch) -> Süddistrikt -> Baracke
        # (Pixi bringt dem Agenten dort »grep« bei). Siehe Charakter/verlag.sh
        verlag_maybe

        # Detektei Holmes betreten: Holmes erzählt Amanda von der Verfolgung,
        # danach übergibt der Agent den Brief (einmalig). Siehe Charakter/SherlockHolmes.sh
        sherlock_maybe_office

        # Stadtteil betreten/verlassen: jeweilige Welt laden bzw. beim
        # Verlassen Richtung Haupttor wieder die Basis übernehmen.
        district_sync

        # Guy Sus: erstes Betreten des Höhleneingangs, Leiche draußen,
        # oder alle Molerats in der Höhle besiegt.
        guy_sus_maybe_intro
        guy_sus_maybe_corpse
        guy_sus_maybe_cave_clear

        # Gegner im neuen Ordner bemerken (»Oink, Oink«) und Angriff stellen.
        gegner_maybe_enter

        # Bis zur Beerdigung: Gemunkel beim Betreten der fünf Stadtteile
        # oder des Haupteingangs (nur einmal pro Betreten, siehe Modul).
        nek_funeral_rumor_maybe

        # Sanfter Tutorial-Hinweis, wenn gerade nicht der erwartete Befehl kam.
        if [ "$TUT_STAGE" = "$st_before" ] && [ "$TUT_STAGE" -ge 1 ]; then
            tutorial_hint "$cmd"
        fi

        # --- Automatischer Quicksave (alle TH_SAVE_INTERVAL Sekunden) ---
        autosave_tick
    done

    tui_end
    trap - EXIT INT TERM
}

run_shell
