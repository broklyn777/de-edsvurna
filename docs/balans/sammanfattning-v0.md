# Balanssimuleringen, första tabellen (0.30.42-test, v0)

2026-10-25. Verktyget och målen: `docs/plan/balanssimulering.md`. Hela tabellen: `docs/balans/balans-0.30.42-v0.csv`
(2 032 rader). **Inga balansvärden är ändrade.** Det här är läget före balansloopen, för VD:s godkännande av målen.

Körningen: alla fyra Realms, djup 1–3, startmakron med makroförslag, utrustningen per fiendedjup (planen), fröna 1..N.
100 nedstigningar per nivå och lag; varje möte 200 strider på nivån där det brukar mötas (fulla och tömda Charges), 100
på ±1 nivå (tömda; boss och väktare 200, båda lägena). Fyra delkörningar, två åt gången: 3,6 timmar processortid, ungefär
2 timmar 15 minuter på klockan (Trollberget ensamt 1 h 45 min, de andra djup 2–3 1 h 23 min, djup 1 30 min).

## Väntad nivå

`HeroStats.expected_level(djup + depth_offset)`. Karriärbotarna (40 profiler × 18 nedstigningar) inom parentes.

| | Djup 1 | Djup 2 | Djup 3 |
|---|---|---|---|
| Kryptan | 3 (2,4) | 6 (7,3) | 7 (8,0) |
| Kapellet | 3 (5,7) | 6 (5,9) | 7 (8,0) |
| Sidenlunden | 3 (7,6) | 6 (5,9) | 7 (7,4) |
| Trollberget | 6 (6,6) | 7 (7,6) | 8 (7,3) |

## Föreslagna mål per nedstigning (VD bestämmer)

Härlett ur specens mål per strid, kedjat över en typisk nedstigning som når bossplatsen (mätt: 7,3 vanliga, 0,8 elit,
0,6 Nemesis, 1 boss eller väktare; 9,7 strider). Se planen för formeln.

| | A: specen rakt kedjad | B: vanliga grupper 99–100 % |
|---|---|---|
| Klarad, huvudbossen (djup 1, 4 …) | 16–42 % | 26–48 % |
| Klarad, väktaren (djup 2, 3, 5, 6 …) | 21–51 % | 33–59 % |
| Minst en hjälte stupar under nedstigningen | 60–92 % (väktare 49–89 %) | samma |
| Wipe (en förlorad strid) | 100 − klarad | samma |

Tabellen och CSV:n flaggar mot A. B finns därför att de vanliga grupperna i spelet aldrig förloras under nötningen
(100 % i varje Realm och djup, 2 % med en stupad), så A:s 93–98 % för vanliga grupper drar ned bandet med ungefär en
tredjedel utan att motsvara något i spelet.

## Hela nedstigningar (huvudmålen)

| Realm | Djup | Lag | Nivå −1 / väntad / +1 | Vinst | Mål (A) | Minst en stupar | Strider | Charges kvar | Flaggor |
|---|---|---|---|---|---|---|---|---|---|
| Kryptan | 1 | 4 | 2 / 3 / 4 | 20 / **38** / 56 % | 17–42 % | 91 % | 9.0 | 71 % | – |
| Kapellet | 1 | 4 | 2 / 3 / 4 | 31 / **67** / 84 % | 17–42 % | 78 % | 9.1 | 72 % | FÖR LÄTT, BRANT NIVÅ |
| Lunden | 1 | 4 | 2 / 3 / 4 | 22 / **42** / 64 % | 16–41 % | 91 % | 9.7 | 72 % | FÖR LÄTT, BRANT NIVÅ |
| Kryptan | 2 | 4 | 5 / 6 / 7 | 72 / **81** / 100 % | 22–52 % | 56 % | 9.5 | 71 % | FÖR LÄTT, PLATT NIVÅ |
| Kryptan | 2 | 5 | 5 / 6 / 7 | 96 / **97** / 100 % | 21–51 % | 31 % | 9.7 | 85 % | FÖR LÄTT, PLATT NIVÅ |
| Kryptan | 3 | 4 | 6 / 7 / 8 | 37 / **93** / 100 % | 21–51 % | 64 % | 9.6 | 69 % | FÖR LÄTT, BRANT NIVÅ, PLATT NIVÅ |
| Kryptan | 3 | 5 | 6 / 7 / 8 | 85 / **98** / 100 % | 21–51 % | 23 % | 9.7 | 83 % | FÖR LÄTT, PLATT NIVÅ |
| Kapellet | 2 | 4 | 5 / 6 / 7 | 64 / **80** / 100 % | 22–52 % | 35 % | 9.1 | 73 % | FÖR LÄTT |
| Kapellet | 2 | 5 | 5 / 6 / 7 | 93 / **99** / 100 % | 21–51 % | 15 % | 9.7 | 85 % | FÖR LÄTT, PLATT NIVÅ |
| Kapellet | 3 | 4 | 6 / 7 / 8 | 26 / **55** / 100 % | 22–53 % | 82 % | 8.6 | 71 % | FÖR LÄTT, BRANT NIVÅ |
| Kapellet | 3 | 5 | 6 / 7 / 8 | 61 / **95** / 100 % | 21–51 % | 33 % | 9.6 | 83 % | FÖR LÄTT, BRANT NIVÅ, PLATT NIVÅ |
| Lunden | 2 | 4 | 5 / 6 / 7 | 50 / **65** / 100 % | 21–51 % | 62 % | 9.7 | 73 % | FÖR LÄTT, BRANT NIVÅ |
| Lunden | 2 | 5 | 5 / 6 / 7 | 99 / **99** / 100 % | 21–51 % | 14 % | 9.7 | 86 % | FÖR LÄTT, PLATT NIVÅ |
| Lunden | 3 | 4 | 6 / 7 / 8 | 82 / **83** / 100 % | 21–51 % | 26 % | 9.7 | 73 % | FÖR LÄTT, PLATT NIVÅ |
| Lunden | 3 | 5 | 6 / 7 / 8 | 98 / **99** / 100 % | 21–51 % | 8 % | 9.7 | 85 % | FÖR LÄTT, PLATT NIVÅ |
| Berget | 1 | 4 | 5 / 6 / 7 | 0 / **4** / 100 % | 16–42 % | 100 % | 9.7 | 65 % | FÖR SVÅR, PLATT NIVÅ, BRANT NIVÅ |
| Berget | 1 | 5 | 5 / 6 / 7 | 50 / **69** / 100 % | 16–41 % | 74 % | 9.7 | 78 % | FÖR LÄTT, BRANT NIVÅ |
| Berget | 2 | 4 | 6 / 7 / 8 | 3 / **97** / 100 % | 21–51 % | 19 % | 9.6 | 64 % | FÖR LÄTT, BRANT NIVÅ, PLATT NIVÅ |
| Berget | 2 | 5 | 6 / 7 / 8 | 58 / **100** / 100 % | 21–51 % | 1 % | 9.7 | 78 % | FÖR LÄTT, BRANT NIVÅ |
| Berget | 3 | 4 | 7 / 8 / 9 | 2 / **75** / 99 % | 21–51 % | 59 % | 9.7 | 64 % | FÖR LÄTT, BRANT NIVÅ |
| Berget | 3 | 5 | 7 / 8 / 9 | 23 / **94** / 100 % | 21–51 % | 35 % | 9.7 | 78 % | FÖR LÄTT, BRANT NIVÅ, PLATT NIVÅ |

PLATT NIVÅ på en rad som står nära 100 % betyder bara att det inte finns mer att vinna uppåt (regeln räknar bort sidan
först vid exakt 100 %).

## Utanför målen, längst bort först (tömda Charges, varje möte)

433 av de tömda stridsraderna ligger utanför specens band, nästan alla FÖR LÄTT (vanliga grupper 100 %, elitgrupper på
våning 2 100 %). De som är FÖR SVÅRA och bossplatserna:

| Möte | Realm, djup, våning | Sort | Nivå | Vinst (mål) | Charges kvar | Flaggor |
|---|---|---|---|---|---|---|
| Tullen vid bron (troll_g1) | Berget d2 v2 | väktare | 7 | 100 % (65–80) | – | FÖR LÄTT, BRANT, FEL VARNING |
| Kistornas råd (crypt_g2) | Kryptan d3 v2 | väktare | 7 | 96 % (65–80) | – | FÖR LÄTT, BRANT, PLATT |
| Vävarnas par (grove_g2) | Lunden d3 v2 | väktare | 7 | 91 % (65–80) | – | FÖR LÄTT, BRANT, PLATT |
| Bergakungens sal (troll_3), fyra | Berget d1 v2 | boss | 6 | 11 % (50–65) | 42 % | FÖR SVÅR, BRANT |
| Midnattsklockan (crypt_g1) | Kryptan d2 v2 | väktare | 6 | 88 % (65–80) | – | FÖR LÄTT, BRANT |
| Vävmoderns krona (grove_3) | Lunden d1 v2 | boss | 5 | 88 % (50–65) | – | FÖR LÄTT, BRANT |
| Biskopens altare (chapel_3) | Kapellet d1 v2 | boss | 5 | 92 % (50–65) | – | FÖR LÄTT, BRANT, PLATT |
| Bergakungens sal, fem | Berget d1 v2 | boss | 6 | 83 % (50–65) | – | FÖR LÄTT, BRANT |
| Grimmens kyrkogård (chapel_e9) | Kapellet d2–3 v2 | Nemesis | 6–7 | 6 % (60–75) | 60–62 % | FÖR SVÅR |
| Grimmens kyrkogård | Kapellet d3 v1 | elit / Nemesis | 7 | 18 % (70–85 / 60–75) | 79–83 % | FÖR SVÅR |
| Inkvisitorns domstol (chapel_g2) | Kapellet d3 v2 | väktare | 7 | 61 % (65–80) | 47 % | FÖR SVÅR, BRANT |
| Benfurstens sal (crypt_3) | Kryptan d1 v2 | boss | 5 | 66 % (50–65) | – | FÖR LÄTT, BRANT |
| Skrivarens avskrifter (crypt_e8) | Kryptan d1 v1–2 | elit / Nemesis | 3–5 | 49–54 % (70–85 / 60–75) | 58–85 % | FÖR SVÅR |
| Grimmens kyrkogård | Kapellet d1 v1 | elit | 3 | 61 % (70–85) | 85 % | FÖR SVÅR |

Nivån på stridsraderna är den sällskapet i snitt har när det når striden (det växer under körningen), därför 5 vid
bossen på djup 1.

FEL VARNING (fyra i Trollberget vinner bossplatsen i mer än 35 %): Bergakungen på djup 1 med fulla Charges 71 % men
tömd 11 % och hela nedstigningen 4 % (varningen stämmer i praktiken); Tullen vid bron på djup 2 100 % och nedstigningen
97 %; Gråluvans ätt på djup 3 67–75 % och nedstigningen 75 % (varningen stämmer inte).

MAKRO: ingen rad. Reservanfallen är 0 % överallt, eftersom startmakrona slutar med "anfall fienden med lägst liv".
Det allmänna anfallet valdes i 51–64 % av hjältarnas turer i nedstigningarna (`standardanfall_pct`).

## Det viktigaste

1. **En nivå är för stor för nivåmålet.** Med den nya kurvan är en nivå 3–4 av de gamla tillväxtnivåerna. En nivå över
   väntad nivå ger 99–100 % i varje Realm från djup 2, och en nivå under kostar 9–94 procentenheter. Specens 10–20
   enheter per nivå går inte att nå med hela nivåer; antingen mäts känsligheten per halv nivå eller i erfarenhet, eller så
   gäller målet bara djup 1, där kurvan är linjär (där ligger kryptan på −18/+18, inom målet).
2. **Djup 2–3 är lättare än djup 1 på väntad nivå** (kryptan 38 → 81 → 93 %, kapellet 67 → 80 → 55 %), eftersom
   utrustningen (artefakt nivå 3–5 och en trofé) kommer till och väntad nivå avrundas. Karriärbotarna såg samma sak
   (kapellet d2 73 %).
3. **Fem i en Realm byggd för fyra är nästan säkert** (95–100 %), eftersom fienderna balanseras mot fyra så snart man äger
   fyra (0.30.21). I Trollberget är fem rätt på djup 1 (69 %) men för lätt på djup 2–3 (94–100 %).
4. **Trollberget med fyra:** djup 1 nästan omöjligt (4 %), djup 2 nästan säkert (97 %). Steget mellan djup 1 och 2 i berget
   är omvänt; det beror på att väntad nivå går från 6 till 7 och att utrustningen följer fiendedjupet.
5. **Svårigheten sitter i bossplatsen.** Vanliga grupper vinns alltid, elitgrupper och Nemesis oftast (74–100 % inne i nedstigningarna),
   och förlusterna kommer vid bossen eller väktaren med under hälften av Charges kvar. Undantagen är Grimmens kyrkogård
   (kapellet) och Skrivarens avskrifter (kryptan), som fäller sällskapet även med 80 % av Charges.
6. **Längd** (information, inga flaggor): i nedstigningarna är medianen 2 rundor för en vanlig grupp, 4–5 för elit och
   Nemesis, 7 för väktare och 11 för boss (14 / 35–37 / 61 / 82 turer).
