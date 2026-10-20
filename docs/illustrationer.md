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

## Hemmet (0.24)

Klistra in **stilblocket** först, sedan motivet. Gör båda i samma chatt så att stilen blir lika.

**H1. Borgen uppifrån** (planritning, 3:2, 1536×1024):

> A top-down view of a small medieval paladin keep, drawn like an old hand-inked floor plan seen from directly
> above, with walls, roofs cut away so you can see inside each room. Rooms: a central courtyard with a well and
> the main gate at the bottom; a smithy with an anvil, a forge with glowing coals, a water barrel and tools; a
> small chapel with a stone altar and candles; a library with bookshelves, a reading desk and scrolls; an inn
> hall with a big hearth, long tables and benches; a training yard with straw dummies and weapon racks; a small
> study with a writing desk and maps. Cozy, lived-in details everywhere. Outside the walls only dark swirling
> ink, as if the keep is a warm island in the darkness. No people, no text, no labels.

**H2. Porträttark** (ett ark, 3 kolumner × 2 rader, lika stora rutor):

> A sheet of six head-and-shoulders character portraits in the same engraving style, in a grid of 3 columns
> and 2 rows with equal squares and space between, light parchment background, no text. Each face clear even
> when small. In order:
> 1 Master Gorm, an old stern but kind paladin mentor, grey beard, scar, simple tabard;
> 2 Hedda the smith, a strong grumpy woman in a leather apron, soot on her cheek, hair tied back;
> 3 Brother Alrik the librarian, an absent-minded elderly monk with round spectacles and a book;
> 4 Imma, a cheerful mischievous young woman archer with short messy copper-pink hair, freckles and a grin;
> 5 Stig the weapon master, a wiry middle-aged man with a dry smirk and a shaved head;
> 6 Mother Elin the innkeeper, a warm round-faced older woman with a kerchief and a ladle.

Skicka bilderna till Huvudtråden.

**Inlagda 2026-10-20.** Borgen ritar `borgen.webp` och rummen i `data/keep.json` är inpassade (kontrollera med
`-- --keep --keep-debug`); porträtten är utklippta till `assets/illustrations/portraits/`. Så här görs det igen:

**När bilderna kommer (0.24 är byggt för att de ska bytas in):**

- **H1** sparas som `assets/illustrations/borgen.webp` (1536×1024). Borgen ritar den i stället för tuschritningen
  (`KeepArt`). Flytta sedan rummen i `data/keep.json` så att de stämmer med bilden: `rect`, `door`, `yard`, `stand`,
  `person`, `lights`, `chimney`, `forge` och `hearth`, i bildens pixlar. Kontrollera med
  `godot --path . -- --keep --screenshot=/tmp/borgen.png --frames=40`.
- **H2** sparas som `assets/illustrations/portrattark.webp` (läggs i `exclude_filter`). Lägg till källan och sex
  rutor i `tools/symbolark.json` med `"opaque": true` och `"out": "res://assets/illustrations/portraits/"`, t.ex.
  `"gorm": {"source": "portratt", "rect": [x, y, b, h], "opaque": true, "out": "res://assets/illustrations/portraits/", "height": 256}`
  (gorm, hedda, alrik, imma, stig, elin), och kör `godot --headless --path . --script res://tools/cut_symbols.gd`.
  Sven och följeslagarna utom Imma har inget porträtt än och ritas som en tuschbyst.

