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
