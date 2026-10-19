# Underlag för 0.19: Bestiariet, Krönikan och Värdshuset

Researchtråden, 2026-10-19, på uppdrag av Huvudtråden. Bygger på `siralim_innehall.md` §6–7 och
`docs/plan/0.18-kartor.md`. Engelska Siralim-termer enligt `docs/ordlista.md`.

Säkerhet: **Bekräftat** = spelets Codex (2.0.37) eller wikin. **Troligt** = flera spelare eller guider.
**Okänt** = motstridigt eller inte belagt. **Vårt val** = förslag.

## 1. Bestiariet

### Siralims Knowledge

| Regel | Säkerhet |
|---|---|
| Man får Knowledge Points för en varelse när man dödar den. Tillräckligt många poäng höjer rangen och låser upp förmåner, t.ex. att man ser varelsens liv i striden. | Bekräftat (Codex) |
| Om man redan har 100 % Mana för varelsen ger dödandet dubbla poäng. | Bekräftat (Codex) |
| Man måste ha en Bestiary-post för varelsen innan man kan få Knowledge-drops. | Bekräftat (wiki Cards) |
| Andra källor: inskrifter i Realms (sedan alla grundspells är hittade), Hunt-uppdrag (D → C), Rodian Creature Masters (ger Bestiary-poster) och Realm-egenskapen "Extra Nemesis Creatures". | Bekräftat (wiki Realms, Cards) |
| Slumpade Knowledge-drops spelar bara roll under rang S. Alla varelser når S runt djup 1800. | Bekräftat (wiki FAQ) |

**Rangerna:**

| Rang | Poäng | Låser upp |
|---|---|---|
| F | > 0 | Varelsens berättelse (lore) |
| E | > 100 | Livsmätaren syns i striden |
| D | > 500 | Hunt-uppdraget |
| C | > 1 000 | Kan kallas fram vid Divination Candle |
| B | > 2 500 | Mer erfarenhet och resurser från varelsen (+30 % eller +15 %, källorna skiljer sig) |
| A | > 5 000 | Större chans att varelsen släpper sitt kort |
| S | > 10 000 | Assassination-uppdraget, som ger varelsens Trait Material |

Säkerhet: Troligt. Trösklarna kommer från wikin via en sammanfattning och från guider. Poäng per dödad
varelse (30 för vanliga, 10 för unika och gudar) är Troligt; wikin sätter själv ett frågetecken.
Wikins stridssida säger också att rang C ger +15 % skada mot varelsen och −15 % skada från den, medan en
spelare säger att rangen inte gör något starkare. **Okänt** vilket som gäller i dag.

### Siralims Mastery (Bekräftat, Codex)

- Varje ras har en Master (en rasmästare med ett lag av mest den rasen). Bara på djupaste djupet, en gång
  per djup.
- Varje seger ger **+1 Mastery** för rasen, och den gäller permanent för hela laget:
  - mer skada från egna varelser av den rasen och mindre skada mot dem
  - mer skada mot fiender av den rasen och mindre skada från dem.
- Högre Mastery gör Mastern svårare men ger mer.
- Efter 3 segrar: mästarens Trait Material. Efter 5: kostym. Efter 10: Transmogrify.

### Vårt Bestiarium (vårt val)

En sida per fiendetyp. Kunskap ges per besegrad fiende (elit ×3, boss ×10). Fem ranger i stället för
sju, eftersom vi har få fiender och korta körningar.

| Rang | Kunskap | Avslöjar och ger | Siralim-förebild |
|---|---|---|---|
| Okänd | 0 | Silhuett och var den finns ("hörs i kapellet") | Bestiary-post saknas |
| F | 1 | Namn, berättelse (2–3 meningar) | F: lore |
| E | 5 | Livsmätaren med siffror och stats vid Inspect | E: livsmätare |
| C | 15 | Avsiktsregler i klartext ("hela när en allierad är under 50 %") och vilken trofé den ger | (vårt tillägg: avsikter) |
| A | 40 | +10 % chans till dess trofé och +10 % silver från den | B/A: mer byte, kort |
| S | 100 | +10 % skada mot den och −10 % skada från den (en gång per fiendetyp) | Mastery och C-rangens +15 % |

Trofésidan i Bestiariet visar vem som ger trofén, hur många segrar som krävs (bosstroféer x/3) och om
man har den.

**Mastery hos oss (förslag, senare):** fienderna har "släkten" (Skelett, Präst, Fördärvad …). En vunnen
elit- eller bosstrid mot ett släkte ger +1 Mastery: +3 % skada mot släktet per nivå, högst 5 nivåer.
Det syns på Kampanjkartan.

## 2. Krönikan

### Vad Siralim visar

Battle History är en kronologisk händelselista för den pågående och den senaste striden (Bekräftat,
Codex). Utöver det finns:
- Achievements, tusentals, som ger mer Piety.
- Bestiary och Knowledge.
- Mastery per ras.
- Stjärnor i Gate of the Gods.

Siralim har ingen statistik per hjälte eller över flera körningar (Troligt: inget i Codex eller wikin).
Krönikan är alltså vårt tillägg, i samma anda som efterrapporten.

### Statistik som är meningsfull (vårt val)

**Per hjälte, totalt och per körning:**
- skada (direkt / genom traits)
- helning, Barrier given
- skada tagen, gånger stupad, väckt
- tillbakaslag (Retribution)
- undvikna anfall
- använda Charges per förmåga
- MVP-strider: flest poäng i efterrapporten.

**Per körning:**
- Realm och djup, Ed och perks, sällskapet och troféerna
- antal strider och utfall, Realm Quest klarad eller inte
- våningsregler
- mest använda makrorad
- tid.

**Över tid:**
- vunna och förlorade körningar per Ed
- djupaste djup per Realm
- besegrade fiender per släkte
- snabbaste vinst mot varje boss.

### "Dina bästa kombinationer"

Datan finns redan: `CombatSim.trait_stats[trait_id] = {unit, procs, damage, heal}` och efterrapportens
poäng `damage + heal × 1,2 + procs × 5`.

1. **Spara per strid.** Efter striden sparas de tre traits med högst poäng (de som syns i
   efterrapporten), deras bärare och utfallet.
2. **Kombination = par av traits som båda gav poäng i samma vunna strid,** och där minst ett av dem
   utlöstes av det andra. Kedjan finns redan i händelsernas `trait`-fält. Utan kedja räknas paret bara
   som "samspel".
3. **Nyckel:** de två trait-id:na i bokstavsordning, plus Eden.
4. **Räknas:** antal vunna strider, summa poäng och bästa enskilda strid.
5. **Visas:** topp 5 efter vunna strider, med det svenska namnet och en rad om varför. Exempel:
   "Hämndens ed + Snabbt tag: 14 segrar, Ronjas falk utlöste tillbakaslaget 31 gånger".
6. **Nytt:** första gången ett par ger poäng markeras det "Ny kombination!" i efterrapporten. Det mäter
   ledstjärnan direkt: provar spelaren den igen?

## 3. Värdshuset: datautkast för sex nya följeslagare

Tonregeln gäller (`siralim_innehall.md` §6.2): inget riktigt ockult, och en blandning av karaktärer.
Stats i formatet från `data/heroes.json` (§12 i `siralim.md`). Charges på Siralim-nivå (§3b). Varje
egenskap ändrar en regel.

⚙ = kräver något som motorn inte har i dag. Det motorn redan har: triggers `damage`, `heal`,
`aura_applied`, `action`, `acted`, `death`, `turn_start`, `battle_start`, `passive` och `modify_*`.
Effekter `damage`, `heal`, `aura`, `barrier`, `revive`, `restore_charge`, `stack` och `cast`. Mål
`self`, `allies`, `enemies`, `random_enemy`, `dead_ally`, `other_allies`, `other_enemies`,
`weakest_ally`, `enemy`, `source` och `target`. Dessutom `actor`, `scope: party`, händelsen `dodge` och
`dodge_add`.

### 3.1 Ronja Falkvind, falkenerare. Regel: falken svarar på fiendens avsikt.

```json
"ronja": {
	"name": "Ronja Falkvind", "title": "Falkenerare", "role": "control", "color": "#c9a46a",
	"stats": {"health": 650, "attack": 80, "intelligence": 60, "defense": 25, "speed": 15},
	"crit_chance": 0.12, "attack_ability": "talon_strike",
	"abilities": ["falcon_dive", "scout_flight", "wing_shadow"],
	"traits": ["ronja_falcon_watch"]
}
```

```json
"ronja_falcon_watch": {
	"name": "Falkens vakt",
	"text": "När en fiende väljer ett mål i sällskapet dyker Stormvinge ned: fienden flyttas ett steg ned på tidslinjen och blir Märkt (en gång per tur).",
	"trigger": "intent_chosen", "once_per_turn": true,
	"when": {"unit": "enemy", "intent_target": "ally"},
	"effects": [
		{"type": "timeline", "move": 1, "target": "event_unit"},
		{"type": "aura", "aura": "marked", "target": "event_unit"}
	]
}
```

| Förmåga | Charges | Effekt |
|---|---|---|
| `falcon_dive` Dykattack | 8 | Skada 120 %, +50 % mot märkta |
| `scout_flight` Spejarflykt | 5 | Alla fiender blir Märkta i 2 turer |
| `wing_shadow` Vingskugga | 6 | En allierad får Agile (+20 % undvikande) i 2 turer |

⚙ triggern `intent_chosen`, effekten `timeline` och auran `agile` (`dodge_add`).
Samspel: Eira, Sefir, Bågskyttens sena och Hämndens ed.

### 3.2 Lirien Silversträng, bard. Regel: en buff till en blir en buff till alla.

```json
"lirien": {
	"name": "Lirien Silversträng", "title": "Bard", "role": "support", "color": "#9fd3ff",
	"stats": {"health": 620, "attack": 60, "intelligence": 85, "defense": 20, "speed": 13},
	"crit_chance": 0.08, "attack_ability": "dissonance",
	"abilities": ["battle_song", "lullaby", "heroes_ballad"],
	"traits": ["lirien_chorus"]
}
```

```json
"lirien_chorus": {
	"name": "Allsång",
	"text": "När Lirien ger en allierad en buff får alla andra i sällskapet samma buff i 1 tur.",
	"trigger": "aura_applied",
	"when": {"source": "self", "unit": "ally", "aura_is_buff": true, "from_trait": false},
	"effects": [{"type": "aura", "aura": "event_aura", "duration": 1, "target": "other_allies"}]
}
```

| Förmåga | Charges | Effekt |
|---|---|---|
| `battle_song` Stridssång | 6 | En allierad får Styrka (`inspired`) i 3 turer |
| `lullaby` Vaggvisa | 5 | En fiende somnar (`sleeping`: hoppar över turer tills den tar skada, högst 2) |
| `heroes_ballad` Hjältens ballad | 4 | En allierad flyttas till toppen av tidslinjen |

⚙ `aura_is_buff`, `aura: event_aura`, auran `sleeping` och effekten `timeline` (`to_top`).
Samspel: Brokks Stridsrop, Gryningens ed (*Holy Might*) och Helig sköld.

### 3.3 Broder Tove, munk. Regel: att undvika blir ett anfall.

```json
"tove": {
	"name": "Broder Tove", "title": "Munk", "role": "tank", "color": "#e2b36b",
	"stats": {"health": 750, "attack": 85, "intelligence": 40, "defense": 25, "speed": 16},
	"crit_chance": 0.1, "attack_ability": "palm_strike",
	"abilities": ["wind_step", "pressure_point", "still_water"],
	"traits": ["tove_mirror_hand"]
}
```

```json
"tove_mirror_hand": {
	"name": "Spegelhand",
	"text": "När Tove undviker ett anfall kontrar han för 100 % och blir 10 % snabbare resten av striden.",
	"trigger": "dodge",
	"when": {"target": "self"},
	"effects": [
		{"type": "damage", "power": 1.0, "kind": "attack", "target": "source"},
		{"type": "stat", "stat": "speed", "pct": 0.1, "target": "self"}
	]
}
```

| Förmåga | Charges | Effekt |
|---|---|---|
| `wind_step` Vindsteg | 6 | Tove får Agile (+25 % undvikande) i 3 turer och Provokerar |
| `pressure_point` Tryckpunkt | 8 | Anfall 100 % och målet blir Scorned (kan inte anfalla) 1 tur |
| `still_water` Stilla vatten | 6 | Försvara och ta bort alla debuffar |

⚙ effekten `stat` (ändra stat i striden), auran `scorned` och effekten `dispel`.
Samspel: Väktarens ed (en munk som provocerar och undviker blir en tank utan Defense) och Hämndens ed.

### 3.4 Hulda Mossrot, druid. Regel: skada på en vän slår tillbaka genom rötterna.

```json
"hulda": {
	"name": "Hulda Mossrot", "title": "Druid", "role": "support", "color": "#6fbf73",
	"stats": {"health": 700, "attack": 50, "intelligence": 90, "defense": 30, "speed": 8},
	"crit_chance": 0.06, "attack_ability": "thorn_whip",
	"abilities": ["snaring_roots", "leaf_shield", "spore_ring"],
	"traits": ["hulda_rootwork", "hulda_rootwork_strike"]
}
```

```json
"hulda_rootwork": {
	"name": "Rotverk",
	"text": "Huldas förmågor ger målet ett Rotskott (högst 3). När bäraren tar skada slår varje rotskott angriparen för 15 % av Huldas Int.",
	"trigger": "action",
	"when": {"unit": "self", "action": "ability", "target": "ally"},
	"effects": [{"type": "stack", "stack": "rootling", "amount": 1, "max": 3, "target": "target"}]
},
"hulda_rootwork_strike": {
	"name": "Rotverk", "hidden": true, "text": "",
	"trigger": "damage", "scope": "party",
	"when": {"target": "self", "source": "enemy", "direct": true, "self_has_stack": "rootling"},
	"effects": [{"type": "damage", "stat": "intelligence", "stat_owner": "hulda", "pct": 0.15, "per_stack": "rootling", "kind": "indirect", "target": "source"}]
}
```

| Förmåga | Charges | Effekt |
|---|---|---|
| `snaring_roots` Snärjande rötter | 6 | En fiende blir Snared: fast längst ned på tidslinjen i 2 turer |
| `leaf_shield` Lövskydd | 6 | En allierad får Barrier (25 % av Huldas Int × 4) och 1 rotskott |
| `spore_ring` Svampring | 5 | Alla fiender blir Poisoned (indirekt skada 30 % av Huldas Attack i 3 turer) |

⚙ stacks på andra än bäraren, `self_has_stack`, `per_stack`, `stat_owner`, och aurorna `snared` och
`poisoned`. Siralims regel att rotskott kan vissna (25 % per tur) kan vänta.
Samspel: Brokk eller en provocerande tank som samlar träffarna, och Väktarens ed.

### 3.5 Ragnhild Ljusdom, före detta domare. Regel: fiendens helning och buffar bränner.

```json
"ragnhild": {
	"name": "Ragnhild Ljusdom", "title": "Domare", "role": "dps", "color": "#ffd27a",
	"stats": {"health": 800, "attack": 75, "intelligence": 80, "defense": 45, "speed": 9},
	"crit_chance": 0.08, "attack_ability": "gavel_strike",
	"abilities": ["brand", "dispel_lie", "light_wave"],
	"traits": ["ragnhild_truth_light"]
}
```

```json
"ragnhild_truth_light": {
	"name": "Sanningens ljus",
	"text": "När en fiende helas eller får en buff bränner ljuset den: Helig skada lika med 50 % av Ragnhilds Int.",
	"trigger": ["heal", "aura_applied"],
	"when": {"target": "enemy", "aura_is_buff_or_heal": true},
	"effects": [{"type": "damage", "stat": "intelligence", "pct": 0.5, "school": "holy", "kind": "indirect", "target": "target"}]
}
```

| Förmåga | Charges | Effekt |
|---|---|---|
| `brand` Brännmärke | 6 | Fienden blir Blighted (helning skadar i stället) och Vulnerable i 2 turer |
| `dispel_lie` Skingra lögnen | 6 | Tar bort alla buffar från en fiende |
| `light_wave` Ljusvåg | 5 | Helig skada 70 % på alla fiender |

⚙ en lista av triggers (eller två traits), `aura_is_buff_or_heal`, auran `blighted` och effekten
`dispel`. Samspel: svaret på kapellets präster och Benfursten. Paladinens heliga skada och Eiras märke.

### 3.6 Sefir av Sanden, svärdsdansare. Regel: kritiska träffar ger en ny tur.

```json
"sefir": {
	"name": "Sefir av Sanden", "title": "Svärdsdansare", "role": "dps", "color": "#ff6f61",
	"stats": {"health": 600, "attack": 95, "intelligence": 40, "defense": 15, "speed": 17},
	"crit_chance": 0.18, "attack_ability": "scimitar",
	"abilities": ["dancing_steel", "wind_stride", "thousand_cuts"],
	"traits": ["sefir_blade_whirl"]
}
```

```json
"sefir_blade_whirl": {
	"name": "Bladvirvel",
	"text": "En kritisk träff flyttar Sefir till toppen av tidslinjen (en gång per tur).",
	"trigger": "damage", "once_per_turn": true,
	"when": {"source": "self", "crit": true, "direct": true},
	"effects": [{"type": "timeline", "to_top": true, "target": "self"}]
}
```

| Förmåga | Charges | Effekt |
|---|---|---|
| `dancing_steel` Dansande stål | 8 | Två anfall à 60 % mot samma mål |
| `wind_stride` Vindens steg | 5 | Sefir till toppen av tidslinjen och Savage (+20 % krit) i 2 turer |
| `thousand_cuts` Tusen snitt | 5 | Alla fiender Bleeding (indirekt skada 8 % av max liv i 3 turer) |

⚙ effekten `timeline` och aurorna `savage` och `bleeding`. Siralim nollställer gränserna per tur när
någon flyttas till toppen. Behåll därför vår `TURN_LIMIT` och `once_per_turn`, så att det inte blir
oändliga turer. Samspel: krit-troféer, Eiras och Ronjas märken.

### Motorbehov, i ordning efter hur många som behöver dem

1. **Effekten `timeline`** (`to_top` / `move: n`): Ronja, Lirien, Sefir. Siralim har samma regler:
   en boss flyttas bara ett steg.
2. **Nya auror:** `agile`, `sleeping`, `snared`, `scorned`, `blighted`, `poisoned`, `bleeding`,
   `savage`. Siralims standardvärden står i `siralim.md` §7.
3. **Effekten `dispel`:** Tove, Ragnhild.
4. **Effekten `stat`:** stat-ändring i striden, med Siralims golv på 20 % och avtagande över 500 %.
5. **Triggern `intent_chosen`:** Ronja. Den kan också ge bossar svar på avsikter.
6. **Villkor och fält:** `aura_is_buff`, `event_aura`, `self_has_stack`, `per_stack`,
   `stat_owner`, och flera triggers i ett trait.

## Källor

- [Codex Reference (Steam-guide, spelets Codex 2.0.37)](https://steamcommunity.com/sharedfiles/filedetails/?id=2197484456):
  Knowledge, Masters, Mastery, Battle History, Achievements.
- [Wiki: Cards](https://siralimultimate.wiki.gg/wiki/Cards), [Wiki: Creatures](https://siralimultimate.wiki.gg/wiki/Creatures),
  [Wiki: Combat](https://siralimultimate.wiki.gg/wiki/Combat), [Wiki: FAQ](https://siralimultimate.wiki.gg/wiki/Frequently_asked_questions).
- [Steam: Creature Rank](https://steamcommunity.com/app/1289810/discussions/0/3194740147273210296/),
  [Steam: Some newbie questions](https://steamcommunity.com/app/1289810/discussions/0/3048356660219462671/),
  [Creature Cards Guide (GamePretty)](https://gamepretty.com/siralim-ultimate-creature-cards-tips-tricks/).
