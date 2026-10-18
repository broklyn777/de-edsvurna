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
| Snabbhet | speed | Speed | I Siralim styr den också krit och undvikande; inte hos oss än. |
| Anfall | attack, `attack_ability` | Attack | |
| Förmåga | ability (`abilities`, `charges`) | Cast / Spell Gem | Siralim: upp till 3 Spell Gems per figur, 1 Charge per cast, Charges fylls först vid nästa Realm. Manuell cast = meny eller makro, automatisk = utlöst av trait. |
| Försvara | defend | Defend | Siralim: 35 % mindre skada **och** 50 % mer Defense. Vi har ännu inget Defense-värde. |
| Provocera | provoke | Provoke | Siralim: alla fiendens attacker och spells går mot hen, 35 % lägre Defense. Hos oss tills vidare: 30 % mer skada. |
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
| Charges | charges | Charges | Användningar per förmåga, räcker hela körningen. |
| Regelbrytare | convert_damage, parts | t.ex. Outcast No Longer | |
| Paladinen | `paladin` | spelaren (Siralim Mage) | Medveten avvikelse: Siralims spelare strider aldrig själv. |
| Ed | oath (`oath_options`) | Specialization (och dess Perks) | Hämndens ed ≈ Paladins Retribution. |
| Följeslagare | hero / companion | Creature | Namngivna personer, inte varelser man samlar. |
| Trofé | trophy | Trait Material (Masters) | Ger ett trait från ett besegrat monster; fyller den plats som Fusion har i Siralim. |
| Artefakt | artifact (`data/artifacts.json`, `equip_artifact`) | Artifact | En per hjälte, smids hos Smeden. Typen höjer en stat och avgör när förmågan i den slår till: svärd vid Anfall 25 %, stav vid Förmåga 25 %, sköld vid Försvara 50 %, hjälm vid Provocera 50 %, stövlar i början av turen 15 %. Automatiskt kast kostar inga Charges. |
| Svärd / Stav / Sköld / Hjälm / Stövlar | sword / staff / shield / helm / boots | Sword / Staff / Shield / Helmet / Boots | Stat: anfall / besvärjelser och helning / mindre skada / liv / snabbhet (Siralim: Attack / Intelligence / Defense / Health / Speed). |
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
| Kryptporten | gate (`start_screen`) | Teleportation Shrine | Välj Ed, följeslagare och trofé; starta körningen. |
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
| Potency | styrka i % av Intelligence (Small–Devastating) | `power` |
| Additional damage | går förbi Defense och minskningar | – |
| Top / Bottom of Timeline | flytta i turordningen | – |
| Calm Mode | lägre Action Limits | `TURN_LIMIT` = 5 |
| Resistant | boss tar halv effekt av debuffar | – |
| Retribution | Paladins kärna: slå tillbaka vid skada | Hämndens ed |
| Perk, Anointment | förmån i en Specialization; lånad perk | – |
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
| Hoppa över tur | skip | skip turn |
| Den som matchade | that_unit | that creature |
| Förklaring | macro log | – (vårt tillägg) |
