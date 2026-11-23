# ============================================================
#  TerminalHero - Startbildschirm: Sound
#
#  Erzeugt fehlende Sounds einmalig per Python (wave) und spielt sie
#  asynchron mit aplay ab. Ergänzt die Sounds aus assets/sounds/.
# ============================================================

SOUND_DIR="$PROJ_DIR/assets/sounds"
SOUND_ENABLED=1
command -v aplay >/dev/null 2>&1 || SOUND_ENABLED=0
[ "${TH_SOUND:-1}" = "0" ] && SOUND_ENABLED=0

ensure_sounds() {
    [ "$SOUND_ENABLED" = "1" ] || return 0
    mkdir -p "$SOUND_DIR" 2>/dev/null
    local names="boot type move select intro alert online error cmd_cd cmd_cat cmd_touch" n missing=0
    for n in $names; do [ -f "$SOUND_DIR/$n.wav" ] || missing=1; done
    [ "$missing" -eq 0 ] && return 0
    command -v python3 >/dev/null 2>&1 || return 0

    python3 - "$SOUND_DIR" <<'PYEOF'
import wave, struct, math, sys, os
d = sys.argv[1]
sr = 44100

def wav(name, samples):
    path = os.path.join(d, name)
    with wave.open(path, 'w') as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(sr)
        f.writeframes(b''.join(struct.pack('<h', max(-32767, min(32767, int(s * 32767)))) for s in samples))

def tone(freq, dur, vol=0.4, shape='sine', fade=0.01):
    n = int(sr * dur); out = []
    for i in range(n):
        t = i / sr
        ph = 2 * math.pi * freq * t
        if shape == 'square':  v = 1.0 if math.sin(ph) >= 0 else -1.0
        elif shape == 'saw':   v = 2 * (freq * t - math.floor(0.5 + freq * t))
        else:                  v = math.sin(ph)
        env = min(1.0, t / fade if fade > 0 else 1.0, (dur - t) / fade if fade > 0 else 1.0)
        out.append(v * vol * max(0.0, env))
    return out

def sweep(f0, f1, dur, vol=0.35):
    n = int(sr * dur); out = []
    for i in range(n):
        t = i / sr; f = f0 + (f1 - f0) * (t / dur)
        env = min(1.0, t / 0.02, (dur - t) / 0.05)
        out.append(math.sin(2 * math.pi * f * t) * vol * max(0.0, env))
    return out

def silence(dur): return [0.0] * int(sr * dur)

def mix(a, b):
    n = max(len(a), len(b)); r = [0.0] * n
    for i in range(n):
        r[i] = (a[i] if i < len(a) else 0.0) + (b[i] if i < len(b) else 0.0)
    return r

def cat(*parts):
    r = []
    for p in parts: r += p
    return r

wav('boot.wav',   cat(tone(523,0.12,.35), tone(659,0.12,.35), tone(784,0.12,.35), tone(1047,0.40,.40)))
wav('type.wav',   tone(1800,0.02,.22, fade=0.004))
wav('move.wav',   tone(900,0.05,.28, fade=0.006))
wav('select.wav', cat(tone(880,0.08,.34), tone(1320,0.12,.34)))
wav('intro.wav',  mix(tone(110,4.0,.20, fade=0.4), tone(165,4.0,.14, fade=0.4)))
wav('alert.wav',  mix(tone(220,0.70,.30,'square', fade=0.02), tone(233,0.70,.24,'square', fade=0.02)))
wav('online.wav', sweep(220,1760,0.8,.34))
wav('error.wav',  tone(120,0.30,.34,'square', fade=0.01))
wav('cmd_cd.wav',    tone(660,0.050,.16, fade=0.008))
wav('cmd_cat.wav',   tone(1320,0.035,.13, fade=0.006))
wav('cmd_touch.wav', cat(tone(880,0.030,.14, fade=0.006), silence(0.005), tone(1175,0.035,.12, fade=0.006)))
PYEOF
}
play_sound() {
    [ "$SOUND_ENABLED" = "1" ] || return 0
    local f="$SOUND_DIR/$1.wav"
    [ -f "$f" ] || return 0
    aplay -q "$f" >/dev/null 2>&1 &
}
