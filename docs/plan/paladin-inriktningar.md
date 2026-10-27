# Paladinens inriktningar: Sköldbäraren och Ljusbäraren

Plan för VD:s godkännande, 2026-10-27. Ingenting är byggt. Prototypen för botarna ligger i `tests/paladin_specs.gd` och
ändrar bara en kopia av datan.

VD (2026-10-27): paladinen är den man spelar själv, men han är tråkigast. Han har Anfall, Rättfärdigt slag och Helig
sköld, ser ut som en tank och gör vanliga slag. Han ska vara roligast. Två inriktningar, **tank** (favoriten) och
**helare** ("underskattat roligt"), ingen skadeinriktning. "Det viktigaste bygget vi har, det måste bli bra."

## Byggt (grenen `paladin-paths`, 2026-10-28): steg 1–3

VD svarade "kör dina" på de tolv frågorna och tog alla rekommendationer. Steg 1–3 i byggordningen är byggda. Steg 4
(tajmingen) och resten väntar på VD:s provspel. Där bygget avviker från planen nedan gäller bygget.

**Siffrorna i spelet** (sänkta mot planen, VD: bara lite över dagens paladin):

| | Sköldbäraren | Ljusbäraren | Dagens paladin |
|---|---|---|---|
| Health / Attack / Intelligence / Defense / Speed | 105 / 9,5 / 8,8 / 6,5 / 9 | 90 / 9,5 / 10,5 / 4,5 / 11 | 90 / 9,5 / 9,5 / 5 / 10 |
| Kärna | Edens sköld: 15 % av varje träff mot de andra, räknas mot hans Försvara, Beskyddad och Emellan | Gryningens hand: 20 % av hans direkta skada helar den svagaste; ersätter Gryningens kalls egen del | Kallet |
| Glöd av | träffar mot honom och träffar Edens sköld tar | varje helning han gör | – |
| Rättfärdigt slag förbrukar all | +20 % skada, 3 Barriär och 3 helning åt honom per Glöd | +15 % skada, 2 Barriär åt den svagaste per Glöd | – |
| Förmågor | Rättfärdigt slag, Kasta sig emellan (6, nedkylning 2), Helig sköld, Befäl | Rättfärdigt slag, Förutseende ljus (160 % Int, 6), Gryningsvåg (75 % Int åt alla, 4), Befäl | Rättfärdigt slag, Helig sköld |

- **Befäl** kostar 3 Glöd och ger en allierad en extra handling direkt (en extra post först på tidslinjen, den vanliga
  ligger kvar) och +30 % på nästa anfall.
  - **Spärrar:** aldrig paladinen själv, aldrig någon som inte kan agera (sover, frusen), aldrig samma allierad två gånger
    inom en runda (antalet levande turer), och Glöden är spärren mot att det sker ofta.
- **Edens startrader** (färdiga rader och klossar, Gambits):
  - Sköldbäraren:
    1. Om någon fiende laddar → Kasta sig emellan
    2. Om någon allierad har liv < 40 % → Helig sköld på den
    3. Om Glöd minst 3 → Rättfärdigt slag (förmågans förvalda mål)
  - Ljusbäraren:
    1. Om någon allierad är laddningens mål → Förutseende ljus på den
    2. Om någon allierad har liv < 40 % → Gryningsvåg
    3. Om Glöd minst 3 → Rättfärdigt slag
  - Eden lär också ut klossarna Glöd minst … och Laddar respektive Bär laddningen.
  - Är målet för ett anfall är ett fynd: Benspringaren, Blodsvuren och Hullingspindeln.
- **Befäl står inte i startraderna** (avvikelse från planen). Som automatisk rad ("Befäl på den med högst Attack" när
  Glöden räcker) sänkte det vinsten kraftigt (tabellen nedan): paladinen ger bort sin egen tur och tre Glöd för en
  allierads vanliga handling, och Rättfärdigt slag får aldrig Glöd. Befäl är ett verktyg för handen och för gambits
  ("Befäl på Imma före Rökpil"), inget att lägga på automatik.

### Botarna, före och efter (`tests/paladin_paths_report.gd`, 100 nedstigningar per rad, samma frön)

**Mätningen fick ändras mot planen.** Sedan gambits-3 har en ny profils följeslagare bara en rad var. Då är huvudbossen
på djup 1 nästan omöjlig för alla, också för dagens paladin: 0 % i båda Realms, Benfursten 0–2 av 19 även på nivå 6. Och
djup 3 på väntad nivå (7) vinns av alla till 96–100 %. Därför mäts två lägen:
- **A.** Följeslagarna kör sina fulla startmakron (en profil som har hittat sina rader), djup 1 och 3 på väntad nivå.
- **B.** En ny profils makron på djup 3, en nivå över den väntade (nivå 8), där skillnaderna syns.

Paladinen har alltid bara edens rader och Gorms rad, så jämförelsen gäller inriktningen och inte makrona. Domens kall i
alla rader. Vinst i procent, och inom parentes hur ofta minst en hjälte stupade.

| Läge | Realm | Djup, nivå | Dagens paladin | Sköldbäraren | Ljusbäraren |
|---|---|---|---|---|---|
| A, Paladinen + Brokk, Alva, Eira | Kryptan | 1, nivå 3 | 73 (74) | **82** (37) | **78** (63) |
| | Kapellet | 1, nivå 3 | 64 (59) | **71** (35) | **71** (38) |
| | Kryptan | 3, nivå 7 | 97 (24) | 99 (3) | 97 (25)* |
| | Kapellet | 3, nivå 7 | 96 (25) | 99 (16) | 98 (18)* |
| A, **utan Alva** (Brokk, Imma, Eira) | Kapellet | 1, nivå 3 | 69 (65) | **77** (45) | **79** (40) |
| | Kapellet | 3, nivå 7 | 100 (28) | 99 (27) | 99 (21)* |
| B, ny profils makron | Kryptan | 3, nivå 8 | 82 (79) | **93** (19) | **91** (31) |
| | Kapellet | 3, nivå 8 | 70 (65) | **77** (78) | **88** (63) |
| A, med raden Befäl (prov)* | Kryptan | 1, nivå 3 | 73 | 45 | 68 |
| | Kapellet | 1, nivå 3 | 64 | 11 | 57 |

\* Mätt före Ljusbärarens sista justering (Gryningsvåg 75 → 65 %, Förutseende ljus 160 → 140 % av Intelligence); på djup
3 och väntad nivå vinner alla ändå.

**Före justeringen** (planens siffror sänkta en gång, Edens sköld 15 %, Rättfärdigt slag +15 % och 2 + 2 per Glöd,
Attack 8,8, Ljusbärarens Int 11 och hand 25 %): Sköldbäraren låg *under* dagens paladin (kryptan djup 1 68 mot 73,
läge B 76 mot 82, kapellet B 29 mot 70), Ljusbäraren +7 till +14. Sköldbäraren fick då tillbaka Attack 9,5, Health 105 och
mer ur Glöden, och Ljusbäraren lite mindre Intelligence och 20 % hand.

**Så ska tabellen läsas**
- **Båda ligger nu +5 till +11 enheter över dagens paladin** där skillnaderna syns. Ljusbäraren i kapellet läge B (+18)
  är undantaget; den sista justeringen ändrade det inte (Gryningens hand mot kapellets många små träffar). Planens första
  förslag gav +20 till +30.
- **Ingen dominerar.** De är lika i kryptan, Ljusbäraren leder lite i kapellet, och Sköldbäraren minskar dödsfallen mest
  (kryptan djup 1: minst en stupad 74 → 37 %).
- **Sköldbäraren utan Alva i kapellet** är nu bättre än dagens paladin (77 mot 69). I planens prototyp var den sämre.
  Skillnaden är att Edens sköld räknas mot hans försvar och att Glöden helar honom.
- **Brus:** ±5 enheter vid 100 nedstigningar. Djup 3 på väntad nivå säger ingenting, där vinner alla.
- **Befäl på automatik är en fälla** (sista raderna). Det behöver provspelas för hand. Om det inte känns värt tre Glöd och
  en tur där heller, är nästa steg att Befäl inte tar paladinens tur (en fri handling), men det är mycket starkt och måste
  mätas för sig.

## Sammanfattning

1. Två inriktningar som ändrar vad paladinen *är*: **Sköldbäraren** (tank) och **Ljusbäraren** (helare). Stats, kärna och
   förmågor kommer från inriktningen. Kallet är kvar som det är, en regel för hela sällskapet, och väljs fritt.
2. Båda bygger **Glöd** (0–5, nollas mellan striderna). Tanken får Glöd när han tar slag, också åt andra. Helaren får den
   när han helar eller när hans Barriär tar ett slag. Glöden spenderas på **Rättfärdigt slag** (all Glöd, det stora
   slaget) och på **Befäl** (3 Glöd).
3. Båda har **Befäl**: en allierad agerar direkt, en extra handling nu. Det är så paladinen dirigerar kombinationerna
   (Imma: Rökpil nu, sedan ett fullt slag mot de förblindade). Botarna visade att Befäl som tidslinjeflytt inte gav
   något, så det görs om.
4. Tankens kärna **Edens sköld** tar 20 % av varje träff mot de andra. **Kasta sig emellan** tar fiendernas anfall till
   nästa tur, och mot ett varslat bosslag kan spelaren tajma ett tryck för att ta ännu mindre.
5. Helarens kärna **Gryningens hand** helar den svagaste för 30 % av skadan han gör. **Förutseende ljus** lägger en
   Barriär på den som slaget pekar på *innan* det kommer, och **Gryningsvåg** helar alla.
6. Tajmingen gäller bara varslade bosslag. Den skickas in i stridslogiken som ett resultat (miss, bra, perfekt), så att
   botarna kan räkna med en antagen träffsäkerhet. Inställningen har lägena av, lätt och full.
7. Valet görs vid eden i introt. Rekommendation: **byte hos Gorm**, där det första bytet är gratis och kommer med en scen,
   sedan till ett lågt pris. Det ska vara billigt nog att pröva, eftersom Ledstjärnans test är att spelaren byter frivilligt.
8. Botarna (en ny profils makron plus inriktningens startrader, 100 nedstigningar per rad, djup 1): dagens paladin vinner
   kryptan 42 % och kapellet 36 %, tanken 70/56 % och helaren 69/66 %. Helaren är starkare utan Alva och tanken med Imma,
   så ingen dominerar. Den största risken är en tank utan helare i kapellet på djup 3 (72 % mot 86 % i dag).
9. Fyra nya makrovillkor (Glöd minst N, Tänker anfalla, Är målet för ett anfall, Har Befäl). Eden lär ut inriktningens
   startrader, så att allt går att köra automatiskt från första striden.
10. Byggordning i sju spelbara steg, med tajmingen först i steg 4, så att resten kan provspelas utan den. Risker och
    öppna frågor står sist.

## 1. Varför WoW:s paladiner är roliga, och vad som går att översätta

**Skyddspaladinen (Protection).** Det roliga är:
- **Ägarskap**: bossen slår mig, inte dem. Taunt är ett löfte till gruppen.
- **En rytm av bygga och spendera**: Holy Power byggs av slag och spenderas på Shield of the Righteous, alltså aktivt
  skydd man tajmar.
- **Planering mot ett känt stort slag**: man sparar en nedkylning (Ardent Defender, Divine Protection) till bossens
  smäll.
- **Att rädda någon annan**: Blessing of Sacrifice och Blessing of Protection, där tanken tar skadan åt en vän.

| WoW | Hos oss | Varför |
|---|---|---|
| Taunt och hotet | Provocera finns. Kasta sig emellan gör det till ett *val per slag*, och Edens sköld till en känsla som alltid finns. | Ägarskapet behålls, utan hottabeller. |
| Holy Power → Shield of the Righteous | Glöd av tagna slag → Rättfärdigt slag med Barriär | En rytm per strid, synlig i fem pärlor. |
| Nedkylning mot bossens smäll | Kasta sig emellan mot den varslade attacken, med tajming | Det enda stället där vi har realtid. |
| Blessing of Sacrifice | Edens sköld (alltid 20 %) och Kasta sig emellan (allt) | Två steg: passivt och aktivt. |

**Översätts inte**: hottabeller, positionering, rotationer med global nedkylning och fem knappar för skydd. På en
telefon i turordning blir det ett val per tur, högst fyra förmågor och en resurs.

**Den helande paladinen (Holy).** Det roliga är:
- **Triage**: vem dör först? Det är ett läsproblem, inte ett reaktionsproblem.
- **Att hela genom att slåss**: Glimmer of Light, Crusader Strike som bygger Holy Power, Avenging Crusader. Helaren är
  inte passiv.
- **Hushållning med mana**, som hos oss är Charges.
- **Förebyggande skydd**, som Disc-prästens absorberingar. Det är "jag visste att det skulle komma" i stället för "jag
  hann inte".

| WoW | Hos oss | Varför |
|---|---|---|
| Glimmer och Crusader Strike → helning | Gryningens hand: 30 % av skadan helar den svagaste | Varje slag är en helning. |
| Absorberingar före skadan | Förutseende ljus på den som avsikten pekar på | Vi visar redan fiendernas avsikter. Det är vår styrka. |
| Holy Power → Word of Glory / Light of Dawn | Glöd av helningar → Rättfärdigt slag (större slag = större helning) | Samma Glöd som tanken, med andra vägar in. |
| Gruppheln vid stor skada | Gryningsvåg | En knapp för krisen, med få Charges. |

**Översätts inte**: raidramar att knacka på varje tur ("whack-a-mole" är pilligt på mobil) och spill-helning att hålla
reda på. Helaren ska göra *ett* intressant val per tur, inte tre små.

**Ärligt omdöme.** WoW:s roller lever på realtid och gruppens samspel. Hos oss är tiden turordnad och sällskapet styrs av
makron. Det starkaste motargumentet är att en tank är ointressant när fienderna redan går på den som provocerar. Svaret
är att tanken här *väljer* vem som ska skyddas och när. Glöd och Kasta sig emellan finns för att varje tur ska ha ett
beslut i sig.

## 2. Grunden som båda delar

### Inriktning och kall är två olika saker (rekommendation)

- **Inriktningen** är vad paladinen *är*: stats, kärna, förmågor och Glödens vägar in. Den väljs vid eden.
- **Kallet** är som i dag, Siralims Specialization: en regel för hela sällskapet med perks. Väktarens kall passar tanken
  och Gryningens kall helaren, men alla tre går att kombinera med båda. Domens kall blir kvar utan nya förmågor, som
  briefen säger.
- Förebilden är FF XII: "gambits är hur hjälten tänker, vägen är vad hjälten är".
- **Motargument**: det blir två val där spelaren kanske väntar sig ett, och kombinationerna blir 2 × 3. Svaret är att det
  är just kombinationer vi vill att spelaren upptäcker, till exempel en tank med Gryningens kall. Botarna visar att
  "fel" kall inte är en fälla (tabellen).
- **Alternativet** är att kallet *är* inriktningen (Väktarens = tank). Det är enklare, men Domens kall blir då utan
  paladin, och perks och förmågor låses ihop.

### Glöd (båda)

- 0–5, visas som fem pärlor under paladinens livmätare. Nollas när striden börjar, som warriorns rage.
- **Två utlopp**: Rättfärdigt slag förbrukar all Glöd. Varje Glöd ger +20 % skada och en effekt som beror på
  inriktningen. Det är "det laddade slaget" från idéfilen. Befäl kostar 3 Glöd (nedan).
- Utan Glöd är Rättfärdigt slag som i dag (160 %, +50 % mot en Förblindad fiende). Introts kombination med Imma står
  kvar orörd.
- **Varför två utlopp och inte tre?** En resurs med tre utgifter blir ett pussel varje tur. Med två är frågan "slå nu,
  eller låta Imma agera nu?". Det är begripligt på en telefon och lätt att skriva som en makrorad ("Om Glöd minst 3 och
  Imma har Rökpil kvar → Befäl på Imma"). Kasta sig emellan kostar Charges, inte Glöd, så att tanken aldrig står utan
  sitt skydd för att han slog.
- **Motargument**: utan Glöd på Befäl blir Glöden en ren skademätare, och det var just så prototypen mätte. Med Glöd på
  Befäl måste spelaren välja, och det är rage-känslan VD vill ha. Priset är ett beslut till per tur.
- **Namnkrock**: trofén Den slocknade glöden (`ember_jaw`) har redan staplar som heter Glöd. En av dem måste byta namn
  (öppen fråga 4).

### Befäl (båda)

- **Prototypen** (mätt): en allierad går först på tidslinjen (`to_top`) och får +30 % på nästa anfall, för 4 Charges och
  nedkylning 3. **Det gav ingenting**: utan raden vann tanken 76 % mot 70 % med den, och helaren 70 % mot 69 % (kryptan,
  djup 1). Paladinen ger bort sin tur för att flytta någon som ändå skulle agera snart.
- **Förslaget**: Befäl kostar 3 Glöd och paladinens tur, och den allierade **agerar direkt**, med en extra handling nu,
  som i VD:s ord. Nästa förmåga hen använder gör 30 % mer. Ingen nedkylning, eftersom Glöden är spärren.
- Det är paladinens sätt att *få kombinationerna att hända*: Imma kastar Rökpil innan bossen agerar, och Alva helar nu
  i stället för om tre turer. En extra handling är dyr, och därför kostar den Glöd.
- **Motargument**: en extra handling är den starkaste effekt ett turspel har, och den kan bli en loop (Befäl på någon som
  ger paladinen Glöd). Spärrar: Befäl kan inte ges till paladinen själv, högst en gång per runda (gränsen som `to_top`
  redan har) och aldrig till någon som just fått Befäl. Det måste mätas i steg 1, eftersom prototypen inte kan uttrycka
  en extra handling.

## 3. Sköldbäraren (tank)

**Stats-lutning** (bas på nivå 1, dagens paladin inom parentes): Health 103,5 (90), Attack 8,6 (9,5), Intelligence 8,6
(9,5), Defense 7 (5), Speed 9 (10). Det är +15 % liv och +40 % Defense, mot −10 % Attack och Intelligence och −1 Speed.
Han agerar lite senare än fienderna, så att Kasta sig emellan oftare hinner före slaget.

**Kärna, Edens sköld**: paladinen tar 20 % av varje träff mot en annan i sällskapet (Siralims livvakt, samma som
Förmannens vakt hos kapellets fiender). Han får 1 Glöd för varje sådan träff. *Det* är känslan av att stå framför de
andra, varje tur, utan knapp.

**Glöd**: +1 när han träffas direkt av en fiende, +1 när han tar en träff åt någon (Edens sköld) och +1 för ett tajmat
Kasta sig emellan. Högst 5.

| Förmåga | Gör | Charges | Exempel (nivå 1, mot Defense 2) |
|---|---|---|---|
| **Rättfärdigt slag** | 160 % anfall; per Glöd +20 %, 3 Barriär och 4 helning åt honom själv; +50 % mot Förblindad | 8 | 0 Glöd: 11. 5 Glöd: 21, 15 Barriär och 20 helning. 5 Glöd mot Förblindad: 32. |
| **Kasta sig emellan** | Fiendernas anfall går till paladinen till hans nästa tur (som Provocera, utan Defense-straffet), 25 % mindre. Mot ett varslat slag: tajming (avsnitt 5). | 6, nedkylning 2 | Dödsdom mot Eira: 45. Mot tanken: 23, tajmat 12, perfekt 8 och ett motslag. |
| **Helig sköld** | Som i dag: Beskyddad (−50 % skada i 3 turer) | 5 | Skyddar den som slaget inte går att flytta från (förmågor med `ignore_taunt`). |
| **Befäl** | Se ovan | 3 Glöd | |

**Varför tanken helar sig själv**: den första prototypen (25 % och bara Barriär) var *sämre* än dagens paladin i
kapellet på djup 3 när Alva inte var med (66 % mot 86 %). Med 20 % och helning ur Glöden blev det 72 %, fortfarande
under. Prototypen låter andelen gå förbi hans försvar, så bygget räknar den mot hans Defense och Försvara. Det mäts
igen i steg 1.

**Kallet**: Väktarens kall (Siegemaster: alla slår tillbaka för 35 % av sin Defense) blir starkare med +40 % Defense.
Domens kall slår tillbaka när *de andra* träffas, och Edens sköld gör att de träffas mindre. I botarna var de lika
(kryptan djup 1: 63 % båda), och Väktarens kall gav fler stupade (58 mot 54 %). Botarna provocerar inte med tanken, så
Väktarens perks (Krigsmaskin) prövades inte.

**Startrader vid eden** (Gambits: inriktningen lär ut dem som en följeslagare lär ut sina):
1. Om någon fiende laddar → Kasta sig emellan
2. Om någon allierad har liv < 40 % → Helig sköld på den
3. Om Glöd minst 3 → Befäl på Imma (eller den med högst Attack)
4. Om Glöd minst 4 → Rättfärdigt slag på den med lägst liv (sedan Gorms rad: Anfall)

**Ärligt omdöme**: Edens sköld är det som bär tanken, inte knapparna. Den tog 250–470 skada åt de andra per
nedstigning. Kasta sig emellan användes 1–2 gånger per nedstigning hos botarna i kryptan och aldrig i kapellet, eftersom bara fyra förmågor i spelet är varslade (Dödsdom, Klockan slår, Midnatt, Dom). Det
starkaste motargumentet är att tankens bästa ögonblick då är sällsynt. **Därför ingår fler varslade slag i
byggordningen** (steg 5): en per boss och väktare och några hos elitfienderna. Utan dem blir tajmingen en kuriositet.

## 4. Ljusbäraren (helare)

**Stats-lutning**: Health 90, Attack 9,5, Intelligence 11,9 (+25 %), Defense 4,5 (−10 %), Speed 11 (+1). Han hinner före
fler fiender, så att Förutseende ljus kommer före slaget.

**Kärna, Gryningens hand**: paladinens direkta träffar helar den svagaste i sällskapet för 30 % av skadan. Han helar *genom
att slåss*. Kärnan finns redan som halva Gryningens kall (30 %), men här ligger den hos inriktningen. **Med Gryningens
kall staplas de inte**: kärnan ersätter kallets egen del, och kallet ger då bara sin andra halva (varje helning blir en
Barriär). Staplade (40 + 30 %) var helaren med Gryningens kall den starkaste kombinationen av alla (84 och 81 % på djup
1). Utan stapling blev den 78 och 74 %, fortfarande bäst, men inte så att man måste välja den.

**Glöd**: +1 för varje helning som faktiskt helar något, också helningen från Gryningens hand, och (förslag efter
mätningen) +1 när en Barriär han lagt tar ett slag. Högst 5. Rättfärdigt slag förbrukar den: +20 % skada och 2 Barriär åt
den svagaste per Glöd. Ett större slag blir alltså en större helning. I prototypen hann helaren bara få 1,1 Glöd per slag
(tanken 2,6), så utan Barriärens Glöd blir hans Glöd nästan osynlig.

| Förmåga | Gör | Charges | Exempel (nivå 1) |
|---|---|---|---|
| **Rättfärdigt slag** | 160 % anfall; +20 % och 2 Barriär åt den svagaste per Glöd; +50 % mot Förblindad | 8 | 0 Glöd: 12 skada, helar 4. 5 Glöd: 24 skada, helar 7 och ger 10 Barriär. |
| **Förutseende ljus** | En allierad får en Barriär på 200 % av Intelligence | 6 | 24 Barriär. Alvas Helande ljus helar 15. Läggs på den som ett slag pekar på. |
| **Gryningsvåg** | Hela sällskapet helas för 90 % av Intelligence | 4 | 11 var, 43 totalt. Krisknappen. |
| **Befäl** | Se ovan | 3 Glöd | |

Helig sköld går över till tanken. Förutseende ljus är helarens sköld, eftersom han ser slaget komma.

**Startrader vid eden**:
1. Om någon allierad är målet för en laddning → Förutseende ljus på den
2. Om någon allierad har liv < 40 % → Gryningsvåg
3. Om Glöd minst 3 → Befäl på Alva eller Imma (den som har en helning eller Rökpil kvar)
4. Om någon fiende har lägst liv → Rättfärdigt slag (sedan Gorms rad)

**Ärligt omdöme**: helaren blir stark av att han *också* slår. Risken är att han blir en skadeinriktning i förklädnad, som
VD inte ville ha. Svaret är att skadan bara räknas som helning åt den svagaste, och att hans egen skada är oförändrad
(Attack 9,5). Det starkaste motargumentet är att Alva redan är en helare, så sällskapet kan få två. Botarna visar vad det
kostar (tabellen, laget med Imma i stället för Alva).

## 5. Kasta sig emellan med tajming

**Flödet**
1. En fiende laddar ett varslat slag (som i dag: ringen med siffran och "SAMLAR KRAFT", pekar på Eira).
2. På sin tur väljer paladinen Kasta sig emellan, för hand eller genom makrot (rad 1). Avsikten pekar om till honom,
   och ordet EMELLAN syns över honom.
3. När slaget släpps springer han fram till platsen framför målet (0,3 s), och en ring krymper runt honom. Tre trumslag
   går i takt, det tredje precis i fönstret.
4. Ett tryck var som helst på skärmen. Inga riktningar och inget att sikta på.
5. Resultatet: **miss** ger −25 % (det Kasta sig emellan alltid ger), **bra** (block) ger −62,5 % och 1 Glöd, och
   **perfekt** (parering) ger −75 %, 2 Glöd och ett motslag på 50 % av hans Attack.

**Fönster** (förslag, avgörs genom provspel):

| Läge | Bra | Perfekt | Utan tryck |
|---|---|---|---|
| Av | ingen tajming, resultatet är alltid "miss" (−25 %) | – | – |
| Lätt | ±200 ms | ±70 ms | miss |
| Full | ±120 ms | ±45 ms | miss |

**Kalibrering** i inställningsrutan: tryck i takt med åtta trumslag, så sparas en förskjutning. Det behövs, eftersom
ljudet på Android ofta kommer 100–200 ms sent. Ringen är sanningen, och ljudet följer förskjutningen.

**Ljud**: trumslagen (`tools/gen_sfx.py`, ett djupt slag med sus före), en metallklang vid bra och en ljus klang plus en
gnista vid perfekt. Haptik: kort vibration vid bra och dubbel vid perfekt (`Input.vibrate_handheld`, finns redan för
gambitsidan).

**Logiken** (ren, testbar):
- `CombatSim` släpper inte slaget direkt mot en paladin som står emellan. Den sänder händelsen `timing_window` och väntar
  (`needs_timing()`, som `needs_input()`).
- UI:t svarar med `sim.resolve_timing("miss" | "good" | "perfect")`.
- Utan svar (headless, avstängt, ALLA AUTO med tajming av) räknas det som miss.
- Botarna svarar med en antagen träffsäkerhet: `PS_TAJMING=0.7` betyder 70 % bra i prototypen. I det riktiga bygget
  blir det en fördelning, till exempel 60 % bra, 20 % perfekt och 20 % miss.
- Stridsloggen skriver "Paladinen kastade sig emellan och blockerade: 45 → 17".

**Under AUTO**: makrot väljer Kasta sig emellan, och spelaren tajmar ändå om tajmingen är på. "Makrot väljer, du tajmar."
Det är bonusen för att spela, aldrig ett krav.

**Ärligt omdöme**: en tajming i en turordnad strid är en främmande fågel, och den syns på en sekund i ett spel som annars
är lugnt. Det starkaste motargumentet är att det bryter tusch och lugn. Svaret: den finns bara vid de stora slagen, högst
några gånger per nedstigning, och den går att stänga av. Om provspelet visar att den stressar, sätt förvalet till "av".

## 6. Valet i berättelsen

**Eden i introt** (`intro.json`, steget "oath", Gorm vid altaret): efter kallet frågar Gorm "Vad bär du in i mörkret,
{namn}? Skölden eller ljuset?". Två stora kort, som kallets, med fyra rader var: vad du gör, Glöden, kärnan och en
mening om känslan. Valet sparas i `Profile.path` ("shield" eller "light"). Paladinens figur får en större sköld eller en
stav med solen på (bara utseende, steg 7).

**Låst eller byte**

| Alternativ | För | Emot |
|---|---|---|
| A. Låst per profil | Ett skäl att spela om. Sällskapet formas kring valet ("Brokk som tank, jag helar"). | Straffar nyfikenhet. En spelare som valt fel tröttnar på fel ställe. Bryter mot Ledstjärnans test (byta frivilligt för att pröva). |
| B. Fritt vid altaret, som kallet | Siralim (verktygslådan). Inget att ångra. | Valet blir en siffra, inte en händelse. Ingen symbios. |
| C. Eden, sedan byte hos Gorm mot ett pris och en scen (projektledarens förslag) | Valet betyder något, men går att ångra. | Ett pris på att pröva kan räcka för att ingen prövar. |
| D. Eden, sedan byte hos Gorm: det första gratis med en scen, därefter 50 silver och bara hemma | Som C, men det första bytet är fritt för den som undrar. | Lite mer att förklara. |

**Rekommendation: D.** Valet blir en händelse i berättelsen ("Gorm: En paladin som byter väg har inte svikit sin ed. Han
har lärt sig något om den."), men nyfikenheten kostar ingenting första gången. Bytet går bara hemma (aldrig under en
nedstigning), och de egna makroraderna står kvar. Rader med förmågor den nya vägen saknar hoppas över, som Tystad i dag,
och inriktningens nya startrader hamnar i FUNNA RADER.
**Motargument**: VD vill ha skäl att spela om. Svaret är att sparplatserna redan ger det, eftersom tre profiler kan välja
olika. Låst kan läggas till som en utmaning per profil (öppen fråga 2).

**Gamla profiler**
- Fram till valet behåller de dagens paladin, "Den edsvurne": samma förmågor, inga nya.
- Första gången de kommer hem efter uppdateringen kallar Gorm på dem med en kort scen och samma två kort. Valet kostar
  ingenting.
- Ingen förlorar något. Helig sköld finns kvar hos tanken, och helaren byter den mot Förutseende ljus. En egen rad med
  Helig sköld hoppas över hos helaren och står kvar låst.
- Övningsgården får välja inriktning fritt, så att man kan prova utan att byta.

## 7. Makrovillkor och gambit-fynd

**Nya villkor** (i `MacroRunner` och `gambits.json`):

| Villkor | Exempel | Hem (förslag) |
|---|---|---|
| **Glöd minst N** (`glow_at_least`, denna hjälte) | "Om Glöd minst 4 → Rättfärdigt slag" | Lärs ut vid eden. Gränserna 3 och 5 hos fiender som slår hårt (Benkolossen, Den svarta lansen). |
| **Tänker anfalla** (`intends_attack`, mål eller vem som helst) | "Om någon fiende tänker anfalla Eira → Förutseende ljus på Eira" | Elit: Fanbäraren, Inkvisitorn. Det är förslagets egen styrka (idéfilen). |
| **Är målet för ett anfall** (`is_attack_target`, allierad) | "Om någon allierad är målet för ett anfall och har liv < 50 % → Kasta sig emellan" | Vanlig: Benspringaren, Blodsvuren (de som går på de svaga). |
| **Har Befäl** (`has_command`) | Kedja: "Om Imma saknar Befäl → Befäl på Imma" | Eden. |

**Befintliga villkor som blir viktiga**: Laddar (`g_charging`, i dag bara hos bossar) och Bär laddningen
(`is_charge_target`, hos Abbedissan och Inkvisitorn). Tankens rad 1 och helarens rad 1 bygger på dem. Därför **lär eden
ut** dem, som en följeslagare lär ut sitt villkor (`gambits.json` "teach"). Annars måste en ny tank spela sin viktigaste
handling för hand tills han fäller en boss, och det bryter mot "makron först, handen ger bonus".

**Att jaga** (VD: "inriktningarnas villkor kan vara gambit-fynd"):
- Gränserna för Glöd.
- Tänker anfalla.
- En sällsynt **Första slaget i striden** (kedja: "Befäl på Imma, sedan Rökpil"), hos Klockaren och biskopen.
- Väktarnas troféer, som redan finns och ger nya val (avsnitt 8).

## 8. Kombinationer

**Med Imma (Rökpil, Fingerfärdig)**
- *Tank*: Befäl på Imma, så kastar hon Rökpil före fienderna och alla blir Förblindade. Paladinen sparar Glöd och slår
  Rättfärdigt slag: 1,5 × 2,0 = ×3, alltså 32 skada på nivå 1 mot 12 i dag. Det är introts kombination, uppväxt.
- *Helare*: samma slag helar den svagaste för 30 % av 32 = 10. Blinda fiender missar oftare, så Förutseende ljus räcker
  längre.
- Fingerfärdig stjäl en buff åt den svagaste. Helaren håller den svagaste vid liv, och buffen går till den som behöver den.

**Med Brokk**
- *Tank*: två tankar. Brokks Stenmur (−25 % för alla) gör Edens sköld billigare, och när Brokk provocerar tar paladinen
  20 % av slagen mot honom och bygger Glöd. Det är rollernas överlapp, och botarna säger att det är *sämre* än att byta Brokk mot Imma: tanken
  vann kryptan djup 1 70 % med Brokk och 88 % med Imma.
- *Helare*: VD:s fråga "hur skulle det vara som helare, med Brokk som tank?". Brokk provocerar, paladinen lägger
  Förutseende ljus på Brokk innan Dödsdomen kommer, och Gryningens hand helar honom med varje slag. Det är den klassiska
  gruppen.

**Med Alva**
- *Tank*: Alva helar och Paladinen skyddar. Med Gryningens kall blir Alvas helningar Barriärer på tanken, som tar 20 % åt
  de andra. Befäl på Alva när någon är nära döden: hon helar *nu*.
- *Helare*: två helare. Sällskapet överlever, men striderna blir långa. Det är laget där helaren behöver slå (Gryningens
  hand). Tabellen jämför med Imma i stället för Alva.

**Med Eira**
- Märk byte (+20 % skada tagen) på bossen, sedan Befäl på Eira (Pilregn före fienderna, +30 %) och sist paladinens fulla
  Rättfärdigt slag mot det märkta målet. Hos helaren blir märket en helning.

**Med troféer**
- **Väktarens hjälm** (Försvara/Provocera helar den svagaste för 140 % av Defense) på tanken: +40 % Defense blir mer
  helning. Kasta sig emellan borde räknas som Provocera för hjälmen (beslut i steg 2).
- **Saltad jord**, **Häroldens horn** och **Brospännet**: tankens provokation blir sällskapets anfall.
- **Midnattsklockans kläpp** (bryter laddningar var tredje handling) på tanken är ett riktigt val. Den tar bort hans stora
  ögonblick men skyddar alla. Ett bra exempel på en trofé som ändrar en regel med en kostnad.
- **Gravprästens radband** (Helig skada helar 25 %) på helaren staplas med Gryningens hand: 55 % av varje slag blir helning.
- **Den delade lågan** på helaren: varje slag helar någon, så hela sällskapet får Läkning varje tur.
- **Den slocknade glöden** (staplar av helningar) på helaren är en andra Glöd. Namnkrocken (öppen fråga 4).
- **Den vandrande kronan** på tanken är en anti-synergi: kronan går till den svagaste, och tanken är aldrig den svagaste.

## 9. Mätningen med botarna

`tests/paladin_specs.gd`, 100 nedstigningar per rad, väntad nivå (kryptan och kapellet: nivå 3 på djup 1, nivå 7 på djup
3), en ny profils makron med makroförslagen (`sim_macros`), antagen utrustning (`sim_gear`), MACRO och den enkla vägen,
samma frön i varje rad. Paladinen har inriktningens startrader överst och Gorms rad sist. Domens kall om inget annat
står.

- *idag* = dagens paladin med en ny profils enda rad (Gorms rad).
- *idag + rader* = dagens förmågor med samma sorts rader (Helig sköld under 40 %, Rättfärdigt slag), för att skilja
  raderna från verktygen.
- *tank* = den första tanken (Edens sköld 25 %, Glöden ger bara Barriär), 70 % tajmat Kasta sig emellan; *tajming 0 /
  100 %* = ingen och full träffsäkerhet; *+ Väktarens kall*.
- **tank (justerad)** = planens tank: Edens sköld 20 %, Glöden helar honom också.
- *helare* = den första helaren (Gryningens hand 40 %, staplas med Gryningens kall); **helare (justerad)** = planens:
  30 %, staplas inte.
- Nivå 6 på djup 3 är en nivå under den väntade. På väntad nivå vinner alla 92–100 %, så skillnaderna syns inte där.

Standardlaget (Paladinen, Brokk, Alva, Eira). Vinst i procent, och inom parentes hur ofta minst en hjälte stupade.

| Variant | Kryptan d1 (nivå 3) | Kapellet d1 | Kryptan d3 (nivå 7) | Kapellet d3 | Kryptan d3, nivå 6 | Kapellet d3, nivå 6 |
|---|---|---|---|---|---|---|
| idag | 42 (82) | 36 (89) | 97 (29) | 96 (32) | 86 (53) | 75 (45) |
| idag + rader | 43 (90) | 30 (90) | 100 (27) | 96 (36) | | |
| tank (första) | 63 (54) | 58 (67) | 96 (8) | 95 (19) | 84 (34) | 76 (38) |
| tank, tajming 0 % | 60 (63) | 58 (67) | 96 (8) | 92 (24) | | |
| tank, tajming 100 % | 65 (54) | 58 (67) | 96 (8) | 96 (18) | | |
| tank + Väktarens kall | 63 (58) | 52 (68) | 96 (22) | 95 (21) | | |
| **tank (justerad)** | **70 (57)** | **56 (57)** | **98 (8)** | **95 (21)** | **89 (31)** | **89 (31)** |
| helare (första) | 70 (73) | 66 (69) | 97 (25) | 96 (26) | 86 (46) | 77 (47) |
| helare + Gryningens kall (första) | 84 (46) | 81 (46) | 97 (33) | 98 (25) | 83 (60) | 76 (46) |
| **helare (justerad)** | **69 (70)** | **66 (73)** | **99 (28)** | **96 (26)** | **87 (46)** | **78 (45)** |
| **helare (justerad) + Gryningens kall** | **78 (57)** | **74 (60)** | **97 (44)** | **94 (35)** | **82 (68)** | **73 (52)** |
| tank (justerad), utan raden Befäl | 76 (49) | 54 (67) | | | | |
| helare (justerad), utan raden Befäl | 70 (73) | 69 (67) | | | | |

**Symbios** (samma mätning med andra lag; Imma tar Brokks eller Alvas plats):

| Lag | Variant | Kryptan d1 | Kapellet d1 | Kryptan d3 | Kapellet d3 |
|---|---|---|---|---|---|
| Imma i stället för Brokk (Paladinen, Imma, Alva, Eira) | idag | 75 | 58 | 97 | 99 |
| | tank (första) | 88 | 74 | 99 | 99 |
| | **tank (justerad)** | **88** | **82** | **100** | **100** |
| | helare (första) | 86 | 67 | 100 | 97 |
| | **helare (justerad)** | **84** | **66** | | |
| Imma i stället för Alva (Paladinen, Brokk, Imma, Eira) | idag | 69 | 46 | 100 | 86 |
| | tank (första) | 73 | 38 | 96 | 66 |
| | **tank (justerad)** | **75** | **54** | **100** | **72** |
| | helare (första) | 87 | 61 | 100 | 91 |
| | **helare (justerad)** | **86** | **60** | | |

**Vad Paladinen gjorde** (30 nedstigningar per rad, per nedstigning):

Kryptan djup 1, standardlaget, de första varianterna:

| | idag | tank | helare |
|---|---|---|---|
| Vinst (30 nedstigningar) | 27 % | 53 % | 67 % |
| Rättfärdigt slag / Anfall | 9,7 / 33,4 (slagen är svärdets kast) | 14,8 / 11,9 | 18,7 / 17,4 |
| Kasta sig emellan / Helig sköld | – / 0 | 1,8 / 3,6 | – |
| Förutseende ljus / Gryningsvåg | – | – | 3,7 / 3,5 |
| Befäl | – | 7,8 | 8,1 |
| Glöd förbrukad (per slag) | – | 38,7 (2,6) | 20,8 (1,1) |
| Skada åt andra (Edens sköld) | – | 248 | – |
| Skada på paladinen / av paladinen | 556 / 955 | 532 / 812 | 632 / 1127 |
| Helat av paladinen | 0 | 0 | 578 |

I kapellet djup 1 och kryptan djup 3 användes Kasta sig emellan aldrig: biskopen och Gravväckaren har inga varslade slag.

**Slutsatser**

1. **Båda är starkare än i dag**, mest på djup 1: tanken +28 och +20 enheter, helaren +27 och +30. På djup 3 en nivå
   under väntad: tanken +3 och +14, helaren +1 och +3. På väntad nivå på djup 3 vinner alla nästan alltid.
2. **Ingen dominerar.** I standardlaget är de lika i kryptan (70 och 69 %). Helaren leder i kapellet djup 1 (66 mot 56)
   och tanken i kapellet djup 3 (89 mot 78). Helaren är bäst utan Alva, och tanken bäst med Imma i stället för Brokk.
   Valet beror på sällskapet, och det är den symbios VD ville ha.
3. **Tanken minskar dödsfallen** mest: "minst en stupad" i kryptan djup 3 sjunker från 29 till 8 %. Det är tankens känsla
   i siffror.
4. **Helaren med Gryningens kall** var den starkaste kombinationen (84/81 %). Därför staplas kärnan och kallet inte i
   planen (78/74 %).
5. **Tajmingen märks knappt** (kryptan djup 1: 60, 63 och 65 % vid 0, 70 och 100 % träffsäkerhet), eftersom Kasta sig
   emellan bara behövdes 1–2 gånger per nedstigning. Det är bra för "aldrig ett krav", men dåligt för tankens bästa
   ögonblick. Därför finns steg 5 (fler varslade slag).
6. **Befäl i prototypens form gav ingenting** (utan raden 76 mot 70 % och 70 mot 69 %). Därför görs det om till en
   extra handling för 3 Glöd.
7. **En tank utan helare i kapellet på djup 3** är sämre än i dag (72 mot 86 %). Delvis beror det på att prototypens
   Edens sköld går förbi hans försvar. Det måste mätas igen i steg 1, innan något annat byggs.
8. **Hela spelet blir lättare på djup 1.** Kryptans första djup ligger i dag under målet (CLAUDE.md: ungefär 80 %
   för den första nedstigningen). Tanken och helaren hamnar närmare målet med fyra hjältar. Rekommendationen är att
   justera paladinens siffror, inte fienderna, om `BALANS=forsta` och balanssimuleringen hamnar över målen efter steg 1.

### Prototypens förenklingar

- **Glöd** är en egenskapsstapel (`stack`/`release`) som Rättfärdigt slag förbrukar helt. Det finns inget villkor för Glöd
  ännu, så botarna slår när raden passar, inte när Glöden är full. Det underskattar Glöden.
- **Kasta sig emellan** är en provokation utan Defense-straff med −25 %. Tajmingen är en andra aura med chansen 70 % och
  −50 % till, som gäller *hela* paladinens tur och inte bara det varslade slaget. Det överskattar tajmingen något mot
  vanliga slag samma tur. Perfekt och motslaget finns inte med.
- **Edens sköld** är Siralims livvakt (`guard_family`, 25 % i första omgången och 20 % i den justerade). Hjältarna får
  familjen "edsvurna", och andelen går förbi
  paladinens egna modifierare (Försvara, Beskyddad). I bygget ska andelen räknas mot hans försvar.
- **Befäl** är den gamla formen (först på tidslinjen och +30 %, för Charges), inte förslaget (en extra handling för 3
  Glöd). En extra handling går inte att uttrycka i datan.
- Startraderna är utan villkoret Glöd minst N, som inte finns än. Raden med Befäl gäller den med högst Attack.
- Inga nya makrovillkor, inga perks och inga troféer utöver `sim_gear`.

## 10. Byggordning (varje steg spelbart på telefonen)

1. **Stats, kärnor och Glöd.** `Profile.path`, inriktningarnas data och Glöd med pärlorna under livmätaren. Rättfärdigt
   slag och Befäl (en extra handling) som utlopp, Förutseende ljus, Gryningsvåg och villkoret Glöd minst N. Edens sköld
   räknas mot paladinens försvar. Valet bara i Övningsgården och med `--path=shield|light`.
   Botarna som i tabellen, särskilt tanken utan Alva i kapellet. *Provspel: känns de olika?*
2. **Kasta sig emellan utan tajming**: animationen (springer fram), ordet EMELLAN, stridsloggen och makrovillkoret Är
   målet för ett anfall. Eden lär ut raderna.
3. **Eden i introt**, Gorms bytesscen, gamla profiler, hjältebladet (inriktningen och Glöd) och handboken ("?"-rutan
   "Glöd").
4. **Tajmingen**: ringen, trumslagen, `timing_window`/`resolve_timing`, inställningen av/lätt/full, kalibreringen och
   haptiken. *Provspel på telefonen, med fönstren i millisekunder.*
5. **Fler varslade slag**: ett per boss och väktare som saknar det (biskopen, Gravväckaren, Abbedissan, Lunden och
   Berget) och två eller tre hos elitfienderna. Annars är tankens bästa ögonblick för sällsynt.
6. **Villkoret Tänker anfalla** (med hem bland eliten) och översyn av kallens perks mot inriktningarna, till exempel
   Krigsmaskin plus Kasta sig emellan.
7. **Figuren**: en större sköld eller en solstav, egna animationer för Kasta sig emellan och Gryningsvåg, och ljuden.

## 11. Risker

- **Tanken blir passiv.** Edens sköld gör jobbet och knapparna betyder lite. Motåtgärden är steg 5 och villkoret Glöd
  minst N, så att "nu eller sen" blir ett beslut.
- **Helaren blir den bästa skadegöraren.** 30 % helning per slag lockar till att bara slå. Bevaka skada per strid i
  hjältebladets Bidrag efter steg 1.
- **Två tankar eller två helare** (Brokk, Alva) blir starka men tråkiga. Det är spelarens val, men tabellen visar priset.
- **Tajmingen och Android-fördröjningen.** Kalibreringen måste fungera på VD:s telefon innan läget "full" visas.
- **Balans mot fem.** Trollberget är byggt för fem. Paladinens nya styrka gör mötena lättare där. Kör `BALANS=fem` efter
  steg 1.
- **Makrorna i gamla profiler.** Rader med Helig sköld hos en helare hoppas över. Det ska synas tydligt ("Ljusbäraren har
  inte Helig sköld").

## 12. Öppna frågor till VD

1. Är inriktning och kall två olika val (rekommendationen), eller ska kallet *vara* inriktningen?
2. Byte hos Gorm: det första gratis och sedan 50 silver (rekommendationen), ett högre pris, eller låst per profil som en
   utmaning?
3. Glöd med två utlopp, Rättfärdigt slag (all) och Befäl (3), som rekommendationen? Eller bara slaget, med Befäl på
   Charges?
4. Namnkrocken: ska paladinens resurs heta Glöd och trofén Den slocknade glöden få "Aska", eller tvärtom?
5. Namnen Sköldbäraren och Ljusbäraren, eller något annat (Väktare och Gryning krockar med kallen)?
6. Tajmingens förval: lätt, eller av tills man har provat i Övningsgården?
7. Ska perfekt parering ge ett motslag, eller bara mer Glöd? Motslaget är roligt men lägger skada på tanken.
8. Ska tanken få Kasta sig emellan även mot vanliga slag (som nu, utan tajming), eller bara mot varslade?
9. Ska helaren behålla Helig sköld som en femte förmåga, eller stämmer det att han har fyra?
10. Hur många nya varslade slag i steg 5: ett per boss och väktare, eller också hos eliten?
11. Befäl som en extra handling direkt (förslaget, starkt och måste mätas) eller som en flytt till toppen av tidslinjen
    (prototypen, som botarna inte fick ut något av)?
12. Är det rätt att djup 1 blir märkbart lättare (+20–30 enheter med fyra hjältar), eller ska paladinens siffror sänkas
    tills inriktningarna bara ligger lite över i dag?
