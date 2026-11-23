#!/usr/bin/env bash
# ============================================================
#  TerminalHero - Test-Suite (Sammellauf)
# ------------------------------------------------------------
#  Läuft alle Tests der Reihe nach und fasst zusammen. Jeder
#  Test ist eigenständig; ein Fehlschlag bricht den Lauf NICHT
#  ab - am Ende steht ein Kurzbericht.
#
#  Aufruf:
#     bash Kern/tests/run_tests.sh              # alle Tests
#     bash Kern/tests/run_tests.sh unit smoke   # nur diese
# ============================================================

HERE="$(cd "$(dirname "$0")" && pwd)"

declare -A NAME=(
    [unit]="Unit-Tests der Spiel-Logik (ohne TUI)"
    [cal]="Kalender: cal, Datumsanzeige, 50 Tokens / 10 EXP, Ablauf"
    [smoke]="Rauchtest: Start, Grundbefehle, Sperren, Menü-Fenster"
    [tutorial]="Tutorial: pwd -> ls -> cat -> touch, General, Belohnung"
    [ermittler]="Kettentest: Sherlock-Tagesablauf, Baracke, Börty, Ermittler"
    [rundgang]="Pixis Stadtrundgang: Papier, Zeitfenster, fünf Distrikte, 1000 EXP"
    [auflage]="Die neueste Auflage: Sperrzone, fünf Kästen, Rachels Bericht, Jimmys Preis"
    [markt]="Zentrum: Marktplatz, Samy Cage, Börtys Bitte, Suche nach Mitch"
    [bier]="Bierlieferung: Ersatzkiste, 24-Stunden-Frist, Scheitern"
    [zeitung]="DailyPulse: Zeitungskästen, Jacks Rückholquest, clear"
    [extra]="Extra-Ausgabe nach Neks Beerdigung, Verkauf & cal-Kosten"
    [statistics]="Michael Mitch im Restaurant & Statistik-Fenster"
    [achievements]="Achievements: Kompass Geeicht & GUI-Fenster"
    [handel]="Handelsfenster: Aufbau, Tasten, Halten, Dialog-Weg zu Börty"
    [handel_info]="Handelsfenster: Beschreibungsfenster im unteren Drittel"
    [aufgaben]="Bits mit grep & direkte Stadtteilwechsel (cd)"
    [tracey]="Tracey Briggs, Jimmys Zeitungsbote & Vermisste-Bewohner-Update"
    [amanda]="Unterstützung für Amanda: Amanda Nox, Jacks Umzug in die Detektei"
    [nutzitems]="Nutzbare Items: Schlafsack ablegen/greppen, Fackel-Auto-ls"
    [lesen]="Lesbare Zeitungen: Inventar, Lesefenster, Scrollen, Esc/Q"
    [archive]="Archiv: Kapitel/Orte, Save-Slots 1-3 & Laden (manual/legacy)"
    [survivalshop]="SurvivalShop: Jack Bones, Sortiment, Fackel-Fundorte"
    [schmied]="Schmiede: Bruno Amboss, Einfaches Set, Kampfset & Preise"
    [symbole]="Ordnerfenster: Symbole/Farben + Sitzbänke Basis"
    [ordner]="Ordnerfenster: Sortierung, Bild↑/↓-Scrollen & Dialog-Tasten"
    [torwaechter]="Torwächter: Erstkontakt, Standard-Dialog nach dem Tor"
    [wachhaus]="Wachhaus: Simon Guard, Simple Jon & Nek Molerat"
    [hoehle]="Höhleneingang, Molerathöhle & acht Ausrüstungs-Slots"
    [moleratgebiet]="Brachland/Steppe: Moleratgebiete, Kill & 24h-Respawn"
    [farm]="Farmland/Farm: Familie Molerat vor & nach Neks Beerdigung"
    [neksleiche]="Neks Leiche: search, Amulett, grep-Ziehen & Speichern"
    [nekschmuck]="Neks Amulett: Schmuck, Ausrüsten & Simons Abschlusswege"
    [nekbeerdigung]="Neks Beerdigung: Termin, Gemunkel, Friedhof & Familie"
    [francesco]="Francesco Dellamorte: Totengräber, erstes Treffen & Standard-Dialog"
    [guy]="Guy Sus: Molerats, Oink-Schaden, rm, Loot, Tod & zwei Abschiede"
)

# Reihenfolge: schnell/breit zuerst, langsame Story danach.
ORDER=(unit cal smoke tutorial ermittler rundgang auflage markt bier zeitung extra statistics achievements handel handel_info aufgaben tracey amanda nutzitems lesen archive survivalshop schmied symbole ordner torwaechter wachhaus hoehle moleratgebiet farm neksleiche nekschmuck nekbeerdigung francesco guy)

if [ "$#" -gt 0 ]; then
    WANT=("$@")
else
    WANT=("${ORDER[@]}")
fi

run() {   # run <name>
    local name="$1" desc="${NAME[$1]:-}"
    printf '\n╔════════════════════════════════════════════════════════════════╗\n'
    printf   '║  %-62s║\n' "$desc"
    printf   '╚════════════════════════════════════════════════════════════════╝\n'
    case "$name" in
        unit)          bash "$HERE/unit.sh" ;;
        cal|smoke|tutorial|ermittler|rundgang|auflage|handel|handel_info|markt|bier|zeitung|extra|statistics|achievements|aufgaben|tracey|amanda|nutzitems|lesen|archive|survivalshop|schmied|symbole|ordner|torwaechter|wachhaus|hoehle|moleratgebiet|farm|neksleiche|nekschmuck|nekbeerdigung|francesco|guy)
                       python3 "$HERE/t_$name.py" ;;
        *)             printf 'Unbekannter Test: %s\n' "$name"; return 2 ;;
    esac
}

passed=0; failed=0; broken=""
for name in "${WANT[@]}"; do
    start="$(date +%s)"
    run "$name"
    rc=$?
    dauer=$(( $(date +%s) - start ))
    if [ "$rc" = 0 ]; then
        passed=$((passed + 1))
        printf '>>> %-10s OK   (%ss)\n' "$name" "$dauer"
    else
        failed=$((failed + 1)); broken+=" $name"
        printf '>>> %-10s FEHLER (rc=%s, %ss)\n' "$name" "$rc" "$dauer"
    fi
done

printf '\n════════════════════════════════════════════════════════════════\n'
printf ' ZUSAMMENFASSUNG: %d bestanden, %d fehlgeschlagen\n' "$passed" "$failed"
[ -n "$broken" ] && printf ' fehlgeschlagen:%s\n' "$broken"
printf '════════════════════════════════════════════════════════════════\n'

[ "$failed" = 0 ]
