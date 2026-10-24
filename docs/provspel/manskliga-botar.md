# Mänskligare karriärbotar

2026-10-24, gren `botar-manskliga` (från `test-0.30`, efter 0.30.35 med Provocera- och djupmätningarna). Spelet är
oförändrat. Det nya läget ligger i `tests/soak.gd`.

```bash
KARRIAR_REALM=chapel SOAK=karriar_mansklig godot --headless --path . --script res://tests/soak.gd -- --runs=50 --descents=40
HUMAN_OFF=sockets,trophies KARRIAR_REALM=crypt SOAK=karriar_mansklig godot --headless --path . --script res://tests/soak.gd -- --runs=30 --descents=20
```

## Hur den mänskliga boten spelar

Grunden är densamma som i `SOAK=karriar` (`svarighetskurva.md`): en ny profil genom introt, startmakron med
makroförslagen, MACRO-boten i striden, smedjan (svärdet till nivå 3, ett svärd till den som saknar artefakt, sedan en
nivå på den lägsta artefakten), den billigaste perken så länge poängen räcker, och sällskapet är de tre följeslagarna
med högst nivå. Det nya:

- **Tränar efter en förlust.** Förlorar boten på djup N går den till N − 1 och stannar där tills sällskapets snittnivå
  når den väntade nivån på N (`HeroStats.expected_level`). Sedan försöker den igen. Förlorar den två gånger i rad
  under träningen går den ett djup till ned. Förlorar den på N igen efter träningen tränar den 3 nivåer längre per nytt
  försök (`TRAIN_EXTRA`).
- **Material.** Efter smedjan sätter den bärnsten i lediga Stat-platser efter hjältens roll: blå för helare och stöd,
  grå för tankar, röd för de andra, grön i andra hand. Den sätter trick i Trick-platser och den Nether Stone med högst
  sällsynthetstal i en tom Nether-plats.
- **Troféer.** I Förberedelser bär varje hjälte den bästa trofén ur samlingen; elit och boss går före vanliga. Efter
  en strid tar den den bästa av de erbjudna. Vid en lägereld byter den till en bättre ur körningen, och den tar alltid
  lägereldens Charges.
- **Perks** köps när det finns poäng, som förut.
- **En Realm per profil** (`KARRIAR_REALM`). Den första nedstigningen är introts krypta, och sedan spelar profilen
  bara den valda Realmen.
- **Delarna kan stängas av** med `HUMAN_OFF=sockets,trophies,campfire,train`, för att se vad som bär.

**Speltiden är en uppskattning.** `playtime.cfg` på Mac:en är tom, så den finns inga riktiga mätningar ännu. Modellen
räknar med 2,5 s per tur i striden (alla figurers, AUTO i 1×), 1,2 s per steg i grottan, 10 s per strid (in, ut och
segerskärm) och 2 min hemma per nedstigning. Den som spelar manuellt är troligen 2–3 gånger långsammare.
Nedstigningar och strider kan räknas om när `Playtime` har riktiga siffror.

## Resultat: 50 profiler × 40 nedstigningar per Realm

Nedstigningar räknas från profilens början, introts nedstigning inräknad, till första gången djupet klaras. Siffrorna är
median (kvartiler). "Fast" är profiler som nådde djupet men inte klarade det inom 40 nedstigningar.

| Djup | Kryptan: ned / timmar | Kapellet: ned / timmar | Trollberget: ned / timmar | Kapellet: försök, träning, fast |
|---|---|---|---|---|
| 2 | 2 / 0,4 | 2 / 0,4 | 3 / 0,6 | 1, 0, 0 |
| 3 | 4 / 0,9 | 7 / 1,3 | 5 / 0,9 | 2, 1, 0 |
| 4 | 8 / 1,5 | 11 / 1,9 | 6 / 1,2 | 2, 2, 0 |
| 5 | 9 / 1,9 | 14 / 2,5 | 8 / 1,4 | 2, 1, 0 |
| 6 | 10 / 2,2 | 17 / 3,1 | 9 / 1,7 | 2, 1, 0 |
| 7 | 11 / 2,5 | 20 / 3,7 | 11 / 2,0 | 2, 2, 0 |
| 8 | 14 / 2,8 | 23 / 4,1 | 12 / 2,2 | 1, 0, 0 |
| 10 | 18 / 3,8 | 27 / 4,9 | 15 / 2,6 | 1, 0, 0 |
| 12 | 21 / 4,3 | 33 / 6,0 | 18 / 3,0 | 1, 0, **4** |
| 13 | 22 / 4,6 | 34 / 6,4 | 19 / 3,2 | 1, 0, **6** |
| 14 | 23 / 4,9 | 37 / 6,9 | 20 / 3,4 | 1, 0, **12** |
| 15 | 24 / 5,1 | 38 / 6,9 | 21 / 3,5 | 1, 0, **9** |

| | Kryptan | Kapellet | Trollberget |
|---|---|---|---|
| Högsta klarade djup efter 40 nedstigningar | d17–30, oftast d20–23 | d11–18, oftast d12–14 | d16–34, oftast d21–25 |
| Sällskapets nivå vid slutet | 99,7 | 66,7 | 106,4 |
| Strider och uppskattad tid per profil | 413 strider, 8,6 h | 360 strider, 7,1 h | 406 strider, 7,1 h |
| Var förlusterna sker | utspritt: Nemesis, elit och boss | **våning 1:s elitgrupp och Nemesis**, på varje djup | **Bergakungen**, på varje djup |

I kryptan och Trollberget klarar boten nästan varje djup från 4 och uppåt på första försöket ("försök 1, träning 0"),
och ingen profil fastnar inom 40 nedstigningar. Med uppskattningen är det ungefär 2 timmar till djup 5 och 3–4 timmar
till djup 10 (AUTO).

### Vad bär? (kryptan, 30 profiler × 20 nedstigningar)

| Avstängt | Djup 8 klarat efter | Högsta klarade djup (median) | Fast på djup 10 |
|---|---|---|---|
| Inget (mänsklig) | 14 ned | d12 | 3 av 30 |
| Material | 16 ned | d9 | 5 av 17 |
| Troféval | 16 ned | d10 | 3 av 25 |
| Lägerelden | 14 ned | d11 | 6 av 26 |
| Allt, utan träning (som `SOAK=karriar`) | 16 ned | d9 | 6 av 16 |

Material (bärnsten, trick, Nether Stones) väger mest, sedan troféerna. Att alltid ta lägerelden betyder lite. Även med
allt avstängt går boten fortare i kryptan än karriärbotarna, eftersom den bara spelar kryptan: kapellet och Lunden
saknas i turordningen.

## Går väggarna att träna bort?

- **Kryptan:** ja, och den behöver knappt träning. Det finns ingen vägg till djup 15. Förlusterna är utspridda och få
  (1–16 per djup på 50 profiler).
- **Trollberget:** ja. Nästan alla förluster sker mot Bergakungen (13 / 13 / 10 / 7 på djup 2–5, sedan 1–7 per djup),
  men nästa försök vinner. Bossen är en tröskel, inte en vägg.
- **Kapellet: nej, inte helt.** Från djup 3 krävs två försök och 1–2 träningsnedstigningar per djup. Från djup 12
  fastnar en av fyra profiler eller fler (12 av 32 på djup 14) trots träning med 3 extra nivåer per försök. Nästan alla
  förluster sker på **våning 1, mot elitgruppen (Lansens anstormning) och Nemesis**, 14–39 per djup på djup 2–15. Träningen hjälper
  bara tills nästa djup: väggen ligger i början av körningen, när sällskapet är fräscht, så det är inte nötning som
  fäller dem. Det stämmer med Provocera-mätningen, där Lansens anstormning var den grupp som tappade mest utan Provocera.

## Rekommendation

1. **Kapellets våning 1 är den riktiga väggen.** Mildra Lansens anstormning och Nemesis på våning 1 från djup 3
   (t.ex. våning 1:s elitmildring `SMALL_PARTY_ELITE` även för fyra hjältar på våning 1, eller färre Irrbloss i
   gruppen). Mät igen med `KARRIAR_REALM=chapel` och sikta på att ingen profil fastnar före djup 15.
2. **Kryptan och Trollberget är för snälla för en spelare som tar hand om sitt bygge.** Den som sätter material och
   väljer troféer förlorar nästan aldrig två gånger på samma djup. Där borde mittspelet (djup 5–12) bita mer. Höj inte
   `DEPTH_STEP`, som gäller alla Realms. Pröva hellre motdrag från tidigare djup eller starkare elitgrupper i just de två.
   Kapellet visar att det går att få en kurva som kräver träning.
3. **Materialen är den största enskilda kraften.** Bärnsten och Nether Stones tar boten från djup 9 till djup 12 på 20
   nedstigningar. Värt att se över om ett fyllt bygge ska vara så mycket starkare, eller om det är just belöningen
   ledstjärnan vill ha.
4. **Mät riktig speltid.** Uppskattningen säger 2 timmar till djup 5 och 4–5 timmar till djup 10 med AUTO. Låt VD:s
   telefon fylla `playtime.cfg` under nästa provspel och räkna om med sekunder per tur därifrån.

## Förbehåll

- MACRO-boten med startmakron och makroförslag. En spelare som skriver egna makron spelar bättre, en som spelar
  manuellt sämre och långsammare.
- En Realm per profil. En verklig spelare växlar, och då kommer kapellets vägg tidigare i karriären och kryptans
  platå senare.
- Rollerna för bärnsten och "bästa trofé" (sällsynthet) är grova regler. Bosstroféer räknas som elit; deras kostnad tas
  inte med.
- Kapellets lärjungar (Lirien, Ragnhild, Hulda, Ronja) skiljer sig från kryptans (Alva, Brokk, Eira …), så sällskapen
  är olika mellan Realmerna. En del av skillnaden kan bero på det.
- Fasta frön: samma frö ger samma körning. Inga körfel i någon körning.
