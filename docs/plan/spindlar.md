# Spindlarna – Realm 3, Sidenlunden (0.31-prov)

Skriven 2026-10-23 på uppdrag från huvudtråden ("kör spindlarna"). Underlag: ChatGPT:s research K
(`docs/ideer/chat-familjer-karta-grottan.md` och `-full.md` på main), `docs/plan/0.27-fiender.md`, `docs/plan/levande-karta.md`.
Märkning som i 0.27-fiender: **Siralim** = som originalet, **VAL** = vårt val, **GISSNING** = obeprövat. ⚙ = ny kod.

## 1. Beslut

### 1.1 Var de bor: egen Realm (VAL, som Siralim)
**Sidenlunden** (`grove`, kort "Lunden"): en egen Realm med två våningar, en boss och egna pooler och elitgrupper.
Som i Siralim har varje Realm sin ras. Den levande kartan (`levande-karta.md`) behöver dessutom tre punkter för
cirkeln troll → skelett → spindlar.

**Kostnaden, ärligt bedömd:**
- **Billigt, eftersom Realms redan är data:** `realms.json` (våningar, pooler, elitpooler, föremål, kartans ruta),
  ungefär 18 möten, 9 fiender med troféer och elitvarianter. Kampanjkartan, grottan, questen, djupen,
  instabiliteten, perk-poängen och botarna läser Realms ur datan.
- **Kod (liten):**
  - tre nya byggstenar i CombatSim (§3);
  - föremålen får en egen resultattext;
  - dekoren på rumskartan;
  - en grönare ton i stridens värld.
- **Saknas, med medveten ersättning:**
  - en egen vinjett (Drakvalvets **Gråskogen** används; prompt i §6);
  - egen musik och stämning (kryptans);
  - egna rumsögonblick i 3D (kryptans stil);
  - lärjungar. Lunden har inga nya följeslagare; fånge-rummen står tomma här, och de 10 hjältarna räcker.
- **Ett familjebygge i en befintlig Realm** hade varit billigare för datan. Men det hade gjort kryptan eller kapellet
  rörigare (kapellet har redan två familjer) och gett den levande kartan bara två punkter.

### 1.2 Modell: Drakvalvets jättespindel (inget nedladdat)
`~/Desktop/Blender-Test/export/qt-jattespindel.glb` är byggd av Drakvalvets eget skript
(`Drakvalvet/Monster/jattespindel.py`: egen rigg, åtta ben med IK, glödande ögon). Den har sju klipp: Idle_Loop,
Walk_Loop, Run_Loop, Sword_Attack (bettet), Spell_Simple_Shoot (nätet), Hit_Chest och Death01.

Den packas upp med `gltf-transform dequantize`, som de andra figurerna, till `assets/models/spindel.glb`. Varianterna
skiljer sig med `tint`, `scale`, `glow` och `light`, så det blir ingen ny modell per spindel.

**VD:s Roblox-modeller** (`~/Desktop/Roblox/assets/figurer/`, egna och fria att använda) är jämförda så här:
- **GiantSpider.fbx** saknar rigg och animationer (10 delar). Animationerna finns bara som nyckelbilder i `spindel_anim.py`
  med Roblox-axlar.
- **Drakvalvets spindel** har en rigg och sju klipp i vår stil och fungerar direkt.

Därför valdes Drakvalvets.

För senare:
- `props/SpiderCaves.fbx` (nätvägg, kokonger, äggsäck) passar som rekvisita i rumsögonblicken.
- Ettercap (Ghoul-rigg) passar som en tvåbent spindelvarelse om Lunden får fler fiender.
- Paletterna WolfSpider och SpiderQueen kan vara förebilder för färgerna.

### 1.3 Snärjd: Siralims version (bekräftad)
Vår Snärjd är originalets:
- figuren hålls längst ned på tidslinjen (`CombatSim._sink_snared`, anropas när auran läggs och efter varje tur);
- 10 % chans att slita sig loss i början av varje figurs tur, 30 % för resistenta (`_break_snares`).

Snärjd kostar alltså aldrig en tur, bara platsen. Därför behövs inget extra skydd mot kedjelås. Research K:s korta
Snärjd ("tas bort efter en missad handling") tas inte in.

Den enda kontroll som kostar en handling är Sömnvävarens sömn. Den bryts av skada, och de andra spindlarna slår.

### 1.4 Kedjan: Snärjd → gift → blind → blödning (förebild Arachnalisk, Siralim)
Varje vanlig spindel lägger nästa länk, men bara om föregående länk redan finns:

| Länk | Spindel | Kräver | Ger |
|---|---|---|---|
| 1 | Snärjspindel | – | Snärjd |
| 2 | Gifttandsspindel | Snärjd läggs | Förgiftad |
| 3 | Dammspindel | Förgiftad | Förblindad |
| 4 | Hullingspindel | Förblindad hjälte anfaller | Blöder |

Svaret, som makrona måste lära sig:
- döda öppnaren först (Snärjspindeln);
- rena gift (Alva, Ragnhild, Abbedissans nyckel);
- **anfall inte medan du är Förblindad**, utan försvara dig eller hela (makrovillkoret "har debuff").

Familj: **Spindelfolket** (`spider_kin`).

## 2. Fienderna (9)

Stats mot Kultisten (H 42, A 11, I 12, D 1, S 10). Varje text ska gå att läsa på telefonen på en rad.

| # | Namn (id) | Roll | Stats | Egenskap (texten gäller) | AI |
|---|---|---|---|---|---|
| 1 | Snärjspindel (`snare_spider`) | Öppnare | H 36, A 10, D 1, S 13 | *Fästtråd:* "Bettet snärjer målet i 2 turer (50 %)." | grundanfall, `pick: random` |
| 2 | Gifttandsspindel (`venom_spider`) | Giftspridare | H 38, A 11, D 1, S 10 | *Gift i tråden:* "När en hjälte blir Snärjd förgiftar Gifttanden hen i 3 turer." | grundanfall |
| 3 | Dammspindel (`dust_spider`) | Stör målval | H 34, A 10, D 1,5, S 11 | *Damm i ögonen:* "Bettet förblindar en Förgiftad hjälte i 1 tur." | grundanfall mot en Förgiftad (`pick_aura` ⚙) |
| 4 | Hullingspindel (`barb_spider`) | Straffar | H 44, A 11, D 2, S 9 | *Hullingar:* "En Förblindad hjälte som anfaller börjar blöda (1 tur)." ⚙ `source_has_aura` | grundanfall |
| 5 | Sömnvävaren (`sleep_weaver`), elit | Förbereder ett offer | H 70, A 13, I 12, D 2, S 12 | *Dvalans nät:* "Anfall mot en Snärjd hjälte söver hen (tills hen tar skada)." | grundanfall mot en Snärjd (`pick_aura` ⚙) |
| 6 | Slukaren (`devourer_spider`), elit | Skördar kontrollen | H 80, A 15, D 2,5, S 8 | *Sluka:* "Anfall mot en Snärjd gör dubbel skada och helar Slukaren med hälften. Snärjningen släpper." ⚙ `remove_aura` | grundanfall mot en Snärjd (`pick_aura`) |
| 7 | Strypvävaren (`old_knot`), miniboss | Väljer nästa offer | H 140, A 13, I 12, D 3, S 9 | Resistent + *Trådens slut:* "I början av sin tur snärjer Strypvävaren den hjälte som står överst på tidslinjen." ⚙ mål `top_enemy` | grundanfall |
| 8 | Vävmodern (`web_mother`), boss | Spinner in alla | H 135, A 13, I 13, D 2, S 9 | Resistent + *Moderns tråd:* "Den som sliter sig loss ur Snärjd förgiftas i 3 turer." | Kokongstorm (alla Snärjda, ingen skada, nedkylning 5), annars bett (30 % gift); följe Snärjspindel, Dammspindel, Hullingspindel |

**Signaturhandlingar** (VD: varje spindel ska kännas igen i striden):
- Varje spindel har en egen förmåga i `abilities.json` med en avsikt som syns. Den används när nedkylningen är klar,
  annars biter spindeln.
- `"anim"` väljer animationen: Spell_Simple_Shoot för nät och kast, Sword_Attack för bett.
- Avståndsförmågor skjuter en projektil (`travel`).

| Spindel | Förmåga (id) | Effekt | Nedkylning | Ljud och animation |
|---|---|---|---|---|
| Snärjspindel | Nätskott (`web_shot`) | 40 % skada; snärjer den med högst Attack i 2 turer | 4 | nature_hit, nätskott |
| Gifttandsspindel | Gifthugg (`venom_strike`) | 90 % skada + gift, 50 % hårdare mot en Snärjd (`bonus_vs`); tar helst den Snärjda | 2 | nature_hit, bett |
| Dammspindel | Dammpust (`dust_puff`) | 30 % skada; förblindar den Förgiftade i 2 turer | 3 | nature_hit, nätskott |
| Hullingspindel | Hullingkast (`barb_throw`) | 70 % skada, 50 % chans till blödning | 3 | arrow_hit, kast |
| Sömnvävaren | Dvalgift (`lullaby`) | den Snärjda somnar | 3 | shadow_hit, nätskott |
| Slukaren | Slukarens språng (`devour_lunge`) | 130 % skada mot den svagaste Snärjda (Sluka dubblar) | 2 | k_boss_hit, bett |
| Strypvävaren | Kokongen (`cocoon_revive`) | väcker en fallen spindel med 40 % liv | 4 | renew, nätskott |
| Strypvävaren | Trådstrypning (`knot_strangle`) | 110 % skada, 50 % hårdare mot en Snärjd | 2 | k_boss_hit, bett |
| Vävmodern | Kokongstorm (`cocoon_storm`) | hela sällskapet blir Snärjt | 5 | shadow_hit, nätskott |

**Äggsäcken som kläcker småspindlar** kräver att figurer kan komma in mitt i striden: ny kod i CombatSim och i
stridens grafik. Den är inte byggd. Det är en fråga till VD om det är värt det, till exempel som Vävmoderns andra
skede.

**Troféerna** ger hjälten spindlarnas egna grepp (snärja, förgifta den Snärjda, förblinda, blödning, söva, sluka).
Därför känns de spindelaktiga utan nya förmågor. En trofé som ger en hjälte Nätskott som förmåga kräver
trofé-förmågor, som vi inte har.

**Motdrag** (Siralim §21.2, högst ett per grupp, bara elit/miniboss/boss):
- Strypvävaren har **Spindelskräck** (förebild Woolly Arachnalisk, Arachnophobia): "Snärjda hjältar tar dubbel skada av
  gift." Den gäller från djup 1, som Abbedissans Ordensregel.

**Elitvarianter** (5 %, glöder, eget namn och egen trofé) för de fyra vanliga:
- Silkesnärjaren
- Smaragdtanden
- Askspindeln
- Blodtaggen

## 3. Ny kod (⚙, allt litet)

| Vad | Var | Varför |
|---|---|---|
| Villkoret `source_has_aura` | `CombatSim._when` | Hullingar: angriparen är Förblindad |
| Effekten `remove_aura` | `_run_trait_effect` | Sluka släpper snärjningen |
| Målet `top_enemy` (överst på tidslinjen) | `_trait_targets` | Trådens slut |
| `pick_aura` i förmågan (helst en med statusen, sedan `pick`) | `_pick_targets` | Avsikten visar vem som är offret |
| Resultattext per föremål (`results`) | `RunState.use_object` | Lundens föremål återanvänder valen |
| `grove`-dekor och grön ton | rumskartan och stridens värld | – |

## 4. Troféer (varje trofé svarar på någon grupp)

| Fiende | Trofé (id) | Sällsynthet | Text | Svar på |
|---|---|---|---|---|
| Snärjspindel | Snärjtråden (`thread_spool`) | vanlig | Bärarens första anfall i striden snärjer målet. | Grupper som slår först (Lansen, Irrbloss) |
| — Silkesnärjaren | Sidenslingan (`silk_noose`) | elit | Bäraren gör 25 % mer skada mot Snärjda fiender. | Höga liv, långa strider |
| Gifttandsspindel | Den tömda giftflaskan (`venom_fang`) | vanlig | När en fiende blir Snärjd förgiftar bäraren den i 3 turer. | Benrustning, Asketen (indirekt skada biter) |
| — Smaragdtanden | Smaragdgiftet (`emerald_venom`) | elit | Bärarens gift gör 50 % mer skada på Snärjda fiender. | Bossar med mycket liv |
| Dammspindel | Dammpungen (`dust_tuft`) | vanlig | Bärarens anfall mot en Förgiftad fiende förblindar den i 1 tur. | Starka anfallare |
| — Askspindeln | Askmolnet (`ash_cloud`) | elit | Bärarens anfall gör 25 % mer skada mot Förblindade fiender. | Kombinationen med Immas Rökpil |
| Hullingspindel | Hullingtråden (`barbed_thread`) | vanlig | En Förblindad fiende som skadar någon i sällskapet börjar blöda (1 tur). | Elitfiender som slår hårt |
| — Blodtaggen | Blodtornet (`rose_thorn`) | elit | En Snärjd fiende som anfaller bäraren börjar blöda (1 tur). | Långsamma, tunga slag |
| Sömnvävaren | Dvalnätet (`lull_web`) | elit | Bärarens anfall mot en Snärjd fiende söver den. | Elitfiender som slår först |
| Slukaren | Den rivna slukväven (`devour_maw`) | elit | Bärarens anfall mot en Snärjd fiende gör 60 % mer skada och helar bäraren med 30 %; snärjningen släpper. | Nötning |
| Strypvävaren | Den lösta strypknuten (`knot_eye`) | boss | I början av bärarens tur snärjs fienden som står överst på tidslinjen, **men** bäraren börjar striden längst ned. | Grupper som slår först |
| Vävmodern | Moderns silke (`mother_silk`) | boss | Fiender som sliter sig loss ur Snärjd förgiftas i 3 turer, **men** sällskapet gör 15 % mindre skada med anfall. | Bossar (Snärjd släpper lättare för dem) |

## 5. Möten och föremål

- **Tier 0** lär ut en länk i taget:
  - Första tråden (Snärjspindel + Gifttand);
  - Damm i snåren (Snärjspindel + Dammspindel);
  - Giftbuskarna (Gifttand + Dammspindel).
- **Tier 1–2** har hela kedjan och mallarna ur 0.27-fiender §4:
  - Kedjan;
  - Hullingarnas snår;
  - Nötning;
  - Familj (fyra spindlar).
- **Elit, våning 1:** **Sömnvävarens bädd** (Sömnvävaren + Snärjspindel + Gifttand). Den prövar en enda sak: döda
  öppnaren.
- **Elit, våning 2:**
  - Slukarens håla;
  - Strypvävarens nät (miniboss);
  - Två vävare.
- **Föremål:**
  - **Kokong** (skär upp: en starkare spindelgrupp och dubbel skatt);
  - **Daggnät** (rör vid tråden: hela raden syns, men nästa grupp är beredd);
  - **Silkesspår** (följ spåret: 2 skatter eller 2 grupper);
  - Väktarens timglas.
  - Valen återanvänder kryptans och kapellets logik med egen text.

## 5b. Mätningen (2026-10-23, djup 1, fyra hjältar på nivå 3, startmakron)

VD:s riktlinje: balansera mot fyra hjältar. Mindre sällskap får vara svårare.

En strid i taget med fulla Charges vinns till 100 % i alla grupper, både i Lunden och i kapellet
(`tests/spider_diag.gd`). Svårigheten kommer av nötningen över körningen.

| Steg | Lunden MACRO / TUNED | Var körningarna förloras |
|---|---|---|
| Första utkastet | 7 % / 13 % | Nästan bara hos Vävmodern |
| Utan Giftregn, Kokongstorm var fjärde tur | 12 % / 18 % | Vävmodern |
| + Fästtråd 50 %, Vävmodern 150 liv, bossmötet ×1,0 | **32 % / 56 %** | Vävmodern 34 och 20, elit v2 0 och 2 |
| Kapellet som jämförelse | **34 % / 40 %** | Bossen 17 och 20, elit v2 13 och 8 |

| + bossens följe utan Gifttanden | 46 % / 50 % | Vävmodern |

(50 körningar per rad med `DIAG_MODE=grotta`. Hela `BALANS=grotta` med 100 körningar per rad står i rapporten nedan.)

- TUNED tjänar mer i Lunden än i kapellet, eftersom makron som renar och helar svarar på kedjan. Det är avsikten:
  Lunden belönar ett makro som svarar på debuffar.
- **Karriären** (`SOAK=karriar`, 60 profiler × 18 nedstigningar, Realms i tur krypta → kapell → lund, en ny profils
  makron, små sällskap tidigt):
  - Nästan alla förluster i Lunden sker hos Vävmodern.
  - Signaturhandlingarna gjorde först Lunden mycket svårare (djup 3: 13 %).
  - Det som hjälpte var att Vävmodern inte längre väcker fallna spindlar (Moderns kallelse togs bort; Strypvävaren
    behåller Kokongen), Nätskott var fjärde tur, och Kokongstorm var femte tur utan skada.
  - Slutläget (Vävmodern 135 liv):

  | Djup | Lunden | Kapellet | Kryptan |
  |---|---|---|---|
  | 2 | 61 % | 51 % | – |
  | 3 | 50 % | 50 % | 68 % |
  | 4 | 36 % | 42 % | 64 % |
  | 5 | 27 % | 59 % | 47 % |
  | 6 | 13 % | 24 % | 20 % |

  Lunden ligger i kapellets nivå på djup 2–4 och är något svårare djupare (kapellets 59 % på djup 5 varierar mellan
  körningarna: 38–60 %).
- **Djup 1 med fyra hjältar** (som `BALANS=grotta`): Lunden 60 / 66 % mot kapellets 34 / 40 %. Lunden är alltså
  lättare än kapellet på djup 1 och lite svårare djupare. Med 120 liv på Vävmodern blev djup 4–6 som kapellet men djup 1
  ännu lättare (66 / 70 %).
- Elitgrupperna (`BALANS=elitgrupper NIVA_REALM=grove`) vinns till 100 % med fulla Charges på djup 1 och 3, som
  kapellets.

## 5c. Namnen (VD 2026-10-23: fiender ska se allvarliga och farliga ut)

Lundens namn och texter är rensade från det skämtsamma (id:na är kvar):

| Förut | Nu |
|---|---|
| Gamla Knut | Strypvävaren |
| Vaggvisa | Dvalgift |
| Vaggande nät | Dvalans nät |
| Rosentaggen | Blodtaggen |
| Dammtofsen | Dammpungen |
| Trådspole | Snärjtråden |
| Slukarens bord | Slukarens håla |

Kokongens text är också allvarligare.

## 6. Öppna frågor till VD (inga beslut)

1. **Vinjett:** Gråskogen är ett lån. Förslag på prompt: *"a silent birch grove wrapped in thick spider silk, cocoons
   hanging from branches, a narrow path into the webs, faint moonlight"* med stilblocket i `docs/illustrationer.md`.
2. **Lärjungar i Lunden:** ska det finnas någon att befria (en tionde hjälte, t.ex. en vävare som bytt sida)?
3. **Familjeräkning för hjältar** (research K: en hjälte med en spindeltrofé räknas som spindel): inte byggt.
4. **Musik:** Lunden spelar kryptans musik och stämning tills vidare.

## 7. Förslag till CLAUDE.md (huvudtråden för in det; den här sessionen ändrar inte CLAUDE.md)

Under **Design**, efter "Kapellets fiender":

> - **Sidenlunden** (0.31, Realm 3, `docs/plan/spindlar.md`, `realms.json` "grove", `"style": "grove"`): familjen Spindelfolket
>   (`spider_kin`) kring bossen Vävmodern, en kedja Snärjd → gift → blind → blödning (förebild Arachnalisk): Snärjspindel
>   (Fästtråd), Gifttandsspindel (Gift i tråden), Dammspindel (Damm i ögonen), Hullingspindel (Hullingar, villkoret
>   `source_has_aura`); elitfiender Sömnvävaren (Dvalans nät) och Slukaren (Sluka, effekten `remove_aura`); miniboss
>   Strypvävaren (Trådens slut, målet `top_enemy`; motdraget Spindelskräck från djup 1). Förmågor med `pick_aura` riktar avsikten mot
>   den som har statusen. Varje spindel har en signaturhandling (Nätskott, Gifthugg, Dammpust, Hullingkast, Dvalgift,
>   Slukarens språng, Kokongen, Trådstrypning, Kokongstorm) med egen animation (förmågans `"anim"`). Snärjd är Siralims (`_sink_snared`, 10 %/30 % loss), kostar aldrig en tur. Modell: Drakvalvets
>   jättespindel (`assets/models/spindel.glb`, färger per material, elitvarianter med egna `colors`/`emit`). Striden blir en
>   lund (`CryptWorld.style`: grön dimma, stammar med nät, kokonger); vinjetten är Drakvalvets Gråskogen tills en egen finns.
>   Föremål: Kokong, Daggnät, Silkesspår (objects.json `results` ger egen text till lånade val). Inga lärjungar i Lunden.
>   0.31 rättade också att en sömn som en träff lägger (Den skingrade dimman) väcktes av samma träff. Tester:
>   `tests/test_enemies_spiders.gd`.
