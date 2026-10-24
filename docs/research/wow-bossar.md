# WoW-bossar som idébank (research, 2026-10-24)

Underlag för VD:s bossworkshop. Inget är byggt eller beslutat; VD bestämmer. Bygger på `docs/plan/varslade-attacker.md`
(laddningar, anti-mönster, faser), `docs/plan/mot-upprepning.md` (bossrotation, tecken, affix) och
`docs/research/variation-i-strid.md` (tid i stället för rum).

Märkning:
- **SÄKERT** = wiki, Blizzard eller flera guider kontrollerade i dag (källor i §7)
- **MINNE** = allmänt känt bland raidare, inte kontrollerat i dag
- **OSÄKERT** = enstaka källa eller motstridiga uppgifter (gäller främst Midnight, 2026)
- **GISSNING** = min bedömning
- ⚙ = ny kod (S liten, M mellan, L stor). Utan ⚙ räcker dagens egenskaper, auror och regler.
- **Finns** = redan i spelet; **Plan** = redan föreslaget i `varslade-attacker.md` eller `mot-upprepning.md`.

Ton: fienderna får vara onda och fördärvade; sällskapets sida är aldrig ockult.

## 0. Den viktigaste skillnaden

WoW:s bossar testar nästan alltid tre saker: **var du står** (rörelse), **när du gör något** (timing) och **vem som gör vad**
(roller och tilldelning). Vi har inget golv, så den första försvinner. Det som återstår passar oss förvånansvärt bra:

- **Timing** blir tidslinjen och laddningar (Plan: varslade attacker).
- **Vem som gör vad** blir makrorader per hjälte och sällskapets sammansättning. Det är vår spelarskicklighet.
- **Rörelse** översätts till tid ("var har du agerat") eller till ett val på en makrorad (Försvara, byt mål).

Tumregel (GISSNING): en WoW-mekanik är värd att låna om svaret går att skriva som **en rad i ett makro** eller som **ett
annat val av hjälte eller trofé**. Mekaniker vars svar är fingerfärdighet eller fotarbete ska vi inte låna.

## 1. Mekanikerna, med översättning

Varje rad: vad det är i WoW, kända exempel, och om det går hos oss. ✔ = bra passform, ~ = går med förbehåll, ✘ = avstå.

### 1.1 Tankbyte och staplar (tank swap)
**WoW:** bossen lägger en staplande debuff på tanken (mer skada tagen); vid N staplar tar den andra tanken över.
Exempel: **Festergut** (*Gastric Bloat*) och **Deathbringer Saurfang** (*Rune of Blood*) i ICC; byten finns i nästan varje
modern raid. MINNE.
**Hos oss ✔:** Plan har "Spräckt sköld" (−10 % Defense per stapel på den som Provocerar). Översättningen: auran staplar,
och ett nytt villkor `har minst n staplar av X` ⚙S (fiendesidan har `self_stacks_at_least`; makrot behöver en spegel).
Svaret: *Om jag har ≥3 Spräckt sköld → Försvara* på tanken, *Om tanken har ≥3 → Provocera* på en andra tank (Brokk +
Paladinen). Det tvingar fram **två tankar** eller en rensare: en sammansättningsfråga. Bra.

### 1.2 Avbrott (interrupt)
**WoW:** kanaliserade eller laddade besvärjelser som måste avbrytas, ofta i en turordning mellan spelarna.
Exempel: **Kel'Thuzad** (Naxx, *Frostbolt*), **Lady Deathwhisper**s tillägg (ICC), och nästan varje Mythic+-rutt. MINNE;
SÄKERT att avbrott är ryggraden i M+.
**Hos oss ✔ (Plan):** laddningen med `broken_by: silenced`. Luckan: sällskapet saknar avbrottsverktyg (Plan §1.6: Toves
Tryckpunkt). Villkoret `is_charging` ⚙S. **Avbrottsrotation** ("du tar första, jag andra") översätts till flera laddande
fiender och två hjältar med avbrott: makrot måste säga *vilken* fiende (`på den som laddar och har lägst liv`).

### 1.3 Adds och prioritet
**WoW:** tillägg som måste dödas först eller i rätt ordning. Exempel: **Ragnaros** (MC, *Sons of Flame*), **Kael'thas** fas 2 (TBC, vapnen), **Professor Putricide**s slemmor (ICC).
M+: *Raging*/*Bolstering*. MINNE.
**Hos oss ✔ Finns:** biskopens sköld (Kultist), Kultens förman (livvakt), Gravväckaren, Kistbäraren. Makron väljer mål med
`has_trait`, `lowest`, familjevillkor. Nytt (Plan): kanalen som gör prioriteten **tidsatt**.

### 1.4 Soak (ta smällen tillsammans)
**WoW:** en stor skadecirkel som delas av alla som står i den; för få och någon dör. Exempel: **Brutallus** (Sunwell, *Meteor Slash* delas av dem som står framför), soak-cirklar i nästan varje modern raid,
t.ex. **L'ura, Midnight Falls** där Dawn Crystal-bärare utlöser dem (OSÄKERT, Method). MINNE för Brutallus.
**Hos oss ~:** "Delad dom": ett slag på X delas lika mellan alla hjältar som **Försvarar** när det släpps; ingen Försvarar
= en hjälte tar allt. ⚙S (laddningens målval `split_among: defending`). Svaret: *Om fiende laddar Delad dom → Försvara* på
minst två hjältar. Intressant eftersom det är motsatsen till "bara tanken försvarar".

### 1.5 Sprid ut / stå ihop (spread/stack)
**WoW:** rörelse: sprid dig för kedjeskada, samla dig för delad skada. Exempel: **Thaddius** (Naxx, polaritet),
**Sapphiron** (isblock), **Sindragosa** (*Unchained Magic*), **Lightblinded Vanguard** (Midnight, råd, OSÄKERT detaljer).
**Hos oss ~:** utan rum blir spridning **tid**: Svallvåg (Plan §4) träffar bara dem som inte agerat sedan laddningen.
Thaddius polaritet → två märken (Ljus/Skugga); skada mellan olika märken som agerar i följd på tidslinjen ⚙M. Troligen
för svårt att läsa på telefon. Avstå polaritet, behåll Svallvåg.

### 1.6 Faser
**WoW:** bossen byter beteende vid liv eller tid. Exempel: **Onyxia** (luftfas), **Kel'Thuzad** (tre faser), **Lich King**
(ICC, övergångar), **Illidan** (BT), **Kil'jaeden** (Sunwell). SÄKERT som mönster.
**Hos oss ✔ (Plan §3):** `phases` i fiendens data ⚙M; Benfurstens vrede finns som egenskap. Bäst när fasen **byter svar**:
fas 1 följer hån, fas 2 inte. Högst två faser.

### 1.7 Enrage-timer (bärsärk)
**WoW:** efter X minuter dödar bossen raiden; ett DPS-test. Exempel: **Patchwerk** (Naxx), **Brutallus** (Sunwell),
nästan alla. Mjuk enrage: bossen blir starkare över tid eller får en ilska som måste tas bort (**Gluth**s *Frenzy*, som jägare lugnar). MINNE.
**Hos oss ~ Finns:** Utmattning från tur 100 (0.30.20). En hård bossenrage vore ett antal *bossens* turer ("Benfursten
vredgas efter 12 egna turer: +50 % skada per tur") ⚙S, visad som en klocka i Inspect. Risk: skadetest utan makrosvar.
Använd hellre **mjuk enrage som staplar**, så att makrot kan svara med att skingra eller döda fortare (se 1.9).

### 1.8 Helarkontroll (healer check)
**WoW:** perioder av stor gruppskada som helarna måste klara. Exempel: **Lich King**s *Infest* (ICC), **Valithria Dreamwalker** (man helar bossen), M+:s *Bursting* och *Grievous*. MINNE.
**Hos oss ✔ Finns delvis:** Svep (Benstorm, Mörk mässa). **Valithria-vändningen** är guld: en **vän som ska helas till
fullt** (se 1.20, Dusk Crystals hos L'ura är samma idé, OSÄKERT). ⚙S: en allierad "fånge" på fiendesidan som måste helas.

### 1.9 Rensa (dispel)
**WoW:** magiska eller sjukdomsdebuffar som måste rensas, ibland med ett pris (rensa = skada eller hopp). Exempel:
**Lucifron** (MC, förbannelser), **Grobbulus** (Naxx, *Mutating Injection*: rensa först när bäraren har gått undan). MINNE.
**Hos oss ✔ Finns:** Helande ljus, Skingra lögnen, `purge`, `dispel`. Nytt: **rensa med pris**: "Fördärvets frö" exploderar
när det rensas (skada på alla) – svaret är att rensa först när målet har Barriär, eller att låta det gå ut. Villkor
`har status X` finns; `har Barriär` finns (GISSNING, annars ⚙S). Bra makrofråga: *inte* rensa blint.

### 1.10 Reflektion och "sluta slå"
**WoW:** bossen reflekterar skada eller besvärjelser; man måste sluta slå eller byta skadetyp. Exempel: **Ossirian** (AQ20, svagheten byts), **Hydross the Unstable** (TBC, frost- och naturfas). Mönstret är säkert,
exemplen MINNE.
**Hos oss ✔ Finns:** Spegelsköld, `mirror_ward`, `warden_thorns`, affixen Taggig och Spegel (Plan §4). Svaret: makrot byter
mellan Anfall och Förmåga via `target_has_aura`. Hydross-varianten: **skolan växlar** var tredje tur (tar bara skada av
attacker, sedan bara av besvärjelser) ⚙S.

### 1.11 Sköld att bryta
**WoW:** bossen får en absorbering; bryt den innan den laddar klart, annars smäller det. Exempel: **Lady Deathwhisper**
(*Mana Barrier*), **Twin Val'kyr** (ToC, bryt skölden för att stoppa helningen), **L'ura**s matriser som tar bort bossens
skadereduktion (OSÄKERT, Method). MINNE.
**Hos oss ✔:** Plan "Skaka loss" (stagger) och affixet Skyddsbön. Kombinationen: **sköld + laddning**: laddningen bryts
när Barriären är borta. Ingen ny mekanik utöver stagger; tydligt på skärmen (Barriär syns redan).

### 1.12 Fordon och fordonsstrider
**WoW:** man styr ett fordon med egna förmågor. Exempel: **Flame Leviathan** (Ulduar), **Malygos** fas 3 (drakar),
**Gunship Battle** (ICC). SÄKERT.
**Hos oss ✘ (mest):** byter hela kontrollen; makrona gäller inte. Enda delen värd att låna: en **temporär förmåga** som
sällskapet får under striden (ett föremål, t.ex. "Klockrepet" ger alla en extra handling *Ring*) ⚙M. Avstå i första hand.

### 1.13 Råd (council)
**WoW:** flera bossar samtidigt med delade eller växlande krafter; när en dör blir de andra starkare eller tar över dess
förmåga. Exempel: **The Four Horsemen** (Naxx, märken som tvingar byte), **Assembly of Iron** (Ulduar, ordningen avgör
regeln), **Blood Prince Council** (ICC, den som har kraften byts), **Lightblinded Vanguard** (Midnight: tre fiender når full
energi i fast ordning; dör en för tidigt eskalerar de andra, OSÄKERT, Method/Gordian Knot).
**Hos oss ✔:** passar perfekt utan rum. Två varianter:
- **Assembly**: varje medlem som dör ger de andra sin egenskap ⚙S (`on_death: grant_trait allies`). Ordningen blir ett
  val med kostnad, och olika sällskap vill olika ordning. Makro: `has_trait` som målval.
- **Blood Prince**: bara den som bär "kronan" går att skada fullt; kronan går vidare var tredje tur ⚙S. Makro: `target_has_aura`.
Mönstret Four Horsemen (märken staplar på den som slår samma) liknar Stenhjärta (Finns).

### 1.14 Överföra debuffar
**WoW:** en debuff som hoppar till en annan spelare, ofta vid rensning eller tid. Exempel: **Professor Putricide** (*Unbound Plague*),
**Lich King** (*Necrotic Plague* hoppar vid rensning), **Blood-Queen Lana'thel** (bettet sprids); M+ *Necrotic* staplar på
tanken. MINNE.
**Hos oss ✔:** **Blodsband**: debuffen hoppar till den som agerar *närmast efter* bäraren på tidslinjen när den rensas eller
går ut ⚙S. Svaret: rensa när en tank står efter, eller låt tanken ta den (Provocera flyttar inte tidslinjen, men
`to_top` gör). Lana'thel-varianten "bit en till eller dö" hör inte hemma i vår ton för sällskapet (sällskapet blir då en
del av ondskan). **Avstå Lana'thel**, behåll hoppet.

### 1.15 Starkare nära varandra (empower by proximity)
**WoW:** adds eller bossar som förstärks när de står nära. Exempel: **Twin Emperors** (AQ40, helar varandra nära; MINNE), M+ *Inspiring*, Bargain: *Voidbound* (en emissarie som
stärker fiender, SÄKERT i grova drag).
**Hos oss ~:** "nära" blir **intill på tidslinjen**: en fiende som står direkt före eller efter en annan fiende i kön får +25 %
skada ⚙S. Spelaren ser det på tidslinjen och kan bryta det med `to_bottom`/`to_top`. Läsbart, men tidslinjen flyttar sig
hela tiden. Enklare och Finns: familjeräkning (Flockbett, Benmur). **Twin Emperors** översatt: två bossar som delar liv
och teleporterar = byter plats på tidslinjen var tredje tur ⚙S; tanken måste provocera om.

### 1.16 Kontroll av spelare (mind control)
**WoW:** en spelare tas över och slår sina vänner. Exempel: **Lady Deathwhisper**
(*Dominate Mind*), **Yogg-Saron** (*Sanity*), **Instructor Razuvious** (raiden *använder* MC på adds).
**Hos oss ~ Finns:** Förvirrad (slår slumpvis). Razuvious-vändningen är mest intressant: sällskapet får styra en fiendes
tillägg en kort stund. Men tonen: att ta över någons vilja är ockult för sällskapets sida. **Avstå Razuvious**; behåll
Förvirrad som fiendens verktyg.

### 1.17 Sanity/korruption som resurs
**WoW:** en mätare som tar slut (Yogg-Saron *Sanity*, Cho'gall *Corruption*, N'Zoth *Sanity*, Ny'alotha). SÄKERT som mönster.
**Hos oss ~:** en mätare per hjälte som fylls av fiendens Fördärv och ger en svaghet vid 100 % ⚙M. Kostar UI. Bättre som
**staplande aura** (Fördärvad finns) med villkor `har minst n staplar`.

### 1.18 Delad hälsa och "döda samtidigt"
**WoW:** **Twin Emperors**, **Twin Val'kyr** (ToC) och **Blood Prince Council** delar liv (MINNE); i M+ ger
*Bolstering* straff om man dödar ojämnt. Darklings i Slay the Spire är samma idé (`variation-i-strid.md` §1).
**Hos oss ✔ (Plan "Länkade" §3):** två som väcker varandra om den andra lever två turer senare ⚙S. Makro: `target_hp_below`
på båda; spelaren lär sig att dämpa skadan på den ena. Mycket bra makrofråga ("sprid skadan").

### 1.19 Kliva in/ut ur en annan värld (realm phase)
**WoW:** delar av raiden går till en annan plan: **Yogg-Saron** (hjärnan), **Halion** (tvilling i skuggvärlden),
**Valithria** (drömportaler). MINNE.
**Hos oss ~:** en hjälte "dras bort" i 2 egna turer (inte målbar, kan inte agera) medan en ande attackerar hen ⚙M. Liknar
Förstenad. Svaret är sammansättning (klarar sig sällskapet en man kort?). Mer berättelse än makro.

### 1.20 Skydda eller hela en vän (escort/heal the NPC)
**WoW:** **Valithria Dreamwalker** (hela bossen till 100 %), **Dusk Crystals** hos L'ura (hela till fullt, OSÄKERT).
**Hos oss ✔:** "Fången i kedjor": en befriad vän (berättelse: en arbetare från kryptan) står på fiendesidan med 30 % liv.
Helas hen till fullt bryts fiendens sköld. Kräver att helare kan målsätta hen ⚙S (`target: captive`). Vänder helarens
roll: hen blir den som avgör striden. Passar Siralims anda (en egenskap att svara på).

### 1.21 Varslat stort slag
**WoW:** varningstext och tid att reagera: **Sartharion** (lavavågor), **Kel'Thuzad**s *Frost Blast*, **Ragnaros** (MC)
*Wrath of Ragnaros*; nästan varje modern boss. Mönstret SÄKERT, exemplen MINNE.
**Hos oss ✔ (Plan, huvudspåret):** laddningen. Inget att lägga till.

### 1.22 Märkt mål (fixate)
**WoW:** ett tillägg jagar en viss spelare; tanken hjälper inte. Exempel: **Professor Putricide** (*Gaseous Bloat* jagar en spelare), Bargain: *Ascendant*
(klot som rör sig mot fiender, SÄKERT i grova drag). MINNE.
**Hos oss ✔ Finns:** `ignore_taunt`, `pick: healer`. Ny form: fienden **visar** vem den jagar (avsiktens linje finns) och
Provocera fungerar inte förrän målet har Försvarat en gång ⚙S. Makro: `is_charge_target` (Plan).

### 1.23 Sårbarhetsfönster (burn window)
**WoW:** bossen blir sårbar efter en mekanik: **Onyxia** när hon landar, **Belo'ren** (Midnight: äggfasen
är det stora skadefönstret, OSÄKERT, Method). MINNE.
**Hos oss ✔ (Plan):** Vacklande efter bruten laddning. Makrovillkor `target_has_aura Vacklande` → spara den starkaste
förmågan till fönstret. Villkor finns (aurans namn). Bra: lär spelaren att *inte* bränna Charges direkt.

### 1.24 Plats-/elementfärg (Light/Void, polaritet)
**WoW:** spelaren får en färg och tar mindre skada av sin färg: **Thaddius**, **Twin Val'kyr**, **Belo'ren** (Ljus och
Tomhet, var spelare halv skada av sin färg, OSÄKERT, wow.gg).
**Hos oss ~:** två skolor av fiendeslag (ljusbrand / skuggslag) och två auror för sällskapet som halverar var sin ⚙S.
Svaret är **sammansättning och artefakt**: vem bär vilken? Kanske för mycket UI. Håll som senare idé.

### 1.25 Pussel med ordning (sekvens)
**WoW:** gör saker i rätt ordning: **Assembly of Iron**, **Yogg-Saron**s Keepers (frivilliga, gör striden svårare och ger mer),
**Algalon** (tidsgräns per vecka). **Hard modes**: **Mimiron**s knapp, **XT-002**s hjärta, **Flame Leviathan**s torn
(Ulduar). SÄKERT.
**Hos oss ✔:** Ulduars **frivilliga svårighet** är ett av de bästa lånen: ett val *före* striden som gör den svårare mot bättre
belöning. Vi har Löften (0.30.17) och instabilitet; en bossversion: "Låt klockan ringa" (Klockaren får behålla sina
tillägg) mot en garanterad trofé. Data + ⚙S.

### 1.26 Golvskada och "stå inte i elden"
**WoW:** allt från *Void Zone* till *Consecration*-pölar (Lightblinded Vanguard lämnar permanenta pölar, OSÄKERT).
**Hos oss ✘ som rörelse.** Ersättning: skada över tid som träffar den som **inte** agerat på X turer (motsatsen till
Svallvåg) – men det blir lätt brus. Avstå; vi har dot-auror.

### Sammanfattning av passformen

| Bra (✔) | Med förbehåll (~) | Avstå (✘) |
|---|---|---|
| Tankbyte, avbrott, adds, faser, rensa med pris, reflektion, sköld att bryta, råd, döda samtidigt, skydda en vän, varslat slag, fixate, sårbarhetsfönster, frivillig svårighet | soak, spridning, enrage, närhet, MC, sanity, annan värld, färg | fordon, golvskada, polaritet i rörelse, Lana'thel-bettet, Razuvious |

## 2. Det som gör svaret till en makrorad

Gemensamt för de lån som fungerar:
1. **Hotet syns i förväg** (avsikt, laddning, stapel, aura). Utan det kan makrot inte svara.
2. **Det finns ett villkor som läser det.** Saknade villkor, samlade (alla ⚙S i `MacroRunner.CONDITIONS`):
   - `is_charging`, `charge_left_at_most`, `charging_all`, `is_charge_target`, `is_channeling` (Plan)
   - `har minst n staplar av <status>` (för tankbyte och sanity)
   - `fienden bär kronan/kraften` (råd) – räcker troligen med `target_has_aura` (finns)
   - `fiende står direkt efter mig på tidslinjen` (överföring, Svallvåg)
3. **Det finns mer än ett svar.** Varje boss ska ha ett brytande svar (avbrott, stagger, döda kanalen) och ett dämpande
   (Försvara, Barriär), som i `varslade-attacker.md` §1.3.
4. **Svaret skiljer sig mellan hjältar.** Tanken byter, helaren rensar, skadegöraren sparar till fönstret. Då blir det en rad
   per hjälte, och spelaren lär sig att makron är *roller*.

## 3. Mythic+-affix som våra affix och djupets tecken

**Hur M+ gör (SÄKERT i stort):** samma dungeons hela säsongen, men affixen roterar varje vecka, så samma rutt spelas
annorlunda. Från Dragonflight och framåt färre affix; The War Within införde *Xal'atath's Bargain* (Ascendant, Devour,
Voidbound, Pulsar, tidigare Oblivion) som **kan vändas till spelarens fördel**. Midnight säsong 1 (OSÄKERT i detaljer):
*Lindormi's Guidance* på låga nivåer (markerar och försvagar fiender längs en rutt), en Bargain från nivå 5, Tyrannical eller
Fortified från 7, båda från 10, *Xal'atath's Guile* från 12 (tar bort Bargainens fördelar).

Det här är exakt `mot-upprepning.md` §3–4: samma grupper, ny fråga. Lärdomen från tio års affix (GISSNING ur
spelardebatten): de affix som **ändrar vad man gör** (Bolstering, Sanguine, Explosive, Spiteful, Incorporeal) älskas eller
hatas men minns; ren skala (Fortified, Tyrannical) är tråkig men ärlig; de som straffar fel man inte ser (Quaking, Volcanic
utan varning) hatas. Bargain-idén, **ett affix som spelaren kan vinna på**, passar vårt "tvåsidiga tecken".

| WoW-affix | Vad det gör (kort) | Vår översättning | Var | Makrosvar | Kod |
|---|---|---|---|---|---|
| Bolstering | döende fiende stärker de andra | **Hämnande** (Plan) | elitaffix | döda ledaren först eller jämnt | ⚙S |
| Raging | fiende under 30 % blir rasande, kan lugnas | **Ursinne**: under 30 % +50 % skada tills Försvagad/Förvirrad läggs | elitaffix | *Om fiende < 30 % → debuff först* | data + ⚙S |
| Sanguine | döende lämnar helande pöl | **Blodsarv**: fallande fiende ger sin närmast efter på tidslinjen Läkning 2 turer | elitaffix | döda i ordning, rensa (purge) | ⚙S |
| Bursting | varje död fiende ger gruppen en dot-stapel | **Benflisor**: varje fiende som faller ger alla hjältar Blöder 1 stapel | tecken | helare rensar, döda inte alla samtidigt | data (on_death aura) |
| Necrotic | tankens slag staplar mindre helning | **Skuld** (Plan) som staplar på Provocerare | elitaffix | byt tank, Försvara bort staplar | ⚙S |
| Explosive | små klot som måste slås | **Gnistor**: var tredje fiendetur ett Glöd-tillägg med 1 liv som exploderar på sällskapet efter 1 tur | tecken | *Om fiende har lägst maxliv → Anfall* (billig rad) | ⚙S |
| Grievous | sår som stannar under 90 % liv | **Djupa sår**: hjältar under 50 % blöder tills helade över 75 % | tecken | helarens tröskel höjs i makrot | data (aura med villkor) ⚙S |
| Spiteful | döende fiender lämnar en ande som jagar helaren | **Hämndande andar**: fallen fiende ger en ande (1 tur, `pick: healer`) | elitaffix | Barriär på helaren, Försvara | ⚙S |
| Incorporeal | ande som måste kontrolleras | **Viskare**: tillägg som Försvagar en hjälte om det inte sövs/tystas i tid | tecken | Vaggvisa, Tryckpunkt | ⚙S |
| Afflicted | ande som måste helas eller rensas | **Den drabbade** (likt 1.20): en vän som ska helas | tecken | helaren måste välja | ⚙S |
| Entangling | rötter man måste gå ur | **Snärjd** i början av striden på en hjälte | tecken | rensa först | data |
| Storming/Quaking/Volcanic | rörelse | ✘ (inget rum) | – | – | – |
| Teeming | fler fiender | **Ett folk** / extra fiende (Finns som `EXTRA_ENEMIES`) | tecken | – | data |
| Fortified / Tyrannical | vanliga fiender resp. bossar starkare | djupet gör redan detta (+8 %/djup) | – | – | Finns |
| Thundering (DF) | märken som måste paras ihop | ✘ rörelse; möjligt som två märken som tar bort varandra om bärarna agerar i följd ⚙M | senare | – | ⚙M |
| Prideful / Inspiring (BfA/SL) | fiende som gör andra immuna mot kontroll | **Inspirerande**: ledaren gör de andra Resistenta | elitaffix | döda ledaren eller använd skada | data (`resistant` via aura ⚙S) |
| Tormented / Encrypted / Infested / Awakened / Beguiling / Reaping (säsongsaffix) | en säsongs egna specialfiender, ofta med belöning | **Säsongen hos oss = Realmens fördärv** (levande kartan): fördärv 3+ ger en specialgrupp | tecken | – | ⚙S |
| Bargain: Ascendant | klot stärker fiender; avbryt/kontrollera och spelaren tar buffen | **Stjärnfall**: var femte tur faller ett ljus; den som Försvarar på den turen tar det (Smidig 2 turer), annars får fienden närmast det | tecken (tvåsidigt) | *Om tecken laddar → Försvara* | ⚙S |
| Bargain: Devour | heal absorb på spelare | **Svält**: en hjälte får en helningsabsorbering; rensas genom helning | tecken | helaren prioriterar | ⚙S (`heal_absorb`) |
| Bargain: Voidbound | emissarie som stärker fiender, ger spelare buff när den dör | **Härolden**: en extra fiende i elitgrupper som stärker de andra; dödas den får sällskapet Arkan | elitaffix | prioritet + belöning | data + ⚙S |
| Bargain: Pulsar | OSÄKERT vad den gör (inte bekräftat i dag) | – | – | – | – |
| Lindormi's Guidance (Midnight) | lärhjälp på låga nivåer | **Gorms rykte**: på djup 1 visar kartan rutten och fienderna är ×0,9 | introt | – | Finns nästan (`quest_hints`) |

**Rekommendation (GISSNING):** ta fyra till elitaffix (Hämnande/Bolstering, Ursinne/Raging, Hämndande andar/Spiteful,
Härolden/Voidbound) och tre till tecken (Benflisor/Bursting, Stjärnfall/Ascendant, Djupa sår/Grievous). De tvingar alla
fram en ny makrorad, inte bara mer liv. Stjärnfall är det enda rent tvåsidiga och passar tecknens regel bäst.

## 4. Femton bossidéer för våra Realms

Varje idé: svenskt namn, förebild, mekanik, makrosvar, insats. Siffror är startpunkter. Alla förutsätter laddningen (Plan).
Ton: fienderna är onda, sällskapet aldrig ockult.

### Kryptan (de döda)

**1. Klockaren som boss: "Tre slag till midnatt"** – förebild Kel'Thuzad (Naxx: faser, frostblast) + Ragnaros (MC: adds i
pausen). Klockan slår var fjärde egen tur och väcker en Benspringare per slag. Vid tredje slaget en laddning *Midnattsslaget*
(alla, 1,5) som bryts om alla väckta är döda (`channeled_by: bone_kin`). Makro: *Om fiende kanaliserar → Anfall den*,
*Om någon laddar mot alla, ≤1 tur → Försvara*. ⚙S (kanal).

**2. Gravväckaren och Kistbärarna: "Kistornas råd"** – förebild Assembly of Iron och Four Horsemen. Tre fiender; den som faller
ger de andra sin egenskap (Barriär, väckning, Benmur). Ordningen är valet: döda Kistbäraren först och de andra får Barriär
vid död; döda Väckaren först och ingen väcks men Benmur staplar. Makro: målval `has_trait` olika per sällskap. ⚙S
(`on_death: grant_trait`).

**3. Benfursten djup 3+: "Den gamla kronans tyngd"** – förebild Lich King (ICC: övergångsfaser, *Necrotic Plague* som hoppar).
Fas 2: *Gravpest* på en hjälte, 2 turer; när den går ut eller rensas hoppar den till den som står närmast efter på
tidslinjen och blir en stapel starkare, och Benfursten helas lite per hopp. Makro: rensa när en tank står efter, eller låt
Paladinen ta den med Helig sköld. ⚙S (hopp).

**4. Benskrivaren som elit: "Den som skriver ditt namn"** – förebild Lady Deathwhisper (mana barrier + adds) och Sapphiron.
Barriär 40 % av livet; medan Barriären står laddar han *Dödsrulla* (ett mål, `ignore_taunt`, dödande). Bryts när Barriären
faller (stagger). Makro: *Om fiende har Barriär och laddar → starkaste förmågan på den*. Data + Plan.

### Det fördärvade kapellet (kulten)

**5. Den fallne biskopen: "Svarta mässan"** – redan i Plan §5.2 (kanal + Skuld). Förebild Lady Deathwhisper och Kel'Thuzad.
Behåll som den är.

**6. Abbedissan som boss: "Systrarnas krona"** – förebild Blood Prince Council (ICC). Abbedissan och två diakoner; bara den
som bär kronan går att skada fullt (övriga −75 %), kronan går vidare var tredje egen tur och den som bär den laddar en
predikan. Makro: *Anfall fiende som har status Krönt*. Dödas en diakon utan krona: de andra +20 % (straff för att slå fel).
⚙S (aura som flyttar).

**7. Inkvisitorn: "Förhöret"** – förebild Garrosh/Necrotic-tank + Spiteful. Varje slag mot den som Provocerar ger Skuld
(−15 % helning tagen, staplar). Vid 3 staplar laddar han *Dom* mot den hjälten. Makro: *Om jag har ≥2 Skuld → Försvara*
(staplarna faller bort) och en andra tank som Provocerar. Tvingar fram tankbyte. ⚙S (stapelvillkor).

**8. Den fångne korgossen: "Ljuset i kedjor"** – förebild Valithria Dreamwalker och Dusk Crystals (L'ura). En pojke fängslad
av kulten står på fiendesidan med 25 % liv; Asketen och två Kultister vaktar. Helas han till fullt bryts deras gemensamma
sköld och han springer i säkerhet (och blir en berättelse: en ny lärjunge senare?). Dör han: kulten får +30 % skada.
Makro: helaren får en rad *Hela fången* överst. ⚙S (`target: captive`). Vänder helarens roll; stark berättelse, god ton.

**9. Den svarta lansen djup 3+: "Anstormningen"** – förebild Patchwerk + Gruul *Growth*. Mjuk enrage: +10 % skada per egen tur
(staplar), som nollställs när han blir Försvagad eller Vacklande. Makro: *Om fiende har ≥4 Ilska → Försvaga den*. Ett
DPS-test med ett makrosvar. data + ⚙S (stapelvillkor).

### Sidenlunden (spindlarna)

**10. Vävmodern: "Kokongerna"** – förebild Maexxna (Naxx: *Web Wrap*, spindelungar). Vart tredje slag spinner hon in en hjälte i
en kokong (kan inte agera; kokongen har eget liv). Ungar kläcks varannan tur. Kokongen är en egen fiende-enhet; rad *Om allierad är inspunnen → Anfall kokongen*. ⚙M (kokongen som enhet;
liknar 1.20).

**11. Sömnvävaren och Slukaren: "Drömmen och munnen"** – förebild Twin Emperors (AQ40). Två bossar som byter plats på
tidslinjen var tredje runda; Sömnvävaren tar bara skada av besvärjelser, Slukaren bara av attacker. Står de intill varandra i
kön helar de varandra. Makro: växla Anfall/Förmåga på `has_trait`, och `to_bottom` för att dra isär dem. ⚙S (byte, intill).

**12. Strypvävaren: "Trådarna"** – förebild Thaddius/Sindragosas *Beacon* utan rörelse: två hjältar knyts ihop med en tråd; när
den ena tar skada tar den andra 50 %. Tråden brister när båda Försvarar samma runda. Makro: *Om jag är bunden → Försvara*.
Lär ut samordning mellan två makron. ⚙S (länkaura).

### Trollberget (trollen)

**13. Bergakungen: "Berget samlas"** – redan i Plan §5.3 (laddning + stagger + Stenhjärta). Förebild Gruul och Garrosh. Behåll.

**14. Trollmor Gråluva och ungarna: "Moderns vrede"** – förebild Bolstering + Ignis. Tre ungar och modern; varje unge som dör
gör modern 25 % starkare (staplar), men levande ungar helar modern varje tur (Trollhud). Två dåliga vägar; svaret är
Trollhud-förmågor på modern (stoppar läkningen) *och sedan* ungarna snabbt i följd. Makro: *Om fiende har Trollhud-läkning →
förmåga som bränner*, sedan ungarna. Data + Hämnande (⚙S).

**15. Brom vid bron: "Tullen"** – förebild Ulduars frivilliga svårighet (hard modes) och dagens Tull. Före striden: betala tull (silver) så strider han utan sin tull-egenskap, eller vägra och få hans trofé
garanterat. I striden: Tull (+50 % mot Provocerare, Finns) och en laddning *Kasta i forsen* som skickar en hjälte längst ned på
tidslinjen. Makro: *Om jag är måltavla → Försvara*. Data + ⚙S (valet före striden).

**Extra (om VD vill ha en sextonde): "Kyrkogrimmen"** – förebild Hodir (Ulduar: extra skatt om han dör inom en tidsgräns; MINNE) – en vakt som
bara går att slå inom 15 egna turer för en extra trofé. Berättelse snarare än mekanik.

## 5. Topp 5 (GISSNING om vad som ger mest makrospel per kodrad)

1. **Kistornas råd** (Assembly): ordningen blir ett val som skiljer sig mellan sällskap; ⚙S.
2. **Ljuset i kedjor** (Valithria): helaren avgör striden, god ton, berättelse; ⚙S.
3. **Systrarnas krona** (Blood Prince): en aura som flyttar räcker; lär makrot att läsa `target_has_aura`; ⚙S.
4. **Förhöret** (tankbyte): tvingar fram två tankar eller Försvara-rytm; stapelvillkoret behövs ändå; ⚙S.
5. **Tre slag till midnatt** (Kel'Thuzad + kanal): bygger direkt på laddningen i Plan, naturlig befordring av Klockaren
   (`mot-upprepning.md` §1).

Sedan: Drömmen och munnen (Twin Emperors) och Moderns vrede, när Sidenlunden och Trollberget får sina Realms.

## 6. Frågor till VD

**VD:s svar 2026-10-24:** idéerna om bossarna lät "superbra". 2: ja, vissa bossar får kräva två tankar. 3: nej, inga frivilliga svåra lägen (Löften och instabilitet räcker). 5: ja, en räddad fånge kan bli lärjunge. 6: ja, rena DPS-test får finnas ibland. 1: exemplen i §4 räcker långt, det är sådana saker VD menar (t.ex. tankbyte när staplarna blir för många). 4: obesvarad, förklarad på nytt. 7: vilket som helst – vi gör båda (Kistornas råd = ordningen, Systrarnas krona = kraften flyttar). 8: VD har bara provat Midnight; har spelat Delves (ensam ned i en grotta) till maxnivå – Midnight-uppgifterna förblir osäkra.

1. **Vilka WoW-bossar minns du som roligast, och varför?** Var det mekaniken, tilldelningen eller berättelsen? Det styr om vi
   prioriterar råd (Assembly/Blood Prince) eller pussel med vän att rädda (Valithria).
2. **Tankbyte:** vill du att vissa bossar *kräver* två tankar (Förhöret), eller ska Försvara alltid räcka som reservsvar?
3. **Frivillig svårighet (Ulduars hard modes):** ett val före bossen som gör den svårare mot en garanterad trofé? Eller räcker
   Löften och instabilitet?
4. **Affix som spelaren kan vinna på (Bargain):** ska djupets tecken vara tvåsidiga som Stjärnfall, eller hellre rena straff
   med silver som i dag?
5. **Rädda en vän i striden:** ska fången bli en ny lärjunge efteråt (berättelse), eller bara en strid?
6. **Hur ofta får en boss vara ett rent DPS-test** (Patchwerk, Svarta lansen), när varje strid annars ska ha ett makrosvar?
7. **Råd med tre fiender:** vill du att ordningen ska vara ett val (Assembly) eller att kraften flyttar sig (Blood Prince)? Båda
   går, men de lär ut olika saker.
8. **Midnight:** har du spelat Voidspire/March on Quel'Danas? Uppgifterna här om Lightblinded Vanguard, Belo'ren och L'ura
   kommer från enstaka guider och kan vara fel i detaljer.

## 7. Källor

Kontrollerade i dag (2026-10-24):
- Midnight-raider: [Wowhead: raid overview](https://www.wowhead.com/news=380447/midnight-season-1-raid-overview-and-schedule),
  [warcraft.wiki.gg: The Voidspire](https://warcraft.wiki.gg/wiki/The_Voidspire),
  [Method: Lightblinded Vanguard](https://method.gg/guides/the-voidspire/lightblinded-vanguard),
  [Gordian Knot: Vanguard](https://gordian-knot.eu/lightblinded-vanguard-heroic-down/),
  [Method: Belo'ren](https://www.method.gg/guides/march-on-queldanas/beloren-child-of-alar),
  [Method: Midnight Falls](https://www.method.gg/guides/march-on-queldanas/midnight-falls),
  [wow.gg: March on Quel'Danas](https://wow.gg/guides/march-on-quel-danas),
  [Blizzard Watch: världsförsta dag 3](https://blizzardwatch.com/2026/03/27/midnight-season-1-race-world-first-recap-day-3-lightblinded-vanguard-goes-another-world-first-liquid).
- Mythic+: [warcraft.wiki.gg: Mythic+ affix](https://warcraft.wiki.gg/wiki/Mythic%2B_affix),
  [Raider.IO: The War Within affixes](https://raider.io/news/667-the-war-within-mythic-plus-affixes),
  [Blizzard: Affix System Updates in TWW](https://eu.forums.blizzard.com/en/wow/t/affix-system-updates-in-the-war-within/520314),
  [Icy Veins: Midnight M+ S1](https://www.icy-veins.com/wow/midnight-mythic-season-1-guide).
- Allt från Vanilla till Dragonflight ovan är **MINNE** om inget annat står: allmänt känd raidkunskap, inte kontrollerad mot
  wiki i dag. Exempel som jag själv var osäker på är märkta med frågetecken eller MINNE; de ska kontrolleras innan något
  byggs efter dem.
