# Siralim Ultimate – research för De edsvurna

Sammanställt 2026-10-18 av Researchtråden. Kompletterar [`docs/ideer/siralim_makron.md`](../ideer/siralim_makron.md)
(makron) och upprepar inte den, utom nya fynd i avsnitt 9.

Säkerhetsgrad: **Bekräftat** = spelets egen Codex-text eller wikin, **Troligt** = flera spelare säger samma
sak, **Okänt** = inte belagt. Codex-texten kommer från Steam-guiden *Codex Reference* (se Källor), som
återger spelets inbyggda Codex.

## Kort: det viktigaste för oss

1. **Timeline (tidslinjen) är inte rundor.** I Siralim bestämmer Speed bara *startplatsen*. Den som har agerat
   läggs längst ned och kön roterar. Effekter flyttar figurer till toppen eller botten. Vi sorterar varje
   runda på snabbhet, så det här är den största skillnaden i stridsreglerna. (Avsnitt 1)
2. **Charges (laddningar) räcker hela utflykten.** Spell Gems laddas om först vid nästa Realm, inte efter varje
   strid. Varje figur har upp till 3 spells. Det ger både makrona riktiga val och en resurs att
   hushålla med genom kryptloopen. (Avsnitt 3)
3. **Tre Trait Slots (egenskapsplatser) stämmer med Siralim.** Varje varelse har eget trait + Fusion-trait
   + Artifactens Trait Slot (+ Nether Stone sent i spelet). Våra *egen + trofé + Artifact* är samma
   modell. Siralim har till och med troféer: efter att ha slagit en Master 3 gånger får man dess
   trait som material. (Avsnitt 4)
4. **Artifactens typ avgör när den slår till.** Svärd ger chans vid Anfall, sköld vid Defend, hjälm vid
   Provoke, stövlar vid turens början. Det är en billig regelbrytare som passar våra tre handlingar
   perfekt. (Avsnitt 5)
5. **Siralim har en Paladin-Specialization**, byggd på *Retribution*: den som tar skada slår tillbaka.
   Hämndens ed ligger rätt. Dess perks är en färdig idébank för fler Eder. (Avsnitt 6)
6. **Det spelare älskar är teoribygge och synergi. Det de klagar på är menyer, grind och att det är
   överväldigande.** Mobilversionen kritiseras för en virtuell handkontroll i stället för riktig touch.
   Där kan vi vara bättre. (Avsnitt 8)

---

## 1. Timeline och turordning

| Regel | Säkerhet |
|---|---|
| Timeline visar ordningen. Figuren överst agerar och läggs sedan **längst ned**. | Bekräftat (Codex) |
| Speed avgör **startplatsen** på Timeline, inte ordningen varje runda. | Bekräftat (Codex) |
| Speed ger också chans att undvika, samt chans till och storlek på kritisk träff, mot målets Speed. | Bekräftat |
| Kritisk skada har avtagande effekt: +200 % vid 3× målets Speed, cirka +450 % vid 27×. Krit-bonusar adderas. | Bekräftat (wiki) |
| "Top of Timeline"-effekter skickar den som står överst till botten. Används de på egna kan man förlora turer. | Bekräftat (wiki) |
| Flyttas en figur till toppen nollställs dess gränser per tur (se avsnitt 2). | Bekräftat |
| En boss som skulle tvingas till botten flyttas bara ned **ett** steg. | Bekräftat (Codex) |
| Exempel på regelbrytare: Mimic, trait *Surprise!*: börjar alltid striden överst. Spelare bygger hela lag kring att agera först. | Bekräftat / Troligt |
| Ordningen vid lika Speed skiljer sig mellan plattformar (PC 1/5/4/3/2/6). | Bekräftat (wiki), oviktigt för oss |

**För oss:** Byt `_round_order()` mot en roterande kö: sortera på Speed en gång vid start, och lägg den som
agerat sist. Då fungerar effekter som "till toppen" och "till botten", och Speed får fler uppgifter än
ordningen. "Runda" finns inte i Siralim. Varaktigheter räknas redan i ägarens turer hos oss, så det
passar. Fiendernas avsikter behöver ett nytt ögonblick: visa avsikten i slutet av fiendens tur (så gör
Siralims boss Nerlyx, som "låser på" ett mål i slutet av sin tur och slår till i början av nästa).

## 2. Strid: handlingar, skada och Action Limits

### Handlingar

| Handling | Effekt | Säkerhet |
|---|---|---|
| Attack | Skada efter Attack mot Defense. Kan bli kritisk och kan undvikas. | Bekräftat |
| Cast | Spell från en Spell Gem, kostar 1 Charge. | Bekräftat |
| Defend | Tar 35 % mindre skada och har 50 % mer Defense. | Bekräftat |
| Provoke | 100 % chans att väljas som mål för fiendens anfall och spells, men 35 % mindre Defense. | Bekräftat |
| Inspect, History | Gratis, kostar ingen tur. Inspect visar fiendens stats, traits, Artifact, gems, buffar, debuffar och minions. | Bekräftat |

Det finns ingen fast avsiktsvisning hos vanliga fiender. Bara boss-traits visar vad som kommer
(Nerlyx ovan, *The Ancestor* dödar alla som inte försvarar sig). Vår avsiktsvisning är alltså ett
tillägg. Den gör bossdesign som "försvara dig nu" läsbar.

### Skada

- **Attack:** `(max(Attack − Defense, 0) + 1 % av Attack) × modifierare + tillägg`. Bekräftat.
- **Spell:** `max(Potens − Defense, 0) × modifierare + tillägg`. Potensen är en andel av
  Intelligence enligt beskrivningens ord, och starkare spells går igenom en del av Defense:

  | Ord | Skada (% Int / % Defense ignoreras) | Helning (% Int) | Stats (% Int) |
  |---|---|---|---|
  | Small | 90 / 0 | 30 | 20 |
  | Moderate | 110 / 10 | 60 | 40 |
  | Large | 120 / 20 | 90 | 60 |
  | Massive | 130 / 30 | 120 | 80 |
  | Devastating | 150 / 40 | – | – |

  Spells på hela laget får −75 % efter Defense (studsande undantagna). Bekräftat (wiki/Codex).
- **Indirekt skada** (DoT, minions, traits): kan inte bli kritisk eller undvikas, bara 20 % av Defense
  räknas. Bekräftat.
- **Procentökningar adderas** (+75 % och +75 % = +150 %). **Minskningar multipliceras** (60 % och 50 % =
  80 %). Varje källa till minskad skada stannar vid 80 %. Bekräftat.
- "Tillägg" (additional damage) går förbi Defense och all minskning. Bekräftat.

### Gränser (skyddar mot oändliga kedjor)

| Gräns | Normal | Calm Mode |
|---|---|---|
| Attack, cast, få buff/debuff/minion, ta skada, bli helad, per figur och tur | 15 | 5 |
| Återupplivningar per figur och strid | 10 | 5 |
| Traits en figur kan få under striden | 10 | 3 |

- "Efter att figuren anfaller"-effekter utlöses bara om anfallet gjorde skada på liv. Undvikna anfall och
  träffar på Barrier/Shelled räknas inte. Bekräftat.
- Allt som händer efter en handling räknas ut samtidigt, men visas ett i taget. Bekräftat (Codex). Så gör
  `battle.gd` redan med trait-kedjor.
- Stats kan inte sjunka under 20 % av startvärdet. Ökningar avtar efter 500 % av basvärdet. Bekräftat.

**För oss:** *Calm Mode* är Siralims eget svar på för långa kedjor. Det passar mobil: visa kedjor steg
för steg men med lägre tak. Vår gräns på 4 steg ligger nära Calm Mode.

### I början av striden (ordning)

1. Traits ges och delas. 2. Ras och klass ändras. 3. Spell Gems ges. 4. Buffar, debuffar och minions
ges. 5. Stats ökar. 6. Stats minskar. 7. Striden börjar (först nu utlöses "när buff"-effekter).
8. Figurer anfaller. 9. Figurer kastar spells. Bekräftat (Codex).

## 3. Spells (Spell Gems)

| Regel | Säkerhet |
|---|---|
| Upp till **3 Spell Gems** per figur, aldrig två av samma, bara figurens egen klass. Traits, perks och gem-properties kan ändra gränserna. | Bekräftat |
| Varje cast kostar **1 Charge**. Slut på Charges = går inte att kasta, varken manuellt eller automatiskt. | Bekräftat |
| Charges fylls på **först vid start av nästa Realm**, inte efter striden. | Bekräftat (Codex) |
| *Manuell* cast = vald i menyn eller via makro. *Automatisk* = utlöst av trait, perk eller annan spell. Extra casts från en manuell cast räknas som manuella. | Bekräftat |
| Silenced: kan inte kasta. Sealed låser en enskild gem. | Bekräftat |
| *Ethereal* gems: får man under striden, färre Charges, försvinner efteråt. | Bekräftat |
| Arcane-buffen: nästa cast kostar ingen Charge. | Bekräftat |
| Särskilda sorter: *Prism* kan inte kastas manuellt men kan utlösas efter en annan cast. *Booze* utlöses slumpvis efter händelser. *Arsenal* samspelar med vissa traits. | Bekräftat |
| Gem-properties (enchantments) ändrar regeln: *Cascading* starkare för varje saknad Charge, *Magnetic* starkare per matchande gem, *Singular* starkare per tom plats, *Generous* ger lagkamraterna en kopia med 1 Charge. | Bekräftat |

**För oss:** Ge varje hjälte 2–3 förmågor med Charges som räcker hela kryptturen och fylls på vid
lägret. Då får makrona riktiga val ("har Charges kvar"?), och spelaren måste hushålla mellan
striderna. Anfall och Defend kostar ingenting, så det finns alltid något att göra. Gem-properties som
*Cascading* och *Generous* är regelbrytare av precis den sort ledstjärnan efterfrågar.

## 4. Traits, fusion och troféer

| Regel | Säkerhet |
|---|---|
| Varje varelse har ett eget, unikt trait. | Bekräftat |
| Fusion: avkomman ärver **båda** föräldrarnas traits och genomsnittet av deras basstats, och får den andra förälderns klass. Utseende från den första, färger från den andra. | Bekräftat (Codex) |
| Artifactens Trait Slot ger ytterligare ett trait. Bara en per Artifact. Materialen är mycket sällsynta. | Bekräftat |
| Nether Stones (sent i spelet) kan ge flera traits samtidigt. | Bekräftat |
| Ett trait staplas inte med sig själv. "Does not stack" betyder: ha bara en i laget. | Bekräftat |
| Traits utlöses från vänster till höger efter plats i laget. | Troligt (wiki-guide) |
| **Masters:** efter att ha slagit en rasmästare 3 gånger får man en Trait Material för mästarens unika trait. | Bekräftat (Codex) |

**För oss:** Vår modell *egen + trofé + Artifact* motsvarar *egen + fusion + Artifact*. Troféer i stället
för fusion har stöd i Siralim självt (Masters). En sak att ta med: en trofé ska helst vara något man inte
kan få på annat sätt, och samma trofé på två hjältar ska inte stapla.

## 5. Artifacts

| Regel | Säkerhet |
|---|---|
| **En Artifact per figur.** Fem typer: svärd, stav, sköld, stövlar, hjälm. Varje typ höjer en stat. | Bekräftat |
| Tillverkas hos smeden för Brimstone, hittas inte som byte. Uppgraderas från nivå 1 till 50. | Bekräftat |
| Nya platser vid nivå: 3 stat, 5 trick, 10 stat, 15 trait, 25 trick, 35 stat, 50 Spell Gem, därefter Nether Stone. | Bekräftat (wiki) |
| Trick-platser: buffar/debuffar vid skada, klasstyrka, krit, minskad skada, undvikande, fler gem-platser, potens. | Bekräftat |
| **Spell Gem i Artifact utlöses av handlingen:** svärd vid Anfall (25 %), stav vid Cast (25 %), sköld vid Defend (50 %), hjälm vid Provoke (50 %), stövlar vid turens början (15 %). Gemmets properties ignoreras. | Bekräftat |
| Tar man ut ett material förstörs det (utom Nether Stones). | Bekräftat |

**För oss:** "Artifactens typ = när den slår till" är lätt att bygga i vår trait-motor (`trigger` +
`chance`) och ger Defend och Provoke egna anledningar. En sköld som kastar Helande ljus när
Brokk försvarar sig är en kombination spelaren kan upptäcka själv. Nivåer och material kan vänta.

## 6. Specializations → våra Eder

Siralims spelare strider inte själv. Hen påverkar laget med en Specialization: en enda idé som gäller
hela laget. Bekräftat (Codex). 40 Specializations, perks köps för Perk Points och kan återställas
gratis. Efter att ha besegrat falska gudar kan man låna perks från andra Specializations
(*Anointments*).

### Siralims Paladin (bekräftat, wiki)

Kärnan är **Retribution**: när en figur tar skada från anfall eller spell slår den tillbaka
(upp till 25 % av skadan).

| Perk | Effekt | Motsvarighet hos oss |
|---|---|---|
| Retribution | Slår tillbaka för 25 % av skadan man tar | Hämndens ed |
| Zeal / Wrath | +50 % Retribution vid Provoke / Defend | – |
| Unbound | Efter Provoke: Defend också | Utmanarens ed gör redan detta |
| Reckoning | Efter Provoke: anfall en slumpvis fiende | – |
| Perseverance / Light's Augmentation | Provoke: −50 % skada / +75 % Defense | – |
| Miraculous Recovery | Efter Provoke: hela 50 % liv | – |
| Hand of Light | Efter Retribution: alla helas 20 % av skadan | – |
| Glory | Efter Retribution: lägsta stat ökar | – |
| Crusade | Extra skada = 100 % av Retribution hittills i striden | – |
| Execution Sentence | Vid död: skada alla fiender med Retribution hittills | – |
| Divine Intervention | Första dödliga träffen lämnar 1 liv | – |
| Seraphim | 50 % av Defense läggs på liv vid start | – |
| Divine Toll | Efter Retribution: kasta Holy Smite | Paladinens signatur heter redan Holy Smite |

Wikins råd: låt fienden slå först, tvinga fram anfall, och välj figurer med mycket liv och låg Defense.

### Andra Specializations som passar en paladin

- **Cleric** (helning och buffar) → *Gryningens ed*.
- **Siegemaster** (Defense via buffar, Provoke blir Defend, törnen som skalar med Defense) → *Väktarens ed*.
- **Warden** (de flesta händelser buffar laget), **Inquisitor** (motangrepp, lojalitet, döda allierade),
  **Monk** (undvika och kontra), **Graveborn** (allierade blir starkare när de dör).

Varje Specialization har *en* resurs eller ett tema (Pyromancer: Burning, Engineer: Bomb, Reaver: långa
strider). Det är en bra regel för våra Eder: en Ed = en idé som ändrar hur alla i sällskapet spelar.

## 7. Buffar, debuffar och minions

Standardvaraktighet är oftast **3 turer**. Läggs samma buff på igen förnyas varaktigheten. Barriers
staplas inte, den starkaste gäller. Bekräftat (wiki).

**Buffar:** Agile (extra undvikande), Arcane (nästa cast gratis), Barrier (absorberar), Berserk (+50 %
skada), Defensive (försvarar automatiskt i slutet av turen), Immune, Invisible, Leeching (helas 25 % av
skadan), Mending (25 % liv vid turstart), Protected (−50 % skada), Rebirth (återuppstår med 50 %),
Repelling, Savage (extra krit), Shelled (nästa träff upphävs), Splashing, Taunting (provocerar
automatiskt), Warded (kan inte förlora stats).

**Debuffar:** Bleeding (30 % av nuvarande liv per tur), Blighted (helning skadar), Blind, Bomb, Burning
(30 % av angriparens Int), Confused, Cursed (angriparen tar skada), Disarmed (förlorar Artifactens
stats), Feared, Frozen, Poisoned (30 % av angriparens Attack), Scorned (kan inte anfalla), Silenced (kan
inte kasta), Sleeping, Snared (fast längst ned på Timeline), Stone, Vulnerable (+50 % skada),
Weak (−50 % skada). Bossar är ofta *Resistant*: effekten halveras eller bryts lättare.

**Minions:** staplar som gör indirekt skada vid en viss händelse (t.ex. Dire Wolves efter herrens anfall,
Spiderlings när herren tar skada). De går inte ut efter tid utan har 25 % chans att lämna vid herrens
turstart. Bekräftat (wiki).

**För oss:** Det här är en färdig katalog att välja ur. Defensive och Taunting ("gör X automatiskt i slutet
av turen") och Snared (påverkar Timeline) blir viktiga när vi byter till Siralims Timeline.

## 8. Vad gör Siralim roligt, och vad klagar spelarna på?

**Positivt** (antal omnämnanden i Steam-recensioner enligt Vaporlens): samlande 44, variation 33, djup
33, teoribygge och anpassning 32, omspelbarhet 32, turbaserad taktik 23, synergi och lagbygge 21.

Guider beskriver lagbygget som en loop: hitta en idé → skissa ett lag → lös det största problemet →
testa 10–20 Realms → förstå varför det föll → ändra. "Det perfekta laget finns inte", eftersom Realm
Instability och slumpade Realm-traits ändrar förutsättningarna. Spelare berättar om kombinationer som
"Mimic + Wisp Watcher: laget börjar överst och vinner innan fienden agerar".

**Negativt:** dåliga menyer och UI 20, översättning 19, grind 19, repetitiv loop 17, sparproblem 16,
svag berättelse 15. Recensenter säger också att nya spelare blir överväldigade av antalet val.
Mobilversionen har högt betyg (Google Play 4,3, App Store ~4,7), men kritiseras för klumpig styrning
med virtuell handkontroll och daterat gränssnitt.

**För oss:** Våra skillnader tar itu med kritiken: få men regelbrytande delar (mot överväldigandet), en
förklaringslogg (mot "varför hände det där?"), och riktig touch (mot mobilkritiken). Grinden (Charges,
Brimstone, nivåer) är inte det som gör spelet roligt och kan hållas liten.

## 9. Macros (makron): nya fynd

Komplement till `docs/ideer/siralim_makron.md`. Fynden kommer från Siralim 3-forum och gäller kanske
inte Ultimate.

| Fynd | Säkerhet |
|---|---|
| Fler villkor som funnits: `has the highest Speed`, `has the lowest Defense`, `is <klass>` (t.ex. Death), `has <debuff>` (t.ex. Scorn), `is alive`, villkor på **turnummer** ("på tur 1"). | Troligt (S3, spelare) |
| "lowest"/"highest" jämför **alla 12 figurer** på slagfältet, inte bara den egna sidan. "Om någon fiende har lägst liv" misslyckas alltså om en allierad har lägst. | Troligt (S3, moderator) |
| "If any enemy" ska ha varit buggigt i S3. En spelare säger att fienderna prövas i ordningen 5, 4, 6, 2, 1, 3 och att den första som matchar väljs. Lösningen var en rad per fiendeplats. | Troligt (S3, en spelare) |
| Inget villkor för "provocerar redan" fanns i S3. Spelare bad om det. | Troligt |
| Makron tar inte över manuella val. Standardhandlingen kan sättas till Macro och körs då när man håller Q/E i turboläge. | Troligt (SU, spelare) |
| Codex nämner bara ett exempel på mål: "cast Healing on that creature" och "attack a random enemy". | Bekräftat |
| Om test next line minns figuren: fortfarande **Okänt**. | Okänt |

**För oss:** Villkoret "har Charges kvar" och "har inte <buff>" (t.ex. provocerar redan) fattades i
Siralim och är värda att lägga till. "Lägst/högst" bör jämföra inom gruppen i raden, inte alla 12. Det
är en avvikelse, men originalets beteende ser ut som en bugg.

### 9b. De okända makroreglerna: andra genomgången

Undersökt på huvudtrådens begäran. Ingen av frågorna har ett officiellt svar. Utvecklarna har inte
svarat i någon tråd vi hittat. Det bästa som finns är spelare i Ultimate (SU) och Siralim 3 (S3).

| Fråga | Vad källorna säger | Säkerhet |
|---|---|---|
| **Mål för attack…** | S3: tre mål, *attack that enemy*, *attack a random enemy*, *attack a random ally*. Codex (SU): *attack a random enemy* och *cast Healing on that creature*. | Troligt |
| **Vem blir "that creature" vid flera träffar på "any"** | S3: en spelare säger att fiendeplatserna prövas i ordningen 5, 4, 6, 2, 1, 3 och att den första som matchar väljs. En annan frågade om "that enemy" slumpas, men fick inget svar. Spelare skriver hellre en rad per plats (`If ally (N)`) när målet spelar roll. | Okänt (en källa, S3) |
| **Minns test next line figuren** | SU: en spelare säger att kedjan fungerade. En annan läser den som två *oberoende* kontroller, där den andra raden väljer sin egen figur. Ingen har testat det ordentligt. | Okänt, lutar åt "minns inte" |
| **Cast som inte går** (tystad, gem saknas, Ethereal gem bytt av Luck's Gambit) | SU: spelare lägger en sista "fånga allt"-rad (*defend*) "ifall man blir silenced/scorned". Det tyder på att en rad vars handling inte går att utföra räknas som inte matchad och att prövningen fortsätter nedåt. När ett Ethereal gem bytts ut kan raden inte kastas. | Troligt |
| **Ingen rad passar** | Två oberoende SU-trådar citerar spelets meddelande: *no macro that meet the requirements*. Ingen handling utförs automatiskt, och spelaren väljer själv. | Troligt (uppgraderat) |
| **Ett makro på flera figurer** | S3: spelare delar ett makro mellan flera Hounds och kopierar makron mellan platser. SU: tilldelning per figur, och det finns inget "makro för hela laget" vid stridens start. | Troligt |
| **Makron vid Fusion** | En sammansmält varelse ärver den första förälderns *strategy* och makro (patch 0.12.0). Varelser har alltså också en "strategy"-inställning, troligen standardhandlingen. | Bekräftat (patchnot) |
| **Vilka spells går att välja** | Sedan 2.0: alla spells i spelet utom de som inte kan kastas manuellt (Prism, Booze …). Tidigare bara spells man ägde, så spells som traits gav vid stridens start gick inte att lägga in. | Bekräftat (patchnot) |
| **Import/export av makron** | Togs bort i 0.11 eftersom spelare handredigerade filerna och förstörde sina sparfiler. | Bekräftat (patchnot) |

**Fler villkor** som spelare använder i SU: `doesn't have <buff/debuff>` (Barrier finns i listan),
`is highest on Timeline` (en spelare säger att det fungerar). Det stämmer med 1.1.1-tillägget
`Is Not At Top/Bottom of Timeline`. Villkoren från S3 (`has the highest Speed`, `has the lowest
Defense`, `is <class>`, `is alive`, turnummer) är inte belagda i SU. **En fullständig lista över
villkoren i Ultimate finns inte publicerad.**

**En motsägelse i skärmdumpen:** i Macro Editor (2024) visar villkorskolumnen för `If any ally` bara
`has < 10%`–`has < 90% Health`, fast det finns plats för fler rader. Villkoren från 1.1.1 och 2.0 syns
inte. Antingen beror villkorslistan på subjektet, eller så rullar kolumnen. Det går inte att avgöra
från bilden.

**Förslag till standardregler för oss** (tills någon testar i spelet):

1. "any" med flera träffar: ta den första i platsordning (sällskapets ordning, fiende 1–6). Förutsägbart
   och lätt att förklara i loggen. Siralims ordning 5, 4, 6, 2, 1, 3 ser ut som en bugg.
2. test next line *minns* figuren som matchade, så att "någon allierad utan Blighted **och** under 30 %"
   betyder samma allierade. Är originalet annorlunda gör det kedjan nästan oanvändbar, och spelarna
   behandlar den som om den minns.
3. En rad vars handling inte går att utföra (cast utan Charges, tystad, Scorned, inget giltigt mål)
   räknas som *inte matchad* och prövningen går vidare. Loggen säger varför: "rad 2 hoppades över:
   Helande ljus har inga Charges kvar".
4. Ingen rad passar: hjälten stannar och väntar på spelaren, med texten "Inget makro passade". Auto
   pausar.
5. Ett makro kan tilldelas flera hjältar. "this creature" betyder den som kör makrot.

## 10. Senare: Realms och progression

Kort, eftersom det kommer efter kryptloopen.

- Realms är slumpade dungeons med en gud var. Man väljer **Realm Depth**: djupare = starkare fiender och
  bättre byte. Varje Realm ger en kort **Realm Quest** som måste klaras innan man åker hem. Den är enda
  källan till Perk Points. Bekräftat.
- **Fortune:** +20 % resurser per klarad Realm Quest, upp till 100 %, nollställs om laget dör. Förlust
  kostar annars bara Fortune och questen. Bekräftat.
- **Realm Instability** 0–5: varelser från andra Realms, sammansmälta fiender och två slumpade
  Realm-traits per nivå (en synlig, en dold), t.ex. "Can't Dodge" eller "fiender återuppstår".
  Ger mer byte. Bekräftat.
- **Nether Bosses** var femte djupnivå efter berättelsen. Var och en har en regelbrytande trait i tre
  nivåer (t.ex. *Myrtle*: immun mot skada så länge hennes allierade lever). **False Gods** har flera
  kroppsdelar med egna traits (huvudet provocerar, hjärtat kan bara skadas när resten är försvagat).
  Bekräftat (Codex).
- Fiender skalar snabbare än ens egna nivåer. Svaret är nya traits, inte grind. Bekräftat (FAQ).

**För oss:** "Realm-traits" är ett bra sätt att variera kryptstriderna utan nytt innehåll: en synlig
regel per våning ("fiender återuppstår en gång"). Bossar med en regelbrytande trait och läsbar avsikt
passar vår avsiktsvisning.

## 10b. Död: Siralim jämfört med oss

**I striden (Siralim Ultimate):**

| Regel | Säkerhet |
|---|---|
| En död figur förlorar buffar, minions och stat-ändringar. Stats återställs till basvärdet. | Bekräftat (wiki Combat; Purgatorian-perks som "Destiny Bond" och "Never Forgotten" finns just för att ändra det) |
| En död figurs traits slutar verka. Perken *Life After Death* (Purgatorian) gör dem aktiva även efter döden. | Troligt (härlett ur perk-texten) |
| Återupplivning sker bara via traits, spells eller buffar: *Rebirth* (50 % liv), *Afterlife* (full hälsa första gången), spells som Reincarnation. Högst 10 återupplivningar per figur och strid (Calm Mode: 5). | Bekräftat |
| Det finns hela byggen kring död: Animator, Graveborn ("allierade blir starkare när de dör"), Purgatorian (fler attacker per död allierad), Paladins *Execution Sentence* (skada alla fiender vid död). | Bekräftat (wiki) |
| Realm Properties kan ändra döden: *Can't Resurrect* (era figurer kan inte återupplivas), *Resurrect on Death* (fiender återuppstår en gång med 25 %). | Bekräftat (Codex) |
| Bossar dör inte av "instant kill". De tar i stället 20 % av sitt saknade liv. | Bekräftat (Codex) |

**Efter striden:**

| Regel | Säkerhet |
|---|---|
| Ingen permanent död. Man förlorar aldrig en varelse. | Troligt (Siralim 2-spelare; inget i SU tyder på motsatsen) |
| Liv återställs och döda figurer kommer tillbaka efter varje strid, vunnen eller förlorad. Det man bär med sig mellan striderna är Spell Gem-Charges, som fylls först vid nästa Realm. | Troligt (Siralim 2-spelare; inte belagt för SU) |
| Dör hela laget skickas man hem till slottet. Fortune nollställs och Realm Quest-framsteget går förlorat. Varelser, föremål och resurser behålls. | Bekräftat (Codex, wiki) |

**Hos oss i dag (koden):**

- I striden försvinner en död hjältes auror och glöd, och hen tas bort ur tidslinjen. Hens traits slutar
  verka (`_emit` hoppar över ägare som inte lever). Det motsvarar Siralim. *Väck de döda* (60 % liv) och
  Rebirth-liknande effekter fungerar.
- Striden förloras bara om **alla** hjältar dör. Paladinen kan dö utan att striden tar slut.
- Mellan våningarna börjar varje strid med fullt liv. En död följeslagare är alltså tillbaka vid nästa
  strid, precis som i Siralim. Bara Charges följer med genom körningen.
- Förlorar man striden går man till startskärmen och körningen är slut. Troféer man hittat finns kvar i
  samlingen. Det är strängare än Siralim, där man bara förlorar Fortune och Realm Quest-framsteget.

**Frågor att besluta:**

1. Ska Paladinens död betyda något mer? Hen är Edens bärare. I Siralim strider spelaren aldrig och kan
   inte dö. Alternativ: Eden slutar verka när Paladinen dör (som traits hos döda), eller ingen skillnad.
2. Ska en förlust kosta hela körningen (roguelike) eller bara framsteg, som i Siralim? Det andra passar
   ledstjärnan om att våga prova nya kombinationer.
3. Död som resurs: traits och Eder som utlöses av död (som *Execution Sentence* eller Graveborn) är
   Siralim-typiska regelbrytare och fungerar redan i motorn (`death`-händelsen).

## 11. Till ordlistan (`docs/ordlista.md`)

Rättelser:

- **Trofé ↔ Fusion** stämmer bara delvis. Fusion ger *båda* föräldrarnas traits, genomsnittliga
  basstats och den andra förälderns klass. Vår trofé ger ett trait från ett besegrat monster och
  inget annat. Det motsvarar närmast **Trait Material** (sätts i Artifactens Trait Slot), särskilt
  Masters, som ger sitt trait som Trait Material efter tre segrar. Förslag: *Trofé ↔ Trait Material
  (Masters); fyller den plats som Fusion har.*
- **Runda:** "samma ordning så länge snabbheten inte ändras" stämmer inte helt. Speed bestämmer bara
  startplatsen. Ändras Speed under striden sorteras inget om. Ordningen ändras bara av effekter som
  flyttar till toppen eller botten (t.ex. Snared, "Top of Timeline"-effekter).
- **Försvara ↔ Defend:** Siralim ger också +50 % Defense, inte bara −35 % skada.
- **Paladinen ↔ Siralim Mage:** Siralims spelare strider aldrig själv, och Specialization verkar genom
  perks. Det är en medveten avvikelse hos oss, värd en rad i kommentaren.
- **Kvitto ↔ Battle History:** Battle History är en kronologisk händelselista utan förklaringar.
  Kvittot och makroförklaringen är våra tillägg.

Saknas:

| Siralim | Betydelse | Förslag hos oss |
|---|---|---|
| Charges | användningar per Spell Gem, fylls vid nästa Realm | laddningar (krockar med vår charge/release – välj annat kodnamn för den ena) |
| Spell Gem, Ethereal Spell Gem | besvärjelse; tillfällig under striden | förmåga |
| Manual / Automatic cast | vald av spelaren eller makro / utlöst av trait | |
| Potency | styrka i % av Int (Small–Devastating) | |
| Additional damage | går förbi Defense och minskningar | |
| Top / Bottom of Timeline | flytta i turordningen | |
| Calm Mode | lägre Action Limits (5/tur, 3 traits) | vår gräns 5 |
| Resistant | boss tar halv effekt av debuffar | |
| Retribution | Paladins kärna: slå tillbaka vid skada | Hämndens ed |
| Perk, Anointment | förmån i en Specialization; lånad perk | |
| Trait Slot, Trait Material, Nether Stone | Artifactens trait-plats och dess material | trofé |
| Master | rasmästare med unikt trait | |
| Realm Quest, Realm Properties, Realm Instability, Fortune | se avsnitt 10 | våningsregler |
| Nether Boss, False God | bossar med regelbrytande traits; flera kroppsdelar | |
| Minion | staplar som gör Indirect Damage | |
| Inspect | gratis titt på fiendens allt | |
| Default action, Turbo | standardhandling, håll Q/E för att köra den | Auto |

---

## Källor

- [Siralim Ultimate Wiki: Combat](https://siralimultimate.wiki.gg/wiki/Combat), [Paladin](https://siralimultimate.wiki.gg/wiki/Paladin),
  [Specializations](https://siralimultimate.wiki.gg/wiki/Specializations), [Artifacts](https://siralimultimate.wiki.gg/wiki/Artifacts),
  [Spell Gems](https://siralimultimate.wiki.gg/wiki/Spell_Gems), [Buffs](https://siralimultimate.wiki.gg/wiki/Buffs),
  [Debuffs](https://siralimultimate.wiki.gg/wiki/Debuffs), [Minions](https://siralimultimate.wiki.gg/wiki/Minions),
  [Realms](https://siralimultimate.wiki.gg/wiki/Realms), [Cards](https://siralimultimate.wiki.gg/wiki/Cards),
  [Mimic](https://siralimultimate.wiki.gg/wiki/Mimic), [Siralim Ultimate](https://siralimultimate.wiki.gg/wiki/Siralim_Ultimate),
  [FAQ](https://siralimultimate.wiki.gg/wiki/Frequently_asked_questions), [Starter guide](https://siralimultimate.wiki.gg/wiki/Starter_guide)
- [Codex Reference (Steam-guide med spelets Codex)](https://steamcommunity.com/sharedfiles/filedetails/?id=2197484456)
- [How to Make a Build (guide)](https://gamepretty.com/siralim-ultimate-how-to-make-a-build-step-by-step-guide/)
- [Vaporlens: sammanfattning av Steam-recensioner](https://vaporlens.app/app/1289810/siralim_ultimate)
- [Steam: Macro Conditions Question](https://steamcommunity.com/app/1289810/discussions/0/4702413966613159824/),
  [S3: Help with lowest health macro](https://steamcommunity.com/app/841770/discussions/0/1645418448928359291/),
  [S3: Persistent macro failure](https://steamcommunity.com/app/841770/discussions/1/1743357605567660231/),
  [S3: Macro Editing](https://steamcommunity.com/app/841770/discussions/0/2805074491030737945/)
- Makron, andra genomgången: [Patch 1.1.1](https://steamcommunity.com/games/1289810/announcements/detail/3360266558219008727),
  [Patch 0.11.X](https://steamdb.info/patchnotes/7248496/), [Patch 0.12.0](https://updatecrazy.com/siralim-ultimate-update-0-12-0-patch-notes-november-15-2021/),
  [2.0-patchnoter](https://www.thylacinestudios.com/blog/siralim-ultimate-2-0-patch-notes),
  [macros question](https://steamcommunity.com/app/1289810/discussions/0/3274688023496201083/),
  [how does the macro system work?](https://steamcommunity.com/app/1289810/discussions/0/3196988242386085605/),
  [I need help with a macro please.](https://steamcommunity.com/app/1289810/discussions/0/598521912287570539/),
  [macro export](https://steamcommunity.com/app/1289810/discussions/0/7155698768542809243),
  [S3: Macro question / suggestion](https://steamcommunity.com/app/841770/discussions/0/1734342161847424378/),
  [Something Awful-tråden](https://forums.somethingawful.com/showthread.php?threadid=3962134&userid=0&perpage=40&pagenumber=2),
  [skärmdump av Macro Editor](https://steamcommunity.com/sharedfiles/filedetails/?id=3356475192)
- [Steam-diskussion om fusion](https://steamcommunity.com/app/1289810/discussions/0/5767400709485797483),
  [Steam-diskussion om instability](https://steamcommunity.com/app/1289810/discussions/0/5710018482973776302)
- Mobilbetyg och styrning: [worldsapps](https://worldsapps.com/reviews-siralim-ultimate), [grand-screen](https://grand-screen.com/games/siralim-ultimate/reviews/)
