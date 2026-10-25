# Balanssimuleringen (0.30.42-test, gren `balanssim`)

2026-10-25. VD:s spec (skriven med ChatGPT, "De edsvurna – spec för balanssimulering") med projektledarens tre
rättelser, som VD godkände. **Det här jobbet ändrar inga balansvärden.** Det bygger verktyget, tar fram den första
tabellen och stannar för VD:s godkännande av målen.

## Rättelserna (de går före specen)

- **A. Nötning, inte enstaka strider.** Svårigheten ligger i nötningen över en nedstigning: livet fylls på efter varje
  strid, men Charges räcker hela körningen. En enstaka strid med fulla Charges är nästan alltid vunnen med flit.
  Huvudmålen gäller därför **hela nedstigningar på väntad nivå** (grottan som i `BALANS=grotta`, Charges som tar slut).
  Varje möte för sig finns kvar som diagnostik, och mäts också **tömd**: med de Charges sällskapet i snitt har kvar när
  nedstigningarna når den sortens strid på den våningen. Målen per nedstigning härleds ur specens mål per strid (nedan);
  VD sätter de slutliga siffrorna.
- **B. Inga mål för turer.** En tur i motorn är en figurs handling, inte en runda (bossens 25–35 turer vore 3–4 rundor),
  och VD tycker att bossstriderna är lagom långa. Turer (median, 90:e percentilen) och **rundor** (turer delat med antalet
  figurer i striden) redovisas som information, utan flaggor.
- **C. Ingen ny motor.** Allt bygger på `tests/balance_report.gd` och botarna i `tests/combat_bot.gd`
  (`run_fight`, `run_expedition`). `tests/balance_sim.gd` är en tunn ingång med flaggor; samma sak går att köra med
  `BALANS=sim` i balansrapporten.

## Verktyget

```bash
# Hela tabellen (alla Realms, djup 1–3) – CSV och sammanfattning
godot --headless --path . --script res://tests/balance_sim.gd -- --out=docs/balans/balans-0.30.42-v0.csv --summary=/tmp/sammanfattning.txt
# Ett urval under utvecklingen
godot --headless --path . --script res://tests/balance_sim.gd -- --realm=crypt --depth=1 --enc=crypt_e8 --n=50 --runs=30
# Delkörningar (två åt gången, iMacen blir varm) slås ihop utan att simulera
godot --headless --path . --script res://tests/balance_sim.gd -- --merge=a.csv,b.csv --out=alla.csv --summary=s.txt
```

Flaggor: `--realm`, `--depth`, `--enc`, `--party`, `--fifth`, `--n` (strider per möte, 200), `--n-side` (±1 nivå, 100),
`--runs` (nedstigningar, 100), `--side-full`, `--fifth-fights`, `--no-descents`, `--out`, `--summary`, `--merge`.

### Vad som mäts

För varje Realm (alla i `realms.json`) och djup 1–3:

1. **Hela nedstigningar** (`matning=nedstigning`): `Bot.run_expedition`, policyn "simple" (slåss mot allt den kliver på,
   elitgrupper när questen kräver det, lägereld när Charges går under 40 %), med erfarenhet under körningen. Tre
   startnivåer: väntad, −1, +1. Rad: andel klarade, turer och rundor för hela nedstigningen, andel nedstigningar där minst
   en hjälte stupade, andel som slutade med en förlorad strid (wipe), strider per nedstigning, Charges kvar i snitt.
2. **Strider inne i nedstigningarna** (`matning=i_nedstigning`): samma körningar, uppdelade per sort (vanlig, elit,
   Nemesis, väktare, boss). Det är de verkliga betingade vinstandelarna under nötning.
3. **Varje möte för sig** (`strid_full`, `strid_tomd`): alla möten ur datan (`RunState.pools_for`, `elite_pools_for`,
   `nemesis_pool`, väktaren eller huvudbossen på djupet; inget hårdkodat), med stridens inställningar som
   `RunState.battle_opts()` (tier, motdrag för elit/Nemesis/boss, påtvingad elitvariant, `full_party`, `depth_offset`).
   Nivån är den sällskapet i snitt har när nedstigningarna (från väntad nivå) når sorten på våningen, och −1/+1 runt den.
   Tömda Charges är snittet per hjälte och förmåga i samma läge. Fulla Charges bara på den nivån (och för boss/väktare
   också ±1); Nemesis med fulla Charges räknas inte om när elitgruppen med samma tier redan är mätt (Nemesis-flaggan
   ändrar ingenting i striden).

Fröna är 1..N (striderna) och 1..runs (nedstigningarna), så två körningar ger samma tabell.

### Antaganden

- **Laget:** Paladinen, Brokk, Syster Alva och Jägaren Eira. **Fem** med Imma där platsen finns: den femte platsen öppnas
  när kapellet är klarat på djup 1, alltså från djup 2 överallt och alltid i Trollberget (som kräver kapellet). Med fem
  äger profilen fem (fienderna som mot fyra i Realms byggda för fyra, som mot fem i Trollberget). Varje möte för sig med
  fem bara i Trollberget (`--fifth-fights` för alla); nedstigningarna med fem överallt där platsen finns.
- **Makron:** en ny profils makron (`Run.starter_lines` via `Bot.new_profile_macros`: Paladinen har introts enda rad
  "anfall fienden med lägst liv", följeslagarna sina två första enheter och sist samma anfallsrad) plus makroförslaget för
  varje hjälte (`heroes.json` "macro_hint", som spelaren lägger till när hjälten ansluter, som karriärboten gör).
- **Utrustning per fiendedjup** (djup + Realmens `depth_offset`), ur karriärbotarna (`SOAK=karriar`, 40 profiler × 18
  nedstigningar, kolumnerna artefakt och trofé som lades till för det här):

  | Fiendedjup | Karriären: artefaktnivå i snitt / andel med trofé | Simuleringen |
  |---|---|---|
  | 1 | 1,7 / 22 % | Paladinens svärd nivå 3 (introt), inga andra artefakter, inga troféer |
  | 2 | 2,4–4,5 / 80–86 % | svärd nivå 3 åt alla (hjältens första förmåga), en vanlig trofé var |
  | 3 | 4,2–5,4 / 79–87 % | svärd nivå 5, en vanlig trofé var |
  | 4 | 5,8–6,7 / 83–90 % | svärd nivå 6, en vanlig trofé var |

  Troféerna är `TROPHY_PAIRS[h][0]` i balansrapporten (Gravprästens radband, Den tystade skramlan, Det brustna bönebandet, Den kapade bågsträngen, Den möglade
  klingan; alla vanliga troféer ur kryptan och kapellet). Inga
  material, inget kall utöver Domens kall, inga perks, ingen instabilitet, inga löften.
- **Reservanfall:** en hjältetur där `MacroRunner.decide` inte gav någon handling (boten försvarar sig då, eller anfaller
  om Försvara inte går). Med startmakrona står "anfall fienden med lägst liv" sist, så reservanfallen blir i praktiken 0.
  Därför finns också `standardanfall_pct`: andelen turer där raden som valdes var det allmänna anfallet (ingen smartare
  rad passade). Det säger hur mycket makrona faktiskt gör.

## Väntad nivå per Realm och djup

`HeroStats.expected_level` på fiendernas djup (djup + `depth_offset`; Trollberget räknar ett djup djupare), med den nya
nivåkurvan (VD 2026-10-25). Karriärbotarna visar vilken nivå sällskapet faktiskt har när det går in (40 profiler × 18
nedstigningar, 0.30.42; nivå = sällskapets snitt när nedstigningen börjar, körningar i parentes).

| Realm | Djup 1 | Djup 2 | Djup 3 |
|---|---|---|---|
| Kryptan: väntad / karriären | 3 / 2,4 (54) | 6 / 7,3 (39) | 7 / 8,0 (20) |
| Kapellet | 3 / 5,7 (3) | 6 / 5,9 (70) | 7 / 8,0 (42) |
| Sidenlunden | 3 / 7,6 (3) | 6 / 5,9 (20) | 7 / 7,4 (66) |
| Trollberget (+1 djup) | 6 / 6,6 (12) | 7 / 7,6 (8) | 8 / 7,3 (44) |

Fiendernas nivå per våning (tier 0 / 1 / 2): djup 1 2,3 / 3,8 / 5,2; djup 2 6,0 / 6,4 / 6,8; djup 3 7,2 / 7,6 / 7,9;
djup 4 8,3 / 8,5 / 8,8. Kryptans djup 1 i karriären är låg eftersom den första nedstigningen (nivå 1, ensam) räknas in.
Formeln och karriären stämmer inom ungefär en nivå utom där karriären har få körningar; formeln används.

## Mål

### Per strid (specen, oförändrade, diagnostik)

| Sort | Vinst | Minst en stupar |
|---|---|---|
| Vanlig | 93–98 % | under 10 % |
| Elit | 70–85 % | 20–40 % |
| Nemesis | 60–75 % | 30–50 % |
| Väktare | 65–80 % | 25–45 % |
| Boss | 50–65 % | 40–60 % |

De jämförs med den **tömda** stridsraden på nivån där striden brukar mötas. Raderna med fulla Charges flaggas bara för
MAKRO, nivåkänslighet och fel varning.

### Per nedstigning (förslag, härlett)

En nedstigning är en kedja strider där varje förlust avslutar körningen. Om specens mål per strid gäller striderna i
nedstigningen blir chansen att klara den produkten:

    P(klarad) = Π p_sort ^ n_sort

där n_sort är antalet strider av den sorten i en nedstigning som når bossplatsen (mätt per Realm, djup och lag). Samma
sak för att någon stupar: 1 − Π (1 − d_sort) ^ n_sort. Verktyget räknar bandet för varje rad (kolumnen `mal_vinst` på
nedstigningsraderna) ur den uppmätta mixen på väntad nivå.

Den uppmätta mixen är nästan densamma överallt (väntad nivå, fyra hjältar): **7,3 vanliga, 0,8 elit, 0,6 Nemesis och
1 boss eller väktare**, 9,7 strider. Med huvudbossen (djup 1, 4 …):

    lägst: 0,93^7,3 · 0,70^0,8 · 0,60^0,6 · 0,50 = 0,589 · 0,746 · 0,740 · 0,50 = 16 %
    högst: 0,98^7,3 · 0,85^0,8 · 0,75^0,6 · 0,65 = 0,863 · 0,875 · 0,844 · 0,65 = 41 %

Med en väktare (65–80 %) i stället: 21–51 %. Minst en stupar: 1 − 1 · 0,8^0,8 · 0,7^0,6 · 0,6 = 60 % till
1 − 0,9^7,3 · 0,6^0,8 · 0,5^0,6 · 0,4 = 92 % (väktare 49–89 %). Wipe = 100 − klarad (en förlorad strid avslutar körningen).

| Förslag | Klarad, huvudbossen | Klarad, väktare | Minst en stupar |
|---|---|---|---|
| A: specen rakt kedjad | 16–42 % | 21–51 % | 60–92 % (väktare 49–89 %) |
| B: vanliga grupper 99–100 % | 26–48 % | 33–59 % | samma |

**A** följer specen bokstavligt. **B** tar hänsyn till att vanliga grupper aldrig förloras under nötningen i spelet
(100 % i varje Realm och djup), så att A:s 93–98 % drar ned bandet med en tredjedel utan motsvarighet. Verktyget flaggar
mot A (`SIM_WIN` i balance_report.gd); byts till B genom att ändra raden för "vanlig". VD väljer, eller sätter egna tal.

### Tilläggsmålen

- **Nivåkänslighet** (specen): en nivå under ska kosta 10–20 procentenheter, en över ge 10–20. Prövas på boss och
  väktare (båda Charges-lägena) och på hela nedstigningar. En sida som redan står vid 0 eller 100 % räknas inte.
  PLATT NIVÅ under bandet, BRANT NIVÅ över. Obs: med den nya kurvan är en nivå stor (+30–40 % stats på djup 2–3), så
  BRANT är väntat på djup 2–3.
- **Lagstorlek** (specen): i Trollberget (byggt för fem) ska fyra på väntad nivå vinna bossplatsen i högst 35 %.
  Annars FEL VARNING.
- **MAKRO:** reservanfall över 15 % av hjältarnas turer.

## Övrigt i jobbet

- **Textspelets makrokommando** (`tests/text_play.gd`, `validate_line`): en rad som skrivs för hand prövas mot datan
  (subjekt, villkor, handling och mål ur MacroRunners listor; statusar ur auras.json, egenskaper ur traits.json,
  förmågor ur abilities.json och hjältens egna, artefakttyper) och läggs inte till om något id är okänt (`bleed`,
  `protective_prayer`). Spelets radeditor väljer ur listor och behöver det inte.
- **Allsång** (`traits.json` lirien_chorus): texten säger nu att buffar från en egenskap (trofé, kall, artefaktens egna
  kast) inte sprids, som `not_from_trait` gör.
- Spelets regler är orörda. Botarna fick räknare (`decisions`, `generic`, `deaths`, `units`) och en stridslogg
  (`fight_log`) i `run_expedition`; karriärrapporten skriver artefaktnivå och troféer per djup.
- Tester: `tests/test_balance_sim.gd` (flaggor, reservanfall, kedjade mål, möten ur datan, CSV, textspelets kontroll).

## Balansloopen (efter VD:s godkännande)

Som i specen: ett värde i taget, bara datafiler, `--enc=` för att köra om ett möte, hela tabellen när det är inom målet,
en rad i `docs/balans/balanslogg.md`, högst 10 varv. Ändringar som rör många möten (nivåkurvan, djupskalningen,
femfiendetaket, startmakrona) föreslås till VD med siffror.
