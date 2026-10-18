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
- **Artefakter** (0.12, Siralims Artifacts): en per hjälte, smids hos Smeden för silver. Typen höjer en
  stat och avgör när förmågan i den slår till av sig själv: svärd vid Anfall (25 %), stav vid Förmåga
  (25 %), sköld vid Försvara (50 %), hjälm vid Provocera (50 %), stövlar i början av turen (15 %).
  Automatiska kast kostar inga Charges men räknas mot gränsen per tur.
- **Basen** (0.12, Siralims slott) ligger mellan körningarna: Kryptporten, Övningsgården (Arena),
  Smeden, Makron och Biblioteket. Förlust eller klarad krypta leder hem. Silver ges per vunnen strid.
- **Död:** en död figurs egenskaper slutar verka, även Paladinens Ed, och verkar igen när den väcks.
- **Strid:** Siralims tidslinje – snabbheten avgör startplatsen, den som agerat läggs längst ned, inga
  rundor. Hjältar väljer Anfall, Förmåga (2–3 per hjälte, med Charges som räcker hela körningen),
  Försvara, Provocera eller Makro. Fiender visar sin avsikt och väljer nästa i slutet av sin tur.
- **Makron** (kärnsystem, som i Siralim): upp till 20 rader per makro, subjekt + villkor + handling (+ mål),
  uppifrån och ned, första raden som passar och går att utföra vinner. Tilldelas per hjälte, med
  standardhandling Makro/Manuell. Auto kör makrona och stannar när inget passar. Förklaringsloggen
  visar varför ("rad 2 matchade: …"). Regler, källor och våra val: `docs/plan/0.11-makron.md`,
  `docs/research/siralim.md` §9–9b.
- Nästa steg: Siralims stats (Attack/Defense/Intelligence, Speed för krit och undvikande), artefaktnivåer
  och fler platser, fler Eder, Inspect. Idéer för basen: `docs/research/siralim.md` §10c–10d.
- Realtidsprototypen i WoW-stil ligger kvar på grenen `wow-realtid` (tagg `v0.8.1-wow`).

## Språk

Spelets text är svensk. Kod, data och research använder Siralims engelska termer (trait, macro, provoke,
timeline …) så att de går att söka på. Kopplingen mellan dem finns i `docs/ordlista.md` – håll den
uppdaterad när nya begrepp tillkommer.

## Teknik

- Godot 4.7.2, GDScript, renderer GL Compatibility, 1280×720 liggande (`canvas_items`/`expand`).
- Stridslogiken i `src/combat/` ska vara ren logik utan noder, så den kan testas och simuleras headless.
- Data (hjältar, fiender, förmågor, egenskaper) i `data/`.
- Allt UI ska fungera med touch; musklick emuleras som touch.

## Struktur

- `src/game/run_state.gd` – en körning: Ed, sällskap, våning (`FLOORS`), troféer och vem som bär dem,
  artefakter; `new_run()` och `new_practice()` (Övningsgården: valfritt möte, fulla Charges).
  `src/game/profile.gd` – det som varar mellan körningar: silver, samlingen, artefakter (`forge()`),
  senaste Ed och sällskap, övningstroféer. Sparas i `user://progress.cfg`.
  `scripts/game/run.gd` är autoloaden `Run` som byter scen (bas → Kryptporten → strid → läger → … → bas;
  bas → Övningsgården → strid → Övningsgården) och sparar makrona i `user://macros.json`
  (startmakron i `data/macros.json`).
  Skärmar i `scripts/screens/`: `base_screen` (första skärmen), `start_screen` (Kryptporten),
  `practice_screen`, `smith_screen`, `library_screen`, `camp_screen`, `macro_screen`. De flesta ärver
  `tap_screen.gd` och reagerar vid släpp.
- `src/combat/` – `CombatSim` (tidslinje, ren logik, händelselista), `CombatUnit`, `GameData`,
  `MacroRunner` (makron: `decide()` ger handling + förklaring, `describe_line()` texten i editorn).
  `create(…, artifacts)` ger hjältarna artefakter (`equip_artifact`): stat + en genererad egenskap
  `artifact_<hjälte>` som lyssnar på `acted` (efter handlingen) eller `turn_start` och kör effekten
  `cast` (kastar förmågan gratis, action `"artifact"`). Datan kopieras per strid – använd `sim.data`.
  Flöde: `begin()`, sedan `act(action, target, ability)` när `needs_input()` annars `ai_act()`; töm `drain_events()`.
- `data/artifacts.json` – artefakttyperna (stat, utlösande handling, chans).
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

Balansmål (utan troféer): startmakrona vinner varje strid för sig nästan alltid, men klarar hela kryptan
(Charges räcker alla tre våningarna) bara ~60 %; bättre makron ~66 %+. BASIC (bara Anfall) förlorar.
En artefakt lyfter startmakrona till 75–85 %, fyra till ~96 % – därför kostar smide 100 silver
(startsilvret räcker till en; en klarad körning ger 110).
Gränser per tur som i Siralim: `TURN_LIMIT` attacker/besvärjelser/helningar.

## Kommandon

```bash
# Kör tester
godot --headless --path . --script res://tests/run_tests.gd

# Starta spelet
godot --path .

# Balansrapport per våning och för hela kryptan (BASIC/MACRO/TUNED, 100 strider var)
godot --headless --path . --script res://tests/balance_report.gd

# Skärmdump av spelet (sparas efter 30 bildrutor, sedan avslut)
godot --path . -- --screenshot=/tmp/shot.png --frames=30

# Starta direkt i en strid (våning 0–2), låt AI:n spela, spola fram 10 turer, fast slumpfrö
godot --path . -- --floor=2 --demo --turns=10 --seed=5

# Visa lägret mellan striderna direkt
godot --path . -- --camp

# Öppna en plats i basen direkt (--gate = Kryptporten, --practice, --smith, --library)
godot --path . -- --smith

# Strid med artefakter (bara den körningen): --artifact=<hjälte>:<typ>:<förmåga>
godot --path . -- --floor=0 --demo --artifact=brokk:shield:healing_light

# Öppna makroredigeraren direkt (--edit-line öppnar radeditorn)
godot --path . -- --macros --edit-line

# Spela in bildsekvens (PNG) för att granska rörelser
godot --path . --write-movie /tmp/mov/f.png --fixed-fps 20 --quit-after 200 -- --floor=0 --demo --seed=3

# Animationslabb: filma en figur på nära håll (se tools/anim_lab.gd för steg)
godot --path . res://tools/anim_lab.tscn --write-movie /tmp/lab/f.png --fixed-fps 20 --quit-after 50 -- --unit=eira --seq=idle:0.2,attack:1.2

# Bygg APK för telefonen. Release-mallen är ~2 MiB mindre än debug och håller filen under 30 MiB
# (gränsen för att skicka filer till telefonen). Signeras med debug-nyckeln via miljövariabler, så att
# den installeras som uppdatering ovanpå tidigare versioner.
GODOT_ANDROID_KEYSTORE_RELEASE_PATH=$HOME/.android/debug.keystore GODOT_ANDROID_KEYSTORE_RELEASE_USER=androiddebugkey GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=android godot --headless --path . --export-release Android export/rpg007.apk

# Debug-APK (för felsökning med adb) och installation på ansluten telefon
godot --headless --path . --export-debug Android export/rpg007.apk
~/Library/Android/sdk/platform-tools/adb install -r export/rpg007.apk
```

## Verktygskedja (iMac 2017, macOS 13)

Homebrew bygger inte längre färdiga paket för macOS 13 – installera inte Java/Android via brew (kompilerar i timmar).

- Godot 4.7.2: `/Applications/Godot.app`, `godot` i PATH. Exportmallar i `~/Library/Application Support/Godot/export_templates/4.7.2.stable/`.
- JDK 17 (Temurin): `~/Library/Java/JavaVirtualMachines/jdk-17.0.20.1+1/Contents/Home`
- Android SDK: `~/Library/Android/sdk` (platform-tools, build-tools 36.1.0, platforms android-36)
- Debug-nyckel: `~/.android/debug.keystore` (standard: android/androiddebugkey)
- Exporten är utan Gradle (`gradle_build/use_gradle_build=false`), endast arm64-v8a. Oanvända ljud
  (röstrepliker, gamla WoW-ljud) och docs/ utesluts i `exclude_filter` i export_presets.cfg.

Tester: lägg `tests/test_*.gd` som ärver `res://tests/test_case.gd`, metoder som börjar på `test_`.
