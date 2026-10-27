# Gambits: makronas villkor som man förtjänar

VD 2026-10-27: "kör". Förslaget kommer från Claude-chatten (`docs/ideer/claude-chat-striden-och-gambits.md`, "Allra viktigast 1"),
med Final Fantasy XII som förebild. Siralim är en verktygslåda: där har man alla villkor från start, och här förtjänar man dem.
I spelets text heter det fortfarande **Makron**. VD har inte bestämt namnet, och "gambit" används bara i koden, datan och den här planen.

## Kärnan

En gambit ger ett **omdöme**, inte en förmåga. Handlingarna (Anfall, förmågorna, Försvara, Provocera) kan man alltid välja för
hand och alltid lägga i en rad. Det man förtjänar är **villkoren** och fler **platser**. Utan "liv under …" kan man ändå hela den
som håller på att dö, men då måste man se det själv.

## Beslut

1. **Villkoren ägs per profil** (`Profile.gambits`, id:n i `data/gambits.json`). Ett villkor täcker en familj av
   makrovillkor, till exempel `g_status` = har/saknar status och `g_immune` = kan skadas/är immun. Värdena är fria när man
   äger villkoret, till exempel liv under 10–100 % och vilken status som helst. *Vårt val*: i FF XII var varje tröskel en egen
   gambit, men vår editor har värdena i en lista, och 26 villkor att jaga räcker.
   Subjektet (denna hjälte, någon allierad, fiende 3 …) är också fritt.
2. **Startvillkor** (rarity `start`): **Lägst liv** (introts första rad), **Liv under …** och **Lever**. *Vårt val*: "Lever"
   motsvarar FF XII:s "Fiende: vem som helst".
3. **Kedjan** ("Pröva nästa rad") är en gambit (`g_chain`), trots att den står bland handlingarna. *Vårt val*: den är ett
   omdöme, inte något hjälten kan göra för hand.
4. **Följeslagarna lär ut sitt villkor** när de ansluter (`gambits.json` "teach", `Profile.recruit`): Imma lär ut buffar
   (hennes rad "om en fiende har en buff → anfall"), Alva kedjan, Brokk högst Defense, Eira status, Torun "tänker hela" och
   så vidare. Befrielserutan säger "Alva lär dig ett nytt villkor för makrona: …".
5. **Platser per hjälte** (*vårt val*, satt med botarna): 3 från start och +1 per två nivåer, högst 12
   (`Gambits.slots_for_level`: nivå 1–2 = 3, 3–4 = 4, 5–6 = 5 … nivå 19 = 12). En plats rymmer en enhet: en rad, eller en
   kedja med "pröva nästa rad" och raden den leder till. En avstängd rad tar sin plats, som i FF XII. En rad med ett villkor
   profilen inte äger tar ingen plats, eftersom ett oägt villkor inte kan stå i listan i FF XII. Den står kvar låst
   (`Gambits.line_states`). Det beslutet kom efter den första botkörningen, där låsta rader åt platserna (se Balans). Rader
   under den sista platsen står kvar men körs inte, och de syns som "Platsen öppnas på nivå N".
6. **Var villkoren finns** (`homes` i gambits.json): varje vanligt villkor har två eller tre hem bland kryptans och kapellets
   fiender. Tankvillkoren finns hos fiender som själva försvarar sig (Kistbäraren, Fanbäraren och Gravväktaren), och
   helarvillkoren i kapellet (Fördärvad diakon: Tänker hela, Häxa och Botgörare: debuffar). De sällsynta finns hos elit och
   boss: **Har stupat** ("när en allierad faller") hos Klockaren och Abbedissan, **På sin tur …** ("första turen") hos
   Benkolossen och Den svarta lansen, **Laddar** hos Benfursten och biskopen, och **Har väckts** hos Gravväckaren.
   Kistvillkoren (Bär en artefakt från djup 2, Djupets tecken från djup 1) finns i skattkistor.
7. **Droppen** (*vårt val*, `gambits.json` "drops"): efter en vunnen strid kan högst ett villkor droppa. Varje oägt villkor
   som har ett hem bland de besegrade får ett slag, de sällsyntaste först: vanligt 25 %, elit 60 %, boss 100 %. Annars finns
   en chans på 3 % till ett vanligt villkor var som helst (först 40 % och 4 %; botarna gav då 10 villkor redan under
   den andra nedstigningen). En kista ger ett kistvillkor från djupet med 50 % chans, annars ett
   vanligt med 12 % chans. Övningsgården ger inga villkor.
8. **Avstängda rader** (`enabled: false` på raden): `MacroRunner.decide` hoppar över dem, och i en kedja bryter de kedjan.
   Förklaringsloggen skriver "Rad N är avstängd".
9. **Vad striden kör** (`Gambits.playable`, `Run.macro_for`): de första `slots` raderna, utan avstängda och utan rader med
   oägda villkor. En kedja tas med hel eller inte alls. Botarna använder samma funktion.
10. **Gamla profiler förlorar ingenting** (`Profile.setup_gambits`): en profil som sparades före gambits (`gambits` saknas i
    progress.cfg) äger allt som står i dess sparade makron. Den får också minst så många platser som det längsta makrot
    (`gambit_slot_floor`). Då äger VD:s profil med fulla makron i praktiken allt den använder.
11. **Ledtrådar i Biblioteket**: knappen VILLKOR visar alla villkor. Ägda står i guld, och oägda visas med ryktet:
    "Det sägs att Klockaren vet när en allierad faller."
12. **Fynd**: segerskärmen visar ett guldkort "NY GAMBIT" ovanför fynden, med ljud. Skattkammaren skriver "Ny gambit: …".
13. **Gambitsidan** (macro_screen): varje rad är ett stort kort, ungefär en sjättedel av höjden, med villkoret till vänster
    och handlingen till höger, en stor PÅ/AV-knapp och en nivåbricka. Håll kvar tummen (0,35 s) så lyfts kortet och kan dras.
    Telefonen vibrerar när kortet släpps (`Input.vibrate_handheld`). Radeditorn behåller sökfältet och grupperna. Oägda
    villkor står där som låsta med sitt rykte, och de går inte att välja. Sidan fungerar också inbäddad i striden.

## Balans

Se tabellen nedan, som botarna har skrivit. `BALANS=forsta` och `BALANS=grotta` kör med en ny profils villkor när
`GAMBITS=ny` är satt (startvillkoren och det sällskapet har lärt ut, inga droppar; det är det svåraste fallet).
`tests/gambit_drops.gd` mäter hur snabbt villkoren kommer.

Kört 2026-10-27, 100 körningar per rad, djup 1. *Före* = main (alla villkor ägda, inga platser). *Efter* =
`GAMBITS=ny`: startvillkoren och det sällskapet har lärt ut, platser efter nivån och inga droppar. Det är det svåraste
fallet, eftersom en riktig profil har hittat fler villkor efter några strider. MACRO = en ny profils makron och
makroförslagen.

### Första nedstigningen och små sällskap (`BALANS=forsta`, MACRO)

| Realm | Rad | Före | Efter |
|---|---|---|---|
| Kryptan | 0.25: ensam, Imma efter strid 1 (profilens första nedstigning) | 44 % | 44 % |
| Kryptan | första nedstigningen (trappa) | 46 % | 46 % |
| Kryptan | Paladinen + Imma, nivå 3 | 31 % | 31 % |
| Kryptan | + Imma + Brokk, nivå 3 | 51 % | 53 % |
| Kryptan | andra, nivå 3, en fånge | 33 % | 26 % |
| Kryptan | ny profil nivå 1, befriar fångar | 10 % | 7 % |
| Kapellet | 0.25: ensam, Imma efter strid 1 | 96 % | 96 % |
| Kapellet | första nedstigningen (trappa) | 96 % | 96 % |
| Kapellet | Paladinen + Imma, nivå 3 | 69 % | 69 % |
| Kapellet | + Imma + Brokk, nivå 3 | 49 % | 45 % |
| Kapellet | andra, nivå 3, en fånge | 41 % | 43 % |
| Kapellet | ny profil nivå 1, befriar fångar | 15 % | 16 % |

### Grottan, kryptan och kapellet (`BALANS=grotta`, MACRO)

| Realm | Rad | Före | Efter |
|---|---|---|---|
| Kryptan | första: ensam, Imma efter strid 1 | 44 % | 44 % |
| Kryptan | Paladinen + Imma, nivå 3 | 31 % | 31 % |
| Kryptan | 4 hjältar, *fulla* startmakron, nivå 3 | 6 % | 0 % |
| Kapellet | första: ensam, Imma efter strid 1 | 96 % | 96 % |
| Kapellet | Paladinen + Imma, nivå 3 | 69 % | 69 % |
| Kapellet | 4 hjältar, *fulla* startmakron, nivå 3 | 0 % | 0 % |

**Så ska tabellen läsas**

- **En ny profils väg ändras inte.** Profilens första nedstigning ligger på 44 % i kryptan och 96 % i kapellet, före och
  efter, eftersom Paladinens första rad och Immas rader bara använder startvillkoren och Immas Buff. Raderna med fångar
  ligger inom ±7 enheter, vilket är brus vid 100 körningar.
- **Målet "ungefär 80 %" nås inte ens före ändringen.** CLAUDE.md anger 91 % för kryptan, men main ger i dag 44 %, och det
  beror inte på gambits. Någon senare balansändring har sänkt kryptan, och det bör ses över för sig.
- **Raden "4 hjältar med fulla startmakron" är konstgjord.** Den kör de långa startmakrona i `data/macros.json`, där varannan
  rad behöver ett villkor en ny profil inte har. En ny profil får aldrig de makrona, eftersom `Run.starter_lines` ger två
  rader och reservanfallet. Raden visar ändå en verklig risk: en hjälte vars ägda rader slutar passa (Charges slut) väntar.
- **TUNED** (de förbättrade botmakrona) är skrivna med alla villkor och tolv rader. Med en ny profils villkor och tre
  platser står Paladinen ensam ibland stilla. Därför räknas bara MACRO. Den första körningen, där oägda rader tog platser,
  gav TUNED 0–3 % i "ensam".
- **Platsräkningen ändrades efter den första körningen** (beslut 5): oägda rader tar ingen plats, och en kedja tar en.
  Före den ändringen var MACRO-raderna desamma, men Alvas anfall hamnade utanför hennes tre platser.

### Hur snabbt villkoren kommer (`tests/gambit_drops.gd`, 40 karriärer, MACRO)

En ny profil: kryptan djup 1 ×2, kapellet, kryptan, kapellet, sedan djup 2 ×4 och kryptan djup 3. Bara funna villkor räknas,
inte de tre startvillkoren och inte det följeslagarna lär ut.

| Villkor funna | Vunna strider (median, 25–75 %) | Nedstigning (median) |
|---|---|---|
| 3 | 3 (2–4) | 1 |
| 6 | 8 (7–10) | 1 |
| 10 | 18 (15–20) | 3 |

| Efter nedstigning | 1 | 2 | 3 | 4 | 5 | 6 | 8 | 10 |
|---|---|---|---|---|---|---|---|---|
| Funna villkor (av 23) | 6,4 | 9,8 | 14,2 | 16,1 | 17,8 | 19,4 | 20,2 | 20,7 |
| Vunna strider | 9 | 18 | 27 | 36 | 46 | 55 | 72 | 88 |

Med 40 % och 4 % (det första förslaget) kom 10 villkor efter 14 strider och 18 efter fem nedstigningar. Det var för fort.
De sällsynta (Kedja, På sin tur …, Bär laddningen, Har väckts) hittas i 16–35 av 40 karriärer efter tio nedstigningar.

**Nackdelen:** 26 villkor räcker ungefär sex nedstigningar för en spelare som går ned ofta. Därefter finns bara de
sällsynta kvar att jaga. Fler villkor bör få hem i Lunden och Trollberget, och villkor som läser fiendernas avsikter
("tänker anfalla Paladinen") är förslagets egen styrka. Det är ett eget nästa steg.
