# ChatGPT provspel 5: 0.30.42 med balans (2026-10-25)

Fortsatt karriär (frö 101), fyra nedstigningar: kapellet d2 klar, kapellet d3 förlust mot Inkvisitorn, kryptan d3 klar, Trollberget d2 klar med fyra. Underlaget: scratchpad gpt_result5.

**Claudes noteringar:** Inkvisitorn brant och Trollberget vinnbart med fyra stämmer med simuleringen (beslut 57: berget svårare per djup). Nivåklivet stort stämmer med nivåkurvans förslag (cirka 20 %, högst 25 %). XP-felet i Trollberget var textspelets (text_play.gd använde state.depth i stället för enemy_depth), rättat; spelet räknade rätt.

# De edsvurna 0.30.42 – provspel, frö 101

Jag fortsatte den bifogade karriären efter Trollberget. Exakt fyra nya nedstigningar, nummer 6–9, spelades med Arn, Imma, Alva och Lirien. Textspelets riktiga stridslogik och AUTO-makron användes; grafik, ljud och pekgränssnitt bedömdes inte. Inga massimuleringar, nya profiler eller ändringar av spelregler gjordes.

## Hur djupen kändes

Kapellets djup 2 var bekvämt fram till väktaren: vanliga grupper tog 11–12 turer. Djup 3 gav tydligare motstånd, särskilt på andra våningen (22–27 turer), men övergången till Inkvisitorn var mycket brant. Kryptans djup 3 gav bättre spänning genom farliga öppningar och återhämtning. Jag spelade inte om djup 1 i denna version och kan därför inte ge en ren jämförelse mot det. Turantal nedan är textspelets räknare, inte hela rundor per figur.

| Nedstigning | Utfall och känsla |
|---|---|
| 6: Kapellet 2 | Klarat. Smågrupperna lätta; Abbedissans kör krävde målval och uthållighet. |
| 7: Kapellet 3 | Förlust mot Inkvisitorns domstol. Ingen fiende föll. |
| 8: Kryptan 3 | Klarat. Dimmans första natt 40 turer, Nemesis 37 och Den svärtade salen 56. Imma stupade i flera segrar. |
| 9: Trollberget 2, fyra hjältar | Klarat, inklusive elit och väktare. Fem kändes inte nödvändigt för detta lag. |

## Justerade grupper och väktare

| Möte | Turer | Bedömning |
|---|---:|---|
| Grimmens kyrkogård, kapellet 2 | 23 | Motangreppen syntes, men segern var trygg. Alla överlevde; Imma hade 168/251 liv kvar. Snarare en lätt elit än orättvis. |
| Skrivarens avskrifter | – | Möttes inte. Ingen bedömning. |
| Abbedissans kör, kapellet 2 | 60 | Mest intressanta taktiska slutstriden. Jag gav Arn och Lirien kronfokus i makrona. Kronbytena var begripliga; helningarna gjorde avslutningen något seg. Alla överlevde. |
| Inkvisitorns domstol, kapellet 3 | 26 | Förlust, alla stupade. Imma föll T11, Arn T17. Förmannens skydd och hög inkommande skada gav liten känsla av framsteg. Mötet innehöll en Häxmästarinna i elitvariant, som dubblerade öppningens förbannelse. Det är därför ingen ren bedömning av grundgruppen. |
| Tullen vid bron, Trollberget 2 | 64 | Alla överlevde, Imma 218/339 liv. Längre och mer krävande än smågrupperna, men inget tydligt krav på fem. |

Inkvisitorns möte kändes närmast orättvist genom språnget från föregående strider, men det bevisar inte fel balans: tre perkpoäng var oanvända, artefakterna var inte maximalt förbättrade och jag gjorde ingen ommatch. Kistornas råd möttes inte; fördärvet gav i stället Den svärtade Benfursten.

## Trollberget med fyra

Avund vid grytan: seger på 32 turer. Gråluvans stuga: 34, ingen stupad och stora livmarginaler. Där kändes eliten för enkel i förhållande till tanken att locka tillbaka med fem. Vanornas straff tog 47 turer med alla kvar. Hela byn i berget tog 46 och kostade Imma och Lirien, men då var laddningarna låga och jag hade själv ringt kyrkklockan, som gav nästa grupp +15 % styrka. Efter lägereld vann laget Brom på 64 turer.

Det lockar att pröva fler följeslagare, men detta besök skapade inget tydligt behov av en femte. Det är ett enskilt välutrustat lag på nivå 8, med anpassade makron, inte ett mått på vinstchans.

## Nivåtakten och egna val

Lirien gick från 6 till 7 tidigt i första nedstigningen. Alla fyra nådde 8 under kryptbesöket. Väntan mellan nivåerna kändes lång, medan själva klivet var stort: Arn 365 → 492 maxliv, Imma 251 → 339. Jag föredrar mindre, tätare märkbara kliv framför den här trappstegskänslan. Trollbergets XP har dock ett separat textspelsfel nedan, så dess nivåtempo ska inte användas för att bedöma vanliga spelet.

Jag använde nya troféer, ändrade kronfokus, lade in Försvara vid Skuld och senare en villkorskedja för Helig sköld. Immas Vargens språng var ett medvetet byte efter farliga öppningar. Inför kryptan höjdes Immas sköld och Alvas stav från 2 till 3. Ragnhild och Brokk befriades men fick vänta i värdshuset; fyrmannalaget behölls.

## Fel och otydligheter, med skärmtext

1. **Fel XP i textspelsverktyget:** Trollbergets vanliga strid gav ”Erfarenhet: +68 var.” Verktyget räknar på visat djup 2; vanliga spelet räknar på fiendedjup 3 och skulle ge 153. Motsvarande gäller elit och slutstrid. Detta är bekräftat i koden och gäller testverktyget, inte ordinarie XP-koden. Sparningen är inte efterkorrigerad.
2. **Felaktig slutprognos i textspelet:** ”Djupets slut: Kistornas råd” och ”(Djupets väktare: Kistornas råd)” följdes av ”[BOSS] (Den svärtade salen)”. Bossbytet är avsiktligt vid fördärv 4, men prognosen tar inte hänsyn till det.
3. **Vägtext på målrutan:** ”Ni står på g6: Trappan.” följdes av ”Questen är klar: trappan (g6) är öppen. Ingen känd väg dit än.” Vi stod redan där.
4. **Mindre textfel:** ”Kartan: { "realm": "crypt", "from": 2, "to": 3, "why": "neglect" }” visas som rå data. ”Djupets prägel – Bundna: …” visades två gånger på samma kort. Den senare dubbleringen kommer från det medföljande level1-tillägget. Efter att Imma ensam stupat sade hon ”Du får låna min lyckopil tills du är på benen igen.”, vilket gör talare och mottagare otydliga.

## De tre viktigaste förbättringarna

1. **Gör textspelet likvärdigt med ordinarie spelet**, främst XP och slutprognos, så framtida provspel bedömer rätt förlopp.
2. **Granska svårighetssprången i massimuleringen:** Inkvisitorns förman + elitvariant jämfört med föregående grupper, samt Gråluva/Brom mot fyra. Mina möten ger konkreta fall att undersöka, inte belägg för nya exakta balansvärden.
3. **Tydliggör nivåprogressionen:** visa vad nivån faktiskt förbättrar och hur långt nästa kliv är bort; överväg jämnare kliv om fler provspel får samma trappstegskänsla.

Slutsparning: hemma, alla fyra nivå 8, 1 030 silver. Kapellet 2, Kryptan 3 och Trollberget 2 klarade. Kapellet 3 är inte klarat.
