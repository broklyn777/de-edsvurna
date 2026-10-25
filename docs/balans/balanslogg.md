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
