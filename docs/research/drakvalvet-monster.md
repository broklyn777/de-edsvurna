# Drakvalvets monster – inventering (2026-10-23)

Källa: `~/Desktop/Blender-Test/Drakvalvet/Monster/*.blend` (29 filer, `.blend1` är säkerhetskopior och räknas inte).
Allt lästes headless med `inventera.py` (Blender 4.2 LTS, `-b --factory-startup`, ingenting sparades). Färdiga exporter
ligger i `~/Desktop/Blender-Test/export/qt-<namn>.glb`. De flesta är packade med meshopt och måste köras genom
`gltf-transform dequantize` innan Godot kan läsa dem (se `ASSETS_LICENSE.md`).

## Riggar och animationer

- **CharacterArmature, 62 ben** (Quaternius Adventurer, King, Hooded Adventurer och Animated Woman): 24 färdiga
  Quaternius-klipp i .blend-filen (Idle, Idle_Sword, Walk, Run, Sword_Slash, Punch_Left/Right, Kick_Left/Right,
  HitRecieve, HitRecieve_2, Death, Interact, Wave, Roll, Gun-klippen …), med suffixet `_CharacterArmature.00x`.
  Längder vid 24 fps: Idle 40 rutor, Walk 32, Sword_Slash 24, HitRecieve 13, Death 25, Interact 30, Punch 20, Kick 22.
  Exporten (`Hjältar/export_hero.py`, `@fps=30`) döper om klippen till spelets namn: Idle_Sword → `Sword_Idle`,
  Idle → `Idle_Loop`, Sword_Slash → `Sword_Attack`, HitRecieve → `Hit_Chest`, Death → `Death01`, Walk → `Walk_Loop`,
  Interact → `Spell_Simple_Shoot`. Benen heter likadant som i `torvald.glb` och `skelett.glb` (kontrollerat), så
  `anims_from: ["torvald"]` bör ge Shield_*, TwoHand_*, Bow_* och Shield_Block även här, som för skelettet. Några har
  egna klipp (`Ako_`, `KF_`, `Rov_`, `Sva_`, `Som_`).
- **AnimalArmature, 51 ben** (brunbjörn, varg, hellhound): Idle, Idle_2, Walk, Gallop, Attack, Death,
  Idle_HitReact_Left/Right, Eating, Jump (varje klipp finns två gånger, `.003`-kopior).
- **Egna smårriggar**: RatArmature 31 (jätteråtta), SpiderArmature 29 (jättespindel), DarkmantleArmature 18,
  StirgeArmature 7. De klippen heter redan som spelet vill (`Idle_Loop`, `Sword_Attack`, `Hit_Chest`, `Death01`, `Walk_Loop`).
- Ingen fil saknar skelett. Ingen har ett blockklipp (Shield_Block lånas från torvald). `cast` = `Spell_Simple_Shoot`
  (Interact eller ett eget kastklipp).

## Tabell

Ytor = polygoner i .blend (trianglar i den exporterade GLB:n är något fler). Höjd = Z-omfång i viloläget (T-pose, så
bredden är armspannet; för djuren är längden angiven). "I spelet" jämför med `assets/models/` och `"model"` i
`data/enemies.json` / `heroes.json`.

| Fil | Rigg | Klipp i .blend (urval) | Ytor | Höjd (m) | I spelet | Passar som |
|---|---|---|---|---|---|---|
| akolyt | CharacterArmature 62 | 24 + Ako_Cast/Idle/Walk | 3 790 | 1,79 (stav) | **Ja**, som `alva.glb` och `gast.glb` | – |
| armborstskytt | CharacterArmature 62 | 24 + Arm_Shoot | 4 320 | 1,63 | Nej | Mänsklig skytt; Kultens folk (armborst i kapellet) eller en jägare |
| brunbjorn | AnimalArmature 51 | Idle, Walk, Gallop, Attack, Death, HitReact | 2 042 | 2,14 (1,9 lång) | Nej | Djurfamilj, troll-husdjur, Trollmors björn |
| darkmantle | DarkmantleArmature 18 | Idle_Loop, Walk_Loop, Sword_Attack, Hit_Chest, Death01 | 504 | 0,66 | Nej | Grottans takvarelse; Vinterhuset (fladdrande frost) med tint |
| ghoul | CharacterArmature 62 | 24 | 2 297 | 1,68 | Nej | Benfolket/kryptan: likätare, liten elit |
| goblin | CharacterArmature 62 | 24 | 4 855 | 0,99 | Nej | Ny familj små gruvfolk; Lärling Pling i Mässingsverket |
| goblinboss | CharacterArmature 62 | 24 | 5 015 | 1,28 | Nej | Ledare för en goblinfamilj; Fjärdingsman Fjun |
| goblinminion | CharacterArmature 62 | 24 | 4 855 | 0,89 | Nej | Svärm, Knut och Knyt (tvillingarna) |
| goblinspejare | CharacterArmature 62 | 24 + Gob_BowShoot | 4 941 | 0,98 | Nej | Goblinfamiljens skytt |
| gudlaug | CharacterArmature 62 | 24 | 4 695 | 1,71 | **Ja**, som `falkenerare.glb` (hjälte) | – |
| hellhound | AnimalArmature 51 | som brunbjörn | 2 071 | 1,20 (2,5 lång) | Nej | Eldhund; Skrattande låga i kapellet, djurfamilj |
| jatteratta | RatArmature 31 | Rat_Idle/Walk/Run/Attack/Death/Jump, Ratta_Hit | 4 004 | 0,34 (0,95 lång) | Nej | Kryptans smådjur, svärm, Gröt-Gudruns husdjur |
| jattespindel | SpiderArmature 29 | Idle_Loop, Walk/Run_Loop, Sword_Attack, Spell_Simple_Shoot, Hit_Chest, Death01 | 1 213 | 1,35 (2,9 bred) | Nej | Egen familj (spindlar), Snärjd-tema |
| kryptvaktare | CharacterArmature 62 | 24 | 4 751 | 2,16 | Nej | Blind väktare 2,2 m: elit i kryptan, Brom-alternativ |
| kultfanatiker | CharacterArmature 62 | 24 + KF_Cast/Chop/Death/Hit/Idle/Slash/Walk | 3 858 | 1,63 | Nej | Kultens folk (närstridare), har egna klipp |
| kultist | CharacterArmature 62 | 24 + Kult_Cast | 3 786 | 1,62 | **Ja**, `kultist.glb` (och `kapa.glb`) | – |
| magmin | CharacterArmature 62 | 24 | 2 349 | 1,00 | Nej | Eldväsen; Linsväktaren/Mässingsverket med glöd |
| ogre | CharacterArmature 62 | 24 | 2 578 | 2,80 | Nej (nu grund för trollen, se nedan) | **Trollfolket** |
| ragnvald | CharacterArmature 62 (King) | 24 | 7 199 | 1,92 | **Ja**, som `biskop.glb` | – |
| rovarhovding | CharacterArmature 62 | 24 + Rov_Chop/Chop2/Death/Hit/Idle/Interact/Slash/Walk | 5 187 | 1,89 | Nej | Pantlånaren Bolin, Gamle Ruskig, mänsklig boss |
| skelett | CharacterArmature 62 | 24 | 1 562 | 1,71 | **Ja**, `skelett.glb` (16 fiender) | – |
| somngangare | CharacterArmature 62 | 24 + Som_Idle/Walk | 4 499 | 1,69 | Nej | Vinterhuset (Sover-tema) eller kryptans gengångare |
| stirge | StirgeArmature 7 | Idle_Loop, Walk_Loop, Sword_Attack, Hit_Chest, Death01, Attached_Loop | 484 | 0,40 | Nej | Vinterbiet Surr (insekt, Attached_Loop = suger fast) |
| stratrovare | CharacterArmature 62 | 24 | 4 332 | 1,63 | Nej | Stråtrövare: Kopisten, mänskliga vandrare |
| svala | CharacterArmature 62 | 24 + Sva_Cast/Idle/Walk | 4 432 | 1,91 (stav) | **Ja**, som `haxa.glb` | – |
| tom_rustning | CharacterArmature 62 | 24 | 768 | 1,78 | **Ja**, som `rustning.glb` (del) | Mätaren (Mässingsverket) |
| torgny | CharacterArmature 62 | 24 | 4 444 | 1,74 | Nej | Mänsklig elit/hjälte; Verkmästare Ärg med tint |
| vakt | CharacterArmature 62 | 24 | 5 043 | 1,77 | Nej | Kuggknekten (rustad vakt), Kultens förman |
| varg | AnimalArmature 51 | som brunbjörn | 1 962 | 0,65 (1,3 lång) | Nej | Flockdjur, Benfolkets Flockbett med bentint |
| yrsa | CharacterArmature 62 | 24 | 4 148 | 1,71 | Nej | Smed med hammare: Mässingsverket (Brokks motpol) |

**Sammanfattning:** sju filer används redan (akolyt, gudlaug, kultist, ragnvald, skelett, svala, tom_rustning). 22 är
riggade, animerade och oanvända. Alla är under 7 500 trianglar. Människoriggen (62 ben) kan låna alla spelets
klipp av `torvald`. De mest användbara oanvända är **ogre** (trollen), **kryptvaktare** (stor elit), **kultfanatiker**
och **rovarhovding** (har egna strids-klipp), **jattespindel**, **stirge** och **darkmantle** (egna riggar med spelets
klippnamn redan) och de tre djuren.

## Trollen (ur ogre.blend, 2026-10-23)

Byggskript: scratchpad `blender-ut/skript/troll_bygg.py` och `troll_export.sh` (läser `ogre.blend`, sparar egna
kopior). Ändringar mot ogren: skalad till 2,2 m (1,3 × skelettet), stor knölig trollnäsa på `Head`, alla namn `Ogr_` →
`Troll_` (material och delar, så att `colors` och `hide` i spelets data kan peka på dem), ljusare neutral hud som går att tinta.

| Fil | Trianglar | Höjd | Storlek | Skillnad |
|---|---|---|---|---|
| `troll.glb` | 2 883 | 2,20 m | 959 KiB | Grundtrollet, gråbrun hud, trädstamsklubba (`Troll_Club`) |
| `troll_mossrygg.glb` | 3 183 | 2,20 m | 984 KiB | Mossgrön hud, mosstuvor på ryggen och axlarna (`Troll_MossBack`, `Troll_MossShoulder`) |
| `troll_grumse.glb` | 2 955 | 2,98 m med kronan | 966 KiB | Grå sten, stenklubba, isblå ögon, stenkrona med en tom infattning framtill (`Troll_Crown`) |

Klipp (30 fps): `Sword_Idle` 1,67 s, `Idle_Loop` 1,67, `Sword_Attack` 1,0, `Punch_Jab` 0,83, `Troll_Kick` 0,9,
`Spell_Simple_Shoot` 1,23 (Interact, till Trollmors sång), `Hit_Chest` 0,53, `Death01` 1,03, `Walk_Loop` 1,33, `Run_Loop` 0,77.
Ingen meshopt, ingen Draco, inga texturer (bara materialfärger). Fötterna står på 0 (kontrollerat med `kolla_glb.py`
i viloläget, Sword_Idle och Walk_Loop). Figuren tittar åt samma håll som `skelett.glb`.

Andra troll med spelets `tint`, `colors`, `hide` och `parts` (ingen egen fil behövs):
- **Grinig-Gunnar:** `troll.glb` med mörkare `tint`. Armarna i kors kräver en egen viloanimation (finns inte).
- **Klubb-Kalle:** `troll.glb`, `hide: ["Troll_Club"]`, `weapons: {"grip_r": "Maul"}` (trollet saknar grepp och får
  torvalds, som skelettet).
- **Gröt-Gudrun:** `troll.glb`, `hide: ["Troll_Club"]`. Slev och förkläde finns inte, så de behöver nya delar.
- **Brom:** `troll.glb` med `scale: 1.3` och en mörkare `tint`. Brospänne och lykta finns inte.
- **Trollmor Gråluva:** `troll.glb`, `hide: ["Troll_Club"]`, `colors: {"Troll_Skin": grå}`. Sjal och stickor finns inte.
- **Grumse:** egen fil (kronan med tom mitt). Spelets `crown` ger en taggig guldkrona utan hålet.

Återstår: inkoppling i rpg007 (kopiera till `assets/models/`, `visual` i enemies.json), Trollmors sjal, Gudruns
förkläde och slev, Broms lykta och armarna i kors för Gunnar.
