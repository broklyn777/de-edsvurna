# De edsvurna 0.30.41 – ny karriär och ett Trollbergsförsök

Ny karriär från nivå 1, frö **101**, Godot 4.7.2 och spelets riktiga CombatSim/MacroRunner. Fyra ordinarie nedstigningar enligt prompten, därefter användarens extra Trollbergsuppdrag. Totalt **31 strider: 30 segrar, en förlust**. Ingen strid spelades om och ingen äldre karriär användes.

## Början och nivåtakten

Arn gick **1→5 under första nedstigningen**. Nivå 2 kom efter första striden, 3 efter tredje och 4 efter femte. Nivå 6 kom i passets nionde strid, nivå 7 i den sjuttonde. Takten blev alltså märkbart glesare, men första riktiga bromsen sammanföll också med en förlust på djup 3.

De större stegen kändes som belöningar: Arns maxliv **198→261 vid nivå 6**, sedan **261→365 vid nivå 7**. Spelets LevelJump gav exempelvis vid nivå 7 ”Rättfärdigt slag 44 → 63 skada” i sin referensberäkning; det är inte garanterad skada på varje fiende. **Första och andra edsgraden** kom vid 3 respektive 6. Immas replik till första graden var: ”Första graden? Då syr jag ett märke på din mantel. Snett, men det syns.”

Nivåbelöningar och edsgrader återgavs med spelets egna funktioner i textadaptern. Den grafiska segerskärmen provades inte. Arn fick ingen ny nivå under Trollbergsbesöket: vanliga strider på djup 1 gav 17 XP mot 2 613 till nivå 8. Återbesök på lågt djup gav därför ganska lite nivåprogression.

| Nedstigning | Resultat | Elit/Nemesis, turer | Väktare/boss, turer |
|---|---|---|---|
| Kryptan 1 | 8 segrar; Imma stupade hos bossen | Väckaren 19, Benskrivaren 12 | Benfursten 39 |
| Kryptan 2 | 5 segrar | Kolossen 33 | Midnattsklockan 45 |
| Kryptan 3 | 1 seger, 1 förlust; Alva befriad | Dimmans första natt: förlust 35 | Inte nådd |
| Kapellet 1 | 7 segrar; Lirien befriad | Förmannen/Nemesis 16, Två familjer 19, Abbedissan 10 | Biskopen 24 |

Dessutom vann vi en vanlig grupp med sällsynt Benjägare på 11 turer i Kryptan 1. Turer är motorns handlingsräknare, inte kompletta lagrundor.

## Det som fungerade – och det som blev segt

Roligast var konkreta ändringar: prästfokus hindrade Gravpakt/Likpredikan, Imma fick sköld och en tankroll, Alva gav uthållighet och Trollbergets egenskaper krävde nya villkor. Kolossen var ett riktigt nära möte: Arn slutade på **8/198 liv**. Nemesis på djup 3 slog ut laget; Imma dog innan Alvas första handling. Det var inte ett problem som enbart en annan helningsgräns kunde lösa.

Sigillen gav ett begripligt riskval. Jag bröt Vaksamhet och Mur och lämnade **Uthållighet**. Midnattsklockan fick tolv registrerade sigillutlösningar och tog 45 turer. **Likpredikan** syntes på Prästens nisch; våra befintliga prästregler räckte, så den krävde ingen helt ny plan.

Kartans bästa val var kyrkbänken som barrikaderade en grupp och gardin→Klockrep som bytte en extra strid mot information. Tomma söksteg, blockerade grannrutor och omvägar till eldar tog mer plats än jag önskade. Trollberget gav Stenraset två gånger i följd, båda 11 turer, och Kittelgropen två gånger. De obligatoriska vakterna var olika; upprepningen kom mellan vanlig grupp och questvakt.

Kapellet 1 spelades med nivå 6–7 och är därför **inte ett rent balansprov av ett färskt låglevellag**.

## Trollberget: ett enda inträde med fyra

Vi gick in med **Arn 7, Imma 7, Alva 6 och Lirien 6** efter att kapellet 1 klarats. Resultatet blev **hela djup 1 klarat: nio segrar, inga dödsfall**.

| Typ | Utfall |
|---|---|
| Sju vanliga grupper | Alla vunna, 8–27 turer |
| Eliten Bron | Seger, 28 turer; alla kvar på högt liv |
| Bergakungens sal | Seger, 49 turer |

Efter bossen: **Arn 352/365, Imma 251/251, Alva 156/203, Lirien 180/180**. Alva nådde därefter nivå 7. Bossen hade 621 liv och fem fiender var med i gruppen. Separat kontroll av den verkliga sparningen visade `full_party=5` och skalningsstorlek 5 trots våra fyra hjältar; textverktyget hade alltså inte råkat använda fyrmannakonfiguration.

Kampanjtexten är **”Byggt för fem i sällskapet – här får fyra stryk”**. Den överdrev faran för just vårt lag. Det kändes inte orättvist; snarare gav försöket inget tydligt behov av en femte. Bossen blev lång men slutläget var tryggt. Jag lockas mer av nästa djup och nya mekaniker än av att återvända hit enbart för den femte platsen.

Detta är **ett försök**, inte underlag för hur ofta fyra vinner generellt. Vi hade nivåfördel: vanliga fiender visades på 2–5 och eliten/bossen på 5. Vi använde också flera fungerande kombinationer och anpassade efter korten: Avund först, förmågor mot Trollhud, inget vanligt nödförsvar medan Klubban levde, och avstängd provokation medan Brom levde. Kombinationen Vaggvisa+Blöder var däremot dålig eftersom blödningen väckte Brom.

## Fel och tre viktigaste förbättringar

1. **Gör Trollbergsvarningen beroende av faktisk risk, och kontrollera styrkan efter femfiendetaket.** Vårt fyrmannalag vann även elit och boss med marginal. Utgå inte från att antalet fyra ensamt innebär nederlag.
2. **Rätta och förklara makrokedjorna.** Liriens startmakro visade ”Om någon allierad har liv < 50 % → pröva nästa rad” direkt före reservanfallet; den ursprungliga Vaggvisa-raden hade klippts bort av den gemensamma startfunktionen. Alvas ”saknar Läkning → under 80 %” kunde binda fullfriske Arn och missa skadad Imma. Jag vände den till skadad först, därefter kontroll av Läkning. Det korrigerar min tidigare rekommendation om ordningen. Detaljer och källställen finns i `fel-och-begransningar.md`.
3. **Minska kartans tomgång och närliggande upprepningar.** Information genom föremål var bra, men elitsökningen och återvägen till en eld blev lång. Undvik gärna att en vanlig grupp och nästa questvakt ger exakt samma möte.

Slutsparning: hemma, **Arn/Imma/Alva 7, Lirien 6**, 290 silver, en oanvänd perkpoäng. Kryptan 2, kapellet 1 och Trollberget 1 klara. Femte platsen är fortfarande låst bakom Benfursten och biskopen på djup 4. Inga balansvärden ändrades. Alla beslut, felaktiga antaganden, makroversioner och stridsloggar finns med.


# Fel, svaga punkter och begränsningar

## 1. Liriens startkedja klipps av – observerat och källkontrollerat

Efter att hans förslag lagts till visade textverktyget (kommando 233):

```text
1. Om någon allierad har inte Styrka → Förmåga: Stridssång på den som matchade
2. Om någon allierad har liv < 35 % → Förmåga: Hjältens ballad på den som matchade
3. Om någon allierad har liv < 50 % → pröva nästa rad
4. Om någon fiende har lägst liv (%) → Anfall på den som matchade
```

`scripts/game/run.gd:starter_lines` filtrerar hint-raden, tar `rest.slice(0, 2)` och lägger till FIRST_LINE om reservanfall saknas. Fullmallen i `data/macros.json` har Vaggvisa efter raden som testar allierads liv under 50 %. Den förmågeraden försvinner, medan testet blir kvar och kopplas till reservanfallet. Det är samma startfunktion som den vanliga spelkoden använder. En kedja bör bevaras som en enhet när startrader väljs. Den grafiska effekten har inte spelats igenom. Textstridernas reservanfall kan dölja att ingen riktig makrorad matchar.

Jag tog bort den avklippta testraden och prioriterade akut ballad före Stridssång. Detta var en spelarändring av makrot, inte en rättning av startfunktionen.

## 2. Alvas Läkning-kedja väljer mål i två steg

Startmakrot band först någon som saknar Läkning, därefter testades samma mål mot 80 %. I Prästens nisch var Arn fullfrisk, medan Imma hade tagit 88 skada av 180 före Alvas första handling (T7). Alva kastade Ljusets dom i stället för Läkande hand. Den första raden kunde redan ha bundit Arn. Akuthelning kom på T12.

`src/combat/macro_runner.gd:decide/match_line` behåller den första matchen genom kedjan; den söker inte om efter en annan allierad när nästa villkor misslyckas. Det är begriplig implementerad semantik, men lätt att misstolka. Jag ändrade ordningen till ”liv < 80 % → pröva nästa rad” följt av ”saknar Läkning → Läkande hand”. Även den versionen har begränsningen att bara den först valda allierade prövas; den löser inte alla flermålssituationer. Min tidigare beskrivning till användaren var för förenklad.

## 3. Allsång + Förmannens nyckelknippa gav inte den förväntade spridningen

Jag valde nyckelknippan till Lirien med hypotesen att dess Beskyddad-buff kunde spridas genom Allsång. Loggen visade knippans egna utlösningar, men ingen sådan spridning. Allsång i `data/traits.json` har `not_from_trait: true`; troféskapade buffar kvalificerar inte. Stridssång utlöste däremot Allsång. Det är en begränsning som gärna får framgå av hjältebladets text ”När Lirien ger en allierad en buff …”. Inte belägg för fel i motorn.

## 4. Mina egna misstag och uteblivna effekter

- Inför Benfursten läste jag Immas totalsiffra 13/19 för grovt. Alla fem Rökpilarna var redan förbrukade. Bossrökregeln användes därför inte och Imma stupade. Därefter visades och kontrollerades resurser per förmåga.
- Första `lacks_status=bleed` använde fel ID. Rätt är `bleeding`. Det kunde förnya Trickpil trots befintlig Blöder. Rättades efter Kolossens vakt; ingen strid spelades om.
- En kultistregel före Biskopen använde det obefintliga ID:t `protective_prayer`; rätt synligt egenskaps-ID är `cultist_ward`. Den regeln matchade inte. Det var vanliga anfall och övriga effekter som tog kultisterna. De två ogiltiga raderna togs bort efter bossen. Textkommandot accepterar ogiltiga ID:n; det säger inget om den grafiska väljaren.
- Vrede/Iver köptes tidigt men gav inte en ständig grundbonus. De krävde försvar/provokation och började användas ordentligt först när Imma fick en tankroll.
- Vid Klockrepets troféval antog jag i förhandsnotisen att allt var känt och valde skip innan jag läst hela utfallet. Diakonens stola var faktiskt ny. Textverktygets ordinarie flöde lägger alla erbjudna troféer i samlingen; därför fanns den hemma utan manuell belöning. Ingen trofé togs med i den pågående körningen från detta val.
- Vaggvisa på Brom kombinerades med Blöder, som väckte honom. Jag räknar inte det som en lyckad sömnlåsning. Provokationsvillkoret gav däremot Imma utrymme att använda Trickpil medan Brom levde.
- Imma undvek Lansens första förstärkta anfall i Två familjer. Den segern bevisar inte att hon hade tålt just den träffen.
- Benskrivaren dog fort. Upprepningsstraffets tak på 50 % stod på kortet, men pressades inte tillräckligt för att verifieras i striden.

## 5. Sparningsavvikelse i verktygsmiljön

Kommando 022 visade och sparade en skattdialog på f2. Nästa anrop hade oförklarligt äldre läge på f3. Kommandona 023–026 gav därför ”Okänt kommando här” eller för långt bort och gjorde inga framsteg. Jag återupptog 022:s bevarade efter-snapshot vid 027, utan att spela om skatt eller belöning. Därefter användes en ny sparmapp per kommando, hydrerad från föregående oföränderliga snapshot. Automatisk jämförelse fann inga senare glapp. Orsaken är inte fastställd och detta är inte belägg för ett fel i mobilversionen.

## 6. Vad som faktiskt testades

- Riktig ny profil, frö 101, introduktion och AUTO-strider med CombatSim/MacroRunner. Inga manuella handlingar inne i pågående strider. Val och makron ändrades mellan striderna.
- Fyra ordinarie nedstigningar och ett extra, uttryckligen beställt Trollbergsinträde. Ingen vinst eller förlust återspelades.
- Fem fiender fanns faktiskt i Hela byn i berget och Bergakungens sal. Fem hjältar spelades inte; den platsen förblev låst.
- Trollbergsbossens verkliga run-snapshot hade fyra hjältar men `full_party=5` och `scale_size=5`. Skalan var alltså den avsedda femmannakonfigurationen. Det är ingen garanti för att ett enda lag säger hur alla andra lag klarar den.
- Textadaptern i leveransen hade redan en gammal prägelbrygga; den kunde dubblera en prägelrad när basverktyget också skrev den. Jag tog bort dubblingen i visningen. Ingen fienderegel ändrades.
- Nivåbelöningar, edstitlar och separata förmågeladdningar lades till som textvisning från spelets egna data/funktioner. Kampanjvarningen återgavs ordagrant från `campaign_screen.gd`. Den grafiska placeringen, tydligheten och den faktiska mobilupplevelsen testades inte.
- Alla ursprungliga filer jämfördes byte för byte mot 0.30.41-zippen. Endast `tests/level1_play.gd` ändrades, med visningsbryggor. En ny läsande profilkontroll lades till under tests. Kärna, data och balans var oförändrade. Hela automatiska testsviten kördes inte.
- Veckobudgetens mätare kan inte avläsas här; ingen aktuell procent eller kostnad per pass påstås.
