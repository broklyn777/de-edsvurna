# Egenskaper som skapar kombinationer – ChatGPT:s research (jobb H, 2026-10-21, sammanfattat)

Underlag, inte bestämt. Hela svaret låg i chatten; här det vi behöver.

## Taxonomi (Siralim Ultimate, SÄKERT med exempel)
Startmotor (The Bearon: Provoke efter stridsstart), återkommande trigger (Sand Giant: läker vid varje varelses turstart),
"efter X gör Y" (Martyaxwar: spell → två attacker), omvandling (Clairvoyant Spirit: läkning → skada), byte av skalande stat
(Ceaseless Maker: skada på Defense), skalning med stridens händelser (Ruby Carbuncle: +Int per kastad spell),
resursbefrielse (Djinn Arcanomancer: inga Charges), tillgång till handlingar (Wisp Watcher: kastar fem spells vid
turstart), Timeline (Mimic: börjar överst), aura/villkorsgivare (Ebony Ent: alltid Mending), spridare (Blood Slime),
familjeskalning och familjemanipulation (Diabolic Fortitude/Revolution), reaktionsförstärkare (Nadin: dödseffekter
dubbelt), motståndarmotor (Recompense: skada när man blir anfallen), förbud som formar bygget (Starless).
**Tips:** registrera per egenskap vilken händelse den behöver, vilken den skapar, vem den gäller och vad som stoppar den.

## Kända kombinationer (urval)
- Mimic + Wisp Watcher + Djinn Arcanomancer: börja först, kasta fem spells, gratis. Startare + motor + möjliggörare.
- Martyaxwar + Magma Construct (+ Lunar Hemomancer): attack → spell → attacker, begränsas av action limits.
- Nix Shadowjumper + Unicorn Vivifier (+ Terror Wight): en allierads död → attacker → återupplivning.
- Sand Giant + Blood Slime + Clairvoyant Spirit: tid → läkning → spridd läkning → skada.
- **Ebony Ent + Efflorescent Ent:** permanent tillstånd + belöning för tillståndet. Enkel, läsbar tidig kombo.
- **Dryad Vindicator + Dolor Sin:** debuff → statförlust → debuff (en klassiker).
- Ruby Carbuncle + Djinn Pyromancer, Diabolic-familjen, Bearon + Water Salamander.

## Tumregler (GISSNING)
Ingång och utgång; flera möjliga partners; eget värde även ensam; tredje delen löser olika problem (start, pålitlighet,
uthållighet); variera vad som omvandlas; exakt räckvidd och händelsetyp; kombinationen ska påverka ett beslut; synlig
orsak och verkan; korta tydliga kedjor slår långa på mobil.

## Vad bröt Siralim (SÄKERT)
0.5.0: stats ändras högst 15 gånger per tur (mot oändliga kedjor), Fortification max 90 %. 0.9.0: tidslinjeflytt en gång
per tur, Lust + Book of the Lost begränsade, Carnal Genesis 30→10 %. Relic som gav odödlighet: tre gånger per strid. 2.0:
rekursiv overkill rättad, Friendly Fire kan inte kasta sig själv, enskild skadereduktion högst 80 %, action limits 15 per
tur, återupplivning högst 10 per strid. **Ett tak på antal stoppar inte enorma värden** – begränsa också hur värdet växer.

## Tjugo idéer (GISSNING)
Skydd (Vakteld, Sköldstöt, Plåster på plåt, Håll ut vän), markering (Spanaröga, Samordnat skott, Vägvisaren, Snabba
fötter), eld/läkning (Glöd i hammaren, Blåsbälg, Hjälpsam hand, Varmt tack), resurser (Fokus 0–3: Ett steg i taget,
Genomtänkt kraft, Andrum, Reserv i fickan, Växelspel, Färdigställ), gruppvillkor (Samlad trupp, Stadig hand: skada på
Defense medan man har sköld). Fjorton par, t.ex. Vakteld + Sköldstöt, Spanaröga + Samordnat skott, Andrum + Genomtänkt kraft.

## Andra trofé-platsen
Siralim: egen + två från Fusion = 2, Tier 15 ger den tredje. Samma egenskap räknas inte två gånger på samma varelse.
Guider: uppgradera stödvarelser till T15 för platsen och stanna där. 2→3 egenskaper per hjälte: 28 → 66 möjliga par i
ett lag om fyra. Förslag: fullvärdiga troféer, inga dubbletter på samma hjälte, definiera kedjor innan, var återhållsam
med att återställa Charges, balansera inte bara med mer fiendeliv.

## Bedömning (huvudtråden)
- Vi har redan de viktigaste skydden: kedjor högst 4 steg, aldrig sig själv, `once_per_turn`, `TURN_LIMIT`, Barriär
  sätter inte igång något. Saknas: tak på hur värden växer (statökningar per tur, skadereduktion max 80 %).
- Idéerna med en ny resurs (Fokus) skulle jag inte ta – Siralim klarar sig med statusar. Mod ≈ vår Styrka/Vildsint,
  Markerad finns (Ronjas Märkt), sköld = Barriär. Många idéer går att göra med det vi har.
- Bäst för oss: mönstret **tillstånd + belöning** (Ebony + Efflorescent) som tidiga, läsbara kombos, och **debuff-loopen**
  som en elitfiendes trofé. Dela upp troféerna i "startare", "motor" och "utdelning" när vi ser över samlingen.
- "Behöver/skapar/vem/stopp" per egenskap i traits.json skulle ge oss "Passar ihop med" (jobb F, förslag 3) gratis.
- Andra trofé-platsen: bygg den (artefaktnivå 6), inga dubbletter på samma hjälte, mät med botarna.
