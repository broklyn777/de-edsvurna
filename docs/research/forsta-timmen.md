# Den första timmen på telefonen

Research 2026-10-24, gren `research-forsta-timmen` (från `test-0.30`). Ingen kod ändrad och Godot har inte körts.
Tiderna nedan är **uppskattade** ur datan (`data/intro.json`, `data/help.json`, var `HelpBox.offer` anropas) och ur
provspelet 0.30.14 (`docs/provspel/provspel-0.30.14.md`: 2–5 minuter per strid, 30–60 minuter per körning). Ingen har
tagit tid med klocka. Förslagen ska diskuteras, de är inga beslut.

## 1. Vad källorna säger

**Hur mycket hjälper genomgångar?** Andersen m.fl. (CHI 2012, *The Impact of Tutorials on Games of Varying
Complexity*) prövade åtta varianter av genomgångar i tre spel på över 45 000 spelare. Genomgångar lönade sig bara i det
mest komplexa spelet. Hjälp som visas när den behövs (kontextkänslig) kunde öka engagemanget. Hjälp på begäran både
skadade och hjälpte hur länge spelare stannade, och friheten under genomgången påverkade inte beteendet. Slutsats för
oss: ett djupt systemspel *behöver* undervisning, men den ska komma i rätt ögonblick, inte i förväg.
Källa: [Andersen m.fl. 2012 (PDF)](https://grail.cs.washington.edu/projects/game-abtesting/chi2012/chi2012.pdf).

**Lära genom att göra.** Praktiker är eniga och belägget är mest erfarenhet, inte kontrollerade studier: text läses
dåligt, undervisningen ska byggas in i spelandet ([Game Developer: "No one reads text in a tutorial"](https://www.gamedeveloper.com/business/no-one-reads-text-in-a-tutorial),
[GDevelop: text-based tutorials don't work](https://gdevelop.io/blog/improve-game-tutorials)). Williams (2009,
refererad i [AtDelfi, arXiv](https://arxiv.org/pdf/1807.04375)) ger motvikten: en aktiv genomgång misslyckas om
spelaren aldrig får en avskild plats att öva en svår färdighet. Våra makron är en sådan färdighet.

**Marvel Snap** lär ut system genom *ordningen* korten låses upp i, inte genom text. Second Dinner (GDC, refererat av
[mobilegamer.biz](https://mobilegamer.biz/second-dinner-reveals-the-secrets-of-marvel-snaps-onboarding-and-card-design/))
ordnade upplåsningarna så att "Ongoing"-kort kommer först och sedan Spectrum, som belönar dem: kombinationen visas
utan ord. De sa också nej till en mulligan eftersom den gjorde spelet långsammare och svårare för nya spelare, och lät
i stället Quicksilver alltid ligga i första handen. [Deconstructor of Fun](https://www.deconstructoroffun.com/blog/2023/5/23/marvel-snap-the-definitive-deconstruction)
beskriver de första 1–4 dagarna som en skräddarsydd upplevelse där system läggs till efter hand.
*Lärdom: en ny regel per upplåsning, och nästa upplåsning ska belöna den förra.*

**Into the Breach** (GDC 2019, ["Into the Breach" Design Postmortem](https://gdcvault.com/play/1025772/-Into-the-Breach-Design),
[PC Gamer-förhandstitt](https://pcgamer.com/into-the-breach-preview)): fienderna visar sin avsikt innan de agerar,
ingen dimma, inga träffchanser. Spelet går att läsa av, och då lär man sig genom att titta. Vi har redan avsikter och
tidslinje. Det svåraste att lära ut var enligt Justin Ma att våga offra sina mekar: det var en attityd, inte en regel.

**Siralim Ultimate på mobil.** Recensioner tar sällan upp själva genomgången, men nämner en hög tröskel och att spelet
handlar mer om menyer och siffror än om handling, och att man inte ska hoppa över berättelsen eftersom den *är*
genomgången. Gränssnittet kallas rörigt och den virtuella styrspaken irriterar på pekskärm
([TouchArcade](https://toucharcade.com/?p=309918), [OpenCritic](https://opencritic.com/game/14119/siralim-ultimate/reviews),
[sammanställning av recensioner, svag källa](https://vaporlens.app/app/1289810/siralim_ultimate)). Vi har redan valt
riktig pekstyrning. Det är vår största fördel mot förebilden.

**Slay the Spire och Monster Train på mobil.** StS-porten fick kritik för små mål och för att det blir tungt att läsa på
en telefon: ögonen tröttnar efter en timme och små ikoner kräver flera tryck
([Android Central](https://www.androidcentral.com/slay-spire-android-game-week),
[TouchArcade](https://toucharcade.com/2020/06/15/slay-the-spire-ios-review-iphone-ipad-performance-icloud-megacrit-humble-games/)).
Monster Train hyllades för sin pekanpassning och jämfördes med StS ([TouchArcade](https://toucharcade.com/2022/10/28/toucharcade-game-of-the-week-monster-train)).
**Darkest Dungeon** släpptes bara för iPad, och text och menyer var för stora för en telefon
([TouchArcade](https://toucharcade.com/2017/09/04/darkest-dungeon-ipad-review/)).
*Lärdom: på en telefon kostar läsning mer än på en dator. Varje stycke vi kan ersätta med ett ögonblick i spelet är värt det.*

**Pokémon Röd/Blå** (som jämförelse, [Bulbapedia](https://bulbapedia.bulbagarden.net/wiki/Pok%C3%A9mon_Red_%26_Blue)):
namn, sedan startval, sedan en strid mot rivalen inom några minuter. Rivalen väljer den typ som slår spelarens, så typer
lärs ut genom en förlust eller en jämn strid, inte genom en tabell. Ärendet med paketet leder sedan spelaren genom kartan.

**Siffror för mobil** (andrahandskällor, ta dem som ungefärliga):
- Retention, alla spel (GameAnalytics 2024): D1 ca 23–28 %, D7 ca 4–8 %, D28/30 under 3 %
  ([gamedevreports om Q1 2024](https://gamedevreports.substack.com/p/gameanalytics-benchmarks-in-mobile),
  [GameAnalytics 2025, PDF](https://investgame.net/wp-content/uploads/2025/02/2025-GameAnalytics-Mobile-Gaming-Benchmarks.pdf)).
  Den bästa fjärdedelen ligger på D1 ca 31–33 % på iOS och 25–27 % på Android. Tabeller per genre (RPG D1 40–60 %) saknar
  källa ([segwise](https://segwise.ai/blog/mobile-gaming-app-user-retention-strategies.md),
  [AppAgent](https://appagent.com/?p=61637)). För ett premiumspel utan annonsköp finns inga tillförlitliga siffror. De
  som köper ett spel stannar troligen längre, men det har jag inte kunnat belägga.
- Sessionens längd (GameAnalytics 2024, 11 600 spel): median 5–6 minuter, bästa fjärdedelen 8–9 minuter
  ([gamedevreports 2025](https://gamedevreports.substack.com/p/gameanalytics-mobile-gaming-benchmarks)).
  En körning hos oss är 30–60 minuter, alltså **5–10 sessioner om spelaren spelar som mobilspelare gör**.
- Bortfall tidigt: påståendet att "20 % lämnar inom två minuter" går igen men saknar studie
  ([Adrian Crook](https://adriancrook.com/?p=8151)). Unity rekommenderar en tratt med händelser per steg i genomgången
  (start, steg, klar, hoppat över). Ett stort tapp mellan två steg betyder att steget är tråkigt, en lång tid mellan två
  steg att det är oklart vart man ska ([Unity: standard events, onboarding](https://blog.unity.com/technology/standard-events-explained-part-1-onboarding)).

**Liggande och enhandsspel.** Stående läge förknippas med enhandsspel, liggande med två händer och mer yta
([devlogg](https://myoden.itch.io/myoden/devlog/170959/devlog-002-screen-orientation)). Bethesda byggde The Elder
Scrolls: Blades för båda lägena ([GDC 2019, UESP](https://content2.uesp.net/wiki/General:Building_the_Interface_of_The_Elder_Scrolls:_Blades_in_Landscape_and_Portrait)).
En recensent bytte till liggande efter 20 obekväma sekunder, en annan tyckte att stående med en hand fungerade bra.
Riktlinjerna för tillgänglighet noterar att samma person byter läge efter situation, stående på bussen och liggande i
soffan ([Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/allow-play-in-both-landscape-and-portrait/)).
Tillförlitliga andelar finns inte. För oss: liggande passar strid, tidslinje och makron. Det som går att göra är att
lägga de vanligaste trycken där tummarna når och att låta AUTO bära striden när man bara har en hand ledig.

## 2. Vår första timme i dag (uppskattning)

Spelaren har inte provat något när hen börjar. Kolumnen *Nytt* räknar system eller begrepp som nämns för första
gången. *Ruta* är hjälprutor (`help.json`, 15 st, 795 ord, 3 stycken var utom combo) och berättarrutor. Introts
repliker är 834 ord i `intro.json` (talk + at), plus `imma_joins` 67 ord.

| Min (ca) | Vad händer | Text | Nytt | Ruta |
|---|---|---|---|---|
| 0:00 | Sparplatser, "Vad heter du, edsvurne?" (`NameEntry`) | kort | – | – |
| 0:30 | Borgen öppnas: planritning, personer, kortrad. Gorm: 3 repliker | 48 ord | borgen, rörelse med tryck | – |
| 1:30 | **Kallets altare**: tre kall med 16 perks (6/5/5), 2 perk-poäng att lägga | perkstexter | kall, kärna, perks, perk-poäng, nivåer | **perks** (44 ord) |
| 4:00 | Gorm: 3 repliker, 100 silver. Gå till smedjan | 70 ord | silver | – |
| 5:00 | **Smedjan**: svärd, förmåga i svärdet, chans att slå till | menyn | artefakt, typ, stat, utlösning, nivå | **artifacts** (56) |
| 7:00 | Hedda 3 repliker. Övningsgården: Stig + Imma 4 repliker | 107 ord | Imma presenteras | – |
| 8:30 | **Övningsstrid** ensam mot en docka | – | tidslinje, avsikt, Anfall/Förmåga/Försvara/Provocera, Charges, (statusar) | **timeline** (59), **charges** (48), ev. **statuses** (47) |
| 11:00 | Segerskärm med "Det här avgjorde striden" | kort | byggets fingeravtryck | – |
| 11:30 | Stig 3 repliker. Gorms kammare: **första makroraden** i radeditorn (sökfält, 7 villkorsgrupper) | 66 ord | makron, subjekt/villkor/handling/mål, AUTO/MANUELL | **macros** (73) |
| 15:00 | Gorm 3 repliker. Biblioteket: Alrik + Imma 6 repliker, ryktena om kryptans troféer | 137 ord | troféer, sällsynthet, bosstrofé | – |
| 18:00 | **Natten**: 15 repliker i borgen (berättaren, Tor, Gorm, Imma), spelas automatiskt | 192 ord | berättelsen | 2 berättarrutor |
| 21:00 | Porten (Sven), kampanjkartan, Förberedelser (bara Paladinen) | 84 ord (`at`) | kampanjkartan, Realm | – |
| 22:30 | Grottan: berättaren "first_gate", repliken new_realm | – | grottan, dimma, steg, grupper, backa, quest, låst trappa | **room_map** (89) + **realm_quest** (59), direkt efter varandra |
| 24:00 | **Första riktiga striden**, ensam, fiender ×0,70 × 0,80 | – | – | – |
| 26:30 | Segerskärm, ev. troféval i lägret | – | trofé att välja | **trophies** (55) |
| 27:00 | Imma smiter efter: 4 repliker på rumskartan | 67 ord | Rökpil + Rättfärdigt slag | – |
| 27–50 | Resten av våning 1: 5–6 grupper, elitgrupp, skatter, lägereld, helgedom, föremål, kanske det första fyndet | korta rutor | elit, lägereld, helgedom, Realmens föremål, fynd/material | **combo** (48), ev. **charges**, berättaren + Imma om fyndet ("Visa fyndet för Hedda") |
| 50–75 | Våning 2 och Benfursten | – | boss, motdrag? (från djup 1 bara elit), Resistant | berättaren "first_boss" (3 rader) |
| 60–80 | Hemma: Gorm och Imma 8 repliker, svärdet till nivå 3 | 130 ord | – | – |

**Summa under den första timmen** (en spelare som läser allt och slåss mot det mesta):
- **Minut till första strid:** ca 8–9 (övningsdockan). **Minut till första riktiga strid:** ca 23–25.
- **Minut till introts kombination** (spelets löfte: "kombinera"): ca 30–40, efter att Imma har anslutit och använt
  Rökpil första gången.
- **Hjälprutor:** 9–10 av 15 (perks, artifacts, timeline, charges, statuses, macros, room_map, realm_quest, trophies,
  combo), ungefär 500–580 ord, plus ca 1 000 ord repliker och berättare. På en telefon i liggande läge med 17–19 px
  brödtext blir det ungefär 15–20 minuters läsning för den som läser allt. Den som inte läser missar det som behövs.
- **System före behov:** perks (minut 2, behövs först när man förstår striden), artefaktens utlösning och chans
  (minut 5, före första striden), troféer i biblioteket (minut 15, första trofén först vid minut 26), makron (minut 12,
  före den första striden där mer än en hjälte står och man kunde behöva AUTO).

## 3. Risker

1. **För lång väg till den första riktiga striden.** 23–25 minuter, varav ungefär hälften är prat och menyer. Den som
   spelar i pass på 5–6 minuter (median på mobil) har lagt *fyra sessioner* innan spelet börjar. Övningsdockan räknas
   inte som spänning: den kan inte förlora.
2. **Löftet kommer sent.** Ledstjärnan är att kombinera ska vara roligt, men den första kombinationen kommer efter
   30–40 minuter. Innan dess lär sig spelaren fem system (kall, perks, artefakt, makron, troféer) som inte ännu
   kombinerar med något.
3. **Rutor i klump.** `room_map` + `realm_quest` (148 ord) visas direkt efter varandra när grottan öppnas, ovanpå en
   ny skärm och berättarens rad om porten. I den första striden kan `timeline` och `charges` komma tätt.
   Andersen: just-in-time slår i förväg, men två rutor i rad är inte just-in-time längre.
4. **Altaret med 16 perks vid minut 2.** Ett val utan grund: spelaren vet inte vad en strid är och lägger ändå
   poäng. Gratis återställning hjälper men syns inte i ögonblicket. (Att välja kall tidigt är Siralims ordning, det
   är perk-köpet som kommer för tidigt.)
5. **Makron före behov.** Första raden skrivs innan spelaren har slagits mer än mot en docka, och innan hen har en
   följeslagare som AUTO skulle styra. Radeditorn med sökfält och grupper är kraftfull men tung för en första rad.
6. **Natten är 15 repliker i rad som inte går att hoppa över.** Berättelsen är bra (ingen kritik av innehållet),
   men i en följd är det 192 ord utan att spelaren gör något.
7. **Paus och återupptagning mitt i en strid är okänd.** `Run._notification` sparar bara speltiden när appen går i
   bakgrunden; körningen sparas efter varje rum (`run.cfg`), inte under en strid. Android kan döda appen i bakgrunden.
   Vad som händer med en påbörjad strid (spelas den om från början? försvinner den?) har jag inte kunnat se utan att
   köra spelet. En strid tar 2–5 minuter och ett telefonsamtal är vanligt.
8. **Långa körningar.** 30–60 minuter per nedstigning och 25–50 minuter för den första. Sparning efter varje rum gör
   det tekniskt möjligt att avbryta, men inget säger till spelaren att det är ett bra ställe att sluta eller påminner om
   var hen var när hen kommer tillbaka.
9. **Text på telefon.** Samma kritik som StS fick. Stycken på 3 × 15–30 ord är rimliga på en dator, men tyngre på en
   telefon, särskilt i rutor som pausar striden.
10. **Ingen mätning.** Det finns en speltidsräknare (`playtime`) men ingen tratt per introsteg. Vi vet inte var en
    ny spelare stannar upp eller ger upp.

## 4. Förslag, rangordnade

Varje förslag anger om det avviker från Siralim. Det är förslag att diskutera, inga beslut.

**1. Mät först: en tratt per introsteg (liten, bara lokal).** Logga minut och sekund (från `playtime`) när varje steg
börjar och slutar, när varje hjälprutan visas och hur länge den är öppen, minut till första strid och till den första
kombinationen. Visa det i en utvecklarflagga och låt **en person som aldrig sett spelet** spela den första timmen på
telefonen. Utan detta är tabellen ovan gissningar. (Ingen avvikelse.)

**2. Flytta perk-köpet från eden till hemkomsten.** Vid altaret väljer man kall och ser kärnan. Perk-poängen och
perks-rutan kommer när man kommer hem efter den första nedstigningen och har sett kallet verka i strid. Sparar 2–3
minuter och en ruta före den första striden. (Siralim väljer specialisering först, så valet av kall står kvar.)

**3. Flytta bibliotekssteget till efter den första trofén.** Broder Alrik förklarar troféer när spelaren har en i
handen (hemkomsten, eller en kort replik från Imma i lägret när den första trofén väljs). Steget `library` blir i
stället en del av hemkomsten. Sparar ca 3 minuter och 137 ord före kryptan, och undervisningen hamnar där
Andersen säger att den verkar. (Ingen avvikelse.)

**4. Låt den första kombinationen hända tidigare och säkert.** Den är spelets löfte. Alternativ att väga:
(a) Immas startmakro (`data/macros.json`: anfall en fiende med buff, annars den med lägst liv) får en rad med Rökpil
när ingen fiende är Förblindad, eller ett `macro_hint` (hon har inget i `heroes.json` i dag), så att kombinationen sker
i den första striden med henne även på AUTO; (b) en övningsstrid i två delar där Imma står bredvid dockan och skjuter en Rökpil (hon är ju redan i
övningsgården), så att KOMBINATION! syns redan vid minut 10. (b) förändrar berättelsen (hon ska inte vara med förrän
hon smiter efter), så (a) är det försiktiga valet. Marvel Snaps poäng: ordningen saker visas i lär ut samspelet.

**5. Gör makrolektionen till en handling, inte ett formulär.** Prototypen *Spara som order* finns redan
(`battle.gd` `_offer_order`). Låt den första raden komma ur övningsstriden: spelaren anfaller dockan, guldknappen
erbjuder "spara som rad", och Gorm förklarar raden *efteråt* vid kartbordet. Radeditorn med sökfält visas först när
hen vill ändra. Om steget ska stå kvar som det är, öppna editorn med raden förifylld så att det bara är att bekräfta.
(Siralim lär ut makron sent och via menyer. Det här är vårt val, men det ligger nära Siralims idé.)

**6. Aldrig två hjälprutor i rad, och en mening först.** Varje ruta får en första mening i fetstil som räcker,
resten under "Mer" (eller i handboken). `realm_quest` visas när spelaren första gången trycker på den låsta trappan
eller ser questens första ring, inte direkt efter `room_map`. Rutor i striden väntar till nästa gång en hjälte står
på tur, inte mitt i en kedja. (Siralims "?"-rutor är längre; detta är en mobilanpassning.)

**7. Paus och återupptagning i striden.** Pausa striden automatiskt när appen tappar fokus (som LJUD-knappen gör), och
undersök vad som händer när Android dödar appen mitt i en strid. Simuleringen är deterministisk (frö + handlingar), så
det går att spara fröet och handlingslistan efter varje tur och spela upp den igen vid start. Minst: spelaren ska
aldrig förlora en strid för att telefonen ringde. (Ingen avvikelse; Siralim sparar inte heller mitt i en strid, men
det är ett datorspel.)

**8. Naturliga stopp och "var var jag?".** Efter våning 1, vid lägerelden och efter varje hemkomst: en lugn bild
(lägerelden sprakar) som säger att körningen är sparad. När spelet startar igen: en rad från den som står närmast,
t.ex. "Vi stod vid lägerelden på våning 2. Questen: två elitgrupper, en kvar." Det passar `Dialog.bark`.
(Ingen avvikelse.)

**9. Korta natten och låt den gå fortare.** Samma berättelse i ca 8–9 repliker i stället för 15 (Tors fyra repliker om
kylan, benen och klockorna kan bli två), och ett tryck som visar hela repliken direkt och nästa tryck som går vidare.
Introt ska fortfarande inte gå att hoppa över. (Ingen avvikelse.)

**10. Tummarna.** Behåll liggande läge (det är rätt för tidslinje och makron), men se över att det spelaren trycker
oftast i grottan och striden (ANFALL/BACKA, Anfall, förvalt mål, AUTO) ligger inom tummarnas räckvidd nere i hörnen,
med mål på minst 9–10 mm. Det spelaren sällan trycker på (GE UPP, GÅ HEM, SKADELOGG) kan ligga uppe. AUTO är vårt
enhandsläge: den som ligger i sängen med en hand ska kunna spela en strid på AUTO och bara titta.
(Ingen avvikelse.)

### Vad den första timmen skulle bli med förslag 2–5 och 9

Namn och ed (2 min) → svärdet (2 min) → övningsstriden med den första raden ur *Spara som order* (4 min) → natten
(2 min) → porten och grottan vid **ca minut 12** → Imma ansluter efter den första striden → den första kombinationen
vid **ca minut 18–22** → hemma efter 45–70 minuter: troféerna hos Alrik, perks vid altaret, svärdet till nivå 3.
Samma innehåll och samma berättelse, men varje system kommer när spelaren har något att använda det till.

## 5. Osäkerheter

- Tiderna är uppskattningar ur datan och provspelet, inte mätningar.
- Siffrorna för retention och sessioner gäller främst gratisspel med annonser. För premiumspel finns inget bra underlag.
- Andersen-studien gällde webbspel på dator 2012. Riktningen (just-in-time, bara när spelet är komplext) har stöd i
  praktiken men siffrorna går inte att föra över.
- Hur striden beter sig när Android dödar appen har inte prövats.
