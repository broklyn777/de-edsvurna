# Varslade attacker, och svar på "tanken provocerar, helaren helar"

Underlag på papper. Inget är byggt eller beslutat; VD bestämmer.
Märkning: **Siralim** = som originalet, **VAL** = vårt val med motivering, **GISSNING** = obeprövad bedömning,
⚙ = kräver ny kod (S liten, M mellan, L stor); utan ⚙ räcker dagens egenskaper, effekter och regler. **VD** = beslut som behövs.
Ton: fienderna får vara onda och fördärvade; sällskapets sida är aldrig ockult.

## 0. Problemet och utgångsläget

VD: svårighet får inte bara vara mer liv och skada. I PoE och WoW varierar striderna genom att man avbryter en besvärjelse
eller gömmer sig bakom en pelare. Det går inte rakt av i turordning utan rum. Dessutom är det enkla mönstret för starkt:
**tanken provocerar, helaren håller tanken vid liv, resten slår.**

Tanken i det här dokumentet: **tid i stället för rum.** Pelaren blir Försvara vid rätt tur; avbrottet blir Tystad, sömn
eller att döda den som kanaliserar; positionen blir platsen på tidslinjen. Och som i Siralim ska fienderna ha egenskaper
som straffar en viss strategi, så att makrona måste svara (**Siralim**, siralim.md §21.2: motdragen finns just för det).

Vad som redan finns och som det här bygger på (läst i koden 2026-10-24):

| Finns | Var | Vad det ger oss |
|---|---|---|
| Avsikt syns i förväg | `CombatSim._choose_intent`, `_intent_chosen`, `fx.gd _draw_intent` | Ikonen ovanför fienden. En laddning är en avsikt som varar längre. |
| `ignore_taunt` | förmågans fält, `_targets_for`, `_pick_targets` | Förmågor som går förbi provokation. |
| `pick`: lowest, random, first, healer, highest_attack, caster, last_attacker, `pick_aura` | `_pick_targets` | Helarjägare finns redan (Inkvisitorn). |
| Motdrag (`counter`) | `CombatSim.counter_for`, encounters/enemies.json | Högst ett per grupp, elit/Nemesis/boss, från visst djup. |
| `self_last_attacked`, `self_hp_below`, `family_at_least`, `alone`, `self_stacks_at_least` | `_rule_matches` | Villkor för fiendens regler. |
| Fas vid 50 % | `lich_undying_wrath` (`once_per_battle`, trigger damage, `self_hp_below`) | En fasväxling går redan att skriva som egenskap. |
| Immun så länge en viss allierad lever | `bishop_aegis` (`immune_while_ally_kind: cultist`), `is_immune` | Prioritetspussel finns. |
| Straff för upprepning | Bergakungens `stone_heart` (`source_repeats_team_action`), Inkvisitorns `interrogation` | Just det som tank+hel gör: samma sak varje tur. |
| Straff för Provocera/Försvara | Broms Tull (+50 % mot den som Provocerar), Stenkrossarens Klubban (dubbelt mot Försvarar) | Ett första anti-tank-verktyg. |
| Ingen läkning | auraflaggan `no_heal` (Trollhud), motdraget Ordensregeln (`limit_enemy_heals`) | Anti-helare finns i liten skala. |
| Tidslinjen | `_move_on_timeline`: `to_top`, `to_bottom` | Se gränserna nedan. |

**Två fynd som styr allt nedan:**

1. **Tystad biter inte på Resistenta** (`is_silenced` kräver `not u.resistant`; texten: "Resistent: kan, men gör 50 % mindre
   skada"). Alla bossar är Resistenta. Sover: en Resistent vaknar i början av sin tur. Alltså kan spelaren i dag varken tysta
   eller söva en boss för att vinna tid. Avbrott mot bossar måste därför byggas in i själva laddningen (§1.3).
2. **`to_bottom` är svagt i bosstrider**: bossen flyttas bara ett steg, och andra fiender i en bosstrid går inte att skicka
   ned alls (`reason: boss_battle`). Till toppen högst en gång per runda (`MAX_TOP_PER_ROUND`). Och **ingen hjälte har i dag en
   förmåga med `to_bottom`**; Tystad finns bara i troféer (Den brutna trollstaven 50 %, Inkvisitorns sigill). Sällskapets
   verktyg i dag: Lirien Vaggvisa (sömn), Tove Tryckpunkt (Hånad), Ragnhild Skingra lögnen (dispel), Alva Helande ljus
   (rensar debuffar), Hulda Lövskydd (Barriär), Paladinen Helig sköld (Beskyddad −50 %), alla kan Försvara.

## 1. Varslade attacker

### 1.1 Vad spelaren ser

En boss eller elitfiende väljer en stor handling som tar 1–2 av dess egna turer att ladda. Avsikten visar det direkt:

- Ikonen ovanför fienden får en ring med segment (ett per tur kvar) och en siffra. Text under: **"Samlar berget – om 2 turer"**.
  Målet markeras som i dag (en linje eller ring på hjälten; för hela sällskapet alla ramar).
- Tidslinjen: fiendens bricka får en röd kant och en liten siffra. Längre ned i kön står en **spökbricka** ("här slår den"),
  på den plats där den släpps, så att spelaren ser hur många hjälteturer som återstår. Flyttas fienden, flyttas spökbrickan.
- Inspect visar laddningen som en egen rad: vad den gör, hur den bryts.
- Bryts den: ordet **AVBRUTEN!** över fienden (samma stil som KOMBINATION!), ett eget ljud, och första gången en hjälpruta.
- Förklaringsloggen och skadeloggen skriver "Benfursten laddar Dödsdom (1 tur kvar)" och "Dödsdom avbröts: Tystad".

**VAL** (inte Siralim): Siralim visar inga avsikter och har inga laddningar i den här formen (**GISSNING**: inget i
siralim.md §9–21 beskriver det; närmast är egenskaper som slår till "var tredje tur"). Vi visar redan avsikter
(Into the Breach, 0.27 §5), och en laddning är samma idé en tur längre. Siralims anda är kvar: en egenskap hos fienden som
makrot måste svara på.

### 1.2 Hur det går till i striden

1. Fienden väljer avsikten (`_choose_intent`) som i dag. Har förmågan `windup`, sätts `u.charging = {ability, left, max,
   targets, taken}` och händelsen `windup_start` sänds. Turen den väljer räknas inte.
2. Varje egen tur medan den laddar: den gör ingenting annat (handlingen `"charging"`, kostar turen), `left` minskar,
   händelsen `windup_tick`. **VAL:** att ladda kostar turen; annars blir det bara ett extra slag.
3. När `left` når 0 i början av dess tur släpps förmågan som dess handling (`windup_release`), med målen från början
   (döda mål byts som i `_enemy_choice`). Cooldown startar som vanligt.
4. Bryts laddningen (§1.3): `windup_broken {unit, ability, reason}`, förmågan får sin cooldown, och fienden är
   **Vacklande** 1 tur: tar 25 % mer skada (**VAL**, belöningen för att lyckas; se fråga 1).

`left` räknas i fiendens egna turer, som allt annat (auror, cooldowns). Speed avgör alltså hur många hjälteturer man får.

### 1.3 Svaren (ett eller flera per laddning)

Varje laddning anger vilka svar som biter (`broken_by`). Det gör att olika laddningar kräver olika makron.

| Svar | Effekt på laddningen | Finns i dag | Kod |
|---|---|---|---|
| **Tystad** | Bryter den. **VAL:** gäller även Resistenta (statusen sätts, den bryter laddningen, men dess vanliga verkan halveras som i dag). Annars finns inget avbrott mot bossar. | bara troféer | ⚙S |
| **Sover / Frusen** | Skjuter upp (turen hoppas över, `left` minskar inte). Bryter inte. Resistenta vaknar i början av sin tur → ingen verkan. | Vaggvisa | – |
| **Ned på tidslinjen** (`to_bottom`) | Skjuter upp: fler hjälteturer före släppet. Boss: ett steg. Andra fiender i bosstrid: inte alls. Vanliga strider: hela vägen. | ingen hjälte | ⚙S (ett verktyg) |
| **Skaka loss** (stagger) | Tar fienden skada ≥ `stagger` × max-liv under laddningen bryts den. WoW:s "bränn den". **VAL.** | – | ⚙S |
| **Döda kanalen** | `channeled_by`: laddningen bryts om ingen levande allierad av den typen finns. Den som kanaliserar visas som "laddar" också. | – (likt `immune_while_ally_kind`) | ⚙S |
| **Försvara** (pelaren) | Bryter inte; tar 35 % mindre skada och +50 % Defense som i dag. Ett hela-sällskapet-släpp mot alla som Försvarar är halverat. | ja | – |
| **Barriär/Beskyddad i förväg** | Bryter inte; tar smällen. Helig sköld (−50 %), Lövskydd. | ja | – |
| **Skingra** | Laddningen är *inte* en buff och går inte att skingra (**VAL**: annars blir Ragnhild svaret på allt). | – | – |

Regel (**VAL**): varje laddning har **minst ett brytande svar och ett dämpande** (Försvara/Barriär). Den som saknar
avbrottsverktyg ska kunna överleva genom att ta skydd; den som har verktyget får Vacklande som belöning.

### 1.4 Datans form

På förmågan i `abilities.json` (så att avsikten, Inspect och hjälpen läser samma ställe):

```json
"lich_doom": {
  "name": "Dödsdom", "target": "enemy", "pick": "lowest", "ignore_taunt": true, "power": "…",
  "windup": {
    "turns": 1,
    "text": "pekar på {mål}",
    "broken_by": ["silenced", "stagger"],
    "stagger": 0.15,
    "channeled_by": "",
    "vulnerable_after": 1.25
  }
}
```

I fiendens `rules` behövs inget nytt: regeln väljer förmågan som i dag. Ett valfritt fält på regeln, `"windup": 2`, får
ändra antalet turer per fiende (eliten laddar fortare än bossen) ⚙S. Motdragens regel gäller: **högst en laddning per grupp
utanför bossmöten**, bara elit, Nemesis, miniboss och boss (**VAL**, samma som motdragen).

Händelser ⚙S: `windup_start`, `windup_tick`, `windup_delayed {reason: sleep|frozen|bottom}`, `windup_release`,
`windup_broken {reason: silenced|stagger|channel}`. `battle.gd` översätter dem; `audit_sim.gd` behöver bara känna till
`"charging"` som en handling utan skada.

### 1.5 Makrovillkor ⚙S

Utan villkor kan makrot inte svara, och då är laddningen bara mer skada. Nya i `MacroRunner.CONDITIONS`:

| Villkor | Svensk text i editorn | Subjekt |
|---|---|---|
| `is_charging` | "laddar" | fiende (vilken som helst, en viss) |
| `charge_left_at_most` (värde n) | "laddar, slår om högst n turer" | fiende |
| `charging_all` | "laddar mot hela sällskapet" | fiende |
| `is_charge_target` | "är måltavla för en laddning" | allierad, jag själv |
| `is_channeling` | "kanaliserar" (ett tillägg som håller laddningen) | fiende |

"Turer" i villkoret = fiendens egna turer, som på ikonen. Raderna spelaren behöver, typiskt överst:

```
Om någon fiende laddar mot hela sällskapet, slår om högst 1 tur → Försvara
Om någon fiende kanaliserar → Anfall den
Om någon allierad är måltavla för en laddning → Helig sköld på den
Om någon fiende laddar → Tryckpunkt/avbrott på den   (när ett sådant finns)
```

Radeditorns grupper (0.30.24): en ny grupp **Laddning** bredvid Status. Sökfältet hittar "laddar".
`Spara som order` (0.30): väljer spelaren själv Försvara när en fiende laddar mot alla, erbjuds raden ovan som order.
Det är det bästa sättet att lära ut den (**VAL**).

### 1.6 Avbrott för sällskapet (luckan)

I dag kan bara troféer tysta. Förslag, alla ⚙S och i vår ton (inget ockult):
- **Tove, Tryckpunkt:** får `breaks_windup` (slaget mot nervpunkten bryter laddningen, inte via Tystad). Hennes roll blir
  avbrytaren. **GISSNING**: bäst passform bland dagens.
- **Paladinen, Domens kall:** en perk *Domens ord*: "Rättfärdigt slag tystar en fiende som laddar." Fråga 5.
- **En trofé** ur en ny elitfiende med `to_bottom` vid träff (som Irrbloss-motdraget, fast åt vårt håll).
Ingen av dem ska vara det enda svaret; stagger och Försvara räcker alltid.

## 2. Mot "tanken provocerar, helaren helar"

Mönstret ska fortfarande fungera i de flesta strider (det är bra makrospel), men inte vara svaret på allt.
Siralims sätt: varje motdrag slår mot *en* strategi, och man byter trofé eller rad när man möter det.

| Verktyg | Exempel | Varför tanken ändå behövs | Finns / kod |
|---|---|---|---|
| **Svep** (alla hjältar) | Benstorm, Bergets vrede, Mörk mässa | Provokation hjälper inte; Försvara åt alla gör. | finns |
| **Klyv**: målet + en slumpad till för 50 % | Benkolossen, Den svarta lansen | Huvudslaget går fortfarande på tanken. | ⚙S (`splash`) |
| **Spräckt sköld** (märke på den som Provocerar) | Varje träff på en provocerande hjälte: −10 % Defense, staplar till 3; går bort med rensning eller när hen slutar provocera en tur. | Byt tank eller låt helaren rensa (Helande ljus rensar redan). Ett märke, inte ett förbud. | ⚙S (aura + trigger, som Tull) |
| **Fas utan hån** | Benfurstens vrede: alla förmågor `ignore_taunt` under 50 %. | Före fasen gör tanken jobbet; efter måste alla klara sig. | ⚙S (fasdata §3) |
| **Helarjägare** | `pick: healer` på en laddning eller ett slag med `ignore_taunt`. | Tanken skyddar inte; helaren behöver Barriär eller Försvara på rätt tur. | finns |
| **Skuld** (mindre helning) | Debuff: tar 50 % mindre helning i 2 turer. | Hel-spam räcker inte; tanken måste Försvara själv eller få Barriär. | ⚙S (`heal_taken_mult`) |
| **Straff för upprepning** | Stenhjärta, Förhör | Tank+hel upprepar samma handling varje tur. | finns |
| **Den som slog senast** | Broms Tull (`last_attacker`) | Fienden väljer själv mål; tanken drar fortfarande vanliga slag. | finns |

Regler (**VAL**) så att provocera förblir värt det:
1. **Högst ett anti-mönster per grupp**, bara elit, Nemesis, miniboss, boss. Vanliga grupper följer hån som i dag.
2. Enkelmålsladdningar **följer hån som standard** (utom när `ignore_taunt` står uttryckligen). Då är "tanken provocerar
   och Försvarar när bossen laddar" ett *svar*, inte ett problem.
3. Märket på tanken går att rensa med dagens verktyg (Helande ljus, Stilla vatten). Helaren får ett nytt jobb, inget förbud.
4. Elitkortet i grottan visar anti-mönstret på samma rad som motdraget, så att spelaren kan byta trofé vid lägerelden.

## 3. Faser och prioritet

**Faser** ⚙M. I dag går det med en egenskap per fas (`lich_undying_wrath`). Det håller för en fas, inte tre. Förslag på
fiendens data:

```json
"phases": [
  {"below": 0.5, "text": "Benfursten vredgas!", "rules": [ … ], "add_traits": ["…"], "all_ignore_taunt": true,
   "on_enter": [{"type": "cast", "ability": "bone_storm"}]}
]
```

En fas byter `rules` (avsikterna), lägger till egenskaper och kan göra något direkt. Händelse `phase {unit, index}`; ramen
och Inspect visar "Fas 2". Makrovillkoret `hp_below` på fienden räcker för spelaren (finns). **VAL:** högst två faser
per boss; en laddning som pågår när fasen växlar släpps inte utan börjar om (annars kan stagger och fasskiftet krocka).

**Prioritetspussel** (döda X först), finns och nytt:
- Finns: biskopens sköld (Kultist), Kultens förman (livvakt, `guard_family`), Klockaren (alla upp på tidslinjen),
  Gravväckaren (väcker), Kistbäraren (Barriär när den faller: döda den *sist*).
- Nytt: **kanalen** (§1.3) – ett tillägg som håller bossens laddning. Pusslet blir tidsatt: hinner vi döda den på två turer?
- Nytt ⚙S: **Länkade** – två tillägg som väcker varandra om den andra lever två turer senare. Döda båda nära varandra.
Makron svarar med `has_trait` (finns) och `is_channeling` (nytt).

## 4. Tidslinjen som position

Vi har inget golv att flytta oss på, men tidslinjen är en rad. "Bakom pelaren" blir "inte närmast fienden i tiden".

- **Efterslag** ⚙M: ett slag mot *den som står närmast efter fienden* på tidslinjen (`pick: timeline_next`). Snabba hjältar
  hamnar ofta där; den som vill gömma sig skickar sig själv ned (Klockrepets kostnad finns som trofé) eller Försvarar.
- **Spökbrickan** (§1.1) gör det läsbart: man ser vilka hjältar som hinner före släppet.
- **Till toppen som svar**: en hjälte som flyttas överst (finns som effekt, `to_top`) hinner Försvara eller döda kanalen.
  Gränsen en gång per runda gäller.
- **Svallvåg** ⚙S: laddningen träffar bara hjältar som *inte* har agerat sedan den började (de som stod "i vägen").
  Förslag för en senare boss, inte för steg 1.
Makrovillkoren finns redan: `top_of_timeline`, `bottom_of_timeline` och deras motsatser.

## 5. Tre exempel

Siffrorna är startpunkter. Bottarnas påverkan är **GISSNING** tills `BALANS=grotta` och `balance_report.gd` har körts.
"MACRO" = startmakrona, "TUNED" = botarnas bästa makron.

### 5.1 Benfursten (kryptan)

I dag: Dödsdom (3,0, lägst liv) under 50 %, Väck de döda, Benstorm var tredje tur, vrede vid 50 %.

- **Laddning: Dödsdom** blir `windup: 1` ("pekar på Eira – Dödsdom om 1 tur"), `pick: lowest`. Följer hån *före* vreden.
  Bryts av Tystad (även på honom, §1.3) och av stagger 15 %. Dämpas av Helig sköld, Försvara.
- **Anti-mönster: Fas utan hån.** Vreden (50 %) gör alla hans förmågor `ignore_taunt`. Före: tanken tar Dödsdom.
  Efter: målet själv måste skyddas.
- **Makrorad:**
  ```
  Om någon allierad är måltavla för en laddning → Helig sköld på den         (Paladinen)
  Om jag är måltavla för en laddning → Försvara                               (alla andra)
  ```
- **Bottarna (GISSNING):** i dag faller någon ofta på Dödsdom utan förvarning. Med varningen: TUNED +5 till +10
  procentenheter på bossvåningen (de får en tur att reagera); MACRO −5 (vreden tar bort tankens skydd, utan nya rader). Med
  raderna i startmakrona: ungefär som i dag. Profilens första nedstigning (×0,81 för Benfursten) bör mätas för sig.

### 5.2 Den fallne biskopen (kapellet)

I dag: immun så länge en Kultist lever, Förbannad predikan (Försvagad på alla), Mörk mässa (0,5 på alla).

- **Laddning: Svarta mässan** (ny, ersätter Mörk mässa) `windup: 2`, alla hjältar, 1,2 och Försvagad 2 turer,
  `channeled_by: cultist`. Kultisten som sjunger visas som "kanaliserar". Bryts när sista Kultisten dör (som också tar bort
  hans immunitet), dämpas av Försvara. Har ingen Kultist levt kvar väljer han predikan i stället.
  Varför: i dag är Kultisten ett lås; nu blir den en **klocka** – två turer att döda den.
- **Anti-mönster: Skuld.** Predikan ger också Skuld (−50 % helning tagen, 2 turer) på den som Provocerar. Tanken kan inte
  bara helas upp; rensa med Helande ljus eller Försvara. (Helarjägare vore ett andra anti-mönster; vi håller oss till
  **ett** per boss, §2 regel 1.)
- **Makrorad:**
  ```
  Om någon fiende kanaliserar → Anfall den                                    (alla som slår)
  Om någon fiende laddar mot hela sällskapet, slår om högst 1 tur → Försvara  (helaren och tanken)
  Om någon allierad har status Skuld → Helande ljus på den                    (Alva: rensar)
  ```
- **Bottarna (GISSNING):** kapellet MACRO är i dag ca 44–66 % beroende på mätning; Kultisten dödas redan först av TUNED.
  Svarta mässan blir sällan släppt mot TUNED (−0 till −5), men MACRO tappar 10–15 procentenheter tills startmakrona får
  kanalraden. Skuld märks mest för Brokk+Alva-byggen (−5).

### 5.3 Bergakungen (Trollfolket, ännu utan Realm)

I dag: Resistent, Trollhud, Stenhjärta (−60 % skada mot upprepning), Bergets vrede (0,75 på alla, 20 % Förstenad) var
tredje tur. Mätt: 78 turer mot biskopens 71.

- **Laddning: Bergets vrede** blir `windup: 2` ("samlar berget – om 2 turer"), 1,4 på alla, Förstenad 40 %.
  Bryts av **stagger 15 %** (Tystad biter inte: berget lyssnar inte på ord, **VAL** för variation). Stenhjärta gör att
  bränningen måste *varieras* (anfall, förmåga, anfall) – laddningen och den egna egenskapen spelar ihop. Dämpas av Försvara.
- **Anti-mönster: Spräckt sköld.** Klubban mot den som Provocerar ger −10 % Defense, staplar till 3. Rensas med Helande
  ljus eller Stilla vatten, eller byt tank. (Bergakungen har redan Stenhjärta mot upprepning; Spräckt sköld gör att tanken
  inte heller kan stå still. Om det blir för mycket: stryk Spräckt sköld och låt Stenhjärta vara anti-mönstret.)
- **Makrorad:**
  ```
  Om någon fiende laddar, slår om högst 2 turer → Förmåga på den             (Solveig, Eira)
  Om någon fiende laddar, slår om högst 2 turer → Anfall den                  (Imma, Paladinen)
  Om någon fiende laddar mot hela sällskapet, slår om högst 1 tur → Försvara
  Om jag har status Spräckt sköld → Försvara                                   (tanken)
  ```
  Variationen kommer av att olika hjältar har olika rader (anfall hos några, förmåga hos andra), så Stenhjärta inte slår
  till varje gång. **GISSNING:** spelaren hittar det via hjälprutan och Stenhjärtas text.
- **Bottarna (GISSNING):** striden blir kortare för TUNED (staggern skär bort långa vrede-cykler), 60–70 turer; MACRO
  förlorar oftare (−10 till −20) eftersom startmakrona upprepar handlingar. Först meningsfullt med en Realm.

## 6. Byggordning

1. **Laddningen + Benfursten** ⚙S–M. `CombatSim`: `charging`, handlingen `"charging"`, `broken_by` (Tystad även på
   Resistenta, stagger, kanal), sömn och `to_bottom` skjuter upp, Vacklande, händelserna. Makrovillkoren `is_charging`,
   `charge_left_at_most`, `charging_all`, `is_charge_target`. UI: ring och siffra på avsikten, spökbrickan, AVBRUTEN!, rad i
   Inspect och loggarna. Dödsdom med `windup: 1`. Tester `tests/test_windup.gd`; `audit_sim.gd` känner `"charging"`;
   botarna: `BALANS=forsta` och `BALANS=grotta` på kryptan före och efter. Flagga `--windup` för skärmdumpar.
2. **Lära ut det:** hjälpruta "Varslad attack", sida i Alriks handbok, Gorms tips efter den första laddningen, "Spara som
   order" för Försvara-raden, eventuellt Försvara-raden i startmakrona (fråga 3).
3. **Biskopen** med Svarta mässan och kanalen (`channeled_by`, `is_channeling`).
4. **Anti-mönstren:** Spräckt sköld, Skuld, klyv. Ett per elitgrupp där det passar, på elitkortet.
5. **Faser som data** (`phases`), Benfurstens vrede flyttas dit.
6. **Avbrott för sällskapet** (Toves Tryckpunkt eller Paladinens perk), sedan Bergakungen när Trollfolket får en Realm.
7. Senare: Efterslag, Svallvåg, en laddning per Realm för elitfiender.

Varje steg spelbart på telefonen före nästa. Testet: lägger spelaren frivilligt till en rad efter första Dödsdom?

## 7. Frågor till VD

1. **Bruten laddning:** räcker det att den är förlorad (och cooldown), eller ska fienden också vara Vacklande (+25 % skada
   tagen en tur) som belöning?
2. **Tystad mot bossar:** ska Tystad bryta laddningar även på Resistenta (förslaget), eller ska bossar bara gå att bryta med
   stagger och kanal, så att Tystad förblir ett vapen mot vanliga fiender?
3. **Startmakrona:** ska de ha en Försvara-rad mot laddningar från början, eller ska spelaren upptäcka den (hjälpruta,
   Gorms tips, Spara som order)?
4. **Hur ofta:** bara bossar och elitgrupper (förslaget), eller också en vanlig fiende per Realm som laddar litet, så att
   spelaren lär sig innan bossen?
5. **Avbrottsverktyg:** ska Paladinen få ett eget (perk *Domens ord* i Domens kall), ska det ligga hos en lärjunge (Tove), eller
   bara i troféer som i dag?
