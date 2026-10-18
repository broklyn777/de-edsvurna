# Ordlista – De edsvurna ↔ Siralim Ultimate

Tre lager:

- **Spelet** (det spelaren ser) är på svenska.
- **Koden och datan** använder engelska, helst Siralims egna ord, så att det går att söka på dem och
  hitta både vår kod och originalets beskrivningar.
- **Research** skriver Siralims engelska termer, gärna med det svenska ordet inom parentes.

Våra egna namn (Hämndens ed, Benfursten, Brokk …) är svenska överallt.

## Strid

| I spelet | Kod / data | Siralim Ultimate | Kommentar |
|---|---|---|---|
| Strid | battle, `CombatSim` | battle | |
| (ingen runda) | `order`, `upcoming()` | Timeline | Som i Siralim: Speed avgör startplatsen, den som agerat läggs sist och kön roterar. |
| Tur | turn | turn | |
| Tidslinje | timeline, `upcoming()` | Timeline | |
| Liv / Attack / Intelligence / Defense / Speed | `stats` i data: health, attack, intelligence, defense, speed | Health / Attack / Intelligence / Defense / Speed | Siralims fem stats (0.13). Spelets text använder de engelska namnen, som i originalet. Stats kan inte sjunka under 20 % av startvärdet. |
| Skadeformel | `attack_damage`, `spell_damage`, `indirect_damage` | Combat-formlerna | Bekräftade: Attack = (max(Atk − Def, 0) + 1 % Atk) × mod; Spell = max(Potency − Def, 0) × mod, Potency = Int × nivåns procent; Indirect = skada × mod − 20 % Def. `power` i förmågorna är modifieraren. **Vårt val:** ±10 % spridning. |
| Nivå (spell) | `tier`: small … devastating, `SPELL_TIERS` | Small / Moderate / Large / Massive / Devastating | Potency 90–150 % av Int, ignorerar 0–40 % av Defense. |
| Modifierare | `combine_mods` | percentage modifiers | Bekräftat: ökningar adderas, minskningar multipliceras, varje minskning stannar vid 80 %. |
| Snabbhet | speed | Speed | Startplats på tidslinjen, krit och undvikande. **Vårt val** (formeln är inte publicerad): krit-chans = egen chans + 10 procentenheter per fördubbling av fartkvoten (högst 50 %), krit-skada +75 % + 125 % · log₃(kvot) (minst +50 %), undvikande 10 % per fördubbling när målet är snabbare (högst 30 %). Bara attacker kan bli kritiska eller undvikas (Troligt i Siralim). |
| Undvek | dodge (händelse) | dodge | |
| Barriär | barrier (`CombatUnit.barrier`, auran `barrier`) | Barrier | Tar skada före livet. Den starkaste gäller, de staplas inte. Träffar som Barriären tar sätter inte igång egenskaper. Vårt val: högst max liv. |
| Tillägg | `additional_from_stat` | Additional damage | Går förbi Defense och minskningar. |
| Anfall | attack, `attack_ability` | Attack | |
| Förmåga | ability (`abilities`, `charges`) | Cast / Spell Gem | Siralim: upp till 3 Spell Gems per figur, 1 Charge per cast, Charges fylls först vid nästa Realm. Manuell cast = meny eller makro, automatisk = utlöst av trait. |
| Försvara | defend | Defend | Som Siralim: 35 % mindre skada och 50 % mer Defense (`defense_mult`). |
| Provocera | provoke | Provoke | Som Siralim: fiendens enkelmål går mot hen, 35 % lägre Defense. |
| Avsikt | intent | – | Fiendens nästa handling visas. Finns inte i Siralim. |
| Skadetyp: anfall / besvärjelse / indirekt | kind: attack / spell / indirect | Attack / Spell / Indirect Damage | |
| Skola: fysisk, helig, eld, skugga, natur | school | – | Siralim har klasser i stället för skolor. |
| Kritisk träff | crit | critical damage | |
| Följdanfall | follow-up (trait damage) | "attacks" från traits | |
| Gräns per tur | `TURN_LIMIT`, `_within_limit` | Action Limits (15 per tur; Calm Mode 5) | Vi har 5, som Calm Mode. |
| Väcka (återuppliva) | revive | resurrect | |
| Auto | `auto` | – | Siralim kräver ett tryck per tur. |

## Bygget

| I spelet | Kod / data | Siralim Ultimate | Kommentar |
|---|---|---|---|
| Egenskap | trait | Trait | Samma idé: händelse → effekt. |
| Utlöses / slår till | trigger, `trait`-händelse | triggers | |
| Kedja | chain, `_trait_depth` | – | |
| Glöd (egenskapsstaplar) / förlösning | stack / release | – | Vår egen mekanik (kallades charge förut). Inte samma som Charges. |
| Charges | charges | Charges | Användningar per förmåga, räcker hela körningen (fylls bara vid en ny körning). Siralim-nivå: starkare förmågor 5, medel 6–8 (`docs/research/siralim.md` §3b). Tillbaka bara via Eder, troféer och artefakter (t.ex. Vila upp). |
| Regelbrytare | convert_damage, parts | t.ex. Outcast No Longer | |
| Paladinen | `paladin` | spelaren (Siralim Mage) | Medveten avvikelse: Siralims spelare strider aldrig själv. |
| Ed | oath (`data/oaths.json`, `Profile.oath`) | Specialization | En kärna som alltid verkar plus köpta perks. Hämndens ed ≈ Paladin (Retribution), Gryningens ed ≈ Cleric (Luminesce), Väktarens ed ≈ Siegemaster (Thorns). Bärs av Paladinen och slutar verka när hen stupar (vår avvikelse). |
| Perk | perk (trait med `"oath"` och `"perk": true`) | Perk | Köps för silver vid Edsaltaret, ett steg per perk (Siralim har ranks). Återställs gratis. |
| Gäller hela sällskapet | `"scope": "party"`, `traits_of()` | Specialization | Egenskapen verkar som om varje levande allierad bar den. |
| Utförare | `actor`: event_unit / event_target / event_source | – | Vem i händelsen som utför effekten. |
| När striden börjar | trigger `battle_start` | start of battle | Efter Siralims ordning: buffar ges innan första turen. |
| Får tillbaka en Charge | effekten `restore_charge`, händelsen `charge_restored` | restore Charges | |
| Följeslagare | hero / companion | Creature | Namngivna personer, inte varelser man samlar. |
| Trofé | trophy | Trait Material (Masters) | Ger ett trait från ett besegrat monster; fyller den plats som Fusion har i Siralim. |
| Artefakt | artifact (`data/artifacts.json`, `equip_artifact`) | Artifact | En per hjälte, smids hos Smeden. Typen höjer en stat och avgör när förmågan i den slår till: svärd vid Anfall 25 %, stav vid Förmåga 25 %, sköld vid Försvara 50 %, hjälm vid Provocera 50 %, stövlar i början av turen 15 %. Automatiskt kast kostar inga Charges. |
| Svärd / Stav / Sköld / Hjälm / Stövlar | sword / staff / shield / helm / boots | Sword / Staff / Shield / Helmet / Boots | Stat: +5 % Attack / +5 % Intelligence / +10 Defense / +5 % Health / +1 Speed (som Siralim). |
| Automatiskt kast | `cast`-effekt, action `artifact`, händelsen `acted` | automatic cast | |
| Samling | collection | Codex / Bestiary | Troféer man någonsin hittat. |
| Sällskap | party | Party | |

## Körningen

| I spelet | Kod / data | Siralim Ultimate | Kommentar |
|---|---|---|---|
| Körning | run, `RunState` | – | Siralim har realms och djup i stället. |
| Våning | floor, `FLOORS` | Realm Depth | |
| Lägret | camp | – (stunden mellan strider i en Realm) | Trofévalet efter varje våning. |
| Basen | base (`base_screen`) | Castle | Mellan körningarna. Förlust och klarad krypta leder hit. |
| Kryptporten | gate (`start_screen`) | Teleportation Shrine | Välj följeslagare och trofé; starta körningen. |
| Edsaltaret | altar (`altar_screen`, `Profile.buy_perk`, `reset_perks`) | Enchanted Wardrobe | Välj Ed och köp perks för silver; återställ gratis. |
| Övningsgården | practice (`RunState.practice`) | Arena | Strid mot valfritt möte utan risk; makrologgen finns kvar efteråt. |
| Smeden | smith (`Profile.forge`) | Blacksmith | Smida artefakt (100 silver) eller byta förmåga (40). |
| Biblioteket | library | Codex / Bestiary | Samlingen av troféer. |
| Silver | silver (`Profile.silver`) | Brimstone m.fl. | Enda resursen. 25/35/50 per vunnen strid på våning 1/2/3. |
| Profil | `Profile` | – | Det som sparas mellan körningar (`user://progress.cfg`). |
| Kvitto | receipt | – | Vårt tillägg. Battle History är en händelselista utan förklaringar. |

## Fler Siralim-termer

| Siralim Ultimate | Betydelse | Hos oss |
|---|---|---|
| Charges | användningar per Spell Gem | laddningar på förmågor (planerat) |
| Ethereal Spell Gem | tillfällig besvärjelse under striden | – |
| Potency | styrka i % av Intelligence (Small–Devastating) | `tier` (`SPELL_TIERS`); `power` är modifieraren |
| Additional damage | går förbi Defense och minskningar | `additional_from_stat` (Bästa försvaret) |
| Top / Bottom of Timeline | flytta i turordningen | – |
| Calm Mode | lägre Action Limits | `TURN_LIMIT` = 5 |
| Resistant | boss tar halv effekt av debuffar | – |
| Retribution | Paladins kärna: slå tillbaka vid skada | Hämndens ed |
| Perk, Anointment | förmån i en Specialization; lånad perk | perk vid Edsaltaret; Anointments finns inte |
| Enchanted Wardrobe | byt Specialization och perks | Edsaltaret |
| Trait Slot, Nether Stone | Artifactens trait-plats; sena trait-platser | – |
| Master | rasmästare med unikt trait | – |
| Realm, Realm Depth, Realm Quest, Realm Instability, Fortune | utflykter och svårighet | körning, våning |
| Nether Boss, False God | bossar med regelbrytande traits | Benfursten |
| Minion | staplar som gör Indirect Damage | – |
| Inspect, History | gratis titt på fienden; händelselista | – |
| Default action, Turbo, Strategy | standardhandling, håll Q/E | Auto |

Källa: `docs/research/siralim.md`.

## Makron (se docs/plan/0.11-makron.md och docs/research/siralim.md §9)

| I spelet | Kod / data | Siralim Ultimate |
|---|---|---|
| Makro | macro | Macro |
| Rad | line | line |
| Om denna hjälte / någon allierad / någon fiende / allierad N / alla allierade | subject: self / any_ally / any_enemy / ally_n / all_allies | If this creature / If any ally / If any enemy / If ally (N) / If ally (all) |
| Villkor | condition | condition |
| Pröva nästa rad | test_next_line | test next line |
| Bär / bär inte (artefakt) | has_artifact / lacks_artifact | – (vårt tillägg) |
| Har högst Speed / lägst eller högst Defense / högst Attack | highest_speed / lowest_defense / highest_defense / highest_attack | has the highest Speed / has the lowest Defense (Siralim 3) |
| Hoppa över tur | skip | skip turn |
| Den som matchade | that_unit | that creature |
| Förklaring | macro log | – (vårt tillägg) |
