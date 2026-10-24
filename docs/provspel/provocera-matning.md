# Hur stark är Provocera?

2026-10-24, gren `provspel-provocera` (från `test-0.30` på 0.30.35). Spelet är oförändrat. Varianterna finns bara i
botarna, bakom miljövariabler:

- `NO_PROVOKE=1`: raderna med Provocera tas bort ur alla makron (`tests/combat_bot.gd`). Brokk faller då igenom till
  nästa rad: Försvara under 50 % liv, annars Anfall.
- `PROVOKE_CD=n`: Provocera går att använda högst var n:te egen tur (förmågans `cooldown` = n − 1;
  `tests/balance_report.gd` och `tests/spider_diag.gd`). `PROVOKE_CD=2` är "inte två turer i rad" och `PROVOKE_CD=3`
  "var tredje tur".

```bash
NO_PROVOKE=1 BALANS=grotta GROTTA_FYRA=1 GROTTA_KORT=1 GROTTA_DJUP=3 NIVA_REALM=mountain godot --headless --path . --script res://tests/balance_report.gd
PROVOKE_CD=2 DIAG_REALM=crypt DIAG_DEPTH=3 DIAG_N=40 godot --headless --path . --script res://tests/spider_diag.gd   # varje grupp för sig
NO_PROVOKE=1 DIAG_MODE=grotta DIAG_REALM=mountain DIAG_N=50 godot --headless --path . --script res://tests/spider_diag.gd   # var körningarna förloras
```

Fyra hjältar (Paladinen, Brokk, Alva, Eira) med startmakron, på väntad nivå. `GROTTA_FYRA=1` kör bara raden med fyra
hjältar även på djup 1, och `GROTTA_KORT=1` bara MACRO och TUNED. Bara Brokk har Provocera i makrona: startmakrot
provocerar när han har över 50 % liv och inte redan provocerar, och TUNED gör likadant.

## Hela körningar i grottan (100 körningar per ruta, MACRO / TUNED)

| Realm, djup | I dag | Utan Provocera | Var 2:a tur | Var 3:e tur |
|---|---|---|---|---|
| Kryptan d1 | 36 / 54 % | **21 / 38 %** | 38 / 53 % | 39 / 57 % |
| Kapellet d1 | 44 / 45 % | **26 / 34 %** | 46 / 53 % | 52 / 57 % |
| Trollberget d1 | 46 / 64 % | **7 / 7 %** | 52 / 67 % | 49 / 64 % |
| Kryptan d3 | 10 / 24 % | 4 / 19 % | 18 / 23 % | 13 / 23 % |
| Kapellet d3 | 12 / 11 % | 9 / 7 % | 16 / 17 % | 18 / 18 % |
| Trollberget d3 | 27 / 36 % | **1 / 1 %** | 27 / 40 % | 34 / 42 % |

**Utan Provocera** tappar kryptan och kapellet 15–18 procentenheter på djup 1 (ungefär 40 % av vinsterna), och
Trollberget faller från 46–64 % till 7 % (nästan alla vinster).

**Med nedkylning** händer ingenting, eller så går det lite bättre (+0–8 enheter). Brokk anfaller turen emellan, och det
väger upp de turer då ingen provocerar.

Var körningarna förloras (`DIAG_MODE=grotta`, djup 1, 50 körningar, MACRO; f0 = våning 1, f1 = våning 2, end = bossen):

| Realm | I dag | Utan Provocera |
|---|---|---|
| Kryptan | boss 22, elit v2 6, elit v1 3 | boss 21, **elit v2 15**, elit v1 3 |
| Kapellet | boss 15, elit v2 9, elit v1 2 | boss 15, **elit v1 15**, elit v2 5 |
| Trollberget | boss 18, elit v2 7 | **boss 25, elit v2 14, vanlig 5** |

## Varje grupp för sig (en strid, fulla Charges, 40 strider; vinst / liv kvar i sällskapet)

Alla vanliga grupper vinns till 100 % i alla fyra varianterna, på djup 1 och 3. I nästan alla grupper slutar sällskapet
med **lika mycket eller mer** liv utan Provocera: Brokk anfaller i stället, och Provoceras −35 % Defense försvinner. Här
är de grupper där Provocera syns (djup 3; djup 1 ger samma bild):

| Grupp | I dag | Utan | Var 2:a | Var 3:e | Vad Provocera gör |
|---|---|---|---|---|---|
| Bergakungens sal (boss, Trollberget) | 100/65 | 100/**41** | 100/64 | 100/64 | Provocera är en *annan sorts handling*. Stenhjärta tar 60 % mindre skada när sällskapet gör samma sak två gånger i rad, och Brokk bryter kedjan. |
| Dimmans valv (elit, Kryptan) | 100/87 | 100/**74** | 100/89 | 100/89 | Gravdimman slår de bakre; Brokk drar till sig resten. |
| Lansens anstormning (elit v1, Kapellet) | 98/61 | **85**/54 | 98/63 | 95/59 | Den svarta lansen (Speed 18) går annars rakt på Alva. |
| Bron (elit, Trollberget) | 100/71 | 100/80 | 100/73 | 100/73 | Omvänt: Brom slår +50 % mot den som Provocerar. Utan Provocera går det bättre. |
| Benfurstens sal, Biskopens altare | 100/58, 100/68 | 100/64, 100/71 | | | Bossen slår alla. Provocera kostar Brokks Defense och tjänar inget. |

Hela tabellen (alla 62 grupper × 2 djup × 4 varianter) ligger i side-session-anteckningarna (`provocera/grupper.txt`).

## Svaret

**Hur mycket av vinsten bär Provocera?** I en enskild strid med fulla Charges nästan ingenting. Under en hel körning, när
Charges och liv nöts, bär den ungefär 40 % av vinsterna i kryptan och kapellet och nästan alla i Trollberget. Den skyddar
Alva och Eira mot elitgrupperna, så att helningarna räcker till bossen. I Trollberget fungerar Provocera också som
"varierad handling" mot Bergakungens Stenhjärta. Det är en kombination, inte en sköld, och borde synas för spelaren.

**Vilka grupper blir triviala med den?** Ingen grupp blir trivial *på grund av* Provocera. Däremot är nästan alla vanliga
grupper redan triviala som enskilda strider, med eller utan den: kapellets våning 1 lämnar 95–99 % liv, och kryptans och
Trollbergets våning 1 lämnar 96–99 %. Svårigheten ligger helt i nötningen, elitgrupperna och bossen.

**Är den för stark?** Nej. Nedkylning ändrar ingenting i siffrorna, och att ta bort den sänker vinsten kraftigt. Den
är en nyckel, inte en genväg. Det som är svagt är att makrot kan provocera varje tur utan att det kostar något.

## Rekommendation

1. **Behåll Provocera som den är, balansmässigt.** Inför ingen nedkylning för balansens skull, den gör ingen skillnad.
2. **Om VD vill göra Provocera till ett val** i stället för en rad som står på varje tur: nedkylning 1 ("inte två turer i
   rad", `PROVOKE_CD=2`) kostar ingenting i vinst (+0–8 enheter) och tvingar tanken att växla mellan Provocera och Anfall.
   Det är en fråga om känsla, inte balans. Pröva den på telefonen först. Siralim har ingen nedkylning på Provoke.
3. **Ge fler grupper ett skäl att *inte* provocera**, som Bron (Brom slår hårdare mot den som Provocerar) och bossar som
   slår alla. Nu straffar bara en av 62 grupper Provocera.
4. **Gör kombinationen med Stenhjärta synlig.** Bergakungen bärs av att Provocera räknas som en annan sorts handling. Det
   är en bra upptäckt för spelaren, men bara om hen förstår den. Ett tips från Imma eller i bossens Inspect skulle räcka.

## Fiendegrupperna efter roller

Roller ur datan (`enemies.json`, `abilities.json`, `traits.json`):

- **slagare**: Attack eller den starkaste skadeförmågan ≥ 16.
- **pansar**: Defense ≥ 3, eller Benrustning, Benmur, Spegelsköld eller Livvakt.
- **helare**: en förmåga eller egenskap som helar eller väcker (Mossryggs självläkning räknas).
- **snabb**: Speed ≥ 12 och Health ≤ 60.
- **förbi**: en skadande förmåga som ignorerar Provocera (`ignore_taunt`) eller träffar alla.

| Realm | Grupper med 3+ roller | Grupper med 1 roll | Saknas helt |
|---|---|---|---|
| Kryptan (23) | 17 | Glödande schakt (förbi), Gravens skyddare (pansar) | – |
| Kapellet (24) | 6 | Botgången, Paktens vakt, Offerprocessionen, Fanatikernas led (slagare); Gastarnas bänkrad, Häxornas cirkel, Fanans procession (snabb); Den skyddade diakonen (helare) | "förbi" i vanliga grupper (bara Inkvisitorn och biskopen) |
| Trollberget (15) | 2 (Bron, Bergakungen) | Mossiga backen, Avundens snår, Klubban vid grytan, Kittelgropen, Stenraset, Vanornas straff (alla "förbi" eller "helare") | **snabb och skör**, och slagare och pansar utom i Bron och hos bossen |

**Varierar för lite:**

- **Trollberget.** Alla vanliga troll har samma kropp: Health 52–60, Attack 11–14, Defense 1,5–2 och Speed 7–8.
  Grupperna skiljer sig bara i egenskaperna (gröt, avund, mossa, klubba). Ingen är snabb och skör, ingen är en tung
  slagare och ingen är pansar. Det förklarar också varför Provocera betyder så mycket där: alla slår lika, så den som drar
  till sig slagen avgör.
- **Kapellets våning 1** (Botgången, Gastarnas bänkrad, Gisslarnas valv, Paktens vakt) är två fiender med en roll
  vardera, och det lämnar 95–99 % liv. Där finns inget att svara på.
- **Kryptan** varierar mest. Gravens skyddare (två pansar) och Glödande schakt (två Glödskelett) är medvetet ensidiga.

Hela listan per grupp och fiende finns i anteckningarna (`provocera/roller.txt`).

## Förbehåll

- Bara Brokk provocerar i botarnas makron. En spelare som låter Paladinen provocera eller provocerar med flera kan få
  andra siffror.
- Gruppmätningen är en strid med fulla Charges. Den visar vilka grupper som är farliga i sig, inte under nötning.
- Rollerna är en grov regel ur siffrorna. En fiende kan spela en roll genom en egenskap som regeln inte ser.
- Mätt medan andra sessioner körde Godot. Det påverkar bara tiden (fasta frön).

## Efter grenen `fiender-roller` (2026-10-24)

Grupperna byggdes om efter rollerna ovan (Trollberget: `docs/plan/troll.md` "Roller"; kryptan: Glödande schakt är
Glödskelett och Benspringare; kapellet: Botgången får ett Irrbloss, Den skyddade diakonen en Gast, Fanatikernas led är
Blodsvuren, Fanbäraren och en Gast). Samma botar, fyra hjältar, 100 körningar, MACRO / TUNED:

| Realm | d1 förr | d1 nu | d3 förr | d3 nu |
|---|---|---|---|---|
| Kryptan | 36 / 54 % | 35 / 54 % | 10 / 24 % | 11 / 24 % |
| Kapellet | 44 / 45 % | 40 / 46 % | 12 / 11 % | 12 / 14 % |
| Trollberget | 46 / 64 % | 41 / 66 % | 27 / 36 % | 29 / 41 % |
| Lunden (orörd) | 49 / 64 % | – | 29 / 47 % | – |

Hela körningarna ligger inom ±5 enheter. Enskilda vanliga grupper blev **inte** dyrare: startmakrot slår fienden med lägst
liv, så den snabba och sköra fienden faller först och hinner göra lite (Bergets tier 2: 79–89 → 87–90 % liv kvar; Den
skyddade diakonen 99 → 94 %). Eftersom livet fylls på efter varje strid är det Charges som nöts; dyrare vanliga strider
betyder en svårare körning om inte elit eller boss blir mildare. Det är VD:s val.
