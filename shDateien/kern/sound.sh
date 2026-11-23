# ============================================================
#  TerminalHero - Sound
#
#  Kurze, dezente Rückmeldungen für häufige Befehle. play_sound <name>
#  spielt assets/sounds/<name>.wav (asynchron). PROJ_DIR muss gesetzt sein.
# ============================================================

SOUND_DIR_="$PROJ_DIR/assets/sounds"
SOUND_ENABLED="${TERMINALHERO_SOUND:-${TH_SOUND:-1}}"
command -v aplay >/dev/null 2>&1 || SOUND_ENABLED=0
[ "${TH_SOUND:-1}" = "0" ] && SOUND_ENABLED=0

play_sound() {
    [ "$SOUND_ENABLED" = "1" ] || return 0
    local f="$SOUND_DIR_/$1.wav"
    [ -f "$f" ] || return 0
    aplay -q "$f" >/dev/null 2>&1 &
}
