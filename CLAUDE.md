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

- **Paladinen** står alltid med i striden och väljer ett **kall** (Siralims Specialization) – en regelbrytare
  för hela sällskapet. Finns (0.13): Domens kall (Paladin), Gryningens kall (Cleric), Väktarens kall
  (Siegemaster). Kärnan verkar alltid; perks kostar perk-poäng (1–3) vid Kallets altare och återställs gratis.
  Perk-poäng (Siralims Perk Points): 2 från start, +1 per klarad Realm Quest på ny Realm och djup (0.18; förr
  +1 för varannat klarat djup), egen pott per kall.
  Perk-nivåer (0.15): perks som är rena siffror har 2–3 nivåer som kostar poäng var; regelbrytare har en.
  Lånad perk (0.15, Siralims Anointment): en besegrad boss låser upp en plats där Kallet lånar en perk
  från ett annat kall, för poäng ur den egna potten.
- **Följeslagare** (Brokk, Syster Alva, Jägaren Eira, Solveig …): namn, roll, egen egenskap och en
  signaturhandling. Börja med 5–8, inte 30.
- **Troféer** ersätter Siralims smältning: besegrade monstertyper lämnar en trofé som ger bäraren monstrets
  egenskap. Vanlig = pålitlig byggdel, elit = specialiserad, boss = ändrar en regel (med kostnad).
- Varje hjälte får till slut 3 egenskaper: egen, trofé och artefakt.
- **Artefakter** (0.12, Siralims Artifacts): en per hjälte, smids hos Smeden för silver. Typen höjer en
  stat och avgör när förmågan i den slår till av sig själv: svärd vid Anfall (25 %), stav vid Förmåga
  (25 %), sköld vid Försvara (50 %), hjälm vid Provocera (50 %), stövlar i början av turen (15 %).
  Automatiska kast kostar inga Charges men räknas mot gränsen per tur.
- **Kartorna** (0.18): Kampanjkartan (ersätter Kryptporten) visar landet på pergament med Realms som
  områden; fördärvet viker för varje klarat djup. Där väljs Realm, djup och instabilitet; Förberedelser
  väljer sällskap och trofé. Kameran glider in i området till **rumskartan**: varje våning har 3–4 steg
  med 2–3 rum (Strid, Elit, Skattkammare, Helgedom, Lägereld, Portal) och sedan våningens slut/bossen.
  Lägereld = +3 Charges per förmåga (livet fylls redan efter varje strid). Helgedom = välj en gåva eller
  Pandemonium. Portal = svårare strid och sedan skatt. En körning blir 8–10 strider. Charges är Siralims
  (4–8 per förmåga, som 0.13): striderna på kartan är svagare (mötena i `realms.json` "pools" har
  `stat_mult` ~0,65–0,72) och lägerelden före våningens slut fyller på.
  **Rumsögonblick** (0.18, `scripts/rooms/`, `docs/rum3d.md`): skattkammare, helgedom, lägereld och portal
  spelar ett kort 3D-ögonblick (`RoomMoment`) i Realmens stil innan rummets ruta; stridsrum har inget. Ett
  tryck hoppar över; RUMSÖGONBLICK PÅ/AV på rumskartan (`Profile.room_moments`). Ljud: room_door,
  room_chest, room_lock.
  **Kartornas stil** (0.18): gammal handritad karta i tusch. Rumskartan: små tuschsymboler (`InkArt`:
  kista, lägereld, altare, korsade svärd, sköld med kranium, dödskalle, virvel), streckade stigar med
  handdragen ojämnhet, bleka rum som inte nåtts och en paladinpjäs som glider längs stigen. Kampanjkartan:
  Drakvalvets tuschvinjetter (`assets/illustrations/`, `docs/illustrationer.md`) med tonade kanter och
  fördärvet som ett flytande bläck i en shader; kompassros, kartuscher, drake, svärd i sten, skelett och
  häxa bara i marginalen. Sigillet tonas bakom basen och nattlägret bakom lägret.
  **Realm Quest** (Jakt på Nemesis, Rensa 2 elitstrider, Rening 3 helgedomar) ger silver och en perk-poäng
  per ny kombination av Realm och djup. Körningen sparas i `user://run.cfg` efter varje rum.
- **Basen** (0.12, Siralims slott) ligger mellan körningarna: Kampanjkartan, Övningsgården (Arena),
  Kallets altare (Enchanted Wardrobe, 0.13), Smeden, Makron och Biblioteket. Förlust eller klarad krypta leder hem. Silver ges per vunnen strid.
- **Djup** (0.14, Siralims Realm Depth): väljs på kampanjkartan, nästa öppnas när föregående är klarat. Fiender
  +8 % stats per djup (inte Speed), silver +25 % och troféchans +15 procentenheter per djup.
- **Fiender** (0.14): alla har egenskaper som makrona måste svara på (Benrustning, Jägarblick, Gravpakt,
  Taggig utmaning, Glödhetta). Benfursten är Resistant (halv effekt av debuffar) och vredgas under 50 % liv.
  Tryck och håll på en figur i striden för att granska den (Inspect, kostar ingen tur).
- **Realms** (0.16, Siralims Realms): väljs på kampanjkartan, `data/realms.json`. Kryptan (Benfursten) och Det
  fördärvade kapellet (Kultist, Gast, Fallen riddare, Häxa, Botgörare och bossen Den fallne biskopen, som är
  immun så länge en Kultist lever). Djup och skalning gäller alla Realms. Nya debuffar: Tystad (inga
  förmågor; makrorader med förmågor hoppas över), Sårbar (+50 % skada) och Försvagad (−50 % skada).
  Troféer har `rarity` (common/elite/boss); bossens trofé ändrar en regel med en kostnad.
- **Instabilitet och våningsregler** (0.17, Siralims Realm Instability och Realm Properties): på kampanjkartan
  väljs instabilitet 0–3. Nivå n ger n synliga och n dolda regler för hela körningen (`data/floor_rules.json`,
  t.ex. De döda vaknar, Förseglade ord, Vaksamma vakter, Speglande ben, Kaosvind), mer silver och bättre
  troféchans. Dolda regler avslöjas när de slår till (händelsen `rule`).
- **Troféjakt** (0.17): sällsynta elitvarianter (5 %, mer med djup och instabilitet) glöder, har ett eget
  namn och en egen regelbrytande trofé (som de själva bär). Bosstroféer kräver tre segrar mot samma boss
  (Siralims Masters, `Profile.boss_wins`). Biblioteket visar alla troféer; Inspect visar vad ett monster lämnar.
- **Död:** en död figurs egenskaper slutar verka, även Paladinens kall, och verkar igen när den väcks.
- **Stats och skada** (0.13, som Siralim): Health, Attack, Intelligence, Defense, Speed. Attack =
  (max(Atk − Def, 0) + 1 % Atk) × mod, Spell = max(Int × nivå − Def, 0) × mod, Indirect = × mod − 20 % Def.
  Försvara: −35 % skada och +50 % Defense; Provocera: −35 % Defense. Krit och undvikande från Speed-kvoten
  (vårt val, formeln är inte publicerad). Barriär tar skada före livet. Se `docs/research/siralim.md` §12.
- **Strid:** Siralims tidslinje – snabbheten avgör startplatsen, den som agerat läggs längst ned, inga
  rundor. Hjältar väljer Anfall, Förmåga (2–3 per hjälte, med Charges som räcker hela körningen),
  Försvara, Provocera eller Makro. Fiender visar sin avsikt och väljer nästa i slutet av sin tur.
- **Makron** (kärnsystem, som i Siralim): upp till 20 rader per makro, subjekt + villkor + handling (+ mål),
  uppifrån och ned, första raden som passar och går att utföra vinner. Tilldelas per hjälte, med
  standardhandling Makro/Manuell. Auto kör makrona och stannar när inget passar. Förklaringsloggen
  visar varför ("rad 2 matchade: …"). Regler, källor och våra val: `docs/plan/0.11-makron.md`,
  `docs/research/siralim.md` §9–9b.
- Nästa steg: artefaktnivåer och fler platser, fler kall (Warden, Inquisitor …), perk-ranks, Realm-traits
  per våning, buffar som höjer stats. Idéer för basen: `docs/research/siralim.md` §10c–10d.
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

- `src/game/run_state.gd` – en körning: kall och perks, sällskap, våning (`FLOORS`), troféer och vem som bär dem,
  artefakter; `new_run()` och `new_practice()` (Övningsgården: valfritt möte, fulla Charges).
  `src/game/profile.gd` – det som varar mellan körningar: silver, samlingen, artefakter (`forge()`),
  valt kall och köpta perks per kall (`buy_perk()`, `reset_perks()`, `perk_points()`, `active_perks()`), senaste sällskap, övningstroféer, valt och
  djupaste klarade djup (`choose_depth()`, `clear_depth()`), perk-nivåer (`perk_rank()`) och lånade perks
  (`bosses_defeated`, `anoint()`, `anointed`). Sparas i `user://progress.cfg`.
  `src/game/room_map.gd` – `RoomMap`: en våning ur ett frö (`generate()`, `choices()`, `problems()` för kraven).
  RunState håller kartan: `start_expedition()`, `enter()`, `battle_opts()`, `battle_won()`, `campfire()`,
  `treasure()`, `shrine_options()`/`apply_shrine()`, `next_floor()`, questen och `save()`/`load_from()`.
  `scripts/game/run.gd` är autoloaden `Run` som byter scen (bas → kampanjkarta → rumskarta → rum/strid →
  läger → rumskarta … → bas;
  bas → Övningsgården → strid → Övningsgården) och sparar makrona i `user://macros.json`
  (startmakron i `data/macros.json`).
  Skärmar i `scripts/screens/`: `base_screen` (första skärmen), `campaign_screen` (kampanjkartan),
  `room_map_screen` (rumskartan), `parchment.gd` (pergamentets shader), `start_screen` (Förberedelser),
  `altar_screen` (Kallets altare), `practice_screen`, `smith_screen`, `library_screen`, `camp_screen`, `macro_screen`. De flesta ärver
  `tap_screen.gd` och reagerar vid släpp.
- `src/combat/` – `CombatSim` (tidslinje, ren logik, händelselista, skadeformlerna som statiska
  funktioner: `attack_damage`, `spell_damage`, `indirect_damage`, `combine_mods`, `crit_chance_for`,
  `crit_bonus`, `dodge_chance`), `CombatUnit` (stats, `defense_now()`, `stat()`, `barrier`), `GameData`,
  `MacroRunner` (makron: `decide()` ger handling + förklaring, `describe_line()` texten i editorn).
  `create(…, artifacts, depth)` skalar fienderna (`depth_mult`, mötets `stat_mult`, `scale_unit`) och ger hjältarna artefakter (`equip_artifact`): stat + en genererad egenskap
  `artifact_<hjälte>` som lyssnar på `acted` (efter handlingen) eller `turn_start` och kör effekten
  `cast` (kastar förmågan gratis, action `"artifact"`). Datan kopieras per strid – använd `sim.data`.
  Flöde: `begin()`, sedan `act(action, target, ability)` när `needs_input()` annars `ai_act()`; töm `drain_events()`.
- `data/artifacts.json` – artefakttyperna (stat, utlösande handling, chans).
- `data/floor_rules.json` – våningsreglerna (namn, text, silver, `min_instability`, `hidden_only`). Effekterna
  ligger i `CombatSim` (`_rule()`, `_rule_hit()`); `RunState.roll_rules()` slumpar dem.
- `data/realms.json` – Realms med namn, text och våningar (möten i encounters.json). `RunState.set_realm()`,
  `floor_ids`; `Profile.realm`.
- `data/oaths.json` – Kallen: Siralims Specialization och perks med pris. Kärnan och perkarna är
  egenskaper i `traits.json` (perks har `"oath"` och `"perk": true`).
- `data/*.json` – förmågor (`power` = modifieraren i skadeformeln, `tier` för spells, helning = Int ×
  `power`, `cooldown` i egna turer), auror (`duration` i ägarens turer, `next_attack_mult`, `taunt`,
  `defense_mult`, `damage_taken_mult`, `buff`, `dot`/`hot`), hjältar och fiender (`stats`: health, attack,
  intelligence, defense, speed; signatur, egenskaper, regler för avsikter), möten (sällskap + fiender), egenskaper (`traits.json`).
- Egenskaper: lyssnar på en händelsetyp (`trigger`) och kör effekter när `when` stämmer, eller ändrar
  siffror (`modify_damage`, `modify_damage_taken`, `modify_heal`). Kan sätta igång varandra i kedjor
  (max 4 steg), aldrig sig själva. `once_per_turn`, `internal_cooldown` (rundor), `chance`.
  `"scope": "party"` = gäller som om varje levande allierad bar den (Specialization; "self" i `when` är då
  var och en). Effekter: damage (`power`, `pct_of_event` eller `stat` + `pct`), heal, aura, barrier,
  revive, restore_charge, cast; `actor` (event_unit/event_target/event_source) väljer vem som utför.
  Mål: self, allies, enemy, enemies, random_enemy, weakest_ally, dead_ally eller ett händelsefält.
  `modify_damage_taken` kan ge `dodge_add` (undvikande), `immune_while_ally_kind` eller
  `immune_while_allies` (immun, `CombatSim.is_immune`); auror kan ha `silence` (`is_silenced`).
  Triggern `battle_start` kommer före första turen. Träffar som en Barriär tar sätter inte igång något.
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
  (Kenney-ljud ligger i `k_*`-mappar). Stämning per Realm (`ambience_crypt/`, `ambience_chapel/`).
  Musiken (`music/`) och menyljuden (`ui_*`) spelas av `Run.audio` så att de fortsätter mellan scenerna:
  `play_music()` korstonar, `Run.ui()`/`ui_tap()` i basens skärmar. Förmågor har `sound` (träffen) och
  `cue` (när handlingen börjar; annars vapnet eller skolan). Mappning: `docs/ljud.md`.
  `-- --log-sfx` skriver ut varje ljud som spelas.
- `tools/gen_sfx.py` – syntetiserar egna ljud och kryptstämningen till `assets/audio/`.
  `tools/gen_audio.py` – komponerar musiken och bygger handlingsljuden (numpy + soundfile, Kenney CC0).
- `tests/combat_bot.gd` – simulerade spelare (BASIC/MACRO/TUNED) för balanstester.
  `tests/perk_report.gd` mäter varje perk för sig.

Balans (0.18, hela körningar på rumskartan med Siralims Charges, djup 1, 100 körningar, enkel väg):
kryptan startmakrona 48 %, TUNED 62 %; kapellet 44 % / 68 % (snabbmätning efter sista justeringen; hela
`tests/balance_report.gd` med artefakter, perks, djup 3 och instabilitet 2 kördes på läget innan:
med en artefakt 78–95 %, artefakt + Gryningens kall med Krigsmaskin 100 %, djup 3 bara starka byggen 61–95 %,
instabilitet 2 TUNED 2–15 %, artefakt + perks 55–67 %). Questen klaras i ~30 % av körningarna.
**Kallens kärnor** (startmakrona, kryptan) 48/48/41 % i 0.18; spridningen var 29–54 % före Charges-ändringen
och ska ses över efter 0.18.
Siffrorna nedan gäller 0.17 (tre strider per körning).
Balans (0.17, `tests/balance_report.gd`, hela kryptan, siffror från 0.16 utan elitfiender): djup 1 – BASIC förlorar (7 % av Benkryptan, 0 % av
resten), startmakrona 42 %, TUNED 66 %, TUNED + en artefakt 93 %, TUNED + bästa perks inom 2 poäng 63–93 %,
med lånad perk upp till 96 % (Gryningens kall + Krigsmaskin), artefakt + perks 99 %, fyra artefakter + perks
100 %. Kallens kärnor med startmakrona 36–42 %. Djup 3 (fiender ×1,16, 3 poäng, med en artefakt): bästa
perks 26–43 %, med lån upp till 68 %, fyra artefakter + perks 94 %.
Det fördärvade kapellet på djup 1: startmakrona 44 %, TUNED 59 %, med en artefakt 89 %, med artefakt + Krigsmaskin
100 %; djup 3: artefakt + bästa perks 57 %, fyra artefakter 87 %.
Instabilitet (0.17, djup 1): instabilitet 0 med elitfiender är ungefär som utan (kryptan MACRO 39/42 %, TUNED
63/66 %). Instabilitet 2: TUNED 5–6 %, artefakt + bästa perks 44–53 %. Reglerna kostar olika mycket och ger
silver därefter (De döda vaknar −59 procentenheter och +60 % silver; Tung luft och Vissnad nåd nästan
ingenting och +5 %); Kaosvind (bara instabilitet 3) gör kryptan omöjlig för TUNED.
**Känd brist:** perk-nivåerna väljs aldrig i de bästa byggena – regelbrytarna (Krigsmaskin, Räkenskap, Ljusets
hand) slår en extra nivå siffror. Krigsmaskin är starkast och lånas helst. Brokks sköld med Helande ljus
(fria helningar) väger tungt. I kapellet vinner BASIC ibland mot biskopen (17 %) och första våningen (11 %):
bossen är farlig mest för att Charges tar slut. Nästa balans: billigare eller starkare nivåer, dyrare
Krigsmaskin, ett farligare biskopsskede.
Gränser per tur som i Siralim: `TURN_LIMIT` attacker/besvärjelser/helningar.

## Kommandon

```bash
# Kör tester
godot --headless --path . --script res://tests/run_tests.gd

# Starta spelet
godot --path .

# Balansrapport per våning och för hela kryptan (BASIC/MACRO/TUNED, 100 strider var), och per kall
godot --headless --path . --script res://tests/balance_report.gd

# Varje perk för sig (hela kryptan med startmakrona)
godot --headless --path . --script res://tests/perk_report.gd

# Skärmdump av spelet (sparas efter 30 bildrutor, sedan avslut)
godot --path . -- --screenshot=/tmp/shot.png --frames=30

# Starta direkt i en strid (våning 0–2), låt AI:n spela, spola fram 10 turer, fast slumpfrö
godot --path . -- --floor=2 --demo --turns=10 --seed=5

# Visa lägret mellan striderna direkt
godot --path . -- --camp

# Rumskartan med en ny körning (efter --realm, --depth, --instability)
godot --path . -- --realm=chapel --map

# Öppna en plats i basen direkt (--gate = kampanjkartan, --practice, --altar, --smith, --library)
godot --path . -- --smith

# Kallets altare med den lånade perken upplåst (som om Benfursten var besegrad)
godot --path . -- --anoint

# Strid med instabilitet (slumpade regler) eller med bestämda regler
godot --path . -- --instability=2 --floor=0 --demo
godot --path . -- --rules=risen_dead,mirror_bones --floor=0 --demo

# Strid i Det fördärvade kapellet (våning 0–2)
godot --path . -- --realm=chapel --floor=2 --demo

# Strid på ett annat djup (bara den körningen)
godot --path . -- --floor=2 --depth=3 --demo

# Strid med ett annat kall (bara den körningen), med alla dess perks
godot --path . -- --oath=oath_ward --all-perks --floor=1 --demo

# Strid med artefakter (bara den körningen): --artifact=<hjälte>:<typ>:<förmåga>
godot --path . -- --floor=0 --demo --artifact=brokk:shield:healing_light

# Öppna makroredigeraren direkt (--edit-line öppnar radeditorn)
godot --path . -- --macros --edit-line

# Spela in bildsekvens (PNG) för att granska rörelser
godot --path . --write-movie /tmp/mov/f.png --fixed-fps 20 --quit-after 200 -- --floor=0 --demo --seed=3

# Animationslabb: filma en figur på nära håll (se tools/anim_lab.gd för steg)
godot --path . res://tools/anim_lab.tscn --write-movie /tmp/lab/f.png --fixed-fps 20 --quit-after 50 -- --unit=eira --seq=idle:0.2,attack:1.2

# Bygg APK för telefonen (release-mallen, ~2 MiB mindre än debug). Signeras med debug-nyckeln via miljövariabler, så att
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
- **Storleken styr inte spelet.** 30 MiB är bara gränsen för att skicka filen i chatten; större APK:er
  läggs som GitHub Release i det privata repot (`gh release create v<version> export/rpg007.apk`) och
  laddas ned i GitHub-appen. Det som räknas är att spelet flyter och får plats på en telefon (Google Play:
  200 MB bas, sedan asset packs). Banta det som inte syns, inte det som gör spelet bättre.
- `sigrun.glb` exporteras inte; Paladinens mantel, Brokks hjälm och Alvas lånade
  animationer kommer från `sigrun_delar.glb` (`node tools/extract_parts.mjs in.glb ut.glb [--anims=A,B] Del …`).
  Modellerna saknar oanvända animationer, och LOD- och skuggmeshar genereras inte (`.glb.import`). Lägg
  till en animation i en modell igen ur originalet i Drakvalvet om en ny figur behöver den.
- Exporten är utan Gradle (`gradle_build/use_gradle_build=false`), endast arm64-v8a. Oanvända ljud
  (röstrepliker, gamla WoW-ljud) och docs/ utesluts i `exclude_filter` i export_presets.cfg.

Tester: lägg `tests/test_*.gd` som ärver `res://tests/test_case.gd`, metoder som börjar på `test_`.
