# Djupsteget: mätning av DEPTH_STEP (0,08 / 0,03 / 0)

2026-10-24, gren `djup-matning` (från `test-0.30`). Spelets värde är oförändrat (`CombatSim.DEPTH_STEP := 0.08`).
Bakgrund: `docs/research/djupvaggen.md` (grenen worktree-agent-a9a7…, F1): fiendernas *nivå* växer redan med djupet
(+5 nivåer per djup, `HeroStats.enemy_level`), och `DEPTH_STEP` lägger +8 % stats per djup ovanpå (från 0.14, innan
nivåerna fanns). Den här mätningen prövar att sänka eller ta bort den extra faktorn.

## Hur

Botarna kan nu byta steget utan att spelet ändras: `CombatSim.depth_step` (static var, förval `DEPTH_STEP`) sätts från
miljövariabeln `DJUPSTEG` i `tests/soak.gd` och `tests/balance_report.gd`. `BALANS=grotta` fick `GROTTA_DJUP=n` (fyra
hjältar med startmakron på väntad nivå på djup n; förval 1 som förut).

```bash
SOAK=karriar DJUPSTEG=0.03 godot --headless --path . --script res://tests/soak.gd -- --runs=80 --descents=18 --verbose
BALANS=grotta GROTTA_DJUP=3 DJUPSTEG=0.0 godot --headless --path . --script res://tests/balance_report.gd
```

Karriären: 80 profiler (frö 1–80) × 18 nedstigningar per variant, samma frön, samma bot som i `svarighetskurva.md`
(MACRO med startmakron och makroförslag, smedjan, billigaste perken, tre Realms i tur, den levande kartan och världen på,
instabilitet 0, inga löften). Ca 5,5 min per variant.

## Karriären

### Vinst per nedstigning

| Nedstigning | 0,08 (i dag) | 0,03 | 0 |
|---|---|---|---|
| 1 | 99 % | 99 % | 99 % |
| 2 | 39 % | 41 % | 49 % |
| 3 | 25 % | 58 % | 59 % |
| 1–3 | 54 % | 66 % | 69 % |
| 4–8 | 51 % | 54 % | 62 % |
| 9–13 | 44 % | 52 % | 62 % |
| 14–18 | 43 % | 52 % | 66 % |

### Vinst per djup (alla 1 440 körningar; antal körningar, sällskapets snittnivå)

| Djup | Väntad nivå | 0,08 | 0,03 | 0 |
|---|---|---|---|---|
| 1 | 3 | 98 % (112, 2,9) | 98 % (99, 2,3) | 98 % (94, 1,9) |
| 2 | 8 | 61 % (206, 7,3) | 62 % (169, 6,5) | 63 % (145, 5,9) |
| 3 | 13 | 51 % (278, 12,9) | 60 % (199, 11,8) | 61 % (152, 10,6) |
| 4 | 18 | 52 % (328, 18,7) | 52 % (219, 16,4) | 65 % (153, 15,2) |
| 5 | 23 | **31 %** (319, 23,1) | 53 % (211, 21,2) | 58 % (172, 19,5) |
| 6 | 28 | **20 %** (156, 27,7) | 51 % (214, 25,7) | 62 % (149, 23,6) |
| 7 | 33 | **14 %** (37, 31,3) | 42 % (178, 29,8) | 61 % (146, 27,7) |
| 8 | 38 | 0 % (4) | 40 % (94, 33,9) | 67 % (125, 31,7) |
| 9 | 43 | – | 31 % (39, 37,3) | 60 % (117, 35,0) |
| 10 | 48 | – | 50 % (12) | 52 % (85, 38,2) |
| 11–14 | | – | 20–100 % (6) | 63–83 % (102) |

Med 0 vinner boten 52–67 % på varje djup från 2 till 12 trots att sällskapet ligger 4–10 nivåer *under* fiendernas väntade
nivå: kurvan är platt, djupet känns bara i nivåsiffran.

### Var profilerna hamnar efter 18 nedstigningar

| | 0,08 | 0,03 | 0 |
|---|---|---|---|
| Högsta klarade djup (fördelning) | d4 10, d5 45, d6 20, d7 5 | d5 3, d6 15, d7 30, d8 20, d9 7, d10 4, d12 1 | d7 3, d8 13, d9 22, d10 9, d11 13, d12 10, d13 5, d14 5 |
| Högsta klarade djup, snitt | 5,3 | 7,4 | 10,1 |
| Djup vid nedstigning 6 / 12 / 18 | 3,2 / 4,7 / 5,9 | 3,6 / 5,7 / 7,8 | 4,2 / 7,1 / 10,6 |
| Nivå vid nedstigning 18 | 28,9 | 34,2 | 41,4 |
| Slipar (djup redan klarat) | 278 av 1 440 | 204 | 117 |
| Ingen ny bästa djup i ned 13–18 | 7 profiler (d4–5) | 0 | 0 |

**Var de fastnar.** Med 0,08 tar väggen vid djup 5–6 (31 % → 20 %); nedstigning 18 förlorar 52 av 56 gånger mot bossen på
våning 2. Med 0,03 flyttas den till djup 8–9 (40 % → 31 %), också där mest bossen. Med 0 syns ingen vägg inom 18
nedstigningar; profilerna klättrar ungefär ett djup per 1,8 nedstigningar.

**Början.** Nedstigning 1 och djup 1 påverkas inte (faktorn är 1 på djup 1). Nedstigning 2 (djup 2, två hjältar) går från 39
till 41 % (0,03) och 49 % (0). Den stora skillnaden är nedstigning 3: 25 % → 58–59 %. Med 0,08 föll 46 av 60 förluster
där mot bossen på våning 2 på djup 2–3.

## Grottan, en körning med fyra hjältar på väntad nivå (`BALANS=grotta`, 100 körningar per ruta)

Utan artefakter, troféer, perks och material, så siffrorna är lägre än i karriären; jämför bara mellan varianterna. Djup 1 är
detsamma för alla varianter (faktorn är 1) och kördes inte om; tidigare mätningar ger ungefär 48 % (MACRO) och 62 % (TUNED).

| Djup (nivå) | Realm | 0,08 MACRO / TUNED | 0,03 MACRO / TUNED | 0 MACRO / TUNED |
|---|---|---|---|---|
| 3 (13) | Kryptan | 2 / 5 % | 8 / 23 % | 42 / 52 % |
| 3 (13) | Kapellet | 2 / 0 % | 12 / 11 % | 41 / 50 % |
| 5 (23) | Kryptan | 0 / 0 % | 4 / 12 % | 38 / 55 % |
| 5 (23) | Kapellet | 0 / 0 % | 5 / 5 % | 48 / 63 % |

(Försiktig och direkt bot följer samma mönster: 0–4 % / 7–25 % / 41–67 %.) Med 0 är ett sällskap på väntad nivå lika starkt
mot djup 3 och 5 som mot djup 1, alltså precis det nivåkurvan är byggd för. Med 0,08 räcker nivån inte alls: det som bär
karriären på djup 3–5 är artefakter, troféer och perks, och de tar slut.

## Rekommendation (VD beslutar)

**0,03 ser ut som den bästa kompromissen**, med 0 som det renare Siralim-valet:
- **0** tar bort dubbelskalningen helt och kurvan blir platt kring 60 %. Djupet blir då bara en nivåsiffra: boten når djup
  10–14 på 18 nedstigningar och slipar nästan aldrig (8 %). Risken är att mittspelet blir för lätt och att bygget slutar
  spela roll; då behövs andra skäl att gå djupare (fiendernas nivå växer, nya fiender och regler, motdrag från djup 1–3).
- **0,03** behåller en mjuk lutning (djup 2–6 51–62 %, djup 7–9 31–42 %), mittspelet ligger kring 52 %, och taket flyttas
  från djup 5–6 till ungefär djup 8–9 för en bot med startmakron. Där borde en riktig spelare med inställda makron och
  troféer orka längre, vilket är vad ledstjärnan vill: bygget bär det sista.
- **0,08** ger det vi mätte förut: vägg vid djup 5–6 (20 % på djup 6), 7 av 80 profiler utan nytt djup under de sista sex
  nedstigningarna.

Början blir inte för lätt med någon av varianterna: djup 1 och nedstigning 1 är oförändrade, nedstigning 2 är fortfarande
41–49 %. Nedstigning 3 blir däremot betydligt snällare (25 → 58 %).

## Förbehåll

- Boten är enkel (slumpade troféer, inga material, billigaste perken, bara Domens kall, instabilitet 0, inga löften). En
  riktig spelare ligger troligen över alla tre kurvorna, mest från djup 4.
- Fiendernas `stat_mult` per våning och elitgruppernas mildring är oförändrade; med 0 kan de behöva höjas lite för att
  behålla bett (forskningens F1).
- 80 profiler: enskilda celler med få körningar (djup 7–8 för 0,08, djup 10+ för 0,03) är osäkra.
- Grottmätningen på djup 3 och 5 saknar artefakter och troféer och visar bara riktningen.
- Alla tre varianterna gav samma sorts kontrollvarningar som förut (5–7 st, någon har inte agerat på 17–25 turer i crypt_3
  under statusen Frusen); de beror inte på djupsteget.
- Silver, troféchans och fynd per djup är oförändrade i alla varianter.
