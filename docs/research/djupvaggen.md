# Djupväggen – hur Siralim låter spelaren ta sig förbi svårighetsmurar, och varför våra botar fastnar vid djup 6–7

2026-10-24. Research, inga beslut. Underlag: karriärbotarna (`SOAK=karriar`, `docs/provspel/svarighetskurva.md`),
`docs/formler.md`, `docs/research/siralim.md` (§8c, §10, §14, §15, §18), `src/game/hero_stats.gd`, `src/game/forge.gd`,
`src/combat/combat_sim.gd`, `data/oaths.json`, `data/artifacts.json`. Godot kördes inte; talen nedan är uträknade för hand
(Python) ur konstanterna i koden.

Märkning: **Belagt** = står i en källa; **Troligt** = återkommande spelaruppgifter; **Gissning** = vår slutsats.

## Kort

1. **Huvudfyndet: vi skalar fienderna två gånger på djupet.** Djupet höjer fiendernas nivå (+5 nivåer per djup, ×1,3 i
   stats per nivå som hjältarna) *och* ger dessutom +8 % stats per djup (`CombatSim.DEPTH_STEP`, från 0.14, alltså från
   tiden innan nivåerna fanns i 0.19). Utan de 8 procenten ligger botarnas sällskap på 92–101 % av fiendernas relativa
   styrka på varje djup 2–7. Med dem faller det från 88 % (djup 2) till 62 % (djup 7). Kurvan följer botarnas vinst nästan
   exakt.
2. Siralim har samma nivåkurva som vi (+30 % av basvärdet per nivå), och ingen källa nämner en extra stat-faktor per djup
   utöver nivån. Där kommer väggen av att fiendernas *nivå* drar ifrån, och svaret är byggen (traits, fusion, perks,
   artefakter) som fortsätter växa i hundratals timmar. Våra öppna hävstänger tar slut tidigt (artefakt nivå 10, ~10
   perk-poäng per kall, tre egenskaper).
3. Förslagen nedan börjar med det minsta: mät med en bot som använder material, och sänk eller ta bort `DEPTH_STEP`.

---

## 1. Siralims hävstänger

### 1.1 Varelsernas nivå (inget tak)
- +30 % av basvärdet per nivå, personligheten 40 %/20 %. Inget tak, varken för egna varelser eller fiender. **Belagt**
  (Codex, se `siralim.md` §14.1; Steam-butiken: "your creatures do not have a level cap … enemies can scale infinitely").
- Fiendernas nivå drar ifrån de egna: en spelare med varelser på nivå 102 mötte fiender på 130+ (kvot 1,3); på djup 2 119
  var fienderna ~350 000 och varelserna ~94 500 (kvot 3,7), och "this gap continues to increase". **Troligt** (en tråd,
  [Creature LVL](https://steamcommunity.com/app/1289810/discussions/0/5767400709474403607/)).
- Wikins FAQ: fienderna skalar snabbare än ens nivåer, och svaret är traits, inte grind. **Belagt** (`siralim.md` §10).
- **Nivå-upphämtning:** vid djup ~40–43 kan man höja en varelse till den högsta nivå man nått, för Power, hos Fusionist.
  **Belagt** ([Starter guide](https://siralimultimate.wiki.gg/wiki/Starter_guide) säger 40,
  [Realm Depth](https://siralimultimate.wiki.gg/wiki/Realm_Depth) listar "Level-up feature" vid 43). Det gör nya lag
  billiga att prova; det lyfter inte taket.

### 1.2 Realm Depth
- "The higher the Realm Depth you choose, the stronger your enemies, but you'll receive greater rewards." Ingen siffra
  publicerad. **Belagt** ([Realms](https://siralimultimate.wiki.gg/wiki/Realms)).
- Svårigheten påverkas av djup, vald svårighetsgrad och instabilitet. **Troligt**
  ([tråd](https://steamcommunity.com/app/1289810/discussions/0/5710018482973776302)).
- Föremålsbonus bara på det djupaste djup man besökt; perk-poäng bara från Realm Quests där. **Belagt**
  ([Realms](https://siralimultimate.wiki.gg/wiki/Realms), [Specializations](https://siralimultimate.wiki.gg/wiki/Specializations)).
- Låga djup går att använda för att träna, och man får erfarenhet även av lätta strider. **Troligt** (spelare, se
  [Starter guide](https://siralimultimate.wiki.gg/wiki/Starter_guide) och
  [Loid-tråden](https://steamcommunity.com/app/1289810/discussions/0/3875969300102855713): "just a few more runs through
  the previous Realm Depth").
- Djupet låser upp system i en lång trappa: Fusion 10, fler Specializations 19, Exotics 20–21, Instabilitet 33, Refinery
  och Goblet 40, nivå-upphämtning 43, Arena 52, Missions 55, kampanjens slut 64, Reliquary 64. **Belagt**
  ([Realm Depth](https://siralimultimate.wiki.gg/wiki/Realm_Depth)). Varje ny mur möts alltså ofta av ett *nytt system*.
- Gate of the Gods: egna varelser låses till nivå 100, fienderna 100–1 500 efter svårighet. Med linjär tillväxt är nivå
  1 500 mot 100 ungefär ×15 i stats – och lag klarar det, med traits. **Belagt**
  ([Gate of the Gods](https://siralimultimate.wiki.gg/wiki/Gate_of_the_Gods)). Det visar hur mycket byggena väger.

### 1.3 Artefakter
- Nivå 1–50 för Brimstone, varje nivå stärker allt; platser Stat 3, Trick 5, Stat 10, Trait 15, Trick 25, Stat 35, Spell
  50, sedan Nether. Totalt ~75 750 Brimstone. Smeden måste själv uppgraderas (Blacksmith Rank 2–5 via Projects). **Belagt**
  (`siralim.md` §15.1, [Projects](https://siralimultimate.wiki.gg/wiki/Projects)).
- Amber 5 per Stat-plats, trick, Trait Material, Nether Stones (slumpade, slutspelets jakt). 2.0: Class Strength max 80 %.
  **Belagt** (§15.2–15.3, [2.0-noterna](https://www.thylacinestudios.com/blog/siralim-ultimate-2-0-patch-notes)).
- Storlek: en lång, jämn ström – en artefakt förbättras under hela spelet. **Gissning** utifrån kostnadstabellen.

### 1.4 Spell Gems
- 3 platser, Tier 1–15; spellen blir inte starkare av tier, men tier 5/10/15 öppnar egenskapsplatser vars tal växer med
  tier (fler Charges, mer potency, chans att kasta igen …). Crystal hos Enchantern. **Belagt** (`siralim.md` §18).

### 1.5 Specialization, perks och Anointments
- Perk-poäng från Realm Quests på det djupaste djupet, delas av alla Specializations, tak 1 500 (sedan till Piety).
  Gratis återställning. **Belagt** ([Specializations](https://siralimultimate.wiki.gg/wiki/Specializations)).
- Perks har många ranker (t.ex. 1–10) och dyra slutperks; Anointments lånar perks från andra klasser (Royal kan ha 10
  fler). **Belagt** delvis ([Royal](https://siralimultimate.wiki.gg/wiki/Royal), `siralim.md` §6, §13b).
- Storlek: med 1 500 poäng och hundratals perks tar potten aldrig slut i kampanjen. **Gissning**.

### 1.6 Traits och fusion
- Varje varelse har egen trait + en ihopsmält + artefaktens Trait-plats (och Nether Stones). Fusion (djup 10) är enligt
  spelarna en milstolpe: ett lag "will easily take you through the next several bosses after unlocking fusion". **Troligt**
  ([tråd](https://steamcommunity.com/app/1289810/discussions/0/3121535825779922961)). Spelarna kallar den den största källan
  till djup. **Troligt**.

### 1.7 Övriga stat-källor
- **Personlighet** (+40/20 %), **kort** (liten stat per kort + samlingsbonus), **reliker** (stats + perk per 10 ranker,
  efter kampanjen), **stat scrolls** (projektet Training: 3 scrolls som höjer en *basstat*), **Mastery** per ras (mer
  skada, mindre tagen). **Belagt** (`siralim.md` §14.2, [Projects](https://siralimultimate.wiki.gg/wiki/Projects)).
- **Fortune:** +20 % resurser per klarad quest i rad (högst 100 %), förloras vid förlust; 2.0 gjorde den starkare.
  **Belagt** (§10, 2.0-noterna).

### 1.8 Valfri svårighet
- **Realm Instability** 0–5 (från djup 33): fler regler, sammansmälta fiender, upp till och över +400 % byte. **Belagt**.
  En spelare på djup 68 RI5 sänkte till RI3 och blev stabil (§8c). Instabilitet är alltså en *ratt åt båda hållen*.
- **Svårighetsgrad:** förr 0–9 (höjer fiendernas nivå "drastiskt"), i 2.0 Relaxed/Ruthless; Ruthless ger också mindre
  resurser och erfarenhet. **Belagt** ([2.0-noterna](https://www.thylacinestudios.com/blog/siralim-ultimate-2-0-patch-notes);
  0–9 enligt patch 0.11 via sökresultat, sidan gick inte att läsa).
- **Nether Bosses** var 5:e djup efter berättelsen, regelbrytande traits i tre nivåer. **Belagt** (§10).

### 1.9 Vad spelarna säger om murar
- "90 % av problemen löses med att överlevla och fokusera problemfienden" (guide, tidigt spel). **Troligt**.
- Tidiga murar (Loid, nivå ~15): "level a bit so your creatures can brute force him". **Troligt**.
- Senare: "make your team so overpowered that level gaps stop mattering"; dela ditt bygge (export) för hjälp. **Troligt**
  ([tråd](https://steamcommunity.com/app/1289810/discussions/0/598513524566738588) m.fl., via sökning).
- Rapporterade murar ligger på djup 6, 37–39, 45–48, kampanjens slut, Nether Bosses 150+ (§8c). Mönstret: lätt länge,
  sedan en boss eller en kombination som stoppar – och då byggs laget om.

---

## 2. Tabell: hävstång | Siralim | vi | gap

| Hävstång | Siralim | Vi (0.30-test) | Gap |
|---|---|---|---|
| Nivåtillväxt | +30 % av bas/nivå, inget tak | samma | inget |
| Fiendernas nivå per djup | följer djupet, "på en kurva", siffra okänd | 5 × (djup − 1) + 2,25 + 1,5/våning | okänt (troligen jämförbart) |
| Extra stat per djup utöver nivån | ingen källa nämner någon | **+8 % per djup** (inte Speed) | **vi har en extra kurva** |
| Erfarenhet | okänd formel; träning på lägre djup fungerar | 17 × rumstyp × djup², nästa nivå 5·L² + 10 | jämförbart |
| Nivå-upphämtning | till högsta nivån för Power (djup 40–43) | ikapphämtning ×1,5/nivå under snittet, högst ×3 | svagare (bara för efterslänkare) |
| Artefaktnivåer | 1–50, Smedens ranker, ~75 750 Brimstone | 1–10, 1 930 silver per artefakt | **svagare** (tar slut) |
| Artefaktmaterial | Amber, trick, Trait Material, Nether | bärnsten, trick, Nether, troféplats nivå 6 | inget–svagare |
| Spell Gems med egenskaper | 3 gems, tier 1–15, egenskapsplatser | förmågor med Charges, inga egenskaper | saknas |
| Perk-poäng | tak 1 500, många ranker | 2 + 1/quest (ny Realm × djup); kallen kostar 8–10 poäng totalt | **svagare** (mättas vid djup ~4–5) |
| Anointments | flera, Royal +10 | en lånad perk per besegrad boss | svagare |
| Traits per figur | egen + fusion + artefakt (+ Nether) | egen + trofé + artefaktens troféplats (+ Nether) | inget |
| Personlighet | 20, bytbar | samma | inget |
| Kort, reliker, stat scrolls, Mastery | finns | saknas | saknas (slutspel i originalet) |
| Fortune | +20 %/quest i rad, högst 100 % | saknas | saknas |
| Valfri svårighet | Instabilitet 0–5, Relaxed/Ruthless | instabilitet 0–3, löften | inget (ingen lättare ratt än 0) |
| Nya system som låses upp med djupet | fusion 10, … reliker 64 | nästan allt finns från start | svagare |
| Silver/byte per djup | mer på djupare, bonus bara på djupaste | silver +25 %/djup, troféchans +15 pp/djup, trick/Nether bara på djupaste | inget |

---

## 3. Varför botarna stannar vid djup 6–7

### 3.1 Två fiendekurvor mot en hjältekurva

Fiendens stat = bas × (1 + 0,08 · (d − 1)) × (1 + 0,3 · (L_f − 1)) (`CombatSim.create`: först `enemy_mult` med
`depth_mult`, sedan `HeroStats.level_mult`). Hjältens stat = bas × (1 + 0,3 · (L_h − 1)) + artefakt.

Med L_f = snittet av våning 1 och 2 (5 · (d − 1) + 3) blir den nivå hjälten behöver för att stå lika *relativt* som på
djup 1 (paritetsnivån, L_p):

| Djup | Fiendens nivå | Djupfaktor | Paritetsnivå L_p | L_p − L_f | Botarnas nivå | Relativ styrka med 8 % | utan 8 % | Botarnas vinst (krypta/kapell) |
|---|---|---|---|---|---|---|---|---|
| 1 | 3 | 1,00 | 3,0 | 0 | 1,3* | 0,68* | 0,68* | 96/100 % |
| 2 | 8 | 1,08 | 8,8 | 0,8 | 7,5 | 0,88 | 0,95 | 63/52 % |
| 3 | 13 | 1,16 | 15,5 | 2,5 | 12,7 | 0,85 | 0,98 | 44/51 % |
| 4 | 18 | 1,24 | 22,9 | 4,9 | 18,2 | 0,81 | 1,01 | 43/47 % |
| 5 | 23 | 1,32 | 31,1 | 8,1 | 22,7 | 0,75 | 0,99 | 28/37 % |
| 6 | 28 | 1,40 | 40,1 | 12,1 | 26,3 | **0,67** | 0,94 | 14/20 % |
| 7 | 33 | 1,48 | 50,0 | 17,0 | 30,0 | **0,62** | 0,92 | 0/8 % |
| 10 | 48 | 1,72 | 84,2 | 36,2 | – | – | – | – |

\* Djup 1 räknas med första nedstigningens trappa (×0,56–0,88), så kvoten där säger inget.

"Relativ styrka" = hjältens nivåfaktor / fiendens nivåfaktor × djupfaktor. Botarnas nivå ligger *på* fiendernas väntade
nivå (kvoten utan 8 % är 0,92–1,01 hela vägen), men djupfaktorn drar isär dem linjärt. Gapet i nivåer växer i kvadrat:
L_p − L_f ≈ 0,08 · (d − 1) · (5 · (d − 1) + 5,3).

### 3.2 Förstärkare
- **Defense dras av** (Attack − Defense): djupfaktorn höjer fiendens Defense också. Paladinen (Attack 9,5) mot Gravväktaren
  (Defense 4,5) vid samma nivå: skadan per träff faller till 57 % vid ×1,48, och livet är ×1,48 → ungefär 2,6 gånger så
  lång tid att fälla den. Mot fiender med Defense 1–2 är det ×1,7. Fiendens träffar mot oss växer på samma sätt.
- En strid är ett utnötningsförlopp: en kvot på 0,62 i både skada och tålighet blir betydligt mer än 38 % sämre vinstchans
  (Lanchester-tänk, **gissning**). Det stämmer med fallet 43 % → 0–8 %.
- **Charges räcker hela körningen.** Längre strider på djupet äter dem fortare, så våning 2:s boss möter ett torrare
  sällskap (botarnas förluster vid djup 6–7 är ofta "v2 boss").

### 3.3 Erfarenheten räcker för nivåkurvan men inte för djupfaktorn
- En vunnen körning ger ungefär 17 · d² · 10,5 (6 vanliga, 1 elit, 1 boss): 714 / 2 856 / 6 426 / 8 746 på djup 2/4/6/7.
- Vid botarnas nivå ger det 1,7–2,5 nivåer per vunnen körning, och i snitt (med förluster) mätt +1,3 nivåer per
  nedstigning. Det är *konstant över djupen* – med flit, eftersom båda kurvorna går i kvadrat.
- Fienderna går +5 nivåer per djup → ~4 nedstigningar per djup om man bara ska hålla jämna steg. Paritetsnivån går däremot
  +6,7 / +7,5 / +8,3 / +9,1 / +9,8 per djup (djup 3–7) → 5–8 nedstigningar per djup, och fler för varje steg.
- På paritetsnivån ger en körning på djup 7 bara 0,7 nivåer, på djup 10 0,5.
- Att slipa ett djup grundare ger ((d − 1)/d)² av erfarenheten: 69 % på djup 6. Det fungerar, men det tar dubbelt så
  många körningar som att följa fiendernas nivå.

### 3.4 Våra övriga hävstänger mättas
- **Artefakten** tar slut vid nivå 10: svärdet ger +9,5 % Attack, tre bärnstensplatser högst ~+34 % på en stat (3 platser ×
  6 % × 1,9; en plats kostar 5 bärnsten men ger 6 %, `Forge.stat_parts`). 1 930 silver per artefakt, 7 720 för fyra; med ~250–330 silver per nedstigning är de
  fulla vid ungefär nedstigning 25–30 – precis där väggen kommer. Därefter växer bara djupfaktorn.
- **Perks**: kallen kostar 8–10 poäng var (med ranker), och två Realms ger upp till två poäng per djup. Ett kall är fullt
  vid djup ~4–5.
- **Botarna använder inga material** och slumpar troféer (svarighetskurva.md, Begränsningar). En spelare kan alltså
  ha ~+30–40 % på sina viktigaste stats – det flyttar väggen ett eller två djup, inte bort den, eftersom djupfaktorn växer
  utan tak.

**Slutsats:** väggen vid 6–7 är inte nivåkurvan (den följer botarna bra) utan den extra djupfaktorn, som växer linjärt utan
tak medan våra hävstänger som skulle möta den (artefakt, perks) har tak. I Siralim motsvaras den av att fiendernas nivå drar
ifrån, men där finns många hävstänger utan tak och nya system var tionde djup.

---

## 4. Förslag (från litet till stort)

### F0. Mät först med en bot som bygger (litet, ingen spelkod)
Lägg till i `SOAK=karriar`: sätt in bärnsten (högsta stat för hjältens roll), behåll den bästa trofén (enligt
`BattleSummary.deciders`) i stället för slump, och köp perk-ranker. **Effekt:** vi ser var en rimlig spelare fastnar.
**Risk:** ingen. **Botar:** ja, det är själva mätningen.

### F1. Sänk eller ta bort `DEPTH_STEP` (litet, en konstant)
Låt djupet verka genom fiendernas nivå, som i Siralim. Två varianter: 0 (som originalet, så vitt vi vet) eller 0,03.
Behåll djupets silver, troféchans och fynd. **Effekt (uppskattning):** relativ styrka 0,92–1,0 på varje djup; botarnas
kurva blir en jämn trappa med ~4 nedstigningar per djup och ingen vägg, bara slipning. Med 0,03: 0,83 vid djup 7.
**Risk:** djup 2–4 blir något lättare (i dag 43–63 %); mittspelets självbalans kring 45 % kan stiga mot 55–60 %. Kanske
behöver `FLOOR_STEP` eller elitgruppernas `stat_mult` höjas lite för att behålla bett. Djupets "känsla" måste då komma av
nivåsiffran och nya fiender/regler. **Botar:** ja, direkt (`SOAK=karriar`, `BALANS=grotta` per djup).

### F2. Nivå-upphämtning hos Mor Elin eller Gorm (litet–medel, Siralims Fusionist)
Höj en hjälte till sällskapets högsta nivå för silver (originalet: Power, från djup 40). Ikapphämtningen finns redan, men
upphämtningen gör det billigt att prova en ny följeslagare – det Siralim vill uppmuntra. **Effekt:** liten på väggen, stor
på viljan att byta hjälte (ledstjärnan). **Risk:** silversänka som konkurrerar med Smeden. **Botar:** delvis.

### F3. Smedens rang: artefaktnivå 11–20 (medel, Siralims Blacksmith Ranks och nivå 1–50)
Låt en besegrad boss (eller ett projekt) höja Smedens rang, som öppnar fler artefaktnivåer, en tredje trick-plats och en
andra stat-plats för Nether. **Effekt:** en silversänka och en tillväxt som håller till djup ~10; varje nivå +10 % på
allt. **Risk:** mer siffror utan nya val (VD:s invändning 2026-10-20 i §15) – koppla varje rang till en ny plats eller
ett nytt val. **Botar:** ja, om boten levlar artefakter (den gör det redan).

### F4. Fler perk-ranker och en pott som inte tar slut (medel, Siralims 1 500 poäng)
Ge varje kall fler ranker på sifferperks, eller låt poäng efter ett fullt kall gå till ett eget mål (Siralims Piety: t.ex.
en liten basstat per poäng, som stat scrolls). **Effekt:** en långsam, öppen hävstång. **Risk:** kända bristen att
regelbrytarna slår siffernivåer; mät `tests/perk_report.gd`. **Botar:** ja.

### F5. Fortune och djupets nya system (större, originalets struktur)
(a) Fortune: +20 % silver och erfarenhet per klarad quest i rad, högst +100 %, förloras vid förlust. Belönar att stanna
på ett djup man klarar i stället för att pendla. (b) Lås upp något nytt var tredje djup (t.ex. troféplatsen, Nether-platsen,
en andra lånad perk, instabilitet), så att varje mur möts av ett nytt verktyg som i Siralim (fusion 10, … reliker 64).
**Effekt:** svårigheten blir "murar och ombyggen" (§8c) i stället för en jämn nedförsbacke. **Risk:** innehåll och
design; Fortune kan göra slipningen på djup 1 ännu mer lönsam (platån). **Botar:** (a) ja, (b) delvis.

Rekommenderad ordning: F0 → F1 (mät båda varianterna) → sedan avgöra om F3/F4 behövs för att trappan ska kännas lång.

---

## 5. Osäkerheter

- **Siralims fiendenivå per djup är inte publicerad.** "Difficulty increases on a curve" kommer från en patchnot som kan
  gälla Siralim 1 (moddb, 1.0.1.2). Forumens datapunkter (nivå 130 mot 102; 350 000 mot 94 500 vid djup 2 119) är
  enstaka spelare utan djup angivet i den första.
- Att Siralim *inte* har en extra stat-faktor per djup utöver nivån är en slutsats av tystnad i wikin och Codex, inte ett
  belägg.
- Vår modell (relativ styrka = kvoten av stat-faktorerna) bortser från egenskaper, krit/undvikande (Speed skalar bara med
  nivån, inte med djupfaktorn – det dämpar effekten något), sällskapets skalning, elitvarianter, motdrag per djup och
  våningsregler. Den förklarar trenden, inte procentsatserna.
- Erfarenheten per körning är en uppskattning (6 vanliga + 1 elit + 1 boss); botarna mätte +1,3 nivåer per nedstigning
  inklusive förluster.
- Botarna spelar inte som människor (inga material, slumpade troféer, ingen instabilitet). F0 behövs innan siffrorna i
  F1 sätts.
- Siralims Ruthless/Relaxed-siffror och 0–9-skalans exakta effekt hittades inte.

## Källor

- Siralim Ultimate Wiki: [Realms](https://siralimultimate.wiki.gg/wiki/Realms),
  [Realm Depth](https://siralimultimate.wiki.gg/wiki/Realm_Depth),
  [Starter guide](https://siralimultimate.wiki.gg/wiki/Starter_guide),
  [Projects](https://siralimultimate.wiki.gg/wiki/Projects),
  [Specializations](https://siralimultimate.wiki.gg/wiki/Specializations),
  [Royal](https://siralimultimate.wiki.gg/wiki/Royal),
  [Gate of the Gods](https://siralimultimate.wiki.gg/wiki/Gate_of_the_Gods)
- Thylacine Studios: [Siralim Ultimate 2.0 Patch Notes](https://www.thylacinestudios.com/blog/siralim-ultimate-2-0-patch-notes)
- Steam-diskussioner: [Creature LVL](https://steamcommunity.com/app/1289810/discussions/0/5767400709474403607/),
  [svårighet och djup](https://steamcommunity.com/app/1289810/discussions/0/5710018482973776302),
  [Loid](https://steamcommunity.com/app/1289810/discussions/0/3875969300102855713),
  [Realm Depth level up](https://steamcommunity.com/app/1289810/discussions/0/3875969300106520844/),
  [tidiga lag och fusion](https://steamcommunity.com/app/1289810/discussions/0/3121535825779922961),
  [Evoker-lag, djup 50–55](https://steamcommunity.com/app/1289810/discussions/0/3782498683137387206),
  [fiender som drar ifrån](https://steamcommunity.com/app/1289810/discussions/0/598513524566738588)
- Tidigare research i repot: `docs/research/siralim.md` §8c, §10, §14, §15, §18.
- r/Siralim gav inga träffar i sökningarna; Steam-forumen fick täcka spelarrösterna.
