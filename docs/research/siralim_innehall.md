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

## 5. Vandring mellan striderna: rumskarta (beslut, byggs troligen i 0.18)

Beslut (användaren och Huvudtråden, 2026-10-19): **3D bara i striderna.** Mellan striderna finns en
**2D-rumskarta på pergament** med 2–3 vägar per steg. Realm Quest blir körningens mål.

**Originalet (Bekräftat, Codex):** en Realm är en slumpad karta man går runt i. Där finns kistor,
inskrifter, ljus (gunst hos guden), Pandemonium-helgedomar, skattkartor och portaler till Nether Realms.
Varje Realm ger en kort, slumpad Realm Quest som måste klaras innan man får åka vidare. Den ger
belöning, +20 % Fortune och de enda Perk Points som finns.

### Rumstyper

| Rum | Vad som händer | Förebild i Siralim |
|---|---|---|
| Strid | Vanlig strid, sedan trofé-val | strider i Realmen |
| Elit | Svårare strid med en extra trait, bättre trofé-chans | Nemesis-varelser, Realm Properties |
| Skattkammare | Silver, ibland en trofé eller ett material | kistor, skattkartor |
| Helgedom | Välj: en gåva eller en slumpad effekt (buff, förbannelse eller våningsregel) för nästa strid | Pandemonium Shrine, gudarnas Blessings |
| Inskrift | Ny förmåga att lära vid Runristaren | Inscriptions |
| Fånge | Värva en följeslagare eller få en tjänst | upplåsning av varelser |
| Lägereld | Liv fylls (Charges fylls inte) | liv efter strid |
| Portal | Liten sidodel: 1–2 rum med risk och belöning | Nether Realm, Otherworld Portal |
| Boss | Våningens slut | Nether Boss eller story-boss |

### Storlek (vårt val)

- 3 våningar per körning, som i dag. Varje våning har **5–7 rum i 3–4 steg** och sedan våningens slut.
- Per våning: minst 2 strider, högst 1 elit, 1 helgedom eller skattkammare och 1 lägereld före bossen.
- Varje steg erbjuder 2–3 vägar, och nästa steg syns, så att man kan planera.
- En körning blir då ungefär 9–12 strider, mot 3 i dag. Det gör Charges per körning (§3b i `siralim.md`)
  till ett verkligt hushållsbeslut, som i Siralim.

### Realm Quest-typer som passar oss

Siralims quests är korta och slumpas per Realm. Exakt vilka typer som finns är inte belagt. Förslag:

1. **Jakt:** besegra en namngiven fiende (Nemesis) som finns på ett av rummen.
2. **Samla:** hitta 3 reliker utspridda i skattkammare och helgedomar.
3. **Rensa:** vinn 3 elitstrider.
4. **Rädda:** nå fången på våning 2 och ta hen med till slutet. Om sällskapet faller är hen förlorad.
5. **Prov:** vinn en strid med en viss regel (t.ex. utan helning eller med en våningsregel).
6. **Rening:** besök och tänd 3 helgedomar.

Belöning: perk-poäng (Siralims enda källa till Perk Points), silver och eventuellt en garanterad trofé.
Klarar man inte questen går körningen ändå att avsluta, men utan belöningen. Det är vårt val, mildare
än Siralim, där questen krävs för att lämna Realmen.

## 6. Värdshuset och nya följeslagare

### 6.1 Vad som gör Siralims varelser unika och åtråvärda

| Drag | Hur det fungerar | Säkerhet |
|---|---|---|
| Ett unikt trait | Varje varelse har ett eget, innate trait som "ändrar hur den strider". Inga två är lika. | Bekräftat (Codex) |
| Ras (Race) | Cirka 6 varelser per ras. Klass, traits och stats inom rasen samspelar. Mastery-traits belönar lag med en enda ras (*Master of Skeletons*). | Bekräftat (Codex); Mastery-traits: Kompendium |
| Klass | 5 klasser (Life, Nature, Chaos, Death, Sorcery). Klassen avgör vilka Spell Gems varelsen kan bära. Stark eller svag mot andra klasser ger ×2 / ×½. | Bekräftat |
| Statprofil | Fem stats med en tydlig profil (Mimic: H30 A24 I23 D23 S8, summa cirka 108–110). Personlighet: en stat växer 40 % per nivå, en 20 %, resten 30 %. | Bekräftat (wiki, Codex); summor: planerarens creatures.csv |
| Var de finns | Varje Realm har sin lista över varelser. Varelser kallas fram för 100 % Mana, som man oftast får genom att besegra dem. Andra kommer från uppdrag, gudarnas butiker (Emblems), Otherworld-portaler (Exotics) eller Projects (Godspawn). | Bekräftat (Codex, wiki) |
| Upplåsning över tid | Varje ras har några varelser från start. En ny låses upp var 15:e djup (15, 30, 45 …). | Bekräftat (FAQ) |

Varelser blir åtråvärda för att traitet öppnar ett nytt bygge, för att de bara finns på ett visst ställe
och för att man vet att fler kommer på djupare nivåer.

**Hos oss** (följeslagare är personer, inte varelser):
- *Unikt trait:* varje följeslagare har en regelbrytare som är grunden för ett bygge.
- *Ras och klass:* klassisk fantasy (dvärg, alv, människa …). Klassen styr förmågorna. Senare kan
  "samma ordning" ge en bonus, som Siralims Mastery.
- *Var de finns:* varje följeslagare hör hemma i en viss Realm och syns i Bestiariet och Kampanjkartan
  som "Okänd: hörs viskas om i kapellet".
- *Mana blir Förtroende:* i stället för att döda varelsen räddar man personen (fånge-rummet) eller klarar
  hens uppdrag.

### 6.2 Sex nya följeslagare (vårt val, med förebild i Siralim)

**Tonregel (VD:n, 2026-10-19), gäller alla framtida följeslagare:** inget riktigt ockult: inga
warlocks, dödsbesvärjare, demonpakter eller mörka kulter bland följeslagarna. Mörkret och ondskan är
fienden. I övrigt är allt tillåtet. Alla behöver inte vara perfekta helgon: någon får gärna vara lite
trasslig (ett förflutet, ett hett humör, en svaghet), men alla behöver inte ha ett problem. Det är en
blandning, som i verkliga livet. Siralims mekanik får gärna lånas, men temat behöver inte följa originalet.

**1. Ronja Falkvind.** Människa, falkenerare från fjällen. Glad och rak, men tjuvjagade på kungens
mark och har svårt att lyda order. Falken Stormvinge följer henne överallt.
- *Trait, Falkens vakt:* när en fiende visar en avsikt mot en allierad dyker Stormvinge ned. Fienden
  flyttas 1 steg ned på Timeline och blir märkt (högst en gång per tur). Förebild: Siralims
  top/bottom-of-Timeline-effekter (Snared, *Imp Impington*) och minions som agerar själva. Regelbrytaren
  är att avsikterna, vår egen mekanik, blir något man kan svara på automatiskt.
- *Förmågor:* Dykattack (falken slår 120 %, och +50 % mot märkta, 8), Spejarflykt (märker alla fiender i
  2 turer, 5), Vingskugga (en allierad får Agile i 2 turer: extra chans att undvika, 6).
- *Stats:* 650 / 80 / 60 / 25 / 15.
- *Samspel:* Eira (*Jägarinstinkt* mot märkta), Sefir och Bågskyttens sena (alltid krit mot märkta), och
  Hämndens ed: fienden hinner slå färre gånger.

**2. Lirien Silversträng.** Alv, bard. Charmig, fåfäng och spelar bort sin gage innan den är intjänad.
- *Trait, Allsång:* när Lirien ger en allierad en buff får alla andra i sällskapet samma buff i 1 tur.
  Förebild: Warden (de flesta händelser ger buffar) och Priest Vizier *Fanaticism*.
- *Förmågor:* Stridssång (en allierad får Styrka i 3 turer, 6), Vaggvisa (en fiende somnar, Sleeping,
  5), Hjältens ballad (en allierad flyttas till toppen av Timeline, 4).
- *Stats:* 620 / 60 / 85 / 20 / 13.
- *Samspel:* Brokks Stridsrop, Gryningens ed (*Holy Might*: skada per buff). Hjältens ballad på Eira ger
  ett extra skott direkt.

**3. Broder Tove.** Människa, munk. Lugn nu, men var legosoldat förr och bär på det.
- *Trait, Spegelhand:* när Tove undviker ett anfall kontrar hen för 100 % och får +10 % Speed (resten av
  striden). Förebild: Monk-specialiseringen (undvika och kontra).
- *Förmågor:* Vindsteg (Agile i 3 turer: extra chans att undvika, 6), Tryckpunkt (anfall 100 % och
  Scorned, 8), Stilla vatten (Defend och tar bort alla debuffar, 6).
- *Stats:* 750 / 85 / 40 / 25 / 16. Kräver undvikande från §12.
- *Samspel:* Väktarens ed: en munk som provocerar och undviker blir en tank utan Defense. Med Hämndens ed
  blir varje träff runt hen ett motanfall.

**4. Hulda Mossrot.** Skogsrå, druid. Klok men misstänksam mot människor, och glömmer aldrig ett fällt träd.
- *Trait, Rotverk:* Huldas förmågor ger målet en stapel *Rotskott* (minion, högst 3). När bäraren tar
  skada slår varje rotskott angriparen för 15 % av Huldas Int (indirekt). 25 % chans att ett rotskott
  vissnar i början av bärarens tur. Förebild: Siralims minions (*Spiderlings*) och Druid.
- *Förmågor:* Snärjande rötter (fiende Snared: fast längst ned på Timeline, 6), Lövskydd (Barrier på en
  allierad och 1 rotskott, 6), Svampring (alla fiender Poisoned, 5).
- *Stats:* 700 / 50 / 90 / 30 / 8.
- *Samspel:* Brokk eller en provocerande tank, som samlar träffar och därmed rotskottens slag. Väktarens
  ed (*Thorns*) dubblar törnena.

**5. Ragnhild Ljusdom.** Människa, före detta domare. Rättvis och skarp, men så envis att hon en gång
dömde fel person och aldrig förlåtit sig själv.
- *Trait, Sanningens ljus:* när en fiende helas eller får en buff bränner ljuset den. Den tar Helig skada
  lika med 50 % av Ragnhilds Int. Förebild: Spectre *Unspeakable Sins* och Inquisitor-specialiseringen.
- *Förmågor:* Brännmärke (fienden blir Blighted, så att helning skadar, och Vulnerable, 6), Skingra lögnen
  (tar bort alla buffar från en fiende, 6), Ljusvåg (Helig skada på alla fiender 70 %, 5).
- *Stats:* 800 / 75 / 80 / 45 / 9.
- *Samspel:* svaret på kapellets fördärvade präster. Med Paladinens heliga skada och Eiras märke blir hon
  specialisten som vänder fiendens styrka mot den.

**6. Sefir av Sanden.** Människa från söder, svärdsdansare. Skrattar mitt i striden och är på flykt undan
en spelskuld.
- *Trait, Bladvirvel:* en kritisk träff flyttar Sefir till toppen av Timeline (högst en gång per tur).
  Förebild: Windrunner (Speed) och Vlora (top-of-Timeline-traits).
- *Förmågor:* Dansande stål (två anfall à 60 %, 8), Vindens steg (Sefir till toppen och Savage: extra
  krit-chans, 5), Tusen snitt (alla fiender Bleeding, 5).
- *Stats:* 600 / 95 / 40 / 15 / 17.
- *Samspel:* krit-troféer (Prickskyttens öga, Bågskyttens sena: alltid krit mot märkta) och Eiras märke.
  Kan ge kedjor av turer, så den behöver Action Limits.

Roller som täcks: tempo och märkning (Ronja), buffar och turordning (Lirien), undvika och kontra
(Tove), minions och kontroll (Hulda), anti-helning och dispel (Ragnhild), fart och krit (Sefir).

### 6.3 Hur många från början och hur fler låses upp

**Siralim (Bekräftat):** några varelser per ras från start. Nya låses upp med djupet (var 15:e djup),
genom Mana från besegrade varelser, uppdrag, gudarnas butiker, Exotics bakom portaler och Projects.

**Förslag för oss:**
- **Från start:** de fyra vi har (Brokk, Alva, Eira, Solveig) i Värdshuset. Sällskapet är Paladinen och
  tre till, som i dag.
- **Upplåsning,** där varje följeslagare har en egen väg, som Siralims varierade källor:

| Följeslagare | Var | Hur | Siralim-förebild |
|---|---|---|---|
| Ronja | Kryptan | Fånge-rummet från djup 2 (fångad av skelett, falken hittar sällskapet) | Mana genom möte i Realmen |
| Hulda | Kryptan | Realm Quest "Rädda" (ta henne till våningens slut) | uppdrag |
| Ragnhild | Kapellet | Fånge-rummet i kapellet | varelser per Realm |
| Lirien | Kapellet | Bakom en portal (Nether Realm) | Otherworld-portal, Exotic |
| Tove | Valfri | Djup 4 klarat | upplåsning med djupet (15, 30 …) |
| Sefir | Valfri | Byggmästarens projekt "Utsänd budbärare" | Projects |

- **Förtroende i stället för 100 % Mana:** första räddningen gör att hen kommer till Värdshuset. Varje
  ytterligare möte ger Förtroende som låser upp en tredje förmåga, som Siralims Knowledge-ranker.
- **Tempo:** ungefär en ny följeslagare per 2 klarade djup eller per ny Realm, så att det alltid finns en
  synlig "nästa" på Kampanjkartan.

## 7. Kampanjkartan (beslut, Huvudtråden, 2026-10-19)

Användarens önskan: "en karta man erövrar och man ser vilka vad fronterna är ... vilka monster man har
slagit ... statistik ... att kunna följa sin progress och planera sina strider."

Siralim (Bekräftat, Codex) har det här utspritt i menyer: Bestiary och Knowledge-ranker, Realm Depth,
Mastery per ras, stjärnor i Gate of the Gods och achievements. Vi samlar det på en karta.

- **0.18: rumskartan och Kampanjkartans grund**, i samma pergamentstil och med zoom mellan dem.
  - Landet med Realms som områden. Fördärvets front drar sig tillbaka med klarade djup.
  - På kartan syns besegrade bossar (x/3 till bosstrofén), klarade Realm Quests och våningsregler.
  - Kryptporten flyttas in i kartan: man väljer Realm genom att trycka på området.
- **0.19: Bestiariet och Krönikan.**
  - *Bestiariet* ersätter dagens bibliotek. Varje fiende har antal besegrade och en kunskapsrank som
    Siralims Knowledge. Högre rank avslöjar liv, avsikter och trofé.
  - *Krönikan* har statistik per hjälte och körning och "dina bästa kombinationer", kopplad till
    efterrapporten.
  - Värdshuset (avsnitt 6) kommer i samma version eller strax efter.

## Källor

- [Codex Reference (Steam-guide, spelets Codex 2.0.37)](https://steamcommunity.com/sharedfiles/filedetails/?id=2197484456):
  Realm Properties (Player/Enemy/Realm), Realm Instability, Nether Bosses, Guilds and False Gods.
- [Wiki: Realms](https://siralimultimate.wiki.gg/wiki/Realms), [Wiki: Mimic](https://siralimultimate.wiki.gg/wiki/Mimic).
- Trait-kompendium: [Siralim Ultimate Compendium – Traits.csv (version 1.1.0)](https://github.com/berated-bert/siralim-planner/tree/master/data/siralim-ultimate-compendium),
  via [Siralim Planner](https://berated-bert.github.io/siralim-planner/).
- [Bloodmage Build Guide (Brothel)](https://gameplay.tips/guides/10177-siralim-ultimate.html).
