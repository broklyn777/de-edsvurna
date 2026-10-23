# Långsiktiga mål: vad håller spelare kvar i 50–500 timmar?

Research 2026-10-24 (grenen `research-langsiktiga-mal`, skuren från `test-0.30`). Underlag för VD, **inga beslut**.
Säkerhet som i `docs/research/siralim.md`: SÄKERT (källa eller originalets text), TROLIGT (flera spelare eller härlett),
GISSNING (vår tolkning). Källor sist.

Frågan: vad får folk att spela Siralim-liknande spel och roguelites i hundratals timmar, vad har vi i dag per fas, var
saknas det och vad kan vi planera? Ledstjärnan gäller också här: **långsiktiga mål ska få spelaren att prova nya
kombinationer, inte bara samla mer av samma sak.**

---

## 1. Kort svar

Spel som håller i hundratals timmar har nästan alltid fyra saker samtidigt (TROLIGT, mönstret i §2):

1. **En frivillig stege uppåt** som spelaren väljer själv (Ascension, Heat, Boss Cells, Covenant, Siralims djup och
   instabilitet). Den fungerar bäst när varje steg är en *regel* och inte bara större tal, och när steget ger en
   engångsbelöning per kombination (Hades bounties per vapen och Heat).
2. **En samling med synliga luckor** (Siralims Codex och skapelser, Dead Cells blueprints, Hades Codex). Luckan är målet;
   man ser vad som saknas och ungefär var det finns.
3. **Mästarskap per byggdel** (Siralims Ascension per Specialization × gud, Monster Trains klannivåer, StS Ascension per
   karaktär). Det gör att man byter bygge med flit, vilket är precis vårt viktigaste test.
4. **En berättelse eller värld som droppar** i små portioner efter verkliga händelser (Hades, Darkest Dungeons hamlet,
   vår krönika och levande värld). Den bär de första 50 timmarna bättre än siffror.

Vi har redan mycket av 1 och 4 och en början på 2. **Det som saknas mest är 3 (mästarskap per kall och hjälte) och ett
slutspel efter djup 6–7**, där botarna visar att nivåkurvan tar slut (`docs/provspel/svarighetskurva.md`).

---

## 2. Mekanismer per spel

### 2.1 Siralim Ultimate (vår förebild)

| Mekanism | Hur den fungerar | Säkerhet |
|---|---|---|
| **Realm Depth** utan tak | Djupare = starkare fiender och bättre byte. Vissa funktioner låses upp av max djup. Bonus på byte bara på det djupaste djupet man besökt. Spelare rapporterar djup 900–1 800. | SÄKERT (wiki Realms; Steam) |
| **Realm Instability** 1–5 | Från djup 33. Två Realm Properties per nivå (en synlig, en dold), fiender från andra Realms, sammansmälta fiender; bytesbonus upp mot 400 %. | SÄKERT (wiki Realms) |
| **Nether Bosses** | Efter berättelsen, var femte djupnivå, via portal. Ett regelbrytande trait i tre svårighetsgrader. | SÄKERT (wiki; vår siralim.md §10) |
| **Nether Realms, Otherworld Portals** | Sidonivåer från djup 21; exotiska varelser från djup 30. | SÄKERT (wiki Realms) |
| **Gate of the Gods / Ascension** | Slå alla 30 gudar med en Specialization på svårighet 10+ → Specializationens sista perk, en dekoration och ett utseende. 30 × 30 = 900 nycklar; spelare kallar det "the ultimate endgame goal". | SÄKERT (Steam, japansk wiki) |
| **Masters / Mastery** | "Gym leaders" per ras; tre segrar ger rasens trait som material. Vi har redan bosstroféer efter tre segrar. | SÄKERT (utvecklarens lista; siralim.md §11) |
| **Rune of Prophecies → Piety → Relics** | Oändliga slumpade uppdrag ger Piety; 30 reliker uppgraderas utan slut. | SÄKERT (utvecklarens lista) |
| **Projects** (Everett) | Samla föremål i Realms för att låsa upp nya platser och funktioner i slottet. Codex rådde att alltid ha många igång. | SÄKERT (siralim.md §10c) |
| **Guilds, False Gods** | Rykte som låser upp varelser och dekorationer; jättebossar med kroppsdelar. | SÄKERT |
| **Achievements** | Tusentals, ger Piety (en del udda, t.ex. att ge upp mot vissa fiender). | SÄKERT (siralim_0.19.md) |
| **Dekorationer, skins, accessoarer** | Kosmetik för slott och varelser. | SÄKERT |

**Vad som fungerar** (TROLIGT, spelarrapporter i siralim.md §8b): svårigheten kommer i *murar* som kräver ombygge, inte
grind. "Fiender skalar snabbare än ens nivåer; svaret är nya traits" (FAQ). Mästarskapet per Specialization (Ascension)
är det mål som de mest hängivna nämner.
**Vad som kritiseras:** menydjungeln, fem valutor, att striderna blir automatiska runt djup 30 (en rapport) och att
slutspelets system är många och utspridda.

### 2.2 Slay the Spire – Ascension

- 20 kumulativa steg **per karaktär**; varje steg lägger till en regel (fler eliter, sämre helning, svårare bossar,
  dubbel boss på A20). Förlust sänker inte nivån. (SÄKERT, Pocket Gamer, Destructoid)
- Ungefär hälften av stegen är rena siffror, resten regler. (SÄKERT, Pocket Gamer)
- **Daily Climb:** samma frö för alla och tre slumpade regelbrytande modifierare per dag. Poäng kräver nät; utan nät
  sparas inte poängen. Topplistorna förstörs av fusk. (SÄKERT/TROLIGT, StS-wiki, Steam)
- **Vad som fungerar:** per karaktär → man spelar alla karaktärer, inte bara den bästa. En tydlig siffra ("jag är på A14
  med Silent") är ett mål man själv kan berätta om.

### 2.3 Hades – Pact of Punishment och Heat

- Paktens villkor (15, i Hell Mode 16) väljs fritt och summeras till Heat. Inbyggd i berättelsen. (SÄKERT, Prima, RPG Site)
- **Bounties per vapen och Heat:** varje boss ger sin belöning *en gång* per vapen och Heat-nivå. Delvisa framsteg räknas
  (två bossar av fyra ger två belöningar). (SÄKERT, RPG Site, Fextralife)
- Öppnas först efter första flykten.
- Berättelsen droppar efter varje försök, vunnet eller förlorat; relationer och keepsakes ger mål utan siffror.
  I Hades II: **Fated List of Minor Prophecies**, 89 profetior som belönar att man gör saker i världen. (SÄKERT, Hades-wiki)
- **Vad som fungerar:** spelaren bygger sin egen svårighet av regler; belöningen per kombination (vapen × Heat) gör att man
  byter vapen. Förlust ger ändå berättelse. Listan av profetior är achievements i världens språk.

### 2.4 Dead Cells – Boss Cells

- 0–5 Boss Stem Cells, permanenta svårighetssteg; varje fås genom att slå slutbossen med de föregående aktiva. (SÄKERT, wiki)
- **Ritningar (blueprints) och vägar som bara finns på högre steg** – svårigheten låser upp innehåll, inte bara mer liv.
  (SÄKERT, wiki)
- **Vad som fungerar:** samlingen och svårigheten hänger ihop; man vill upp ett steg för att det finns nya saker där.

### 2.5 Monster Train – Covenant, klannivåer, utmaningar

- 25 Covenant-nivåer. Klar på Covenant 25 låser upp **Expert Challenges**: fasta mutatorer, Covenant låst till 25.
  (SÄKERT, fandom-wiki)
- Varje klan har 10 nivåer som låser upp kort; att nå nivå 10 är en achievement per klan. (SÄKERT/TROLIGT)
- Daglig utmaning med mutatorer och topplista; en Logbook med mål och samlingsuppgifter (tydligast i MT2). (SÄKERT, butik)
- **Vad som fungerar:** två axlar (klanparet och Covenant) ger många kombinationer att "klara". Mutatorer är regler.

### 2.6 Darkest Dungeon

- Slutspelet är Darkest Dungeon själv: hjältar som klarat en expedition dit **vägrar gå tillbaka**, så man måste bygga
  flera lag. Radiant lättar på det; Stygian har tidsgräns och svårare fiender. (SÄKERT, DD-wiki)
- Hamlet-uppgraderingar ger långsiktig plan; hjältarna har egenheter och minns saker.
- DD2 bytte metaspel till Altar of Hope: ljus (candles) från expeditioner köper uppgraderingar i fyra grenar. (SÄKERT, NME)
- **Vad som fungerar:** en regel som tvingar fram bredd (vägran) gör hela truppen viktig. **För oss** (GISSNING): ett mjukt
  släkte av samma idé finns redan i Värdshuset (följeslagare som vill följa med efter två nedstigningar hemma).

### 2.7 Path of Exile / Diablo – säsonger (lätt)

- Ny mekanik var 3–4:e månad på en ny figur; gamla figurer flyttas till Standard. Motiv: ny ekonomi och lika start.
  (TROLIGT, bloggar och forum, inte officiellt)
- **För oss:** onlineekonomi och nollställning passar inte ett offline-spel för mobil. Det som kan lånas är *rytmen*:
  ett nytt tema med egen regel då och då, utan att ta något ifrån spelaren.

### 2.8 Tvärgående mekanismer

| Mekanism | Vad som fungerar | Risk |
|---|---|---|
| **Samling, codex, bestiarium** | Synliga luckor och "var finns den?" (Dead Cells, Siralim Codex). | Blir en checklista om luckorna inte leder till nya kombinationer. |
| **Achievements som vägledning** | Visar system som spelaren annars missar (Hades profetior). | Forskning och essäer varnar för att yttre mål kan tränga undan egna mål i spel där utforskande är kärnan (UCF-avhandlingen; populärvetenskap, inte granskat). Därför: i världens språk, få och meningsfulla. |
| **Dagliga/veckovisa fröer** | Samma utmaning för alla; ett nytt pussel att lösa. | Topplistor kräver nät och lockar fusk (StS). Dagliga serier skapar stress (FOMO) – fel ton för oss. Ett **lokalt frö per vecka** fungerar offline. |
| **New Game+** | Fungerar i spel med en fast kampanj. | Siralim har inget NG+; djupet *är* dess NG+. Vi bör göra samma sak. |
| **Mästarskapsspår** | Per karaktär/klass (StS, Siralim Ascension, MT klannivåer). Får spelaren att byta bygge. | Får inte bli grind; ska vara kort per steg. |
| **Kosmetik** | Visar vad man klarat (Siralims dekorationer, skins). | Måste vara allvarlig i vår ton: heraldik, banér, troféer på väggen, inte hattar. |
| **Bygg-delning** | Siralim-spelare delar lag i forum; StS-spelare delar fröer. | Kräver ett kompakt format; inget nät behövs om det är en textkod. |

---

## 3. Våra mål i dag per fas

Speltid är en uppskattning: en nedstigning är 6–11 strider, 2–5 minuter per strid plus steg och borgen
(`provspel-0.30.14.md`), alltså ungefär 40–70 minuter. Botarnas karriär når djup 5–6 efter ~15–18 nedstigningar.
(GISSNING: 12–20 timmar dit för en spelare.)

| Fas | Vad spelaren strävar efter i dag | System som bär det | Luckor |
|---|---|---|---|
| **Första timmen** | Edens intro, svärdet, övningsstriden, natten, ned ensam, Imma smiter efter, första kombinationen (Rökpil + Rättfärdigt slag), första bossen. | Introt, hjälprutor, "Kombination!", "Det här avgjorde striden". | Bra täckt. Målet efter introt ("vad gör jag nu?") står bara i uppdragsraden; inget "nästa mål" efter introt. |
| **1–10 h** | Befria lärjungar (12 hjältar), djup 2–4, kapellet och Sidenlunden, smida och nivå på artefakter, perks, bosstroféer (3 segrar), titlar, löften, krönikan, kartans fördärv och världshändelser. | Grottan, Realm Quest, smedjan, altaret, krönikan, levande kartan, WorldEvents. | Steget till djup 2 (mildrat 26 → 41 %). **Djup 1 är en tom platå** (svårighetskurvan, fråga 4). Ingen överblick av vad som är kvar att göra. |
| **10–50 h** | Djup 4–7, artefakt nivå 10, Nether Stones, instabilitet 1–3, sällsynta elitvarianter, alla 15 titlar, perk-nivåer, lånad perk. | Djup, instabilitet, troféjakt, Forge. | **Taket vid djup 6–7**: nivåkurvan når inte fiendernas (26 mot 28, 30 mot 33). Bara 3 kall, 3 Realms; inget mål per kall. Instabilitet ger bara silver och troféchans, ingen engångsbelöning. Kurvan pendlar kring 45 % utan riktning. |
| **50 h+** | Inget designat. | – | **Inget slutspel**: inga bossar efter berättelsen, inget mästarskap, inga återkommande utmaningar, ingen samling som säger vad som saknas. |

Det vi har som andra saknar (TROLIGT): krönikan, titlarna och den levande världen är en ovanligt stark motor för de
första 50 timmarna, eftersom de reagerar på det spelaren faktiskt gjort. De bör bära även slutspelet: varje förslag
nedan ska kunna synas i krönikan och ge en replik.

---

## 4. Förslag, rangordnade från litet till stort

Ordningen är efter storlek och nytta per arbete. Varje förslag anger Siralim-förebild, ton och vilka system som återanvänds.

### 1. Bestiariet i Biblioteket (litet)

**Vad:** Broder Alriks bibliotek visar varje fiende som en rad: besegrade gånger, **kunskapsrank** 1–3 (t.ex. 5 / 25 / 100
segrar) som avslöjar mer (egenskaper, motdrag, vilken trofé, vilken trofé som svarar på den: `answers`), och var den
finns (Realm, våning). Okända fiender är tomma rader med en siluett och ett rykte. Räknare "Troféer 23 / 49".
**Siralim:** Bestiary och Knowledge-ranker (SÄKERT, siralim_innehall.md §7). **Ton:** en lärd munks anteckningar.
**Återanvänder:** Biblioteket, troféernas lektion, `answers`, Inspect, krönikans räknare.
**I dag:** Biblioteket visar troféerna och kryptans troféer som rykten (0.24.3), men inga räknare per fiende
och ingen kunskapsrank. **Varför först:** ger djup 1-platån en mening (kunskap att samla), gör luckorna synliga och är nästan bara UI.

### 2. Engångsbelöningar per Realm × djup × instabilitet (litet)

**Vad:** som Hades bounties. Första gången man klarar en Realm Quest på en ny kombination av Realm, djup **och
instabilitet** ger det något en gång: instabilitet 1 ett trick, 2 en Nether Stone, 3 en sällsynt Nether Stone. En liten
tabell på kampanjkartan visar vad som är taget (tusch-bock).
**Siralim:** bytesbonusen på det djupaste djupet och instabilitetens bonus (SÄKERT); Realm Questens perk-poäng per ny
kombination finns redan hos oss. **Återanvänder:** `Profile` (samma nyckel som perk-poängen), `Forge.roll_stone`,
kampanjkartan, krönikan ("första gången på instabilitet 2 i kapellet").
**Varför:** instabiliteten blir ett mål i sig, och man byter Realm för att samla bockarna.

### 3. Alriks lista: profetior i världens språk (litet–medel)

**Vad:** 30–60 korta uppdrag som achievements, men skrivna som rader i krönikan ("Låt en trofé väcka en annan i samma
tur", "Vinn en strid där Paladinen aldrig anföll", "Håll löftet Jag helar inte i kapellet"). Varje uppdrag lär ut en
kombination eller ett system; belöningen är silver, material eller en titel, och en replik av den som bryr sig.
Visas en handfull åt gången (nästa öppnas när en klaras), aldrig hundratals.
**Förebild:** Hades II:s Fated List (SÄKERT); Siralims achievements ger Piety. **Ton:** profetior, inte poäng.
**Återanvänder:** krönikan (`chron_stats`), titlarna, `BattleSummary.deciders`/`combo_stats` (vad som avgjorde), dialog-id:n.
**Varför:** det direkta svaret på ledstjärnan: mål som *pekar på kombinationer* i stället för mer skada. Här kan "Nästa
mål" efter introt också bo.

### 4. Kallets ära: mästarskap per kall (medel)

**Vad:** varje kall har ett spår: klara en Realm Quest på djup 1, 3, 5, 7 … med kallet valt → en stjärna per Realm och
djup. Tre stjärnor i varje Realm ger kallets **sista perk** (en regelbrytare som bara finns så), ett banér i borgen och en
titel. Behöver fler kall för att bära (Warden, Inquisitor står redan i "Nästa steg").
**Siralim:** Ascension per Specialization × gud (SÄKERT) – det mål som hängivna spelare kallar slutspelet. StS Ascension
per karaktär. **Återanvänder:** kallen och perks (`oaths.json`), altaret, kampanjkartan, titlar.
**Varför:** tvingar fram att man byter kall och bygger om, vilket är vårt viktigaste test.

### 5. Veckans prövning, offline (medel)

**Vad:** ett frö per ISO-vecka, räknat lokalt ur datumet (inget nät): fast Realm, djup, två våningsregler och ett löfte,
kanske ett krav på sällskapet ("utan Brokk"). En nedstigning, en gång per vecka med full belöning, sedan fritt utan
belöning. Resultatet går in i krönikan; ingen topplista, ingen serie som bryts. Portvakten Sven eller en budbärare
berättar om "veckans rykte".
**Förebild:** StS Daily Climb och MT:s dagliga utmaning (SÄKERT), utan nätet och stressen. **Ton:** en uppgift från
landet, inte ett event. **Återanvänder:** `Grotto.generate` med frö, `floor_rules.json`, `vows.json`, kampanjkartan.
**Risk:** en vecka är långt för den som spelar mycket; tidsresa via klockan är ofarlig offline.

### 6. Stigs mästare i Övningsgården (medel)

**Vad:** vapenmästaren Stig har en stege med 10–15 fasta strider ("mästare"), var och en ett pussel med en regel: "en
grupp som bara kan skadas av förmågor", "en fiende som speglar buffar". Klarad tre gånger ger en sällsynt trofé eller en
lektion. Inga Charges förbrukas; strider på riktigt djup.
**Siralim:** Rodian Creature Masters och Mastery (SÄKERT). **Återanvänder:** Övningsgården, `--encounter`, encounters.json,
bosstrofé-räknaren (`boss_wins`), `BattleSummary.alternatives`.
**Varför:** ger en plats att pröva ett bygge mot ett känt problem, och sprider troféer som annars bara finns djupt ned.

### 7. Djupets väktare och ett riktigt slutspel för djupet (medel–stort)

**Vad:** två delar. (a) Lös taket vid djup 6–7: antingen följer erfarenheten djupet hårdare, eller så ger djupet något
som bär (fler perk-poäng, artefakt över nivå 10). Botarna ska visa att en bra spelare kan fortsätta. (b) Var femte djup
(5, 10, 15 …) vaktas en Realms trappa av en **väktare** med ett regelbrytande trait i tre grader, som Nether Bosses; en
förvriden boss från den levande kartan är en färdig förlaga (Den svärtade Benfursten). Väktaren ger sin trofé efter tre
segrar, som bossarna.
**Siralim:** Nether Bosses var femte djup (SÄKERT); djup utan tak. **Ton:** allvarliga, Drakvalvets monster
(`docs/research/drakvalvet-monster.md`), inga skämtfigurer. **Återanvänder:** `HeroStats.enemy_level`, levande kartans
förvridna bossar, bosstroféer, motdragen (`counter`).
**Varför:** utan detta tar spelet slut runt 20 timmar för den som spelar bra.

### 8. Heraldik och trofésalen (medel)

**Vad:** allvarlig kosmetik som visar vad man klarat: paladinens vapensköld och banér (färger och sinnebilder låses upp av
titlar, kallets ära och väktare), troféer som hängs på väggen i borgen (planritningen får en sal), mantelns färg i
striden. Inget köps.
**Siralim:** dekorationer och skins som belöning för Ascension (SÄKERT). **Ton:** heraldik passar en edsvuren paladin;
inga hattar. **Återanvänder:** `keep.json` (ny sal), `KeepArt`, titlarna, `unit_model` (`tint`).

### 9. Sällskapets sigill: dela bygget som text (medel)

**Vad:** "Kopiera sigill" i Förberedelser ger en kort textkod med sällskap, kall och perks, troféer, artefakttyper och
makron. "Läs sigill" visar bygget och låter spelaren prova det i Övningsgården med sina egna ägda delar (det som saknas
markeras). Delas i chatt eller forum, inget nät i spelet.
**Förebild:** fröer och lag som delas i StS och Siralims forum (TROLIGT). **Återanvänder:** `macros.json`-formatet,
Övningsgården, `BattleSummary`. **Varför:** makron är svåra; att se någon annans är det snabbaste sättet att lära sig.

### 10. Byggmästarens projekt (stort)

**Vad:** en byggmästare i borgen som tar emot föremål från grottan (quest-föremål, Realmens föremål, väktartroféer) och
bygger ut borgen: fler artefaktnivåer, ett nytt kall, en tredje trofé-plats, ett kapell för Ragnhild, en karta över
Nether-djupen. Flera projekt igång samtidigt; varje klart projekt syns i planritningen och i krönikan.
**Siralim:** Everett och Projects (SÄKERT; Codex rådde att alltid ha flera igång). **Ton:** återuppbygga det fördärvet tog.
**Återanvänder:** borgen och `keep.json`, levande världens följder och gåvor (projekt kan bero på att en Realm hålls nere),
grottans föremål, Forge. **Varför sist:** störst, och behöver de andra målen för att ha något att låsa upp.

### Inte nu

- **Topplistor och dagliga serier:** kräver nät och fuskskydd, och serier ger stress som inte hör till tonen.
- **Säsonger med nollställning:** fel för ett offline-spel; rytmen kan lånas via veckans prövning och nya Realms.
- **New Game+:** djupet är vårt NG+, som i Siralim.
- **Fler valutor:** Siralims fem valutor är en del av grind-kritiken (siralim.md §10d). Projekten bör ta föremål, inte en ny valuta.

---

## 5. Ordning, förslag (inget beslut)

1. **Bestiariet** och **engångsbelöningarna** – små, ger djup 1 och instabiliteten mening direkt.
2. **Alriks lista** – mål som pekar på kombinationer, och "nästa mål" efter introt.
3. **Taket vid djup 6–7** (del a av förslag 7) – mät med `SOAK=karriar` innan något byggs ovanpå.
4. **Kallets ära**, när det finns 5–6 kall.
5. **Stigs mästare**, **veckans prövning**, **väktarna**.
6. **Heraldik**, **sigill**, sist **projekten**.

Frågor till VD:
- Ska djupet vara utan tak som i Siralim, eller ska spelet ha ett "slut" (t.ex. djup 10 och en sista väktare) och sedan
  bara frivilliga stegar?
- Hur många kall är målet? Mästarskap per kall bär först med fler än tre.
- Vill vi ha något veckovis alls, eller räcker det spelaren själv väljer (löften, instabilitet)?

---

## Källor

- Siralim Ultimate-wikin, Realms: https://siralimultimate.wiki.gg/wiki/Realms
- Utvecklarens översikt av slutspelet (Steam): https://steamcommunity.com/app/1289810/discussions/0/4164113537231972561
- Gate of the Gods och nycklar (Steam): https://steamcommunity.com/app/1289810/discussions/0/5457797888012219729
- Gate of the Gods, gudarnas effekter (Steam): https://steamcommunity.com/app/1289810/discussions/0/3412055301111162879
- Ascension (japansk Siralim-wiki): https://wikiwiki.jp/siralim_ult/Ascension
- Slay the Spire Ascension: https://www.pocketgamer.com/slay-the-spire/ascension-guide och https://www.destructoid.com/?p=1190035
- Slay the Spire Daily Climb: https://intothespine.com/2018/03/05/slay-the-spire-daily-climb/ ,
  https://slaythespire.wiki.gg/wiki/Custom_Mode , https://steamcommunity.com/app/646570/discussions/2/1697168437877807582
- Hades, Pact och bounties: https://www.rpgsite.net/feature/10287-hades-pact-of-punishment-heat-modifiers-and-how-to-maximize-your-rewards ,
  https://primagames.com/gaming/hades-guide-pact-of-punishment-modifiers-heat , https://hades.wiki.fextralife.com/New+Game+Plus
- Hades II, Fated List: https://hades.fandom.com/wiki/Fated_List_of_Minor_Prophecies/Hades_II
- Dead Cells, Boss Stem Cells och blueprints: https://deadcells.wiki.gg/wiki/BSC , https://deadcells.wiki.gg/wiki/Blueprint
- Monster Train, Expert Challenges: https://monster-train.fandom.com/wiki/Expert_Challenges?oldid=9905 ;
  butikssida: https://www.playstation.com/en-ca/games/monster-train/
- Darkest Dungeon, lägen och Darkest Dungeon: https://darkestdungeon.wiki.gg/wiki/Game_Modes ,
  https://darkestdungeon.fandom.com/wiki/Darkest_Dungeon_(location)
- Darkest Dungeon II, Altar of Hope: https://www.nme.com/news/darkest-dungeon-2-update-introduces-a-new-progression-system-3318046
- Path of Exile, säsonger (blogg, inofficiellt): https://game-wisdom.com/general/design-philosophy-behind-poe-2s-seasonal-model-resetting-everything-works
- Achievements och motivation: https://stars.library.ucf.edu/etd/1827
- I repot: `CLAUDE.md`, `docs/provspel/svarighetskurva.md`, `docs/provspel/provspel-0.30.14.md`, `docs/research/siralim.md`
  (§8b, §10–10d), `docs/research/siralim_innehall.md` §7, `docs/plan/levande-karta.md`, `docs/plan/loften.md`,
  `src/game/chronicle.gd`, `src/game/world_events.gd`, `data/titles.json`.
