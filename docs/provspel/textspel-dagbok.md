# Textspel – provspelardagbok (oktober 2026)

En AI-agent spelade fem nedstigningar beslut för beslut i textläget (`tests/text_play.gd`, gren `textspel` från
`test-0.30`), som en människa: läste korten, valde väg, backade, bytte troféer vid lägereldar, ändrade makron inför
väktare och la silver hos smeden. Ingen kod lästes för att optimera spelet; när jag behövde ett id för en makrorad slog
jag upp det motsvarande det redigeraren visar med namn. Hela loggen: `textspel-logg.md`.

**Utgångsläge:** en profil mitt i spelet (skapad av verktyget med `new`): Paladinen Arn (nivå 12, Domens kall med Vrede,
Iver och Klockan klämtar), Brokk och Syster Alva (11), Jägaren Eira (10), artefakter på nivå 3–5, tio vanliga troféer,
kryptan klarad till djup 3 och kapellet till djup 2, väktarna besegrade en gång var. Imma, Solveig och Tove i Värdshuset.

**Resultat:** 5 nedstigningar, 38 strider, 38 segrar, ingen hjälte stupade en enda gång. Hjältarna gick från nivå 10–12 till
20–21. Jag behövde aldrig gå tillbaka ett djup och träna.

| # | Realm, djup | Slut | Strider | Svåraste ögonblicket |
|---|---|---|---|---|
| 1 | Kryptan 2 | Midnattsklockan | 7 | inget; väktaren tog 33 turer utan att någon kom under 80 % |
| 2 | Kryptan 3 | Kistornas råd | 8 | Nemesis (Benkolossen) tog Brokk till 64 % |
| 3 | Kapellet 2 | Abbedissans kör | 8 | inget; strider på 2–3 turer |
| 4 | Kryptan 4 | Benfursten | 9 | Benfurstens Dödsdom: 431 skada på Brokk i ett slag |
| 5 | Kryptan 5 | Midnattsklockan (igen) | 6 | Klockaren laddade "MIDNATT NÄRMAR SIG" men dog först |

---

## Nedstigning 1 – Kryptan djup 2 (Midnattsklockan)

**Vad hände.** Hemma köpte jag Räkenskap och Domslut (tre perk-poäng låg oanvända) och höjde Eiras stövlar. Questen var
Rensa en elitgrupp. Första gruppen jag mötte var ELITGRUPP Kolossens vakt (Benkolossen + Skelettkrigare). Sedan Prästens
nisch, Glödande schakt, Väktarens port, Likgropen, Benvakten och väktaren. Alla vanliga strider tog 4–14 turer och ingen
i sällskapet kom under 75 % liv. På våning 1 hittade jag inga vanliga grupper på de 17 första rutorna, bara tomma rutor,
en skatt och en helgedom.

**Kul.** Elitkortet var tydligt och fick mig att tänka ("Efter tre gånger sveper den med Benstorm"). Väktarkortet är bra
skrivet: *"Tre slag till midnatt: klockan väcker Benfolket, och det tredje slaget bryts bara om hela Benfolket har
fallit."* Det är en fråga som makron skulle kunna svara på. Eira har bra repliker som hör till platsen: *"Släpspår fram
till kistan. Någon annan fick bära den hit."*

**Repetitivt.** Kolossens vakt var våningens elit; den kom tillbaka i tre av fyra kryptnedstigningar (se nedan).
Helgedomen erbjöd exakt samma tre saker som i verktygstestet före provspelet: +2 Charges på en förmåga, Styrka nästa
strid, Pandemonium.

**Tveksam/förvirrad.** I väktarstriden står det två gånger `Klockaren: Klockan slår → Klockaren` utan att något syns hända.
Det tredje slaget kom aldrig, så frågan på kortet fick aldrig något svar. Jag vet inte om jag "löste" mekaniken eller om
den bara inte hann. På trofélistan efter Prästens nisch fick jag erbjudandet Den slocknade glöden – samma trofé som skatten
bakom gruppen just hade gett mig.

**Vad väktaren tillförde.** Ett snyggt kort och en trofé (Midnattsklockans kläpp, nu 2/2 segrar). I själva striden ingen
press alls: med nivå 12 mot 10 slogs väktaren ned medan hjältarna stod på fullt liv.

## Nedstigning 2 – Kryptan djup 3 (Kistornas råd)

**Vad hände.** Kryptan 3 hade fiender på nivå 12–15 mot mina 13–14. Questen var Jakt på Nemesis, och Nemesis var … Kolossens
vakt igen. Den tog Brokk till 395/621, vilket var första gången jag kände att troféerna och Alvas stav bar striden
("avgjorde: Väktarens hjälm 136 helning, Stav: Helande ljus 140 helning"). På våning 2 tvingade sedda grupper mig in i
strider (en sedd grupp spärrar rutorna runt sig, så jag kunde inte gå runt). Gravregistret ("BESVÄRLIGA GRANNAR")
visade elitgruppen och det sista föremålet; det var ett riktigt bra val som sparade mig tre rutor letande.

**Kul.** Väktaren. Kortet säger *"när en i rådet faller ärver de andra hens egenskap. Välj ordningen."* Det är precis rätt
sorts fråga. Jag la till en rad överst hos Arn, Eira och Alva: "Om någon fiende har egenskapen Kallelse → anfall den",
så Gravväckaren föll först. I loggen syns det: `!! Gravväckaren föll; Gravens kraft går vidare till Kistbärare 1,
Kistbärare 2`. Den enda gången på hela provspelet som jag ändrade ett makro för att jag ville, inte för att jag var
tvungen.

**Repetitivt.** Benkryptans gång, Glödande schakt och Likgropen från djup 2 kom tillbaka med samma namn, samma fiender och
samma egenskaper, bara med högre nivå. Likätaren blev elitvarianten Gravgnagaren båda gångerna jag mötte honom. Alvas
repliker handlar nästan alltid om hennes utrustning: *"Fukten går genom manteln. Kom hit, jag fäster den tätare vid
halsen."*, *"Låt mig fästa manteln …"*, *"Känn efter om stövlarna skaver …"*, *"Vänta. Jag knyter förbandsväskan
framtill …"*.

**Tveksam/förvirrad.** I rådsstriden står det `!! Kistbärare 1 föll; Jägarinstinkt går vidare till Kistbärare 2`.
Jägarinstinkt är Eiras egen egenskap, inte rådets. Jag trodde först att Eira hade tappat den. (Det är ett fel i spelet,
se "Fel jag hittade".) Kortet listade Kallelse och Sista tjänsten men inte Likvakan, som slog till fyra gånger och helade
den andra kistbäraren.

## Nedstigning 3 – Det fördärvade kapellet djup 2 (Abbedissans kör)

**Vad hände.** Kampanjkartan sa *"Kulten samlas till högtid – fäll biskopen (en nedstigning kvar)"*. Kapellet djup 2 slutar
med Abbedissans kör, inte biskopen, så jag väntade mig att förlora händelsen. Med nivå 15 mot fiender på nivå 7 tog de
vanliga striderna 2–3 turer. Nemesis var Lansens anstormning (24 turer, ingen fara).

**Kul.** Väktarkortet igen: *"Systrarnas krona: bara den som bär kronan tar full skada. Kronan flyttar efter tre av
bärarens turer."* Jag la till "Om någon fiende har Systrarnas krona → anfall den" och såg kronan gå vidare:
`!! Systrarnas krona går från Den fördärvade abbedissan till Fördärvad diakon 1`. Hemkomsten var en överraskning:
*"Kulten samlas till högtid: Högtiden bröts innan den började. Kapellet tystnade."* och *"En pilgrim sitter i
värdshuset: han vet var nästa körnings första mål står"*. Den levande världen är det som kändes mest nytt på hela
provspelet.

**Repetitivt.** Kapellets våning 1-elit (Lansens anstormning) är fast, som kryptans. Abbedissan dog på 11 turer, innan
hennes Mässan ("Var tredje egen tur helas alla …") slog till en enda gång.

**Tveksam/förvirrad.** Händelsen sa "fäll biskopen" men räknade abbedissan. Det var bra för mig men texten stämmer inte.
Väktarens timglas visade *"Ett val går inte"* fast det fanns en elit kvar på våningen före – i spelet får timglaset
dessutom bänkens text ("Gedigen ek. Ni har inte sett någon grupp att barrikadera bort än") när dess val är avstängt.
Jag missade Häxmästarinnans brutna spira (*"Bärarens förmågor har 30 % chans att kastas en gång till, utan Charge"*,
från en sällsynt elitvariant) för att jag tryckte förbi lägret i samma tempo som efter tjugo likadana erbjudanden.
Elitvariantens trofé ser likadan ut som de vanliga i listan; den borde glöda.

## Nedstigning 4 – Kryptan djup 4 (Benfursten)

**Vad hände.** Hemma satte jag bärnsten i alla artefakter, höjde Alva och Brokk till nivå 6 och fick troféplatser: Den
fallnes klinga i Brokks sköld, Det brustna bönebandet i Alvas stav. Pilgrimens rykte visade alla tre föremålen på våning 1
från start (`Q!` på kartan), så våningen tog åtta drag. Fiender på nivå 19–20, mina på 16–18. Första gången striderna
kostade: Kolossens vakt (som elit, fjärde gången) tog Brokk till 481/800.

**Kul – provspelets bästa ögonblick.** Efter Askkoret fick jag elitvariantens trofé Den återtända ljusstaken (*"I början av
bärarens tur helas hela sällskapet för 8 % av bärarens max liv"*). Jag gick tillbaka till lägerelden, gav den till Arn i
stället för Kolossens tålamod, och i nästa strid stod den överst på segerskärmen: `avgjorde: [TROFÉ] Den återtända
ljusstaken (Arn): 443 helning · 6 gånger`. Den låg överst i varje strid resten av provspelet. Det är exakt ledstjärnans
test: jag bytte frivilligt efter att ha sett en ny del, och ville se den verka direkt. Benfursten var den enda strid som
kändes som en boss: `!! Benfursten laddar Dödsdom – slår om 1 tur mot Syster Alva`, sedan `Dödsdom → Brokk | Brokk −431`,
Väck de döda på Gravprästen, Odödlig vrede med Benstorm. Sefir av Sanden satt fången bakom Glödande schakt.

**Repetitivt.** Klockaren, väktaren från djup 2, var nu en vanlig elitgrupp (Klockstapeln) med samma kort, egenskaper och
motdrag. Glödande schakt för tredje och fjärde gången (en av dem vaktade Sefir). Väktarens port och Likfärden ännu en gång.

**Tveksam/förvirrad.** Charges tog nästan slut på våning 2 (Arn 5/13, Eira 4/14) av strider som inte behövde dem.
Makrona bränner Rättfärdigt slag och Ljusets dom på vilken skelettkrigare som helst, och det finns inget villkor för "om
det här är en elit eller boss". Sefir anslöt på **nivå 2** när sällskapet var på 17: *"Sällskapet är fullt – väntar i
Värdshuset."* Hen går inte att prova i ett djup 5-sällskap.

## Nedstigning 5 – Kryptan djup 5 (Midnattsklockan igen)

**Vad hände.** Djup 5 i kryptan slutar med samma väktare som djup 2. Våning 1: Prästens nisch, Benkryptans gång,
Benkryptans gång (en till, som jag backade från), Prästens nisch – alla tre quest-föremål vaktades av samma två möten.
Våning 2: Likfärden (samma elit som på djup 4) och sedan en ny elit, Gravdimman.

**Kul.** Gravdimman: *"Var tredje egen tur lägger Gravdimman hela sällskapet i Dimsömn"*. Plötsligt stod tre hjältar över
sin tur (`Syster Alva står över (deep_sleep)`), och jag fick trofén Den skingrade dimman. Första nya fienden på två
nedstigningar, och det märktes direkt hur mycket mer jag läste kortet. Midnattsklockan visade den här gången hela sin
mekanik: två slag, sedan `!! Klockaren laddar Midnatt – slår om 2 turer mot hela sällskapet (MIDNATT NÄRMAR SIG)` – och
Eira fällde Klockaren med ett kritiskt slag turen innan.

**Repetitivt.** Väktarkortet var ordagrant samma som på djup 2, enda skillnaden *"(2/2 segrar)"*. Fiendernas nivåer steg
(10 → 25) men mina också (12 → 20), så det kändes som samma strid med större tal. Trofélägret erbjöd för sjuttonde gången
Den slocknade glöden.

---

## Det text-verktyget inte kan visa

- Animation, ljud, kamera, hitstop och "känslan" när Dödsdom slår eller kronan flyttar. Mycket av väktarnas dramatik
  (ord över fienden som MIDNATT NÄRMAR SIG) finns bara som en rad här.
- Hur lång en strid känns: 47 turer i AUTO kan vara spännande eller segt på telefonen; det går inte att avgöra i text.
- Manuella val i striden (verktyget kör alla hjältar på AUTO), "Spara som order", hjälprutorna, berättarrutorna,
  porträtten, samtalen i borgen och Värdshuset, krönikan och Övningsgården.
- Kartan är ASCII; i spelet syns bergssidor, ringar och den gyllene stigen, vilket säkert gör letandet i ryktesringarna
  trevligare än här.
- Jag ser inte fienderna innan kortet; i spelet kanske en glödande elitvariant syns på avstånd.

## De fem största upprepningsproblemen (rangordnade)

1. **Samma vanliga möten på varje djup.** Prästens nisch (4 gånger), Glödande schakt (4), Benkryptans gång (2 + 1 jag
   backade från), Likgropen, Kistbärarnas gång och Likfärden (2 var) kom tillbaka från djup 2 till djup 5 med samma namn,
   samma två–tre fiender och samma egenskaper; bara nivån ändrades. Förslag: (a) möten per djupband (djup 1–2, 3–4, 5+)
   i `realms.json`, där de högre banden byter ut en fiende mot en ny familjemedlem; (b) en "djupets egenskap" per mötestyp
   som Siralims Realm Properties (t.ex. djup 4+: Glödskelett lämnar en glödpöl); (c) från djup 4 blandas en grupp från en
   annan Realm in (kapellets kultister i kryptan med en berättelse om varför).
2. **Våning 1:s elit är alltid samma.** Kolossens vakt var våningens elit eller Nemesis i alla kryptans nedstigningar
   (djup 2, 3, 4 och i testet) och Lansens anstormning i kapellet. Det är det första stora kortet varje gång, så det är där
   upprepningen märks mest. Förslag: två–tre elitgrupper för våning 1 som roterar per djup (som väktarna), och att
   Nemesis väljs ur en annan pool än våningens elit.
3. **Väktarna och deras folk kommer tillbaka för fort.** Med två väktare per Realm är Midnattsklockan slutet på djup 2 och
   5, med ordagrant samma kort, och dess Klockare är dessutom vanlig elit (Klockstapeln) på djup 4. Förslag: andra mötet med
   en väktare får ett nytt steg (Klockan slår fyra gånger, en ny regel, en replik som minns förra gången: "Klockan
   minns er"); håll väktarens miniboss borta ur elitpoolen på djupen intill; eller en tredje väktare per Realm så att
   cykeln blir fyra.
4. **Trofélägret erbjuder samma saker.** På 38 läger: Den slocknade glöden 17 gånger, Det andra hugget 12, Springarens steg
   10, ofta troféer jag redan ägde, en gång samma trofé som skatten precis gett. Efter djup 2 valde jag "skip" utan att
   läsa. Därför missade jag den enda riktigt regelbrytande trofén (Häxmästarinnans brutna spira). Förslag: fyll på
   erbjudandet med troféer man inte äger först; markera "NY" och sällsynthet tydligt; ersätt ägda med något annat (en
   bärnsten, silver); låt elitvariantens trofé alltid stå först och glöda.
5. **Samma motor vinner varje strid, och spelet tvingar aldrig fram en ändring.** Väktarens hjälm, Domens kall,
   Jägarinstinkt och Alvas stav stod överst på nästan varje segerskärm; makrona behövde bara ändras för väktarnas egna
   frågor. Nivåerna hängde med djupet (spåren gav 75 % av erfarenheten utan strid, t.ex. "+459 erfarenhet"), så jag var
   aldrig i fara och förlorade ingen av 38 strider. Utan förlust eller hot finns inget skäl att prova en ny hjälte eller
   trofé. Förslag: ge vanliga grupper från djup 3 en "fråga" som väktarna har (en egenskap som straffar just det vanligaste
   bygget, t.ex. en grupp som hånar den som provocerar eller renar Märkt); låt kortet visa den som ett motdrag; se över
   spårens andel när sällskapet redan ligger över fiendernas nivå.

**Mindre upprepningar:** helgedomen hade alltid samma tre val (Charges / Styrka eller Värnad / Pandemonium); Alvas repliker
kretsar kring mantel, stövlar och förbandsväska; befriade följeslagare kommer på nivå 2 och blir aldrig ett verkligt val
(Sefir), så de nya kombinationerna i Värdshuset prövas inte; ryktesringarna på 3×3 betydde ofta att gå sex–nio tomma
rutor (två ringar som överlappade på våning 2 i kryptan 3 gav femton rutor att leta i).

## Fel jag hittade (i spelet, inte i verktyget)

1. **Fel egenskap i "går vidare till".** `CombatSim._emit` skriver över händelsens `trait` med `_trait_ctx` när händelsen
   skickas inifrån en egenskap. När en Kistbärare dog av Eiras Jägarinstinkt blev raden "Jägarinstinkt går vidare till
   Kistbärare 2" (i spelet: flytande text "ÄRVER JÄGARINSTINKT"). Samma sak drabbar Rådets sigill (`inherit_trophy`),
   som alltid körs inifrån en egenskap.
2. **Samma trofé två gånger.** En vunnen grupp som vaktar en skatt: lägrets erbjudande räknas ut före skatten
   (`Run.battle_finished`), så skattens trofé (Den slocknade glöden, två gånger) erbjuds också i lägret.
3. **Timglasets avstängda val visar bänkens text.** `room_map_screen._object_dialog` skriver "Gedigen ek. Ni har inte sett
   någon grupp att barrikadera bort än" för alla avstängda val, även Väktarens timglas.
4. **Repliken nämner en som inte är med.** Vid lägerelden sa Syster Alva *"Drick vatten. Alla. Ja, du också, Imma."* fast
   Imma satt i Värdshuset.
5. **Händelsens text och villkor.** "Kulten samlas till högtid – fäll biskopen" klarades av att fälla Abbedissans kör.
6. Kortet för en vanlig grupp säger inget om sällsynta elitvarianter: Likgropen stod som FIENDEGRUPP med Likätare och
   Skelettkrigare men striden var mot Gravgnagaren och Benkapten (båda elit).

## Vad jag ville göra men inte kunde

- Säga åt makrot att spara Charges i lätta strider: ett villkor som "striden är mot elit/Nemesis/boss" eller "fiendens
  nivå under sällskapets".
- Ta med Sefir (nivå 2) eller Imma (nivå 9) i ett djup 5-sällskap utan att träna dem i timmar.
- Välja biskopen för att stoppa kultens högtid; den finns bara på djup 1 och 4 i kapellet.
- Se vad Klockan slår faktiskt gjorde i första väktarstriden.
