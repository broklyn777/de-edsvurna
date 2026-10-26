# Balansloggen

Balansloopen (docs/plan/balanssimulering.md, VD:s beslut 2026-10-25): ett värde per varv, bara datafiler. Mål per strid
med tömda Charges (diagnostik): elit 70–85 %, Nemesis 60–75 %, väktare 65–80 %, boss 50–65 %. Mål per nedstigning (B):
huvudbossen 26–48 %, väktaren 33–59 %. Utgångsläget är `balans-0.30.42-v0.csv`.

Mätning per varv: `tests/balance_sim.gd -- --realm=<r> --enc=<möte> --fifth= --runs=50` (n 200 på nivån, 100 på ±1; 50
nedstigningar per nivå för de tömda Charges och nivån vid striden), sedan Realmens nedstigningar på djup 1–3 med
`--enc=__none__ --runs=100` (bara nedstigningar, fyra och fem). Kandidatvärden prövades i en andra arbetskatalog; bara
det valda värdet är incheckat. Tabellerna: vinst (tömda Charges), median turer, andel strider där minst en stupar.

## Varv 1: Grimmens kyrkogård (chapel_e9)

`data/encounters.json` chapel_e9 `stat_mult` **1.1 → 0.95** (`first_descent_stat_mult` 0.72 orörd).

Prövade värden (tömda Charges, väntad nivå): 0.95 / 0.94 / 0.93 / 0.85. Mötet är mycket brant: 0.85 ger 93–100 % överallt,
0.93–0.94 lyfter elitraden på djup 3 över 85 % utan att flytta Nemesis på djup 2 över 57 %. 0.95 är kompromissen.

| Rad | Nivå | Före (1.1) | Efter (0.95) | Mål | Turer före → efter | Minst en stupar |
|---|---|---|---|---|---|---|
| d1 elit v1 | 2 / **3** / 4 | 1 / **61** / 100 | 16 / **99,5** / 100 | 70–85 | 52 → 42 | 84,5 → 22 % |
| d1 Nemesis v2 | **5** | **83,5** | **100** | 60–75 | 54 → 42 | 71 → 7,5 % |
| d2 elit v1 | **6** | **97** | **100** | 70–85 | 39 → 31 | 18 → 0 % |
| d2 Nemesis v2 | 5 / **6** / 7 | 0 / **6,5** / 100 | 0 / **57,5** / 100 | 60–75 | 45 → 56 | 99,5 → 85,5 % |
| d3 elit v1 | 6 / **7** / 8 | 0 / **18** / 100 | 0 / **82,5** / 100 | 70–85 | 56 → 60 | 89,5 → 44 % |
| d3 Nemesis v1 | **7** | **18** | **82,5** | 60–75 | 56 → 60 | 89,5 → 44 % |
| d3 Nemesis v2 | 6 / **7** / 8 | 0 / **6** / 100 | 0 / **61,5** / 100 | 60–75 | 43 → 55 | 98 → 72,5 % |

De tre raderna som föll sällskapet med 80 % av Charges (6–18 %) ligger nu på 57–83 %: elitraden på djup 3 och Nemesis på
djup 3 v2 inom bandet, Nemesis på djup 2 v2 2,5 enheter under. Djup 1 och djup 2 v1 blev för lätta (99,5–100 %), som de
andra elitgrupperna på våning 1 redan var (88–100 %).

Kapellets nedstigningar (100 per nivå, väntad nivå; före → efter):

| Djup | Lag | Klarad | Elit i nedstigningen | Nemesis | Boss/väktare |
|---|---|---|---|---|---|
| 1 | 4 | 67 → 73 % | 94 → 99 % | 84 → 91 % | 77 → 78 % |
| 2 | 4 | 80 → 88 % | 92 → 96 % | 79 → 88 % | 98 → 98 % |
| 2 | 5 | 99 → 100 % | | | |
| 3 | 4 | 55 → 62 % | 90 → 99 % | 75 → 86 % | 70 → 68 % |
| 3 | 5 | 95 → 98 % | | | |

Flytten (+6–8 enheter) kommer helt från elit- och Nemesisstriderna; boss och väktare är oförändrade. Kapellet var redan
FÖR LÄTT på alla djup och blev lite lättare.

## Varv 2: Skrivarens avskrifter (crypt_e8)

`data/encounters.json` crypt_e8 `stat_mult` **1.3 → 1.24** (`first_descent_stat_mult` 0.72 orörd).

Prövade värden: 1.24 / 1.22 / 1.15. 1.15 gav 93 % på djup 1 och 84,5 % för Nemesis på djup 2–3; 1.22 lade Nemesis på
djup 2 på 78 %. Benskrivarens Antecknat (mindre skada för varje upprepad handling) straffar djup 1 hårdast, där sällskapet
saknar artefakter och har färst olika handlingar; därför var mötet svårt på djup 1 och lätt på djup 2–3 v1.

| Rad | Nivå | Före (1.3) | Efter (1.24) | Mål | Turer före → efter | Minst en stupar |
|---|---|---|---|---|---|---|
| d1 elit v1 | 2 / **3** / 4 | 0 / **54** / 100 | 0 / **78** / 100 | 70–85 | 65 → 62 | 81 → 61,5 % |
| d1 Nemesis v1 | **3** | **49** | **78** | 60–75 | 61 → 62 | 85 → 61,5 % |
| d1 Nemesis v2 | 4 / **5** / 6 | 0 / **53,5** / 100 | 1 / **68** / 100 | 60–75 | 60 → 55 | 93 → 93 % |
| d2 elit v1 | **6** | **100** | **99,5** | 70–85 | 47 → 41 | 5 → 5,5 % |
| d2 Nemesis v2 | 5 / **6** / 7 | 0 / **63** / 100 | 0 / **74** / 100 | 60–75 | 76 → 67 | 62,5 → 53 % |
| d3 elit v1 | **7** | **96** | **99** | 70–85 | 55 → 46 | 8 → 7 % |
| d3 Nemesis v2 | 6 / **7** / 8 | 1 / **60,5** / 100 | 0 / **72,5** / 100 | 60–75 | 67 → 66 | 63,5 → 53,5 % |

Djup 1 inom elitbandet och alla Nemesisrader på våning 2 inom 60–75 %. Nemesis på djup 1 v1 (samma strid som elitgruppen)
ligger 3 enheter över sitt band. Djup 2–3 v1 är fortfarande för lätta (99–100 %), som alla elitgrupper där.

Kryptans nedstigningar (100 per nivå, väntad nivå; före → efter): djup 1 fyra 38 → 40 %, djup 2 fyra 81 → 81 %, fem 97 →
98 %, djup 3 fyra 93 → 94 %, fem 98 → 99 %. Elit i nedstigningarna djup 1 89 → 95 %, Nemesis 80 → 81 %, bossen 47 → 47 %.
Inget annat flyttade sig utanför bruset.

## Varv 3: Inkvisitorns domstol (chapel_g2, väktaren på kapellets djup 3)

`data/encounters.json` chapel_g2 `stat_mult` **1.6 → 1.55**.

Prövade värden: 1.55 / 1.5 (1.5 gav 85,5 % tömd).

| Rad | Nivå | Före (1.6) | Efter (1.55) | Mål | Turer före → efter | Minst en stupar |
|---|---|---|---|---|---|---|
| tömd (47 % Charges) | 6 / **7** / 8 | 0 / **61** / 100 | 0 / **72** / 100 | 65–80 | 74 → 73 | 86 → 74,5 % |
| fulla Charges | 6 / **7** / 8 | 0 / **88,5** / 100 | 0 / **98** / 100 | – | 74 → 67 | 63,5 → 42 % |

Inom väktarbandet. BRANT NIVÅ står kvar (−72/+28): en nivå är för stor för nivåmålet, se sammanfattningen v0 punkt 1.

Kapellets nedstigningar på djup 3 (100 per nivå, efter varv 1 → efter varv 3): fyra 62 → 68 % (väktaren i nedstigningen
68 → 75 %), fem 98 → 99 %. Kapellet djup 3 med fyra var redan över bandet B (33–59 %) och hamnar längre över; det är
väktarstriden som nu ligger rätt, resten av nedstigningen (elit 99 %, Nemesis 86 %) bär inte någon svårighet.

## Utredning: varför djup 2–3 är lättare än djup 1 (inget ändrat)

Diagnostik med `Report.sim_descents` och valfri utrustning eller `CombatSim.depth_step` (samma som DJUPSTEG), 100
nedstigningar, fyra hjältar, väntad nivå, efter varv 1–3.

- **Nivån gör djup 2–3 svårare, inte lättare.** Väntad nivå 3 / 6 / 7 är i tillväxtskalan 3 / 7,3 / 11,2 mot fiendernas
  3 / 8 / 13 mellan våning 1 och 2 (avrundningen ligger 0 / 0,7 / 1,8 tillväxtnivåer under). Fiende/hjälte i stats på
  våning 1: 1,14 / 1,18 / 1,26. Och sällskapet växer bara på djup 1 under nedstigningen (3 → 4,8 vid bossen, +34 % stats);
  på djup 2 6 → 6,2, på djup 3 7 → 7,0.
- **Utrustningen bär hela skillnaden.** SIM_GEAR ger djup 1 bara Paladinens svärd nivå 3, djup 2 alla ett svärd nivå 3 och
  en trofé, djup 3 nivå 5 och trofé. Kryptan djup 1 med djup 2:s utrustning: 40 → **99 %** (bossen 47 → 99 %); kapellet
  djup 1: 73 → **98 %**. Kryptan djup 2 med djup 1:s utrustning: 81 → **4 %** (väktaren 85 → 7 %).
- **Inte bossen mot väktaren:** med fulla Charges vinner Benfursten (crypt_3) på djup 2 99 % och Midnattsklockan (crypt_g1)
  90,5 %; huvudbossen är inte svårare än väktaren på samma djup.
- Djupsteget (+3 % per djup) är litet mot utrustningens hopp. Prov: 0,10 → kryptan d2 81 → 65 %, d3 94 → 48 %; kapellet d2
  88 → 75 %, d3 68 → 20 %. 0,12 → kryptan d2 60 %. 0,15 → kryptan d2 59 %, d3 7 %. Djup 3 svarar mycket brantare än djup 2.

## Djup 1 med karriärbotarnas utrustning (2026-10-25)

`SIM_GEAR` djup 1: artefaktnivå 2 för alla (Paladinen 3) och en trofé, i stället för bara Paladinens svärd.
Nedstigningar med fyra, 100 per nivå, väntad nivå: kryptan 40 → 74 %, kapellet 73 → 91 %, Trollberget 4 % (oförändrat).
Med ärlig utrustning är djup 1 ungefär lika svårt som djup 2 (kryptan 81 %, kapellet 88 %) och allt ligger över mål B
(26–48 %). Stöder förslaget om ett större djupsteg; inget balansvärde ändrat.

## Balans v1 (gren `balans-v2`, VD:s beslut 2026-10-25)

Mätningen under justeringen: bara nedstigningar på väntad nivå (`--enc=__none__ --levels=0 --runs=100`, ny flagga
`--levels`), prov utan att ändra spelet med `DJUPSTEG`, `BERGSTEG`, `FEM_I_FYRA` och `MOTE_MULT=möte=värde,…` i
`tests/balance_sim.gd`. Utgångsläget är v0 med varv 1–3 och djup 1 med karriärbotarnas utrustning (kryptan d1 74 %,
kapellet d1 91 %). Siffrorna: andel klarade nedstigningar, med boss/väktare i nedstigningen inom parentes.

### Steg 1: nivåkurvan (`HeroStats.strength`)

Styrkan per nivå är en egen kurva, delad av hjältar och fiender: +20 % mot nivån innan för nivå 2–10, sedan
13 % + 7 % · e^(−(L − 10)/10) (+19,3 % nivå 11, +15,6 % nivå 20, +13,9 % nivå 30). Takten är orörd: erfarenheten per nivå
(`xp_to_next`), fiendernas nivå per djup och våning (`enemy_level`) och väntad nivå (3, 6, 7, 8 …) följer variant C som
förut. Bara multiplikatorn på en given nivå ändras: förr 1 + 0,3 · (g(L) − 1). `enemy_level_mult` = `strength(enemy_level)`.

| Nivå | Förr | Steg förr | Nu | Steg nu |
|---|---|---|---|---|
| 1 | 1,00 | – | 1,00 | – |
| 2 | 1,30 | +30 % | 1,20 | +20 % |
| 3 | 1,60 | +23 % | 1,44 | +20 % |
| 4 | 1,90 | +19 % | 1,73 | +20 % |
| 5 | 2,20 | +16 % | 2,07 | +20 % |
| 6 | 2,90 | +32 % | 2,49 | +20 % |
| 7 | 4,05 | +40 % | 2,99 | +20 % |
| 8 | 5,47 | +35 % | 3,58 | +20 % |
| 9 | 7,09 | +30 % | 4,30 | +20 % |
| 10 | 8,88 | +25 % | 5,16 | +20 % |
| 11 | 10,82 | +22 % | 6,16 | +19,3 % |
| 12 | 12,90 | +19 % | 7,31 | +18,7 % |
| 13 | 15,10 | +17 % | 8,64 | +18,2 % |
| 15 | 19,83 | +14 % | 11,92 | +17,2 % |
| 20 | 33,31 | +9 % | 25,23 | +15,6 % |

Gamla profiler: nivån står kvar (ingen omräkning). Resten från 0.19-omräkningen (`carry`) blir en del av en nivå på takten
(`growth_level`: `strength(new_level(old_level(L) + carry))`), så att hjälten står lika långt från fienderna som förut.
En hjälte på nivå 8: Paladinens Health 492 → 322 (−35 %); mot fienderna på djup 3 våning 2 1,07 → 0,83 och på djup 4
(där nivå 8 är väntad) 0,79 → 0,63 i stats, nästan helt av djupsteget (kurvan ensam: 1,13 → 1,08 mot våning 2 på djup 3).

Nedstigningar efter steg 1 (djupsteg 3 %, fyra): kryptan 72 / 99 / 97 %, kapellet 88 / 98 / 93 %, lunden 78 / 89 / 99 %,
Trollberget fyra 69 / 100 / 80 %, fem 98 / 100 / 99 %. Allt blev lättare: en nivå mellan sällskapet och fienderna väger
mindre.

### Steg 2: djupsteget (`CombatSim.DEPTH_STEP`) 0,03 → **0,15**

| Djupsteg | Kryptan d2 / d3 | Kapellet d2 / d3 | Lunden d2 / d3 |
|---|---|---|---|
| 0,03 | 99 / 97 | 98 / 93 | 89 / 99 |
| 0,10 | 92 / 93 | 92 / 68 | 83 / 87 |
| 0,15 | 92 / 72 | 92 / 30 | 63 / 71 |
| 0,20 | 82 / 13 | 82 / 4 | 47 / 58 |

Djup 3 svarar mycket brantare än djup 2: djup 2 är för lätt vid alla steg som inte gör djup 3 omöjligt, eftersom väktarna
på djup 2 (Midnattsklockan, Abbedissans kör) var svaga för sitt djup. 0,15 lägger djup 3 närmast bandet (två över, en
under) och djup 2 rättas med väktarna i steg 5. Djup 1 påverkas inte (`depth_mult(1)` = 1). Varning: 0,15 är linjärt och
läggs på fiendernivåerna; djup 4+ är inte mätt här (karriärbotarna bör köras före en sammanslagning).

### Steg 3: fem i en Realm byggd för fyra

`RunState.full_party_size()`: fem i kryptan, kapellet eller lunden möter fiender som mot fem på djup som Realmen inte är
klarad på (`depth_cleared`, `Profile.realm_depth`), som mot fyra på klarade djup. Mötena där saknar Trollbergets "extra",
så "som mot fem" är `CombatSim.FIVE_IN_FOUR` på Health, Attack och Intelligence (opts `five_in_four`). Test:
`test_party_five.gd::test_five_in_a_realm_for_four_scales_on_the_deepest_depth`.

| FIVE_IN_FOUR | Kryptan d2 / d3 | Kapellet d2 / d3 | Lunden d2 / d3 |
|---|---|---|---|
| (som mot fyra, steg 1) | 100 / 100 | 100 / 100 | 100 / 100 |
| 1,25 | 62 / 79 | 77 / 48 | 82 / 79 |
| 1,35 | 54 / 67 | 61 / 32 | 65 / 82 |
| 1,45 | 50 / 59 | 47 / 21 | 43 / 83 |

Valt **1,4** (mellan de två sista; med väktarna i steg 5 inräknade).

### Steg 4: Trollbergets eget djupsteg (`realms.json` mountain "depth_step" **0,05**)

Per fiendedjup över 1 (djup 1 = fiendedjup 2, så att också djup 1 räknas), gånger det allmänna djupsteget. Test:
`test_party_five.gd::test_mountain_has_its_own_depth_step`. Med djupsteg 0,15 (fyra / fem):

| Bergsteg, Tullen vid bron | Djup 1 | Djup 2 | Djup 3 |
|---|---|---|---|
| 0, 1,17 | 18 / 87 | 93 / 100 | 21 / 79 |
| 0,04, 1,5 | 6 / 75 | 0 / 32 | 3 / 52 |
| 0,06, 1,6 | 1 / 74 | 0 / 0 | 1 / 39 |
| 0,15, 1,17 | 1 / 25 | 1 / 82 | 0 / 1 |

Berget är mycket brant (fem på djup 3: 79 % vid ×1,45, 1 % vid ×2,10). Ett linjärt steg kan inte ensamt ge både djup 1
och djup 3 rätt (bossen på djup 1 behöver ungefär 0,10, väktaren på djup 3 0,05), och Tullen vid bron (djup 2) var svag
för sitt djup. 0,05 ger djup 3; djup 1 och 2 rättas med mötena i steg 5.

### Steg 5: mötena (`data/encounters.json` stat_mult, sex värden)

| Möte | Djup | Förr → nu | Prövat (nedstigning, väktare/boss i den) |
|---|---|---|---|
| Benfurstens sal (crypt_3) | kryptan 1 | 1,02 → **1,14** | 72 (79) → 42 (46) |
| Biskopens altare (chapel_3) | kapellet 1 | 1,06 → **1,33** | 88 (93); 1,22: 69 (73); 1,38: 24 (25); 1,33: 36 (38) |
| Midnattsklockan (crypt_g1) | kryptan 2 | 1,025 → **1,24** | 92 (96); 1,17: 72 (75); 1,24: 53 (55) |
| Abbedissans kör (chapel_g1) | kapellet 2 | 0,96 → **1,32** | 92 (98); 1,12: 84 (89); 1,32: 55 (59) |
| Tullen vid bron (troll_g1) | berget 2 | 1,17 → **1,45** | fem 100; 1,5: 32; 1,45: 53 (fyra 0) |
| Bergakungens sal (troll_3) | berget 1 | 1,05 → **1,12** | fem 75 (vid 1,05 och bergsteg 0,04); 1,10: 50; 1,12: 42 (fyra 1) |

Utanför budgeten (sex värden) och kvar utanför bandet i proven: lunden djup 1 (78 %, Vävmoderns krona), lunden djup 2–3
med fyra (63 / 71 %), kryptan djup 3 med fyra (72 %, Kistornas råd) och kapellet djup 3 med fyra (30 %, Inkvisitorns
domstol, under bandet). Hela tabellen: `docs/balans/sammanfattning-v1.md`.

## Balans v2: rättelse efter karriärbotarna (2026-10-26)

Karriärbotarna (`SOAK=karriar`, 40 profiler × 18 nedstigningar) med v1: kryptan d4 59 → 0 %, kapellet d4 52 → 14 %, lunden
d4 62 → 4 %, ingen förbi djup 4 (förr djup 9). Orsak: fienderna och hjältarna delar nu styrkekurvan, och på karriärens
nivåer (8,6 på djup 4, 10,3 på djup 7) ger djupsteget 3 % exakt samma kvot fiende/hjälte som förr (räknat: 1,00 på djup
4–9). Varje procent över 3 lägger på: 0,05 → +6–13 %, 0,08 → +14–32 %, 0,15 → +34–60 % på djup 4–9.

Prov (karriären, vinst per djup, kryptan / kapellet / lunden; djupaste djupet efter 18 nedstigningar):

| Djupsteg och möten | n | Djup 4 | Djup 5 | Djup 6 | Djupast |
|---|---|---|---|---|---|
| förr (test-0.30) | 40 | 59 / 52 / 62 | 38 / 54 / 33 | 53 / 56 / 45 | 9 |
| v1, 0,15 | 40 | 0 / 14 / 4 | – | – | 4 |
| 0,08, v1:s möten | 20 | 19 / 38 / 40 | 8 / 33 / 50 | 0 / 0 / – | 6 |
| 0,05, v1:s möten | 20 | 64 / 43 / 43 | 8 / 57 / 74 | 19 / 0 / 0 | 7 |
| 0,05, möten A (nedan) | 40 | 33 / 42 / 46 | 39 / 31 / 35 | 37 / 25 / 0 | 7 |
| **0,03, möten A** | 40 | 36 / 46 / 42 | 35 / 60 / 61 | 48 / 36 / 43 | **9** |

Väktarna och bossarna återkommer var tredje djup (huvudbossen på djup 1, 4, 7, väktarna på 2, 5, 8 och 3, 6, 9), så
v1:s höjningar av Midnattsklockan och Abbedissans kör gav väggen på djup 5 (kryptan 8 %). Möten A (tre nya värden av
åtta tillåtna): **crypt_g1 1,24 → 1,10**, **chapel_g1 1,32 → 1,20**, **chapel_g2 1,55 → 1,45**. De andra föreslagna
(grove_3, crypt_g2, grove_g1/g2 uppåt) gjordes inte: de skulle sänka karriären på djup 4–6 där de återkommer.

Valt: **`DEPTH_STEP` tillbaka till 0,03** (spelets värde före balansen). Trollbergets eget steg **0,05 → 0,17** så att
berget blir lika brant som i v1 (0,15 × 0,05 tillsammans ≈ 0,03 × 0,17 per fiendedjup); karriären kördes med 0,15 (berget
vinns ändå inte med fyra). Botarna i Trollberget: 0 % i alla versioner med fyra (karriären går dit var fjärde nedstigning
med fyra; förr 0–22 %). Det är botens val, berget kräver fem.

Balanssimuleringen på väntad nivå med v2 (nedstigningar, 100 per rad, fyra / fem):

| | Djup 1 | Djup 2 | Djup 3 |
|---|---|---|---|
| Kryptan | 42 | 97 / 73 | 97 / 92 |
| Kapellet | 36 | 93 / 83 | 96 / 79 |
| Lunden | 78 | 89 / 87 | 99 / 86 |
| Trollberget | 1 / 39 | 0 / 56 | 6 / 48 |

Djup 2–3 i simuleringen ligger åter över mål B: simuleringens väntade nivå och karriärens verklighet går inte att få i mål
med samma mötesvärden, eftersom samma väktare möter sällskapet på djup 2 (väntad nivå 6, simuleringen 93–97 %) och på djup 5
(karriären nivå 9,4, 35–61 %). Karriären är grinden; djup 2–3 i karriären vinns 54–81 % (förr 37–71 %).

Felet i karriären (frö 26, "paladin har inte fått agera på 21 turer … troll_2a"): ingen motorbugg. Paladinen snärjdes på
tur 9 (sjönk längst ned), slet sig loss på tur 13 (Fri), stod överst på tur 19 och knuffades ned när Lirien flyttade sig
själv överst (originalets regel). Under väntan dog fyra figurer och kontrollens gräns (4 × levande) föll från 36 till 20.
`tests/soak.gd` räknar nu gränsen på hur många som levde när hjälten senast stod på tur; frö 26 ger inga fel.

## Torun som den femte (gren `torun`, 2026-10-26, en justeringsomgång godkänd av VD)

Mätning: `tests/balance_sim.gd -- --realm=<r> --depth=<d> --fifth=torun --n=40 --n-side=20 --runs=40 --levels=0`, jämfört
med samma körning `--fifth=imma`. Tabellen: vinst per nedstigning med fem i sällskapet (n 40, brus ungefär ±15 enheter).

| Varv | Ändring | Trollberget d1 / d2 / d3 | Kryptan d2 / d3 | Kapellet d2 / d3 |
|---|---|---|---|---|
| Imma | – | 35 / 40 / 62,5 | 65 / 87,5 | 87,5 / 75 |
| 0 | första versionen (attack 8,0, fart 8) | 2,5 / 0 / 15 | 67,5 / 60 | 57,5 / 60 |
| 0b | attack 8,8, Kilslag i makrot | 5 / 0 / 20 | – | – |
| 1 | Stå beredd provocerar också; Health 120, Defense 6,5; Kilslag 150 %; makrot provocerar | 10 / 2,5 / 7,5 | – | – |
| 2 | attack 10, fart 11; Kilslag 8 Charges; makrot provocerar inte längre | 25 / 15 / 25 | – | – |
| 3 | attack 11, fart 13 | 20 / 17,5 / 25 | 72,5 / 85 | 77,5 / 85 |

Valt: **varv 2** (attack 10, fart 11). Varv 3 gav inget mer i Trollberget men gick förbi Imma i kryptan d2 och kapellet d3;
varv 2 i kryptan och kapellet är inte mätt (det ligger mellan varv 0 och varv 3). Trollberget når inte inom 10 enheter av
Imma: 10 / 25 / 37,5 enheter under. Att provocera hjälpte inte (Trollbergets fara är nötningen över en lång nedstigning,
inte ett fokuserat mål); fart och anfall gjorde det. Imma slår med fart 18, alltså ungefär dubbelt så ofta som trollen.

Varv 4 (Claude, efter VD:s fråga): Kilslag +50 % även mot troll med Svedd hud (Trollhud), och en makrorad för det. Trollberget
d2 / d3 med fem: 15 / 25 % – oförändrat. I en enskild väktarstrid (troll_g1, d2, fulla Charges) får 73 av 77 Kilslag
bonusen; i nedstigningen är hennes 8 Kilslag slut före väktaren. Behålls (bara troll påverkas).

## Den delade lågan (Irrblossets trofé, gruppläkaren)

Ny vanlig trofé `shared_flame` (Irrblosset lämnar den i stället för Det släckta irrblosset, som finns kvar i datan): när
bäraren helar någon får hela sällskapet Läkning i 1 tur, en gång per tur; en Läkning som tickar räknas inte (`not_hot`).
Mätning: hela nedstigningar, fyra hjältar (Paladinen, Brokk, Alva, Eira) på väntad nivå, Alva med bara den trofén, ingen
artefakt, n = 60 per ruta, samma frön (`tests/_alva_sim.gd`, inte incheckad). `stola_fix` = Diakonens stola med `not_hot`.

| Varv | Ändring | Bot | Kryptan d1 / d2 / d3 | Kapellet d1 / d2 / d3 |
|---|---|---|---|---|
| 1 | lågan: Läkning 1 tur till alla, en gång per tur | MACRO | stola 52/40/57, radband 8/5/0, **låga 38/10/12** | stola 50/28/28, radband 0/3/7, **låga 7/2/15** |
| 2 | samma, med jämförelser | MACRO | ingen 5/3/0, stola_fix 30/10/12, **låga 38/10/12** | ingen 0/0/2, stola_fix 7/0/15, **låga 7/2/15** |
| 3 | samma | TUNED | ingen 18/8/0, radband 22/17/2, stola 65/65/58, stola_fix 37/32/30, **låga 47/43/28** | ingen 0/7/15, radband 0/7/22, stola 80/57/38, stola_fix 22/17/30, **låga 35/20/35** |

Lågan ligger 8–45 enheter **under** Diakonens stola som den är i spelet, och i snitt +0 (MACRO) / +7 (TUNED, −2 … +13)
över stolan med `not_hot`. Värdena behölls (1 tur, en gång per tur). **Fynd:** Diakonens stola håller sig själv vid liv:
Läkningens tick är en helning från bäraren, så stolan fyller på Läkningen varje tur (266 Läkningar mot 72 med `not_hot`
på 20 strider i crypt_2). Det ger +28–58 enheter. En rättelse (`"not_hot": true` i stolans `when`) är VD:s beslut.

Diakonens stola rättad (VD 2026-10-26, fråga 81): Läkningens tick räknas inte längre som en ny helning (`not_hot`), så stolan förnyar
inte sin egen Läkning i all oändlighet. TUNED kryptan 65/65/58 → 37/32/30, kapellet 80/57/38 → 22/17/30 (tabellen ovan).
