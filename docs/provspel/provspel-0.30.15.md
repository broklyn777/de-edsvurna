# Provspel och buggjakt 0.30.15-test (grenen test-0.30, 134c7c6)

2026-10-23. Rättelserna efter provspelet av 0.30.14 är kontrollerade och kombinationsrutan granskad med en ny flagga.
Nivån efter första nedstigningen är mätt, och ett nytt bottest (`tests/soak.gd`) har spelat 1 050 hela körningar med
slumpade val. Spelkoden är inte rättad. Det enda tillägget i spelet är utvecklarflaggan `--combo-first` i `battle.gd`.

## Sammanfattning

1. Rättelserna håller: GÅ HEM syns inte under introts nedstigning, smedjan förväljer Rättfärdigt slag, Gorms svar och
   replikerna är rättade, plattan bakom "Det här avgjorde striden" och reglagens handtag syns.
2. Soak-testet (1 050 körningar, 107 000 drag, 7 300 strider, 10 600 sparningar) gav **inga körfel, ingen fastlåsning
   på kartan och inga fel vid sparning och inläsning**. Silver, samling och Charges höll sig inom gränserna.
3. **Medel:** en strid kan bli ett evigt dödläge på instabilitet 3. Alla fem fall har **Kaosvind**, och spelet har
   ingen turgräns, så bara GE UPP tar spelaren därifrån.
4. **Medel (kvar från förra rapporten):** förlorar man under introts nedstigning innan Imma har anslutit, spelas ändå
   hemkomsten där Imma "smet efter" och talar om Benfursten (3 % av första nedstigningarna).
5. **Nivån:** efter första nedstigningen står sällskapet på nivå 4–5 (vinst 97 %), och den andra nedstigningen vinns då
   i 100 % av fallen. Den behöver inte bli lättare, snarare tvärtom. Undantaget är den som förlorar första striden
   ensam: hen går ned igen på nivå 1 och vinner 14 %.

## 1. Rättelserna (kort kontroll)

| Rättelse | Resultat | Bild (`shots15/`) |
|---|---|---|
| GÅ HEM dold tills `intro_done` | Bara RUMSÖGONBLICK och MAKRON syns på första nedstigningen | `v1_descent_map_*` |
| Smedjan förväljer `holy_smite` | "Rättfärdigt slag" vald; texten säger "25 % chans vid Anfall: kastar Rättfärdigt slag … 50 % hårdare mot en Förblindad fiende" | `v2_smith_intro_*` |
| Gorms svar i övningssteget | "Makrona kommer när du har prövat ett riktigt svärd hos Stig." | `v5_macros_reply_*` |
| Platta bakom "Det här avgjorde striden" | Mörk platta, läsbar med fyra hjältar; den täcker ramarna, men det är avsikten | `v4_victory4_*` |
| Reglage med handtag | Handtag och "Dra i staplarna för att ändra." | `v6_settings_*` |
| Hemkomsten | Gorms och Immas samtal som förut (`v3_crypt_home_*`); soak-testet kontrollerar att introt står på `crypt` och att Imma är rekryterad efter hemkomsten: alltid sant |  |
| Svärdet slår till | Introts svärd (nivå 1, Rättfärdigt slag) och en ny profils makro, 50 strider mot crypt_1: svärdet kastade i 58 av 239 anfall (24 %, väntat 25 %) | — |

Bilderna ligger i scratchpad
(`/private/tmp/claude-501/-Users-bjornjansson-Desktop-CodeVibe26-rpg007--claude-worktrees-rum-3d-a91c58/1886a707-58a3-4ce1-a6ce-0d28074ffa4d/scratchpad/shots15/`)
och kopieras till anteckningsmappen `provspel-0.30.15/`.

## 2. Kombinationsrutan (`--combo-first`)

Ny utvecklarflagga i `scripts/battle/battle.gd`: som `--combo`, men Paladinen ställs först på tidslinjen (snabbheten
höjs bara medan `begin()` lägger ordningen och återställs sedan). Rutan visas bara en gång per profil, så flaggan
behöver en ny profil:

```bash
godot --path . -- --intro-step=crypt --combo-first --floor=0 --screenshot=/tmp/combo.png --frames=260
```

Med `--all-companions` (Mac:ens sparplats i minnet) har rutan redan setts och bara ordet KOMBINATION! syns.

Granskning (`shots15/combo_box_1280x720.png`, `combo_box_1560x720.png`): rubriken "Kombination!" och tre rader:
"Imma gjorde Skelettbågskytt Förblindad." / "Rättfärdigt slag slår 50 % hårdare mot en Förblindad fiende: 13 blev 20."
/ "Så fungerar hela spelet: …". Räkningen stämmer (13 × 1,5 = 19,5 → 20), texten ryms i båda bredderna och spelet
pausas bakom. Kosmetiskt: makrologgen under rutan klipps mitt i ett ord ("någon fiende h") utan "…". Den nya ellipsen i
`UiStyle.para` gäller inte loggraden.

Föreslås för CLAUDE.md (Kommandon). Jag har inte ändrat den.

## 3. Nivån efter första nedstigningen

`SOAK=nivaer godot --headless --path . --script res://tests/soak.gd -- --runs=300` (1,5 min). Det här är spelets
riktiga flöde: en ny profil med introts svärd (Rättfärdigt slag, nivå 1) och en ny profils makron. Paladinen går ned
ensam, Imma ansluter efter första striden, och erfarenheten ges med `Profile.grant_xp` (ikapphämtning, även till
stupade). Boten slåss mot allt den kliver på och ger aldrig upp. Efter hemkomsten går samma profil ned igen, med Syster
Alva i ett fånge-rum och utan att svärdet höjs.

| Första nedstigningen | Körningar | Nivå efteråt (Paladinen, Imma) |
|---|---|---|
| Vunnen | 291 (97 %) | 5/5: 216 · 4/4: 56 · 5/4: 14 · 6/6: 5 |
| Förlorad | 9 | 1/– (föll i första striden, ensam): 7 · 3/3: 2 |

| Andra nedstigningen med just de nivåerna | Vinst |
|---|---|
| Nivå 4–6 | **100 %** (291 av 291) |
| Nivå 3 | 1 av 2 |
| Nivå 1 (efter förlust i första striden) | **14 %** (1 av 7) |
| Totalt | 98 % (293 av 300) |

Slutsats: raden "ny profil nivå 1" i `BALANS=forsta` (13–20 %) motsvarar bara den som förlorar första striden. En
vanlig spelare kommer till den andra nedstigningen på nivå 4–5, två nivåer över fiendernas väntade nivå 3, och vinner
alltid. Den andra nedstigningen behöver alltså inte balanseras ned. Frågan är snarare om den är för lätt, och om den
som förlorar tidigt behöver hjälp, till exempel att trappan för första nedstigningen gäller tills man har vunnit en
gång. Obs: `BALANS=forsta` ger inte boten introts svärd, så dess rader för första nedstigningen är något för låga.

## 4. Buggjakt med botar (`tests/soak.gd`)

```bash
godot --headless --path . --script res://tests/soak.gd -- --runs=50
godot --headless --path . --script res://tests/soak.gd -- --runs=1000 --from=1001
godot --headless --path . --script res://tests/soak.gd -- --seed=30 --verbose
```

**Vad den gör.** Spelets flöde (Run, rumskartan, striden, lägret) är skrivet en gång till utan noder, med samma anrop
till RunState, Profile och CombatSim i samma ordning: `start_run`, steg, ANFALL/BACKA, `battle_finished` (silver, boss,
`mark_sneak`, troféerbjudande, `battle_won`, fånge/skatt/föremål/klocka, questen), lägret (välj trofé, ge den till
någon, `after_camp`), lägereld (vila, byt troféer), skatter, fångar, helgedomar (slumpad gåva eller Pandemonium), alla
föremålsval som går, trappan, bossen, GE UPP i striden och GÅ HEM. Körningen och profilen sparas och läses in mitt i
(12 % av dragen, och 5 % mitt i en strid) och spelet fortsätter från den inlästa. Varje körning slumpar ur fröet:
Realm, djup 1–3, instabilitet 0–3 (spelets `roll_rules`), sällskap 1–4 och följeslagare, kall och perks, nivåer kring
väntad nivå, artefakter (typ, förmåga, nivå 1–10), burna troféer, tidigare nedstigningar och strategi: slumpad väg,
boten (enkel, försiktig, girig) och 0, 25 eller 100 % slumpade handlingar i striden. 20 % är introts första
nedstigning.

**Invarianter efter varje drag:** körfel (Logger); grottans regler (`Grotto.problems`) på varje ny våning; inget
negativt, NaN eller oändligt i stats, liv och barriär; liv ≤ max; ingen levande med 0 liv; Charges ≥ 0 (och inte
orimligt många); alla i sällskapet har Charges; Paladinen först, ingen dubblett, högst fyra; burna troféer finns bland
körningens; pjäsen står på en besökt ruta; questens framsteg ≤ målet; det finns alltid ett giltigt drag (annars
"fastlåst"); striden tar slut inom 1 500 drag; körningen tar slut inom 2 000 drag; sparning och inläsning ger samma
körning och profil; silvret sjunker aldrig och ingen trofé försvinner ur samlingen. Efter en första nedstigning
kontrolleras hemkomsten (introts steg, Imma rekryterad, berättelsen).

**Körningar:** 50 (frö 1–50, 17 s) och 1 000 (frö 1001–2000, 7,6 min): 365 klarade, 524 förlorade (88 gav upp), 106
gick hem; 100 642 drag, 6 940 strider, 488 bossar, 10 208 sparningar, 2 722 föremålsval, 948 helgedomar, 2 216
lägereldar, 410 befrielser, 4 447 skatter, 611 trappor. Botfixar under arbetet (bara i testet): en profil efter
introt har alltid Imma (annars lägger `Profile.load_from` till henne och sparningen ser ut att ändras), och första
nedstigningen sker alltid i kryptan.

### Fel, rangordnade

**Medel 1. Evigt dödläge på instabilitet 3 med Kaosvind (5 av 1 050 körningar).** Striden fortsätter i över 1 500
turer: sällskapet skadar inte fienderna fortare än de helas, och spelet har ingen turgräns. Alla fall har
`chaos_wind` (hjältarnas Attack och Defense byter plats), oftast med `sealed_words` (en förmåga i taget förseglas),
`risen_dead` och `withered_grace`. Spelaren kommer bara ur med GE UPP och förlorar då körningen.
- Frö 30: crypt_2f, djup 2; Mögelskelettet står på fullt liv, Gravprästen helar. Regler: chaos_wind, fog_weakness,
  sealed_words, cursed_ground, heavy_air, mirror_bones.
- Frö 1414 och 1462: chapel_e2, djup 3, Paladinen + Alva på nivå 17, båda på fullt liv, ingen fiende dör.
- Frö 1102 (crypt_2e), 1167 (crypt_3, Benfursten), 1968 (chapel_2d).
- Återskapa: `godot --headless --path . --script res://tests/soak.gd -- --seed=1414 --verbose`.
- Förslag (frågor till VD): en turgräns som Siralims (Siralim har ingen, men där kan man alltid fly) med en tydlig
  förlust "Striden ebbar ut", eller låt Kaosvind byta tillbaka efter några turer. CLAUDE.md säger redan att Kaosvind gör
  kryptan omöjlig för TUNED.

**Medel 2. Hemkomsten efter en förlust innan Imma anslöt (kvar från 0.30.14 A1, 18 fall: 3 % av första
nedstigningarna).** GÅ HEM är borta, men förlorar man eller ger upp i första striden, då Paladinen är ensam, leder
förlusten hem. `came_home` rekryterar Imma, och Gorm och Imma talar om nedstigningen ("Längst ned satt en Benfurste")
fast hon aldrig följde med. Profilen går sedan ned på nivå 1 (se avsnitt 3).
- Frö 16 (50-körningen), 1001, 1318, 1529, 1538, 1551 …; i nivåläget frö 5, 23, 102, 167, 180.
- Förslag: en egen kort hemkomst när `state.party` saknar Imma (Gorm: "Du kom hem. Det räknas.", och Imma ber om att
  få följa med nästa gång), och kanske trappan för första nedstigningen en gång till.

**Kosmetiskt 3. Nether Stones kvalitet tappar decimaler vid sparning.** `ConfigFile` skriver
`stones[*].affixes[*].q` med ungefär sju siffror (1,31107497 → 1,311075). Det märks inte i spelet. Testet jämför nu
flyttal med en relativ tolerans på 0,01 %. Frö 6, 35, 40, 49 i den första versionen.

**Kosmetiskt 4. Makrologgens rad klipps utan "…"** (se avsnitt 2).

**Inga fel** i: körfel, fastlåsning på kartan, grottans regler, sparning och inläsning av körningen (även mitt i
striden), silver, samling, Charges, stats, sällskapets form, troféer och quest.

### Vad testet inte täcker
Scenerna (UI, animationer, tryck), smedjan, altaret och Värdshuset; makroredigeringen; spelets egna `Run`-metoder (de
är speglade, så en avvikelse mellan spegeln och `run.gd` syns inte); Övningsgården.

## Ändringar på grenen
- `tests/soak.gd` (nytt), `scripts/battle/battle.gd` (`--combo-first`), `docs/provspel/provspel-0.30.14.md` och
  `provspel-0.30.15.md`. Testerna: 336/336.
