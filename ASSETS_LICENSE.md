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
| brokk.glb | Quaternius "Adventurer" (poly.pizza/m/5EGWBMpuXq), omformad till dvärg med skägg i Blender (Drakvalvet `qt-hjalte-dwarf-m.glb`), med tung rustning (axelskydd, bröstplåt, bälte) byggd i Blender | Brokk |
| alva.glb | Quaternius "Hooded Adventurer" (poly.pizza/m/y9KWOVG21R) med kåpa och huva (Drakvalvet `qt-akolyt.glb`) | Syster Alva |
| kapa.glb | Quaternius "Hooded Adventurer" (poly.pizza/m/y9KWOVG21R), bara kåpan och hänget kvar (Drakvalvet `qt-kultist.glb`, kropp och animationer bortskurna med gltf-transform) | Kåpa åt gravprästen och Benfursten |
| rustning.glb | Quaternius "Adventurer" (poly.pizza/m/5EGWBMpuXq) utan kropp, med plåtrustning (Drakvalvet `qt-tom_rustning.glb`) | Rustning åt gravväktaren och axelskydd åt Benfursten |
| kultist.glb | Quaternius "Hooded Adventurer" (poly.pizza/m/y9KWOVG21R) med röd kåpa och huva (Drakvalvet `qt-kultist.glb`) | Kultist i kapellet |
| gast.glb | Quaternius "Hooded Adventurer" (poly.pizza/m/y9KWOVG21R), Drakvalvets akolyt omgjord i Blender: genomskinligt likklädnad, mörkt ansikte, lysande ögon, svävar 18 cm | Gast i kapellet |
| fallen_riddare.glb | Quaternius "Adventurer" (poly.pizza/m/5EGWBMpuXq), torvald.glb omfärgad i Blender (svart rustning, glödande röda kanter) med horn på hjälmen | Fallen riddare i kapellet |
| haxa.glb | Quaternius "Hooded Adventurer" (poly.pizza/m/y9KWOVG21R), Drakvalvets Svala (`qt-svala.glb`) i Blender: spetsig hatt, sumpgrön kappa | Häxa i kapellet |
| biskop.glb | Quaternius "King" (poly.pizza/m/I1gTjmuK2m), Drakvalvets Ragnvald (`qt-ragnvald.glb`) i Blender: mitra, kräkla i stället för hammare, smutsvit kåpa, grönt sken | Den fallne biskopen |
| falkenerare.glb | Quaternius "Adventurer" kvinna (poly.pizza/m/ZwF0K7WBmu), Drakvalvets Gudlaug (`qt-gudlaug.glb`) i Blender: ljusblå rock, falken Stormvinge på vänster axel (byggd i Blender, utan UV) | Ronja Falkvind, falkenerare |
| bard.glb | Quaternius "Adventurer" (poly.pizza/m/5EGWBMpuXq) som alv, Drakvalvets `qt-hjalte-elf-m.glb` i Blender: plymhatt, luta på ryggen, vinröd klädsel (7 anims, utan UV) | Lirien Silversträng, bard |
| munk.glb | Quaternius "Adventurer" (poly.pizza/m/5EGWBMpuXq), Drakvalvets `qt-hjalte-human-m.glb` i Blender: saffransgul klädsel, rakad, pärlband (8 anims, utan UV) | Broder Tove, munk |
| druid.glb | Quaternius "Adventurer" kvinna (poly.pizza/m/ZwF0K7WBmu), Drakvalvets `qt-hjalte-human-f.glb` i Blender: horn, lövkrage, mossgrön klädsel (7 anims, utan UV) | Hulda Mossrot, druid |
| domare.glb | Quaternius "Adventurer" kvinna (poly.pizza/m/ZwF0K7WBmu), Drakvalvets `qt-hjalte-human-f.glb` i Blender: vit och guld dräkt, silverhår, domarmössa, vit mantel (7 anims, utan UV) | Ragnhild Ljusdom, domare |
| svardsdansare.glb | Quaternius "Adventurer" (poly.pizza/m/5EGWBMpuXq), Drakvalvets `qt-hjalte-human-m.glb` i Blender: sandfärgad dräkt, turban, turkost skärp (8 anims, utan UV) | Sefir av Sanden, svärdsdansare |
| imma.glb | Quaternius "Adventurer" kvinna (poly.pizza/m/ZwF0K7WBmu), Drakvalvets `qt-hjalte-human-f.glb` i Blender: kopparrosa hår, läderdräkt, kort lila mantel, koger (6 anims, utan UV) | Imma, Paladinens barndomsvän |
| spindel.glb | Egen modell, byggd helt i Blender av Drakvalvets skript `Monster/jattespindel.py` (egen rigg `SpiderArmature`, 7 klipp: Idle_Loop, Walk_Loop, Run_Loop, Sword_Attack, Spell_Simple_Shoot, Hit_Chest, Death01), ingen Quaternius-del; `qt-jattespindel.glb` uppackad med gltf-transform | Alla spindlar i Sidenlunden (0.31), färgade per material |
| vapen.glb | Vapen från Drakvalvet – **källa ej bekräftad, kontrollera före release** | Vapen i händerna |

Animationerna kommer från Quaternius "Universal Animation Library" (CC0). Alla figurer har samma rigg
(`CharacterArmature`), så `unit_model.gd` kan låna animationer och delar mellan dem (se "visual" i
`data/heroes.json` och `data/enemies.json`). Benfurstens krona byggs i kod.

Rumsögonblicken (`scripts/rooms/`, se `docs/rum3d.md`) har inga egna modellfiler: rummen, kistan,
altaret, buren, stentavlan, lägerelden och portalen byggs av former i kod. Statyn i helgedomen är
`torvald.glb` och fången i buren `alva.glb` (se ovan).

# Ljud

- `assets/audio/k_*/` – Kenney "RPG Audio", "Impact Sounds", "Interface Sounds" (kenney.nl), CC0 1.0.
  Licens: `assets/audio/KENNEY_LICENSE.txt`.
- `assets/audio/*.wav` – syntetiserade i `tools/gen_sfx.py` (egna).
- `assets/audio/music/*.ogg`, `ambience_chapel/`, `ambience_crypt/` (från gen_sfx.py, omkodad) – egenkomponerade och syntetiserade i `tools/gen_audio.py`
  (egna). Kapellstämningen har knarr ur Kenney "RPG Audio" (`creak1–3`), CC0 1.0.
- Handlingsljud byggda i `tools/gen_audio.py` (egna synteslager blandade med Kenney-inspelningar, CC0 1.0):
  | Mapp | Egen syntes | Kenney-filer (paket) |
  |---|---|---|
  | `atk_sword/` | svisch, låg duns | drawKnife1–3, knifeSlice, knifeSlice2 (RPG Audio); impactMetal_medium (Impact Sounds) |
  | `atk_axe/` | svisch, låg duns | chop (RPG Audio); impactWood_heavy, impactPunch_heavy (Impact Sounds) |
  | `atk_blunt/` | svisch, låg duns | impactPunch_medium, impactWood_medium (Impact Sounds) |
  | `bow_shot/` | bågsträng, pilsvisch | beltHandle1–2 (RPG Audio) |
  | `arrow_hit/` | duns | impactWood_light, impactSoft_medium (Impact Sounds) |
  | `spell_holy/`, `spell_fire/`, `fire_hit/`, `spell_shadow/`, `shadow_hit/`, `heal_light/` | allt | – |
  | `spell_nature/`, `nature_hit/` | flöjtdrill, prassel | impactWood_light, impactPlank_medium (Impact Sounds) |
  | `defend/` | klang, duns | clothBelt, clothBelt2 (RPG Audio); impactPlate_light (Impact Sounds) |
  | `provoke/` | stridshorn, duns | impactPlate_heavy (Impact Sounds) |
  | `trophy_*/`, `elite_appears/`, `boss_appears/`, `jingle_victory/`, `jingle_defeat/`, `macro_nomatch/` | allt (egen musik) | trophy_boss: impactBell_heavy_000 (Impact Sounds) |
- `assets/audio/ui_*/` – Kenney-filer oförändrade, CC0 1.0: `ui_tap` (select_001–003), `ui_back` (back_001–002),
  `ui_confirm` (confirmation_001–002), `ui_toggle` (toggle_001–002) ur "Interface Sounds"; `ui_page`
  (bookFlip2–3), `ui_coins` (handleCoins2), `ui_door` (doorOpen_1) ur "RPG Audio";
  `ui_forge` (impactMetal_heavy_000/002/004) ur "Impact Sounds". Hämtade från kenney.nl 2026-10-19.
- `assets/audio/voice/*.mp3` – användarens egna röstrepliker, gjorda i ElevenLabs.
  **Kontrollera att ElevenLabs-planen tillåter kommersiell användning före release.**
- `assets/models/troll.glb`, `troll_mossrygg.glb`, `troll_grumse.glb` – användarens egen ogre ur Drakvalvet (`~/Desktop/Blender-Test/Drakvalvet/Monster/ogre.blend`), omgjord till troll i Blender 2026-10-23 (näsa, mossa, stenkrona). `troll_delar.glb` (sjal, förklädet, lykta, sten) byggd i Blender 2026-10-24 på samma skelett, egna delar. `troll_bortbyting.glb` (2026-10-24) är samma troll, smalare och med längre armar.
- `assets/models/ghoul.glb`, `kultfanatiker.glb`, `helvetshund.glb`, `varg.glb` – användarens egna figurer ur Drakvalvet (`~/Desktop/Blender-Test/Drakvalvet/Monster/{ghoul,kultfanatiker,hellhound,varg}.blend`, byggda på Quaternius-figurer, CC0 1.0), exporterade oförändrade till GLB (30 fps, spelets klippnamn) 2026-10-23.

# Illustrationer

`assets/illustrations/graskogen.webp` (0.31, Sidenlundens vinjett på kampanjkartan tills en egen finns) kommer från
Drakvalvets illustrationer (`~/drakvalvet/public/illustrations/graskogen.webp`), samma källa som stendorren, vaktaren,
under-tornet, nattlägret och sigillet.


`assets/illustrations/vagen.webp` (Trollberget, kampanjkartans vinjett och zoombild tills en egen finns) kommer från
samma källa (`~/drakvalvet/public/illustrations/vagen.webp`).
