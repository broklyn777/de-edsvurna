# rpg007

"Siralim Ultimate i 3D" för mobil (Android först, iPhone senare via moln-Mac). Turordningsstrider där
djupet ligger i hur egenskaper kombineras. Spelaren är en rättfärdig **paladin** (inte en besvärjare)
som leder ett sällskap av följeslagare i Baldur's Gate-stil.

## Ledstjärna

**Bevisa att det är roligt att kombinera innan vi bygger mycket innehåll.**
Få följeslagare, troféer och artefakter som ändrar regler, hellre än många som bara ger mer skada.
Varje steg ska vara spelbart på telefonen innan nästa börjar. Det viktigaste testet: byter spelaren
frivilligt en hjälte eller trofé efter att ha upptäckt en ny kombination, och vill prova den direkt?

## Design

- **Paladinen** står alltid med i striden och väljer en **Ed** (Siralims specialisering) – en regelbrytare
  för hela sällskapet. Finns: Hämndens ed. Planerade: Gryningens ed, Väktarens ed.
- **Följeslagare** (Brokk, Syster Alva, Jägaren Eira, Solveig …): namn, roll, egen egenskap och en
  signaturhandling. Börja med 5–8, inte 30.
- **Troféer** ersätter Siralims smältning: besegrade monstertyper lämnar en trofé som ger bäraren monstrets
  egenskap. Vanlig = pålitlig byggdel, elit = specialiserad, boss = ändrar en regel (med kostnad).
- Varje hjälte får till slut 3 egenskaper: egen, trofé och artefakt.
- **Strid:** varje runda agerar alla en gång, snabbast först. Hjältar väljer Anfall, signatur eller
  Försvara. Fiender visar sin avsikt (vad och mot vem) i början av rundan. Följdanfall från egenskaper
  är automatiska. Auto-läge och 2× snabbhet finns.
- Nästa steg (enligt plan): troféval mellan tre korta strider (kryptloop), en andra Ed, efterrapport
  ("varför vann du"), sedan värvning och våningar.
- Realtidsprototypen i WoW-stil ligger kvar på grenen `wow-realtid` (tagg `v0.8.1-wow`).

## Teknik

- Godot 4.7.2, GDScript, renderer GL Compatibility, 1280×720 liggande (`canvas_items`/`expand`).
- Stridslogiken i `src/combat/` ska vara ren logik utan noder, så den kan testas och simuleras headless.
- Data (hjältar, fiender, förmågor, egenskaper) i `data/`.
- Allt UI ska fungera med touch; musklick emuleras som touch.

## Struktur

- `src/game/run_state.gd` – en körning: Ed, sällskap, våning (`FLOORS`), troféer och vem som bär dem.
  `scripts/game/run.gd` är autoloaden `Run` som byter scen (start → strid → läger → … ) och sparar
  samlingen i `user://progress.cfg`. Skärmar i `scripts/screens/` (start, läger); val reagerar vid släpp.
- `src/combat/` – `CombatSim` (turordning, ren logik, händelselista), `CombatUnit`, `GameData`.
  Flöde: `begin()`, sedan `act(action, target)` när `needs_input()` annars `ai_act()`; töm `drain_events()`.
- `data/*.json` – förmågor (`power` = andel av enhetens attack, `cooldown` i egna turer), auror
  (`duration` i ägarens turer, `next_attack_mult`, `taunt`, `dot`/`hot`), hjältar (signatur, egenskaper,
  auto-regler), fiender (attack, regler för avsikter), möten (sällskap + fiender), egenskaper (`traits.json`).
- Egenskaper: lyssnar på en händelsetyp (`trigger`) och kör effekter när `when` stämmer, eller ändrar
  siffror (`modify_damage`, `modify_damage_taken`, `modify_heal`). Kan sätta igång varandra i kedjor
  (max 4 steg), aldrig sig själva. `once_per_turn`, `internal_cooldown` (rundor), `chance`.
  Laddningar: en `charge`-effekt laddar upp, `release` förbrukar när en viss förmåga används.
  Effekter med `pct_of_event` skalar mot händelsens belopp (t.ex. följdanfall för 50 %).
- `scripts/battle/` – grafik och känsla. `battle.gd` kör en tur i taget och översätter händelserna till
  animationer, projektiler, siffror, hitstop och skakningar; egenskapskedjor visas steg för steg.
  - `timeline.gd` (tidslinjen), `action_bar.gd` (Anfall/signatur/Försvara; välj mål genom att trycka på
    figuren eller tryck samma knapp igen för förvalt mål), `party_frame.gd`, `chip_button.gd` (Auto, 1×/2×).
  - `crypt_world.gd` – 3D-kryptan (golv, pelare, facklor, ljus, kamera), byggd i kod.
  - `unit_model.gd` – 3D-figur: laddar `assets/models/<model>.glb`, hänger vapen från `vapen.glb` i
    `grip_r`/`grip_l`, spelar animationer enligt `visual.anims`. `tint` färgar om, `glow` ger sken.
    Vapen i `vapen.glb`: Greatsword, Longsword, Shortsword, Spear, Greataxe, Handaxe, Maul, Mace, Flail,
    Javelin, Longbow, Shield, Staff, Shortbow.
  - `procedural_anims.gd` – egna animationer byggda i kod (Kick, Shield_Wall, Cast_Channel_*):
    vridningar per ben i grader ovanpå en baspose. Axlar: UpperLeg X− = benet framåt; Torso X+ =
    framåtlutning; UpperArm.R Z+ / UpperArm.L Z− = armen framåt/upp; UpperArm X− = armen ut åt sidan.
  - `fx.gd` – 2D-lager ovanpå 3D: siffror, projektiler, ringar, hälsomätare och fiendernas avsikter.
- `assets/models/` – Quaternius-figurer från Drakvalvet, uppackade med
  `node ~/.npm/_npx/425967af1abfabd4/node_modules/@gltf-transform/cli/bin/cli.js dequantize in.glb ut.glb`
  (Godot läser inte meshopt/kvantisering). Se `ASSETS_LICENSE.md`.
- `assets/audio/` – `sfx.play("namn")` spelar `namn.wav` eller en slumpad variant ur mappen `namn/`
  (Kenney-ljud ligger i `k_*`-mappar). Kryptstämningen loopar (`ambience_crypt.wav`).
- `tools/gen_sfx.py` – syntetiserar egna ljud och kryptstämningen till `assets/audio/`.
- `tests/combat_bot.gd` – simulerade spelare (BASIC/AUTO/GOOD) för balanstester.

Balansmål (utan troféer): AUTO vinner ~95 % på våning 1, ~70 % på våning 2, ~60 % mot Benfursten;
BASIC (bara Anfall) förlorar. Gränser per tur som i Siralim: `TURN_LIMIT` attacker/besvärjelser/helningar.

## Kommandon

```bash
# Kör tester
godot --headless --path . --script res://tests/run_tests.gd

# Starta spelet
godot --path .

# Balansrapport per våning (100 strider per spelarnivå)
godot --headless --path . --script res://tests/balance_report.gd

# Skärmdump av spelet (sparas efter 30 bildrutor, sedan avslut)
godot --path . -- --screenshot=/tmp/shot.png --frames=30

# Starta direkt i en strid (våning 0–2), låt AI:n spela, spola fram 10 turer, fast slumpfrö
godot --path . -- --floor=2 --demo --turns=10 --seed=5

# Visa lägret mellan striderna direkt
godot --path . -- --camp

# Spela in bildsekvens (PNG) för att granska rörelser
godot --path . --write-movie /tmp/mov/f.png --fixed-fps 20 --quit-after 200 -- --floor=0 --demo --seed=3

# Animationslabb: filma en figur på nära håll (se tools/anim_lab.gd för steg)
godot --path . res://tools/anim_lab.tscn --write-movie /tmp/lab/f.png --fixed-fps 20 --quit-after 50 -- --unit=eira --seq=idle:0.2,attack:1.2

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
