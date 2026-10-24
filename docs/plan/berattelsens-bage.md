# Berättelsens båge – förslag till en sammanhållen berättelse

Skriven 2026-10-24 på uppdrag från huvudtråden (grenen `research-berattelsen`, skuren från `test-0.30`). **Inget här är
beslutat.** Det är ett förslag. Underlag:
- CLAUDE.md (Introduktionen, Berättarrutor, Realmens föremål "Berättelsen 0.29.2", Krönikan, Den levande världen)
- `data/intro.json`, `data/dialog.json` ("narrator", Gorms och Alriks repliker om kronan, `gorm_crown_2`, `alrik_crown_2`)
- `docs/plan/0.25-berattelsen.md`, `docs/plan/spindlar.md`, `docs/plan/trollens-realm.md`
- `docs/ideer/chat-realm3-kallornas-tradgard.md` (de tre leveranserna)
- ChatGPT:s vandrare (`docs/ideer/chat-vandrare-1.tsv`, `-2.tsv`, ospårade på main): Rådgivaren och Kronans gåva
- `docs/research/foljeslagare-relationer.md`, `docs/research/langsiktiga-mal.md`, `docs/research/siralim-luckor.md`

Märkning:
- **VD** = VD bestämmer.
- **VAL** = vårt förslag.
- **Siralim** = som originalet.
- I researchen: **SÄKERT** (källa), **TROLIGT** (flera källor eller härlett), **MINNE** (allmänt känt men inte kontrollerat i
  dag).

---

## 0. Kort

- **Det som redan finns bär en berättelse.** Klockan i borgens torn slår när paladinen svär eden, och samma natt vaknar
  kryptan. Klockorna i kryptan ringer av sig själva. Efter Benfursten slår tornklockan igen, och ett beslag har stämpeln
  med kronan med en tom mitt. Trollen kom ut när kapellets klockor tystnade. Rådgivaren erbjuder gåvor ur ett skrin med
  samma krona på låset.
- **Förslaget (VAL, alternativ A, §2):** kronan är ett gammalt tyranniskt hovs krona. Mitten var **Edsstenen**: varje ed
  som svors i landet band sig till den som bar kronan. De första edsvurna bröt den makten. De svor *för deras skull som
  inte kan försvara sig själva*, inte för en krona (Gorms ord vid altaret). Stenen sitter sedan dess i **Kallets altare** i
  borgen, och klockorna hängdes för att ringa när en ed svärs på riktigt.
  Hovet dog aldrig riktigt. **Kronans råd** har väntat, och Rådgivaren är dess siste tjänare. När paladinen svor eden
  slog klockan, och hovet vaknade. Kronan kan inte ta något, den måste *få*: därför handlar allt om gåvor. Det hovet vill
  ha till sist är paladinen, en frivilligt svuren människa i mitten.
- **Fem akter** knutna till Realms och djup. Varje boss avslöjar en bit, och slutet (eftertexter) kommer på **djup 5**,
  före väggen vid djup 6–7. Väggen blir då slutspelet och inte ett stopp mitt i berättelsen.
- **Efter eftertexterna** fortsätter spelet: djupen har inget tak, kronans skärvor bärs av förvridna bossar, och Kronans
  sex andra rådgivare blir väktare var femte djup (vårt svar på Nether Bosses). Rådgivaren kommer tillbaka, för han
  ljuger aldrig: "Vi ses nog längre ned."
- **Följeslagarna** får var sin tråd som hakar i en akt (§6). Ingen tråd kräver att man har med just den personen för att
  se huvudberättelsen.

---

## 1. Research: hur andra berättar över många körningar

### 1.1 Siralim Ultimate
- **Premiss:** Siralim och Nex har varit allierade i ett sekel. Alliansen bryts, och kung Andrick av Nex skaffar en relik
  som styr gudarna. Spelaren är Siralims härskare. (SÄKERT, RPGamer 2020)
- **Struktur:** 21 Realms i berättelsen, var och en med en gud. En Realm Quest när man kommer in. Berättelsen går genom
  Realms och djup, och bossar avslutar kapitlen (SÄKERT, RPGamer; vår `siralim-luckor.md`). Caliban är en bossjätte i
  berättelsen (TROLIGT, Steam).
- **Story-djupen är skyddade:** instabiliteten gäller inte på berättelsebossarnas djup (SÄKERT, wiki Realms).
  Instabiliteten låses upp efter bossen på djup 33 (SÄKERT, wiki).
- **Efter berättelsen:** Nether Bosses var femte djup, Nether Realms från djup 21, False Gods, Gate of the Gods (laget
  låst till nivå 100 mot starkare gudar) och slumpbossen Zantai (SÄKERT/TROLIGT, wiki och Steam).
  Djupet har inget tak, och spelare rapporterar djup över 1 000 (`langsiktiga-mal.md`).
- **Kritik:** "svag berättelse" är ett av de vanligaste klagomålen (15 nämnanden i vår genomgång, `siralim.md` §8). En
  spelare beskriver Siralim 3 så här: gudarna tvingar en in i strider, och berättelsen förklarar inte varför (Steam).
  **Lärdom:** vi tar strukturen men ska vara tydligare än originalet. Varje boss ska ge en bit som spelaren förstår.

### 1.2 Hades
- Berättelsen går framåt **med varje död**. Kasavins mål var att roguelikens upprepning och berättelsen skulle vara samma
  sak (SÄKERT, Gamasutra/GDC Podcast, ScreenHub).
- Repliker väljs efter spelets tillstånd. En död är ett skäl att prata hemma.
- **Slutet:** den första flykten ger ingen upplösning. Det verkliga slutet kommer efter tio flykter, och epilogen kräver
  dessutom relationer (TROLIGT, flera källor är oense om antalet). Eftertexterna rullar, och spelet fortsätter med samma
  loop (MINNE).
- Supergiant bygger system så att den som har svårt ändå kan se berättelsen (SÄKERT, Kasavin).
- **Lärdom:** hemkomsten är scenen, inte grottan. Det har vi redan (`_start_homecoming`, krönikan). Slutet får gärna
  kräva *mer än en* seger mot slutbossen, men inte en ny vägg av svårighet.

### 1.3 Darkest Dungeon 1 och 2
- DD1: anfadern berättar genom hela spelet, i strid, i byn och i exponeringen (TROLIGT, Marchitto). Berättelsen blir
  mörkare ju djupare man går (SÄKERT, utvecklarintervju via NME).
- DD2: en kort berättarbit spelas före varje expedition, och en ny bit kommer för varje nytt försök. Det är ett
  "droppande" som bokstavligen är knutet till att man försöker igen (TROLIGT, Bloody Disgusting).
  Fem akter, var och en med en ny slutboss (TROLIGT). Hjältarnas bakgrund visas när man besöker vissa platser (TROLIGT).
- **Lärdom:** berättarrösten (vår StoryBox) kan bära mycket med lite text. Personliga trådar kan sitta på *platser*
  (Realms), inte på hur många timmar man har spelat.

### 1.4 Rogue Legacy 2 (MINNE, ej kontrollerat i dag)
- Varje biom har dagböcker och minnen som man hittar under körningarna, och de berättar en sammanhängande historia
  baklänges. Efter slutbossen kommer eftertexter. Sedan fortsätter spelet med en svårare omgång (New Game+) och ett
  "sant" slut för den som har samlat allt.
- **Lärdom:** föremål i grottan kan bära lore (vi har redan Realmens föremål) utan att striden stannar.

### 1.5 Wildermyth
- Kampanjer med 3 eller 5 kapitel, och varje kapitel slutar med en bossliknande händelse (SÄKERT, wiki Campaign).
  Hjältar som överlever går in i ett legacy-förråd och kan följa med i nästa kampanj (SÄKERT, wiki Legacy).
- **Lärdom:** berättelsen uppstår ur det som hände i striderna (vår krönika). Det fasta manuset kan vara kort om
  krönikan fyller i resten.

### 1.6 Inscryption (lätt)
- Tre akter där spelets form ändras medan reglerna består (SÄKERT, Wikipedia).
- **Lärdom för oss:** *inte* att byta form, men en akt kan ändra *var* man är. Sista akten kan utspela sig under borgen
  i stället för i en ny Realm (§4, akt V).

### 1.7 Mönster som gäller oss
1. **Droppa efter verkliga händelser:** en boss, ett nytt djup, en hemkomst. Aldrig efter tid. (Hades, DD2, vår
   "lines follow progress".)
2. **Hemkomsten är scenen.** Grottan visar spår, borgen förklarar dem.
3. **Varje kapitel slutar med en boss som ger en bit** (Siralim, Wildermyth, DD2).
4. **Slutet ska nås före väggen**, och eftertexterna öppnar slutspelet i stället för att stänga spelet (Siralim: Nether
   Bosses efter berättelsen; Hades: loopen fortsätter).
5. **Mer än en seger mot slutbossen** för hela upplösningen (Hades tio flykter, Siralims tre segrar mot Masters, vår
   `boss_wins` för bosstroféer).

---

## 2. Vem är avsändaren? Tre alternativ (VD)

Tonen gäller alla tre:
- Fienden får vara hur ockult och ond som helst.
- Spelarens sida är aldrig ockult och sluter aldrig pakter.
- Paladinens ed är det som står emot.

### A. Kronans råd och Edsstenen (rekommenderas, VAL)
**Kort:** ett gammalt hov vars krona band varje ed i landet till sin bärare. Mittstenen, **Edsstenen**, bröts ut av de
första edsvurna och sitter i Kallets altare i borgen. Hovets rådgivare har väntat på en ny ed som är stark nog att
fylla mitten. Paladinens ed var det.

**Hur det knyter an till det som finns:**
- Gorm vid altaret: "Inte för min skull – för deras skull som inte kan försvara sig själva." Så lyder ordensregeln mot
  kronan.
- "Klockan i tornet slog när du valde – det gör den bara ibland." Klockorna ringer vid en verklig ed, och hovet hörde
  den. Samma natt vaknar kryptan.
- Kryptans klockor ringde av sig själva, och tornklockan slog efter Benfursten. Hovet testar vad klockorna gör.
- Kapellets klockor tystnade, och trollen kom ut. Hovet tystar det som håller.
- Rådgivaren säger "en gåva ska aldrig trängas i någons hand". Kronan kan bara ta emot. Därför erbjuder hovet gåvor och
  löften till alla, till Benfursten, biskopen, Vävmodern, Bergakungen och till sist paladinen.

**För:**
- Eden blir mekaniskt och berättarmässigt viktig. Kallen, perks och altaret är redan spelets kärna.
- Rådgivaren får en självklar roll som hovets förvaltare.
- Slutet kan spelas i borgen och under den, med altaret och tornklockan som har funnits sedan första minuten.
- Gorm får en brist: han visste mer än han sa (tonen: människor med fel, inte helgon).

**Mot:**
- Abstrakt. En "makt som binder eder" måste visas med konkreta saker: klockor, beslag, en tom infattning. Den får inte
  förklaras med text.
- Risken att paladinen blir "den utvalda". Motmedel: hovet väljer inte paladinen för att hen är speciell, utan för att
  hen *svor på riktigt*, vilket vem som helst kan göra. Imma kan också göra det i slutet (§6).

### B. Den edslöse: Gorms forne edsbroder
**Kort:** **Herr Halvard** (förslag) svor eden med Gorm för fyrtio år sedan. Han bröt den för att rädda sin dotter och
miste henne ändå. Nu tror han att eder är kedjor. Han vill bära en krona som ingen behöver svära till, och mitten är
platsen för hans brutna ed. Rådgivaren är hans tjänare, eller han själv i förklädnad.

**För:**
- Ett ansikte och en spegel av paladinen. Personligt för Gorm, och lätt att förstå på en telefonskärm.
- En tragisk skurk kan få ett slut där han ångrar sig (passar paladinens nåd).

**Mot:**
- "Den fallne paladinen" är en sliten figur.
- Halvard har varit på spelarens sida. Det kan sudda ut gränsen mot det ockulta: hans pakter måste vara tydligt *hans*
  fall och aldrig ordens väg.
- Svårt att förklara varför han skulle tala genom troll och spindlar.

### C. Den namnlöse under landet
**Kort:** något gammalt som var bundet av de första klockorna och ederna. Det har ingen form och inget namn som någon
minns. Kronan är dess kärl, och mitten är platsen för dess **namn**. Den som säger namnet binder det (folktron om jätten
Finn i Lund, `trollens-realm.md` §3). Rådgivaren är en människa som tog emot gåvan för länge sedan.

**För:**
- Ren ondska som får vara hur ockult som helst, och klar gräns mot spelarens sida.
- Namnmotivet ger Trollberget en nyckelroll: Lirien kan lära sig vaggvisan, och slutet blir att *namnge* i stället för
  att bara döda.

**Mot:**
- Ansiktslöst. Det kräver Rådgivaren som ansikte hela vägen.
- Eden blir mindre central, och kronan blir en bild snarare än en sak med mening.

### Rekommendation
**A**, med två lån från C:
- Hovets kung har inget namn kvar. Hans namn ströks ur krönikorna när stenen togs. Att Broder Alrik till sist hittar namnet
  är en akts belöning, och folktron om namn (Finn) gäller fortfarande i Trollberget.
- Rådgivaren är en människa som tog emot Kronans gåva en gång, föll och reste sig. Så blev han odödlig och fri från sina
  egna löften.

Resten av dokumentet utgår från A. Det mesta går att flytta till B eller C genom att byta vad mitten betyder.

---

## 3. Rådgivaren

**Vem (VAL):** **Kronans siste rådgivare.** Han tjänar en kung som inte finns och en krona som är tom. Han har inget eget
namn i spelet, bara "Rådgivaren". Bär grå resrock och har ett skrin med kronan på låset (ChatGPT:s vandrare).

**Regler för honom:**
1. Han ljuger aldrig rakt ut och säger aldrig vem han tjänar förrän i akt V.
2. Han går aldrig in i borgen och aldrig in i ett rum där en klocka hänger. Han står utanför porten och pratar med Sven.
3. Han erbjuder alltid, han tar aldrig. Allt han ger har ett pris som slår tillbaka mot den som tog emot
   (Kronans gåva: bossen reser sig också).
4. Han är vänlig. Det obehagliga är hur vänlig han är.

**Hans gåvor är provspel (VAL):** varje gåva prövar om paladinen kan förmås att *ta emot* av kronan. Den som tar emot
straffas inte i berättelsen, men Rådgivaren minns det: "Ni tog emot förra gången. Det var klokt." Den som avböjer får
en annan rad. Det ger ett litet minne utan att slutet förgrenas.

**Hans framträdanden** (med mekanik där den finns):

| När | Var | Vad |
|---|---|---|
| Akt I, efter första bossen | Vandrare i grottan (ChatGPT:s scen) | Kronans gåva. TA EMOT / AVBÖJ / PRÖVA HONOM (Ragnhild). |
| Akt II, kapellets boss första gången | I dörröppningen efter striden | Två repliker om priset om gåvan togs, annars en om att biskopen "tog emot utan att tveka". |
| Akt III, hemkomst från Lunden | Utanför porten, Sven berättar | Han har frågat efter paladinen vid namn. Sven släppte inte in honom. |
| Akt IV, Trollberget våning 2 | En vandrare som lämnar Bergakungens sal | Han erbjuder en gåva till, större. Han nämner altaret för första gången. |
| Akt V | Under borgen | Han talar öppet. Han erbjuder kronan. |
| Efter eftertexterna | Vandrare var femte djup, sällsynt | Större gåvor med större priser, som Pandemonium-helgedomen. |

**VD:** ska Rådgivaren gå att strida mot i akt V, eller bara tala? Förslaget: han slåss inte. Kronans väktare slåss,
och han ser på. Han försvinner när kronan bryts och dyker upp igen efter eftertexterna. Det är kusligare, och han kan
komma tillbaka.

---

## 4. Akterna

Djupen nedan är förslag (VAL). Spelarens snittnivå vid varje akt bör stämma mot `HeroStats.enemy_level` och
svårighetskurvan (`docs/provspel/svarighetskurva.md`: djup 1 är en platå, taket vid djup 6–7).

| Akt | Namn | Realm och djup | Bossen avslöjar | Slutar med |
|---|---|---|---|---|
| I | **Klockorna** | Kryptan, djup 1 | Någon hjälpte Benfursten (beslaget) | Tornklockan slår. Rådgivaren visar sig. |
| II | **Löftet** | Kapellet, djup 1 (Kryptan djup 2 parallellt) | Hovet gav löften, inte bara saker. Biskopen ville att klockorna skulle tystna. | Alrik: stämpeln är ett avsändartecken. |
| III | **Tråden** | Sidenlunden, djup 2 | Leveranserna gick genom Lunden. Ett brev nämner paladinen vid namn. | Hovet heter Kronans råd. Det är ett hov, inte en person. |
| IV | **Namnet** | Trollberget, djup 3 | Bergakungen minns den förra kungen och stenen. Stenen sitter i altaret. | Gorm erkänner vad orden har gömt. |
| V | **Kröningen** | Det tomma hovet under kryptan, djup 5 | Kronan, Rådgivaren och kungens namn | Kronan bryts på Heddas städ. Eftertexter. |

### Akt I – Klockorna (finns till största delen)
- **Finns:** introt, eden, natten med arbetarna, Imma som smiter efter, Benfursten, beslaget (`narrator.first_boss`),
  Gorm ("Benfursten fick hjälp av någon") och Alrik ("Den stämpeln har jag sett förut").
- **Saknas:**
  1. Rådgivaren som vandrare efter första bossen. ChatGPT:s repliker finns. Grottans händelser behöver en
     vandrartyp (⚙).
  2. **Klockans koppling** sägs aldrig rakt ut. Lägg en rad hos Gorm efter Benfursten: "Tornklockan slog i går natt. Den
     slog också när du svor. Jag tycker inte om när den slår av sig själv."

### Akt II – Löftet
- **Kapellets boss, Den fallne biskopen,** fick ett löfte, inte ett föremål: att klockorna skulle tystna så att ingen mer
  i hans församling skulle behöva höra dem ringa till begravning (pesten tog dem, GISSNING om bakgrund, VD). Hans
  biskopsring har en tom infattning.
- **Det binder ihop:** kapellets klockor tystnade → trollen kom ut (`trollens-realm.md` §2). Spelaren förstår det
  först i akt IV.
- **Finns:** `gorm_crown_2` och `alrik_crown_2` (två bossar).
- **Saknas:** en berättarruta efter biskopen (förslag i §7.0), och Syster Alvas eller Ragnhilds rad om biskopen.

### Akt III – Tråden (Sidenlunden, finns som Realm utan berättelse)
- **Vävmodern** spinner igen handelsvägarna (följden "nät över handelsvägen" finns redan i den levande världen). Hovet
  lovade henne att alla vägar skulle leda till henne.
- **I kokongerna** hittar man gods som aldrig kom fram: en kista med beslag med samma stämpel, och ett sigillerat brev.
- **Brevet** (läses först hemma av Alrik): "Till den edsvurne i borgen. Ni svor i rätt tid. Vi har väntat länge. — K.R."
  Hovet vet vem paladinen är.
- **Avslöjandet:** "K.R." är **Kronans råd**. Alrik hittar ordet i en gammal rulla: ett hov med sju rådgivare kring en
  kung vars namn har strukits.
- Källornas trädgård (ChatGPT) kan bli en senare Realm. Dess "tre leveranser" flyttas till Lundens kokonger
  (VAL; VD).

### Akt IV – Namnet (Trollberget, föreslagen Realm 4)
- **Bergakungen** fick löftet att klockorna skulle tystna (finns i `trollens-realm.md`). Han bär en krona av sten med
  en tom infattning. Trollen är gamla nog att *minnas* den förra kungen.
- **Bossens avslöjande** (berättarruta och en replik från Bergakungen när han faller): "Den förra kungen bar stenen i
  mitten. Era edsvurna bröt ut den och gömde den under ett altare. Fråga er gubbe."
- **Hemma:** Gorm erkänner. Orden har vaktat stenen i borgen sedan dess, och han har vetat att hovet kunde vakna.
  Han berättade inte, för han ville att paladinen skulle svära *för de andras skull*, inte av rädsla.
  Imma blir arg på honom. Detta är akten där Gorm får sin brist.
- **Namnmotivet** (lån från C): Lirien eller Hulda hör en trollmor sjunga en vaggvisa med ett namn i. Alrik hittar
  sedan namnet i rullan. Kungens namn är nyckeln till akt V.

### Akt V – Kröningen (första slutet)
- **Var:** under kryptan. Kryptan ligger under borgen, och under kryptans äldsta del ligger **Det tomma hovet**,
  kungens gamla tronsal (VAL). Det är en egen Realm med två våningar, som återanvänder kryptans och kapellets familjer
  blandade (Siralims sista Realms blandar raser), plus hovets egna rådgivare som elitfiender.
- **Öppnas:** när akt IV är klar och djup 5 är upplåst (VAL; VD).
- **Slutbossen:** **Kronans väktare** (förslag), kungens tomma rustning på tronen. Kronan svävar ovanför den, och
  Rådgivaren står bredvid.
  - **Skede 1:** väktaren slåss.
  - **Skede 2:** kronan försöker *ta emot* en hjältes ed. Den hjälte som står överst på tidslinjen blir Hånad och
    måste slå sig fri.
  - **Skede 3, när kungens namn är känt:** namnet sägs, och kronan tappar sin immunitet (mekanik som Den fallne
    biskopens `immune_while_ally_kind`).
- **Erbjudandet:** efter segern erbjuder Rådgivaren paladinen kronan. **VD:** ska spelaren få välja?
  - **Förslag:** två knappar, TA EMOT och JAG HAR REDAN SVURIT.
  - TA EMOT ger en berättarruta: *(Din hand stannar en tum från kronan. Uppe i tornet slår klockan, en gång.)* Sedan
    visas samma två knappar igen, utan TA EMOT.
  - Ingen förgrening, men spelaren har fått *känna* frestelsen. (Siralim har inga förgreningar heller.)
- **Upplösningen:** kronan bärs upp till borgen. Hedda bryter den på städet ("rör inte städet" från introt får sitt
  svar: "I dag får du röra det."). Edsstenen stannar i altaret. Alla klockor i landet ringer, kryptans, kapellets och
  Stenbys (om den har kommit hem).
- **Eftertexter**, sedan rutan "Medan ni var borta": krönikan får posten "Kronan bröts".
  Titeln **Kronbrytare** (`titles.json`).
- **Hela slutet kräver tre segrar mot väktaren** (Siralims Masters, vår `boss_wins`, VAL). Den första segern ger
  erbjudandet och en rad som säger att kronan "lagar sig". Den tredje ger Heddas städ och eftertexterna. **VD:** en
  eller tre segrar?

---

## 5. Efter eftertexterna

Spelet fortsätter som Siralim efter berättelsen, med samma loop:

1. **Djupen har inget tak.** Fiendernas nivå följer djupet (`HeroStats.enemy_level`).
2. **Kronans skärvor:** kronan bröts i sju bitar, och Rådgivaren tog några med sig. På levande kartans steg 4 bär den
   förvridna bossen en skärva (Den svärtade Benfursten finns redan, med trofén Svärtad krona). Varje skärva är en
   samling med synliga luckor (`langsiktiga-mal.md` punkt 2).
3. **De sex andra rådgivarna** blir **väktare var femte djup** (5, 10, 15 …), vårt svar på Nether Bosses
   (`langsiktiga-mal.md` förslag 7). Var och en har ett regelbrytande trait i tre grader och en trofé efter tre segrar.
   Var och en var rådgivare för något: Rådgivaren över Ederna, över Döden, över Vägarna, över Klangen …
4. **Rådgivaren** kommer tillbaka som sällsynt vandrare med större gåvor och större priser.
5. **Kallens fullbordan** (`langsiktiga-mal.md` förslag 4, Siralims Ascension) får en berättelse: att slå väktarna med
   varje kall är att "svära om" eden i varje form.
6. **Följeslagarnas trådar** som inte är klara går att avsluta efter slutet.

**Varför slutet på djup 5 (VAL):** botarna visar en vägg vid djup 6–7. Om eftertexterna kommer där kör spelaren fast
*före* slutet, vilket är det sämsta läget. På djup 5 blir slutet en belöning för den som har lärt sig kombinera, och
väggen blir det första målet efter slutet, med väktaren på djup 10 som nästa.

---

## 6. Följeslagarnas trådar

Varje tråd har en **krok** i en akt och kan bli ett personligt uppdrag (`foljeslagare-relationer.md` förslag 7).
Ingen av dem behövs för att se huvudberättelsen.

| Hjälte | Krok | Tråd (förslag) |
|---|---|---|
| **Imma** | Akt I och IV | Hon vill svära en ed själv, men Gorm har alltid sagt nej ("du stannar här"). I akt IV är hon arg på Gorm för hans hemlighet. I akt V lovar hon något, men inte till en krona: "Jag lovar dig, {namn}. Inte någon krona." Det är ingen ed, men hovet kan inte röra det. Hon behöver inte vara med för att det ska hända. |
| **Syster Alva** | Akt II | Hon lärde sig hela i kapellet under biskopen innan han föll. Hon vill veta varför han tog emot. Efter biskopen: "Han var snäll mot mig. Det är det värsta." |
| **Ragnhild Ljusdom** | Akt I och II | Domaren som prövar Rådgivaren (ChatGPT:s PRÖVA HONOM). I kapellet dömer hon biskopen hårt och får medge att hon själv har dömt fel en gång. Bibelord bara ur 1917, kontrollerade. |
| **Brokk** | Akt V | Dvärgarna smidde en gång kronans infattning, under tvång. Han känner igen arbetet på beslaget i akt I ("Fint arbete. Fel kund.") och står bredvid Hedda vid städet. |
| **Jägaren Eira** | Akt III | Lunden var hennes skog. Hon vet vilka stigar som har spunnits igen, och hon hittar kokongen med brevet. |
| **Hulda Mossrot** | Akt III och IV | Hon kan folktron om troll och skog utan att vara trollkunnig (aldrig ockult): salt, stål och att man inte tackar för mat i berget. Hon känner igen vaggvisan. |
| **Lirien Silversträng** | Akt IV | Barden skriver ned vaggvisan och sjunger namnet i akt V. Hen vill skriva "något som faktiskt har hänt" (hens rad i värdshuset), och får göra det. |
| **Solveig** | Akt II | Elden och nåden, grälet med Ragnhild. Hon vill bränna biskopens kapell, men Ragnhild säger nej. |
| **Broder Tove** | Akt V | Munken som har övat tålamod. Han är den enda som Rådgivaren inte lyckas göra osäker, och han säger varför. |
| **Ronja Falkvind** | Akt III | Falken bär det första brevet ur Lunden, oläst, till Alrik. |
| **Sefir av Sanden** | Akt III | Hon har sett stämpeln på karavaner i söder, där man kallar den "den tomma tronens märke". Det första beviset på att hovet är större än landet (en krok efter slutet). |
| **Tor** (inte hjälte) | Akt I och V | Han lagade valvet när det började. I akt V hittar hans arbetare dörren till det tomma hovet under kryptans äldsta sal. |
| **Hedda** (inte hjälte) | Akt I och V | Hon ser att beslaget är gammalt arbete och inte sitt eget. I akt V bryter hon kronan. |
| **Sven** (inte hjälte) | Akt III | Den enda som har talat med Rådgivaren i borgen, genom porten. Han släppte inte in honom. |

---

## 7. Konkreta scener för de två nästa Realms

Format: **utlösare → scen → vem talar**. Repliker är förslag, med id som i `dialog.json`. Datanyckeln står efter pilen
(⚙ = ny kod).

### 7.0 Två luckor i akt II (kapellet) som bör fyllas först
| # | Utlösare | Scen | Vem |
|---|---|---|---|
| 0a | Första segern mot Den fallne biskopen | Berättarruta → `narrator.chapel_boss` (⚙ `Run.narrate` per boss, i dag bara `first_boss`) | Berättaren: *(Biskopens ring rullar över stengolvet. Infattningen är tom.)* *(Ingen klocka slår. I kapellet finns inga klockor kvar.)* |
| 0b | Hemkomst efter 0a, Alva i sällskapet eller i värdshuset | Hemkomstens samtal → `chronicle` nyckel `chapel_boss_alva` | Alva: "Han var snäll mot mig. Det är det värsta." |
| 0c | Samma hemkomst | `chronicle` `chapel_boss_gorm` | Gorm: "Ett löfte, inte en sak. Någon lovade honom tystnad. Vem lovar sådant?" |

### 7.1 Sidenlunden (akt III, Tråden)

| # | Utlösare | Scen | Vem talar |
|---|---|---|---|
| L1 | Första gången genom Lundens port | Berättarruta (`narrator.first_grove`) | Berättaren: *(Det är tyst i skogen. Inte stilla – tyst, som när någon håller andan.)* |
| L2 | Första gången i Lunden, Eira med | Replik på grottan (`barks` `new_realm`, `eira_grove_1`) | Eira: "Här gick handelsvägen. Den är borta. Någon har spunnit igen den." |
| L3 | Föremålet **Kokong** öppnas första gången | Resultattext (`objects.json` `results`) + krönikan | Berättaren: *(I kokongen ligger en kista. Beslagen har en stämpel du känner igen.)* |
| L4 | Strypvävaren (miniboss) besegrad första gången | Bark efter striden (`imma_grove_knot`) | Imma: "Hon valde alltid den som stod först. Precis som någon som har fått order." |
| L5 | Första segern mot Vävmodern | Berättarruta (`narrator.grove_boss`) | *(Vävmodern drar sig samman och blir stilla.)* *(I den största kokongen finns ett brev. Sigillet är en krona med en tom mitt.)* |
| L6 | Hemkomst efter L5 | Hemkomstens samtal, Alrik går till paladinen (`chronicle` `grove_boss_letter`) | Alrik: "Brevet är till dig, {namn}. 'Till den edsvurne i borgen. Ni svor i rätt tid.' Undertecknat K.R." |
| L7 | Samma hemkomst, efter L6 | Gorm (`chronicle` `grove_boss_gorm`) | Gorm: "De vet vem du är. Då vet de också var du bor." |
| L8 | Nästa besök i biblioteket | `alrik_crown_3` (idle, `min_bosses: 3`, ⚙ villkor `boss: web_mother`) | Alrik: "K.R. Kronans råd. Sju rådgivare kring en kung. Hans namn är struket ur varenda bok." |
| L9 | Nästa gång man går ut genom porten | Svens rad vid porten (`stations.gate`, ⚙ villkor `boss: web_mother`) | Sven: "En man i grå rock frågade efter dig i natt. Vid namn. Jag sa att du sov. Han sa att han kunde vänta." |
| L10 | Sefir med i en körning efter L6 | Lägereldens par (`pairs`, `sefir_imma_crown`) | Sefir: "Den stämpeln har jag sett på karavaner i söder." Imma: "Och du sa ingenting?" Sefir: "Ingen frågade. Ni frågar sällan saker." |
| L11 | Ronja med vid L5 | Bark (`ronja_grove_letter`) | Ronja: "Falken vill inte röra brevet. Han brukar ta allt." |

**Valfritt (VD):** Rådgivaren som vandrare på Lundens våning 2 efter L5, med en kortare scen. Han erbjuder ingenting, han
frågar bara: "Läste ni brevet? Det var vänligt menat."

### 7.2 Trollberget (akt IV, Namnet)

| # | Utlösare | Scen | Vem talar |
|---|---|---|---|
| T1 | Trollberget öppnas på kampanjkartan (efter kapellet djup 1 och Lunden, VD) | Rutan "Medan ni var borta" + hemkomstens samtal (`chronicle` `mountain_opens`) | Gorm: "Stenby skickar bud. Klockan är borta ur tornet, och berget står öppet om nätterna." |
| T2 | Första gången genom bergets port | Berättarruta (`narrator.first_mountain`) | *(Berget är varmt inifrån. Det luktar sot, mjölk och något som har legat länge.)* |
| T3 | Första gången i berget, Hulda med | Bark (`hulda_mountain_1`) | Hulda: "Tacka inte för maten här inne. Ät inte heller. Och säg inte ditt namn." |
| T4 | Trollmor Gråluva besegrad första gången, Lirien eller Hulda med | Bark (`lirien_lullaby_1`) | Lirien: "Hon sjöng för sin unge. Det var ett namn i visan. Inte hennes." |
| T5 | Brom (miniboss) besegrad | Bark (`brokk_brom_1`) eller Imma | Brokk: "Tull på en bro han inte har byggt. Det säger mycket om ett troll." |
| T6 | Vandrare på våning 2, första körningen efter T4 | Rådgivaren lämnar Bergakungens sal (vandrartyp ⚙) | Rådgivaren: "Ni igen. Jag har just talat med kungen här. Han är otålig." / "Jag kan erbjuda er något bättre än förra gången. Men det har ni redan gissat." / (avböj) "Altaret i er borg är vackert, har jag hört. Sten av det gamla slaget." |
| T7 | Första segern mot Bergakungen | Bergakungens sista replik (⚙ `death_line` i enemies.json) + berättarruta (`narrator.mountain_boss`, texten finns i `trollens-realm.md` §2) | Bergakungen: "Den förra kungen bar stenen i mitten. Era edsvurna bröt ut den. Fråga er gubbe var den ligger." Berättaren: *(Kronan var tung och kall. Infattningen var tom, och på insidan fanns samma stämpel.)* |
| T8 | Hemkomst efter T7 | Gorm går till paladinen. Hemkomsten blir ett längre samtal (4–6 repliker, `chronicle` `gorm_confession`) | Gorm: "Stenen ligger i altaret. Där du lade handen." / "Orden har vaktat den i tvåhundra år. Jag visste att de kunde vakna." / "Jag sa ingenting. Du skulle svära för deras skull, inte av rädsla." |
| T9 | Direkt efter T8 | Imma (`chronicle` `imma_angry_gorm`) | Imma: "Du skickade ned {namn} ensam. Och du visste." Gorm: "Ja." Imma: "…Jag är arg på dig i en vecka. Minst." |
| T10 | Nästa besök i biblioteket efter T4 och T7 | `alrik_name_1` (⚙ villkor: två bossar plus `lullaby_heard`) | Alrik: "Visan och rullan. Samma namn. Kungen hette … nej. Jag skriver det inte förrän vi behöver det." |
| T11 | Världshändelsen **Heddas lärling är bergtagen** vunnen | Hedda (`world` `apprentice_home`) | Hedda: "Hon säger att de hade en krona där inne som de putsade varje kväll. Med ett hål i mitten." |
| T12 | Efter T8, första gången vid altaret | Altarets rad (⚙ altaret får en replik, i dag ingen person) | Berättaren: *(Stenen i altaret är varm under handen. Den har alltid varit varm. Du har bara inte tänkt på det.)* |
| T13 | Efter T8, Tor på gården | Tor (`chronicle` `tor_door`, krok till akt V) | Tor: "Mina karlar hittade en dörr under kryptans äldsta sal. Den var murad från *andra* sidan." |

**Akt V börjar** med T13. Det tomma hovet öppnas på kampanjkartan som en ny ruta under borgen.

---

## 8. Vad som behövs i koden (översikt, inget byggs nu)

- `Run.narrate` per boss och Realm (i dag bara `first_gate` och `first_boss`): `narrator.<realm>_boss`, `first_<realm>`.
- Replikvillkor `boss: <id>` för stationer och borgens folk. Villkoret finns redan för Benfursten. Lägg till villkoren
  `lullaby_heard` och `act` (aktens nummer räknat ur besegrade bossar).
- **Vandrare i grottan** (ChatGPT:s Rådgivaren, Den avfallne, Arbetaren): en rutstyp eller ett föremål med val, som
  Realmens föremål. Detta är den största nya delen.
- `death_line` för bossar (en replik när de faller, visas efter segerskärmen).
- Krönikans nycklar för hemkomstens samtal finns (`chronicle`). Gorms bekännelse behöver ett längre samtal, som
  introts `talk`.
- Akt V: en ny Realm (`court`), slutbossens skeden, erbjudandet med två knappar och eftertexterna (en ny skärm).

---

## 9. Frågor till VD

1. **Avsändaren:** A (Kronans råd och Edsstenen), B (Den edslöse) eller C (Den namnlöse)? Förslaget: A med namnmotivet
   från C.
2. **Ordningen:** Lunden före Trollberget? Förslaget: krypta → kapell → lund → berg → hovet.
3. **Slutets djup:** djup 5 (före väggen) eller senare?
4. **Erbjudandet i slutet:** en skenbar valmöjlighet (TA EMOT stannar handen), ett riktigt val, eller inget val alls?
5. **Tre segrar** mot slutbossen för hela slutet, eller en?
6. **Rådgivaren** i akt V: slåss han, eller ser han bara på och försvinner?
7. **Biskopens bakgrund:** pesten och klockorna som ringde till begravning, eller något annat?
8. **Källornas trädgård:** blir den en senare Realm, så att leveranserna flyttas till Lundens kokonger?
9. **Gorms hemlighet:** är det rätt att han har vetat? Det gör honom bristfällig, men en del spelare kan uppleva det som
   svek.

---

## Källor

- RPGamer, "Kickstarter Check-In: Siralim Ultimate, Black Book" (2020): https://rpgamer.com/2020/05/kickstarter-check-in-siralim-ultimate-black-book/
- Siralim Ultimate wiki, Realms: https://siralimultimate.wiki.gg/wiki/Realms
- Steam, Siralim Ultimate-diskussioner (berättelsen, efter berättelsen):
  https://steamcommunity.com/app/1289810/discussions/0/3770113150035347768 ,
  https://steamcommunity.com/app/1289810/discussions/0/3412055301111162879
- Gamasutra, "Roguelikes and narrative design with Hades creative director Greg Kasavin": https://GamaSutra.com/design/roguelikes-and-narrative-design-with-i-hades-i-creative-director-greg-kasavin
- ScreenHub, "Hades' Greg Kasavin breaks down Supergiant's unique approach to narrative": https://www.screenhub.com.au/news-article/features/digital/jini-maxwell/hades-greg-kasavin-breaks-down-supergiants-unique-approach-to-narrative-262459
- SVG, "The True Ending Of Hades Explained": https://www.svg.com/314973/the-true-ending-of-hades-explained/
- Matthew Marchitto, "Darkest Dungeon and narrative context": https://matthewmarchitto.substack.com/p/darkest-dungeon-and-narrative-context
- Matthew Marchitto, "Darkest Dungeon 2 and ephemeral storytelling": https://matthewmarchitto.substack.com/p/darkest-dungeon-2-and-ephemeral-storytelling
- Bloody Disgusting, Darkest Dungeon II-recension: https://bloody-disgusting.com/video-games/3763251/darkest-dungeon-ii-review-how-the-new-sequel-improves-upon-an-already-great-game/
- NME, "Darkest Dungeon 2: how Red Hook are reinventing their roguelike classic": https://www.nme.com/features/darkest-dungeon-2-how-redhook-studios-are-reinventing-their-roguelike-classic-3085987
- Wildermyth wiki, Campaign och Legacy: https://wildermyth.com/wiki/Campaign , https://wildermyth.com/wiki/Legacy
- Wikipedia, Inscryption: https://en.wikipedia.org/wiki/Inscryption
- Interna: `docs/research/siralim.md` §8 och §10, `siralim-luckor.md`, `langsiktiga-mal.md`, `foljeslagare-relationer.md`.
