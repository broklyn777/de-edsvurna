# Den levande kartan – plan för ett första test (skriven 2026-10-22; första testet byggt 2026-10-23, se Resultat)

Ursprung: tråd 3 (`docs/ideer/trad3-losa-ideer.md`) och ChatGPT:s research L (`docs/ideer/chat-familjer-karta-grottan.md`).
**Avvikelse från Siralim:** Siralim har ingen värld som förändras mellan körningarna. Vi provar det för att samlandet
och djupen ska få en berättelse – men bara som ett litet test först.

## Frågan testet ska svara på
Känns världen levande, eller känns kartan som en syssla? Inget annat. Blir svaret nej har vi bara lagt några dagar.

## Testet: två Realms, inga nya familjer
- Varje Realm (Kryptan: Benfolket; Kapellet: Kultens folk och De fallna) får `growth` 0–4 i profilen. Start: 1 och 1.
- **Efter varje nedstigning med minst en vunnen strid** (aldrig i verklig tid): den Realm man gick till sjunker 2 steg
  (lägst 0) om dess quest klarades, annars 1; den andra växer 1 steg. En Realm på 0 vilar en nedstigning.
- **Styrkan i strid:** fienderna som en mildare instabilitet (förslag +6 % stats per steg) och bättre fynd och
  troféchans per steg. Mäts med botarna innan något bestäms.
- **Steg 4:** en förvriden boss (t.ex. "Den svärtade Benfursten") med en egen trofé visar sig. Realmen står still på 4
  tills man går dit; ingen spridning vidare i testet. Varning på steg 3: "Nästa gång kan något vakna där nere."
- **Visas utan siffror:** fördärvet över området blir tätare, svarta märken och fler eldar; en rad före avfärd
  ("Går ni till kapellet får Benfolket i kryptan andas ut") och efter hemkomsten samma orsak och vad som ändrades.
  Imma eller Gorm säger något när ett steg ändras, högst en replik.
- Inga permanenta förluster: byar och tjänster försvinner aldrig.

## Känd begränsning
Med två Realms blir det en pendel: slår man den ena växer den andra. Cirkeln (troll → skelett → spindlar → troll)
kräver en tredje familj. Testet visar känslan, inte hela idén.

## Ordning
1. VD provspelar 0.30.x.
2. Testet ovan (profilfält, kampanjkartans bild, styrkan i `battle_opts`, en förvriden boss, botar).
3. Om det känns rätt: spindlarna som tredje familj (research K), sedan trollen.

## Resultat: första testet (2026-10-23, grenen `levande-karta`, skuren från test-0.30)

Byggt: `src/game/living_map.gd` (`LivingMap`), fälten `Profile.growth`, `growth_rest`, `growth_last`, `growth_news` (gamla
sparfiler får startvärdet 1), `RunState.growth`, `twisted`, `wins`, `realm_quest_done`, `Run.end_descent()` (förlust, ge
upp, gå hem och klarad körning; inte första nedstigningen eller Övningsgården), kampanjkartans bild och texter, den
förvridna bossen i kryptan och botarna. Tester: `tests/test_living_map.gd`.

### Egna val
- **Upplåst = besökt.** En Realm växer först när man har gått ned där en gång. Annars skulle en ny spelare möta ett kapell
  på steg 4 första gången.
- **Med tre Realms växer bara den som legat orörd längst** (`growth_last`). Planens regel (alla andra växer) mättes först:
  karriärbotarna (som växlar Realm varje gång men ofta förlorar, och då sjunker Realmen bara 1) drev upp kryptan till
  3,7 i snitt efter 18 nedstigningar och mötte den förvridna bossen 2,4 gånger per profil. Med "äldst växer" ligger
  kartan på 0–2 när man växlar (0,15 förvridna bossar per profil), och den man undviker når 4 (se KARRIAR_REALM=lagst).
  Med två Realms är reglerna desamma som i planen.
- **Steg 0 och 1 är dagens strider.** Inget blir lättare än balansen; steg 0 är bara vila och ett tunnare bläck.
- **Styrkan: +2 % stats per steg från steg 2** (×1,02 / ×1,04), och **steg 4 = steg 3** i stats: där är det den förvridna
  bossen som är hotet. Planens +6 % var alldeles för mycket: kryptans körningar föll från 35 % till 12/5/0 % (steg 2/3/4).
- **Bytet från steg 2:** troféchans +5 procentenheter per steg, bärnstenschans +10 procentenheter per steg och +1 bärnsten
  från steg 3, trick och Nether Stones +25 % per steg (`Forge.roll_finds` `growth`).
- **Vila:** en Realm som når 0 växer inte nästa nedstigning; vilar den, växer den näst äldsta.
- **Den svärtade Benfursten** (`bone_lich_black`, mötet `crypt_twisted`): Benfurstens regler, Resistent, Odödlig vrede och
  Svart märg (Barriär 8 % av max liv när någon i hans följe faller), stats 190/12/12/2/9 (Benfursten 180/11,8/11,8/2/9).
  Sotsvart kåpa, järnkrona, röda ögon och rött sken. Hans trofé **Den krossade svarta kronan** (boss): när någon i sällskapet faller
  sveper bäraren fienderna med Benstorm, men bärarens helningar är 25 % svagare. Ges direkt vid första segern (inte efter tre
  som Siralims Masters), eftersom han bara visar sig på steg 4. Kapellet och Lunden har ingen förvriden boss än; där är
  steg 4 bara steg 3 som står still.
- **Texterna:** raden före avfärd i panelen ("Går ni hit trängs Benfolket tillbaka. Under tiden växer fördärvet i
  kapellet." och på steg 3 "Nästa gång kan något vakna i kryptan.") och rutan "Medan ni var borta" efter hemkomsten, en rad
  per Realm som ändrades, med högst en replik (Imma om hon finns, annars Gorm) för den viktigaste ändringen
  (`dialog.json` "living_map", repliker med id). Rutan visas en gång och försvinner vid nästa nedstigning.
- **Bilden:** vinjettens bläck når längre in och blir mörkare per steg (shaderns `growth`), svarta stänk spiller över ramen
  ut på pergamentet och fiendens eldar fladdrar i området från steg 2; på steg 4 med en förvriden boss ett rött dödskallesigill.

### Botsiffror
`BALANS=levande` (djup 1, väntad nivå 3, fyra hjältar med startmakron, 100 hela grottkörningar per ruta, MACRO/TUNED):

| | steg 1 (= 0) | steg 2 | steg 3 | steg 4 |
|---|---|---|---|---|
| Kryptan | 35/52 % | 28/45 % | 21/31 % | 13/14 % (förvriden boss) |
| Kapellet | 48/45 % | 29/37 % | 30/32 % | 30/32 % |
| Lunden | 48/65 % | 34/62 % | 30/54 % | 30/54 % |

Bossmötet ensamt med fulla Charges (nivå 5): Benfursten 100 %, Den svärtade Benfursten 98 % på steg 4. Han fäller körningar
genom nötningen, inte i en ren strid. Prövat och förkastat: +6 % per steg (kryptan 12/5/0 %), +3,5 % (22/15/0 %), och en
första förvriden boss med 216 i liv och 13 i Attack (kryptan steg 4: 3/13 %).

`SOAK=karriar` (40 profiler × 18 nedstigningar, Realm i tur, botarnas hemmaval som förut):
- Kurvan med kartan på och av är densamma inom bruset (vinst per nedstigning 25–63 % på, 23–63 % av; djupet efter 18
  nedstigningar 6,0 i båda). Vinst per steg i den Realm man gick till: steg 0 48 %, steg 1 46 %, steg 2 44 %, steg 3 34 %,
  steg 4 25 % (8 nedstigningar). Kartan i snitt (krypta/kapell/lund) ligger på 0–2,9 per Realm, oftast under 2, och kryptan går i en sågtand eftersom den besöks var tredje gång.
- `KARRIAR_REALM=lagst` (går alltid till den lugnaste): kryptan står på 4 från nedstigning 5 och lunden når 3,6; boten
  slipar kapellet på steg 0. Ingen förvriden boss möts, eftersom boten aldrig går dit.
- Inga nya soak-fel. Kontrollfelen "har inte fått agera på 17–25 turer (frozen)" i crypt_3 finns lika ofta med kartan av
  (Benstormens frysning hos Benfursten); ett av dem kom i crypt_twisted, som har samma Benstorm.

### Öppna frågor till VD
1. Känns kartan levande eller som en syssla? (Testets enda fråga.)
2. När man växlar ligger världen mest lugnt (0–2), och den förvridna bossen kommer bara om man undviker en Realm i tre
   nedstigningar. Ska den komma oftare (t.ex. att två Realms växer när man förlorar)?
3. Steg 4 i kryptan halverar ungefär vinsten för botarna. Är det rätt pris för en egen bosstrofé, eller ska han vara mildare?
4. Ska kapellet och Lunden få egna förvridna bossar (förslag: Den svärtade biskopen, Vävmoderns förvridna drottning)?
5. Bytet syns inte i siffror för spelaren (planens "utan siffror"). Räcker det att Imma säger att det är farligare och
   rikare, eller behövs en ledtråd om bättre fynd?

## Levande värld (2026-10-24, grenen `levande-varld`, skuren från test-0.30)

VD (2026-10-23): kommentarer som är levande. När spelaren kommer hem ska hen få bekräftat vad hen har gjort, personerna
ska hålla koll på vad som verkligen händer, och det ska hända större saker som spelaren kan påverka. "Att det betyder
något är ett måste." Viktigt för den som spelar ensam. Tillägg: någon möter en vid porten och berättar (samtalet är
huvudsaken, listan en sammanfattning), och hemkomsten svarar även efter en förlust: tröst, vad det ledde till, vad man kan göra.

Kartan (`LivingMap`) är motorn. Byggt: `src/game/world_events.gd` (`WorldEvents`, ren logik), `data/world_events.json`,
`Profile.world` (ett lexikon; gamla profiler läses som {}), `RunState.world_heal_mod`, `world_boss_mult`, `world_stat_mult`,
krönikans nya händelser och repliker (`dialog.json` "chronicle" och "world"), hemkomsten i borgen (`base_screen`).

### 1. Bekräftelser med detaljer
- Kartans ändringar är egna händelser i krönikan: `map_down` (Realmen man gick till trycktes tillbaka; repliker per Realm
  och steg, `min_streak` för "två gånger i rad i lunden"), `map_up` (växte medan man var borta), `map_wake`,
  `map_calm_twisted`. Tor talar om kryptan, Hedda om lunden (järnet), Mor Elin om kapellet (pilgrimerna), Sven om vägarna,
  Broder Alrik om det som skrivs in, följeslagarna om de var med.
- Sammanfattningen per Realm är varierad (`living_map.summary`, per Realm: down, quest, zero, up, warn) i stället för
  "andas ut, fördärvet växer där".
- Ingen replik upprepas förrän de andra med samma villkor har sagts (`chron_said`, samma mekanik som krönikan).
- 86 nya repliker med fasta id:n: 72 i hemkomsten och 14 som borgens folk säger medan något pågår. `{namn}` i ungefär var
  tredje. Ragnhild citerar Ps. 119:105 och Rom. 12:13 ur listan.

### 2. Följder i borgen
| Realm på steg 3+ | Följd (så länge den står där) | Syns | Tryckt tillbaka till 0–1 (en gång) |
|---|---|---|---|
| Lunden | nät över handelsvägen: smedjans nivåer +15 % | priset och Heddas rad vid knappen, hennes replik, kampanjkartan | en handelsman på gården: 5 bärnsten (60 silver) och ett trick (80), en av varje; han stannar tills nästa nedstigning börjar |
| Kryptan | arbetarna vägrar gå ned: ingen bärnsten från Tor (annars 1 per hemkomst) | Tor och arbetarna på gården, kampanjkartan | arbetarna hittar 3 bärnsten och 30 silver |
| Kapellet | inga pilgrimer, Mor Elin har ont om förband: helningsförmågorna −1 Charge nästa körning | Mor Elins replik, kampanjkartan | en pilgrim i värdshuset med ett rykte: i nästa körning (vilken Realm som helst) syns den första våningens questmål från start |

Allt vänds av sig självt när Realmen trycks tillbaka. Gåvan laddas när Realmen står på 2+ (`armed`), så att den kommer
efter ett verkligt arbete och bara en gång per gång.

### 3. Händelser med tidsgräns
Tidigast efter 4 nedstigningar, sedan 3–5 mellan starterna, aldrig två samtidigt. Den som har legat längst sedan sist väljs,
bland dem vars Realms man har besökt.

| Händelse | Realm | Tid | Lyckas | Belöning | Annars |
|---|---|---|---|---|---|
| Kulten samlas till högtid | kapellet | 2 | fäll biskopen | 60 silver, titeln Den som bröt högtiden | mässan hålls: +1 steg, biskopen ×1,12 nästa körning dit |
| Spindlarna har tagit en karavan | lunden | 2 | klara questen | 40 silver, en tacksam handelsman (halva priset) | smedjan +10 % i tre nedstigningar |
| Gravklockan ringer av sig själv | kryptan | 2 | vinn 4 strider där | en Nether Stone | +1 steg, alla grupper ×1,06 nästa körning dit |
| En pilgrimsskara drar genom kapellets dal | kapellet | 3 | klara questen | 30 silver, välsignelse två körningar | +1 steg |
| Benfolket och spindlarna rör sig samtidigt | kryptan + lunden | 2 | fäll bossen i båda | 50 silver | den som inte stoppades växer (`half` om en stoppades) |

Titeln Landets värn för tre stoppade händelser.

### Hemkomsten i borgen
Rutan på kampanjkartan är borta (bara `--news`). I borgen går den som det viktigaste angår från sin plats (eller porten)
fram till paladinen och pratar i samtalsrutan; den andra kommer efter, högst tre. Sist "Medan ni var borta" med kartans och
världens rader, nya titlar och händelsen som pågår. Ett tryck hoppar fram. Efter en förlust (även GE UPP och GÅ HEM) kommer
tröst först (Mor Elin, Gorm, Imma), sedan en sak om världen, och efter två förluster i rad ett konkret råd: Stig
(Övningsgården mot mötet som fällde en), Broder Alrik (en ägd trofé vars `answers` nämner fienden eller dess egenskap) eller
Gorm (ett djup grundare, eller den lugnaste andra Realmen). Högst ett råd.

### Repliker: budget och ton (efter `docs/research/levande-repliker.md`)
- Högst tre repliker; den tredje bara för det som är viktigt (`ESSENTIAL_KEYS`: händelser, följd, gåva, väckt boss, råd).
- Samma ämne (samma Realm, samma händelse, tröst) ger bara en replik per hemkomst (`family`).
- `{namn}`/`{titel}` aldrig två gånger i samma hemkomst (`line_for` `no_name`).
- Efter en förlust: tröst, sedan världen bara om något ändrades, sist ett råd ur datan; efter tre förluster i rad bara tröst
  och råd (`ONLY_COMFORT_AFTER`). GE UPP får bara repliker skrivna för det ("Du vände i tid"), aldrig "förlust".
- Inte gjort: en egen nedkylning i nedstigningar per replik (`chron_said` turas om bland alla med samma villkor, över
  körningarna, men en replik kan komma tillbaka när poolen är slut), och `{namn}` ligger i ungefär var fjärde av alla
  hemkomstrepliker, inte var femte.

### Botsiffror
`SOAK=karriar` (40 profiler × 18 nedstigningar, Realm i tur), före (`VARLD=av`) och efter:

| | före | efter |
|---|---|---|
| vinst per nedstigning, snitt | 48,2 % | 47,7 % |
| nedstigning 4–18 | 47,3 % | 46,7 % |
| djup efter 18 nedstigningar | 6,0 | 6,0 |
| steg 4 (den förvridna bossen) | 1 nedstigning, 0,03 per profil | 11 nedstigningar, 0,15 per profil |

- Händelser: 4,0 per profil på 18 nedstigningar (Kulten, karavanen, gravklockan och pilgrimerna en gång var; två fronter
  hann aldrig starta). Utfall för botarna: kulten 23 stoppade / 17 inte, karavanen 37/3, gravklockan 31/9, pilgrimerna 29/0
  (11 pågick fortfarande när profilen slutade). Botarna roterar Realm, så de går ofta dit av en slump.
- Följder som började: kryptan 53, kapellet 8, lunden 1. Gåvor: kryptan 94, kapellet 29, lunden 3. Tors bärnsten 602 gånger.
- Steg 4 kom oftare för att en förlorad händelse gav ett steg till; efter soaken ändrat så att den Realm man just gick till
  inte växer av händelsen (bara de andra följderna). Soakens fel (`den förvridna bossen är kvar efter en nedstigning dit`)
  kom av det och är borta (frö 12 igen: inga fel). Kontrollfelet "alva har inte fått agera" i crypt_3 är det kända (Benstormens frysning).

### Frågor till VD
1. Räcker det att Tor skickar en bärnsten per hemkomst när kryptan är lugn, eller ska det vara något annat (silver, ett fynd)?
2. Ska en förlorad händelse också få växa i den Realm man gick till men misslyckades i (nu: nej, bara biskopen blir starkare)?
3. ~~Handelsmannen säljer en sak och går.~~ Beslutat: han stannar tills nästa nedstigning (en av varje vara; allt sålt = han går).
4. Två fronter kommer först efter ungefär 20 nedstigningar med nuvarande ordning (den som legat längst). Ska den komma tidigare?
5. ~~Gåvan efter kapellet är liten.~~ Beslutat: pilgrimen ger ett rykte. Ringarna (nya-grottor.md A) syns redan alltid, så
   ryktet visar själva målen på den första våningen genom dimman (`RunState.apply_rumour`, `revealed`); pilgrimsskarans
   händelse ger fortfarande sin välsignelse (`bless_runs`).

## Kartan syns (2026-10-24, grenen `karta-synlig`, efter VD:s provspel av 0.30.30: "Jag såg inte levande kartan")
- **Hjälprutan "Den levande kartan"** första gången en besökt Realm står på steg 2+ (`LivingMap.grown_realm`): kampanjkartan
  lämnar området ljust med en pulserande guldring och en pil, rutan bredvid (`HelpBox.focus`). Först i kön före djup och
  instabilitet. I Broder Alriks handbok.
- **Stegen syns från 0:** 0 stilla och brunt (inget flöde, tunnare), 1 bläcket andas (`breath` i shadern, ojämn rytm) och
  fyra svaga droppar vid ramen, 2–4 som förut. Obesökta Realms ser ut som förut. Inga siffror; balansen är orörd.
- **"Medan ni var borta" när inget ändrades:** en rad om Realmen som växer härnäst (`LivingMap.quiet_line`, 3 per Realm och
  2 allmänna, plus 2 när bara en Realm är besökt), ingen upprepning förrän alla är sagda (`chron_said`). Bara i
  sammanfattningen, replikernas budget är densamma. Inte på första nedstigningen.
- Skärmdumpar: `docs/provspel/karta-synlig/`.
