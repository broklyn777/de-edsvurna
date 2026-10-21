# Ordlista – De edsvurna ↔ Siralim Ultimate

Tre lager:

- **Spelet** (det spelaren ser) är på svenska.
- **Koden och datan** använder engelska, helst Siralims egna ord, så att det går att söka på dem och
  hitta både vår kod och originalets beskrivningar.
- **Research** skriver Siralims engelska termer, gärna med det svenska ordet inom parentes.

Våra egna namn (Domens kall, Benfursten, Brokk …) är svenska överallt.

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
| Charges | charges | Charges | Användningar per förmåga, räcker hela körningen (fylls bara vid en ny körning). Siralim-nivå: starkare förmågor 5, medel 6–8 (`docs/research/siralim.md` §3b). Tillbaka bara via kall, troféer och artefakter (t.ex. Vila upp). |
| Regelbrytare | convert_damage, parts | t.ex. Outcast No Longer | |
| Paladinen | `paladin` | spelaren (Siralim Mage) | Medveten avvikelse: Siralims spelare strider aldrig själv. |
| Kall (hette Ed före 0.18) | oath (`data/oaths.json`, `Profile.oath`) | Specialization | En kärna som alltid verkar plus köpta perks. Domens kall ≈ Paladin (Retribution), Gryningens kall ≈ Cleric (Luminesce), Väktarens kall ≈ Siegemaster (Thorns). Bärs av Paladinen och slutar verka när hen stupar (vår avvikelse). |
| Perk | perk (trait med `"oath"` och `"perk": true`) | Perk | Köps för silver vid Kallets altare, ett steg per perk (Siralim har ranks). Återställs gratis. |
| Gäller hela sällskapet | `"scope": "party"`, `traits_of()` | Specialization | Egenskapen verkar som om varje levande allierad bar den. |
| Utförare | `actor`: event_unit / event_target / event_source | – | Vem i händelsen som utför effekten. |
| När striden börjar | trigger `battle_start` | start of battle | Efter Siralims ordning: buffar ges innan första turen. |
| Får tillbaka en Charge | effekten `restore_charge`, händelsen `charge_restored` | restore Charges | |
| Följeslagare | hero / companion | Creature | Namngivna personer, inte varelser man samlar. |
| Trofé | trophy | Trait Material (Masters) | Ger ett trait från ett besegrat monster; fyller den plats som Fusion har i Siralim. |
| Artefakt | artifact (`data/artifacts.json`, `equip_artifact`) | Artifact | En per hjälte, smids hos Smeden. Typen höjer en stat och avgör när förmågan i den slår till: svärd vid Anfall 25 %, stav vid Förmåga 25 %, sköld vid Försvara 50 %, hjälm vid Provocera 50 %, stövlar i början av turen 15 %. Automatiskt kast kostar inga Charges. Nivå 1–10 hos Smeden (0.20); nivåerna öppnar platser. |
| Artefaktnivå | `level`, `Forge.LEVEL_COST`, `Profile.level_artifact()` | Artifact Level | 1–10 för silver; +10 % på allt i artefakten per nivå. Platser: Stat 2, 5, 9, Trick 3, 7, Nether 10. |
| Bärnsten | amber (`data/materials.json`) | Amber (Stat Material) | Tio färger, en eller två stats. 5 per Stat-plats. Förstörs när den tas ut. |
| Trick | trick (`materials.json` "tricks") | Trick Material | Brynsten (Whetstone), Taggsten (Jagged Rock), Rustningsskrot (Armor Scrap), Hal sten (Slippery Stone), Arkant sigill (Arcane Sigil), Styrkans skiffer (Slate of …), Sårbarhetens kuriosa (Curio of …). |
| Nether Stone | stone (`Forge.roll_stone`) | Nether Stone | Slumpad sten med 1–4 egenskaper (Vanlig, Magisk, Sällsynt, Legendarisk) och ett sällsynthetstal. Överlever när den tas ut. |
| Status | aura (`data/auras.json`) | Buff / Debuff | Varar i ägarens turer; ikon under livmätaren, text i Inspect. Se `docs/formler.md` §5. |
| Smidig, Arkan, Bärsärk, Defensiv, Immun, Livstörst, Läkning, Beskyddad, Pånyttfödd, Vildsint, Skyddsskal, Utmanande | agile, arcane, berserk, defensive, immune, leeching, mending, protected, rebirth, savage, shelled, taunting | Agile, Arcane, Berserk, Defensive, Immune, Leeching, Mending, Protected, Rebirth, Savage, Shelled, Taunting | Buffar (0.22). |
| Blöder, Fördärvad, Förblindad, Förvirrad, Frusen, Förgiftad, Hånad, Sover, Snärjd, Förstenad | bleeding, blighted, blind, confused, frozen, poisoned, scorned, sleeping, snared, stone | Bleeding, Blighted, Blind, Confused, Frozen, Poisoned, Scorned, Sleeping, Snared, Stone | Debuffar (0.22). |
| Dispel, Rening | dispel, purge | Dispel, Cleanse | Dispel tar bort alla statusar på målet; Rening bara debuffar. |
| Överst / sist på tidslinjen | to_top, to_bottom | Top / Bottom of Timeline | Den som stod överst skickas ned; bossar flyttas ett steg. |
| Lärjunge | disciple (`realms.json` "disciples") | Creature (rekrytering) | Följeslagare som befrias ur ett fånge-rum och ansluter på låg nivå. |
| Fånge-ruta | prisoner | – (vårt tema för rekrytering) | Ruta i grottan med en lärjunge; den första är tidig och oftast obevakad. |
| Värdshuset | inn (`inn_screen`) | Menagerie | Där följeslagarna bor; välj sällskap, de som stannar behåller nivån. |
| Borgen | keep (`base_screen`, `KeepArt`, `data/keep.json`) | Castle | Basen som en planritning i tusch att gå runt i (0.24; 3D-gård i 0.23). |
| Paladinens namn | `Profile.hero_name`, `{namn}` (`Dialog.fill`), `NameEntry` | player name | Väljs när en ny profil börjar, skrivs om hos Broder Alrik; "Paladinen" om det lämnas tomt (0.24.2). |
| Samtal, dialogruta | `Dialog`, `DialogBox`, `data/dialog.json` | dialogue box | Personen hälsar och erbjuder tjänsterna som val; sist "Ingenting just nu". |
| Vardagsreplik | idle (`Dialog.idle_line`) | – | Det personen säger när inget uppdrag gäller; nyheter (ny lärjunge, besegrad boss) först. |
| Replik under nedstigningen | bark (`Dialog.bark`, `Run.pending_bark`) | – | En rad från sällskapet efter en svår strid, vid lägerelden m.m.; vårt Baldur's Gate-drag. |
| Berättarruta | `StoryBox.narrator`, talaren `"narrator"` (intro.json, dialog.json "narrator") | narrator text | 0.25: en kursiv rad inom parentes på svart när tid går eller platsen byts. |
| Hjälpruta | `Help`, `HelpBox`, `data/help.json` | help box ("?") | 0.25: ett grönt ? och 2–3 stycken första gången man möter ett system; en gång per profil (`Profile.help_seen`). |
| Handboken | `handbook_screen`, Broder Alriks val "Läs i handboken" | – | 0.25: alla hjälprutor att läsa igen. |
| Nedstigning | descent (`Profile.descents`) | – | En påbörjad körning i en Realm. Alva räddas på den andra i kryptan; den första har svagare fiender. |
| Hedda, Broder Alrik, Stig, Mor Elin, Sven | hedda, alrik, stig, elin, sven | (Sabon m.fl.) | Smeden, bibliotekarien, vapenmästaren, värdshusvärden och portvakten (namnen är förslag, 0.24). |
| Introduktionen | intro (`data/intro.json`, `Intro`) | Tutorial | Småuppdrag i borgen för en ny profil. |
| Imma, Mäster Gorm | imma, gorm | – | Paladinens barndomsvän (första följeslagaren) och borgens präst. |
| Uträkning | `calc`, `DamageExplain` | – (vårt tillägg) | Hela vägen till en siffra: stat, variation, Defense, modifierare, krit, barriär. Tryck på en siffra i striden. |
| Skadelogg | `DamageLog` | – (vårt tillägg) | Alla skador och helningar i striden, nyast överst; en rad öppnar uträkningen. |
| Ge upp | forfeit (`CombatSim.forfeit()`) | Forfeit | Avslutar striden som förlust; körningen är förlorad och Realmen börjar om från våning 1. Det som redan är vunnet behålls. |
| Fynd | finds (`Forge.roll_finds`) | Loot | Material och stenar från rummen; trick och stenar bara på det djupaste djupet man nått. |
| Svärd / Stav / Sköld / Hjälm / Stövlar | sword / staff / shield / helm / boots | Sword / Staff / Shield / Helmet / Boots | Stat: +5 % Attack / +5 % Intelligence / +10 Defense / +5 % Health / +1 Speed (som Siralim). |
| Automatiskt kast | `cast`-effekt, action `artifact`, händelsen `acted` | automatic cast | |
| Samling | collection | Codex / Bestiary | Troféer man någonsin hittat. |
| Sällskap | party | Party | |

## Körningen

| I spelet | Kod / data | Siralim Ultimate | Kommentar |
|---|---|---|---|
| Körning | run, `RunState` | – | Siralim har realms och djup i stället. |
| Våning | floor, `FLOORS`, `stat_mult` i encounters.json | – (en del av en Realm) | Våning 2 och 3 har starkare fiender (×1,08, ×1,10). |
| Realm | realm, `data/realms.json`, `RunState.set_realm()`, `Profile.realm` | Realm | Väljs på kampanjkartan: Kryptan eller Det fördärvade kapellet. |
| Nivå | level, `Profile.heroes[id].level`, `HeroStats` | Level | +30 % av basvärdet per nivå, inget tak. Fiendernas nivå följer djup och våning. |
| Erfarenhet | xp, `HeroStats.battle_xp()`, `add_xp()` | Experience | Per vunnen strid efter rumstyp och djup²; hela sällskapet får den. 5 · L² + 10 till nästa nivå. |
| Personlighet | personality, `data/personalities.json` | Personality | 20 sorter: en stat växer 40 %, en annan 20 %. Byts i Biblioteket (Personality Tome) mot silver. |
| Hjältebladet | `hero_screen` | varelsens skärm | Nivå, erfarenhet, fiendernas nivå på valt djup, stats per källa, vad de betyder, egenskaper, förmågor, artefakt och historik. |
| Instabilitet | `Profile.instability`, `RunState.instability`, `roll_rules()` | Realm Instability | 0–3 på kampanjkartan: n synliga och n dolda våningsregler, mer silver och troféchans. |
| Våningsregel | `data/floor_rules.json`, `CombatSim.rules`, händelsen `rule` | Realm Property | T.ex. De döda vaknar (Resurrect on Death), Förseglade ord (Gems Sealed After Casting), Speglande ben (Reflect Damage Taken), Kaosvind (Stats are Swapped). |
| Dold regel | `rules_hidden`, `rules_revealed` | hidden Realm Property | Syns först när den slår till. |
| Elitvariant | `elite` i enemies.json, `CombatUnit.elite`, `CombatSim.elite_chance()` | – (sällsynta varelser; Fused/Nether-varianter) | Benkapten, Benjägare, Gravabbot, Gravfogde, Askbärare, Ockultist, Banshee, Edsbrytare, Häxmästarinna, Självplågare. Egen trofé. |
| Bosstrofé efter tre segrar | `Profile.boss_wins`, `RunState.BOSS_WINS_FOR_TROPHY` | Master (Trait Material efter tre segrar) | Räknaren syns i Biblioteket och i Inspect. |
| Tystad | silenced (aura med `silence`), `is_silenced`, makrovillkoret "är tystad" | Silenced | Inga förmågor; fiender bara anfaller; artefakter kastar inte. |
| Sårbar | vulnerable | Vulnerable | +50 % skada i 2 turer. |
| Försvagad | weak (aura `damage_mult` 0,5) | Weak | −50 % skada i 2 turer. |
| Immun | `immune`-händelse, `is_immune`, makrovillkoren "är immun"/"kan skadas" | (Myrtle, Nether Boss) | Den fallne biskopen så länge en Kultist lever; Biskopens mitra. |
| Kultist, Gast, Fallen riddare, Häxa, Botgörare, Den fallne biskopen | cultist, wraith, fallen_knight, witch, penitent, fallen_bishop | – (egna) | Kapellets fiender; egenskaper Skyddande bön, Eterisk, Motstöt, Häxans illvilja, Bödelns märke, Kultens sköld. |
| Vanlig / elit / boss-trofé | `rarity`: common, elite, boss | – (Siralims vanliga/Nether/boss-traits) | Pålitlig byggdel / specialiserad / regeländring med kostnad. |
| Djup | depth, `Profile.depth`/`best_depth`, `CombatSim.depth_mult` | Realm Depth | Väljs på kampanjkartan. Fiender +8 % stats per djup (utom Speed), silver +25 %, troféchans +15 procentenheter. Nästa djup öppnas när det föregående är klarat. |
| Fiendens egenskap | `traits` i enemies.json (`"enemy": true` i traits.json) | creature trait | Alla fiender har minst en, som makrona måste svara på. |
| Benrustning, Jägarblick, Gravpakt, Taggig utmaning, Glödhetta | bone_armor, deadeye, grave_pact, warden_thorns, ember_heat | – (egna) | Skelettkrigare, bågskytt, Gravpräst, Gravväktare, Glödskelett. |
| Benspringare, Kistbärare, Mögelskelett, Skramlaren | bone_runner, coffin_bearer, mold_skeleton, rattler | – (egna) | Kryptans nya vanliga fiender (0.27); egenskaper Flockbett, Sista tjänsten, Sporer, Skrammel. Elitvarianter Benvarg, Likbärare, Sporfursten, Benklappret. |
| Benkolossen, Gravväckaren, Gravdimman, Benskrivaren | bone_colossus, grave_caller, grave_mist, bone_scribe (`"rank": "elite"`) | – (egna) | Kryptans elitfiender (0.27): Växande vrede + Benmur, Kallelse, Dimslöja, Antecknat. |
| Klockaren | bell_ringer (`"rank": "miniboss"`) | – (egen) | Kryptans miniboss (0.27): Klockslaget flyttar hela Benfolket överst var tredje tur. |
| Elitgrupp | `elite_group` i encounters.json, `elite_pools` i realms.json | – (vårt val) | En grupp med en elitfiende i rollen; ingen påtvingad elitvariant. Första våningens elit i kryptan är Kolossens vakt. |
| Familj, Benfolket | `family` i enemies.json, `CombatSim.family_count()` | Race (Undead …) | Ingen gemensam egenskap, som i Siralim: medlemmarnas egna egenskaper räknar familjen. |
| Motdrag | `counter` i enemies.json, `CombatSim.counter_for()`, `"counter": true` i traits.json | counter-trait (Satyr Guardian …) | Högst ett per grupp, bara i elitgrupper och bossmöten, från ett visst djup. Kryptan: Sista klangen, Dimmans tyngd, Sista vaktens ilska. |
| Dimmig | dulled (`int_mult`) | – (Dragon Revenants sänkning) | −20 % Intelligence i 2 turer. |
| Resistent | resistant, `CombatUnit.resistant` | Resistant | Bara statusarna med en Resistant-version verkar svagare på bossen (Blöder, Frusen, Tystad, Hånad, Sover, Snärjd, Förstenad); andra debuffar verkar fullt. |
| Odödlig vrede, Dödsdom | lich_undying_wrath (`once_per_battle`), lich_wrath, lich_doom | – (bossfas) | Benfursten under 50 % liv. |
| Brinner | burning (`dot_stat`, `dot_pct`) | Burning | 30 % av källans Intelligence per tur, som i Siralim. |
| Granska (håll fingret) | `_show_inspect` i battle.gd | Inspect | Visar stats och egenskaper, kostar ingen tur. |
| Lägret | camp | – (stunden mellan strider i en Realm) | Trofévalet efter varje våning. |
| Basen | base (`base_screen`) | Castle | Mellan körningarna. Förlust och klarad krypta leder hit. |
| Kampanjkartan | `campaign_screen`, `realms.json` "map" | Teleportation Shrine (och Siralims karta över Realms) | Landet med Realms som områden; ersätter Kryptporten (0.18). Fördärvets front viker för varje klarat djup. |
| Förberedelser | `start_screen` | – | Sällskap och trofé att ta med (förr Kryptporten). |
| Grottan | `room_map_screen`, `Grotto` | Realm (utforskningen) | Våningen som ett rutnät 8×8 med dimma (0.27); ersätter rumskartan. |
| Dimma | `RunState.visited` | – (VAL, strängare än originalets synvidd) | Bara besökta rutor syns; målet syns alltid. |
| Fiendegrupp | `kind` battle/elite, `encounter` | Enemy group | Synlig grupp på en ruta; kliver man på den syns ett kort (ANFALL/BACKA). |
| Spärr | `Grotto.blocked`, `RunState.seen` | – (Dungelot) | En sedd grupp spärrar de obesökta rutorna intill sig tills den är besegrad. |
| Trappa | `kind` stairs | – | Första våningens mål; låst tills questen är klar. |
| Quest-föremål | `kind` item, Samla | Quest item | Bevakat föremål som questen Samla kräver. |
| Strid, Elit, Skattkammare, Helgedom, Lägereld, Portal, Våningens slut | battle, elite, treasure, shrine, campfire, portal, end | strider, Nemesis, kistor, Pandemonium Shrine, (liv efter strid), Otherworld Portal, boss | Rumstyperna. Lägereld fyller 1 Charge per förmåga. |
| Realm Quest | `RunState.quest`, `roll_quest()`, `Profile.quests_done` | Realm Quest | Jakt (Nemesis), Rensa (2 elitstrider), Rening (3 helgedomar). Silver och en perk-poäng per ny Realm och djup. |
| Nemesis | `nemesis` i rummet, `CombatUnit.nemesis` | Nemesis | En namngiven elit på ett rum (questen Jakt). |
| Sparad körning | `user://slot<n>/run.cfg`, `RunState.save()` | sparning | Efter varje rum; spelet fortsätter där när profilen väljs. |
| Profil (sparplats) | slot, `SaveSlots`, `Run.choose_slot()` | Save slot | Tre profiler med egen borg, hjältar, makron och körning. Radering kräver bekräftelse. |
| Kallets altare | altar (`altar_screen`, `Profile.buy_perk`, `reset_perks`) | Enchanted Wardrobe | Välj kall och köp perks för silver; återställ gratis. |
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
| Retribution | Paladins kärna: slå tillbaka vid skada | Domens kall |
| Perk | förmån i en Specialization | perk vid Kallets altare |
| Perk rank | perkens nivå (Siralim 1–50) | perk-nivå, `ranks` i oaths.json: 2–3 på rena siffror, 1 på regelbrytare; en post per nivå i listan |
| Anointment | lånad perk från en annan Specialization efter en False God | lånad perk, `Profile.anoint()`: en plats när en boss (Benfursten) är besegrad, kostar poäng ur kallets pott |
| Perk Points | poäng att lägga i perks, från Realm Quests | perk-poäng, `Profile.perk_points()`: 2 från start, +1 per klarad quest (ny Realm och djup), per kall; äldre profiler behåller sina (`bonus_points`) |
| Enchanted Wardrobe | byt Specialization och perks | Kallets altare |
| Trait Slot, Nether Stone | Artifactens trait-plats; sena trait-platser | – |
| Master | rasmästare med unikt trait | – |
| Realm Quest, Fortune | uppdrag och belöning i en Realm | – |
| Nether Boss, False God | bossar med regelbrytande traits | Benfursten |
| Minion | staplar som gör Indirect Damage | – |
| History | händelselista | – |
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
