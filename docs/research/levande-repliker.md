# Levande repliker: hur bra spel gör, och regler för oss

2026-10-24. Uppdrag från VD: följeslagarnas och borgens repliker ska reagera på det som faktiskt har hänt, tilltala
spelaren med `{namn}`/`{titel}`, aldrig kännas upprepade och få den som spelar ensam att känna att hen inte är ensam.
"Att det betyder något är ett måste."

Dokumentet har tre delar: (1) vad andra spel gör, med källor; (2) var vårt system står i dag; (3) regler, dataformat
och en prioriterad byggordning. Det som byggs parallellt (den levande världen: bekräftelser per Realm, följder i borgen,
världshändelser, möten vid porten, svar efter förlust) ska följa reglerna i del 3, inte få ett eget urval.

---

## 1. Källorna

### 1.1 Hades (Supergiant, 2020)

**Storlek.** Över 22 000 repliker med röst (GDC 2021, Kasavin och Korb), drygt 300 000 ord, varav ca 8 500 repliker är
Zagreus egna. Zagreus får bara en eller två repliker med varje person per körning (Kasavin i podden Eggplant, återgiven
av Videlais), så att relationerna växer lite i taget över många dödsfall.

**Mekanismen** (läst direkt i spelets Lua-skript, `Narrative.lua` och `NPCData.lua`, som ligger öppet i en spegling på
GitHub, se källorna):

- Varje samtal är en namngiven **TextLineSet** med villkor på spelets läge. De vanligaste fälten i `NPCData.lua`
  (räknade av oss): `PlayOnce` 1 252 gånger, `RequiredTextLines` (de här samtalen måste ha spelats) 1 190,
  `RequiredFalseTextLines` (de här får *inte* ha spelats) 527, `RequiredFalseFlags` 408, `RequiredAnyTextLines` 352,
  `Priority` 320, `RequiredMinNPCInteractions` 231, `MinRunsSinceAnyTextLines` 184, `SuperPriority` 98,
  `RequiredFalseTextLinesThisRun` 86, `RequiredLastKilledByUnits` 57 (vem som dödade dig sist), `RequiredKillsThisRun`
  34, `MaxRunsSinceAnyTextLines` 40.
- Personerna har tre sorters samtal: **InteractTextLineSets** (berättelse och reaktioner, oftast `PlayOnce`),
  **RepeatableTextLineSets** (korta fyllnadsrepliker som får upprepas) och **GiftTextLineSets** (svar på gåvor).
  Fyllnaden används när inget unikt passar.
- Urvalet (`PlayRandomRemainingTextLines`): samla alla samtal vars villkor gäller. Bland dem som inte spelats än:
  finns `SuperPriority`, välj slumpvis bland dem; annars `Priority`; annars slumpvis bland de ospelade. När alla
  passande har spelats nollställs minnet för den gruppen och man slumpar bland alla. Det är **"färskt först, sedan
  om från början"** med två prioritetsnivåer ovanpå.
- `IsTextLineEligible`: `PlayOnce` kollar ett minne över hela sparfilen (`TextLinesRecord`), `PlayOnceThisRun` ett minne
  för körningen. Kedjor byggs bara med `RequiredTextLines`/`RequiredFalseTextLines`: samtal B kräver att A har sagts,
  och A:s uppföljning stänger av sig själv när B har sagts.
- **Avstånd i körningar:** `MinRunsSinceAnyTextLines = { TextLines = {...}, Count = 20 }` (exempel ur Hades om
  helgedomen: minst 20 körningar sedan ett visst samtal). Det är så Hades låter saker sjunka in innan nästa steg.
- **Strids- och fältrepliker** (`AudioScripts.lua`): `Cooldowns` med namngivna nedräkningar som flera repliker delar
  (t.ex. "Zagreus säger något alls"), `ChanceToPlay`, `SuccessiveChanceToPlay` (lägre chans om något i gruppen redan
  sagts), `RandomRemaining` (tömma högen innan upprepning), `PlayOnceContext` (en gång per sammanhang),
  `BreakIfPlayed`.

**Lärdom för oss:** Hades känns levande inte för att varje replik är smart, utan för att *de viktiga* är bundna till
exakta händelser (vem dödade dig, vilken boss, vad som sades förra gången) och spelas en gång, medan fyllnaden är
uttryckligen fyllnad. Prioritet slår slump; slump väljer bara bland lika viktiga.

### 1.1b Hades II (Supergiant, early access 2024, 1.0 2025)

**Vad som ändrades.** Samma grundmodell (samtal med villkor, `PlayOnce`, `RequiredTextLines`, prioritet, färskt först),
men större: navet Crossroads har fler personer (Hecate, Odysseus, Dora, Nemesis, Moros, Eris m.fl.), och relationerna
fördjupas genom aktiviteter man betalar med resurser från körningarna. Den varma källan låter en person sitta ned med
Melinoë för ett längre samtal; det kräver Bath Salts och är frivilligt (PC Gamer, Dot Esports). Personer man möter
under körningen, t.ex. Nemesis som ibland dyker upp och utmanar eller stör, för både huvudberättelsen och de egna
trådarna framåt (Inverse; Exitlag).

**Tekniskt** (läst i en mod som bygger på spelets skript, NikkelM/Hades-II-HadesBiomes): villkoren har blivit generella.
I stället för hundratals fasta fält som `RequiredFalseTextLines` skriver man `Path = {"CurrentRun", "BiomesReached"}` med
`IsAny`/`HasAny`/`PathTrue`/`PathFalse` och `OrRequirements`, och återkommande villkor har fått **namn** i
`NamedRequirementsData` (t.ex. `NoRecentFieldNPCEncounter`, `IsDevotionEncounter`), som repliker och möten pekar på.

**Mottagandet.** Betygen är höga (94 på Metacritic och OpenCritic enligt GameGeeker; spelpris vid The Game Awards 2025).
Repliken för repliken får beröm: "sharply written dialogue" (Inverse). Men flera recensenter tycker att spelet följer
ettans mönster nära och känns bekant, att berättelsen kommer i små fragment och delvis grumlas (GamingBolt, GameGeeker
7/10 för berättelsen), och att resursletandet kan göra upprepningen till en syssla (Inverse). Användarrecensioner säger
att reaktiviteten finns men plattas till: varje gud återkommer till samma ämnen (Backloggd, anekdotiskt). Redan om
ettan klagade spelare på att personer pratar om en besegrad boss som om det vore första gången (Steam-tråd).

**Vår bedömning** (ärlig, inte källbelagd i sig): i hantverk lika bra som ettan, men inte lika tydligt *reaktiv* som
upplevelse. Fler personer delar på uppmärksamheten, och mer av samtalen är låst bakom resurser och aktiviteter än
bakom det som faktiskt hände i körningen. Det bekräftar vår ledstjärna: färre personer som minns mer slår många som
var och en minns lite.

**Värt att ta efter:** (1) **namngivna villkor**, så att "inget samtal med den här personen på länge" eller "sällskapet
är litet" skrivs en gång och återanvänds (se `conditions` i del 4); (2) **eller-grupper** i villkoren; (3) det
frivilliga **längre samtalet** (den varma källan) motsvarar vår lägereld eller värdshuset: en plats där spelaren själv
väljer att lyssna, och där längre par-samtal passar. Att låsa samtal bakom resurser tar vi däremot *inte* efter.

### 1.2 Valve: dynamisk dialog genom "fuzzy pattern matching" (Elan Ruskin, GDC 2012, Left 4 Dead)

- Varje gång något händer ställer spelet en **fråga** (query): en ordlista med hundratals fakta om talaren, världen och
  minnet (vem, var, koncept som "såg en fiende", hälsa, hur många gånger något sagts …).
- Tusentals **regler** har var sin lista med **kriterier**. Ett kriterium som stämmer ger sin vikt (standard 1,0), ett
  som inte stämmer ger 0; kriterier kan vara `required`. Regeln med högst poäng vinner och pekar på en grupp svar
  (Valve Developer Community, "Criteria"). I praktiken: **den mest specifika regeln vinner**, de allmänna är reserv
  (Emily Shorts referat: "the most specific rule it can find, using less-specific ones as fall-backs").
- **Svarsgrupperna** går igenom alla svar innan något upprepas (standard), `norepeat` stänger gruppen när alla sagts,
  och svar kan ha fördröjning innan de får sägas igen (`respeakdelay`).
- Svar kan **skriva tillbaka fakta** i minnet ("har pratat om cirkusen"), som nästa fråga kan läsa. Så byggs
  uppföljningar och "vi har redan sagt det" utan kod.
- Målet var att författarna själva lägger till repliker utan programmerare, och att repliker kan avbrytas om något
  viktigare händer.

**Lärdom för oss:** specificitet är ett bättre sätt än handskrivna prioriteter att få "Brokk i kapellet efter att
Alva föll för andra gången" att slå "någon föll". Våra villkor (`when`) kan räknas som kriterier.

### 1.3 Darkest Dungeon (Red Hook, 2016)

- Det mesta av berättelsen går genom berättaren (Bourassa till GameSpot); repliker knutna till stridens ögonblick
  (kritiska träffar, döda hjältar, helningar) och korta rader i hamleten.
- **Vad som blev upprepat:** spelarna älskar rösten men säger att den blir tjatig. Red Hook *sänkte frekvensen* på de nya
  helningsreplikerna i en patch (21 juni 2017), och de berättade stadshändelserna fick ett frekvensreglage i
  inställningarna. Det vill säga: problemet var inte texten utan hur ofta vanliga händelser fick en replik.
- **Lärdom:** vanliga händelser (helning, träff, vanlig seger) ska ha låg chans och lång paus; starka händelser
  (död, boss, första gången) kan ha full chans. Frekvens är en designparameter, inte en eftertanke.

### 1.4 Siralim Ultimate (Thylacine)

- Man kan prata med varelserna i Menageriet; varje ras har egen dialog efter sin personlighet, och utvecklarna skriver
  själva att det är mycket text (fäst inlägg på Steam). NPC:erna i slottet har tjänster och korta repliker.
- Vi har inte hittat publicerade siffror eller klagomål om upprepning. Vår bedömning (inte källbelagd): Siralims
  repliker är mest *personlighet* och nästan aldrig *minne*; de vet inte vad som hände i förra Realmen. Där kan vi
  gå längre än förebilden utan att bryta mot dess anda.

### 1.5 Wildermyth (Worldwalker, 2021), kort

- Varje hjälte har en **historik**: tre genererade rader från början (ursprung, anekdot, drivkraft) och nya rader när
  händelser inträffar; rader lämnar "hooks" som senare händelser kan haka i. Överlevande hjältar kan bli legender och
  återkomma i nya kampanjer med sin historik (Wildermyth-wikin, "History").
- **Lärdom:** minnet ska vara *per hjälte*, läsbart för spelaren (vår Krönika) och användbart för replikerna (samma
  fakta). Det som står i krönikan är det replikerna får referera till, så att spelaren kan kontrollera att det stämmer.

---

## 2. Vårt system i dag (main och `test-0.30`)

| Del | Var | Urval | Minne |
|---|---|---|---|
| Vardagsrepliker i borgen (`people.*.idle`) | `Dialog.idle_line` | Repliker vars `when` gäller först, sedan de allmänna; `posmod(turn, antal)` | `Profile.talks` (antal samtal). Nyheter upprepas för alltid i turordning. |
| Hälsningar | `Dialog.greeting` | Första mötet, sedan turordning | `talks` |
| Värdshuset (`inn`) | `Dialog.inn_line` | welcome / bored / inn efter `home_runs`, `inn_heard` | per följeslagare |
| Repliker i grottan (`barks`, `pairs`) | `Dialog.bark`, `Run.bark` | Läge (14 sorter), Imma 70 %, par 50 %, högst en per rum | `RunState.barks_used` (texten, **bara den här körningen**) |
| Berättarrutor | `Run.narrate` | Händelsenyckel | `Profile.narrated` (en gång) |
| Hemkomsten (Krönikan, test-0.30) | `Chronicle.pick_remarks` | Händelser med `PRIO` (100 → 5), `FAMILY` mot dubbletter, högst 2 (den andra bara om prio ≥ 44), talaren efter relevans (`who`, `subject`), specifika före allmänna | `Profile.chron_said` (id, nollställs per pool), `chron_stats` (mönster) |
| Levande kartan (test-0.30) | `LivingMap` + `MAP_PRIO` | Tävlar i samma ruta som krönikan | `growth_news` |
| Titlar | `data/titles.json`, `Chronicle.title_or_name` | `{titel}` faller tillbaka på namnet; repliker med `{titel}` väljs bara om en titel finns | `Profile.title`, `titles` |

**Det som redan är rätt** (och som ska behållas): krönikans hemkomst är i princip Hades-modellen (händelse → prioritet →
relevant talare → färskt först). Fasta id:n på nya repliker. `{titel}` med reserv. Högst en replik per rum.
Ingen replik i striden.

**Luckorna:**

1. **Repliker i grottan har inget minne mellan körningar.** `barks_used` töms varje körning och jämför text, inte id.
   Imma har 3–6 repliker per läge; "cave" sägs varje våning, så efter 5–10 nedstigningar har spelaren hört allt
   flera gånger. Det här är den största källan till upprepning över 50–100 nedstigningar.
2. **Nyheter i borgen pensioneras aldrig.** En `when`-replik ("Benfursten är besegrad") står kvar i turordningen för
   alltid; efter tjugo nedstigningar är den gammal och upprepad.
3. **Fem olika urval** (idle, inn, bark, krönika, karta) med var sin logik för prioritet, minne och reserv. Den levande
   världen riskerar att bli ett sjätte.
4. **Lite specificitet.** Villkoren är få (`recruited`, `boss`, `min_descents` …); en replik kan inte kräva "Alva föll
   *i kapellet* mot *Inkvisitorn*" eller "förra gången sade Gorm X".
5. **Inga uppföljningar.** Ingen replik kan kräva att en annan har sagts (Hades `RequiredTextLines`).
6. **Ingen budget per körning** utöver "en per rum". En lång körning med tolv strider kan ge tolv repliker.

---

## 3. Regler för oss

### 3.1 Ett urval för allt: kriterier → specificitet → prioritet → färskhet

All text som en person säger utanför de skrivna introsamtalen väljs av **en funktion** (förslag: `Lines.pick(concept,
query, profile, run)` i `src/game/lines.gd`, ren logik, testbar headless). Krönikan, borgen, värdshuset, grottan och den
levande världen ställer bara olika frågor.

1. **Koncept** (Valves "concept", vårt `kind`/`key`): vad som hände. `cave`, `fell`, `home_lost`, `idle`, `inn`,
   `gate_meet`, `world_event`, `realm_confirm` … Varje koncept har en pool repliker.
2. **Fråga** (query): en ordlista med fakta just nu, byggd av den som frågar: talare som kan svara, sällskapet, Realm,
   djup, vem som föll och mot vad, krönikans räknare, kartans steg, löftet, titeln, plus allt i minnet (3.2).
3. **Kriterier**: varje repliks `when`. Alla måste stämma (vi behöver inga "fuzzy" delpoäng; Valves `required` är
   standard hos oss).
4. **Specificitet**: poäng = antal kriterier (vikt 1 var, `weight` kan höja). Bland passande repliker väljs de med
   högst poäng. Det är Valves regel och ersätter krönikans nuvarande "specifika före allmänna". Följd: den som skriver
   en replik med fler villkor behöver inte sätta prioritet; den vinner automatiskt när den passar.
5. **Prioritetsnivå** ovanpå (Hades): `tier` = `essential` (berättelse, första gången, bossar; spelas alltid när den
   passar, före specificitet), `normal`, `filler` (får bara sägas om inget annat passar, Hades Repeatable).
   Ordning: tier först, sedan specificitet, sedan färskhet.
6. **Färskhet**: bland lika bra repliker väljs en som inte har sagts, sedan den som sades för längst sedan (mätt i
   nedstigningar, inte i samtal). Slumpen väljer bara bland lika färska. Ingen nollställning av hela poolen som i dag;
   "längst sedan" ger samma effekt utan att två repliker kan komma tätt efter en nollställning.
7. **Spärrar**: `once` (en gång per profil), `once_run` (en gång per körning), `cooldown` (minst så många
   nedstigningar sedan den sades, standard per koncept, se 3.3), `after`/`not_after` (andra id:n som måste/inte får ha
   sagts, Hades kedjor), `chance` (för vanliga lägen, Darkest Dungeons lärdom).
8. **Talare** väljs efter relevans före slump: den det handlar om (`subject`), den som var med, den vars station det är
   (Mor Elin vid fall, Hedda vid stenar, Alrik vid troféer, Gorm vid djup, Sven vid porten), Imma som reserv.
   Ingen talar om sig själv i tredje person (finns redan i `Chronicle._speaker`).
9. **En sak, en replik**: händelser om samma sak delar familj (krönikans `FAMILY`). Om krönikan och den levande världen
   båda vill säga något om att Alva föll, säger bara en av dem det.

**Varför en funktion:** då gäller minnet, budgeten och "inte samma sak två gånger" över alla system, och testerna kan
mäta upprepning i en simulering av 100 nedstigningar (3.8).

### 3.2 Minnet: vilka fakta vi ska spara

Allt nedan är fakta som replikerna får läsa i `when` och fylla i texten. Det mesta finns redan; nytt markeras **NY**.
Princip (Wildermyth): ett faktum som en replik refererar till ska också gå att se i krönikan, så att spelaren kan
känna igen det.

**Per profil (varar för alltid)**

- Nedstigningar totalt och per Realm (`descents`), djupaste djup totalt och **NY** per Realm, bossar och segrar per boss
  (`boss_wins`), första bossen, bosstroféer.
- Krönikans räknare (`chron_stats`): segrar/förluster i rad, comebacks, Realm i rad, fall per hjälte, hållna och brutna
  löften, ensamma nedstigningar.
- **NY** `last_killer`: fienden (sort och namn) som avslutade den senaste förlorade körningen, och `killers` {sort: antal}.
  Hades har `RequiredLastKilledByUnits` 57 gånger; det är det mest personliga en replik kan säga efter en förlust.
- **NY** `fell_to` {hjälte: {fiende: antal}}: vem som fällde vem. "Inkvisitorn har tagit Alva två gånger nu."
- **NY** `saved` {räddare: {räddad: antal}}: vem som helade eller väckte vem under 20 % liv. Ger par-repliker med tack.
- **NY** `first_with` {hjälte: nedstigning}: första segern tillsammans; `together` {par: nedstigningar ihop}.
- Lärjungar: när de befriades, var, av vem (`recruited`, **NY** `rescued_at` {id: {realm, djup, n}}), nedstigningar hemma
  (`home_runs`), senaste nedstigning med (**NY** `last_with` {id: n}).
- Realmens tillväxt (`growth`, `growth_last`), förvridna bossar, vilande Realms.
- Titeln och de upplåsta titlarna, och **NY** när titeln byttes (så att Gorm kan säga den nya en gång).
- Kallet och **NY** byten av kall (en replik vid altaret första gången man byter).
- Löften: valt, hållet, brutet, i rad.
- **NY** `left_early`: GÅ HEM och GE UPP (räknas, men repliker om det är aldrig hånfulla, 3.6).
- **NY** "gåvor": vi har inga gåvor i dag. Om den levande världen inför något man ger (silver till Mor Elins kök, en
  sten till Hedda), spara det per mottagare; Hades GiftTextLineSets visar att gåvan är den billigaste vägen till en
  replik som känns personlig.
- **NY** `said` {id: n}: nedstigningen då repliken senast sades (ersätter `chron_said`, `barks_used`, `narrated`,
  `inn_heard` på sikt). Ca 20 byte per replik; med 1 000 repliker under 20 kB i progress.cfg.

**Per körning** (`RunState.chron` och körningens egna fält): vem som föll och hur ofta, vem som stod kvar med lite liv,
fynd, befriade, troféer, löftet, våningsreglerna som avslöjats, elitgrupper man backade från, **NY** svåraste striden
(flest förlorade procent liv), **NY** vem som gjorde mest (krönikan har redan `deciders`).

### 3.3 Hur många repliker som behövs

En replik som sägs igen efter lång tid känns som en vana; en som sägs igen nästa körning känns som en maskin. Vi räknar
med **avstånd i nedstigningar**:

> repliker som behövs i en pool ≈ hur ofta läget inträffar per nedstigning × önskat avstånd i nedstigningar

Avståndet sätts som `cooldown` per koncept. Förslag, för 50–100 nedstigningar:

| Läge | Inträffar | Önskat avstånd | Repliker totalt i poolen | Kommentar |
|---|---|---|---|---|
| `cave` (ny våning) | 2 per nedstigning, med chans 0,4 ≈ 0,8 | 15 | ~12, fördelat på dem som brukar vara med | I dag 3–6 bara för Imma, utan minne mellan körningar |
| `elite`, `back`, `treasure` | 1–2 med chans 0,3–0,5 ≈ 0,5 | 15 | ~8 var | |
| `boss` (ser bossen) | 1, chans 1,0 | 8 | ~8 per boss + 4 allmänna | Specifika per boss vinner (specificitet) |
| `fallen` | ~0,5 | 10 | ~5 + specifika per par (Brokk om Alva …) | Par-replikerna är det som bär |
| `campfire` | ~1,5 | 15 | ~20 | Lägereld = paus; här passar längre repliker och par |
| `rare_find`, `rescue`, `new_realm` | sällan | — | 3–5 + `once`-varianter | Första gången alltid `essential`, `once` |
| Hemkomst `home_won` (standard) | ~0,6 | 15 | ~10 | Fyllnad; tier `filler` |
| Hemkomst `home_lost` | ~0,4 | 10 | ~4 per steg i 3.6 = 12 | |
| Borgens vardagsrepliker per person | 1–2 samtal per hemkomst | 10 | ~15 allmänna per person + nyheter | Nyheter `once` eller cooldown 999 efter 2 visningar |
| Värdshuset per följeslagare | ~0,5 | 10 | ~6 | |

Totalt för sju följeslagare och sex i borgen: i storleksordningen **400–600 repliker** för att klara 100 nedstigningar
med få upprepningar, ungefär dubbelt mot i dag (krönikan har 75). Det är långt från Hades 22 000, och det behövs inte:
vi har ingen röst och en kortare kampanj. Prioritera **specifika** repliker (par, bossar, fiender som fällt någon) före
fler allmänna; en specifik replik är värd fem allmänna.

**Regel för uppföljningar:** varje `essential`-replik bör ha minst en uppföljning (`after`) som kan sägas när samma sak
händer igen (andra bossegern, tredje fallet), annars blir det tyst precis när mönstret blir intressant.

### 3.4 Hur ofta någon talar (budget)

Darkest Dungeons patch visar att frekvensen avgör om det blir tjat. Förslag (vårt val):

- **Under nedstigningen:** högst en replik per rum (som i dag) **och** högst 5 per nedstigning (2 våningar, ~12
  strider), varav högst ett par-samtal per våning. Vanliga lägen har `chance` 0,3–0,5; starka (boss, fall, befrielse,
  ensam kvar) har 1,0 och går före om budgeten är slut. Inget sägs två rum i rad om inte läget är `essential`.
- **Hemkomsten:** 1 replik, 2 om händelsen har prio ≥ 44 (som krönikan i dag), 3 bara vid en `essential`-händelse
  (första bossen, förvriden boss). Den levande världen tävlar om samma platser (som `MAP_PRIO`), och mötet vid porten
  räknas in i hemkomstens budget, inte ovanpå.
- **Borgen efter hemkomsten:** varje person har högst en *nyhet* per hemkomst; den sägs första gången man pratar med
  personen, sedan kommer vardagsrepliker. Hades låter Zagreus prata med varje person en eller två gånger per körning;
  vi låter samtalet fortsätta, men nyheten kommer bara en gång.
- **Tystnad är tillåten.** Om ingen replik passar eller alla är på cooldown sägs inget. Det är bättre än en upprepning.

### 3.5 `{namn}` och `{titel}`

- **Frekvens:** ungefär **en av fem** repliker innehåller `{namn}` eller `{titel}`. Aldrig två repliker i samma ruta
  som båda använder namnet. Ett namn i *varje* rad blir som ett säljsamtal; ett namn när något viktigt händer känns
  som att bli sedd. Lägg namnet i de starka lägena (fall, boss, comeback, första hemkomsten efter en förlust).
- **Vem säger vad:** Gorm, Alrik och Sven använder `{titel}` (formellt, de är borgens folk). Imma säger `{namn}`, aldrig
  titeln utom på skämt-allvar en gång när en titel förtjänas ("Ska jag kalla dig {titel} nu? Nej."). Mor Elin säger
  namnet eller "barn"-liknande värme utan att det blir gulligt. Följeslagarna använder namnet sparsamt, Ragnhild
  formellt.
- **Titelbyte:** första gången efter att en titel valts får Gorm eller Sven en `once`-replik med den nya titeln
  (`after_title`-faktum). Repliker med `{titel}` väljs bara om titeln finns (redan så i krönikan); gör det till en regel
  i det gemensamma urvalet.
- **Kontroll:** testet för repliker (3.8) varnar om en pool har mer än 30 % namnrepliker.

### 3.6 Förlust med värdighet: tröst → följd → konkret råd

Förlusten är där spelaren mest behöver känna att någon är med, och där det är lättast att låta nedlåtande. Varje
förlust får högst tre korta steg, gärna av olika personer, i den här ordningen:

1. **Tröst** (den det angår mest; Imma eller Mor Elin om någon föll): erkänner det som hände med fakta, inte med
   floskler. "Inkvisitorn igen. Han har tagit Alva två gånger nu." Aldrig "det gör inget": det gjorde något.
2. **Följd** (den levande världen, Gorm eller Sven): vad som faktiskt ändrades, kort, utan siffror. "Kapellets folk har
   flyttat fram. Arbetarna går inte ned än." Om inget ändrades säger ingen något här.
3. **Råd** (Gorm, Stig eller Alrik, efter sin station): ett *konkret* råd byggt ur fakta, inte allmänt. Exempel på
   regler som väljer rådet (högsta som stämmer vinner):
   - Sällskapets snittnivå minst 3 under fiendernas väntade nivå (`Playtime` och `HeroStats.enemy_level` har talen) →
     Stig: gå ett djup lägre och träna ("Kryptan på djup 1 har ingenting kvar att lära dig, men den har erfarenhet.").
   - Samma fiende har fällt någon två gånger (`fell_to`) → Alrik: nämner fiendens egenskap och en trofé spelaren äger
     som svarar på den (troféns `lesson`).
   - Charges slut innan bossen (körningens fakta) → Gorm: lägereldar och att backa från vanliga grupper.
   - Ingen helning i makrona och helaren föll → Gorm vid kartbordet: makroraden "hela den som har lågt liv".
   - Inget av ovan → Gorm säger något kort och sant om att resa sig, utan råd.
   Rådet är en replik, inte en hjälpruta; hjälprutan finns redan för systemen.

**Ton efter förlust:** allvarlig och varm, aldrig skämt på spelarens bekostnad, aldrig skuld. Imma får vara torr, men
efter en förlust är hon torr *om fienden*, inte om spelaren. Efter tre förluster i rad (`loss_streak` ≥ 3) väljs bara
tröst + råd, ingen följd (spelaren vet redan att det går dåligt). Efter en comeback (seger efter ≥ 3 förluster) är det en
`essential`-händelse som minns förlusterna: "Tre gånger gick vi hem utan honom. Inte i kväll."

**GÅ HEM och GE UPP** är inte nederlag i replikerna: "Bra att ni vände" är rätt ton. Bara om man går hem tre gånger i
rad från samma våning får Stig säga något om förberedelse.

### 3.7 Ton och innehåll

- **Fienderna får vara hur ockulta och onda som helst** (kulter, nekromanti, pakter). Spelarens sida, Paladinen,
  följeslagarna, kallen och borgens folk utövar det aldrig och sluter inga pakter. En replik om en trofé från en
  ockult fiende talar om den som besegrad eller bruten, eller som en lärdom (som troféernas `lesson`).
- Allvarlig och varm, inte tramsig. Humor finns i karaktärerna (Immas torrhet, Svens skvaller), aldrig i att förminska
  döden eller spelaren.
- Ragnhild citerar bara 1917 års kyrkobibel, ordagrant och kontrollerat (`ref`); aldrig för att förlöjliga tron.
- Repliker refererar bara till sådant som spelaren kan ha sett. Om en replik säger "Inkvisitorn" måste spelaren ha
  mött Inkvisitorn, och helst ska det stå i krönikan.
- Folk har egna liv: en del vardagsrepliker handlar inte om spelaren alls (Hedda och en trög bälg). Det gör att
  repliker *om* spelaren väger mer.

### 3.8 Kontroll: testa upprepning innan spelaren gör det

- Ett headless-test (senare, när datorn tål det) kör `Lines.pick` genom en simulerad karriär på 100 nedstigningar
  (karriärbotarna i `tests/soak.gd` har redan utfallen) och rapporterar per koncept och talare: hur många repliker
  som sagts, kortaste avstånd mellan två visningar av samma replik, och lägen där ingenting passade. Mål: inget
  `normal`/`filler` igen inom sin cooldown, och färre än 10 % tysta lägen för starka händelser.
- Ett datatest: alla id:n unika och stabila, varje `after` pekar på ett id som finns, inga `{titel}`-repliker utan
  reserv, högst 30 % namnrepliker per pool, alla talare finns i `people` eller `heroes`.

---

## 4. Dataformat: en utvidgning av `dialog.json`

Bakåtkompatibelt: en sträng eller `{id, text}` betyder som i dag "inga villkor, tier normal, standard-cooldown för
konceptet". Allt nytt är valfria fält på repliken. Befintliga block (`barks`, `pairs`, `inn`, `people.*.idle`,
`chronicle.lines`, `living_map`) läses av samma urval genom en liten adapter, så inget behöver flyttas på en gång.

```jsonc
{
  "id": "brokk_fallen_alva_2",          // stabilt, för minnet och eventuella röster
  "concept": "fallen",                   // underförstått av blocket (barks.brokk.fallen) om det saknas
  "who": "brokk",                        // talare: id, "subject" (den det handlar om) eller "any_party"
  "text": "Andra gången, Alva. Jag står närmare nästa gång.",
  "when": {                              // alla måste stämma; antalet = specificitet
    "subject": "alva",
    "fell_count_at_least": {"alva": 2},
    "realm": "chapel"
  },
  "tier": "normal",                      // "essential" | "normal" | "filler"
  "weight": 1,                           // extra specificitet om en villkorsnyckel väger mer
  "once": false,                         // en gång per profil
  "once_run": false,                     // en gång per körning
  "cooldown": 10,                        // minst så många nedstigningar sedan senast (standard per koncept)
  "chance": 1.0,                         // för vanliga lägen 0.3–0.5
  "after": ["brokk_fallen_alva_1"],      // måste ha sagts (Hades RequiredTextLines)
  "not_after": [],                       // får inte ha sagts (RequiredFalseTextLines)
  "family": "fell",                      // en sak, en replik (krönikans FAMILY)
  "sets": {"brokk_vowed_alva": true},    // fakta som skrivs i minnet när repliken sägs (Valve)
  "lines": [["alva", "Det vet jag."]]    // valfritt svar: ett kort par-samtal efter repliken
}
```

**Standard per koncept** står på ett ställe, så att författaren inte behöver skriva det på varje rad:

```jsonc
"concepts": {
  "cave":     {"cooldown": 15, "chance": 0.4, "budget": "run"},
  "fallen":   {"cooldown": 10, "chance": 1.0, "budget": "run"},
  "home_won": {"cooldown": 15, "tier": "filler", "budget": "home"},
  "home_lost":{"cooldown": 10, "budget": "home", "steps": ["comfort", "consequence", "advice"]},
  "idle":     {"cooldown": 10, "budget": "talk"}
}
```

**Namngivna villkor** (Hades II:s `NamedRequirementsData`): återkommande kombinationer skrivs en gång och används som
`"when": {"cond": "lost_twice_to_same"}`; `"any": [{…}, {…}]` ger eller-grupper. Ett namngivet villkor räknas som lika
många kriterier som det innehåller, så specificiteten blir rätt.

```jsonc
"conditions": {
  "small_party":         {"party_size_at_most": 2},
  "lost_twice_to_same":  {"loss_streak_at_least": 2, "fact": "same_killer"},
  "long_apart":          {"home_runs_at_least": 3}
}
```

**Nya villkorsnycklar** (utöver dagens `recruited`, `boss`, `min_descents`, `min_best_depth`, `seen_realm`,
`min_bosses`, `intro_done`): `realm`, `depth_at_least`, `subject`, `in_party`, `not_in_party`, `fell_count_at_least`,
`fell_to` (fiende), `last_killer`, `saved_by`, `together_at_least`, `loss_streak_at_least`, `win_streak_at_least`,
`comeback`, `growth_at_least` {realm: steg}, `title` (någon / ett id), `vow`, `vow_result`, `home_runs_at_least`,
`level_gap_at_least` (fiender över sällskapet), `step` (för förlustens tre steg), `fact` (ett faktum som `sets` har
skrivit). Platshållare utöver dagens: `{fiende}` (senaste fällaren), `{räddare}`, `{gånger}` (finns som `TIMES`).

**Minnet** i `Profile`: `said` {id: nedstigning}, `facts` {nyckel: värde} för `sets`, plus de nya räknarna i 3.2.

---

## 5. Byggordning, från litet till stort

1. **Minne mellan körningar för grottans repliker** (litet, störst effekt mot upprepning). `Profile.said` {id: n};
   `Dialog.bark` jämför id och hoppar över repliker med `n − said[id] < cooldown` (standard 10–15). Behåll
   `barks_used` som spärr inom körningen. Ge replikerna utan id ett id i datan.
2. **Nyheter i borgen pensioneras.** `idle_line`: en `when`-replik sägs högst två gånger (eller `once`), sedan går den
   till vila; nyheten sägs först i första samtalet efter hemkomsten och aldrig mer än en per person och hemkomst.
3. **Budget och chans under nedstigningen.** Högst 5 repliker per nedstigning, `chance` per läge, inga två rum i rad
   utom starka lägen.
4. **De nya fakta i krönikan:** `last_killer`, `fell_to`, `saved`, `together`, `rescued_at`, `last_with` (i
   `Chronicle.note_battle`/`end`; striden har redan händelserna). Inga nya repliker behövs för att spara dem.
5. **Förlustens tre steg** med råd ur fakta (3.6). Börja med 4 råd-regler och 6–8 tröstrepliker; det är den del av
   spelet där en replik betyder mest.
6. **Det gemensamma urvalet `Lines.pick`** med specificitet, tier, färskhet, `after`/`not_after`, `sets`. Krönikan går
   över först (den ligger närmast), sedan grottan, borgen och värdshuset. Den levande världen byggs direkt mot det om
   tidsplanen tillåter; annars följer den åtminstone reglerna: samma `said`, samma budget i hemkomstrutan, `family` mot
   dubbletter, talare efter relevans.
7. **Specifika repliker i bulk:** par (vem räddade vem, vem föll bredvid vem), per boss och per elitfiende som fällt
   någon, per Realm-tillväxt. Beställs gärna hos ChatGPT med id:n och villkor i tabell (som `repliker-v2.tsv`),
   granskas mot 3.7.
8. **Repliktestet** (3.8): datatestet direkt, karriärsimuleringen när datorn tål Godot-körningar.

Ordningen följer ledstjärnan: punkt 1–3 gör att det som finns slutar upprepa sig, 4–5 gör att det som sägs blir sant
och personligt, 6–8 gör att det går att skriva mycket mer utan att det blir rörigt.

---

## Källor

- GDC Vault: Kasavin och Korb, "Breathing Life into Greek Myth: The Dialogue of Hades" (GDC 2021, 22 000+ repliker):
  https://gdcvault.com/play/1026975/Breathing-Life-into-Greek-Myth
- Nintendo Wire, Hades ord och repliker per person: https://nintendowire.com/news/2020/12/30/hades-has-over-300000-words-of-voiced-dialogue-heres-a-handy-breakdown-of-who-speaks-most-and-least/
- Videlais, referat av Kasavin i Eggplant (en eller två repliker per person och körning): https://videlais.com/page/57
- Hades skript (spegling): `Narrative.lua` (`IsTextLineEligible`, `PlayRandomRemainingTextLines`),
  `NPCData.lua` (fälträkningen ovan), `AudioScripts.lua` (cooldowns, `SuccessiveChanceToPlay`):
  https://github.com/crazytuzi/LuaFramework/tree/master/Hades
- Hades II: Inverse-recensionen https://www.inverse.com/gaming/hades-2-review ; GamingBolt
  https://gamingbolt.com/hades-2-review-supergiant-raises-the-rogue-lite-bar ; GameGeeker
  https://gamegeeker.com/games/hades-ii/review?market=US ; PC Gamer om den varma källan
  https://pcgamer.com/hades-2-hot-springs-guide ; Dot Esports https://dotesports.com/hades/news/hades-2-how-to-use-the-hot-spring ;
  Exitlag om Nemesis https://www.exitlag.com/blog/nemesis-hades-2/ ; Backloggd-användare (anekdotiskt)
  https://backloggd.com/u/TheDarkestLink/ ; Steam-tråd om ettans upprepning
  https://steamcommunity.com/app/1145360/discussions/0/2987539784417139179 ; villkorsformatet i
  https://github.com/NikkelM/Hades-II-HadesBiomes (`src/Scripts/RequirementsData.lua`)
- Elan Ruskin, "AI-driven Dynamic Dialog through Fuzzy Pattern Matching. Empower Your Writers!" (GDC 2012):
  https://www.gdcvault.com/play/1015528/AI-driven-Dynamic-Dialog-through
- Emily Short, referat av Ruskins föredrag: https://emshort.blog/2012/03/16/gdc-2012-talk-on-dynamic-dialogue/
- Valve Developer Community, Response System, Criteria (poäng och vikt), Response (`norepeat`, `permitrepeats`,
  `respeakdelay`): https://developer.valvesoftware.com/wiki/Response_System ,
  https://developer.valvesoftware.com/wiki/Criteria , https://developer.valvesoftware.com/wiki/Response
- Game Developer, "Creating Behaviours with Fuzzy Pattern Matching": https://www.gamedeveloper.com/game-platforms/creating-behaviours-with-fuzzy-pattern-matching
- GameSpot, "The Gothic Sensibilities of Darkest Dungeon": https://www.gamespot.com/articles/the-gothic-sensibilities-of-darkest-dungeon/1100-6424880/
- Darkest Dungeon-wikin, patch 21 juni 2017 (helningsrepliker mer sällan): https://darkestdungeon.wiki.gg/wiki/21_June_2017_Patch
- Siliconera, Everything Burns (stadshändelsernas frekvens i inställningarna): https://www.siliconera.com/not-even-hamlet-safe-everything-burns-update-darkest-dungeon/
- Quarter to Three, spelare om berättarens upprepning: https://forum.quartertothree.com/t/darkest-dungeon/73511?page=14
- Siralim Ultimate, utvecklarnas fästa inlägg på Steam (samtal med varelserna): https://steamcommunity.com/app/1289810/discussions/0/4164113537231972561
- Wildermyth-wikin, History: https://wildermyth.com/wiki/History

Inte kontrollerat: Ruskins bilder (sidan crashworks.org svarar inte längre); exakta antal regler i Left 4 Dead 2;
Siralims slott-NPC:ers urval. Hades-siffrorna ovan är räknade av oss i spelets skript och kan skilja något mellan
versioner.
