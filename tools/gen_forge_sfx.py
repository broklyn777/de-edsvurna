#!/usr/bin/env python3
"""Syntetiserar Smedens och fyndens ljud (0.20) till assets/audio/ med verktygen i gen_sfx.py.
Rör inga andra ljud.

    python3 tools/gen_forge_sfx.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gen_sfx import SR, bell, lowpass, mix, noise, save, tone  # noqa: E402


def chime(freqs, step, vol=0.5, decay=0.9):
    return mix(*[tone(f, decay, vol, decay=decay, shape="rich") for f in freqs], offsets=[i * step for i in range(len(freqs))])


def main():
    sounds = {
        # Bärnsten: en kort, varm klocka.
        "find_amber": mix(bell([1318, 1976, 2637], 0.5, 0.45, decay=0.4), tone(659, 0.3, 0.25, decay=0.25)),
        # Trick: två toner och ett metalliskt klick.
        "find_trick": mix(chime([880, 1318], 0.09, 0.4, 0.5), noise(0.05, 0.4, lp=0.7, decay=0.03)),
        # Nether Stone: skimmer som stiger.
        "find_nether": mix(lowpass(noise(1.2, 0.5, swell=True, lp=0.4), 0.2),
                           tone(330, 1.4, 0.35, freq_end=660, attack=0.3, decay=1.6, vibrato=0.01),
                           bell([1760, 2349, 3136], 1.2, 0.35, decay=1.0), offsets=[0, 0, 0.5]),
        # Sällsynt fynd: en liten fanfar över skimret.
        "find_rare": mix(lowpass(noise(1.8, 0.4, swell=True, lp=0.4), 0.2),
                         chime([523, 659, 784, 1046, 1318], 0.11, 0.45, 1.4),
                         bell([2093, 2637, 3520], 1.6, 0.4, decay=1.4), offsets=[0, 0.15, 0.7]),
        # Smeden höjer nivån: städslag och en stigande ton.
        "forge_level": mix(bell([523, 1410, 2215, 3120], 0.7, 0.8, decay=0.5), noise(0.08, 0.7, lp=0.5, decay=0.05),
                           bell([523, 1410, 2215, 3120], 0.7, 0.6, decay=0.5),
                           tone(392, 0.9, 0.35, freq_end=784, attack=0.05, decay=1.0, shape="rich"),
                           offsets=[0, 0, 0.22, 0.35]),
        # En ny plats öppnas: ljust lås som går upp och en klang.
        "slot_open": mix(noise(0.06, 0.6, lp=0.6, decay=0.04), tone(1200, 0.08, 0.4, freq_end=1800, decay=0.06),
                         chime([784, 1175, 1568, 2349], 0.07, 0.45, 1.2), offsets=[0, 0.02, 0.12]),
        # Ett material sätts i en plats.
        "socket": mix(noise(0.05, 0.5, lp=0.5, decay=0.03), bell([988, 1480, 1976], 0.45, 0.45, decay=0.35),
                      offsets=[0, 0.03]),
    }
    for name, track in sounds.items():
        save(name, track)
        print(f"{name:14s} {len(track) / SR:4.2f}s")


if __name__ == "__main__":
    main()
