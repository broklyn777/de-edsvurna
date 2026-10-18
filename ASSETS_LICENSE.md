# Modeller

Hämtade från Drakvalvet-projektet (`~/Desktop/Blender-Test/export/qt-*.glb`), uppackade från
meshopt/kvantisering med gltf-transform (`dequantize`) så att Godot kan läsa dem.

Figurer och animationer av Quaternius (https://quaternius.com), CC0 1.0 (public domain),
klädda och beväpnade i Blender för Drakvalvet:

| Fil | Källa | Roll i rpg007 |
|---|---|---|
| torvald.glb | Quaternius "Adventurer" (poly.pizza/m/5EGWBMpuXq) | Warrior |
| sigrun.glb | Quaternius "Animated Woman" (poly.pizza/m/qJ2gsTUBHL) | Priest |
| solveig.glb | Quaternius "Animated Woman" (poly.pizza/m/qJ2gsTUBHL) | Mage |
| liria.glb | Quaternius "Hooded Adventurer" (poly.pizza/m/y9KWOVG21R) | Rogue |
| skelett.glb | Troligen Quaternius (skelett) – **källa ej bekräftad, kontrollera före release** | Bone Lich |
| vapen.glb | Vapen från Drakvalvet – **källa ej bekräftad, kontrollera före release** | Vapen i händerna |

Animationerna kommer från Quaternius "Universal Animation Library" (CC0).

# Ljud

- `assets/audio/k_*/` – Kenney "RPG Audio", "Impact Sounds", "Interface Sounds" (kenney.nl), CC0 1.0.
  Licens: `assets/audio/KENNEY_LICENSE.txt`.
- `assets/audio/*.wav` – syntetiserade i `tools/gen_sfx.py` (egna).
- `assets/audio/voice/*.mp3` – användarens egna röstrepliker, gjorda i ElevenLabs.
  **Kontrollera att ElevenLabs-planen tillåter kommersiell användning före release.**
