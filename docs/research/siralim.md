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

### 3b. Charges så nära Siralim som möjligt (användarens beslut 2026-10-18)

Användaren: Alva ska inte kunna hela obegränsat. Charges ska ligga "så nära Siralims regler som möjligt".

**Belagt i originalet:**

| Regel | Säkerhet |
|---|---|
| Ingen mana. Varje spell sitter i en Spell Gem med ett eget antal Charges, och 1 cast = 1 Charge. Slut på Charges betyder att varken manuell eller automatisk cast går. | Bekräftat |
| Charges fylls inte mellan striderna. Codex (version 2.0.37): "vid start av varje Realm". Wikin: "när man återvänder till slottet". | Bekräftat. Källorna skiljer sig. Hos oss betyder båda: vid en ny körning. |
| Starkare spells har färre Charges. Exempel: *Benediction* (helar alla, massive) 4, *Breath of Life* (helar en, massive, och väcker döda) 5, *Holy Armor* (Barrier, massive) 5, *Fireball* (moderate skada + Burning) 8. | Bekräftat (wikins spell-sidor) |
| Max 3 Spell Gems per figur. Attack, Defend och Provoke kostar ingenting. | Bekräftat |
| Ethereal gems (fått i striden) har 1 Charge. Avatarernas Ultimate Spell har 1 Charge som fylls efter varje strid. | Bekräftat |
| Sätt att få tillbaka Charges: buffen *Arcane* (nästa cast gratis), Siegemaster-perken *Rest Up* (+1 Charge efter Defend), spellen *Recharge*, gem-egenskapen *More Charges*, och *Cascading* som gör en gem starkare ju fler Charges som saknas. | Bekräftat (Recharge: spelare) |
| Helning begränsas också av debuffen Blighted, Realm-egenskapen "Less Healing" och Action Limits (helad högst 15 gånger per tur). | Bekräftat |

**Hos oss i dag:** Charges fylls vid en ny körning från basen. Det stämmer med originalet. Men talen är
3–5 gånger högre än Siralims: Helande ljus 24, Förnyelse 20, Helig smäll 16. Därför märks gränsen inte.

**Förslag: Siralims tal efter styrka.** Massive 4–5, large 6, moderate eller med bieffekt 8. Vårt val är
hur våra förmågor placeras på skalan.

| Förmåga | I dag | Förslag | Motivering (närmaste Siralim-spell) |
|---|---|---|---|
| Helande ljus (Alva, helar en, 300 %) | 24 | **5** | Breath of Life 5 |
| Förnyelse (Alva, helning över tid) | 20 | **6** | large |
| Ljusets dom (Alva, 150 % skada) | 12 | **8** | Fireball 8 |
| Helig smäll (Paladinen, 160 %) | 16 | **8** | moderate |
| Helig sköld (−40 % skada) | 12 | **5** | Holy Armor 5 |
| Stenmur (Brokk, hela sällskapet −25 %) | 12 | **5** | effekt på hela laget |
| Stridsrop (hela sällskapet +30 %) | 10 | **5** | effekt på hela laget |
| Jägarens märke (Eira) | 20 | **8** | moderate + debuff |
| Pilregn (alla fiender, 60 %) | 10 | **6** | flera mål |
| Eldvåg (alla fiender, 70 %) | 12 | **6** | flera mål |
| Eldklot (Solveig, 200 %) | 12 | **5** | massive |

Ingen påfyllning i lägret, precis som i originalet. Körningen motsvarar en Realm. Med tre strider
räcker Alvas 5 + 6 helningar till ungefär 3–4 per strid, och fler strider per körning gör det
snävare, som i Siralim.

Mekanikerna för att få tillbaka Charges hör hemma i Eder, troféer och artefakter. Exempel: *Rest Up* i
Väktarens ed (avsnitt 13), en Arcane-aura och gem-egenskaperna hos Runristaren. Kontrollera efteråt med
`tests/balance_report.gd`. Om AUTO hamnar under ~95 % ska stridernas svårighet sänkas, inte Charges
höjas.

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

## 10c. Basen: Siralims slott jämfört med vårt läger

**Vad slottet är (Codex, bekräftat):** "När du inte är ute i en Realm tillbringar du det mesta av tiden
i ditt slott." Där sköter man laget, ändrar föremål, spelar minispel och dekorerar. Det som finns där:

| Plats / NPC | Vad man gör | Hos oss |
|---|---|---|
| Teleportation Shrine | Välj Realm, Realm Depth och Realm Instability, och slumpa om Realm Properties | startskärmen (körningen startar) |
| Summoning Brazier | Kalla fram varelser man har 100 % Mana för | – (följeslagarna är fasta) |
| Fusion | Smält ihop två varelser | trofé-tilldelningen |
| Blacksmith | Tillverka, uppgradera och socka Artifacts (Brimstone) | – (artefakter planerade) |
| Enchanter | Tillverka och förtrolla Spell Gems | – |
| Enchanted Wardrobe | Byta Specialization, återställa perks, kostymer | Ed-valet på startskärmen |
| Everett | Projects: samla föremål i Realms för att låsa upp nya platser (Blacksmith-nivåer, fler Specializations, Refinery, Goblet of Trials, Gambling Dwarves, slottsutbyggnad …) | – |
| Reliquary, Nethermancer, Guilds, Godforge, Arena | Slutspelets system | – |
| Dekorationer, Decoration Mode | Tusentals föremål att placera, egna NPC:er, musik, golv | – |

Projects är motorn som får en att återvända: de låser upp nästan allt i slottet. Codex rekommenderar
att alltid ha så många Projects igång som man får.

**Hur ofta man är där:**

| Regel | Säkerhet |
|---|---|
| En Realm är en utflykt med många strider och en kort Realm Quest. Questen måste klaras innan man får lämna Realmen. | Bekräftat |
| När questen är klar använder man Teleportation Shrine för att åka **till en ny Realm eller hem**. Man behöver alltså inte åka hem mellan Realms. | Bekräftat (Codex, wiki Realms) |
| Spell Gem-Charges fylls vid start av varje Realm, inte i slottet. Liv återställs efter varje strid. Det finns alltså inget tvång att åka hem för att "vila". | Bekräftat / Troligt |
| Man åker hem när man vill bygga om: fusera, kalla fram, smida, förtrolla, starta Projects. Det blir ungefär var några Realms. | Troligt (följer av reglerna; ingen källa anger takt) |
| Dör hela laget skickas man hem och förlorar Fortune. | Bekräftat |
| Utrustning och makron sköts från huvudmenyn ("Items", "Creatures → Assign Macro"). Huvudmenyn nås troligen även inne i en Realm. | Troligt |

**Vårt läger i dag:** det visas efter **varje** vunnen strid (våning). Där väljer man en av tre troféer,
fördelar troféerna mellan hjältarna, öppnar makron och ser nästa strid. Charges följer med och fylls inte
på. Startskärmen är där man väljer Ed och följeslagare.

**Jämförelse:** vårt läger motsvarar egentligen inte slottet. Det motsvarar stunden *mellan strider inne i
en Realm*: bytet efter striden plus huvudmenyn. Vår startskärm är närmare slottet och Teleportation
Shrine. Det är rimligt för kryptloopen.

**Frågor att besluta:**

1. Ska det finnas ett riktigt slott, en bas, *mellan* körningarna? Den skulle ge en plats för det som
   varar över körningar: samlingen, Eder att låsa upp, smedja för artefakter, Projects. I Siralim är det
   där den långsiktiga motivationen ligger, och Projects är det som får spelaren att längta tillbaka.
2. Ska lägret fylla på något? I Siralim gör det inte det mellan strider (bara liv). Fyller lägret på
   Charges blir de en resurs per strid i stället för per körning.
3. Siralims kritik gäller grind och menyer i slottet. En liten bas med få, tydliga platser (som smeden
   och Ed-altaret) ger det långsiktiga utan Siralims meny-djungel.

### 10d. Förslag: vår bas, som originalet men med egna lösningar

Användarens riktning (2026-10-18): en bas som Siralims slott, med egna lösningar där vår design skiljer
sig. Vi smälter till exempel inga monster. Smeden och flera andra platser passar oss.

**Rytm, som originalet:** basen ligger *mellan* körningarna, och en körning motsvarar en Realm. Lägret
finns kvar *inne i* körningen, mellan våningarna. Man åker hem när man vill bygga om, eller när laget dör.

| Siralim | Vår plats (förslag) | Vad man gör | Vår lösning i stället för originalets |
|---|---|---|---|
| Teleportation Shrine | **Kryptporten** | Välj krypta och djup, senare instabilitet och våningsregler (Realm Properties), slumpa om reglerna | Som originalet |
| Blacksmith | **Smeden** | Smid en Artifact av fem typer (svärd, sköld, hjälm, stövlar, stav), uppgradera nivåer som öppnar platser, socka material | Som originalet. Typen avgör när förmågan i den slår till |
| Fusion | **Trofésalen** | Troféerna hänger på väggen (3D: monsterhuvuden, sköldar). Här bestämmer man vem som bär vilken | Ingen fusion. Trofén = Trait Material. Alternativ: trofén sockas i artefaktens Trait Slot hos Smeden, precis som Masters-material i originalet |
| Enchanter | **Runristaren** | Lär hjältarna nya förmågor från inskrifter man hittat i kryptan, ge förmågorna egenskaper (som Cascading eller Generous), fler Charges | Förmågor i stället för Spell Gems, men samma tre platser och samma regler |
| Enchanted Wardrobe | **Edsaltaret** (kapellet) | Välj Ed, lägg perks för poäng från körningar, återställ gratis | Ed = Specialization |
| Summoning Brazier | **Värdshuset** | Värva följeslagare | Namngivna personer, inte varelser. Upplåsta genom händelser i kryptan (räddad fånge, uppdrag) i stället för Mana |
| Everett, Projects | **Byggmästaren** | Bygg upp klostret eller borgen: samla föremål i kryptan för att låsa upp Smedens nivåer, nya Eder, nya platser och fler samtidiga projekt | Som originalet. Det är det som ger långsiktig dragkraft |
| Arena | **Övningsgården** | Prova sällskapet mot valfria fiender, utan risk | Lyfts fram tidigt. Den testar ledstjärnan direkt: "vill spelaren prova den nya kombinationen genast?" |
| Codex, Bestiary, Knowledge | **Biblioteket** | Samlingen av troféer, kända fiender och kunskap per fiende | Som originalet |
| Reliquary, Piety, Prophecies | **Relikskrinet** | Helgonreliker som uppgraderas med fromhet | Senare. Passar en paladin perfekt |
| Guilds, False Gods | **Riddarordnarna** | Uppdrag mot falska gudar, rykte, belöningar | Senare |
| Decorations, Gambling Dwarves, minispel | – | – | Hoppas över, eller blir troféer på väggen |

**Ordning efter ledstjärnan** (kombinationer före innehåll):

1. **Smeden.** Artefakttypen ger en ny regelbrytare per handling (Anfall, Defend, Provoke).
2. **Övningsgården.** Gör det gratis att prova en ny kombination.
3. **Edsaltaret.** Fler Eder och perks.
4. **Runristaren.** 2–3 förmågor per hjälte med egenskaper.
5. **Byggmästaren.** Projects som låser upp resten och ger en anledning att åka ut igen.
6. **Värdshuset.** Fler följeslagare, sedan Relikskrinet och Riddarordnarna.

**Valuta:** Siralim har fem resurser (Brimstone, Crystal, Essence, Granite, Power) plus Emblems.
Det är en källa till grind-kritiken. Förslag: en resurs per plats till att börja med, till exempel
*järn* för Smeden och *bläck* för Runristaren, samt föremål till projekten.

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

## 12. Stats och skadeformler (underlag för 0.13)

### Vad som är belagt i originalet

| Stat | Gör | Säkerhet |
|---|---|---|
| Health | Liv. 0 = död. | Bekräftat (Codex) |
| Attack | Skada med Attack. | Bekräftat |
| Intelligence | Potency för spells: skada, helning, stat-ändringar. | Bekräftat |
| Defense | Dras av från Attack/Potency innan modifierarna. Indirect Damage drar bara av 20 %. | Bekräftat |
| Speed | Startplats på Timeline, chans till undvikande, chans till och storlek på krit. Allt räknas mot målets Speed. Ordningen räknas aldrig om under striden. | Bekräftat (Codex); "räknas aldrig om" Troligt (spelare) |

**Formler (Bekräftat, wiki Combat):**

- Attack Damage = `(max(Attack − Defense, 0) + 1 % · Attack) × modifierare + additional`
- Spell Damage = `max(Potency − Defense, 0) × modifierare + additional`. Potency = Int × nivåns
  procent (Small 90 % … Devastating 150 %). Starkare nivåer ignorerar 0–40 % av Defense (tabellen i
  avsnitt 2). Spells på hela laget får ×0,25 efter Defense.
- Indirect Damage = `skada × modifierare + additional − 20 % · Defense`. Här dras Defense av *efter*
  modifierarna. Ingen krit och inget undvikande.
- Procentökningar adderas, minskningar multipliceras, varje källa till minskning stannar vid 80 %.
- Defend: −35 % skada **och** +50 % Defense. Provoke: alla fiendens attacker och spells går mot
  figuren, och den har −35 % Defense. (Bekräftat, Codex)
- Klass stark/svag: ×2 / ×½. Stats kan inte sjunka under 20 % av startvärdet.

**Krit och undvikande: formeln är inte publicerad.** Wikin skriver uttryckligen att formeln är okänd.
Spelare på Steam säger samma sak, och ingen utvecklare har svarat. Det enda som finns:

- Krit-*skada* +200 % vid 3× målets Speed, cirka +450 % vid 27×, avtagande. Krit-bonusar adderas
  (Pummel +200 % vid 3× = +400 %). (Bekräftat, wiki)
- Traitet *Frenzy*: "dodge and deal critical damage as if they have 100 % more Speed". Både krit och
  undvikande skalar alltså med Speed-kvoten. (Bekräftat, trait-text)
- Krit-*chans* och undvikande-chans: inga datapunkter. (Okänt)

### Förslag till vår modell (vårt val där originalet är okänt)

- **Skada:** ta Siralims formler rakt av. `power` i abilities blir modifieraren:
  `(max(Attack − Defense, 0) + 0,01 · Attack) × power × modifierare`. Spells använder Int.
- **Krit-skada** (passar båda datapunkterna): `bonus = 75 % + 125 % · log₃(r)`, där r = egen
  Speed / målets Speed. Det ger +75 % vid lika fart, +154 % vid 2×, +200 % vid 3× och +450 % vid 27×.
  Under lika fart (r < 1) blir det +50 %, som vår `CRIT_MULT` 1,5 i dag.
- **Krit-chans:** dagens `crit_chance` gäller vid lika fart, plus 10 procentenheter per fördubbling av r,
  högst 50 %.
- **Undvikande:** bara när målet är snabbare: 10 % per fördubbling av målets fart mot angriparens,
  högst 30 %. Spells och Indirect Damage kan inte undvikas.
- **Defend och Provoke** som originalet. Provoke blir mildare för en tank än vår +30 % i dag: Brokk
  får 39 Defense i stället för 60.

### Startvärden som håller dagens balans

Tanken: fiendernas Attack höjs lika mycket som sällskapets genomsnittliga Defense (≈ 39, avrundat till
+40). Hjältarnas Attack höjs lika mycket som fiendernas genomsnittliga Defense (≈ 15). Medelskadan blir
då ungefär oförändrad, men fördelas om: tanken tar mindre, de lätta tar mer.

| Hjälte | Health | Attack (idag → nytt) | Int | Defense | Speed |
|---|---|---|---|---|---|
| Paladinen | 900 | 70–90 → 85–105 | 95 | 50 | 10 |
| Brokk | 1150 | 55–70 → 70–85 | 77 | 60 | 7 |
| Syster Alva | 700 | 45–55 → 60–70 | 65 | 25 | 11 |
| Jägaren Eira | 650 | 65–85 → 80–100 | 90 | 20 | 14 |
| Solveig | 600 | 60–75 → 75–90 | 83 | 15 | 12 |

Int = Attack-mitten + 15, så att spells efter fiendens Defense gör ungefär lika mycket som i dag. Helningar
dras inte mot Defense och skulle bli för starka. Sänk därför helningarnas `power` med faktorn
mitten / (mitten + 15). Exempel: Helande ljus 3,0 → 2,3.

| Fiende | Health | Attack (idag → nytt) | Defense | Speed |
|---|---|---|---|---|
| Skelettkrigare | 640 | 161–195 → 201–235 | 20 | 9 |
| Skelettbågskytt | 440 | 131–158 → 171–198 | 10 | 13 |
| Gravpräst | 460 | 79–94 → 119–134 | 10 | 8 |
| Gravväktare | 900 | 118–144 → 158–184 | 45 | 6 |
| Glödskelett | 480 | 103–126 → 143–166 | 15 | 11 |
| Benlich (boss) | 2000 | 112–135 → 152–175 | 30 | 9 |

Exempel (skelettkrigare, medel 218): mot Brokk 160, mot Paladinen 170, mot Alva 195, mot Eira 200 (i dag
178 mot alla). Mot Brokk som försvarar sig (Defense 90, −35 %): 83. Mot Brokk som provocerar
(Defense 39): 181.

Kontrollera med `tests/balance_report.gd` efteråt. Målet är detsamma: BASIC förlorar nästan alltid,
AUTO vinner ~95 %, cirka 7 rundor. Gravväktaren (Defense 45) blir tydligt svårare att slå med svaga
anfall. Det är meningen, och det gör Alvas och Solveigs spells mer värda.

## 13. Edsaltaret: tre Eder i vårt dataformat

Siralims Specialization gäller **hela laget**. Hos oss bärs Eden av Paladinen och slutar verka när hen dör
(0.12). Förslag: varje Ed har ett kärn-trait som alltid gäller, och 4–6 perks som låses upp vid
Edsaltaret. Varje perk är ett trait i `data/traits.json` med `"oath"` och `"perk": true`. Siralim köper
perks i flera nivåer (ranks). Vi börjar med ett steg per perk, i Siralims maxnivå eller lägre.

Märkning: **O** = idén finns i originalet (namn och effekt, siffran ofta sänkt av oss). **V** = vårt
val. **⚙** = kräver något som motorn inte har i dag (se listan sist).

### Hämndens ed (Paladin, Retribution)

Kärna: `oath_vengeance`, som finns i dag. Paladinen slår tillbaka för 40 % när en allierad träffas.
Originalet: varje figur slår själv tillbaka för upp till 25 %. **O**

| Perk (original) | Effekt hos oss | Märkning |
|---|---|---|
| Zeal | Retribution +50 % om den träffade provocerar | O ⚙ |
| Wrath | Retribution +50 % om den träffade försvarar sig | O ⚙ |
| Reckoning | När en allierad provocerar anfaller hen en slumpad fiende | O ⚙ |
| Hand of Light | Efter Retribution helas alla allierade för 20 % av skadan | O (fungerar i motorn i dag) |
| Divine Toll | Efter Retribution 25 % chans att kasta Helig smäll gratis mot samma fiende | O, chansen V ⚙ |
| Execution Sentence | När en allierad dör tar alla fiender Helig skada (60 % av Paladinens Attack) | O förenklad: originalet räknar Retribution-skadan hittills i striden ⚙ |

```json
"vengeance_hand_of_light": {
	"name": "Ljusets hand", "oath": "oath_vengeance", "perk": true,
	"text": "När Hämndens ed slår tillbaka helas hela sällskapet för 20 % av skadan.",
	"trigger": "damage",
	"when": {"source": "self", "ability": "oath_vengeance"},
	"effects": [{"type": "heal", "pct_of_event": 0.2, "target": "allies"}]
},
"vengeance_zeal": {
	"name": "Iver", "oath": "oath_vengeance", "perk": true,
	"text": "Hämndens ed slår 50 % hårdare för en allierad som provocerar.",
	"trigger": "modify_damage",
	"when": {"ability": "oath_vengeance", "origin_target_has_aura": "provoke"},
	"modify": {"damage_mult": 1.5}
},
"vengeance_wrath": {
	"name": "Vrede", "oath": "oath_vengeance", "perk": true,
	"text": "Hämndens ed slår 50 % hårdare för en allierad som försvarar sig.",
	"trigger": "modify_damage",
	"when": {"ability": "oath_vengeance", "origin_target_has_aura": "defend"},
	"modify": {"damage_mult": 1.5}
},
"vengeance_reckoning": {
	"name": "Räkenskap", "oath": "oath_vengeance", "perk": true,
	"text": "När någon i sällskapet provocerar anfaller hen en slumpad fiende.",
	"trigger": "aura_applied",
	"when": {"unit": "ally", "aura": "provoke"},
	"effects": [{"type": "damage", "power": 1.0, "kind": "attack", "actor": "event_unit", "target": "enemy"}]
},
"vengeance_divine_toll": {
	"name": "Klockan klämtar", "oath": "oath_vengeance", "perk": true,
	"text": "När Hämndens ed slår tillbaka har Paladinen 25 % chans att kasta Helig smäll gratis.",
	"trigger": "damage", "chance": 0.25,
	"when": {"source": "self", "ability": "oath_vengeance"},
	"effects": [{"type": "cast", "ability": "holy_smite", "free": true, "target": "target"}]
},
"vengeance_execution": {
	"name": "Domslut", "oath": "oath_vengeance", "perk": true,
	"text": "När någon i sällskapet dör tar alla fiender Helig skada.",
	"trigger": "death",
	"when": {"unit": "ally"},
	"effects": [{"type": "damage", "power": 0.6, "school": "holy", "kind": "indirect", "target": "enemies"}]
}
```

### Gryningens ed (Cleric: helning, Barrier, buffar)

Kärna, **V** (byggd på Clerics *Luminesce*, som gör överhelning till Barrier): när någon i sällskapet
helas får målet Barrier för 30 % av helningen.

| Perk (original) | Effekt hos oss | Märkning |
|---|---|---|
| Guiding Light | Vid stridens start får alla Barrier för 15 % av max liv (original 50 %) | O ⚙ |
| Anointment | Efter en helning 50 % chans att målet får Välsignelse | O (original: slumpad buff). Fungerar i motorn för Paladinens helningar |
| Greater Healing | All helning i sällskapet +50 % (original +100 %) | O ⚙ |
| Revelation | I början av Paladinens tur 30 % chans att väcka en död allierad med 30 % liv | O (original: i slutet av turen) ⚙ |
| Holy Might | +10 % skada per buff man har (original 10 % per buff) | O ⚙ |

```json
"oath_dawn": {
	"name": "Gryningens ed",
	"text": "När någon i sällskapet helas får målet en Barrier för 30 % av helningen.",
	"trigger": "heal", "scope": "party",
	"when": {"target": "ally"},
	"effects": [{"type": "barrier", "pct_of_event": 0.3, "target": "target"}]
},
"dawn_guiding_light": {
	"name": "Ledljus", "oath": "oath_dawn", "perk": true,
	"text": "Vid stridens start får hela sällskapet en Barrier för 15 % av sitt liv.",
	"trigger": "battle_start",
	"effects": [{"type": "barrier", "pct_max_hp": 0.15, "target": "allies"}]
},
"dawn_anointment": {
	"name": "Smörjelse", "oath": "oath_dawn", "perk": true,
	"text": "Efter en helning har målet 50 % chans att få Välsignelse.",
	"trigger": "heal", "chance": 0.5, "scope": "party",
	"when": {"target": "ally"},
	"effects": [{"type": "aura", "aura": "blessing", "target": "target"}]
},
"dawn_greater_healing": {
	"name": "Större helning", "oath": "oath_dawn", "perk": true,
	"text": "All helning i sällskapet är 50 % starkare.",
	"trigger": "modify_heal", "scope": "party",
	"modify": {"heal_mult": 1.5}
},
"dawn_revelation": {
	"name": "Uppenbarelse", "oath": "oath_dawn", "perk": true,
	"text": "I början av Paladinens tur: 30 % chans att väcka en död allierad med 30 % liv.",
	"trigger": "turn_start", "chance": 0.3,
	"when": {"unit": "self"},
	"effects": [{"type": "revive", "pct": 0.3, "target": "dead_ally"}]
},
"dawn_holy_might": {
	"name": "Helig makt", "oath": "oath_dawn", "perk": true,
	"text": "Sällskapet gör 10 % mer skada per buff de har.",
	"trigger": "modify_damage", "scope": "party",
	"modify": {"damage_mult_per_aura": 0.1}
}
```

### Väktarens ed (Siegemaster: Defend, Provoke, Defense)

Kärna, **O** (*Thorns*): när någon i sällskapet tar skada av en attack eller spell slår hen tillbaka för
15 % av sin Defense. Kräver Defense från avsnitt 12. Dagens `oath_challenger` (Utmanarens ed, Provoke →
Defend) motsvarar *War Machine* och flyttas hit som perk.

| Perk (original) | Effekt hos oss | Märkning |
|---|---|---|
| War Machine | När någon provocerar försvarar hen sig också | O (finns som `oath_challenger`, men bara för Paladinen) ⚙ scope |
| In Formation | Alla börjar striden med Försvara | O ⚙ |
| Rest Up | Efter Försvara får hjälten tillbaka 1 Charge på en förmåga | O ⚙ |
| Titanic Rage | +50 % skada mot fiender som försvarar sig eller provocerar (original +150 %) | O. Gravväktaren provocerar, så det passar krypta 2 |
| The Best Offense | Anfall gör extra skada lika med 30 % av egen Defense | O ⚙ |
| Barricade | Medan någon försvarar sig tar de andra 20 % mindre skada (original: grannar 50 %) | O förenklad: vi har inga grannar ⚙ |

```json
"oath_ward": {
	"name": "Väktarens ed",
	"text": "När någon i sällskapet träffas av en attack eller spell slår hen tillbaka för 15 % av sin Defense.",
	"trigger": "damage", "scope": "party",
	"when": {"target": "ally", "source": "enemy", "direct": true},
	"effects": [{"type": "damage", "stat": "defense", "pct": 0.15, "kind": "indirect", "actor": "event_target", "target": "source"}]
},
"ward_war_machine": {
	"name": "Krigsmaskin", "oath": "oath_ward", "perk": true,
	"text": "När någon i sällskapet provocerar försvarar hen sig också.",
	"trigger": "aura_applied", "scope": "party",
	"when": {"unit": "ally", "aura": "provoke"},
	"effects": [{"type": "aura", "aura": "defend", "target": "event_unit"}]
},
"ward_in_formation": {
	"name": "I formation", "oath": "oath_ward", "perk": true,
	"text": "Hela sällskapet börjar striden försvarande.",
	"trigger": "battle_start",
	"effects": [{"type": "aura", "aura": "defend", "target": "allies"}]
},
"ward_rest_up": {
	"name": "Vila upp", "oath": "oath_ward", "perk": true,
	"text": "När någon försvarar sig får hen tillbaka en Charge på en förmåga.",
	"trigger": "aura_applied", "scope": "party",
	"when": {"unit": "ally", "aura": "defend"},
	"effects": [{"type": "restore_charge", "amount": 1, "target": "event_unit"}]
},
"ward_titanic_rage": {
	"name": "Titanisk vrede", "oath": "oath_ward", "perk": true,
	"text": "Sällskapet gör 50 % mer skada mot fiender som försvarar sig eller provocerar.",
	"trigger": "modify_damage", "scope": "party",
	"when": {"target_has_any_aura": ["defend", "provoke"]},
	"modify": {"damage_mult": 1.5}
},
"ward_best_offense": {
	"name": "Bästa försvaret", "oath": "oath_ward", "perk": true,
	"text": "Anfall gör extra skada lika med 30 % av anfallarens Defense.",
	"trigger": "modify_damage", "scope": "party",
	"when": {"kind": "attack"},
	"modify": {"additional_from_stat": {"stat": "defense", "pct": 0.3}}
}
```

### Vad motorn behöver (⚙)

1. **`"scope": "party"`.** Traitet gäller allas händelser, som om varje allierad bar det. Det motsvarar
   Siralims Specialization. Det är det viktigaste tillägget. Utan det blir modify-perks bara Paladinens.
2. **`actor`.** Den som utför effekten: `event_unit` (den som agerade) eller `event_target` (den som
   träffades). I dag är det alltid traitets ägare.
3. **Nya effekter:** `cast` (förmåga, gratis), `revive`, `barrier` (absorberar skada; i originalet
   staplas de inte, den starkaste gäller, max 200 % av högsta stat), `restore_charge`.
4. **Nya triggers:** `battle_start` (efter Siralims ordning i avsnitt 2), eventuellt `turn_end`.
5. **Nya mål och villkor:** `enemies`, `dead_ally`, `origin_target_has_aura` (den allierade som
   utlöste Retribution), `target_has_any_aura`, `damage_mult_per_aura`, `additional_from_stat`.
6. **Defense och Int** som stats (avsnitt 12).

Börja med Hämndens ed: `vengeance_hand_of_light` fungerar redan, och resten kräver bara punkt 2–5.
Gryningens och Väktarens ed kräver `scope: party` och Barrier.

### 13b. Beslut om perks (Huvudtråden, 2026-10-19, byggs i 0.15)

Bakgrund (Bekräftat, wikin): i Siralim har varje perk 1–50 nivåer och kostar 100 poäng fullt utbyggd.
Paladins 15 perks kostar 1 500 poäng, vilket är exakt taket för Perk Points. Återställning är gratis.
Anointments låter en låna perks från andra Specializations efter segrar mot False Gods.

1. **Anointments: ja, först.** Varje besegrad boss (Benfursten nu, fler senare) låser upp en
   anointment-plats. Där kan man låna **en** perk från en annan Ed. Den kostar perk-poäng som vanligt,
   och regelbrytare får lånas.
2. **Nivåer: ja, i liten skala.** 2–3 nivåer bara på perks som är rena siffror (Wrath, Zeal, Greater
   Healing och liknande). Regelbrytare (Reckoning, War Machine, In Formation …) har en nivå, som i
   Siralim.
3. **Delad poängpott: nej, inte nu.** Egen pott per Ed, så att det lönar sig att prova de andra. Tas upp
   igen vid fler än cirka 5 Eder.


**Tillägg (2026-10-19, ur [Character Specialization Guide](https://steamcommunity.com/sharedfiles/filedetails/?id=2190265173), version 2.0.37):**
- *Perk-potten:* "The total amount of perk points you've earned is available to every class." Varje
  Specialization har alltså **hela** potten för sig. Vårt beslut (egen pott per Ed, punkt 3 ovan)
  motsvarar originalet exakt. Den "delade potten" i wikin betydde detta. Bekräftat.
- *Perk Points:* 10 per Realm Quest på djupaste djupet, 50 per besegrad story-boss. Bekräftat (guide).
- *Anointments:* 5 platser som standard (vissa Specializations får fler). De låses upp gradvis genom
  segrar mot False Gods via Guilds, långt efter berättelsen. Varje Specializations anointments kommer
  från en viss False God: Paladin och Cleric från Saint Althea, Monk och Warden från Jotun, Inquisitor
  från The Ancestor. Inte alla perks kan bli Anointments. Bekräftat (guide).
- *Start:* varje start-Specialization får två unika startvarelser och en egen startspell. Efter
  tutorialen får man en varelse till. Paladin börjar med Blood Crusader (Crusader/Life). Bekräftat
  (guide).
- *Klasscirkeln:* Life > Death > Chaos > Sorcery > Nature > Life (stark mot, ×2). Bekräftat (guide).
- Guiden rekommenderar Cleric för den som vill tanka och Monk för den som vill undvika. Det stöder
  §4 i `siralim_0.19.md` (tank som byggd roll).

## 14. Hur varelser blir starkare, och hur man ser det (2026-10-19)

VD:ns fråga (bara diskussion): hur bygger man upp HP och styrka, vad bygger man utöver troféerna, och hur
ser man hur en karaktär är uppbyggd? Hos oss är hjältarnas grundstats fasta. Bara artefaktens stat och
perks höjer dem, och fienderna skalar med djupet.

### 14.1 Nivåer

| Regel | Säkerhet |
|---|---|
| Varelser får erfarenhet när en strid vinns. | Bekräftat (Codex) |
| Varje nivå höjer varje stat med 30 % av basvärdet (värdet på nivå 1). Personligheten gör att en stat växer 40 % och en annan 20 %. | Bekräftat (Codex) |
| Det finns inget nivåtak. Fienderna skalar också utan tak. | Bekräftat (wiki) |
| Fienderna stiger i nivå mycket snabbare än ens varelser. Svaret är nya traits och synergi, inte grind. | Bekräftat (wiki FAQ) |
| Fiendernas nivå följer Realm Depth, och djupet väljer man själv (låga djup går att använda för att träna). | Troligt (spelare) |
| Från djup 40 kan man betala Power för att höja en varelse till den högsta nivå man har nått (hos Fusionist), så att nya varelser inte behöver tränas från noll. | Bekräftat (wiki Starter guide); var det sker: Troligt |
| I Gate of the Gods skalas alla till nivå 100. | Bekräftat (Codex) |

### 14.2 Andra källor till stats

| Källa | Hur | Säkerhet |
|---|---|---|
| **Personlighet** | 20 sorter. Den ändrar inte stats direkt, bara tillväxten per nivå (+40 % / 20 % i stället för 30 %). Kan bytas med en Personality Tome, och då räknas allt om bakåt. Pilar vid stats visar vilka som påverkas. | Bekräftat (Codex) |
| **Artefakt** | Typen ger en stat. Uppgradering till nivå 50 stärker allt. Upp till 4 Stat Slots (Amber) med en eller två stats var. Buffen Proficient ger +30 % från Stat Slots. Health fungerar som en ökning vid stridens start. | Bekräftat (Codex, wiki) |
| **Kort (Cards)** | Varje kort ger en liten stat-bonus efter klass. Kompletta kortsamlingar ger en passiv bonus. Dubbletter ger stats men inte samlingsbonus. | Bekräftat (Codex) |
| **Reliker** (slutspel) | Stat-bonus till den varelse reliken är fäst vid, och en perk per 10 ranker. Med "Synergy" får alla varelser stat-bonusen från alla reliker. | Bekräftat (Codex) |
| **Nether Stones** (slutspel) | Kan ge stora stat-ökningar och flera traits. | Bekräftat (Codex) |
| **Stat scrolls** | Projects-uppdraget Training ger 3 stat scrolls. | Bekräftat (wiki Projects); exakt effekt: Okänt |
| **Mastery** (per ras) | Mer skada och mindre skada tagen, inga stats. | Bekräftat |
| **Traits och perks** | Ändrar oftast stats i striden (t.ex. +35 % Attack efter en cast), inte grundvärdet. *Seraphim* (Paladin) lägger Defense på Health vid start. | Bekräftat |
| **Spell Properties** | Påverkar besvärjelser, inte varelsens stats. | Bekräftat |

Det finns ingen "träning" i slottet som köps med pengar, utom nivå-upphämtningen för Power och Projects
som ger scrolls. Styrkan byggs över tid genom nivåer, artefakter och samlingar, och i varje strid genom
traits.

### 14.3 Att granska en varelse

- Siralim har **inget karaktärsblad med många värden** (ingen styrka, smidighet osv. som i D&D). Det
  finns bara fem stats: Health, Attack, Intelligence, Defense och Speed. Bekräftat (Codex).
- Varelsens skärm visar nivå, klass och ras, de fem värdena med personlighetens pilar (upp och ned),
  traits (egen, ihopsmält, artefaktens), artefakten och dess egenskaper, och Spell Gems med Charges.
  Delarna: Bekräftat (Codex). Exakt layout: Troligt.
- I striden visar Inspect fiendens stats, traits, artefakt, Spell Gems, buffar, debuffar och minions.
  Liv syns först från Knowledge-rang E. Håll F för varaktigheter och Realm Properties. Bekräftat (Codex).
- **Krit- och undvikandechans visas inte som procent.** De beror på Speed mot det aktuella målet, och
  formeln är inte publicerad. Troligt (wiki: "formeln är okänd", spelare: "ingen fast procent att se").

### 14.4 Trait Materials kontra troféer

- Trait Materials är **sällsynta** i Siralim: "extremely difficult to find". De kommer från Masters (efter
  3 segrar, sedan en chans per seger) och Assassination-uppdrag (Knowledge-rang S). En varelse kan bära
  bara ett (artefaktens Trait Slot). Bekräftat (Codex).
- Däremot får man **många varelser**. Nästan varje besegrad varelse ger Mana, och vid 100 % kan man kalla
  fram den, med dess trait. Man äger hundratals men använder sex. Bekräftat (Codex).
- Våra troféer motsvarar alltså två saker: den täta strömmen av nya varelser (nya traits att välja
  bland) och, för bosstroféerna, de sällsynta Trait Materials (3 segrar, beslut §4 i
  `siralim_innehall.md`). **Att det kommer många troféer stämmer med originalet**, så länge man bara kan
  bära en per hjälte. Samlingen ska kännas som Siralims Bestiary, inte som en ryggsäck.

### 14.5 Slottet mellan våningarna

- I Siralim är en Realm en sammanhängande karta utan våningar. Man går inte hem mitt i den. När Realm
  Quest är klar väljer man vid Teleportation Shrine: en ny Realm direkt, eller hem till slottet.
  Bekräftat (Codex).
- Hos oss (0.18.5) går körningen redan från våning till våning via lägret och rumskartan, och man kommer
  hem till basen först när sista våningen är klar eller sällskapet faller. **Det stämmer med
  originalet.**
- Skillnad (Okänt om det behövs): Siralim låter en gå direkt till nästa Realm utan att åka hem. Hos oss
  går man alltid hem efter körningen.

### 14.6 Vad vi saknar jämfört med originalet

Bara sådant som finns i Siralim. Varje anpassning är märkt.

1. **Nivåer och erfarenhet** (originalet). Hjältarna får erfarenhet av vunna strider, och varje nivå ger
   +30 % av basvärdet. **Inget nivåtak**, som i originalet. Fienderna skalar med det valda djupet, inte
   med hjältarnas nivå. Då kan man gå tillbaka till lägre djup, bli starkare, hitta nya troféer och prova
   nya kombinationer, och sedan gå djupare igen (VD:ns önskan, 2026-10-19). Mitt tidigare förslag om ett
   nivåtak per djup är **struket**: det fanns inte i originalet och hindrade just det.
   Okänt: om originalet ger mindre erfarenhet från lägre djup.
2. **Personlighet per hjälte** (originalet). Passar namngivna personer extra bra: Brokk "Envis"
   (Health 40 %, Speed 20 %), Eira "Rastlös" (Speed 40 %, Defense 20 %) … Kan bytas med en Personality
   Tome från skattkammare. Syns som pilar vid stats.
3. **Nivå-upphämtning i basen** (originalet: Power-uppgradering hos Fusionist). En ny följeslagare från
   Värdshuset kan höjas till sällskapets högsta nivå för silver, så att den inte måste tränas från noll.
4. **Artefaktnivåer och Stat Slots hos Smeden** (originalet). I dag ger en artefakt +5 % eller +10. Med
   nivåer och Stat Slots (Amber) blir Smeden platsen där man bygger upp stats över tid.
5. **Hjältens blad** (originalet). En skärm per hjälte med nivå, de fem stats och personlighetens pilar,
   egen egenskap, trofé och artefakt, och förmågor med Charges. Ingen procent för krit eller undvikande,
   som i originalet. *Möjligt eget tillägg, inte rekommenderat nu:* en hjälptext "Snabbare än målet ger
   högre krit- och undvikandechans".
6. **Senare, i originalets ordning:** kort (stat-bonus per fiende och samlingsbonus, passar Bestiariet),
   stat scrolls via Byggmästarens projekt, och reliker.

## 15. Artefaktuppgraderingar: vad som gör dem roliga (underlag för 0.20)

VD:ns tvivel: "Jag brukar älska att uppgradera gear … jag kan inte se det roligt att uppgradera en
artefakt bara. Men det kanske är det. Vi får göra det roligt."

### 15.1 Nivåer 1–50

| Regel | Säkerhet |
|---|---|
| Artefakter tillverkas och uppgraderas hos Blacksmith i slottet. De hittas aldrig färdiga. | Bekräftat (Codex) |
| Varje nivå stärker **alla** egenskaper i artefakten ("en nivå 30-artefakt ger större stat-ökning än en nivå 10"). | Bekräftat (Codex) |
| Nya platser öppnas vid vissa nivåer: Stat 3, Trick 5, Stat 10, Trait 15, Trick 25, Stat 35, Spell Gem 50, sedan Nether (extra uppgradering). | Bekräftat (wiki) |
| Kostnad i Brimstone per nivå: 1 000 (nivå 1), 250 (2–10), 500 (11–20), 750 (21–30), 1 000 (31–40), 5 000 (41–50), 25 000 (Nether-platsen). Totalt 75 750 till nivå 50. | Bekräftat (wiki-tabell; exakt nivå för varje plats är något oklar i tabellen) |
| Smeden själv måste uppgraderas via Projects för att nå nivå 50. | Bekräftat (Codex, wiki Projects) |

### 15.2 Stat Slots och Amber

| Regel | Säkerhet |
|---|---|
| Stat Slots tar Stat Materials, *Amber*, i olika färger. Det är **den vanligaste materialtypen** i spelet. En plats kostar 5 Amber. | Bekräftat (Codex, wiki) |
| Varje färg ger en av de fem stats, eller delar ökningen mellan två. | Bekräftat (Codex) |
| Storleken följer artefaktens nivå, inte materialet. Amber har inga slumpvärden eller sällsynthetsgrader. | Troligt (inga värden på materialen i någon källa; Codex säger att nivån stärker allt) |
| Material hittas under vandringen i Realms (marken, kistor, fiender) och kan köpas i butiker. Realms har material i *common, rare, legendary*. | Bekräftat (Codex, wiki Realms) |
| Man får bonus på föremål bara på det djupaste djup man nått. Realm Instability ger mer (upp till +400 %). | Bekräftat (Codex, wiki Realms) |
| Att ta ut ett material **förstör** det. Nether Stones överlever. | Bekräftat (Codex) |

### 15.3 Övriga material

| Plats | Material | Vad det gör | När | Säkerhet |
|---|---|---|---|---|
| Trick (2) | *Slate of (Buff)*, *Curio of (Debuff)*, *(Class) Crippler*, *Whetstone*, *Jagged Rock*, *Armor Scrap*, *Slippery Stone*, *Pump Drill*, *Arcane Sigil* | Chans till buff när man gör skada, chans till debuff på fienden, klasstyrka, mer anfallsskada, krit, mindre skada, undvikande, fler Spell Gem-platser, potency | "Något mindre vanliga än Stat Materials" | Bekräftat (Codex) |
| Trait (1) | Trait Materials | Ytterligare ett trait | "Extremely difficult": Masters (efter 3 segrar), Assassination-uppdrag | Bekräftat |
| Spell (1) | Spell Gem | Chans att kasta spellen vid artefakttypens handling. Gemmets nivå och egenskaper ignoreras. | Nivå 50 | Bekräftat |
| Nether (1) | Nether Stone | Slumpgenererad, "Diablo-liknande". Kan ge flera traits, spells och stats. Sällsynthet visas med ett tal. | Efter nivå 50. Vanligare med hög instabilitet och djup. | Bekräftat (Codex, wiki); frekvens: Troligt (spelare) |

### 15.4 Vad spelarna säger

- **Tråkigt:** grind. En spelare hade "dumpat alla resurser i artefakter och spell gems och kan inte
  uppgradera utan timmar av grind". En annan saknar känslan av framsteg. Troligt (Steam).
- **Roligt:** bredden i byggen ("build diversity far surpasses the other Siralim games"), där artefakter,
  spells och traits ihop gör lagbygget. Nether Stones beskrivs som slutspelets jakt, med slumpade värden
  och sällsynthet. Troligt (Steam, wiki).
- Slutsatsen är densamma som VD:ns: **att höja en procentsiffra är inte roligt. Det roliga är när en
  uppgradering öppnar ett nytt val** (en ny plats, en ny trigger) och när man hittar något sällsynt.

### 15.5 Koppling till att gå tillbaka

- Material finns på alla djup, så att gå tillbaka ger nivåer, troféer och vanliga material (Amber).
- **Det bästa bytet finns på det djupaste djupet** (bonus bara där), och Nether Stones med instabilitet.
  Originalet driver alltså spelaren både bakåt (bli starkare, testa) och framåt (bättre byte). Bekräftat.

### 15.6 Förslag: vår Smed (anpassningar märkta)

**Princip:** varje uppgradering ska **öppna något**: en plats, ett val eller en tydlig ny regel. Inte
bara +2 %.

1. **Nivåer 1–10** i stället för 1–50. *Anpassning:* vi har få strider per körning. Platserna öppnas i
   originalets **ordning**:

   | Nivå | Öppnas | Siralim |
   |---|---|---|
   | 1 | Typens stat och **förmågeplatsen** (typen avgör triggern) | Spell-plats vid 50 |
   | 2 | Stat-plats 1 | 3 |
   | 3 | Trick-plats 1 | 5 |
   | 5 | Stat-plats 2 | 10 |
   | 7 | Trick-plats 2 | 25 |
   | 9 | Stat-plats 3 | 35 |
   | 10 | Nether-plats (senare) | efter 50 |

   *Anpassning:* förmågeplatsen redan på nivå 1, eftersom vår artefakt redan har den och det är den mest
   regelbrytande delen. Trait-platsen (Siralim 15) hoppar vi över, eftersom trofén redan är vår
   trait-plats (beslut i `siralim_innehall.md` §4).
2. **Varje nivå stärker alla egenskaper** (originalet), t.ex. +10 % per nivå.
3. **Material från rummen** (originalet):
   - Amber i fem färger, en per stat. Vanligt: strider och skattkammare.
   - Trick-material med originalets namn och effekter (Brynsten = Whetstone, Taggsten = Jagged Rock,
     Rustningsskrot = Armor Scrap, Hal sten = Slippery Stone, Arkant sigill …). Mindre vanligt:
     elit, skattkammare, portaler.
   - Bättre chans på det djupaste djupet. 5 Amber per plats, som i originalet.
4. **Att ta ut förstör materialet** (originalet). Det gör valet viktigt.
5. **Silver** i stället för Brimstone. *Anpassning:* vi har en valuta. Kostnaden stiger brant per nivå,
   som i originalet.
6. **Smedens egen nivå** via Byggmästarens Projects (originalet). Den öppnar artefaktnivå 4–6, 7–9 och
   10, så att Smeden växer med kampanjen.
7. **Nether Stones senare**, som jakten i slutspelet: slumpade, med ett sällsynthetstal (originalet).
   Det är originalets svar på "loot-känslan", och det svar som ligger närmast det VD:n älskar med gear.
8. **Synligt mål** (originalet visar platserna i smedjan): Smeden visar "nästa nivå öppnar
   Trick-plats". *Litet eget tillägg:* artefakten syns i 3D på hjälten och får en glöd per öppnad plats,
   bara utseende.

### 15.7 Smeden Sabon i 2.0: komplettering och jämförelse med vår Smed (VD:ns källa, 2026-10-20)

VD:ns andra genomgång (Ultimate 2.0.x, SÄKERT/TROLIGT, inte prövat i spelet). Det nya och det som skiljer mot oss:

| Punkt | Originalet (2.0) | Säkerhet | Hos oss (0.20) |
|---|---|---|---|
| Tjänster | Smida, uppgradera, sätta in, ta ut, namnge artefakt (Brand) och Nether Stone (Etch). Namnen påverkar inte styrkan. | Säkert | Smida, nivå, sätta in, ta ut. Ingen namngivning. |
| Från start | Sabon finns från introt | Säkert | Samma (Hedda i borgen) |
| Smida | 1 000 Brimstone (japanska wikin: 500) | Troligt | Silver |
| Nivåpris | 250 per steg (1→10), 500, 750, 1 000, sedan 5 000 (40→50); sista steget till Nether 25 000. Totalt 1→50: 74 750. | Troligt | 10 nivåer för silver (anpassning) |
| Platserna | Stat 3, Trick 5, Stat 10, Trait 15, Trick 25, Stat 35, Spell 50, Nether efter 50 | Säkert | Stat 2, Trick 3, Stat 5, Trick 7, Stat 9, Nether 10. Ingen Trait-plats (trofén), ingen Spell-plats (se nedan). |
| Insättning kostar | Två betalningar: nivån öppnar platsen, insättningen kostar Brimstone. Första stat-platsen 100; övriga stat 2 500; trick 2 500–5 000; trait ~10 000; spell 25 000; Nether efter stenens sällsynthet | Första: säkert; övriga: troligt | **Gratis**: bara materialet förbrukas |
| Material per plats | Amber 5, **trick 3**, trait 1, spell 1 gem, Nether 1 sten | Säkert | Amber 5, **trick 1** |
| Samma trick två gånger | **Förbjudet** (sedan före 1.0). Samma stat i flera stat-platser är tillåtet. | Säkert | **Tillåtet**: `Profile.socket()` kontrollerar inte den andra trick-platsen |
| Trick-sorter | Whetstone (attackskada), Arcane Sigil (spell potency), Jagged Rock (krit), Armor Scrap (mindre skada), Slippery Stone (undvikande), **Pump Drill (fler gem-platser)**, Slate of … (buff vid skada), Curio of … (debuff vid skada), **… Crippler (styrka mot en klass, tak 80 %)** | Säkert | Brynsten, Taggsten, Rustningsskrot, Hal sten, Arkant sigill, Styrkans skiffer, Sårbarhetens kuriosa. Pump Drill och Crippler saknas (vi har inga gems eller klasser än). |
| Spell-platsen | Nivå 50. En Spell Gem sätts in; tier och egenskaper ignoreras; klassen behöver inte stämma; kastas automatiskt av typens handling utan Charges; räknas som automatisk cast | Säkert | Artefakten har en förmåga från start (vårt val), också utan Charges och klassfri |
| Ta ut | Amber, trick, trait och spell gem förstörs; Nether Stone går tillbaka (sedan 1.0.3). Platsen och nivån finns kvar. Avgift ~1 000. | Säkert; avgift troligt | Samma, utan avgift |
| Nether Stones | En plats per artefakt; slumpade bonusar (stats, trick, traits, spells); sällsynthetstal. Ingen omslumpning eller sammanslagning hos Sabon (Nether Workshop är 3.0). | Säkert / troligt | Samma (1–4 egenskaper efter sällsynthet) |
| Smedjans ranker | 5 ranker, var och en höjer taket med 10 nivåer. Uppgraderas som **Projects** hos Everett: Granite, göt (koppar, järn, förtrollat kol från krossbara föremål), hammare som hittas på marken, Creature Parts (strider), Arcane Dust (Realm Quests). Första projektet efter djup 6. | Säkert; antal troligt | Saknas: alla 10 nivåer går att köpa direkt |
| Trait-material | Ger exakt den egenskapen. Även via Assassination-uppdrag när varelsens Knowledge nått S (~40 000 Granite). Alla traits finns inte som material. | Säkert / troligt | Troféerna (ersätter fusion och trait-material) |
| Återvinna artefakter | Hos Refinery, inte Sabon | Säkert | Saknas |

**Avvikelser att ta ställning till** (inget beslutat):
1. **Samma trick två gånger** är tillåtet hos oss men förbjudet i originalet. Det är den enda rena regelskillnaden och lätt att rätta.
2. **Trick kostar 1 hos oss, 3 i originalet.** Med våra fyndtakter kan 1 vara medvetet; i så fall bör det märkas som vårt val.
3. **Insättning utan avgift.** Originalet tar betalt för varje insättning, vilket gör silvret till ett beslut. Kan vara en anpassning.
4. **Smedjans ranker via Projects** saknas. Det är originalets sätt att låta utforskningen (krossbara föremål, hammare på marken, Realm Quests) styra hur långt artefakterna kan växa. Kopplar till §19.
5. Brand/Etch (namngivning) är billigt och personligt, men påverkar inte spelet.

## 16. Att ge upp, fly och gå hem (2026-10-19)

VD:ns fråga (bara diskussion): borde det finnas en "ge upp"-knapp för att gå hem och reparera?

| Fråga | Siralim | Säkerhet |
|---|---|---|
| Lämna en Realm när som helst? | Nej, inte via Teleportation Shrine: Realm Quest måste vara klar innan man kan åka hem eller vidare. Vägarna hem utan klar quest är att förlora (laget faller) eller att spara och ladda om, vilket alltid tar en till slottet. | Bekräftat (wiki Realms, Codex); spara och ladda: Troligt (spelare) |
| Vad förlorar man då? | Realm Quest och framsteget i Realmen. Nästa gång får man en ny quest i en ny, slumpad Realm. Förlorar man en strid nollställs Fortune (resursbonusen) också. Varelser, föremål och resurser behålls. | Bekräftat (wiki Realms, Combat, Codex) |
| Fly från en strid? | Ja: *Forfeit* (håll E+Q+F i några sekunder). Det räknas som förlust: man skickas hem och förlorar Fortune, men behåller varelser, föremål och resurser. | Bekräftat (wiki Combat, Codex) |
| Fylls Charges hemma? | Ja. Wikin: "automatically recharged upon returning to your castle". Codex: vid start av varje Realm. | Bekräftat (båda) |

Det som kommer närmast en "ge upp"-knapp i originalet är alltså **Forfeit i striden**. Den kostar
Fortune och questen men ingenting annat, och man kommer hem med fulla Charges. Siralim har ingen knapp för
att "åka hem utan att förlora" mitt i en Realm.

**Hos oss** motsvaras det av: Forfeit i striden, som avslutar körningen och skickar hem. Det man förlorar
är det som motsvarar Fortune och questen (körningens perk-poäng och quest-belöning), medan troféer,
silver och material från vunna strider behålls. Charges fylls vid nästa körning, som i dag. *Anpassning:*
ingen.

## 17. Buffar, debuffar och tidslinjen (underlag för 0.22)

Källor: Codex-listorna "List: Buffs" och "List: Debuffs" (spelets egen text, 2.0.37), wikins Buffs-,
Debuffs- och Combat-sidor, och trait-kompendiet. Allt i tabellerna är **Bekräftat (Codex)** om inget
annat står.

### 17.1 Buffar (18)

| Buff | Exakt effekt | Varaktighet |
|---|---|---|
| Agile | Extra, oberoende chans att undvika anfall | 3 |
| Arcane | Nästa spell kostar ingen Charge, sedan försvinner buffen | tills den används |
| Barrier | Absorberar skada tills den är slut. Högst 200 % av högsta stat. Staplas inte, den starkaste gäller (wiki) | tills den är slut |
| Berserk | +50 % skada | 3 |
| Defensive | Försvarar automatiskt i slutet av sin tur | 3 |
| Immune | Kan inte få debuffar | 1 |
| Invisible | Kan inte väljas som mål för fiendens anfall och spells. Försvinner när figuren agerar | tills den agerar |
| Leeching | Helas 25 % av skadan den gör | 3 |
| Mending | Helas 25 % av sitt liv i början av sin tur | 3 |
| Proficient | +30 % från artefaktens Stat Slots, utom Health | 3 |
| Protected | Tar 50 % mindre skada | 3 |
| Rebirth | Återuppstår med 50 % liv när den dör | 3 |
| Repelling | 50 % chans att ignorera skada från spells | 3 |
| Savage | Extra, oberoende chans till krit med anfall | 3 |
| Shelled | Upphäver nästa anfall eller spell | tills den träffas |
| Splashing | Gör 100 % av skadan på fiender intill målet | 3 |
| Taunting | Provocerar automatiskt i slutet av sin tur | 3 |
| Warded | Kan inte förlora stats | 3 |

### 17.2 Debuffar (20)

| Debuff | Exakt effekt | Varaktighet | Resistant (bossar) |
|---|---|---|---|
| Bleeding | Skada = 30 % av *nuvarande* liv i början av varje tur | 3 | 66 % mindre skada |
| Blighted | Kan inte helas. Helning gör i stället skada = 50 % av helningen | 3 | – |
| Blind | Kan inte välja mål för anfall och enkelmåls-spells | 3 | – |
| Bomb | I början av sin tur: skada = 80 % av angriparens Speed, sedan bort | tills den smäller | – |
| Burning | Skada varje tur efter angriparens Int (30 %, wiki) | 3 | – |
| Confused | 50 % chans att anfalla eller kasta skadliga spells på sina egna | 3 | – |
| Cursed | När den gör skada med anfall eller spell tar den skada = 100 % av målets Attack | 3 | – |
| Disarmed | Förlorar alla fördelar från artefakten (artefaktens traits verkar ändå, wiki) | 3 | – |
| Feared | Kan inte få stats | 3 | – |
| Frozen | Kan inte agera. 25 % chans att tina i början av sin tur, chansen dubblas varje tur | tills den tinar | dubbel chans att tina |
| Inverted | Anfall och spells helar fiender och skadar egna, tills tillräckligt har gjorts. Ges inte av slumpade debuffar (wiki) | tills den är förbrukad | – |
| Mania | Skada i slutet av turen = 3 % av allt liv som alla hade helats när den lades. Ges inte av slumpade debuffar (wiki) | 3 (Codex) / 1 (wiki) | – |
| Poisoned | Skada varje tur efter angriparens Attack (30 %, wiki) | 3 | – |
| Scorned | Kan inte anfalla. Skriver över Silenced | 1 | kan anfalla, −50 % skada |
| Silenced | Kan inte kasta spells. Skriver över Scorned | 1 | kan kasta, −50 % skada |
| Sleeping | Kan inte agera förrän den tar skada eller debuffen går ut | 3 | vaknar i början av sin tur |
| Snared | Fast längst ned på Timeline. 10 % chans att slita sig loss i början av *varje figurs* tur | 3 | tredubbel chans |
| Stone | Kan inte undvika eller krita | 1 | 50 % lägre chans i stället |
| Vulnerable | Tar 50 % mer skada | 3 | – |
| Weak | Gör 50 % mindre skada | 3 | – |

### 17.3 Allmänna regler

| Regel | Säkerhet |
|---|---|
| Läggs samma buff eller debuff på igen förnyas varaktigheten. De staplas inte. | Bekräftat (wiki) |
| Immune: kan inte få debuffar alls. | Bekräftat |
| "Always has": tas den bort kommer den tillbaka direkt, med nollställd potency men utan att on-apply-effekter utlöses. | Bekräftat (wiki) |
| Slumpade debuff-effekter kan lägga en debuff som målet redan har, och då förnyas varaktigheten. | Bekräftat (wiki) |
| Varaktighet räknas i ägarens turer. | Troligt (trait-texter som *Sarea's Haste* "förlorar 2 enheter per tur"; inte uttryckligt). Vår motor gör redan så. |
| Bara Resistant-versionerna ovan påverkas. Andra debuffar verkar fullt på bossar. | Bekräftat (Codex) |
| Barrier och Shelled: "efter att ha anfallit"-effekter utlöses inte när träffen bara tar Barrier eller Shelled. | Bekräftat (wiki) |

### 17.4 Leeching (VD:ns fråga)

- **25 % av skadan den gör.** Bekräftat (Codex).
- **Skada som Barrier tar:** Okänt. Siralims egen regel för "efter att ha anfallit" kräver skada på
  *liv* (Bekräftat). *Förslag (vårt val):* Leeching räknar bara skada som når livet, samma regel som
  originalet har för anfall. Det gör Barrier till ett riktigt motmedel.
- **Överskottsskada (mer än målet har kvar):** Okänt. *Förslag (vårt val):* räknas inte. Bara faktiskt
  förlorat liv. Annars blir ett jättekrit mot en nästan död fiende en fullhelning.
- **Skadesorter:** Codex säger "the damage they deal", utan undantag. *Förslag:* anfall, spells och
  traitskada som figuren gör räknas. DoT-tick (Burning, Poisoned) räknas också, eftersom de "görs" av
  angriparen. Okänt i originalet.
- Notera: trait-kompendiet har många Leeching-synergier (*Coming Undone*: +10 % stats efter anfall med
  Leeching, *Blood Weapon*: alltid Mending och Leeching). Det är en riktig byggsten.

### 17.5 Tidslinjen

| Regel | Säkerhet |
|---|---|
| Den som står överst agerar och läggs sedan längst ned. Speed ger bara startplatsen. | Bekräftat (Codex) |
| "Top of Timeline"-effekter flyttar en figur högst upp. Den som stod överst skickas då till botten. Används de på egna kan man förlora turer. | Bekräftat (wiki Combat) |
| Flyttas en figur till toppen nollställs dess gränser per tur (Action Limits). | Bekräftat (wiki Combat) |
| En boss som skulle tvingas till botten flyttas bara **ett** steg ned. | Bekräftat (Codex) |
| Bottom-of-Timeline-effekter fungerar inte på fiender i bosstrider. | Bekräftat (wiki Combat) |
| Snared: fast längst ned, 10 % chans att slita sig loss i början av varje figurs tur. | Bekräftat (Codex) |
| Exempel på traits: *Surprise!* (börjar överst), *Contradiction* (+200 % Speed men börjar längst ned), *Break the Cycle* (provocerar → slumpad fiende till botten), *Pocket Frog* (50 % chans att en allierad skickas till toppen). | Kompendium |

**Varning från originalet:** att skicka någon till toppen och nollställa gränserna ger oändliga turer
om två effekter matar varandra. Vår `TURN_LIMIT` och `once_per_turn` måste ligga kvar, och gränsen ska
**inte** nollställas av vårt eget "till toppen". *Vårt val, en avvikelse:* utan den regeln blir det
kedjor som telefonen inte hinner visa.

### 17.6 Ta bort buffar och debuffar

- *Dispel* (Sorcery-spell, 20 Charges): "Target's buffs and debuffs are removed", alltså **båda**
  sorterna på målet. Bekräftat (wiki).
- Fler spells för att ta bort, som byggguiden nämner: *Mass Dispel*, *Absolute Corruption*,
  *Reverse Polarity*. Exakt text: Okänt.
- Wikin: "Debuffs can be cleansed", utan detaljer. Siegemaster-perken *Shrug Off*: efter Defend tas
  debuffar bort och man får en slumpad buff per borttagen debuff. Bekräftat.
- Det finns ingen separat "Purge" i källorna. Okänt.

### 17.7 Visning

- Varje buff och debuff har en egen ikon, och Resistant-versionerna har egna ikoner. Bekräftat (wiki).
- Varaktigheter, minion-staplar och Realm Properties syns när man håller F i striden. Bekräftat (Codex).
  Var ikonerna sitter (under livmätaren eller annat): Okänt.
- *Förslag:* ikoner under livmätaren med en liten siffra för turer kvar, och håll inne för text. Det är
  Inspect hos oss. Rött för debuffar, guld för buffar.

### 17.8 Förslag: de ~20 som passar oss först (ljust tema)

Vi har redan: Barrier, Warded, Burning, Silenced, Vulnerable, Weak, samt egna (inspired, blessing, marked,
holy_shield, renew, salted, defend, provoke, lich_wrath).

**Buffar (12):** Agile, Arcane, Berserk, Defensive, Immune, Leeching, Mending, Protected, Rebirth,
Savage, Shelled, Taunting.

**Debuffar (10):** Bleeding, Blighted, Blind, Confused, Frozen, Poisoned, Scorned, Sleeping, Snared,
Stone.

Motivering: alla har tydliga regler och är lätta att se, och flera av våra traits och följeslagare väntar
på dem: Lirien (Sleeping), Tove (Agile, Scorned), Hulda (Snared, Poisoned), Ragnhild (Blighted), Sefir
(Savage, Bleeding), Arcane i stället för lägereldens Charges, och Taunting.

**Senare:**
- Proficient (artefakter): lätt, men liten effekt.
- Invisible: kräver målregler.
- Repelling, Disarmed och Bomb.
- Feared: vi har få stat-ökningar än.
- Splashing: kräver "intill", som vi inte har.
- Cursed, Inverted och Mania: komplexa. Inverted och Mania ges inte ens av slumpeffekter i originalet.

**Tonen:** inga av dem är ockulta. Bleeding och Poisoned är vanliga strids-effekter. Cursed kan vänta.

**Våra egna auror att mappa** (vårt val): holy_shield ≈ Protected (40 % i stället för 50 %) → byt till
Protected. renew ≈ Mending (fast 45 i stället för 25 %) → behåll eller byt. inspired (nästa anfall +30 %)
kan ligga kvar som vår egen, eller bli Berserk (+50 % i 3 turer).

## 18. Spell Gems och Rhea the Enchanter (underlag, 2026-10-19)

VD spelade början av originalet och såg ett uppdrag hos Enchantern bredvid Smedens. Inget är beslutat; huvudtråden
diskuterar med VD. Grundreglerna för Charges står i avsnitt 3 och 3b. Källa: wikins sida Spell Gems (läst i dag).

### 18.1 Reglerna

| Regel | Säkerhet |
|---|---|
| En varelse kastar bara spells från Spell Gems den bär. **3 platser**, aldrig två av samma spell, bara gems av **varelsens egen klass** (Chaos, Death, Life, Nature, Sorcery). Traits, perks och gem-egenskaper kan häva gränserna. | Bekräftat |
| Charges per gem, 1 per cast; fylls inte mellan striderna i en Realm, bara hemma (se 3b). | Bekräftat |
| **Rhea the Enchanter** i slottet tillverkar, uppgraderar och förtrollar gems. Allt kostar **Crystal**. | Bekräftat |
| **Inscriptions** = recept som krävs för att tillverka en gem. Förbrukas aldrig. | Bekräftat |
| **Tier 1–15.** Till skillnad från artefakter blir spellen *inte* starkare av högre tier: vid tier 5, 10 och 15 öppnas en egenskapsplats. Egenskapernas tal växer med tier. | Bekräftat |
| **Ethereal gems** fås i striden (t.ex. Generous): färre Charges, inga egenskaper, försvinner efteråt. Vissa spells finns bara så (Avatarernas Ultimate, Rune Knights runor). | Bekräftat |
| *Manuell* cast = vald i menyn eller av makro. *Automatisk* = utlöst av trait, perk eller spell. Silenced stoppar båda; en Resistant-varelse kan kasta med −50 % skada. *Sealed* låser en enskild gem. | Bekräftat |

### 18.2 Var recepten kommer ifrån

- Vanliga spells: **skattkistor** och **inskriptionsobelisker** i Realms.
- Vissa: köps av gudarna vid en viss nivå av Favor.
- Booze-spells: köps av spelande dvärgar (Notoriety). Arsenal-spells: köps i Arenan (Glory).
- Sent i spelet: från False Gods.

### 18.3 Styrka (potency)

Spells skalar med Intelligence om inget annat står. Orden i texten betyder fasta procent:

| Typ | Small | Moderate | Large | Massive | Devastating |
|---|---|---|---|---|---|
| Skada, % av Int | 90 | 110 | 120 | 130 | 150 |
| Skada, % Defense som ignoreras | 0 | 10 | 20 | 30 | 40 |
| Helning, % av Int | 30 | 60 | 90 | 120 | – |
| Stats, % | 20 | 40 | 60 | 80 | – |

Hos oss har några förmågor redan `tier` (moderate/large/massive) men `power` sätts fritt (t.ex. Helande ljus 300 %).
Tabellen kan bli vår skala om vi vill närma oss originalet. Det påverkar balansen och bör mätas.

### 18.4 Egenskaper (enchantments), hela listan

Material = en ädelsten per egenskap. **I 2.0 köps de i gudarnas butiker för 1 Emblem styck** (eller fås från Experiment-uppdrag);
uppgiften om fynd i Realms gäller äldre versioner (se 18.8). Alla egenskaper passar inte alla gems.

| Egenskap | Vad den gör | Material |
|---|---|---|
| Cascading | +5 % styrka per saknad Charge | Aquamarine |
| Casts On Extra Target | kastas även på en slumpad fiende till | Diamond |
| Class Swap | gemets klass byts | Opal |
| Damage Increased | mer skada | Moonstone |
| Duration Increased | längre buffar och debuffar | Jasper |
| Generous | övriga i laget får en ethereal kopia med 1 Charge | Jade |
| Healing Increased | mer helning | Obsidian |
| Magnetic | +15 % per likadan gem i laget | Beryl |
| Singular | +50 % per tom gem-plats hos varelsen (2.0; förut 30 %, som wiki.gg fortfarande anger) | Aventurine |
| Stat +/- Increased | starkare stat-ändringar | Malachite |
| Chance to Attack | chans att anfalla en slumpad fiende efter casten | Bloodstone |
| Chance to Cast After (handling) | chans att kasta efter Anfall, Försvara, Helning av annan eller Provocera | Citrine |
| Chance to Cast Twice | chans att kasta en gång till | Garnet |
| Chance to Defend | chans att Försvara efter casten | Carnelian |
| Chance to Provoke | chans att Provocera efter casten | Emerald |
| Defense Penetration | ignorerar en del av målets Defense | Azurite |
| More Charges | fler Charges | Agate |
| Potency Based On Attack / Defense / Health / Speed | en del av styrkan från en annan stat än Int | Onyx / Topaz / Tourmaline / Sapphire |

Flera av dem är regelbrytare av den sort ledstjärnan efterfrågar (Singular, Magnetic, Generous, Cascading,
Potency Based On Defense för en tank som kastar).

### 18.5 Jämfört med oss

| Siralim | Vi i dag |
|---|---|
| Spells på utbytbara gems, 3 platser | 2–3 förmågor som sitter fast på hjälten (`heroes.json` → `abilities`) |
| Bara gems av den egna klassen | Förmågorna har redan `school` (holy, fire, shadow), men det styr inget |
| Charges per gem, påfyllning hemma | Samma (3b) |
| Rhea: recept, tier, egenskaper | Ingen motsvarighet |
| Ethereal gems | Ingen motsvarighet (artefaktens automatiska kast liknar) |
| Valuta Crystal | Bara silver |

Det här är den största byggdelen som saknas efter troféer, artefakter och kall.

### 18.6 Frågor innan något föreslås

1. **Identitet.** Om förmågor kan bytas fritt blir hjältarna mer lika. Originalets klassregel håller isär dem:
   Alva (Life/holy) kan bara bära holy-gems. Vårt `school`-fält räcker nästan som klass. Behövs mer än så?
2. **Signaturen.** Ska signaturhandlingen sitta fast och övriga platser vara fria? *Inte originalets regel*
   (där är alla tre fria), alltså ett eget val (VAL) som kräver motivering.
3. **Recept som fynd.** Skattkammare och portaler kan ge Inscriptions, som i originalet. Passar troféjakten och
   Bestiariet.
4. **Valuta.** Silver eller en egen kristall? Originalet har en valuta per tillverkare (Brimstone hos Smeden,
   Crystal hos Rhea). Vi använder silver hos Smeden (anpassning). Samma anpassning här är enklast; en egen valuta
   ger mer att jaga.
5. **Tier.** 1–15 med platser vid 5/10/15 eller förkortat som artefakterna (1–10)? Om förkortat: platser vid
   t.ex. 3, 6 och 10.
6. **Intro.** Ett Rhea-uppdrag efter Smedens ("tillverka din första gem"), som originalet.

### 18.7 Vad motorn behöver (om det byggs)

- Förmågor som egna föremål i profilen (gem: spell, tier, egenskaper, Charges) i stället för en lista på hjälten.
- Klasskontroll vid utrustning (`school` mot hjältens skola).
- Egenskaperna som modifierare och triggers: de flesta finns redan som effekttyper (`cast`, `chance`,
  `modify_damage`, `aura`, `restore_charge`). Nytt: potency från annan stat, "per saknad Charge", "per tom plats",
  "per likadan gem", ethereal kopior.
- Makroredigeraren behöver redan visa förmågor per hjälte; den följer med om listan kommer från gems.

### 18.8 Komplettering (VD:ns andra källa, 2026-10-20)

VD tog fram en andra genomgång (Ultimate 2.0.x, med SÄKERT/TROLIGT). Det som ändrar eller fyller i ovan:

| Punkt | Uppgift | Säkerhet |
|---|---|---|
| Receptkällor och priser | Kistor och inskriptionsobelisker; gudarnas butiker för **10 Emblems**; Booze hos spelande dvärgar för 2 000 Notoriety; Arsenal i Arenan för 2 000 Glory; False Gods | Säkert |
| Rheas priser (Crystal) | Tillverka 2 000; tier 1→5 250 per steg, 5→10 1 000, 10→15 2 000; förtrolla 1 000 + material; ta bort gratis men materialet går förlorat | Troligt (äldre guide) |
| Material i 2.0 | Köps hos gudarna för 1 Emblem styck, eller från Experiment-uppdrag. Inte längre vanligt byte. | Säkert (2.0-patchnoterna) |
| Undantag från klassregeln | Class Swap (Opal); Evokers fem Mastery-perks (60 poäng var, hela laget får bära den klassen); samma perks som Anointment; Aurum-varelsens trait Pandora (alla klasser); ethereal gems | Säkert |
| Fler platser | Evokers *Expanded Mind*: +1 plats per rank, högst +5 (8 totalt) | Säkert |
| Charges per spell | **Spridningen är större än 4–8**: Magic Missile har 25, Recharge 1. Varje spell har sitt eget tal. | Säkert. Rättar 3b, som bara tog exempel ur den starka änden. |
| Återladdning | Inget mellan strider i samma Realm; fullt hemma; vid ny Realm enligt Codex (Troligt). Vissa Realm-förmåner fyller på (Path of the Damned, Favor 20: svampar). | Säkert / Troligt |
| Chance to Cast Twice | Den extra casten kan kosta en Charge | Säkert |
| Generous | Kopiorna har 1 Charge och försvinner efter striden; alla ethereal gems har inte 1 Charge | Säkert |
| Sällsynthet | Gems har ingen sällsynthetstrappa; utvecklingen är tier + egenskaper. Twisted gems och tier 30 hör till **3.0** och ska inte blandas in. | Troligt |
| Makron | Raden "cast <spell> på that creature"; makrocasting räknas som manuell. **Det finns troligen inget villkor "har Charges kvar"** i 2.0. | Troligt |

**Avvikelse att känna till:** vårt makrosystem har villkoret `has_charges` ("har Charges kvar på …",
`src/combat/macro_runner.gd`). Om originalet saknar det är det vårt eget val. I originalet hoppar en rad vars spell inte
går att kasta troligen över till nästa rad, vilket ger nästan samma resultat; exakt hur är inte belagt.

### 18.9 Rhea i 2.0: komplettering (VD:ns källa, 2026-10-20)

| Punkt | Uppgift | Säkerhet |
|---|---|---|
| Tjänster | Craft, Upgrade, Enchant, Disenchant. Craft, Upgrade och Enchant kostar Crystal. | Säkert |
| I introt | Rhea finns från början; introt skickar dig till henne **efter Sabon**, och där tillverkar och utrustar man sin första gem | Säkert |
| Första receptet | Varje Specialization börjar med ett eget spellrecept, så det finns något att tillverka direkt | Säkert (2.0) |
| Verkstadens ranker | **3 ranker**, taket för gemmens tier 5 / 10 / 15 (1 / 2 / 3 egenskapsplatser). Byggs som Projects hos Everett: rank 2 = 3 000 Granite, 10 Blood Candle, 1 Exquisite Crystal Ball, 1 500 Creature Parts, 300 Arcane Dust; rank 3 = 5 000 Granite, 25 Blood Candle, Spell Book, Soul Mirror, 2 500 Creature Parts, 500 Arcane Dust. | Ranker säkert; antal troligt |
| Enchant | Materialet avgör egenskapen (inget slumpmoment). Samma egenskap kan inte staplas på en gem; olika "Cast After"-utlösare kan kombineras, två Class Swap inte. | Säkert |
| Material | Gudarnas butiker, troligen från **Favor 4** (t.ex. Jade hos Azural), och Experiment-uppdrag | Säkert / troligt (Favor 4) |
| 2.0-värden | Cascading +5 % (förut 3 %), Singular +50 % (förut 30 %). Skada, helning och stat-egenskaperna stärktes också. | Säkert (patchnoterna) |
| Disenchant | Tar bort en egenskap; materialet och tidigare betald Crystal går förlorade; gem och tier finns kvar. Troligen gratis. | Säkert / troligt (avgift) |
| Tier och styrka | Wikins mekaniksida: tier ger bara platser. Spelets tutorialtext säger att tier ökar styrkan. **Motstridigt**; 3.0 annonserar ökad styrka och Charges per tier. | Troligt: bara platser |
| Undantag | *Sacrifice to the Light* kan inte tillverkas i 2.0, bara hittas | Säkert |
| I artefaktens spell-plats | Gemmens tier och egenskaper ignoreras (se 15.7) | Säkert |
| Mala ned gems | Hos Refinery, inte Rhea | Säkert |
| Totalpris (troligt) | Tier 1→15 = 16 000 Crystal; med tillverkning och tre egenskaper 21 000 plus material. Guiden själv anger 22 000, vilket inte går ihop. | Troligt |

**Mönstret hos både Sabon och Rhea:** tjänsten finns från introt, men taket (artefaktnivå, gemmens tier) höjs genom
Projects med föremål från utforskningen. Det är originalets koppling mellan Realm-innehållet (§19) och byggdelarna.

## 19. Vad man hittar i en Realm (underlag, 2026-10-20)

Fråga från huvudtråden: VD vill ha "mer spel" på rumskartan. Inget är beslutat. Källor: wikins sidor Realms,
Blessings, Gods, Nemesis, Nether Realm och Blood Grove (läst i dag), Codex. Säkerhet anges per rad.

### 19.1 Föremål och platser i en Realm

En Realm är en slumpad karta som man går fritt i. Bortom en viss synvidd är den mörk: gudarnas välsignelser
ger "Increased View Distance". Det mesta nedan ligger utspritt och måste letas upp.

| Sak | Vad den gör och ger | Hur vanlig | Tvingar utforskning? | Säkerhet |
|---|---|---|---|---|
| **Teleportation Shrine** | Vägen hem eller vidare. Används bara när Realm Questen är klar. | 1 per Realm | **Ja**: den är dold tills man hittar den. Välsignelse 9 avslöjar den från start, så normalt är den dold. | Bekräftat (Realms, Blessings) |
| **Gudens altare** | Realmens gud: ge resurser för Favor, köp i gudens butik för Emblems. | 1 per Realm | Ja, dold tills man hittar det. Välsignelse 16 avslöjar det. | Bekräftat (Gods, Blessings) |
| **Skattkistor** | Treasure: resurser, föremål, ibland Inscriptions och tillbehör. Det finns vanliga kistor, "Large Treasure Chests" och en egen kista per Realm. | Några per Realm; välsignelser ger +1 (tre gånger) | Ja | Bekräftat (Blessings, Blood Grove, Codex) |
| **Material-kistor** (tre färger) | Vanlig = 1 Amber; sällsynt = trick-material; legendarisk = trait-material | Utspridda | Ja | Bekräftat (Realms) |
| **Inscriptions** | Recept till Spell Gems (§18). När alla grundspells är hittade ger de Knowledge i stället. | Utspridda | Ja | Bekräftat (Realms) |
| **Emblems** | Gudens valuta, bara i gudens egen Realm | Några; välsignelser ger +1 | Ja | Bekräftat |
| **Resource Nodes** | Resurser (Blood Grove: Crystal). Ibland även ädelmetall eller kol. | Några; välsignelser ger +1 | Ja | Bekräftat (Blood Grove, Blessings) |
| **Breakables** | Krossbara föremål med smått byte | Många; välsignelser ger +1 | Valfritt | Bekräftat (Blessings) |
| **Ljus** (Candle) | Sällsynt. Tänds för +200 Favor hos Realmens gud. | Sällsynt | Valfritt | Bekräftat (Realms) |
| **Skattkarta** | Ritar ett rött X på kartan; man gräver upp skatten där | Ibland | **Ja**: skickar en till en viss punkt | Bekräftat (Realms) |
| **Treasure Golem** | Vandrar på kartan (i 2.0; före 2.0 sprang den undan spelaren). **I striden** försöker den fly varje tur (traitet Animated Treasure). Ger mycket skatt om man fäller den innan den flyr. | Slumpad | Delvis | Bekräftat (Blessings, Treasure Golem, japanska wikin) |
| **Dumpling** | Som golemen men ger mycket erfarenhet. Kan fly. | Slumpad | Delvis | Bekräftat (Blessings, Nether Realm) |
| **Mimic** | Ser ut som en kista men startar en strid | Slumpad | Fälla | Bekräftat |
| **Pandemonium Shrine** | Slumpad effekt: skatt, en Dumpling, strid mot Pandemonium King & Queen, ingenting, eller Favor hos alla gudar | Ibland | Valfritt | Bekräftat (Realms) |
| **Nether Realm-dörr** (från djup 21) | En liten egen bana. Exempel: taverna, korridor med skräp och en gycklare bakom, tre kistor (en med skatt, en med något dåligt, en tom; mimics), en kista med fyra kranar där kranarnas läge avgör innehållet, många kistor, 5 golems, en mini-boss som tappar sitt trait-material, en hantverkare som gör ett projekt gratis | Ibland | Valfritt; en överraskning bakom dörren | Bekräftat (Nether Realm, ofullständig lista) |
| **Otherworld Portal** (från djup 30) | Bossrum med en Exotic-varelse | Sällsynt | Valfritt | Bekräftat (Realms) |
| **Nether Boss-portal** (efter storyn) | Var 5:e djup | – | – | Bekräftat |
| **Divination Candle** (efter ett Project) | Välj en varelse och betala Power för att kalla fram 5 grupper av den | – | – | Bekräftat |
| **Realmens egna föremål** | Varje Realm har sina egna. Blood Grove: svampar (buff i resten av våningens strider), nomader (byter ved mot skatt), flöjter (kallar på satyrer; strid och Favor), fällor (Favor), grottor (mini-boss med svamp före och efter), squash (tre i kombination ger resurser eller en debuff på fienderna). Andra Realms: kemibord, frukt, tarotkort, musikkristaller med kombinationer. | Flera per Realm | Ja: de är Realmens personlighet | Bekräftat (Blood Grove, Steam-trådar) |
| **Mini-boss-rum** | Grottor eller rum med en starkare strid. Ger Favor och bättre byte. | Några per Realm | Valfritt | Bekräftat (Gods, Blood Grove) |
| **NPC:er med önskemål** | T.ex. Blood Groves nomader och "imp disputes". Gudens sida nämner "resolving imp disputes" som en källa till Favor. | Realm-bundet | Delvis | Bekräftat i exemplen; ingen samlad lista |
| **Projekt-föremål** | Föremål till slottets Projects: från fiender, Realm Quests eller "på marken" | Utspridda | Ja, när man jagar ett projekt | Bekräftat (Codex) |

**Lost Souls, nycklar och lönnrum:** jag hittade inget om dem i Ultimate. Nycklarna som finns är Gate of the
Gods-nycklar, och de kommer från Nether Bosses och Keyforge-uppdrag, inte från låsta dörrar i en Realm. "Lönnrum"
motsvaras närmast av Nether Realm-dörrarna. *Ej belagt: kan finnas i spelet utan att stå på wikin.*

**Gudarnas Favor** fås av: gåvor vid altaret, Realmens föremål (+25), föremål som startar strider (+50),
mini-boss-rum, Realm Quest (+200) och särskilda NPC-händelser. Favor-ranker ger välsignelser i just den
Realmen: fler kistor, noder och Emblems, längre synvidd, ett avslöjat altare eller en avslöjad Shrine. Det är
originalets drivkraft för att gå tillbaka till samma Realm. (Bekräftat, Gods och Blessings)

### 19.2 Hur striderna börjar

- **Synliga fiendegrupper som vandrar omkring** ("wandering groups") på kartan. Man går in i en grupp för att
  starta en strid. Nemesis-varelser "vandrar som andra grupper" men har en varningstext över sig (t.ex. Hearty,
  Thorns, Greedy: dubbelt liv, reflekterad skada, extra byte). (Bekräftat, Nemesis)
- Dessutom startar föremål strider: flöjter, mimics, benhögar och Pandemonium.
- Slumpmöten per steg har jag inte sett belagda i Ultimate (Siralim 3 hade dem). *Troligt: inga slumpmöten.*
- **"Enemies: 2" på minikartan:** antagligen antalet vandrande grupper som är kvar. *Ej belagt.* För False God-
  uppdragen ska man "besegra alla fiender i Realmen" (5 grupper med runor), så gruppernas antal är räknebart och
  ändligt. (Bekräftat, Codex/Guilds)

### 19.3 Realm Quests

- En slumpad quest per Realm. Den måste klaras innan Teleportation Shrine låter en åka hem eller vidare. Faller
  laget, eller sparar man och laddar om, får man en ny quest nästa gång. (Bekräftat)
- Belöning: skatt, Perk Points (10 på det djupaste djupet), +200 Favor, ett Emblem på det djupaste djupet och
  +20 % Fortune. (Bekräftat)
- **Typerna:** ingen källa listar dem; wikin saknar en sida om dem. Från spelet och Siralim 3 är jag ganska säker
  på att det finns quests av typen *besegra ett antal av en viss varelse* (jaga den sorten på kartan) och *samla
  ett antal föremål* som ligger utspridda eller tappas av fiender. Båda skickar spelaren runt hela kartan.
  *Osäkert, inte belagt: andra typer.* VD kan läsa questens text i spelet; det är snabbaste vägen till en lista.

### 19.4 Storlek och tid

Ingen källa anger kartans storlek eller tid per Realm. *Osäkert (spelarvana):* en Realm tar ungefär 5–15
minuter; den som ska klara questen, hitta Shrinen och plocka kistorna går över större delen av kartan, med
kanske 5–10 strider. Kontrollera gärna mot VD:ns eget spelande.

### 19.5 Bedömning: vad som passar en nodkarta på telefon

**Passar bra** (fungerar som rum eller noder utan fri gång):
- **Dold utgång och dimma:** utgången (Shrine) och altaret är dolda tills man hittat dem. Det är originalets
  starkaste skäl att utforska och går direkt att göra med "rum som inte syns förrän man står bredvid".
- **Synliga fiendegrupper med varning:** fiender som står i rum och syns innan man går in (Nemesis med text).
  Matchar redan vår Elit och avsikter.
- **Kistor, materialkistor och skattkarta:** skattkartan pekar ut ett rum med X. Bra skäl att gå omvägar.
- **Nether-dörrar som "?"-rum:** en egen liten händelse bakom dörren (tre kistor, kranarna, taverna). Svarar på
  VD:ns önskan om överraskning.
- **Realmens egna föremål:** svampar (buff för våningen), fällor, en NPC som vill ha något. Ger Realmen
  personlighet; några per Realm räcker.
- **Treasure Golem:** i originalet är flykten en regel *i striden* (den försöker fly varje tur), inte på kartan. Den går
  direkt att göra som en strid: fäll den innan den flyr. *Vårt val vore* ett rum som försvinner efter N steg; det finns inte
  i 2.0.
- **Quest-typer som skickar runt:** "besegra 3 av X" och "samla 3 föremål" kräver ett nät, inte en enkelriktad
  väg.
- **Favor per Realm:** belönar att gå tillbaka till samma Realm (synvidd, fler kistor), som VD vill.

**Kräver fri gång och passar sämre:**
- Breakables och resursnoder i stora mängder: på en nodkarta blir det bara "tryck för silver". Slå ihop dem till
  kistans byte.
- Vandrande grupper som rör sig och jagar: rörelse i realtid passar inte en turfri karta. *Kompromiss:* grupper
  som flyttar ett rum när spelaren rör sig, men det är vårt eget val.
- Synvidd i rutor och att leta i hörn.
- Projekt-föremål "på marken": vi har inga Projects.

**Skepsis:** att gå tillbaka i ett rumsnät är originalets känsla, men varje steg tillbaka på en telefon är ett
tryck utan innehåll. Originalet löser det med att kartan är full av saker. Ett nät på 10–15 rum fungerar bara om
nästan varje rum har något, och om utgången är dold så att man har ett skäl att leta.

### 19.6 Komplettering (VD:ns andra källa, 2026-10-20)

| Punkt | Uppgift | Säkerhet |
|---|---|---|
| Fog of war | Patch 2.0 gjorde om den: förut syntes hela kartans form, nu måste även formen upptäckas | Säkert |
| Strider | Kontakt med synliga, vandrande grupper; dessutom kartföremål (t.ex. Worm Pits och Hives i Forbidden Depths). Inga stegslumpmöten belagda men inte heller uteslutna. | Troligt |
| Synvidd | Blessings vid Favor 8, 31 och 55; Shrine syns från start vid 9, altaret vid 16 | Säkert |
| Realm Boosts | Gäller i alla strider sedan 2.0; vissa gäller bara nästa strid | Säkert |
| Fler kombinationer | Forbidden Depths: musikkristaller (A+B Power, A+C buff för dina i Realmen, B+C debuff för fienderna); Refuge of the Magi: kemibord | Säkert |
| Tid | 5 respektive 15 minuter för full utforskning (två spelare, före 2.0) | Troligt |

**Realm Quest-typer som går att belägga** (ingen fullständig lista för 2.0):

- **Samla** föremål (t.ex. drycker i Caustic Reactor; patch 0.4.0). Säkert historiskt.
- **Gräv upp skatt** efter skattkartans X. Säkert.
- **Undersök eller förstör** utpekade föremål på kartan. Säkert (japanska wikin).
- **Sök upp personer** som placerats på kartan: rekryter, förrädare, invånare, förrymda varelser. Säkert (japanska wikin).
- **Gåtdvärgen:** försök svara på gåtor; fel svar hindrar inte att questen klaras. Säkert (japanska wikin).
- **Besegra bossen** på Nether Boss- och False God-våningar. Säkert.
- Rädda eller eskortera: **inte belagt.** Vår questtyp "Rädda" och fånge-rummen för lärjungar är alltså vårt val.

Det stärker bedömningen i 19.5: nästan alla typer skickar spelaren till utspridda platser, så de kräver ett nät där man
kan välja väg och gå tillbaka. "Sök upp personer" ligger nära våra fånge-rum.

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
- Slott och Projects: [Projects (wiki)](https://siralimultimate.wiki.gg/wiki/Projects), Codex-avsnitten Castle och Realms
- [Cleric](https://siralimultimate.wiki.gg/wiki/Cleric), [Siegemaster](https://siralimultimate.wiki.gg/wiki/Siegemaster), [Steam: Speed stat](https://steamcommunity.com/app/1289810/discussions/0/3096760955426011883/), [Steam: new player question (krit)](https://steamcommunity.com/app/1289810/discussions/0/3467226415503450035/), [S3: speed → crit/dodge](https://steamcommunity.com/app/841770/discussions/0/1642042464747022009/)
- Charges: [Spell Gems](https://siralimultimate.wiki.gg/wiki/Spell_Gems), [Benediction](https://siralimultimate.wiki.gg/wiki/Benediction), [Breath of Life](https://siralimultimate.wiki.gg/wiki/Breath_of_Life), [Holy Armor](https://siralimultimate.wiki.gg/wiki/Holy_Armor), [Fireball](https://siralimultimate.wiki.gg/wiki/Fireball)
- Realm-innehåll (§19): [Blessings](https://siralimultimate.wiki.gg/wiki/Blessings), [Gods](https://siralimultimate.wiki.gg/wiki/Gods), [Nemesis](https://siralimultimate.wiki.gg/wiki/Nemesis), [Nether Realm](https://siralimultimate.wiki.gg/wiki/Nether_Realm), [Blood Grove](https://siralimultimate.wiki.gg/wiki/Blood_Grove), [Steam: kombinationer i Realms](https://steamcommunity.com/app/1289810/discussions/0/3189112650406353420)
- [Steam-diskussion om fusion](https://steamcommunity.com/app/1289810/discussions/0/5767400709485797483),
  [Steam-diskussion om instability](https://steamcommunity.com/app/1289810/discussions/0/5710018482973776302)
- Mobilbetyg och styrning: [worldsapps](https://worldsapps.com/reviews-siralim-ultimate), [grand-screen](https://grand-screen.com/games/siralim-ultimate/reviews/)
