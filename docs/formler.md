# Formlerna – hur siffrorna räknas

*0.21 "Siffrorna stämmer".* Det här är exakt vad striden gör, i samma ordning som koden (`src/combat/combat_sim.gd`).
Där originalet (Siralim Ultimate) har en publicerad formel använder vi den; där den saknas står **vårt val**.
Underlaget finns i `docs/research/siralim.md` §12. I striden går det att se uträkningen bakom varje siffra:
tryck på en skadesiffra, eller öppna **Skadeloggen** och tryck på en rad.

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

- Nivå: varje nivå ger +30 % av basvärdet (personligheten ger en stat 40 % och en annan 20 %).
- Artefakt: typens stat, t.ex. svärd +5 % Attack. Varje artefaktnivå gör det 10 % starkare.
- Bärnsten: +6 % av statsen före artefakten per sten (tvåfärgad 3,6 % på var), gånger artefaktnivåns styrka.
- Nether Stone: sin egen procent.

**Defense just nu** (`defense_now()`): Defense gånger auror. Försvara ×1,5 (+50 %), Provocera ×0,65 (−35 %),
Saltad jord ×0,8. Aldrig under 20 % av startvärdet (originalet).

## 2. Skadan

Först kommer en **variation**: varje träff slår ett tal mellan 0,90 och 1,10 (±10 %, vårt val).

**Anfall** (originalet):

    skada = (max(Attack × variation − Defense, 0) + 1 % av Attack × variation) × förmågans styrka

Exempel: Eira har 198 Attack, variationen blir 1,00, och Botgöraren har 22 Defense och försvarar sig
(×1,5 = 33): (198 − 33) + 2 = 167, × styrka 1,0 = 167.

Den sista procenten gör att även en hjälte med lägre Attack än målets Defense alltid gör lite skada.

**Besvärjelse** (originalet):

    potency = Intelligence × nivåns procent (Liten 90 %, Måttlig 110 %, Stor 120 %, Massiv 130 %, Förödande 150 %) × variation
    skada   = max(potency − Defense × (1 − nivåns genomslag), 0) × förmågans styrka

Starkare nivåer bortser från en del av Defense (Måttlig 10 %, Stor 20 %, Massiv 30 %, Förödande 40 %).
*Vårt val:* besvärjelser mot hela fiendelaget har redan en lägre styrka i datan (0,5–0,6) i stället för
originalets ×0,25 efter Defense.

**Indirekt skada** (följdanfall, Brinner, våningsregler; originalet):

    skada = belopp × modifierare − 20 % av Defense

Defense dras alltså av *sist* och bara till en femtedel. Indirekt skada kan inte undvikas och blir aldrig krit.

**Fasta belopp** (t.ex. ett följdanfall för 50 % av träffen, eller Brinner = 30 % av kastarens Intelligence
per tur) räknas inte om mot Defense igen, men får modifierarna.

## 3. Modifierarna

Allt som ändrar skadan i procent: auror (Sårbar +50 %, Märkt +20 %, Försvarar −35 %, Försvagad −50 %, Styrka
och Välsignelse på nästa anfall), egenskaper (t.ex. Benrustning −30 % från attacker, Brynsten +12 %) och
laddningar. Originalets regel:

- **ökningar adderas:** +50 % och +20 % = +70 % (×1,7);
- **minskningar multipliceras:** −35 % och −30 % = ×0,65 × 0,70 = ×0,455;
- **varje minskning stannar vid −80 %.**

Sedan gäller: `skada × (1 + ökningar) × minskningarna`.

Resistent (bossar): en debuff får halv effekt (Sårbar +25 % i stället för +50 %).

## 4. Krit och undvikande (vårt val – originalets formel är inte publicerad)

Fartkvoten = egen Speed / målets Speed.

- **Krit-chans** = figurens chans vid lika fart (oftast 10 %) + 10 procentenheter per fördubbling av kvoten,
  mellan 0 och 50 %. Taggsten lägger till sin procent ovanpå.
- **Krit-skada** = +75 % + 125 % · log₃(kvot), minst +50 %. Det ger +75 % vid lika fart, +154 % vid dubbla
  farten och +200 % vid tredubbla (stämmer med originalets datapunkter).
- Bara anfall kan bli krit, aldrig besvärjelser, indirekt skada eller helningar.
- **Undvikande:** bara ett snabbare mål: 10 % per fördubbling av målets fart mot anfallarens, högst 30 %.
  Egenskaper (Hal sten, Gastens Eterisk) adderas, högst 75 %. Bara anfall kan undvikas.

## 5. Barriär

En Barriär tar skadan före livet. Den starkaste gäller, de staplas inte (originalet). Träffar som Barriären tar
helt sätter inte igång egenskaper.

## 6. Helning

    helning = Intelligence × förmågans styrka × variation × modifierare

Exempel: Helande ljus har styrka 2,3. Med 104 Intelligence och variationen 1,00 blir det 239.

Helningar blir aldrig krit. Vissnad nåd (våningsregel) ger −40 %.

**Förnyelse** (HoT) helar 70 % av kastarens Intelligence i början av målets tre nästa turer. *0.21:* tidigare var
det fast 45 och växte inte med nivåerna.

## 7. Artefaktens kast

Artefaktens förmåga slår till av sig själv vid typens handling (svärd vid Anfall …) med typens chans, gånger
artefaktnivåns styrka (högst 90 %). Kastet kostar inga Charges men räknas mot gränsen per tur, och skadan räknas
precis som om hjälten hade använt förmågan själv.

## 8. Fiender

Fiendernas stats = bas × mötets skalning × djupet (+8 % per djup, inte Speed) × nivån (+30 % per nivå från
djupets och våningens nivå, även Speed). Elitvarianter har +25 % Health och +10 % Attack och Intelligence.

## 9. Hjältebladets "Vad det betyder"

Bladet räknar med simulatorns egen funktion (`CombatSim.expected_damage`) på riktiga figurer mot den första
fienden på valt djup: samma formler och samma egenskaper som i striden, med variationen 1,0 och utan krit. Ett
test (`tests/test_numbers.gd`) kontrollerar att bladet och simulatorns medelvärde stämmer.
