# Gameplay: Siralim Ultimate jämfört med De edsvurna (0.20.3)

Researchtråden, 2026-10-19, på uppdrag av VD:n via Huvudtråden: "läsa allt som finns om Siralim
Ultimate … jämföra typ allt i gameplay". **Bara diskussion, inga beslut.**

Säkerhet: **B** = Bekräftat (spelets Codex 2.0.37, wikin, patchnoter). **T** = Troligt (guider och
flera spelare). **O** = Okänt.
Status: **Lika** = finns som i originalet. **Avvikelse** = finns, men annorlunda (vad och varför).
**Saknas**.
Vikt för det roliga, enligt spelarna: **hög / medel / låg**. Grunden är Vaporlens sammanfattning av
Steam-recensioner, byggguider och Steam-trådar (se Källor).

Vår kod och dokumentation är genomläst för att säkra vad vi har: `CLAUDE.md`, `docs/plan/0.11–0.20`,
`src/combat`, `src/game`, `scripts/screens` och `data/*.json`. Detaljer och belägg för Siralim finns i
`siralim.md`, `siralim_innehall.md` och `siralim_0.19.md`. Den här filen samlar dem.

**Vad spelarna värderar** (Vaporlens, antal omnämnanden):
- Positivt: samlande 44, variation 33, djup 33, teoribygge 32, omspelbarhet 32, turbaserad taktik 23,
  synergi och lagbygge 21, slumpade dungeons 21.
- Negativt: UI och menyer 20, översättning 19, grind 19, repetitiv loop 17.
- Reddit gick inte att nå via sökningen (O).

## 1. Strid

| System | Siralim | Vi (0.20.3) | Status | Vikt |
|---|---|---|---|---|
| Lagstorlek | 6 mot 6 (B). Druid-specen 4, Pariah 3 | Paladinen + 3 mot 3–6 | **Avvikelse.** 4 är vårt val, som Druid. Skäl: få följeslagare att välja bland, 3D på telefon | hög |
| Tidslinje | Speed ger startplats, den som agerat läggs sist, inga rundor (B) | Samma sak (0.11) | **Lika** | hög |
| Flytta i tidslinjen | Top/Bottom-effekter, Snared, bossar flyttas bara ett steg, gränserna per tur nollställs (B) | Saknas | **Saknas** | hög (Mimic och liknande byggen) |
| Handlingar | Attack, Cast, Defend, Provoke, Skip, Macro, Inspect och History gratis (B) | Anfall, Förmåga, Försvara, Provocera, Hoppa över, Makro. Inspect genom att hålla | **Lika** | hög |
| Defend och Provoke | −35 % skada och +50 % Defense. 100 % mål och −35 % Defense (B) | Samma siffror | **Lika** | medel |
| Fiendens avsikt | Visas inte, bara vissa bossar låser mål (B) | Alla fiender visar avsikt | **Avvikelse** (vårt tillägg för läsbarhet och makron) | medel |
| Auto och turbo | Standardhandling plus turbo, ett tryck per tur (T) | Auto kör makron för alla | **Avvikelse** (mobil) | medel |
| Ge upp | Forfeit räknas som förlust: hem, Fortune och quest förlorade (B) | Ge upp (0.20.1): körningen slut, fynd behålls | **Lika** | låg |
| Action Limits | 15 per tur, 10 återupplivningar, 10 vunna traits. Calm Mode 5/5/3 (B) | 5 per tur, kedjor max | **Avvikelse** = Calm Mode (läsbarhet) | medel |
| Battle History | Händelselista (B) | Logg, makroförklaring, kvitto | **Avvikelse** (vårt tillägg: "varför") | medel |

## 2. Stats och skada

| System | Siralim | Vi | Status | Vikt |
|---|---|---|---|---|
| Fem stats | Health, Attack, Int, Defense, Speed (B) | Samma (0.13) | **Lika** | hög |
| Skadeformler | Attack: (A−D)+1 % A. Spell: Potency−D. Indirect −20 % D (B) | Samma | **Lika** | medel |
| Krit och undvikande | Speed mot målets Speed. Formeln opublicerad. +200 % krit vid 3× (B/O) | Egen kurva som passar datapunkterna | **Avvikelse** (formeln är okänd) | medel |
| Stat-golv och tak | Min 20 % av start, avtagande över 500 % (B) | Golv 20 % | **Avvikelse** (taket saknas, spelar liten roll) | låg |
| Klassstyrka | ×2 / ×½ i en cirkel (B) | Saknas (skolor i stället) | **Saknas** | medel |

## 3. Bygget

| System | Siralim | Vi | Status | Vikt |
|---|---|---|---|---|
| Traits | 1 200+ unika, lyssnar på händelser, kedjor, "does not stack" (B) | 62 traits (22 troféer, 16 perks), kedjor, `scope: party` | **Lika** (färre) | **hög**: kärnan |
| Klasser och raser | 5 klasser styr gems och styrka. ~6 varelser per ras, Mastery-traits för lag med en ras (B) | Roller (tank/heal/dps), skolor. Inga raser | **Saknas** | medel (raser: hög i slutspelet) |
| Spell Gems | 3 per varelse, egen klass, tillverkas av inskrifter, nivå 1–15 (B) | 2–3 fasta förmågor per hjälte | **Avvikelse** (inget eget val, ingen tillverkning) | hög |
| Spell Properties | Cascading, Generous, Magnetic, Singular, Class Swap, chans att kasta två gånger, % potency från andra stats … (B) | Saknas | **Saknas** | hög (regelbrytare) |
| Charges | 4–8 per gem, fylls vid ny Realm eller hemma (B) | Siralims värden, men lägereldar ger +3 | **Avvikelse**: lägereldarna (se 8) | medel |
| Makron | 20 rader, subjekt, villkor, handling, test next line (B) | Samma, plus förklaringslogg och fler villkor | **Lika** (+ tillägg) | medel (hög för VD:n) |
| Specialization | 40 st, perks i nivåer, 100 poäng per perk fullt, egen pott per spec, gratis återställning (B) | 3 Kall (Ed), perks med 2–3 nivåer, egen pott, gratis återställning | **Lika** (färre) | hög |
| Anointments | 5 platser, från False Gods (B) | 1 lånad perk per besegrad boss | **Avvikelse** (färre platser, från bossar) | medel |
| Ascension | Slå alla gudar på svårighet 10 med samma spec ger skin, dekor och en perk (B) | Saknas | **Saknas** | låg |
| Fusion | Båda traits, genomsnittliga stats, andra förälderns klass, permanent (B) | Troféer flyttas fritt. Bosstrofé efter 3 segrar | **Avvikelse** (beslut: fri flytt) | hög |
| Trait Materials | Masters efter 3 segrar, Assassination (B) | Bosstroféer x/3 | **Lika** i princip | medel |
| Nivåer | +30 % av bas per nivå, inget tak, fienderna följer djupet (B) | Samma (0.19) | **Lika** | hög (VD:n) |
| Nivå-upphämtning | Power hos Fusionist från djup 40 (B) | Saknas (behövs med Värdshuset) | **Saknas** | låg |
| Personlighet | 20 sorter, 40/20 % tillväxt, Tome för byte (B) | 20 sorter (0.19) | **Lika** | låg–medel |
| Artefakter | 1 per varelse, nivå 1–50, platser Stat/Trick/Trait/Spell/Nether, Brimstone (B) | Nivå 1–10, Stat/Trick/Nether, förmåga från nivå 1, silver (0.20) | **Avvikelse** (kortad, ingen Trait-plats eftersom trofén är den) | hög (VD:n: gear) |
| Material | Amber (vanligast), trick-material, Trait Materials, Nether Stones (slumpade), uttag förstör (B) | 10 Amber, 7 trick, Nether Stones med sällsynthet, uttag förstör | **Lika** (färre) | hög (fynd) |
| Item Sets | Spara uppsättningar av gems och artefakter (B) | Saknas | **Saknas** | låg |
| Kort | Kort per varelse ger stats, samlingar ger bonus (B) | Saknas | **Saknas** | medel (samlande) |
| Reliker | Gudarnas reliker, Piety, perk var 10:e rank, Synergy (B) | Saknas | **Saknas** | medel (slutspel) |

## 4. Status och effekter

| System | Siralim | Vi | Status | Vikt |
|---|---|---|---|---|
| Buffar | ~18: Agile, Arcane, Barrier, Berserk, Defensive, Immune, Invisible, Leeching, Mending, Protected, Rebirth, Repelling, Savage, Shelled, Splashing, Taunting, Warded … (B) | 7 buffar (inspired, blessing, warded, holy_shield, renew, barrier, defend och provoke) | **Avvikelse** (få) | hög (traits reagerar på dem) |
| Debuffar | ~20: Bleeding, Blighted, Blind, Bomb, Burning, Confused, Cursed, Disarmed, Feared, Frozen, Poisoned, Scorned, Silenced, Sleeping, Snared, Stone, Vulnerable, Weak … (B) | 6 (marked, burning, silenced, vulnerable, weak, salted) | **Avvikelse** (få) | hög |
| Minions | Staplar som gör indirekt skada vid händelser, 25 % chans att lämna (B) | Saknas | **Saknas** | medel |
| Resistant | Bossar tar halv effekt av debuffar (B) | Finns | **Lika** | låg |

## 5. Världen och körningen

| System | Siralim | Vi | Status | Vikt |
|---|---|---|---|---|
| Realms | 30 slumpade, en gud var, egna varelser (B) | 2 (Kryptan, Kapellet) med 3 våningar | **Avvikelse** (färre, våningar) | hög |
| Vandring | Fri karta, strider under vandringen (B) | Rumskarta med vägval, 3D-ögonblick (0.18) | **Avvikelse** (beslut: telefon, tydliga val) | hög |
| Föremål i Realms | Kistor, resursnoder, inskrifter, ljus (Favor), Pandemonium-helgedomar, skattkartor, gåtdvärgar, Nether Realm-portaler, Otherworld-portaler (B) | Skattkammare, helgedom, lägereld, portal | **Avvikelse** (färre sorter) | medel |
| Realm Depth | Valfritt djup, oändligt, fienderna följer djupet, bonus på djupaste (B) | Valfritt djup, fienderna följer djup och våning | **Lika** | hög (VD:n) |
| Realm Properties | Synliga och dolda regler, slumpas om vid shrinen (B) | 10 våningsregler | **Lika** (färre) | medel |
| Instability | 0–5, dolda regler, fused fiender, upp till +400 % byte (B) | 0–3, synliga och dolda | **Lika** (kortad) | medel |
| Realm Quest | Krävs för att lämna, ger Perk Points (10) och Fortune (B) | Jakt, Rensa, Rening, ger perk-poäng, krävs inte | **Avvikelse** (mildare) | medel |
| Fortune | +20 % per quest upp till 100 %, nollställs vid förlust (B) | Saknas | **Saknas** | låg |
| Nemesis | Starkare varelser i Realms (B) | Namngiven elit i Jakt-questen | **Lika** i princip | låg |
| Svårighet | Relaxed / Normal / Ruthless vid nytt spel (B, 2.0) | Djupet är svårigheten | **Saknas** (Ruthless) | låg |
| Lägereld | Finns inte. Liv fylls efter varje strid (B) | Liv plus 3 Charges per förmåga | **Avvikelse**: motverkar Charges-beslutet | medel |
| Spara och ladda | Laddning ger slottet, Realm och quest förlorade (T) | Sparas efter varje rum | **Avvikelse** (mobil) | låg |

## 6. Bossar och slutspel

| System | Siralim | Vi | Status | Vikt |
|---|---|---|---|---|
| Story-bossar | Per djup, ger 50 Perk Points (B) | Benfursten, Fallen biskop | **Lika** i princip | medel |
| Masters | En per ras, unikt Mastery-trait, Mastery ±skada, Trait Material efter 3 (B) | Bosstroféer x/3 | **Avvikelse** (inga raser) | medel |
| Nether Bosses | 35 st, ett regelbrytande trait i 3 nivåer, från djup 70 (B) | Saknas (idéer i `siralim_innehall.md` §3) | **Saknas** | hög (bygga mot en regel) |
| False Gods och Guilds | Kroppsdelar, runor gör dem starkare eller svagare, ger Anointments och rykte (B) | Saknas | **Saknas** | medel |
| Gate of the Gods | 21 gudar, svårighet 1–10+, nivå 100, Avatars med Ultimate Spell (B) | Saknas | **Saknas** | medel (slutspel) |
| Arena | Draft 6 slumpade, 5 lag, Wild-regler, Masters, Glory och Fame (B) | Övningsgården: riskfri test | **Avvikelse** (test, inte draft) | låg–medel |

## 7. Basen och progressionen

| System | Siralim | Vi | Status | Vikt |
|---|---|---|---|---|
| Slottet | Shrine, Blacksmith, Enchanter, Summoning, Wardrobe, Everett, Refinery, Goblet, Reliquary, Menagerie, dekor (B) | Bas: Kampanjkartan, Smeden, Kallets altare, Makron, Biblioteket, Övningsgården | **Avvikelse** (färre) | medel |
| Projects | Samla föremål för att låsa upp byggnader, nivåer, specs (B) | Saknas (Byggmästaren planerad) | **Saknas** | medel (långsiktigt) |
| Rekrytering | Mana genom att besegra, Summoning Brazier, gudarnas butiker, Exotics (B) | Saknas (Värdshuset planerat, 6 följeslagare skissade) | **Saknas** | **hög** (samlande 44) |
| Bestiary och Knowledge | Ranker F–S: lore, livsmätare, Hunt, summon, byte, kort, Assassination (T) | Biblioteket = troféer. Ingen kunskap | **Saknas** (planerat) | medel |
| Gudar och Favor | Favor per gud, butiker för Emblems, Blessings i Realmen (B) | Saknas | **Saknas** | medel (fynd) |
| Valutor | 5 resurser + Emblems, Glory, Piety … (B) | Silver och material | **Avvikelse** (avsiktligt få, grind-kritik) | låg |
| Achievements | Tusentals, ger Piety (B) | Saknas | **Saknas** | låg |
| Hjälteblad | Nivå, klass, ras, fem stats med pilar, traits, artefakt, gems (B/T) | Hjältebladet (0.19): stats per källa, skada i siffror, historik | **Avvikelse** (mer detaljerat, VD:n) | medel |
| Statistik och Krönika | Finns inte (T) | Delvis i hjältebladet | Vårt tillägg | – |
| Minispel, skins, accessoarer, Menagerie | Finns (B) | Saknas | **Saknas** | låg |

## 8. Avvikelser värda att ompröva

Bara diskussion. Det här är ställen där vi gått ifrån originalet utan att det har prövats mot
ledstjärnan:

1. **Lägereldar ger +3 Charges per förmåga.** Originalet fyller bara vid ny Realm. Med 3 lägereldar per
   körning får Helande ljus 5 + 9 = 14 användningar. Det tar bort det hushållande som VD:n beslutade
   (`siralim.md` §3b). Siralim-trogna alternativ: liv bara, eller buffen *Arcane* (nästa förmåga
   gratis).
2. **Lagstorlek 4.** Rimligt nu (Druid-läget), men bör följa truppens storlek: pröva 5–6 när
   Värdshuset har 15–20 följeslagare.
3. **Realm Quest krävs inte.** Mildare än originalet. Det fungerar, men gör questen mindre viktig.

## 9. Prioriterad lista: det viktigaste vi saknar

Ordningen följer VD:ns smak: djup i kombinationer, makron, hjälteblad och progression, fynd och gear,
att gå tillbaka och bli starkare, och ingen nivåskalning. Allt finns i originalet.

1. **Buffar, debuffar och tidslinjeeffekter (§1, §4).** Siralims ~38 statusar och Top/Bottom of
   Timeline. *Varför:* billigt i regler och det som gör att traits får något att reagera på. Mest
   kombinationsdjup per arbetsinsats, och makrona får fler villkor att använda. Data finns redan i
   `siralim.md` §7.
2. **Värdshuset och rekrytering (§7).** Samlandet är spelarnas största skäl (44). Fler hjältar ger fler
   kombinationer och gör att lagstorleken kan växa mot originalets 6. Utkasten finns
   (`siralim_0.19.md` §3).
3. **Valbara förmågor och Spell Properties (§3), Runristaren.** Varje hjälte väljer 3 av flera, och
   förmågor får egenskaper (Cascading, Generous, Chance to Cast Twice …). *Varför:* gear och fynd i
   form av inskrifter, och nya regelbrytare. Originalets andra stora bygglager efter traits.
4. **Bestiary och Knowledge (§7).** Visa vad man slagit, ranker som avslöjar och belönar. *Varför:*
   progression och planering, som VD:n efterfrågat. Kampanjkartan är grunden.
5. **Masters och Nether Bosses (§6).** Bossar med en regel man bygger mot, Trait Materials efter 3
   segrar. *Varför:* skäl att gå tillbaka och bli starkare, och mål för fynd.
6. **Minions (§4).** Ett eget bygglager (Necromancer och Inquisitor i originalet). *Varför:* djup.
   *Tonregel:* temat måste vara ljust (t.ex. Huldas rotskott, Ronjas falk), inte nekromanti.
7. **Gudar, Favor och butiker (§7).** Varje Realm får en "gud" med egna föremål att köpa för Realmens
   märken. *Varför:* fynd med mål, och skäl att välja Realm.
8. **Projects via Byggmästaren (§7).** Långsiktiga mål som låser upp basen.
9. **Klass och ras (§3).** Klasscirkeln (×2/½) och ras-Mastery. *Varför:* djup i sammansättningen.
   Väntar tills vi har fler hjältar och fiender.
10. **Slutspel:** reliker, kort, False Gods, Gate of the Gods och Arena-draft. Senare.

## Källor

- [Codex Reference (Steam-guide, spelets Codex 2.0.37)](https://steamcommunity.com/sharedfiles/filedetails/?id=2197484456)
- [Character Specialization Guide (2.0.37)](https://steamcommunity.com/sharedfiles/filedetails/?id=2190265173)
- Wiki: [Combat](https://siralimultimate.wiki.gg/wiki/Combat), [Specializations](https://siralimultimate.wiki.gg/wiki/Specializations),
  [Artifacts](https://siralimultimate.wiki.gg/wiki/Artifacts), [Spell Gems](https://siralimultimate.wiki.gg/wiki/Spell_Gems),
  [Buffs](https://siralimultimate.wiki.gg/wiki/Buffs), [Debuffs](https://siralimultimate.wiki.gg/wiki/Debuffs),
  [Minions](https://siralimultimate.wiki.gg/wiki/Minions), [Realms](https://siralimultimate.wiki.gg/wiki/Realms),
  [Projects](https://siralimultimate.wiki.gg/wiki/Projects), [Cards](https://siralimultimate.wiki.gg/wiki/Cards),
  [Arena](https://siralimultimate.wiki.gg/wiki/Arena), [Gamemode](https://siralimultimate.wiki.gg/wiki/Gamemode),
  [FAQ](https://siralimultimate.wiki.gg/wiki/Frequently_asked_questions), [Starter guide](https://siralimultimate.wiki.gg/wiki/Starter_guide)
- [Siralim Ultimate 2.0 patchnoter](https://www.thylacinestudios.com/blog/siralim-ultimate-2-0-patch-notes),
  [Survey results](https://www.thylacinestudios.com/blog/siralim-ultimate-survey-results)
- [Trait-kompendium (CSV, version 1.1.0)](https://github.com/berated-bert/siralim-planner/tree/master/data/siralim-ultimate-compendium)
- [Vaporlens: Steam-recensioner](https://vaporlens.app/app/1289810/siralim_ultimate),
  [How to Make a Build](https://gamepretty.com/siralim-ultimate-how-to-make-a-build-step-by-step-guide/)
