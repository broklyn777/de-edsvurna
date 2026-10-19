# Modeller

Hämtade från Drakvalvet-projektet (`~/Desktop/Blender-Test/export/qt-*.glb`), uppackade från
meshopt/kvantisering med gltf-transform (`dequantize`) så att Godot kan läsa dem.

Figurer och animationer av Quaternius (https://quaternius.com), CC0 1.0 (public domain),
klädda och beväpnade i Blender för Drakvalvet:

| Fil | Källa | Roll i rpg007 |
|---|---|---|
| torvald.glb | Quaternius "Adventurer" (poly.pizza/m/5EGWBMpuXq) | Paladinen (omfärgad) |
| sigrun.glb | Quaternius "Animated Woman" (poly.pizza/m/qJ2gsTUBHL) | Lånar ut mantel, solmärke och hjälm (Paladinen, Brokk) |
| solveig.glb | Quaternius "Animated Woman" (poly.pizza/m/qJ2gsTUBHL) | Solveig |
| liria.glb | Quaternius "Hooded Adventurer" (poly.pizza/m/y9KWOVG21R) | Jägaren Eira (och koger åt skelettbågskytten) |
| skelett.glb | Quaternius "Adventurer" (poly.pizza/m/5EGWBMpuXq) utan kropp; benen är stela delar byggda i Blender (Drakvalvet `Monster/skelett.py`) | Alla skelettfiender och Benfursten |
| brokk.glb | Quaternius "Adventurer" (poly.pizza/m/5EGWBMpuXq), omformad till dvärg med skägg i Blender (Drakvalvet `qt-hjalte-dwarf-m.glb`) | Brokk |
| alva.glb | Quaternius "Hooded Adventurer" (poly.pizza/m/y9KWOVG21R) med kåpa och huva (Drakvalvet `qt-akolyt.glb`) | Syster Alva |
| kapa.glb | Quaternius "Hooded Adventurer" (poly.pizza/m/y9KWOVG21R), bara kåpan och hänget kvar (Drakvalvet `qt-kultist.glb`, kropp och animationer bortskurna med gltf-transform) | Kåpa åt gravprästen och Benfursten |
| rustning.glb | Quaternius "Adventurer" (poly.pizza/m/5EGWBMpuXq) utan kropp, med plåtrustning (Drakvalvet `qt-tom_rustning.glb`) | Rustning åt gravväktaren och axelskydd åt Benfursten |
| kultist.glb | Quaternius "Hooded Adventurer" (poly.pizza/m/y9KWOVG21R) med röd kåpa och huva (Drakvalvet `qt-kultist.glb`) | Kultist i kapellet |
| gast.glb | Quaternius "Hooded Adventurer" (poly.pizza/m/y9KWOVG21R), Drakvalvets akolyt omgjord i Blender: genomskinligt likklädnad, mörkt ansikte, lysande ögon, svävar 18 cm | Gast i kapellet |
| fallen_riddare.glb | Quaternius "Adventurer" (poly.pizza/m/5EGWBMpuXq), torvald.glb omfärgad i Blender (svart rustning, glödande röda kanter) med horn på hjälmen | Fallen riddare i kapellet |
| haxa.glb | Quaternius "Hooded Adventurer" (poly.pizza/m/y9KWOVG21R), Drakvalvets Svala (`qt-svala.glb`) i Blender: spetsig hatt, sumpgrön kappa | Häxa i kapellet |
| biskop.glb | Quaternius "King" (poly.pizza/m/I1gTjmuK2m), Drakvalvets Ragnvald (`qt-ragnvald.glb`) i Blender: mitra, kräkla i stället för hammare, smutsvit kåpa, grönt sken | Den fallne biskopen |
| nekromant.glb | Quaternius "Hooded Adventurer" (poly.pizza/m/y9KWOVG21R), Drakvalvets akolyt i Blender: svart kåpa, grönt lysande skärp, lie | Nekromant (Värdshuset) |
| bard.glb | Quaternius "Adventurer" (poly.pizza/m/5EGWBMpuXq), Drakvalvets rövarhövding (`qt-rovarhovding.glb`) i Blender: plym i hatten, luta på ryggen, vinröd rock | Bard (Värdshuset) |
| munk.glb | Quaternius "Adventurer" (poly.pizza/m/5EGWBMpuXq), Drakvalvets `qt-hjalte-human-m.glb` i Blender: saffransgul klädsel, rakad, pärlband, 11 anims | Munk (Värdshuset) |
| druid.glb | Quaternius "Adventurer" kvinna (poly.pizza/m/ZwF0K7WBmu), Drakvalvets `qt-hjalte-human-f.glb` i Blender: horn, lövkrage, mossgrön klädsel, 10 anims | Druid (Värdshuset) |
| vapen.glb | Vapen från Drakvalvet – **källa ej bekräftad, kontrollera före release** | Vapen i händerna |

Animationerna kommer från Quaternius "Universal Animation Library" (CC0). Alla figurer har samma rigg
(`CharacterArmature`), så `unit_model.gd` kan låna animationer och delar mellan dem (se "visual" i
`data/heroes.json` och `data/enemies.json`). Benfurstens krona byggs i kod.

# Ljud

- `assets/audio/k_*/` – Kenney "RPG Audio", "Impact Sounds", "Interface Sounds" (kenney.nl), CC0 1.0.
  Licens: `assets/audio/KENNEY_LICENSE.txt`.
- `assets/audio/*.wav` – syntetiserade i `tools/gen_sfx.py` (egna).
- `assets/audio/voice/*.mp3` – användarens egna röstrepliker, gjorda i ElevenLabs.
  **Kontrollera att ElevenLabs-planen tillåter kommersiell användning före release.**
