# Följeslagarnas relationer och personliga uppdrag (research, 2026-10-24)

Fråga: vad får en ensam spelare att fästa sig vid följeslagare, och hur passar det oss (De edsvurna)? Underlag: webbkällor
nedan, CLAUDE.md, `data/heroes.json`, `data/dialog.json`. `docs/research/levande-repliker.md` finns inte på test-0.30.
Siffror ur fan-wikier är andrahandsuppgifter och markeras (wiki).

## Vad vi redan har

- **12 hjältar** (`heroes.json`): Paladinen, Imma, Brokk, Syster Alva, Eira, Solveig, Ronja, Lirien, Tove, Hulda, Ragnhild,
  Sefir. Var och en har roll, en egen egenskap och en signatur.
- **Repliker** (`dialog.json`): `barks` för 8 följeslagare (14 tillfällen: hard_fight, campfire, rare_find, rescue, new_realm,
  alone, cave, elite, back, treasure, stairs, boss, fallen, home; ca 210 rader), `pairs` (17 tvåradssamtal, 7 av dem med
  Ragnhild; tillfällena campfire, cave, hard_fight, elite), `inn` (värdshusets repliker: inn, bored, welcome, för 11),
  `chronicle` (147 rader i 35 nycklar vid hemkomsten, bl.a. `rescued`, `fell`, `hurt`, `new_trophy`), `living_map`, `world`.
- **Minne i profilen**: `recruited`, `descents`, `home_runs`, `inn_heard`, `narrated`, `worn` (troféerna följer hjälten),
  `heroes` (nivåer), `boss_wins`. **Stridens händelser** bär redan vem som helade vem (`heal` med `source`/`target`),
  `revive`, `death`, och `CombatSim.trait_stats` räknar vad varje egenskap gjorde.
- **Regler att respektera**: troféer är *föremål som tagits eller lärdomar* (`lesson` i traits.json), följeslagarna är
  bristfälliga människor och inte helgon, spelarens sida är aldrig ockult, Ragnhild citerar bara 1917 års bibel ordagrant,
  repliker har fasta id:n, och de reagerar på verkliga händelser (minnet "lines follow progress").

Det som saknas är **riktning över tid**: replikerna är lösa ögonblick, inget samlas till en båge per person eller par.

## Spelen

### Hades (Supergiant, 2020)
**Mekanism.** Nektar (sällsynt valuta från rummen) ges som gåva; den första ger en **keepsake** tillbaka, ett föremål man
bär under en körning som ger en effekt och som stärks av att bäras. Varje gåva fyller ett hjärta; efter ca 5–6 hjärtan
öppnas personens uppdrag (wiki), och först när det är klart kan resten fyllas med den sällsyntare Ambrosia. Bakom ligger
ett enormt manus (över 22 000 röstade repliker enligt GDC-talet) som väljs efter spelets tillstånd: Dionysos kommenterar
ditt nektarförråd, Ares ditt vapen. Kasavin: "motsatsen till skriptat".
**Fungerar.** Förloppet syns (hjärtan), gåvan ger något *användbart* tillbaka, och bågen har ett mål (uppdraget). Repliker
som vet exakt vad du just gjorde gör att varje körning känns som en ny dag i samma liv. Döden är en anledning att prata.
**Fallerar.** Kräver väldigt mycket text; nektar blir till slut en checklista ("ge alla en flaska"). Relationer utan
spelpåverkan efter keepsaken.

### Hades II (2024–25)
Samma grund: den första nektaren ger keepsaken, varje gåva höjer relationen ett steg, varje person ger bara en keepsake.
Nytt är att man kan köpa nektar i Korsvägen (basen) via en besvärjelse. **Lärdom**: valutan till relationer bör komma ur
körningen men kunna jämnas ut hemma, så att otur inte låser bågar.

### Baldur's Gate 3 (Larian, 2023)
**Mekanism.** Godkännande −50 till 100 (wiki) som rör sig när följeslagaren *ser* dina val; höga nivåer öppnar personliga
uppdrag och romanser, mycket lågt får dem att gå. **Lägret** är scenen: efter vila spelas nattscener när godkännande och
berättelsesteg räcker. Godkännande växer långsamt för den som sitter kvar i lägret.
**Fungerar.** Lägret som plats för samtal (paus mellan spänning); personliga uppdrag som rör den yttre världen (deras
förflutna dyker upp i *din* väg). Att de ogillar saker gör dem till människor.
**Fallerar.** Oklart varför siffran rör sig ("Astarion ogillade det" utan förklaring), spelare sparar och laddar för att jaga
godkännande; kräver dialogval, vilket vi inte har (Paladinen är ingen dialoghjälte).

### Dragon Age: Origins / Inquisition (BioWare)
**Mekanism.** Origins: godkännande −100 till +100, gåvor (rätt gåva till rätt person ger mycket, fel ger lite),
personliga uppdrag öppnas vid tröskel, **party banter** när man går med vissa i sällskapet. Inquisition flyttade
godkännandet från gåvor till handlingar och åsikter (BioWare 2014) och fick lappa banter-systemet efter lanseringen
eftersom följeslagarna teg i timmar (patch 3 gjorde utlösningen mer slumpad och vanligare).
**Fungerar.** Banter mellan två är det billigaste och mest omtyckta: det visar att de har liv även utan spelaren, och
belönar att man tar med olika personer. **Fallerar.** Gåvor som köper kärlek blir mekaniska (Inquisitions egen slutsats);
för sällsynt banter märks inte alls.

### Mass Effect 2 (BioWare, 2010)
**Mekanism.** Varje följeslagare har ett **lojalitetsuppdrag** om deras förflutna. Lojal = ny kraft, ny dräkt och bättre
chans att överleva självmordsuppdraget i slutet; uppdraget öppnas efter att man pratat med dem några gånger.
**Fungerar.** Det tydligaste exemplet på att *personlig berättelse = mekanisk styrka*. Varje uppdrag är en egen bana med
egen ton, och belöningen syns i slutstriden. **Fallerar.** Engångsinnehåll, dyrt per person; checklistekänsla när alla tio
står i kö.

### Darkest Dungeon 1 och 2 (Red Hook)
**Mekanism.** DD1: **quirks** (halvpermanenta egenheter, bra och dåliga) från expeditioner och tavernan; stress som vid
100 ger antingen en Affliction (ca 75 %) eller en Virtue (25 %), där drabbade hjältar handlar själva. DD2: **affinitet per
par** (0–20) som rör sig av strid, stress, val på vägen och föremål på värdshuset; vid värdshusen bildas relationer, positiva
(t.ex. Amorous: tar en träff för den andra) eller negativa (Tumultuous: står i vägen för den andra).
**Fungerar.** Hjältarna blir *någon* genom ärr och egenheter som spelet gav dem, inte som skrevs i förväg. Par med
stridseffekt gör relationer till taktik. Negativa relationer gör dem mänskliga (passar vår ton: bristfälliga, inte helgon).
**Fallerar.** Negativa relationer känns som straff man inte kunde påverka; mycket slump. DD1:s hjältar är utbytbara, vilket
motverkar fästning – motsatsen till våra namngivna följeslagare.

### Wildermyth (Worldwalker, 2021)
**Mekanism.** Relationer i fem nivåer (vän, rival, älskare; vänner ger blockchans intill varandra, rivaler kan
"stunta" efter varandra) som fördjupas av att slåss och göra saker tillsammans. Hjältar **åldras** mellan kapitel, får
**skador** (förlorad arm ersätts av något som beror på vad de varit med om), och kan föras vidare i ett legacy-förråd.
Allt skrivs som en krönika med serierutor.
**Fungerar.** Det mest relevanta spelet för oss: berättelsen *uppstår* ur vad som hände i striderna, och ärren är
historia man bär. Relationerna kostar lite text eftersom händelserna är korta och kombineras. **Fallerar.** Procedurella
händelser upprepas efter några kampanjer; karaktärerna blir mallar med namn.

### Fire Emblem (supports)
**Mekanism.** Två enheter som slåss intill varandra samlar stödpoäng; vid C, B, A (S) öppnas ett samtal, och varje rang
ger en stridsbonus när de står nära. Samtalen är korta (en sida), skrivna per par.
**Fungerar.** Den renaste kopplingen *göra något ihop → få höra något om dem*. Spelaren väljer sällskap för att låsa upp
samtal. Korta, avgränsade scener är lätta att skriva i omgångar. **Fallerar.** Antalet par exploderar (n² / 2); spelare
"farmar" stöd. Lösningen i senare spel: bara utvalda par har samtal.

### Pyre (Supergiant, 2017)
**Mekanism.** Den som vinner säsongens befrielserit väljer en lagkamrat som blir fri – och försvinner ur spelet för gott.
**Fungerar.** Fästningen mäts av vad man är beredd att förlora: man vill behålla en stark spelare men unnar henne friheten.
**Fallerar.** Ger avsiktligt sämre lag; fungerar bara i ett spel med ett slut.

### Persona 5 (lätt)
**Mekanism.** Confidants i tio rang; tid med personen ger rang, och varje rang ger en konkret förmåga (t.ex. att se fiendens
fynd, rabatter, mer erfarenhet vid fusion). **Lärdom**: varje steg i relationen ger *ett litet verktyg*, inte bara text.

### Siralim Ultimate (Thylacine)
Man kan prata med sina varelser i Menagerie, och varje ras har egna repliker efter sin personlighet (Steam-tråd).
Ingen båge, ingen mekanik – bara färg. Vi har redan motsvarigheten (värdshuset, 0.29.3). Siralim själv bygger alltså inte
relationer; allt nedan är tillägg *utöver* förebilden och bör vägas mot ledstjärnan (kombinera först).

## Mönster

1. **Gör något ihop → få höra något** (Fire Emblem, Wildermyth, DD2). Billigast när utlösaren är en verklig händelse vi
   redan loggar.
2. **Synligt förlopp med ett mål** (Hades hjärtan, Persona rang). Utan mål blir det brus.
3. **Personlig båge som ger mekanisk styrka** (Mass Effect, Hades keepsake). Gör att den som vill optimera också läser.
4. **Minne av specifika händelser** (Hades reaktivitet, Wildermyth krönika). "Du drog upp mig i kapellet" slår allmänna rader.
5. **Brister och friktion** (DD, BG3 ogillande). Men utan straff man inte kan påverka.
6. **Fel som ska undvikas**: gåvor som köper tillgivenhet, siffror utan förklaring, för sällsynt banter, n²-explosion,
   checklistor.

## Förslag för oss (från litet till stort)

Gemensam grund för flera förslag: ett **band** per par (följeslagare–följeslagare och följeslagare–Paladinen), räknat i
`Profile.bonds = {"alva|brokk": {"fights": n, "saves": n, "seen": [...]}}`. Inget visas som siffra (undviker BG3:s
"varför?"); det syns bara som scener och rader. Alla nya rader följer formatet `{id, text}`.

### 1. Den som räddade mig minns det (litet)
När en hjälte helas från under 25 % liv, väcks (`revive`) eller skyddas av en livvakt, sparas *vem* i körningen
(`RunState.saved_by[target] = source`). Vid lägerelden eller hemkomsten säger den räddade en rad *till räddaren*:
"Alva. Det där i kapellets andra våning. Tack. Säg inget till Brokk." Paladinen som räddare får `{namn}`.
- **Data**: `dialog.json` "saved": per följeslagare 3–4 rader till en annan, 2 till Paladinen (generiska med `{hjälte}`,
  några specifika par). Ca 8 × 5 = **40 rader**. Krönikans `rescued` finns redan för fångar; ny nyckel `saved_me`.
- **Kopplingar**: stridens `heal`/`revive`-händelser, `Run.bark` (högst en per rum), `RunState.barks_used`.
- **Risk**: låg. Tröskeln måste vara äkta (inte varje helning) så att raden betyder något.

### 2. Banter vid lägerelden blir ett samtal som går framåt (litet–medel)
Dagens `pairs` är lösa skämt. Låt varje par ha en **kedja** på 3 samtal (`"step": 1–3`) som spelas i ordning, ett per
lägereld där båda är med; nästa kräver att de varit i en strid ihop sedan förra (`bonds.fights`). Tredje samtalet visar
en spricka eller en vänskap (Ragnhild och Solveig grälar om eld och nåd; Brokk erkänner för Imma att han inte kan läsa).
- **Data**: `pairs` får `step` och `chain`-id. Börja med **6 utvalda par** (inte alla 55): imma–alva, imma–brokk,
  ragnhild–solveig, alva–brokk, eira–sefir, tove–brokk. 6 × 3 samtal × 4–6 rader = **ca 90 rader**.
- **Kopplingar**: `Dialog.bark` med "pairs", lägereldsrutan i grottan, `bonds`. Fire Emblems lärdom: bara utvalda par.
- **Risk**: låg. Dragon Ages fel: för sällsynt. Lägg kedjesamtalet *före* lösa skämt när ett finns.

### 3. Värdshuset minns vem du lämnade hemma, och vem du tog med (litet)
Vi har `home_runs` och `welcome`. Lägg till rader när någon följt med många gånger i rad ("fem nedstigningar nu. Mina
knän har slutat klaga, de har gett upp") och en avundsjuk rad från den som alltid står kvar, *utan* straff.
- **Data**: `inn` får `veteran` och `passed_over`; 11 × 2–3 = **ca 30 rader**. `Profile.runs_with[hjälte]`.
- **Risk**: mycket låg. Ger DD:s friktion utan Tumultuous-straffet.

### 4. Minnessaker: en lärdom eller ett föremål från deras förflutna (medel)
Hades keepsakes, men på vårt språk. Varje följeslagare har **en minnessak** som hen ger Paladinen när bandet räcker
(t.ex. efter kedjans tredje samtal med Paladinen eller efter det personliga uppdraget, förslag 7). Den är ett **föremål**
(Immas slangbella från barndomen, Brokks bucklade knäskydd, Alvas salviapåse) eller en **lärdom** ("Som Eira lärde
dig: vänta ett andetag till"), alltså samma regel som troféerna. Den kan bäras i **troféplatsen av en annan hjälte**
eller av Paladinen, och dess effekt är liten men regelformad (Hades-modellen), med `lesson` som rad. Exempel:
*Immas slangbella* – första fienden som förblindas varje strid blir det också nästa tur. Inget som bara ger skada.
- **Data**: 11 nya egenskaper i `traits.json` med `rarity: "keepsake"`, `lesson`, `combo`; `Profile.keepsakes`.
  Text: namn + effekt + lärdom + överlämningsrad, ca **11 × 4 = 45 rader**.
- **Kopplingar**: `worn`/`wear()`, troféplatsen (`Forge.effect_traits`), Biblioteket listar dem, "Det här avgjorde
  striden" visar källan MINNESSAK. Inga nya platser – de konkurrerar med troféer, vilket ger val (ledstjärnan: byter
  spelaren frivilligt?).
- **Risk**: medel. Balans (en till sorts trofé); måste vara regelbrytare, inte siffror. Fråga VD om det avviker för mycket
  från Siralim (där finns inget motsvarande).

### 5. Stridsband: par som slåss ihop får en liten gemensam reaktion (medel)
Fire Emblem och Wildermyths vänskapsnivå, men som **egenskap**. Efter t.ex. 15 gemensamma vunna strider (`bonds.fights`)
och kedjans andra samtal öppnas ett band: när den ena faller anfaller den andra en gång gratis, eller "när Alva helar Brokk
får han Beskyddad". Ett band per hjälte i taget (väljs i Förberedelser), högst ett aktivt per par.
- **Data**: `data/bonds.json` (par, krav, egenskap-id), 6 egenskaper i `traits.json` (scope self, `when` på partnern).
  Text: namn, effekt, upplåsningsrad: **ca 20 rader**.
- **Kopplingar**: egenskapsmotorn (triggers `death`, `heal`), `trait_stats` och segerskärmen (källan BAND), botarna.
- **Risk**: medel. Kan låsa spelaren vid samma sällskap (motverkar att prova kombinationer). Håll effekterna små och
  krav som nås naturligt; DD2 visar att negativa band upplevs som straff – ha inga.

### 6. Ärr och egenheter som berättar (medel)
Wildermyth och DD:s quirks, mjukt. Händelser ger en **egenhet** som syns i hjältebladet med en historikrad och färgar
repliker, men nästan ingen siffra: "Föll mot Den fallne biskopen (djup 2). Står alltid till vänster om Brokk sedan dess."
Den som fallit tre gånger mot samma fiende får en rad när fienden dyker upp igen; den som dödat en boss får ett ärr.
- **Data**: `Profile.scars[hjälte] = [{id, realm, depth, foe}]`, `data/scars.json` (8–12 sorter), repliker per sort och
  några per hjälte: **ca 50 rader**.
- **Kopplingar**: hjältebladets historik (finns), krönikans `fell`/`fell_often`, `Dialog.bark` villkor `has_scar`.
- **Risk**: låg om de är rent berättande; hög om de blir negativa statsar (DD:s fel). Tonen: ärr ska vara värdiga,
  inte groteska.

### 7. Personliga uppdrag i grottan, ett per följeslagare (stort)
Mass Effects lojalitetsuppdrag i vår grotta. När bandet med Paladinen räcker (t.ex. 8 nedstigningar med hen eller en
viss Realm och ett samtal i värdshuset) ersätter **följeslagarens uppdrag** våningens quest en gång: ett föremål, en
person eller en fiende ur hens förflutna som står på en ruta i grottan (`objects.json`-modellen), med 2–4 repliker före
och efter. Exempel: Brokk letar efter hammaren hans bror lämnade i kryptan; Sefir möter en svärdsdansare som lärde henne
(en elitgrupp med eget namn); Ragnhild hittar en kyrkbok i kapellet och tvingas medge att hon dömt fel. Belöningen är
hens **minnessak** (förslag 4) och en ny rad i hjältebladet. Kräver att hen är med.
- **Data**: `data/personal_quests.json` (hjälte, realm, krav, ruta/föremål, möte, repliker, belöning); `RunState.roll_quest`
  får en väg för personligt uppdrag; `Profile.pq_done`. Text: 11 × (samtal 5 + grotta 4 + efter 4) ≈ **ca 145 rader**,
  plus 4–6 nya möten eller föremål.
- **Kopplingar**: grottans quest, föremålen (0.28.2), elitgrupper, krönikan, `Intro`-liknande `talk` i värdshuset.
- **Risk**: hög arbetsmängd; engångsinnehåll. Börja med **två** (Imma och Brokk) och mät om spelare tar med dem för att
  låsa upp uppdraget – det är vårt test.

### 8. Krönikan som bok per hjälte (medel–stort)
Wildermyths krönika: Broder Alrik skriver det viktigaste ur varje hjältes historia (räddningar, ärr, band, uppdrag,
bossar) i en bok man kan bläddra i, med de repliker som sades. Vi har redan händelserna och `chronicle`; det som saknas är
att *spara* dem per hjälte.
- **Data**: `Profile.chronicle_log[hjälte] = [{kind, realm, depth, line_id}]` (begränsad längd); `handbook_screen`-liknande
  skärm. Nästan ingen ny text: **ca 20 mallrader** ("{hjälte} drog {annan} ur dödens hand i {plats}").
- **Kopplingar**: krönikan, hjältebladets historik, Alriks bibliotek.
- **Risk**: låg i text, medel i UI-arbete. Värdet växer med 1, 6 och 7.

### Avvägda och avfärdade
- **Gåvor som köper tillgivenhet** (Origins, Hades nektar): nej. Passar inte en paladin och blir checklista. Om något: ge
  följeslagare *föremål ur grottan* som de reagerar på med en rad, utan siffra.
- **Godkännande som reagerar på val** (BG3): vi har nästan inga dialogval. Möjligt senare via Löften (Jag helar inte ger
  Alva en rad), men ingen mätare.
- **Negativa relationer med stridsstraff** (DD2): nej, men friktion i text (förslag 2, 3) ja.
- **Befrielse/avsked** (Pyre): stark idé för ett slut. Kan bli berättelsens sista akt (en följeslagare stannar för att
  hålla en Realm), inte ett system nu.
- **Romans**: inte nu. Tonen är allvarlig och varm; vänskap, skuld och lojalitet räcker länge.

## Rekommenderad ordning

1 → 2 → 3 (en vecka text, nästan ingen kod, mäter om spelare märker dem) → 4 + 7 för Imma och Brokk som prov →
utvärdera med ledstjärnans fråga (tar spelaren med någon *för att* få höra mer, och byter hen minnessak mot trofé?)
→ 5, 6, 8 om provet håller. Totalt för allt: ca 450 nya rader; för steg 1–3: ca 160.

Repliker skrivs med fasta id:n (`brokk_saved_alva_1`), `{namn}` ibland, Ragnhilds bibelord bara ur 1917 och kontrollerade.
Ingen följeslagare blir ett helgon: varje kedja bör innehålla något hen skäms över eller har fel om.

## Källor

- Hades nektar och keepsakes: https://hades.wiki.fextralife.com/Nectar , https://breezewiki.discard.no/hades/wiki/Nectar
- Hades manus och reaktivitet: https://gdcvault.com/play/1026975/Breathing-Life-into-Greek-Myth ,
  https://geekdad.com/2019/10/narrative-and-early-access-supergiants-greg-kasavin-discusses-hades-development/ ,
  https://gamespot.com/articles/hades-writer-explains-script-philosophy-after-player-discovers-incredible-detail/1100-6482650/
- Hades II keepsakes och nektar: https://gamespot.com/gallery/hades-2-keepsakes-unlock-guide/2900-5377/ ,
  https://gamesradar.com/games/hades/hades-2-nectar
- Baldur's Gate 3: https://baldursgate3.wiki.fextralife.com/Companion+Approval , https://baldursgate3.wiki.fextralife.com/Camp
- Dragon Age: https://www.thegamer.com/dragon-age-origins-companion-approval-guide/ ,
  https://gameinformer.com/games/dragon_age_inquisition/b/pc/archive/2014/07/10/bioware-takes-on-a-slew-of-questions-in-dragon-age-inquisition-q-and-a ,
  https://www.pushsquare.com/news/2015/02/dragon_age_inquisitions_ps4_and_ps3_patch_means_more_party_banter
- Mass Effect 2: https://en.wikipedia.org/wiki/Suicide_Mission_(Mass_Effect_2) , https://gamesradar.com/mass-effect-2-loyalty-guide
- Darkest Dungeon: https://darkestdungeon.wiki.gg/wiki/Quirks , https://darkestdungeon.wiki.gg/wiki/Town ,
  https://darkestdungeon.wiki.gg/wiki/Relationships , https://gamespot.com/articles/darkest-dungeon-2-affinity-how-does-affinity-work/1100-6510587/
- Wildermyth: https://wildermyth.com/wiki/Relationship , https://rpgamer.com/review/wildermyth-review/ ,
  https://www.pcgamer.com/best-rpg-2021-wildermyth/
- Fire Emblem: https://strategywiki.org/wiki/Fire_Emblem_Awakening/Supports
- Pyre: https://rpgsite.net/review/5853-pyre-review , https://superjumpmagazine.com/in-defense-of-pyre-supergiants-underappreciated-middle-child
- Persona 5: https://www.rpgsite.net/feature/5479-persona-5-royal-confidant-guide-conversation-choices-answers-romance-options-gifts-skill-unlocks
- Siralim Ultimate: https://steamcommunity.com/app/1289810/discussions/0/4164113537231972561
