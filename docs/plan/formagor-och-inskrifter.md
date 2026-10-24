# Förmågor och inskrifter (design, grenen design-formagor, 2026-10-24)

Siralims Spell Gems, Spell Properties och Enchanter, anpassade till De edsvurna. Det här är ett förslag och inget är
beslutat. **VD** markerar beslut som VD ska fatta. **VAL** betyder vårt eget val där originalet är annorlunda eller okänt.
Underlag: `docs/research/siralim-luckor.md` (plats 1 i topp 10), `docs/research/siralim.md` §3, §3b och §18 (regler,
Charges, egenskapslistan, Rheas priser), CLAUDE.md, `data/abilities.json`, `data/heroes.json`, `src/game/forge.gd`,
`src/combat/combat_sim.gd`, `src/combat/macro_runner.gd`.

## 0. Kort

- Varje hjälte får **3 förmågeplatser**, som i Siralim. Hjältens egna förmågor sitter inte fast längre. Hen väljer bland
  sina egna och de **skolförmågor** hen har lärt sig.
- Förmågor får **inskrifter** (Siralims Spell Properties): 20 sorter, till exempel Hängivenhet (starkare per tom plats),
  Givmildhet (de andra får en kopia), Eko (chans att kasta en gång till) och Vaksamhet (kastas när man Försvarar).
- **Broder Alrik** (förslag) skriver in dem i biblioteket. Det kostar silver och en **inskriftsrulle**, som man hittar i
  grottan och som förstörs när inskriften tas bort. Det är originalets material.
- **Förlagor** (Siralims Inscriptions, alltså recepten) lär sällskapet nya skolförmågor. De finns i skatter, hos Realmens
  föremål och hos elitfiender.
- **Rekommenderad ordning (VD):** S = inskrifter på de förmågor hjältarna redan har, med en plats per förmåga. M = valbara
  förmågor och förlagor. L = grader, tre platser, skolbyte och kopior. Luckanalysen föreslog den omvända ordningen, men
  inskrifterna ger regelbrytare direkt utan nytt innehåll. Valet kräver nya förmågor för att betyda något (se §8).

## 1. Siralim, precist (det vi bygger på)

Det här är belagt i wikin och i §18 (B). Uppgifter som bara är troliga märks T.

| Regel | Siralim |
|---|---|
| Platser | 3 Spell Gems per varelse, aldrig två av samma spell, bara varelsens egen klass (Chaos, Death, Life, Nature, Sorcery). Traits, perks och egenskaper kan häva gränserna (Class Swap, Evokers Mastery, Pandora). Evokers *Expanded Mind* ger +1 plats per rank, upp till 8. |
| Charges | Varje gem har ett eget tal, från 1 (Recharge) till 25 (Magic Missile); de starka har 4–5. 1 cast kostar 1 Charge. Inget fylls på i Realmen. Allt fylls på hemma. Med 0 Charges går det varken att kasta manuellt eller automatiskt. |
| Tier | 1–15 hos Rhea. Tier gör inte spellen starkare (enligt wikin; spelets tutorial säger något annat, T). Tier 5, 10 och 15 öppnar en egenskapsplats var, och egenskapernas tal växer med tier. Verkstadens ranker (Projects) sätter taket på 5/10/15. |
| Egenskaper | ~22 sorter (lista i §18.4). Materialet avgör egenskapen, så inget är slumpat. Samma egenskap kan inte sitta två gånger på en gem. Olika "Cast After"-utlösare går att kombinera. Vissa egenskaper passar inte vissa gems (rött i menyn). |
| Material | En ädelsten per egenskap. I 2.0 köps de för 1 Emblem styck i gudarnas butiker (från Favor 4, T) eller fås från Experiment-uppdrag. Förr var de vanligt byte. |
| Rhea | Craft, Upgrade, Enchant och Disenchant, allt för Crystal. Disenchant tar bort egenskapen, och materialet går förlorat. Priser (T): tillverka 2 000, tier 1→15 ungefär 16 000, förtrolla 1 000 + material. |
| Recept | Inscriptions: från kistor och inskriptionsobelisker i Realms, från gudarnas butiker och senare från False Gods. De förbrukas aldrig. Varje Specialization börjar med ett eget recept. |
| Ethereal | Tillfälliga gems i striden (från Generous och vissa traits) med få Charges och inga egenskaper. De försvinner efter striden. |
| Artefakt | En gem i artefaktens spell-plats tappar sin tier och sina egenskaper. |
| Makron | "Cast <spell> on <mål>". Makrocasting räknas som manuell. Ett villkor "har Charges kvar" finns troligen inte (T; vi har det). |

**Spelarnas omdöme.** Det som gör systemet roligt är regelbrytarna (Singular, Generous, Cascading, potency från Defense
för en tank som kastar) och att gems matchas mot artefaktens utlösare. Det som gör det tråkigt (Steam och den japanska
wikin) är materialbristen: ädelstenarna finns i princip bara i gudarnas butiker, och nybörjare har för få. Det är dyrt
att tier-uppgradera en gem man sedan inte vill ha ("25K per gem, se till att det är rätt gem"). Det är svårt att hitta
rätt spell i makroeditorns lista. Och att pröva ett nytt lag kostar för mycket (§8b punkt 8 och 13). Därför: billiga
grader i början, vanliga rullar till salu, och samma sökfält som i makroeditorn.

## 2. Hos oss i dag

- 120 förmågor i `abilities.json`. 32 av dem är hjältarnas, 2–3 per hjälte i `heroes.json` `abilities`. Resten är
  fienders och grundhandlingar.
- Fältet `school` finns på 46 förmågor (holy 11, fire 8, nature 7, shadow 19, physical 1) men styr ingenting. Hjältarna
  saknar skola.
- Charges per förmåga och körning (`charges` 3–8, Siralims skala efter §3b). Lägerelden ger +3 per förmåga en gång
  (`CAMPFIRE_CHARGES`). Arkan gör nästa cast gratis.
- Artefakten kastar *vilken som helst* av sällskapets förmågor (`smith_screen._abilities`, `CombatSim.equip_artifact`,
  effekten `cast` i en genererad egenskap). Det är redan ett frö till fria förmågor.
- Makron namnger förmågan (`{action: "ability", ability: id}`), och villkoret `has_charges` finns.
- Forge är förebilden för platser, nivåer och material: `LEVEL_COST`, platser som öppnas på vissa nivåer, `FINDS` per
  rumstyp, bärnsten som förstörs och Nether Stones som går tillbaka.
- Ordet **Lärdom** är redan upptaget (troféns kursiva rad, ordlistan 2026-10-23). Det får inte användas för förmågor.

## 3. Platser och vilka förmågor en hjälte får lära sig

### 3.1 Platser

- **3 platser per hjälte** (Siralim). Paladinen, Brokk, Eira och Solveig har i dag bara 2 förmågor och alltså en tom plats,
  vilket redan i S ger Hängivenhet något att räkna på.
- I M blir alla tre platserna fria, som i Siralim. **VD:** ska en av hjältens egna förmågor vara låst ("signaturen")?
  Jag rekommenderar nej. Identiteten bevaras av poolen (3.2), inte av ett lås, och en låst plats gör Hängivenhet och
  byten mindre intressanta.
- En förmåga kan läggas undan ("vila"). Då blir platsen tom, med samma knapp som byter.
- En fjärde plats kan senare bli en perk (Siralims Expanded Mind), förslagsvis i ett framtida kall som Warden. Den ska
  inte ligga i grunden.

### 3.2 Skolor (Siralims klasser, ANPASSAT)

Fem skolor för spelarsidan, aldrig Death eller Chaos (tonregeln). Fiendernas `shadow` förblir deras.

| Skola | Fält | Hjältar (förslag) | Förmågor som finns i dag |
|---|---|---|---|
| Ljus | `holy` | Paladinen, Alva, Ragnhild | Rättfärdigt slag, Helig sköld, Helande ljus, Förnyelse, Ljusets dom, Brännmärke, Skingra lögnen, Ljusvåg |
| Stål | `steel` | Paladinen (andra skola, VD), Brokk, Imma, Sefir | Stenmur, Krigsrop, Dansande stål, Tusen snitt, Trickpil, Rökpil |
| Glöd | `fire` | Solveig | Eldvåg, Eldklot, Gnistpil |
| Mark | `nature` | Hulda, Eira, Ronja | Snärjande rötter, Lövskydd, Svampring, Märk byte, Pilregn, (falkens tre) |
| Ord | `word` (sång, andning, list) | Lirien, Tove | Stridssång, Vaggvisa, Hjältens ballad, Vindsteg, Tryckpunkt, Stilla vatten, Vindens steg |

- En hjälte har **en skola** (Siralim). **VD:** ska Paladinen som ledare ha två (Ljus och Stål)? Jag rekommenderar ja,
  så att Paladinen alltid har något att välja mellan från början.
- **Egna förmågor** (`"own": true`) kan bara hjälten själv bära, oavsett skola: Ronjas falk, Liriens sånger, Immas pilar.
  Det är för att det ska låta rimligt: Brokk sjunger inte Vaggvisa. Övriga förmågor i en skola kan alla i skolan lära sig.
- Antal i M: varje skola behöver **minst 4 delbara förmågor**. Glöd och Ord är tunna i dag och behöver 2–3 nya var (§8).

### 3.3 Hur man lär sig (Förlagor = Siralims Inscriptions)

En **förlaga** är en avskrift av en teknik eller bön, ett recept som aldrig förbrukas. När den har hittats kan alla i
skolan lära sig förmågan hos Broder Alrik.

- **Var:** skatter (bevakade oftare), Realmens föremål (en ny "Minnestavla" i kryptan och en "Mässbok" i kapellet,
  `objects.json`), helgedomens gåva, och questens belöning första gången en Realm och ett djup klaras.
- **Från fiender? (VD).** Elitfiender och miniboss som slåss med en teknik utan ockult innehåll (Lansens anstormning,
  Förmannens livvakt, Kolossens vakt) kan släppa en **motteknik** första gången de besegras: "Lansbrytning" för Stål,
  "Klockans tystnad" för Ord. Ingen förmåga tas direkt från en fiende som tillhör mörkret. Troféerna ger redan fiendens
  egenskaper, så det här är ett tillägg och inget krav. Jag rekommenderar det i L, med högst en per Realm.
- **Biblioteket** visar förlagorna som rykten, på samma sätt som kryptans troféer (Alrik: "Det sägs att en mässbok i
  kapellet beskriver Ljusvåg").
- Varje kall börjar med en förlaga (Siralim: varje Specialization har ett eget recept). Domens kall har Brännmärke,
  Gryningens kall Förnyelse och Väktarens kall Stenmur. Det räcker för att det första bytet ska gå att göra direkt.

## 4. Inskrifterna (Spell Properties)

Talen är i vår skala: `power` 1,0–1,6, Charges 3–8, `TURN_LIMIT` 5 per sort och tur, `REDUCTION_CAP`. "Grad" är förmågans
nivå hos Alrik (§5). Talen anges på grad 1 → grad 6 (+10 % per grad, som `Forge.level_mult`). Alla gäller bara den
förmåga de sitter på. Samma inskrift kan inte sitta två gånger på samma förmåga (Siralim), men de fyra Efter-inskrifterna
(nr 11–14) räknas som olika.

| # | Inskrift | Siralim | Effekt (grad 1 → 6) | Sällsynthet | Motor |
|---|---|---|---|---|---|
| 1 | **Skärpa** | Damage Increased | +15 → 22 % skada | vanlig | `modify_damage` med förmågefilter |
| 2 | **Barmhärtighet** | Healing Increased | +15 → 22 % helning | vanlig | `modify_heal` med förmågefilter |
| 3 | **Varaktighet** | Duration Increased | statusar från förmågan +1 tur (grad 6: +2) | vanlig | `duration` + n |
| 4 | **Eftertryck** | Stat +/- Increased | stat-ändringar och auraeffekter +25 → 37 % | vanlig | multiplikator på aurans tal |
| 5 | **Förråd** | More Charges | +2 Charges (grad 4: +3) | vanlig | `full_charges` + n |
| 6 | **Genomslag** | Defense Penetration | ignorerar 15 → 22 % av målets Defense | vanlig | `ignore_defense` finns |
| 7 | **Spridning** | Casts On Extra Target | träffar också en slumpad annan fiende eller allierad för 60 → 90 % (VAL: Siralim ger full styrka, men vi har färre mål) | sällsynt | nytt i `act` |
| 8 | **Uthållighet** | Cascading | +5 → 7,5 % styrka per saknad Charge | sällsynt | ny multiplikator |
| 9 | **Hängivenhet** | Singular | +40 → 60 % styrka per tom förmågeplats hos kastaren (VAL: Siralim 50 % i 2.0) | sällsynt | ny multiplikator |
| 10 | **Samklang** | Magnetic | +10 → 15 % per annan levande hjälte i sällskapet med en förmåga i samma skola (VAL: Siralim räknar likadana gems) | sällsynt | ny multiplikator |
| 11 | **Stridsvana** | Chance to Cast After Attack | 15 → 22 % chans att kastas gratis efter Anfall | ovanlig | genererad egenskap `acted` + `cast` (som artefakten) |
| 12 | **Vaksamhet** | … After Defend | 25 → 37 % efter Försvara | ovanlig | samma |
| 13 | **Trots** | … After Provoke | 25 → 37 % efter Provocera | ovanlig | samma |
| 14 | **Omsorg** | … After Heal Other | 20 → 30 % efter en helning på en annan | ovanlig | samma, `heal` |
| 15 | **Eko** | Chance to Cast Twice | 15 → 22 % chans att kastas en gång till. Den andra kostar ingen Charge (VD; i Siralim kan den kosta) | sällsynt | `cast` efter handlingen |
| 16 | **Följdslag** | Chance to Attack | 30 → 45 % chans att anfalla en slumpad fiende efter | ovanlig | ny effekt `act` |
| 17 | **Garde** | Chance to Defend | 30 → 45 % chans att Försvara efter | ovanlig | `act` |
| 18 | **Utmaning** | Chance to Provoke | 30 → 45 % chans att Provocera efter | ovanlig | `act` |
| 19 | **Armkraft / Sköldtro / Livskraft / Snabbhet** | Potency Based On Attack / Defense / Health / Speed | 35 → 50 % av styrkan räknas från en annan stat i stället för Intelligence (Health ×0,1 för att passa skalan) | ovanlig | ny i `spell_damage` och helning |
| 20 | **Givmildhet** | Generous | i början av striden får de andra i sällskapet en tillfällig kopia med 1 Charge (grad 6: 2) | sällsynt | nytt: tillfälliga Charges |
| 21 | **Översättning** | Class Swap | förmågan byter skola till kastarens, så att en hjälte i en annan skola kan bära den. Bara i L | sällsynt | kontroll vid utrustning |
| 22 | **Morgonbön** (VAL, eget) | – | kastas av sig själv i första turen, en gång per strid, och kostar 1 Charge | sällsynt | `battle_start` + `cast` |
| 23 | **Sista utväg** (VAL, eget) | – | kostar ingen Charge när kastaren har under 30 % liv | ovanlig | villkor i `act` |

**Tonen.** Namnen beskriver hantverk (Skärpa, Genomslag, Förråd), dygd och tro (Barmhärtighet, Hängivenhet, Omsorg,
Morgonbön) och kunskap (Översättning, Eftertryck). Inget i listan är ett avtal med något, och ingen rulle "binder" en kraft.
En inskrift är en rad i marginalen, skriven med omsorg.

**Regelbrytarna** (det ledstjärnan frågar efter): Hängivenhet (bär en enda förmåga och gör den enorm), Givmildhet (Alvas
Helande ljus hos alla), Uthållighet (spara inget), Samklang (ett helt Ljus-sällskap), Sköldtro (Brokk kastar med sin
Defense), Vaksamhet och Trots (en tank som kastar medan den försvarar) och Översättning. De övriga är pålitliga byggdelar,
som vanliga troféer.

**Utesluts:** Siralims Booze, Prism och Arsenal (spellsorter, inte egenskaper). Gemmens klasser byts mot våra skolor.

**Passar inte alla:** helningsinskrifter bara på förmågor som helar, Spridning bara på förmågor med ett enda mål,
Genomslag bara på skada, och så vidare. De visas utgråade med en orsak (Siralims röda), till exempel "Rökpil gör ingen
skada".

## 5. Var de hittas, och hos vem de skrivs in

### 5.1 Inskriftsrullar (materialet)

En rulle är inskriften som föremål. Den förbrukas när den skrivs in och förstörs när den tas bort (Siralim). Fynden följer
`Forge.FINDS`-mönstret och visas på segerskärmen med vad de gör (`find_effect`).

| Rumstyp | Vanlig | Ovanlig | Sällsynt |
|---|---|---|---|
| strid | 0 | 0 | 0 |
| elitgrupp | 35 % | 15 % | 3 % |
| skatt (bevakad ×1,5) | 40 % | 20 % | 5 % |
| boss | 100 % | 60 % | 25 % |
| questens belöning | – | 100 % | – |

- Ovanliga och sällsynta finns bara på det **djupaste djupet** man nått, som trick och Nether Stones. Lägre djup ger bara
  vanliga rullar, vilket gör det meningsfullt att gå tillbaka och träna.
- **Instabilitet** ger +25 % chans per nivå på ovanliga och sällsynta rullar. Från instabilitet 2 kan en sällsynt rulle
  också hittas i en vanlig skatt.
- **Djup** ger +5 procentenheter per djup över 1 på alla.
- **Alrik säljer vanliga rullar** han har sett (alltså någon gång hittat) för 25 silver. Det är VAL, mot Siralims
  materialbrist, som spelarna klagar på. Ovanliga och sällsynta säljs aldrig.

### 5.2 Hos vem (VD)

- **Rekommendation: Broder Alrik i biblioteket.** Han är kunskapens och trons person, förklarar redan troféerna och har
  handboken. Ett nytt val i hans samtal: "Skriv i en förmåga". Ingen ny person behövs i borgen.
- **Alternativ:** en ny skrivare i ett skrivarrum vid biblioteket, med en egen station i `keep.json` (Siralims Rhea står
  bredvid Smeden). 0.18 planerade "Runristaren". Runor är hos oss skrift och inte magi, men en skrivare eller
  kopist (Syster Ingrid, förslag) är tydligare för tonen.
- **Introt (VD):** Siralim skickar spelaren till Rhea direkt efter Smeden. Vi har redan ett långt intro. Jag föreslår att
  det första fyndet av en rulle ger uppdraget "Visa rullen för Broder Alrik", som `find_quest` hos Hedda. Han skriver in
  den gratis på en förmåga man väljer och förklarar platserna i en hjälpruta.

### 5.3 Grader och kostnad

Siralims tier 1–15 med platser på 5/10/15 kortas till **grad 1–6** med platser på **2, 4 och 6** (VAL; artefakterna
har 1–10). Graden höjer inskrifternas tal med 10 % per steg men inte förmågans egen styrka (wikins regel).

| | Kostnad (silver) |
|---|---|
| Grad 2 / 3 / 4 / 5 / 6 | 40 / 60 / 90 / 130 / 180 (totalt 500 per förmåga) |
| Skriva in en inskrift | 30 + rullen |
| Ta bort en inskrift | gratis, rullen förstörs (Siralim) |
| Lära en hjälte en förmåga ur en förlaga | 50 (första gången per hjälte och förmåga) |
| Byta förmåga på en plats | gratis, i Förberedelser och vid en lägereld (som troféerna) |

**Graden följer förmågan hos hjälten** (inte en sten man kan flytta), så att det inte straffar sig att pröva en ny
förmåga. Den nya börjar på grad 1, men den gamla behåller sin grad och sina inskrifter när den läggs undan. **VD:** ska
graden i stället höra till förmågan för hela sällskapet (en Helande ljus på grad 4, vem som än bär den)? Det är närmare
Siralims gem. Rekommendation: per förmåga och sällskap, eftersom det gör byten mellan hjältar billiga, vilket är testet i
ledstjärnan. Det kräver en regel: samma förmåga får bäras av två hjältar samtidigt, men inskrifterna följer med bara en
av dem (som troféerna, `worn`).

Talen ska mätas mot silver per körning (`BALANS=artefakter` skriver ut det). Målet är att en hjälte har en förmåga på
grad 2 med en inskrift efter 2–3 nedstigningar.

## 6. Hur det samspelar

### 6.1 Charges

- Charges per förmåga och körning som i dag. När man byter förmåga mitt i en körning (vid en lägereld) kommer den nya
  in med **hälften** av sina Charges (VAL), så att byten inte blir ett sätt att fylla på.
- Förråd höjer taket. Uthållighet belönar att man spenderar. Sista utväg sparar Charges i nöd.
- Givmildhetens kopior har egna Charges per strid och rör inte körningens (Siralims ethereal gems).
- Eko, Stridsvana och de andra Efter-kasten är automatiska och gratis, som artefaktens kast. De räknas mot `TURN_LIMIT`
  och `TURN_PROC_LIMIT`. Med 0 Charges på förmågan blir det inget automatiskt kast (Siralim).
- **Risk:** Förråd + lägereld + Givmildhet kan återskapa gamla tiders "oändliga helningar" (§3b, VD:ns beslut 2026-10-18).
  Därför: Förråd högst +3, Givmildhet bara 1–2 per strid, och botarna mäter hur många Charges som är kvar i slutet av
  körningen.

### 6.2 Makron

- Raderna namnger förmågan som i dag. Om hjälten inte bär förmågan hoppas raden över med en ny orsak,
  `not_equipped`: "rad 3: Brokk bär inte Krigsrop" i förklaringsloggen.
- När man byter förmåga i Förberedelser frågar spelet: "Byt Krigsrop mot Lansbrytning i Brokks makro (2 rader)?" Ett
  tryck räcker. Utan frågan går makrot sönder i det tysta, och det är den vanligaste friktionen i Siralim.
- Radeditorn visar de burna förmågorna först och de lärda men undanlagda utgråade (sökfältet från 0.30.24 täcker dem).
- Givmildhetens kopior: en ny handling, **"Kopia: <förmåga>"**, eller att raden "Förmåga: Helande ljus" gäller också en
  kopia. **VD.** Rekommendation: den senare. Då fungerar Alvas helningsrader hos Brokk direkt om han har en sådan rad,
  och `macro_hint` kan föreslå den när kopian finns.
- Nya villkor (L): "förmågan har inskriften X" behövs inte. "Har en kopia" kan behövas.
- Spara som order (0.30) fortsätter att fungera, eftersom den skriver förmågans id.

### 6.3 Artefakter

- Artefakten kastar förmågan **utan grad och inskrifter** (Siralim: en gem i artefaktens plats tappar dem). Det håller
  artefaktens slumpkast och inskrifternas Efter-kast isär och förhindrar dubbla kedjor.
- I M väljer artefakten bland förmågor sällskapet *känner till* (förlagor och egna), inte bara de burna. Det är en
  liten skillnad mot i dag och gör förlagor värdefulla även för den som inte kan bära dem.
- **Kombinationen att mäta:** stav (kast vid Förmåga, 25 %) + Eko + Stridsvana ger tre vägar till extra kast från en
  handling. Taken finns redan (`TURN_LIMIT`, kedjor högst 4 steg), men det är den första stället där en loop kan uppstå.

### 6.4 Troféer och kall

- Egenskaper som kastar en förmåga (effekten `cast`) använder hjältens **burna version med inskrifter** om hen bär
  förmågan, annars grundformen. **VD**, eftersom det är okänt i Siralim (T: Siralim använder gemmens egenskaper vid
  automatiska kast från traits).
- Troféer som bryr sig om "använde en förmåga" (Arkan, förmågeräknare, Ragnhilds Sanningens ljus) samverkar med Eko och
  Efter-kasten. Det är meningen.
- Kallen kan få perks som rör förmågor (L, VD): Gryningens kall "Lärd tro" (+1 plats), Domens kall "Domens ord"
  (Hängivenhet räknar också undanlagda förmågor som tomma platser) och Väktarens kall "Vaksam ed" (Vaksamhet +10
  procentenheter för hela sällskapet).
- **Det här avgjorde striden** får källan INSKRIFT, med skada eller helning per inskrift (`trait_stats` per genererad
  egenskap). Skadeloggen visar inskriften i uträkningen (`calc.inscription`). `docs/formler.md` och
  `tests/numbers_reference.gd` behöver de nya multiplikatorerna.

### 6.5 Löften

"Jag helar inte" utesluter redan helningsförmågor. Med valbara förmågor blir löftet lättare att hålla (man väljer bort
helningarna). Löftets belöning bör mätas igen i M.

## 7. Telefonen (1280×720 och 1560×720)

- **Förberedelser:** varje hjältekort får tre små förmågechips under trofén. Ett tryck öppnar en lista med hjältens pool,
  högst ~10 rader med ikon, Charges, grad och inskriftsprickar, plus "Vila". Inget nytt skärmlager behövs.
- **Alriks skärm:** byggs som Smedens, med flikarna FÖRMÅGOR (grad och platser), INSKRIFTER (rullarna med sökfält) och
  FÖRLAGOR (lära hjältar). Platserna ritas som Smedens.
- **Striden:** handlingsknappen får 0–3 små prickar för inskrifterna. Tryck och håll visar texten, som Inspect.
  Givmildhetens kopior får en egen knapp med en tunn ram. Om knappraden blir för lång (3 egna + kopior) visas kopiorna i
  en undermeny "Gåvor".
- Text minst 15 px (`UiStyle.MIN_SIZE`). Inskrifternas namn är högst 12 tecken, så att de får plats på ett chip.
- Hjälprutor första gången: "förmågor" (platser och skolor), "inskrifter" och "förlagor". Alla tre läggs i handboken.

## 8. Versioner

### S: inskrifter på dagens förmågor (en version)

- Inga nya förmågor och inga skolor. Varje förmåga hos en hjälte får **1 inskriftsplats** (ingen grad).
- **8 inskrifter:** Skärpa, Barmhärtighet, Förråd, Varaktighet, Vaksamhet, Eko, Hängivenhet och Sköldtro. De sex första är
  byggdelar, Hängivenhet och Sköldtro regelbrytare. Hängivenhet fungerar redan, eftersom fyra hjältar har en tom plats och
  "Vila" en förmåga är en knapp.
- Rullar i elitgrupper, skatter och hos bossen enligt §5.1. Alrik skriver in för 30 silver och säljer vanliga rullar.
- Uppdraget "Visa rullen för Broder Alrik".
- Artefakten ignorerar inskrifterna. Makrona påverkas bara av "Vila" (`not_equipped`).
- Motor: `data/inscriptions.json`, `Profile.inscriptions` ({hjälte: {förmåga: [id]}}), `Profile.rested`,
  `CombatSim.create` tar emot dem och bygger genererade egenskaper och multiplikatorer (som `equip_artifact`), och
  `RunState.fill_charges` räknar Förråd.
- Mätpunkt: byter spelaren frivilligt en inskrift efter att ha sett vad Hängivenhet gör med Eldklot?

### M: valbara förmågor och förlagor

- Skolorna, `own`, 3 fria platser, förlagor i grottan och hos kallen, 2–3 nya förmågor i Glöd och Ord och 1–2 i Stål och
  Mark. Mer än 8 nya bör det inte bli, och animationerna återanvänder `cue` och vapen.
- Byten i Förberedelser och vid lägerelden, och makrofrågan vid byte. Givmildhet och Samklang läggs till här, eftersom
  de behöver valet.

### L: hela systemet

- Grader 1–6 med platser på 2/4/6, alla 23 inskrifter, Översättning, mottekniker från elitfiender, kallens perks, en
  egen skrivare (om VD vill) och ett Siralim-liknande tak för verkstaden genom Projects.

## 9. Risker

| Risk | Vad vi gör |
|---|---|
| **Balans:** Hängivenhet + en massive spell (Eldklot 1,4 × 1,8 med två tomma platser) | Börja på 40 % (inte Siralims 50 %), mät, och låt den inte gälla automatiska kast (VAL) |
| **Balans:** Givmildhet + helning tar bort Charges-gränsen från 0.18 | 1 Charge per kopia, bara på grad 6 två; botarna mäter Charges som är kvar |
| **Loopar:** Eko + Efter-kast + stav + troféer som kastar | Taken finns; `TURN_PROC_LIMIT`-träffar räknas i bot-rapporten |
| **Identitet:** alla hjältar bär samma tre bästa förmågor | Skolor och `own`; inga förmågor som är bäst överallt; Samklang belönar skola, inte en enda förmåga |
| **Grind:** materialbrist som i Siralim | Vanliga rullar till salu, rullar på lägre djup, billiga grader |
| **UI:** knappraden och listorna blir för långa på telefonen | Prickar i stället för text, undermenyn "Gåvor", sökfält |
| **Makron går sönder** vid byte | Frågan "byt i makrot", orsaken `not_equipped` i loggen |
| **Spara:** äldre profiler | Migrering: burna = dagens `abilities`, inga inskrifter; körningar som pågår fortsätter med dagens förmågor |
| **Ny spelare:** för mycket på en gång | Inskrifter först efter introt (det första rullfyndet), förlagor först efter den första bossen (VD) |
| **Innehåll:** nya förmågor kostar animationer och ljud | Högst 8 nya i M; återanvänd `cue`, `sound` och procedurella animationer |

## 10. Vad botarna behöver mäta

En ny rapport, `BALANS=inskrifter` i `tests/balance_report.gd` (eller `tests/inscription_report.gd` efter `perk_report.gd`):

1. **Varje inskrift för sig** på varje förmåga den passar, med startmakron och TUNED, kryptan och kapellet på djup 1 och
   3, 100 körningar. Vinst och skillnad mot utan. Målet är att ingen inskrift ger över +15 procentenheter på egen hand
   och att varje inskrift är bäst någonstans.
2. **Hängivenhet:** med 0, 1 och 2 tomma platser. Den bästa förmågan att bära ensam.
3. **Givmildhet och Förråd:** Charges kvar vid körningens slut och helningar per strid jämfört med i dag.
4. **Kedjor:** hur många gånger `TURN_PROC_LIMIT` och `TURN_LIMIT` slår i, och stridens längd (Utmattning från tur 100).
   Stav + Eko + Stridsvana särskilt.
5. **Grader:** grad 1, 3 och 6 för de fem bästa kombinationerna. Silver som behövs mot silver per körning.
6. **M:** de bästa tre förmågorna per hjälte enligt botarna (`TUNED` väljer). Om samma tre vinner för alla i en skola är
   poolen för smal.
7. **Makron:** att TUNED-makrona hoppar över förmågor som inte bärs utan att stanna (`not_equipped`). Botarna behöver
   kunna välja platser, alltså en enkel valfunktion: "bär de tre med högst förväntad nytta enligt
   `CombatSim.expected_damage`".
8. **Granskningen:** `tests/numbers_audit_report.gd` med de nya multiplikatorerna i `numbers_reference.gd`.

## 11. VD-beslut, samlade

1. **Ordningen:** inskrifter först (S) eller valbara förmågor först, som luckanalysen föreslog. Rekommendation: inskrifter först.
2. **Namnen:** "inskrift" = Siralims Spell Property, och "förlaga" = Siralims Inscription (receptet). Det avviker från
   originalets ord och ska stå i ordlistan. "Lärdom" är upptaget.
3. **Vem:** Broder Alrik (rekommendation) eller en ny skrivare.
4. **Platserna:** 3 fria eller en låst signatur. Rekommendation: 3 fria.
5. **Skolor:** fem (Ljus, Stål, Glöd, Mark, Ord). Ska Paladinen ha två?
6. **Mottekniker från elitfiender:** ja i L, eller nej.
7. **Grader:** 1–6, och per förmåga och sällskap eller per hjälte. Valutan: silver (rekommendation) eller ett eget bläck.
8. **Ta bort:** rullen förstörs (Siralim) eller kommer tillbaka.
9. **Eko:** den andra casten gratis (rekommendation) eller för en Charge, som ibland i Siralim.
10. **Automatiska kast från troféer** med eller utan inskrifter.
11. **När det öppnas:** det första rullfyndet efter introt, och förlagor efter den första bossen.
12. **Givmildhetens kopior i makron:** samma rad som förmågan, eller en egen handling.

## Källor

- [Spell Gems, siralimultimate.wiki.gg](https://siralimultimate.wiki.gg/wiki/Spell_Gems) (läst 2026-10-24): platser,
  klassregel, Charges, tier 1–15 med platser på 5/10/15, material, recept och ethereal. Sidan anger inga priser och inga
  fynd per djup.
- [Enchant, wikiwiki.jp](https://wikiwiki.jp/siralim_ult/Enchant): materialen köps i princip bara för Emblems, och
  nybörjare har för få.
- Steam-trådar om gems och artefakter:
  [3189112650410207583](https://steamcommunity.com/app/1289810/discussions/0/3189112650410207583),
  [3782498683137387206](https://steamcommunity.com/app/1289810/discussions/0/3782498683137387206),
  [4039231510646693069](https://steamcommunity.com/app/1289810/discussions/0/4039231510646693069): välj gems efter
  artefaktens utlösare, Generous för särskilda lägen, och det är dyrt att uppgradera fel gem.
- `docs/research/siralim.md` §18.1–18.9: hela egenskapslistan, Rheas priser och ranker (T), 2.0-värdena (Cascading 5 %,
  Singular 50 %).
