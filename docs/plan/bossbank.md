# Bossbanken – alla idéer på ett ställe (2026-10-24)

VD läste idéerna och tyckte att de var "superbra, precis sånt": bossar där man måste ändra något mitt i striden, t.ex. byta
tank när staplarna blir för många, kraft som flyttar runt mellan tre fiender, och en som bär något så att bara den tar full
skada. Den här filen samlar exemplen kort. Detaljerna står i källorna:

- `docs/plan/varslade-attacker.md` – laddningar, avbrott, motmedel mot tank och helare, faser
- `docs/research/wow-bossar.md` – 26 sorters WoW-mekanik översatta till vår tidslinje, 15 bossidéer
- `docs/research/bossar-andra-spel.md` – FF14, Hades, PoE, Diablo, Etrian m.fl., varningsspråk, grottans variation
- `docs/plan/mot-upprepning.md` – roterande väktare, affix, djupets tecken, innehållsplan
- `docs/research/variation-i-strid.md` – turordningsspel (Slay the Spire, Darkest Dungeon, FFX, Octopath …)

## VD:s beslut
- Vissa bossar får **kräva två tankar** (tankbyte).
- **Inga frivilliga svåra lägen** (Löften och instabilitet räcker).
- En **räddad fånge kan bli lärjunge** efteråt.
- **Rena DPS-prov** får finnas ibland.
- Råd med tre fiender: **båda sorterna** (ordningen som val, och kraften som flyttar).
- Djupets tecken: obesvarat (Claude rekommenderar tvåsidiga).

## Bossar och strider

| Namn | Realm | Förebild | Mekaniken | Svaret i makrot |
|---|---|---|---|---|
| **Systrarnas krona** | Kapellet | Blood Prince Council | Abbedissan och två diakoner. Bara den som bär kronan tar full skada; kronan flyttar var tredje tur. | Anfall den som har kronan (`target_has_aura`). |
| **Kistornas råd** | Kryptan | Assembly of Iron, Four Horsemen | Gravväckaren och två Kistbärare. Den som dör ger sin egenskap till de andra – ordningen blir ett val. | Välj ordning; rader per mål. |
| **Förhöret** | Kapellet | Tankbyte (Necrotic-staplar) | Inkvisitorn staplar Skuld (mindre helning) på den som provocerar; vid 3 staplar laddar han Dom mot den hjälten. | Försvara, eller en andra tank provocerar vid 3 staplar. |
| **Ljuset i kedjor** | Kapellet | Valithria | En fången pojke på kultens sida. Hela honom till fullt så brister vakternas gemensamma sköld. Han kan bli lärjunge. | Helaren helar fången (`target: captive`). |
| **Tre slag till midnatt** | Kryptan | Kel'Thuzad, Ragnaros adds | Klockaren som boss. Klockan väcker skelett; det tredje slaget bryts bara om alla skelett är döda. | Döda adds före tredje slaget. |
| **Benfursten** | Kryptan | – | Dödsdom laddas en tur; i vredesfasen (under 50 %) bryr han sig inte om Provocera. | Tysta eller försvara; i fas 2 skydda helaren. |
| **Den fallne biskopen** | Kapellet | Kanaliserade besvärjelser | Svarta mässan laddas i två turer och hålls av en Kultist; Skuld på den som provocerar. | Döda Kultisten först. |
| **Bergakungen** | Trollberget | Stagger (FFXIII) | Bergets vrede laddas i två turer och bryts bara av en stöt (mycket skada); Stenhjärta straffar samma handling två gånger; Spräckt sköld på tanken. | Variera handlingar, bränn under laddningen. |
| **Furietrion** | Alla | Hades Furier | En bossstrid per Realm är tre ur samma familj: slumpad ledare, två stöd som inte går att skada förrän ledaren faller. | Fokusera ledaren. |
| **Vandraren** | Alla | Siralims Zantai | En sällsynt boss med tre egenskaper lånade från våra andra bossar. | Läs kortet, bygg om. |

**Roterande väktare** (mot upprepning): huvudbossen på djup 1 och vart tredje djup; däremellan befordrade minibossar och
elitfiender – Klockaren och Gravväckaren (kryptan), Abbedissan och Inkvisitorn (kapellet), Strypvävaren (Lunden), Brom och
Trollmor Gråluva (berget).

## Verktyg
- **Varslade attacker:** en boss laddar 1–2 turer (ring med nedräkning, skuggruta på tidslinjen). Svar: Tysta, skjuta ned på
  tidslinjen (vårt avbrott), alla Försvarar (vår "pelare"), döda den som kanaliserar, Barriär i förväg. Bruten laddning gör
  fienden Vacklande (+25 % skada en tur).
- **Varningsspråk (FF14):** fyra återkommande former – Tankslag, Samlas, Sprid, Torn – var och en ett makrovillkor.
- **Mot tank och helare:** svepande slag, Spräckt sköld (märke på den som provocerar), en fas utan Provocera, helarjägare,
  Skuld (−50 % helning), straff för upprepning.
- **Affix på elitgrupper och Nemesis från djup 3:** Taggig, Spegel, Väktare, Läkande, Girig, Glödande (den som dödar ledaren
  brinner), Fängslare (första hjälten börjar Snärjd), Tornvakt (Torn-laddning var fjärde tur), Skiftande (halv skada av den
  skadetyp som träffade senast). Bara sådana som ändrar svaret, inte bara mer liv.
- **Djupets tecken:** en synlig regel per nedstigning för båda sidor – Fullmåne, Helig mark, Ekande valv, Ett folk,
  Inkräktare, Två Nemesis, Stjärnfall (tvåsidigt) – gärna som gåva + börda, går att slå om för silver.
- **Byt makro med ett tryck (FFXIII):** upp till tre sparade makron per hjälte, en knapp byter alla till "Skydd" eller "Bränn".
- **Belöningen syns på kortet (Hades):** vägen genom grottan blir ett val.

## Grottan (utan drastiska ändringar)
Vandrande grupp (Etrians FOE), brinnande elit med nedräkning, lås och nyckel, dold nisch, ibland ingen dimma, varierad storlek
och form per våning, Väktarsalen eller skattvalv som egen våning.
