# Poleringen (förslag 2026-10-26, VD läser och ändrar)

VD: "Nu ska vi inte göra det större, utan få allt ifrån leveling till karaktärsblad, lilla kartorna, fighten, allting
superpolerat. Sen kan vi bygga större."

Inga nya system under poleringen. Ett område i taget, i den ordning spelaren möter dem. Varje område har en kort lista
med vad "klart" betyder; när listan är uppfylld provspelar VD området på telefonen och säger "klart" eller vad som skaver.
Först då går vi vidare. Ungefär 2–3 veckor totalt.

## Ledstänger (VD 2026-10-26, efter att ha provat Baldur's Gate 3 igen)
VD kom aldrig in i BG3 fast det "har allt": **för mycket att hålla reda på** (inventariet, väggar av siffror) och **långt
mellan striderna** (mycket gång och samtal). Tärningsslump och långsamma nivåer är okej – så länge man **känner framsteg och
vet vad man ska göra**. Därför, i varje område:
- Visa det som spelar roll nu; resten bakom ett tryck. Förråd och samlingar sorteras efter nytta, inte i en lång lista.
- Samtal korta och möjliga att hoppa över; vägen till nästa strid kort.
- Alltid ett tydligt nästa steg och synligt framsteg.

## Ordningen

### 1. Första timmen (intro, borgen, de två första nedstigningarna)
Klart när:
- En ny profil kommer från eden till den första klarade kryptan utan att fastna, gissa eller läsa om en hjälpruta.
- Varje introsteg säger tydligt vad nästa steg är och var (personen och rummet).
- Inga repliker som säger fel sak (fel talare, fel tillfälle, upprepning samma körning).
- Första förlusten känns rättvis och visar vad man kan göra bättre.

### 2. Striden
Klart när:
- Det syns vem som är på tur, vad fienden tänker göra och varför något hände (Stridsloggen, siffrorna).
- Inga figurer som står still, glider fel eller skymmer varandra; inga effekter utan ljud.
- Tempot: 1× känns inte segt, 2× hinner man följa med i.
- MANUELL/AUTO och makrona i striden är lätta att förstå första gången.

### 3. Grottkartan
Klart när:
- Man ser direkt var man kan gå, vad som spärrar och vad rutan innehåller.
- Gruppkortet (ANFALL/BACKA) säger allt som behövs för att välja.
- Questen och vägen dit är tydliga; rykten och spår förvirrar inte.
- Lägereld, helgedom, skatter och föremål känns som belöningar, inte som administration.

### 4. Nivåer och hjältebladet
Klart när:
- Varje nivåuppgång syns och känns (segerskärmen, vad som blev bättre).
- Bladet visar vad hjälten bygger mot: stats per källa, egenskaper, NÄSTA STEG, DET HÄR HAR … GJORT.
- Inga siffror som kan läsas på två sätt (som personligheten var).

### 5. Smedjan och troféerna
Klart när:
- Man förstår vad bärnsten, trick och Nether Stones gör innan man köper.
- Trofébyte vid lägerelden visar vad man vinner och förlorar.
- Varje roll (tank, helare, skada, kontroll, stöd) har minst två vanliga troféer att bygga med.
Kända skavanker (skärmdump 2026-10-26, `--forge-demo --smith --smith-hero=alva`): listan "Förmåga i artefakten" visar alla
hjältars förmågor (Alva erbjuds Rättfärdigt slag, Trickpil …) – kontrollera om det gäller vanliga profiler eller bara demon;
knappen SMID täcker de nedersta förmågorna; "FÖRRÅD – TRYCK FÖR ALLT" ritas över Torun i hjältelistan.

### 6. Makroeditorn
Klart när:
- En ny spelare kan skriva "om någon allierad har lågt liv → hela den" utan hjälp.
- Förslagen (Spara som order, makroförslag från nya följeslagare) dyker upp i rätt läge.

## Hur vi hittar det som skaver
- VD provspelar på telefonen efter varje område (viktigast).
- Botarna (soak, balans) hittar dödlägen och fel i siffrorna, datortid i stället för budget.
- Claude granskar skärmdumpar i 1280×720 och telefonbredd.
- ChatGPT bara för små, avgränsade uppgifter (dess resurser räcker inte till långa provspel).
- Senare: 2–3 utomstående som aldrig sett spelet spelar första timmen.

## Efter poleringen
Variation i det som finns (fler monster per Realm, bossar som skiftar mellan djup) före nya system. Sedan nya Realms
och iPhone.

## Fynd från VD:s provspel av 0.30.47 (ny profil, 2026-10-26)
Gjort i grenen `claude/polish-final-99cc98` (efter 0.30.48): fynd 1 (SÄLLSKAPET i borgen), 6 (träffytor, fiender isär),
11 (en rad om troféplatsen hos Smeden) och textfelen (Förberedelsers namn, löftesknappen, kapellets text, lägrets
artefaktrad, MOTSTÖT över skyltarna, porträtten vid Mor Elin och ovanför PORTEN).
1. Borgen: hjältebladet går inte att nå härifrån. Man vill kunna se allt om sina karaktärer när som helst
   (Siralim: skapelserna nås från slottets meny). Förslag: tryck på paladinpjäsen, eller en knapp SÄLLSKAPET under
   INSTÄLLNINGAR, som öppnar `hero_screen` för alla som har anslutit. (Område 4, men syns redan i första timmen.)
   VD 2026-10-27 (andra gången, HÖG PRIO): "titta på sina karaktärsblad, se vilka troféer man har med mera" ska vara lätt
   från borgen. Förslag: knappen SÄLLSKAPET i borgen → en översikt med alla hjältar (nivå, trofé, artefakt och dess
   troféplats, tomma platser markerade) där ett tryck öppnar hjältebladet, och en flik SAMLINGEN med alla troféer
   sorterade efter roll och vem som bär dem (i dag bara i Biblioteket som rykten/lista).
2. Kampanjkartan, första nedstigningen: Kapellet och Sidenlunden går att välja (bara Trollberget har `requires` i
   `realms.json`). Förslag: Kapellet öppnas när Kryptan är klarad på djup 1, Sidenlunden efter Kapellet (som Siralim, där
   Realms öppnas efter hand); under introts nedstigning bara Kryptan.
   Samma skärm har för mycket för en ny spelare (jfr BG3): instabilitet, perk-poäng, "Fiender +0 % / Silver +0 %",
   0/3-märkena och hela listan "Sägs sitta fången här" (sex namn, och Alva står som djup 1 fast hon kommer på andra
   nedstigningen). Förslag: visa instabilitet och perk-poäng först när de går att använda, visa bara nästa fånge som rykte.
3. Smedjan: listan "Förmåga i artefakten" visar alla hjältars förmågor även i en vanlig profil (bekräftat). Troligen rätt
   (Siralims spell gems bär vilken besvärjelse som helst), men elva knappar utan ordning är mycket för en ny spelare.
   VD fick fråga vad som var bäst för Brokk. Förslag: sortera så att det som passar hjälten och typen står först (t.ex.
   Hjälm → förmågor som skyddar, bärarens egna först) och märk ett "Förslag" utifrån hjältens makro (hur ofta hen
   anfaller/provocerar/försvarar).
4. Kampanjkartan, panelen till höger: när djupets tecken (Trång passage + BYT · 25), Löfte och fångelistan finns samtidigt
   ritas "Sägs sitta fången här: Lirien … Ronja" över "Sällskap: Mr Bobo, Imma …". Panelen har för mycket (jfr fynd 2).
   Dessutom: rubriken säger "DJUPASTE KLARADE 1" för Kapellet fast kortet säger "Djup klarat: 0" (rubriken verkar visa
   profilens djupaste, inte Realmens). Förslag: rullbar panel eller färre rader (fånge som ett rykte, sällskapet bara i
   Förberedelser), och Realmens eget djup i rubriken. Kontrollera i 1280×720 och 1560×720 med tecken + löfte + fångar.
5. Lägerelden: "DINA TROFÉER" visar bara körningens troféer (de burna + de hittade i körningen, `camp_screen._inventory`).
   VD trodde att de andra troféerna var borta eller måste väljas i borgen. Förslag: rubriken "KÖRNINGENS TROFÉER" och en
   rad "Hela samlingen väljer du i Förberedelser innan du går ned"; en hjälte utan trofé (Brokk) markerad som "tom plats".
   Fråga till VD senare: ska hela samlingen gå att välja vid lägerelden? (Mer att hålla reda på, men mindre förvirring.)

## Granskning av fem skärmdumpar (Claude-chatten, 2026-10-27, `docs/provspel/chatt-granskning-skarmdumpar-0.30.47.txt`)
Huvudpoäng: allt har samma tyngd, mer att läsa än beslutet kräver (samma som VD:s BG3-ledstång). Claudes bedömning:
- **Ta direkt (billigt, rätt):** porträttklungan vid Mor Elin och porträtten staplade ovanför Porten (layoutfel);
  makrologgens rad klipps ("någon allierad har li…") – kort form "Alva → Helande ljus på Paladinen · rad 1";
  "Inga våningsregler" krockar med Djupets tecken → "Inga regler från instabilitet"; 0/3-märkena oförklarade (fynd 2);
  Questraden "QUEST: Samla: ta 3 bevakade föremål" → "Hämta 3 bevakade föremål · 0/3 – öppnar trappan"; låst trappa
  tydligare; rykteringarna svagare/streckade; hörnmarkeringarna (möjliga steg) starkare än dimman; Immas döda porträtt
  läsbart namn + DÖD; "Syster Alva: Helande ljus" vid effekten när NU visar någon annan; "BASEN" → "BORGEN".
- **Ta i sitt område:** tidslinjen (K/H/F-bokstäver → konsekvent symbol per figur, aktören tydligast; område 2);
  fiendernas namn/liv/avsikt i fast ordning med mer luft; hjältebladets källformler bakom ett tryck, decimaler bara i
  detaljen, "Vad det betyder" i tre rader, historiken i två rader (område 4); stridens lila golv och neonringar dämpas
  mot tuschvärlden (område 2, ljus och färg, inga nya modeller).
- **VD avgör (fråga 83):** termerna. Granskningen vill ha allt på svenska (Liv, Anfall, Laddningar, Uppdrag,
  Talangpoäng). VD sa 2026-10-26 att standardord som healer/dps/tank kan stå på engelska, och spelet använder Siralims
  Health/Attack/Charges/Quest/Perk medvetet. Förslag: EN regel – stats och Siralim-system på svenska i spelets text
  (Liv, Anfall, Intelligens, Försvar, Snabbhet, Laddningar, Uppdrag), rollord (tank, healer) får vara engelska; ordlistan
  uppdateras. Nackdel: spelare som kan Siralim känner igen mindre.
- **Avvisa/vänta:** "RUMSÖGONBLICK" bort ur grottvyn (flytta till Inställningar, inte ta bort); "GÅ HEM" → "Avsluta
  nedstigningen" (ok, billigt).
6. Striden, välja mål: svårt att träffa den nedersta fienden, särskilt när två står nära (Häxan och Kultisten i
   kapellet). Huvudet fungerade förut som träffyta, men inte när figurerna överlappar. Förslag (område 2, högt prio):
   namnskylten/livmätaren över varje fiende är också en träffyta; vid målval visas en rad stora målknappar (namn + liv)
   längst ned eller pilar för att stega mellan mål (Siralim stegar med pilar); tryck på fel figur markerar bara, ett
   andra tryck bekräftar. Och sprid fiendernas platser så att de inte står i varandra.
7. Trollberget djup 1 med fyra: vunnen på 132 turer (utmattningen börjar vid 100). VD: "rätt svårt men egentligen ingen
   fara" – helningen (Gryningens kall 151 helning, 79 gånger; radbandet 14 gånger) höll jämna steg, så striden blev lång
   utan att bli farlig. Kontrollera bossens längd i botarna; en bossstrid ska kännas farlig, inte seg.
   Språk: "%s RENSAD!" (`battle.gd` rad ~1372) ger "BERGET RENSAD!" – ska vara "RENSAT" för ett ett-ord. Lägg genus i
   realms.json (t.ex. `"cleared": "RENSAT"`) eller skriv "KRYPTAN ÄR FRI!"-liknande per Realm.
8. VD önskar en mätare som Recount i WoW: skada, helning, tagen skada och skydd per hjälte som staplar. Data finns
   (`CombatSim.contrib`, `trait_stats`). Förslag: en flik "MÄTARE" på segerskärmen och i Stridsloggen (staplar per hjälte,
   tryck för att växla skada/helning/tagen/skydd); senare kanske en liten live-mätare. Passar ledstången "känna framsteg".
9. Smedjan, byta typ: VD trodde att man kunde ha både svärd och sköld (Paladinen bär båda i 3D). Skärmen säger inte att
   varje hjälte bär EN artefakt, och att välja en annan typ ger knappen "SMID – 160 SILVER" (`Profile.forge_cost` =
   FORGE_COST) utan att säga att svärdet ersätts och utan bekräftelse. Förslag: raden "Varje hjälte bär en artefakt" under
   TYP; knappen "BYT SVÄRD → SKÖLD – 160 SILVER" med "Nivå 4 och materialen följer med" under; samma i textspelet.
10. Smedjan, sätta i (VD 2026-10-27: inget omtag, "jag borde sett det"; Claude föreslår bara en rad "Tryck igen för att sätta i" på det valda kortet): ett alternativ (trofé, bärnsten, trick, Nether Stone) sätts i först vid ett ANDRA tryck på
    samma kort (`smith_screen.gd` ~rad 175); den stora röda knappen bredvid höjer nivån. VD tryckte på Den rivna slöjan och
    sedan på knappen i tron att den bekräftade – köpte nivå 7 (230 silver) och trofén kom aldrig i. Förslag: när något är
    valt blir den stora knappen "SÄTT I <NAMN>" (gratis, eller vad det kostar); nivåknappen bara när inget är valt, eller
    en egen mindre knapp vid nivåstegen. Samma mönster på andra skärmar med "tryck två gånger" ska ses över.
11. Artefaktens troféplats (nivå 6) gör att en hjälte bär två troféer; VD kände inte till det. Visa det i nivåstegen och
    hjälprutan "material" (eller en egen första gång platsen öppnas).
12. Förberedelser: knapparna KLAR och MAKRON ritas ovanpå trofénätet (Den brutna fanstaven, Blodsvurens kniv, Den trasiga
    fanan, Den kluvna stenen skyms). Samlingen (30+ troféer) är ett osorterat rutnät utan beskrivning förrän man trycker
    (jfr BG3: "för mycket att hålla reda på"). Förslag: knapparna i en egen rad under en rullbar lista; sortera/filtrera
    efter roll (tank, helare, skada, kontroll, stöd) och "passar den valda hjälten" först; visa sällsynthet med färg.
    Kontrollera i 1280×720 och 1560×720 med 30+ troféer.
13. Troféer flyttas i tysthet (VIKTIG): en trofé finns i ett exemplar (`Profile._free_trophy`). VD satte Den rivna slöjan i
    Brokks hjälm och gav den sedan av misstag till Eira i Förberedelser – den försvann ur hjälmen utan ett ord. VD: "ett gem
    som sätts dit borde vara evigt tills jag tar bort den med flit". Förslag: Förberedelser och lägerelden visar var en
    trofé sitter ("i Brokks hjälm", "bärs av Alva") på rutan, och att flytta den kräver en bekräftelse ("Flytta från
    Brokks hjälm till Eira?"). Samma i smedjan åt andra hållet (den visar redan vem som har den).
