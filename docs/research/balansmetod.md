# Balansmetod – att balansera ett systemtungt spel med simulerade spelare

2026-10-24. Research (ingen kod ändrad, Godot inte kört). Frågan: hur balanserar andra spel med många kombinerbara delar,
vad säger forskningen om automatiska speltestare, och vad saknar våra botar (`tests/combat_bot.gd`,
`tests/balance_report.gd`, `tests/soak.gd` med `SOAK=karriar`, `docs/provspel/svarighetskurva.md`)?

Kort svar: våra botar mäter **nivåkurvan och nötningen** bra, men de mäter nästan inte **bygget**, som är spelets kärna.
Därför vet vi var en spelare med startmakron fastnar, men inte vad en tänkande spelare klarar eller vilka kombinationer
som är för starka. Siffrorna i rapporterna saknar dessutom felmarginaler, och 100 körningar ger ungefär ±10
procentenheter. Det är för grovt för de flesta beslut vi fattar på dem.

---

## 1. Hur andra gör (med källor)

### 1.1 Slay the Spire: mätvärden från spelarna, först och hela tiden

Anthony Giovannetti (Mega Crit) höll föredraget *"Slay the Spire: Metrics Driven Design and Balance"* på GDC 2019.
Studion byggde in mätningar tidigt och använde dem under hela Early Access: en egen metrikserver, plockfrekvens och
vinst per kort, och en Slack-kanal där datan diskuterades. Han varnar för att siffror kan vilseleda om man tolkar dem
slarvigt. Han sa också att ett enspelarspel tål en sällsynt övermäktig kombination, eftersom den inte drabbar någon
annan. Varje kort ska ha en plats, men alla behöver inte vara lika starka. Ascension-nivåerna (en stege av svårighet)
och veckovisa uppdateringar med feedback från Discord och streamare formade balansen.
([GDC:s presentation](https://gdconf.com/news/learn-slay-spires-successful-metrics-driven-approach-game-balancing-gdc-2019),
[Game Developer](https://www.gamedeveloper.com/design/learn-i-slay-the-spire-i-s-metrics-driven-approach-to-game-balancing-at-gdc-2019),
[GDC Vault](https://www.gdcvault.com/browse/gdc-19/play/1025731))

Nivåerna i StS är låga med flit. Enligt Mega Crits egen statistik för Slay the Spire 2 (maj 2026, 240 miljoner
körningar, återgiven i andra hand) vinns 25 % av alla körningar. På Ascension 0 vinns 16 %, mot 9 % i ettan.
([gamegeeker, sammanfattning](https://gamegeeker.com/fr/news/slay-the-spire-2-may-neows-news-update?market=FR))
Lärdomen är att målvinsten beror på genren. I en roguelike där varje körning är kort är förlust normalt. Vår körning
är längre och förlusten kostar mer (Realmen börjar om), så våra mål ska ligga högre (§4).

### 1.2 Monster Train: instrumentpaneler och klanpar

Shiny Shoe har berättat att deras interna paneler följer plockfrekvens per kort, vinst per **kombination av klaner** och
medianen av förlorat liv per strid. Datan är svår att tolka djupt, men uppenbara fel syns snabbt. De kombinerar egna
speltester, betatestare och datainsamling. Covenant är en stege av svårighet för de som vill ha mer.
([Film Stories, förhandstitt 2020](https://filmstories.co.uk/gaming/monster-train-literally-a-train-full-of-monsters/))
Två saker att ta efter: att mäta **par av byggdelar** (hos oss kall × trofé, trofé × trofé) och att mäta **förlorat liv**
utöver vinst eller förlust. Livet säger något även när alla vinner.

### 1.3 Legends of Runeterra och Hearthstone: vinst, spelfrekvens och "inte allt på 50 %"

Riot vägde kortens vinst (särskilt i bästa regionparet), lekarnas vinst och mästarnas spelfrekvens. Spelfrekvensen är
en egen signal: ett kort ingen väljer är ett problem även om dess vinst är normal. De sa uttryckligen att mätvärdena är
ett verktyg och inte målet, och att alla kort på exakt 50 % inte vore roligt.
([Inven Global, patch 1.2](https://www.invenglobal.com/legendsofruneterra/articles/11264/legends-of-runeterra-patch-12-balances-new-mechanics-from-rising-tides),
[Out of Games, intervju](https://outof.games/legends-of-runeterra/921-riot-discusses-the-state-of-the-legends-of-runeterra-beta-mobile-balance-card-backs-card-styles-more))

Forskningen kring Hearthstone använder simulering för att leta byggen: genetiska algoritmer som bygger lekar och testar
dem mot ett urval av mänskliga lekar i en simulator (García-Sánchez m.fl., IEEE CIG 2016,
[UCA](https://produccioncientifica.uca.es/documentos/640d406a4531f424f8818a16?lang=en)), evolution som hittar lekar
som slår spelarnas ([Exploring the Hearthstone Deck Space](https://researchwith.njit.edu/en/publications/exploring-the-hearthstone-deck-space/)),
och evolution av kortens siffror så att matchupper närmar sig 50 % med så små ändringar som möjligt
([Evolving the Hearthstone Meta](https://researchwith.njit.edu/en/publications/evolving-the-hearthstone-meta/)).
Fontaine m.fl. använder **MAP-Elites** (en "kvalitet och mångfald"-algoritm) för att kartlägga *olika* sätt att spela
bra, längs valda beteendeaxlar, och visar att mönstren i kartan pekar på vad som behöver balanseras om
([arXiv 1904.10656](https://arxiv.org/pdf/1904.10656), uppföljare med en ytlig modell som förutsäger utfallet så att
färre simuleringar behövs: [Deep Surrogate Assisted MAP-Elites](https://ar5iv.labs.arxiv.org/html/2112.03534)).

### 1.4 Automatiska speltestare i forskningen och industrin

- **Procedurella personor** (Holmgård, Cerny Green, Liapis, Togelius, IEEE Transactions on Games 2019): botar byggda
  på MCTS där varje persona har egna vikter för vad den värderar (skatt, fiender, snabbhet …). Personorna ersätter
  designern eller olika sorters spelare när mycket innehåll ska prövas.
  ([arXiv 1802.06881](https://arxiv.org/pdf/1802.06881), [AIIDE-versionen](https://ojs.aaai.org/index.php/AIIDE/article/view/12849))
  Samma grupp prövade det på match-3 (Bejeweled, Candy Crush) ([arXiv 1907.06570](https://ar5iv.arxiv.org/html/1907.06570)).
- **King, Candy Crush** (Gudmundsson m.fl. 2018, *Human-Like Playtesting with Deep Learning*): ett nätverk lärs att
  välja det drag en *människa* skulle välja, och dess vinst per bana förutsäger banans svårighet bättre än MCTS och
  mycket snabbare. Poängen är att boten ska likna spelarna, inte vara bäst.
  ([PDF](https://www.Gwern.net/doc/reinforcement-learning/imitation-learning/2018-gudmundsson.pdf),
  [kommentar](https://koaning.io/posts/playtesting))
- **EA SEED** (Gillberg m.fl. 2023, *Technical Challenges of Deploying RL Agents for Game Testing in AAA Games*): RL
  som komplement till skriptade testbotar i Battlefield och Dead Space; skriptade botar är effektiva men inte
  tillräckligt rörliga. ([arXiv 2307.11105](https://arxiv.org/abs/2307.11105v1),
  [SEED](https://www.ea.com/seed/news/seed-ml-research-aaa-game-testing))
- **EA, *Winning Isn't Everything*** (2019): agenter som ska utforska beteenden som svarar på designerns frågor, inte
  vinna. En simulerande agent hittade obalanserade handlingar, belöningar som inte spelade roll och valfria
  strategier som inte lönade sig. ([arXiv 1903.10545](https://arxiv.org/pdf/1903.10545))
- **Restricted play** (Jaffe m.fl., AIIDE 2012): balans mäts genom att låta en *begränsad* agent (som inte får använda
  en viss del) spela mot en obegränsad. Hur mycket sämre den begränsade blir säger hur mycket delen är värd. En del
  som ingen klarar sig utan är dominant.
  ([AAAI](https://ojs.aaai.org/index.php/AIIDE/article/view/12513), [PDF](https://cdn.aaai.org/ojs/12513/12513-52-16035-1-2-20201228.pdf))
- **Överlevnadsanalys** (Isaksen och Nealen m.fl.): Monte Carlo-simulering med hasardfunktioner visar *var* i en bana
  svårigheten ligger, i stället för en enda vinstsiffra. Zook, Harrison och Riedl simulerar spelare av olika skicklighet
  med planerande agenter ([arXiv 1908.01423](https://arxiv.org/pdf/1908.01423)). Pfau m.fl. bygger generativa
  spelarmodeller ur 213 spelares handlingar och hittar obalans mellan klasser i ett MMORPG
  ([Dungeons & Replicants](https://antoniosliapis.com/papers/dungeons_replicants_automated_game_balancing_across_multiple_difficulty_dimensions_via_deep_player_behavior_modeling.pdf)).
- **Agenter och skicklighet kontra tur** ([arXiv 2304.08699](https://arxiv.org/pdf/2304.08699)): jämför svårighet
  mellan versioner och mäter om spelet kräver skicklighet genom att låta agenter av olika styrka spela.

### 1.5 Siralim

Thylacine Studios har inte publicerat någon balansmetod, och sökningen gav inga föredrag. Det som syns i patchnoterna:
fiendernas svårighet steg först linjärt med Realm-djupet och gjordes sedan till en **kurva** som märks först djupt ned
(Siralim 1.0.12); Nether-fiendernas styrka fick ett tak; Realm Instability (1–5) öppnas efter djup 33. Spelarnas egen
beskrivning: svårigheten styrs bara av djup, vald svårighetsgrad och instabilitet.
([ModDB, Siralim 1.0.12](https://www.moddb.com/games/siralim/news/siralim-1012-has-been-released),
[wiki: Realms](https://siralimultimate.wiki.gg/wiki/Realms),
[Thylacine](https://thylacinestudios.com/))
Siralim har alltså **en** skalning av fienderna efter djupet. Vi har två som multipliceras (§3.3).

---

## 2. Statistik: hur många körningar behövs?

En vinstandel är en andel ur n oberoende försök. Felmarginalen (95 %) är ungefär `1,96 · √(p(1−p)/n)`.

| Mål | p ≈ 0,5 | p ≈ 0,8 eller 0,2 | p ≈ 0,9 eller 0,1 |
|---|---|---|---|
| ±10 pp | 97 | 62 | 35 |
| **±5 pp** | **385** | **246** | **139** |
| ±3 pp | 1 068 | 683 | 385 |

Våra rapporter kör oftast **100 körningar per rad: ±10 pp** vid 50 %. Karriärens 80 profiler per nedstigning: ±11 pp.

**Små tal och nollor.** Använd Wilson-intervallet, inte `p ± …`, nära 0 och 100 % och när n är litet:
`(p + z²/2n ± z·√(p(1−p)/n + z²/4n²)) / (1 + z²/n)`, z = 1,96. Exempel från svårighetskurvan:
- Djup 7 i kryptan, 0 av 8: sanna vinsten ligger någonstans mellan **0 och 32 %**. "0 %" säger nästan ingenting.
- Djup 6 i kryptan, 14 % av 57: **7–25 %**.

**Att jämföra två versioner.** Att upptäcka en skillnad på 5 pp mellan två oberoende mätningar vid 50 % (95 %, styrka
80 %) kräver ungefär **1 570 körningar per sida**. Det är dyrt. Två sätt att komma billigare undan:

1. **Parade frön (common random numbers).** Kör samma frön i båda versionerna och räkna bara de frön där utfallet
   skiljer sig (McNemars test). Våra rapporter kör redan frö 1…RUNS i varje rad, så parningen finns, men den utnyttjas
   inte. Varningen: om en ändring förbrukar slumptalen i en annan ordning glider fröna isär, och då hjälper parningen
   mindre. Separata slumpströmmar per syfte (karta, strid, fynd, botens val; soak.gd har redan `pick` åt sig) gör den
   starkare.
2. **Sekventiell testning.** Kör i omgångar om 100 och sluta när intervallet inte längre överlappar målbandet. De
   flesta raderna är långt från gränsen och behöver bara 100.

Exempel: svårighetskurvans "efter rättelsen" (nedstigning 2: 26 → 41 %, 80 profiler var) är ungefär två
standardfel, alltså troligen verklig. Nedstigning 4 (54 → 44 %) är inom bruset.

**Vad som ska stå i varje rad:** n, andelen, Wilson-intervallet och, vid en jämförelse, skillnaden med intervall.

---

## 3. Vår botsvit: vad den mäter bra och vad den inte ser

### 3.1 Vad som finns

| Verktyg | Vad det gör |
|---|---|
| `combat_bot.gd` BASIC / MACRO / TUNED | BASIC anfaller alltid; MACRO kör startmakrona (eller en ny profils få rader); TUNED handskrivna förbättrade makron för de fyra första hjältarna och några följeslagare. Saknas en rad försvarar hjälten. |
| `run_expedition` + policyer | Hela grottkörningar: simple, greedy, careful, direct (spåren). Lägereld när Charges tar slut. |
| `balance_report.gd`, 15 `BALANS=`-lägen | Våningar, hela körningar, kall, perks, artefakter (med `built_artifact`: rollens bärnsten, trick och Nether Stone), sällskapsstorlek, första nedstigningen, grottan, elitgrupper ensamma och under nötning (sparade lägen), svar på elitgrupper, löften, levande kartan, nivåer. |
| `perk_report.gd` | Varje perk för sig. |
| `soak.gd` | Slumpade upplägg för att hitta fel (krascher, låsningar, sparfel); `SOAK=karriar`: 80 profiler × 18 nedstigningar med spelets riktiga flöde. |
| `numbers_audit*` | Formlerna räknas om oberoende. (Det är korrekthet, inte balans, och det är föredömligt.) |

### 3.2 Vad den mäter bra

- **Nivåkurvan och nötningen över en körning.** Karriären är exakt det verktyg som saknas i de flesta indiespel: den
  visade väggen vid nedstigning 2, platån på djup 1, självbalanseringen kring 45 % och taket vid djup 6–7.
- **Var man förlorar** (`lost_at`, "v1 elit", "v2 boss"). Det är en grov form av överlevnadsanalys (§1.4).
- **Elitgrupper under riktig nötning** (sparade lägen i stället för fulla Charges). Det är bättre än de flesta.
- **Fel och dödlägen** (soak hittade Asketens eviga strid).
- **Fasta frön**, så att allt går att köra om.

### 3.3 Blinda fläckar, i ordning efter hur mycket de snedvrider

1. **Boten bygger inte.** Troféer väljs slumpvis (`_battle_finished`, `_swap_trophies`), inga material sätts in i
   karriären (`built_artifact` finns bara i `BALANS=artefakter`), perken är alltid den billigaste, kallet alltid Domens
   kall, artefakten alltid ett svärd med hjältens första förmåga. **Spelets ledstjärna är kombinationerna**, och de mäts
   inte av något som efterliknar en spelare som väljer. Följden: kurvan visar golvet, inte vad en tänkande spelare når,
   och vi vet inte om taket vid djup 6–7 är verkligt eller en följd av att boten aldrig blir starkare av sina val.
2. **Makrona utvecklas aldrig.** Makron är kärnsystemet. En spelare skriver om dem efter förluster. MACRO-boten kör
   samma rader i 18 nedstigningar; TUNED finns bara för de första hjältarna och för dagens fiender (rader mot
   `grave_pact`, `cultist_ward`). Nya fiender och familjer (Trollhud, Benfolket, Kultens folk) har inga svar i TUNED.
3. **Dubbel djupskalning (känd).** `CombatSim.DEPTH_STEP` (+8 % per djup) multipliceras med nivåskalningen (+30 % per
   nivå, 5 nivåer per djup). Siralim har en skalning (§1.5). Allt vi balanserar på djup 4+ ovanpå detta riskerar att
   bli fel när det rättas. **Bestäm detta först**, innan något annat på djupet justeras.
4. **Inga felmarginaler.** Raderna saknar n och intervall; beslut har fattats på skillnader på 5–10 pp mellan rader om
   100 (§2).
5. **Inga mål att mäta mot.** Varje rapport jämförs med förra versionen och med magkänslan. Det finns få uttalade mål
   (första nedstigningen ~80 %, fyra hjältar ~40 % per körning) och inget band per djup (§4).
6. **Inga byggen jämförs mot varandra.** Ingen sökning efter dominanta kombinationer. "Krigsmaskin är starkast" och
   "perk-nivåer väljs aldrig" (känd brist i CLAUDE.md) upptäcktes för hand i `perk_report`. Par (kall × trofé, trofé ×
   trofé, artefaktens förmåga × trofé) mäts aldrig.
7. **En sorts spelare.** Ingen persona som är försiktig med Charges, som backar, som tar löften, som går hem, eller som
   spelar MANUELL med misstag. `soak.gd` har policyer (random, bot_careful, bot_greedy) och slumpade handlingar, men
   de används för fel, inte för balans.
8. **Bara vinst.** Inget mått på *hur nära* det var (förlorat liv, stupade, Charges kvar), hur långa striderna är, eller
   om valen spelade roll. "Bevisa att det är roligt att kombinera" kräver ett mått på val som gör skillnad (§5.7).
9. **Ingen koppling till människor.** Botarna är aldrig kalibrerade mot VD:s egna körningar. King visade att det
   viktiga är att boten och människorna förlorar *på samma ställen* (§1.4).
10. **Inget skydd mot regressioner.** Det finns ingen `.github/workflows`, och balansen kontrolleras bara när någon kör
    en rapport.

---

## 4. Målband per djup (förslag till VD, inget beslut)

Ett band per persona och djup gör varje rapport till ett ja eller nej. Förslag, för en hel körning (två våningar) på
väntad nivå, instabilitet 0:

| Läge | Startmakron (MACRO) | Tänkande spelare (GREEDY-BUILD, §5.1) | Kommentar |
|---|---|---|---|
| Första nedstigningen | 75–90 % | – | Introt ska bära. I dag 83 %. |
| Djup 1–2 | 50–70 % | 75–90 % | Lära sig systemen. |
| Djup 3–5 | 35–55 % | 65–85 % | Bygget ska märkas: minst +20 pp över MACRO. |
| Djup 6–10 | 15–35 % | 50–75 % | Här ska makron och byggen bära, som i Siralim. |
| Instabilitet n | – | högst −10 pp per nivå | Silver och troféer betalar riskbiten. |

Två regler som är viktigare än själva siffrorna:

- **Avståndet mellan personorna är måttet på djupet i systemen.** Om GREEDY-BUILD bara är 5 pp över MACRO lönar sig
  inte att bygga. Om skillnaden är 60 pp är spelet ogenomträngligt utan guide.
- **Inget bygge får vara mer än ~15 pp bättre än näst bästa i en roll** (efter Riots "spelfrekvens"-tanke): då slutar
  spelarna välja. Undantag får finnas, som StS säger, men de ska vara sällsynta och kosta något (bosstroféerna).

---

## 5. Förbättringar, rangordnade

Rangordningen väger nytta mot arbete. Allt är headless och kan köras i bakgrunden; inget kräver Godot-fönster.

### 5.1 En bot som bygger girigt (GREEDY-BUILD) – högst nytta

En persona som fattar byggbesluten genom att **pröva**:
- **Trofé** (efter strid och vid lägereld): för varje kandidat och hjälte, spela K = 20 korta strider mot nästa
  våningsgrupps fiender från ett sparat läge (infrastrukturen finns: `attrition_fight`, sparade lägen i
  `BALANS=elitnotning`, svaren i `BALANS=elitsvar`). Välj den som höjer vinst och sparat liv mest. Billigare variant:
  en tabell över varje trofés värde per roll som byggs en gång av §5.3 och slås upp.
- **Material**: sätt in rollens bärnsten och trick (`ROLE_AMBER`, `ROLE_TRICKS`, `ROLE_STONE` i balance_report finns
  redan), och Nether Stones efter samma prövning.
- **Perks och nivåer**: prova varje köp som ryms i potten (inklusive en extra nivå och den lånade perken), välj bästa.
  Det svarar direkt på den kända bristen "perk-nivåer väljs aldrig": antingen är de för svaga, eller så väljer boten
  bara fel.
- **Kall** och **artefaktens förmåga**: samma sak, hemma mellan nedstigningarna.

Kör karriären med GREEDY-BUILD bredvid MACRO. Då får vi två kurvor, golvet och en rimlig tänkande spelare, och kan
avgöra om taket vid djup 6–7 är verkligt.

### 5.2 Felmarginaler, n och parade jämförelser i alla rapporter – billigast

En hjälpfunktion `wilson(k, n)` i en delad fil som varje rad använder: `46 % [36–56] n=100`. Vid jämförelser av två
rader på samma frön: skillnaden, antalet frön där utfallet skiljer sig, och McNemar. Omgångar om 100 tills intervallet
ligger helt i eller helt utanför målbandet (§2). Separata slumpströmmar per syfte i `RunState` och `CombatSim` gör
parningen tålig.

### 5.3 Byggsökning efter dominanta kombinationer

1. **Ablation enligt Jaffe ("restricted play")**: ta bästa bygget, ta bort en del i taget (trofén, perken, kallet,
   artefaktens förmåga) och mät tappet. En del som bär mer än ~20 pp ensam är en kandidat till "dominant".
2. **Parmätning** (Monster Train): vinst för varje par kall × trofé och trofé × trofé på samma hjälte eller i samma
   sällskap, mot förväntat från delarnas egna värden. Par som slår förväntan stort är **kombinationer**, det vi vill ha
   fler av; par som slår allt annat är problem.
3. **Lokal sökning** (koordinatvis: byt en del i taget till den bästa, upprepa tills inget förbättras) över kall,
   perks, troféer per hjälte och artefakttyper, från flera slumpade start. Om alla starter hamnar i samma bygge finns
   ett dominant bygge.
4. Senare, om det behövs: **MAP-Elites** (Fontaine m.fl.) med beteendeaxlar som andel skada från egenskaper kontra
   förmågor, och andel helning. Då ser man om det finns flera olika bra sätt att spela, eller bara ett.

Börja med 1 och 2: de är små och svarar på frågor vi redan har (Krigsmaskin, Brokks sköld med Helande ljus).

### 5.4 Fixa den dubbla djupskalningen före all annan djupbalans

Antingen tas `DEPTH_STEP` bort och nivåskalningen ensam bär djupet (Siralims modell), eller så görs nivåtrappan
flackare. Kör karriären före och efter med parade frön. Inget annat på djup 4+ ska justeras innan.

### 5.5 Målband i rapporterna och en balansvakt

Lägg banden från §4 i en datafil (t.ex. `tests/balance_targets.json`) och låt rapporterna skriva OK, LÅG eller HÖG
per rad. Sedan en snabb **balansvakt** (`BALANS=vakt`): ett tiotal rader med fasta frön (första nedstigningen, djup 1
och 3 per Realm, en elitgrupp per Realm, ett bygge med artefakt), 100 körningar var, som misslyckas om en rad hamnar
utanför sitt band med marginal (intervallet helt utanför). Den körs före varje APK. GitHub Actions med Godot headless
går (Godot finns som Linux-binär), men eftersom spelet byggs lokalt och iMacen ska hållas sval är en lokal vakt före
release ett rimligt första steg, och en molnkörning ett andra som också avlastar datorn.

### 5.6 Personor i stället för BASIC/MACRO/TUNED

Efter Holmgårds procedurella personor: några få spelare med olika vikter, samma kod.
- **Nybörjaren**: en ny profils makron, ändrar aldrig, slåss mot allt, slumpade troféer (dagens MACRO).
- **Den försiktige**: backar från vanliga grupper, sparar Charges, går hem efter två stupade.
- **Byggaren**: GREEDY-BUILD (§5.1).
- **Den lärande**: lägger till makroförslagen och en rad efter varje förlust ur en liten katalog av svar (rader som
  dagens TUNED-rader, valda efter förlustorsaken: dödades av helaren → "döda helaren först", tappade mot Benrustning
  → "besvärjelser mot Benrustning"). Det mäter om makrosystemet går att lära sig av förluster, vilket är spelets
  löfte.
- **Den slarvige**: MANUELL med 10–25 % felval (finns i soak som `p_random_action`).

Skillnaden mellan personorna på samma djup är det viktigaste talet i hela sviten (§4).

### 5.7 Fler mått än vinst

Per strid och körning: förlorat liv i procent, stupade, Charges kvar, antal turer, och **valets vikt**: för varje
trofébeslut, skillnaden i vinst mellan bästa och sämsta valet (från §5.1:s prövningar). Om den skillnaden nästan alltid
är liten spelar trofévalet ingen roll; om den alltid är stor för samma trofé är den dominant. Det är ett direkt mått på
ledstjärnan ("byter spelaren frivilligt en trofé efter en ny kombination?"). Förlorad plats som hasard per rumstyp och
våning (Isaksen) ersätter dagens räknade `lost_at`.

### 5.8 Kalibrering mot människor

Logga VD:s egna körningar lokalt (`user://chronicle` eller en enkel logg: djup, sällskap, troféer, var man förlorade,
antal makrorader) och jämför med personorna på samma djup och nivå. Målet är inte samma vinst utan **samma
förlustställen** (King). När en persona förlorar på andra ställen än människan, är det personan som behöver ändras.
Ingen data lämnar telefonen; filen skickas för hand om VD vill.

### 5.9 Mindre saker

- TUNED-raderna behöver svar för de nya familjerna (Trollhud, Benfolket, Kultens folk, De fallna), annars mäter TUNED
  bara 0.16:s fiender.
- Karriären ska kunna slumpa kall, instabilitet och löften per profil, så att kurvan inte bara gäller Domens kall och
  instabilitet 0.
- Botens "ingen rad passar → Försvara" är en egen strategi som ingen människa väljer; räkna hur ofta den slår till
  (`no_match` finns) och visa det i rapporten.

---

## 6. Sammanfattning

| Rang | Förbättring | Arbete | Svarar på |
|---|---|---|---|
| 1 | Wilson-intervall, n och parade jämförelser i alla rapporter | litet | Är skillnaden verklig? |
| 2 | Bestäm den dubbla djupskalningen innan djupet balanseras | litet | Taket vid djup 6–7 |
| 3 | GREEDY-BUILD: troféer, material, perks (med nivåer) och kall väljs genom prövning | medel | Vad når en tänkande spelare? Väljs perk-nivåer? |
| 4 | Ablation och parmätning av byggdelar | litet–medel | Dominanta delar och riktiga kombinationer |
| 5 | Målband per djup och persona, balansvakt före APK | litet | Regressioner |
| 6 | Personor (försiktig, lärande, slarvig) | medel | Går makrona att lära sig? |
| 7 | Fler mått: förlorat liv, Charges, valets vikt, hasard per rum | litet | Är valen meningsfulla? |
| 8 | Kalibrering mot VD:s egna körningar | litet | Liknar botarna spelarna? |
| 9 | Lokal sökning / MAP-Elites över byggen | stort | Finns flera sätt att spela bra? |

**Körningar för ±5 pp: ungefär 385 vid 50 %, 250 vid 80 %, 140 vid 90 %.** Dagens 100 ger ±10 pp. För att se en
skillnad på 5 pp mellan två versioner krävs ~1 570 per sida utan parning, betydligt färre med samma frön.
