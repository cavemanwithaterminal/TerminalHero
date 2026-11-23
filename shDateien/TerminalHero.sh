#!/bin/bash

# ============================================================
#  TerminalHero - Startbildschirm (Skelett)
#
#  Diese Datei ist NUR noch das Gerüst: Projektpfade, Modul-Laden und der
#  Einstieg ins Menü. Darstellung, Prolog, Setup, Lademenü und Ablauf
#  stecken in eigenen Dateien unter Startbildschirm/:
#
#    Startbildschirm/base.sh      Block-Schrift, Größe, Tasten, Helfer
#    Startbildschirm/sound.sh     Soundeffekte (erzeugen + abspielen)
#    Startbildschirm/screen.sh    Hauptmenü zeichnen
#    Startbildschirm/intro.sh     Prolog
#    Startbildschirm/setup.sh     Benutzer/Host/Agent abfragen
#    Startbildschirm/loadmenu.sh  »Spiel laden« (Quicksave / manuell)
#    Startbildschirm/menu.sh      init_screen, launch_shell, main
#
#  Das eigentliche Spiel startet dieses Skript über launch_shell als
#  eigenen Prozess:  bash shDateien/TerminalShell.sh
# ============================================================

# shDateien/ = Ordner dieses Skripts; die Projektwurzel (assets/, saves/)
# liegt eine Ebene darüber.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# ---------- Engine (geteilt mit dem Spiel) ----------
. "$SCRIPT_DIR/kern/loader.sh"   # .sh-Dateien-Manager (lädt bei Bedarf)
. "$SCRIPT_DIR/kern/theme.sh"    # Farbpalette
. "$SCRIPT_DIR/kern/save.sh"     # Speichersystem (th_have_save/th_save_info fürs Lademenü)

# ---------- Startbildschirm-Module ----------
require_start base
require_start sound
require_start screen
require_start intro
require_start setup
require_start loadmenu
require_start menu

main
