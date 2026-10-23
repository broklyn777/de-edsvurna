# Siralim Ultimate: luckanalys mot De edsvurna (test-0.30, 2026-10-24)

Alla system i Siralim Ultimate (SU) jämförda med det vi har. Det här är underlag, och inget är beslutat. Bygger på
CLAUDE.md (läget 0.30.24), `docs/research/siralim.md`, `siralim_0.19.md`, `siralim_innehall.md`, `jamforelse.md`
(läget 0.20.3, nu delvis inaktuell), `docs/ordlista.md`, `docs/plan/*` och `data/` på `test-0.30`. Wikin lästes i dag.

**Märkning.** Säkerheten anges när den inte är **B** (Bekräftat i wikin eller Codex): **T** = troligt, **?** = inte belagt.
Våra spalter:
- **Vi:** HAR, DELVIS eller SAKNAS, med vårt namn.
- **Passar:** JA, ANPASSAT eller NEJ. Tonregeln gäller här: spelarens sida är aldrig ockult, fienderna får vara det.
- **Värde:** hur mycket systemet tillför det roliga (hög/med/låg), mätt mot ledstjärnan: kombinationer före innehåll.
- **Storlek:** S = dagar, M = en version, L = flera versioner.

Läget i dag, kort: 12 hjältar, 49 fiender, 180 egenskaper, 120 förmågor, 3 kall, 3 Realms i datan (två spelbara plus
trollens prov), 10 våningsregler, 11 Realm-föremål, 4 löften och 20 personligheter. Utöver CLAUDE.md finns på test-0.30
också Krönikan med titlar (`chronicle.gd`, `titles.json`), den levande kartan och världshändelser (`living_map.gd`,
`world_events.gd`, med en handelsman).

## 1. Hela tabellen

### 1.1 Strid och bygge

| System | Siralim (kort) | Vi | Passar? | Värde | Storlek |
|---|---|---|---|---|---|
| Timeline | Speed ger startplatsen; den som agerat läggs sist; Top/Bottom-effekter | **HAR** (tidslinjen, `to_top`/`to_bottom`) | JA | hög | – |
| Handlingar | Attack, Cast, Defend, Provoke, Skip, Inspect, History, Forfeit | **HAR** (+ Makro, GE UPP, skadelogg) | JA | hög | – |
| Action Limits | Högst 15 av varje per tur; stats högst 20 % ned; högst 10 återupplivningar | **HAR** (`TURN_LIMIT`, `TURN_PROC_LIMIT`, tak) | JA | med | – |
| Turgräns och trötthet | Ingen turgräns i stridssidan. Den gamla listan över Realm Properties har dock "Rapid Fatigue: Battle fatigue builds much faster" (?) | **HAR** (Utmattning från tur 100, 0.30.20) | ANPASSAT | med | – |
| Stats och formler | 5 stats, Attack/Spell/Indirect | **HAR** (0.13, 0.26: små tal) | JA | hög | – |
| Klasser och klasscirkeln | 5 klasser (Chaos, Death, Life, Nature, Sorcery); gems bara av egen klass; "Strong Against (Class)" | **SAKNAS** (inga klasser) | ANPASSAT: fem dygder eller skolor, inte Death och Chaos för spelarsidan | med | M |
| Ras och familj | ~6 varelser per ras; raskortens bonusar | **DELVIS** (fiendefamiljer Benfolket, Kultens folk, De fallna, Trollfolket) | JA | med | – |
| Traits (3 platser) | Eget + fusion + artefakt (+ Nether Stone) | **HAR** (egen + trofé + artefaktens trofé/Nether Stone, troféplatsen) | JA | hög | – |
| Fusion | Avkomman ärver båda föräldrarnas traits och genomsnittliga stats | **ANPASSAT** till troféer (beslut) | NEJ i originalform: vi har människor, inte varelser | – | – |
| Trait Materials | Ett trait som föremål; från Masters ×3 och Assassination | **HAR** som troféer (bosstroféer x/3) | JA | hög | – |
| Spell Gems | 3 platser, Charges per gem för hela Realmen, gems byts fritt | **DELVIS** (2–3 fasta förmågor per hjälte, Charges per körning) | JA | **hög** | – |
| Spell crafting (Enchanter) | Rhea tillverkar och uppgraderar gems för Crystal; Inscriptions är recept; tier 1–15 öppnar 3 egenskapsplatser | **SAKNAS** | ANPASSAT: "Runristaren" eller Broder Alrik, välsignade inskrifter | **hög** | L |
| Spell Properties | ~40 egenskaper (Cascading, Generous, chans att kasta två gånger …) | **SAKNAS** | JA | **hög** | M (efter valbara förmågor) |
| Ethereal gems | Tillfälliga gems i striden från traits | **SAKNAS** | JA (en trofé som "lär ut" en förmåga i striden) | med | S |
| Artefakter | Typ, nivå 1–50, Stat/Trick/Trait/Nether-platser, Amber | **HAR** (0.12, 0.20, nivå 1–10, troféplatsen) | JA | hög | – |
| Nether Stones | Slumpade egenskaper, kan krossas i Refinery | **HAR** (`roll_stone`, tillbaka till förrådet) | JA | med | – |
| Refinery | Bryter ned artefakter, gems och stenar; växlar resurser 2:1 | **SAKNAS** | JA, liten: "Smälta" hos Hedda | låg | S |
| Specializations | 43 (15 start, 26 avancerade, 2 utmaning); perks för Perk Points (tak 1500), återställs gratis | **DELVIS** (3 kall, perk-nivåer) | JA | **hög** | M per kall |
| Anointment | Låna perks från andra specs | **HAR** (lånad perk, 0.15) | JA | med | – |
| Ascension | Gud på svårighet 10 med samma spec: perk, skin, dekor | **SAKNAS** | ANPASSAT: "kallets fullbordan", inte gudar | låg | M |
| Personligheter | En stat +40 % per nivå, en +20 % | **HAR** (20 st, Biblioteket) | JA | låg | – |
| Nivåer | Inget tak, stat scrolls | **HAR** (0.19), inga scrolls | JA | med | S (scrolls) |
| Buffar och debuffar | 18 + 20, Resistant | **HAR** (12 + 10 + egna, 0.22) | JA | hög | S per status |
| Minions | Egna småvarelser med eget bygglager (Necromancer, Inquisitor) | **SAKNAS** | ANPASSAT: ljust tema (Ronjas falk, Huldas rotskott, en vakthund), aldrig nekromanti på spelarsidan | **hög** | L |
| Avatars och Ultimate Spell | Gudens avatar, 1 Charge som fylls varje strid, en per lag | **SAKNAS** | NEJ som gudar. ANPASSAT som "helgonets ingripande": en gång per strid | med | M |
| Makron | 20 rader, subjekt + villkor + handling + mål | **HAR**, och mer än originalet (sök, grupper, Spara som order, AUTO/MANUELL per hjälte) | JA | hög | – |
| Inspect, History | Gratis; visar allt | **HAR** (+ skadelogg med uträkning, "Det här avgjorde striden") | JA | hög | – |
| Calm Mode, Sandbox, Relaxed/Ruthless | 2.0: färre kedjor, sandlåda, svårighetsgrader | **DELVIS** (Övningsgården ≈ sandlåda; ingen svårighetsgrad) | JA | låg–med | S |

### 1.2 Realms och utforskning

| System | Siralim (kort) | Vi | Passar? | Värde | Storlek |
|---|---|---|---|---|---|
| Realms | 30 (21 i storyn + 9 efter), en gud och ras var, egna föremål | **DELVIS** (Kryptan, Kapellet; Sidenlunden och trollen planerade) | JA | hög | M per Realm |
| Fri karta | Stor slumpad karta, vandrande grupper, dimma | **ANPASSAT** (grottan 8×8 med dimma, 0.27) | JA (telefon) | hög | – |
| Realm Depth | Valfritt djup; slutspelet fortsätter mycket långt (Gate of the Gods från djup 240) | **HAR** (0.14) | JA | hög | – |
| Realm Properties | ~40 regler för spelare, fiender och Realm | **DELVIS** (10 våningsregler) | JA | med | S per regel |
| Realm Instability | 0–5, dolda regler, fused fiender och fiender från andra Realms, byte över +400 % | **HAR** (0–3) | JA | med | S (nivå 4–5) |
| Realm Quests | Krävs för att lämna; skatt, Perk Points, +200 Favor, Emblem, Fortune. Typerna listas inte i wikin (?) | **HAR** (Nemesis, Rensa, Samla, belöning på sista våningen), krävs inte | JA | med | – |
| Fortune | +20 % byte per klarad quest, högst 100 %, nollställs vid förlust | **SAKNAS** | JA (en "segersvit" som är lätt att förstå) | med | S |
| Nemesis | Starkare vandrande varelser med varningstext (Hearty, Thorns, Greedy) | **HAR** (Jakt på Nemesis, elitvarianter som glöder) | JA | med | – |
| Skattkistor och materialkistor | Tre färger: Amber, trick, trait | **HAR** (skatter, fynd) | JA | med | – |
| Inscriptions | Recept till spells, sedan Knowledge | **SAKNAS** (inga spells att låsa upp) | JA, hänger på Runristaren | med | S (efter L) |
| Breakables, Resource Nodes | Smått byte, resurser | **SAKNAS** | JA, men låg nytta på ett rutnät 8×8 | låg | S |
| Candles (Favor) | +200 Favor hos guden | **SAKNAS** | ANPASSAT till "ljus för Realmens folk", om Favor byggs | låg | S |
| Skattkartor | Ett X att gräva upp | **DELVIS** (Gravregistret visar skatter; rykten och spår 0.30.22) | JA | med | S |
| Treasure Golem | Sällsynt; försöker fly varje tur, släpper resurser när den träffas | **SAKNAS** | JA ("Skattväktaren", en mimisk kista som springer) | **hög** för överraskning | S |
| Dumplings | Sällsynta; flyr; ger mycket erfarenhet; egen samlarkedja | **SAKNAS** | ANPASSAT: SU:s Dumplings är gulliga, och vi vill ha allvarliga monster. En "bleklarv" eller "irrbloss" som ger erfarenhet | med | S |
| Mimic | En kista som startar en strid | **SAKNAS** (finns bara i datan som ord) | JA | med | S |
| Pandemonium Shrine | Slumpad effekt: skatt, Dumpling, strid mot King & Queen, Favor | **DELVIS** (helgedomen: välj gåva eller Pandemonium) | JA | med | – |
| Realmens egna föremål | Svampar, flöjter, fällor, nomader med byteshandel | **HAR** (0.28.2, 11 föremål) | JA | hög | S per föremål |
| Mini-boss-rum | Starkare strid, bättre byte | **HAR** (elitgrupper, Klockaren, Abbedissan) | JA | hög | – |
| NPC-händelser | Imp disputes, nomader med önskemål | **DELVIS** (fångar; handelsmannen i världshändelserna) | JA | med | S–M |
| Gåtdvärgar | Gåtor om gudar och spells, svar ger byte | **SAKNAS** | ANPASSAT: en gåta om fiender och troféer ("vem lämnar Glasvalvet?") lär ut Bestiariet. Spelarna tycker att originalets gåtor är irriterande | låg | S |
| Nether Realm-dörrar | Från djup 21: små banor med överraskningar (taverna, tre kistor varav en mimic, kranar, 5 golems, en hantverkare) | **SAKNAS** | JA ("Lönnrum") | **hög** | M |
| Otherworld Portals | Bossrum med en Exotic-varelse | **SAKNAS** | JA, som en sällsynt elit | med | S |
| Divination Candle | Betala för att kalla fram 5 grupper av en vald varelse (farma troféer) | **SAKNAS** | JA ("Lockbete", farma en trofé) | med | S |
| Teleportation Shrine | Dold utgång; åk vidare eller hem | **ANPASSAT** (synlig men låst trappa eller boss; GÅ HEM) | JA | – | – |
| Blessings | Favor-ranker ger bonusar i just den Realmen (synvidd, fler kistor, avslöjat altare) | **SAKNAS** | ANPASSAT: Realmens befriade folk tackar, inte gudar | med | M |
| Levande värld | Finns inte | **HAR** (levande kartan, världshändelser; vårt tillägg) | – | – | – |

### 1.3 Bossar och slutspel

| System | Siralim (kort) | Vi | Passar? | Värde | Storlek |
|---|---|---|---|---|---|
| Story-bossar | Per djupsteg, ger Perk Points | **HAR** (Benfursten, biskopen, Bergakungen i datan) | JA | hög | M per boss |
| Rodian Creature Masters och Mastery | En rasmästare per ras med ett nästan rent raslag; varje seger +1 Mastery (± skada mot och från rasen); efter 3 segrar Trait Material, efter 5 en skin | **SAKNAS** (vi har familjer att knyta det till) | JA ("Familjens mästare": Benfolkets mästare, Kultens förman …) | **hög** | M |
| Nether Bosses | 35 st, ett regelbrytande trait i 3 nivåer, var 5:e djup efter storyn; nyckelfragment | **SAKNAS** (idéer i `siralim_innehall.md` §3; motdragen 0.28 är ett frö) | JA | **hög** | M |
| False Gods och Guilds | Bossar med kroppsdelar och runor; gillen med rykte som säljer varelser, spells och dekor | **SAKNAS** | ANPASSAT: "Falska helgon" som fiender (tonen tillåter det); gillen som byar eller ordnar | med | L |
| Gate of the Gods | Djup 240+, 31 gudar, svårighet 1–10, laget skalas till nivå 100, nycklar | **SAKNAS** | NEJ nu: slutspel för ett spel vi inte har ännu | låg nu | L |
| Godforge | Uppgraderar avatarer för Mana och Emblems | **SAKNAS** | NEJ | låg | M |
| Godspawn | Varelser via Projects vid Favor-rank 20 | **SAKNAS** | NEJ (vi rekryterar människor) | låg | – |
| Exotics | Sällsynta varelser i Otherworld-portaler | **SAKNAS** | ANPASSAT: en sällsynt lärjunge bakom en portal | med | M |
| Arena | Draft 6 slumpade mot 5 lag; Infinite, Wild (slumpad regel), Masters; Glory och Fame köper unika saker | **DELVIS** (Övningsgården: fritt möte, ingen draft eller belöning) | JA | med | M |
| PvP | Asynkron i Siralim 3; SU:s arena är mot AI (T) | **SAKNAS** | NEJ (offline mobil) | låg | L |

### 1.4 Slottet, progression och samlande

| System | Siralim (kort) | Vi | Passar? | Värde | Storlek |
|---|---|---|---|---|---|
| Slottet | Teleportation Shrine, Brazier, Blacksmith, Enchanter, Wardrobe, Everett, Refinery, Goblet, Reliquary, Menagerie, Arena, Godforge | **HAR** (Borgen 0.24: Gorm, Hedda, Alrik, Stig, Mor Elin, Sven, Kallets altare) | JA | hög | – |
| Dekorationer | Tusentals föremål, Decoration Mode, egen musik och golv | **SAKNAS** | ANPASSAT: få och meningsfulla, t.ex. troféer på väggen, fanor från bossar | låg–med | M |
| Projects och Missions (Everett) | Låser upp byggnader, nivåer, specs, Realms; Missions: Hunt, Assassination, Pilgrimage, Training, Keyforge, Nether Synthesis | **SAKNAS** (Byggmästaren nämnd i jamforelse.md) | JA | med–hög (långa mål) | M |
| Rekrytering och Menagerie | Mana per besegrad varelse, Summoning Brazier; Menagerie med dialog efter ras | **HAR** (fånge-rum, Värdshuset med samtal 0.29.3) | JA | hög | – |
| Enchanted Wardrobe | Byt spec, återställ perks, kostymer | **HAR** (Kallets altare); kostymer SAKNAS | JA | låg (kostymer) | S–M |
| Skins och accessoarer | Hela utseendet byts; auror och husdjur | **SAKNAS** | JA som belöning (bossens färger på manteln) | låg | M |
| Bestiary och Knowledge | Ranker F–S: lore, livsmätare, mer byte, kort, Assassination | **SAKNAS** (planerat i `siralim_0.19.md`; troféryktena i Biblioteket och Inspect täcker en del) | JA | med–hög | M |
| Cards | Mycket sällsynta drops; set per ras med tre nivåer av bonusar | **SAKNAS** | ANPASSAT: "Vapensköldar" per familj | låg | M |
| Gudar, Favor och Emblems | 30 gudar; Favor-ranker 1–100; butik för Emblems med varelser, inskrifter och dekor | **SAKNAS** | ANPASSAT: inga gudar på spelarsidan. Realmens folk eller ett helgon per Realm, med tack och en butik | med | M |
| Relics och Reliquary | 30 reliker som uppgraderas utan slut för Piety; passiva perks och stats | **SAKNAS** | ANPASSAT: "Helgonreliker" passar paladinen bättre än något annat i listan, men det är ett grindsystem | med | L |
| Rune of Prophecies | Slumpade sidouppdrag i all oändlighet, ger Piety | **DELVIS** (världshändelser med tidsgräns) | JA | med | S |
| Goblet of Trials | Fylls av quests med 3 angivna specs; full = stor skatt | **SAKNAS** | JA ("Kallens bägare": tvingar en att pröva andra kall) | med | S |
| Achievements | Tusentals; poängen höjer Piety | **DELVIS** (titlar i Krönikan) | JA | låg | S |
| Valutor | Brimstone, Crystal, Essence, Granite, Power + Emblems, Notoriety, Glory, Piety, Stardust | **ANPASSAT** (silver och material; avsiktligt få) | JA (få) | – | – |
| Gambling Dwarves | Minispel för Notoriety, Booze-spells | **SAKNAS** | NEJ (spel om pengar passar inte paladinens ton och tillför inget till kombinationerna) | låg | S |
| Story | Kungen av Siralim; berättelsen genom Realms och djup; bossar avslutar kapitel; story-djupen undantas från instabilitet | **DELVIS** (introt, natten, berättarrutor, kronan med tom mitt) | JA | med | M |
| Statistik och krönika | Finns inte (T) | **HAR** (hjältebladet, Krönikan) | – | – | – |
| Codex och handbok | Inbyggd Codex med alla regler | **HAR** (hjälprutor, Broder Alriks handbok) | JA | med | – |
| Sökning och filter | Spelarna saknar det mest (sök i traits) | **DELVIS** (makroeditorns sök 0.30.24; inte i Biblioteket och Förberedelser) | JA | med | S |
| Loot-filter och autosälj | Inte belagt i SU (?) | **SAKNAS**, och behövs inte med våra få material | NEJ nu | låg | – |
| Dagliga och veckovisa utmaningar | Finns inte i SU (?); Wild Arena är närmast | **SAKNAS** | ANPASSAT: "Veckans prövning" med fast frö och regel, offline | med | S–M |
| Molnsparning och flera enheter | Spelarna uppskattar det (§8b) | **SAKNAS** | JA, senare | låg | M |

**Inte belagt i SU:** jag hittade ingen "Gauntlet" i Siralim Ultimate. Wikins sökning ger bara spellen Living Gauntlet
i arenans butik. Arena Infinite (lag efter lag) är det närmaste. Inte heller Lost Souls, nycklar till lönnrum eller
dagliga utmaningar finns belagda.

**Värt att kontrollera:** CLAUDE.md säger att "Siralim har ingen turgräns" (0.30.20). Stridssidan nämner ingen turgräns.
Den gamla listan över Realm Properties på wikin har däremot "Rapid Fatigue: Battle fatigue builds much faster". Det tyder
på att det åtminstone någon gång har funnits en trötthet i striden. VD kan se efter i Codex. Vår Utmattning står sig
oavsett, men "vårt val" kan behöva bli "som Siralim".

## 2. Topp 10: det som saknas och är värt att bygga

Ordningen följer ledstjärnan: det som skapar nya kombinationer kommer först, innehåll och grind sist.

1. **Valbara förmågor med egenskaper (Spell Gems och Enchanter, ANPASSAT, L).** Varje hjälte får en pool med 4–6
   förmågor och väljer 3 för körningen. Förmågorna får sedan inskrifter med originalets egenskaper (Cascading, chans att
   kasta två gånger, Generous …) hos en "Runristare" eller Broder Alrik. Det är originalets andra stora bygglager efter
   traits, och det enda stora som helt saknas. Det ger också fynd med mål: inskrifter i grottan. Börja med valet
   (M) och lägg egenskaperna efteråt.
2. **Familjens mästare (Rodian Masters och Mastery, JA, M).** Vi har redan familjer med egna egenskaper. En mästare per
   familj, bara på det djupaste djupet. Varje seger ger +1 Mastery (några procent skada mot och från familjen), efter
   3 segrar mästarens trofé. Det ger ett skäl att gå tillbaka, ett mål att bygga mot och ett lätt sätt att få nya
   troféer.
3. **Nether Bosses: bossar med en enda regel (JA, M).** En boss med ett regelbrytande drag i tre nivåer (immun så länge en
   allierad lever, dödar alla varannan tur …). Spelaren måste bygga om mot just den regeln, vilket är exakt det testet
   frågar efter: byter man trofé för att prova en ny kombination? Motdragen (0.28) och Bergakungen är fröet. Belöning:
   nyckelfragment eller en Nether Stone.
4. **Minions med ljust tema (ANPASSAT, L).** Ett eget bygglager: hjältar som kallar en falk, en vakthund eller rotskott,
   och troféer och kall som stärker dem. Originalet bygger flera specs på det (Necromancer, Inquisitor). Djupt för
   kombinationerna, men en del motorarbete i CombatSim: platser, tidslinjen, mål och makrovillkor. Aldrig nekromanti på
   spelarsidan.
5. **Lönnrum (Nether Realm-dörrar, JA, M).** En sällsynt dörr i grottan leder till en liten handgjord scen: tre kistor
   varav en mimic, en hantverkare som gör ett smide gratis, en mini-boss som tappar sin trofé, fem skattväktare. VD vill
   ha "mer spel" i grottan (§19), och lönnrummen ger överraskning utan att göra kartan större. Återanvänder
   rumsögonblicken.
6. **Skattväktaren och irrblosset (Treasure Golem och Dumpling, JA/ANPASSAT, S).** En sällsynt grupp som försöker fly
   varje tur. Fäller man den i tid får man silver och material (golemen) eller mycket erfarenhet (irrblosset). Billigt:
   ett trait och en AI-regel. Ger glädjeskrik och ett skäl att bygga för snabbhet och första draget. Se till att den ser
   allvarlig ut, inte gullig.
7. **Bestiariet med kunskapsranker (JA, M).** Planen finns redan i `siralim_0.19.md`: en sida per fiendetyp, ranker som
   avslöjar avsiktsregler, troféer och till sist en liten skadebonus. Gör planeringen begriplig (vad lämnar vem, vad
   gör den) och är rätt plats för den sökning spelarna saknar mest i originalet (§8b).
8. **Projects hos en byggmästare (JA, M).** Långa mål som låser upp saker i borgen: Smedens nivåer, Värdshusets platser,
   ett fjärde kall, Refinery, Kallens bägare. Delar från strider och quests. Originalet är tydligt: det är Projects som
   får en att vilja komma tillbaka. Håll listan kort för att undvika grindkritiken.
9. **Prövningar i Övningsgården (Arena Wild och Masters, JA, M).** Draft: välj 4 av 8 slumpade hjältar och troféer och
   möt 5 grupper under en slumpad regel, med en liten belöning (en trofé eller ett material). Tvingar fram nya
   kombinationer med hjältar man annars inte använder. Med fast frö blir det också "Veckans prövning" utan nät.
10. **Realmens tack: Favor och välsignelser (ANPASSAT, M).** I stället för gudar tackar Realmens befriade folk (eller ett
    helgon per Realm). Favor från föremål, eliter och quests ger ranker med små välsignelser i just den Realmen
    (synvidd, en skatt till, ett avslöjat mål) och en butik. Ger skäl att välja Realm, och passar ihop med den levande
    kartan och Fortune (+20 % byte per quest i följd, S), som kan byggas samtidigt.

**Medvetet utanför topp 10:** Gate of the Gods, avatarer och Godforge (gudar på spelarsidan, och slutspel för ett spel vi
inte har ännu), PvP (offline), Gambling Dwarves (fel ton), Cards och Relics (grindsystem med lite kombinationsdjup per
arbetsinsats; relikerna passar paladinen tematiskt och kan bli slutspel), dekorationer och skins (låg nytta för det
roliga nu), klasscirkeln (väntar på fler hjältar).

## Källor

- Wikin (läst 2026-10-24): [Gate of the Gods](https://siralimultimate.wiki.gg/wiki/Gate_of_the_Gods),
  [Avatar](https://siralimultimate.wiki.gg/wiki/Avatar), [Currency](https://siralimultimate.wiki.gg/wiki/Currency),
  [Blessings](https://siralimultimate.wiki.gg/wiki/Blessings), [Achievements](https://siralimultimate.wiki.gg/wiki/Achievements),
  [Projects](https://siralimultimate.wiki.gg/wiki/Projects), [Realms](https://siralimultimate.wiki.gg/wiki/Realms)
  (Realm Properties, Instability, Nether Realm), [Gods](https://siralimultimate.wiki.gg/wiki/Gods),
  [Cards](https://siralimultimate.wiki.gg/wiki/Cards), [Arena](https://siralimultimate.wiki.gg/wiki/Arena),
  [Specializations](https://siralimultimate.wiki.gg/wiki/Specializations), [Combat](https://siralimultimate.wiki.gg/wiki/Combat),
  [Goblet of Trials](https://siralimultimate.wiki.gg/wiki/Goblet_of_Trials), [Golem](https://siralimultimate.wiki.gg/wiki/Golem),
  sökningarna "gauntlet" och "dumpling".
- Utvecklarens funktionslista mot Siralim 3 (Steam, mars 2021):
  [What's different](https://steamcommunity.com/app/1289810/discussions/0/4164113537231972561); spelartråd
  [3770113150035347768](https://steamcommunity.com/app/1289810/discussions/0/3770113150035347768).
- [Treasure Golem, japanska wikin](https://wikiwiki.jp/siralim_ult/Treasure%20Golem);
  [Dwarf Riddle Answer key](https://gamepretty.com/siralim-ultimate-dwarf-riddle-answer-key-8-10/).
- Tidigare research i repot: `docs/research/siralim.md` (Codex Reference 2.0.37, §8b spelarnas åsikter, §10c slottet,
  §18 Spell Gems, §19 föremål i Realms), `siralim_0.19.md` (Knowledge, Mastery, Bestiarium),
  `siralim_innehall.md` (Nether Bosses, False Gods), `jamforelse.md`.
