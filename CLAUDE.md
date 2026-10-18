# rpg007

Party-RPG för mobil (Android först, iPhone senare via moln-Mac). Spelaren är raidledaren för ett party.

## Ledstjärna

**En strid först, och ingenting annat förrän den känns skön.**
Inga talangträd, ingen loot, inga nya klasser förrän den första striden (4 hjältar, 1 boss, 5 knappar) känns bra.

## Pelare

- **WoW Vanilla–WotLK** – känslan: GCD-rytm, cast bars, spell queue, tunga träffar, tydliga ljud, läsbara bossmekaniker.
- **Path of Exile** – karaktärsbygget (senare).
- **Dragon Age: Origins** – taktiken: regler per hjälte, taktisk paus, kombinationer.

## Teknik

- Godot 4.7.2, GDScript, renderer GL Compatibility, 1280×720 liggande (`canvas_items`/`expand`).
- Stridslogiken i `src/combat/` ska vara ren logik utan noder, så den kan testas och simuleras headless.
- Data (klasser, förmågor, fiender) i `data/`.
- Allt UI ska fungera med touch; musklick emuleras som touch.

## Struktur

- `src/combat/` – `CombatSim` (ren logik, fast tidssteg 0,05 s, händelselista), `CombatUnit`, `GameData`.
- `data/*.json` – förmågor, auror, hjältar (med AI-regler och `trait_options`), bossar (timers, faser),
  möten (party + knappar), egenskaper (`traits.json`).
- Egenskaper: lyssnar på en händelsetyp (`trigger`) och kör effekter när `when` stämmer, eller ändrar
  siffror (`modify_damage`, `modify_damage_taken`, `modify_heal`). Kan sätta igång varandra i kedjor
  (max 4 steg). Spelaren väljer en klassegenskap per hjälte och fördelar artefakter (egenskaper med `"artifact": true`,
  en per hjälte, var och en bara på en hjälte) på valskärmen före striden (`trait_picker.gd`, sparas i `user://choices.cfg`).
- `scripts/battle/` – grafik och känsla. `battle.gd` översätter simulatorns händelser till animationer,
  ljud, siffror, hitstop (`Engine.time_scale`), skakningar och effekter. Knappar reagerar på tryck, inte släpp.
  - `crypt_world.gd` – 3D-kryptan (golv, pelare, facklor, ljus, kamera, varningscirklar), byggd i kod.
  - `unit_model.gd` – 3D-figur: laddar `assets/models/<model>.glb`, hänger vapen från `vapen.glb` i
    `grip_r`/`grip_l`, spelar animationer enligt `visual.anims` i heroes.json/bosses.json.
    Bossens närstridskast (windup) håller vapnet högt tills slaget faller.
  - `procedural_anims.gd` – egna animationer byggda i kod (Kick, Shield_Wall, Cast_Channel_*):
    vridningar per ben i grader ovanpå en baspose. Fotbenen är egna IK-ben i riggen och flyttas
    automatiskt med benet. Axlar: UpperLeg X− = benet framåt; Torso X+ = framåtlutning;
    UpperArm.R Z+ / UpperArm.L Z− = armen framåt/upp; UpperArm X− = armen ut åt sidan.
  - 2D-lager ovanpå 3D: siffror, projektiler, ringar, healstrålar och hälsomätare projiceras från 3D.
- `assets/models/` – Quaternius-figurer från Drakvalvet, uppackade med
  `node ~/.npm/_npx/425967af1abfabd4/node_modules/@gltf-transform/cli/bin/cli.js dequantize in.glb ut.glb`
  (Godot läser inte meshopt/kvantisering). Se `ASSETS_LICENSE.md`.
- `assets/audio/` – `sfx.play("namn")` spelar `namn.wav` eller en slumpad variant ur mappen `namn/`
  (Kenney-ljud ligger i `k_*`-mappar). Röster i `voice/` spelas med `sfx.say()` (en i taget, vilotid).
  Huvudkanalen har kompressor + limiter (sätts i `sfx.gd`). Kryptstämningen loopar (`ambience_crypt.wav`).
- `tools/gen_sfx.py` – syntetiserar egna ljud och kryptstämningen till `assets/audio/` (kör om efter ändringar).
- `tests/combat_bot.gd` – simulerade spelare (NONE/SLOPPY/GOOD) för balanstester.

Balansmål för Bone Lich: NONE förlorar alltid, SLOPPY vinner ~70 %, GOOD ~100 %, strid ~90 s.

## Kommandon

```bash
# Kör tester
godot --headless --path . --script res://tests/run_tests.gd

# Starta spelet
godot --path .

# Balansrapport (40 strider per spelarnivå)
godot --headless --path . --script res://tests/balance_report.gd

# Alla kombinationer av egenskapsval (SLOPPY-bot), starkast/svagast och snitt per egenskap (~2,5 min)
godot --headless --path . --script res://tests/trait_report.gd

# Varje artefakt på varje hjälte jämfört med utan artefakt (~2 min)
godot --headless --path . --script res://tests/artifact_report.gd

# Skärmdump av spelet (sparas efter 30 bildrutor, sedan avslut)
godot --path . -- --screenshot=/tmp/shot.png --frames=30

# Låt en bot spela, spola fram 16 s, fast slumpfrö
godot --path . -- --demo --warp=16 --seed=5

# Spela in bildsekvens (PNG) för att granska rörelser
godot --path . --write-movie /tmp/mov/f.png --fixed-fps 20 --quit-after 70 -- --demo --warp=8 --seed=5

# Animationslabb: filma en figur på nära håll (se tools/anim_lab.gd för steg)
godot --path . res://tools/anim_lab.tscn --write-movie /tmp/lab/f.png --fixed-fps 20 --quit-after 50 -- --unit=rogue --seq=idle:0.2,kick:1.2

# Bygg debug-APK och installera på ansluten Android-telefon
godot --headless --path . --export-debug Android export/rpg007.apk
~/Library/Android/sdk/platform-tools/adb install -r export/rpg007.apk
```

## Verktygskedja (iMac 2017, macOS 13)

Homebrew bygger inte längre färdiga paket för macOS 13 – installera inte Java/Android via brew (kompilerar i timmar).

- Godot 4.7.2: `/Applications/Godot.app`, `godot` i PATH. Exportmallar i `~/Library/Application Support/Godot/export_templates/4.7.2.stable/`.
- JDK 17 (Temurin): `~/Library/Java/JavaVirtualMachines/jdk-17.0.20.1+1/Contents/Home`
- Android SDK: `~/Library/Android/sdk` (platform-tools, build-tools 36.1.0, platforms android-36)
- Debug-nyckel: `~/.android/debug.keystore` (standard: android/androiddebugkey)
- Exporten är utan Gradle (`gradle_build/use_gradle_build=false`), endast arm64-v8a.

Tester: lägg `tests/test_*.gd` som ärver `res://tests/test_case.gd`, metoder som börjar på `test_`.
