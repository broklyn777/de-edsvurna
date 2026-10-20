#!/usr/bin/env python3
"""Borgens stämning (0.24 Hemmet): en härd som sprakar, ett lågt brus av eld och vind och en smed som slår
mot städet då och då, långt bort. Bara standardbiblioteket, så att det går att köra utan numpy.

    python3 tools/gen_home_ambience.py

Skriver assets/audio/ambience_home.wav (22 050 Hz, mono, 24 sekunder som loopar utan skarv).
"""
import math
import random
import struct
import wave
from pathlib import Path

SR = 22050
DUR = 24.0
N = int(SR * DUR)
OUT = Path(__file__).resolve().parent.parent / "assets" / "audio" / "ambience_home.wav"

rng = random.Random(24)
buf = [0.0] * N

# Lågt brus: brunt brus (integrerat vitt brus) genom ett enkelt lågpass, som eld och vind i skorstenen.
b = 0.0
lp = 0.0
for i in range(N):
    b = (b + rng.uniform(-1, 1) * 0.02) * 0.998
    lp += (b - lp) * 0.05
    buf[i] += lp * 0.9

# Sprak: korta klick med snabb avklingning, tätare ibland (en vedklabbe som sätter sig).
t = 0.0
while t < DUR - 0.1:
    t += rng.expovariate(9.0)
    start = int(t * SR)
    amp = rng.uniform(0.05, 0.22) * (1.6 if rng.random() < 0.08 else 1.0)
    length = int(SR * rng.uniform(0.004, 0.02))
    tone = rng.uniform(1500, 4500)
    for j in range(length):
        k = start + j
        if k >= N:
            break
        env = math.exp(-j / (length * 0.25))
        buf[k] += amp * env * (rng.uniform(-1, 1) * 0.7 + 0.3 * math.sin(2 * math.pi * tone * j / SR))

# Smeden: tre-fyra slag mot städet, långt bort (lågt, med lite eko), två gånger per loop.
def anvil(at, gain):
    for hit in range(rng.randint(3, 4)):
        start = int((at + hit * 0.55) * SR)
        f = 1850 + rng.uniform(-60, 60)
        for j in range(int(SR * 1.2)):
            k = start + j
            if k >= N:
                break
            env = math.exp(-j / (SR * 0.18))
            s = math.sin(2 * math.pi * f * j / SR) + 0.5 * math.sin(2 * math.pi * f * 2.71 * j / SR)
            buf[k] += gain * env * s
            if k + int(SR * 0.21) < N:
                buf[k + int(SR * 0.21)] += gain * 0.25 * env * s


anvil(5.0, 0.05)
anvil(16.5, 0.04)

# Mjuk övergång i loopen: de sista 1,5 sekunderna tonas över i början.
fade = int(SR * 1.5)
for i in range(fade):
    a = i / fade
    buf[i] = buf[i] * a + buf[N - fade + i] * (1 - a)
buf = buf[: N - fade]

peak = max(abs(x) for x in buf) or 1.0
OUT.parent.mkdir(parents=True, exist_ok=True)
with wave.open(str(OUT), "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, x / peak * 0.8)) * 32767)) for x in buf))
print("skrev", OUT)
