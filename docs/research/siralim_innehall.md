# Siralim Ultimate – innehåll för De edsvurna (underlag för 0.17)

Sammanställt 2026-10-19 av Researchtråden på uppdrag av Huvudtråden. Kompletterar
[`siralim.md`](siralim.md). Engelska Siralim-termer enligt [`docs/ordlista.md`](../ordlista.md).

Säkerhet: **Bekräftat** = Codex (spelets egen text, version 2.0.37) eller wikin. **Kompendium** =
communityns trait-kompendium (version 1.1.0, kan ha ändrats sedan). **Vårt val** = förslag.

## 1. Realm Properties och Realm Instability → våra våningsregler

### Originalet (Bekräftat, Codex)

- Varje Realm har några **Realm Properties** som gör fienderna starkare eller hindrar laget. Ju svårare
  properties, desto större belöning. Man kan slumpa om dem vid Teleportation Shrine.
- **Realm Instability** 0–5 (efter bossen på djup 33):
  - varelser från andra Realms dyker upp
  - properties blir starkare
  - **dolda** properties läggs till och syns först inne i Realmen
  - fiender kan vara sammansmälta (Fused).
- Wikin säger "två properties per nivå, en synlig och en dold". Bytet stiger med upp till +400 %.
- Properties visas med F i striden (vi: håll inne, som Inspect).

**Properties mot spelaren:** Bad Luck (era slumpeffekter slås om en gång till), Can't Deal Critical
Damage, Can't Defend/Provoke, Can't Dodge, Can't Gain Gems, Can't Gain Traits, Can't Resurrect,
Damage Every Turn x %, Debuff: X vid start, Gems Sealed After Casting, Less (Stat) x %, Less Charges,
Less Damage Dealt, Less Healing, Less Indirect Damage, Less Spell Potency, Less Stat Gain, Maximum
Buffs x, More Damage Taken, No Additional Attacks/Casts, Stats are Swapped.

**Properties för fienderna:** Always Critical Damage, Attack/Cast Additional Times, Buff: X, Chance to
Dodge, Chance to Resist Damage, Copy your Spell Gems, End of Turn: Attack / Cast / Defend / Provoke,
Extra (Stat), Extra Traits, Good Luck, Heal Every Turn, Less Damage Taken, Less Stat Loss, Minion: X,
More Damage Dealt, More Spell Slots, Reflect Damage Taken, Resistant to Debuffs, Resurrect on Death
(första döden: 25 % liv), Strong Against (Class).

**Properties för Realmen:** Enemies Belong To Same Race, Extra Nemesis Creatures, Inhabited by X
Race, Rapid Fatigue.

### Förslag: tio våningsregler (Vårt val, alla med förebild i originalet)

Regeln visas vid Kryptporten och i striden. Varje regel ger mer silver. Instabilitet blir en inställning
vid Kryptporten: nivå *n* ger *n* synliga och *n* dolda regler. De dolda syns när striden börjar.

| # | Våningsregel | Effekt | Förebild | Silver | Varför den är rolig |
|---|---|---|---|---|---|
| 1 | De döda vaknar | Varje fiende återuppstår en gång med 25 % liv | Resurrect on Death | +30 % | Ändrar vem man fokuserar och gör död-traits starkare |
| 2 | Förseglade ord | En förmåga som har använts förseglas resten av striden | Gems Sealed After Casting | +30 % | Gör Charges och makrons cast-rader till ett verkligt val |
| 3 | Tung luft | Ingen kan undvika | Can't Dodge | +10 % | Liten men tydlig, och slår mot Eira och snabba lag |
| 4 | Vissnad nåd | Helning är 40 % svagare | Less Healing | +20 % | Tvingar fram Barrier och Defend i stället för Alva |
| 5 | Vaksamma vakter | Fiender försvarar sig i slutet av sin tur | End of Turn: Defend | +20 % | Väktarens ed (Titanic Rage) blir plötsligt stark |
| 6 | Förbannad mark | Alla i sällskapet tar 5 % av max liv i början av sin tur | Damage Every Turn | +20 % | Klocka som tickar. Belönar snabba lag |
| 7 | Speglande ben | 20 % av skadan på fiender studsar tillbaka | Reflect Damage Taken | +25 % | Gör Hämndens ed till ett svar på ett svar |
| 8 | Svaghetens dimma | Sällskapet börjar med Weak (−50 % skada) i 2 turer | Debuff: X | +15 % | Belönar att man tar bort debuffar och spelar defensivt först |
| 9 | Inga bönder | Ingen kan Provoke eller Defend | Can't Defend/Provoke | +40 % | Stänger av hela byggen. Bara som dold regel på hög instabilitet |
| 10 | Kaosvind | Varje hjältes Attack och Defense byts vid stridens start | Stats are Swapped | +40 % | Vilt. Brokk blir glaskanon. Bara på instabilitet 3+ |

Motorn behöver: modifierare för hela striden (dodge av, heal_mult, reflect), en `battle_start`-trigger,
en "end of turn"-handling för fiender, och "sealed" per förmåga. Regel 1 och 8 går med det som finns
(revive, aura).

## 2. Regelbrytande creature traits → troféer

### Vad som gör ett trait omtyckt i Siralim

Spelare bygger hela lag kring traits som ändrar en **regel** snarare än en siffra. Det finns tre
sorter:

1. **Ordning:** *Surprise!* (Mimic) börjar alltid överst på Timeline. Bekräftat (wiki).
2. **Lagidentitet:** *Outcast No Longer* (Clawing Cockatrice) gör de tre sista i laget till samma ras
   som den första. *Brothel* (Regalis) delar innate traits mellan figurer av samma klass. Kompendium.
3. **Masters:** *Master of Skeletons*: om alla är Skeletons anfaller de en extra gång och kritar alltid.
   Kompendium. Siralims Masters ger alltså en belöning för rena lag.

### 20 troféer ur våra fiendetyper

Kryptan: skelettkrigare, -bågskytt, gravpräst, gravväktare, glödskelett, Benfursten. För kapellet
antar jag fiendetyper som präst, ängel, gargoyle, kultist (Occultist), banshee, spöke (Spectre) och imp.
**Mappa om till de verkliga 0.16-typerna.** Alla förebilder är ur Kompendium, utom där det står annat.

| Trofé (vårt namn) | Från | Effekt hos oss (vårt val) | Förebild i Siralim |
|---|---|---|---|
| Kaparens första hugg | Skelettkrigare | Bärarens första anfall i striden gör +200 % | *All In* (Skeleton Buccaneer: +300 %) |
| Prickskyttens öga | Skelettbågskytt | Anfall mot mål med fullt liv gör +150 % | *Aimed Shot* (+200 %) |
| Snabbt tag | Skelettbågskytt | Efter anfall 40 % chans att anfalla samma mål igen | *Quick Shot* (50 %) |
| Splitterben | Glödskelett | Efter anfall tar alla andra fiender 30 % av skadan | *Scatter Shot* |
| Benmästarens bröstsköld | Benfursten (boss) | Om alla i sällskapet bär en skelett-trofé anfaller de en extra gång | *Master of Skeletons* |
| Ljusets bärare | Präst | I början av bärarens tur helas de andra för 10 % av bärarens max liv | *Bearer of Needs* (15 %) |
| Strålande förmörkelse | Präst | I början av bärarens tur får sällskapet Barrier för 10 % av bärarens max liv | *Radiant Eclipse* |
| Krigsprästens hand | Präst | I början av bärarens tur tas 1 debuff bort från de andra | *Disciple of War* (2) |
| Själaskördaren | Ängel | Efter anfall kopierar bäraren målets trofé eller trait resten av striden | *Soul to Keep* (Angel Soulslayer). En stark regelbrytare |
| Barmhärtighetens slut | Ängel | I början av bärarens tur dör alla fiender under 15 % liv | *Final Act of Mercy* (25 %) |
| Kaosets hjärta | Gargoyle | Om bäraren har använt en förmåga i striden återuppstår hen en gång med 50 % | *Heart of Steel* |
| Fantasm | Kultist | Förmågor gör 20 % mer skada per gång de redan använts i striden | *Phantasm* (30 %) |
| Förseglingen | Kultist | När en fiende använder en förmåga förseglas den resten av striden | *Seal Magic* |
| Sareas intrig | Kultist | Bäraren gör 10 % mer skada per gång hen träffats i striden | *Sarea's Plot* (15 %, hela laget) |
| Skuggans ackord | Banshee | När bäraren flyttas till toppen av Timeline får de andra Invisible | *Vlora's Haunting*. Kräver top-of-Timeline-effekter |
| Saltad jord | Spöke | När bäraren försvarar sig eller provocerar förlorar fienderna 20 % Defense | *Salted Earth* (30 % Defense och Speed) |
| Skuldens tyngd | Spöke | När en fiende helas förlorar den 25 % Attack | *Unspeakable Sins* (35 %) |
| Den lilla extra | Imp | 15 % chans att bäraren får en extra tur | *Hee Hoo Ha* (Imp Impington, hela laget) |
| Mirakel | Imp | Bärarens förmågor har 30 % chans att kastas en gång till, utan Charge | *Miracle of the Mind* (50 %, hela laget) |
| Överraskning! | (sällsynt, valfri) | Bäraren börjar alltid överst på Timeline | *Surprise!* (Mimic). Bekräftat |

Urval efter ledstjärnan: varje trofé ändrar *när* eller *hur* något händer, inte bara hur mycket.
Flera passar ihop och bildar byggen:
- Snabbt tag + Hämndens ed
- Fantasm + Mirakel
- Saltad jord + Väktarens ed
- Själaskördaren + vilken trofé som helst
- Överraskning! + Kaparens första hugg

Siralims Masters-belöning (krav på ett rent lag) passar en trofé från bossen.

## 3. Bossdesign → tre bossidéer

### Originalet (Bekräftat, Codex)

**Nether Bosses** har ett enda regelbrytande trait i tre svårighetsgrader. Exempel:
- *Nerlyx – Evil Eye:* låser i slutet av sin tur på ett mål och gör i början av nästa tur 10 000 % skada,
  eller bara 300 % om målet försvarar sig.
- *Myrtle – Ravenous:* immun mot skada så länge hennes allierade lever, och tar 50 % av statsen från
  varje figur som dör.
- *Ceaseless Gladiator – Undying:* tar all skada åt sina allierade och får Shelled efter varje träff.
- *Loid:* efter att ha anfallit blir man Scorned, efter en cast blir man Silenced.
- *Kiichi:* Bleeding som sprider sig till alla.

**False Gods** har kroppsdelar med egna traits:
- *Caliban:* huvudet provocerar, och hjärtat försvarar sig och kan bara skadas när de andra delarna är
  försvagade.
- *The Ancestor:* huvudet dödar alla som inte försvarar sig.
- *Imp Impington Reborn:* handen skickar den översta fienden till botten av Timeline.

Gemensamt: **regeln syns och har ett tydligt svar** (Defend, döda i rätt ordning, sluta casta).

### Tre bossar för oss (Vårt val)

**1. Klockaren** (kapellets boss, förebild Nerlyx)
- *Avsikt:* i slutet av sin tur klämtar Klockaren för en hjälte ("Klockan klämtar för Eira").
  Märket syns över hjälten.
- *Regelbrytare:* i början av nästa tur tar den märkta 300 % av Klockarens Attack, men bara 50 % om hen
  försvarar sig.
- *Svar:* Defend, eller att Brokks Stenmur skyddar. Lär spelaren makroraden "om denna hjälte är märkt
  → Försvara".
- *Trofé:* "Klockans eko". Bärarens Defend ger också nästa anfall +50 %.

**2. Den fördärvade abbedissan** (förebild False God Caliban)
- Kroppsdelar som egna mål: *Abbedissan* (hjärtat), *Vänstra ljuset* och *Högra ljuset*.
- *Avsikt per del:*
  - Vänstra ljuset helar de andra delarna i början av sin tur.
  - Högra ljuset provocerar, så att alla anfall dras dit.
  - Abbedissan anfaller hela sällskapet med en spell.
- *Regelbrytare:* Abbedissan kan bara skadas när båda ljusen är släckta (under 0 liv: de släcks, dör
  inte, och tänds igen efter 3 turer).
- *Svar:* ordning och tempo. Släck båda och slå Abbedissan innan de tänds. Provoke på Högra ljuset gör
  att Hämndens ed inte når fram.
- *Trofé:* "Ljusbärarens veke". När bäraren dör tänds hen igen en gång med 30 % liv efter 2 turer.

**3. Gravbiskopen** (förebild Myrtle)
- Biskopen och två benkorister.
- *Avsikt:* en korist sjunger en "psalm" som syns: nästa tur ger den alla fiender +30 % Attack.
- *Regelbrytare:* Biskopen är immun mot skada så länge en korist lever, och får 50 % av statsen från
  varje figur som dör, även era hjältar.
- *Svar:* döda koristerna i rätt ordning och låt ingen i sällskapet dö. Hämndens ed blir riskabel
  (Execution Sentence), medan Gryningens ed lyser.
- *Trofé:* "Biskopens hunger". Efter att en fiende dör får bäraren 15 % av dess Attack.

Varje boss ger i Siralims anda också en **Anointment-plats** (beslut 13b i `siralim.md`).

## 4. Beslut: vår motsvarighet till Fusion (Huvudtråden, 2026-10-19)

Fusion i Siralim (Bekräftat, Codex): avkomman ärver båda föräldrarnas traits, deras genomsnittliga
basstats och den andra förälderns klass. Det går inte att ångra, och båda föräldrarna försvinner. Varje
varelse får till slut egen + ihopsmält + artefaktens trait, och Nether Stones kan ge fler.

1. **Troféer flyttas fritt** mellan striderna, som i dag. Trofén fyller Fusionens plats i bygget.
2. **Bosstroféer kräver tre segrar mot samma boss**, som Siralims Masters (Trait Material efter tre
   segrar). Byggs troligen i 0.17 med de nya bossarna.
3. **Invigning väntar tills vi har cirka 20 troféer.** Då blir den en permanent extra egenskapsplats per
   hjälte (motsvarar både Fusions arv och Nether Stones). Den är dyr i silver och troféer, så att den
   blir ett långsiktigt mål.

## Källor

- [Codex Reference (Steam-guide, spelets Codex 2.0.37)](https://steamcommunity.com/sharedfiles/filedetails/?id=2197484456):
  Realm Properties (Player/Enemy/Realm), Realm Instability, Nether Bosses, Guilds and False Gods.
- [Wiki: Realms](https://siralimultimate.wiki.gg/wiki/Realms), [Wiki: Mimic](https://siralimultimate.wiki.gg/wiki/Mimic).
- Trait-kompendium: [Siralim Ultimate Compendium – Traits.csv (version 1.1.0)](https://github.com/berated-bert/siralim-planner/tree/master/data/siralim-ultimate-compendium),
  via [Siralim Planner](https://berated-bert.github.io/siralim-planner/).
- [Bloodmage Build Guide (Brothel)](https://gameplay.tips/guides/10177-siralim-ultimate.html).
