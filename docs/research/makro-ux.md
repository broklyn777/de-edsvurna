# Makron som går att lära sig och är sköna på telefonen

Research 2026-10-24 (grenen `research-makro-ux`). Underlag, inte beslut. Säkerhet som i `siralim_makron.md`:
**Bekräftat** (officiell text, patchnot, utvecklare), **Troligt** (flera spelare/guider säger samma sak),
**Minne** (allmänt känt om spelet men inte belagt med källa här), **Gissning** (vår slutsats).

Läs först: `docs/ideer/siralim_makron.md` (Siralims regler), `docs/research/siralim.md` §9–9b,
`docs/ideer/chat-makron-research.md` (ChatGPT:s jobb G, "Spara som order"). Det här dokumentet upprepar dem inte.

## 0. Var vi står (läst i koden, test-0.30)

- `MacroRunner.decide()` prövar raderna uppifrån; en rad vars handling inte går att utföra räknas som omatchad och
  hamnar i `skipped` med orsak ("Rad 2 hoppades över: Helande ljus har inga Charges kvar"). **Rader vars villkor inte
  stämde syns inte alls i loggen** – bara att något matchade, eller "inget makro passade". Det är den viktigaste luckan
  för felsökning.
- Inget makro passade → hjälten väntar (Siralims beteende, `siralim.md` §9b). Startmakrona har ingen garanterad sista
  rad: Paladinens sista rad är "någon fiende är inte immun → anfall", som bara missar om alla fiender är immuna
  samtidigt (sällsynt, men inget hindrar det) eller om Paladinen är Tystad/Hånad på ett sätt som spärrar anfallet. Följeslagarnas startrader är
  bara de två första (`Run.starter_lines`), så en ny profils hjältar kan stå stilla.
- Radeditorn (0.30.24): fyra kolumner, sökfält, villkorsgrupper, förhandsvisning av radens text (`_update_preview`).
  Förhandsvisningen säger vad raden *betyder*, inte vad den *skulle göra just nu*.
- Undervisning finns redan i tre former: `FIRST_LINE` i ett tomt makro (Gorms uppdrag), `macro_hint` när en hjälte
  ansluter (Alva: "hela den som har lågt liv"), och "Spara som order" (guldknapp i 9 s efter ett manuellt val som
  makrot inte hade gjort).
- **Testarens fråga om "lägst Defense" med en fiende:** `_extreme()` jämför bara mot *andra levande* i gruppen. Med en
  fiende kvar stämmer "har lägst Defense" alltid för den. Lika värden räknas som lägst för alla (den första i
  platsordning blir "den"). Defense räknas med Försvara/Provocera just nu (`defense_now()`). Ingen bugg, men spelaren
  kunde inte se det – ett argument för förslag 1 nedan.

## 1. Fynd per spel

### Final Fantasy XII (2006) och The Zodiac Age (2017)

| Fynd | Säkerhet |
|---|---|
| Gambits uppstod för att realtidsstrid med vanliga menyer blev för snabbt och svårt; idén lånades från monster-AI i FF IV. En utvecklare beskriver glädjen som att fälla en svår fiende med finjusterade gambits. | Bekräftat (PlayStation Blog) |
| Mål + handling i en lista, viktigast överst; dra om ordningen. Spelare ger nybörjarrådet "närmaste fiende → anfall" och "allierad HP < 30 % → Cure/Potion". | Troligt (guider) |
| Upp till 12 gambits per figur. Man börjar med några platser och köper fler på License Board – **platserna är progression**, inte bara villkoren. | Troligt (StrategyWiki, guider) |
| Villkoren och handlingarna är föremål: en grunduppsättning gratis, resten köps i butiker (den största i första staden) eller hittas. I originalet låstes vissa upp med berättelsen; i Zodiac Age säljs allt efter ett tidigt skede. | Troligt (guider, Steam) |
| Handledningen kommer efter en dryg timme: Penelo nämner gambits, Balthier förklarar dem; först därefter kan man redigera. | Troligt (guider) |
| Varje gambit kan slås PÅ/AV med en knapp utan att tas bort; alla gambits kan stängas av mitt i striden, då blir det vanlig menystrid. | Troligt (guider) / Minne (per rad) |
| Färgade linjer i striden visar vem som siktar på vem (blått för egna handlingar, rött för fienders). | Minne |
| Zodiac Age 2020 (PS4/PC): **tre sparade gambit-uppsättningar** att byta mellan direkt, t.ex. en för vanliga strider och en för bossen. | Bekräftat (patchnot) |
| Kritiken: "spelet spelar sig självt". Kotaku vänder på det – man lär spelet att spela sig självt – och nämner att grindandet blir automatiskt. Bossar som kontrar vanliga gambits tvingar fram omtag. | Troligt (Kotaku) |

**För oss:** tre saker att ta efter: (a) PÅ/AV per rad, (b) sparade uppsättningar (vi har flera makron per hjälte –
det som fattas är snabbbyte *i striden*), (c) att villkoren låses upp efter hand som ett skäl att gå ut och hitta saker.
Att platserna är progression passar sämre: Siralims 20 rader från start är redan vår grund.

### Dragon Age: Origins (2009), Dragon Age II, Inquisition (2014), The Veilguard (2024)

| Fynd | Säkerhet |
|---|---|
| Origins: taktikplatser (villkor → handling) som växer med nivån och färdigheten Combat Tactics; spelare säger att nivåerna räcker. | Troligt (Steam) |
| **Förinställningar** (Healer, Supporter m.fl.) och ett **Behavior**-val som avgör vad figuren gör när ingen taktik passar (t.ex. anfall närmaste). Spelare påpekar att man då inte behöver slösa en plats på anfallsraden. | Troligt (Steam) |
| Förinställningarna kritiseras: Wynnes Healer-förval spammar helningar så fort de är klara; spelare lägger in egna trösklar i stället. | Troligt (Steam) |
| Ordningen biter nybörjare: en dryckesregel under en anfallsregel slår aldrig till. | Troligt (forum) |
| Inquisition ersatte listan med per förmåga **Föredragen / Normal / Använd inte**, plus trösklar för mana/uthållighet och när man dricker. Fansen saknade djupet. | Troligt (forum, Prima) |
| The Veilguard tog bort både taktikvyn och kontrollen över följeslagarna; regissören sa att full kontroll "inte tillförde" och var tung ovanpå den egna figuren. Kritik: det är ett av seriens mest särpräglade inslag som försvann. | Bekräftat (intervju via TechRadar/PSLS) / Troligt (kritiken) |

**För oss:** en *garanterad standardhandling* utanför listan (Origins' Behavior) löser "inget makro passade" utan att
spelaren behöver förstå det. Inquisitions förenkling visar en mellanväg för nybörjare (per förmåga: ofta/ibland/aldrig),
men också att erfarna spelare uppfattar den som förlust. Ledstjärnan ("kombinera") talar för att behålla raderna och
lägga förenklingen *ovanpå* som mallar.

### Pillars of Eternity II: Deadfire (2018)

| Fynd | Säkerhet |
|---|---|
| Fliken Behaviors: "+" skapar ett eget beteende; villkor, handling och en **timer** så att en buff inte spammas. | Troligt (Steam) |
| Färdiga beteenden per klass finns, men erfarna spelare kallar dem dåliga och bygger egna från grunden. | Troligt (Steam) |
| Egna AI-uppsättningar sparas som filer och delas mellan spelare; en mod lägger till fler villkor. | Troligt (forum, mod) |
| Ett tomt eget beteende går inte – man behöver en platshållare. | Troligt (Steam) |

**För oss:** mallar måste vara *bra* (annars lär de ut fel och skapar misstro). Delning som fil var populär, men Siralim
tog bort import/export för att spelare förstörde sparfiler (`siralim.md` §9b) – en kort kod som valideras är säkrare.

### Siralim 3 / Ultimate

Se `siralim_makron.md`. Nytt i den här genomgången: en Steam-tråd (2023) klagar på att import/export togs bort och att
förmågor som ges vid stridens start inte gick att lägga in (åtgärdat i 2.0). Ingen officiell handledning för makron
hittades; spelarna lär sig i forumtrådar. Kärnkritiken (redan i jobb G): bra för vanliga strider, "håll E"-utbrändhet,
obegripligt när en rad inte slår till. **Troligt.**

### Unicorn Overlord (Vanillaware, 2024)

| Fynd | Säkerhet |
|---|---|
| Varje enhet har en lista med färdigheter; varje färdighet kan få **högst två villkor**, båda måste stämma; den översta som passar används. Rådet: smalast villkor överst. | Troligt (guider) |
| Utan villkor används en färdighet alltid – en helning under ett villkorslöst anfall används aldrig. Guiderna lär ut det med just det exemplet. | Troligt (guider) |
| **Optimize** sätter en rekommenderad uppställning med ett tryck. | Troligt (RPG Site) |
| **Förhandsvisning före striden:** man ser fiendens klasser och väntad skada, kan gå in i Organize och ändra taktiken, och ser den nya väntade skadan när man går tillbaka. | Troligt (guide, förhandsvisningar) |
| Recensenter (IGN 9/10, CGM 9/10): unikt och djupt men lätt att förstå. Checkpoint: blir mycket komplicerat när armén växer. | Troligt (recensioner) |
| Spelare rapporterar att de två villkoren inte alltid prövas i ordning. | Okänt (en guide) |

**För oss:** det starkaste mönstret är **slingan förhandsvisa → ändra → se skillnaden** innan något står på spel. Två
villkor per färdighet (inte kedjor) är också lättare att läsa än vår "Pröva nästa rad". Optimize motsvarar mallar.

### Gladiabots och Gratuitous Space Battles

| Fynd | Säkerhet |
|---|---|
| Gladiabots: visuell redigerare (om detta, gör det) med interaktiv handledning; en bot fungerar efter några klick, men att vinna kräver fler villkor. Recensenter: tillgänglig först, krävande sedan. **Sandlåda** där man styr båda lagen för att pröva. | Troligt (Steam-sida, recensioner) |
| GSB:s skapare (2025) kallar sitt gamla ordersystem en röra: ordrarna "samarbetade" på ett sätt ingen kunde se. Det nya: färgkodade kategorier, prioritetssiffror och en enda "tie-breaker" – och uttryckligen inga spelarskrivna villkor, för att det blir arbete. | Bekräftat (utvecklarens blogg) |

**För oss:** GSB är en varning: när man inte ser *varför* en enhet valde ett mål slutar spelaren lita på systemet.
"Tie-breaker" motsvarar vår regel "den första i platsordning" – den bör synas.

### Persona och mobila auto-strider

| Fynd | Säkerhet |
|---|---|
| Persona 5: taktiker per följeslagare (Act Freely, Conserve SP, Heal/Support, Direct Commands) ändras utanför striden eller via Order-menyn i striden. P3 Reload har både direktkontroll och taktiker. | Troligt (Megaten-wikin) |
| Mobila spel: auto-strid uppskattas som bekvämlighet för korta pass och för farm, men kritiseras när strider avgörs av vilka enheter man har, inte hur man använder dem. Förslag från spelare: auto ska vara till för strider man *vet* att man vinner. | Troligt (forum, recensioner) |

**För oss:** Personas grova lägen är en bra *första* nivå innan rader (jämför jobb G:s "startlägen för Charges").
Mobilkritiken stämmer med vår ledstjärna: automatiken ska vara spelarens eget bygge, inte en knapp som spelar åt en.

## 2. Mönster tvärs över spelen

1. **Förklara varför, även när inget hände.** GSB och Siralim får kritik för ogenomskinlighet; UO och Gladiabots
   beröms för att experimentet syns. (Gissning, bred grund.)
2. **En garanterad standardhandling.** DA:O:s Behavior och FFXII:s "närmaste fiende → anfall" gör att en figur aldrig
   står stilla av misstag.
3. **Förhandsvisa före risk.** UO:s förhandsvisning och Gladiabots sandlåda.
4. **Lära ut ett begrepp i taget, med ett exempel som visar varför ordningen spelar roll** (helning under anfall).
5. **Bra mallar, sedan egna justeringar.** Dåliga förval (PoE II, Wynne) skadar förtroendet mer än inga.
6. **Snabbyte mellan uppsättningar** (FFXII TZA 2020, Persona i striden).
7. **Delning** har varit populärt men farligt som rå fil.

## 3. Förslag, rangordnade efter värde/insats för oss

Insats: S = en kväll, M = några dagar, L = en version. Värde bedömt mot ledstjärnan och provspelet.

| # | Förslag | Värde | Insats |
|---|---|---|---|
| 1 | Radernas "varför inte" i makrologgen | Högt | S |
| 2 | Garanterad sista rad (standardhandling) | Högt | S |
| 3 | Förhandsvisning "Just nu: …" i radeditorn och makrolistan | Högt | M |
| 4 | PÅ/AV per rad | Medel | S |
| 5 | Sökfältet syns: fokus och exempel | Medel | S |
| 6 | Mallar per roll, färdiga och bra | Medel–högt | M |
| 7 | "Spara som order" längre och med förklaring | Medel | S |
| 8 | Ett begrepp i taget: villkorsgrupper som låses upp | Medel | M |
| 9 | Makrobyte i striden (uppsättning för boss) | Medel | S–M |
| 10 | Provstrid från editorn (Övningsgårdens sandlåda) | Medel | M |
| 11 | Två villkor på en rad i stället för kedjan | Medel | L |
| 12 | Dela makro som kort kod | Lågt nu | M |

### 1. Radernas "varför inte" i makrologgen (S)

`decide()` samlar redan `skipped` för rader som matchade men inte kunde utföras. Utöka med **rader vars villkor inte
stämde**, kort: "Rad 1: ingen allierad under 30 % liv (lägst: Brokk 64 %)". Visas när man öppnar loggen, inte i de fyra
synliga raderna. Vid "inget makro passade" visas listan direkt, med raden närmast att stämma först. Det besvarar
testarens fråga om lägst Defense utan att någon behöver läsa koden ("Rad 3: den enda fienden har lägst Defense →
matchar"). **Varför först:** billigast, och allt annat (mallar, order) blir begripligare när felen går att se.

### 2. Garanterad sista rad (S)

Som DA:O:s Behavior: en fast, gråmarkerad rad under de 20 som inte räknas mot gränsen och inte går att ta bort, bara
ändra mellan **Anfall den med lägst liv** (förval), **Försvara** och **Vänta på mig**. "Vänta på mig" är dagens beteende
och Siralims; förvalet gör att nybörjaren aldrig ser en hjälte stå still. Loggen säger "standardraden". Avvikelse från
Siralim (där väntar man) – ska tas upp med VD; ett alternativ som ligger närmare originalet är att bara lägga
`FIRST_LINE` sist i alla *startmakron* och i `starter_lines`.

### 3. Förhandsvisning "Just nu: …" (M)

UO:s starkaste drag. När radeditorn öppnas ovanpå en pausad strid (`embedded`) kör vi `match_line()` mot den riktiga
striden och skriver under förhandsvisningen: "Just nu: stämmer för Benväktare 2 (lägst liv, 18 %)" eller "Just nu:
stämmer inte (ingen fiende är förgiftad)". I makrolistan får varje rad en liten markering: ✓ den rad som skulle väljas,
– rader som inte stämmer. Utanför striden används ett typiskt möte från valt Realm/djup (eller Övningsgårdens
senaste), tydligt märkt "i ett provmöte". Ren logik, `sim` finns redan i striden.

### 4. PÅ/AV per rad (S)

FFXII:s knapp. En rad som stängs av ligger kvar men prövas inte (`"off": true` i raden, `decide()` hoppar över).
Gör det billigt att experimentera på telefonen, där det är jobbigt att bygga om en rad. Loggen: "Rad 4 avstängd".

### 5. Sökfältet syns (S)

Testarna missar sökfältet. Förslag: en ritad lupp framför platshållaren, ett
par **förslagschips** under fältet som fyller i sökningen med ett tryck ("liv", "förgiftad", "Charges", "lägst"), och
att fältet får fokus när villkorskolumnen har fler än ~30 val. På telefonen öppnar fokus tangentbordet och döljer halva
skärmen – chipsen löser de vanligaste fallen utan tangentbord.

### 6. Mallar per roll (M)

"Ny från mall": Beskyddare (provocera när någon är låg, försvara när själv låg), Helare (hela under 50 %, rena debuffar),
Skytt (märk omärkta, anfall lägst liv), Besvärjare (yta när tre lever, annars lägst liv). Byggs ur hjältens egna
förmågor; mallarna testas av botarna (`combat_bot.gd`) så att de är minst lika bra som startmakrona – PoE II:s läxa.
Mallen är en vanlig lista som spelaren sedan ändrar, inte ett låst läge (Inquisitions misstag).

### 7. "Spara som order" längre och med förklaring (S)

Provspelet 0.30.14: 9 sekunder kan vara kort när man läser loggen. Låt knappen stå kvar tills nästa hjälte agerat två
gånger, och visa raden den skulle lägga till ("Spara: om någon allierad < 50 % → Helande ljus på den"). Det är vår
egen version av "förslag ur observerat spel" och den som ligger närmast ledstjärnan.

### 8. Ett begrepp i taget (M)

Som FFXII:s köpta gambits men utan butik: villkorsgrupperna (0.30.24) öppnas efter hand – Liv från start, Status när man
först möter en status (redan en hjälpruta), Egenskaper när man fått sin första trofé, Tidslinje/Charges när man har tre
hjältar. Varje upplåsning visar ett exempel med rätt ordning (helning ovanför anfall, UO:s exempel). Erfarna kan slå på
"alla villkor" i inställningarna. Risk: Siralim visar allt från start; avvikelsen bör vägas med VD.

### 9. Makrobyte i striden (S–M)

FFXII TZA och Persona: byt makro för en hjälte i striden med ett tryck (långt tryck på ramen → lista), utan att öppna
redigeraren. Gör "ett makro för vanliga strider, ett för bossen" naturligt – och är en plats där kombinationer upptäcks.

### 10. Provstrid från editorn (M)

Gladiabots sandlåda: knappen "Pröva" i makroskärmen startar Övningsgårdens strid mot senaste mötet med ALLA AUTO och 2×,
och visar loggen öppen. Mycket finns redan (`new_practice()`, `--battle-macros`).

### 11. Två villkor på en rad (L)

UO har högst två villkor per färdighet och det läses som en mening. Vår "Pröva nästa rad" gör samma sak men ser ut som
två rader och förvirrar (Siralims spelare var osäkra på om kedjan minns figuren, §9b). Ett "och …" i radeditorn som
sparar en kedja under huven vore läsbarare. Stor ändring av editorn; vänta tills 1–3 har prövats.

### 12. Dela makro som kod (M)

En kort text (base64 av raderna) som valideras mot datan vid inklistring – aldrig en fil i sparmappen (Siralims läxa).
Värde först när det finns fler spelare.

## 4. Rekommenderad ordning

1, 2 och 5 i en liten version (allt S, löser provspelets tre klagomål). Sedan 3 (det som mest liknar UO, det spel som
beröms mest just nu) och 4. Mallar (6) när botarna har mätt dem. 8 och 11 diskuteras med VD eftersom de avviker från
Siralim.

## Källor

- [PlayStation Blog: How FFXII's Gambit created one of the most distinct RPGs](https://blog.playstation.com/?p=192698)
- [Square Enix: FFXII TZA PC/PS4 update (tre gambit-uppsättningar)](https://www.square-enix-games.com/news/final-fantasy-xii-zodiac-age-pc-ps4-update)
- [Gematsu: job reset och fler gambit-uppsättningar](https://gematsu.com/2020/04/final-fantasy-xii-the-zodiac-age-for-ps4-pc-updated-with-job-reset-function-additional-gambit-sets)
- [Kotaku: Tips for playing FFXII TZA](https://kotaku.com/tips-for-playing-final-fantasy-xii-the-zodiac-age-1796816046)
- [Twinfinite: How to get more gambits](https://twinfinite.net/?p=287225), [Changing and setting gambits](https://twinfinite.net/?p=286811)
- [StrategyWiki: FFXII Gambits](https://strategywiki.org/wiki/Final_Fantasy_XII/Gambits) (sammanfattning i sökresultat; sidan gick inte att hämta)
- [Steam: FFXII TZA gambit-butiker](https://steamcommunity.com/app/595520/discussions/0/2828702373010361549)
- [Steam: DA:O tactics och Combat Tactics](https://steamcommunity.com/app/47810/discussions/0/1319961868324922289)
- [Steam: DA Inquisition tactics, Preferred](https://steamcommunity.com/app/1222690/discussions/0/598512477964095800)
- [Giant Bomb: Inquisition hints](https://www.giantbomb.com/forums/dragon-age-inquisition-7175/inquisition-hints-tips-tricks-1500141/)
- [AnandTech: Dragon Age tips (ordningen)](https://forums.anandtech.com/threads/dragon-age-tips.2033146/post-29094979)
- [TechRadar: Veilguard tar bort taktikkameran](https://www.techradar.com/gaming/consoles-pc/dragon-age-the-veilguard-has-removed-the-tactical-camera-and-wont-let-you-control-your-companions)
- [PlayStation LifeStyle: Veilguard, kontroll var "detrimental"](https://www.playstationlifestyle.net/2024/08/09/dragon-age-the-veilguard-companions-controlled-detrimental/)
- [Inverse: Veilguard och Origins](https://inverse.com/gaming/dragon-age-veilguard-gameplay-reveal-combat-origins)
- [Obsidian-forum: Party AI tips (Deadfire)](https://forums.obsidian.net/topic/99663-lets-share-tips-on-the-party-ai-system)
- [Steam: Deadfire custom AI](https://steamcommunity.com/app/560130/discussions/0/1693795812309628406)
- [Mod: More Custom AI Conditions](https://www.gamepressure.com/download/pillars-of-eternity-ii-deadfire-more-custom-ai-conditions-v400-m/z510a03)
- [Steam: Siralim Ultimate, import/export borttaget](https://steamcommunity.com/app/1289810/discussions/0/7155698768542809243)
- [RPG Site: Unicorn Overlord tactics, priority, Optimize](https://www.rpgsite.net/news/15481-unicorn-overlord-highlights-tactics-priority-and-battle-stages-along-with-several-new-non-human-allies)
- [Prima Games: UO tactics and conditions](https://primagames.com/gaming/unicorn-overlord-tactics-and-conditions-explained)
- [GamesFuze: UO best tactics (förhandsvisning och Organize)](https://gamesfuze.com/guides/unicorn-overlord-best-tactics-guide-how-to-do-more-damage/)
- [Checkpoint Gaming: UO review](https://checkpointgaming.net/reviews/2024/03/unicorn-overlord-review-another-win-for-vanillaware/)
- [GameSpot: UO review roundup](https://www.gamespot.com/articles/review-roundup-for-unicorn-overlord/1100-6521701/)
- [Positech: Designing the orders system for Ridiculous Space Battles](https://www.positech.co.uk/cliffsblog/2025/08/15/designing-the-orders-system-for-ridiculous-space-battles/)
- [GamingOnLinux: Gladiabots](https://www.gamingonlinux.com/2018/10/ai-combat-arena-gladiabots-has-enabled-linux-support-on-steam/), [itch.io: Gladiabots](https://gfx47.itch.io/gladiabots)
- [Megaten Wiki: Tactics (Persona)](https://megatenwiki.com/wiki/Tactics)
- [TouchArcade: auto battle](https://toucharcade.com/community/threads/auto-battle.285840/)
