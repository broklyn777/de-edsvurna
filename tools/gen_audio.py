#!/usr/bin/env python3
"""Komponerar musiken och bygger handlingsljuden till assets/audio/ (ogg Vorbis).

Allt är egenkomponerat och syntetiserat här, utom de inspelade träffarna som blandas in
från Kenneys CC0-paket (RPG Audio, Impact Sounds, Interface Sounds). Mappningen till spelet:
docs/ljud.md. Källor och licenser: ASSETS_LICENSE.md.

Kräver numpy och soundfile (libsndfile med Vorbis):
    python3 -m venv /tmp/venv && /tmp/venv/bin/pip install numpy soundfile
    /tmp/venv/bin/python tools/gen_audio.py <mapp med uppackade Kenney-zip>

Musiken renderas längre än loopen och svansen viks tillbaka till början, så att efterklangen
fortsätter över loopgränsen och loopen blir sömlös.
"""
import glob
import os
import sys

import numpy as np
import soundfile as sf

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")
KENNEY = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/Downloads/kenney")
MSR = 22050   # musik
ASR = 16000   # ambiens (mörkt och lågt, behöver inte mer; håller APK:n under gränsen)
MQ = 0.05     # Vorbis-kvalitet för musik och ambiens (lägsta som låter rent; lägre blir större i libsndfile)
SQ = 0.1      # handlingsljud och menyljud
XSR = 32000   # handlingsljud
rng = np.random.default_rng(17)

A4 = 440.0
NOTES = {"C": -9, "C#": -8, "Db": -8, "D": -7, "D#": -6, "Eb": -6, "E": -5, "F": -4, "F#": -3,
         "Gb": -3, "G": -2, "G#": -1, "Ab": -1, "A": 0, "A#": 1, "Bb": 1, "B": 2}


def hz(name):
    """'D3' -> frekvens."""
    pitch, octave = name[:-1], int(name[-1])
    return A4 * 2 ** ((NOTES[pitch] + 12 * (octave - 4)) / 12)


# ---------------------------------------------------------------- byggstenar

def env_adsr(n, sr, a=0.01, d=0.1, s=0.7, r=0.2):
    t = np.arange(n) / sr
    dur = n / sr
    e = np.where(t < a, t / max(a, 1e-6), s + (1 - s) * np.exp(-(t - a) / max(d, 1e-6)))
    rel = np.clip((dur - t) / max(r, 1e-6), 0, 1)
    return e * rel


def additive(freq, dur, sr, partials, decay=None, vib=0.0, vib_rate=5.0, detune=0.0, phase_rand=True):
    """Summa av övertoner. partials = [(multipel, amplitud)], decay = sekunder per deltons halvering
    (högre deltoner klingar av fortare, som en sträng)."""
    n = int(dur * sr)
    t = np.arange(n) / sr
    f = freq * (1 + vib * np.sin(2 * np.pi * vib_rate * t + rng.uniform(0, 6)))
    ph = 2 * np.pi * np.cumsum(f) / sr
    out = np.zeros(n)
    for mult, amp in partials:
        p0 = rng.uniform(0, 2 * np.pi) if phase_rand else 0
        part = amp * np.sin(ph * mult * (1 + detune * rng.uniform(-1, 1)) + p0)
        if decay:
            part *= np.exp(-t * mult / decay)
        out += part
    return out


def string_partials(n=12, bright=1.0):
    return [(k, (1 / k) * bright ** (k - 1)) for k in range(1, n + 1)]


def organ_partials():
    return [(1, 1.0), (2, 0.7), (3, 0.35), (4, 0.4), (6, 0.15), (8, 0.18), (0.5, 0.5)]


def vowel_partials(f0, formants=((730, 90), (1090, 110), (2440, 160))):
    """Kör ('aah'): deltoner viktade efter formanter."""
    parts = []
    for k in range(1, 40):
        fk = f0 * k
        if fk > 4000:
            break
        g = sum(np.exp(-((fk - fc) / bw) ** 2 / 2) * (1.0 if i == 0 else 0.6 / i)
                for i, (fc, bw) in enumerate(formants))
        parts.append((k, 0.15 / k + g))
    return parts


def pluck(freq, dur, sr, bright=0.7):
    n = int(dur * sr)
    x = additive(freq, dur, sr, string_partials(10, bright), decay=1.6 / (1 + freq / 600))
    return x * env_adsr(n, sr, 0.003, 0.4, 0.6, 0.05)


def bell(freq, dur, sr, amp=1.0):
    n = int(dur * sr)
    t = np.arange(n) / sr
    out = np.zeros(n)
    for ratio, a, dec in [(0.5, 0.5, 2.5), (1, 1, 2.0), (1.19, 0.4, 1.4), (2.0, 0.5, 1.0),
                          (2.76, 0.35, 0.7), (5.4, 0.2, 0.35), (8.93, 0.1, 0.2)]:
        out += a * np.sin(2 * np.pi * freq * ratio * t) * np.exp(-t / dec * 2.5 / max(dur, 1))
    return amp * out * np.minimum(1, t / 0.002)


def noise(n):
    return rng.uniform(-1, 1, n)


def lowpass(x, cutoff, sr):
    """Enpolsfilter i frekvensplanet (snabbt för långa buffertar)."""
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / sr)
    X *= 1 / np.sqrt(1 + (f / cutoff) ** 2) ** 2
    return np.fft.irfft(X, len(x))


def bandpass(x, lo, hi, sr):
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / sr)
    X *= 1 / np.sqrt(1 + (f / hi) ** 4) * (1 - 1 / np.sqrt(1 + (f / lo) ** 4))
    return np.fft.irfft(X, len(x))


def sweep_noise(dur, sr, f0, f1, q=0.3, env=None):
    """Brus genom ett bandpass som glider från f0 till f1 (svischar, vindsus, eld)."""
    n = int(dur * sr)
    hop = 256
    out = np.zeros(n + hop * 2)
    src = noise(n + hop * 2)
    win = np.hanning(hop * 2)
    for i in range(0, n, hop):
        k = i / max(n, 1)
        fc = f0 * (f1 / f0) ** k
        seg = src[i:i + hop * 2] * win
        out[i:i + hop * 2] += bandpass(seg, fc * (1 - q), fc * (1 + q), sr)
    out = out[:n]
    if env is not None:
        out *= env
    return out / (np.max(np.abs(out)) + 1e-9)


def reverb(x, sr, seconds=2.5, wet=0.35, damp=3000, predelay=0.02):
    n = int(seconds * sr)
    t = np.arange(n) / sr
    ir = noise(n) * np.exp(-t * 6.9 / seconds)
    ir = lowpass(ir, damp, sr)
    ir[: int(predelay * sr)] = 0
    ir /= np.sqrt(np.sum(ir ** 2))
    m = len(x) + n
    size = 1 << (m - 1).bit_length()
    y = np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(ir, size), size)[:m]
    dry = np.concatenate([x, np.zeros(n)])
    return dry * (1 - wet * 0.5) + y * wet


def place(buf, x, at, sr, gain=1.0):
    i = int(at * sr)
    if i >= len(buf):
        return
    j = min(len(buf), i + len(x))
    buf[i:j] += x[: j - i] * gain


def normalize(x, peak=0.89):
    return x * (peak / (np.max(np.abs(x)) + 1e-9))


def fade(x, sr, fin=0.0, fout=0.0):
    x = x.copy()
    if fin > 0:
        k = int(fin * sr)
        x[:k] *= np.linspace(0, 1, k)
    if fout > 0:
        k = int(fout * sr)
        x[-k:] *= np.linspace(1, 0, k)
    return x


def fold_loop(x, loop_len):
    """Viker allt efter loopens slut tillbaka på början (sömlös loop med efterklang)."""
    y = x[:loop_len].copy()
    tail = x[loop_len:]
    while len(tail):
        k = min(len(tail), loop_len)
        y[:k] += tail[:k]
        tail = tail[k:]
    return y


def write(name, x, sr, quality=0.2):
    """quality 0..1 (Vorbis); lågt för musik och ambiens."""
    path = os.path.join(OUT, name)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    sf.write(path, x.astype(np.float32), sr, format="OGG", subtype="VORBIS",
             compression_level=1.0 - quality)
    print(f"{name:34s} {len(x) / sr:5.1f} s {os.path.getsize(path) / 1024:6.1f} KiB")


_kcache = {}


def kenney(name, sr=XSR):
    """Läser ett Kenney-ljud (mono, omsamplat)."""
    if name not in _kcache:
        hits = glob.glob(os.path.join(KENNEY, "**", name + ".ogg"), recursive=True)
        if not hits:
            raise SystemExit(f"hittar inte {name}.ogg under {KENNEY}")
        data, rate = sf.read(hits[0], always_2d=True)
        _kcache[name] = (data.mean(axis=1), rate)
    data, rate = _kcache[name]
    if rate != sr:
        data = resample(lowpass(data, sr * 0.42, rate), rate, sr)
    return data


def resample(x, rate, sr):
    n = int(len(x) * sr / rate)
    return np.interp(np.arange(n) * rate / sr, np.arange(len(x)), x)


## k_*-mappar som inte exporteras (export_presets.cfg) och därför lämnas orörda.
K_UNUSED = {"k_bone_crack", "k_interrupt", "k_kick", "k_queued", "k_shield_slam"}


def thump(dur, sr, f0=90, f1=40, amp=1.0):
    n = int(dur * sr)
    t = np.arange(n) / sr
    f = f1 + (f0 - f1) * np.exp(-t * 25)
    return amp * np.sin(2 * np.pi * np.cumsum(f) / sr) * np.exp(-t * 9)


def timpani(freq, dur, sr, amp=1.0):
    n = int(dur * sr)
    t = np.arange(n) / sr
    body = additive(freq, dur, sr, [(1, 1), (1.5, 0.5), (1.98, 0.3), (2.44, 0.15)], decay=0.9)
    body *= np.exp(-t * 2.5)
    hit = lowpass(noise(n), 900, sr) * np.exp(-t * 40) * 1.5
    return amp * (body + hit + thump(dur, sr, freq * 1.6, freq, 0.8))


def mix(length, sr, *parts):
    buf = np.zeros(int(length * sr))
    for x, at, g in parts:
        place(buf, x, at, sr, g)
    return buf


# ---------------------------------------------------------------- musik

def chord_pad(buf, chord, at, dur, sr, gain, partials, vib=0.003, attack=1.2, release=1.5, oct_shift=0):
    for note in chord:
        f = hz(note) * 2 ** oct_shift
        for det in (-0.004, 0.004):
            x = additive(f * (1 + det), dur + release, sr, partials, vib=vib, vib_rate=rng.uniform(4, 5.5))
            x *= env_adsr(len(x), sr, attack, 1.0, 0.85, release)
            place(buf, x, at, sr, gain / len(chord))


def music_base():
    """Basen: lugn och hoppfull. D-dur, harpa, stråkmatta och en flöjtlik melodi."""
    bpm, bars = 72, 8
    beat = 60 / bpm
    loop = bars * 4 * beat
    sr = MSR
    buf = np.zeros(int((loop + 4) * sr))
    prog = [["D3", "F#3", "A3"], ["A2", "C#3", "E3"], ["B2", "D3", "F#3"], ["G2", "B2", "D3"],
            ["G2", "B2", "D3"], ["D3", "F#3", "A3"], ["E3", "G3", "B3"], ["A2", "C#3", "E3"]]
    bass = ["D2", "C#2", "B1", "G1", "G1", "F#2", "E2", "A1"]
    soft = string_partials(8, 0.55)
    for b, ch in enumerate(prog):
        t0 = b * 4 * beat
        chord_pad(buf, ch, t0, 4 * beat, sr, 0.22, soft)
        x = additive(hz(bass[b]), 4 * beat + 1, sr, string_partials(6, 0.4))
        place(buf, x * env_adsr(len(x), sr, 0.3, 1, 0.8, 1.0), t0, sr, 0.18)
        # harpa: arpeggio upp och ned i åttondelar
        notes = [hz(ch[0]) * 2, hz(ch[1]) * 2, hz(ch[2]) * 2, hz(ch[0]) * 4,
                 hz(ch[2]) * 2, hz(ch[1]) * 2, hz(ch[0]) * 2, hz(ch[2])]
        for i, f in enumerate(notes):
            place(buf, pluck(f, 2.0, sr, 0.6), t0 + i * beat / 2, sr, 0.16)
    # melodi (fyra takter fråga, fyra svar)
    mel = [("A4", 0, 2), ("F#4", 2, 1), ("E4", 3, 1), ("C#4", 4, 3), ("E4", 7, 1),
           ("D4", 8, 1.5), ("F#4", 9.5, 0.5), ("B4", 10, 2), ("A4", 12, 4),
           ("B4", 16, 2), ("D5", 18, 2), ("A4", 20, 3), ("F#4", 23, 1),
           ("G4", 24, 2), ("B4", 26, 1), ("A4", 27, 1), ("E4", 28, 3), ("C#4", 31, 1)]
    flute = [(1, 1), (2, 0.25), (3, 0.12), (4, 0.04)]
    for note, start, length in mel:
        d = length * beat
        x = additive(hz(note), d + 0.4, sr, flute, vib=0.006, vib_rate=5.2)
        breath = lowpass(noise(len(x)), 2500, sr) * 0.04
        x = (x + breath) * env_adsr(len(x), sr, 0.08, 0.5, 0.8, 0.35)
        place(buf, x, start * beat, sr, 0.13)
    buf = reverb(buf, sr, 2.8, 0.4)
    return fold_loop(buf, int(loop * sr)), sr


def music_crypt():
    """Kryptan: dov. D-moll, låg bordun, mörka stråkar, gravklocka och avlägsen puka."""
    bpm, bars = 60, 8
    beat = 60 / bpm
    loop = bars * 4 * beat
    sr = MSR
    buf = np.zeros(int((loop + 5) * sr))
    prog = [["D3", "F3", "A3"], ["D3", "F3", "A3"], ["Bb2", "D3", "F3"], ["G2", "Bb2", "D3"],
            ["D3", "F3", "A3"], ["Bb2", "D3", "G3"], ["G2", "Bb2", "E3"], ["A2", "C#3", "E3"]]
    dark = string_partials(10, 0.5)
    drone = additive(hz("D1"), loop + 5, sr, [(1, 1), (2, 0.6), (3, 0.3), (1.5, 0.25)], vib=0.002, vib_rate=0.3)
    drone *= 0.85 + 0.15 * np.sin(2 * np.pi * np.arange(len(drone)) / sr / loop * 4)
    place(buf, fade(drone, sr, 5, 5), 0, sr, 0.13)  # överlappar sig själv vid loopen
    for b, ch in enumerate(prog):
        t0 = b * 4 * beat
        chord_pad(buf, ch, t0, 4 * beat, sr, 0.24, dark, attack=1.8, release=2.0)
        if b % 2 == 0:
            place(buf, timpani(hz("D2"), 2.5, sr), t0, sr, 0.22)
            place(buf, timpani(hz("D2"), 2.5, sr), t0 + 2.5 * beat, sr, 0.10)
        if b in (0, 4):
            place(buf, bell(hz("D4"), 5, sr), t0 + beat, sr, 0.12)
        if b in (3, 7):
            place(buf, bell(hz("A3"), 5, sr), t0 + 2 * beat, sr, 0.09)
    # cellomelodi
    mel = [("A3", 0, 3), ("F3", 3, 1), ("E3", 4, 2), ("D3", 6, 2), ("F3", 8, 2), ("G3", 10, 1),
           ("A3", 11, 1), ("Bb3", 12, 4), ("A3", 16, 3), ("C4", 19, 1), ("Bb3", 20, 2),
           ("G3", 22, 2), ("E3", 24, 3), ("G3", 27, 1), ("C#3", 28, 4)]
    cello = string_partials(14, 0.75)
    for note, start, length in mel:
        d = length * beat
        x = additive(hz(note), d + 0.6, sr, cello, vib=0.005, vib_rate=5.0)
        x = lowpass(x, 1800, sr) * env_adsr(len(x), sr, 0.25, 0.6, 0.8, 0.5)
        place(buf, x, start * beat, sr, 0.16)
    buf = reverb(buf, sr, 3.5, 0.5, damp=2000)
    return fold_loop(buf, int(loop * sr)), sr


def music_chapel():
    """Kapellet: sakralt och förvridet. Orgel och kör i E-frygisk, med en tritonus och ett
    långsamt vridet tonhöjdssvaj som ett gammalt band."""
    bpm, bars = 56, 8
    beat = 60 / bpm
    loop = bars * 4 * beat
    sr = MSR
    n = int((loop + 5) * sr)
    buf = np.zeros(n)
    prog = [["E3", "G3", "B3"], ["F3", "A3", "C4"], ["E3", "G3", "B3"], ["D3", "F3", "A#3"],
            ["E3", "G3", "B3"], ["C3", "E3", "G3"], ["F3", "A3", "C4"], ["B2", "D3", "F3"]]
    org = organ_partials()
    for b, ch in enumerate(prog):
        t0 = b * 4 * beat
        chord_pad(buf, ch, t0, 4 * beat, sr, 0.30, org, vib=0.0, attack=0.25, release=1.2)
        place(buf, additive(hz(ch[0]) / 2, 4 * beat + 1, sr, org) *
              env_adsr(int((4 * beat + 1) * sr), sr, 0.2, 1, 0.9, 1.0), t0, sr, 0.10)
        if b % 4 == 0:
            place(buf, bell(hz("E3"), 6, sr), t0, sr, 0.16)
        if b == 7:
            place(buf, bell(hz("A#3"), 6, sr), t0 + 2 * beat, sr, 0.12)
    # kör: långa toner, en halvton som gnisslar mot orgeln
    choir = [("B3", 0, 8), ("C4", 8, 8), ("B3", 16, 6), ("A#3", 22, 2), ("G3", 24, 4), ("F3", 28, 4)]
    for note, start, length in choir:
        f = hz(note)
        d = length * beat
        for det in (-0.006, 0, 0.007):
            x = additive(f * (1 + det), d + 1.5, sr, vowel_partials(f), vib=0.009, vib_rate=4.6)
            x *= env_adsr(len(x), sr, 1.0, 1, 0.9, 1.5)
            place(buf, x, start * beat, sr, 0.05)
    buf = reverb(buf, sr, 4.5, 0.6, damp=2500, predelay=0.04)
    y = fold_loop(buf, int(loop * sr))
    # vridet band: loopen läses med svajande hastighet; svajet går ett helt antal varv per loop
    m = len(y)
    t = np.arange(m)
    wow = 0.004 * np.sin(2 * np.pi * 2 * t / m) + 0.0015 * np.sin(2 * np.pi * 6 * t / m)
    pos = np.concatenate([[0], np.cumsum(1 + wow)[:-1]])
    pos *= m / (pos[-1] + 1 + wow[-1])
    return np.interp(pos, np.arange(m + 1), np.concatenate([y, y[:1]])), sr


def music_boss():
    """Boss: intensiv. C-moll i 132 bpm, ostinato i låga stråkar, pukor, mässingsstötar och kör."""
    bpm, bars = 132, 16
    beat = 60 / bpm
    loop = bars * 4 * beat
    sr = MSR
    buf = np.zeros(int((loop + 3) * sr))
    prog = ["Cm", "Cm", "Ab", "Ab", "Fm", "Fm", "G", "G", "Cm", "Cm", "Db", "Db", "Bb", "Bb", "G", "G"]
    chords = {"Cm": ["C3", "Eb3", "G3"], "Ab": ["Ab2", "C3", "Eb3"], "Fm": ["F2", "Ab2", "C3"],
              "G": ["G2", "B2", "D3"], "Db": ["Db3", "F3", "Ab3"], "Bb": ["Bb2", "D3", "F3"]}
    roots = {"Cm": "C2", "Ab": "Ab1", "Fm": "F1", "G": "G1", "Db": "Db2", "Bb": "Bb1"}
    low = string_partials(12, 0.8)
    brass = string_partials(16, 0.9)
    for b, name in enumerate(prog):
        t0 = b * 4 * beat
        root = hz(roots[name])
        # ostinato: åttondelar, grundton–grundton–oktav
        for i in range(8):
            f = root * (2 if i in (2, 5) else 1) * 2
            x = additive(f, beat * 0.5, sr, low)
            x *= env_adsr(len(x), sr, 0.005, 0.08, 0.5, 0.05)
            place(buf, x, t0 + i * beat / 2, sr, 0.20 if i % 2 == 0 else 0.13)
        # pukor
        for at, g in [(0, 0.35), (1.5, 0.18), (2, 0.25), (3.5, 0.2)]:
            place(buf, timpani(root * 2, 1.0, sr), t0 + at * beat, sr, g)
        if b % 2 == 0:
            for note in chords[name]:
                x = additive(hz(note), beat * 1.2, sr, brass)
                x = lowpass(x, 2500, sr) * env_adsr(len(x), sr, 0.02, 0.15, 0.5, 0.3)
                place(buf, x, t0, sr, 0.10)
                place(buf, x, t0 + 2.5 * beat, sr, 0.07)
        chord_pad(buf, chords[name][:2], t0, 4 * beat, sr, 0.06, vowel_partials(hz(chords[name][1]) * 2),
                  attack=0.6, release=0.6, oct_shift=1)
    # högt stråkmotiv andra halvan
    mel = [("G4", 32, 1), ("Ab4", 33, 1), ("G4", 34, 1), ("F4", 35, 1), ("Eb4", 36, 2), ("D4", 38, 2),
           ("Db5", 40, 3), ("C5", 43, 1), ("Bb4", 44, 2), ("Ab4", 46, 2),
           ("F4", 48, 2), ("D5", 50, 2), ("C5", 52, 3), ("Bb4", 55, 1), ("B4", 56, 4), ("D5", 60, 4)]
    for note, start, length in mel:
        d = length * beat
        x = additive(hz(note), d + 0.3, sr, string_partials(10, 0.7), vib=0.006, vib_rate=6)
        x *= env_adsr(len(x), sr, 0.05, 0.3, 0.8, 0.25)
        place(buf, x, start * beat, sr, 0.12)
    buf = reverb(buf, sr, 2.0, 0.3)
    return fold_loop(buf, int(loop * sr)), sr


# ---------------------------------------------------------------- ambiens

def ambience_chapel():
    """Kapellets stämning: avlägsen orgelton, viskningar, knarr och droppar i ett stort rum."""
    sr = ASR
    loop = 16.0
    n = int((loop + 5) * sr)
    buf = np.zeros(n)
    t = np.arange(n) / sr
    org = additive(hz("E2"), loop + 5, sr, organ_partials(), vib=0.001, vib_rate=0.2)
    org += 0.6 * additive(hz("A#2"), loop + 5, sr, organ_partials())
    org *= 0.5 + 0.5 * np.sin(2 * np.pi * t / loop) ** 2
    place(buf, fade(lowpass(org, 600, sr), sr, 5, 5), 0, sr, 0.06)
    wind = lowpass(noise(n), 400, sr) * (0.6 + 0.4 * np.sin(2 * np.pi * t / loop * 2))
    place(buf, fade(wind, sr, 5, 5), 0, sr, 0.05)
    # viskningar: brus genom vokalformanter med stavelserytm
    for start in (1.5, 6.0, 10.4, 13.6):
        d = rng.uniform(1.2, 2.2)
        m = int(d * sr)
        tt = np.arange(m) / sr
        syll = np.clip(np.sin(2 * np.pi * rng.uniform(5, 7) * tt) + 0.3, 0, None) ** 1.5
        x = sum(bandpass(noise(m), fc * 0.85, fc * 1.15, sr) for fc in rng.choice([500, 900, 1500, 2600, 3300], 3))
        x *= syll * np.hanning(m)
        place(buf, normalize(x), start, sr, 0.10)
    for start in (4.2, 12.0):
        place(buf, kenney("creak%d" % rng.integers(1, 4), sr), start, sr, 0.18)
    for start in rng.uniform(0, loop, 5):
        place(buf, bell(rng.uniform(1800, 2600), 0.3, sr), start, sr, 0.05)  # droppar
    buf = reverb(buf, sr, 5.0, 0.7, damp=2200, predelay=0.05)
    return fold_loop(buf, int(loop * sr)), sr


# ---------------------------------------------------------------- handlingsljud

def swish(dur=0.22, f0=600, f1=2400, amp=1.0):
    n = int(dur * XSR)
    e = np.sin(np.linspace(0, np.pi, n)) ** 2
    return amp * sweep_noise(dur, XSR, f0, f1, 0.5, e)


def attack_sword(v):
    hits = ["impactMetal_medium_00%d" % v, "impactPlate_medium_00%d" % (v + 1)]
    return normalize(mix(0.7, XSR, (kenney("drawKnife%d" % (v + 1)), 0, 0.35), (swish(0.2, 900, 3200), 0.0, 0.5),
                         (kenney("knifeSlice" if v != 1 else "knifeSlice2"), 0.12, 0.7),
                         (kenney(hits[0]), 0.16, 0.8), (thump(0.25, XSR, 140, 60), 0.16, 0.6)))


def attack_axe(v):
    return normalize(mix(0.8, XSR, (swish(0.28, 300, 1400), 0.0, 0.7), (kenney("chop"), 0.2, 0.9),
                         (kenney("impactWood_heavy_00%d" % v), 0.2, 0.9),
                         (kenney("impactPunch_heavy_00%d" % v), 0.21, 0.6), (thump(0.35, XSR, 110, 40), 0.2, 0.9)))


def attack_blunt(v):
    """Stav, klubba och spikklubba."""
    return normalize(mix(0.7, XSR, (swish(0.26, 250, 1100), 0.0, 0.6),
                         (kenney("impactPunch_medium_00%d" % v), 0.18, 0.8),
                         (kenney("impactWood_medium_00%d" % v), 0.18, 0.6), (thump(0.3, XSR, 120, 45), 0.18, 0.8)))


def bow_shot(v):
    f = [110, 98, 123][v]
    n = int(0.4 * XSR)
    tt = np.arange(n) / XSR
    twang = additive(f, 0.4, XSR, string_partials(12, 0.85), decay=0.3) * np.exp(-tt * 9)
    twang *= 1 + 0.1 * np.sin(2 * np.pi * 18 * tt)
    return normalize(mix(0.55, XSR, (kenney("beltHandle%d" % (v % 2 + 1)), 0, 0.3), (twang, 0.05, 1.0),
                         (swish(0.25, 2000, 4500), 0.07, 0.45)))


def arrow_hit(v):
    return normalize(mix(0.4, XSR, (kenney("impactWood_light_00%d" % v), 0, 0.8),
                         (kenney("impactSoft_medium_00%d" % v), 0, 0.6), (thump(0.15, XSR, 200, 90), 0, 0.5)))


def spell_holy(v):
    """Helig: klockackord som stiger, kör som sväller och glitter."""
    root = [hz("D5"), hz("E5")][v]
    buf = np.zeros(int(1.6 * XSR))
    for i, r in enumerate([1, 1.25, 1.5, 2]):
        place(buf, bell(root * r, 1.3, XSR), i * 0.07, XSR, 0.25)
    for det in (-0.005, 0.005):
        x = additive(root / 2 * (1 + det), 1.4, XSR, vowel_partials(root / 2, ((800, 120), (1150, 140), (2900, 200))),
                     vib=0.008)
        place(buf, x * env_adsr(len(x), XSR, 0.35, 1, 0.8, 0.6), 0, XSR, 0.25)
    sparkle = bandpass(noise(len(buf)), 5000, 9000, XSR) * np.exp(-np.arange(len(buf)) / XSR * 3)
    buf += sparkle * 0.25
    return normalize(reverb(buf, XSR, 1.5, 0.4)[: int(2.0 * XSR)])


def spell_fire(v):
    """Eld: svällande brus som dånar upp, med sprak."""
    d = 1.0
    n = int(d * XSR)
    e = np.minimum(1, np.arange(n) / XSR / 0.25) * np.exp(-np.maximum(0, np.arange(n) / XSR - 0.3) * 4)
    roar = sweep_noise(d, XSR, 300 + 100 * v, 1200, 0.8, e)
    crackle = np.zeros(n)
    for at in rng.uniform(0.05, 0.8, 18):
        place(crackle, noise(int(0.004 * XSR)) * rng.uniform(0.3, 1), at, XSR)
    low = lowpass(noise(n), 150, XSR) * e * 4
    return normalize(roar + crackle * 0.5 + low * 0.6)


def fire_hit(v):
    n = int(0.6 * XSR)
    e = np.exp(-np.arange(n) / XSR * 7)
    return normalize(sweep_noise(0.6, XSR, 1500, 300, 0.9, e) + np.pad(thump(0.4, XSR, 100, 40), (0, n - int(0.4 * XSR))) * 0.9
                     + lowpass(noise(n), 300, XSR) * e * 2)


def spell_shadow(v):
    """Skugga: bakvänd svällning, dissonant låg bordun och viskande brus."""
    d = 1.3
    n = int(d * XSR)
    tt = np.arange(n) / XSR
    swell = (tt / d) ** 2
    base = hz(["F2", "E2"][v])
    drone = sum(additive(base * r, d, XSR, string_partials(8, 0.6), vib=0.01, vib_rate=3) for r in (1, 1.06, 1.414))
    whisper = bandpass(noise(n), 900, 3500, XSR) * (0.5 + 0.5 * np.sin(2 * np.pi * 7 * tt))
    x = (drone * 0.5 + whisper * 0.8) * swell
    x[-int(0.05 * XSR):] *= np.linspace(1, 0, int(0.05 * XSR))
    return normalize(reverb(x, XSR, 1.2, 0.35)[: int(1.6 * XSR)])


def shadow_hit(v):
    n = int(0.7 * XSR)
    tt = np.arange(n) / XSR
    x = additive(hz("C2"), 0.7, XSR, [(1, 1), (1.41, 0.7), (2.1, 0.4)]) * np.exp(-tt * 5)
    x += lowpass(noise(n), 700, XSR) * np.exp(-tt * 12) * 1.5
    return normalize(reverb(x + thump(0.7, XSR, 80, 35) * 0.8, XSR, 1.0, 0.3)[: int(1.0 * XSR)])


def spell_nature(v):
    """Natur: träflöjtsdrill, lövprassel och ett mjukt träknäpp."""
    buf = np.zeros(int(1.1 * XSR))
    notes = [hz("A5"), hz("B5"), hz("A5"), hz("D6"), hz("E6")] if v == 0 else [hz("G5"), hz("A5"), hz("C6"), hz("D6"), hz("G6")]
    for i, f in enumerate(notes):
        x = additive(f, 0.25, XSR, [(1, 1), (2, 0.15), (3, 0.05)], vib=0.01)
        place(buf, x * env_adsr(len(x), XSR, 0.01, 0.2, 0.6, 0.08), i * 0.08, XSR, 0.3)
    rustle = bandpass(noise(len(buf)), 2500, 7000, XSR)
    rustle *= np.abs(np.sin(np.linspace(0, 9 * np.pi, len(buf)))) ** 3 * np.hanning(len(buf))
    buf += rustle * 0.35
    place(buf, kenney("impactWood_light_00%d" % (v + 2)), 0.45, XSR, 0.4)
    return normalize(reverb(buf, XSR, 0.9, 0.25)[: int(1.4 * XSR)])


def nature_hit(v):
    return normalize(mix(0.6, XSR, (kenney("impactPlank_medium_00%d" % v), 0, 0.9),
                         (bandpass(noise(int(0.4 * XSR)), 2000, 6000, XSR) * np.hanning(int(0.4 * XSR)), 0, 0.3)))


def heal(v):
    """Helning: harpa som stiger i dur, med ett ljust skimmer."""
    buf = np.zeros(int(1.5 * XSR))
    notes = ["C5", "E5", "G5", "C6"] if v == 0 else ["D5", "F#5", "A5", "D6"]
    for i, note in enumerate(notes):
        place(buf, pluck(hz(note), 1.2, XSR, 0.5), i * 0.08, XSR, 0.4)
    shimmer = additive(hz(notes[-1]) * 2, 1.2, XSR, [(1, 1), (1.5, 0.4)], vib=0.01, vib_rate=7)
    place(buf, shimmer * env_adsr(len(shimmer), XSR, 0.3, 0.5, 0.6, 0.6), 0.2, XSR, 0.08)
    return normalize(reverb(buf, XSR, 1.4, 0.4)[: int(1.9 * XSR)])


def defend(v):
    """Försvara: läder och spänne, sköld som lyfts och en kort metallisk klang."""
    ring = additive(hz("E5"), 0.8, XSR, [(1, 1), (2.4, 0.5), (3.9, 0.3)], decay=0.8)
    ring *= np.exp(-np.arange(len(ring)) / XSR * 5)
    return normalize(mix(0.9, XSR, (kenney(["clothBelt", "clothBelt2"][v]), 0, 0.5),
                         (kenney("impactPlate_light_00%d" % (v + 1)), 0.12, 0.9),
                         (ring, 0.13, 0.2), (thump(0.3, XSR, 150, 70), 0.12, 0.6)))


def provoke(v):
    """Provocera: två slag med vapnet mot skölden och en kort, låg stridshorn-stöt."""
    horn = additive(hz(["D3", "C3"][v]), 0.8, XSR, string_partials(14, 0.85), vib=0.004)
    horn = lowpass(horn, 1400, XSR) * env_adsr(len(horn), XSR, 0.06, 0.3, 0.7, 0.25)
    return normalize(mix(1.1, XSR, (kenney("impactPlate_heavy_00%d" % v), 0, 0.9),
                         (kenney("impactPlate_heavy_00%d" % (v + 2)), 0.22, 1.0),
                         (thump(0.3, XSR, 120, 50), 0.22, 0.7), (horn, 0.32, 0.55)))


def trophy(rarity):
    """Troféfynd: stigande harpa och klockor; elit med fler toner, boss med full kadens."""
    seqs = {"common": ["G5", "C6", "E6"], "elite": ["E5", "G5", "C6", "E6", "G6"],
            "boss": ["C5", "E5", "G5", "C6", "E6", "G6", "C7"]}
    notes = seqs[rarity]
    step = 0.07
    buf = np.zeros(int((len(notes) * step + 2.0) * XSR))
    for i, note in enumerate(notes):
        place(buf, pluck(hz(note), 1.0, XSR, 0.6), i * step, XSR, 0.3)
        place(buf, bell(hz(note), 1.2, XSR), i * step, XSR, 0.1)
    end = len(notes) * step
    if rarity != "common":
        for note in (["C4", "E4", "G4"] if rarity == "elite" else ["C3", "G3", "C4", "E4", "G4"]):
            x = additive(hz(note), 1.6, XSR, string_partials(10, 0.7), vib=0.004)
            place(buf, x * env_adsr(len(x), XSR, 0.05, 0.6, 0.6, 0.8), end, XSR, 0.12)
    if rarity == "boss":
        place(buf, timpani(hz("C2"), 1.5, XSR), end, XSR, 0.5)
        place(buf, kenney("impactBell_heavy_000"), end, XSR, 0.25)
    sparkle = bandpass(noise(len(buf)), 6000, 10000, XSR) * np.exp(-np.arange(len(buf)) / XSR * 2.5)
    return normalize(reverb(buf + sparkle * 0.12, XSR, 1.6, 0.35)[: len(buf) + int(0.5 * XSR)])


def stinger(kind):
    """Elit (eller boss) dyker upp: låg mässingsstöt, pukvirvel och en klocka."""
    d = 2.2 if kind == "elite" else 3.2
    buf = np.zeros(int(d * XSR))
    roll_end = 0.5 if kind == "elite" else 0.9
    k = 0
    for at in np.arange(0, roll_end, 0.06):
        place(buf, timpani(hz("D2"), 0.5, XSR), at, XSR, 0.1 + 0.25 * at / roll_end)
        k += 1
    chord = ["D2", "A2", "D3", "F3"] if kind == "elite" else ["D2", "A2", "D3", "F3", "G#3"]
    for note in chord:
        x = additive(hz(note), d - roll_end, XSR, string_partials(16, 0.9), vib=0.003)
        x = lowpass(x, 1600, XSR) * env_adsr(len(x), XSR, 0.04, 0.5, 0.6, 1.0)
        place(buf, x, roll_end, XSR, 0.12)
    place(buf, timpani(hz("D2"), 1.5, XSR), roll_end, XSR, 0.6)
    place(buf, bell(hz("D4") if kind == "elite" else hz("G#3"), 2.0, XSR), roll_end, XSR, 0.2)
    return normalize(reverb(buf, XSR, 2.0, 0.4)[: int((d + 0.6) * XSR)])


def macro_nomatch():
    """Makrot passade inte: två dova trätoner nedåt, mjukt och inte larmande."""
    buf = np.zeros(int(0.45 * XSR))
    for i, note in enumerate(["E4", "B3"]):
        x = additive(hz(note), 0.2, XSR, [(1, 1), (3.9, 0.3), (9.2, 0.1)], decay=0.08)
        place(buf, x * np.exp(-np.arange(len(x)) / XSR * 18), i * 0.11, XSR, 0.6)
    return normalize(buf, 0.7)


def fanfare(win):
    """Seger: mässing och harpa i C-dur. Förlust: långsam moll-kadens med låg klocka."""
    if win:
        seq = [("C4", 0, 0.18), ("E4", 0.18, 0.18), ("G4", 0.36, 0.18), ("C5", 0.54, 1.4)]
        chord = ["C3", "G3", "C4", "E4"]
    else:
        seq = [("A3", 0, 0.5), ("F3", 0.5, 0.5), ("E3", 1.0, 0.5), ("D3", 1.5, 1.5)]
        chord = ["D3", "F3", "A3"]
    end = seq[-1][1]
    buf = np.zeros(int((end + 3.0) * XSR))
    for note, at, d in seq:
        x = additive(hz(note), d + 0.2, XSR, string_partials(14, 0.85 if win else 0.6), vib=0.005)
        x = lowpass(x, 2800 if win else 1500, XSR) * env_adsr(len(x), XSR, 0.03, 0.3, 0.75, 0.2)
        place(buf, x, at, XSR, 0.3)
    for note in chord:
        x = additive(hz(note), 2.2, XSR, string_partials(10, 0.7 if win else 0.5), vib=0.004)
        place(buf, x * env_adsr(len(x), XSR, 0.05, 0.8, 0.6, 1.2), end, XSR, 0.12)
    if win:
        for i, note in enumerate(["C5", "E5", "G5", "C6", "E6"]):
            place(buf, pluck(hz(note), 1.2, XSR), end + i * 0.05, XSR, 0.15)
        place(buf, timpani(hz("C2"), 1.5, XSR), end, XSR, 0.5)
    else:
        place(buf, bell(hz("D3"), 3.0, XSR), end, XSR, 0.3)
    return normalize(reverb(buf, XSR, 2.0, 0.4))


# ---------------------------------------------------------------- rumsögonblick (0.18)

def room_door():
    """Tung trädörr: knarrande gångjärn, dovt drag och en duns när den slår i stenväggen."""
    hinge = bandpass(kenney("creak2"), 300, 2500, XSR)
    draft = lowpass(noise(int(1.3 * XSR)), 500, XSR) * np.hanning(int(1.3 * XSR))
    return normalize(reverb(mix(1.6, XSR, (kenney("doorOpen_1"), 0, 0.7), (hinge, 0.05, 0.5), (draft, 0.1, 0.25),
                                (kenney("impactWood_heavy_002"), 1.0, 0.6), (thump(0.4, XSR, 90, 40), 1.0, 0.7)),
                            XSR, 1.2, 0.3)[: int(1.9 * XSR)])


def room_chest():
    """Kista: spännet släpper, locket knarrar upp och ett litet skimmer av skatten."""
    buf = mix(1.8, XSR, (kenney("metalLatch"), 0, 0.7), (kenney("creak1"), 0.18, 0.6),
              (kenney("impactWood_medium_001"), 0.7, 0.4), (kenney("handleCoins2"), 0.75, 0.35))
    for i, note in enumerate(["E6", "G#6", "B6"]):
        place(buf, bell(hz(note), 0.9, XSR), 0.8 + i * 0.06, XSR, 0.07)
    return normalize(reverb(buf, XSR, 1.0, 0.25)[: int(2.2 * XSR)])


def room_lock():
    """Hänglås: nyckeln vrids (klick, klick) och bygeln släpper med en tung metallklang."""
    ring = additive(hz("A5"), 0.6, XSR, [(1, 1), (2.7, 0.5), (5.1, 0.25)], decay=0.5)
    ring *= np.exp(-np.arange(len(ring)) / XSR * 7)
    return normalize(mix(1.0, XSR, (kenney("metalClick"), 0, 0.6), (kenney("metalClick"), 0.16, 0.5),
                         (kenney("metalLatch"), 0.34, 0.8), (ring, 0.36, 0.15),
                         (kenney("impactMetal_light_001"), 0.36, 0.5)))


# ---------------------------------------------------------------- huvudprogram

def main():
    os.makedirs(OUT, exist_ok=True)
    for name, fn in [("music_base", music_base), ("music_crypt", music_crypt),
                     ("music_chapel", music_chapel), ("music_boss", music_boss)]:
        x, sr = fn()
        write(f"music/{name}.ogg", normalize(x, 0.8), sr, MQ)
    x, sr = ambience_chapel()
    write("ambience_chapel/ambience_chapel.ogg", normalize(x, 0.7), sr, MQ)
    # kryptstämningen byggs av gen_sfx.py (16 s loop med korstoning), här som ogg i 16 kHz
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    sys.dont_write_bytecode = True
    import gen_sfx
    x = np.array(gen_sfx.crypt_ambience(16.0))
    x = resample(lowpass(x, 6000, gen_sfx.SR), gen_sfx.SR, ASR)
    write("ambience_crypt/ambience_crypt.ogg", normalize(x, 0.7), ASR, MQ)

    q = SQ
    for v in range(3):
        write(f"atk_sword/atk_sword_{v}.ogg", attack_sword(v), XSR, q)
        write(f"atk_axe/atk_axe_{v}.ogg", attack_axe(v), XSR, q)
        write(f"atk_blunt/atk_blunt_{v}.ogg", attack_blunt(v), XSR, q)
        write(f"bow_shot/bow_shot_{v}.ogg", bow_shot(v), XSR, q)
        write(f"arrow_hit/arrow_hit_{v}.ogg", arrow_hit(v), XSR, q)
    for v in range(2):
        for name, fn in [("spell_holy", spell_holy), ("spell_fire", spell_fire), ("fire_hit", fire_hit),
                         ("spell_shadow", spell_shadow), ("shadow_hit", shadow_hit),
                         ("spell_nature", spell_nature), ("nature_hit", nature_hit),
                         ("heal_light", heal), ("defend", defend), ("provoke", provoke)]:
            write(f"{name}/{name}_{v}.ogg", fn(v), XSR, q)
    for r in ("common", "elite", "boss"):
        write(f"trophy_{r}/trophy_{r}.ogg", trophy(r), XSR, q)
    write("elite_appears/elite_appears.ogg", stinger("elite"), XSR, q)
    write("boss_appears/boss_appears.ogg", stinger("boss"), XSR, q)
    write("macro_nomatch/macro_nomatch.ogg", macro_nomatch(), XSR, q)
    write("jingle_victory/jingle_victory.ogg", fanfare(True), XSR, q)
    write("jingle_defeat/jingle_defeat.ogg", fanfare(False), XSR, q)

    # rumsögonblicken i 0.18 (inte inkopplade): dörr, kista och hänglås
    write("room_door/room_door.ogg", room_door(), XSR, q)
    write("room_chest/room_chest.ogg", room_chest(), XSR, q)
    write("room_lock/room_lock.ogg", room_lock(), XSR, q)

    # Kenney-filerna i k_*- och ui_*-mapparna: mono, 32 kHz, låg kvalitet (originalen är stereo 44–48 kHz)
    for folder in sorted(os.listdir(OUT)):
        if folder.startswith("k_") and folder not in K_UNUSED:
            for f in sorted(os.listdir(os.path.join(OUT, folder))):
                if f.endswith(".ogg"):
                    write(f"{folder}/{f}", kenney(f[:-4]), XSR, q)
    ui = {"ui_tap": ["select_001", "select_002", "select_003"], "ui_back": ["back_001", "back_002"],
          "ui_confirm": ["confirmation_001", "confirmation_002"], "ui_toggle": ["toggle_001", "toggle_002"],
          "ui_page": ["bookFlip2", "bookFlip3"], "ui_coins": ["handleCoins2"],
          "ui_forge": ["impactMetal_heavy_000", "impactMetal_heavy_002", "impactMetal_heavy_004"],
          "ui_door": ["doorOpen_1"]}
    for folder, names in ui.items():  # menyljuden
        for nm in names:
            write(f"{folder}/{nm}.ogg", kenney(nm), XSR, q)


if __name__ == "__main__":
    main()
