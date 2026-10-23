# Drakvalvets fiender: Likätaren, Blodsvuren, Kyrkogrimmen och vargen

> **Inkopplat 2026-10-23 på grenen `fiender-data`** (VD:s beslut): Likätaren och Gravgnagaren (äter inte hjältar), Blodsvuren
> och Blodfogden (ingen elitgrupp med Förmannen), Kyrkogrimmen i kapellet (väg A, `chapel_e7`), vargen som Benvargens figur
> (alternativ 1). Troféerna fick namn efter regeln "föremål eller lärdom": Likätarens tand → Den brutna gravspaden
> (`ghoul_spade`), Gravgnagarens käke → Den sprängda bojan (`gnawer_chain`), Paktkniven → Den brutna paktkniven, Blodseden →
> Den brutna fogdestaven (`bailiff_staff`), Grimmens halsband → Grimmens brustna halsband. Stats som i planen; mötenas
> `stat_mult` som planens gissningar. Ljudet `ghoul_feast` är inte gjort (Likmåltid använder bone_crush).

Skriven 2026-10-23 på grenen `drakvalvet-fiender` (från `test-0.30`). Den här omgången innehåller bara modeller och plan.
Ingen speldata och ingen kod är ändrad, eftersom Den levande kartan ändrar `data/` samtidigt.
Underlag:
- `data/enemies.json`, `traits.json`, `abilities.json`, `realms.json` och `encounters.json`;
- `docs/plan/0.27-fiender.md`, `troll.md` och `spindlar.md`;
- `docs/plan/roligare-fiender.md` (finns bara på main).

Märkning som i 0.27-fiender:
- **Siralim** = som originalet;
- **VAL** = vårt val;
- **GISSNING** = obeprövat;
- ⚙ = ny kod (S liten, M mellan).

**VD:s beslut 2026-10-23:**
- Ghoulen och vargen (med skelettfärg) går till kryptans Benfolket.
- Kultfanatikern går till kapellets Kultens folk.
- Helvetshunden blir antingen en ny familj eller en fiende i kapellet.
- "De behöver rätt sammanhang": var och en ska ha en egen roll i sin Realm och familj, inte bara vara en ny modell på en
  gammal fiende.
- Namnen och utseendet ska vara allvarliga.

**Måttstocken** (roligare-fiender §1): en fiende ska ställa en fråga som spelaren kan svara på före striden (trofé,
sällskap) och som en makrorad kan svara på i striden (`has_trait`, `has_status`, `hp_below`, `bottom_of_timeline` …).
Spelet är balanserat mot fyra hjältar, och ingen ny fiende lägger kontroll (CC).

## 0. Modellerna (klara)

| Fil | Källa | Rigg | Klipp (30 fps; Godot tar bort `_Loop`) | Höjd | Storlek |
|---|---|---|---|---|---|
| `ghoul.glb` | `Monster/ghoul.blend` | CharacterArmature 62 | Idle_Loop, Sword_Idle, Sword_Attack, Punch_Jab, Punch_Cross, Spell_Simple_Shoot (Interact), Hit_Chest, Death01, Walk_Loop, Run_Loop | 1,68 m | 917 KiB |
| `kultfanatiker.glb` | `Monster/kultfanatiker.blend` | CharacterArmature 62 | Sword_Idle (KF_Idle), Idle_Loop, Sword_Attack (KF_Slash), Chop_Attack (KF_Chop), Spell_Simple_Shoot (KF_Cast), Hit_Chest (KF_Hit), Death01 (KF_Death), Walk_Loop (KF_Walk), Run_Loop | 1,63 m | 944 KiB |
| `helvetshund.glb` | `Monster/hellhound.blend` | AnimalArmature 51 | Idle_Loop, Idle_Alert (Idle_2), Sword_Attack (bettet), Leap_Attack (Jump_ToIdle), Hit_Chest (HitReact_Left), Death01, Walk_Loop, Run_Loop (Gallop), Eat_Loop | 1,2 m (2,5 m lång) | 777 KiB |
| `varg.glb` | `Monster/varg.blend` | AnimalArmature 51 | som helvetshunden | 0,65 m (1,3 m lång) | 745 KiB |

**Så gjordes de:**
- Skriptet är en kopia av `export_hero.py`: `scratchpad/df/export_df.py`, och `export_alla.sh` exporterar alla fyra.
- Blender körs headless, en process i taget, och originalfilerna sparas aldrig.
- Ingen meshopt och ingen Draco, så ingen dequantize behövs.
- `.import` har inga LOD- eller skuggmeshar, som de andra figurerna.

**Detaljer per fil:**
- I `kultfanatiker.blend` har klippen redan 30-fps-längd, fast scenen säger 24 fps. Därför byts bara scenens takt
  (`@setfps=30`); annars blir klippen 25 % för långsamma.
- I djurfilerna finns varje klipp två gånger, med samma innehåll. Exporten använder `AnimalArmature|…`.

**Godot läser alla fyra.** Det är kontrollerat med en egen skriptkörning: alla klipp finns och har rätt längd.

**Visuell kontroll** i `tools/anim_lab.tscn` (`--models=<fil>`, Idle → anfall → träff → död). Kontaktarken och
bildrutorna ligger i scratchpad (`df/ark/<figur>.png`, `df/mov/<figur>/`).

**Att tänka på vid inkopplingen:**
- **Ghoulen:**
  - Den har klor och lysande ögon och ser rätt ut i alla klipp.
  - Huden är ljust grågrön och blir nästan grå i kryptans ljus.
  - Förslag: `colors` för `Gho_Skin` mot gulgrått och `emit` på `Gho_EyeGlow`.
- **Kultfanatikern:**
  - Röd kåpa med huva och en paktkniv i högerhanden (`Kfan_PactBlade`).
  - Hänget lyser gult (`Kfan_Glow`), och KF_Slash och KF_Chop är tydliga.
  - Dödsklippet faller framåt.
- **Helvetshunden:**
  - Lågorna på manken och svansen (`Hh_Flame`) och käken (`Hh_Glow`) är gula men lyser inte efter exporten.
  - Ge dem `emit` och ett orange `light`.
  - Den är stor (2,5 m lång). `scale` 0,75–0,85 passar bredvid skelettet.
- **Vargen:**
  - Grå. Benfärgen ges med `colors` (`Varg_Main` #d8cfb4, `Varg_Main_Light` #f0e8d0), inte en egen fil.
  - `scale` 1,2–1,3.
- Leap_Attack (Jump_ToIdle) och Eat_Loop finns för en signaturhandling. Eat_Loop är tänkt för vargen; Ghoulen använder
  Interact.

## 1. Likätaren (Ghoulen) – kryptan, Benfolket

**Sammanhang:** kryptans döda ligger inte stilla. Likätaren gnager benen av de fallna i Benfolket och blir starkare av
varje måltid. Det blir ett ordningspussel åt andra hållet än Kistbäraren:
- Kistbäraren ska dö sist.
- Likätaren ska dö *innan* de andra faller, eller när den är för svag för att det ska spela någon roll.

**VAL:** Siralim har ingen likätare som vi känner till. Mekaniken bygger på originalets mönster "räknar familjen" och
"reagerar på döda allierade" (Gravpakt, Unicorn Vivifier).

| | |
|---|---|
| Namn (id) | **Likätare** (`ghoul`); elitvariant **Gravgnagaren** |
| Realm, familj, rang | Kryptan, Benfolket (`bone_kin`), vanlig |
| Roll | Växer av de fallna (ordningspussel) |
| Stats | H 48, A 15, I 8, D 1, S 11. Spröd och lite snabbare än Skelettkrigaren (H 57,6, A 17,4, D 2, S 9), segare än Benspringaren (H 35, A 19, S 17). Farlig först när den har ätit. |
| Grundanfall | Likklor (`ghoul_claw`): 100 % skada, `pick: lowest`, närstrid, ljud k_boss_hit, anim Sword_Attack/Punch_Jab |
| **Egen förmåga** | **Likmåltid** (`corpse_feast`): mål en fallen ur Benfolket. Liket äts upp och kan inte väckas. Likätaren helas 35 % av sitt maxliv. Nedkylning 2. Avsikten syns ("äter Skelettkrigaren"). Anim Spell_Simple_Shoot (Interact, böjer sig fram), ljud nytt (gnag, `ghoul_feast`). ⚙S: effekten `consume_corpse` och målet `dead_ally` begränsat till familjen. |
| **Egen egenskap** | **Gravhunger** (`grave_hunger`): "Varje måltid ger Likätaren +20 % Attack för resten av striden (högst 3). Det den äter kan aldrig väckas." ⚙S: staplar med `stack`, som Växande vrede. |
| Makrots svar | `has_trait: Gravhunger` → anfall den först. När två fiender lever och en är nästan död: döda Likätaren innan du fäller den andra. |
| AI | `rules: [{"ability": "corpse_feast", "if": {"dead_ally": true}}]`, annars Likklor. ⚙S: `dead_ally` ska räkna bara Benfolket och bara lik som inte är ätna. |

**Samspel som gör den intressant:**
- **Gravväckaren och Benfursten tävlar med den om liken.** Den som agerar först tar liket, väckning eller måltid.
  Spelaren väljer: döda väckaren, så blir liken mat, eller döda Likätaren, så kommer de tillbaka.
- **Gravpakt** (Gravprästen) räknar fortfarande ett ätet lik som fallet. **VAL:** det är dött, bara inte väckbart.
- **Flockbett, Benmur och Sista tjänsten** räknar levande, så Likätaren ingår i familjen och stärker dem som vanligt.
- **Med två hjältar och en fallen hjälte:** Likätaren äter aldrig hjältar.
  - **VAL:** det vore ett motdrag mot väckning, och Sista klangen finns redan.
  - Om VD vill ha det kan Gravgnagaren få det som motdrag från djup 3 (öppen fråga 2).

**Troféer** (svaret på grupper som väcker):

| Trofé (id) | Sällsynthet | Text | `combo` | Svar på |
|---|---|---|---|---|
| Likätarens tand (`ghoul_tooth`) | vanlig | "Fiender som bäraren fäller kan inte väckas. Bäraren helas 10 % av sitt maxliv när hen fäller en fiende." | `{"needs": "kill", "creates": "no_revive", "scope": "self"}` ⚙S (ny nyckel, effekten `consume_corpse` på den fällde) | Gravväckaren, Benfursten, Strypvävarens Kokongen, regeln De döda vaknar |
| Gravgnagarens käke (`gnawer_jaw`) | elit (variant) | "När en fiende faller får bäraren +8 % Attack för resten av striden (högst 3)." | `{"needs": "enemy_death", "creates": "attack_up", "scope": "self"}` | Grupper med många små (Springarnas flock, Irrblossens dans, spindlarna) |

**Möten** (mallarna ur 0.27-fiender §4):

| Id | Namn | Fiender | Våning, tier | Mall | Prövar |
|---|---|---|---|---|---|
| `crypt_2g` | Likgropen | Likätare + Skelettkrigare + Skelettbågskytt | v1, tier 1 | Ny: "Den som äter" | Döda ätaren först. Bågskytten faller lätt och blir mat. |
| `crypt_3e` | Gnagda ben | Likätare + Benspringare ×2 | v2, tier 2 | Offret | Springarna dör fort och föder den. Försvara eller provocera mot flocken, eller döda Likätaren först. |
| `crypt_e7` | Gravfältet (elit) | Gravväckaren + Likätare + Skelettkrigare ×2 | v2, elit | Ny: "Två som vill ha liken" | Ordningen: väckaren eller ätaren först. `stat_mult` ~0,95 (GISSNING), `first_descent_stat_mult` 0,72. |

Ingen tier 0, eftersom de första striderna lär ut grunderna.

## 2. Blodsvuren (Kultfanatikern) – kapellet, Kultens folk

**Sammanhang:** kulten har sina egna edsvurna. Där Paladinen svär vid ljuset har Blodsvuren skurit en pakt med fördärvet.
Den slår med paktkniven och betalar med sitt eget blod, och kultisterna håller den vid liv.

Samspelet med kulten är redan inbyggt i datan:
- Kultistens **Skyddande bön** ger Barriär till *den svagaste allierade*. Blodsvuren gör sig själv till den svagaste.
- Diakonens helning går till den med lägst liv.

Kulten skyddar alltså sin fanatiker utan någon ny regel.

**Frågan till spelaren:** "Fäller du den som blöder sig stark, eller först den som håller den uppe?"

| | |
|---|---|
| Namn (id) | **Blodsvuren** (`cult_zealot`); elitvariant **Blodfogden** |
| Realm, familj, rang | Kapellet, Kultens folk (`cult_kin`), vanlig |
| Roll | Närstridare som blir farligare ju mer skadad den är, och som kulten skyddar |
| Stats | H 52, A 17, I 8, D 1,5, S 11. Slår som Botgöraren (H 56, A 16,5) men snabbare och utan försvar. Lever längre än Kultisten (H 42) bara tack vare Barriären. |
| Grundanfall | Paktkniven (`pact_knife`): 100 % skada, `pick: random`, närstrid, ljud k_hero_hit, anim Sword_Attack (KF_Slash) |
| **Egen förmåga** | **Blodhugget** (`blood_cut`): 140 % skada mot den svagaste. Blodsvuren förlorar 10 % av sitt maxliv (indirekt, förbi Barriär). Nedkylning 2, anim Chop_Attack (KF_Chop), ljud k_boss_hit. ⚙S: en effekt som skadar utföraren (`self_damage` med `pct` av maxliv). |
| **Egen egenskap** | **Blodpakt** (`blood_pact`): "Gör 10 % mer skada för varje tiondel liv Blodsvuren saknar (högst +50 %)." ⚙S: `modify` `damage_mult_per_missing_tenth`. |
| Makrots svar | "anfall fienden med lägst liv": Barriären tar slaget, men nästa slag fäller den. "Om fiende har Blodpakt och hp_below 50 % → anfall den." "Anfall Kultisten först" stoppar Barriären. |
| AI | `rules: [{"ability": "blood_cut", "if": {"self_hp_below": 0.9}}]` (den skär sig inte vid fullt liv i första turen), annars Paktkniven |

**Det ärliga:**
- Diakonens helning *sänker* Blodsvurens skada. Det är en svaghet i kultens samspel som spelaren kan läsa: en diakon i
  gruppen gör fanatikern ofarligare men segare.
- Blodsvuren kan döda sig själv med Blodhugget. **VAL:** golvet är 1 liv (`self_damage` dödar aldrig), så att en strid
  inte vinns av en slump.

**Troféer:**

| Trofé (id) | Sällsynthet | Text | `combo` | Svar på |
|---|---|---|---|---|
| Paktkniven (`pact_blade`) | vanlig | "Bäraren gör 6 % mer skada för varje tiondel liv hen saknar (högst +30 %)." | `{"needs": "low_health", "creates": "damage_bonus", "scope": "self"}` (ny `needs`) | Långa strider och höga liv (Asketen, bossar). Passar ihop med Barriär (Det brustna bönebandet, Kistspik) och med Väktarens kall. |
| Blodseden (`blood_oath`) | elit (variant) | "Första gången i striden som bäraren hamnar under 50 % liv får hen en Barriär för 25 % av sitt maxliv." | `{"needs": "low_health", "creates": "barrier", "scope": "self"}` | Stora slag (Lansens anstormning, Dödsdom, Blodhugget) |

**Möten:**

| Id | Namn | Fiender | Våning, tier | Mall | Prövar |
|---|---|---|---|---|---|
| `chapel_1d` | Paktens vakt | Blodsvuren + Kultist | v1, tier 0 | Skyddad präst, vänd | Lär ut paret: Barriären går till den som blöder. |
| `chapel_3f` | Blodmässan | Blodsvuren + Kultist + Fördärvad diakon | v2, tier 2 | Front och stöd | Ordningen. Diakonen gör den segare men svagare. |
| `chapel_3g` | Fanatikernas led | Blodsvuren ×2 + Fanbäraren | v2, tier 2 | Familj med ledare | Fanan och två som blöder sig starka: döda fanan eller fanatikerna först. |

**Ingen elitgrupp:** Förmannens vakt (50 % av skadan) ovanpå Barriär och Blodpakt blir troligen ett dödläge
(GISSNING; botarna avgör).

## 3. Helvetshunden – två vägar

### 3a. Väg A: kapellet, som **Kyrkogrimmen** (elit, utan familj)

**Sammanhang:** i svensk folktro begravdes ett djur levande under kyrkans grund för att vakta den, och det kallas
kyrkogrim. Kapellets kyrkogrim har fördärvet tänt eld i. Nu vaktar den kulten i stället för kyrkan.
- Det är kapellets eget väsen, allvarligt och inte ockult.
- Hundens lågor får en förklaring.
- Den står utanför båda familjerna, som Gasten och Irrblosset.

| | |
|---|---|
| Namn (id) | **Kyrkogrimmen** (`church_grim`) |
| Rang | elit (ingen 5 %-variant, som de andra elitfienderna) |
| Roll | Vakthund: straffar den som skadar någon annan än den själv |
| Stats | H 80, A 17, I 10, D 2, S 15. Långsammare och segare än Lansen (H 62, A 19, S 18). Lika seg som Förmannen (H 80) men snabbare. |
| Grundanfall | Glödbett (`grim_bite`): 100 % skada, sätter Brinner (som Glödhetta, 2 turer), `pick: lowest`, anim Sword_Attack, ljud fire_hit |
| **Egen förmåga** | **Eldsprånget** (`hellfire_leap`): 120 % skada mot den som senast skadade en fiende (`pick: last_attacker`, finns sedan trollen). Brinner i 2 turer. Nedkylning 3, anim Leap_Attack, `travel` kort, ljud fire_hit + k_boss_hit. |
| **Egen egenskap** | **Grimmens vakt** (`grim_watch`): "När en hjälte skadar en annan fiende med en direkt träff biter Kyrkogrimmen hen för 50 % (en gång per tur)." Bygger på `trigger: damage`, `when` source enemy, target ally, `target_not_self`, direct, och `damage` mot `event_source` med `once_per_turn`. Allt finns utom kanske `target_not_self` i just den kombinationen (⚙ ingen–S). |
| **Motdrag** (djup 3) | **Skrattande låga** (`laughing_wisp`, finns): "Kan inte få debuffar, men skickas längst ned på tidslinjen när den träffas." Det passar en eldhund. Motdraget gör rätt svar ännu tydligare: slå hunden, så hamnar den sist. Regeln om högst ett motdrag per grupp gäller: i en grupp med Irrbloss bär bara den ena. |
| Makrots svar | `has_trait: Grimmens vakt` → anfall den först. Mot Brinner: rena eller Försvara. Provocera hjälper inte mot vakten (en egenskap, ingen avsikt), och det är meningen. |
| AI | `rules: [{"ability": "hellfire_leap"}]` (när nedkylningen är klar), annars Glödbett |

**Trofé:**

| Trofé (id) | Sällsynthet | Text | `combo` | Svar på |
|---|---|---|---|---|
| Grimmens halsband (`grim_collar`) | elit | "När en fiende skadar någon annan i sällskapet än bäraren biter bäraren den fienden för 40 % (en gång per tur)." | `{"needs": "ally_hit", "creates": "follow_up", "scope": "party"}` (ny `needs`) | Grupper som fokuserar en hjälte (Botgörare + Häxa, Bågskytt, Lansen). Bärs av en tålig hjälte bredvid den som provocerar: hunden biter den som slår tanken. |

**Möte:**

| Id | Namn | Fiender | Våning | Mall | Prövar |
|---|---|---|---|---|---|
| `chapel_e7` | Grimmens vakt (elit) | Kyrkogrimmen + Kultist + Häxa | v2, elit | Ny: "Vakthunden" | Döda hunden först, fast Häxan tystar och Kultisten skyddar. Med motdraget (djup 3) går hunden inte att tysta eller försvaga. `stat_mult` ~0,9 (GISSNING). |

### 3b. Väg B: en ny familj, **Askans folk** (`ash_kin`), i en kommande Realm

- **Tanken:**
  - En Realm där elden är rasen, till exempel ett glödschakt under borgen.
  - Familjen bygger på Brinner, och medlemmarna räknar hur många hjältar som brinner (jämför Glödregn i
    roligare-fiender §2).
  - Hunden är familjens jägare. Drakvalvets **magmin** (eldväsen, 1,0 m) är den andra modellen.
- **För:**
  - Siralim har en ras per Realm.
  - Hunden får eld utan förklaring.
  - Glödskelettets idé om att elden sprider sig får ett hem.
- **Emot:**
  - Drakvalvet har bara två eldfigurer (hellhound och magmin). En Realm behöver omkring nio fiender, en vinjett,
    föremål, omkring 18 möten och egen musik.
  - Trollen och Lunden står redan i kö.
  - Ledstjärnan säger att vi ska bevisa kombinationerna innan vi bygger mycket innehåll.

### 3c. Rekommendation: väg A nu

- Kyrkogrimmen ger kapellet en vakthund som saknas: en fiende som skyddar *med hot* i stället för med Barriär eller
  provokation.
- Den använder motdraget Skrattande låga, som redan finns.
- Den kostar en fiende, en förmåga, en egenskap, en trofé och ett möte.
- Om Askans folk byggs senare kan hunden följa med som en färgad variant (till exempel **Askhunden**) med en egen
  familjeregel. Det som byggs nu går inte förlorat.

## 4. Vargen – ärligt: tillför lite som egen fiende

Benfolket har redan en snabb flockfiende, Benspringaren. Den har betyg 1 i roligare-fiender: Flockbett slår en gång och
sedan inget mer. En **Gravvarg** med samma roll (snabb, flock, benfärg) vore en ny modell på en gammal fiende, alltså
precis det VD inte vill ha.

**Två ärliga alternativ:**
1. **Rekommenderas: ingen egen fiende.** Vargen blir modellen för Benspringarens elitvariant **Benvarg**.
   - Namnet finns redan i `enemies.json`, och dess trofé heter Vargens språng.
   - En gulvit varg med glöd känns som en kryptvarelse när den lyser.
   - Kostnad: ⚙S, `variant.visual` (en egen modell för varianten) i `CombatSim`/`unit_model`.
2. **Gravvarg (vanlig) med Flockjakt**, roligare-fiender §2: "När en annan ur Benfolket anfaller följer Gravvargen upp
   mot samma mål för 30 % (en gång per tur)."
   - Den blir en multiplikator: döda den först eller provocera, så slår hela flocken i skölden.
   - Stats: H 34, A 14, D 1, S 15.
   - Trofé **Vargens tand** (`wolf_fang`, vanlig): "När en annan i sällskapet anfaller följer bäraren upp för 25 % (en
     gång per tur)." `combo` `{"needs": "ally_attack", "creates": "follow_up", "scope": "party"}`.
   - Möte "Gravvargarnas spår" (Gravvarg ×2 + Skelettkrigare, v1 tier 1).
   - Då bör Benspringaren få en annan roll, annars finns två snabba flockdjur.

## 5. Ny kod i nästa omgång (⚙, allt litet)

| Vad | Var | För |
|---|---|---|
| Effekten `consume_corpse` och flaggan `consumed` på `CombatUnit`; `revive` och målet `dead_ally` hoppar över ätna | `CombatSim._run_effect`, `_pick_targets` | Likmåltid, Gravhunger, Likätarens tand |
| `dead_ally` begränsat till den egna familjen (`"family": true` i förmågan eller villkoret) | `_pick_targets`, villkoret `dead_ally` | Likmåltid |
| Effekten `self_damage` (procent av maxliv, förbi Barriär, golv 1) | `_run_effect` | Blodhugget |
| `damage_mult_per_missing_tenth` | `modify_damage` | Blodpakt, Paktkniven |
| `combo`-nycklarna `kill`, `enemy_death`, `low_health`, `ally_hit` och kanske `ally_attack` | `traits.json` + kombinationsvisningen | troféerna |
| (vargen, alt. 1) `variant.visual` | `CombatSim`/`unit_model` | Benvarg |
| Ljudet `ghoul_feast` (gnag) | `tools/gen_sfx.py` | Likmåltid |

Tester som de andra familjerna: `tests/test_enemies_drakvalvet.gd` med ett test per mekanik:
- ätet lik går inte att väcka;
- Gravhunger staplar högst 3;
- Blodhugget dödar inte;
- Grimmens vakt biter en gång per tur och inte när man slår hunden själv;
- Skrattande låga på hunden.

Botarna:
- `BALANS=elitgrupper` för `crypt_e7` och `chapel_e7`;
- `BALANS=grotta` för båda Realms (inom ±5 procentenheter);
- `BALANS=forsta`, eftersom `chapel_1d` och `crypt_2g` ligger tidigt.

Ordlistan (`docs/ordlista.md`) får: Likätare/ghoul, Likmåltid/corpse feast, ätet lik/consumed corpse,
Blodsvuren/zealot, Blodpakt/blood pact, Kyrkogrimmen/church grim, Grimmens vakt/grim watch.

## 6. Öppna frågor till VD

1. **Kyrkogrimmen eller Askans folk?** Planen rekommenderar kapellet nu och familjen senare.
2. **Ska Gravgnagaren få äta fallna hjältar** som motdrag från djup 3? Det är hårt, ett lås mot väckning ovanpå Sista
   klangen. Planen säger nej.
3. **Vargen:** Benvarg-variantens modell (alternativ 1), en egen Gravvarg (alternativ 2) eller ingenting?
4. **Namnen:**
   - Likätare / Gravgnagaren;
   - Blodsvuren / Blodfogden (Blodsvuren speglar spelets titel *De edsvurna*; för nära eller rätt?);
   - Kyrkogrimmen.
5. **Blodsvuren som elit senare?** Med Förmannen blir den troligen ett dödläge. Ska botarna pröva det ändå?
