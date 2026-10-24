# Variation i strid utan rum (research, 2026-10-24)

Underlag till `docs/plan/varslade-attacker.md`: hur andra turordningsspel gör strider olika utan ett golv att flytta sig på,
och vad som fungerar på en telefon när makrona spelar. Inget är beslutat.

Märkning:
- **SÄKERT** = wiki eller utvecklaren
- **TROLIGT** = guider, recensioner eller flera spelare
- **MINNE** = allmänt känt om spelet men inte kontrollerat i dag
- **GISSNING** = min bedömning

Källorna står vid varje spel. Siralim-delen bygger på `siralim.md` §21.

## Kort

Spelen gör striderna olika på fem sätt:

1. **Fienden säger vad den ska göra** (Slay the Spire, Into the Breach).
2. **En mätare som spelaren fyller för att bryta fienden** (FFXIII:s stagger, Octopaths sköldar, Honkai: Star Rails toughness).
3. **Tiden som position** (FFX:s turordning, Darkest Dungeons stun och daze).
4. **Fiendens egenskaper straffar en viss strategi** (Siralim, Slay the Spires bossar).
5. **Spelaren byter hela uppsättningen order i stället för att styra varje drag** (FFXIII:s paradigm, FFXII:s gambits).

Planen har redan 1–4. Det som saknas är **5**: makron räcker inte till allt, och spelaren behöver ett enda tryck för att byta
plan mitt i striden.

## 1. Slay the Spire

**Vad som gör striderna olika:**
- **Avsikten** syns ovanför varje fiende med ikon och siffra: anfall med skada, försvar, buff, debuff eller okänt.
  SÄKERT ([wiki: Module:Enemies/data](https://slaythespire.wiki.gg/wiki/Module:Enemies/data),
  [Guardian](https://slaythespire.wiki.gg/wiki/Guardian)).
- Bossarna har var sin regel som straffar ett visst spelsätt. MINNE:
  - The Guardian byter till försvarsläge när den har tagit en viss mängd skada (en tröskel som spelaren fyller, alltså ett
    stagger), och laddar sedan sitt stora slag.
  - Time Eater avbryter turen efter ett visst antal spelade kort (straffar den som spelar många små kort).
  - Awakened One straffar den som spelar Powers.
  - Hexaghost har ett stort slag vars skada beror på spelarens liv.
- Pussel med flera fiender: tre Darklings återuppstår om de inte dör samtidigt (`siralim.md` §21.4).

**På mobil med makron:** avsikten är det som gör Slay the Spire spelbart på telefon: man ser hotet och svarar på det.
Spelet har ingen automatik, men avsikter går bra att skriva som makrovillkor ("om fienden anfaller för mer än X → Försvara").

**Låna:**
- Guardians tröskel: läget byts när spelaren har gjort X skada. Det är planens "Skaka loss" (§1.3), fast **synlig som en
  siffra** som räknas ned.
- Time Eaters räknare som straffar mängd: vi har redan Stenhjärta, som straffar upprepning.

**Undvik:** att varje boss har en helt ny regel att lära sig utan förvarning. Slay the Spire klarar det därför att en strid
tar 3 minuter och nästa försök ger kunskapen gratis. Våra bosstrider är längre, så regeln ska stå på elitkortet och i Inspect.

## 2. Darkest Dungeon 1 och 2

**Vad som gör striderna olika:**
- **Position 1–4:** varje färdighet kan bara användas från vissa platser och träffa vissa platser, och fienderna flyttar
  hjältarna. Hos oss finns ingen motsvarighet utan rum. MINNE för DD1, SÄKERT att positionen är kvar i DD2 (designchefen Tyler
  Sigman: "part of the game's identity", via [darkestdungeon.wiki.gg/PC Gamer-intervjun](https://darkestdungeon.wiki.gg/wiki/Combat_Mechanics_(Darkest_Dungeon_II))).
- **Stun och daze i DD2:** stun tar målets nästa tur. Daze skjuter turen till slutet av rundan. Båda har ett eget
  motstånd. SÄKERT ([Combat Mechanics (DD2)](https://darkestdungeon.wiki.gg/wiki/Combat_Mechanics_(Darkest_Dungeon_II)),
  [Tokens](https://darkestdungeon.wiki.gg/wiki/Tokens)).
- **Tokens:** buffar och debuffar syns som brickor under livmätaren och försvinner när de förbrukas eller efter ungefär tre
  turer. SÄKERT, samma.
- **Bossar:**
  - Profetens *Rubble of Ruin* märker **platser**, inte hjältar. Den som står där tar skadan. TROLIGT
    ([TheGamer](https://www.thegamer.com/darkest-dungeon-fulminating-prophet-boss-battle-guide/)).
  - Kyrkbänkarna skyddar honom tills man slår sönder dem: ett prioritetspussel.
  - Ravenous Reach (DD2) samlar positiva tokens och har tre faser
    ([wiki](https://darkestdungeon.wiki.gg/wiki/Ravenous_Reach)).
  - DD1:s *Swine Prince* och Wilbur: slår man Wilbur får man ett motanfall, och dör han blir bossen rasande (`siralim.md` §21.4).
- **Att dra ut på strider straffas** (stress och förstärkningar), men inte i bosstrider. SÄKERT
  ([Stalling](https://darkestdungeon.wiki.gg/wiki/Stalling)).

**På mobil med makron:** Darkest Dungeon finns på iPad och Switch men saknar automatik. Daze (skjut till slutet) är exakt
vår `to_bottom` och går att skriva som makrovillkor. Positionen går inte att översätta.

**Låna:**
- **Motstånd efter stun:** den som har blivit avbruten är svårare att avbryta igen. Det hindrar att makron låser en boss.
- Profetens *märkta platser*: översatt till tid blir det planens Svallvåg (§4), alltså "det slår mot dem som inte har agerat".
- Tokens som ikoner under livmätaren har vi redan (`status_icons.gd`).

**Undvik:** att lägga till positionen. Den kräver rum och fler knappar, och tidslinjen gör samma jobb.

## 3. Final Fantasy X (CTB)

**Vad som gör striderna olika:**
- Turordningen syns hela tiden (*Act List*), och **handlingen avgör när man får nästa tur**: ett föremål ger en tur
  snabbare än en tung Overdrive, och Haste och Slow ändrar avståndet. SÄKERT
  ([Giant Bomb: Conditional Turn-Based Battle](https://giantbomb.com/wiki/Concepts/Conditional_Turn_Based_Battle),
  [GamerGuides](https://www.gamerguides.com/final-fantasy-x-hd/guide/introduction/gameplay/battle-system)).
- Man planerar runt bossens stora slag genom att titta i turordningen
  ([Jegged: CTB Window](https://jegged.com/Games/Final-Fantasy-X/Tips-and-Tricks/CTB-Window.html)).
- Delay Attack och Delay Buster skjuter fienden bakåt i kön. MINNE.
- Stödfiender låser upp bossens värre anfall, som Crawler och Negator (`siralim.md` §21.4).

**På mobil med makron:** turordningen är vår tidslinje. FFX visar *förhandsvisningen*: när man väljer en handling ser man
var man hamnar i kön. Det fungerar även när makrot väljer, så länge spökbrickan syns.

**Låna:**
- **Spökbrickan** (redan i planen, §1.1). FFX visar att det räcker som "pelare": man ser när slaget kommer och vem som
  hinner före.
- Att en tung handling kostar tid (tyngre handling = senare nästa tur) passar Siralim dåligt, eftersom alla handlingar
  flyttar en till slutet. Låna inte.

**Undvik:** fördröjning som enda svar. Hos oss flyttas bossar bara ett steg nedåt (`to_bottom`), med rätta, eftersom
fördröjning i serie annars blir ett lås.

## 4. Final Fantasy XIII (stagger och paradigm)

**Vad som gör striderna olika:**
- **Kedjemätaren:** varje fiende har en mätare som fylls av träffar. När den når fiendens stagger-punkt vacklar fienden.
  Den tar då mer skada, och de flesta kan inte använda vissa anfall. Fysiska anfall fyller lite men håller kvar, magi fyller
  mycket men töms fort. SÄKERT ([Jegged: Chains and Staggering](https://jegged.com/Games/Final-Fantasy-XIII/Tips-and-Tricks/Basic/Chains-and-Staggering.html),
  [GamerGuides](https://www.gamerguides.com/final-fantasy-xiii/introduction/tutorials/attack-chain)).
- **Paradigmerna:** spelaren styr bara ledaren. Följeslagarna har roller (Commando, Ravager, Sentinel, Medic, Synergist,
  Saboteur) och sköts av AI:n. I striden byter man hela lagets roller med ett tryck, en *Paradigm Shift*. Bossarna tvingar
  fram skiften: försvar inför det stora slaget, anfall när de vacklar. MINNE.

**På mobil med makron:** FFXIII ligger närmast oss. AI:n spelar, och spelarens skicklighet är *när man byter plan*, inte
varje drag. Det är vad en telefon klarar: ett tryck vid rätt tillfälle, inte tio.

**Låna:**
- **Mätaren som syns:** stagger-tröskeln i planen (§1.3, 15 % av max-liv) ska synas som en mätare som fylls på fiendens
  avsikt, inte som en dold procent.
- **Ett byte av makron med ett tryck:** två eller tre sparade makron per hjälte ("Normal", "Skydd", "Bränn"), och en knapp i
  striden som byter alla. Makrona tar hand om dragen, och spelaren väljer läget när bossen laddar. ⚙M (VAL).

**Undvik:**
- **Mätare som töms med tiden.** Vi har inga sekunder, bara turer. En mätare som töms gör stagger till en fråga om
  reaktionstid.
- För många roller. Våra makron är redan rollerna.

## 5. Octopath Traveler (sköldar och break)

**Vad som gör striderna olika:**
- **Sköldar och svagheter:** varje fiende har ett antal sköldpunkter och dolda svagheter, som visas efter att man har träffat
  dem.
- **Break:** slår man fienden med en svaghet tillräckligt många gånger bryts den. Den tappar då sin nästa tur och tar mer
  skada. Medan skölden är uppe tar den mindre skada. När den vaknar agerar den **före** spelaren, så att den inte går att låsa.
  SÄKERT/TROLIGT ([Wikipedia](https://en.wikipedia.org/wiki/Octopath_Traveler),
  [GamerGuides](https://www.gamerguides.com/octopath-traveler/guide/the-basics/game-mechanics/battle-system)).
- **Bossar byter svagheter efter varje break** (Miguel), växlar mellan låsta och öppna (Bandelam), döljer sköldarna
  (Pelagia) eller får färre sköldar efter några break (Oskha). TROLIGT
  ([fandom: Miguel](https://octopathtraveler.fandom.com/wiki/Miguel_(Battle))).

**På mobil med makron:** Octopath finns på mobil (*Champions of the Continent*) med automatisk strid (MINNE, inte
kontrollerat i dag). Sköldtalet är en siffra som makron kan läsa: "om fiendens sköld ≤ 2 → anfall med svagheten".

**Låna:**
- **Break-belöningen:** fienden tappar turen och tar mer skada. Det är planens Vacklande; Octopath visar att belöningen ska
  kännas, och +25 % är försiktigt.
- **Vakna först:** den som har varit bruten agerar direkt efter, och går inte att bryta igen förrän den har agerat. Samma
  skydd mot lås som Darkest Dungeons stun-motstånd.
- **Bossen byter svaret efter ett break:** första laddningen bryts av Tystad, den andra av stagger. Då räcker inte en enda
  makrorad. Det är Siralims anda: egenskapen tvingar fram ett andra svar.

**Undvik:** dolda svagheter som man måste prova sig fram till. På telefonen, med makron som spelar, blir det gissningar.
Inspect ska alltid visa svaret.

## 6. Into the Breach

**Vad som gör striderna olika:**
- **Varje fiendes anfall visas i förväg**, med pilar till rutorna som tar skadan, och spelaren söker det perfekta svaret
  varje tur. SÄKERT (Subsets egen text: "All enemy attacks are telegraphed …",
  [PC Gamer](https://www.pcgamer.com/au/ftl-devs-announce-into-the-breach-a-turn-based-game-with-echoes-of-pacific-rim),
  [Game Developer](https://gamedeveloper.com/game-platforms/road-to-the-igf-subset-games-i-into-the-breach-i-)).
- Svaret är oftast att **flytta** fienden eller målet, inte att döda: anfallet slår då fel eller träffar en annan fiende.
- Deterministiskt, utan träffchans: det man ser händer (`siralim.md` §21.5).

**På mobil med makron:** Into the Breach finns på mobil (MINNE, Netflix-utgåvan) och fungerar för att allt syns. Det är
ett pussel som makron inte löser. Makron kan läsa "målet för laddningen" och ge skydd, men inte flytta saker.

**Låna:**
- **Flytta målet i stället för att stoppa slaget:** en enkelmålsladdning som följer hån (planens regel 2 i §2) är exakt
  detta. Tanken provocerar och laddningen byter mål. Gör det synligt: målmarkeringen hoppar till tanken.
- **Ingen slump i det varslade:** en laddning ska slå exakt så hårt som avsikten säger. Planens Förstenad 40 % på Bergets
  vrede bör stå i Inspect som en chans.

**Undvik:** att varje drag blir ett pussel. Då slutar makrona att fungera, och telefonen blir ett schackbräde.

## 7. Siralim Ultimate (förebilden)

**Vad som gör striderna olika** (`siralim.md` §21.2–21.3, TROLIGT för 2.0; Steam-trådar
[Gate of the Gods](https://steamcommunity.com/app/1289810/discussions/0/3875969300102855713)):
- Inga avsikter och inga laddningar. Variationen ligger helt i **fiendernas egenskaper**, som var och en straffar en
  strategi. Några exempel:
  - reflektion (Sparktail Officer)
  - −35 % Intelligence efter varje kast (Dragon Revenant)
  - skada när någon undviker (Dragon Soldier)
  - livvakt (Sandstone Imler)
  - +15 % stats per tur, en klocka (Aaxer Apocalypse)
  - ledaren är immun så länge de allierade lever (Champion)
- Möten som tvingar fram ett nytt bygge:
  - Gonfurian: inga kast, och bossen kan bara skadas med minst 5 debuffar.
  - Aeolian: immun mot indirekt skada, och bara en klass i taget kan skada den.
  - *The Ancestor*: dödar de varelser som inte Försvarar.
  - Gate of the Gods: gudarna har regler i striden, till exempel att de bara går att skada efter tillräckligt många debuffar.
- Zantai har tre slumpade bossegenskaper.
- Spelarna svarar med **ett nytt bygge eller nya makron**, inte med drag i stunden.

**På mobil med makron:** det här är vår modell, och den fungerar för att svaret görs *före* striden, i lägret och vid
trofébytet. Det kräver att egenskapen syns innan man går in (vårt elitkort).

**Låna:**
- *The Ancestor* ("Försvara eller dö") är en ren varslad attack i Siralims form, utan ny mekanik. Den går att göra redan i
  dag med en egenskap.
- Gonfurian (skadas bara med minst X debuffar) är ett lås som inte är ett stagger. Det passar en elitfiende i kapellet.

**Undvik:** Siralims lösning att man bygger om laget helt för en enda boss. Vi har fyra hjältar och få troféer; svaret ska
få plats i en makrorad eller ett trofébyte.

## 8. Två till

### Honkai: Star Rail (mobil, automatisk strid)
- **Toughness:** en vit mätare över livet som bara skador av fiendens svaghetstyper sänker. När den bryts får fienden en
  bruten-skada, skjuts 25 % bakåt i turordningen och kan få en debuff efter elementet. Den återställs vid fiendens nästa tur.
  Flera lager: först det sista lagret ger fördröjningen. SÄKERT
  ([fandom: Toughness](https://honkai-star-rail.fandom.com/wiki/Toughness),
  [Icy Veins](https://www.icy-veins.com/honkai-star-rail/combat-basics)).
- **På mobil:** ett av de största mobila turordningsspelen, och det har automatisk strid. Mätaren ovanför livet är det som gör
  striderna olika även när automatiken spelar: fiendens svaghet avgör vem man tar med. GISSNING: spelare kör vanliga strider
  på automatik och bossar för hand. Ingen källa i dag.
- **Låna:** **mätaren i lager** för bossar: varje lager som bryts ger skada, och bara det sista ger Vacklande. Det passar
  en boss med två faser.

### Final Fantasy XII (gambits)
- Gambits är makron: villkor och handling uppifrån och ned, upp till 12 per figur. Ordningen styr. SÄKERT
  ([StrategyWiki: Gambits](https://strategywiki.org/wiki/Final_Fantasy_XII/Gambits)).
- I *The Zodiac Age* gör spelarna **egna listor för bossar**, och många byter eller stänger av gambits i bosstrider. TROLIGT
  ([Twinfinite](https://twinfinite.net/2019/05/final-fantasy-xii-is-basically-menu-ing-the-game-and-i-love-it/),
  [Steam](https://steamcommunity.com/app/595520/discussions/0/1700541698692933426)).
- **Lärdomen:** ett makrospel behöver ett snabbt sätt att byta lista, annars stänger spelaren av automatiken i bosstriden, och
  då är makrona inte längre kärnan. Samma slutsats som FFXIII:s paradigm.

## 9. Topp 5 att låna till planen

1. **Byt makro med ett tryck (FFXIII:s paradigm, FFXII:s boss-listor).** Varje hjälte har upp till tre sparade makron, och
   en knapp i striden byter alla till "Skydd" eller "Bränn". Laddningen blir ett beslut i rätt ögonblick, och makrona gör
   resten. Det är vad telefonen klarar. ⚙M, VAL. Planen saknar det i dag: där måste allt stå i ett enda makro.
2. **Stagger som en synlig mätare (FFXIII, Octopaths sköldar, Star Rails toughness, Guardian i Slay the Spire).**
   Planens 15 % av max-liv visas som en mätare som fylls på avsiktsringen, med siffran kvar. Mätaren töms bara när laddningen
   tar slut, aldrig med tiden. Makrovillkoret blir "laddar och mätaren ≥ 50 %" för den som ska bränna. ⚙S.
3. **Skydd mot lås efter ett avbrott (Darkest Dungeons stun-motstånd, Octopaths "vaknar först").** En bruten fiende kan inte
   börja ladda och brytas igen förrän efter sin nästa tur, och dess nästa laddning bryts inte av samma svar en gång till.
   Utan det kan en makrorad låsa en boss för alltid. ⚙S.
4. **Bossen byter svaret efter ett avbrott (Octopaths Miguel och Bandelam).** Benfurstens första Dödsdom bryts av Tystad, den
   andra bara av stagger. Det tvingar fram två rader och gör den andra laddningen spännande. Det håller sig till Siralims
   anda (en egenskap som kräver ett svar) och kostar nästan ingen kod utöver `broken_by` per laddning. ⚙S.
5. **Varslade platser i tiden (Profetens märkta platser, Into the Breachs pilar).** Svallvågen (§4) med spökbrickan: slaget
   träffar dem som står mellan laddningen och släppet på tidslinjen. Det är det närmaste "gå ur elden" vi kan komma utan rum,
   och det går att läsa och skriva som makrovillkor ("jag står före släppet → Försvara"). Ta det först med Bergakungen, inte
   i steg 1. ⚙M.

**Avråder:**
- mätare som töms med tiden
- dolda svagheter man måste gissa
- positioner 1–4
- pussel som bara går att lösa för hand

Allt som makrona inte kan läsa gör att spelaren stänger av automatiken, och då har vi tappat det som gör spelet till
Siralim.

## 10. Frågor till VD

1. **Makrolägen:** ska varje hjälte kunna ha 2–3 sparade makron med en knapp i striden som byter alla (topp 1)? Det är det
   största tillägget och påverkar makroskärmen.
2. **Stagger-mätaren:** synlig som en mätare (förslaget), eller bara som text i Inspect?
3. **Byter bossen svaret efter ett avbrott** redan i steg 1 med Benfursten, eller först när spelaren har lärt sig laddningen?
