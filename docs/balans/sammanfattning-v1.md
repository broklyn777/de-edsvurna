# Balanssimuleringen, balans v1 (0.30.43-test, gren `balans-v2`)

2026-10-26. VD:s beslut 2026-10-25 (mål B per nedstigning; nivåkurva, djupsteg, fem i Realms för fyra, Trollberget,
högst sex mötesvärden). Hela tabellen: `docs/balans/balans-0.30.43-v1.csv` (2 032 rader, samma körning och frön som
v0: alla fyra Realms, djup 1–3, fyra och fem, 100 nedstigningar per nivå, 200/100 strider per möte; två delkörningar
samtidigt, 2 h 9 min på klockan). Varje ändring och proven: `docs/balans/balanslogg.md`, avsnittet "Balans v1".
**Inget är sammanslaget.**

## Nivåkurvan (steg 1)

Styrkan på en nivå (multiplikatorn på basen med vanlig tillväxt), delad av hjältar och fiender. Takten (erfarenhet per
nivå, fiendernas nivå per djup, väntad nivå 3 / 6 / 7 / 8) är orörd.

| Nivå | v0 | Steg v0 | v1 | Steg v1 | Erfarenhet till nästa |
|---|---|---|---|---|---|
| 1 | 1,00 | – | 1,00 | – | 15 |
| 2 | 1,30 | +30 % | 1,20 | +20 % | 30 |
| 3 | 1,60 | +23 % | 1,44 | +20 % | 55 |
| 4 | 1,90 | +19 % | 1,73 | +20 % | 90 |
| 5 | 2,20 | +16 % | 2,07 | +20 % | 163 |
| 6 | 2,90 | +32 % | 2,49 | +20 % | 845 |
| 7 | 4,05 | +40 % | 2,99 | +20 % | 2 613 |
| 8 | 5,47 | +35 % | 3,58 | +20 % | 6 233 |
| 9 | 7,09 | +30 % | 4,30 | +20 % | 12 605 |
| 10 | 8,88 | +25 % | 5,16 | +20 % | 22 684 |
| 11 | 10,82 | +22 % | 6,16 | +19,3 % | 37 478 |
| 12 | 12,90 | +19 % | 7,31 | +18,7 % | 58 041 |
| 13 | 15,10 | +17 % | 8,64 | +18,2 % | 85 465 |
| 15 | 19,83 | +14 % | 11,92 | +17,2 % | 165 422 |
| 20 | 33,31 | +9 % | 25,23 | +15,6 % | 567 464 |

v1: 1,2^(L − 1) till nivå 10, sedan steg på 13 % + 7 % · e^(−(L − 10)/10). Fiendernas multiplikator på djup 1–3
(våning 1 / 2 / 3): v0 1,38 / 1,82 / 2,27, 2,88 / 3,32 / 3,77, 4,38 / 4,83 / 5,27; v1 (före djupsteget) 1,26 / 1,65 /
2,15, 2,48 / 2,68 / 2,87, 3,12 / 3,31 / 3,50.

**En sparad hjälte på nivå 8** behåller nivån. Paladinens Health 492 → 322 (−35 %). Mot fienderna på djup 3, våning 2:
1,07 → 0,83 i stats, och på djup 4 (där nivå 8 är väntad) 0,79 → 0,63. Nästan allt kommer av djupsteget (kurvan ensam:
1,13 → 1,08 mot djup 3 våning 2). Resten från 0.19-omräkningen (`carry`) blir en del av en nivå på takten.

## Det som ändrades

| | v0 | v1 |
|---|---|---|
| Styrka per nivå | 1 + 0,3 · (g(L) − 1), +30–40 % för nivå 6–9 | `HeroStats.strength`, +20 % nivå 2–10 |
| Djupsteg (`CombatSim.DEPTH_STEP`) | +3 % per djup | **+15 %** per djup |
| Fem i kryptan, kapellet, lunden | som mot fyra (fem vann 95–100 %) | som mot fem på djupet Realmen inte är klarad på: fienderna ×**1,4** (Health, Attack, Intelligence; `FIVE_IN_FOUR`); som mot fyra på klarade djup |
| Trollberget | bara `depth_offset` 1 | dessutom `"depth_step": 0.05` per fiendedjup över 1 (realms.json) |
| Benfurstens sal (crypt_3) | 1,02 | **1,14** |
| Biskopens altare (chapel_3) | 1,06 | **1,33** |
| Midnattsklockan (crypt_g1) | 1,025 | **1,24** |
| Abbedissans kör (chapel_g1) | 0,96 | **1,32** |
| Tullen vid bron (troll_g1) | 1,17 | **1,45** |
| Bergakungens sal (troll_3) | 1,05 | **1,12** |

v0-kolumnen nedan är `balans-0.30.42-v0.csv`, alltså före varv 1–3 i balansloggen och före djup 1 med karriärbotarnas
utrustning (de var redan incheckade i test-0.30 och ingår i v1).

## Hela nedstigningar (huvudmålen, mål B)

Väntad nivå i fetstil. Mål B: huvudbossen (djup 1) 26–48 %, väktaren (djup 2–3) 33–59 %; Trollberget med fyra högst 35 %.

| Realm | Djup | Lag | Nivå −1 / väntad / +1 | v0 | v1 | Mål | I mål? | Boss/väktare i nedstigningen | Minst en stupar | Charges kvar |
|---|---|---|---|---|---|---|---|---|---|---|
| Kryptan | 1 | 4 | 2 / 3 / 4 | 20 / **38** / 56 | 24 / **42** / 59 | 26–48 | ja | 46 % | 82 % | 71 % |
| Kryptan | 2 | 4 | 5 / 6 / 7 | 72 / **81** / 100 | 45 / **53** / 96 | 33–59 | ja | 55 % | 86 % | 71 % |
| Kryptan | 2 | 5 | 5 / 6 / 7 | 96 / **97** / 100 | 43 / **51** / 74 | 33–59 | ja | 57 % | 93 % | 81 % |
| Kryptan | 3 | 4 | 6 / 7 / 8 | 37 / **93** / 100 | 46 / **72** / 97 | 33–59 | **för lätt** | 86 % | 98 % | 68 % |
| Kryptan | 3 | 5 | 6 / 7 / 8 | 85 / **98** / 100 | 51 / **65** / 96 | 33–59 | **för lätt** | 97 % | 94 % | 80 % |
| Kapellet | 1 | 4 | 2 / 3 / 4 | 31 / **67** / 84 | 21 / **36** / 46 | 26–48 | ja | 38 % | 89 % | 72 % |
| Kapellet | 2 | 4 | 5 / 6 / 7 | 64 / **80** / 100 | 49 / **55** / 95 | 33–59 | ja | 59 % | 82 % | 72 % |
| Kapellet | 2 | 5 | 5 / 6 / 7 | 93 / **99** / 100 | 41 / **48** / 94 | 33–59 | ja | 63 % | 97 % | 81 % |
| Kapellet | 3 | 4 | 6 / 7 / 8 | 26 / **55** / 100 | 17 / **30** / 96 | 33–59 | **för svår** | 38 % | 100 % | 69 % |
| Kapellet | 3 | 5 | 6 / 7 / 8 | 61 / **95** / 100 | 15 / **22** / 86 | 33–59 | **för svår** | 42 % | 99 % | 81 % |
| Lunden | 1 | 4 | 2 / 3 / 4 | 22 / **42** / 64 | 52 / **78** / 97 | 26–48 | **för lätt** | 78 % | 57 % | 72 % |
| Lunden | 2 | 4 | 5 / 6 / 7 | 50 / **65** / 100 | 56 / **63** / 99 | 33–59 | **för lätt** | 63 % | 70 % | 73 % |
| Lunden | 2 | 5 | 5 / 6 / 7 | 99 / **99** / 100 | 31 / **46** / 99 | 33–59 | ja | 46 % | 84 % | 82 % |
| Lunden | 3 | 4 | 6 / 7 / 8 | 82 / **83** / 100 | 69 / **71** / 100 | 33–59 | **för lätt** | 71 % | 50 % | 71 % |
| Lunden | 3 | 5 | 6 / 7 / 8 | 98 / **99** / 100 | 81 / **84** / 85 | 33–59 | **för lätt** | 85 % | 33 % | 80 % |
| Berget | 1 | 4 | 5 / 6 / 7 | 0 / **4** / 100 | 1 / **1** / 70 | ≤ 35 | ja | 1 % | 100 % | 63 % |
| Berget | 1 | 5 | 5 / 6 / 7 | 50 / **69** / 100 | 28 / **42** / 98 | 26–48 | ja | 42 % | 98 % | 77 % |
| Berget | 2 | 4 | 6 / 7 / 8 | 3 / **97** / 100 | 0 / **0** / 83 | ≤ 35 | ja | 0 % | 100 % | 60 % |
| Berget | 2 | 5 | 6 / 7 / 8 | 58 / **100** / 100 | 11 / **53** / 100 | 33–59 | ja | 53 % | 97 % | 74 % |
| Berget | 3 | 4 | 7 / 8 / 9 | 2 / **75** / 99 | 0 / **2** / 39 | ≤ 35 | ja | 4 % | 100 % | 60 % |
| Berget | 3 | 5 | 7 / 8 / 9 | 23 / **94** / 100 | 0 / **43** / 84 | 33–59 | ja | 44 % | 93 % | 72 % |

**I mål B: 13 av 21 rader** (v0: 4, kryptan d1, kapellet d3 med fyra, lunden d1 och Trollberget d1 med fyra, som bara
låg under 35 % genom att vara nästan omöjligt, 4 %). Trollberget ligger rätt på alla tre djup, med fyra under 5 % och fem 42–53 %.
CSV:ns flaggkolumn räknar fortfarande mot specens band A (därför står FÖR LÄTT på t.ex. kryptan d2 53 %).

## Det som inte kom i mål

| Rad | v1 | Orsak | Förslag (inte gjort, budgeten var sex värden) |
|---|---|---|---|
| Lunden d1 (Vävmoderns krona, grove_3) | 78 % | bossen orörd (1,22) | stat_mult ~1,35 |
| Lunden d2–3 med fyra (grove_g1, grove_g2) | 63 / 71 % | väktarna orörda | g2 ~1,65; g1 en aning |
| Kryptan d3 (Kistornas råd, crypt_g2) | 72 / 65 % | djupsteget räcker inte för just den väktaren | stat_mult ~1,22 (1,155 nu) |
| Kapellet d3 (Inkvisitorns domstol, chapel_g2) | 30 / 22 % | djup 3 är mycket brantare i kapellet; elitgrupperna Kultens förmans vakt och Grimmens kyrkogård blir också för svåra tömda (48 / 32 %) | chapel_g2 ~1,45 (1,55 nu) |
| Lunden d3 med fem | 84 % | grove_g2 orörd | som ovan |

Djupsteget är en kompromiss: djup 3 svarar mycket brantare än djup 2 (0,15 → 0,20 tar kryptan d3 från 72 till 13 %),
och kapellet d3 och kryptan d3 drar åt var sitt håll. Ett steg på 0,16 skulle byta två rader för lätta mot en för svår.

## Varje möte, tömda Charges (diagnostik)

428 av 1 329 stridsrader utanför specens band (v0 431): 406 för lätta (vanliga grupper 100 %, elit på våning 1–2), 22
för svåra (v0 10). Boss och väktare som är justerade mot mål B hamnar under sina band per strid, eftersom elit och Nemesis
i nedstigningarna vinns i 90–100 % och bossplatsen därför bär hela svårigheten:

| Möte | Realm, djup | Nivå −1 / väntad / +1 (tömd) | Mål |
|---|---|---|---|
| Benfurstens sal (crypt_3) | Kryptan 1 | 2 / **60** / 100 | 50–65 |
| Biskopens altare (chapel_3) | Kapellet 1 | 1 / **44** / 100 | 50–65 |
| Midnattsklockan (crypt_g1) | Kryptan 2 | 0 / **49** / 100 | 65–80 |
| Abbedissans kör (chapel_g1) | Kapellet 2 | 0 / **43** / 96 | 65–80 |
| Kistornas råd (crypt_g2) | Kryptan 3 | 0 / **82** / 92 | 65–80 |
| Inkvisitorns domstol (chapel_g2) | Kapellet 3 | 0 / **21** / 94 | 65–80 |
| Vävmoderns krona (grove_3) | Lunden 1 | 8 / **98** / 100 | 50–65 |
| Bergakungens sal (troll_3), fem | Berget 1 | 0 / **50** / 99 | 50–65 |
| Tullen vid bron (troll_g1), fem | Berget 2 | 0 / **46** / 100 | 65–80 |
| Gråluvans ätt (troll_g2), fem | Berget 3 | 2 / **48** / 85 | 65–80 |

Nya för svåra elit- och Nemesisrader: kapellet d3 Kultens förman (chapel_e1) 48 % / Nemesis v2 18 %, Grimmens kyrkogård
(chapel_e9) 26–32 %, kryptan d3 crypt_e6 56 %, Trollberget d3 troll_e2 med fyra 13 % (berget ska vara svårt med fyra).

## Det viktigaste

1. **Nivån väger lika tungt som förut i nedstigningarna.** Med +20 % per nivå i stället för +35 % ger en nivå över väntad
   fortfarande 94–100 % från djup 2 (kryptan d2 53 → 96 %). En nivå under kostar mindre än förut (kryptan d3 −26 i stället
   för −56). Fienderna på våning 2–3 ligger mellan väntad nivå och nästa, och sällskapet växer knappt under en nedstigning
   från djup 2 (845 erfarenhet till nivå 7), så en hel nivå är fortfarande ett stort hopp. Mät känsligheten per halv nivå
   eller i erfarenhet om målet ska gälla.
2. **Djup 2 och 3 är inte längre lättare än djup 1** i kryptan och kapellet (kryptan 42 → 53 → 72 %, kapellet 36 → 55 →
   30 %). Lunden är orörd och ligger kvar för lätt.
3. **Fem är en bedrift bara där man inte varit.** På det djupaste djupet vinner fem 46–65 % i kryptan och lunden d2,
   48 % i kapellet d2, 22 % i kapellet d3; tillbaka på ett klarat djup möter fem fiender som mot fyra (95–100 % som i v0).
4. **Trollberget med fyra är stängt på alla djup** (0–2 %), fem ligger i bandet (42 / 53 / 43 %). Berget är mycket brant:
   ±10 % i fiendernas stats flyttar fem 40–50 enheter.
5. **Djupsteget +15 % är fem gånger dagens** och läggs på fiendernas nivå. Djup 4 och djupare är inte mätta här; v0:s
   +8 % gav väggen vid djup 5–6 med den gamla kurvan, då en nivå var +30–40 %. Karriärbotarna (`SOAK=karriar`) bör köras på
   grenen innan den slås ihop.
6. **Längd** (information): median 77 turer för boss och 79 för väktare i nedstigningarna (v0 82 / 62); väktarna blev
   längre när de blev starkare.
