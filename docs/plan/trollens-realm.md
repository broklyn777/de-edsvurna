# Trollens Realm – designförslag (Realm 4)

Skriven 2026-10-24 på uppdrag från huvudtråden. Ingenting här är beslutat. Underlag: `docs/plan/troll.md` (Trollfolket,
0.30.23), `docs/plan/spindlar.md` (hur Lunden lades till), `docs/plan/levande-karta.md` (kartan, följderna och
världshändelserna), `docs/plan/0.27-fiender.md`, `docs/ideer/chat-realm3-kallornas-tradgard.md` (kronan med en tom mitt),
`docs/research/siralim.md` §10, §19 och §21, `docs/research/drakvalvet-monster.md`, `data/realms.json`, `data/objects.json`,
`data/world_events.json` och `data/enemies.json`.

Märkning som i 0.27-fiender och spindlar: **Siralim** = som originalet, **VAL** = vårt val, **GISSNING** = obeprövat,
**⚙** = ny kod, **VD** = VD behöver bestämma.

`docs/plan/grotta-handelser.md`, som uppdraget nämner, finns inte på test-0.30. Händelserna i grottan tas därför här
från `levande-karta.md` (världshändelserna) och `objects.json` (Realmens föremål).

---

## Steg 1 – byggt (2026-10-24, grenen `trollberget` från test-0.30)

VD sade "kör". Projektledaren tog besluten nedan; alla är **VAL** tills VD säger annat.

- **VAL 1 Namn:** Trollberget, kort "Berget", id `mountain`.
- **VAL 2 Öppnas** när kapellet är klarat på djup 1 (⚙ `"requires": {"realm": "chapel", "depth": 1}` i realms.json,
  `RunState.realm_open()`, `realm_lock_text()`). På kampanjkartan är området täckt av fördärvet och blekt, med raden
  "Öppnas när kapellet är klarat på djup 1"; ett tryck väljer det inte. Lunden har ingen sådan spärr i koden (den är
  öppen från början); samma rad i realms.json räcker om den ska få en. Utvecklarflaggan `--cleared=chapel:1`.
- **VAL 3 Inga nya troll:** bara de sju som finns. Pooler (alla `stat_mult` satta med botarna, se nedan):
  - Tier 0: `troll_1a` Mossiga backen, `troll_1b` Grytans eld, `troll_1c` Avundens snår, *ny* `troll_1d` Klubban vid grytan
    (Stenkrossaren, Grytmodern).
  - Tier 1: `troll_2a`, `troll_2b`, *nya* `troll_2c` Avund vid grytan (Avundsjätten, Grytmodern, Mossrygg), `troll_2d`
    Stenraset (Stenkrossaren ×2, Avundsjätten).
  - Tier 2: *nya* `troll_3a` Hela byn i berget (fyra), `troll_3b` Vanornas straff, `troll_3d` Mossa och sten, och `troll_2a`.
  - Våningsmöten (vakten vid den bevakade skatten, Nemesis): *nya* `troll_1` Trollstigen och `troll_2` Bergets port
    (Mossrygg, Grytmodern, Stenkrossaren, Avundsjätten); bossen `troll_3` Bergakungens sal.
  - Elit: våning 1 `troll_e1` Gråluvans stuga; våning 2 `troll_e2` Bron (Brom) och *ny* `troll_e3` Vaggan (Gråluva,
    Grytmodern, Mossrygg). Bergsrået, Byggaren och Bortbytingen väntar på nya troll.
- **VAL 4 Motdrag:** inga. Inget befintligt motdrag passar trollen (de nämner Likbäraren, dimman, kultens ordensregel
  eller spindlar); §4.3 kräver ny kod.
- **VAL 5 Berättelsen** som §2. Berättarrutan efter den första segern mot Bergakungen (`dialog.json` narrator
  `boss_mountain_king`, `Run.narrate("boss_" + kind)`): kronan, den tomma infattningen, stämpeln och löftet om klockorna.
- **VAL 6 Fångar:** inga (`"disciples": []` som Lunden). Inga bybor, ingen `captives`-kod.
- **VAL 7 Ingen följd och ingen gåva** (tull, klocka) i det här steget; `growth.folk` är "Trollfolket" så att den levande
  kartan fungerar som för de andra.
- **VAL 8 Kartan:** `rect` [40, 96, 240, 160] i nordväst. Väktarens vinjett låg under området och visas inte längre när
  berget finns; häxan står kvar mellan berget och kapellet. Kompassen flyttade ned till vänster under bergets kartusch, och
  kartuschen hålls innanför vänsterkanten. Kontrollerat i 1280×720 och 1560×720.
- **VAL 9/10 Föremål utan ny kod:** de lånar andra föremåls val med egen text (`results`, som Lunden):
  - **Trollbägaren** (`troll_cup`): TA BÄGAREN = sarkofagens "knock" (en trollgrupp +15 % följer efter, dubbel skatt).
    Planens enklaste version; trollen jagar inte till trappan (det kräver `spawn_group_at_goal` ⚙).
  - **Nedsänkt kyrkklocka** (`sunken_bell`): SLÅ PÅ KLOCKAN = glasfönstrets "pull" (raden syns, nästa grupp +15 %).
    Svedd hud på alla vid `battle_start` och räknaren `bells` väntar (⚙).
  - **Ljusspricka** (`light_crack`): registrets val, MOT GLIMTEN (2 skatter) eller MOT SPÅREN (2 grupper). Planens
    Förstenade-version kräver ⚙.
  - Väktarens timglas. **Sång genom berget** väntar (kräver `named`/`knows_name` ⚙).
- **Questens namn** (§7, ⚙ litet: `"quests"` i realms.json, `quest.title`, `RunState.quest_text`): Tullen vid ravinen,
  Stäng berget, Klockans delar. Föremålens namn i Samla (Kläppen, Oket, Klockrepet) är inte gjorda.
- **Vinjett och zoombild:** `vagen.webp` ur Drakvalvet. **Stämning:** kryptans. **Stil** `"mountain"`: striden (`CryptWorld`)
  i kallt blått ljus, grå granit, grova sjukantiga stenpelare och flyttblock; rumsögonblicken (`RoomWorld`) i kryptans
  form med kallare palett.
- **Tester:** `tests/test_realm_mountain.gd` (bara troll, spärren, kartans ruta, 40 frön × 2 våningar utan
  `Grotto.problems()`, questens namn, föremålens texter).

**Botarna** (`BALANS=grotta NIVA_REALM=mountain`, djup 1, 100 körningar per rad, MACRO / TUNED / försiktig / direkt):

| Läge | 4 hjältar, nivå 3 | Paladinen + Imma |
|---|---|---|
| Trollens möten utan `stat_mult` (tier 0,72 / 0,76 / 0,78, elit och boss 1,0) | 80 / 83 / 69 / 70 % | – |
| Tier 0,82 / 0,88 / 0,90, elit 1,1, våningar 1,1 / 1,14, boss 1,1 | 38 / 52 / 28 / 32 % | 3 / 3 / 2 / 6 % |
| Samma, boss 1,0 | 58 / 69 / 51 / 57 % | 23 / 31 / 5 / 11 % |
| **Samma, boss 1,05 (valt)** | **46 / 64 / 34 / 38 %** | 8 / 8 / 2 / 7 % |
| Kapellet som jämförelse (samma gren) | 44 / 45 / 10 / 22 % | 94 / 74 / 91 / 91 % |

- Nästan alla förluster sker hos Bergakungen (`f1_end`), resten vid elitgruppen på våning 2.
- **Små sällskap är en vägg:** med två hjältar gör sällskapet nästan alltid samma sorts handling två gånger i rad, så
  Stenhjärta (−60 % skada) gäller nästan hela tiden. `PARTY_SCALE` räcker inte. Berget öppnas efter kapellet, då de
  flesta har fler hjältar, men **VD** bör avgöra om Stenhjärta ska räkna per hjälte eller vara mildare för små sällskap.

**Kvar ur planen:** de fyra nya trollen och deras troféer och elitvarianter (§4.2), motdragen (§4.3), elitgrupperna e3–e6
med nya troll, Sång genom berget och de andra föremålens fulla versioner (§6), föremålsnamnen i Samla, fångarna (§8),
tull och klockgåva (§9), den kronade Bergakungen (steg 4), världshändelsen (§10), tuschvägen och bron på kartan (§11),
egen stämning, musik och ljud (§12), egna modeller och en egen vinjett (§13).

---

## 0. Kort

- **Trollberget** (`mountain`, kort "Berget"): ett fjäll ovanför Stenby. Där har trollen bott sedan före kyrkorna, och
  de höll sig inne så länge kyrkklockorna i dalen ringde. När kapellet fördärvades tystnade klockorna, och då kom
  trollen ut. Bergakungen bär en krona med en tom infattning. Det är samma avsändare som i de andra Realms.
- **Familjen finns redan:** sju troll, sju troféer, Trollhud, mötena `troll_1a` … `troll_3`. Det som saknas är
  Realmens data: pooler i tre tiers, våningsmöten, elitpooler, föremål, kartans ruta och vinjett.
- **Tema i striden: trollen straffar vanor.** Varje troll straffar en sak som makrona gör av gammal vana: försvara,
  buffa, hela, provocera, kasta förmågor före vaggvisan eller göra samma sak två gånger mot Bergakungen. De fyra nya
  trollen i förslaget straffar fler vanor: att alltid slå den svagaste, att hela med ljus, att vara snabbast och att
  slåss utan att veta vad man möter.
- **Folktron är svensk och allvarlig:** bergtagning, bortbytingar, klockor som trollen hatar och stjäl, stenar kastade
  mot kyrkor, trollbägaren, berget som lyfts på guldstolpar en helig natt och jätten Finn i Lund, vars namn röjdes av en
  vaggvisa.

---

## 1. Namn och vinjett

**Namnförslag (VD):**
1. **Trollberget** (rekommenderas): tydligt för en ny spelare, och "Berget" som kort namn får plats i panelen.
2. **Gråberget:** knyter an till Gråluva och den grå stenen, men säger mindre om vad som bor där.
3. **Kungsberget:** pekar mot bossen, men kan läsas som ett vanligt ortnamn.

id i datan: `mountain` (VAL, eftersom `troll` redan är prefix för möten och modeller).

**Vinjett:**
- **Tills vidare** används Drakvalvets `vagen.webp` (`~/drakvalvet/public/illustrations/`, inte använd i spelet än): en
  lerig väg mellan stora stenblock, granskog och fjäll i dimma. Stenblocken läses som troll som har stelnat, så bilden
  fungerar redan. Den kopieras till `assets/illustrations/` och sätts som `"vignette": "vagen"`.
- **En egen vinjett** beställs med stilblocket i `docs/illustrationer.md` följt av:

> A steep granite mountain above a small mining village in a valley, seen from a distance. At the foot of the mountain
> one side of the hill is lifted on thick pillars and warm light spills out from beneath it, with long shadows of huge
> hunched figures. A small stone church in the valley with an empty bell tower and a few large boulders lying in the
> churchyard as if thrown from the mountain. A narrow wooden bridge over a ravine on the path up. Moss-covered boulders
> along the path that almost look like crouching giants. Serious and foreboding, no cute creatures, no faces in the
> rocks, no text.

- **Zoombilden** (`zoom_image`, kameran glider in i området) blir `vagen` tills den egna bilden finns.

---

## 2. Berättelsen (lore)

> Ovanför Stenby står ett fjäll som byborna inte pekar på. Där inne har trollen bott sedan före kyrkorna: Bergakungen,
> hans folk och de gamla som var jättar när berget var ungt. Man stod ut med varandra så länge klockorna i dalen ringde.
> Klangen gör ont i trollen, så de höll sig inne, bytte ibland till sig ett barn, en ko eller en piga och lät byn vara.
> I höstas tystnade klockorna i kapellet ovanför dalen, och med dem tystnade de i Stenby. Någon hade lovat Bergakungen
> att de aldrig skulle ringa igen. Sedan dess står berget öppet på nätterna. Kor försvinner, vägen över ravinen kostar
> tull, kyrkklockan i Stenby är borta ur tornet och tre människor har gått in i berget utan att komma ut igen.
> Bergakungen bär en ny krona av sten, med en tom infattning i mitten.

**Tråden till de andra Realms (VD):**
- 0.29.2 hittar spelaren efter den första bossen ett beslag med en krona med en tom mitt, och i Källornas trädgård
  (`chat-realm3-kallornas-tradgard.md`) har tre leveranser samma stämpel.
- Trollens del är ett **löfte, ingen leverans:** avsändaren lovade Bergakungen att klockorna skulle tystna, och
  kapellets fördärv var priset.
- Modellen `troll_grumse.glb` har redan en tom infattning framtill i kronan. Bilden finns alltså, och berättelsen får
  knyta an till den.
- Berättarrutan efter den första segern mot Bergakungen (`dialog.json` "narrator") kan lyda: *(Kronan var tung och
  kall. Infattningen i mitten var tom, och på insidan av ringen fanns samma stämpel som på beslaget i kryptan: en krona
  med en tom mitt.)*

**Varför Realmen öppnas sent (VAL):** den öppnas när kapellet har klarats på djup 1, eftersom kapellets tystade klockor
är orsaken. Ordningen blir krypta → kapell → lund eller berg. **VD:** ska Trollberget komma före eller efter Lunden?

**Ton:**
- Trollen är onda, gamla och listiga. De är aldrig gulliga och aldrig skämtfigurer (VD 2026-10-23).
- Paladinens sida blir aldrig ockult. Mot trollen använder hon det byn alltid har använt: ljus, klockor, stål och
  att kunna namnet.
- Troféerna är föremål som tagits eller lärdomar, aldrig kroppsdelar (`lesson` som i `traits.json`).

---

## 3. Folktron bakom (research)

Kort sammanfattning av svensk och nordisk folktro som förslaget bygger på. Källorna står sist.

| Motiv | Folktron | Hur vi använder det |
|---|---|---|
| **Bergtagning** | Bergatroll och bergsrån lockade in människor i berget, och de kom ut förändrade eller inte alls. Det förekommer i domstolsprotokoll (en rättegång 1691) och i balladerna ("Den bergtagna", "Herr Mannelig"). | Fångarna i fånge-rummen, Bergsrået (Lockrop), världshändelsen "Hedda lärling är bergtagen" |
| **Klockor** | Trollen tålde inte kyrkklockornas klang. De flyttade bort från bygder med kyrkor och försökte stjäla eller sänka klockorna. | Lore (de tysta klockorna), föremålet *Nedsänkt kyrkklocka*, Kyrkkastarens Klockhat, Samla-questen |
| **Kyrkkast** | Jättar och troll kastade stenblock mot nybyggda kyrkor. Stora flyttblock förklarades som missade kast. | Kyrkkastaren, vinjettens stenar på kyrkogården |
| **Bortbytingar** | Trollkvinnor bytte ut människobarn mot sina egna. Bytingen var hungrig, ful och ovanligt stark. | Bortbytingen |
| **Dagsljuset** | Troll som överraskas av solen spricker eller blir sten (mest i norsk och isländsk tradition). I Sverige är det oftare åskan eller hanegället som jagar dem. | Motdraget *Före hanegället*, reservföremålet *Ljusspricka*, heligt ljus som Realmens vapen |
| **Guldstolparna** | Julnatten (i vissa trakter midsommarnatten) lyfts berget på guldstolpar och trollen håller fest. En modig kan ta något, men aldrig äta eller dricka. | Föremålet *Trollbägaren*, en reservhändelse |
| **Trollbägaren** | Trollen bjuder en ryttare att dricka ur en bägare om natten. Han kastar drycken bakom sig (den bränner hästens hud) och rider bort med bägaren, och trollen jagar honom till kyrkogården. Bägare med den historien finns i flera kyrkor. | Föremålet *Trollbägaren* |
| **Jätten Finn** | Finn byggde Lunds domkyrka. Lönen var S:t Laurentius ögon om helgonet inte kunde lista ut hans namn. Laurentius hörde jättekvinnan sjunga namnet för sitt barn. När han ropade det blev Finn och hans hustru sten i kryptan (Finnpelarna). | Den namnlöse byggaren, föremålet *Sång genom berget*, Gråluvans vaggvisa |
| **Bron** | Bron över forsen vaktas av ett troll (De tre bockarna Bruse, norsk). | Brom (finns), tullen som följd i världen |
| **Stål** | "Stål över dig!" Stål över dörren eller i vaggan skyddade mot troll och bytingar. | Smedjan och Hedda (Bergets gåva), en replik |
| **Bergakungen** | Bergets härskare i balladerna. Ibsens och Griegs Dovregubbe är norsk. | Bossen (finns). Griegs musik citeras inte (§12). |

---

## 4. Fienderna

### 4.1 Det som finns (0.30.23)
Mossrygg, Grytmodern, Avundsjätten, Stenkrossaren (vanliga), Trollmor Gråluva (elit), Brom (miniboss) och Bergakungen
(boss). Artregeln är Trollhud (`troll_hide`): en träff från en förmåga ger Svedd hud, så att trollet inte läker förrän
efter sin nästa tur. Alla har en egen förmåga och en egen trofé (`troll.md`).

**Vanorna som straffas i dag:**

| Troll | Straffar |
|---|---|
| Stenkrossaren | att försvara |
| Avundsjätten | att buffa |
| Grytmodern | att hela |
| Brom | att provocera |
| Gråluva | att kasta förmågor när vaggvisan närmar sig |
| Bergakungen | att upprepa samma sorts handling |
| Mossrygg | att låta bli att slå med förmågor (Trollhud) |

### 4.2 Fyra nya troll (förslag)
Stats jämförs med Mossrygg (H 60, A 12, I 6, D 2, S 7). Som för spindlarna: en rad text per egenskap som går att läsa
på telefonen.

| # | Namn (id) | Roll | Stats (GISSNING) | Egenskap | Egen förmåga | Straffar |
|---|---|---|---|---|---|---|
| 1 | **Bortbytingen** (`changeling_troll`) | vanlig, liten | H 34, A 9, I 6, D 1, S 11 | *Moderns famn:* "Så länge Bytingen har lägst liv i gruppen tar trollet med mest liv hälften av de riktade träffarna mot den." `guard_family` 0,5 som Kultens förman, ⚙ villkoret `self_lowest_hp` | *Bytingens skrik* (`changeling_wail`): alla hjältar Hånade 1 tur, 30 % chans, nedkylning 4 | att alltid slå "fienden med lägst liv" (startmakrot) |
| 2 | **Kyrkkastaren** (`stone_thrower`) | vanlig, bakre led | H 50, A 13, I 6, D 1,5, S 6 | *Klockhat:* "När en hjälte använder en helig förmåga kastar Kyrkkastaren en sten mot hen (60 % av Attack)." ⚙ villkoret `school` i `when` (skolan finns i händelsen men inte som villkor) | *Flyttblocket* (`boulder_throw`): 110 % skada mot den som senast helade (`pick: healer`), sedan längst ned på tidslinjen (`to_bottom`), nedkylning 3 | att hela och slå med ljus utan att tänka, trots att heligt ljus är det trollen tål sämst |
| 3 | **Bergsrået** (`mountain_lure`) | elit | H 66, A 9, I 14, D 2, S 12 | *Lockrop:* "I början av sin tur lockar Bergsrået hjälten med högst Speed: Förvirrad 1 tur." (aura `confused`, finns; mål ⚙ `highest_speed`) | *Bergtagning* (`mountain_take`): en Förvirrad hjälte blir Sovande 1 tur och tappar en Charge (`drain_charge`, finns), nedkylning 4 | att vara snabbast och att låta bli att rena debuffar |
| 4 | **Den namnlöse byggaren** (`nameless_giant`) | elit | H 95, A 15, I 5, D 3,5, S 6 | *Utan namn:* "Tar 50 % mindre skada tills någon säger hans namn. När Gråluva sjunger hör sällskapet det, och då tar han full skada resten av striden." ⚙ auran `named` som en annan fiendes förmåga sätter på honom | *Kyrkbygget* (`giant_wall`): Barriär 15 % av max liv på alla troll, nedkylning 4 | att stressa: sällskapet tjänar på att stå ut med vaggvisan en gång |

**Varför just de här fyra:**
- **Bortbytingen** lär makrona att "lägst liv" inte alltid är rätt. Svaret är att anfalla den med mest liv först, slå
  alla på en gång, eller lägga villkoret "saknar Moderns famn". Det är familjens enda lilla troll, så grupperna blir
  lättare att läsa.
- **Kyrkkastaren** gör Realmens vapen till en fråga. Heligt ljus bränner trollen (Trollhud vill ha förmågor), men
  kastaren slår tillbaka mot den som använder det. Frågan blir vem som kastar ljuset och när.
- **Bergsrået** är bergtagningen i striden. Svaret är att rena debuffar (Alva, Ragnhild, Abbedissans nyckel), fälla
  henne först eller ta bort Speed ur bygget. Hon är en egen varelse ur folktron, men räknas till `troll_kin` (VAL).
  **VD:** ska Bergsrået vara ett troll? Alternativet är en egen liten familj, "De underjordiska".
- **Den namnlöse byggaren** är jätten Finn i Lund. Han är Realmens kombination mellan två fiender: i hans grupp ger
  Gråluvas vaggvisa sällskapet ett anfallsfönster. Spelaren lär sig att låta en farlig handling ske. Hans trofé
  (nedan) bär samma idé.

**Troféerna** (alla är föremål eller lärdomar):

| Fiende | Trofé (id) | Sällsynthet | Text (GISSNING) | Svar på |
|---|---|---|---|---|
| Bortbytingen | **Stålet ur vaggan** (`cradle_steel`) | vanlig | "Bäraren tar hälften av de riktade träffarna mot den allierade som har lägst liv, så länge bäraren har mer än 50 % liv." | Grupper som väljer den svagaste (spindlarna, Slukaren) |
| Kyrkkastaren | **Kyrkstenen** (`church_stone`) | vanlig | "När en fiende helar kastar bäraren en sten mot den (60 % av Attack), en gång per tur." | Kultens folk, Grytmodern, Mossrygg |
| Bergsrået | **De bergtagnas ring** (`taken_ring`) | elit | "Första gången i striden som bäraren skulle bli Förvirrad, Sovande eller Förstenad slipper hen, och den som försökte blir Förvirrad i stället." ⚙ `reflect_aura`, en gång | Gråluva, Sömnvävaren, Bergakungens vrede |
| Den namnlöse | **Byggmästarens mått** (`builders_measure`) | elit | "När en fiende använder sin egen förmåga gör bärarens nästa anfall +40 % skada." (`next_attack_mult` och villkoret `ability_not_basic` finns; GISSNING att de räcker för en fiendes förmåga) | Fiender med farliga förmågor: låt dem kasta, svara sedan |

Lärdomsrader i samma stil som `troll.md`:
- `cradle_steel`: "Bytingen hade en mor som skyddade den. {bärare} lärde sig att ställa sig framför den svagaste."
- `builders_measure`: "Byggmästaren väntade ut varje sten. {bärare} lärde sig att låta fienden visa sin hand först."

**Elitvarianter** (5 %, glöder, eget namn och egen trofé) för de vanliga, med namn ur folktron:
- Mossrygg → **Den gamle i skogen**
- Grytmodern → **Trollkäringen från Ödemarken**
- Avundsjätten → **Guldräknaren**
- Stenkrossaren → **Gråstensbrytaren**
- Bortbytingen → **Den bortbytte**
- Kyrkkastaren → **Kastaren från Kinnekulle** (VD: ett riktigt ortnamn, eller ett påhittat?)

Varianternas troféer skrivs när VD har sagt ja till de fyra nya trollen.

### 4.3 Motdrag per djup (Siralim §21.2, högst ett per grupp, bara elit, Nemesis och boss)

| Djup | Motdrag (id) | Förebild | Text | Bärs av |
|---|---|---|---|---|
| 1 | **De tysta klockorna** (`silent_bells`) | Nix Informer (tystar vid stridens början) | "Motdrag: hjälten med högst Intelligence är Tystad sin första tur." (`silenced`, finns; ⚙ mål `highest_int`) | Trollmor Gråluva |
| 2 | **Trollguldet** (`troll_gold`) | Dragon Queen (laget tar skada när en spelarvarelse buffas) | "Motdrag: när en hjälte får en buff tar sällskapet skada (20 % av den här fiendens Attack)." | Den namnlöse byggaren, Bergsrået |
| 3 | **Före hanegället** (`before_cockcrow`) | Aaxer Apocalypse (+15 % stats per tur), mildare | "Motdrag: trollen får +5 % Attack och Defense efter varje egen tur, högst +40 %. Natten är deras." | Bergakungen, Brom |

Brom behåller Tull som egenskap. Före hanegället bärs av högst en per grupp (VAL), alltså av Bergakungen i bossmötet
och av Brom i Bron.

**VD:** Före hanegället och Utmattningen (från tur 100) drar båda åt samma håll i långa strider. Trollstriderna är
redan längre än kapellets (14–15 turer mot 10, Bergakungen 78 mot biskopens 71, `troll.md`), så taket behöver mätas.

---

## 5. Pooler, våningsmöten och elitgrupper

Samma form som i `realms.json`: tre tiers efter våning och avstånd, elitpooler för våning 1 och 2, `floors` med
våningarnas Nemesis-/questmöten och bossmötet. Gruppernas `stat_mult` sätts med botarna (`BALANS=grotta`,
`NIVA_REALM=mountain`, `BALANS=elitgrupper`), som för Lunden.

**Tier 0** (nära starten på våning 1):

| id | Namn | Fiender | Mall |
|---|---|---|---|
| `troll_1a` | Mossiga backen | Mossrygg ×2 | finns |
| `troll_1b` | Grytans eld | Grytmodern, Mossrygg | finns |
| `troll_1c` | Avundens snår | Avundsjätten, Stenkrossaren | finns |
| `troll_1d` *ny* | Vaggan i snåret | Bortbytingen, Mossrygg | "Fel mål" |

**Tier 1:**

| id | Namn | Fiender | Mall |
|---|---|---|---|
| `troll_2a` | Klubbor i dimman | Stenkrossaren, Mossrygg, Avundsjätten | finns |
| `troll_2b` | Kittelgropen | Grytmodern ×2, Stenkrossaren | finns |
| `troll_2c` *ny* | Stenregnet | Kyrkkastaren, Stenkrossaren, Bortbytingen | "Straffar helning" |
| `troll_2d` *ny* | Avund vid grytan | Avundsjätten, Grytmodern, Mossrygg | "Straffar stöd" |
| `troll_2e` *ny* | Kastarnas egg | Kyrkkastaren ×2, Mossrygg | "Straffar ljus" |

**Tier 2** (långt bort och på våning 2):

| id | Namn | Fiender | Mall |
|---|---|---|---|
| `troll_3a` *ny* | Hela byn i berget | Grytmodern, Bortbytingen, Stenkrossaren, Kyrkkastaren | "Vanorna" |
| `troll_3b` *ny* | Vanornas straff | Stenkrossaren, Avundsjätten, Grytmodern | "Straffar stöd" |
| `troll_3c` *ny* | Bytingarna | Bortbytingen ×2, Mossrygg, Kyrkkastaren | "Fel mål" |
| `troll_3d` *ny* | Mossa och sten | Mossrygg ×2, Stenkrossaren, Avundsjätten | "Nötning" |
| `troll_2a` | (återanvänds, som Lunden gör med grove_2a) | | |

**Våningsmöten** (`floors`; de saknas i dag, eftersom troll_1 och troll_2 inte finns):
- `troll_1` **Trollstigen**: Mossrygg, Grytmodern, Stenkrossaren, Bortbytingen
- `troll_2` **Bergets port**: Stenkrossaren, Kyrkkastaren, Avundsjätten, Mossrygg
- `troll_3` **Bergakungens sal**: Bergakungen, Stenkrossaren, Trollmor Gråluva (finns)

**Elitpooler:**
- **Våning 1:** `[troll_e1]` Gråluvans stuga (Gråluva, Avundsjätten, Mossrygg; finns). Eliten på våning 1 ska vara den
  lättaste: vaggvisan är läsbar och syns på kortet. `SMALL_PARTY_ELITE` gäller som för de andra Realms.
- **Våning 2:**

| id | Namn | Fiender | Frågan |
|---|---|---|---|
| `troll_e2` | Bron (finns) | **Brom** (miniboss), Mossrygg ×2 | Provocera inte, slå honom inte i onödan |
| `troll_e3` *ny* | Bergsråets lockrop | Bergsrået, Avundsjätten, Kyrkkastaren | Rena Förvirrad och fäll henne först |
| `troll_e4` *ny* | Kyrkbyggaren | Den namnlöse byggaren, Gråluva, Bortbytingen | Stå ut med vaggvisan, slå när han har fått sitt namn |
| `troll_e5` *ny* | Bergtagningen | Bergsrået, Stenkrossaren, Mossrygg | Försvara när du är Förvirrad, men inte mot Klubban |
| `troll_e6` *ny* | Vaggan | Gråluva, Bortbytingen, Grytmodern | Hela inte i otakt, slå inte bara den svagaste |

**Minibossen** är Brom (`rank: miniboss`, finns), på samma plats som Klockaren i kryptan. Han kan också vara Nemesis i
questen "Jakt på Nemesis" (§7).

**Mönstret Lunden använder** (`stat_mult` 0,78 / 0,84 / 0,85 för tiers och ~1,1–0,88 för eliten) är en startpunkt. Trollen
har mer liv per figur och färre figurer per grupp. Grupperna ovan har därför 2–4 troll, aldrig 4 på tier 0.

---

## 6. Realmens föremål (3, i objects.json-stil)

Siralims Realms har egna föremål som är Realmens personlighet (Blood Groves svampar, flöjter och nomader, §19.1). Två
till tre per våning (`Grotto._place_objects`), plus Väktarens timglas som alla Realms har.
`"objects": ["troll_cup", "sunken_bell", "song_in_rock", "hourglass"]`.

```json
"troll_cup": {
  "name": "Trollbägaren",
  "text": "Berget står öppet på guldstolpar, och på en sten står en bägare full till brädden. Den som tar den måste springa. Den som dricker kommer inte ut igen.",
  "options": [
    {"id": "grab", "label": "TA BÄGAREN OCH SPRING"},
    {"id": "spill", "label": "HÄLL UT DRYCKEN"},
    {"id": "leave", "label": "LÅT DEN STÅ"}
  ],
  "results": {
    "grab": "Ni har bägaren. Bakom er vaknar berget: en trollgrupp följer efter er till trappan.",
    "spill": "Drycken fräser i mossan. Där den rann syns spåret till en skatt.",
    "leave": "Ni går förbi. Någon i berget skrattar lågt."
  }
}
```
- **grab:** tre gånger en vanlig skatts silver (S × 3) och en bärnsten. En ny vanlig grupp (tier efter våning) ställs
  intill trappan eller bossen och måste besegras för att komma förbi (⚙ `spawn_group_at_goal`). Trollen jagar ryttaren
  till kyrkogården.
- **spill:** den närmaste obevakade skatten avslöjas (`revealed`, finns). En liten och säker belöning.
- Föremålet gör det som Siralim gör med föremål som startar strider: större byte mot en strid man inte valde själv.

```json
"sunken_bell": {
  "name": "Nedsänkt kyrkklocka",
  "text": "Stenbys klocka ligger i en grop, halvt begravd i grus. Trollen har slagit sönder kläppen men inte malmen. Den går att få att ljuda en gång till.",
  "options": [
    {"id": "ring", "label": "SLÅ PÅ KLOCKAN"},
    {"id": "mark", "label": "MÄRK UT PLATSEN"}
  ],
  "results": {
    "ring": "Klangen går genom berget. Trollen på våningen bränns av den – men nu vet de var ni är: nästa grupp är beredd.",
    "mark": "Ni ristar ett kors i stenen. Arbetarna från Stenby kan hämta klockan när berget är lugnt."
  }
}
```
- **ring:** alla trollgrupper på den här våningen börjar sin strid med Svedd hud (`troll_scorched` på alla vid
  `battle_start` ⚙, som `next_stat_mult` fast med en aura). Nästa grupp man möter är beredd (+15 %, som Övertäckt
  glasfönster).
- **mark:** en klockdel räknas till Samla-questen om den är aktiv (§7). Annars ger den +1 till världens räkning
  (`Profile.world.bells`, ⚙). Tre märkta klockor ger gåvan "Klockan hänger igen" (§9) även om berget inte står på
  0–1. **VD:** en räknare till är mer att hålla reda på. Alternativet är att mark bara ger silver.

```json
"song_in_rock": {
  "name": "Sång genom berget",
  "text": "Genom en spricka hörs en trollkvinna sjunga för ett barn. Det är en vaggvisa, och i den finns ett namn. Lyssnar man länge nog lär man sig det – men den som lyssnar blir sömnig.",
  "options": [
    {"id": "listen", "label": "LYSSNA TILL SLUTET"},
    {"id": "leave", "label": "GÅ VIDARE"}
  ],
  "results": {
    "listen": "Ni kan namnet. Bergakungen och de gamla i berget kan inte längre gömma sig bakom det i den här nedstigningen.",
    "leave": "Sången följer er en bit och tystnar."
  }
}
```
- **listen:** kostar en Charge från varje hjälte, eller så börjar hjälten med högst Speed nästa strid Sovande (**VD**
  väljer). Vinsten gäller hela körningen:
  - Den namnlöse byggaren börjar med `named` och tar alltså full skada.
  - Bergakungens Stenhjärta är av hans tre första turer i bossmötet (⚙ `RunState.knows_name`, läses i `battle_opts`).
- Ligger bara på våning 2 (VAL), så att spelaren väljer det med bossen framför sig.
- Det här är jätten Finn: namnet röjs av en vaggvisa.

**Reserv:** **Ljusspricka** (`light_crack`): "Dagsljus sipprar in genom en spricka. Trollen går en omväg runt den."
VIDGA SPRICKAN (offra en Charge) gör att trollen i nästa strid börjar Förstenade 1 tur (`stone`, finns: kan inte undvika
eller krita). Svagare än de tre ovan, men den enklaste att bygga.

---

## 7. Realm Quest (smak)

De tre typerna finns (`RunState.roll_quest`). Trollberget ger dem egna namn och texter (⚙ text per Realm, om det inte
redan finns):

| Typ | Namn | Text |
|---|---|---|
| Jakt på Nemesis | **Tullen vid ravinen** | "Någon tar tull på vägen till Stenby. Hitta honom och betala med stål." Nemesis är Brom eller en elitvariant av en vanlig. |
| Rensa (2 elitgrupper) | **Stäng berget** | "Två av bergets gamla har kommit ut i ljuset. Driv in dem igen innan natten." |
| Samla (2–3 föremål, bevakade) | **Klockans delar** | "Kläppen, oket och repet till Stenbys klocka är utspridda i berget. Bär hem dem." |

Föremålen i Samla heter **Kläppen**, **Oket** och **Klockrepet** (⚙ föremålens namn per Realm). När Samla har klarats
en gång ringer klockan i Stenby, och Gorm eller Tor säger en replik vid hemkomsten (världens krönika).

---

## 8. Fångar och lärjungar

Lunden har inga lärjungar (`"disciples": []`). Två vägar (**VD**):

**A. Bergtagna bybor (rekommenderas, billigt):**
- Fånge-rummen innehåller bybor ur Stenby, inte hjältar: Pigan Kerstin, Drängen Pål, Klockarens son.
- Den som befrias ger silver, och en rad i krönikan vid hemkomsten (Mor Elin har en gäst i värdshuset tills nästa
  nedstigning).
- Folktron säger att de bergtagna kom ut förändrade. Den första befriade säger alltid något som visar att hen har
  varit borta längre än hen tror ("Är det redan höst?").
- ⚙ `"captives"` i realms.json med namn och replik i stället för `hero`, och `Run.rescue_prisoner` ger silver och
  krönika i stället för en hjälte.

**B. En ny följeslagare:**
- **Klockgjutaren Elof** (förslag), en äldre hantverkare vars klocka trollen tog.
- Han är inte präst och inte trollkunnig, bara en gjutare med ett gott öra: ingen ockult sida, tonen följer
  `tone-fresh` (en människa med brister, inte ett helgon).
- Roll: stöd/störning. Egen egenskap *Malmens klang*: "När en hjälte vaknar ur Sovande eller slutar vara Förvirrad
  får hen +20 % Attack sin nästa handling."
- Signaturhandling *Klockslag*: väcker och renar Sovande och Förvirrad från hela sällskapet, nedkylning 4.
- Han svarar direkt på Bergsrået och Gråluva, så han är "lösningen före väggen" (ChatGPT:s lärdom).
- Kostnad: porträtt, modell, repliker, makroförslag, balans. Med 12 hjältar räcker A.

---

## 9. Den levande världen

Följer tabellen i `levande-karta.md` §2. Familjen i `growth`: `{"folk": "Trollfolket"}`.

**Följd på steg 3+** (så länge Realmen står där): **Tull på vägarna.**
- Brom och hans folk tar tull på vägarna till borgen, så att silvret från vunna strider blir 15 % mindre (alla Realms).
- Det syns hos portvakten Sven ("Det kostar att gå över bron nu, {namn}"), på kampanjkartan och i segerskärmens
  silverrad (en liten tullsymbol, ⚙).
- **Varför silver:** kryptan tar Tors bärnsten, lunden tar smedjan och kapellet tar helningen. Silvret är det enda
  som ingen Realm rör än.

**Gåva när Realmen trycks tillbaka till 0–1** (en gång, laddas på 2+): **Klockan hänger igen.**
- Arbetarna bär hem Stenbys klocka och hänger den i borgens port. Den ringer när paladinen går ut.
- I nästa körning (vilken Realm som helst) varar Sovande och Förvirrad en tur kortare på hjältarna (⚙ en
  `RunState`-flagga som `world_heal_mod`).
- **Enklare alternativ:** 3 bärnsten och 40 silver från stenhuggarna, som kan bryta i berget igen (samma form som
  kryptans gåva).

**Steg 4 – förvriden boss (VD, senare):** **Den kronade Bergakungen**, med en sten i infattningen som lyser kallt.
- Stenhjärta gäller även när sällskapet gör samma handling två gånger på olika hjältar, och ett tredje skede vid 30 %.
- Följer den svärtade Benfursten (`levande-karta.md`): egen trofé direkt vid första segern.

---

## 10. Världshändelse

```json
"taken_apprentice": {
  "name": "Heddas lärling är bergtagen",
  "realms": ["mountain"],
  "turns": 2,
  "win": "quest",
  "text": "Heddas lärling gick upp mot berget efter malm och kom inte tillbaka. Byborna har sett ljus mellan guldstolparna. Klara questen på Trollberget innan berget sluter sig.",
  "mark": "Heddas lärling är bergtagen – klara questen i berget",
  "win_text": "Lärlingen gick ut ur berget bakom er, blek men hel. Hedda smider gratis en gång.",
  "lose_text": "Lärlingen kom hem själv efter tre nätter och säger inte var hon har varit. Hedda har svårt att arbeta, och berget växte.",
  "on_win": {"silver": 30, "free_level": 1},
  "on_lose": {"growth": 1, "smith_runs": 2}
}
```
- ⚙ `free_level`: nästa artefaktnivå hos Hedda kostar ingenting.
- **Ingen permanent förlust** (regeln i `levande-karta.md`): lärlingen kommer alltid hem. Förändrad, som de bergtagna
  i folktron, och Hedda påverkas en tid.
- Den passar Realmen bättre än en högtid (kapellet har redan Kulten samlas till högtid). Den är personlig, och
  spelaren känner Hedda.

**Reserv: "Två fronter"** med kapellet:
- "Kapellets klockor ska tystas för gott, och berget väntar på det": fäll bossen i kapellet eller i berget.
- Den knyter ihop lore-tråden (§2). Kräver bara datan (`realms: ["chapel", "mountain"]`).

---

## 11. Kampanjkartan

Upptaget i 1280×720 (`realms.json` "map" och `campaign_screen.gd`):

| Område | x | y | b | h |
|---|---|---|---|---|
| Kryptan | 150 | 372 | 330 | 220 |
| Kapellet | 490 | 96 | 320 | 213 |
| Lunden | 548 | 404 | 250 | 168 |
| Väktaren | 296 | 176 | 165 | 110 |
| Häxan (marginal) | 26 | 104 | 200 | 133 |
| Panelen | | | höger kant | |

**Förslag (VD):** `"rect": [40, 96, 240, 160]` i nordväst.
- Fjällen ligger i norr i folktron, och berget hamnar intill kapellet: dalen mellan dem är där klockorna tystnade.
- **Häxan** flyttas eller tas bort. Hon är bara dekor, och kapellets häxor finns redan i fienderna.
- **Väktaren** står kvar mellan berget och kryptan.
- Ett **tuschvägskäl** med en liten bro över en ravin mellan berget och kapellet ger Brom en plats på kartan.
- **Om häxan ska stå kvar:** `[24, 300, 140, 120]` (vänster kant ovanför kryptan) är trångt men fritt. Kontrollera
  med `--gate` på telefonens bredd.

Fördärvets shader och `growth` fungerar som i de andra Realms. På steg 2+ fladdrar fiendens eldar som ljus under
guldstolparna.

---

## 12. Stämning och musik

**Stämning** (`assets/audio/ambience_mountain/`, `tools/gen_sfx.py`): saknas. Kryptans stämning används tills vidare,
som i Lunden.
- vind över sten och lavar
- vatten som droppar i ett schakt
- ett mycket lågt och långsamt mullrande (berget som andas)
- sten som gnids mot sten långt bort
- **sällan** en avlägsen kulning från dalen, som om en vallkulla kallar hem korna före natten. Kulning användes mot
  rovdjur och "det som gick i skogen". Den hör till människornas sida, så den är inte ockult.

**Musik** (`music_mountain.ogg`, `tools/gen_audio.py`):
- moll eller dorisk skala, en låg bordunton som från en nyckelharpa eller hummel
- långsam 3/4 i polskans tunga gång, stråkar i lågt register och en djup trumma på första slaget
- inga körer
- **Bossen** (Bergakungen) använder `music_boss.ogg` eller en variant med samma bordun och trumman dubbelt så tät.
- **Griegs "I Bergakungens sal" undviks:** den är fri att använda (Grieg dog 1907), men den är en kliché, gör tonen
  komisk för många och är norsk.

**Ljud för förmågorna** (finns till stor del):
- `bone_crush` för klubborna
- ett lågt `stone_throw` och `stone_land` för Kyrkkastaren (nya, syntes)
- vaggvisan: ett nynnande moll-motiv, tre toner (saknas, står som kvar i `troll.md`)
- Bergsråets lockrop: en långt borta kulning baklänges (syntes)
- klockan: ett nytt `bell_toll` (syntes; det finns inget klockljud i `assets/audio/` i dag)

---

## 13. Modeller

**Finns** (`assets/models/`):

| Fil | Används av | Anm. |
|---|---|---|
| `troll.glb` | Avundsjätten, Stenkrossaren, Brom (×1,3), Gråluva (utan klubba) | grundtrollet, 2,2 m, tintas med `colors` |
| `troll_mossrygg.glb` | Mossrygg | mosstuvor på rygg och axlar |
| `troll_slev.glb` | Grytmodern | med slev; förklädet ur `troll_delar.glb` |
| `troll_grumse.glb` | Bergakungen | stenkrona med tom infattning, 2,98 m |

**Nya troll ur befintliga filer** (ingen ny modell behövs, `scale`, `colors`, `hide`, `weapons`):
- **Bortbytingen:** `troll.glb`, `scale` 0,6, `hide: ["Troll_Club"]`, blekare och gråare hud, stora ljusa ögon
  (`Troll_EyeGlint`). Han ska se fel ut, inte söt: smal och långarmad. GISSNING: skalan ensam kan göra honom för knubbig.
  Då behövs en egen variant i Blender med längre armar.
- **Kyrkkastaren:** `troll.glb`, `hide: ["Troll_Club"]`, en sten i handen. Kastet använder `Spell_Simple_Shoot` med en
  projektil (`travel`).
  - **Finns:** `troll_delar/Troll_Boulder` (sten i höger hand, `parts`). Projektilen i kastet är fortfarande `fx.gd`:s.
- **Den namnlöse byggaren:** `troll_grumse.glb` utan kronan (`hide: ["Troll_Crown"]`), `scale` 1,15, kall grå sten och
  mörkare ögon. Han ska läsas som Bergakungens äldre släkt, inte som kungen själv.
- **Varg** (`varg.glb`) kan bli trollens husdjur i en senare grupp (inte i förslaget).

**Saknas:**
- **Bergsrået:** en kvinnlig gestalt, vacker framifrån och ihålig som ett murket träd bakifrån (folktrons rå). Förslag:
  `haxa.glb` eller `gast.glb` med en grå och mossgrön tint och glöd. **VD:** duger en omfärgad häxa, eller ska
  Drakvalvets kvinnliga figurer byggas om i Blender?
- **Delarna** (förkläde, sjal, lykta, sten) finns i `troll_delar.glb` sedan 2026-10-24.
- **Rumsögonblicken** (`scripts/rooms/`): grottans fyra stilar finns. Berget får kryptans stil med kallare ljus och
  mossa (VAL, som Lunden) tills en egen stil finns.

---

## 14. Ny kod (⚙), samlat

| Vad | Var | För |
|---|---|---|
| Villkoret `self_lowest_hp` för `guard_family` | `CombatSim._when` / livvakten | Bortbytingens Moderns famn |
| Villkoret `school` i `when` | `CombatSim._when` | Kyrkkastarens Klockhat |
| Målen `highest_speed`, `highest_int` | `_trait_targets` | Lockrop, De tysta klockorna |
| Auran `named` som en annan fiende sätter | `_run_trait_effect` | Den namnlöse byggaren och Gråluva |
| `reflect_aura` (en gång) | `_apply_aura` | De bergtagnas ring |
| Svedd hud på alla vid `battle_start` från ett föremål | `RunState.battle_opts` | Nedsänkt kyrkklocka |
| `knows_name` i körningen | `RunState`, `battle_opts` | Sång genom berget |
| `spawn_group_at_goal` | `Grotto` / `RunState.use_object` | Trollbägaren |
| Questtexter och samla-föremål per Realm | `RunState.roll_quest` | §7 |
| `captives` i stället för hjältar | `realms.json`, `Run.rescue_prisoner` | §8 A |
| Följden `toll` (silver −15 %) och gåvan `bell` | `LivingMap`, `WorldEvents` | §9 |
| `free_level` i en världshändelse | `WorldEvents` | §10 |

Utan koden kan Realmen ändå läggas in, med de befintliga sju trollen, mötena och föremålen *Ljusspricka* och
*Trollbägaren* (spill-valet). Allt annat kommer stegvis.

---

## 15. Frågor till VD

1. Namnet: **Trollberget**, Gråberget eller Kungsberget?
2. Kommer berget före eller efter Lunden, och öppnas det av en klarad kapellkörning?
3. Ska de fyra nya trollen byggas (Bortbytingen, Kyrkkastaren, Bergsrået, Den namnlöse byggaren), eller räcker de sju
   som finns för ett första prov?
4. Hör Bergsrået till Trollfolket eller till en egen familj?
5. Lore-tråden: avsändaren lovade Bergakungen att klockorna skulle tystna (kapellet var priset). Stämmer det med den
   större berättelsen?
6. Fångar: bergtagna bybor (A) eller en ny följeslagare, Klockgjutaren Elof (B)?
7. Följden på steg 3: tull på silvret? Gåvan: Klockan hänger igen (kortare sömn och förvirring), eller bärnsten och
   silver?
8. Kampanjkartan: flytta häxan och lägga berget i nordväst?
9. *Sång genom berget*: priset för att lyssna (en Charge per hjälte, eller sömn i nästa strid)?
10. Före hanegället på djup 3: eller ett annat motdrag, eftersom trollstriderna redan är långa?

---

## Källor (folktron)

- [Mountain troll (Wikipedia)](https://en.wikipedia.org/wiki/Mountain_troll)
- [Bergsrå (Wikipedia)](https://en.wikipedia.org/wiki/Bergsr%C3%A5): bergtagning, rättegången 1691
- [Tales of the Trolls (svenska folksagor, 1921)](https://worldoftales.com/European_folktales/Swedish_folktale_18.html)
- [Mytiska väsen – Troll (Studentlitteratur)](https://www.studentlitteratur.se/globalassets/inriver/resources/45811-01_-mytiska-vasen---troll_elevmaterial.pdf): kyrkklockor, bortbytingar
- [I kryptan hittar du jätten Finn (Svenska kyrkan, Lunds domkyrka)](https://www.svenskakyrkan.se/lund/lundsdomkyrka/7-kryptan-och-jatten-finn)
- [Jätten Finn och Lunds domkyrka (Allmogens)](https://allmogens.se/en/tale/jatten-finn-och-lunds-domkyrka/)
- [Fin (legend) (Wikipedia)](https://wikipedia.com/wiki/Fin_(troll))
- [Fin – i nordisk mytologi (Lex.dk)](https://lex.dk/Fin_-_i_nordisk_mytologi)
- Siralim: [Realms (siralimultimate.wiki.gg)](https://siralimultimate.wiki.gg/wiki/Realms),
  [Steam-tråd om Realmens föremål](https://steamcommunity.com/app/1289810/discussions/0/3189112650406353420) och
  `docs/research/siralim.md` §19.1 och §21.2.
- Trollbägaren, guldstolparna, kyrkkast, stål mot troll och kulning: allmän kännedom om svensk folktro (sägnerna finns i
  många varianter, till exempel trollbägare i flera skånska och västgötska kyrkor). Inte kontrollerat mot en enskild källa
  i dag: **GISSNING** i detaljerna.
