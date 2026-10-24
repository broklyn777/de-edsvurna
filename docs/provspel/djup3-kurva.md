# Svårighetskurvan efter 0.30.33 (DEPTH_STEP 0,03)

2026-10-24, gren `provspel-djup3` (från `test-0.30` på 0.30.33). Spelkoden är inte ändrad. Jämförs med
`djupsteg-matning.md` (samma steg 0,03, men utan Lunden och före 0.30.32:s fix av Frusen) och `svarighetskurva.md`
(0,08).

```bash
SOAK=karriar godot --headless --path . --script res://tests/soak.gd -- --runs=80 --descents=24          # 8 min 20 s
BALANS=grotta GROTTA_DJUP=4 NIVA_REALM=grove godot --headless --path . --script res://tests/balance_report.gd   # per djup och Realm
DIAG_MODE=boss DIAG_N=40 godot --headless --path . --script res://tests/spider_diag.gd                        # bossarna
```

Karriären: 80 profiler × 24 nedstigningar (1 920 körningar), samma bot som i `svarighetskurva.md`. Realmen roterar
kryptan → kapellet → Lunden, så nedstigning 3, 6, 9 … är alltid i Lunden. Inga körfel och inga kontrollvarningar.

## Karriären per djup (alla tre Realms)

| Djup | Väntad nivå | Körningar | Sällskapets nivå | Vinst | Kryptan | Kapellet | Lunden |
|---|---|---|---|---|---|---|---|
| 1 | 3 | 97 | 2,1 | **98 %** | 99 % | – | – |
| 2 | 8 | 168 | 6,5 | 63 % | – | 56 % | **74 %** |
| 3 | 13 | 202 | 11,7 | 58 % | 63 % | 59 % | 49 % |
| 4 | 18 | 227 | 16,8 | 55 % | 68 % | 51 % | 49 % |
| 5 | 23 | 246 | 21,6 | 49 % | 55 % | 51 % | 41 % |
| 6 | 28 | 224 | 26,6 | 54 % | 63 % | 47 % | 51 % |
| 7 | 33 | 226 | 31,1 | 50 % | 57 % | 53 % | 38 % |
| 8 | 38 | 201 | 35,5 | 49 % | 57 % | 51 % | 40 % |
| 9 | 43 | 152 | 39,1 | 45 % | 55 % | 48 % | 33 % |
| 10 | 48 | 92 | 42,8 | 40 % | 65 % | 32 % | 36 % |
| 11 | 53 | 46 | 46,5 | 46 % | (10) | (18) | (18) |
| 12 | 58 | 28 | 49,4 | **29 %** | (7) | (8) | (13) |
| 13 | 63 | 9 | 52,1 | 22 % | | | |

Inom parentes: för få körningar för en procentsats. Jämfört med förra mätningen av 0,03 (två Realms, före Frusen-fixen):
djup 7 42 → 50 %, djup 8 40 → 49 %, djup 9 31 → 45 %. **Väggen vid djup 8–9 finns inte längre.** Kurvan sjunker
långsamt från 55 % på djup 4 till 45 % på djup 9, och den första tydliga kanten kommer vid djup 12 (29 %).

| Efter nedstigning | 6 | 12 | 18 | 24 |
|---|---|---|---|---|
| Djup i snitt | 3,6 | 5,6 | 7,7 | 9,9 |
| Sällskapets nivå | 13,3 | 23,9 | 34,0 | 43,9 |

Boten går ungefär ett djup per 2,7 nedstigningar och ligger 2–4 nivåer under fiendernas väntade nivå hela vägen.
299 av 1 920 nedstigningar (16 %) slipar ett djup som redan är klarat (förut 20 % med 0,08).

### Per Realm: Lunden har en bossvägg

| Realm | Vinst i karriären | Förluster mot bossen |
|---|---|---|
| Kryptan | 66 % | 84 av 193 (44 %) |
| Kapellet | 50 % | 67 av 316 (21 %), mest våning 1:s elit och Nemesis |
| Lunden | 45 % | **331 av 350 (95 %)** |

Var tredje nedstigning (alltid Lunden) förlorar 30–48 av 80 mot Vävmodern, på alla djup från 3 till 10. Kapellet förlorar
i stället tidigt, mot våning 1:s elitgrupp och Nemesis. Kryptan är snällast på varje djup (55–68 %).

Bossarna med karriärens villkor (`spider_diag` boss, en strid, halva Charges, nivå = väntad − 2, 40 strider):

| | Kryptan d2 / d3 / d5 | Kapellet d2 / d3 / d5 | Lunden d2 / d3 / d5 |
|---|---|---|---|
| 3 hjältar (mildringen för små sällskap) | 90 / 95 / 93 % | 98 / 100 / 98 % | 83 / 98 / 98 % |
| 4 hjältar | 23 / 38 / 25 % | 33 / 68 / 50 % | **15 / 33 / 20 %** |

Med fyra hjältar är Vävmodern den svåraste bossen, men inte mycket svårare än Benfursten. Skillnaden i karriären kommer
av att Lunden möts med slitet sällskap efter två våningar av förgiftning och snaror (hennes strid kommer sist).

## Grottan utan bygge (`BALANS=grotta`, fyra hjältar på väntad nivå, 100 körningar per ruta)

Utan artefakter, troféer, perks och material. Visar vad nivån ensam räcker till; jämför inte direkt med karriären.

| Djup (nivå) | Kryptan MACRO / TUNED / försiktig | Kapellet MACRO / TUNED / försiktig | Lunden MACRO / TUNED / försiktig |
|---|---|---|---|
| 4 (18) | 6 / 20 / 19 % | 3 / 5 / 11 % | 21 / 42 / 55 % |
| 5 (23) | 4 / 11 / 13 % | 5 / 5 / 13 % | 19 / 37 / 47 % |
| 6 (28) | 6 / 13 / 11 % | 1 / 1 / 4 % | 10 / 27 / 37 % |
| 7 (33) | 4 / 5 / 12 % | **1 / 0 / 1 %** | 7 / 17 / 33 % |
| 8 (38) | 1 / 2 / 2 % | **0 / 0 / 1 %** | 5 / 11 / 25 % |

Nivån ensam räcker inte på något djup från 4: det som bär karriären är artefakter, troféer och perks, som ledstjärnan
vill. Kapellet faller till noll utan bygge från djup 6, men karriären klarar det i ungefär 50 % av körningarna. Bygget
gör alltså jobbet där. Lunden är lättast utan bygge men svårast i karriären: vanliga grupper är snälla, och bossen är
svårigheten.

## Platåer

- **Djup 1** (98–99 %) är den enda riktiga platån. Den spelas nästan bara i första nedstigningen och av den som backar.
- **Lunden på djup 2** (74 %) är en mjuk punkt. Den kommer som tredje nedstigning, efter kryptan och kapellet.
- **Kryptan djup 4–10** ligger på 55–68 % utan att sjunka. Det är ingen platå i den meningen att inget händer, men den
  känns troligen lättare än de andra två på samma djup.
- Inget djup från 2 till 11 ligger över 63 % totalt, så ingen del av kurvan är för lätt för den här boten.

## Rekommendation

**Behåll 0,03.** Kurvan är jämn och lutar lagom (63 % → 45 % från djup 2 till 9). Taket har flyttats från djup 5–6
(0,08) till ungefär djup 12 för en bot med startmakron och billigaste perken. Ingen vägg och ingen tom platå finns i
djup 4–8.

Justera bossen i stället för steget. Vävmodern står för 95 % av Lundens förluster. Om VD vill jämna ut Realmerna:
sänk hennes `stat_mult` något (t.ex. 0,9) eller gör Kokongstormen mer sällsynt. Det påverkar bara var tredje
nedstigning, inte hela kurvan. Kapellets våning 1, elitgrupp och Nemesis, är den andra punkten att bevaka.

## Fem saker för VD att titta efter på telefonen, djup 4–8

1. **Vävmodern.** Hur många försök tar hon? Känns förlusten rättvis, eller kommer den av gift och snaror som byggts
   upp under hela körningen? Ser man varför man förlorar?
2. **Kapellets våning 1.** Elitgruppen och Nemesis tar flest kapellkörningar. Blir det en vägg mitt i körningen,
   innan man ens sett bossen?
3. **Kryptan mot de andra.** Känns kryptan på djup 5–8 för lätt jämfört med kapellet och Lunden på samma djup? Väljer
   man den för att slipa?
4. **Nivån mot fienderna.** Boten ligger 2–4 nivåer under fiendernas väntade nivå (hjältebladet visar den) och vinner
   ändå hälften. Känns det som att bygget bär, eller som att siffran på djupet inte betyder något?
5. **Charges och längden.** Räcker Charges genom två våningar och bossen på djup 6–8, och blir striderna långa nog att
   Utmattningen (tur 100) syns? Gör en riktig spelare med inställda makron och troféer det lättare, så att djup 8
   redan känns för lätt?

## Förbehåll

- Boten är enkel: slumpade troféer, inga material, billigaste perken, bara Domens kall, instabilitet 0 och inga löften.
  En riktig spelare ligger troligen över kurvan.
- Realmen roterar, så varje Realm har bara en tredjedel av körningarna. Celler under ca 40 körningar är osäkra.
- Grottmätningen saknar bygge och visar bara riktningen. Den direkta boten och nivåerna 4–8 finns i
  `BALANS=grotta`-utskriften.
- Mätt medan andra sessioner körde Godot; det påverkar bara tiden, inte siffrorna (fasta frön).
