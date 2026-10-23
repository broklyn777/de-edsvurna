# Svårighetskurvan (0.30.17-test)

2026-10-23. Botar spelar en profil i taget, från en ny profil genom 18 nedstigningar i rad, med spelets riktiga flöde.
Spelkoden är inte ändrad. Läget heter `SOAK=karriar` och ligger i `tests/soak.gd`.

```bash
SOAK=karriar godot --headless --path . --script res://tests/soak.gd -- --runs=80 --descents=18
SOAK=karriar godot --headless --path . --script res://tests/soak.gd -- --seed=30 --descents=18 --verbose   # en profil
```

80 profiler × 18 nedstigningar = 1 440 körningar tog 4 min 42 s.

## Hur boten spelar

- **Start:** en ny profil med introts svärd (Rättfärdigt slag, nivå 1) och en ny profils makron. Första nedstigningen
  sker ensam, och Imma ansluter efter första striden.
- **Makron:** när en ny sorts hjälte ansluter läggs makroförslaget till (LÄGG TILL RADEN). Boten är MACRO utan inställda
  makron och utan slumpade handlingar. Den ger aldrig upp och går aldrig hem.
- **I grottan:** boten slåss mot allt den kliver på och tar elitgrupper när questen kräver det (`Bot._bot_target`,
  "simple"). Lägereld, helgedomar, föremål och troféval sker som i soak-testet (slumpat). Burna troféer behålls mellan
  körningarna (`keep_worn`).
- **Erfarenhet:** `Profile.grant_xp`, med ikapphämtning och även till de som stupat. Lärjungar befrias ur fånge-rummen
  och ansluter.
- **Hemma efter varje nedstigning:**
  - Smedjan: svärdet till nivå 3 (introts uppdrag), sedan ett svärd med hjältens första förmåga till den som saknar
    artefakt, sedan en nivå på den lägsta artefakten, så länge silvret räcker.
  - Den billigaste perken som går att köpa.
  - Sällskapet blir de tre följeslagarna med högst nivå.
- **Djup:** ett djup djupare efter en klarad körning och ett grundare efter två förluster i rad.
- **Realm:** växlar mellan kryptan och kapellet varje gång (första nedstigningen alltid i kryptan).
- **Inte med:** instabilitet (0) och löften (inget löfte).

## Per nedstigning

Fiendernas väntade nivå är 3 / 8 / 13 / 18 / 23 / 28 / 33 på djup 1–7 (`HeroStats.enemy_level`).

| Ned | Djup (snitt; fördelning) | Nivå | Vinst | Strider | Silver | Hjältar | Förluster (flest först) |
|---|---|---|---|---|---|---|---|
| 1 | 1,0 (d1 80) | 1,0 | **96 %** | 10,1 | 232 | 1,0 | v1 vanlig 2, v2 boss 1 |
| 2 | 2,0 (d1 3, d2 77) | 4,7 | **26 %** | 6,0 | 129 | 2,0 | v1 elit 27, v1 Nemesis 23, v2 boss 5 |
| 3 | 2,2 (d2 62, d3 18) | 6,4 | **34 %** | 7,4 | 187 | 2,5 | v1 elit 18, v2 boss 14, v1 Nemesis 11 |
| 4 | 2,1 (d1 34, d2 2, d3 43, d4 1) | 8,3 | 54 % | 8,5 | 206 | 2,9 | v1 Nemesis 17, v2 boss 9, v1 elit 8 |
| 5 | 2,5 (d2 47, d3 23, d4 9) | 9,6 | 55 % | 8,6 | 236 | 3,2 | v2 boss 10, v1 elit 10, v1 Nemesis 7 |
| 6 | 2,8 (d2 28, d3 40, d4 11) | 11,2 | 43 % | 7,4 | 208 | 3,5 | v1 elit 20, v2 boss 13, v1 Nemesis 13 |
| 7 | 3,1 (d3 63, d4 12) | 12,4 | 33 % | 8,4 | 252 | 3,7 | v2 boss 24, v1 Nemesis 10, v2 elit 8 |
| 8 | 3,1 (d2 25, d3 23, d4 30) | 13,9 | 55 % | 8,6 | 258 | 3,9 | v1 elit 13, v1 Nemesis 12, v2 boss 9 |
| 9 | 3,5 (d3 30, d4 35, d5 6) | 15,4 | 45 % | 8,1 | 262 | 3,9 | v2 boss 17, v1 elit 12, v2 elit 7 |
| 10 | 3,7 (d3 35, d4 35, d5 9) | 16,7 | 51 % | 8,0 | 263 | 4,0 | v1 Nemesis 20, v1 elit 11, v2 boss 8 |
| 11 | 4,0 (d4 53, d5 13) | 17,9 | 38 % | 8,4 | 292 | 4,0 | v2 boss 16, v1 Nemesis 10, v1 elit 10 |
| 12 | 4,2 (d4 34, d5 25) | 19,3 | 56 % | 8,4 | 295 | 4,0 | v1 Nemesis 14, v1 elit 11, v2 boss 8 |
| 13 | 4,5 (d4 26, d5 32, d6 9) | 20,6 | 44 % | 8,7 | 313 | 4,0 | v2 boss 16, v1 Nemesis 9, v2 elit 6 |
| 14 | 4,8 (d4 26, d5 40, d6 10) | 22,0 | 36 % | 7,5 | 271 | 4,0 | v1 Nemesis 19, v1 elit 17, v2 boss 13 |
| 15 | 4,9 (d4 23, d5 42, d6 13) | 23,1 | 45 % | 9,5 | 380 | 4,0 | v2 boss 23, v1 Nemesis 8 |
| 16 | 5,1 (d4 15, d5 41, d6 19) | 24,6 | 51 % | 8,3 | 329 | 4,0 | v1 elit 13, v2 boss 12, v1 Nemesis 11 |
| 17 | 5,4 (d5 30, d6 33, d7 6) | 25,8 | 38 % | 7,8 | 304 | 4,0 | v2 boss 14, v1 elit 13, v1 Nemesis 11 |
| 18 | 5,5 (d5 27, d6 38, d7 7) | 26,9 | 43 % | 7,7 | 325 | 4,0 | v1 elit 17, v1 Nemesis 15, v2 boss 12 |

Nivå = sällskapets snittnivå när nedstigningen börjar. Silver = vunnet i körningen. v1/v2 = våning 1/2.

## Per djup och Realm (alla 1 440 körningar)

| Djup | Kryptan: vinst (körningar, nivå) | Kapellet: vinst (körningar, nivå) | Väntad nivå |
|---|---|---|---|
| 1 | 96 % (84, 1,3) | **100 %** (37, 6,4) | 3 |
| 2 | 63 % (120, 7,5) | 52 % (133, 7,4) | 8 |
| 3 | 44 % (157, 12,6) | 51 % (163, 12,8) | 13 |
| 4 | 43 % (169, 18,1) | 47 % (159, 18,3) | 18 |
| 5 | 28 % (125, 22,4) | 37 % (145, 23,0) | 23 |
| 6 | **14 %** (57, 26,0) | **20 %** (71, 26,6) | 28 |
| 7 | **0 %** (8, 29,8) | **8 %** (12, 30,2) | 33 |

294 av 1 440 nedstigningar (20 %) sker på ett djup som redan är klarat, alltså slipande.

## Slutsatser

1. **Väggen kommer direkt, vid nedstigning 2–3.** Efter första nedstigningen (96 %) går man till djup 2 på nivå 4,7
   med två hjältar, mot fiender på nivå 8, och vinner 26 %. Därefter 34 %. Nästan alla förluster sker vid våning 1:s
   elitgrupp eller Nemesis (50 av 59 i nedstigning 2). En ny spelare som gör det naturliga, går djupare, förlorar två
   eller tre gånger i rad precis efter introt.
2. **Djup 1 är en platå** (kryptan 96 %, kapellet 100 %). Den som backar slipar där tills nivån räcker: vid
   nedstigning 4 står 34 av 80 profiler på djup 1 igen. Där finns inget att lära sig, bara erfarenhet att samla.
3. **Mitt i spelet balanserar kurvan sig själv kring 45 %**, från nedstigning 4 till 18. Sällskapet ligger ungefär på
   fiendernas väntade nivå på djup 2–4, då vinner MACRO-boten 43–63 %, och boten pendlar mellan två djup. Sällskapet är
   fullt (fyra hjältar) från ungefär nedstigning 9.
4. **Taket ligger vid djup 6–7.** Där halkar nivån efter fiendernas: 26 mot 28 på djup 6 och 30 mot 33 på djup 7.
   Vinsten faller till 14–20 % och sedan 0–8 %. Erfarenheten per körning, ungefär +1,3 nivåer per nedstigning, räcker
   inte för att följa fiendernas +5 nivåer per djup. Här skulle startmakrona fastna. En spelare med inställda makron,
   troféer och artefaktmaterial kommer längre, men botarna visar var den rena nivåkurvan tar slut.
5. **Förlusterna fördelar sig jämnt** mellan våning 1:s elitgrupp, våning 1:s Nemesis (jaktquesten) och bossen på
   våning 2. Nemesis på våning 1 fäller lika många som bossen, och i de små sällskapen tidigt fler.

### Frågor till VD (inga beslut)

- Ska djup 2 kännas som ett steg uppåt eller som en vägg? Ett sätt är en mjukare trappa i början (fiendernas nivå
  3 / 6 / 10 / 15 …). Ett annat är att kampanjkartan föreslår att man stannar på djup 1 tills sällskapet har tre hjältar.
- Ska våning 1:s Nemesis och elitgrupp vara mildare för sällskap med två hjältar? `PARTY_SCALE` gäller redan vanliga
  strider. Elitgrupperna har en egen mildring bara under första nedstigningen.
- Taket vid djup 6–7: ska erfarenheten följa djupet hårdare (i dag 17 × rumstyp × djup²), eller är det meningen att
  makron och byggen bär resten, som i Siralim?
- Ska platån på djup 1 ge något mer än erfarenhet, så att slipandet inte blir tomt?

## Fel som karriären hittade

**Medel: ett dödläge utan våningsregler** (frö 30, nedstigning 2, chapel_e4 på djup 2). Imma har stupat och Paladinen
står ensam med 10 av 225 liv mot Asketen. Asketen försvarar sig och samlar Fastans Defense (+8 % per tur, högst 5
gånger). Paladinens anfall gör 0 skada, och Asketen skadar inte heller Paladinen. Striden fortsätter efter 1 500 turer.
Kaosvindens rättelse täcker inte detta. Spelaren kommer bara ur med GE UPP.

```bash
SOAK=karriar godot --headless --path . --script res://tests/soak.gd -- --seed=30 --descents=2 --verbose
```

Fråga: en minsta skada på 1 för en träff, eller en turgräns?

## Begränsningar

- Botens val i grottan och lägret är enkla: troféer slumpas, inga material sätts in, ingen trofé-plats används och
  inga löften tas. En riktig spelare ligger troligen över kurvan, särskilt från djup 4.
- Bara kallet Domens kall (profilens förval) och den billigaste perken.
- Instabilitet 0 hela vägen.
- Speltiden är inte mätt här. En körning är 6–10 strider (se provspel-0.30.14).
