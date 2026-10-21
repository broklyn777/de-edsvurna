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
- **Troféer** ersätter Siralims smältning: besegrade monstertyper lämnar en trofé som ger bäraren monstrets
  egenskap. Vanlig = pålitlig byggdel, elit = specialiserad, boss = ändrar en regel (med kostnad).
  Hjältarna behåller sina troféer (0.26.3, som i Siralim, `Profile.worn`, `wear()`, `keep_worn()`): de följer med i varje
  körning och i Övningsgården tills man byter i lägret eller i Förberedelser; allt som hittas hamnar i samlingen.
  En andel av en träff (`pct_of_event`, t.ex. följdanfall) blir aldrig kritisk igen.
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
  bytas utan att nivån och materialen går förlorade (vårt val). Fynden syns på segerskärmen, i
  skattkammaren och på rumskartan; sällsynta stenar får en egen scen (`find_reveal.gd`). Ljud:
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
  alltid bevakade). Belöningen (silver, perk-poäng) ges för den sista våningens quest, en gång per körning som förut.
  Lägereld = +3 Charges per förmåga en gång, och **troféer byts bara vid en lägereld** (VAL; lägret i läget "campfire",
  `Run.open_campfire_camp`; efter en strid väljer man bara en ny trofé). Helgedom = välj en gåva eller Pandemonium.
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
  även stupade) och varje nivå ger +30 % av basvärdet i varje stat. Inget tak, som i Siralim: den som kör
  fast går tillbaka till ett lägre djup och tränar.
  En av 20 personligheter låter en stat växa 40 % och en annan 20 % (byts i Biblioteket, räknas om bakåt).
  Nivåerna sparas i `Profile.heroes`. Fiendernas nivå följer bara djup och våning, som i Siralim
  (`HeroStats.enemy_level`: 5 × (djup − 1) + 2,25 + 1,5 per våning; väntad nivå 3, 8, 13 …).
  *Vårt val* (originalet okänt): erfarenhet 17 × rumstyp × djup², så att lägre djup ger mindre men går att
  träna på, och till nästa nivå 5 · L² + 10 (15, 30, 55, 90 …): de första nivåerna går fort. **Hjältebladet** (`hero_screen`, från
  lägret, Förberedelser och Biblioteket): nivå, erfarenhet, fiendernas nivå på valt djup, personlighet, stats per källa
  (`HeroStats.SOURCES`; 0.20 lägger till material och Nether Stone), vad de
  betyder i skada och helning mot en typisk fiende, egenskaper med körningens statistik, förmågor,
  artefakt och historik. Nivåuppgångar syns och hörs på segerskärmen.
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
  värdshuset. Kortraden längst ned är genvägar. **Repliker under nedstigningen** (`Dialog.bark`, `Run.bark`):
  Imma (och andra) säger en rad efter en svår strid, vid lägerelden, vid ett sällsynt fynd, en befrielse, i en ny
  Realm eller när paladinen står ensam kvar; högst en per rum, aldrig i striden, inget upprepas samma körning
  (`RunState.barks_used`); ibland ett kort samtal mellan två (`pairs`). Visas på rumskartan. 0.28.1: tillfällen i grottan (cave, elite, back, treasure, stairs, boss, fallen; home i datan men visas inte än) för
  sju följeslagare ur ChatGPT:s version 2 (`docs/ideer/repliker-v2.tsv`); nya repliker är `{id, text}` med fasta id:n
  (t.ex. `imma_elite_1`, för eventuella röster senare), `Dialog.line_text`. Ragnhild Ljusdom (0.29.1) är sträng, konservativ och
  älskvärd och citerar bibelord **endast ur 1917 års kyrkobibel**, ordagrant och kontrollerade (`ref`,
  `docs/ideer/ragnhild-bibelord.md`); aldrig för att förlöjliga tron.
  **Värdshuset** (0.29.3, Siralims samtal med skapelserna, ChatGPT:s jobb E, `docs/ideer/chat-vardshuset-och-sok.md`): tryck på en
  följeslagare som bor i värdshuset så säger hen något (`dialog.json` "inn": inn, bored, welcome med id:n; `Dialog.inn_line`),
  valet Visa hjältebladet. Välkomstrepliken en gång efter en nedstigning hen stannade hemma under (`Profile.home_runs`,
  `inn_heard`), efter två nedstigningar hemma vill hen följa med. Kronan steg 2 (Gorm, Alrik) när två bossar är besegrade
  (`min_bosses`). `--talk=<följeslagare>` med `--all-companions --keep`.
  **Introduktionen** för en ny profil (`data/intro.json`, `src/game/intro.gd`): eden vid altaret, en övningsstrid
  ensam, svärdet hos Smeden (bara svärdet går att välja), första makroraden, Biblioteket, och (0.25 "Berättelsen",
  `docs/plan/0.25-berattelsen.md`) natten: berättarens rutor, sedan arbetarna från kryptan på gården (de skadade på
  bårar, Mor Elin och Broder Alrik hos dem, `keep.json` "scene"). Gravgrävaren Tor berättar, Gorm skickar paladinen
  ned ensam och Imma får stanna (stegen `workers` och `descent`; steg med `"auto"` spelar samtalet direkt i borgen,
  rader är text eller `[talare, text]`, `Intro.lines`). Den första striden gör paladinen ensam (fienderna ×0,80 till,
  `RunState.FIRST_FIGHT_ALONE`, ~99 % vinst); direkt efter den smiter Imma efter (0.25.1: striden märker `RunState.joins_next`, hon ansluter först på rumskartan efter segerskärmen, `Run.imma_sneaks`; hennes porträtt
  på rumskartan, `intro.json` "imma_joins") och följer med resten av vägen. Hemma igen (`came_home`) skäller Gorm lite
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
- **Ge upp** (0.20.1, Siralims Forfeit): knappen GE UPP bredvid 1×/Auto, med en bekräftelse. Räknas som
  förlust: körningen och questens belöning går förlorade och Realmen börjar om från våning 1 (`run.cfg`
  tas bort, `RunState.delete_saved`); erfarenhet, troféer, silver och material som redan är vunna finns kvar.
  `CombatSim.forfeit()`. `-- --ask-forfeit` visar frågan i en strid.
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
- **Död:** en död figurs egenskaper slutar verka, även Paladinens kall, och verkar igen när den väcks.
- **Stats och skada** (0.13, som Siralim): Health, Attack, Intelligence, Defense, Speed. Attack =
  (max(Atk − Def, 0) + 1 % Atk) × mod, Spell = max(Int × nivå − Def, 0) × mod, Indirect = × mod − 20 % Def.
  Försvara: −35 % skada och +50 % Defense; Provocera: −35 % Defense. Krit och undvikande från Speed-kvoten
  (vårt val, formeln är inte publicerad). Barriär tar skada före livet. Se `docs/research/siralim.md` §12.
  **Små tal** (0.26, som Siralim): grundvärdena för Health, Attack, Intelligence och Defense delades med 10 (Paladinen 90
  Health, Brokk 115, en vanlig träff 10–15). Stats har en decimal (`CombatSim.snap_stat`, Speed i heltal); skada och
  helning avrundas till heltal en gång på slutet (inget golv på 1 längre; en mycket svag träff kan göra 0 men räknas som en träff för egenskaperna), och skadeloggen visar mellanleden med en decimal och
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
  i klartext. I striden: tryck på en siffra, eller SKADELOGG. Hjältebladet räknar med `CombatSim.expected_damage()`
  (samma formler och modifierare som striden). `tests/test_numbers.gd` prövar formlernas egenskaper.
  `-- --show-calc` och `-- --damage-log` visar dem direkt i en strid. **Granskningen** (0.23.3, `docs/formler.md` §11–12):
  `tests/numbers_reference.gd` är formlerna skrivna en gång till utan spelets kod; `tests/audit_sim.gd` + `numbers_audit.gd`
  räknar om varje händelse i seedade strider (`tests/test_numbers_audit.gd` kör 72 strider i testerna). Stats som inte
  är heltal visas med en decimal (`HeroStats.shown`, `shown_parts`).
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

# Granskningen av siffrorna (0.23.3): räknar om varje skada, helning och undvikande i 432 seedade strider med en
# oberoende formelmodul (tests/numbers_reference.gd) och listar avvikelser. AUDIT_SEEDS=n ändrar antalet frön.
godot --headless --path . --script res://tests/numbers_audit_report.gd

# Varje perk för sig (hela kryptan med startmakrona)
godot --headless --path . --script res://tests/perk_report.gd

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
