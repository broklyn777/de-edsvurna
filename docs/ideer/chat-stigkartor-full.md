# De edsvurna – Research N: stigkartor, upptäckt och tempo

**Datum: 22 oktober 2026.** Underlag: `CHAT-JOBB-N-stigkartor.md`, med projektinstruktionerna som krav på källkritik.

## Rekommendation för beslutet

**GISSNING – designförslag:** Testa en stigkarta med **15 besökta noder, varav 8 strider inklusive elites och boss**, uppdelad i två tydliga etapper. Gör kartan större genom fler alternativa vägar och olika fiendefamiljer, innan ni gör den längre. Visa vägarnas struktur och viktiga hållpunkter, men låt detaljer om belöningar, möten och sidouppdrag upptäckas under färden. Motivering och testupplägg finns i avsnitt 6–7.

**SÄKERT – beräkning från ert underlag:** Med 2–5 minuter per strid tar 12 strider **24–60 minuter enbart i strid**. Varken en stigkarta eller snabbare gång tar bort den tiden. Däremot kan en stigkarta ta bort onödiga förflyttningar och göra valen mellan striderna meningsfulla. Källa: uppdragsfilen; beräkning 12 × 2–5.

**TROLIGT – syntes:** Den mest lovande lösningen är därför en karta där spelaren upptäcker **vilka möjligheter som finns**, men kan bedöma **vad ett vägval kostar**. Allt dolt ger svagt beslutsunderlag; allt känt kan minska överraskningen. FTL, Roguebook och Hades ger olika exempel på denna uppdelning. [S11, S17, S27]

### Hur märkningarna ska läsas

- **SÄKERT:** Källan säger detta uttryckligen, eller det är en redovisad matematisk beräkning. En säker uppgift om att en spelare klagar är inte bevis för att majoriteten tycker likadant.
- **TROLIGT:** Tolkning eller syntes med stöd, men utan fullständig verifiering eller representativ statistik.
- **GISSNING:** Eget designförslag, målvärde eller oprövad hypotes. Det betyder inte att förslaget saknar argument.
- **Ej verifierat:** Jag anger ingen exakt siffra när underlaget inte räcker. Det gäller särskilt totala nodantal i flera av jämförelsespelen.

**SÄKERT – metodbegränsning:** Rapporten bygger på utvecklarintervjuer, patch notes, dokumenterade spelregler och förstahandsinlägg från spelare. Jag har inte kört kartgeneratorerna eller mätt ett urval av egna spelomgångar. Vissa wikis gick bara att läsa genom sökmotorns index; sådana uppgifter får inte samma tyngd som en fullt läst primärkälla. StS 2 behandlas med angiven dokumentationsversion, inte som en verifiering av senaste spelbygget.

## 1. Slay the Spires karta i detalj

### 1.1 StS 1: kartans storlek och generering

**SÄKERT – beskrivet av den som reverse-engineerade generatorn:** Grundmallen är **7 kolumner × 15 rader**. Generatorn drar sex vägar från botten till toppen. Varje steg går till någon av de tre närmaste positionerna på raden ovanför; vägar får inte korsa varandra. De två första startpositionerna måste skilja sig, vilket ger minst två ingångar. Oanvända positioner blir inte besöksbara rum. Detta är alltså inte 105 rum som spelaren ska tömma. [S1]

**SÄKERT – samma dokumentation:** Efter att förbindelserna skapats fördelas rumstyper ur en blandad samling med hänsyn till placeringsregler. Om inget tillgängligt rumsslag passar kan en plats slutligen bli ett vanligt Monster-rum. Det är mer styrt än att oberoende slå samma procent för varje ruta. [S1]

| Fast plats i en akt | Regel | Bedömning och källa |
|---|---|---|
| Rad 1 | Vanliga Monster-rum | **SÄKERT.** [S2] |
| Rad 9 | Treasure-rum | **SÄKERT.** [S2] |
| Rad 15 | Rest Sites | **SÄKERT.** [S2] |
| Ovanför rad 15 | Aktens boss | **SÄKERT.** [S2] |
| Före rad 6 | Inga Elites eller slumpmässiga Rest Sites | **SÄKERT.** [S2] |
| Rad 14 | Inga Rest Sites | **SÄKERT.** [S2] |
| Direkt efter samma typ | Elites, Shops och Rest Sites får inte följa sin egen typ längs en förbindelse | **SÄKERT.** [S1] |
| Syskon vid ett vägskäl | Generatorn försöker undvika samma rumstyp bland destinationer med samma förälder; fallback till Monster kan bryta idealet | **SÄKERT.** [S1] |

**TROLIGT – designbetydelse:** De första fem raderna fungerar som en uppbyggnadssträcka. Kartan försöker också undvika vissa monotona sekvenser, medan den sista viloplatsen ger en förutsägbar förberedelse inför bossen. Det är en tolkning av reglernas funktion, inte ett utvecklarcitat. [S1, S2]

### 1.2 Rumssannolikheter: vad procenten betyder

| Rumstyp | Vanligt angivet grundvärde i StS 1 | Bedömning och källa |
|---|---:|---|
| Monster | 53 % i den förenklade grundtabellen | **SÄKERT som wikins tabellvärde**, inte som utfall för varje faktisk nod. [S3] |
| Elite | 8 % | **SÄKERT.** [S3] |
| Rest Site | 12 % | **SÄKERT.** [S3] |
| Merchant | 5 % | **SÄKERT.** [S3] |
| Unknown, `?` | 22 % | **SÄKERT.** [S3] |
| Treasure | Fasta nionde raden, samt möjlighet genom `?` | **SÄKERT.** [S2, S5] |

**SÄKERT:** Från Ascension 1 multipliceras Elite-värdet med **1,6**, alltså 8 % × 1,6 = **12,8 %** före placeringsreglernas påverkan. En Steam-guide anger i stället 16 %. Jag använder den förstahandsbeskrivna kodregeln och wikins uppgift om cirka 60 % fler elites. [S1–S3]

**SÄKERT – viktig precisering:** Fasta rader, heltalsavrundning, förbindelser, placeringsförbud och fallback påverkar resultatet. Spelaren väljer dessutom aktivt vilka noder som besöks. Man kan därför inte multiplicera 15 med 8 % och kalla svaret det normala antalet elites per spelad akt. [S1]

### 1.3 Vad finns bakom `?`?

| Utfall | Utgångschans utan relevanta modifierare | Märkning |
|---|---:|---|
| Monster | 10 % | **SÄKERT.** [S4, S5] |
| Treasure | 2 % | **SÄKERT.** [S4, S5] |
| Shop | 3 % | **SÄKERT.** [S4, S5] |
| Event | Återstoden, initialt 85 % | **SÄKERT.** [S4, S5] |

**SÄKERT:** När ett sådant icke-Event-utfall inte inträffar växer dess chans med sitt grundvärde: exempelvis Monster 10 → 20 → 30 procent. När utfallet inträffar återställs dess chans till grundvärdet. Därför är upprepade `?` inte oberoende lotter med permanent 85 % Event-chans. Modifierare och relics kan ändra reglerna. [S4, S5]

**SÄKERT – källkritik:** FDG-artikeln om kartosäkerhet redovisar även Elite-utfallet från custom-modifieraren **Deadly Events** i sin modell. Den tabellens 20 % Elite och 65 % Event ska inte presenteras som grundregler för en vanlig StS-run. Jag använder artikeln för dess redovisade undersökning, inte som ensam regelbok. [S6]

**TROLIGT – designbetydelse:** StS har redan upptäckt, men huvudsakligen som osäkerhet om mötets innehåll. Spelaren kan känna till nodens kategori utan att känna till fienden, eventet, butikens sortiment eller belöningen. En synlig karta är därför inte samma sak som en helt förutsägbar körning. [S5, S6]

### 1.4 Hur många rum besöks, och hur lång är en run?

**SÄKERT – struktur och beräkning:** En full vanlig akt har **15 valda kartnoder + en boss = 16 innehållsrum**. Tre akter ger **48 sådana rum**. Det är en annan räkning än spelets golvräknare: övergångar mellan akter gör att bossarna ligger på floor 16, 33 och 50. Dessa två räknesätt får inte blandas. [S1, S2, S6]

**SÄKERT:** Act 4 lägger till Rest Site, Shop, Elite och Heart. Ascension 20 lägger dessutom till en andra Act 3-boss. Det blir **52 innehållsrum med Heart**, eller **53 med Heart på A20**, räknat utan övergångsrum. Spelets floor-räknare kan då sluta på 55 respektive 56 eftersom även övergångarna räknas. [S7; beräkning från reglerna]

**SÄKERT – spelaruppgifter:** En diskussion anger ungefär 30–60 minuter för en vinnande run, medan en nyare spelare i samma tråd beskriver nära två timmar och cirka 2,5 timmar till Heart. Andra erfarna spelare rapporterar betydligt snabbare tider. Detta är självrapporter, inte ett populationsmedel. [S8, S9]

**TROLIGT – användbart planeringsintervall:** Räkna med ungefär **30–90 minuter för en van spelare**, och utrymme för längre nybörjaromgångar. Det är ett grovt jämförelseintervall, inte en verifierad mediantid. Antalet rum kan vara fast samtidigt som tiden varierar mycket. [S8, S9]

### 1.5 Vad säger utvecklarna om längden?

**SÄKERT – Casey Yano, intervju cirka 46:34–49:38:** Han beskriver att spellängden bestämdes utifrån hur många tillfällen att lägga till kort som behövdes för att få en bra lek, plus lite tid att använda och finslipa den före slutbossen. De arbetade också med svårighetstoppar och bossar som kontrollpunkter. Kartan ersatte en tidigare lösning med lokala dörrval; Yano kopplar det försiktigt till mer framförhållning och nämner FTL som stark inspiration. [S10]

**SÄKERT – avgränsning:** Intervjun ger ett skäl till den övergripande längden och kartans funktion. Den visar inte att exakt **7 × 15** är ett vetenskapligt optimum, eller att samma mått passar ett party-RPG. Jag hittade inget verifierat utvecklaruttalande som bevisar det. [S10]

### 1.6 StS 2: dokumenterat, men versionsbundet

**SÄKERT:** Mega Crit släppte StS 2 i Early Access den 5 mars 2026 och säger att innehåll och balans fortsätter att ändras. [S12]

**SÄKERT som dokumentationsuppgift, TROLIGT som spelregel utan egen kontroll:** Den lästa fanreferensen anger uttryckligen **game v0.107.1**. För den versionen redovisas följande; jag hävdar inte att detta är senaste byggets exakta generator. [S13]

| StS 2-akt enligt v0.107.1-referensen | Kartans kolumner | Vanliga kartrader | Ancient + boss | Totalt besökta golv i singleplayer |
|---|---:|---:|---:|---:|
| Overgrowth, Act 1 | 7 | 15 | 2 | 17 |
| Underdocks, alternativ Act 1 | 7 | 15 | 2 | 17 |
| Hive, Act 2 | 7 | 14 | 2 | 16 |
| Glory, Act 3 | 7 | 13 | 2 | 15 |

*Samtliga tabellvärden: **TROLIGT för spelets mekanik**, direkt dokumenterade i [S13]. Ancient är här ett eget golv, till skillnad från hur Neow vanligen räknas i StS 1.*

**TROLIGT – samma versionsunderlag:** Generatorn drar sju vägar och använder antal i stället för att bara återanvända StS 1:s procenttabell: tre Shops och fem Elites över hela kartan, åtta Elites på A1; vanligen sex–sju Rest Sites, fem–sex i Glory; tio–fjorton Unknown i Act 1 och nio–tretton i senare akter. Detta är **hela kartans utbud, inte spelarens besökta antal**. Första vanliga rummet är en strid och sista raden före bossen ett Rest Site. [S13]

**SÄKERT – utvecklarens patch notes:** Betapatch v0.101.0 i mars 2026 ändrade kartgenereringen för att minska kartor överfulla med tidiga Monster-rum. Den rättade också tidiga elites: eftersom Neow nu räknas som ett golv hade elites kunnat dyka upp tidigare än avsett. Utvecklaren skrev att Gloom gjort kartorna mindre intressanta. [S14]

**TROLIGT – lärdom:** StS 2 stöder inte slutsatsen att större alltid är bättre. De dokumenterade senare akterna är kortare, och åtminstone en korrigering prioriterade varierade tidiga möjligheter framför fler vanliga strider. [S13, S14]

## 2. Vilka beslut skapar kartan, och när blir de bra?

### 2.1 Beslut som faktiskt ändrar vägen

| Beslut | Vad spelaren väger | Betydelse för De edsvurna |
|---|---|---|
| Elite nu eller senare | Omedelbar risk mot starkare framtida build | **GISSNING:** Visa både fiendefamilj och vilken sorts trofé som kan vinnas. |
| Vila eller förbättring | Säkerhet nu mot kapacitet i kommande strider | **GISSNING:** En lägerplats måste erbjuda ett verkligt alternativ även för ett friskt sällskap. |
| Tidig eller sen Shop | Möjligheten att laga en svag build mot mer pengar senare | **GISSNING:** Låt spelaren se tjänstens inriktning före vägvalet. |
| Fler strider eller `?` | Fler vanliga belöningar mot andra möjligheter och risker | **GISSNING:** Märk okända platser med användbar ledtråd, inte bara identiska frågetecken. |
| Låst väg eller framtida utväg | Högre möjlig vinst mot möjligheten att ändra sig | **GISSNING:** En återanslutning efter en eller två noder kan göra det lättare att våga testa en kombination. |

**SÄKERT – belägg för spelarbeteendet bakom tabellen:** Spelardiskussioner beskriver tidiga vanliga strider för kort, campfire före elite, pengar före Shop och vikten av att kunna avvika från en farlig eliteväg. Rest Sites erbjuder normalt vila eller uppgradering; dessa är konkurrerande användningar av samma besök. [S15, S16, S6]

**TROLIGT – syntes:** Ett vägval är intressant när det finns minst två alternativ som kan bli rimliga beroende på aktuell hälsa, pengar, build och nästa hot. Det räcker inte att linjerna skiljer sig geometriskt. [S15, S16, S18]

### 2.2 Kända svagheter och vad underlaget faktiskt visar

- **SÄKERT – en spelarsynpunkt:** I en äldre StS-tråd förespråkar vissa vägen med flest Rest Sites eller att undvika elites. Trådens rubrik ifrågasätter om detta gör kartan tråkig. Det visar att kartan kan uppfattas som en återkommande tumregel, inte att alla spelare har löst den. [S19]
- **SÄKERT – motsatt beteende finns:** Andra beskriver att de söker elites men anpassar vägvalet efter styrka och förberedelser. Underlaget stöder alltså inte en universell regel som ”maximera alltid elites” eller ”undvik alltid elites”. [S15, S16]
- **SÄKERT – kritik mot likvärdiga grenar:** Cobalt Core-spelare pekar ut vägskäl där två liknande strider omedelbart förenas igen och utfallet känns likadant. Samma tråd innehåller invändningen att korta runs är en fördel och att större karta är en preferensfråga. [S18]
- **TROLIGT – ett vanligt fel:** Om en väg ger både säkrare strider och bättre användbara belöningar, medan den andra saknar motfördel, blir valet lätt uppenbart. Fler sådana vägskäl ger mer kartläsning utan mer strategi. Detta är min analys, förenlig med kritiken i [S18].
- **TROLIGT – överraskning kan minska genom erfarenhet:** Att känna igen event och belöningsmönster kan göra återbesök rutinmässiga. Men jag har inget representativt underlag för påståendet att StS-kartan generellt ”ignoreras”.

**SÄKERT – forskning med begränsningar:** Bazzaz och Cooper analyserade 20 000 runs och fann samband mellan deras osäkerhetsmått och utfall/skicklighetsnivå. Det är inte ett experiment som visar att fler `?` eller en större karta orsakar bättre spelupplevelse eller fler vinster. [S6]

### 2.3 Vad som blir annorlunda i ert spel

**GISSNING – central designhypotes:** Hos er kan **vilken fiendefamilj man väljer** vara viktigare än skillnaden mellan Monster- och Event-symbolen. ”Spindelvägen kan ge trofén som kopplar kontroll till mitt anfall” är ett konkret buildbeslut. ”Vänster och höger är båda en slumpstrid” blir svagare om innehållet ändå är utbytbart.

**GISSNING:** Visa därför olika slags information på olika avstånd:

1. **Hela etappen:** riktning, förbindelser, bossens hot, säkra läger och utgång.
2. **Nästa två steg:** nodkategori och fiendefamilj eller belöningsinriktning.
3. **När platsen nås:** exakt fiendeuppställning, trofévariant, eventval eller skatt.

**GISSNING:** En fungerande macrobuild får gärna göra en bekant strid enkel. Kartans val kan fortfarande handla om vilken ny trofé man söker, vilken motmekanik man vågar möta och om sällskapet är redo för elite. Undvik att göra varje väg till samma automatiserade belöningssekvens.

## 3. Jämförelse med andra kartspel

### 3.1 Storlek och tidsåtgång

**SÄKERT – jämförelseprincip:** Strider, besökta kartnoder, kartans samtliga positioner och golvräknare är olika mått. Tabellen anger vilket mått som faktiskt är belagt. Ett okänt totalantal ersätts inte med en påhittad exakt siffra.

| Spel och avgränsning | Belagd omfattning per full run | Tidsunderlag och osäkerhet |
|---|---|---|
| **Monster Train 1** | **SÄKERT:** 8 strider; stora bossar på 3, 6 och 8. Flera serviceplatser mellan striderna, vanligen val mellan två sidor. Last Divinity-DLC kan lägga till slutstrid. Exakt totalt servicebesök är inte verifierat här. [S20, S21] | **SÄKERT som självrapport:** En van C25-spelare anger 35–40 min med Divinity och hög animationshastighet; andra rapporterar flera timmar. **TROLIGT:** cirka 30–60 min är ett användbart men grovt intervall för vana spelare. [S22] |
| **Inscryption, Act 1** | **SÄKERT:** Tre områdeskartor med varsin boss, därefter Leshy. Exakt totalt nodantal ej verifierat; blanda inte ihop en Act 1-run med hela berättelsens tre akter. [S23] | **TROLIGT:** Kaycee's Mod kan ge ungefär 30–60 min för en van spelare enligt diskussion, men detta verifierar inte första berättelseförsökets längd med stugpussel. Act 1 utan den avgränsningen: ingen säker minutuppgift. [S24] |
| **Across the Obelisk, Adventure** | **SÄKERT:** Fyra akter i grundstrukturen; slutområdet The Void har två kartdelar. Grenar, sidouppdrag och alternativa regioner gör ett generellt exakt nodantal olämpligt; antal längs en referensrutt ej verifierat. DLC kan ändra innehållet. [S25, S26] | **SÄKERT som erfarenhet:** Skribenter beskriver flera timmar, inklusive en rapport om 9 timmar för första klarningen med möjliga pauser. **TROLIGT:** detta är en flersessionsstruktur för ert tänkta mobiltempo, inte en 10–30-minutersmall. [S28, S29] |
| **Wildfrost** | **SÄKERT enligt guide:** 8 strider, med en nionde för hemligt slut. Därutöver valbara event mellan striderna. Totalt nodantal ej verifierat. [S30, S31] | **SÄKERT som självrapport:** cirka 30–60 min i en diskussion; snabbare och långsammare exempel finns. Ingen verifierad median. [S32] |
| **Darkest Dungeon II, Confessions** | **SÄKERT:** Regioner med vägnät och platser; vägsegment kan själva bära strid eller annan kostnad. Ett Lair kan innehålla flera strider. Ingen enda fast nodsumma verifierad för alla Confessions/versioner. Kingdoms är en annan struktur. [S33, S34] | **SÄKERT som historisk kritik:** En tråd från 2023 klagar på 4–5-timmarsruns; senare spelare beskriver också långa runs. Detta ska inte läsas som uppmätt mediantid i senaste versionen. [S35] |
| **FTL, grundspelet** | **SÄKERT:** 8 sektorer i normal struktur. Kartorna innehåller många beacons, men besökta antal varierar med väg, flotta och events; exakt total för en typisk run ej verifierad. **TROLIGT:** storleksordningen omkring 20 tillgängliga beacons per sektor är en orientering, inte en regel för alla sektorer. [S36, S37] | **SÄKERT som självrapport:** cirka 1,5–3,5 timmar i en tråd, ofta omkring 2 timmar för skribenten. [S38] |
| **Griftlands, story** | **SÄKERT enligt spelarbeskrivning:** Sal-kampanjen sträcker sig över fem dagar. Uppdrag kan innehålla flera förhandlingar och strider; dagar är inte noder. Inget generellt fast nodantal verifierat över de tre kampanjerna. [S39, S40] | **SÄKERT som självrapport:** En ny spelare hade spelat 2 timmar efter dag 2; en annan beskriver 8 timmar för första Rook-vinsten. En erfaren spelare i samma tråd anger omkring en timme med överhoppad dialog. **TROLIGT:** flera timmar för en första story-run; läsning och erfarenhet spelar stor roll. [S40, S41] |
| **Peglin** | **SÄKERT:** Tre områden med boss i slutet av varje. Kartan innehåller strider, elites, events, skatter och Shops. Exakt antal besökta rader/noder ej verifierat. [S42–S44] | **SÄKERT som recensentuppgift:** En full lyckad run anges kunna ta omkring en timme; ingen populationsstatistik. [S45] |
| **Dicey Dungeons, vanliga episoder** | **SÄKERT:** Normalt sex våningar, den sjätte en bossvåning; undantag finns. Totalt antal fiender/platser beror på episod och generering, och är inte säkert fastställt här. [S46] | **SÄKERT som självrapport:** 30–60 min och 40–60 min nämns av spelare; recensent anger 20–30 min. **TROLIGT:** cirka 20–60 min är mer hederligt än en enda normalminut. [S47, S48] |
| **Roguebook** | **SÄKERT:** Tre kapitel; hexkarta med ink och brushes. Besökta hexar är resursberoende, inte en fast följd av N noder. Exakt typisk totalsumma ej verifierad. [S11, S49] | **SÄKERT som självrapport:** Spelare anger omkring 1,5–3 timmar, inklusive 2–3 timmar även med effektiv utforskning. [S50, S51] |
| **Cobalt Core** | **SÄKERT:** Tre sektorer med varsin boss och slumpad nodkarta. Exakt totalt nodantal ej verifierat. [S52] | **SÄKERT som självrapport:** cirka 40 min respektive lite över en timme i samma tråd; andra anger cirka 90 min. **TROLIGT:** ungefär 40–100 min som jämförelseintervall, med stora individuella skillnader. [S53, S54] |
| **Balatro, normal vinst till Ante 8** | **SÄKERT:** 8 Antes × 3 Blinds = 24 erbjudna Blinds. Small och Big kan hoppas över; Boss måste spelas. Därmed **8–24 spelade Blinds** i grundräkningen. Extra ante-effekter och Endless ligger utanför. Shops är ytterligare interaktioner. [S55, S56] | **SÄKERT som en spelares uppgift:** omkring 30 min. **Ej verifierat:** representativ normal- eller mediantid; använd inte 30 min som en fast regel. [S57] |
| **Hades 1** | **SÄKERT:** Bossar på chamber 14, 24 och 36, därefter Styx med varierande antal sidokammare. Jag anger ingen exakt totalsumma för en normal run. Chamber-räkningen är inte samma som antalet vägval eller strider. [S27] | **SÄKERT som självrapport:** flera spelare anger ungefär 20–40 min på spelets timer. **TROLIGT:** verklig session kan bli längre eftersom menyer och val inte alltid räknas i den timer som jämförs. [S58, S59] |

### 3.2 Synligt, dolt och hur upptäckt uppstår

| Spel | Synligt före valet | Dolt eller föränderligt | Slutsats för ert spel |
|---|---|---|---|
| Monster Train | **SÄKERT:** Två sidors serviceutbud, kommande strider och stora bossvarianter kan planeras. [S20, S21] | **SÄKERT:** Exakta kort-, uppgraderings- och eventerbjudanden upptäcks i systemen. [S20] | **GISSNING:** Det närmaste tempoföredömet: få strider, men flera sätt att forma builden mellan dem. |
| Inscryption Act 1 | **SÄKERT:** Förgrenade vägar med mötessymboler; kartan läses tillsammans med stugans andra mysterier. [S23] | **TROLIGT:** Upptäckt bärs mycket av kortens egenskaper och berättelsens förändringar, inte av stort antal kartnoder. [S23] | **GISSNING:** Låna koncentrerade möten och meningsfulla förbättringar, inte spelets ton. |
| Across the Obelisk | **SÄKERT:** Regioner, förgreningar och uppdragsplatser; vissa nyckelföremål öppnar senare möjligheter. [S25, S26] | **SÄKERT:** Samma nod kan ha olika aktiva events/utfall mellan runs. [S60] | **GISSNING:** Låt ett tidigt fynd ändra ett senare vägval utan att kräva karttömning. |
| Wildfrost | **SÄKERT:** Vägar med belönings- och eventtyper mellan striderna. [S31] | **SÄKERT:** Exakta rekryter och erbjudanden fås vid besöken. En historisk spelartråd efterfrågar bättre bossinformation. [S31, S61] | **GISSNING:** Dölj inte kommande motmekanik om spelaren behöver förbereda sig mot den. |
| Darkest Dungeon II | **SÄKERT:** Regionens förbindelser och scoutade plats-/vägtyper. [S33, S34] | **SÄKERT:** Ospanade platser och vägsegment; scouting kan ge mer information. [S33] | **GISSNING:** Låna scouting; var försiktig med transportsträckan som följer mellan valen. |
| FTL | **SÄKERT:** Beacon-nätverk, exit och flottans front. [S17, S36] | **SÄKERT:** Många events är okända; intilliggande Shops/Distress kan avslöjas och Long-Ranged Scanners visar fartyg/faror. [S17] | **GISSNING:** Visa terräng och riktning, låt innehållets detaljer upptäckas på nära håll. |
| Griftlands | **SÄKERT:** Platser, aktuella uppdrag och personer. Relationer ändrar senare förhandlingar och konflikter. [S39, S62] | **TROLIGT:** Upptäckt ligger mer i följderna av personer och uppdrag än i kartans geometriska förgrening. [S39, S62] | **GISSNING:** Ett möte med en återkommande person kan ge mer världskänsla än flera anonyma `?`. |
| Peglin | **SÄKERT:** Nodtyper och bossikon; efter ett möte används ett fysikbaserat navigationsmoment för riktningen. [S42–S44, S63] | **SÄKERT:** `?` kan ge event, fiende eller skatt; navigation kan avvika från avsikten. [S43, S63] | **GISSNING:** Undvik att ett feltryck eller en slumpstuds förstör ett strategiskt vägval på mobilen. |
| Dicey Dungeons | **SÄKERT:** Små våningskartor med fiender, kistor, äpplen, Shops och utgång. [S46, S64] | **TROLIGT:** Nya utrustningskombinationer och episodregler bär mycket av upptäckten. [S46, S64] | **GISSNING:** En karta kan vara mycket liten om varje besök påverkar nästa strid. |
| Roguebook | **SÄKERT:** Bland annat intressanta landmärken och synliga strider enligt utvecklarintervjun. [S11] | **SÄKERT:** Ink/brushes avslöjar valda delar av hexkartan; strider ger mer ink. [S11] | **GISSNING:** Mest relevant förebild om ni väljer att förbättra fog-kartan. |
| Cobalt Core | **SÄKERT:** Sektorns nodkategorier: fiender, elites, repair, events, artifacts och boss. [S52] | **SÄKERT:** Events och belöningar har innehåll som upptäcks vid besök. [S52] | **GISSNING:** Belöningsvariation måste göra grenarna olika även när de har samma antal strider. |
| Balatro | **SÄKERT:** Aktuella Blinds, skip-Tags och bossens regel ger beslut i en i grunden linjär följd. [S55, S56] | **SÄKERT:** Framtida Shops och erbjudanden är inte en färdig synlig lootlista. [S56] | **GISSNING:** En extra strid kan vara ett val med tydlig vinst och tydlig alternativkostnad. |
| Hades | **SÄKERT:** Nästa dörrars belöningssymboler, snarare än en full aktkarta. [S27] | **SÄKERT:** Nästa rum och det exakta erbjudandet upptäcks efter valet. [S27] | **GISSNING:** Visa vilket buildbehov vägen tjänar utan att avslöja hela mötet. |

**TROLIGT – viktig jämförelse:** Monster Trains åtta strider är ett mer relevant mått för er än StS:s 48 innehållsrum. Ni har långa partystrider och vill ge tid åt kombinationer. Men inte heller åtta är ett färdigt facit: belöningsfrekvens, hur mycket builden förändras under körningen och hur länge macros tar måste mätas hos er. [S20; egen syntes]

## 4. Större kartor: mer spel eller mer väntan?

### 4.1 Tre sätt att göra en karta större

| Förändring | Vad som faktiskt ökar | Min bedömning |
|---|---|---|
| Fler parallella vägar | Fler alternativ, ungefär samma antal besök | **GISSNING:** Bör testas först; kan kräva mer kartläsning men behöver inte ge mer stridstid. |
| Fler rader på den valda vägen | Fler genomförda möten | **SÄKERT – aritmetik:** Fler 2–5-minutersstrider förlänger körningen med motsvarande tid, om inget annat kortas. |
| Fler regioner/etapper | Större helhet och fler naturliga avbrott | **GISSNING:** Passar bättre om körningen uttryckligen ska fortsätta över flera sessioner. |

**SÄKERT – konkreta större strukturer:** Across the Obelisk ger regionval och uppdrag över flera akter; FTL kombinerar ett sektorsval med ett lokalt beaconnät; Griftlands låter uppdragen breda ut sig över flera dagar. De gör storlek på olika sätt och har inte samma besöksekonomi som StS:s enkelriktade rader. [S17, S25, S39]

**SÄKERT – både för- och nackdelar uttrycks:** Cobalt Core-spelare efterfrågar fler platser och mer tid med en färdig build, medan andra vill behålla korta runs. Roguebook- och DD2-spelare beskriver utmattning av långa runs. Detta är belagda motsatta preferenser, inte ett belägg för att en viss kartstorlek vinner generellt. [S18, S35, S50, S65]

**TROLIGT:** En större karta hjälper när den tillför skilda mål, motståndare eller buildmöjligheter. Den hjälper mindre när en redan fungerande build bara ska bevisa samma sak i fler likadana strider. [S18, S65; syntes]

### 4.2 Finns ett belagt mobiloptimum på 10–30 minuter?

**SÄKERT – branschdata:** GameAnalytics 2025-rapport beskriver midcore-sessioner omkring 10–15 minuter, men den bredare 2026-rapportens data för 2025 redovisar betydligt kortare sessioner för medianen av mobilspel: 3,1–3,5 minuter. Topprocenten ligger däremot över 22 minuter. Dessa urval beskriver beteende i många spel, inte ett experiment som fastställer optimal RPG-längd. [S66, S67]

**TROLIGT – slutsats för er:** Ett önskat spelpass på 10–30 minuter är rimligt att testa, men det går inte att härleda ett universellt optimalt nodantal från dessa siffror. Era 2–5-minutersstrider gör att **2–4 strider plus ett par korta beslut** är en användbar första sessionsbudget. Det är min härledning, inte en benchmark. [S66, S67; uppdragsfilen]

**GISSNING – rekommenderad struktur:** En körning får ta cirka 35 minuter om den har en tydlig etappgräns efter cirka 15–20 minuter och går lätt att fortsätta. Men autosave behöver också fungera mellan handlingar i en lång strid; en telefon kan avbrytas före etappgränsen.

**GISSNING – återupptagning:** Spara build, Charges, kampstatus, kartval och redan avslöjad information. Vid återkomst: visa nästa planerade hot och ett kort minnesstöd, exempelvis ”Du söker en trofé som stärker Poisoned”. Det minskar behovet att rekonstruera hela planen.

## 5. Hybrider: vägval tillsammans med upptäckt

| Princip | Konkret belägg | Vad som är värt att testa |
|---|---|---|
| **Nära innehåll avslöjas stegvis** | **SÄKERT:** FTL avslöjar information om närliggande beacons, och Long-Ranged Scanners förbättrar beslutsunderlaget. [S17] | **GISSNING:** Två kommande steg visar familj/risk; längre bort syns landmärken och vägstruktur. |
| **Scouting är en möjlighet** | **SÄKERT:** DD2 skiljer mellan scoutade och oscoutade platser/vägar; ett Watchtower avslöjar regioninformation. [S33, S68] | **GISSNING:** Ett event kan ge spaning över en gren som spelaren faktiskt kan välja efteråt. |
| **Spelaren väljer vad som avslöjas** | **SÄKERT:** Roguebook använder ink och brushes; utvecklaren säger att fullständig karttömning inte är målet. [S11] | **GISSNING:** En begränsad spaningsresurs kan köpa information om möjligheter, med snabb förflyttning genom känd terräng. |
| **Tidigt föremål öppnar senare väg** | **SÄKERT:** Across the Obelisks utvecklartext beskriver nyckelföremål som öppnar dörrar i världen. [S25] | **GISSNING:** En räddad spejare visar en genväg på nästa våning. Visa att genvägen finns innan spelaren passerar sitt sista relevanta vägval. |
| **Kartans användbarhet förändras** | **SÄKERT:** FTL:s flotta tar över beacons och gör om dem till farliga besök. [S36, S69] | **GISSNING:** Ett val kan ändra en framtida gren, men undvik att dolda ändringar omöjliggör den plan som kartan just uppmuntrat. |
| **En sällsynt möjlighet bryter förbindelserna** | **SÄKERT:** StS 1:s Wing Boots låter spelaren ignorera vägar vid val av nästa rum tre gånger. [S70] | **GISSNING:** En genväg kan öppna en tidigare otillgänglig belöning utan att ge fria besök på samtliga grenar. |
| **Belöningstyp känd, innehåll okänt** | **SÄKERT:** Hades använder belöningssymboler över nästa dörrar. [S27] | **GISSNING:** Visa ”healertrofé”, ”Artifact-fynd” eller ”Charges-hjälp”, och låt exakt erbjudande vara upptäckten. |

### Hur väl fungerade detta?

**SÄKERT – ovanligt relevant utvecklarerfarenhet:** Roguebooks utvecklare beskriver att tidigare stegbudget och dag/natt-lösningar kunde göra återvägar frustrerande. De gick vidare till att göra själva avslöjandet till resursbeslut, med synliga intressepunkter som riktmärken. Det är ett belägg för deras designprocess, inte ett experiment som visar att ink alltid slår fog. [S11]

**SÄKERT – motexempel om transport:** DD2:s Redemption Road-uppdatering gav vägar fler strategiska effekter och enklare kontroll. Ändå finns senare spelarkritik mot att själva körandet mellan redan fattade vägval saknar tillräckligt innehåll. En meningsfull kartkant kan alltså fortfarande kännas för lång i presentationen. [S34, S71]

**TROLIGT – huvudrisken med dimma:** Om nästa läger eller det enda sättet att motverka bossen avslöjas först efter den sista avtagsvägen har spelaren inte gjort ett informerat riskval. Att kunna se riktning, kategori och möjliga räddningsvägar kan vara viktigare än att se exakt loot. [S17, S61; syntes]

### Rekommenderad hybrid för De edsvurna

**GISSNING – konkret förslag:** Låt dimman dölja **detaljerna i världen**, medan vägarna fortfarande går att planera:

- Bossens plats, huvudmekanik och säkra läger syns från etappens början.
- Fiendefamilj och belöningsinriktning syns två steg bort.
- Ett täckt rum får en ledtråd: nät, hovspår, hammarslag eller en nödställds röst.
- Exakt fiendeuppställning, troféval och kort dialog avslöjas vid ankomst.
- Spaning låter spelaren jämföra två fortfarande nåbara grenar.
- Sidogrenar ersätter andra besök eller har en uttrycklig extra tidskostnad. De får inte vara gratis extraloot som alla förväntas städa av.

**GISSNING:** Ett uppdrag ska ha ett angivet vägval eller en riktad ledtråd. Att gömma en obligatorisk nyckel på en godtycklig plats återinför ert nuvarande krav på att söka överallt.

## 6. Hur många strider passar ert kombospel?

### 6.1 Tidsekonomin före kartformen

**SÄKERT – underlagsräkning:** Två våningar med 5–6 vanliga fiendegrupper och 1 elite vardera ger **12–14 strider**, innan eventuella ytterligare bossar räknas. Vid 2–5 minuter blir det **24–70 minuter strid**. Jag räknar inte en elite två gånger om den redan ingår i ert interna gruppantal; detta följer den separata uppräkningen i uppdraget.

**SÄKERT – modell:** Total tid kan delas upp som `stridstid + belöningsval/buildarbete + övriga noder + kartläsning/transport`. En ny kartform påverkar främst de senare delarna, om ni behåller samma strider.

| Antal strider inklusive elites och bossar | Enbart strid vid 2 min/st | Vid 3,5 min/st | Vid 5 min/st |
|---:|---:|---:|---:|
| 5 | 10 min | 17,5 min | 25 min |
| 8 | 16 min | 28 min | 40 min |
| 12 | 24 min | 42 min | 60 min |
| 15 | 30 min | 52,5 min | 75 min |
| 25 | 50 min | 87,5 min | 125 min |

*Alla siffror: **SÄKERT – villkorlig aritmetik**, inte prognoser från speltest. Tiden för kartan och belöningar tillkommer.*

**GISSNING – mitt startvärde:** Sikta på **7–9 totala strider** för en normal testkörning, med åtta som första variant. Om en run verkligen måste avslutas inom 30 minuter även när strider tar fem minuter behöver ni ligga närmare **4–5 strider** och hålla övriga beslut korta.

**GISSNING – varför inte bara fem överallt?** Om de intressanta troféerna nästan alltid kommer sent kan fem strider ge för få tillfällen att pröva en ny kombination. Ge därför tidigt en användbar del och därefter minst två relevanta strider där spelaren får se den fungera. Det följer samma designfråga som Yano beskriver, men de föreslagna talen är mina. [S10]

### 6.2 Placering av innehåll

| Innehåll | Första testregel | Risk att bevaka |
|---|---|---|
| Vanliga strider | **GISSNING:** Två tidiga tillfällen att testa startbuilden, sedan högst två strider i följd utan kort mellanliggande beslut. | **GISSNING:** För många identiska bekräftelser blir väntan, särskilt med macros. |
| Elites | **GISSNING:** Första efter tidig belöning och möjlighet att justera build. Ge tydlig troféinriktning. | **GISSNING:** Om elites alltid är bäst blir routingen en rutin; om priset är dolt blir den ett bakhåll. |
| Vila | **GISSNING:** En återhämtning kring mitten och en före boss, med nyttigt alternativ för friska lag. | **GISSNING:** För generös återställning kan göra tidigare resurshushållning oviktig. Charges-regler måste balanseras separat. |
| Treasure/buildval | **GISSNING:** Första användbara valet efter första striden eller inom cirka fem minuters aktivt spel. | **GISSNING:** Loot som spelaren bara kvitterar ger mindre beslut än ett val mellan två relevanta delar. |
| Events | **GISSNING:** Korta val som ändrar resurs, spaning eller nästa väg. Tillåt snabb läsning. | **GISSNING:** Väggar av text och återkommande optimala svar blir ett annat slags transport. |
| Quest | **GISSNING:** Målet eller dess ledtråd syns före det relevanta vägskälet. | **GISSNING:** Dolda obligatoriska föremål uppmuntrar till tömning. |
| Boss | **GISSNING:** Förhandsvisa den mekanik som builden ska klara, därefter en chans till justering. | **GISSNING:** En helt oväntad hård motmekanik kan göra kartvalen meningslösa i efterhand. |

### 6.3 Macros: automatisk strid behöver mätas separat

**SÄKERT – beräkning:** Om åtta strider genom snabb automation faktiskt tar en minut vardera blir stridsdelen åtta minuter, inte 16–40. Det är ett villkorligt exempel; jag vet inte er verkliga macrohastighet.

**GISSNING – mätplan:** Logga separat manuell strid, automatiserad strid, tänkpaus, animation och belöningsval. En snabb lösning kan vara att korta animationstid i en redan avgjord strid; en annan är att minska antalet upprepade strider. Vilken som behövs går inte att avgöra från nodantalet.

**GISSNING:** Behåll nöjet att se den färdiga kombinationen vinna några gånger, men låt en vanlig körning sluta innan samma bevis behöver upprepas tio gånger. Om spelaren vill fortsätta kan en tydligt frivillig längre expedition passa bättre än obligatorisk extra längd.

## 7. Tre konkreta kartdesigner och vilket test jag skulle börja med

### Gemensamma antaganden

**GISSNING – designspecifikation:** I följande modeller betyder **8, 15 och 25 noder antal besök under en referensrutt**, inklusive elites och bossar. Det är inte hela kartans utbud. Rutnätsmåtten anger positioner för ritning, inte att alla positioner fylls eller kan besökas.

**GISSNING – tidsmodell:** Varje strid tar 2–5 minuter, varje icke-stridsnod 30 sekunder, varje stridsbelöning/buildkontroll 15 sekunder och total kartorientering två minuter. Detta är öppna antaganden för jämförelse. Nya texter, längre bossar och omfattande byte av utrustning kan dra över intervallet.

| Modell | Kartmall | Besök | Vanlig strid | Elite | Boss | Övrigt | Modelltid |
|---|---|---:|---:|---:|---:|---|---|
| **A. Kort utfärd** | 3 kolumner × 8 rader | 8 | 3 | 1 | 1 | 1 Treasure, 1 Event, 1 Rest | **15–30 min**, mittscenario cirka 22 min |
| **B. Två etapper** | 4 kolumner × 15 rader | 15 | 5 | 2 | 1 | 2 Treasure, 2 Event, 2 Rest, 1 Shrine | **24–48 min**, mittscenario cirka 36 min |
| **C. Lång expedition** | 5 kolumner × 25 rader | 25 | 7 | 3 | 2 | 3 Treasure, 4 Event, 3 Rest, 1 Shrine, 2 Quest | **36–72 min**, mittscenario cirka 54 min |

*Samtliga kartmått och fördelningar: **GISSNING – egna förslag**. Tiderna är **SÄKERT beräknade givet antagandena**, avrundade till hela minuter. De är inte testresultat.*

**GISSNING – princip för alternativa vägar:** Referensrutterna nedan anger innehållsbudget. På en alternativ rutt kan exempelvis Event bytas mot Treasure eller en Elite mot en vanlig strid. Fler alternativa noder ska inte automatiskt kunna samlas ovanpå budgeten. Visa ändringen i antal strider innan spelaren väljer en förlängning.

### A. Kort utfärd: åtta noder

**GISSNING – referensrutt:**

| Steg | Innehåll | Avsikt |
|---:|---|---|
| 1 | Vanlig strid | Prova startbuild |
| 2 | Treasure | Tidigt användbart val |
| 3 | Vanlig strid | Se vad valet gör |
| 4 | Event | Spaning eller resurstradeoff |
| 5 | Elite | Sök en specifik trofé; alternativ väg kan ha vanlig strid |
| 6 | Vanlig strid | Använd vunnen kombination |
| 7 | Rest | Återhämtning eller förbättring |
| 8 | Boss | Tydligt avslut |

**GISSNING – synlighet:** Hela vägstrukturen och bossens hot syns. Nästa två steg visar kategori och familj. Belöningar och eventdetaljer avslöjas vid besök. Använd minst två skilda familjeval så att kartan inte bara blir en rad av rum.

**GISSNING – risk:** Kort och begripligt, men kan avslutas precis när en ny kombination blivit rolig. Passar introduktion eller ett kort kontrakt bättre än som enda storlek för hela spelet.

### B. Två etapper: femton noder – mitt första huvudtest

**GISSNING – referensrutt:**

| Steg | Innehåll | Steg | Innehåll |
|---:|---|---:|---|
| 1 | Vanlig strid | 9 | Treasure |
| 2 | Treasure | 10 | Vanlig strid |
| 3 | Vanlig strid | 11 | Event |
| 4 | Event | 12 | Elite |
| 5 | Elite | 13 | Vanlig strid |
| 6 | Rest | 14 | Rest |
| 7 | Vanlig strid | 15 | Boss |
| 8 | Shrine och tydlig etappgräns | | |

**GISSNING – karta:** Rita två områden med fyra möjliga kolumnpositioner, men visa högst två–tre aktuella vägval åt gången. Grenar ska ibland förbli skilda i två–tre steg så att valet får följder; återanslutningar ger chans att ompröva senare.

**GISSNING – upptäckt:** Andra etappen syns först som terräng, boss och läger. Före etappgränsen visas en förhandsbild av nästa hot. Shrine kan erbjuda spaning som avslöjar detaljer medan nästa vägval fortfarande är öppet. Ingen obligatorisk uppdragsnyckel får ligga i en bortvald dold gren.

**GISSNING – sessionsgräns:** Första etappen innehåller fem strider och några korta noder. Med modellens mittvärden är den ungefär ett 20-minuterspass; andra etappen kan spelas senare. Spara även inne i strid.

**GISSNING – varför först:** Åtta strider ger utrymme att få en del, upptäcka ett samspel och använda det igen. Två etapper bevarar något av er nuvarande färd ned genom två våningar. Testet kan visa om vägvalen fungerar utan att ni samtidigt måste bygga ett stort innehållsutbud.

**GISSNING – risk:** Hela körningen är inte säkert en halvtimme. Vid långsamma strider blir den nästan 50 minuter. Om användarna vill avsluta hela uppdraget inom ett kort spelpass behöver A eller snabbare strider vinna över B.

### C. Lång expedition: tjugofem noder

**GISSNING – referensrutt, första området:** 1 strid, 2 Treasure, 3 strid, 4 Event, 5 Elite, 6 Rest, 7 strid, 8 Quest, 9 Shrine, 10 Event, 11 Rest, 12 områdesboss.

**GISSNING – andra området:** 13 Event, 14 strid, 15 Treasure, 16 Elite, 17 Event, 18 strid, 19 Quest, 20 strid, 21 strid, 22 Treasure, 23 Elite, 24 Rest, 25 slutboss.

**GISSNING – karta:** Fem kolumnpositioner, två regioner med tolv respektive tretton besök. Bara den aktuella regionen behöver visas i detalj. Första bossen och bytet av region ger ett starkt avbrott; ytterligare autosave-stopp finns vid alla noder.

**GISSNING – upptäckt:** Första områdets Quest kan öppna en alternativ gren i det andra. Senare region visar först landmärken och familjer, sedan exakta platser. Extra grenar måste ersätta andra steg eller uttryckligen vara frivilliga förlängningar.

**GISSNING – risk:** Tolv strider ligger nära ert nuvarande stridsantal. Denna modell kan ta bort tom gång, men löser inte lång stridstid. Den kräver dessutom mer innehåll för att undvika upprepning, och längre paus gör builden svårare att minnas.

**GISSNING – användning:** Spara den till en frivillig expedition för spelare som uttryckligen vill använda sin build längre. Jag skulle inte göra den till obligatorisk standard innan B har visat att spelarna vill fortsätta.

### 7.4 En ofta bättre ”stor karta”: 25 erbjudna, cirka 15 besökta

**GISSNING – alternativ till C:** Om målet är en karta som känns större snarare än längre: bygg exempelvis **25 verkliga platser i kartgrafen**, där en genomspelning besöker omkring **15**, med högst åtta strider på normalrutten. Då kan en karta ha fler familjer och upptäckter över flera runs utan att varje enskild run måste konsumera allt.

**SÄKERT – strukturell skillnad:** Extra alternativ som inte besöks lägger inte till sin stridstid i den valda körningen. De kan däremot öka tiden för att förstå kartan. Det är därför viktigt att skilja erbjuden bredd från genomspelad längd.

### 7.5 Är återgång till stigkarta en bra idé, jämfört med att laga fog-kartan?

**TROLIGT – min bedömning:** Ja, en återgång är en bra hypotes **om problemet främst är att själva förflyttningen saknar beslut**. En stigkarta passar bra för att välja fiendefamiljer och belöningsinriktningar. Det är däremot inte visat att den ensam återger upptäcktskänslan ni saknade förra gången.

**GISSNING – när fog bör få en chans till:** Om spelarna faktiskt uppskattar att avslöja platsen och problemet bara är klickandet, prova en liten reparation först: visa riktning till uppdragsmål, gör känd terräng snabb att passera och ge ledtrådar till intressanta platser. Men gratis extraloot på okända rutor gör fortfarande full tömning rationell.

**SÄKERT – geometri:** En ändring från 8 × 8 till 6 × 6 minskar möjliga rutor från 64 till 36, alltså **43,75 % färre rutor**. Det garanterar inte 43,75 % kortare run, eftersom strider och belöningsval kan ta huvuddelen av tiden.

| Alternativ | Fördel att testa | Problem som kan finnas kvar |
|---|---|---|
| Reparera fog | **GISSNING:** Behåller den fysiska upptäckten och kan vara billigast att prototypa. | **GISSNING:** Full tömning kvarstår om allt är gratis och värdefullt. |
| Helt synlig stigkarta | **GISSNING:** Stark framförhållning, tydliga slut och få tomma klick. | **GISSNING:** Kan upprepa ert tidigare problem med svag platsupptäckt. |
| Stigkarta med stegvis detaljavslöjande | **GISSNING:** Kombinerar planeringsbara hållpunkter med överraskningar. | **GISSNING:** För mycket dimma kan göra valen godtyckliga; för mycket information kan göra dem arbetsamma. |

### 7.6 Ett test som kan ge ett tydligt svar

**GISSNING – föreslagen ordning:**

1. **Mät nuvarande version:** tid i strid, på karta och i buildval; antal tomma tryck; när spelaren slutar eller återkommer.
2. **Prototypa B med åtta strider.** Behåll enkel grafik och befintliga fiender. Gör skillnad mellan familjer och belöningsinriktning före vägvalet.
3. **Jämför med en reparerad fog-variant med samma åtta strider och motsvarande belöningar.** Annars går det inte att veta om vinsten kom av kartformen eller bara färre strider.
4. **Jämför därefter 8 mot 12 strider inom samma kartform**, om ni behöver svar på innehållsmängd. Öka inte bredd, längd och loot samtidigt.

**GISSNING – vad ni ska mäta:**

- Median och långsam svans för sessions- och runtid; skilj nya och vana spelare samt macro/manuellt.
- Andel som återupptar efter paus och tid tills de kan göra nästa beslut.
- Om spelaren kan säga varför hen tog en gren och vilken trofé/builddel hen sökte.
- Hur ofta en ny trofé faktiskt utrustas och provas före avslutet.
- ”Jag upptäckte något”, ”jag valde något viktigt” och ”jag fick använda min kombination”, som separata frågor.
- Om körningen avslutas när spelaren fortfarande är nyfiken, eller först när hen är trött på upprepningen.

**GISSNING – beslutskriterium:** Välj den karta som förbättrar både begripligt vägval och lusten att återkomma, utan att sänka upptäckten eller tiden med en ny kombination för mycket. Inget av de undersökta spelen ger ett belagt universellt optimum på 8, 15 eller 25 noder.

## Källor

Källorna är grupperade efter användning. Spelardiskussioner belägger personernas uttryckta erfarenheter, inte hur stor andel av spelarna som håller med. Tider från äldre inlägg är historiska exempel. Regler i levande spel kan ha ändrats efter respektive angiven version.

- **S1.** [Wh0N0se: reverse-engineering av StS-kartgeneratorn](https://www.reddit.com/r/slaythespire/comments/ndqweh/i_have_reverseengineered_map_generation_algorithm/). Förstahandsbeskrivning med kodprojekt; Casey Yano deltar i tråden men hans skämtsvar är inte en formell verifiering av varje detalj.
- **S2.** [Steam-guide: Map Generation in Slay the Spire](https://steamcommunity.com/sharedfiles/filedetails/?id=2830078257). Användbar för fasta platser; dess uppgift 16 % elites avviker från S1 och används inte som korrekt A1-värde.
- **S3.** [StS 1 Wiki: Map Generation](https://slaythespire.wiki.gg/wiki/Map_Generation). Procenttabell; läst via sökindex på grund av åtkomstbegränsning.
- **S4.** [Spelargenomgång: A brief writeup on unknown locations](https://www.reddit.com/r/slaythespire/comments/1w2cx1x/a_brief_writeup_on_unknown_locations/).
- **S5.** [StS Wiki: Unknown Location](https://slay-the-spire.fandom.com/wiki/Unknown_Location). Sökindex samt regelhänvisning i S6.
- **S6.** [Bazzaz & Cooper: Analysis of Uncertainty in Procedural Maps in Slay the Spire, FDG 2025](https://arxiv.org/html/2504.03918v1). 20 000 runs; notera modellens inkludering av custom-Elites.
- **S7.** [StS: Potions, Events and Shops Reference](https://teemo.dev/game-design/slay-the-spire/systems/potions-events-and-shops-reference/). Sekundär sammanställning av Act 4 och `?`-regler.
- **S8.** [Spelartider: How many hours of gameplay for a complete run?](https://www.reddit.com/r/slaythespire/comments/ec1fb1/how_many_hours_of_gameplay_for_a_complete_run/).
- **S9.** [Spelartider: What is your average run time?](https://www.reddit.com/r/slaythespire/comments/1kbm0ph/what_is_your_average_run_time/).
- **S10.** [Casey Yano, Think Like a Game Designer #58, transkription](https://podscripts.co/podcasts/think-like-a-game-designer/casey-yano-designing-with-detail-in-slay-the-spire-mastering-the-gaming-grind-marketing-dos-and-donts-and-building-a-high-trust-company-culture-58). Relevant del cirka 46:34–49:38. Transkriptionen har automatiska ordmissar; rapporten återger innebörden utan långa citat.
- **S11.** [GamesBeat: Roguebook interview – Rewriting the Slay to Spire formula](https://gamesbeat.com/roguebook-interview-rewriting-the-slay-to-spire-formula/). Utvecklarintervju med Gary Morris; särskilt avsnittet om overworld och movement economy.
- **S12.** [Mega Crit: StS 2 Early Access launch, 5 mars 2026](https://www.megacrit.com/news/2026-03-05-early-access-launch/).
- **S13.** [StS 2-fanreferens: Acts](https://sts.wiki/acts). Den lästa sidan anger data från **v0.107.1**; inte officiell dokumentation.
- **S14.** [StS 2 v0.101.0 beta patch notes, återgivna på SteamDB](https://steamdb.info/patchnotes/22526470/). Utvecklarens text om kartvariation, tidiga elites och Gloom.
- **S15.** [StS-spelare: Let's talk pathing](https://www.reddit.com/r/slaythespire/comments/1ccqd52/).
- **S16.** [StS-spelare: Picking your path](https://www.reddit.com/r/slaythespire/comments/1m7t8ue/).
- **S17.** [FTL Wiki: Beacons](https://ftl.fandom.com/wiki/Beacons).
- **S18.** [Cobalt Core: REQ – Bigger map](https://steamcommunity.com/app/2179850/discussions/0/6027566973997258121/). Både önskemål om större karta och invändningar mot förlängning.
- **S19.** [StS: Path with most Rest sites – all the time?](https://steamcommunity.com/app/646570/discussions/0/3160848559779551994/).
- **S20.** [Monster Train Wiki: Battle](https://monster-train.fandom.com/wiki/Battle).
- **S21.** [Monster Train Wiki: Rings](https://monster-train.fandom.com/wiki/Rings).
- **S22.** [Monster Train: How long does an average complete run take you?](https://www.reddit.com/r/MonsterTrain/comments/ptb2p9/how_long_does_an_average_complete_run_take_you/).
- **S23.** [Inscryption Wiki: Act I](https://inscryption.fandom.com/wiki/Act_I).
- **S24.** [Inscryption-spelare om Act I-liknande spel och Kaycee's Mod](https://steamcommunity.com/app/1092790/discussions/0/3639496710963935028/).
- **S25.** [Xbox Wire, utvecklartext: Discover Across the Obelisk](https://news.xbox.com/en-us/2024/11/06/discover-across-the-obelisk-the-deckbuilder-that-lets-you-cooperate-with-everyone/).
- **S26.** [Across the Obelisk Wiki: Adventure Mode](https://ato.fandom.com/wiki/Adventure_Mode).
- **S27.** [Hades Wiki: Chambers and Encounters](https://hades.fandom.com/wiki/Chambers_and_Encounters).
- **S28.** [Across the Obelisk: several issues – pace of place, strategy?](https://www.reddit.com/r/AcrossTheObelisk/comments/x45igd/).
- **S29.** [Spelares essä: Spoiler-Free Review – Across the Obelisk](https://www.greaterwrong.com/posts/u3w2h5HerCFAwJJNj/spoiler-free-review-across-the-obelisk).
- **S30.** [Wildfrost Daily Voyage Guide](https://steamcommunity.com/sharedfiles/filedetails/?id=2980643661).
- **S31.** [Wildfrost Wiki: Map](https://wildfrostwiki.com/Map).
- **S32.** [Wildfrost: Average Run Time?](https://www.reddit.com/r/wildfrostgame/comments/1bfk88b/).
- **S33.** [Darkest Dungeon II: Locations och scouting](https://darkestdungeon.wiki.gg/wiki/Locations_%28Darkest_Dungeon_II%29).
- **S34.** [Darkest Dungeon II: Redemption Road, 30 mars 2023](https://darkestdungeon.wiki.gg/wiki/30_March_2023_Patch). Utvecklarens patchtext återgiven på wikin.
- **S35.** [DD2-spelarkritik: runs have to be shorter](https://www.reddit.com/r/darkestdungeon/comments/13nie38/if_dd2_is_going_to_be_a_roguelike_the_runs_have/).
- **S36.** [FTL Wiki: Sectors](https://ftl.fandom.com/wiki/Sectors).
- **S37.** [FTL: Faster Than Light, översikt](https://en.wikipedia.org/wiki/FTL%3A_Faster_Than_Light). Endast stöd för orienterande kartstorlek, inte en exakt genereringsspecifikation.
- **S38.** [FTL: What's the average time for a run?](https://www.reddit.com/r/ftlgame/comments/dsvqov/).
- **S39.** [Griftlands-spelare: What roguelite here means?](https://steamcommunity.com/app/601840/discussions/0/2442588263998126844/).
- **S40.** [Griftlands: How long does a run take?](https://www.reddit.com/r/griftlands/comments/h9sa34/how_long_does_a_run_take/).
- **S41.** [Griftlands: What is the average run time?](https://www.reddit.com/r/griftlands/comments/hoou3x/what_is_the_average_run_time/).
- **S42.** [Peglin Wiki: Map](https://peglin.wiki.gg/wiki/Map).
- **S43.** [Peglin Wiki: Encounters](https://peglin.wiki.gg/wiki/Encounters).
- **S44.** [Peglin-spelare: What is a run?](https://steamcommunity.com/app/1296610/discussions/0/596263353496657633/).
- **S45.** [RPGamer: Peglin Review](https://rpgamer.com/review/peglin-review/).
- **S46.** [Official Dicey Dungeons Wiki: Maps](https://wiki.diceydungeons.com/doku.php?id=maps).
- **S47.** [Dicey Dungeons: Average run time?](https://www.reddit.com/r/DiceyDungeons/comments/eswghw/).
- **S48.** [Destructoid: Review – Dicey Dungeons](https://www.destructoid.com/reviews/review-dicey-dungeons/).
- **S49.** [Xbox Wire, utvecklartext: Roguebook Available Now](https://news.xbox.com/en-us/2022/02/25/roguebook-available-now/).
- **S50.** [Roguebook: Why do my games take so long to finish?](https://www.reddit.com/r/roguebook/comments/s56lbu/).
- **S51.** [Roguebook: Is it any good?](https://www.reddit.com/r/roguebook/comments/1mofwpe/is_it_any_good/).
- **S52.** [Steam-guide: Cobalt Core Starting Guide](https://steamcommunity.com/sharedfiles/filedetails/?id=3076644839).
- **S53.** [Cobalt Core: How long does it take to restore everyone's memories?](https://steamcommunity.com/app/2179850/discussions/0/4040354734341793448/).
- **S54.** [Cobalt Core: I've beat the scenario eight consecutive times](https://www.reddit.com/r/cobaltcore/comments/185m3is/ive_beat_the_scenario_8_consecutive_times_am_i/).
- **S55.** [Balatro Wiki: Blinds and Antes](https://balatrogame.fandom.com/wiki/Blinds_and_Antes).
- **S56.** [Balatro Wiki: Gameplay rules](https://balatrogame.fandom.com/wiki/Gameplay_rules).
- **S57.** [Förstahandsessä: Introduction and Organization of Roguelike Deck-Building Games](https://note.com/witty_lilac874/n/n1a9cdaf872b5).
- **S58.** [Hades: Average clear time?](https://steamcommunity.com/app/1145360/discussions/0/2632850464737266078/).
- **S59.** [Eurogamer-text om Hades-timer och verklig tid, återgiven i Steam News](https://store.steampowered.com/news/posts/?enddate=1602173945&feed=eurogamer).
- **S60.** [Across the Obelisk Wiki: Nodes](https://ato.fandom.com/wiki/Nodes).
- **S61.** [Wildfrost: There should be a map indicator for the next boss](https://www.reddit.com/r/wildfrostgame/comments/12spi64/).
- **S62.** [Griftlands Wiki: Relationships](https://griftlands.fandom.com/wiki/Relationships).
- **S63.** [Peglin: Does anyone else dislike the navigation mechanic?](https://www.reddit.com/r/Peglin/comments/1iotm1x/).
- **S64.** [Dicey Dungeons Wiki: Overworld Items](https://diceydungeons.fandom.com/wiki/Overworld_Items).
- **S65.** [Cobalt Core-diskussion om bland annat för kort tid med färdig build](https://www.reddit.com/r/slaythespire/comments/18x9ztz/so_cobalt_core_has_been_pretty_aggressively/).
- **S66.** [GameAnalytics: 2025 Mobile Gaming Benchmarks](https://www.gameanalytics.com/reports/2025-mobile-gaming-benchmarks). Sessioner i 2024-underlaget.
- **S67.** [GameAnalytics: 2026 Mobile & PC Gaming Benchmarks](https://www.gameanalytics.com/reports/2026-mobile-pc-gaming-benchmarks). Sessioner i 2025-underlaget; rapportår och mätår är olika.
- **S68.** [DD2 Steam-guide: The Novel-Guide](https://steamcommunity.com/sharedfiles/filedetails/?id=2973257745). Scouting och regionstruktur.
- **S69.** [FTL Wiki: Rebel Fleet](https://ftl.fandom.com/wiki/Rebel_Fleet).
- **S70.** [StS Wiki: Wing Boots](https://slay-the-spire.fandom.com/wiki/Wing_Boots).
- **S71.** [DD2-spelare: Why does driving the stagecoach get so much more flak?](https://www.reddit.com/r/darkestdungeon/comments/1id8l4s/).
