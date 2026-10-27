# Striden i tusch: prototyp (borttagen)

**VD 2026-10-28, efter 0.30.53:** tusch var inte bra på något sätt; 3D fungerar och syns tydligt. Stilen togs bort helt på
grenen `paladin-paths` (inställningen, efterbehandlingen, arenaskiftet och gränssnittet). Koden finns kvar i git
(`ink-proto`, 895f242). Inget av det blev bättre oberoende av tuschen, så inget behölls.

VD (2026-10-27): spelet har två stilar som krockar. Borgen, kartorna och porträtten är tusch på pergament, striden är
mättad 3D. Frågan: kan striden bli vacker och höra ihop med resten? Prototypen är en växelbar stil på grenen `ink-proto`.
Figurerna, Quaternius-modellerna och all logik är orörda.

## Hur man växlar

- **STIL: TUSCH / 3D** i inställningsrutan (knappen LJUD · STIL i striden och INSTÄLLNINGAR i borgen). Den gäller
  direkt, också mitt i en strid, och sparas i `user://settings.cfg` (`GameSettings.ink_style`).
- `--ink` och `--no-ink` sätter stilen för en körning utan att spara.

## Vad som är gjort

1. **Efterbehandling** (`scripts/battle/ink_post.gd`, `InkPost`): en skärmfyllande fyrkant framför kameran med en
   spatial shader.
   - **Silhuetter ur djupet.** `hint_depth_texture` fungerar med GL Compatibility i Godot 4.7: djupbufferten kopieras en
     gång per bildruta. Normalbufferten (`hint_normal_roughness_texture`) finns inte i Compatibility, så inre linjer kommer
     i stället ur färgens kanter (Sobel på ljusheten), svagare än silhuetterna.
   - **Färgskalan.** Ljusheten blir en lavering mellan bläck och papper. Starka färger (manteln, lågor, elitens glöd)
     behåller lite av sig själva, som akvarell.
   - **Papper och skuggor.** Pappret har samma brus som kartornas pergament (`Parchment`), skuggorna har skraffering
     (enkel i halvmörker, korsad i det mörkaste), pennan är lite ojämn och kanterna mörkare.
2. **Arenan** (`CryptWorld.set_ink`): golv, upphöjning och pelare tonas mot pergament och grått, runorna blir bläck och
   golvets brustextur försvinner (pappret i efterbehandlingen är kornet). Ljuset blir varmt och dämpat, och glöden är av.
   Varje värde som byter står i `_ink_swaps`, så att stilen går att växla fram och tillbaka.
3. **Gränssnittet** (`UiStyle.ink`, sätts av striden och nollställs när den tar slut, så att menyerna aldrig påverkas):
   - Livmätare på papper med en lavering och en ojämn bläckram, olivgrön för hjältarna, sepia för fienderna och röd under 30 %.
   - Namn i bläck med papperskant.
   - Avsikter som sigill på papper: rött för anfall (fara), olivgrönt för helning.
   - Markeringsringar som två handdragna penndrag: guld för den som agerar, rött för ett mål.
   - Siffror i bläck.
   - Paneler (ramarna, knapparna, makrologgen, tidslinjen och segerskärmen) i en mörk sepialavering i stället för nästan
     svart lila.
   - Guld bara för val och rött bara för fara (`UiStyle.inked`, `tests/test_ink_style.gd`).
4. **Träffkänslan**: bläckstänk (en klick och droppar som flyger kort och stannar) i stället för gnistor, ringar i två
   tunna penndrag och projektiler som bläckdroppar.

## Bildfrekvensen (iMac 2017, Radeon Pro 575, `--disable-vsync --print-fps`, samma strid, median)

| Upplösning | 3D | Tusch | Kostnad per bild |
|---|---|---|---|
| 1560×720 (telefonens) | 88 | 85 | ~0,4 ms |
| 3120×1440 (4× pixlarna, för att se GPU:ns del) | 81 | 67 | ~2,6 ms |

- På datorn bestämmer processorn takten i telefonens upplösning, så tuschen märks knappt där.
- Med fyra gånger så många pixlar syns kostnaden: ungefär 0,6 ms per miljon pixlar.
- Ingen enskild del står för den. Utan papper, utan inre linjer eller utan djup gav 66, 67 och 68 bilder per sekund
  (`INK_PROBE=1|2|3`).
- Det som kostar är passet i sig: kopian av skärmen, kopian av djupet och 13 läsningar per pixel. Mipmaps på skärmkopian
  gjorde ingen skillnad.
- En telefons GPU är kanske 5–10 gånger svagare, så räkna med 3–6 ms per bild. Det ryms i 33 ms (30 bilder per sekund,
  stillastående) och troligen i 16,7 ms (60).
- **Mät på telefonen med FPS: PÅ** i inställningsrutan, i båda stilarna.
- Faller det under 30, finns tre billiga steg:
  - Rendera efterbehandlingen i halv upplösning.
  - Baka pappret en gång till en textur, som `Parchment` gör.
  - Släpp de inre linjerna.

## Skärmdumpar (1560×720, samma ögonblick i båda stilarna)

Kryptan, kapellet, en träff och segerskärmen: `krypta_tusch.png`/`krypta_3d.png`, `kapell_*`, `traff_*`, `seger_*`.

## Ärligt omdöme

**Tusch på 3D håller för stämningen men inte för läsbarheten, i alla fall inte än.**
- Arenan, pelarna, ringarna, livmätarna och segerskärmen hör ihop med kartorna. Det är samma papper och samma bläck, och
  striden ser ut som en teckning i krönikan.
- Figurerna är små på skärmen (kameran är långt bort). Med färgen borta skiljer man dem mest på silhuetten. Paladinens
  blå mantel och Immas röda kappa försvinner nästan, och en hjälte och en skelettkrigare är båda en bläckfigur.
- Det svåraste är inte shadern utan att Quaternius-figurerna är byggda för färg: utan den har de för lite form. De
  starkaste motåtgärderna är billiga:
  1. Kameran närmare.
  2. En färgaccent per hjälte som shadern släpper igenom (manteln, kappan).
  3. Tjockare silhuetter på figurerna än på arenan.
  4. Ett ljust papper bakom figurerna i stället för skuggor.
- **Riktig 2D** (tecknade figurer) skulle se bättre ut på en stillbild. Men den kostar varje figur och varje rörelse på
  nytt och tar bort animationerna vi har. Jag rekommenderar att först pröva tusch på 3D på telefonen med de fyra åtgärderna
  ovan, och först därefter bestämma om 2D behövs.
