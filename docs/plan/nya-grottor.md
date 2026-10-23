# Nya grottor (plan att diskutera)

Status: **förslag**, inget byggs förrän VD säger "kör". **Siralim** = som originalet, **VAL** = vårt eget val.
Underlag: `src/game/grotto.gd`, `docs/plan/0.27-grottan.md`, `docs/ideer/chat-familjer-karta-grottan.md` §M,
`chat-foremal-grottan.md`, `chat-stigkartor.md`, `docs/research/siralim.md` §8b, §10, §19–20, `docs/provspel/svarighetskurva.md`
och provspelen 0.30.14/0.30.15 (finns i commit a2900d7, men inte i `docs/provspel/` på main).

## 1. Varför grottorna är enformiga i dag

1. **Att raka av grottan är det rätta draget.** Botarna som backar från vanliga grupper vinner mindre: kryptan 32 → 15 %,
   första nedstigningen 86 → 36 % (provspel 0.30.14). Klarade körningar har fler strider än snittet (11,1 mot 9,4).
   Orsaken är att striderna ger erfarenhet medan fiendernas nivå bara följer djup och våning. Ingen karta ändrar det
   ensam. Belöningen måste också ändras.
2. **Questens mål syns aldrig.** Research M: i Samla hittar man det sista föremålet efter i snitt ~49 avslöjade rutor
   (76 %). Samma sak gäller (min läsning av `_roll`, inte mätt) Jakt och Rensa: eliten ligger var som helst minst 4 steg
   från start, under dimma. Det betyder att alla tre questerna tvingar fram ett svep. Bara Gravregistret och timglaset
   ger en ledtråd, och de finns inte på varje våning.
3. **Varje våning är samma recept.** 8×8, öppen plan, start vid kanten och målet långt bort. `problems()` kräver samma
   intervall överallt: 5–6 grupper, 1 elit, 1–2 lägereldar, 1 helgedom, 1–2 + 3–4 skatter. Våning 1 och 2 skiljer sig
   bara i tier. Kryptan och kapellet skiljer sig i fiendepooler och tre föremål, inte i hur grottan ser ut eller spelas.
   Siralims spelare klagar på precis detta: "våningarna känns lika" (§8b punkt 11, §19.7).
4. **Det finns ~30 tomma rutor och ~75 steg per körning.** Tryck utan beslut (§20.4: "nästan varje ruta bör ha något").
5. **Inget säger "gå nu".** När questen är klar fortsätter man, eftersom allt som finns kvar ger erfarenhet och silver.
6. **Körningen är lång:** 9–11 strider, 30–60 minuter. Stigkarteforskningen (N) visar att antalet strider väger tyngre
   än kartan.

## 2. Förslag

Varje förslag har en ungefärlig insats i arbetsdagar för en session. Det inkluderar tester och en botmätning, men inte
VD:s provspel.

**A. Ledtråd för questen (Siralim: skattkartans X, quests som pekar ut en plats).** När våningen börjar ritas ett rykte
på kartan: en blek tuschring över ett 3×3-område där varje quest-föremål, Nemesis eller elitgrupp står. Exakt ruta och
innehåll stannar under dimman. Varianter: ringen krymper efter varje strid, eller så avslöjas målet av Realmens föremål.
*Kod:* `RunState` räknar fram `quest_hints` (rutor) i `start_floor`, som sparas. `room_map_screen` ritar ringen. Ingen
ändring i `Grotto`. *Insats:* 0,5–1 dag.

**B. Tydlig avfärd (research M nr 2).** När questen är klar: en rad ("Trappan är öppen") och en streckad stig till målet
genom kända rutor (`Grotto.path` finns redan), och trappan/bossen pulserar. Dessutom en **avfärdsbelöning** (VAL, fråga
till VD), till exempel att varje vanlig grupp som står kvar ger en del av sin erfarenhet och silver när man går ned
("ni slapp striden men lärde er av spåren"). Alternativet är högre erfarenhet per strid och färre grupper (GROUPS 4–5).
Utan en av dem löser B bara känslan, inte strategin i punkt 1. *Kod:* liten, i `RunState` (`descend`/bossen) och
`HeroStats`. *Insats:* 1 dag plus balans.

**C. Planformer per Realm och våning (Siralim: Realms ser olika ut).** Ett formsteg före placeringen märker rutor som
`rock` (klippa):
- *Öppen* (i dag).
- *Gångar* (kryptan): gravgångar, 1–2 rutor breda, med nischer.
- *Rum* (kapellet): skepp, sidokapell och sakristia, förbundna med dörrar (1 ruta).
- *Öar* (en tredje Realm med vatten): områden med broar som flaskhalsar.

VD valde öppen plan för att osynliga klippor blir väggar man går in i. Förslag (VAL, fråga till VD): en klippa syns så
fort man står intill den. Bergssidorna i tusch (0.28.3) ritar redan den gränsen. Då går man aldrig in i något osynligt,
och dimman gäller fortfarande för innehållet.

*Kod:* `KINDS` får `rock`. `neighbors`, `path` och `blocked` hoppar över klippor. `_free_cell` väljer aldrig en klippa.
`problems()` behöver en sammanhangskontroll (BFS från start till allt innehåll). Avståndsreglerna (målet ≥5, eliten ≥4,
lägereld ≤3) bör räknas längs vägen, inte fågelvägen. Klungregeln gäller fortfarande. Formerna blir mallar i kod (en
funktion per form) med parametrar i data (`realms.json` "layouts" per våning). *Insats:* 3–5 dagar, varav ritningen av
klipporna och `problems()` är det mesta.

**D. Storlek per våning (research M nr 3: 6×6).** Våning 1 6×6 (snabb, ~3–4 grupper) och våning 2 8×8. *Kod:* `SIZE` är
en konstant som de statiska `xy`, `idx`, `neighbors` och `dist` använder, och den läses i `run_state.gd`,
`room_map_screen.gd`, `tests/combat_bot.gd` och `tests/test_map.gd`. Den måste bli `w`/`h` per grotta (sparas i
`to_dict`). Antalen i `_roll` och `problems()` ska skalas med storleken. Det leder till samma omskrivning som ett
**recept** (se E). *Insats:* 1,5–2 dagar.

**E. Specialvåningar (Siralim: Nether Realm-dörrar, mini-boss-rum, Treasure Golem).** Ett *recept* per våning ersätter
de fasta konstanterna (storlek, form, antal grupper och skatter, quest, dimma) och läses ur `data/floor_recipes.json`.
Våning 1 får ett specialrecept med en viss chans, eller när instabiliteten är ≥ 1:
- *Skattvåning* (6×6): inga vanliga grupper, 6 kistor och en Skattgolem som försöker fly i striden (Siralim). Questen:
  fäll golemen.
- *Väktarsalen* (elitvåning, 6×6): ingen dimma, tre elitgrupper med en lägereld mellan sig, och man besegrar två av tre
  för att gå vidare. Ledstjärnans test i ren form: man ser alla tre och väljer bygge.
- *Mörk våning*: även besökta rutor bleknar efter några steg, och lyktor (föremål) lyser upp ett område för gott.
  Grupperna har bättre troféchans. Det är tveksamt: risken är mer dimma och mer frustration. Prova sist.

*Kod:* receptomskrivningen av `_roll`/`problems()` (D ingår), sedan lite kod per variant (golemens flykt är en ny
egenskap i striden). *Insats:* receptet 2 dagar, varje variant 0,5–1,5 dagar.

**F. Realm-egna ruttyper.** Det mesta finns redan som föremål (`objects.json`). Två saker kan läggas till. Föremål
som *ändrar kartan*: Kryptans benhög spärrar en gång tills man rensar den (1 Charge eller en strid), och Kapellets
dörr kräver en nyckel från sakristian. Föremål som *hör till formen*: nischer i gångarna och altare i rummen. *Kod:*
mest data. Varje ny effekt är en gren i `RunState.use_object`. *Insats:* 0,5 dag per föremål.

**G. Lockelser genom dimman (research M nr 4, Siralims synvidd).** En sällsynt skatt eller elitgrupp syns som ett svagt
sken eller rök två rutor bort. Man ser att något finns, inte vad. Det gör dimman till ett vägval i stället för ett svep.
*Kod:* `RunState` räknar `glimpsed` efter varje steg, och kartan ritar en symbol. *Insats:* 0,5–1 dag.

**H. Två behov som konkurrerar (research M nr 5).** En regel i `problems()`: den kortaste vägen till målet går förbi
eliten, och lägerelden ligger på en omväg. Det ger fler beslut och färre tomma tryck. *Insats:* 0,5 dag, men regeln kan
öka antalet försök i `generate()`. Mät det.

## 3. Kod eller data

| Förslag | Ny kod i `Grotto.generate()`/`problems()` | Bara data | Insats |
|---|---|---|---|
| A ledtråd | nej (RunState + karta) | radien | 0,5–1 d |
| B avfärd | nej (RunState, belöning) | andel erfarenhet/silver | 1 d + balans |
| C planformer | ja: `rock`, BFS-sammanhang, vägavstånd, mallar | vilken form per Realm och våning | 3–5 d |
| D storlek | ja: `SIZE` → per grotta, skalade antal | storlek per våning | 1,5–2 d |
| E specialvåningar | ja: recept i stället för konstanter | recepten, chans per våning | 2 d + 0,5–1,5 d/variant |
| F ruttyper | nej (`use_object`) | föremålen | 0,5 d/st |
| G lockelser | nej (RunState + karta) | vad som syns, avstånd | 0,5–1 d |
| H konkurrerande behov | ja: en regel | – | 0,5 d |

Varje ändring i `_roll` ändrar alla befintliga frön. En sparad körning bär hela grottan i `run.cfg`, så den fortsätter.
Däremot ändras testernas förväntade grottor. `tests/test_map.gd` bör pröva `problems()` för varje form och recept över
några hundra frön, och soak-testet kontrollerar redan grottans regler på varje ny våning.

## 4. Topp 3 att bygga först

Ingen av siffrorna nedan är mätt. De är mål. Mätningen behöver tre nya saker i `BALANS=grotta`: **andel besökta rutor**,
**steg efter att questen är klar** och en bot **"direkt"** som går mot ledtråden, slåss bara mot det som spärrar eller
hör till questen och går när questen är klar. "Försiktig" och "enkel" finns redan.

1. **A + B: ledtråd och avfärd, på dagens 8×8** (1,5–2 dagar). Det angriper rotorsaken billigast, och research M säger
   att det ska testas först, så att vi ser vad som gör vad innan kartan byggs om.
   *Bättre om:* "direkt" och "försiktig" vinner inom 5 procentenheter från "enkel" (i dag 32 mot 15 %). Strider per
   klarad körning för "direkt" ≤ 7–8 (i dag 11,1). Steg ≤ 50 (i dag ~75). Andel besökta rutor ≤ 60 % (i dag ~76 % enligt
   M). "Enkel" vinner lika mycket som i dag, ±5.
2. **Recept + planformer: gångar i kryptan och rum i kapellet, våning 1 i 6×6** (C + D, 5–7 dagar). Det gör Realmerna
   olika att gå i, inte bara att slåss i, och gör körningen kortare.
   *Bättre om:* vinsten med startmakrona är oförändrad ±5 per Realm. Steg per körning sjunker ytterligare ~15 %.
   `generate()` behöver i snitt < 20 försök per våning, och ingen våning faller tillbaka på "sista försöket" (mät i
   `test_map`). Soak-testet går utan fel. VD ser på skärmdumpar (`--explore=64`) att två våningar av samma form inte
   liknar varandra.
3. **Väktarsalen som första specialvåning** (E, 1 dag efter receptet). Den prövar ledstjärnan direkt: man ser tre
   elitgrupper och byter trofé eller makro vid lägerelden.
   *Bättre om:* TUNED vinner minst 10 procentenheter mer än MACRO på den våningen (byggen ska spela roll). Vinsten för
   hela körningen sjunker högst 5 enheter. Andelen körningar där boten byter trofé vid lägerelden före en elitgrupp ökar
   (ny räknare i boten).

Hela tiden gäller: körningen ska inte bli längre. Strider per klarad körning ska ligga på ≤ 10 med "enkel".

## 5. En tredje Realm (spindlarna, eller Källornas trädgård)

Med recept och former blir en ny Realm mest data:
- Spindlarna: en form *Nät* (gångar som strålar ut från ett centrum där bossen eller ett ägghölje står) och ruttypen
  *tråd* (kostar en Charge att skära igenom eller en strid för att gå runt). Föremålen ägg, kokonger och offer finns i
  Siralims Arachnid Nest (§19.7).
- Källornas trädgård: formen *Öar* med broar, och slussar som öppnar en väg när de vrids (ett föremål som ändrar kartan,
  F).

Ingen av dem kräver mer kod i grottan än C och F. Spindelsessionen behöver bara en rad i `realms.json` "layouts".

## 6. Frågor till VD

1. Får klippor finnas om de syns så fort man står intill (C)? Det ändrar beslutet "öppen plan" från 2026-10-21.
2. Vilken belöning ska få spelaren att gå när questen är klar: erfarenhet från grupper man inte slogs mot, eller högre
   erfarenhet per strid och färre grupper (B)?
3. Ska ledtråden vara gratis och alltid synlig (A), eller köpas med en Charge som timglaset?
4. Specialvåningar på våning 1 som slump, eller bara med instabilitet? Och ska de ersätta våning 1 eller vara en frivillig
   sidodörr (Siralims Nether-dörr, mer kod: en våning i våningen)?
