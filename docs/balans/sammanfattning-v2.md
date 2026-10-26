# Balans v2 (0.30.43-test, gren `balans-v2`)

2026-10-26. Rättelse av v1 (`sammanfattning-v1.md`) efter karriärbotarna, som är grinden för en sammanslagning. Proven
och siffrorna i detalj: `docs/balans/balanslogg.md`, avsnittet "Balans v2". **Inget är sammanslaget.**

## Vad som gäller i v2

| | v0 (test-0.30) | v1 | v2 |
|---|---|---|---|
| Styrka per nivå | +30–40 % (nivå 6–9) | +20 % nivå 2–10, sedan mot 13 % | samma som v1 |
| Djupsteg | 3 % | 15 % | **3 %** |
| Fem i Realms för fyra | som mot fyra | ×1,4 på det djupaste djupet | samma som v1 |
| Trollbergets eget steg | – | 5 % per fiendedjup | **17 %** (lika brant som v1) |
| crypt_3 / chapel_3 | 1,02 / 1,06 | 1,14 / 1,33 | 1,14 / 1,33 |
| crypt_g1 / chapel_g1 | 1,025 / 0,96 | 1,24 / 1,32 | **1,10 / 1,20** |
| chapel_g2 | 1,55 | 1,55 | **1,45** |
| troll_g1 / troll_3 | 1,17 / 1,05 | 1,45 / 1,12 | 1,45 / 1,12 |

Varför 3 %: fienderna och hjältarna delar nu styrkekurvan, och på karriärens nivåer ger 3 % samma kvot fiende/hjälte på
djup 4–9 som förr. 5 % lade på 6–13 %, 8 % 14–32 % och 15 % 34–60 %, och varje sådant steg gav en vägg vid djup 4–6.

## Karriärbotarna (grinden, 40 profiler × 18 nedstigningar)

Vinst per djup (antal körningar inom parentes):

| | Djup 1 | Djup 2 | Djup 3 | Djup 4 | Djup 5 | Djup 6 | Djup 7 |
|---|---|---|---|---|---|---|---|
| Kryptan v0 | 94 (53) | 70 (37) | 57 (23) | 59 (37) | 38 (26) | 53 (15) | 50 (6) |
| Kryptan v1 | 76 (72) | 74 (35) | 31 (68) | 0 (24) | 0 (1) | – | – |
| Kryptan v2 | 76 (54) | 79 (19) | 81 (47) | 36 (33) | 35 (26) | 48 (17) | 0 (3) |
| Kapellet v0 | 67 (3) | 71 (65) | 68 (47) | 52 (29) | 54 (26) | 56 (16) | 63 (8) |
| Kapellet v1 | 71 (21) | 36 (101) | 61 (56) | 14 (22) | – | – | – |
| Kapellet v2 | 60 (15) | 60 (48) | 73 (37) | 46 (57) | 60 (20) | 36 (14) | 0 (8) |
| Lunden v0 | 75 (4) | 37 (19) | 40 (60) | 62 (39) | 33 (21) | 45 (11) | 50 (4) |
| Lunden v1 | 100 (6) | 58 (78) | 46 (52) | 4 (24) | – | – | – |
| Lunden v2 | 85 (7) | 54 (28) | 63 (38) | 42 (53) | 61 (23) | 43 (7) | 25 (4) |
| Trollberget v0 / v1 / v2 | 0 / 4 / 0 | 22 / 0 / 8 | 3 / 0 / 0 | 2 / 0 / 0 | 17 / – / 0 | | |

Efter 18 nedstigningar: v0 djup 5,7 i snitt, djupast 9, Paladinen nivå 10,3; v1 3,1, djupast 4, nivå 9,0; v2 5,2,
djupast 9 (åtta av 40 profiler på djup 7 eller djupare), nivå 10,0. Djup 4–6 ligger på 35–61 %, något under förr på djup 4
(36–46 mot 52–62 %: huvudbossarna är starkare sedan v1). Djup 7+ har för få körningar för att säga något. Trollberget
vinns inte med fyra (karriären går dit var fjärde gång med fyra; berget kräver fem).

## Balanssimuleringen (väntad nivå, 100 nedstigningar, fyra / fem; mål B 26–48 / 33–59 %)

| | Djup 1 | Djup 2 | Djup 3 |
|---|---|---|---|
| Kryptan | **42** | 97 / 73 | 97 / 92 |
| Kapellet | **36** | 93 / 83 | 96 / 79 |
| Lunden | 78 | 89 / 87 | 99 / 86 |
| Trollberget | **1 / 39** | **0 / 56** | **6 / 48** |

Djup 1 och Trollberget ligger i mål; djup 2–3 ligger över (v1 hade dem i mål med 15 %). Det går inte att få både
simuleringens djup 2–3 och karriärens djup 5–6 i mål med samma mötesvärden: väktaren på djup 2 är densamma på djup 5,
och sällskapet möter den på väntad nivå 6 i simuleringen men på nivå 9,4 med starkare grupper (motdrag, djuppooler) i
karriären. Beslut för VD: antingen godta karriären som sanningen för djup 2–3 (den vinner där 54–81 %, förr 37–71 %), eller
låta mötena bli starkare första gången de kommer och mildare när de återkommer (en ny regel, inte byggd).

## En sparad hjälte på nivå 8

Kvoten hjälte/fiende i stats (neutral tillväxt, utan utrustning) per våning, förr / v1 / v2, och v2 med en nivå till:

| Djup | Våning 1 | Våning 2 | Våning 3 |
|---|---|---|---|
| 3 | 1,18 / 0,88 / 1,08 (+1: 1,30) | 1,07 / 0,83 / 1,02 (+1: 1,23) | 0,98 / 0,79 / 0,97 (+1: 1,16) |
| 4 (väntad nivå 8) | 0,85 / 0,66 / 0,87 (+1: 1,05) | 0,79 / 0,62 / 0,83 (+1: 1,00) | 0,74 / 0,59 / 0,79 (+1: 0,95) |
| 5 | 0,66 / 0,51 / 0,72 (+1: 0,87) | 0,62 / 0,48 / 0,69 (+1: 0,83) | 0,59 / 0,46 / 0,66 (+1: 0,79) |

Med v2 är en nivå 8-hjälte lika stark mot sitt djup som förr: 9 % svagare på djup 3, lika på djup 4, 9–12 % starkare på
djup 5. En gratis nivå skulle göra hen ungefär 20 % starkare än förr (som en nivå är nu). Paladinens Health sjunker
ändå från 492 till 322, eftersom alla tal är mindre.

## Felet i karriären (frö 26)

Det var ingen motorbugg, mekaniken gjorde rätt. Paladinen blev snärjd (sjönk längst ned), slet sig loss och knuffades ned
när Lirien flyttade sig själv överst. Under väntan dog fyra figurer, så kontrollens gräns (4 × levande) föll under väntan.
Kontrollen i `tests/soak.gd` räknar nu på hur många som levde när hjälten senast stod på tur.
