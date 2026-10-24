# Bossar och fiendevariation i andra spel (research, 2026-10-24)

Underlag till `docs/plan/mot-upprepning.md` och `docs/plan/varslade-attacker.md`. Fortsättning på
`docs/research/variation-i-strid.md`, som redan täcker Slay the Spires strider, Darkest Dungeons strider, FFX, FFXIII,
Octopath, Into the Breachs strider, Siralim, Star Rail och FFXII. Här: **bossar, fiendevariation och kartor**, och vad som
går att översätta till turordning på Siralims tidslinje med makron, utan rörelse. Inget är beslutat; VD bestämmer.

Märkning:
- **SÄKERT** = wiki eller utvecklaren (källa i slutet)
- **TROLIGT** = guider eller flera spelare
- **MINNE** = allmänt känt om spelet, inte kontrollerat i dag
- **GISSNING** = min bedömning
- ⚙ = kräver ny kod (S liten, M mellan, L stor). Utan ⚙ räcker dagens egenskaper, auror, regler och föremål.

Grundregel från förra rapporten, som gäller allt nedan: **allt makrona inte kan läsa gör att spelaren stänger av
automatiken.** Varje idé ska därför ha ett svar som går att skriva som en makrorad eller göras som ett trofébyte vid lägerelden.

## Kort

Spelen som håller fräscht länge gör det på fyra sätt:

1. **Ett litet språk av varningar som återkommer** (FFXIV:s markörer, Monster Hunters tecken). Spelaren lär sig orden en
   gång; varje ny boss blandar dem på ett nytt sätt.
2. **Kombinationer i stället för innehåll** (PoE:s kartmods, Diablos affix, Hades heat). Tio regler ger hundratals strider.
3. **Spelaren väljer svårigheten själv och får något för det** (Hades, PoE, Diablo IV:s sigill). Svårt blir en utmaning,
   inte ett straff.
4. **Hot som syns på kartan och gör vägen till ett beslut** (Etrians FOE, Darkest Dungeons ljus, Slay the Spires karta).

Vi har redan en del av 2 och 3 (instabilitet, motdrag, glödande varianter) och har planerat mer (affix, tecken,
bossrotation). Det som saknas helt är **1** (ett återkommande varningsspråk för bossarna) och kartans **rörliga hot**.

## 1. Spel för spel

### Final Fantasy XIV (räder och trials)
- Bossarna följer ett **fast manus** (timeline): samma anfall i samma ordning varje gång. Svårigheten ligger i att utföra,
  inte i att gissa. MINNE.
- Varningarna är ett **delat språk** över hela spelet: tankslag (röd ring med pil, mot den med mest hot), samlingsmarkör
  (skadan delas av alla inom ringen; står ingen där dör målet), spridning, torn (för få spelare i tornet = skada på alla),
  flare (målet springer bort). SÄKERT (consolegameswiki, Common mechanics and markers).
- Svåra versioner (Extreme, Savage) använder samma markörer men **tätare och i nya kombinationer**. MINNE.
- **Låna:**
  - **Ett markörspråk för våra laddningar** (varslade-attacker §1): fyra former som återkommer hos alla bossar.
    *Tankslag* (följer hån, Försvara halverar), *Samlas* (skadan delas mellan alla som Försvarar den turen; ingen
    Försvarar = målet tar allt), *Sprid* (träffar alla, dubbelt på den som Försvarar bredvid en annan – i vår tid: den som
    står närmast på tidslinjen), *Torn* (minst två hjältar måste Försvara före släppet, annars skada på alla). Varje form är
    ett makrovillkor ("laddar Samlas → Försvara"). ⚙S per form när laddningen finns.
  - **Manus synligt i Inspect** ("tur 3: Benstorm, tur 6: Dödsdom"). Regler med `every` finns redan; att visa dem är ⚙S.

### Path of Exile (kartor, bossfaser, ligamekaniker)
- Varje karta har **slumpade modifierare** (t.ex. monster reflekterar skada, spelaren kan inte regenerera); svårare mods ger
  mer byte. Spelarna **slumpar om** de mods som gör deras bygge omöjligt. SÄKERT/TROLIGT (poewiki, Maxroll).
- Bossarna har **faser** med nya anfall och ofta en arena som ändras. MINNE.
- **Ligamekaniker** är frivilliga inslag inne i kartan: Breach (en spricka man aktiverar), Delirium (en dimma som gör
  fienderna starkare ju längre man går; man kan sluta när som helst), Ritual (döda allt runt en totem, sedan väcks kopior
  av det man har dödat). Gemensamt: **spelaren väljer när och hur länge**. TROLIGT (poe-vault, poe2wiki).
- **Låna:**
  - **Instabiliteten som en meny**: man ser varje regel och dess silver, och kan slumpa om en regel för silver. Det är
    PoE:s kartmods och Siralims Realm Properties. ⚙S i kampanjkartan.
  - **Gravkoret** (Ritual i vår ton): ett föremål på våning 2 där sällskapet kan möta **ekon av två grupper man redan har
    besegrat på våningen**, som ett bossmöte, för en extra trofé och material. Frivilligt. ⚙M (mötet byggs av körningens
    loggade grupper).

### Diablo III och IV (elitaffix, riftar, mardrömsfängelsehålor)
- **Elitaffix**: championpaket delar samma affix (Molten lämnar eld efter sig och exploderar vid döden, Frozen, Jailer
  låser fast, Arcane Enchanted). Vissa affix får **aldrig** komma ihop (listor över uteslutningar). Antalet affix växer med
  nivån. SÄKERT/TROLIGT (diablowiki, Maxroll).
- **Nephalem-riftar** (D3): slumpad miljö, slumpad monsterblandning och en **riftväktare ur en pool**, som dyker upp när en
  mätare har fyllts av dödade fiender. MINNE.
- **Mardrömssigill** (D4): ett sigill ger fängelsehålan **en positiv och två till fyra negativa** affix, fler på högre
  nivå. TROLIGT (windowscentral, gamerguides; poolen byts per säsong).
- **Låna:**
  - **Affix med uteslutningslista** (redan i mot-upprepning §4); Diablo bekräftar att `excludes` behövs från början.
    Nya affix i Diablos anda: *Glödande* (dör ledaren får den som dödade den Förbränd två turer, i stället för eld på
    golvet) ⚙S, *Fängslare* (den första hjälten på tidslinjen blir Snärjd vid stridens början) – data (`battle_start` +
    aura).
  - **Sigillet** för djupets tecken: alltid **en gåva och en last** (t.ex. "Helig mark" + "Tunga kistor"), synliga före
    avfärd. ⚙S, bygger på tecknen.
  - **Väktaren ur en pool**: en sällsynt nedstigning där bossen är en vandrande väktare (se Siralims Zantai nedan).

### Monster Hunter
- Varje monster har en **identitet i beteendet**: tecken före de stora anfallen, ett vredgat läge (snabbare, starkare,
  ibland nya anfall) och ett **utmattat** läge (längre uppladdning, fler öppningar). De kan inte vara båda samtidigt.
  TROLIGT (mp1st, Steam-trådar).
- **Delbrott**: slår man sönder en del får man byte, och ibland förlorar monstret ett anfall (Rathians svans och giftet;
  Barroths krona hindrar ny vrede). TROLIGT.
- **Låna:**
  - **Delbrott på bossen**: när bossen har tagit X skada av en viss sort (besvärjelser, eller anfall) bryts en del; den
    förlorar en förmåga för resten av striden och tappar ett material (t.ex. Benfurstens krona: inga fler Väck de döda).
    Makrot svarar med vilken sorts skada man lägger. ⚙S (räknare per skadetyp, som stagger).
  - **Utmattning efter vreden**: efter två släppta laddningar blir bossen *Utmattad* en tur (+25 % skada tagen, ingen
    laddning). Det belönar att man överlever, inte bara att man bryter. ⚙S, aura + räknare.

### Dark Souls och Elden Ring
- Bossens **identitet** bärs av få men tydliga saker: ett namn över mätaren, en egen arena, egen musik, ett eller två
  anfall man minns, och en **andra fas** där bossen förändras synligt och får ett nytt anfall. MINNE.
- Många bossar är **frivilliga**, och samma figur kan återkomma i en ny form senare (Margit och Morgott). MINNE.
- **Låna:**
  - **Fas 2 ska synas och höras**: namnet byter rad ("Benfursten, vredgad"), musiken skiftar, modellen får sken (`glow`
    finns). Mest presentation. ⚙S i `battle.gd`.
  - **Den återkommande figuren**: en elitfiende som flyr vid 30 % liv i våning 1 och möts igen som boss senare. Passar
    berättelsen (kronans avsändare). ⚙S (en flyktregel), resten data.

### Hades och Hades II
- **Pact of Punishment** (I): ett tiotal villkor med flera grader, var och en med heat; man väljer själv vilka. Belöningar
  ges första gången man klarar en viss heat med ett visst vapen. TROLIGT (primagames, rpgsite).
- **Extreme Measures** ändrar bossarnas **mekanik**, inte bara siffror: alla tre Furierna i samma strid (en leder, två
  stödjer med några få anfall och kan inte skadas), Hydran i en mindre arena, Theseus i en stridsvagn, en tredje fas hos
  Hades. TROLIGT (pcinvasion, trueachievements).
- **Bossrotation från första körningen**: den första bossen är en av tre Furier, slumpad. MINNE.
- Hades II: **Oath of the Unseen** med ~16 löften; *Vow of Rivals* lägger en rival bredvid regionens väktare. TROLIGT
  (Hades Wiki, game8; antal och värden skiljer mellan källor).
- **Låna:**
  - **Furie-trion**: ett bossmöte med tre ur samma familj där en slumpad leder och de två andra stödjer med 1–2 handlingar
    och är oskadliga tills ledaren faller. Tre strider ur samma figurer. Data + ⚙S (`invulnerable_support`, nära
    `immune_while_ally_kind`).
  - **Svår form per boss** (Extreme Measures): efter tre segrar kan spelaren slå på bossens svåra form på kampanjkartan.
    Den ändrar en mekanik (Benfursten: Dödsdom blir Samlas; biskopen: två kanaliserande kultister). Belöning: bosstrofén
    får en andra rad. ⚙S–M.
  - **Rivalen** (Vow of Rivals): ett löfte (0.30.17 har löften) som lägger en Nemesis bredvid bossen. Data i `vows.json` +
    ⚙S.

### Persona 5 och Shin Megami Tensei
- **Press Turn** (SMT): träffar man en svaghet får man en halv extra tur; missar man eller slår mot immunitet eller
  reflektion förlorar man turer. **Fienderna har samma regel.** Bossar har ofta flera turer per runda. SÄKERT (megatenwiki).
- Persona: svaghet ger *One More*, alla nere ger *All-Out Attack*. MINNE.
- **Låna** (försiktigt; Siralim har inga elementsvagheter):
  - **Bossen med två brickor**: en boss som står på tidslinjen två gånger (SMT:s extra press turns). Gör den svårare utan
    mer liv, och makrona läser det redan via tidslinjevillkoren. ⚙M (en enhet, två platser).
  - **Reflektion som straff mot fel svar** finns (Spegelsköld, Taggig); SMT visar att straffet ska stå tydligt i Inspect
    innan man slår. Inget nytt.
  - Avråder: svagheter som ger extra turer. Det blir lås, och vi har redan Sårbar.

### Dragon Quest
- Monstren har **fasta, läsbara roller** i grupperna: Healslime helar de andra, Metal Slime flyr snabbt men ger enorm
  erfarenhet och tål nästan ingen skada. Gruppen blir pusslet, inte monstret. MINNE.
- **Låna:** **Silverbenet** (Metal Slime): en sällsynt grupp i grottan som flyr efter två turer, har hög Defense men lite
  liv och ger tredubbel erfarenhet. Samma idé som Skattgolemen (`nya-grottor.md` E), men som en vanlig ruta utan
  specialvåning. ⚙S (flyktregel).

### Pokémon
- **Gymmen har teman** (en typ), så spelaren vet vad som väntar och bygger laget därefter. Elite Four testar bredd.
  Återmatcher ger starkare lag. MINNE.
- **Låna:** **Tema per elitgrupp, synligt i ryktet**: Sven eller Gorm säger före avfärd vad Nemesis har ("kylan biter
  där nere" = Frusen-tema). Det är ledstjärnans fråga: man byter trofé innan man går. Data i `dialog.json`, ⚙S för att
  välja repliken efter den dragna gruppen.

### Chrono Trigger
- **Magus byter barriär**: han är bara sårbar för ett element i taget, och ett fysiskt slag får honom att byta. MINNE,
  TROLIGT (fan-wikis).
- Bossar med **delar som återuppstår** om man inte dödar dem i rätt ordning (Guardian och dess Bits). MINNE.
- **Låna:** **Skiftande sköld**: bossen tar halv skada från den sort (anfall/besvärjelse) som senast träffade den. Tvingar
  fram blandade makron, som Stenhjärta men läsbart med en ikon. ⚙S (`modify_damage_taken` med villkor på senaste skadetyp).

### Siralim Ultimate (förebilden, bara det nya)
- **Nether Bosses** var femte nivå efter berättelsen, bakom portaler. **Zantai** är en slumpad boss med **tre slumpade
  bossegenskaper** från de vanliga bossarna. **Gate of the Gods**: gudarna har regler i striden (skadas bara efter fem
  debuffar, inga besvärjelser). TROLIGT (Steam-trådar, siralimultimate.wiki.gg).
- **Låna:** **Vandraren (Zantai)**: en sällsynt boss i vilken Realm som helst, med tre egenskaper dragna ur våra andra
  bossars egenskaper (Benfurstens vrede, biskopens sköld, Stenhjärta …). Nästan bara data, eftersom egenskaperna finns.
  ⚙S (dra tre ur en lista, utesluta krockar).

### Legend of Grimrock och Etrian Odyssey
- **FOE** (Etrian): starka fiender som **syns på kartan och rör sig när du rör dig** – i cirklar, fram och tillbaka på en
  linje, eller mot dig när de ser dig. Vissa rör sig bara vartannat steg. Man lär sig mönstret och går runt. Står en FOE
  nära en strid ansluter den efter några turer. SÄKERT/TROLIGT (etrian.fandom, dungeoncrawlers.org).
- Grimrock: rutnät, tryckplattor, hemliga knappar, fiender man dansar runt. MINNE.
- **Låna:**
  - **Den vandrande gruppen**: en elitgrupp per våning (från djup 2) som rör sig ett steg per två steg spelaren tar, på en
    fast patrull (en linje eller ring). Den syns bara på sedda rutor. Strid bredvid den = den ansluter efter tre turer
    (förstärkning). ⚙M (Grotto + RunState + förstärkning i striden).
  - **Dold nisch** (Grimrocks knappar): Gravregistret kan avslöja en nisch med en skatt i en vägg. Data i `objects.json`.

### Wildermyth
- **Kalamiteter**: med tiden och efter varje strid dras kort som ger fienderna nya fiendetyper, förmågor och stats. Vissa
  kan avvärjas. Varje fiendefolk har egna kort. SÄKERT/TROLIGT (wildermyth.com wiki, utvecklarens dagbok).
- **Låna:** **Fördärvets kort**: varje gång man går till en annan Realm drar den Realm man lämnar ett kort ("Benfolket har
  lärt sig Flockbett av vargarna": en egenskap på en fiendetyp). Korten syns på kampanjkartan och nollställs när man klarar
  Realmen på det djupet. Passar den levande kartan. ⚙S, korten är data.

### Battle Brothers
- Varje fraktion har **spawnlistor** med fasta sammansättningar; **champions** bär namngivna föremål; **legendariska
  platser** kräver ett eget bygge; sent i spelet kommer en **kris** (adelns fejd, grönhudarnas invasion, de odöda) som
  ändrar hela världen en tid. TROLIGT (Steam-trådar).
- **Låna:** **Krisen som period**: en världshändelse som gäller i tre nedstigningar ("Benfolkets vandring": en grupp ur
  kryptan på varje våning i alla Realms). Det är mot-upprepning §2e i en form med början och slut. ⚙S (`world_events.json`
  finns).

### Inscryption
- Varje boss i akt 1 har **två faser där fas 2 ändrar spelplanens regel**: Prospector gör dina kort till guldklumpar,
  Angler krokar dina kort, Trapper gör döda kort till pälsar som Trader sedan byter. Slutbossen **lånar de tidigare
  bossarnas masker**. TROLIGT (pcinvasion, techraptor).
- **Låna:**
  - **Fas 2 som ändrar spelarens resurs, inte bossens siffror**: Klockaren i fas 2 skickar alla hjältar ned på
    tidslinjen; Bergakungen förvandlar den svagaste hjälten till sten tills någon slår på stenen. Data i `phases`
    (varslade-attacker §3), ⚙S per effekt.
  - **Kronans bärare med masker**: den sista bossen i berättelsen (avsändaren bakom kronan) lånar en mekanik från varje
    Realmboss man har besegrat. Det knyter berättelsen och belönar minnet. ⚙M, långt fram.

## 2. Mot upprepning: hur de håller den femtionde körningen fräsch

### Fyra modeller

| Spel | Mekanism | Varför det håller |
|---|---|---|
| Hades | Spelaren väljer namngivna villkor med grader; bossarna får nya mekaniker i grader | Valet är spelarens; belöning första gången per kombination; bossen *ändras* |
| Path of Exile | Slumpade kartmods, mer byte för svårare; omslumpning | Kombinatorik; spelaren kan slippa det som omöjliggör bygget |
| Diablo | Affix på elitpaket, uteslutningar; sigill med gåva + last | Tusentals par av samma få monster; positiv sida gör det lockande |
| Etrian | FOE syns, rör sig i mönster, kan undvikas | Kartan har ett hot man lär sig och planerar runt |

### Principer (GISSNING, dragna ur de fyra)
1. **Kombination före innehåll.** Ingen av dem gör hundra nya bossar; de gör tio regler som går att blanda.
2. **Synligt före avfärd.** Hades visar villkoren, PoE och Diablo skriver mods på kartan och sigillet. Siralims Nemesis
   har varningstext. Hos oss: elitkortet, kampanjkartan, Svens rykte.
3. **Ändra svaret, inte siffran.** De minnesvärda modsen (reflektion, ingen regenerering, Extreme Measures) tvingar fram
   en annan plan. Rena "+40 % liv" glöms.
4. **Spelaren väljer risken och får något för det.** Annars blir upprepningen ett straff.
5. **Belöning första gången per kombination.** Hades (vapen × heat), vi (Realm × djup ger perk-poäng). Utöka till
   boss × svår form.
6. **Uteslutningar.** Diablo stänger vissa par; utan det blir vissa kombinationer omöjliga eller triviala.

### Översatt till oss

**Elitaffix** (mot-upprepning §4 står fast). Tillägg från Diablo och FFXIV:
| Affix | Regel | Svar i makrot | Kod |
|---|---|---|---|
| Glödande | Den som dödar ledaren blir Förbränd 2 turer | döda ledaren med den som har Barriär | ⚙S |
| Fängslare | Första hjälten på tidslinjen blir Snärjd vid stridens början | Försvara först, rensa | data |
| Tornvakt | Ledaren laddar ett Torn (minst två Försvarar) var fjärde tur | "laddar Torn → Försvara" | ⚙S efter laddningen |
| Skiftande | Halv skada från den sort som senast träffade | blanda anfall och förmåga | ⚙S |

**Djupets tecken som sigill**: en gåva och en last, synliga på kampanjkartan, slumpa om en gång för silver. Gåvan gör att
spelaren *vill* ha tecknet, inte bara tål det.

**Roterande bossar**: Hades visar att rotationen ska börja tidigt, inte först på djup 3. Kombinera mot-upprepning §1
(bosslista per djup) med Furie-trion: ett av de tre bossmötena per Realm är en trio där ledaren slumpas. Exempel kapellet:
biskopen, Abbedissan och Inkvisitorn; en leder, de andra kastar varsin förmåga och är oskadliga. Tre strider av en.

**Svår form**: efter tre segrar mot en boss (samma räknare som bosstrofén) kan spelaren slå på dess svåra form. Den byter
en mekanik och ger bosstrofén en andra rad. Det ger djupväggens träning (djup 4–6) något nytt att jaga.

**Grottan**: Etrians vandrande grupp och PoE:s frivilliga inslag (Gravkoret) gör att två våningar med samma recept ändå
spelas olika. Se §3.

## 3. Grottans variation utan stora ändringar

Utgångsläget: 8×8 med dimma, en quest per våning, rykten och spår (0.30.22). Allt nedan behåller rutnätet och reglerna i
`Grotto.problems()`; det mesta är föremål eller en ny sorts ruta.

| Idé | Förebild | Vad spelaren gör | Kod |
|---|---|---|---|
| **Vandrande grupp** | Etrians FOE | Ser en patrull, väntar ut den eller tar den; strid bredvid = förstärkning | ⚙M |
| **Facklan** | Darkest Dungeons ljus | Varje nytt steg kostar ljus; lågt ljus = bättre fynd men grupper kan överraska (ingen förvarning på kortet) | ⚙M |
| **Brinnande elit** | Slay the Spires brinnande elit (emerald key) | En elitgrupp per våning glöder: svårare (ett affix till), men ger ett sällsynt material | data + ⚙S |
| **Belöning på dörren** | Hades (belöningen syns på dörren) | En sedd grupp visar på kortet vilken sorts trofé eller fynd den lämnar, så vägen väljs efter belöning | ⚙S (kortet finns) |
| **Nedräkning på kartan** | Into the Breach (varslade hot) | "Klockan ringer om 6 steg": då vaknar en sovande grupp eller en ny grupp kliver in. Syns som en siffra | ⚙S |
| **Frivillig utmaning** | PoE:s Ritual och Delirium | Gravkoret: ekon av två besegrade grupper som ett bossmöte, för trofé och material | ⚙M |
| **Lås och nyckel** | Dungelot (nycklar, låsta rutor) | En bevakad kista öppnas bara med nyckeln från en annan grupp | data + ⚙S |
| **Dold nisch** | Grimrock | Gravregistret avslöjar en nisch i bergssidan | data |
| **Hela vägen i förväg** | Slay the Spires karta | Våning 1 utan dimma ibland (Väktarsalen, nya-grottor E) | receptet |

Kommentarer (GISSNING):
- **Vandrande grupp** är den största förändringen i känsla för minst kod i kartan: grottan blir levande utan att
  rutnätet ändras. Risken är att den känns som slump om patrullen inte syns. Därför: patrullens linje ritas som en
  streckad tuschlinje så fort man har sett gruppen en gång.
- **Facklan** är Darkest Dungeons starkaste kartidé men krockar med att vi vill ha färre tomma tryck. Prova den bara som
  djupets tecken ("Mörkt djup"), inte på varje våning (samma slutsats som nya-grottor E).
- **Belöning på dörren** och **brinnande elit** är billigast och svarar direkt på problemet i nya-grottor §1.1 (att raka
  av grottan är rätt drag): när man ser vad en grupp ger väljer man, i stället för att ta allt.
- **Nedräkning** ger ett skäl att gå vidare, utan att straffa den som vill rensa: den som stannar får en strid till, inte
  en förlust.

## 4. Topp 10 (effekt per insats, GISSNING)

Markerat **ny** = finns inte i dagens planer; **stärker** = bekräftar och preciserar ett förslag i mot-upprepning eller
varslade-attacker.

1. **Markörspråket** (FFXIV, ny). Fyra laddningsformer (Tankslag, Samlas, Sprid, Torn) som alla bossar och elitfiender
   delar, var och en ett makrovillkor. Lär en gång, kombineras hela spelet. ⚙S per form ovanpå laddningen (som inte är
   byggd). Insats: ½ dag per form efter laddningen.
2. **Belöning på kortet** (Hades, ny). Elitkortet och vanliga gruppkort visar vad gruppen lämnar (troféns sällsynthet,
   material). Gör vägen till ett val och angriper "raka av allt". ⚙S, ½ dag.
3. **Sigillet: gåva + last** (Diablo IV, PoE, stärker §3). Djupets tecken alltid i par, synligt, omslumpning för silver.
   ⚙S ovanpå tecknen, ½ dag.
4. **Vandraren** (Siralims Zantai, ny). En sällsynt boss med tre egenskaper ur andra bossar. Nästan bara data. ⚙S, ½–1 dag
   inklusive uteslutningar och botmätning.
5. **Furie-trion** (Hades, stärker §1). Ett av bossmötena per Realm är tre ur samma familj, slumpad ledare, två oskadliga
   stödjare. ⚙S (`invulnerable_support`) + data, 1 dag.
6. **Svår form per boss** (Extreme Measures, ny). Efter tre segrar; byter en mekanik, ger bosstrofén en andra rad. ⚙S–M,
   1–2 dagar (kräver faser eller laddning för att ha något att byta).
7. **Delbrott och utmattning** (Monster Hunter, ny). Bossen förlorar en förmåga efter X skada av en viss sort; utmattad
   efter två släppta laddningar. ⚙S, 1 dag. Bra andra steg efter stagger.
8. **Fas 2 som ändrar spelarens resurs** (Inscryption, Elden Ring, stärker varslade §3). Data i `phases`; synlig och
   hörbar fasväxling. ⚙S per effekt när `phases` finns.
9. **Vandrande grupp** (Etrian, ny). En patrullerande elit per våning från djup 2 som kan förstärka strider. ⚙M, 2–3 dagar.
10. **Fördärvets kort** (Wildermyth, ny). Realmen man lämnar drar ett kort som ger en fiendetyp en egenskap; nollställs när
    man klarar den. Den levande kartan får tänder. ⚙S + data, 1 dag.

Utanför listan men värda att spara: Gravkoret (PoE Ritual, ⚙M), Silverbenet (Dragon Quest, ⚙S), bossen med två brickor
(SMT, ⚙M), Skiftande sköld (Chrono Trigger, ⚙S), krisen som period (Battle Brothers), kronans bärare med masker
(Inscryption, långt fram).

**Ordning (förslag):** 2 och 3 kan byggas nu, oberoende av laddningen. 1, 7 och 8 hör ihop med varslade-attacker och tas
efter att Benfurstens laddning är provspelad. 4 och 5 hör till bossrotationen i mot-upprepning §8. 9 och 10 är steg tre.

**Mätbart:** samma som mot-upprepning §8 (ingen boss mer än 4 gånger på 10 nedstigningar) plus för 2: botten "direct" ska
välja bort fler vanliga grupper när belöningen syns (andel besegrade grupper per våning sjunker), utan att vinsten faller
mer än 5 enheter.

## 5. Frågor till VD

1. **Markörspråket:** vill du ha fyra fasta laddningsformer som återkommer hos alla bossar (FFXIV), eller ska varje boss
   ha sin egen laddning utan gemensamt språk?
2. **Belöningen på kortet:** ska spelaren se vad en grupp lämnar innan striden (Hades), eller ska det vara en överraskning
   som i Siralim?
3. **Svår form:** ska bossarna få en frivillig svår form efter tre segrar, eller ska svårigheten bara komma med djupet?
4. **Vandraren:** passar en slumpad boss med lånade egenskaper (Zantai), eller blir det för likt "slump i stället för
   design"?
5. **Rörliga grupper i grottan:** får en grupp per våning patrullera (Etrian), eller ska alla grupper stå still som i dag
   (Siralim, Dungelot)?
6. **Fördärvets kort:** ska Realms man inte besöker bli farligare med tiden (Wildermyth), eller straffar det den som vill
   stanna i en Realm och träna?

## Källor

- Hades: [PC Invasion: Pact of Punishment](https://www.pcinvasion.com/?p=221639),
  [TrueAchievements](https://www.trueachievements.com/game/Hades/walkthrough/7),
  [Prima Games](https://primagames.com/gaming/hades-guide-pact-of-punishment-modifiers-heat),
  [RPG Site](https://www.rpgsite.net/feature/10287-hades-pact-of-punishment-heat-modifiers-and-how-to-maximize-your-rewards),
  [Hades Wiki: Oath of the Unseen](https://hades.fandom.com/wiki/Oath_of_the_Unseen),
  [game8](https://game8.co/games/Hades-2/archives/454373)
- Path of Exile: [poewiki: Nightmare Map modifiers](https://www.poewiki.net/wiki/List_of_modifiers_for_Nightmare_Map),
  [Maxroll: rolling maps](https://maxroll.gg/poe/getting-started/how-to-roll-maps),
  [poe-vault: Delirium](https://poe-vault.com/guides/delirium-league-guide),
  [poe2wiki: Encounter](https://www.poe2wiki.net/wiki/Encounter)
- Diablo: [Maxroll: D3 elite affixes](https://maxroll.gg/d3/resources/elite-affixes),
  [diablowiki: Molten](https://diablowiki.net/Molten), [Arcane Enchanted](https://diablowiki.net/Arcane_Enchanted),
  [Windows Central: Nightmare Dungeons](https://www.windowscentral.com/gaming/diablo-4-nightmare-dungeons)
- FFXIV: [consolegameswiki: Common mechanics and markers](https://ffxiv.consolegameswiki.com/wiki/Common_mechanics_and_markers),
  [Tankbuster](https://ffxiv.consolegameswiki.com/wiki/Tankbuster), [Stack marker](https://ffxiv.consolegameswiki.com/wiki/Stack_marker)
- Monster Hunter: [mp1st: Enraged monsters](https://mp1st.com/news/monster-hunter-world-enraged-monsters-guide),
  [Steam-tråd om utmattning](https://steamcommunity.com/app/582010/discussions/0/3410929406907564527)
- SMT/Persona: [megatenwiki: Press Turn System](https://megatenwiki.com/wiki/Press_Turn_System)
- Siralim: [siralimultimate.wiki.gg: Realms](https://siralimultimate.wiki.gg/wiki/Realms),
  [Steam-tråd om Zantai och Gate of the Gods](https://steamcommunity.com/app/1289810/discussions/0/3412055301111162879)
- Etrian Odyssey: [dungeoncrawlers.org](https://www.dungeoncrawlers.org/game/etrian-odyssey/),
  [etrian.fandom: Fireking](https://etrian.fandom.com/wiki/Fireking),
  [Siliconera](https://www.siliconera.com/etrian-odyssey-vs-f-o-e-s-bosses-brutal-balanced/)
- Darkest Dungeon: [wiki: Light Meter](https://darkestdungeon.wiki.gg/wiki/Light_Meter),
  [Scouting](https://darkestdungeon.wiki.gg/wiki/Scouting)
- Wildermyth: [wildermyth.com: Difficulty](https://wildermyth.com/wiki/Difficulty),
  [Design Journal: Campaign Balance](https://wildermyth.itch.io/wildermyth/devlog/86387/design-journal-campaign-balance)
- Battle Brothers: [Steam-diskussioner](https://steamcommunity.com/app/365360/discussions/0/3173324051170418550)
- Inscryption: [PC Invasion: bossguide](https://pcinvasion.com/inscryption-boss-guide-leshy-angler-prospector-cabin/2),
  [TechRaptor](https://Techraptor.net/gaming/guides/inscryption-boss-battle-guide)
- Chrono Trigger: [Tropedia: Barrier Change Boss](https://tropedia.fandom.com/wiki/Barrier_Change_Boss)
- Dark Souls/Elden Ring, Dragon Quest, Pokémon, Grimrock, Dungelot, Slay the Spires karta: MINNE, inte kontrollerat i dag.
