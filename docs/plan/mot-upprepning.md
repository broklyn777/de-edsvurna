# Mot upprepning: samma boss, samma grupper, bara starkare

Underlag på papper (2026-10-24, grenen `plan-variation`, skuren från test-0.30). Inget är byggt eller beslutat; VD bestämmer.
Märkning som i `0.27-fiender.md`: **Siralim** = som originalet, **VAL** = vårt val med motivering, **GISSNING** = obeprövad
bedömning, ⚙ = ny kod (S liten, M mellan, L stor); utan ⚙ räcker data. **VD** = beslut som behövs.

## 0. Problemet

VD: spelet är roligt. Att dö, gå hem, träna, smida och prova nya makron är precis det som ska hända. Risken på lång sikt är
**upprepning**: samma boss, samma monster och samma elitgrupper på varje våning och djup, bara starkare. Ledstjärnan
("byter spelaren frivilligt en hjälte eller trofé efter en ny kombination?") kräver att fienderna ibland ställer en ny fråga.
Djupet gör i dag bara samma fråga svårare (+8 % stats per djup).

### Vad som upprepas i dag (läst i datan 2026-10-24)

| Realm | Vanliga grupper tier 0 / 1 / 2 | Elitgrupper våning 1 / 2 | Boss | Miniboss (bara i en elitgrupp) |
|---|---|---|---|---|
| Kryptan | 3 / 7 / 6 | **1** (Kolossens vakt) / 6 | Benfursten (+ den svärtade på fördärv 4) | Klockaren (`crypt_e5`) |
| Kapellet | 4 / 7 / 8 | **1** (Lansens anstormning) / 6 | Den fallne biskopen | Abbedissan (`chapel_e6`) |
| Sidenlunden | 3 / 4 / 5 | **1** / 3 | Vävmodern | Strypvävaren (`grove_e3`) |
| Trollberget | 4 / 4 / 4 | **1** / 2 | Bergakungen | Brom (`troll_e2`) |

En nedstigning har ca 10–12 strider (`BALANS=grotta`). Räknat för **10 nedstigningar till samma Realm** (GISSNING, jämn
slump, kryptan):
- Bossen: samma strid **10 av 10** gånger. Bara fördärvet byter den, och bara på steg 4.
- Våning 1:s elitgrupp: samma **10 av 10** (poolen har en grupp). Nemesis i en Jakt dras ur samma pool.
- Våning 2:s elitgrupp: var och en ses 1–2 gånger. Det är den bästa delen i dag.
- Vanliga grupper: ca 100 strider ur ~16 grupper, varje grupp **6 gånger**. Elitvarianterna (de glödande) är 5–14 % per fiende.
- Våningsreglerna kommer bara med instabilitet, som de flesta inte väljer förrän sent.

Sprider spelaren sig över fyra Realms blir det bättre, men bossen och våning 1:s elit upprepas fortfarande varje gång man
går till en viss Realm. **Det är de två strider som syns mest och betyder mest.** De tar man först.

### Vad Siralim gör (siralim.md §10, §19, §21; siralim_innehall.md §1, §3; langsiktiga-mal.md §2.1)

- **Vanliga Realms har ingen boss** (**Siralim**, säkert). Utgången är målet. Bossar finns på story-djup, var femte djup
  (Nether Bosses, ett regelbrytande trait i tre grader), False Gods och bakom portaler. Vi har valt en boss per körning
  (**VAL** sedan 0.18); därför syns upprepningen mer hos oss än i originalet.
- **Nemesis** vandrar som andra grupper men bär en **varningstext**: Hearty (dubbelt liv), Thorns (reflekterad skada),
  Greedy (mer byte), Brutal … (**Siralim**, säkert). Det är originalets affix.
- **Realm Properties**: synliga och dolda regler per Realm, fler med instabilitet. Några gäller kartan: Extra Nemesis
  Creatures, Inhabited by X Race, Enemies Belong To Same Race (**Siralim**, säkert).
- **Instabilitet**: varelser från andra Realms, sammansmälta fiender (**Siralim**, säkert).
- **Nether Realm-dörrar** och Otherworld Portals: små egna banor som överraskning (**Siralim**, säkert).
- **Mängden**: ca 1200 varelser, 30+ Realms med en ras och en gud var (**Siralim**, säkert i storleksordning). Ingen indie
  kan matcha det; originalets variation kommer ändå mer av *kombinationen* (vilka varelser, vilken property, vilken Nemesis)
  än av att varje strid är ny. Det är vår väg också.

## 1. Bossar som växlar med djupet, och en Nemesis som skiljer sig

**Idé (VAL, förebild Siralims Nether Bosses var femte djup):** varje Realm har en **bosslista** i stället för ett bossmöte.
Huvudbossen kommer på djup 1 (berättelsen) och sedan **var tredje djup** (3, 6, 9 …). Däremellan vaktar en annan:

| Realm | Djup 1, 3, 6, 9 … | Djup 2, 5, 8 … | Djup 4, 7, 10 … |
|---|---|---|---|
| Kryptan | Benfursten | **Klockaren** (befordrad miniboss) med Benfolket | **Gravväckaren** med två Kistbärare (eliten som boss) |
| Kapellet | Den fallne biskopen | **Abbedissan** med diakoner | **Inkvisitorn** med Kultens förman |
| Lunden | Vävmodern | **Strypvävaren** | **Sömnvävaren och Slukaren** (två eliter) |
| Berget | Bergakungen | **Brom** vid bron | **Trollmor Gråluva** med tre ungar |

- **Befordrad**: samma fiende, men mötet är ett bossmöte (`boss: true` på mötet, inte på fienden), med bossens stat_mult,
  Resistent och motdraget från början. Fienden behåller sin egen trofé; bossmötet lägger till en **bosstrofé** efter tre
  segrar som vanligt (`Profile.boss_wins`). ⚙S: i dag läser `RunState` bossen som `floor_ids[-1]`; den blir
  `boss_for(realm, depth)` ur `realms.json` "bosses": `[{"encounter": "crypt_3", "every": 3, "from": 1}, …]`.
  Bossflaggan läses i dag från fienden på flera ställen (troféer, segerskärmen, berättarrutan efter första bossen); de
  måste läsa mötet. GISSNING: en halv till en dag med tester.
- **Huvudbossen blir svårare på riktigt, inte bara starkare** (Siralim: Nether Bossens trait i tre grader). Djup 1: som i dag.
  Djup 3–5: ett andra skede eller en varslad attack (`varslade-attacker.md` §5). Djup 6+: motdraget från djup 1 och ett till.
  Det är data i bossens egenskaper med `min_depth` ⚙S (samma mönster som motdragens djup i `counter_for`).
- **Den förvridna bossen** (levande kartan) står kvar som den är: den tar huvudbossens plats på fördärv 4, oavsett djup.
- **Bosstroféerna** kommer långsammare när bossen växlar (3 segrar per boss). Det är bra: fler bosstroféer att jaga, och
  varje är värd en resa tillbaka. VD: ska det räcka med 2 segrar för befordrade bossar?

**Nemesis (Siralim):** i dag är Nemesis bara den första elitgruppen i en Jakt, ur samma pool. Förslag:
1. Nemesis dras ur **hela Realmens elitpool** (båda våningarna), inte bara våningens. Data/⚙S.
2. Nemesis bär **alltid ett affix** med namn och varningstext på kortet (§4). Det är originalets form och den billigaste
   vägen till "den här gången är det något annat".
3. Nemesis får ett eget namn ur gruppens ledare + affixet: "Benkolossen den seglivade". Data i affixet.

**Effekt på 10 nedstigningar:** bossen blir 4 strider med huvudbossen och 6 med två andra, i stället för 10 lika. Nemesis
med affix gör Jakt-questen olik varje gång. GISSNING: den största enskilda vinsten per timme, eftersom bossen är det man
minns.

**Insats:** ⚙S för bosslistan och befordran (1 dag), data för 2 nya bossmöten per Realm (2–3 timmar per Realm inkl.
botmätning), affixet hör till §4.

## 2. Fler grupper, våningar med egen prägel och blandade familjer

**2a. Våning 1:s elitpool är en enda grupp i alla Realms.** Det är den mest upprepade striden efter bossen. Förslag: 3
grupper per Realm på våning 1, byggda av fiender som redan finns (data). Exempel kryptan: Kolossens vakt (som i dag),
"Benskrivarens kopior" (Benskrivaren + Skelettkrigare, mild), "Gravdimmans första natt" (Gravdimman + bågskytt). Den första
nedstigningen behåller Kolossens vakt (`first_descent_stat_mult`, berättelsen). **Data**, 2 timmar per Realm med
`BALANS=elitgrupper`.

**2b. Fler vanliga grupper per tier**, särskilt tier 0 (3–4 i dag). Mål: 6 per tier. Varje grupp är en mall
(`template`: "Front och stöd", "Offret", "Nötning" …) med andra fiender; mallarna finns redan i `0.27-fiender.md`. **Data.**

**2c. Våningsblandningar per djup (VAL).** I dag är poolerna desamma på varje djup. Förslag: poolen får `min_depth` per
grupp, så att djup 2 lägger till ett par grupper och djup 4 ett par till (t.ex. två eliter som vanlig grupp i tier 2 från
djup 5). Spelaren märker att djupet *ändrar* något. ⚙S (filter i `Grotto.generate` där poolen väljs), resten data.

**2d. Elitvarianterna (de glödande) oftare med djupet.** I dag 5 % + 1 % per djup, tak 30 %. Förslag: +2 % per djup, och
**högst en per grupp men minst en per våning från djup 3** (säker sällsynthet). De har eget namn och egen trofé, så de är
redan variation; de syns bara för sällan. Data (konstanterna i `CombatSim`) + ⚙S för "minst en per våning".
VD: elitvariantens trofé blir vanligare; vill VD hålla den sällsynt?

**2e. Blandade familjer genom den levande kartan (Siralim: instabilitetens varelser från andra Realms).** När en Realm står
på fördärv 3+ "sprider" den sig: i grannrealmen kan en av våningens grupper bytas mot en **blandgrupp** (en ur den egna
familjen och en ur den spridda, t.ex. Benspringare + Snärjspindel). Kartan berättar redan att fördärvet växer; nu syns det i
striden. Mötena skrivs för hand (8–12 blandgrupper totalt, data), valet är ⚙S i `start_floor` (läs `LivingMap.growth` för
grannarna). Fungerar först när tre Realms spelas i växling. GISSNING: blandgrupperna är där nya kombinationer uppstår
(Flockbett räknar bara Benfolket; Snärjd + Jägarblick blir en ny fråga).

**Effekt:** 2a tar bort den näst mest upprepade striden. 2b–2c halverar hur ofta en vanlig grupp ses (6 → ~3 gånger på 10
nedstigningar). 2d–2e ger överraskningar, inte bara fler mönster.
**Insats:** 2a och 2b data (en dag för alla fyra Realms med botar), 2c–2d ⚙S (halv dag), 2e ⚙S + data (1–2 dagar).

## 3. Djupets tecken: en synlig regel per nedstigning

**Siralim:** Realm Properties gäller hela Realmen och syns innan man går in. Hos oss finns de bara som instabilitet
(straff mot silver). Förslag (**VAL**): **varje nedstigning efter introt drar ett tecken**, en synlig regel som *ändrar hur
striderna spelas* utan att vara ett straff. Den syns på kampanjkartan ("Det här djupet: Fullmåne") och överst i grottan,
och kan slumpas om en gång vid portalen för lite silver (Siralim: properties slumpas om vid Teleportation Shrine).

Tecknet skiljer sig från instabiliteten: **det är tvåsidigt** (gäller båda sidor eller ger något tillbaka) och ger inget
extra silver. Instabiliteten finns kvar ovanpå.

| Tecken (förslag) | Regel | Förebild | Insats |
|---|---|---|---|
| Fullmåne | Kritiska träffar gör dubbelt, för alla | Always Critical Damage (mildare) | ⚙S |
| Helig mark | Helning +25 % för alla, även fiendernas | Heal Every Turn / Less Healing, vänd | data (`modify_heal`, scope alla) |
| Ekande valv | Var tredje förmåga i striden kastas två gånger, båda sidor | Attack/Cast Additional Times | ⚙S |
| Rastlösa döda | Alla börjar striden Smidiga i 2 turer | Buff: X | data (`start_auras` för båda) |
| Ett folk | Alla grupper på våningen är ur samma familj (familjens egenskaper slår hårdare) | Enemies Belong To Same Race | ⚙S (poolfilter) |
| Inkräktare | En grupp per våning kommer från en annan Realm | Inhabited by X Race | ⚙S (som 2e) |
| Två Nemesis | Jakt-questen har två, båda med affix; belöningen +50 % | Extra Nemesis Creatures | ⚙S |
| Tunga kistor | Dubbelt så mycket bärnsten; fienderna +10 % Defense | Properties mot byte | data |
| Tyst mässa | Den första förmågan i varje strid är gratis (ingen Charge) | – (VAL) | ⚙S |
| Mörkt djup | Dimman glömmer rutor efter 6 steg, men troféchansen +10 enheter | – (VAL, `nya-grottor.md` E) | ⚙M, prova sist |

Varje tecken behöver en rad för makrona: ett tecken som makrona inte kan svara på blir bara brus
(`variation-i-strid.md` §9: allt makrona inte kan läsa gör att spelaren stänger av automatiken). Fullmåne och Ekande valv
läses redan av vanliga villkor; "Ett folk" läses av familjevillkoren.

**Kod:** tecknen kan bo i `floor_rules.json` med `"omen": true` och dras i `RunState.roll_rules()` vid sidan av
instabiliteten; effekterna går genom `CombatSim._rule()` som i dag. ⚙S för dragningen och visningen, sedan data eller ⚙S
per tecken. **Insats:** mekanismen en halv dag, 6 tecken en dag till, botmätning per tecken (`BALANS=grotta` med tvingat
tecken).

**Effekt:** varje nedstigning får en rubrik, och samma grupp spelas annorlunda under Fullmåne än under Helig mark. GISSNING:
störst effekt per timme näst efter bossarna, eftersom 10 tecken × 4 Realms × 3 bossar redan ger få upprepningar av hela
kombinationen. Risken är att tecknen känns som brus; därför få, tydliga och tvåsidiga.

## 4. Affix på elitgrupper och Nemesis från djup 3

**Siralim:** Nemesis-varningarna (Hearty, Thorns, Greedy, Brutal). Diablo och Path of Exile gör samma sak med "champion
packs". Förslag (**VAL**): från **djup 3** får varje elitgrupp och varje Nemesis **ett affix** (två från djup 7), dragit ur en
lista och visat på elitkortet med namn och en rad. Affixet sitter på gruppens ledare, aldrig på bossen. Det tar bara
befintliga egenskaper eller enkla siffror:

| Affix | Regel | Svar som makrona kan ge | Byggt på |
|---|---|---|---|
| Seglivad | Ledaren +80 % liv, −20 % Attack | utdragen skada, debuffar | stat_mult per fiende ⚙S |
| Taggig | 25 % av direkt skada mot ledaren studsar tillbaka | besvärjelser, indirekt | som `warden_thorns`, utan villkor |
| Spegel | Den som skadar ledaren med en besvärjelse tar 40 % tillbaka | attacker | `mirror_ward` |
| Väktare | Ledaren tar 30 % av skadan åt sina allierade | döda ledaren först | ⚙S (`guard_family` finns) |
| Snabb | +6 Speed, börjar överst | Försvara först, Snärjd | data |
| Läkande | Ledaren helas 8 % i början av sin tur | Trollhud-förmågor, burst | som `troll_moss` |
| Hämnande | När en allierad faller: ledaren +25 % skada (stapel) | döda ledaren först, eller alla samtidigt | ⚙S |
| Seg vilja | Resistent (om den inte redan är det) | skada i stället för debuffar | data |
| Girig | Inget extra; ger dubbla fynd och silver | – (en lockelse, Siralims Greedy) | ⚙S i `battle_won` |
| Skyddsbön | Ledaren börjar med en Barriär på 30 % av sitt liv | genomträngning, flera träffar | `start_auras` |

- Affixet visas som en tuschstämpel på kortet och i Inspect; tidslinjen visar ledaren med en ring. Kortet säger redan vilka
  egenskaper gruppen har; affixet blir en rad till.
- Högst ett affix som straffar samma sak som gruppens motdrag (t.ex. inte Spegel ihop med Dimmans tyngd). En lista i datan
  (`excludes`).
- **Ingen trofé från affixet** (VAL: troféerna hör till monstren). Undantag: Girig ger bättre byte.

**Kod:** `data/affixes.json`, dragningen i `Grotto.generate` (sparas i rutan, så kortet och striden visar samma), applicering i
`CombatSim.create` via `opts.affix` (lägger egenskapen på ledaren eller ändrar dess stats), visning på elitkortet. ⚙S–M,
1–1,5 dag med botmätning (`BALANS=elitgrupper` med affix).

**Effekt:** 6–7 elitgrupper × 10 affix = 70 olika elitfrågor per Realm, och Nemesis blir aldrig samma två gånger i rad.
GISSNING: störst effekt för den som spelar djup 3+, alltså just den som börjar känna upprepningen. Risk: fienderna blir
"svårare" igen snarare än annorlunda; därför väljs affix som byter svar, inte bara höjer siffror (Seglivad är det enda rena
sifferaffixet och kan strykas).

## 5. Specialvåningar och händelser mellan våningarna

`nya-grottor.md` E har redan **recept** för våningar: Skattvåning (golem som flyr), Väktarsalen (tre synliga elitgrupper,
välj två), Mörk våning. Föremålen per Realm (`objects.json`) och världshändelserna (`world_events.json`) finns redan.
Förslag i den här ordningen:

1. **Väktarsalen som våning 1 ibland** (Siralim: mini-boss-rum, Nether Realm-dörr). 15 % från djup 2, alltid med Två Nemesis-
   tecknet. Den ställer ledstjärnans fråga i ren form: man ser tre elitgrupper med affix och väljer bygge vid lägerelden.
   Kräver receptet ⚙M (2 dagar), sedan 1 dag.
2. **Vandraren** (Siralim: Treasure Golem, Dumpling, NPC:er med önskemål): en sällsynt ruta med en person eller varelse som
   vill något: en pilgrim som vill bli eskorterad till trappan (strid om en grupp ser er), en gravrövare som säljer en karta
   över våningen, en Skattgolem som flyr efter 3 turer. ⚙S per vandrare (en gren i `use_object` eller en ny egenskap).
3. **Nether-dörren** (Siralim, från djup 21 i originalet; vi från djup 4): en dörr som leder till ett litet rum 4×4 med en
   överraskning ur en tabell: tre kistor (en mimic), en miniboss som tappar sin trofé direkt, en smed som höjer en artefakt
   en nivå gratis. Kräver receptet. ⚙M.
4. **Rykten före avfärd** (levande kartan): Sven vid porten säger vilken boss och vilket tecken som väntar ("De säger att
   klockan i kryptan ringer igen"). Data i `dialog.json`, ⚙S. Billigt och gör växlingen i §1 synlig innan man går.

**Effekt:** stor för känslan av att en nedstigning kan överraska, men dyrare än §1–4. GISSNING: värt det först när §1–4
finns, eftersom specialvåningarna annars fylls av samma grupper.

## 6. Hur mycket innehåll behövs för ~50 timmar?

**Antaganden (GISSNING):** en nedstigning tar 30–45 minuter; 50 timmar ≈ 75–100 nedstigningar. Upprepning märks när samma
*hela strid* (grupp + affix + tecken) kommer tillbaka ofta, och när samma boss möts mer än var tredje gång i en Realm.

| | I dag | Mål för 50 h (med §1–4) | Siralim (jämförelse) |
|---|---|---|---|
| Realms | 4 (2 med lärjungar och berättelse) | **6** | 30+ |
| Fiender per Realm | 9–16 | 15 (9 vanliga, 4 elit, 2 boss), som `0.27-fiender.md` | ~6 per ras, 1200 varelser |
| Bossar per Realm | 1 (+1 förvriden) | **3 i rotation + 1 förvriden** = 24 bossstrider | bossar bara på vissa djup |
| Vanliga grupper per Realm | 12–19 | 18 (6 per tier) + 2 per djupsteg | slumpad sammansättning |
| Elitgrupper per Realm | 4–8 | 10 (3 + 7) | Nemesis + mini-boss-rum |
| Affix | 0 | 10 | ~10 Nemesis-varningar |
| Tecken (Realm Properties) | 0 (10 våningsregler med instabilitet) | 10 tecken + 10 regler | ~50 properties |
| Specialvåningar | 0 | 3 recept + 3 vandrare | Nether Realm-dörrar, portaler |

Räkning (GISSNING): 6 Realms × 3 bossar × 10 tecken ger 180 olika bosskvällar; 10 elitgrupper × 10 affix × 10 tecken per
Realm gör att samma elitfråga nästan aldrig upprepas. Det är **kombinationen**, inte antalet fiender, som bär 50 timmar.
Det mesta av målet är data på fiender som redan finns. Nytt arbete som verkligen kostar är **två nya Realms** (modeller,
föremål, berättelse; `trollens-realm.md` och `chat-realm3-kallornas-tradgard.md` är påbörjade) och §5.

Djupväggen (taket vid djup 6–7, `djupvaggen.md`) hör ihop med detta: den som kör fast tränar på lägre djup. Där blir
upprepningen störst. Bossrotationen och tecknen gör att träningen på djup 4 inte är samma kväll som djup 5.

## 7. Sammanställning

| Förslag | Insats | Typ | Effekt på 10 nedstigningar (GISSNING) |
|---|---|---|---|
| 2a Fler elitgrupper på våning 1 | 1 dag, alla Realms | data | Hög: den näst mest upprepade striden försvinner |
| 2b Fler vanliga grupper | 1 dag | data | Medel: varje grupp ses 3 i stället för 6 gånger |
| 1 Bossar som växlar med djupet | 1 dag + 2–3 h per Realm | ⚙S + data | **Högst**: bossen är det man minns |
| 2d Elitvarianter oftare | 2 h | data + ⚙S | Låg–medel: fler glödande överraskningar |
| 4 Affix på elit och Nemesis | 1–1,5 dag | ⚙S–M | Hög från djup 3 |
| 3 Djupets tecken | 1,5 dag | ⚙S + data | Hög: varje nedstigning får en rubrik |
| 2c Grupper per djup | ½ dag | ⚙S + data | Medel: djupet ändrar något |
| 2e Blandade familjer | 1–2 dagar | ⚙S + data | Medel, kräver tre Realms i växling |
| 5 Specialvåningar, vandrare | 3–6 dagar | ⚙M | Hög känsla, dyrt; efter 1–4 |
| 6 Två nya Realms | veckor | stort | Hög, men långt fram |

## 8. Rekommenderat första steg

**"Varje Realm får tre vakter" = 2a + 1 (utan huvudbossens djupgrader) + Nemesis ur hela elitpoolen. Ca 2 dagar.**

1. Två nya elitgrupper på våning 1 per Realm (data, `BALANS=elitgrupper`).
2. Bosslistan i `realms.json` och `RunState.boss_for(realm, depth)`; bossflaggan läses från mötet (⚙S).
3. Två befordrade bossmöten per Realm av fiender som redan finns (Klockaren, Gravväckaren; Abbedissan, Inkvisitorn;
   Strypvävaren, Sömnvävaren + Slukaren; Brom, Trollmor). Inga nya modeller, inga nya egenskaper.
4. Nemesis dras ur båda våningarnas elitpool.
5. Botarna: vinst per boss på djup 1–6 (`BALANS=grotta` per boss), inom ±8 enheter från huvudbossen på samma djup.
6. Sven säger vem som vaktar djupet innan man går (en replik per boss, §5.4).

Varför först: det tar de två mest upprepade striderna (bossen, våning 1:s elit), det är nästan bara data på fiender som
finns, och det går att provspela på telefonen efter ett par kvällar. Affixen (§4) och tecknen (§3) är steg två, i den
ordningen: affixen bygger på samma kort och samma Nemesis.

**Mätbart (förslag):** i en botkörning med 10 nedstigningar till samma Realm ska ingen boss mötas mer än 4 gånger, ingen
elitgrupp mer än 3 och ingen vanlig grupp mer än 4 gånger. Ny räknare i `combat_bot.gd`: antal olika möten per 10 körningar.

## 9. Frågor till VD

1. **Bossen per körning:** ska huvudbossen bara komma på djup 1 och var tredje djup, med befordrade minibossar och eliter
   däremellan? Eller ska vi gå närmare Siralim (ingen boss på vanliga djup, utgången är målet, boss var femte djup)?
2. **Befordrade bossar och troféer:** ska en befordrad boss (t.ex. Klockaren som boss) ge en egen bosstrofé efter tre segrar,
   och räcker det med två segrar när bossarna växlar?
3. **Djupets tecken:** vill du ha en synlig regel per nedstigning som gäller båda sidor (Fullmåne, Helig mark …), utöver
   instabiliteten? Ska den gå att slumpa om vid porten för silver, som i Siralim?
4. **Affix från djup 3:** ska elitgrupper och Nemesis få ett affix med varningstext (Seglivad, Taggig, Girig …), och ska
   affixen bara byta svar (ingen ren "mer liv")?
5. **Blandade familjer:** ska den levande kartan sprida en familj in i grannrealmen (blandgrupper som Benspringare +
   Snärjspindel), eller ska varje Realm hålla sina familjer rena som i Siralim utan instabilitet?
