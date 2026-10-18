#!/usr/bin/env python3
"""Syntetiserar spelets ljudeffekter till assets/audio/*.wav.

Platshållarljud tills riktiga ljud finns, men byggda för att kännas rätt:
korta attacker, tydlig tyngd i träffar och ljud som skiljer klasserna åt.

    python3 tools/gen_sfx.py
"""
import math
import os
import random
import struct
import wave

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
rng = random.Random(7)


def silence(dur):
    return [0.0] * int(SR * dur)


def tone(freq, dur, vol=1.0, freq_end=None, attack=0.004, decay=None, shape="sine", vibrato=0.0, vib_rate=6.0):
    n = int(SR * dur)
    out = []
    phase = 0.0
    decay = dur if decay is None else decay
    for i in range(n):
        t = i / SR
        k = i / max(n - 1, 1)
        f = freq if freq_end is None else freq * (freq_end / freq) ** k
        f *= 1.0 + vibrato * math.sin(2 * math.pi * vib_rate * t)
        phase += 2 * math.pi * f / SR
        if shape == "sine":
            s = math.sin(phase)
        elif shape == "saw":
            s = 2.0 * ((phase / (2 * math.pi)) % 1.0) - 1.0
        elif shape == "square":
            s = 1.0 if math.sin(phase) >= 0 else -1.0
        else:
            s = math.sin(phase) + 0.5 * math.sin(2 * phase) + 0.25 * math.sin(3 * phase)
        env = min(1.0, t / attack) if attack > 0 else 1.0
        env *= math.exp(-t * 5.0 / decay)
        out.append(s * env * vol)
    return out


def noise(dur, vol=1.0, attack=0.002, decay=None, lp=1.0, hp=0.0, swell=False):
    n = int(SR * dur)
    out = []
    low = 0.0
    prev_low = 0.0
    decay = dur if decay is None else decay
    for i in range(n):
        t = i / SR
        x = rng.uniform(-1, 1)
        low += lp * (x - low)
        s = low
        if hp > 0:
            s = low - prev_low * (1 - hp)
            prev_low = low
        if swell:
            env = math.sin(math.pi * min(1.0, t / dur)) ** 1.5
        else:
            env = min(1.0, t / attack) * math.exp(-t * 5.0 / decay)
        out.append(s * env * vol)
    return out


def bell(freqs, dur, vol=1.0, decay=None):
    """Inharmoniska partialtoner – metall, glas och klockor."""
    out = silence(dur)
    for j, f in enumerate(freqs):
        part = tone(f, dur, vol / (1 + j * 0.6), decay=(decay or dur) / (1 + j * 0.3))
        out = mix(out, part)
    return out


def mix(*tracks, offsets=None):
    offsets = offsets or [0.0] * len(tracks)
    length = max(int(o * SR) + len(t) for t, o in zip(tracks, offsets))
    out = [0.0] * length
    for t, o in zip(tracks, offsets):
        start = int(o * SR)
        for i, s in enumerate(t):
            out[start + i] += s
    return out


def lowpass(track, amount):
    out = []
    y = 0.0
    for s in track:
        y += amount * (s - y)
        out.append(y)
    return out


def fade(track, fade_in=0.0, fade_out=0.0):
    n = len(track)
    fi = int(fade_in * SR)
    fo = int(fade_out * SR)
    out = list(track)
    for i in range(min(fi, n)):
        out[i] *= i / fi
    for i in range(min(fo, n)):
        out[n - 1 - i] *= i / fo
    return out


def save(name, track, gain=0.9):
    peak = max(1e-6, max(abs(s) for s in track))
    data = b"".join(
        struct.pack("<h", int(max(-1.0, min(1.0, math.tanh(1.4 * s / peak) / math.tanh(1.4) * gain)) * 32767))
        for s in track
    )
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data)


def cast_loop(freqs, dur=4.5, vib=0.004, noise_lp=0.05, noise_vol=0.25, shape="sine"):
    layers = [tone(f, dur, 0.4, decay=1e9, attack=0.25, shape=shape, vibrato=vib, vib_rate=5 + i)
              for i, f in enumerate(freqs)]
    layers.append(noise(dur, noise_vol, attack=0.3, decay=1e9, lp=noise_lp))
    return fade(mix(*layers), 0.2, 0.3)


def drum(offset):
    return (mix(tone(95, 0.35, 1.0, freq_end=48, decay=0.3), noise(0.08, 0.5, lp=0.3)), offset)


def main():
    os.makedirs(OUT, exist_ok=True)
    sounds = {
        # Närstrid
        "melee_hit": mix(noise(0.11, 0.9, lp=0.35, decay=0.08), tone(120, 0.12, 0.8, freq_end=60, decay=0.1)),
        "melee_crit": mix(noise(0.16, 1.0, lp=0.5, decay=0.12), tone(110, 0.2, 1.0, freq_end=45, decay=0.18),
                          bell([1850, 2730, 3910], 0.3, 0.25)),
        "boss_swing": mix(noise(0.25, 0.9, lp=0.12, decay=0.2), tone(75, 0.3, 1.0, freq_end=38, decay=0.25)),
        "shield_slam": mix(bell([420, 1033, 1610, 2380], 0.45, 0.7, decay=0.3), tone(90, 0.2, 1.0, freq_end=50),
                           noise(0.06, 0.6, lp=0.5)),
        "kick": mix(noise(0.09, 0.6, lp=0.6, hp=0.2, swell=True), tone(150, 0.12, 0.9, freq_end=70, decay=0.1),
                    offsets=[0, 0.06]),
        # Kastljud (spelas medan mätaren fylls, stoppas när kastet är klart)
        "cast_frost": cast_loop([880, 1320, 1975], noise_lp=0.6, noise_vol=0.1, vib=0.006),
        "cast_fire": cast_loop([110, 165], noise_lp=0.08, noise_vol=0.6, shape="saw"),
        "cast_holy": cast_loop([523, 659, 784, 1046], noise_lp=0.3, noise_vol=0.05, vib=0.008),
        "cast_shadow": lowpass(cast_loop([73, 110, 146], noise_lp=0.04, noise_vol=0.5, shape="saw", vib=0.01), 0.25),
        # Träffar och effekter
        "frost_impact": mix(noise(0.2, 0.7, lp=0.9, hp=0.3, decay=0.12), bell([2400, 3150, 4020], 0.35, 0.5)),
        "pyro_impact": mix(noise(0.9, 1.0, lp=0.1, decay=0.6), tone(85, 0.8, 1.0, freq_end=35, decay=0.6),
                           noise(0.5, 0.4, lp=0.7, decay=0.3)),
        "heal": mix(*[tone(f, 0.7, 0.45, decay=0.55) for f in (784, 988, 1175, 1568)],
                    offsets=[0, 0.05, 0.1, 0.15]),
        "renew": mix(tone(1175, 0.5, 0.3, decay=0.4), tone(1568, 0.5, 0.3, decay=0.4), offsets=[0, 0.08]),
        "shield_wall": mix(bell([180, 433, 690, 1130], 1.3, 0.9, decay=1.0), tone(60, 0.4, 1.0, freq_end=40),
                           noise(0.1, 0.5, lp=0.3)),
        "interrupt": mix(*[bell([rng.uniform(2200, 5200)], 0.4, 0.35, decay=0.25) for _ in range(7)],
                         noise(0.25, 0.8, lp=0.95, hp=0.4, decay=0.15),
                         offsets=[rng.uniform(0, 0.08) for _ in range(7)] + [0]),
        "bloodlust": mix(*(t for t, _ in (drum(0), drum(0.17), drum(0.34))),
                         lowpass(tone(220, 1.2, 0.5, freq_end=330, attack=0.3, decay=2.0, shape="saw", vibrato=0.01), 0.15),
                         offsets=[0, 0.17, 0.34, 0.3]),
        "volley_impact": mix(noise(0.35, 0.8, lp=0.15, decay=0.25), tone(160, 0.35, 0.7, freq_end=70, decay=0.3)),
        "bone_crush": mix(tone(62, 1.1, 1.0, freq_end=28, decay=0.9), noise(0.7, 1.0, lp=0.08, decay=0.5),
                          noise(0.18, 0.7, lp=0.6, decay=0.1), noise(0.15, 0.5, lp=0.6, decay=0.1),
                          offsets=[0, 0, 0.03, 0.11]),
        "frenzy": mix(lowpass(noise(1.3, 1.0, swell=True, lp=0.5), 0.1),
                      tone(90, 1.3, 0.7, attack=0.2, decay=2.0, shape="saw", vibrato=0.05, vib_rate=11)),
        "death": tone(320, 0.7, 0.8, freq_end=70, decay=0.5, shape="rich"),
        # Gränssnitt
        "ui_error": lowpass(tone(130, 0.14, 0.5, shape="square", decay=0.2), 0.3),
        "ready": mix(tone(1568, 0.18, 0.35, decay=0.12), tone(2093, 0.2, 0.3, decay=0.15), offsets=[0, 0.04]),
        "queued": tone(1046, 0.06, 0.25, decay=0.05),
        "count": tone(660, 0.18, 0.6, decay=0.15, shape="rich"),
        "go": mix(tone(990, 0.4, 0.6, decay=0.3, shape="rich"), tone(1320, 0.4, 0.4, decay=0.3)),
        "victory": mix(*[lowpass(tone(f, d, 0.5, attack=0.01, decay=d * 1.2, shape="saw"), 0.2)
                         for f, d in ((523, 0.25), (659, 0.25), (784, 0.25), (1046, 1.4), (784, 1.4), (659, 1.4))],
                       offsets=[0, 0.16, 0.32, 0.5, 0.5, 0.5]),
        "defeat": mix(*[lowpass(tone(f, 1.0, 0.5, decay=0.9, shape="saw"), 0.12) for f in (440, 349, 294, 220)],
                      offsets=[0, 0.35, 0.7, 1.05]),
    }
    for name, track in sounds.items():
        save(name, track)
        print(f"{name:14s} {len(track) / SR:4.2f}s")


if __name__ == "__main__":
    main()
