# Nivåer och Charges: glesare nivåer som känns, Charges från djupet (förslag)

2026-10-24, gren `forslag-nivaer` (från `test-0.30`). **Det här är ett förslag och inget är beslutat.** Spelet beter sig
som förut. Prototypkoden ligger bakom miljövariabeln `NIVAER` och används bara av botarna. **VAL** betyder vårt eget val
där Siralim är annorlunda eller okänt. **VD** betyder beslut som VD fattar.

Underlag: CLAUDE.md (Nivåer och personlighet, Lägereld, Helgedom, Charges), `src/game/hero_stats.gd`, `docs/formler.md`,
`docs/provspel/svarighetskurva.md`, `docs/provspel/provspel-0.30.14.md` (speltid), `docs/research/djupvaggen.md` §3.3,
`docs/research/siralim.md` §3, §3b, §14 och §18, `docs/plan/formagor-och-inskrifter.md` (Spell Gems och inskrifter) och
`docs/plan/beslutsblad.md` (Fö 1–6).

VD (2026-10-24): *"Det är inget roligt om man får en ny nivå var tionde minut – då betyder det ingenting."* Nivåer ska
vara ovanligare, kännas som en belöning och ta längre tid ju högre man kommer. En nivå kan ge mer liv och styrka eller
något helt annat. Fler Charges längre fram är välkommet, men de ska inte vara kopplade till nivåer och ska komma först
några djup ned. Ingen stor ombalansering nu.

## 0. Kort

- **I dag ser man en nivåhöjning var 8:e–13:e minut.** Paladinen tar ungefär 2 nivåer per nedstigning. Sällskapet tar
  7–9 nivåer per nedstigning, och 36–39 % av de vunna striderna slutar med att någon stiger i nivå på segerskärmen. Med
  3–5 minuter per strid är det just VD:s "var tionde minut". Under första nedstigningen gäller det 57 % av striderna.
- **Hur ofta nivåerna kommer är mest presentation.** Varje stat är bas × (1 + 0,3 · (nivå − 1)), och fienderna växer
  med samma formel. Vi kan därför byta ut nivåskalan, så att en ny nivå motsvarar två eller tre av dagens och ger
  motsvarande större hopp. Fiendernas nivå och erfarenhetskurvan räknas om på samma sätt. Då är striderna exakt lika
  starka, och bara antalet nivåer ändras. Botarna bekräftar det (§2.3).
- **Rekommendation: "kurva"** (variant C). Nivåerna glesnar ju högre man kommer: ungefär 6 strider per nivå på djup 1,
  17 på djup 2–3, 24 på djup 7 och 32 på djup 10. Varje nivå ger mer, +45 % på djup 1 och +16 % på djup 7 (i dag +3 %).
  Svårighetskurvan är densamma enligt botarna. Hälften av omräkningen är redan skriven bakom `NIVAER`.
- **En nivå ska visas i det den gör:** "Paladinens Rättfärdiga slag: 14 → 17 skada" på segerskärmen, inte "+0,9 Attack".
  Var tredje nivå får dessutom en titel och en replik (VAL). Ett val vid varje nivå avråder jag från, eftersom Siralim
  inte har något sådant (fråga 5).
- **Charges: ett enda system, och det är inskriften Förråd** (Siralims More Charges i Spell Gems-planen). Rullen hittas
  först från ett visst djup (förslag: djup 7), på samma sätt som Nether Stones bara hittas på det djupaste djupet.
  Charges ska inte komma från nivåer, Nether Stones, bärnsten eller nya perks. Lägerelden och Vila upp fyller på inom en
  körning och höjer inte taket, så de krockar inte. Om inskrifterna dröjer behövs inget i mellantiden, eftersom djup 7
  ligger utanför det de flesta spelare når i dag.

## 1. Takten i dag, mätt

### 1.1 Botarna (karriären, `test-0.30`)

`SOAK=karriar godot --headless --path . --script res://tests/soak.gd -- --runs=40 --descents=18`: 40 profiler × 18
nedstigningar, med samma bot som i `svarighetskurva.md`. På `test-0.30` roterar fyra Realms. Rapporten har fått ett nytt
avsnitt, **Nivåtakten**: Paladinens nivå, nivåer per nedstigning (Paladinen och alla hjältar), andelen vunna strider där
någon steg i nivå, och strider per Paladinens nivå.

| Nedstigning | Djup (snitt) | Paladinens nivå efter | Paladinens nivåer | Alla hjältars nivåer | Strider med nivåhöjning |
|---|---|---|---|---|---|
| 1 | 1,0 | 4,7 | 3,7 | 7,3 | **57 %** |
| 2 | 2,0 | 6,9 | 2,2 | 5,4 | 42 % |
| 3 | 2,5 | 9,8 | 3,0 | 7,5 | 40 % |
| 5 | 3,3 | 14,0 | 2,1 | 8,7 | 45 % |
| 8 | 4,8 | 20,7 | 2,4 | 7,1 | 33 % |
| 10 | 5,9 | 24,4 | 1,6 | 9,4 | 53 % |
| 13 | 6,8 | 30,2 | 1,5 | 8,7 | 39 % |
| 18 | 9,2 | 39,1 | 1,2 | 5,9 | 31 % |
| **2–18** | | | **2,0** | **~8** | **39 %** (andra fröna 36 %) |

Totalt blir det **4,3 vunna strider per Paladinens nivå** (4,6 med frö 41–80). Formeln ger 3 vanliga strider per nivå
på djup 1 och 6–7 på djup 4 och djupare. Botarna kommer lägre eftersom elitgrupper och bossar ger 1,5–3 gånger så mycket
erfarenhet. Skillnaden mellan Paladinens 2 nivåer och sällskapets 8 kommer av att fyra hjältar stiger var för sig, och
att ikapphämtningen (+50 % per nivå under snittet) gör att nya lärjungar stiger ofta. **Segerskärmen visar en nivåhöjning
så fort någon stiger**, så det är sällskapets takt spelaren ser, inte Paladinens.

### 1.2 Per speltimme

Ingen har mätt speltiden på riktigt än. Speltidsmätningen (`Playtime`, `user://playtime.cfg`) finns, men den har inga
data från VD:s telefon i det här underlaget. Två uppskattningar:

| Uppskattning | Tid per nedstigning | Paladinens nivåer per timme | Nivåhöjningar på segerskärmen per timme |
|---|---|---|---|
| Provspelet 0.30.14 (2–5 min per strid, ~10 strider) | 30–60 min | 2–4 | 8–16 (en var 4:e–8:e minut) |
| VD:s känsla (kortare pass) | 10–15 min | 8–12 | 30–50 |
| Räknat per strid (39 % × 3–5 min) | – | – | en var **8:e–13:e minut** |

Oavsett vilken uppskattning som stämmer ligger det i dag runt eller under VD:s gräns på tio minuter.

### 1.3 Varför takten är jämn

Erfarenheten per strid växer med djup² (17 × rumstyp × djup²), och kurvan till nästa nivå växer med L² (5 · L² + 10).
Eftersom fiendernas nivå växer med 5 per djup blir antalet strider per nivå nästan konstant (5–7) från djup 3. Det var
med flit (`djupvaggen.md` §3.3). Följden är att nivå 30 känns som nivå 5: lika ofta, och varje nivå ger mindre
(+30 % av basen är +23 % på nivå 2 men +3 % på nivå 30).

## 2. Insikten: nivåtakten är presentation

### 2.1 Varför

- Hjälten har stats = bas × (1 + 0,3 · (L − 1)), med personlighet 0,4 eller 0,2 i stället för 0,3.
- Fienden har stats × (1 + 0,3 · (E − 1)), där E = 5 · (djup − 1) + 2,25 + 1,5 per våning (`HeroStats.level_mult`).
- Inget annat i striden läser nivån.

Välj en avbildning g från den nya nivån L till "dagens nivå" g(L). Ge hjälten tillväxten 0,3 · (g(L) − 1), sätt
fiendens nivå till g⁻¹(E) och lägg kurvan till nästa nivå så att den samlade erfarenheten följer dagens kurva i g(L).
Då är varje strid exakt lika stark som i dag. Det enda som ändras är hur många nivåer spelaren ser, och hur stort varje
hopp är. Att halvera erfarenheten per strid ger samma effekt som att göra kurvan brantare. Jag har ändrat kurvan
eftersom erfarenheten per strid syns i fler texter.

Två saker gör att det inte blir exakt lika i praktiken:

1. **Hela nivåer.** Med färre och större steg ligger hjälten ibland längre efter sin erfarenhet. Om tröskeln låg vid
   g(L) föll första nedstigningen från 98 till **60 %** (k2). Lösningen är att nå den nya nivån mitt emellan
   (i erfarenhet) när dagens kurva skulle ha nått den första mellanliggande nivån och g(L) (`HeroStats._threshold_xp`).
2. **Första nedstigningen är ömtålig.** Den är finjusterad med en trappa (`FIRST_DESCENT_RAMP`, `FIRST_FIGHT_ALONE`)
   för en Paladin som tar 3,7 nivåer på tio strider. Med k3 utan särskild början blev den 70 %, och med de tre första
   nivåerna som i dag 75 %. Med **de fyra första nivåerna som i dag** (g(L) = L upp till nivå 5) är den 98 %, som förut.
   Varianten "kurva" behöver inget sådant (93 %), eftersom den redan är tät nere vid nivå 1–2.

### 2.2 Varianterna

| Variant | g(L) = dagens nivå | Kurvan till nästa nivå (L = 1, 2, …) |
|---|---|---|
| I dag | L | 15, 30, 55, 90, 135, 190, 255, 330 … (5 · L² + 10) |
| **A: k2s** (hälften så ofta) | L upp till 5, sedan 2L − 5 | 15, 30, 55, 90, 230, 515, 835, 1 235, 1 715, 2 275 … |
| **B: k3s** (en tredjedel) | L upp till 5, sedan 3L − 10 | 15, 30, 55, 90, 358, 1 015, 1 870, 2 995, 4 390 … |
| **C: kurva** (glesare uppåt) | 1 + 1,5 · (L − 1)^1,4 | 21, 106, 415, 1 148, 2 543, 4 853, 8 346, 13 301 … |
| **D: k2seg** (verkligt långsammare) | som A, och kurvan × (1 + 0,10 · (L − 6)) från nivå 7 | 15, 30, 55, 90, 230, 515, 919, 1 482, 2 230 … |

Fiendernas nivå blir g⁻¹(dagens nivå). Djup 1–2 är till exempel 2,25 / 3,75 / 5,25 och 7,25 / 8,75 / 10,25 i dag,
och ungefär 1,9 / 2,5 / 3,1 och 3,8 / 4,2 / 4,7 i C. Tabellen nedan visar den väntade nivån (mitt i djupet, dagens
3, 8, 13 …), hur många vanliga strider en nivå tar där (17 · djup² per strid) och hur mycket en nivå höjer alla stats.

**Nivå på djupet** (sällskapets väntade nivå):

| Djup | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| I dag | 3 | 8 | 13 | 18 | 23 | 28 | 33 | 38 | 43 | 48 |
| A k2s / D | 3 | 6,5 | 9 | 11,5 | 14 | 16,5 | 19 | 21,5 | 24 | 26,5 |
| B k3s | 3 | 6 | 7,7 | 9,3 | 11 | 12,7 | 14,3 | 16 | 17,7 | 19,3 |
| C kurva | 2,2 | 4,0 | 5,4 | 6,7 | 7,8 | 8,9 | 9,9 | 10,9 | 11,8 | 12,7 |

**Vanliga strider per nivå** (formeln, på väntad nivå):

| Djup | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| I dag | 3 | 5 | 6 | 6 | 6 | 6 | 7 | 7 | 7 | 7 |
| A k2s | 3 | 8 | 11 | 11 | 13 | 12 | 13 | 13 | 13 | 13 |
| B k3s | 3 | 15 | 12 | 16 | 19 | 17 | 19 | 20 | 18 | 20 |
| C kurva | 6 | 17 | 17 | 18 | 20 | 22 | 24 | 26 | 29 | 32 |
| D k2seg | 3 | 8 | 15 | 16 | 23 | 24 | 30 | 32 | 38 | 39 |

**Hur mycket en nivå ger** (alla stats, i procent av det man har):

| Djup | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| I dag | +23 | +11 | +7 | +5 | +4 | +3 | +3 | +3 | +2 | +2 |
| A k2s / D | +23 | +27 | +15 | +10 | +9 | +7 | +6 | +5 | +5 | +4 |
| B k3s | +23 | +41 | +22 | +18 | +13 | +11 | +10 | +8 | +7 | +6 |
| C kurva | +45 | +41 | +34 | +24 | +20 | +18 | +16 | +14 | +13 | +12 |

### 2.3 Botarna: samma svårighet?

Varje variant kördes med samma 40 frön och 18 nedstigningar. För att se hur mycket slumpen spelar in kördes dagens
spel också med frö 41–80.

| Variant | Ned 1 | Ned 2–6 | Ned 7–12 | Ned 13–18 | Djup efter 18 | Paladinens nivå efter 18 | Paladinens nivåer per ned (2–18) | Strider med nivåhöjning (2–18) | Strider per Paladinens nivå |
|---|---|---|---|---|---|---|---|---|---|
| I dag, frö 1–40 | 98 % | 55 % | 58 % | 55 % | 9,2 | 39,1 | 2,02 | 39 % | 4,3 |
| I dag, frö 41–80 | 100 % | 51 % | 55 % | 53 % | 8,4 | 37,3 | 1,91 | 36 % | 4,6 |
| A k2s | 98 % | 53 % | 57 % | 52 % | 8,4 | 21,0 | 0,96 | 22 % | 8,3 |
| B k3s | 98 % | 53 % | 56 % | 52 % | 8,2 | 15,3 | 0,62 | 16 % | 11,5 |
| C kurva | 93 % | 50 % | 60 % | 51 % | 8,4 | 10,6 | 0,46 | 12 % | 16,9 |
| D k2seg | 98 % | 47 % | 52 % | **42 %** | **6,9** | 16,2 | 0,68 | 18 % | 10,7 |
| (k2, k3 utan särskild början) | 83 / 70 % | 54 / 55 % | 57 / 56 % | 47 / 50 % | 8,1 / 8,2 | 18,6 / 12,9 | | | |

Vinst per djup över alla Realms, med antal körningar inom parentes:

| Djup | I dag | A k2s | B k3s | C kurva | D k2seg |
|---|---|---|---|---|---|
| 1 | 97 % (54) | 97 % (61) | 97 % (65) | 94 % (62) | 97 % (61) |
| 2 | 56 % (73) | 46 % (89) | 48 % (101) | 53 % (89) | 52 % (97) |
| 3 | 64 % (78) | 75 % (79) | 59 % (86) | 55 % (94) | 59 % (107) |
| 4 | 57 % (92) | 51 % (107) | 62 % (87) | 56 % (87) | 48 % (123) |
| 5 | 60 % (95) | 60 % (91) | 59 % (108) | 63 % (97) | 53 % (133) |
| 6 | 53 % (99) | 54 % (108) | 43 % (113) | 42 % (112) | **30 %** (125) |
| 7 | 55 % (80) | 38 % (96) | 45 % (77) | 60 % (71) | **23 %** (56) |
| 8 | 51 % (64) | 60 % (47) | 61 % (41) | 37 % (56) | 33 % (12) |
| Slipar (på ett redan klarat djup) | 81 av 720 | 101 | 104 | 96 | **128** |

**Slutsats.** A, B och C ligger inom slumpen från dagens spel. Mellan de två fröserierna skiljer det 0,8 djup efter 18
nedstigningar och 2–4 procentenheter i vinst. Antalet nivåer halveras (A), blir en tredjedel (B) eller en fjärdedel
uppåt (C), och vunna strider med en nivåhöjning sjunker från 39 % till 22, 16 och 12 %. Med C får man en nivåhöjning
ungefär var 25:e–40:e minut (12 % × 3–5 minuter). Paladinens egen nivå kommer var 17:e strid, alltså ungefär en gång per
två nedstigningar på djupet.

### 2.4 Variant D: när det verkligen blir långsammare

D följer A men gör varje nivå från nivå 7 10 % dyrare per nivå. Hjältarna halkar efter fiendernas kurva, och väggen
flyttas: djup 6 vinns 30 % och djup 7 23 % (i dag 53 % och 55 %). Efter 18 nedstigningar står sällskapet på djup 6,9
i stället för 8,4–9,2. Slipandet ökar med 60 % (128 mot 81 nedstigningar på ett redan klarat djup). VD:s önskan om
långsam belöning ger alltså en tydligare vägg vid djup 6–7. Det kan vara meningen (`svarighetskurva.md`: "makron och
byggen bär resten, som i Siralim"), men då är det en ombalansering och inte presentation. Startmakrona fastnar där, och
den som bygger med troféer och artefakter tar sig förbi. **Det rekommenderar jag inte nu**, eftersom VD inte vill ha
någon stor ombalansering. C ger samma känsla, att det tar längre tid och betyder mer, utan att flytta väggen.

### 2.5 Vad ett byte kostar (A–C)

- `HeroStats`: avbildningen finns i prototypen (`set_variant`, `old_level`, `new_level`, `_threshold_xp`). Den ska
  göras till spelets enda väg, utan grenar.
- **Gamla profiler** ska räknas om. En hjälte på nivå 24 med xp x får den nya nivå som har samma samlade erfarenhet,
  och resten blir xp. Ingen förlorar någon styrka.
- Ikapphämtningen räknar avståndet i dagens nivåer (finns i prototypen). Lärjungar som ansluter får nivå 2 när
  Paladinen motsvarar dagens nivå 4 (finns). Övningsgårdens och testernas väntade nivåer behöver ändras
  (`test_levels.gd`: väntad nivå 3 och 13).
- Texter: hjältebladets fiendenivå, förlusttipsen ("gå ett djup lägre"), segerskärmen. De läser redan `HeroStats`.
- **Siralim:** +30 % av basen per nivå är originalets (Codex). Varianterna avviker från det (**VAL**), men styrkan på
  ett givet djup blir densamma. Originalets nivåtakt är okänd i vårt underlag (`siralim.md` §14.1 säger bara att
  fienderna växer fortare än ens varelser och att svaret är traits).

## 3. Vad en nivå ska ge, så att den märks

Glesare nivåer räcker inte om nivån fortfarande visas som "+0,9 Attack". Förslag i den ordning jag rekommenderar dem:

1. **Visa hoppet i det striden gör** (VAL; Siralim visar bara stats). Segerskärmen säger "Brokk nivå 7: liv 152 → 178,
   Sköldslag 11 → 13 skada" och "Alva: Helande ljus 18 → 22". Talen kommer från `CombatSim.expected_damage` och
   `expected_heal`, som hjältebladet redan använder mot en typisk fiende på valt djup. Med C är hoppet +16–45 %, och
   det syns i siffrorna. Det här är den billigaste och viktigaste delen.
2. **En egen stund för nivån** (VAL). När det sker en gång per en eller två nedstigningar har det råd att ta tid: ett
   kort ljud (`forge_level` finns), hjältens porträtt och en replik från hjälten själv eller en kamrat ("Jag kände det
   i armen i dag, {namn}."). Det passar VD:s önskan om repliker som följer det som händer (`dialog.json`, id:n). Ingen
   ny skärm, bara en rad på segerskärmen.
3. **Var tredje nivå en edsgrad** (VAL, inte Siralim). Med C är det nivå 3, 6, 9 och 12, alltså ungefär djup 1, 4, 7 och
   10, samma rytm som väktarna (huvudbossen på djup 1, 4, 7). Graden ger en titel i hjältebladet och krönikan
   ("Edsvuren", "Prövad", "Härdad" …), och Gorm eller Alrik säger något när man kommer hem. Den ger inga nya
   siffror, så balansen rörs inte.
4. **Ett val vid nivån** (VAL, avviker från Siralim). Till exempel "lägg nivåns extra hopp på Attack eller Defense",
   som en tillfällig personlighet. Det gör nivån till ett beslut, men det krockar med personligheten (som redan styr
   tillväxten och byts i Biblioteket) och gör det svårare att jämföra byggen. **Jag avråder** och föreslår hellre att
   valet ligger där Siralim lägger det: troféer, artefakter och inskrifter.
5. Något "helt annat" (VD:s idé), till exempel en ny makrorad, en extra artefaktplats eller en perk-poäng. **Jag avråder
   från perk-poäng och Charges per nivå**, eftersom de redan kommer från quests och djup som i Siralim. En lättare form
   är att edsgraden låser upp en *kosmetisk* sak: en mantelfärg eller en fana i borgen.

## 4. Charges

### 4.1 I dag

- Varje förmåga har ett eget antal Charges: 3–8 (`abilities.json`, flest 5–6). De fylls vid varje ny körning
  (`RunState.fill_charges`).
- Lägereld: +3 per förmåga en gång per lägereld (`CAMPFIRE_CHARGES`), 1–2 per våning.
- Väktarens kall har perken *Vila upp* (Siralims Rest Up): +1 Charge efter Försvara. Buffen Arkan gör nästa cast gratis.
- Ingenting höjer taket permanent. Därför tar boss på våning 2 på djup 6–7 slut på Charges oftare
  (`djupvaggen.md` §3.2).

### 4.2 Siralim

- Charges sitter på varje Spell Gem och är fasta per spell (1–25, de starka 4–5). De fylls hemma eller vid nästa Realm.
  **De växer inte med varelsens nivå** (`siralim.md` §3b, §18). VD:s känsla att Charges inte ska följa nivåerna
  stämmer alltså med originalet.
- Sätt att få fler: gem-egenskapen **More Charges** (Agate), *Cascading* (starkare per saknad Charge), spellen
  *Recharge*, perken *Rest Up*, buffen *Arcane* och ethereal-kopior från *Generous*. Siralim 3.0 annonserar fler
  Charges per tier (T, inte belagt).
- Realm-egenskapen *Less Charges* finns som svårighet (`siralim_innehall.md`).

### 4.3 Alternativ för oss (inga kopplade till nivåer)

| # | Alternativ | Siralim? | Från djup | Fördel | Nackdel |
|---|---|---|---|---|---|
| a | **Inskriften Förråd** (+2, grad 4: +3 på en förmåga), med rullen bara från ett visst djup | Ja (More Charges) | 7 (VD) | Ingår redan i Spell Gems-planen (§4 nr 5), är ett val per förmåga och har ett tak | Väntar på inskrifterna. Planen kallar Förråd "vanlig", och det måste ändras till ett djupfynd |
| b | Djupbelöning: +1 Charge på alla förmågor efter klarat djup 7 (och 10) | Nej (VAL) | 7 | Enkelt, går att bygga i dag och känns som "djupet ger" | Inget val. Gäller alla förmågor lika, också helningarna (gamla tiders "oändliga helningar", VD-beslutet 2026-10-18) |
| c | Trick eller bärnsten i artefakten: "Förrådssten" | Nej | 7 | Använder smedjan | Smedjan har redan stats och trick. Charges hör till förmågan och inte till artefakten, som kastar gratis |
| d | Nether Stone-egenskap "+1 Charge" | Nej | det djupaste | Överraskning | Slumpad, så den kan bli ett måste att jaga. Krockar med (a) |
| e | Ny perk i kallen ("Förrådsmästare") | Delvis (Rest Up) | perk-poäng | Kallen bestämmer | Bara för ett kall. Perk-poängen mättas redan vid djup 4–5 (`djupvaggen.md`) |

### 4.4 Rekommendation: ett system

**(a), inskriften Förråd, som enda permanenta källa till fler Charges.** Den görs till ett djupfynd: rullen hittas bara
från djup 7 (förslag), som Nether Stones bara finns på det djupaste djupet (`Forge.FINDS`). Det stämmer med Siralim
(More Charges är en gem-egenskap), det ger ett val (vilken förmåga ska räcka längre?) och det har ett tak (+3).
Lägerelden och Vila upp ligger kvar. De fyller på inom en körning men höjer inte taket, så de är inte ett andra system.

Om VD vill ha något innan inskrifterna kommer är (b) det enda som går att bygga snabbt. Då ska det **ersättas** av
Förråd när inskrifterna kommer, inte läggas ovanpå. Annars får vi två system som gör samma sak. Eftersom bara de
starkaste spelarna når djup 7 i dag (botarna kommer dit efter ungefär 10–13 nedstigningar) brådskar det inte.

**Hur det hänger ihop med Spell Gems-beslutet** (beslutsblad Fö 1: inskrifter först). Förslaget kräver ingen ny
ordning. Det ändrar bara en rad i inskriftstabellen: Förråd blir ett djupfynd och inte vanligt. Om VD väljer valbara
förmågor först (M) i stället kommer Förråd senare, och då gäller frågan om (b) i mellantiden. Givmildhet (Generous) och
Eko ger också fler kast. De ska mätas tillsammans med Förråd i `BALANS=inskrifter` (planen §10 punkt 3).

## 5. Ärliga nackdelar

| Alternativ | Nackdel |
|---|---|
| A k2s | Färre nivåer, men fortfarande ungefär en Paladin-nivå per nedstigning. Uppåt kommer de inte långsammare, bara mer sällan. Kanske inte nog för VD |
| B k3s | Det andra steget (dagens nivå 5 → 8) är ett stort hopp på +41 %, och djup 2 kan kännas ojämnt. En nivå tar 15–20 strider redan från djup 2 |
| C kurva (rekommendation) | Formeln är svårare att förklara (`formler.md` får en tabell i stället för en rad). Första nedstigningen 93 % mot 98 % (inom slumpen men värd att följa). Väldigt höga nivåer finns inte: djup 10 är nivå 13, och den som vill se "nivå 50" får det aldrig |
| D k2seg | En ombalansering: väggen vid djup 6–7 blir tydligare och slipandet ökar med 60 % |
| Alla A–D | Gamla profiler räknas om, och en nivå 39 blir 11–21. Det kan kännas som en förlust även om styrkan är densamma. Det behöver en rad i krönikan ("Krönikan räknar nu edsgrader i stället för nivåer") |
| Visa hoppet i skada | Siffran gäller mot en typisk fiende och stämmer inte exakt mot en viss fiende. Det är samma förbehåll som i hjältebladet |
| Förråd från djup 7 | De flesta spelare får aldrig fler Charges. Om bossens Charges-brist vid djup 6–7 ska lösas måste startdjupet vara lägre (fråga 8) |

## 6. Prototypen (grenen `forslag-nivaer`)

- `HeroStats.set_variant("k2s" | "k3s" | "kurva" | "k2seg" | "k2" | "k3")`. Utan variant körs exakt dagens kod
  (alla 516 tester går igenom). Botarna läser miljövariabeln `NIVAER` i `tests/soak.gd` och `tests/balance_report.gd`.
- `Profile.catch_up` och `recruit` räknar i dagens nivåer när en variant är på.
- `SOAK=karriar` har fått avsnittet **Nivåtakten**.

```bash
SOAK=karriar NIVAER=kurva godot --headless --path . --script res://tests/soak.gd -- --runs=40 --descents=18
BALANS=grotta NIVAER=k2s godot --headless --path . --script res://tests/balance_report.gd
```

Begränsningar: 40 profiler per variant (slumpen ±0,8 djup, se §2.3), bara MACRO-boten med startmakron, inga löften och
ingen instabilitet. Speltiden är uppskattad och inte mätt. `kurva` kördes innan tröskeln fick sin slutliga form. De nya
trösklarna skiljer sig med högst 10 % i erfarenhet (nivå 2, sedan under 6 %), så resultatet bör stå sig, men det kan köras om.

## 7. Frågor till VD

1. **Takten:** räcker en Paladin-nivå ungefär varannan nedstigning på djupet och en nivåhöjning på segerskärmen var
   25:e–40:e minut (C)? Eller vill du ha ungefär en per nedstigning (A)?
2. **Glesare uppåt** (C, rekommendation) eller **jämnt glesare** (A/B)? C betyder att djup 10 är nivå 13 och att
   hjältarna aldrig når "nivå 50".
3. **Svårigheten ska stå still**, alltså inte D? Eller vill du att väggen vid djup 6–7 blir tydligare, så att byggen och
   slipande bär mer?
4. **Första nedstigningen:** ska de första 3–4 nivåerna komma tätt som i dag (en belöning i introt), som i A och B?
5. **Vad en nivå ger:** räcker större hopp visade i skada och helning, plus en replik (§3.1–2)? Eller vill du ha ett val
   vid nivån (§3.4), trots att Siralim inte har det?
6. **Edsgrader** var tredje nivå med titel och replik men utan siffror (§3.3): ja eller nej?
7. **Gamla profiler:** räkna om tyst, eller med en rad i krönikan och hos Broder Alrik?
8. **Charges:** bara inskriften Förråd som permanent källa (rekommendation)? Från vilket djup hittas rullen: 7 (min
   rekommendation), 6 (där bossen börjar ta slut på Charges) eller 10?
9. **I mellantiden:** ska vi bygga djupbelöningen +1 Charge efter klarat djup 7 (b) innan inskrifterna finns, med löftet
   att Förråd ersätter den? Min rekommendation är nej.
10. **Spell Gems:** står Fö 1 (inskrifter först)? Då ändras bara Förråds sällsynthet i planen från "vanlig" till
    "djupfynd".
