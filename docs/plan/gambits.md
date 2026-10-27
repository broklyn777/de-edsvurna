# Gambits: makronas villkor som man förtjänar

VD 2026-10-27: "kör". Förslaget kommer från Claude-chatten (`docs/ideer/claude-chat-striden-och-gambits.md`, "Allra viktigast 1"),
med Final Fantasy XII som förebild. Siralim är en verktygslåda: där har man alla villkor från start, och här förtjänar man dem.
I spelets text heter det fortfarande **Makron**. VD har inte bestämt namnet, och "gambit" används bara i koden, datan och den här planen.

## Gambits 3: en gång per strid, avsikter och nya hem

VD 2026-10-27 ("kör"), efter 0.30.51.

1. **En gång per strid** (`once` på raden, som PÅ/AV). Brickan under PÅ/AV på kortet växlar mellan VARJE GÅNG och 1 / STRID
   (`toggle_once`). Striden minns körda rader i `CombatSim.macro_once` (nyckel `MacroRunner.once_key`: hjälten och radens
   innehåll). `MacroRunner.decide` registrerar raden när den väljs, utom vid en titt (`peek`, Spara som order). I en kedja
   räknas varje rad med brickan. Förklaringsloggen skriver "Rad N har redan körts den här striden". Exempel: Imma skjuter
   Rökpil en gång per strid och sparar sina Charges. *Vårt val*: FF XII har ingen sådan bricka, men den löser det vanligaste
   felet i botarnas makron, en buff eller debuff som läggs om och om igen.
2. **Villkor som läser fiendernas avsikter** (gruppen Avsikt i radeditorn, tillsammans med Tänker hela). Avsikten syns
   redan över fienden, så villkoren läser bara det spelaren ser:
   - `intends_attack` "tänker anfalla" och `intends_attack_on` "tänker anfalla denna hjälte/Paladinen …" (värdet är `me`
     eller en hjälte), kloss **Tänker anfalla**.
   - `intends_attack_low` "tänker anfalla någon med liv < 30/50 %", kloss **Tänker anfalla den svage**.
   - `intends_aoe` "tänker träffa alla", kloss **Tänker träffa alla** (elit).
   - `leader_charging` "är bossen eller en elit och laddar sitt stora slag", kloss **Bossen laddar** (elit).
   - `intends_lethal` "tänker fälla någon" (avsiktens väntade skada, `CombatSim.expected_damage`, når målets liv och
     Barriär), mästarkloss **Tänker fälla någon**.
   *Vårt val*: en avsikt som är en helning räknas aldrig som ett anfall (`_intent_victims`).
3. **Hem i Sidenlunden och Trollberget**: alla klossar med hem har nu också ett hem bland spindlarna och ett bland trollen,
   med egna rykten (`home_clues`, Biblioteket visar alla, `Gambits.clues`). De skarpa gränserna finns hos Vävmodern,
   Sömnvävaren och Gråluva, och elitklossarna hos Strypvävaren, Brom och Gråluva.
4. **Mästarklossar (klass III, rarity `master`)** finns bara hos Realmernas bossar Vävmodern och Bergakungen, 50 % av gångerna
   (`home_master`):
   - **Tänker fälla någon** ("Om någon fiende tänker fälla någon → Provocera").
   - **Förbered kamratens slag** (`ally_bonus_missing`): fienden saknar en status som en levande allierad har en förmåga som
     slår hårdare mot (`bonus_vs`). Till exempel lägger Imma Rökpil på den som inte är Förblindad, så att Paladinens
     Rättfärdigt slag biter.

## Gambits 2: legoklossar och funna rader

VD 2026-10-27 ("kör"): **en makrorad består av legoklossar, och man bygger upp makrosystemet från noll genom att hitta hela
rader.** Den här delen ersätter beslut 1–4, 6, 7 och 12 nedan där de säger emot den. Resten (platser, PÅ/AV, gambitsidan,
Biblioteket) gäller som förut.

1. **Fynd är färdiga rader** (`Gambits.make_row`, `Profile.learn_row`, `Profile.found_rows`). En droppe, en kista, en
   befrielse eller introt ger en hel rad, till exempel "Om någon allierad har liv < 30 % → Helande ljus på den som
   matchade". Varje kloss har radmallar i `gambits.json` ("rows"), prövade i ordning. Den första mall som någon hjälte i
   sällskapet kan utföra blir raden, och fyndet väljer den hjälten: för en förmåga den som har den, för Anfall någon, och
   för Försvara och Provocera den med högst Defense. Kan ingen läka blir "liv < 30 %" en Helig sköld hos Paladinen, och
   kan ingen skydda blir det Provocera. En mall kan ange en förmåga eller en sort (heal, protect, support, cleanse, damage,
   aoe, debuff, bonus, `Gambits.ability_fits`). *Vårt val*: sorterna läses ur förmågornas effekter, så att nya hjältar
   passar in utan ny data. **Varje rad ska kunna göra nytta** (`Gambits.row_problem`, testet
   `test_every_template_can_do_some_good`): målet och handlingen ska gå ihop med subjektet och villkoret. Har stupat och Har
   väckts matchar också döda, så de paras aldrig med en handling på den som matchade. Har stupat ger en återupplivning om
   någon har en, annars en sköld på sig själv eller Provocera. Varje lista slutar med en mall utan förmåga.
2. **Segerskärmen** visar raden i ett guldkort, "NY RAD FÖR MAKRONA", med knappen **LÄGG TILL HOS <HJÄLTE>**. Ett tryck
   lägger raden överst i hjältens makro (`Run.add_row`, samma väg som Spara som order och makroförslagen). Skattkammaren
   skriver raden i rummets text. Alla fynd sparas i **FUNNA RADER** på gambitsidan, där varje rad kan läggas till hos sin
   hjälte eller i det makro som är öppet. Varje rad säger var den kom ifrån, med namn ("Från Klockaren", "Lärd av Syster
   Alva", "Ur en kista på djup 2", `from`). Samma rad sparas en gång (`Profile.merge_found_rows`, också för gamla sparfiler),
   med alla hjältar den kom från i `heroes`. Knappen gäller den första av dem som har anslutit och saknar raden.
3. **Klossarna i en funnen rad blir ens egna** och är fria att kombinera: "liv < 50 %" går att använda både för att hela
   och för att slå en fiende. `Gambits.needs(rad)` ger radens klossar, och raden är spelbar när profilen äger alla.
4. **Gränserna är egna klossar** (`"thresholds"` i gambits.json, id `g_hp_below@50`). Liv under 10–80 % och Liv över
   30/50/70/90 % har var sitt hem. De skarpa gränserna finns hos svårare fiender: Liv under 10 % hos bossar, 20 % och Liv
   över 90 % hos elit. Charges kvar har ingen siffra i vårt villkor (värdet är en förmåga), så där är villkoret klossen.
   Statusar, egenskaper och förmågor är fria värden när man äger villkoret. *Vårt val*: tröskelvärdena följer editorns gamla
   steg om tio. En gräns som inte står i listan (35 eller 45 i gamla startmakron) är också en egen kloss, men den kan inte
   hittas.
5. **Vad som förtjänas**: villkoren, gränserna och de specifika subjekten och målen, nämligen Allierad 1–4, Fiende 1–6
   (subjekt och mål), Alla allierade, Alla fiender och Slumpvis (`"subjects"`/`"targets"` i gambits.json). **Fria från
   start**: Denna hjälte, Någon allierad, Någon fiende, Den som matchade och mål "sig själv" (`free_subjects`,
   `free_targets`). Ett mål räknas bara när handlingen använder det (Anfall, Förmåga). **Handlingarna är fria**.
6. **En ny profil börjar nästan tom** (`Profile.setup_gambits`): bara Lägst liv. Gorms rad i introt ("Om någon fiende har
   lägst liv → Anfall på den som matchade") är det första fyndet. En följeslagare som ansluter (`Profile.recruit`,
   `Gambits.recruit_gift`) ger sitt makroförslag som funnen rad, till exempel Alvas "liv < 50 % → Helande ljus" och Brokks
   "liv < 50 % → Provocera". Följeslagare utan förslag ger en rad för sin kloss i `"teach"`, Imma till exempel "Om någon
   fiende har en buff → Anfall". Följeslagaren lär också ut klossarna i sina startrader (`Run.starter_lines`), så att en ny
   profils följeslagare gör samma sak som förut. *Vårt val*: VD vill att makrona byggs från noll, men en följeslagare som
   står stilla för att hennes egen startrad är låst är inte roligt.
7. **Radeditorn visar bara ägda klossar.** En ny profil ser alltså bara Lägst liv bland villkoren, inte tio rader med liv.
   VD 2026-10-27 (Gambits 3): låsta klossar syns inte alls i editorn, inte ens Pröva nästa rad ("Det får komma
   överraskningar … annars blir det övermäktigt"). En rad i ett gammalt makro med en oägd kloss står kvar som ett låst kort
   på gambitsidan. Biblioteket och ryktena är oförändrade tills VD har bestämt.
8. **Gamla profiler förlorar ingenting**. Den här versionen (`gambit_version` 2) behandlar profiler från före gambits och
   från 0.30.50 som gamla: allt i deras makron räknas som ägt, och för ett villkor man äger räknas alla gränser som ägda
   (familjens id, `g_hp_below`, äger alla gränser, `Gambits.has`). De startvillkor som 0.30.50 gav (Liv under …, Lever)
   äger alltså fortfarande alla sina gränser.
9. **Tre villkor från idéfilen**: **Svag mot förmågan** (`weak_to`, värdet är en förmåga med `bonus_vs`, till exempel
   Rättfärdigt slag mot en Förblindad fiende) och **Näst i tur** (`next_in_turn`, den som står efter den som har turen,
   till exempel "Paladinen står näst på tidslinjen") finns, med hem hos Gast och Kyrkogrim respektive Benspringare och
   Blodsvuren. **Högst en gång per strid** är inget villkor utan en egenskap hos raden, som kräver att striden minns vilka
   rader som har körts. Det blir nästa steg.

### Balans för Gambits 2 (kört 2026-10-27, 100 körningar per rad, djup 1)

*Före* = test-0.30 (0.30.50, version 1) med `GAMBITS=ny`, alltså startvillkoren Lägst liv, Liv under … och Lever, det
följeslagarna lärde ut och platser efter nivån. *Efter* = den här grenen med `GAMBITS=ny`: bara Lägst liv, det
följeslagarna lär ut (makroförslaget och klossarna i deras startrader) och inga droppar. MACRO = en ny profils makron och
makroförslagen. TUNED = botarnas fulla makron, filtrerade genom det profilen äger.

| Mätning | Realm | Rad | MACRO före | MACRO efter | TUNED före | TUNED efter |
|---|---|---|---|---|---|---|
| forsta | Kryptan | ensam, Imma efter strid 1 (profilens första) | 44 % | 44 % | 29 % | 45 % |
| forsta | Kryptan | första nedstigningen (trappa) | 46 % | 46 % | 33 % | 47 % |
| forsta | Kryptan | Paladinen + Imma, nivå 3 | 31 % | 31 % | 17 % | 32 % |
| forsta | Kryptan | + Imma + Brokk, nivå 3 | 53 % | 51 % | 27 % | 44 % |
| forsta | Kryptan | andra, nivå 3, en fånge | 26 % | 33 % | 22 % | 25 % |
| forsta | Kryptan | ny profil nivå 1, befriar fångar | 7 % | 10 % | 5 % | 5 % |
| forsta | Kapellet | ensam, Imma efter strid 1 | 96 % | 96 % | 82 % | 98 % |
| forsta | Kapellet | första nedstigningen (trappa) | 96 % | 96 % | 86 % | 97 % |
| forsta | Kapellet | Paladinen + Imma, nivå 3 | 69 % | 69 % | 63 % | 70 % |
| forsta | Kapellet | + Imma + Brokk, nivå 3 | 45 % | 49 % | 28 % | 45 % |
| forsta | Kapellet | andra, nivå 3, en fånge | 43 % | 41 % | 41 % | 47 % |
| forsta | Kapellet | ny profil nivå 1, befriar fångar | 16 % | 15 % | 13 % | 16 % |
| grotta | Kryptan | första: ensam, Imma efter strid 1 | 44 % | 44 % | 29 % | 45 % |
| grotta | Kryptan | Paladinen + Imma, nivå 3 | 31 % | 31 % | 17 % | 32 % |
| grotta | Kryptan | 4 hjältar, *fulla* startmakron, nivå 3 | 0 % | 0 % | 0 % | 0 % |
| grotta | Kapellet | första: ensam, Imma efter strid 1 | 96 % | 96 % | 82 % | 98 % |
| grotta | Kapellet | Paladinen + Imma, nivå 3 | 69 % | 69 % | 63 % | 70 % |
| grotta | Kapellet | 4 hjältar, *fulla* startmakron, nivå 3 | 0 % | 0 % | 1 % | 0 % |

- **En ny profils väg ändras inte (MACRO).** Paladinens första rad är Gorms rad, och följeslagarna lär ut klossarna i sina
  startrader. Skillnaderna i raderna med fångar (−2 till +7) är brus vid 100 körningar.
- **TUNED stiger** (kryptan ensam 29 → 45 %). I version 1 ägde en ny profil Liv under … och Lever, så halva TUNED-raderna
  kördes utan resten av sin plan och Paladinen slösade turer. Nu äger han bara Lägst liv och kör samma rad som MACRO.
- **Kryptans första nedstigning ligger kvar på 44 %**, inte kring 80 % som CLAUDE.md säger. Det gällde redan före gambits
  och är en egen fråga.
- **Raden "4 hjältar med fulla startmakron" är fortfarande konstgjord**: en ny profil får aldrig de makrona.

### Hur snabbt raderna kommer (`tests/gambit_drops.gd`, 40 karriärer, MACRO)

Samma karriär som ovan. Bara fynd från strider och kistor räknas, inte introts rad och inte det följeslagarna lär ut.
Klossar ägda räknar också det följeslagarna lär ut, av de 43 som går att hitta.

| Funna rader | Vunna strider, median (25–75 %) | Nedstigning, median |
|---|---|---|
| 3 | 3 (2–4) | 1 |
| 6 | 7 (6–9) | 1 |
| 10 | 15 (13–16) | 2 |

| Efter nedstigning | 1 | 2 | 3 | 4 | 5 | 6 | 8 | 10 |
|---|---|---|---|---|---|---|---|---|
| Funna rader | 6,9 | 12,1 | 18,3 | 21,6 | 25,0 | 27,6 | 31,1 | 33,0 |
| Klossar ägda (av 43) | 11,5 | 18,6 | 25,7 | 29,5 | 33,0 | 35,7 | 39,3 | 41,3 |
| Vunna strider | 9 | 18 | 27 | 36 | 46 | 55 | 72 | 88 |

Droppen sänktes till 15 % för hem och 2 % var som helst (förut 25 % och 3 %). Med 43 klossar i stället för 23 gav 25 % 10
rader redan efter 11 strider och 39 av 43 klossar efter sex nedstigningar. Med 15 % kommer 10 rader efter 15 strider (version
1: 18), och förrådet räcker till ungefär åttonde nedstigningen. De sällsynta (Kedja, På sin tur …, Bär laddningen, Har väckts)
hittas i 9–32 av 40 karriärer efter tio nedstigningar. Kedja och Liv under 50 % hittas sällan i strid, eftersom Alva lär ut
dem.

**Nackdelen** är densamma som förut: efter ungefär åtta nedstigningar finns bara de sällsynta kvar. Lunden och Trollberget
behöver egna hem, och villkor som läser fiendernas avsikter är nästa steg.

## Kärnan

En gambit ger ett **omdöme**, inte en förmåga. Handlingarna (Anfall, förmågorna, Försvara, Provocera) kan man alltid välja för
hand och alltid lägga i en rad. Det man förtjänar är **villkoren** och fler **platser**. Utan "liv under …" kan man ändå hela den
som håller på att dö, men då måste man se det själv.

## Beslut

1. **Villkoren ägs per profil** (`Profile.gambits`, id:n i `data/gambits.json`). Ett villkor täcker en familj av
   makrovillkor, till exempel `g_status` = har/saknar status och `g_immune` = kan skadas/är immun. Värdena är fria när man
   äger villkoret, till exempel liv under 10–100 % och vilken status som helst. *Vårt val*: i FF XII var varje tröskel en egen
   gambit, men vår editor har värdena i en lista, och 26 villkor att jaga räcker.
   Subjektet (denna hjälte, någon allierad, fiende 3 …) är också fritt.
2. **Startvillkor** (rarity `start`): **Lägst liv** (introts första rad), **Liv under …** och **Lever**. *Vårt val*: "Lever"
   motsvarar FF XII:s "Fiende: vem som helst".
3. **Kedjan** ("Pröva nästa rad") är en gambit (`g_chain`), trots att den står bland handlingarna. *Vårt val*: den är ett
   omdöme, inte något hjälten kan göra för hand.
4. **Följeslagarna lär ut sitt villkor** när de ansluter (`gambits.json` "teach", `Profile.recruit`): Imma lär ut buffar
   (hennes rad "om en fiende har en buff → anfall"), Alva kedjan, Brokk högst Defense, Eira status, Torun "tänker hela" och
   så vidare. Befrielserutan säger "Alva lär dig ett nytt villkor för makrona: …".
5. **Platser per hjälte** (*vårt val*, satt med botarna): 3 från start och +1 per två nivåer, högst 12
   (`Gambits.slots_for_level`: nivå 1–2 = 3, 3–4 = 4, 5–6 = 5 … nivå 19 = 12). En plats rymmer en enhet: en rad, eller en
   kedja med "pröva nästa rad" och raden den leder till. En avstängd rad tar sin plats, som i FF XII. En rad med ett villkor
   profilen inte äger tar ingen plats, eftersom ett oägt villkor inte kan stå i listan i FF XII. Den står kvar låst
   (`Gambits.line_states`). Det beslutet kom efter den första botkörningen, där låsta rader åt platserna (se Balans). Rader
   under den sista platsen står kvar men körs inte, och de syns som "Platsen öppnas på nivå N".
6. **Var villkoren finns** (`homes` i gambits.json): varje vanligt villkor har två eller tre hem bland kryptans och kapellets
   fiender. Tankvillkoren finns hos fiender som själva försvarar sig (Kistbäraren, Fanbäraren och Gravväktaren), och
   helarvillkoren i kapellet (Fördärvad diakon: Tänker hela, Häxa och Botgörare: debuffar). De sällsynta finns hos elit och
   boss: **Har stupat** ("när en allierad faller") hos Klockaren och Abbedissan, **På sin tur …** ("första turen") hos
   Benkolossen och Den svarta lansen, **Laddar** hos Benfursten och biskopen, och **Har väckts** hos Gravväckaren.
   Kistvillkoren (Bär en artefakt från djup 2, Djupets tecken från djup 1) finns i skattkistor.
7. **Droppen** (*vårt val*, `gambits.json` "drops"): efter en vunnen strid kan högst ett villkor droppa. Varje oägt villkor
   som har ett hem bland de besegrade får ett slag, de sällsyntaste först: vanligt 25 %, elit 60 %, boss 100 %. Annars finns
   en chans på 3 % till ett vanligt villkor var som helst (först 40 % och 4 %; botarna gav då 10 villkor redan under
   den andra nedstigningen). En kista ger ett kistvillkor från djupet med 50 % chans, annars ett
   vanligt med 12 % chans. Övningsgården ger inga villkor.
8. **Avstängda rader** (`enabled: false` på raden): `MacroRunner.decide` hoppar över dem, och i en kedja bryter de kedjan.
   Förklaringsloggen skriver "Rad N är avstängd".
9. **Vad striden kör** (`Gambits.playable`, `Run.macro_for`): de första `slots` raderna, utan avstängda och utan rader med
   oägda villkor. En kedja tas med hel eller inte alls. Botarna använder samma funktion.
10. **Gamla profiler förlorar ingenting** (`Profile.setup_gambits`): en profil som sparades före gambits (`gambits` saknas i
    progress.cfg) äger allt som står i dess sparade makron. Den får också minst så många platser som det längsta makrot
    (`gambit_slot_floor`). Då äger VD:s profil med fulla makron i praktiken allt den använder.
11. **Ledtrådar i Biblioteket**: knappen VILLKOR visar alla villkor. Ägda står i guld, och oägda visas med ryktet:
    "Det sägs att Klockaren vet när en allierad faller."
12. **Fynd**: segerskärmen visar ett guldkort "NY GAMBIT" ovanför fynden, med ljud. Skattkammaren skriver "Ny gambit: …".
13. **Gambitsidan** (macro_screen): varje rad är ett stort kort, ungefär en sjättedel av höjden, med villkoret till vänster
    och handlingen till höger, en stor PÅ/AV-knapp och en nivåbricka. Håll kvar tummen (0,35 s) så lyfts kortet och kan dras.
    Telefonen vibrerar när kortet släpps (`Input.vibrate_handheld`). Radeditorn behåller sökfältet och grupperna. Oägda
    villkor står där som låsta med sitt rykte, och de går inte att välja. Sidan fungerar också inbäddad i striden.

## Balans

Se tabellen nedan, som botarna har skrivit. `BALANS=forsta` och `BALANS=grotta` kör med en ny profils villkor när
`GAMBITS=ny` är satt (startvillkoren och det sällskapet har lärt ut, inga droppar; det är det svåraste fallet).
`tests/gambit_drops.gd` mäter hur snabbt villkoren kommer.

Kört 2026-10-27, 100 körningar per rad, djup 1. *Före* = main (alla villkor ägda, inga platser). *Efter* =
`GAMBITS=ny`: startvillkoren och det sällskapet har lärt ut, platser efter nivån och inga droppar. Det är det svåraste
fallet, eftersom en riktig profil har hittat fler villkor efter några strider. MACRO = en ny profils makron och
makroförslagen.

### Första nedstigningen och små sällskap (`BALANS=forsta`, MACRO)

| Realm | Rad | Före | Efter |
|---|---|---|---|
| Kryptan | 0.25: ensam, Imma efter strid 1 (profilens första nedstigning) | 44 % | 44 % |
| Kryptan | första nedstigningen (trappa) | 46 % | 46 % |
| Kryptan | Paladinen + Imma, nivå 3 | 31 % | 31 % |
| Kryptan | + Imma + Brokk, nivå 3 | 51 % | 53 % |
| Kryptan | andra, nivå 3, en fånge | 33 % | 26 % |
| Kryptan | ny profil nivå 1, befriar fångar | 10 % | 7 % |
| Kapellet | 0.25: ensam, Imma efter strid 1 | 96 % | 96 % |
| Kapellet | första nedstigningen (trappa) | 96 % | 96 % |
| Kapellet | Paladinen + Imma, nivå 3 | 69 % | 69 % |
| Kapellet | + Imma + Brokk, nivå 3 | 49 % | 45 % |
| Kapellet | andra, nivå 3, en fånge | 41 % | 43 % |
| Kapellet | ny profil nivå 1, befriar fångar | 15 % | 16 % |

### Grottan, kryptan och kapellet (`BALANS=grotta`, MACRO)

| Realm | Rad | Före | Efter |
|---|---|---|---|
| Kryptan | första: ensam, Imma efter strid 1 | 44 % | 44 % |
| Kryptan | Paladinen + Imma, nivå 3 | 31 % | 31 % |
| Kryptan | 4 hjältar, *fulla* startmakron, nivå 3 | 6 % | 0 % |
| Kapellet | första: ensam, Imma efter strid 1 | 96 % | 96 % |
| Kapellet | Paladinen + Imma, nivå 3 | 69 % | 69 % |
| Kapellet | 4 hjältar, *fulla* startmakron, nivå 3 | 0 % | 0 % |

**Så ska tabellen läsas**

- **En ny profils väg ändras inte.** Profilens första nedstigning ligger på 44 % i kryptan och 96 % i kapellet, före och
  efter, eftersom Paladinens första rad och Immas rader bara använder startvillkoren och Immas Buff. Raderna med fångar
  ligger inom ±7 enheter, vilket är brus vid 100 körningar.
- **Målet "ungefär 80 %" nås inte ens före ändringen.** CLAUDE.md anger 91 % för kryptan, men main ger i dag 44 %, och det
  beror inte på gambits. Någon senare balansändring har sänkt kryptan, och det bör ses över för sig.
- **Raden "4 hjältar med fulla startmakron" är konstgjord.** Den kör de långa startmakrona i `data/macros.json`, där varannan
  rad behöver ett villkor en ny profil inte har. En ny profil får aldrig de makrona, eftersom `Run.starter_lines` ger två
  rader och reservanfallet. Raden visar ändå en verklig risk: en hjälte vars ägda rader slutar passa (Charges slut) väntar.
- **TUNED** (de förbättrade botmakrona) är skrivna med alla villkor och tolv rader. Med en ny profils villkor och tre
  platser står Paladinen ensam ibland stilla. Därför räknas bara MACRO. Den första körningen, där oägda rader tog platser,
  gav TUNED 0–3 % i "ensam".
- **Platsräkningen ändrades efter den första körningen** (beslut 5): oägda rader tar ingen plats, och en kedja tar en.
  Före den ändringen var MACRO-raderna desamma, men Alvas anfall hamnade utanför hennes tre platser.

### Hur snabbt villkoren kommer (`tests/gambit_drops.gd`, 40 karriärer, MACRO)

En ny profil: kryptan djup 1 ×2, kapellet, kryptan, kapellet, sedan djup 2 ×4 och kryptan djup 3. Bara funna villkor räknas,
inte de tre startvillkoren och inte det följeslagarna lär ut.

| Villkor funna | Vunna strider (median, 25–75 %) | Nedstigning (median) |
|---|---|---|
| 3 | 3 (2–4) | 1 |
| 6 | 8 (7–10) | 1 |
| 10 | 18 (15–20) | 3 |

| Efter nedstigning | 1 | 2 | 3 | 4 | 5 | 6 | 8 | 10 |
|---|---|---|---|---|---|---|---|---|
| Funna villkor (av 23) | 6,4 | 9,8 | 14,2 | 16,1 | 17,8 | 19,4 | 20,2 | 20,7 |
| Vunna strider | 9 | 18 | 27 | 36 | 46 | 55 | 72 | 88 |

Med 40 % och 4 % (det första förslaget) kom 10 villkor efter 14 strider och 18 efter fem nedstigningar. Det var för fort.
De sällsynta (Kedja, På sin tur …, Bär laddningen, Har väckts) hittas i 16–35 av 40 karriärer efter tio nedstigningar.

**Nackdelen:** 26 villkor räcker ungefär sex nedstigningar för en spelare som går ned ofta. Därefter finns bara de
sällsynta kvar att jaga. Fler villkor bör få hem i Lunden och Trollberget, och villkor som läser fiendernas avsikter
("tänker anfalla Paladinen") är förslagets egen styrka. Det är ett eget nästa steg.
