# rpg007

"Siralim Ultimate i 3D" för mobil (Android först, iPhone senare via moln-Mac). Turordningsstrider där
djupet ligger i hur egenskaper kombineras. Spelaren är en rättfärdig **paladin** (inte en besvärjare)
som leder ett sällskap av följeslagare i Baldur's Gate-stil.

## Ledstjärna

**Siralim är en verktygslåda, inte en regel** (VD 2026-10-27). Målet är djup och rollspelskänsla, inte en kopia.
Pröva varje idé så här: 1) gör den kombinationerna roligare eller världen mer levande? 2) vet spelaren vad nästa steg
är? 3) har Siralim redan löst det? Ta då deras lösning, den är prövad, men vi får gå ifrån den. Baldur's Gate 3 är en
stor inspiration. Siffror får gärna vara många om de är begripliga och märks (förbered dig mot ett känt hot, känn
skillnaden när en stat växer). Undvik dess baksidor för VD: långt mellan striderna, mycket prat, krångliga quests och
skräpföremål att hålla reda på.

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
- **Paladinens namn** (0.24.2, som i Siralim): en ny profil frågar "Vad heter du, edsvurne?" (`NameEntry`, ett textfält
  som öppnar telefonens tangentbord, högst 16 tecken, tomt blir "Paladinen"). `Profile.hero_name`, `set_hero_name()`;
  `Run.apply_name()` sätter namnet i datan för "paladin" (stridens ram, hjältebladet, makroskärmen, korten; striden
  läser sin egen data och gör samma). Repliker använder `{namn}` (`Dialog.fill`) ibland, inte i varje rad. Namnet
  skrivs om hos Broder Alrik ("Skriv om mitt namn i krönikan"). Rollen ("Paladinen", titeln "Edsvuren") står kvar
  där den beskriver klassen. Flaggor: `--ask-name=<plats>` på sparplatsskärmen, `--name=Tran`, `--rename` i borgen.
- **Följeslagare** (Brokk, Syster Alva, Jägaren Eira, Solveig …): namn, roll, egen egenskap och en
  signaturhandling. Börja med 5–8, inte 30.
  **Lärjungar och Värdshuset** (0.23, Siralims rekrytering och Menagerie, `docs/plan/0.23-vardshuset.md`): en ny
  profil börjar med Paladinen ensam; Imma (barndomsvännen, bågskytt, Fingerfärdig stjäl fiendens buff åt den
  svagaste – vårt val, förebild Mesmerist) ansluter i introt. De andra befrias ur **fånge-rum** på rumskartan:
  varje Realm har egna lärjungar per djup (`realms.json` "disciples", en i taget sedan 0.24; Kryptan: Syster Alva på
  den andra nedstigningen (`after_descents`, `Profile.descents`), sedan Brokk (bevakad), Eira, Tove, Solveig, Sefir;
  Kapellet: Lirien, Ragnhild, Hulda, Ronja). Profilens första nedstigning gör Paladinen ensam i första striden och sedan med Imma (hela kryptan, 0.25),
  med en trappa i fiendernas stats per våning: ×0,70 / ×0,88 / ×0,81 för Benfursten (`RunState.FIRST_DESCENT_RAMP`, vårt
  val, docs/formler.md §9; ungefär 80 % med en ny profils makron). Alva räddas tidigt på den andra, på våning 1, och
  hennes makroförslag lär ut ett villkor ("hela den som har lågt liv"); följeslagare med ett förslag börjar utan den
  raden (`Run.starter_lines`). De ansluter direkt på nivå
  1–2 om det finns plats (Paladinen + 3), annars väntar de i **Värdshuset**, där man väljer sällskap och de som
  stannar behåller sin nivå. `Profile.recruited`, `recruit()`, `set_party()`; `RunState.place_prisoners()`;
  `Run.rescue_prisoner()`. Ikapphämtning (vårt val): +50 % erfarenhet per nivå under sällskapets snitt, högst ×3.
  Fiender efter sällskapets storlek (vårt val): högst sällskapet + 1 fiender (0.23.3, `CombatSim.enemy_lineup`,
  `EXTRA_ENEMIES`: dubbletter går först, aldrig ledaren, bossen eller den som gör en annan immun) och
  `CombatSim.PARTY_SCALE` (×0,54 för två, ×0,64 för tre). `BALANS=forsta` mäter första nedstigningen med en ny profils makron.
  När en ny sorts hjälte ansluter föreslår spelet en makrorad (`heroes.json` "macro_hint"). Äldre profiler
  behåller sina fyra och får Imma i Värdshuset.
  **Torun Bergsbrytare** (den femte, `docs/ideer/chat-femte-foljeslagaren.md`, `chat-torun-repliker.tsv`): 46, bröt malm i
  Trollbergets järngruva, brodern blev kvar bakom en nedrasad port; torr humor, räknar allt. Hon kommer när den femte platsen
  öppnas (`Run.check_slot_unlock` → `Run.fifth_arrives`: ankomstscenen `dialog.json` "party_slot" "torun" med Gorm, paladinen
  och Imma, sedan `Profile.recruit`); Broder Alriks tre rykten före det (`alrik_torun_rumour_*`, `not_recruited`). Andra
  tank och avbrytare: **Inte färdigt än** (`torun_not_done`, `"interrupt"`) – står hon **Beredd** (förmågan Stå beredd: Försvara,
  Provocera och statusen `torun_ready`, nedkylning 3) när en fiende helar eller släpper en varslad attack avbryter hon det
  (`CombatSim._interrupted`, händelsen `interrupt`): fiendens tur går åt, beredskapen förbrukas. Kostnaden är hennes tur och
  nedkylningen. Tystad behövs ändå: inte när hon själv är Tystad/sover/frusen, inte laddningar som bara bryts på annat sätt
  (Midnatt), en boss eller Resistent fiende får laddningen uppskjuten en tur i stället, och bara Tystad hindrar en laddning
  innan den börjar och ger Vacklande – som hennes Kilslag slår 50 % hårdare mot. Makrovillkoret `intends_heal` ("tänker
  hela"). Repliker under nedstigningen (Trollbergets rader med `"realm": "mountain"`, `Dialog.realm_ok`), avbrottets rader
  efter striden (läget `interrupt`). Figuren är druidens kvinnokropp med Torvalds tvåhandsslag (`borrow_skip` utan fingrarna),
  en slägga (`placeholder_figure`). `--party=torun,imma` väljer sällskapet för en påhittad profil.
  Balans (en justeringsomgång, `docs/balans/balanslogg.md`): Stå beredd provocerar också, Health 120, Attack 10, Defense 6,5,
  Speed 11, Kilslag 150 % med 8 Charges. Som femte i Trollberget djup 1–3 25/15/25 % mot Immas 35/40/62,5 % (fyra utan femte
  0/0/7,5 %); svagare än Imma men inget måste-val åt något håll. Kilslag slår också 50 % hårdare mot ett troll med Svedd hud
  (`bonus_vs` kan vara en lista, `CombatSim.bonus_vs_for`; startmakrot har raden): i en enskild väktarstrid 73 av 77 slag, men
  nedstigningarna oförändrade – hennes 8 Kilslag är slut före väktaren (nötningen avgör, inte förmågan).
- **Troféer** ersätter Siralims smältning: besegrade monstertyper lämnar en trofé som ger bäraren monstrets
  egenskap. Vanlig = pålitlig byggdel, elit = specialiserad, boss = ändrar en regel (med kostnad).
  Hjältarna behåller sina troféer (0.26.3, som i Siralim, `Profile.worn`, `wear()`, `keep_worn()`): de följer med i varje
  körning och i Övningsgården tills man byter i lägret eller i Förberedelser; allt som hittas hamnar i samlingen.
  **Trofélåset** (0.30.48, fynd 13): en trofé i en artefakt sitter kvar tills den tas ut hos Smeden (`Profile.wear()` och
  `RunState.equip()` vägrar); rutorna visar var en trofé sitter (`Profile.trophy_place`: "Bärs av Brokk", "I Brokks hjälm")
  och att ta en trofé från en annan hjälte frågar först (`Profile.move_question`, `ConfirmBox`). Tester: `test_trophy_lock.gd`.
  En andel av en träff (`pct_of_event`, t.ex. följdanfall) blir aldrig kritisk igen.
  Gruppläkaren (0.30, vanlig): Irrblosset lämnar **Den delade lågan** (`shared_flame`): bärarens helning ger hela sällskapet
  Läkning i 1 tur, en gång per tur; villkoret `not_hot` gör att en HoT som tickar inte räknas (`tests/test_shared_flame.gd`).
  **Namn och lärdom** (VD 2026-10-23, `docs/ideer/chat-trofeer-1.tsv`): en trofé är ett föremål man tagit eller en lärdom man
  dragit, aldrig en ed, en pakt, en mottagen kraft eller en kroppsdel; ett föremål från en ockult fiende låter besegrat eller
  brutet. Varje trofé har `lesson` ("{bärare} har lärt sig …", `GameData.lesson()`), kursiv under effekten (`UiStyle.lesson`) i
  Biblioteket, lägret, Inspect och hjältebladet (`tests/test_trophy_slot.gd`).
- Varje hjälte får till slut 3 egenskaper: egen, trofé och artefakt.
- **Artefakter** (0.12, Siralims Artifacts): en per hjälte, smids hos Smeden för silver. Typen höjer en
  stat och avgör när förmågan i den slår till av sig själv: svärd vid Anfall (25 %), stav vid Förmåga
  (25 %), sköld vid Försvara (50 %), hjälm vid Provocera (50 %), stövlar i början av turen (15 %).
  Automatiska kast kostar inga Charges men räknas mot gränsen per tur.
  **Nivåer och material** (0.20, Siralims Artifacts, `src/game/forge.gd`, `data/materials.json`): nivå 1–10
  hos Smeden för silver (`Forge.LEVEL_COST`, *anpassning*: Siralim har 50 nivåer och Brimstone); varje nivå
  stärker typens stat, chansen, materialen och tricken med 10 %. Platserna öppnas i originalets ordning:
  Stat 2, Trick 3, Stat 5, Trick 7, Stat 9, Nether 10 (ingen Trait-plats, trofén är den). **Bärnsten** (Amber,
  tio färger, en eller två stats, 5 per plats) och **trick** (Brynsten, Taggsten, Rustningsskrot, Hal sten,
  Arkant sigill, Styrkans skiffer, Sårbarhetens kuriosa) förstörs när de tas ut; en **Nether Stone**
  (slumpad, 1–4 egenskaper efter sällsynthet: stat, trick eller en troféegenskap, sällsynthetstal) går
  tillbaka till förrådet. Fynd i rummen (`Forge.FINDS`, `Run.roll_finds`): bärnsten överallt, trick och
  Nether Stones bara på det djupaste djupet man nått (originalets bonus), mer med instabilitet. Typen kan
  bytas utan att nivån och materialen går förlorade (vårt val). Fynden syns på segerskärmen (0.29.5: med vad de gör, `Forge.find_effect`), i
  skattkammaren och på rumskartan; det första fyndet efter introt ger uppdraget "Visa fyndet för Hedda" (`Profile.find_quest`,
  `dialog.json` "find_quest"; Hedda förklarar materialen och platserna och ger 20 silver; `--find-quest`); sällsynta stenar får en egen scen (`find_reveal.gd`). Ljud:
  `tools/gen_forge_sfx.py` (find_*, forge_level, slot_open, socket).
- **Kartorna** (0.18): Kampanjkartan (ersätter Kryptporten) visar landet på pergament med Realms som
  områden; fördärvet viker för varje klarat djup. Där väljs Realm, djup och instabilitet; Förberedelser
  väljer sällskap och trofé. Kameran glider in i området till **grottan** (0.27, `docs/plan/0.27-grottan.md`, ersätter
  0.18:s rumskarta med steg och rum): två våningar per körning (`RunState.FLOORS_PER_RUN`), var och en ett rutnät 8×8
  (`src/game/grotto.gd`, `Grotto`, öppen plan utan klippor), genererat ur ett frö efter regler (`Grotto.problems()`):
  start vid en kant, trappan (första våningen) eller bossen minst 5 steg bort, synlig från start men låst tills våningens
  quest är klar; 5–6 fiendegrupper (0.27.0, först 6–8) ur Realmens pooler (tier 0–2 efter våning och avstånd, `FAR_TIER_DIST`), 1 elitgrupp
  (2 om questen är Rensa) minst 4 steg bort med en lägereld inom 3, 1–2 bevakade och 3–4 obevakade skatter, 1 helgedom,
  1–2 lägereldar, quest-föremål och kanske en fånge; inga grupper bredvid start och högst två grupper intill varandra.
  **Dimma:** bara besökta rutor (och målet) syns. Ett tryck går ett steg till en granne; ett tryck på en besökt ruta får
  pjäsen att gå dit själv (`RunState.can_step`, `step`, `Grotto.path`). En grupp visas som ett kort i panelen (fiender,
  storlek, egenskaper, möjliga troféer, varning för elit): ANFALL (`Run.fight_here`) eller BACKA (`back`); en sedd grupp
  spärrar de obesökta rutorna intill sig tills den är besegrad (Dungelot, `Grotto.blocked`, `RunState.seen`).
  **Questen** (en per våning, `RunState.roll_quest`): Jakt på Nemesis, Rensa (2 elitgrupper) eller Samla (2–3 föremål,
  alltid bevakade) eller **Bryt två av tre sigill** (prov, ChatGPT:s förslag, `docs/provspel/chatgpt-om-textspel.md`; quest
  `seals`, bara på den sista våningen och aldrig på den första nedstigningen, 1 av 4): tre sigill (fiendens värn, `kind`
  seal) i olika fjärdedelar, var och en bevakad av en lika stark vanlig grupp ur den svårare poolen (VD: valet gäller
  fördelen, inte att slippa en elit). Vakten besegrad = sigillet brutet (`RunState.break_seal`); två brutna öppnar bossen
  och det tredje håller och syns på kartan: dess fördel går till slutstriden (`boss_seals`, sparas, högst en per körning;
  `end_fight_seals`, CombatSim `boss_traits` ger bossen, annars ledaren, egenskapen): Murens sigill (Barriär 20 %; mot en
  väktare 6 % på alla, `GUARDIAN_WARD`, så att Kistornas råd inte blir ogenomträngligt), Vaksamhetens sigill (först på
  tidslinjen, Smidig två turer, första anfallet +30 %, auran `seal_strike`), Uthållighetens sigill (helas 1,5 % per tur; 2–3 %
  var starkast i botarna), traits.json `seal_*`. Sigillkortet och bosskortet visar fördelen; rubriken "KVAR ÅT BOSSEN".
  Botarna lämnar ett slumpat sigill (`SIGILL=nara|ward|haste|mend` ändrar), `GROTTA_QUEST=1` visar våningar per quest,
  `BALANS=sigill` (`SIGILL_MOTE=<möte>`) bossen med varje fördel. Flaggor: `--quest=seals` före `--map`, `--reveal-seals`, `--break-seals=<n>`, `--seals-left=ward,mend`;
  textspelet `TEXTSPEL_QUEST=seals`. Tester: `tests/test_seals.gd`.
  Belöningen (silver, perk-poäng) ges för den sista våningens quest, en gång per körning som förut.
  Lägereld = +3 Charges per förmåga en gång, och **troféer byts bara vid en lägereld** (VAL; lägret i läget "campfire",
  `Run.open_campfire_camp`; efter en strid väljer man bara en ny trofé). Helgedom = välj en gåva eller Pandemonium.
  Gåvorna Värnad (−20 % skada) och Styrka (+15 % skada) och Pandemoniums Välsignade sköld (−30 %) varar hela nästa strid
  (strid-justering, auror `shrine_*` med `"battle": true`, `RunState.SHRINE_AURAS`; förr tickade de bort vid första turen).
  Charges är Siralims (4–8 per förmåga) och räcker hela körningen. Botarna (`BALANS=grotta`): ca 12 strider per körning
  om man slåss mot allt man kliver på, 6–9 om man backar från vanliga grupper.
  **Rumsögonblick** (0.18, `scripts/rooms/`, `docs/rum3d.md`): skattkammare, helgedom, lägereld och portal
  spelar ett kort 3D-ögonblick (`RoomMoment`) i Realmens stil innan rummets ruta; stridsrum har inget. Ett
  tryck hoppar över; RUMSÖGONBLICK PÅ/AV på rumskartan (`Profile.room_moments`). Ljud: room_door,
  room_chest, room_lock.
  **Kartornas stil** (0.18): gammal handritad karta i tusch. Rumskartan: små tuschsymboler (`InkArt`:
  kista, lägereld, altare, korsade svärd, sköld med kranium, dödskalle, virvel), streckade stigar med
  handdragen ojämnhet, bleka rum som inte nåtts och en paladinpjäs som glider längs stigen. Kampanjkartan:
  Drakvalvets tuschvinjetter (`assets/illustrations/`, `docs/illustrationer.md`) med tonade kanter och
  fördärvet som ett flytande bläck i en shader; kompassros, kartuscher, drake, svärd i sten, skelett och
  häxa bara i marginalen (0.18.2: häxan och Väktaren är vinjetter). Borgen (basen.webp) tonas bakom basen,
  nattlägret bakom lägret och sällskapet (sallskapet.webp) bakom Förberedelser.
  Rumssymbolerna, paladinpjäsen, kompassrosen, kartuschen, draken och svärdet i stenen kommer ur VD:ns
  symbolark: `godot --headless --path . --script res://tools/cut_symbols.gd` klipper ut dem enligt rutorna i
  `tools/symbolark.json` till `assets/illustrations/icons/` (pergamentet blir genomskinligt med en
  luminansmask). Kör om med nya koordinater när ett nytt ark kommer. Enskilda bilder (t.ex. skelett.webp) är
  egna källor i samma fil. Källbilderna (symbolark, sigillet, skelett) exporteras inte (`exclude_filter`).
  **Realm Quest** (Jakt på Nemesis, Rensa 2 elitstrider, Rening 3 helgedomar) ger silver och en perk-poäng
  per ny kombination av Realm och djup. Körningen sparas i `user://run.cfg` efter varje rum.
- **Nivåer och personlighet** (0.19, Siralim): hjältarna får erfarenhet av vunna strider (rumstyp × djup²,
  även stupade) och varje nivå ger +20 % mot nivån innan för nivå 2–10, sedan ett steg som krymper mot 13 % (balans v1,
  `HeroStats.strength`; förr +30 % av basen, +32–40 % för nivå 6–9); fienderna följer samma kurva på sin nivå. Inget tak, som i Siralim: den som kör
  fast går tillbaka till ett lägre djup och tränar.
  En av 20 personligheter låter en stat växa 40 % och en annan 20 % (byts i Biblioteket, räknas om bakåt).
  Nivåerna sparas i `Profile.heroes`. Fiendernas nivå följer bara djup och våning, som i Siralim
  (`HeroStats.enemy_level`: 5 × (djup − 1) + 2,25 + 1,5 per våning; väntad nivå 3, 8, 13 …).
  *Vårt val* (originalet okänt): erfarenhet 17 × rumstyp × djup², så att lägre djup ger mindre men går att
  träna på, och till nästa nivå 5 · L² + 10 (15, 30, 55, 90 …): de första nivåerna går fort. **Hjältebladet** (`hero_screen`, från
  lägret, Förberedelser och Biblioteket): nivå, erfarenhet, fiendernas nivå på valt djup, personlighet, stats per källa
  (`HeroStats.SOURCES`; 0.20 lägger till material och Nether Stone), vad de
  betyder i skada och helning mot en typisk fiende, egenskaper med körningens statistik, förmågor,
  artefakt och historik. **Bidraget** (STATS, högra spalten, "DET HÄR HAR <NAMN> GJORT"): Denna nedstigning och Förra
  nedstigningen, bara det som inte är noll: skada, helat (överhelning), skyddat (Barriär hjälten gav), avbröt, stupat
  (`CombatSim.contrib` → `RunState.contrib` via `Run.award_battle`, `finish_contrib` → `Profile.last_contrib` i
  `Run.end_descent`; `RunState.contrib_rows`, även i textspelets hjälteblad; `--contrib-demo` för skärmdumpar).
  Nivåuppgångar syns och hörs på segerskärmen.
  **Nivåkurvan** (VD 2026-10-25, variant C "kurva" i `docs/plan/nivaer-och-charges.md`, VAL): en nivå L växer som
  tillväxtnivån g(L) = L upp till nivå 5 (de fyra första nivåerna lika tätt som förut), sedan 5 + 2,34 · (L − 5)^1,4
  (`HeroStats.old_level`/`new_level`, `KNEE`, `CURVE_A`, `CURVE_P`). Stats, fiendernas multiplikator (`enemy_level_mult`,
  räknad direkt i den gamla skalan) och den samlade erfarenheten följer 0.19:s kurva i g(L), så striderna är lika
  starka; bara antalet nivåer och hoppet per nivå ändras (+32–40 % på djup 2–3, +15 % på djup 10). Väntad nivå per
  djup 3, 6, 7, 8, 9, 10, 11, 12, 12, 13 (förr 3, 8, 13 … 48). En nivå nås när 0.19:s kurva når tillväxtnivån mitt
  emellan g(L − 1) och g(L) (`_threshold_xp`; prototypens senare tröskel kostade karriärbotarna ett djup).
  Karriärbotarna (`SOAK=karriar`, 40 × 18, samma frön, före → efter): djup efter 18 nedstigningar 6,8 → 6,5, vinst
  nedstigning 2–6 44 → 46 %, 7–12 45 → 45 %, 13–18 57 → 55 %, slipar 149 → 159 av 720; Paladinens nivå efter 18
  33 → 10,9, vunna strider med en nivåhöjning (2–18) ~28 → ~6 %. `BALANS=forsta`: oförändrad (kryptan "ensam, Imma
  efter strid 1" MACRO/TUNED 91/68 % i båda skalorna; karriärens första nedstigning 98 %).
  Ikapphämtningen och lärjungarnas startnivå räknar i den gamla skalan. Gamla profiler (`level_scale` saknas, nu
  `Profile.LEVEL_SCALE` = 2) räknas om en gång när de läses till den första nivå som är minst lika stark (VD: aldrig svagare;
  `HeroStats.convert_legacy`, `Profile.convert_levels`; 0.19:s nivå 7 → 6, 12 → 8, 24 → 10) och Broder Alrik
  förklarar det en gång (`levels_rescaled`, `alrik_levels_rescaled`). Segerskärmen visar hoppet i det striden gör:
  "Liv 120 → 158 · Rättfärdigt slag 14 → 19 skada" och helningen (`LevelJump`, samma som hjältebladet).
  Botarna jämför med den gamla skalan med `NIVAER=idag` (`HeroStats.legacy`). `--level=<n>` sätter sällskapets nivå.
  **Edsgrader** (VD 2026-10-25, VAL, inte Siralim): var tredje nivå (`HeroStats.OATH_RANK_EVERY`, `oath_rank`) får
  Paladinen en titel, "Edsvuren av första/andra … graden" (`Dialog.oath_rank_title`, `dialog.json` "oath_rank"), och en
  replik från en kamrat i sällskapet eller Gorm (`oath_rank_line`); inga siffror. Syns på segerskärmen och i hjältebladet.
  `--all-companions --level=5 --xp-bar=160 --floor=0 --demo --turns=300` visar en.
- **Borgen** (0.12 som basen, 0.24 "Hemmet", `docs/plan/0.24-hemmet.md`, `base_screen.gd` + `scripts/keep/keep_art.gd`):
  en planritning i tusch på pergament sedd uppifrån, som rumskartan; fördärvet flyter som bläck utanför murarna
  (shader), innanför kvällsljus, rök, gnistor och en härd som sprakar (`ambience_home`, `tools/gen_home_ambience.py`).
  Rummen och gångarna står i `data/keep.json` (planens pixlar, 1536×1024), inpassade i VD:ns bild
  `assets/illustrations/borgen.webp` (`-- --keep --keep-debug` visar rutor, dörrar och ljus; `KeepArt` ritar en tuschversion
  om bilden saknas). `-- --walk=<station>` startar en gång. Tryck i ett rum så går paladinpjäsen dit (1–2 sekunder) och sällskapet
  följer i en rad (med porträtt som pjäs om det finns); dubbeltryck hoppar fram. Personerna står vid sina platser med
  porträtt: Mäster Gorm i sin kammare vid kartbordet (Makron), utom när ett introsteg flyttar honom (`where`, `Intro.who_at`:
  vid altaret under eden och övningsuppdraget; altaret har annars ingen person och öppnas direkt, 0.24.3), smeden Hedda, Broder Alrik i biblioteket, vapenmästaren Stig, Mor Elin i
  värdshuset och portvakten Sven (namnen är förslag). **Samtal** (Siralims dialogruta, `Dialog`, `DialogBox`,
  `data/dialog.json`): personen hälsar, säger en vardagsreplik (nyheter först) och erbjuder tjänsterna som val, sist
  "Ingenting just nu". Porträtten läses från `assets/illustrations/portraits/<id>.png` (utklippta ur VD:ns ark
  `portrattark.webp` med `tools/cut_symbols.gd`, `"opaque": true`, `"out"`); Sven och följeslagarna utom Imma ritas som en tuschbyst. Befriade som inte är med bor i
  värdshuset. Kortraden längst ned är genvägar, sist **SÄLLSKAPET** (polering fynd 1, `party_screen`, logiken i `PartyOverview`):
  alla rekryterade med nivå, trofé, artefakt och dess troféplats, MED eller VÄRDSHUSET (ett tryck öppnar hjältebladet),
  och fliken SAMLINGEN med var varje trofé sitter (`Profile.trophy_place`), de som bärs först, sedan boss/elit/vanlig;
  `--party`, `--party-collection`, `--trophy-demo` (efter `--all-companions --forge-demo`). Sällskapet står i sicksack
  bakom paladinen (`_line_up`) och värdshusets platser lämnar Mor Elin fri. **Repliker under nedstigningen** (`Dialog.bark`, `Run.bark`):
  Imma (och andra) säger en rad efter en svår strid, vid lägerelden, vid ett sällsynt fynd, en befrielse, i en ny
  Realm eller när paladinen står ensam kvar; högst en per rum, aldrig i striden, inget upprepas samma körning
  (`RunState.barks_used`); ibland ett kort samtal mellan två (`pairs`). Visas på rumskartan. 0.28.1: tillfällen i grottan (cave, elite, back, treasure, stairs, boss, fallen; home i datan men visas inte än) för
  sju följeslagare ur ChatGPT:s version 2 (`docs/ideer/repliker-v2.tsv`); nya repliker är `{id, text}` med fasta id:n
  (t.ex. `imma_elite_1`, för eventuella röster senare), `Dialog.line_text`. **Replikminnet** (levande repliker steg 1–3,
  `docs/research/levande-repliker.md` §5): `Profile.said` {nyckel: nedstigningen då den senast sades} (+ `said_times`,
  `last_idle`; nyckeln är id:t, annars `Dialog.line_key` = hash av texten) varar mellan körningarna. Grottans repliker väljer
  aldrig sagda först, sedan den som vilat längst; vilan är `Dialog.BARK_REST_PER_LINE` (2) × lägets pool för sällskapet, högst
  `BARK_COOLDOWN` (10) nedstigningar; vilar allt blir det tyst, utom i starka lägen. `barks_used` håller nycklar (ingen
  upprepning i körningen). Budget (`RunState.bark_allowed`): högst 5 repliker per nedstigning (`BARK_BUDGET`), aldrig i två
  rum i rad (`rooms_entered`, `bark_room`), vanliga lägen med `BARK_CHANCE`; starka lägen (`STRONG_BARKS`: boss, fallen,
  alone, rare_find, rescue, new_realm) går före. Nyheter i borgen (`idle` med `when`) sägs högst 2 gånger (`Dialog.NEWS_TIMES`),
  sedan vilar de; högst en nyhet per person och hemkomst (`said["news:<person>"]`), allmänna repliker aldrig två i rad.
  Valfria fält på en replik (bakåtkompatibelt med `{id, text}`): `once` (en gång per profil), `times` (nyheter),
  `cooldown` (nedstigningar), `chance` (0–1). Ragnhild Ljusdom (0.29.1) är sträng, konservativ och
  älskvärd och citerar bibelord **endast ur 1917 års kyrkobibel**, ordagrant och kontrollerade (`ref`,
  `docs/ideer/ragnhild-bibelord.md`); aldrig för att förlöjliga tron.
  Hennes Sanningens ljus har nåd (0.29.4): den svagaste i sällskapet helas med 12 % av hennes Intelligence när ljuset bränner (kapellet
  MACRO/TUNED 53/66 → 66/74 %, Eira 45/51 %; kryptan 10/24 %, Eira 34/42 %: en specialist mot fiender som helar sig).
  **Värdshuset** (0.29.3, Siralims samtal med skapelserna, ChatGPT:s jobb E, `docs/ideer/chat-vardshuset-och-sok.md`): tryck på en
  följeslagare som bor i värdshuset så säger hen något (`dialog.json` "inn": inn, bored, welcome med id:n; `Dialog.inn_line`),
  valet Visa hjältebladet. Välkomstrepliken en gång efter en nedstigning hen stannade hemma under (`Profile.home_runs`,
  `inn_heard`), efter två nedstigningar hemma vill hen följa med. Kronan steg 2 (Gorm, Alrik) när två bossar är besegrade
  (`min_bosses`). `--talk=<följeslagare>` med `--all-companions --keep`.
  **Introduktionen** för en ny profil (`data/intro.json`, `src/game/intro.gd`): eden vid altaret (Gorm ger 100 silver),
  svärdet hos Smeden (bara svärdet går att välja), en övningsstrid ensam där svärdet prövas (0.30: smedjan före
  övningsgården; `Profile.INTRO_ORDER` flyttar profiler som stod mitt i den gamla ordningen till svärdssteget), första makroraden, Biblioteket, och (0.25 "Berättelsen",
  `docs/plan/0.25-berattelsen.md`) natten: berättarens rutor, sedan arbetarna från kryptan på gården (de skadade på
  bårar, Mor Elin och Broder Alrik hos dem, `keep.json` "scene"). Gravgrävaren Tor berättar, Gorm skickar paladinen
  ned ensam och Imma får stanna (stegen `workers` och `descent`; steg med `"auto"` spelar samtalet direkt i borgen,
  rader är text eller `[talare, text]`, `Intro.lines`). Den första striden gör paladinen ensam (fienderna ×0,80 till,
  `RunState.FIRST_FIGHT_ALONE`, ~99 % vinst); direkt efter den smiter Imma efter (0.25.1: striden märker `RunState.joins_next`, hon ansluter först på rumskartan efter segerskärmen, `Run.imma_sneaks`; hennes porträtt
  på rumskartan, `intro.json` "imma_joins") och följer med resten av vägen (0.30.16: faller paladinen innan dess spelas en egen kort hemkomst, `intro.json`
  "alone_home", och nedstigningen börjar om med samma trappa). Hemma igen (`came_home`) skäller Gorm lite
  på henne, och sedan svärdet till nivå 3. Varje steg börjar med ett samtal på 2–5 repliker hos den som
  ger uppdraget (`giver`, `talk`, `Profile.intro_talked`, `Intro.needs_talk()`); nästa uppdrag kommer först efter
  samtalet. Uppdraget syns bara överst (svärdssteget med nivå och nästa kostnad), aldrig i någons mun: personen vid stegets plats säger en egen replik (`at` i
  intro.json, 0.24.3). Broder Alrik förklarar troféerna, och kryptans troféer syns som rykten i Biblioteket. Andra
  stationer svarar med en replik. Introt går inte att hoppa över; befintliga profiler har `intro_done`. Efter introt öppnas Värdshuset när
  man har räddat någon (vårt val). Förlust eller klarad krypta leder hem. Silver ges per vunnen strid.
  **Berättarrutor** (0.25, Siralims kursiva rutor, `StoryBox`): talaren `"narrator"` ger en rad inom parentes på svart;
  också första gången genom porten och efter den första bossen (`dialog.json` "narrator", `Run.narrate`,
  `Profile.narrated`, `Run.pending_story` som rumskartan och borgen visar). **Hjälprutor** (0.25, Siralims "?"-rutor,
  `Help`, `HelpBox`, `data/help.json`): ett grönt ?, en rubrik och 2–3 stycken första gången man möter ett system
  (rumskartan, Realm Quest, troféer, makron, artefakter, material, djup, instabilitet, perks, lärjungar, tidslinjen,
  statusar, ge upp), en gång per profil (`Profile.help_seen`); i striden pausas spelet medan rutan syns. Alla går att
  läsa igen i Broder Alriks handbok (`handbook_screen`). `--no-help` stänger av dem för skärmdumpar.
- **Inställningar** (0.30, `GameSettings`, `SettingsBox`): musikens och ljudeffekternas volym för hela spelet
  (`user://settings.cfg`, ljudkanalerna "Music" och "Sfx" som `Sfx` och figurernas kastljud använder; 0 % stänger av)
  och rumsögonblicken (profilens). Knappen INSTÄLLNINGAR under ‹ PROFILER i borgen och LJUD i striden (pausar).
  `--settings` öppnar rutan i borgen eller striden.
  **Speltid** (`src/game/playtime.gd`, `Playtime`, `Run.playtime`): aktiv tid per strid (första turen till resultatet),
  våning och nedstigning (kampanjkartan till hemma: boss, förlust, GE UPP, GÅ HEM), i verklig tid; klockan står still i
  bakgrunden, när trädet är pausat och när en ruta i gruppen `stops_playtime` är öppen (hjälprutan, inställningarna).
  Övningsgården räknas inte. `user://playtime.cfg` för alla profiler (senaste 200 strider, 50 körningar; en pågående
  körning per sparplats räknar vidare efter omstart). Snitten och NOLLSTÄLL SPELTID i inställningsrutan; `--playtime-demo`
  visar påhittade siffror och sparar inte. Tester: `tests/test_playtime.gd`. 0.31: varje strid sparar också sällskapets
  snittnivå och fiendernas väntade nivå; rutan visar snitt per djup och om sällskapet låg över, i nivå (±2) eller under.
- **Löften** (0.30.17, prov, `docs/plan/loften.md`, `data/vows.json`): på kampanjkartan (LÖFTE bredvid FÖRBEREDELSER,
  efter introt, `Profile.vow`) lovar Paladinen något för hela körningen. Hållet ger en egenskap hos Paladinen och silver;
  brutet blir det en ödmjukare form (`RunState.vow`, `vow_broken`, `vow_trait`, `vow_after_battle`, `is_common_group`).
  Ingen ska falla (Barriär till den svagaste; bryts när någon faller, då reser sig den som faller en gång), Jag helar inte
  (helningsförmågor går inte att välja, `CombatSim.no_heal`, orsaken "vowed"; Paladinens attacker helar 20 %), Raka vägen
  (högst två vanliga grupper per våning; questens silver dubbelt). Botarna: `BALANS=loften`. `--vow=<id>` före `--map`,
  `--vows` öppnar valet på kampanjkartan.
- **Krönikan och titlarna** (grenen `kronika`, `src/game/chronicle.gd`, `Chronicle`; VD: "så man känner att man inte är ensam"):
  `Profile.chronicle` får en kort post per nedstigning (Realm, djup, utfall, bossar, vem som föll, befriade, sällsynta fynd,
  nya troféer, löftet, kartans ändringar; `RunState.chron` = `Chronicle.begin` i `start_run`, `note_battle`, `note_finds`,
  `Chronicle.end` i `Run.end_descent(outcome)`, även första nedstigningen) och räknare i `chron_stats` (Realm i rad, segrar
  och förluster i rad, fall per hjälte, hållna löften …). Hemkomsten: rutan "Medan ni var borta" visar nya titlar och 1–2
  repliker (`Profile.homecoming`) av den det angår (`dialog.json` "chronicle", `{id, key, who, subject, text}`, `PRIO`):
  Mor Elin när någon föll, Hedda vid en sällsynt sten, Alrik vid troféer, den befriade första gången hemma, Gorm vid ett nytt
  djup, Imma vid stora saker och som standard, följeslagare som var med om varandra; mönster (tredje gången i rad, första
  segern, tre segrar mot en boss, faller ofta, rader); ingen upprepas förrän de andra har sagts (`chron_said`); kartans
  replik tävlar om platserna (`MAP_PRIO`). Titlar (`data/titles.json`, vårt val, 15 st, `Profile.title`, `titles`,
  `Chronicle.unlock_titles`; den första bärs direkt); `{titel}` (faller tillbaka till namnet; repliker med `{titel}` väljs
  bara med en titel). Broder Alrik: "Krönikan och titlarna" (`chronicle_screen`, de senaste 10 i tusch, titlarna att bära).
  Flaggor: `--chronicle-demo` (påhittad krönika), `--home=fell|boss3|rare|depth` (hemkomsten i borgen), `--chronicle`,
  `--title-focus=<id>`. Tester: `tests/test_chronicle.gd`.
- **Den levande kartan** (prov, grenen `levande-karta`, `docs/plan/levande-karta.md`, `src/game/living_map.gd`; avviker från
  Siralim): varje Realm man har gått ned i har ett fördärv 0–4 (`Profile.growth`, start 1, `growth_rest`, `growth_news`).
  Efter en nedstigning med minst en vunnen strid (`Run.end_descent`, `LivingMap.after_descent`; inte första nedstigningen)
  sjunker den Realm man gick till (2 steg om Realm Quest klarades, `RunState.realm_quest_done`, annars 1) och den besökta
  Realm som legat orörd längst växer 1 (`growth_last`; vårt val, alla andra växte för fort med tre Realms); en Realm som
  når 0 vilar en nedstigning. Steg 0–1 är dagens strider; steg 2–3 fiender +2/+4 % (`RunState.battle_opts`,
  `LivingMap.stat_mult`, steg 4 = steg 3), bättre troféchans och fynd (`Forge.roll_finds` `growth`). Steg 4 står still
  tills man går dit; i kryptan vaknar Den svärtade Benfursten (`crypt_twisted`, `bone_lich_black`, `twisted`, trofén Svärtad
  krona ges direkt). Kampanjkartan visar det utan siffror: tätare bläck, svarta stänk över ramen, fiendens eldar, ett rött
  sigill på steg 4, en rad före avfärd (`departure_line`, varning på steg 3) och rutan "Medan ni var borta" efter hemkomsten
  med högst en replik (Imma, annars Gorm; `dialog.json` "living_map"). Flaggor: `--growth=crypt:3,chapel:1`,
  `--growth-home=chapel[:quest]` (som efter en hemkomst), `--twisted` (strid mot den förvridna bossen). Botarna:
  `BALANS=levande` (vinst per steg), `SOAK=karriar` skriver kartans läge (`LEVANDE=av`, `KARRIAR_REALM=lagst|hogst`).
  Tester: `tests/test_living_map.gd`.
- **Den levande världen** (grenen `levande-varld`, `docs/plan/levande-karta.md` "Levande värld", `src/game/world_events.gd`,
  `WorldEvents`, `data/world_events.json`, `Profile.world`; VD: "att det betyder något är ett måste"). Kartan är motorn.
  **Följder** (en besökt Realm på steg 3+, vänds när den trycks tillbaka): lunden = nät över handelsvägen, smedjans nivåer
  +15 % (`smith_mult`, `Profile.artifact_level_cost`, Heddas rad vid knappen, `smith_reason`); kryptan = arbetarna vägrar gå
  ned, Tor och arbetarna står på gården och skickar ingen bärnsten (annars 1 per hemkomst, `tor_sends`); kapellet = inga
  pilgrimer, helningsförmågorna −1 Charge nästa körning (`heal_charge_mod`, `apply_to_run` i `RunState.new_run`).
  **Gåvor** (en gång när en Realm som stått på 2+ trycks till 0–1, `armed`): lunden = en handelsman på gården (5 bärnsten
  och ett trick för silver, en av varje, `merchant_buy`, `merchant_sold`, stationen "merchant"; han stannar tills nästa
  nedstigning börjar, `begin_run`, eller tills allt är sålt; samma för karavanens tacksamma; `--buy=amber` med
  `--world-demo --keep`), kryptan = arbetarna hittar 3 bärnsten + 30 silver, kapellet = en pilgrim i värdshuset med ett
  rykte (`world.rumour`): i nästa körning, vilken Realm som helst, syns den första våningens questmål genom dimman från start
  (`RunState.apply_rumour`, `world_rumour`; ringarna syns ju redan alltid; `dialog.json` world "pilgrim_rumour", "rumour_map";
  `--world-demo --map`). Pilgrimsskarans händelse ger fortfarande +1 Charge på helningar (`bless_runs`). **Händelser** (5 st, tidigast efter
  4 nedstigningar, sedan 3–5 mellan starterna, aldrig två samtidigt, `pick_event`, `start`, `after_descent`): Kulten samlas
  till högtid (fäll biskopen; annars +1 steg och biskopen ×1,12 nästa körning, `world_boss_mult`), Spindlarna har tagit en
  karavan (questen; tacksam handelsman eller smedjan +10 % i 3 nedstigningar), Gravklockan ringer (4 strider; en Nether
  Stone eller +1 steg och grupperna ×1,06, `world_stat_mult`), Pilgrimer genom dalen (questen; 2 välsignelser), Två fronter
  (krypta och lund, man hinner bara den ena: `half`). Kampanjkartan: ett rött timglassigill över området, raden
  "HÄNDELSE: … (två nedstigningar kvar)" och vad Realmen kostar hemma. Borgens folk nämner det som pågår
  (`dialog.json` "world" "ongoing", `ongoing_line`). Titlar: Den som bröt högtiden, Landets värn.
  **Hemkomsten i borgen** (`base_screen` `_start_homecoming`): den som det viktigaste angår går från sin plats till paladinen
  och pratar i samtalsrutan, nästa kommer efter (högst tre), sist rutan "Medan ni var borta" (kartan, världen, nya titlar,
  händelsen som pågår); ett tryck hoppar fram. Krönikans nya händelser: `map_down` (per Realm och steg, `min_streak` för
  gånger i rad), `map_up`, `map_wake`, `cost_on`/`cost_off`, `gift`, `ev_start`/`ev_won`/`ev_half`/`ev_lost`, `advice`;
  replikvillkor `realm`, `step`, `event`, `outcome`, `advice`, `min_streak`. Efter en förlust: tröst först (Mor Elin, Gorm,
  Imma), sedan världen, sist ett råd efter två förluster i rad (Stig: Övningsgården mot mötet som fällde en,
  `chron.lost_to`; Broder Alrik: en ägd trofé vars `answers` nämner fienden, `answering_trophy`; Gorm: ett djup grundare
  eller en lugnare Realm). Flaggor: `--home=event_lost|event_won|start|loss|cost|gift` (och de gamla), `--event=<id>`,
  `--world-demo`, `--news` (den gamla rutan på kampanjkartan). Botarna: `SOAK=karriar` skriver händelserna (`VARLD=av`).
  Tester: `tests/test_world_events.gd`.
- **Djupets tecken** (0.30.45, `docs/plan/mot-upprepning.md` §3, `docs/ideer/chat-djupets-tecken.md`): varje nedstigning efter
  introt drar ett tecken, en synlig regel för hela nedstigningen som gäller **båda sidor** och inte ger silver (instabiliteten
  ligger ovanpå). `floor_rules.json` med `"omen": true` (instabiliteten drar dem aldrig), `RunState.omen` (run.cfg),
  `Profile.omen` (nästa nedstignings, dras i `Run.ensure_omen`, aldrig samma två gånger i rad), `CombatSim.omen`.
  Fullmåne (kritiska träffars extra skada ×1,25; ×2 gav kryptan djup 2 −20 enheter), Helig mark (helning +15 %; +25 % gav kapellet djup 1 +13), Ekande valv (var tredje förmåga var och en använder
  kastas en gång till, gratis, ny målväljning om målet dog; händelsen `omen`, action `echo`), Tyst mässa (lagets första förmåga
  i varje strid kostar ingen Charge, men kräver en kvar; en per figur gav +15–20 enheter), Sista kraften (+25 % skada under halva livet), Trång passage
  (+25 % mot ett mål, −25 % för förmågor som träffar alla, `CombatSim.is_multi_target`). En varslad attack ekar inte.
  Botarna (`BALANS=tecken`, 200 nedstigningar, djup 1–2): alla inom ±8 enheter utom Tyst mässa i kapellet djup 2 (−12: Eira
  sparar Charges och lägger Pilregn på Abbedissans kör, där bara kronbäraren tar full skada; botmakrots fel, inte tecknets). Syns på kampanjkartan ("Det här
  djupet: …", BYT för 25 silver en gång, `Run.reroll_omen`), överst i grottan och i stridens regelrad; berättarens rad när
  nedstigningen börjar och Svens vid porten (`dialog.json` "omens", id:n som `omen_fullmane_sven`); hjälprutan "omens".
  Makrovillkor under Tecken: `omen_is`, `next_ability_echoes`, `free_ability_unused`; förmågor som träffar alla märks "(alla)".
  `--omen=<id>` (med eller utan `omen_`, `none`), `BALANS=tecken` (nedstigningar som balanssimuleringen), `OMEN=` i text_play.
- **Djup** (0.14, Siralims Realm Depth): väljs på kampanjkartan, nästa öppnas när föregående är klarat. Fiender
  +3 % stats per djup (inte Speed; 0.30.33; balans v2 prövade 5–15 %, allt över 3 % gav väggen vid djup 4–6 hos karriärbotarna, `docs/balans/sammanfattning-v2.md`; förr 8 %: det lades ovanpå fiendernivåerna och gav väggen vid djup 5–6, `docs/provspel/djupsteg-matning.md`), silver +25 % och troféchans +15 procentenheter per djup.
- **Fiender** (0.14): alla har egenskaper som makrona måste svara på (Benrustning, Jägarblick, Gravpakt,
  Taggig utmaning, Glödhetta). Benfursten är Resistant (halv effekt av debuffar) och vredgas under 50 % liv;
  Dödsdom laddar han också över 50 % när Benstormen vilar, två turer i förväg (strid-justering).
  Tryck och håll på en figur i striden för att granska den (Inspect, kostar ingen tur).
- **Realms** (0.16, Siralims Realms): väljs på kampanjkartan, `data/realms.json`. Kryptan (Benfursten) och Det
  fördärvade kapellet (Kultist, Gast, Fallen riddare, Häxa, Botgörare och bossen Den fallne biskopen, som är
  immun så länge en Kultist lever). Djup och skalning gäller alla Realms. Nya debuffar: Tystad (inga
  förmågor; makrorader med förmågor hoppas över), Sårbar (+50 % skada) och Försvagad (−50 % skada).
  Troféer har `rarity` (common/elite/boss); bossens trofé ändrar en regel med en kostnad.
  **Roterande väktare** (mot upprepning, `docs/plan/mot-upprepning.md` §1, VD): bossplatsen växlar med djupet. `realms.json`
  "guardians" (två möten per Realm, `"guardian": true` i encounters.json); cykeln är [huvudbossen] + väktarna, djup d tar
  plats (d − 1) mod 3: huvudbossen på djup 1, 4, 7 …, väktare 1 på 2, 5, 8 …, väktare 2 på 3, 6, 9 … (`RunState.guardian_for`,
  `boss_encounter`; den förvridna bossen går före). Kryptan: Klockaren (Midnattsklockan), Gravväckaren (Kistornas råd);
  kapellet: Abbedissan, Inkvisitorn; Lunden: Strypvävaren, Sömnvävaren + Slukaren; Berget: Brom, Gråluva. Väktarna är
  inga bossar: ledarens egen trofé, inga bosstroféer, `boss_wins`, smörjelse eller berättarruta; djupet, Realm Quest och
  upplåsningar som förut. Kortet säger VÄKTARE och när huvudbossen kommer. `stat_mult` mätt mot huvudbossen med
  `BALANS=grotta` (`KORNINGAR=300`) och `BALANS=vaktare`; `--depth=2 --map --enter=end` visar kortet.
  **Väktarsteg 2** (`docs/plan/bossbank.md`): varje väktare ställer en egen fråga, med mötets egna egenskaper och regler
  (`"overrides"` i encounters.json, nyckel typ eller "typ#n", `CombatSim.unit_override`), en varning på kortet (`"warning"`),
  en hjälpruta första gången (`"help"`), en rad i Inspect och ett ord över figuren. **Midnattsklockan**: Klockan slår
  (laddning, väcker en fallen ur Benfolket, "SLAG n AV 3"), efter två slag Midnatt mot alla i två turer, bryts bara när hela
  Benfolket har fallit (`channeled_by_family`, `reset_stack`; HÅLLER MIDNATT; villkoret `is_channeling`). **Kistornas råd**:
  Gravens kraft, Kistlocket, Likvakan (`passes_on_death`) går i arv till de andra när en faller (ÄRVER, `trait_passed`).
  **Förhöret**: den som provocerar och träffas får Skuld (`guilt`, −20 % helning per stapel, `heal_taken_mult`); vid tre
  staplar laddar Inkvisitorn Dom mot hen (`enemy_aura_stacks`, `pick: aura_stacks`), rensad Skuld bryter den (`target_aura`,
  "absolved"; villkoret `is_charge_target`). **Systrarnas krona**: bara bäraren tar full skada (Körens skydd: halv skada), kronan går
  vidare efter tre av bärarens turer eller när hen faller (aurans `pass_to`, `aura_passed`; BÄR KRONAN). Väktarens trofé
  (`"trophy"` på mötet, rarity boss) efter **två** segrar mot just den väktaren (`RunState.GUARDIAN_WINS_FOR_TROPHY`,
  `Profile.guardian_wins`, skilt från `boss_wins`): Midnattsklockans kläpp (var tredje handling bryter fiendernas
  laddningar; +15 % skada tagen), Rådets sigill (ärver en fallen allierads trofé; −20 % helning tagen), Den vandrande kronan
  (−30 % skada tagen, −15 % skada, går till den svagaste), Domstolens klubba (Skuld vid träff; +25 %/−15 % skada). Biblioteket
  visar dem (VÄKTARE n/2). **Sven vid porten** säger vem som vaktar det valda djupet (`Dialog.gate_guard_line`, dialog.json
  "gate_guard"; `--talk=gate --gate-depth=2 --line=1`). Lunden och Berget har ännu bara befordrade grupper.
  Botarna (300 per rad, före → efter): grottan med fyra hjältar kryptan djup 2 MACRO/TUNED 9/30 → 10/30 %, djup 3 15/24 →
  15/20; kapellet djup 2 10/31 → 8/28, djup 3 10/15 → 11/15. En strid med fulla Charges (`BALANS=vaktare`): Kistornas råd
  d3 74/58 → 78/62, Abbedissans kör d2 89/74 → 91/78, Inkvisitorns domstol d3 20/8 → 22/11, men Midnattsklockan d2 58/44 →
  78/68 (Midnatt tömmer Charges, så den är svårare i grottan än ensam; `stat_mult` valt efter grottan). Botarna svarar
  inte på mekanikerna (inga nya rader i TUNED). `--windup=<förmåga> --windup-first` visar ett slag i striden.
- **Trollberget** (Realm 4, steg 1, `docs/plan/trollens-realm.md`, `realms.json` "mountain", kort "Berget", `"style": "mountain"`):
  bara de sju trollen som finns, pooler i tre tiers (`troll_1a` … `troll_3d`), våningsmöten `troll_1`/`troll_2`, elit Gråluvans
  stuga (våning 1), Bron och Vaggan (våning 2), bossen Bergakungen. Öppnas när kapellet är klarat på djup 1 (`"requires"`,
  `RunState.realm_open()`; kampanjkartan visar området täckt av fördärvet med "Öppnas när …"; `--cleared=chapel:1`). Questen
  har egna namn (`"quests"`: Tullen vid ravinen, Stäng berget, Klockans delar). Föremålen Trollbägaren, Nedsänkt kyrkklocka
  och Ljusspricka lånar sarkofagens, glasfönstrets och registrets val med egen text. Inga lärjungar, inga motdrag, ingen följd
  eller gåva än. Vinjett `vagen.webp` (Drakvalvet), kryptans stämning, kallare ljus i strid och rumsögonblick. Berättarrutan
  efter första segern mot Bergakungen (`narrator` "boss_mountain_king"). Tester: `tests/test_realm_mountain.gd`.
  **Djupförskjutning** (0.30.25, VD): `realms.json` "depth_offset" (berget 1) lägger till djup för fiendernas nivå och stats
  (`RunState.depth_offset`, `enemy_depth()`, opts "depth_offset", `CombatSim.enemy_depth`; hjältebladet, nivåhoppet, förlusttipsen
  och kampanjkartans "Fiender +%" räknar med den). Erfarenheten följer fiendernas djup, silver, troféchans, motdrag och
  elitvarianter det visade djupet; kartan säger fortfarande "Djup 1". VD bad om 3 (djup 4); botarna (`TROLL_MODE=djup` i
  `tests/troll_balance.gd`, nivå 6–7, MACRO, 100 körningar) gav med 1: fyra 0 % klarat (vanliga 100 %, elit 93 %, boss 0 %),
  fem 38 % (boss 38 %); med 2 klarar ingen av dem bossen, med 3 inte ens vanliga grupper (48–63 %).
- **Instabilitet och våningsregler** (0.17, Siralims Realm Instability och Realm Properties): på kampanjkartan
  väljs instabilitet 0–3. Nivå n ger n synliga och n dolda regler för hela körningen (`data/floor_rules.json`,
  t.ex. De döda vaknar, Förseglade ord, Vaksamma vakter, Speglande ben, Kaosvind), mer silver och bättre
  troféchans. Dolda regler avslöjas när de slår till (händelsen `rule`). Kaosvind (0.30.16) lägger sig efter varje
  hjältes tredje tur (`CombatSim.CHAOS_WIND_TURNS`, händelsen `chaos_calm`): botarna fann eviga strider annars.
  **Utmattning** (0.30.20, vårt val; Siralim har ingen turgräns): från tur 100 tappar den som står på tur 0,4 % av sitt
  maximala liv per tur över 100, förbi Barriär (`CombatSim.EXHAUSTION_TURN`, `_exhaust`, händelserna `exhaustion_start`
  och `exhaustion`, skylten "Facklorna falnar"); tur 300 är en ren förlust. Botarna: 99 av 100 strider är klara på 69 turer.
  `--exhaust=<tur>` startar striden på en viss tur.
  **Stridernas längd** (strid-langd, textspelet: Benskrivaren 55 turer, Kistornas råd 87): fiendernas helningar mattas
  15 % per tidigare tur med samma förmåga, ned till 40 % (`CombatSim.heal_fade`, "Mattad helning", formler.md §7);
  Antecknat högst 50 % (förr 75); Kistbäraren försvarar sig under 35 % liv (förr 60); Kistornas råd stat_mult 1,155
  (förr 1,14, för att hålla vinsten). Botarna: `GROTTA_TURER=1` ger turer per strid (median/90:e percentilen/max) per sort
  och per möte i `BALANS=grotta` och `BALANS=vaktare`. Prov utan att ändra spelet: `HEAL_FADE`, `NOTED_MAX`, `BEARER_DEF`,
  `MOTE_MULT=<möte>:<x>`, och för stora strider (elit, Nemesis, boss) `BIG_HP`, `BIG_POW`, `BIG_EXH`, `BIG_EXH_STEP`
  (`CombatSim.big_fight_*`, av som förval). Våningens nödvändiga grupper (elit, Nemesis, föremåls- och sigillvakter) är
  olika möten när poolen har fler (`Grotto._pick_unused`).
  Fiender som försvarar sig vid lågt liv gör det bara direkt efter ett anfall (0.30.19, `self_last_attacked`: karriärbotarna
  fann ett dödläge mot Asketen). **Svårighetskurvan** (`SOAK=karriar` i `tests/soak.gd` på testgrenen,
  `docs/provspel/svarighetskurva.md`): en profil genom 18 nedstigningar; djup 1 är en platå, taket kommer vid djup 6–7.
  Våning 1:s elitgrupp och Nemesis ×0,80 för högst två hjältar (`RunState.SMALL_PARTY_ELITE`, andra nedstigningen 26 → 41 %).
  **Balanserat mot fyra** (0.30.21, VD): `PARTY_SCALE` och mildringen ovan gäller bara när profilen äger färre än fyra hjältar
  (`RunState.owned_heroes`); den som har fyra och går med färre möter samma fiender som mot fyra (`full_party`), en bedrift.
  Balans v1: fem i en Realm byggd för fyra möter fiender som mot fem (`CombatSim.FIVE_IN_FOUR` ×1,4 på Health, Attack och
  Intelligence, opts `five_in_four`) på det djupaste djupet, som mot fyra på djup Realmen redan är klarad på
  (`RunState.depth_cleared`, `Profile.realm_depth`). Trollberget har ett eget djupsteg ovanpå (`realms.json` "depth_step"
  0,17 per fiendedjup, opts `realm_depth_step`).
  **Sällskap om fem** (prototyp, grenen `sallskap-fem`, VD): platserna kommer ur `Profile.party_slots()` (4, eller 5 när
  `Profile.SLOT_UNLOCKS` är uppfyllt: huvudbossen besegrad på djup 4 i både kryptan och kapellet; `max_companions()`,
  `RunState.party_slots`). Den låsta platsen syns grå i Förberedelser och Värdshuset från att profilen äger fyra
  (`next_slot_lock()`); när den öppnas visar borgen berättaren och Gorm en gång (`Run.check_slot_unlock`, `slots_seen`,
  `dialog.json` "party_slot"). Trollberget (`realms.json` "party": 5) är **alltid** balanserat mot fem
  (`RunState.full_party_size()`, `CombatSim.party_scale_size`, `PARTY_SCALE[5]`; mötenas `"extra"` i encounters.json kommer
  med mot fem, men aldrig fler än fem fiender, VD 2026-10-25, `CombatSim.max_enemies` = 5; `FIVE_CAPPED_SCALE` 1,0);
  kampanjkartan varnar med färre platser (`RunState.realm_too_big`). Kryptan och kapellet är byggda för fyra: fem
  hjältar där möter fiender som mot fyra, utan "extra" (VD: låga djup ska vara lätta; `party_scale_size` tar
  "full_party" åt båda hållen). Botarna (berget djup 1, 100 körningar, MACRO/TUNED): fyra förr 38/60 %, fyra mot fem
  2/7 % (vanliga 99 %, boss 2–7 %), fem med Imma 41/47 %, med Solveig 23/37 %. Striden: lägre ramar för fem (`PartyFrame.compact`).
  Flaggor: `--party5` (före `--all-companions`), `--slot-unlock --keep`, `--fps` (eller FPS PÅ i inställningarna,
  `FpsMeter`). Botarna: `BALANS=grotta GROTTA_FEM=1` (GROTTA_TYPER=1 vinst per sorts strid, GROTTA_TAK=5 högst fem
  fiender, GROTTA_FEMTE), `BALANS=fem` (en strid per möte med fulla Charges).
- **Troféjakt** (0.17): sällsynta elitvarianter (5 %, mer med djup och instabilitet) glöder, har ett eget
  namn och en egen regelbrytande trofé (som de själva bär). Bosstroféer kräver tre segrar mot samma boss
  (Siralims Masters, `Profile.boss_wins`). Biblioteket visar alla troféer; Inspect visar vad ett monster lämnar.
- **Ge upp** (0.20.1, Siralims Forfeit): knappen GE UPP bredvid 1×/Auto, med en bekräftelse. Räknas som
  förlust: körningen och questens belöning går förlorade och Realmen börjar om från våning 1 (`run.cfg`
  tas bort, `RunState.delete_saved`); erfarenhet, troféer, silver och material som redan är vunna finns kvar.
  `CombatSim.forfeit()`. `-- --ask-forfeit` visar frågan i en strid. **GÅ HEM** (0.30, Siralims återvändo till slottet) i grottan
  gör samma sak utanför striden, med en bekräftelse (`Run.leave_run`, `--ask-leave`); att stänga spelet pausar bara.
- **Rykten och spår** (0.30.22, `docs/plan/nya-grottor.md` A och B): röda ringar över 3×3 visar ungefär var questens mål
  står (`RunState.quest_hints`, `active_hints`); en gyllene stig till det öppna målet; den som går vidare får 75 % av
  erfarenheten och silvret från vanliga grupper som står kvar (`TRAIL_SHARE`, `take_trail`, `Run._pay_trail`). Boten
  `direct` i `BALANS=grotta`. Drakvalvets monster (29, alla riggade): `docs/research/drakvalvet-monster.md`.
- **Den levande kartan syns** (karta-synlig, VD: "Jag såg inte levande kartan", `docs/plan/levande-karta.md`): hjälprutan
  "Den levande kartan" första gången något har vuxit (`LivingMap.grown_realm`), med området ljust, en pulserande ring och en
  pil (`HelpBox.focus`, `focus_panel_rect`); i handboken. Stegen utan siffror: 0 stilla och brunt bläck, 1 bläcket andas
  (shaderns `breath`, `flow`) och svaga droppar vid ramen, 2 fläckar och eldar, 3 fler, 4 rött sigill. Ändrades inget på
  kartan får "Medan ni var borta" en rad om det som växer härnäst (`LivingMap.quiet_line`, `next_to_grow`, `dialog.json`
  living_map "quiet"/"lonely" med id:n, `chron_said`). `--home=quiet --home-summary`; stegen: `--growth=crypt:0,chapel:1,grove:2 --gate`.
- **Mot upprepning** (variation-1, textspelet `docs/provspel/textspel-dagbok.md`, `docs/plan/mot-upprepning.md`): vanliga
  grupper per djupband (`realms.json` "depth_pools" från djup 3 och 6, `RunState.pools_for`), några med **djupets prägel**
  (`encounters.json` "twist" + "overrides", "base"; visas på kortet) som ändrar vem man fäller först: Sorgens vrede (fäll
  prästen/häxan/grytmodern först), Livvakt (`bodyguard`, guard_family: fäll livvakten först) och Bundna (`bound_pair`,
  villkoret `ally_has_trait`: välj vem som får stå kvar); samma prägel högst en gång per nedstigning (`twists_used`).
  Från djup 4 är en vanlig grupp per våning ibland en **inkräktare** ur en annan Realm (`realms.json` "intruders",
  `INTRUDER_CHANCE`, kortets rubrik INKRÄKTARE, `--enter=intruder:<realm>:<möte>`). Våning 1:s elit roterar (2–3 per
  Realm; första nedstigningen behåller den första), Nemesis på våning 2 dras ur båda våningarnas elit (`nemesis_pool`),
  och en väktares ledare (rank miniboss) är ingen vanlig elit på väktarens djup ±1 (`elite_pools_for`, `GUARDIAN_GAP`).
  Väktarens andra möte: en egen rad på kortet ("second_warning"). Lägret: troféer man inte äger går först och märks NY,
  ägda visar ÄGD och vem som bär dem, sällsynta (`is_rare_trophy`) står först och glöder; inget nytt = ingen valskärm,
  en kort rad och troféerna följer med (`Run.note_offer`, `offer_new`, `offer_known`); erbjudandet räknas efter det
  gruppen vaktade (ingen skattetrofé två gånger); skatten föredrar det man inte äger. `--camp --camp-mix` för
  skärmdumpar. Mätning: `tests/variety_report.gd`; tester `tests/test_variation.gd`.
- **Grottans utseende** (0.28.3, efter skärmgranskningen): dimman är en sammanhängande tuschlavering med skraffering
  och svagt rutnät; besökta rutor ljust pergament med stenprickar; bergssidor i tusch där det kända möter dimman; ett
  varmt sken där man står; hörnmarkeringar på hela gränsen mot dimman (varje ruta man når med ett tryck). `--explore=<n>`
  markerar n rutor som besökta för skärmdumpar.
- **Realmens föremål i grottan** (0.28.2, `data/objects.json`, `realms.json` "objects", Siralims föremål per Realm):
  2–3 per våning (`Grotto._place_objects`, eget frö). Kryptan: Rasslande sarkofag (knacka: starkare benvakt, dubbel
  skatt), Gravklocka (ring: strid; efter segern ring igen, svårare och större belöning), Gravregister (visa 2 skatter
  eller 2 grupper). Kapellet: Övertäckt glasfönster (hela raden syns, nästa grupp +15 %), Klockrep (beredd grupp, sedan
  syns alla grupper), Lös kyrkbänk (barrikadera bort en sedd vanlig grupp utan belöning, eller virke för silver). Båda
  (0.29.2): Väktarens timglas (offra en Charge, se närmaste elitgrupp). Berättelsen (0.29.2): efter den första bossen
  hittas ett beslag med en krona med en tom mitt – samma avsändare bakom allt (`docs/ideer/chat-realm3-kallornas-tradgard.md`).
  `RunState.use_object`, `object_won`, `revealed` (avslöjade rutor), `next_stat_mult`; `--enter=object:<id>`.
  Förslag på fler: `docs/ideer/chat-foremal-grottan.md`.
- **Kryptans fiender** (0.28, `docs/plan/0.27-fiender.md`, Siralims raser): familjen Benfolket (`family` i enemies.json,
  `CombatSim.family_count`; ingen delad aura, medlemmarnas egna egenskaper räknar familjen, t.ex. Flockbett, Benmur),
  elitfiender (`rank`: elite) och Klockaren som miniboss (`rank`: miniboss, inte boss). Elitgrupper ligger i
  `realms.json` "elite_pools" (våning 1 bara Kolossens vakt, mildare på första nedstigningen: `FIRST_DESCENT_ELITE`).
  Motdrag (`counter`, `CombatSim.counter_for`): högst ett per grupp, bara elit, Nemesis och boss, från ett visst djup
  (Sista klangen djup 1, Dimmans tyngd 2, Sista vaktens ilska 3); elitkortet visar det. Nya AI-val: `pick` healer,
  highest_attack, caster; `ignore_taunt`; villkor `family_at_least`, `alone`, `self_stacks_at_least`.
  Flaggor: `--encounter=<möte>` (övningsstrid mot gruppen), `--enter=elite:<möte>` (gruppens kort i grottan).
- **Kapellets fiender** (0.29, `docs/plan/0.27-fiender.md` §2): två familjer, Kultens folk (`cult_kin`, även Abbedissan)
  och De fallna (`fallen_kin`), med egna egenskaper som räknar familjen (Kultens fana, Spegelsköld, Fastan, Bruten ed,
  Grumlad välsignelse). Elitfiender Kultens förman (livvakt, `guard_family`, händelsen `guarded`), Inkvisitorn, Asketen
  och Den svarta lansen; Den fördärvade abbedissan som miniboss. Motdrag: Ordensregeln (`limit_enemy_heals`, djup 1) och
  Skrattande låga (djup 3). Våning 1:s elit är Lansens anstormning. Nya villkor: `target_in_family`, `self_family`,
  `self_not_acted`, `unit_repeated_ability`, regeln `self_last_attacked`; modifieraren `ignore_defense`. Tester:
  `tests/test_enemies_chapel.gd`. `NIVA_REALM=chapel` begränsar `BALANS=grotta`; `BALANS=elitgrupper` kör en strid per
  elitgrupp (alla vinns med fulla Charges – svårigheten kommer av nötningen över körningen).
- **Trollfolket** (0.30.23, `docs/plan/troll.md`, ännu utan Realm; `--encounter=troll_1a` … `troll_3`): familjen `troll_kin`
  med artregeln Trollhud (en förmåga stoppar läkningen, `troll_scorched`), sju troll med var sin egen förmåga och trofé, bossen
  Bergakungen (Stenhjärta). Modellerna `troll*.glb` ur Drakvalvets ogre, färgade per troll med `colors`.
  **Roller** (grenen `fiender-roller`, `tests/test_enemy_roles.gd`): Stenkrossaren slår hårt, Mossrygg är pansar, Grytmodern
  helar (Grytans gröt, inte ett troll med Svedd hud), Avundsjätten går förbi Provocera och **Bortbytingen** (`changeling_troll`)
  är snabb och skör och river den svagaste förbi Provocera; bergets vanliga grupper blandar 2–4 roller.
  **Moderns famn** (strid-justering, `mothers_embrace`, `shelter_family`, `shelter_kind`, `CombatSim._shelter_for`): så länge
  ett större troll lever (mest maximalt liv i familjen) tar det hälften av varje anfall mot Bortbytingen (förmågor och
  indirekt skada träffar honom fullt); händelsen `guarded` med `shelter`, siffran FAMN över trollet, raden i stridsloggen,
  Inspect säger vem som tar emot. Han fick 22 Health och 13,5 Attack (förr 30 / 15) så att berget håller sin svårighet. Kapellets Häxa: Tystnadens förbannelse går förbi Provocera.
- **Drakvalvets fiender** (0.31, `docs/plan/drakvalvet-fiender.md`, `tests/test_enemies_crypt.gd`/`_chapel.gd`): **Likätaren**
  (`ghoul`, Benfolket) äter lik ur familjen (Likmåltid, `consume_corpse`, `CombatUnit.consumed`: kan aldrig väckas) och växer
  (Gravhunger, högst 3); elitvarianten Gravgnagaren äter aldrig hjältar. **Blodsvuren** (`cult_zealot`, Kultens folk; elit
  Blodfogden) slår hårdare ju mer skadad den är (Blodpakt, `damage_mult_per_missing_tenth`) och betalar Blodhugget med eget liv
  (`self_damage`, aldrig det sista); ingen grupp med Förmannen. **Kyrkogrimmen** (`church_grim`, elit utan familj, `chapel_e7`)
  biter den som slår någon annan i gruppen (Grimmens vakt, en gång per tur), motdraget Skrattande låga från djup 3. Benvargen
  (Benspringarens elitvariant) är `varg.glb` (`elite.visual` ersätter figuren). `emit_energy` i `visual` låter lågor och ögon
  lysa. Möten `crypt_2g`, `crypt_3e`, `crypt_e7`, `chapel_1d`, `chapel_3f`, `chapel_3g`, `chapel_e7`. Ingen ny kontroll.
- **Död:** en död figurs egenskaper slutar verka, även Paladinens kall, och verkar igen när den väcks.
- **Stats och skada** (0.13, som Siralim): Health, Attack, Intelligence, Defense, Speed. Attack =
  (max(Atk − Def, 0) + 1 % Atk) × mod, Spell = max(Int × nivå − Def, 0) × mod, Indirect = × mod − 20 % Def.
  Försvara: −35 % skada och +50 % Defense; Provocera: −35 % Defense. Krit och undvikande från Speed-kvoten
  (vårt val, formeln är inte publicerad). Barriär tar skada före livet. Se `docs/research/siralim.md` §12.
  **Små tal** (0.26, som Siralim): grundvärdena för Health, Attack, Intelligence och Defense delades med 10 (Paladinen 90
  Health, Brokk 115, en vanlig träff 10–15). Stats har en decimal (`CombatSim.snap_stat`, Speed i heltal); skada och
  helning avrundas till heltal en gång på slutet (inget golv på 1 längre; en mycket svag träff kan göra 0 men räknas som en träff för egenskaperna), och stridsloggen visar mellanleden med en decimal och
  avrundningen. Balansen är densamma (botarna före och efter, `docs/formler.md`).
- **Statusar** (0.22, Siralims buffar och debuffar, `docs/formler.md` §5, `docs/research/siralim.md` §17): 12 buffar
  (Smidig, Arkan, Bärsärk, Defensiv, Immun, Livstörst, Läkning, Beskyddad, Pånyttfödd, Vildsint, Skyddsskal,
  Utmanande) och 10 debuffar (Blöder, Fördärvad, Förblindad, Förvirrad, Frusen, Förgiftad, Hånad, Sover, Snärjd,
  Förstenad) med originalets siffror, plus de vi hade. Auror har typ (`buff`/`debuff`, annars tillstånd),
  varaktighet i ägarens turer, `stacking`, `removes`, `cannot_dispel` och flaggor (`snare`, `leech`, `freeze`,
  `sleep`, `stone`, `blind`, `confuse`, `scorn`, `shell`, `rebirth`, `end_turn_aura` …), `text` och `glyph`.
  Resistent påverkar bara statusarna med en Resistant-version (originalet). Effekter: `dispel` (alla statusar),
  `purge` (debuffar), `to_top`, `to_bottom` (`_move_on_timeline`: den som stod överst skickas ned, gränserna per
  tur nollställs, Snärjd hindrar, bossar ett steg; vårt val: en gång per runda). Effekter kan ha `chance`.
  Händelser `aura_applied`/`aura_removed` (`aura_kind`, `reason`), `timeline_move`, `status_skip`, `shelled`.
  Villkor: `self_lacks_aura`, `target_lacks_aura`, `self_has_kind`, `target_has_kind`, `unit_has_kind`; makron:
  har/saknar buff/debuff. Ikoner under livmätarna (`scripts/battle/status_icons.gd`), Inspect listar dem.
  `-- --statuses` ger några statusar i en strid. Tester: `tests/test_status.gd`, `tests/test_numbers.gd`.
- **Siffrorna** (0.21): alla formler med svensk förklaring i `docs/formler.md`. Varje skada, helning och
  undvikande bär sin uträkning (`calc` i händelsen); `DamageExplain` (`src/combat/damage_explain.gd`) skriver den
  i klartext. I striden: tryck på en siffra, eller STRIDSLOGG (förr SKADELOGG; Siralims stridslogg: varje handling, också
  förmågor utan skada, buffar, debuffar, Barriär, missar, tidslinjen, statusar som tar en tur och avbrott, en svensk rad
  var ur `BattleLog`, `src/combat/battle_log.gd`; skador och helningar behåller uträkningen). Hjältebladet räknar med `CombatSim.expected_damage()`
  (samma formler och modifierare som striden). `tests/test_numbers.gd` prövar formlernas egenskaper.
  `-- --show-calc` och `-- --damage-log` visar dem direkt i en strid. **Granskningen** (0.23.3, `docs/formler.md` §11–12):
  `tests/numbers_reference.gd` är formlerna skrivna en gång till utan spelets kod; `tests/audit_sim.gd` + `numbers_audit.gd`
  räknar om varje händelse i seedade strider (`tests/test_numbers_audit.gd` kör 72 strider i testerna). Stats som inte
  är heltal visas med en decimal (`HeroStats.shown`, `shown_parts`).
- **Strid:** Siralims tidslinje – snabbheten avgör startplatsen, den som agerat läggs längst ned, inga
  rundor. Hjältar väljer Anfall, Förmåga (2–3 per hjälte, med Charges som räcker hela körningen),
  Försvara, Provocera eller Makro. Fiender visar sin avsikt och väljer nästa i slutet av sin tur.
  **Uppställning** (bara utseende, `UnitModel.formation`): högst Defense vid stridens början står närmast fienderna,
  sedan fallande (Brokk fram, Imma och Alva bak); sällskapet är flyttat bakåt i bilden (`PARTY_LIFT`) så att ringen
  inte hamnar bakom MAKROLOGG. Fienderna står kvar som förut (deras plats ska inte avslöja den svagaste).
  En engångsrörelse som också är en loop (Alvas Spell_Simple_Shoot är både anfall och kast) spelas som kopia utan
  loop (`UnitModel._once`), så att figuren går tillbaka till vilan.
- **Makron** (kärnsystem, som i Siralim): upp till 20 rader per makro, subjekt + villkor + handling (+ mål),
  uppifrån och ned, första raden som passar och går att utföra vinner. Tilldelas per hjälte, med
  AUTO eller MANUELL per hjälte i striden (0.29.5): striden börjar på MANUELL; knappen växlar MANUELL → AUTO (följeslagarna) →
  ALLA AUTO, ett tryck på en hjältes ram byter den hjälten (`battle.gd` `_auto_heroes`); passar ingen rad väntar hjälten.
  Knappen MAKRON i striden öppnar redigeraren ovanpå den pausade striden (`macro_screen` `embedded`; ändringarna gäller
  direkt; `--battle-macros`).
  **Radeditorn** (0.30.24, VD): ett sökfält filtrerar alla fyra kolumnerna (alla ord måste finnas; det valda syns alltid),
  villkoren har grupper (Vanliga, Liv, Status, Egenskaper, Charges, Artefakt, Alla; Vanliga utan de hundratals
  egenskaperna), högre rader och en bred rullningslist. `--macros "--macro-search=liv 30"` för skärmdumpar.
  Sökfältet syns (makro-UX förslag 5, `docs/research/makro-ux.md`): en ritad lupp, guldram och förslagschips (liv,
  förgiftad, Charges, lägst) som fyller i sökningen utan tangentbord; fokus av sig självt bara utan pekskärm.
  **Varför inte** (förslag 1): `MacroRunner.decide(…, explain)` ger `notes`, en rad per rad ovanför den valda, också
  villkor som inte stämde ("Rad 1 stämde inte: någon allierad har liv < 30 % (lägst: Brokk 64 %)", `why_not`); makrologgen
  visar dem när den öppnas, och när inget passade står den närmaste raden först och syns i hörnet ("Närmast: …").
  **Startraderna** (förslag 2, varianten nära Siralim): `Run.starter_lines` lägger `FIRST_LINE` sist, så att en ny profils
  följeslagare inte står stilla; ingen fast standardrad utanför listan (det vore en avvikelse att ta upp med VD).
  0.30.25: en kedja (rader med "pröva nästa rad" och raden de leder till, `Run.macro_units`) tas med hel eller inte alls.
  **Kedjor** håller fast vid figuren som den första raden valde (VAL, Siralim okänt, `docs/research/siralim.md` §9b):
  radtexten säger "pröva nästa rad med den", radeditorn och hjälpen förklarar det, förklaringsloggen skriver "Kedjan prövade
  bara X". Alvas startmakro prövar den skadade först (liv < 80 % → pröva nästa rad; saknar Läkning → Läkande hand).
  Tester: `tests/test_starter_chains.gd` (skriver ut varje startmakro).
  **Villkoren förtjänas** (gambits, VD 2026-10-27, `docs/plan/gambits.md`, som Final Fantasy XII; i texten fortfarande
  "Makron"). **Gambits 2, legoklossar**: en rad är klossar, och man bygger makrona från noll genom att hitta hela rader.
  Klossarna ägs per profil (`Profile.gambits`, `data/gambits.json`, `src/game/gambits.gd` `Gambits`): villkoren, gränserna
  som egna klossar (`thresholds`, id `g_hp_below@50`; Liv under 10 % hos bossar, 20 % och Liv över 90 % hos elit) och
  subjekten och målen Allierad 1–4, Fiende 1–6, Alla allierade, Alla fiender och Slumpvis. Fria: Denna hjälte, Någon
  allierad, Någon fiende, Den som matchade, sig själv och alla handlingar. Ett fynd är en färdig rad (`Gambits.make_row`
  ur klossens radmallar `rows`, med en hjälte i sällskapet som kan utföra den; `Profile.learn_row`, `found_rows`): efter en
  vunnen strid (hem 15 %, elit 60 %, boss 100 %, 2 % var som helst, högst en; `Run.roll_gambit`, `last_row`), i kistor
  (Djupets tecken, Artefakt från djup 2), från följeslagare (makroförslaget eller `teach`, och klossarna i deras startrader,
  `Gambits.recruit_gift`) och introt (Gorms rad, den enda klossen en ny profil har: Lägst liv). Segerskärmen: NY RAD FÖR
  MAKRONA och LÄGG TILL HOS <HJÄLTE> (`Run.add_row`, överst i makrot); gambitsidan: FUNNA RADER. Nya villkor: Svag mot
  förmågan (`weak_to`, förmågans `bonus_vs`), Näst i tur (`next_in_turn`). Platser 3 + 1 per två nivåer, högst 12 (en
  kedja tar en plats, en rad med oägd kloss ingen, `Gambits.line_states`) (`Gambits.slots_for_level`,
  `Profile.gambit_slots`). Striden kör `Run.macro_for` = `Gambits.playable`: de första platserna, utan avstängda rader
  (`enabled`, `MacroRunner.decide` hoppar också över dem) och utan oägda klossar, kedjor hela eller inte alls. Gamla
  profiler (`gambit_version` < 2, också 0.30.50) äger allt i sina makron med alla gränser för sina villkor (familjens id
  äger alla, `Gambits.has`) och får minst lika många platser som det längsta (`setup_gambits`, `gambit_slot_floor`).
  Gambitsidan: stora kort (en sjättedel av höjden, `Card` i macro_screen), håll kvar tummen och dra, vibration när kortet
  släpps, PÅ/AV, låsta kort med rykte; radeditorn visar bara ägda klossar (VD: låsta syns inte alls där, bara som låsta kort i gamla makron). Biblioteket:
  VILLKOR med alla klossar och rykten. Botarna: `GAMBITS=ny` (en ny profils klossar, inga droppar), `tests/gambit_drops.gd`
  (strider till 3/6/10 funna rader, ägda klossar per nedstigning). Flaggor: `--macro-focus=<hjälte>`, `--gambit-off`,
  `--gambit-drag`, `--gambit-demo`, `--library-gambits`, `--found-rows`, `--new-line`. Tester: `tests/test_gambits.gd`.
  **Gambits 3**: en gång per strid (`once` på raden, brickan VARJE GÅNG / 1 / STRID under PÅ/AV, `CombatSim.macro_once`,
  `MacroRunner.once_key`, `decide(…, peek)`; `--gambit-once`, `--all-gambits`); villkor som läser fiendernas avsikter (gruppen Avsikt:
  `intends_attack`, `intends_attack_on` me/hjälte, `intends_attack_low`, `intends_aoe`, `leader_charging`, `intends_lethal`,
  `_intent_victims`); hem och rykten i Lunden och Berget (`home_clues`, `Gambits.clues`); mästarklossar (rarity `master`,
  klass III, `home_master` 50 %) hos Vävmodern och Bergakungen: Tänker fälla någon och Förbered kamratens slag
  (`ally_bonus_missing`). `tests/gambit_drops.gd` med `GAMBIT_PLAN=lang` fortsätter karriären i Lunden och Berget.
  **Spara som order** (0.30, prototyp): väljer spelaren själv något som makrot inte hade valt (en helning på en skadad,
  eller en förmåga mot en status den slår hårdare mot) visar striden en guldknapp i 9 sekunder som lägger en sådan rad
  överst i hjältens makro (`battle.gd` `_offer_order`, `_save_order`; `--offer-order`).
  **Introts kombination** (0.30): Rättfärdigt slag slår 50 % hårdare mot en Förblindad fiende (förmågans `bonus_vs`,
  `CombatSim._bonus_vs`, `calc.combo`), och Immas Rökpil förblindar alla fiender. Första gången visas rutan
  "Kombination!" med orsak och siffror (`HelpBox.offer_custom`, hjälpen "combo"), sedan ordet KOMBINATION! över målet;
  Imma tipsar om det när hon ansluter. `--combo` förblindar fienderna och kör ALLA AUTO för skärmdumpar.
  **Det här avgjorde striden** (0.30, byggets fingeravtryck, `BattleSummary.deciders`): segerskärmen visar till vänster
  upp till fyra delar av sällskapets bygge som bar striden, med källan (TROFÉ, KALL, ARTEFAKT, EGEN, KOMBINATION) och vad
  de gjorde (`CombatSim.trait_stats`, `combo_stats`); kallet räknas en gång under Paladinen. Samma urval är kvittot vid lägret.
  Andra halvan (0.30.16): tryck på en TROFÉ-rad så visas upp till fyra ägda troféer som kunde ta dess plats
  (`BattleSummary.alternatives`: samma roll, utlösare, sällsynthet; körningens troféer, i Övningsgården samlingen), med
  vem som bär dem; `--alt-open` öppnar listan för skärmdumpar. Plan för Löften per nedstigning: `docs/plan/loften.md`.
  **Varslade attacker** (0.31 prov, steg 1 av `docs/plan/varslade-attacker.md`, VD): en förmåga med `windup` (turns, text,
  broken_by, stagger, channeled_by, vulnerable_after) laddas i fiendens egna turer; avsikten får en ring med siffran och
  raden "SAMLAR KRAFT" (`CombatUnit.charging`, `CombatSim._windup_turn`). `turns` = egna turer tills den slår: 1 = nästa
  tur (en hjälterunda att svara), 2 = en tur går åt till laddningen; en avsikt som väljs om mitt i turen blir aldrig en laddning. Tystad bryter även på
  Resistenta (bara för laddningen), likaså skada ≥ stagger × max-liv och en dödad kanal; bruten = AVBRUTEN!, nedkylning och
  **Vacklande** (+25 % skada tagen till nästa tur); ingen ny laddning förrän efter fiendens nästa tur (`windup_guard`, skydd
  mot evigt lås). Sömn/Frusen skjuter upp. Makrovillkor `is_charging`, `charge_left_at_most` (gruppen Laddning); inga rader i
  startmakrona – hjälprutan "windup" och Gorms replik (`help_seen`) lär ut det. Först: Benfurstens Dödsdom (1 tur).
  `--windup` startar en laddning direkt (skärmdumpar). Tester: `tests/test_windup.gd`.
  **Träffytor** (polering fynd 6, `TargetPick`): kroppen och namnskylten (namn, livmätare, avsikt) räknas; träffar ett tryck
  flera vinner närmaste mitt. Fiender vars skyltar och överkroppar överlappar i bilden knuffas isär i sidled när striden
  byggs (`battle.gd` `_spread_enemies`, bara utseende). Ord som stiger över en fiende börjar vid bröstet (`--float-demo`).
  Tidslinjen visar hjältarnas porträtt, fiendernas begynnelsebokstav (elit i guld) och "NU: <namn>". Förklaringsloggen
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
- Prestanda och bakåtknappen (`docs/research/prestanda-android.md` punkt 1, 2, 8, 9): `Run.update_fps` ger 30 bilder per
  sekund utanför striden (60 när skärmen svarar `wants_smooth()`: kartornas zoom, rumsögonblick), striden utan gräns som
  förut men 30 när den står still; inte headless eller med `--write-movie`. Pergamentet (`Parchment`) ritas en gång i en
  SubViewport och bara om när storlek eller zoom ändras. `quit_on_go_back=false`: `Run.go_back` stänger en öppen ruta,
  sedan skärmens `go_back()` eller ‹-knapp; striden pausar med inställningsrutan; i borgen, profilerna och grottan
  avslutar ett andra tryck inom 2,5 s. `--go-back` trycker bakåt en gång efter en sekund (skärmdumpar).
- Text (0.20.3): minst 15 px (`UiStyle.MIN_SIZE`, golv i `UiStyle.text`), brödtext ~17–19 px (`UiStyle.BODY_SIZE`,
  `UiStyle.para()` bryter rader). Kontrollera skärmar i 1280×720 och telefonens bredd: `godot --path . --resolution 1560x720`.

## Struktur

- `src/game/run_state.gd` – en körning: kall och perks, sällskap, våning (`FLOORS`), troféer och vem som bär dem,
  artefakter; `new_run()` och `new_practice()` (Övningsgården: valfritt möte, fulla Charges).
  `src/game/profile.gd` – det som varar mellan körningar: silver, samlingen, artefakter (`forge()`),
  valt kall och köpta perks per kall (`buy_perk()`, `reset_perks()`, `perk_points()`, `active_perks()`), senaste sällskap, övningstroféer, valt och
  djupaste klarade djup (`choose_depth()`, `clear_depth()`), perk-nivåer (`perk_rank()`) och lånade perks
  (`bosses_defeated`, `anoint()`, `anointed`). Sparas i `user://slot<n>/progress.cfg`.
  `src/game/save_slots.gd` – `SaveSlots` (0.23.1): tre sparplatser, var och en med egen progress.cfg, run.cfg och
  macros.json i `user://slot1/`–`slot3/`; senast använda i `user://slots.cfg`. `migrate()` flyttar filer från före
  0.23.1 orörda till plats 1. `summary()` ger kortets rader. Huvudscenen är `scenes/slots.tscn` (`slots_screen`):
  den visas vid start, `Run.choose_slot()` laddar platsen och fortsätter en sparad körning; borgen har ‹ PROFILER.
  `src/game/hero_stats.gd` – `HeroStats`: nivåer, tillväxt, personlighet, `breakdown()` per källa, erfarenhet,
  väntad nivå och fiendernas nivå. `data/personalities.json` – de 20 personligheterna (namn, up, down, text).
  `src/game/grotto.gd` – `Grotto` (0.27): en våning ur ett frö (`generate()`, `problems()` för reglerna, `blocked()`,
  `path()`). RunState håller grottan: `start_expedition()`, `start_floor()`, `can_step()`, `step()`, `back()`, `fight()`,
  `battle_opts()`, `battle_won()`, `collect_item()`, `campfire()`, `treasure()`, `shrine_options()`/`apply_shrine()`,
  `floor_cleared()`, `next_floor()`, questen och `save()`/`load_from()` (en körning sparad med 0.18:s rumskarta fortsätter inte).
  `scripts/game/run.gd` är autoloaden `Run` som byter scen (bas → kampanjkarta → rumskarta → rum/strid →
  läger → rumskarta … → bas;
  bas → Övningsgården → strid → Övningsgården) och sparar makrona i `user://macros.json`
  (startmakron i `data/macros.json`).
  Makroskärmen (0.23.2) visar bara Paladinen och de som har anslutit (`Run.macro_heroes()`), och ett tomt makro
  föreslår `Run.FIRST_LINE` (anfall fienden med lägst liv) som läggs till med ett tryck. `--new-profile` sparar inte makrona.
  Skärmar i `scripts/screens/`: `base_screen` (borgen, första skärmen), `inn_screen` (Värdshuset), `campaign_screen` (kampanjkartan),
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
- `data/artifacts.json` – artefakttyperna (stat, utlösande handling, chans). `data/materials.json` – bärnsten,
  trick och Nether Stones sällsynthet (0.20). `src/game/forge.gd` – `Forge`: nivåer, platser, `stat_parts()`
  (artefakt, material, Nether Stone per stat, samma i striden och i hjältebladet), `effect_traits()`,
  `roll_finds()`, `roll_stone()`. `Profile`: `artifact()`, `level_artifact()`, `socket()`, `socket_stone()`,
  `materials`, `stones`. Ritas av `scripts/screens/gem_art.gd`.
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

# Balanssimuleringen (docs/plan/balanssimulering.md): hela nedstigningar (huvudmålen) och varje möte ur datan (fulla och
# tömda Charges) på väntad nivå ±1, med fyra och fem; CSV och sammanfattning av det som ligger utanför målen. Hela
# tabellen tar ~3,6 h processortid (kör två delar åt gången och slå ihop med --merge); urval med --realm/--depth/--enc.
godot --headless --path . --script res://tests/balance_sim.gd -- --realm=crypt --depth=1 --out=/tmp/balans.csv

# Buggjakt med botar (0.30.16, tests/soak.gd): tusentals hela körningar med slumpade val och kontroller efter varje drag
# (körfel, fastlåsning, eviga strider, sparning och inläsning, silver, samling, Charges). --seed=N --verbose återskapar ett fel.
godot --headless --path . --script res://tests/soak.gd -- --runs=1000

# Granskningen av siffrorna (0.23.3): räknar om varje skada, helning och undvikande i 432 seedade strider med en
# oberoende formelmodul (tests/numbers_reference.gd) och listar avvikelser. AUDIT_SEEDS=n ändrar antalet frön.
godot --headless --path . --script res://tests/numbers_audit_report.gd

# Varje perk för sig (hela kryptan med startmakrona)
godot --headless --path . --script res://tests/perk_report.gd

# Textspel (provspel utan grafik, tests/text_play.gd): spelets logik ett kommando per anrop, läget och log.txt i mappen;
# help visar kommandona (go d5, fight, back, choose 1, take 1, swap, macro, smith, socket, start …). Provspel:
# docs/provspel/textspel-dagbok.md och textspel-logg.md
godot --headless --path . --script res://tests/textplay_cli.gd -- --dir=/tmp/tp new

# Skärmdump av spelet (sparas efter 30 bildrutor, sedan avslut)
godot --path . -- --screenshot=/tmp/shot.png --frames=30

# Starta direkt i en strid (våning 0–2), låt AI:n spela, spola fram 10 turer, fast slumpfrö
godot --path . -- --floor=2 --demo --turns=10 --seed=5

# Visa lägret mellan striderna direkt
godot --path . -- --camp

# Hjältebladet direkt (--tab=0–2), och erfarenhet för att se nivåuppgångar på segerskärmen
godot --path . -- --hero=brokk --tab=0
godot --path . -- --xp-bar=85 --floor=0 --demo --turns=300

# Grottan med en ny körning (efter --realm, --depth, --instability); --enter=<sort> lägger en sådan ruta bredvid start
# och går dit (elite, campfire, treasure …); --campfire-camp visar trofébytet vid en lägereld
godot --path . -- --realm=chapel --map
godot --path . -- --all-companions --map --enter=elite
godot --path . -- --all-companions --map --campfire-camp

# Grottan i botarna: vinst, strider och steg per körning
BALANS=grotta godot --headless --path . --script res://tests/balance_report.gd

# Profilskärmen med raderingsbekräftelsen öppen (för skärmdumpar)
godot --path . -- --confirm-delete=1

# Borgen direkt (0.24): på ett introsteg (en påhittad profil), i ett samtal, och en replik på rumskartan
godot --path . -- --keep
godot --path . -- --intro-step=imma --keep --talk=imma
godot --path . -- --all-companions --keep --talk=smith
godot --path . -- --intro-step=crypt --map --bark=new_realm

# 0.25: natten och arbetarna (--line=N visar en viss rad i samtalet), Imma som smiter efter, handboken
godot --path . -- --intro-step=workers --keep --line=3
godot --path . -- --intro-step=descent --map --story=imma_joins
godot --path . -- --handbook

# Första nedstigningen och små sällskap i balansrapporten
BALANS=forsta godot --headless --path . --script res://tests/balance_report.gd

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

# Smeden med en påhittad profil som inte sparas (--smith-hero, --smith-slot=stat:1, --smith-pick=amber_green),
# segerskärmen med fynd som efter en boss, och scenen för ett legendariskt fynd
godot --path . -- --forge-demo --smith --smith-hero=brokk --smith-slot=stat:1 --smith-pick=amber_green
godot --path . -- --forge-demo --find-luck --floor=0 --demo --turns=300 --seed=3
godot --path . -- --forge-demo --find-demo

# Bara artefaktavsnittet i balansrapporten (artefakter på nivå 1, 5 och 10, fynd och silver per körning)
BALANS=artefakter godot --headless --path . --script res://tests/balance_report.gd

# En ny profil (sparas inte), en profil med alla lärjungar, och Värdshuset direkt
godot --path . -- --new-profile
godot --path . -- --all-companions --inn

# Sällskapets storlek och de nya följeslagarna i balansrapporten
BALANS=sallskap godot --headless --path . --script res://tests/balance_report.gd

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

Tester: lägg `tests/test_*.gd` som ärver `res://tests/test_case.gd`, metoder som börjar på `test_`. Köraren fångar körfel (en
Logger i `run_tests.gd`) och avslutar med felkod om något misslyckas; `tests/test_runner.gd` kör fixturerna i
`tests/fixtures/` (som måste misslyckas) och kontrollerar det. Lägg aldrig `test_`-filer som ska lyckas i fixtures.
