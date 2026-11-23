# TerminalHero (Demo)

Ein dystopisches Terminal-Abenteuer – komplett in Bash.

Du bist ein KI-Agent, der in einer Stadt aus Ordnern und Dateien erwacht.
Ordner sind Orte, Dateien sind Menschen, und das Terminal ist deine einzige
Verbindung zur Welt. Erkunde die Stadt, sprich mit beseelten Dateien, löse
Quests, handle mit Bits – und halte die Viren (Molerats) in Schach.
Deine Energie sind **Tokens**: Jeder Befehl kostet welche.

## Voraussetzungen

- **Linux** mit **Bash 4+** (associative Arrays)
- Ein Terminal mit mindestens **60 × 16** Zeichen (empfohlen: 80 × 24)
- Optional: **`aplay`** (alsa-utils) für Sound – fehlt es, läuft das Spiel stumm
- **Python 3** nur für die Testsuite

Es gibt keine Installation und keine weiteren Abhängigkeiten.

## Starten

```bash
git clone https://github.com/cavemanwithaterminal/TerminalHero.git
cd TerminalHero
bash shDateien/TerminalHero.sh
```

Alternativ direkt über das Quicklaunch-Skript:

```bash
./TerminalHero
```

Wer den Startbildschirm überspringen und sofort ins Spiel will:

```bash
bash shDateien/TerminalShell.sh
```

Sound abschalten:

```bash
TERMINALHERO_SOUND=0 bash shDateien/TerminalHero.sh
```

Beim ersten Start führt der Startbildschirm durch die Einrichtung
(Benutzername, Hostname, Agentenname) und den Prolog. Spielstände landen in
`saves/` und werden nicht ins Repository hochgeladen.

## Steuerung

Gespielt wird mit normalen Terminal-Befehlen:

| Befehl | Wirkung |
|--------|---------|
| `pwd`, `ls`, `cd` | Pfad anzeigen, Ordnerinhalt sehen, Ortswechsel |
| `cat`, `touch` | Datei lesen, mit einer Datei sprechen |
| `grep`, `file` | Suchen und Dinge herausziehen, Metadaten ansehen |
| `rm` | Gegner löschen (Kampfbefehl – Waffe nötig) |

Dazu kommen Spiel-Befehle wie `help`, `character`, `questlog`, `inventar`,
`use`, `save`, `search`, `statistics`, `achievements`, `cal`, `archive`
und `trade`.

In Fenstern und Dialogen: **Pfeiltasten** zum Navigieren, **Enter** zum
Bestätigen, **Tab** für Vervollständigung, **Esc/Q** zum Schließen.

## Projektaufbau

```
TerminalHero/
├── shDateien/          Spielcode (Engine, Befehle, Orte, Charaktere, Items)
├── assets/sounds/      Soundeffekte
├── Kern/tests/         Testsuite (Unit- und PTY-Tests)
├── saves/              Spielstände (wird zur Laufzeit erzeugt)
├── Story&Quests/       Quest- und Story-Notizen
├── Lore.txt            Hintergrund
└── TerminalHero        Quicklaunch-Skript
```

## Tests

```bash
# komplette Suite
bash Kern/tests/run_tests.sh

# nur ausgewählte Tests
bash Kern/tests/run_tests.sh unit archive

# nur die Unit-Tests
bash Kern/tests/unit.sh
```

Die PTY-Tests starten echte Spielsitzungen und brauchen ein Terminal.
Ein vollständiger Lauf dauert einige Minuten.

> **Spoiler-Warnung:** Die Tests und die Story-Dokumente enthalten
> Questlösungen und Handlungsdetails. Wer das Spiel unvoreingenommen
> erleben will, sollte sie erst nach dem Durchspielen lesen.

## Status

Das Spiel befindet sich in aktiver Entwicklung. Beiträge, Bugmeldungen und
Ideen sind willkommen.
