# Illustrationer i tusch (promptar till ChatGPT)

Kartan och vinjetterna ska kännas som en gammal handritad karta. Stilen följer Drakvalvets bilder
(`~/drakvalvet/public/illustrations/`). Fem av dem används redan: stendorren, vaktaren,
under-tornet, nattlagret och sigillet.

Klistra in **stilblocket** först och sedan en motivrad. Spara bilderna som PNG eller WEBP och skicka dem
till Huvudtråden, så läggs de i `assets/illustrations/`.

## Stilblock

> Detailed pen-and-ink illustration with fine cross-hatching, sepia ink on aged cream parchment,
> soft vignette fading to the paper at all edges, dark medieval fantasy, moody but warm, no color
> except sepia tones, no text, no modern elements. Landscape 3:2, 1200×800.

För symboler och dekor (transparent bakgrund):

> Antique pen-and-ink engraving in the style of an old map illustration: fine sepia ink linework with
> delicate cross-hatching for shading, no solid color fills, no cartoon outlines, monochrome sepia on a
> transparent background. Simple clear silhouette that stays readable when small. No text. Centered,
> square 512×512.

Om bilden blir för tecknad: klistra in kapellbilden i chatten och skriv *"Match the engraving style of
this illustration."* (Första försöket med "bold clean outlines" gav en tecknad, fylld stil.)

## Vinjetter (3:2)

1. **Det fördärvade kapellet:** a ruined gothic chapel on a hill, broken stained-glass windows, dark
   smoke and creeping corruption spilling from its doors, crows, a lone path leading up to it.
2. **Häxan:** a gaunt witch in tattered robes stirring a cauldron among dead trees, eerie glow
   suggested by hatching, seen from a distance.
3. **Paladinen och sällskapet på väg:** a paladin in plate armor with a tabard and a raised sword
   leading four companions (a dwarf warrior, a priestess, a huntress with a bow, a fire mage) along a
   road toward distant ruins at dawn.
4. **Basen:** a small fortified keep with a forge, a library tower and an altar courtyard, smoke from
   chimneys, cozy evening light.

## Symboler för rumskartan (512×512, transparent)

5. A small treasure chest, lid slightly open.
6. A campfire with three logs and rising sparks.
7. A stone altar with a ray of light.
8. Two crossed swords.
9. A shield with a skull emblem.
10. A horned skull.
11. A swirling portal inside a ring of standing stones.
12. A paladin game piece, like a carved miniature on a round base, with a shield and a sword.

## Dekor (transparent)

13. An ornate old-map compass rose.
14. An empty decorative cartouche (scroll banner) for a place name.
15. A coiled dragon for a map corner.
16. A sword thrust into a stone.

## Statusikoner (0.22) – ett ark

Arket med kartsymboler fungerade bra, så statusikonerna görs som ett ark med rutnät (lättare att klippa
ut med `tools/cut_symbols.gd`). Skicka i samma chatt som det första arket:

> Gör ett nytt ark i exakt samma gravyrstil: 22 små statusikoner i ett rutnät med 6 kolumner och 4 rader,
> lika stora rutor med luft emellan, ljus pergamentbakgrund, ingen text. Varje ikon ska vara tydlig även
> när den är liten (ca 40 pixlar). Ordning, rad för rad:
> 1 a feathered boot (Agile), 2 an open book with a glowing rune (Arcane), 3 a roaring face with clenched
> teeth (Berserk), 4 a raised kite shield (Defensive), 5 a radiant halo (Immune), 6 a drop of blood with a
> leaf (Leeching),
> 7 a sprouting green leaf (Mending), 8 a dome of light (Protected), 9 a phoenix feather (Rebirth),
> 10 a clawed paw (Savage), 11 a turtle shell (Shelled), 12 a war horn (Taunting),
> 13 a dripping cut (Bleeding), 14 a withered flower (Blighted), 15 a blindfolded eye (Blind),
> 16 a spiral of question marks without letters (Confused), 17 a snowflake (Frozen), 18 a small poison
> vial (Poisoned),
> 19 a cracked broken heart (Scorned), 20 a crescent moon with z-shapes (Sleeping), 21 a coiled rope snare
> (Snared), 22 a stone statue head (Stone).
