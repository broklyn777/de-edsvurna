# De edsvurna 0.30.40 – två nedstigningar

## Resultat

Följde uttryckligen paketets checkpoint efter Kryptan 4/kapellet 2, inte den separata slutprofilen efter 0.30.39-passet. Två nedstigningar, 12 segrar av 12 strider, inga stupade hjältar. Ingen tredje nedstigning. Frö 73 behölls.

| Plats | Strider | Slutmöte | Turer |
|---|---:|---|---:|
| Kryptan 5 | 5 | Midnattsklockan | 61 |
| Kapellet 3 | 7 | Inkvisitorns domstol | 30 |

## Det viktigaste: nivåomräkningen

Alla fem befintliga hjältars fem stats jämfördes i 0.30.39 och 0.30.40, med exakt samma inprofil och utrustning. Huvudlaget räknades 16→9, Imma 12→8. **Ingen blev svagare i dessa värden, men samtliga värden ökade cirka 24–30 %.** Exempel: Arns maxliv 495→638 och Brokks 842,7→1097,7. Hela tabellen finns i migration-tabell.md och mätvärdena i migration-check.json.

Första eliten var samma grupp med samma fiendeliv (444/283/319) och samma förberedelser som i 0.30.39. Nu blev det 21 turer och fullt slutliv för alla, mot 41 turer och två stupade då. Det är ett konkret tecken på migrationens förstärkning; inte bevis för att hela spelet blivit bättre balanserat.

Efter två nedstigningar och våningsbelöningar hade ingen gått upp en nivå. Arn stod på `nivå 9 (7308/12605 erfarenhet)`. Glesheten märks tydligt. Beräknad slutedsgrad var `Edsvuren av tredje graden`; ingen gradändring eller ny nivåbonus i segerskärmen kunde observeras eftersom ingen nivåhöjning skedde.

## Val, variation och makron

Jag bröt Vaksamheten och Muren i Kryptan och lämnade Uthålligheten, som utlöstes tio gånger. Midnattsklockan tog 61 turer mot tidigare 105, men sigill, styrka och vissa möten skiljde sig, så det är ingen ren jämförelse. Fortfarande ett långt möte med fullt slutliv.

Bundna på Gravens skyddare gav ett begripligt fokusval. Livvaktsprägeln Botgörarens ed på Förbannelsens kor gav en konkret Eira-kedja: välj Livvakt, märk om samma mål saknar märkning, annars anfall den. Botgöraren föll först, T3. Sorgens vrede och inkräktare observerades inte.

Kapellets två obligatoriska eliter var olika: Abbedissans mässa och Grimmens vakt. Däremot mötte jag Kyrkogrimmen två gånger på nedstigningen med olika följen; samma anti-Grimmen-plan fungerade igen. Olika grupper behöver inte alltid innebära olika lösningar.

Jag bytte Brokk mot nyrekryterade Tove, som kom på nivå 9. Han fick Den rivna slöjan och stövlar med Vindsteg. I Grimmens vakt gav Spegelhand 164 skada på två utlösningar. Tryckpunkt fick däremot aldrig användas under högre skyddsregler och togs bort. Mot Inkvisitorn behöll jag provokation och använde egen rening: Stilla vatten T14 och T25, ingen Dom laddades. Det gav ett annat svar än Brokks rena försvarsplan i förra passet. Före/efter-makron och avsikter är sparade.

## Det som bar passet och det som var segt

Det mest spelmässigt intressanta var att bygga Tove för en annan sorts beskydd och se rening svara på en väktarmekanik. Klockrepet gav också ett verkligt kartval: åtta turers extra strid för att avslöja alla grupper, sedan kunde jag gå direkt till eliterna.

En återkommande friktion: vid återpassage på glasfönsterrutan öppnades samma val igen efter tidigare avstående: `1) DRA UNDAN` / `2) LÅT DEN HÄNGA`. Klockrepet hade redan löst informationsbehovet. Detta är observerat i textläget, inte ett säkert nytt mobilfel.

Timglasets rättade text var däremot tydlig: `Sanden ligger stilla. Det finns ingen elitgrupp kvar på våningen som ni inte redan vet om.`

Inga säkra nya fel i stridskärnan hittades. Statspåslaget kan vara en avsiktlig följd av att konvertera uppåt till nästa hela nivå, men är viktigt att skilja från löftet om samma svårighet. Upprepad helning med samma fiendeförmåga och Benskrivarens tak fick inget ordentligt stridstest.

## De tre viktigaste förbättringarna härnäst

1. Bestäm och förklara migrationspåslaget. Om äldre profiler ska behålla ungefär samma styrka behöver omräkningen bevara den mer exakt; om förstärkningen är avsiktlig bör spelaren få veta det. Utvärdera nykarriärbalans separat från migrerade profiler.
2. Utvärdera rytmen mellan nivåer och edsgrader. Här gav två hela nedstigningar ingen nivå. Se till att lagbygge och andra delmål bär tiden mellan de större hoppen; korta inte kurvan enbart på grund av detta enstaka prov.
3. Minska återkommande kartdialoger utan nytt beslut. Överväg att låta ett tidigare avböjt val öppnas på begäran vid återpassage, i stället för att automatiskt avbryta färden igen. Behåll informationsval som Klockrepet där uppoffring och nytta var tydliga.

## Begränsningar och slutläge

Alla strider AUTO. Ingen utdelad XP, inga ändrade balansvärden, inga omslagna slumpfrön och inga återkörningar. Inga avbrott mellan före/efter-snapshots upptäcktes med det nya sparskalet.

Endast level1_play.gd fick samma rena kortvisningstillägg som förra passet: native-gränssnittets redan synliga twist/intruder/second_warning. Två read-only diagnosskript jämförde styrka och läste slutprofilens plats-/edsgradsvärden. Kärnkod och data är bytekontrollerade mot zippen. Grafik, låsplatsens visuella presentation och den fullständiga testsviten kördes inte. Textlägret emulerar fortfarande inte alla nya NY/ÄGD/SÄLLSYNT-detaljer.

Spelade grupper hade 2–4 fiender; femgränsen har inte belastningstestats med större uppställningar. Femte platsen förblev låst: ett vanligt försök att välja fyra följeslagare gav fortfarande bara fyra personer totalt. Profilens låstext är `Besegra Benfursten och Den fallne biskopen på djup 4`. Kapellet 4 är inte klarat i denna förgrening.

Sparat hemma med Arn, Tove, Alva och Eira på nivå 9, 369 silver och två oanvända perk-poäng. Kryptan 5 och kapellet 3 klarade. Veckobudgeten kan inte avläsas av agenten; ingen aktuell procent påstås.

# Nivåmigrering: samma inprofil och utrustning

| Hjälte | Nivå före → efter | Egenskap | Före | Efter | Förändring |
|---|---|---|---:|---:|---:|
| paladin | 16 → 9 | attack | 57.6974 | 74.2454 | +28.7 % |
| paladin | 16 → 9 | defense | 36.512 | 47.5699 | +30.3 % |
| paladin | 16 → 9 | health | 495 | 638 | +28.9 % |
| paladin | 16 → 9 | intelligence | 38 | 48.1 | +26.6 % |
| paladin | 16 → 9 | speed | 55 | 71 | +29.1 % |
| brokk | 16 → 9 | attack | 42.9 | 55.3 | +28.9 % |
| brokk | 16 → 9 | defense | 35.8444 | 45.789 | +27.7 % |
| brokk | 16 → 9 | health | 842.7 | 1097.7 | +30.3 % |
| brokk | 16 → 9 | intelligence | 42.4 | 54.6 | +28.8 % |
| brokk | 16 → 9 | speed | 28 | 35 | +25.0 % |
| alva | 16 → 9 | attack | 26 | 32.9 | +26.5 % |
| alva | 16 → 9 | defense | 13.8 | 17.7 | +28.3 % |
| alva | 16 → 9 | health | 385 | 496.2 | +28.9 % |
| alva | 16 → 9 | intelligence | 52.0065 | 67.7799 | +30.3 % |
| alva | 16 → 9 | speed | 61 | 78 | +27.9 % |
| eira | 16 → 9 | attack | 53.064 | 68.3936 | +28.9 % |
| eira | 16 → 9 | defense | 8 | 10.1 | +26.2 % |
| eira | 16 → 9 | health | 357.5 | 460.8 | +28.9 % |
| eira | 16 → 9 | intelligence | 49.5 | 63.8 | +28.9 % |
| eira | 16 → 9 | speed | 99.2 | 129.2 | +30.2 % |
| imma | 12 → 8 | attack | 45.6 | 58 | +27.2 % |
| imma | 12 → 8 | defense | 5.8 | 7.2 | +24.1 % |
| imma | 12 → 8 | health | 266.6 | 339 | +27.2 % |
| imma | 12 → 8 | intelligence | 34.4 | 43.7 | +27.0 % |
| imma | 12 → 8 | speed | 98 | 126 | +28.6 % |
