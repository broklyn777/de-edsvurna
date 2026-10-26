# Formlerna – hur siffrorna räknas

*0.21 "Siffrorna stämmer".* Det här är exakt vad striden gör, i samma ordning som koden (`src/combat/combat_sim.gd`).
Där originalet (Siralim Ultimate) har en publicerad formel använder vi den; där den saknas står **vårt val**.
Underlaget finns i `docs/research/siralim.md` §12. I striden går det att se uträkningen bakom varje siffra:
tryck på en skadesiffra, eller öppna **Skadeloggen** och tryck på en rad.

**0.26: talen börjar små, som i Siralim.** Alla grundvärden för Health, Attack, Intelligence och Defense delades med 10
(Paladinen 90 Health, Brokk 115; kryptans vanliga fiender 40–80 innan djup, våning och sällskapets storlek skalar dem), och sköldens +10 Defense blev +1. Allt annat är procent och
multiplikatorer och är oförändrat, så striderna är desamma: samma antal träffar för att fälla någon och samma vinstchans
(mätt med botarna före och efter). Speed är oförändrad (bara kvoten räknas). Stats har en decimal; skada och helning
räknas med decimaler och avrundas till heltal en gång på slutet. Golvet på minst 1 skada togs bort: med de små talen gjorde det svaga träffar upp till dubbelt så starka (botarna: första nedstigningen 5 procentenheter svårare med golvet, oförändrad utan). En mycket svag träff kan därför göra 0, men den räknas ändå som en träff (om inte Barriären tog den), så att egenskaper som slår till vid en träff, t.ex. Domens kall, gör det som förut (`landed` i händelsen; utan det vann sällskapet bossen i kapellet 86 % i stället för 99 %). Belopp som DoT, HoT, Blöder och
våningsreglernas skada avrundas inte längre på vägen.

## 1. De fem statsen

| Stat | Gör |
|---|---|
| Health | Livet. 0 = stupad. |
| Attack | Anfall och fysiska förmågor. |
| Intelligence | Besvärjelser (spells), helningar och vissa egenskaper (t.ex. Barriär, Brinner). |
| Defense | Dras av från Attack eller Intelligence innan modifierarna. Indirekt skada drar bara av 20 %. |
| Speed | Startplatsen på tidslinjen, chansen att undvika och chansen till och storleken på krit. |

Statsen kommer från flera källor, som alla når striden och syns i hjältebladet:
**bas + nivåer + personlighet + artefakt + material (bärnsten) + Nether Stone.**

- Nivå (balans v1): styrkan är 1,2^(L − 1) upp till nivå 10, sedan steg på 13 % + 7 % · e^(−(L − 10)/10) mot nivån innan
  (`HeroStats.strength`); en stat är bas × (1 + tillväxt/30 % × (styrkan − 1)), personligheten ger en stat 40 % och en
  annan 20 % i stället för 30. Fienderna har samma styrka på sin nivå. Förr: +30 % av basvärdet per tillväxtnivå.
- Artefakt: typens stat, t.ex. svärd +5 % Attack. Varje artefaktnivå gör det 10 % starkare.
- Bärnsten: +6 % av statsen före artefakten per Stat-plats (en plats tar 5 bärnsten; tvåfärgad 3,6 % på var), gånger
  artefaktnivåns styrka.
- Nether Stone: sin egen procent av statsen före artefakten (inte gånger artefaktnivån).
- Health, Attack, Intelligence och Defense avrundas till en decimal (0.26, `CombatSim.snap_stat`; förut heltal, samma
  upplösning i förhållande till värdet), Speed till heltal. Material och Nether Stone behåller decimalerna och striden
  räknar med dem; de visas med en decimal när de inte är heltal (0.23.3, `HeroStats.shown`), och hjältebladets delar
  blir alltid den visade summan.

**Defense just nu** (`defense_now()`): Defense gånger auror. Försvara ×1,5 (+50 %), Provocera ×0,65 (−35 %),
Saltad jord ×0,8. Aldrig under 20 % av startvärdet (originalet).

## 2. Skadan

Först kommer en **variation**: varje träff slår ett tal mellan 0,90 och 1,10 (±10 %, vårt val).

**Anfall** (originalet):

    skada = (max(Attack × variation − Defense, 0) + 1 % av Attack × variation) × förmågans styrka

Exempel: Eira har 19,8 Attack, variationen blir 1,00, och Botgöraren har 2,2 Defense och försvarar sig
(×1,5 = 3,3): (19,8 − 3,3) + 0,2 = 16,7, × styrka 1,0 = 16,7, avrundat 17.

Den sista procenten gör att även en hjälte med lägre Attack än målets Defense alltid gör lite skada.

**Besvärjelse** (originalet):

    potency = Intelligence × nivåns procent (Liten 90 %, Måttlig 110 %, Stor 120 %, Massiv 130 %, Förödande 150 %) × variation
    skada   = max(potency − Defense × (1 − nivåns genomslag), 0) × förmågans styrka

Starkare nivåer bortser från en del av Defense (Måttlig 10 %, Stor 20 %, Massiv 30 %, Förödande 40 %).
*Vårt val:* besvärjelser mot hela fiendelaget har redan en lägre styrka i datan (0,5–0,7) i stället för
originalets ×0,25 efter Defense. *Vårt val:* en besvärjelse utan nivå (t.ex. fiendernas Glödskur och Benstorm) räknar
med 100 % av Intelligence och bortser inte från någon Defense.

**Indirekt skada** (Brinner, Förgiftad, Väktarens kall, Rotskott, våningsregler; originalet):

    skada = belopp × modifierare − 20 % av Defense

Defense dras alltså av *sist* och bara till en femtedel. Indirekt skada kan inte undvikas och blir aldrig krit.

**Fasta belopp** (t.ex. ett följdanfall för 50 % av träffen, eller Brinner = 30 % av kastarens Intelligence
per tur) räknas inte om mot Defense igen, men får modifierarna. Brinner och Förgiftad räknas ut när statusen läggs
och är sedan samma varje tur. *Vårt val:* ett följdanfall från en egenskap (Jägarinstinkt, Det andra hugget) är
ett **anfall** om datan inte säger "indirect": det kan undvikas och bli krit, men drar ingen Defense.

**Tillägg** (originalets "additional damage", t.ex. Bästa försvaret: +30 % av Defense) läggs på sist. Det går förbi
Defense och alla minskningar (originalet); hos oss går det också förbi ökningarna och kritten (*vårt val*).

**Avrundning** (*vårt val*): skadan avrundas till ett heltal efter modifierarna, kritten och Defense (0.26: inget golv på 1 längre).
Barriären tar sedan sin del, och resten dras från livet.

## 3. Modifierarna

Allt som ändrar skadan i procent: auror (Sårbar +50 %, Märkt +20 %, Försvarar −35 %, Försvagad −50 %, Styrka
och Välsignelse på nästa anfall), egenskaper (t.ex. Benrustning −30 % från attacker, Brynsten +12 %) och
laddningar. Originalets regel:

- **ökningar adderas:** +50 % och +20 % = +70 % (×1,7);
- **minskningar multipliceras:** −35 % och −30 % = ×0,65 × 0,70 = ×0,455;
- **varje minskning stannar vid −80 %.**

Sedan gäller: `skada × (1 + ökningar) × minskningarna`.

Resistent (bossar) ändrar inga modifierare: Sårbar ger +50 % även på en boss (originalet, se §5). *Före 0.23.3
stod här att debuffar fick halv effekt; det gällde före 0.22.*

## 4. Krit och undvikande (vårt val – originalets formel är inte publicerad)

Fartkvoten = egen Speed / målets Speed.

- **Krit-chans** = figurens chans vid lika fart (oftast 10 %) + 10 procentenheter per fördubbling av kvoten,
  mellan 0 och 50 %. Taggsten lägger till sin procent ovanpå.
- **Krit-skada** = +75 % + 125 % · log₃(kvot), minst +50 %. Det ger +75 % vid lika fart, +154 % vid dubbla
  farten och +200 % vid tredubbla (stämmer med originalets datapunkter).
- Bara anfall kan bli krit, aldrig besvärjelser, indirekt skada eller helningar.
- Kritten multiplicerar efter modifierarna: `grundskada × modifierare × (1 + krit-skada)` (*vårt val*; originalet
  säger bara att krit-bonusar adderas med varandra). Vildsint och Taggsten lägger till chans, aldrig skada.
- **Undvikande:** bara ett snabbare mål: 10 % per fördubbling av målets fart mot anfallarens, högst 30 %.
  Egenskaper (Hal sten, Gastens Eterisk) adderas, högst 75 %. Bara anfall kan undvikas.

## 5. Statusar (0.22)

En status är en buff eller en debuff (eller ett tillstånd som Försvarar och Provocerar). Den varar ett antal av
**ägarens egna turer** och räknas ned i början av ägarens tur. Läggs samma status på igen fylls varaktigheten på;
de staplas inte (originalet). Siffrorna är originalets (Siralim Ultimate, Codex), se `docs/research/siralim.md` §17.

**Buffar**

| Status | Original | Gör | Turer |
|---|---|---|---|
| Smidig | Agile | En extra, oberoende chans att undvika anfall: **25 %** (*vårt val*, originalet anger ingen siffra) | 3 |
| Arkan | Arcane | Nästa förmåga kostar ingen Charge | tills den används |
| Bärsärk | Berserk | +50 % skada | 3 |
| Defensiv | Defensive | Försvarar automatiskt i slutet av sin tur | 3 |
| Immun | Immune | Kan inte få debuffar | 1 |
| Livstörst | Leeching | Helas 25 % av skadan den gör | 3 |
| Läkning | Mending | Helas 25 % av sitt liv i början av sin tur | 3 |
| Beskyddad | Protected | Tar 50 % mindre skada | 3 |
| Pånyttfödd | Rebirth | Återuppstår med 50 % liv när den faller | 3 |
| Vildsint | Savage | En extra, oberoende chans till krit med anfall: **25 %** (*vårt val*) | 3 |
| Skyddsskal | Shelled | Upphäver nästa anfall eller besvärjelse | tills den träffas |
| Utmanande | Taunting | Provocerar automatiskt i slutet av sin tur | 3 |

**Debuffar** (Resistent = bossar)

| Status | Original | Gör | Turer | Resistent |
|---|---|---|---|---|
| Blöder | Bleeding | Skada = 30 % av *nuvarande* liv i början av varje tur | 3 | 10 % i stället |
| Fördärvad | Blighted | Kan inte helas; helning gör i stället skada = 50 % av helningen | 3 | – |
| Förblindad | Blind | Kan inte välja mål för anfall och förmågor mot en fiende (målet slumpas) | 3 | – |
| Brinner | Burning | Skada = 30 % av källans Intelligence varje tur | 3 | – |
| Förvirrad | Confused | 50 % chans att anfalla eller kasta skadliga förmågor på sina egna | 3 | – |
| Frusen | Frozen | Kan inte agera. 25 % chans att tina i början av sin tur, chansen dubblas varje tur | tills den tinar | dubbel chans |
| Förgiftad | Poisoned | Skada = 30 % av källans Attack varje tur | 3 | – |
| Hånad | Scorned | Kan inte anfalla. Tar bort Tystad | 1 | kan anfalla, −50 % skada |
| Tystad | Silenced | Kan inte använda förmågor. Tar bort Hånad | 1 | kan, −50 % skada |
| Sover | Sleeping | Kan inte agera förrän den tar skada | 3 | vaknar i början av sin tur |
| Snärjd | Snared | Fast längst ned på tidslinjen; 10 % chans att slita sig loss i början av *varje* figurs tur | 3 | 30 % |
| Förstenad | Stone | Kan inte undvika eller krita | 1 | halva chansen |
| Sårbar | Vulnerable | Tar 50 % mer skada | 3 | – |
| Försvagad | Weak | Gör 50 % mindre skada | 3 | – |

**Resistent** (originalet): bara statusarna med en Resistant-version ovan påverkas. Andra debuffar verkar fullt på
bossar. (Före 0.22 halverade vi alla debuffar på bossar; det var vårt eget.)

Våra egna statusar ligger kvar: Styrka och Välsignelse (nästa anfall), Märkt (+20 % skada tagen), Skyddad
(−25 %), Saltad jord (−20 % Defense), Barriär och Vrede. Helig sköld ger nu Beskyddad och Förnyelse ger Läkning.

**Ta bort:** *Dispel* tar bort alla buffar och debuffar på målet (originalet). *Rening* (vårt, effekten "purge") tar
bort debuffar, de senaste först; Helande ljus tar bort en. Vrede går inte att ta bort.

**Livstörst** (*vårt val* där originalet är okänt): bara liv som faktiskt förlorades räknas, alltså inte det
Barriären tog och inte överskott mot en nästan död fiende. Alla skadesorter räknas, även DoT som figuren lagt.
Helningens uträkning pekar på träffen.

Skada från statusar (Blöder, Brinner, Förgiftad, Fördärvad) räknas med modifierarna (t.ex. Sårbar); Brinner och
Förgiftad är indirekta (−20 % av Defense), Blöder och Fördärvads skada drar ingen Defense (*vårt val*).

**Tidslinjen:** en effekt kan flytta en figur **överst** (den får nästa tur). Den som stod överst skickas då till
botten, och den flyttades gränser per tur nollställs (originalet). **Snärjd** kan inte flyttas upp. En **boss** som
tvingas nedåt flyttas bara ett steg, och "till botten" fungerar inte på fiender i bosstrider (originalet). *Vårt
val:* samma figur kan flyttas till toppen högst en gång per runda (lika många turer som det finns levande
figurer), så att två effekter inte kan mata varandra i all oändlighet. Gränserna per tur (fem anfall,
besvärjelser och helningar) nollställs också varje gång figuren får turen.

## 6. Barriär

En Barriär tar skadan före livet. Den starkaste gäller, de staplas inte (originalet). Träffar som Barriären tar
helt sätter inte igång egenskaper. *Vårt val:* en Barriär är högst figurens max liv (originalet: 200 % av den högsta
staten).

## 7. Helning

    helning = Intelligence × förmågans styrka × variation × modifierare

Exempel: Helande ljus har styrka 2,3. Med 10,4 Intelligence och variationen 1,00 blir det 23,9, avrundat 24.

Helningar blir aldrig krit. Vissnad nåd (våningsregel) ger −40 %.

**Mattad helning** (strid-langd, vårt val; Siralim har det inte): en fiendes helning med samma förmåga eller egenskap
helar 15 % mindre för varje tidigare gång i striden, ned till 40 % (100, 85, 70, 55, 40, 40 … %). Hjältarnas helningar
mattas inte. Syns som modifieraren "Mattad helning" i skadeloggen (`CombatSim.heal_fade`, `heal_fade_min`).

**Förnyelse** (HoT) helar 70 % av kastarens Intelligence i början av målets tre nästa turer. *0.21:* tidigare var
det fast 45 och växte inte med nivåerna.

## 8. Artefaktens kast

Artefaktens förmåga slår till av sig själv vid typens handling (svärd vid Anfall …) med typens chans, gånger
artefaktnivåns styrka (högst 90 %). Kastet kostar inga Charges men räknas mot gränsen per tur, och skadan räknas
precis som om hjälten hade använt förmågan själv.

## 9. Fiender

**Hur många** (0.23.3, *vårt val*): ett sällskap möter högst en fiende mer än det har hjältar. Är mötet större
försvinner först dubbletter, sedan andra fiender, alltid bakifrån. Kvar blir alltid den första (våningens ledare),
bossar och en fiende som en annan behöver (Kultisten som gör biskopen immun). Troféerbjudandet och Övningsgårdens
lista visar samma fiender som striden (`CombatSim.enemy_lineup`).

Fiendernas stats räknas i den här ordningen, och avrundas efter varje steg:

1. bas × mötets skalning × djupet (+3 % per djup sedan 0.30.33, förr 8 %; inte Speed; Trollberget dessutom × (1 + 17 % per fiendedjup över 1), balans v2) × Portalens strid (×1,15) × profilens första
   nedstigning (se nedan). Båda kan gälla samtidigt. Health, Attack, Intelligence och Defense, inte Speed;
2. × sällskapets storlek (0.23.3, *vårt val*): ×0,45 för en hjälte, ×0,54 för två, ×0,64 för tre, ×1 för fyra (Health,
   Attack och Intelligence, inte Defense och Speed);
3. × nivån: +30 % per nivå (nivån = 5 × (djup − 1) + 2,25 + 1,5 per våning), även Speed;
4. elitvarianter: +25 % Health och +10 % Attack och Intelligence.

**Profilens första nedstigning** (0.24.1, *vårt val*, `RunState.FIRST_DESCENT_RAMP`): den allra första körningen gör
Paladinen och Imma ensamma, hela kryptan med dess tre våningar. Fienderna får en mjuk trappa per våning, som aldrig
följer hjältarnas nivå: ×0,70 på våning 1, ×0,88 på våning 2 och ×0,83 för Benfursten (bossen är svår i sig, så hans
tal är lägre än våning 2:s; elit-balans 2026-10-21: 0,81 → 0,83 när bossmötena blev mildare, Benfursten 1,06 → 1,02 och
biskopen 1,08 → 1,06, så att fyra hjältar klarar en körning i ungefär 40 % och den första nedstigningen står kvar på 71–79 %). Med en ny profils makron (botarna, `BALANS=forsta`, 200 körningar) vinns våning 1 nästan
alltid (100 %), våning 2 i 94 % av dem som når den och Benfursten i 88 %; hela nedstigningen i 83 %. Målet är ungefär
80 %. Från den andra nedstigningen gäller vanliga siffror (då kommer Syster Alva).
0.25: paladinen går ned ensam och Imma smiter efter först efter den första striden. Den striden gör paladinen ensam med
fienderna ×0,80 till (`RunState.FIRST_FIGHT_ALONE`, *vårt val*: ×0,70 × 0,80 = ×0,56 före sällskapets ×0,45), så att den
blir lika lätt som övningen.

## 10. Hjältebladets "Vad det betyder"

Bladet räknar med simulatorns egen funktion (`CombatSim.expected_damage`, och `expected_heal` för helningar) på
riktiga figurer mot den första fienden på valt djup: samma formler och samma egenskaper som i striden, med variationen
1,0 och utan krit. Sedan 0.23.3 räknar bladet med det valda sällskapet (fienden skalas efter dess storlek, §9) och med
Paladinens kall och perks. Ett test (`tests/test_numbers.gd`) kontrollerar att bladet och simulatorns medelvärde
stämmer.

## 11. Granskningen (0.23.3)

Formlerna ovan finns skrivna en gång till, oberoende av spelets kod, i `tests/numbers_reference.gd`. Granskningen
(`tests/numbers_audit.gd`) spelar seedade strider i kryptan och kapellet, djup 1–3, alla våningar, med 2–4 hjältar,
nivåer och personligheter, artefakter med bärnsten, trick och Nether Stones, slumpade statusar och våningsregler. För
varje skada, helning och undvikande räknas siffran om ur figurernas stats och statusar precis före träffen och jämförs
med siffran spelet visade och med texten i skadeloggen. Fiendernas och hjältarnas stats räknas om på samma sätt.

    godot --headless --path . --script res://tests/numbers_audit_report.gd

Testet `tests/test_numbers_audit.gd` kör ett urval (72 strider) varje gång testerna körs.

## 12. Där koden, dokumentet och originalet skiljer sig (granskningen 0.23.3)

Talen i tabellen är från före 0.26 (tio gånger större än nu).

| Vad | Originalet | Koden | Före 0.23.3 i dokumentet | Bedömning |
|---|---|---|---|---|
| Resistent och Sårbar | bara Resistant-versionerna | som originalet | §3: "halv effekt, Sårbar +25 %" | fel i dokumentet, rättat |
| Hjältebladets fiende | – | räknade mot en fiende skalad för en ensam hjälte (×0,45) | "samma som i striden" | **bugg, rättad**: bladet visade t.ex. 76 skada tagen mot Skelettkrigaren i stället för 209 |
| Hjältebladet och kallet | – | utan Paladinens kall och perks; helningen utan modifierare | "samma egenskaper" | **bugg, rättad** |
| Stats med decimaler | heltal | striden räknar med decimaler, bladet och Inspect visade dem avkortade (`%d`) | – | **bugg i visningen, rättad**: delarna blev inte summan, och en liten bärnsten syntes inte hos Smeden |
| Skadeloggen när Defense > Attack | – | visade "(125 − 139) × 0,55 = 0" | – | **bugg i texten, rättad**: nu "(125 − 139 → 0)" |
| Egenskapers helning av en stat | – | uträkningen visade bara "Grundbelopp" | – | rättat: visar "8 % av 900 Health" |
| Följdanfall | indirekt skada från egenskaper | anfall (krit, undvikande, ingen Defense) | listade som indirekt | vårt val, dokumentet rättat. *Fråga till VD:* ett följdanfall på en krit kan krita igen |
| Besvärjelser på alla fiender | ×0,25 efter Defense | lägre styrka i datan (0,5–0,7) | "0,5–0,6" | vårt val, siffran rättad |
| Besvärjelse utan nivå | – (alla har nivå) | 100 % av Int, inget genomslag | – | vårt val, nu dokumenterat |
| Variation ±10 % | ingen publicerad | ±10 % | ja | vårt val |
| Krit-chans och undvikande | formeln okänd | fartkvoten | ja | vårt val |
| Krit och modifierarna | krit-bonusar adderas | krit multiplicerar efter modifierarna | – | vårt val, nu dokumenterat |
| Minsta skada och avrundning | – | heltal, minst 1 (0.26: inget golv) | – | vårt val, nu dokumenterat |
| Barriärens tak | 200 % av högsta stat | max liv | – | vårt val, nu dokumenterat |
| Blöder hos resistenta | 66 % mindre (≈ 10,2 %) | 10 % | 10 % | vårt val (avrundat) |
| Blöder och Fördärvad | – | ingen Defense, men källans och målets modifierare | ja | vårt val |
| Sällskapets storlek | finns inte | ×0,45 / 0,54 / 0,64 / 1,0 för 1–4 hjältar (0.23.3) | saknades i §9 | vårt val, nu dokumenterat |
| Antalet fiender | mötet är detsamma | högst en fler än hjältarna (0.23.3) | – | vårt val, dokumenterat i §9. Övningsgårdens lista visade hela mötet: **rättat** (0.24) |
| Första nedstigningen | finns inte | en trappa per våning: ×0,70 / ×0,88 / ×0,83 för Benfursten (Health, Attack, Int, Defense), bara profilens första körning (0.24.1; ×0,85 överallt i 0.24) | – | vårt val, dokumenterat i §9 |
| Brinner och Förgiftad | 30 % av Int / Attack | räknas när statusen läggs | – | vårt val, nu dokumenterat |
| Helig kraft (+15 % per buff) | – | räknar inte Styrka/Välsignelse som förbrukas i samma träff | – | vårt val (ordningen i koden) |
| Klass stark/svag ×2/×½ | finns | finns inte | – | vårt val (inga klasser) |
| Gräns per tur | 15 (Calm Mode 5) | 5 | – | vårt val |

Allt annat som granskningen räknade om stämde: Anfall, besvärjelser med nivå och genomslag, indirekt skada,
modifierarna (ökningar adderas, minskningar multipliceras, golvet −80 %), krit-chans och krit-skada, undvikande med
egenskaper, Smidig, Vildsint, Förstenad, Barriär, Skyddsskal, Immun-egenskaperna, Defense med golvet 20 %, helningar,
Läkning, Förnyelse, Livstörst, Fördärvad, Blöder, Brinner, Förgiftad, Rotskott, våningsreglerna, artefaktens kast,
alla stat-källor och fiendernas skalning.
