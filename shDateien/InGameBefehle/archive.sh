# ============================================================
#  TerminalHero - Spiel-Befehl: archive
#
#  Archiv für freigeschaltete Kapitelbilder (ASCII/ANSI). Wird
#  am Ende des Gesprächs mit dem Torwächter und Pixi am Stadttor
#  erlernt (siehe Charakter/pixi.sh). Kapitelbilder werden beim
#  ersten Erreichen freigeschaltet und können hier erneut
#  angesehen werden.
#
#  Öffnet ein eigenes TUI-Fenster (wie help/character):
#     Hauptmenü:  Kapitel  |  Zurück
#     Kapitel:    Liste freigeschalteter Bilder, durchblättern
#
#  Eingang für den Dispatch in TerminalShell.sh:
#     builtin_archive
# ============================================================

# --- Freischaltungen -------------------------------------------------
archive_is_unlocked() {   # $1 = Kapitelnummer
    case "$1" in
        1) [ "${ARCHIVE_KAP1:-0}" = "1" ] ;;
        *) return 1 ;;
    esac
}

archive_unlock() {        # $1 = Kapitelnummer
    case "$1" in
        1) ARCHIVE_KAP1=1 ;;
    esac
}

archive_chapter_title() { # $1 = Kapitelnummer
    case "$1" in
        1) printf 'Kapitel 1 — Ein neuer Agent' ;;
        *) printf 'Kapitel %s' "$1" ;;
    esac
}

# --- Kapitel 1: Innenleben eines modernen Gaming-PCs ------------------
# Sehr aufwendig gestaltete Seitenansicht (Gehäuse geöffnet) mit
# großem ASCII-Schriftzug "KAPITEL 1 / EIN NEUER AGENT" mitten im Bild.
archive_draw_kapitel1() {
    local w=146
    local cols="${COLS:-80}" rows="${ROWS:-24}"
    local pad=$(( (cols - w) / 2 ))
    [ "$pad" -lt 0 ] && pad=0
    local sp; printf -v sp '%*s' "$pad" ''

    # Farbpalette (256-Farben)
    local R=$'\033[0m'
    local B=$'\033[48;5;232m'
    local FR=$'\033[38;5;240m'
    local FR2=$'\033[38;5;248m'
    local GL=$'\033[38;5;51m'
    local PCB=$'\033[38;5;22m'
    local PCB2=$'\033[38;5;28m'
    local TRC=$'\033[38;5;178m'
    local TRC2=$'\033[38;5;136m'
    local SIL=$'\033[38;5;252m'
    local SIL2=$'\033[38;5;245m'
    local SIL3=$'\033[38;5;238m'
    local FAN=$'\033[38;5;159m'
    local FAN2=$'\033[38;5;39m'
    local FAN3=$'\033[38;5;33m'
    local RAM=$'\033[38;5;27m'
    local RAMR=$'\033[38;5;201m'
    local RAMG=$'\033[38;5;51m'
    local GPU=$'\033[38;5;250m'
    local GPU2=$'\033[38;5;242m'
    local GPU3=$'\033[38;5;236m'
    local GPUG=$'\033[38;5;46m'
    local GPUC=$'\033[38;5;51m'
    local PSU=$'\033[38;5;237m'
    local PSU2=$'\033[38;5;245m'
    local CBL=$'\033[38;5;208m'
    local CBL2=$'\033[38;5;196m'
    local CBL3=$'\033[38;5;226m'
    local CBL4=$'\033[38;5;118m'
    local CBL5=$'\033[38;5;141m'
    local SSD=$'\033[38;5;81m'
    local SSD2=$'\033[38;5;75m'
    local DRV=$'\033[38;5;252m'
    local VRM=$'\033[38;5;102m'
    local CHIP=$'\033[38;5;59m'
    local TUBE=$'\033[38;5;45m'
    local LIQ=$'\033[38;5;123m'
    local RES=$'\033[38;5;81m'
    local LED=$'\033[38;5;82m'
    local LED2=$'\033[38;5;196m'
    local LED3=$'\033[38;5;220m'
    local DIM=$'\033[38;5;60m'
    local DIM2=$'\033[38;5;244m'
    # Großer Titelschriftzug (mitten im Bild, holografisch leuchtend)
    local T1=$'\033[1;38;5;51m'
    local T1G=$'\033[1;38;5;87m'
    local T2=$'\033[1;38;5;220m'
    local T2G=$'\033[1;38;5;229m'
    local TG=$'\033[38;5;45m'

    printf '%s' "$B"
    clear

    local y=1
    local -a L=()
    # Gehäuse & obere Sektion (Radiator, Lüfter, IO, RGB, Mesh)
    L+=("${FR}┌${FR2}══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════${FR}┐${R}${B}")
    L+=("${FR}│${GL}░▒▓${FR2}  HIGH-END GAMING RIG  ·  SEITENGLAS ABGENOMMEN  ·  SYSTEM AKTIV  ${DIM2}│${FR}  ${RAMR}▰▰${RAMG}▰▰${GPUG}▰▰${GL}▰▰${RAMR}▰▰${RAMG}▰▰${GPUG}▰▰${GL}▰▰${RAMR}▰▰${FR}  ARGB SYNC  ${GL}▓▒░${FR}│${R}${B}")
    L+=("${FR}├${FR2}──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────${FR}┤${R}${B}")
    L+=("${FR}│${B} ${DIM}┌─ OBERES GEHÄUSE / FRONT ───────────────────────────────────────────────────────────────────────────────────────────────────────────────┐${B} ${DIM}┌────────┐${FR} │${R}${B}")
    L+=("${FR}│${B} ${DIM}│${FAN3} ╭─────────╮${FAN2} ╭─────────╮${FAN2} ╭─────────╮${SIL2}  360mm RADIATOR · KÜHLRIPPENSTACK  ${SIL3}▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓${B}  ${TUBE}╭──TUBE──╮${B} ${TUBE}╭──TUBE──╮${B} ${DIM}│${B} ${DIM}│ I/O    │${FR} │${R}${B}")
    L+=("${FR}│${B} ${DIM}│${FAN3}╭╯${FAN} ◉ ◔ ◕ ◑ ${FAN3}╰╮${FAN2}╭╯${FAN} ◉ ◔ ◕ ◑ ${FAN2}╰╮${FAN2}╭╯${FAN} ◉ ◔ ◕ ◑ ${FAN2}╰╮${SIL3} ▓▓${DIM2}LAMELLEN/ALU FIN ARRAY${SIL3}▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓${B} ${TUBE}│${LIQ}≈≈≈≈≈≈≈${TUBE}│${B} ${TUBE}│${LIQ}≈≈≈≈≈≈≈${TUBE}│${B} ${DIM}│${B} ${DIM}│USB-C 2 │${FR} │${R}${B}")
    L+=("${FR}│${B} ${DIM}│${FAN3} ╰─────────╯${FAN2} ╰─────────╯${FAN2} ╰─────────╯${SIL2}  PWM 120mm ARGB · PUSH/PULL · 2000rpm ${DIM2}AIRFLOW →${B}             ${TUBE}╰───┬────╯${B} ${TUBE}╰───┬────╯${B} ${DIM}│${B} ${DIM}│USB3 x4 │${FR} │${R}${B}")
    L+=("${FR}│${B} ${DIM}│${DIM2}  FRONT-MESH · STAUBFILTER · RGB-RAHMEN ${RAMR}▚${GL}▚${GPUG}▚${RAMR}▚${GL}▚${GPUG}▚${B}      ${RES}┌─ RESERVOIR/PUMP ─┐${B}                 ${TUBE}│${B}          ${TUBE}│${B}      ${DIM}│${B} ${DIM}│AUDIO HD│${FR} │${R}${B}")
    L+=("${FR}│${B} ${DIM}└──────────────────────────────────────────────────────────────${RES}│${LIQ} ≋≋≋  ${DIM2}D5 PUMP ${LED}●${LIQ} ≋≋≋ ${RES}│${B}─────────────────${TUBE}│${DIM}──────────${TUBE}│${DIM}──────┘${B} ${DIM}│PWR ${LED}●${DIM} RST${LED2}●${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}┌─ ATX MAINBOARD · Z790 / X670E ─────────────────────────────${RES}└───────${TUBE}┬${RES}───${TUBE}┬${RES}───────┘${B}───────────────────────────────────────────┐${B} ${DIM}│HDD ${LED}◉${DIM} LED${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${TRC2} ═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═${TUBE}│${TRC2}═══${TUBE}│${TRC2}═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═ ${PCB}│${B} ${DIM}└────────┘${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${VRM}┌VRM HEATSINK┐${TRC} │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │${SIL2}┌──────── CPU-WASSERBLOCK ────────┐${TRC}│ │ │ │ │${SSD}┌─ NVMe 1 ─────┐${TRC}│ │ │${VRM}┌VRM┐${TRC}│ ${PCB}│${B} ${DIM}┌REAR 120┐${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${VRM}│▓▓▓▓▓▓▓▓▓▓▓▓│${TRC} │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │${SIL2}│${SIL} ┌───────────────────────────────┐ ${SIL2}│${TRC}│ │ │ │ │${SSD}│${SSD2}▓▓▓▓▓▓▓▓▓▓▓▓${SSD}│${TRC}│ │ │${VRM}│▓▓▓▓│${TRC}│ ${PCB}│${B} ${FAN2}╭╯${FAN}◉◔◕◑${FAN2}╰╮${FR}│${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${VRM}│MOSFET COILS│${TRC} │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │${SIL2}│${SIL} │${GL}  CPU · 24C/32T · 5.8GHz  ${DIM}OC${SIL}   │ ${SIL2}│${TRC}│ │ │ │ │${SSD}│${DIM2}2TB PCIe5.0${SSD}│${TRC}│ │ │${VRM}│COIL│${TRC}│ ${PCB}│${B} ${FAN2}╰──────╯${FR}│${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${VRM}└────────────┘${TRC} │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │${SIL2}│${SIL} │${GL}  KUPFER-COLDPLATE · MIKROFIN  ${SIL} │ ${SIL2}│${TRC}│ │ │ │ │${SSD}└─────────────┘${TRC}│ │ │${VRM}└────┘${TRC}│ ${PCB}│${B} ${DIM}EXHAUST${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${TRC} ═╧═╧═╧═╧═╧═╧═══ ${SIL2}└────${SIL3}▒▒▒▒▒▒▒  LGA / AM5 SOCKET  ▒▒▒▒▒▒▒${SIL2}────┘${TRC} ═╧═╧═╧═╧═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═ ${PCB}│${B}         ${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${TRC}  │ │ │ │ │ │   ═╤═══╤═══╤═══╤═══╤═══╤═══╤═══╤═══╤═══╤═══╤═══╤═   │ │ │ │${SSD}┌─ NVMe 2 ─────┐${TRC}│ │ │ │ │ │ │ │ │ ${PCB}│${B}         ${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${TRC}  │ │ │ │ │ │    │${RAM}┏━━━━━━━━━┓${TRC}│${RAM}┏━━━━━━━━━┓${TRC}│${RAM}┏━━━━━━━━━┓${TRC}│${RAM}┏━━━━━━━━━┓${TRC}│   │ │ │ │${SSD}│${SSD2}▓▓▓▓▓▓▓▓▓▓▓▓${SSD}│${TRC}│ │ │ │ │ │ │ │ │ ${PCB}│${B} ${DIM}┌SIDE FAN┐${FR}│${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${TRC}  │ │ │ │ │ │    │${RAM}┃${RAMR}███${RAMG}███${RAMR}███${RAM}┃${TRC}│${RAM}┃${RAMR}███${RAMG}███${RAMR}███${RAM}┃${TRC}│${RAM}┃${RAMR}███${RAMG}███${RAMR}███${RAM}┃${TRC}│${RAM}┃${RAMR}███${RAMG}███${RAMR}███${RAM}┃${TRC}│   │ │ │ │${SSD}│${DIM2}1TB PCIe4.0${SSD}│${TRC}│ │ │ │ │ │ │ │ │ ${PCB}│${B} ${FAN2}╭╯${FAN}◉◔◕◑${FAN2}╰╮${FR}│${R}${B}")
    # --- Großer ASCII-Schriftzug MITTEN IM BILD ---
    L+=("${FR}│${B}  ${PCB}│${TRC}  │ │ │ │ │ │    │${RAM}┃ DDR5 32G┃${TRC}│${RAM}┃ DDR5 32G┃${TRC}│${RAM}┃ DDR5 32G┃${TRC}│${RAM}┃ DDR5 32G┃${TRC}│   │ │ │ │${SSD}└─────────────┘${TRC}│ │ │ │ │ │ │ │ │ ${PCB}│${B} ${FAN2}╰──────╯${FR}│${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${TRC}  │ │ │ │ │ │    │${RAM}┃ 7200MT/s┃${TRC}│${RAM}┃ 7200MT/s┃${TRC}│${RAM}┃ 7200MT/s┃${TRC}│${RAM}┃ 7200MT/s┃${TRC}│   ${CHIP}┌─CHIPSET─┐${TRC} │ │ │ │ │ │ │ │ │ ${PCB}│${B}         ${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${TRC}  ═╧═╧═╧═╧═╧═══  ${RAM}┗━━━━━━━━━┛${TRC} ${RAM}┗━━━━━━━━━┛${TRC} ${RAM}┗━━━━━━━━━┛${TRC} ${RAM}┗━━━━━━━━━┛${TRC}   ${CHIP}│${DIM}PCH/HSK${CHIP}│${TRC} │ │ │ │ │ │ │ │ │ ${PCB}│${B}         ${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${TG}  ╭─────────────────────────────────────────  ${T1}H O L O   D I S P L A Y${TG}  ─────────────────────────────────────────╮${TRC} ${PCB}│${B}         ${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${TG}  │${T1}  ██╗  ██╗ █████╗ ██████╗ ██╗████████╗███████╗██╗         ██╗ ${TG}                                                       │${TRC} ${PCB}│${B}         ${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${TG}  │${T1}  ██║ ██╔╝██╔══██╗██╔══██╗██║╚══██╔══╝██╔════╝██║        ███║ ${TG}                                                       │${TRC} ${PCB}│${B}         ${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${TG}  │${T1G}  █████╔╝ ███████║██████╔╝██║   ██║   █████╗  ██║        ╚██║ ${TG}                                                       │${TRC} ${PCB}│${B}         ${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${TG}  │${T1}  ██╔═██╗ ██╔══██║██╔═══╝ ██║   ██║   ██╔══╝  ██║         ██║ ${TG}                                                       │${TRC} ${PCB}│${B}         ${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${TG}  │${T1G}  ██║  ██╗██║  ██║██║     ██║   ██║   ███████╗███████╗    ██║ ${TG}                                                       │${TRC} ${PCB}│${B}         ${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${TG}  │${T1}  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝   ╚═╝   ╚══════╝╚══════╝    ╚═╝ ${TG}                                                       │${TRC} ${PCB}│${B}         ${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${TG}  │${TG}                                                                                                                      │${TRC} ${PCB}│${B}         ${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${TG}  │${T2}   ███████╗██╗███╗   ██╗   ███╗   ██╗███████╗██╗   ██╗███████╗██████╗      █████╗  ██████╗ ███████╗███╗   ██╗████████╗${TG} │${TRC} ${PCB}│${B}         ${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${TG}  │${T2}   ██╔════╝██║████╗  ██║   ████╗  ██║██╔════╝██║   ██║██╔════╝██╔══██╗    ██╔══██╗██╔════╝ ██╔════╝████╗  ██║╚══██╔══╝${TG} │${TRC} ${PCB}│${B}         ${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${TG}  │${T2G}   █████╗  ██║██╔██╗ ██║   ██╔██╗ ██║█████╗  ██║   ██║█████╗  ██████╔╝    ███████║██║  ███╗█████╗  ██╔██╗ ██║   ██║   ${TG} │${TRC} ${PCB}│${B}         ${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${TG}  │${T2}   ██╔══╝  ██║██║╚██╗██║   ██║╚██╗██║██╔══╝  ██║   ██║██╔══╝  ██╔══██╗    ██╔══██║██║   ██║██╔══╝  ██║╚██╗██║   ██║   ${TG} │${TRC} ${PCB}│${B}         ${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${TG}  │${T2G}   ███████╗██║██║ ╚████║   ██║ ╚████║███████╗╚██████╔╝███████╗██║  ██║    ██║  ██║╚██████╔╝███████╗██║ ╚████║   ██║   ${TG} │${TRC} ${PCB}│${B}         ${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${TG}  │${T2}   ╚══════╝╚═╝╚═╝  ╚═══╝   ╚═╝  ╚═══╝╚══════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝    ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝   ${TG} │${TRC} ${PCB}│${B}         ${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${TG}  ╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯${TRC} ${PCB}│${B}         ${FR} │${R}${B}")
    # GPU und untere Sektion
    L+=("${FR}│${B}  ${PCB}│${GPU3}  ┌──────────── GRAFIKKARTE · GeForce RTX 4090 Ti · 24GB GDDR6X · 450W · TRIPLE-FAN ────────────────────────────────────────┐${TRC} ${PCB}│${B}         ${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${GPU3}  │${GPU} ▓▓▓▓ METALL-BACKPLATE · HEATSPREADER · THERMAL PADS ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ${GPU3}│${TRC} ${PCB}│${B}         ${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${GPU3}  │${GPU} ▓${FAN2}  ╭──────────╮${GPU}    ${FAN2}╭──────────╮${GPU}    ${FAN2}╭──────────╮${GPU}  ${GPUG}▚▚▚${GPUC}▚▚▚${GPUG}▚▚▚${GPUC}▚▚▚${GPU} ARGB  ${DIM2}GEFORCE RTX${GPU}  ${DIM2}2520 MHz${GPU}        ▓ ${GPU3}│${TRC} ${PCB}│${B}         ${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${GPU3}  │${GPU} ▓${FAN2} ╭╯${FAN} ◉ ◔ ◕ ◑ ◉ ${FAN2}╰╮${GPU}  ${FAN2}╭╯${FAN} ◉ ◔ ◕ ◑ ◉ ${FAN2}╰╮${GPU}  ${FAN2}╭╯${FAN} ◉ ◔ ◕ ◑ ◉ ${FAN2}╰╮${GPU} ${DIM2}AXIAL-TECH · VAPOR CHAMBER · 7 HEATPIPES${GPU} ▓ ${GPU3}│${TRC} ${PCB}│${B}         ${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${GPU3}  │${GPU} ▓${FAN2} ╰╮${FAN} ◑ ◉ ◔ ◕ ◑ ${FAN2}╭╯${GPU}  ${FAN2}╰╮${FAN} ◑ ◉ ◔ ◕ ◑ ${FAN2}╭╯${GPU}  ${FAN2}╰╮${FAN} ◑ ◉ ◔ ◕ ◑ ${FAN2}╭╯${GPU} ${GPU3}████ FIN STACK ████ HEATSINK ███████████${GPU} ▓ ${GPU3}│${TRC} ${PCB}│${B}         ${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${GPU3}  │${GPU} ▓${FAN2}  ╰──────────╯${GPU}    ${FAN2}╰──────────╯${GPU}    ${FAN2}╰──────────╯${GPU}  ${DIM2}12VHPWR${CBL2}■${CBL}■${CBL3}■${DIM2}  HDMI  DP  DP  DP  BIOS-SW${GPU}        ▓ ${GPU3}│${TRC} ${PCB}│${B}         ${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${GPU3}  └────────────────────────────────────────┬──────────────────────────────┬──────────────────────────────────────────────────┘${TRC} ${PCB}│${B}         ${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${TRC}  ═╤══╤══╤══╤══╤══╤══╤══╤══╤══╤══╤══╤══╤══${GPU3}  PCIe 5.0 x16  ${TRC}══╤══╤══╤══╤═╧══╤══╤══╤══╤══╤══╤══╤══╤══╤══╤══╤══╤══╤══╤══ ${PCB}│${B}         ${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}│${TRC}   │${DIM}x1${TRC}│  │${DIM}x1${TRC}│  │${DIM}AUDIO HDR${TRC}│  │${DIM}SATA${TRC}│  │${DIM}USB HDR${TRC}│  │${DIM}SYS_FAN${TRC}│  │${DIM}ARGB HDR${TRC}│  │${DIM}TPM${TRC}│  │${DIM}DEBUG LED${TRC}│  │${DIM}BAT${TRC}│   ${PCB}│${B}         ${FR} │${R}${B}")
    L+=("${FR}│${B}  ${PCB}└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘${B}         ${FR} │${R}${B}")
    L+=("${FR}│${B}   ${CBL4}╭─24-PIN ATX MB─╮${B} ${CBL2}╭─12VHPWR GPU─╮${B} ${CBL}╭─2x8 EPS CPU─╮${B} ${CBL3}╭─SATA/PWR─╮${B} ${CBL5}╭─ARGB/FAN─╮${B}  ${DRV}┌─ DRIVE BAY / SSD ──────────┐${B} ${PSU}┌─ 1000W 80+ TITANIUM PSU ─┐${FR} │${R}${B}")
    L+=("${FR}│${B}   ${CBL4}│${DIM}▓▓▓▓▓▓▓▓▓▓▓▓▓▓${CBL4}│${B} ${CBL2}│${DIM}▓▓▓▓▓▓▓▓▓▓▓${CBL2}│${B} ${CBL}│${DIM}▓▓▓▓▓▓▓▓▓▓${CBL}│${B} ${CBL3}│${DIM}▓▓▓▓▓▓▓▓${CBL3}│${B} ${CBL5}│${DIM}▓▓▓▓▓▓${CBL5}│${B}  ${DRV}│${SSD}[NVMe Bay] ${DIM}ext${SSD}  [2.5]4TB ${LED}●${DRV} │${B} ${PSU}│${PSU2}╔═══════════════════════╗${PSU}│${FR} │${R}${B}")
    L+=("${FR}│${B}   ${CBL4}╰──────┬────────╯${B} ${CBL2}╰─────┬──────╯${B} ${CBL}╰─────┬──────╯${B} ${CBL3}╰───┬────╯${B} ${CBL5}╰───┬──╯${B}  ${DRV}│${SSD}[2.5 SSD] 2TB ${LED}●${DIM}  [2.5]2TB ${LED}●${DRV} │${B} ${PSU}│${PSU2}║${DIM} ███ HYBRID FAN 135mm ███ ${PSU2}║${PSU}│${FR} │${R}${B}")
    L+=("${FR}│${B}          ${CBL4}│${B}              ${CBL2}│${B}            ${CBL}│${B}          ${CBL3}│${B}        ${CBL5}│${B}     ${DRV}│${DIM}[3.5 HDD] 8TB ${LED2}○${DIM}  HOT-SWAP  ${DRV} │${B} ${PSU}│${PSU2}║${DIM} ~~~~~~~~~~~~~~~~~~~~~~~~ ${PSU2}║${PSU}│${FR} │${R}${B}")
    L+=("${FR}│${B}          ${CBL4}└──────────────${CBL2}┴──────┬─────${CBL}┴──────────${CBL3}┴────────${CBL5}┴─────${DRV}└────────────────────────────┘${B} ${PSU}│${PSU2}║${DIM} FULL MODULAR · LLC · DC-DC ${PSU2}║${PSU}│${FR} │${R}${B}")
    L+=("${FR}│${B}                                 ${DIM2}gesleevte Kabel · Kämme · Gummidurchführungen · sauberer Kabelkanal${B}                  ${PSU}│${PSU2}╚═══════════════════════╝${PSU}│${FR} │${R}${B}")
    L+=("${FR}│${B}                                                                                                                     ${PSU}└──────────────────────────┘${FR} │${R}${B}")
    L+=("${FR}└${FR2}══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════${FR}┘${R}${B}")

    local i
    for i in "${!L[@]}"; do
        printf '\033[%d;1H%s%s%s' "$((y + i))" "$B" "$sp" "${L[$i]}"
    done
    printf '%s' "$R"
}

# --- Ort: Desktop City (Stadtansicht mit großem Schriftzug) ----------
archive_draw_ort_desktopcity() {
    local w=146
    local cols="${COLS:-80}" rows="${ROWS:-24}"
    local pad=$(( (cols - w) / 2 ))
    [ "$pad" -lt 0 ] && pad=0
    local sp; printf -v sp '%*s' "$pad" ''

    local R=$'\033[0m'
    local B=$'\033[48;5;232m'
    local FR=$'\033[38;5;31m'
    local SKY=$'\033[38;5;17m'
    local SKY2=$'\033[38;5;18m'
    local STAR=$'\033[38;5;229m'
    local STAR2=$'\033[38;5;159m'
    local DATA=$'\033[38;5;45m'
    local DATA2=$'\033[38;5;39m'
    local NEON=$'\033[1;38;5;51m'
    local NEON2=$'\033[1;38;5;87m'
    local NEONP=$'\033[1;38;5;201m'
    local NEONG=$'\033[1;38;5;46m'
    local GOLD=$'\033[1;38;5;220m'
    local GOLD2=$'\033[1;38;5;228m'
    local BLD=$'\033[38;5;240m'
    local BLD2=$'\033[38;5;244m'
    local BLD3=$'\033[38;5;236m'
    local BLD4=$'\033[38;5;238m'
    local WIN=$'\033[38;5;226m'
    local WIN2=$'\033[38;5;51m'
    local WIN3=$'\033[38;5;214m'
    local WIN4=$'\033[38;5;120m'
    local OFF=$'\033[38;5;238m'
    local GLASS=$'\033[38;5;30m'
    local ROAD=$'\033[38;5;239m'
    local ROAD2=$'\033[38;5;250m'
    local ROAD3=$'\033[38;5;244m'
    local GATE=$'\033[38;5;252m'
    local SIGN=$'\033[38;5;81m'
    local DIM=$'\033[38;5;60m'
    local DIM2=$'\033[38;5;245m'

    printf '%s' "$B"
    clear

    local -a L=()
    L+=("${FR}┌${NEON}══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════${FR}┐${R}${B}")
    L+=("${FR}│${SKY}  ·  ˚  ·   ${STAR}✦${SKY}     ·      ˚   ${STAR2}✧${SKY}   ·  ══${DATA}════${DATA2}════${DATA}══╗${SKY}  ·   ${STAR}✦${SKY}    DATENSTROM-HIMMEL   ${STAR2}✧${SKY}   ·  ╔══${DATA}════${DATA2}════${DATA}══  ·   ˚  ${STAR}✦${SKY}  ·      ${FR}│${R}${B}")
    L+=("${FR}│${SKY}   ·    ${STAR2}✧${SKY}    ·   ${STAR}✦${SKY}   ·        ${DATA}║${SKY}   ˚  ·      ${STAR}✦${SKY}      ·  PACKET-FLUSS / ROUTING  ·      ${STAR2}✧${SKY}   ·   ${DATA}║${SKY}      ·    ${STAR}✦${SKY}     ·   ${FR}│${R}${B}")
    L+=("${FR}├${FR}──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────${FR}┤${R}${B}")
    # Ferne Skyline + Antennen
    L+=("${FR}│${SKY2} ${DIM}˙˙˙${BLD3}┌┐${DIM}˙˙${BLD3}┌──┐${DIM}˙˙˙${BLD4}┌┐${DIM}˙˙˙${BLD3}┌───┐${DIM}˙˙${BLD4}┌┐${DIM}˙˙˙${BLD3}┌─┐${DIM}˙˙˙${BLD4}┌──┐${DIM}˙˙˙${BLD3}┌┐${DIM}˙˙˙${BLD4}┌───┐${DIM}˙˙˙${BLD3}┌─┐${DIM}˙˙˙${BLD4}┌──┐${DIM}˙˙${BLD3}┌┐${DIM}˙˙˙${BLD4}┌───┐${DIM}˙˙˙${BLD3}┌──┐${DIM}˙˙˙${BLD4}┌┐${DIM}˙˙˙${FR}│${R}${B}")
    L+=("${FR}│${SKY2} ${DIM}  ${BLD3}││${DIM}  ${BLD3}│${WIN2}··${BLD3}│${DIM}  ${BLD4}││${DIM}  ${BLD3}│${WIN}·${WIN2}·${BLD3}│${DIM}  ${BLD4}││${DIM}  ${BLD3}│${WIN3}·${BLD3}│${DIM}  ${BLD4}│${WIN}··${BLD4}│${DIM}  ${BLD3}││${DIM}  ${BLD4}│${WIN2}·${WIN}·${BLD4}│${DIM}  ${BLD3}│${WIN3}·${BLD3}│${DIM}  ${BLD4}│${WIN}··${BLD4}│${DIM}  ${BLD3}││${DIM}  ${BLD4}│${WIN2}·${WIN}·${BLD4}│${DIM}  ${BLD3}│${WIN}··${BLD3}│${DIM}  ${BLD4}││${DIM}  ${FR}│${R}${B}")
    # Mittlere Skyline mit großem DESKTOP Schriftzug
    L+=("${FR}│${SKY2} ${BLD4}┌──┐${BLD3}┌────┐${BLD4}┌─┐${BLD3}┌──────┐${BLD4}┌──┐${BLD3}┌───┐${SKY2}      ${NEON}╔════════════════════════════════════════════════════════════════════╗${SKY2}      ${BLD3}┌───┐${BLD4}┌──────┐${BLD3}┌──┐${FR} │${R}${B}")
    L+=("${FR}│${SKY2} ${BLD4}│${WIN2}▣▣${BLD4}│${BLD3}│${WIN}▣${WIN2}▣${WIN}▣${WIN2}▣${BLD3}│${BLD4}│${WIN3}▣${BLD4}│${BLD3}│${WIN}▣${WIN2}▣${WIN}▣${WIN2}▣${WIN}▣${BLD3}│${BLD4}│${WIN}▣▣${BLD4}│${BLD3}│${WIN2}▣${WIN}▣${BLD3}│${SKY2}      ${NEON}║${NEON2}  ██████╗ ███████╗███████╗██╗  ██╗████████╗ ██████╗ ██████╗   ${NEON}║${SKY2}      ${BLD3}│${WIN}▣${WIN2}▣${BLD3}│${BLD4}│${WIN}▣${WIN2}▣${WIN}▣${WIN2}▣${WIN}▣${BLD4}│${BLD3}│${WIN2}▣▣${BLD3}│${FR} │${R}${B}")
    L+=("${FR}│${SKY2} ${BLD4}│${WIN}▣▣${BLD4}│${BLD3}│${WIN2}▣${WIN}▣${WIN2}▣${WIN}▣${BLD3}│${BLD4}│${WIN}▣${BLD4}│${BLD3}│${WIN2}▣${WIN}▣${WIN2}▣${WIN}▣${WIN2}▣${BLD3}│${BLD4}│${WIN2}▣▣${BLD4}│${BLD3}│${WIN}▣${WIN2}▣${BLD3}│${SKY2}      ${NEON}║${NEON2}  ██╔══██╗██╔════╝██╔════╝██║ ██╔╝╚══██╔══╝██╔═══██╗██╔══██╗  ${NEON}║${SKY2}      ${BLD3}│${WIN2}▣${WIN}▣${BLD3}│${BLD4}│${WIN2}▣${WIN}▣${WIN2}▣${WIN}▣${WIN2}▣${BLD4}│${BLD3}│${WIN}▣▣${BLD3}│${FR} │${R}${B}")
    L+=("${FR}│${SKY2} ${BLD4}│${WIN2}▣▣${BLD4}│${BLD3}│${WIN}▣${WIN2}▣${WIN}▣${WIN2}▣${BLD3}│${BLD4}│${WIN3}▣${BLD4}│${BLD3}│${WIN}▣${WIN2}▣${WIN}▣${WIN2}▣${WIN}▣${BLD3}│${BLD4}│${WIN}▣▣${BLD4}│${BLD3}│${WIN2}▣${WIN}▣${BLD3}│${SKY2}      ${NEON}║${NEON}  ██║  ██║█████╗  ███████╗█████╔╝    ██║   ██║   ██║██████╔╝  ${NEON}║${SKY2}      ${BLD3}│${WIN}▣${WIN2}▣${BLD3}│${BLD4}│${WIN}▣${WIN2}▣${WIN}▣${WIN2}▣${WIN}▣${BLD4}│${BLD3}│${WIN2}▣▣${BLD3}│${FR} │${R}${B}")
    L+=("${FR}│${SKY2} ${BLD4}│${WIN}▣▣${BLD4}│${BLD3}│${WIN2}▣${WIN}▣${WIN2}▣${WIN}▣${BLD3}│${BLD4}│${WIN}▣${BLD4}│${BLD3}│${WIN2}▣${WIN}▣${WIN2}▣${WIN}▣${WIN2}▣${BLD3}│${BLD4}│${WIN2}▣▣${BLD4}│${BLD3}│${WIN}▣${WIN2}▣${BLD3}│${SKY2}      ${NEON}║${NEON2}  ██║  ██║██╔══╝  ╚════██║██╔═██╗    ██║   ██║   ██║██╔═══╝   ${NEON}║${SKY2}      ${BLD3}│${WIN2}▣${WIN}▣${BLD3}│${BLD4}│${WIN2}▣${WIN}▣${WIN2}▣${WIN}▣${WIN2}▣${BLD4}│${BLD3}│${WIN}▣▣${BLD3}│${FR} │${R}${B}")
    L+=("${FR}│${SKY2} ${BLD4}│${WIN2}▣▣${BLD4}│${BLD3}│${WIN}▣${WIN2}▣${WIN}▣${WIN2}▣${BLD3}│${BLD4}│${WIN3}▣${BLD4}│${BLD3}│${WIN}▣${WIN2}▣${WIN}▣${WIN2}▣${WIN}▣${BLD3}│${BLD4}│${WIN}▣▣${BLD4}│${BLD3}│${WIN2}▣${WIN}▣${BLD3}│${SKY2}      ${NEON}║${NEON}  ██████╔╝███████╗███████║██║  ██╗   ██║   ╚██████╔╝██║       ${NEON}║${SKY2}      ${BLD3}│${WIN}▣${WIN2}▣${BLD3}│${BLD4}│${WIN}▣${WIN2}▣${WIN}▣${WIN2}▣${WIN}▣${BLD4}│${BLD3}│${WIN2}▣▣${BLD3}│${FR} │${R}${B}")
    L+=("${FR}│${SKY2} ${BLD4}│${OFF}▣▣${BLD4}│${BLD3}│${OFF}▣${WIN}▣${OFF}▣${WIN}▣${BLD3}│${BLD4}│${OFF}▣${BLD4}│${BLD3}│${OFF}▣${WIN}▣${OFF}▣${WIN}▣${OFF}▣${BLD3}│${BLD4}│${OFF}▣▣${BLD4}│${BLD3}│${OFF}▣${WIN}▣${BLD3}│${SKY2}      ${NEON}║${NEON2}  ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝       ${NEON}║${SKY2}      ${BLD3}│${OFF}▣${WIN}▣${BLD3}│${BLD4}│${OFF}▣${WIN}▣${OFF}▣${WIN}▣${OFF}▣${BLD4}│${BLD3}│${OFF}▣▣${BLD3}│${FR} │${R}${B}")
    L+=("${FR}│${SKY2} ${BLD4}└──┘${BLD3}└────┘${BLD4}└─┘${BLD3}└──────┘${BLD4}└──┘${BLD3}└───┘${SKY2}      ${NEON}║${NEON}                                                                ${NEON}║${SKY2}      ${BLD3}└───┘${BLD4}└──────┘${BLD3}└──┘${FR} │${R}${B}")
    # CITY Schriftzug darunter (groß und gut lesbar)
    L+=("${FR}│${SKY2}        ${BLD3}┌────┐${SKY2}      ${BLD4}┌──────┐${SKY2}          ${NEON}║${NEON}                                                                ${NEON}║${SKY2}          ${BLD4}┌──────┐${SKY2}      ${BLD3}┌────┐${SKY2}        ${FR}│${R}${B}")
    L+=("${FR}│${SKY2}        ${BLD3}│${WIN}▣${WIN2}▣${WIN}▣${BLD3}│${SKY2}      ${BLD4}│${WIN}▣${WIN2}▣${WIN}▣${WIN2}▣${BLD4}│${SKY2}          ${NEON}║${GOLD}                ██████╗ ██╗ ████████╗ ██╗   ██╗                   ${NEON}║${SKY2}          ${BLD4}│${WIN2}▣${WIN}▣${WIN2}▣${WIN}▣${BLD4}│${SKY2}      ${BLD3}│${WIN}▣${WIN2}▣${WIN}▣${BLD3}│${SKY2}        ${FR}│${R}${B}")
    L+=("${FR}│${SKY2}        ${BLD3}│${WIN2}▣${WIN}▣${WIN2}▣${BLD3}│${SKY2}      ${BLD4}│${WIN2}▣${WIN}▣${WIN2}▣${WIN}▣${BLD4}│${SKY2}          ${NEON}║${GOLD}               ██╔════╝ ██║ ╚══██╔══╝ ╚██╗ ██╔╝                   ${NEON}║${SKY2}          ${BLD4}│${WIN}▣${WIN2}▣${WIN}▣${WIN2}▣${BLD4}│${SKY2}      ${BLD3}│${WIN2}▣${WIN}▣${WIN2}▣${BLD3}│${SKY2}        ${FR}│${R}${B}")
    L+=("${FR}│${SKY2}        ${BLD3}│${WIN}▣${OFF}▣${WIN}▣${BLD3}│${SKY2}      ${BLD4}│${WIN}▣${OFF}▣${WIN}▣${OFF}▣${BLD4}│${SKY2}          ${NEON}║${GOLD2}               ██║      ██║    ██║     ╚████╔╝                    ${NEON}║${SKY2}          ${BLD4}│${WIN2}▣${OFF}▣${WIN2}▣${OFF}▣${BLD4}│${SKY2}      ${BLD3}│${WIN}▣${OFF}▣${WIN}▣${BLD3}│${SKY2}        ${FR}│${R}${B}")
    L+=("${FR}│${SKY2}        ${BLD3}│${WIN2}▣${WIN}▣${WIN2}▣${BLD3}│${SKY2}      ${BLD4}│${WIN2}▣${WIN}▣${WIN2}▣${WIN}▣${BLD4}│${SKY2}          ${NEON}║${GOLD}               ██║      ██║    ██║      ╚██╔╝                     ${NEON}║${SKY2}          ${BLD4}│${WIN}▣${WIN2}▣${WIN}▣${WIN2}▣${BLD4}│${SKY2}      ${BLD3}│${WIN2}▣${WIN}▣${WIN2}▣${BLD3}│${SKY2}        ${FR}│${R}${B}")
    L+=("${FR}│${SKY2}        ${BLD3}└────┘${SKY2}      ${BLD4}│${WIN}▣${WIN2}▣${WIN}▣${WIN2}▣${BLD4}│${SKY2}          ${NEON}║${GOLD2}               ╚██████╗ ██║    ██║       ██║                      ${NEON}║${SKY2}          ${BLD4}│${WIN2}▣${WIN}▣${WIN2}▣${WIN}▣${BLD4}│${SKY2}      ${BLD3}└────┘${SKY2}        ${FR}│${R}${B}")
    L+=("${FR}│${SKY2}                    ${BLD4}└──────┘${SKY2}          ${NEON}║${GOLD}                ╚═════╝ ╚═╝    ╚═╝       ╚═╝                      ${NEON}║${SKY2}          ${BLD4}└──────┘${SKY2}                    ${FR}│${R}${B}")
    L+=("${FR}│${SKY2}     ${DATA}──╦──${DATA2}──────${DATA}──╦──${SKY2}                      ${NEON}║${NEON}                                                                ${NEON}║${SKY2}                      ${DATA}──╦──${DATA2}──────${DATA}──╦──${SKY2}     ${FR}│${R}${B}")
    L+=("${FR}│${SKY2}                                              ${NEON}╚════════════════════════════════════════════════════════════════════╝${SKY2}                                              ${FR}│${R}${B}")
    # Dichtere Stadtbebauung, Reklame, Brücken, Monorail-Linie
    L+=("${FR}│${BLD3} ┌──────────────┐${B} ${BLD}┌─────────┐${B} ${BLD4}┌────┐${B} ${BLD3}┌────────────┐${B} ${NEONP}┌─ DAILYPULSE ─┐${B} ${BLD}┌───────────────┐${B} ${NEONG}┌─ TERMINAL ──┐${B} ${BLD3}┌──────────┐${FR} │${R}${B}")
    L+=("${FR}│${BLD3} │${WIN2}▣ ${WIN}▣ ${WIN2}▣ ${WIN}▣ ${WIN2}▣ ${WIN}▣ ${WIN2}▣│${B} ${BLD}│${WIN}▣ ${WIN2}▣ ${WIN}▣ ${WIN2}▣│${B} ${BLD4}│${WIN3}▣${WIN}▣│${B} ${BLD3}│${WIN}▣ ${WIN2}▣ ${WIN}▣ ${WIN2}▣ ${WIN}▣ │${B} ${NEONP}│${DIM}/var/log/news${NEONP}│${B} ${BLD}│${WIN}▣ ${WIN2}▣ ${WIN}▣ ${WIN2}▣ ${WIN}▣ ${WIN2}▣ ${WIN}▣│${B} ${NEONG}│${DIM}  >_ shell  ${NEONG}│${B} ${BLD3}│${WIN}▣ ${WIN2}▣ ${WIN}▣ ${WIN2}▣│${FR} │${R}${B}")
    L+=("${FR}│${BLD3} │${WIN}▣ ${WIN2}▣ ${WIN}▣ ${WIN2}▣ ${WIN}▣ ${WIN2}▣ ${WIN}▣│${B} ${BLD}│${WIN2}▣ ${WIN}▣ ${WIN2}▣ ${WIN}▣│${B} ${BLD4}│${WIN}▣${WIN3}▣│${B} ${BLD3}│${WIN2}▣ ${WIN}▣ ${WIN2}▣ ${WIN}▣ ${WIN2}▣ │${B} ${NEONP}└──────────────┘${B} ${BLD}│${WIN2}▣ ${WIN}▣ ${WIN2}▣ ${WIN}▣ ${WIN2}▣ ${WIN}▣ ${WIN2}▣│${B} ${NEONG}└─────────────┘${B} ${BLD3}│${WIN2}▣ ${WIN}▣ ${WIN2}▣ ${WIN}▣│${FR} │${R}${B}")
    L+=("${FR}│${BLD3} │${WIN2}▣ ${OFF}▣ ${WIN}▣ ${WIN2}▣ ${OFF}▣ ${WIN}▣ ${OFF}▣│${B} ${BLD}│${WIN}▣ ${OFF}▣ ${WIN}▣ ${OFF}▣│${B} ${BLD4}│${OFF}▣${WIN}▣│${B} ${BLD3}│${WIN}▣ ${OFF}▣ ${WIN}▣ ${OFF}▣ ${WIN}▣ │${B} ${SIGN}┌─ SYS SHOP ─┐${B} ${BLD}│${WIN}▣ ${OFF}▣ ${WIN}▣ ${OFF}▣ ${WIN}▣ ${OFF}▣ ${WIN}▣│${B} ${BLD4}┌────────┐${B} ${BLD3}│${WIN}▣ ${OFF}▣ ${WIN}▣ ${OFF}▣│${FR} │${R}${B}")
    L+=("${FR}│${BLD3} │${WIN}▣ ${WIN2}▣ ${OFF}▣ ${WIN}▣ ${WIN2}▣ ${OFF}▣ ${WIN}▣│${B} ${BLD}│${WIN2}▣ ${WIN}▣ ${OFF}▣ ${WIN}▣│${B} ${BLD4}│${WIN}▣${OFF}▣│${B} ${BLD3}│${WIN2}▣ ${WIN}▣ ${OFF}▣ ${WIN}▣ ${WIN2}▣ │${B} ${SIGN}│${DIM}  bits/tools${SIGN}│${B} ${BLD}│${WIN2}▣ ${WIN}▣ ${OFF}▣ ${WIN}▣ ${WIN2}▣ ${WIN}▣ ${OFF}▣│${B} ${BLD4}│${WIN4}▣${WIN}▣${WIN4}▣${WIN}▣${BLD4}│${B} ${BLD3}│${WIN2}▣ ${WIN}▣ ${OFF}▣ ${WIN}▣│${FR} │${R}${B}")
    L+=("${FR}│${BLD3} └───────┬──────┘${B} ${BLD}└────┬────┘${B} ${BLD4}└─┬──┘${B} ${BLD3}└──────┬─────┘${B} ${SIGN}└────────────┘${B} ${BLD}└───────┬───────┘${B} ${BLD4}│${WIN}▣${WIN4}▣${WIN}▣${WIN4}▣${BLD4}│${B} ${BLD3}└────┬─────┘${FR} │${R}${B}")
    L+=("${FR}│${DIM2}  ───────┴─────── MONORAIL / DATENBRÜCKE ─────────┴───────────────┴────────────────────────┴────────────────${BLD4}└────────┘${DIM2}────┴──────────── ${FR}│${R}${B}")
    L+=("${FR}│${ROAD}═════════╧══════════════${BLD}════╧══════${BLD4}══╧════${BLD3}══════╧════════════════════════════════════${BLD}═══════╧══════════════════════════${BLD3}════╧══════════${FR}│${R}${B}")
    L+=("${FR}│${ROAD2}  ░░  ░░  ░░  ${DIM}▓▓${ROAD2}  ░░  ░░  ${GATE}┌───────────── HAUPTTOR / GATEWAY ─────────────┐${ROAD2}  ░░  ${DIM}▓▓${ROAD2}  ░░  ${DATA}≋${ROAD2}  ░░  ${DIM}STREAM: ~/DesktopCity${ROAD2}  ░░ ${FR}│${R}${B}")
    L+=("${FR}│${ROAD}── ── ── ── ── ── ── ── ── ${GATE}│${NEON}   >>>   WILLKOMMEN IN DESKTOP CITY   <<<   ${GATE}│${ROAD} ── ── ── ── ── ── ── ── ── ── ── ── ── ── ── ── ──${FR}│${R}${B}")
    L+=("${FR}│${ROAD2}  ░░  ${DIM}▓▓${ROAD2}  ░░  ░░  ${DIM}▓▓${ROAD2}  ░░  ${GATE}│${DIM}   Zugang: /home/.../Schreibtisch/DesktopCity   ${GATE}│${ROAD2}  ░░  ${DIM}▓▓${ROAD2}  ░░  ${DIM}▓▓${ROAD2}  ░░  ${DIM}▓▓${ROAD2}  ░░  ${DIM}▓▓${ROAD2}  ░░     ${FR}│${R}${B}")
    L+=("${FR}│${ROAD}── ── ── ── ── ── ── ── ── ${GATE}│${DIM}   Status: AKTIV  ·  Firewall: ONLINE  ·  Ports offen ${GATE}│${ROAD} ── ── ── ── ── ── ── ── ── ── ── ── ── ── ──${FR}│${R}${B}")
    L+=("${FR}│${ROAD2}  ░░  ░░  ░░  ${DIM}▓▓${ROAD2}  ░░  ░░  ${GATE}└──────────────────────┬──────────────────────┘${ROAD2}  ░░  ░░  ${DIM}▓▓${ROAD2}  ░░  ░░  ${DIM}▓▓${ROAD2}  ░░  ░░  ░░  ░░     ${FR}│${R}${B}")
    L+=("${FR}│${ROAD}══════════════════════════════════════════════════════${GATE}╩${ROAD}═══════════════════════════════════════════════════════════════════════════════${FR}│${R}${B}")
    L+=("${FR}│${ROAD3}  ▓▓  PFLASTER  ▓▓  ${DIM}│${ROAD3}  Leitungen  ${DIM}│${ROAD3}  Datenkabel  ${DIM}│${ROAD3}  Wartungsschächte  ${DIM}│${ROAD3}  ${NEONP}●${DIM} DailyPulse  ${NEONG}●${DIM} Terminal  ${GOLD}●${DIM} Zentrum  ${NEON}●${DIM} Tor aktiv     ${ROAD3}▓▓${FR} │${R}${B}")
    L+=("${FR}│${DIM}  Knoten: Norddistrikt · Süddistrikt · Westdistrikt · Ostdistrikt · Zentrum   ·   Verkehr: Prozesse/Daemons   ·   Sicherheit: Watcher       ${FR}│${R}${B}")
    L+=("${FR}└${FR}══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════${FR}┘${R}${B}")

    local art_h=${#L[@]}
    local y=$(( (rows - art_h) / 2 ))
    [ "$y" -lt 1 ] && y=1
    local i
    for i in "${!L[@]}"; do
        printf '\033[%d;1H%s%s%s' "$((y + i))" "$B" "$sp" "${L[$i]}"
    done
    printf '%s' "$R"
}

# --- Orte: Freischaltungen/Metadaten ---------------------------------
archive_ort_is_unlocked() {   # $1 = Ort-ID
    case "$1" in
        desktopcity) [ "${ARCHIVE_ORT_DESKTOPCITY:-0}" = "1" ] ;;
        *) return 1 ;;
    esac
}

archive_ort_unlock() {        # $1 = Ort-ID
    case "$1" in
        desktopcity) ARCHIVE_ORT_DESKTOPCITY=1 ;;
    esac
}

archive_ort_title() {         # $1 = Ort-ID
    case "$1" in
        desktopcity) printf 'Desktop City' ;;
        *) printf '%s' "$1" ;;
    esac
}

archive_show_ort_timed() {    # $1 = Ort-ID
    local id="${1:-}"
    play_sound online 2>/dev/null || true
    case "$id" in
        desktopcity) archive_draw_ort_desktopcity ;;
        *) return 1 ;;
    esac
    sleep 7
}

archive_show_ort_interactive() {  # $1 = Ort-ID
    local id="${1:-}"
    play_sound online 2>/dev/null || true
    case "$id" in
        desktopcity) archive_draw_ort_desktopcity ;;
        *) return 1 ;;
    esac
    local hint=' Schließen mit ESC / Q '
    local cols="${COLS:-80}" rows="${ROWS:-24}"
    local col=$(( (cols - ${#hint}) / 2 ))
    [ "$col" -lt 1 ] && col=1
    printf '\033[%d;%dH\033[1;38;5;231;48;5;236m%s\033[0m\033[48;5;232m' "$rows" "$col" "$hint"
    while true; do
        read_key_t "" || break
        case "$LAST_KEY" in
            $'\x1b'|q|Q) break ;;
            *) : ;;
        esac
    done
}

# Komfort: Desktop City freischalten und automatisch anzeigen.
archive_maybe_intro_desktopcity() {
    [ "${ARCHIVE_ORT_DESKTOPCITY:-0}" = "1" ] && return 0
    archive_ort_unlock desktopcity
    archive_show_ort_timed desktopcity
}

# Kapitelbild anzeigen (Intro/automatisch): Vollbild, 7 Sekunden, dann zurück.
# $1 = Kapitelnummer
archive_show_chapter_timed() {
    local ch="${1:-1}"
    play_sound online 2>/dev/null || true
    case "$ch" in
        1) archive_draw_kapitel1 ;;
        *) return 1 ;;
    esac
    sleep 7
}

# Kapitelbild interaktiv im Archiv anzeigen: bleibt sichtbar, bis der
# Benutzer schließt (ESC/Q). Hinweis wird eingeblendet.
# $1 = Kapitelnummer
archive_show_chapter_interactive() {
    local ch="${1:-1}"
    play_sound online 2>/dev/null || true
    case "$ch" in
        1) archive_draw_kapitel1 ;;
        *) return 1 ;;
    esac
    # Hinweis unten einblenden: Schließen mit ESC / Q
    local hint=' Schließen mit ESC / Q '
    local cols="${COLS:-80}" rows="${ROWS:-24}"
    local col=$(( (cols - ${#hint}) / 2 ))
    [ "$col" -lt 1 ] && col=1
    printf '\033[%d;%dH\033[1;38;5;231;48;5;236m%s\033[0m\033[48;5;232m' "$rows" "$col" "$hint"
    # Auf Schließen warten (kein automatisches Ausblenden)
    while true; do
        read_key_t "" || break
        case "$LAST_KEY" in
            $'\x1b'|q|Q) break ;;
            *) : ;;
        esac
    done
}

# Komfort: Kapitel 1 beim ersten Erreichen freischalten und zeigen.
archive_maybe_intro_kap1() {
    [ "${ARCHIVE_KAP1:-0}" = "1" ] && return 0
    archive_unlock 1
    archive_show_chapter_timed 1
}

# --- TUI: Kapitel-Ansicht (durch freigeschaltete Bilder blättern) ----
archive_chapter_view() {
    # Liste freigeschalteter Kapitel aufbauen
    local -a unlocked=()
    [ "${ARCHIVE_KAP1:-0}" = "1" ] && unlocked+=(1)
    if [ "${#unlocked[@]}" -eq 0 ]; then
        printf '%s' "$UI_BG"; clear
        overlay_geom
        local pw="$OV_W" ph="$OV_H" px="$OV_X" py="$OV_Y" inner="$OV_INNER" ix=$((px+1))
        draw_box "$px" "$py" "$pw" "$ph" "" "$FRAME_HI"
        put_text "$((py + ph/2))" "$ix" "$inner" \
            "$(center_text 'Noch keine Kapitel freigeschaltet.' "$inner")" "$MUTED"
        put_text "$((py + ph - 2))" "$ix" "$inner" \
            "$(center_text 'Beliebige Taste: zurück' "$inner")" "$MENU_C"
        read_key_t "" || true
        return 0
    fi

    local idx=0
    while true; do
        archive_show_chapter_interactive "${unlocked[$idx]}"
        printf '%s' "$UI_BG"
        clear
        overlay_geom
        local pw="$OV_W" ph="$OV_H" px="$OV_X" py="$OV_Y" inner="$OV_INNER" ix=$((px+1))
        draw_box "$px" "$py" "$pw" "$ph" "" "$FRAME_HI"
        put_text "$((py + 2))" "$ix" "$inner" \
            "$(center_text '◤  ARCHIV · KAPITEL  ◢' "$inner")" "$TITLE$BOLD"
        put_text "$((py + 4))" "$ix" "$inner" \
            "$(center_text "$(archive_chapter_title "${unlocked[$idx]}")" "$inner")" "$FG"
        put_text "$((py + 6))" "$ix" "$inner" \
            "$(center_text "Kapitel $((idx+1)) von ${#unlocked[@]}" "$inner")" "$MUTED"
        local hint='←/→ wechseln  ·  Enter anzeigen  ·  Esc/Q zurück'
        put_text "$((py + ph - 2))" "$ix" "$inner" "$(center_text "$hint" "$inner")" "$MENU_C"
        read_key_t "" || break
        case "$LAST_KEY" in
            $'\x1b[C'|$'\x1bOC'|$'\x1b[B'|$'\x1bOB')
                [ $((idx + 1)) -lt ${#unlocked[@]} ] && idx=$((idx + 1)) ;;
            $'\x1b[D'|$'\x1bOD'|$'\x1b[A'|$'\x1bOA')
                [ "$idx" -gt 0 ] && idx=$((idx - 1)) ;;
            $'\n'|$'\r'|'')
                : ;; # erneut anzeigen
            $'\x1b'|q|Q) break ;;
            *) : ;;
        esac
    done
}

# --- TUI: Orte-Ansicht (durch freigeschaltete Ortsbilder blättern) ----
archive_orte_view() {
    local -a unlocked=()
    [ "${ARCHIVE_ORT_DESKTOPCITY:-0}" = "1" ] && unlocked+=(desktopcity)
    if [ "${#unlocked[@]}" -eq 0 ]; then
        printf '%s' "$UI_BG"; clear
        overlay_geom
        local pw="$OV_W" ph="$OV_H" px="$OV_X" py="$OV_Y" inner="$OV_INNER" ix=$((px+1))
        draw_box "$px" "$py" "$pw" "$ph" "" "$FRAME_HI"
        put_text "$((py + ph/2))" "$ix" "$inner" \
            "$(center_text 'Noch keine Orte freigeschaltet.' "$inner")" "$MUTED"
        put_text "$((py + ph - 2))" "$ix" "$inner" \
            "$(center_text 'Beliebige Taste: zurück' "$inner")" "$MENU_C"
        read_key_t "" || true
        return 0
    fi

    local idx=0
    while true; do
        archive_show_ort_interactive "${unlocked[$idx]}"
        printf '%s' "$UI_BG"
        clear
        overlay_geom
        local pw="$OV_W" ph="$OV_H" px="$OV_X" py="$OV_Y" inner="$OV_INNER" ix=$((px+1))
        draw_box "$px" "$py" "$pw" "$ph" "" "$FRAME_HI"
        put_text "$((py + 2))" "$ix" "$inner" \
            "$(center_text '◤  ARCHIV · ORTE  ◢' "$inner")" "$TITLE$BOLD"
        put_text "$((py + 4))" "$ix" "$inner" \
            "$(center_text "$(archive_ort_title "${unlocked[$idx]}")" "$inner")" "$FG"
        put_text "$((py + 6))" "$ix" "$inner" \
            "$(center_text "Ort $((idx+1)) von ${#unlocked[@]}" "$inner")" "$MUTED"
        local hint='←/→ wechseln  ·  Enter anzeigen  ·  Esc/Q zurück'
        put_text "$((py + ph - 2))" "$ix" "$inner" "$(center_text "$hint" "$inner")" "$MENU_C"
        read_key_t "" || break
        case "$LAST_KEY" in
            $'\x1b[C'|$'\x1bOC'|$'\x1b[B'|$'\x1bOB')
                [ $((idx + 1)) -lt ${#unlocked[@]} ] && idx=$((idx + 1)) ;;
            $'\x1b[D'|$'\x1bOD'|$'\x1b[A'|$'\x1bOA')
                [ "$idx" -gt 0 ] && idx=$((idx - 1)) ;;
            $'\n'|$'\r'|'')
                : ;; # erneut anzeigen
            $'\x1b'|q|Q) break ;;
            *) : ;;
        esac
    done
}

# --- TUI: Hauptmenü (Kapitel / Orte / Zurück) ------------------------
archive_draw_menu() {   # $1 = selektierter Index (0=Kapitel,1=Orte,2=Zurück)
    local sel="${1:-0}"
    overlay_geom
    local pw="$OV_W" ph="$OV_H" px="$OV_X" py="$OV_Y" inner="$OV_INNER" ix=$((px+1))

    clear_region "$((py + 1))" "$ix" "$inner" "$((ph - 2))"
    draw_box "$px" "$py" "$pw" "$ph" "" "$FRAME_HI"
    put_text "$((py + 2))" "$ix" "$inner" \
        "$(center_text '◤  A R C H I V  ◢' "$inner")" "$TITLE$BOLD"
    put_text "$((py + 3))" "$ix" "$inner" "$(repeat '─' "$inner")" "$FRAME"
    put_text "$((py + 5))" "$ix" "$inner" \
        "$(center_text 'Freigeschaltete Erinnerungen, Kapitel und Orte.' "$inner")" "$MUTED"

    local row=$((py + 8))
    local opts=("Kapitel" "Orte" "Zurück")
    local i label col marker
    for i in "${!opts[@]}"; do
        label="${opts[$i]}"
        if [ "$i" = "$sel" ]; then
            col="$ACCENT$BOLD"; marker="▸ ${label}"
        else
            col="$FG"; marker="  ${label}"
        fi
        put_text "$((row + i*2))" "$ix" "$inner" "$(center_text "$marker" "$inner")" "$col"
    done

    local cntk=0 cnto=0
    [ "${ARCHIVE_KAP1:-0}" = "1" ] && cntk=$((cntk + 1))
    [ "${ARCHIVE_ORT_DESKTOPCITY:-0}" = "1" ] && cnto=$((cnto + 1))
    put_text "$((py + ph - 4))" "$ix" "$inner" \
        "$(center_text "Freigeschaltet: ${cntk} Kapitel · ${cnto} Orte" "$inner")" "$DIM"
    put_text "$((py + ph - 2))" "$ix" "$inner" \
        "$(center_text '↑/↓ wählen  ·  Enter öffnen  ·  Esc/Q zurück' "$inner")" "$MENU_C"
}

archive_screen() {
    play_sound select
    printf '%s' "$UI_BG"; clear
    local sel=0
    while true; do
        archive_draw_menu "$sel"
        read_key_t "" || break
        case "$LAST_KEY" in
            $'\x1b[A'|$'\x1bOA') sel=$((sel - 1)); [ "$sel" -lt 0 ] && sel=2 ;;
            $'\x1b[B'|$'\x1bOB') sel=$((sel + 1)); [ "$sel" -gt 2 ] && sel=0 ;;
            $'\n'|$'\r'|'')
                if [ "$sel" -eq 0 ]; then
                    archive_chapter_view
                    printf '%s' "$UI_BG"; clear
                elif [ "$sel" -eq 1 ]; then
                    archive_orte_view
                    printf '%s' "$UI_BG"; clear
                else
                    break
                fi
                ;;
            $'\x1b'|q|Q) break ;;
        esac
    done
    FIRST_RENDER=1
}

# --- Befehl ----------------------------------------------------------
builtin_archive() {
    if ! knows archive; then
        play_sound error
        OUT+=("»archive« …? Diesen Befehl kenne ich nicht.")
        return
    fi
    archive_screen
}
