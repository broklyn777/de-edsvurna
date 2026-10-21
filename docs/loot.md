# Loot i De edsvurna (läget 2026-10-21)

Allt man kan hitta eller tjäna, vad det är till och vad det uppgraderar. Siffrorna gäller djup 1 om inget annat står.
Källor: `src/game/forge.gd`, `data/materials.json`, `data/artifacts.json`, `src/game/run_state.gd`, `src/game/profile.gd`,
`src/game/hero_stats.gd`, `data/objects.json`. Jämförelse med Siralim: `docs/research/siralim.md` §14–15.

## 1. Silver – enda valutan (vårt val; Siralim har fem resurser)

**Varifrån**
- Vunnen strid: 40 % av våningens belöning (15 / 20 / 30 på våning 1 / 2 / 3); bossen ger hela.
- Skatt: 60 % av våningens belöning.
- Quest: halv (15) för våning 1, full (30) för sista våningen.
- +25 % per djup; våningsregler (instabilitet) ger mer. Lös kyrkbänk: "ta virket". Ny profil: 60.

**Till**
| Vad | Pris |
|---|---|
| Smida artefakt / byta typ | 160 |
| Byta förmåga i artefakten | 60 |
| Artefaktnivå 2 → 10 | 60, 80, 110, 140, 180, 230, 290, 370, 470 |
| Byta personlighet (Biblioteket) | 80 |

## 2. Troféer – egenskaper (Siralims varelser och Trait Materials)

En per hjälte; behålls mellan körningar, byts bara vid lägereld.

| Sort | Antal | Hur |
|---|---|---|
| Vanlig | 9 | Efter vunnen våning: första säker, resten 40 % (+15 pp/djup, +10 pp/instabilitet). Skatt 20 %. |
| Elit | 26 | Alltid när eliten eller den glödande varianten är besegrad. |
| Boss | 3 | Efter tre segrar mot samma boss. Ändrar en regel, med kostnad. |

## 3. Bärnsten – stats i artefakten (Amber)

5 per Stat-plats, +6 % per sten på nivå 1; förstörs när den tas ut.
- En stat: röd Attack, blå Intelligence, grön Health, järngrå Defense, gul Speed.
- Två stats (60 % var): orange Attack/Health, violett Intelligence/Speed, turkos Health/Defense, rosa Intelligence/Health, brons Attack/Defense.

| Rum | Chans | Antal |
|---|---|---|
| Vanlig strid | 35 % | 1 |
| Elit | alltid | 2–3 |
| Skatt | alltid | 2–4 |
| Boss | alltid | 3–4 |

+1 sten på lägre djup än det djupaste man nått.

## 4. Trick – effekter i artefakten (Trick Materials)

Förstörs när de tas ut. Bara på det djupaste djupet: elit 40 %, skatt 50 %, boss alltid (instabilitet höjer).

| Trick | Effekt (nivå 1) | Gäller |
|---|---|---|
| Brynsten | +12 % skada | anfall |
| Taggsten | +8 % krit | anfall |
| Arkant sigill | +12 % skada | besvärjelser (inte helning) |
| Rustningsskrot | −8 % skada tagen | alla |
| Hal sten | +7 % undvikande | mot anfall |
| Styrkans skiffer | 15 % chans till Styrka | vid direkt träff |
| Sårbarhetens kuriosa | 12 % chans att göra målet Sårbart | vid direkt träff |

## 5. Nether Stones

1–4 egenskaper (stat, trick eller troféegenskap) efter sällsynthet: Vanlig, Magisk, Sällsynt, Legendarisk. Nether-platsen
på nivå 10; stenen överlever när den tas ut. Bara på det djupaste djupet: elit 8 %, skatt 12 %, boss 50 %. Djup och
instabilitet ger sällsyntare stenar. Sällsynta fynd får en egen scen.

## 6. Artefakten (Smeden)

En per hjälte, nivå 1–10; varje nivå +10 % på typens stat, chansen och materialen.
Platser: Stat 2, Trick 3, Stat 5, Trick 7, Stat 9, Nether 10.

| Typ | Stat | Förmågan slår till vid |
|---|---|---|
| Svärd | Attack | Anfall, 25 % |
| Stav | Intelligence | Förmåga, 25 % |
| Sköld | Defense | Försvara, 50 % |
| Hjälm | Health | Provocera, 50 % |
| Stövlar | Speed | turens början, 15 % |

## 7. Belöningar som inte är saker

- Erfarenhet: 17 × rumstyp × djup² (strid 1, elit 1,5, sista strid 2, boss 3); varje nivå +30 % av basvärdet.
- Perk-poäng: sista våningens quest på ny kombination av Realm och djup.
- Lärjungar ur fånge-rum.
- Bara under körningen: lägereld +3 Charges per förmåga; helgedom (+2 Charges på en förmåga, Styrka eller Skyddad,
  eller Pandemonium); föremål (sarkofag och Gravklocka: dubbel/större skatt; register, klockrep, fönster, timglas: information).

## 8. Vem har nytta av vad

- **Bara besvärjare och helare:** blå bärnsten (Intelligence styr både besvärjelser och helning), Arkant sigill
  (besvärjelser, inte helning), Stav (Intelligence). Violett och rosa till hälften.
- **Bara anfallare:** röd bärnsten, Brynsten, Taggsten, Svärd. Orange och brons till hälften.
- **Alla:** grön, järngrå, gul, turkos bärnsten; Rustningsskrot, Hal sten, skiffern, kuriosan; Sköld, Hjälm, Stövlar.
- **Lucka:** inget material höjer helning direkt (bara via Intelligence).
