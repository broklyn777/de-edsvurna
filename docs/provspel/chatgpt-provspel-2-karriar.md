# De edsvurna – egen provspelning från nivå 1

## Omfattning

- Start: riktig Profile.new(), Arn ensam på nivå 1, 60 silver, inga troféer, artefakter, rekryter eller klarade djup.
- Slumpfrö: 73. Ingen omstart av karriären efter förlust; ingen ändring av spelbalans, inga utdelade resurser eller nivåer.
- 10 nedstigningar, 51 expeditionsstrider: 49 segrar och 2 förluster. En separat övningsstrid i introt gav ingen XP eller belöning.
- 398 loggade kommandon, inklusive visningar, makroändringar, misslyckade kommandon och förflyttningar. Detta är inte antal mobiltryck.
- Avslut: hemma i borgen, Arn/Brokk/Alva/Eira nivå 16; Imma nivå 12 i värdshuset. Kryptan djup 4 och kapellet djup 2 klarade. Kryptan djup 5 och kapellet djup 3 är öppna men oprövade i detta pass.

## Karriär

| Nedstigning | Plats | Utfall |
|---|---|---|
| 1 | Kryptan 1 | Klarad; Imma anslöt efter första striden |
| 2 | Kryptan 1 | Klarad; Alva räddades |
| 3 | Kryptan 2 | Förlust mot Kolossens vakt, 46 turer; Brokk räddades före förlusten och behölls |
| 4 | Kryptan 1 | Klarad; träning av Brokk och insamling till utrustning |
| 5 | Kryptan 2 | Klarad; Midnattsklockan besegrad på 46 turer |
| 6 | Kryptan 3 | Klarad; Eira räddades; Kistornas råd 65 turer |
| 7 | Kryptan 4 | Förlust mot Benskrivaren, 38 turer; Eira ersatte Imma |
| 8 | Kapellet 1 | Klarad; nya troféer och träning av Eira |
| 9 | Kapellet 2 | Klarad; Abbedissans kör 21 turer efter anpassning till kronan |
| 10 | Kryptan 4 | Klarad; sigilluppdrag och Benfursten 66 turer |

## Det starkaste jag observerade

1. **Introduktionens kombination gick att tillämpa.** Immas Rökpil och Arns Rättfärdiga slag gav uttryckliga kombinationsbonusar. Jag byggde makrorader kring hennes tips.
2. **Förlust och återhämtning fungerade som en mekanisk loop.** Brokk föll på djup 2. Jag tränade på djup 1, utrustade honom med Väktarens hjälm och senare en sköld, ändrade makron och återvände. Djup 2 klarades vid nästa försök. Flera saker ändrades; detta isolerar inte effekten av en enskild ändring.
3. **Troféer gav nya planer.** Jag använde bland annat Snabbt tag på Imma, märkning/kritiska träffar på Eira, Diakonens stola på Alva och Saltad jord på Arn.
4. **Midnatt fick en begriplig upplösning.** I nedstigning 5 fällde Imma det återuppväckta skelettet innan Midnatt slog; kanaliseringen avbröts.
5. **Sigillen gav ett faktiskt vägval.** I nedstigning 10 bröt jag Vaksamhetens och Uthållighetens sigill och lämnade Murens. En farligare öppning och återkommande helning bedömdes farligare för mitt lag än en engångsbarriär. Jag sökte upp det andra alternativet efter att ha backat från Murens vakt. Båda alternativen har inte jämförts experimentellt.

## Svagheter och frågor

- **Långa avslutningar:** Kistornas råd tog 65 turer, Benfursten på djup 4 tog 66. Försvar, återkommande helning och uttömda laddningar kan ge långa strider. Turantalet är inte en mätning av mobilens uppspelningstid.
- **Svaga återbesök:** På kapellets djup 1, med nivå 13 i kärnlaget, klarades flera grupper på 3–7 turer med fullt slutliv. Nya troféer motiverade besöket, men striderna var sällan hotfulla.
- **Kartan blev ofta transport:** sökande i ryktesområden, rundning av spärrande grupper och långa återvägar till lägereld. Att leta efter en lägereld inför sista Benfursten krävde många tomma steg och omvägar. Resursbehovet var meningsfullt; själva letandet gav få andra beslut.
- **Upprepad obligatorisk grupp:** Askkoret förekom två gånger som bevakat uppdragsmål på samma våning i nedstigning 4, med samma fiender och nivåer.
- **Återkommande erbjudanden:** jag började avstå från redan kända troféer. Det är inte i sig dåligt, men många sådana skärmar gav inget nytt beslut.
- **Tidiga dödsfall:** Arn föll redan T4 i Gravdimmans möte under nedstigning 10; Benjägarens följdanfall bidrog. Laget vann ändå. Min plan att tysta fiender med Arn fick då inte möjlighet att verka.
- **Makrofel är en del av spelningen:** jag lät Arn provocera för ofta i ett tidigt försök och tog bort regeln. Jag gjorde även några felaktiga kommandon. Dessa ingår i råloggen och är inte automatiskt fel i mobilgränssnittet.
- **Troféer vid lägereld:** textläget tillät bara körningens tillgängliga troféer, inte hela samlingen. Ett försök att ge Arn en tidigare insamlad hjälm avvisades. Kontrollera gränssnittets avsedda beteende innan detta behandlas som designproblem.

## Första förbättringar att provspela

1. Hindra exakt samma obligatoriska gruppvariant från att väljas två gånger på samma våning när alternativ finns.
2. Ge en ledtråd till återhämtning eller bekvämare återresa när spelaren redan klarat våningsmålet. Behåll laddningarnas strategiska betydelse.
3. Granska långa striders sista tredjedel: är hotet fortfarande aktivt och finns rimliga verktyg för att avsluta? Utvärdera offensiva alternativ och tydligare återkoppling innan fler fiendesiffror höjs.

## Metod och begränsningar – viktigt vid återanvändning

Det medföljande textverktyget skapar normalt en profil på nivå 10–12. Jag lade därför till två separata adapterskript (tests/level1_play.gd och tests/level1_cli.gd) i arbetskopian. Originalet tests/text_play.gd och spelets kärnkod/data ändrades inte.

Adaptern använder Profile.new(), Intro.notify(), spelets smidesmetoder, CombatSim, RunState och MacroRunner. Den återger introhändelser och möjliggör övningsstrid, smide och läsning som inte fanns som textkommandon. Den använder nybörjarmakron från Run.starter_lines, återställer first_descent-flaggan som huvudflödet använder, låter Imma ansluta via RunState.join_waiting och hanterar hemkomsten i linje med introreglerna.

Detta är ett separat testgränssnitt, inte en provspelning av originalets menyer och pekstyrning. Adaptern är inte en komplett kopia av alla UI-spärrar eller all berättarpresentation. Exempelvis återges inte automatiska samtal med exakt samma timing. Stridsregler och progression kommer från spelet, men resultaten är inte en certifiering av fullständig likhet med mobilversionen.

Jag fattade vägbeslut från de skärmar textläget visade. Kod lästes för att koppla nybörjarflödet och slå upp interna identifierare, inte för att läsa de genererade kartornas dolda innehåll. Inget slumpfrö söktes fram för att få en lättare karriär. Detta är en karriär med ett frö, inte ett representativt balanstest över många spelare.

Grafik, ljud, animationernas tempo och mobilens användbarhet har inte testats. Jag kan beskriva val, utfall och friktion; jag har inte upplevt mänsklig spelglädje eller mätt retention.

## Fortsätta

Använd originalprojektet från edsvurna-textspel.zip och Godot 4.7.2. Lägg adapterskripten i projektets tests-mapp. Packa upp save-mappen på en skrivbar plats och kör:

```
godot --headless --path /sokvag/till/edsvurna --script res://tests/level1_cli.gd -- --dir=/sokvag/till/save look
```

Fortsätt med ett kommando per anrop. Använd inte `new` om sparningen ska behållas. På hemmaplan stöder adaptern även `forge <hjälte> <typ> <förmåga>`, `talk`, `practice [möte]` och `read`. Ordinarie spelkommandon som depth, realm, start, go, fight, choose, take, skip, macro, smith och wear fungerar som tidigare.

Sparningen slutar hemma efter klarad Kryptan 4, med 353 silver och en oanvänd perk-poäng. Inga uppgraderingar eller nya nedstigningar är gjorda efter denna kontrollpunkt.
