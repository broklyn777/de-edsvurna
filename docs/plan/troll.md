# Trollfolket (0.30.23, byggt utan Realm)

Underlag: `docs/ideer/claude-coola-fiender.md` §1. Modeller: Drakvalvets ogre gjord om i Blender (`troll.glb`,
`troll_mossrygg.glb`, `troll_grumse.glb`; skripten i huvudtrådens scratchpad, `docs/research/drakvalvet-monster.md`).

**Artregel – Trollhud** (`troll_hide`): en träff från en förmåga (inte grundanfallet) ger Svedd hud
(`troll_scorched`, `no_heal`): trollet läker inte förrän efter sin nästa tur. Frågan: *när* slår du med förmåga?

| Troll | Roll | Egenskap | Egen förmåga | Trofé |
|---|---|---|---|---|
| Mossrygg | vanlig | Mossa: helas 10 % i början av sin tur | Mosskast: skada + Snärjd 2 turer | Mosskappan (helas 6 %) |
| Grytmodern | vanlig | Grytans hunger: +10 % Attack när en hjälte helas (×3) | Kokande gryta: alla hjältar, 30 % Försvagad | Grytskärvan (samma mot fiendens helning) |
| Avundsjätten | vanlig | Avund: får samma buff som en hjälte | Avundens blick: Hånad på den med högst Attack | Den kluvna stenen (kopierar fiendens buff) |
| Stenkrossaren | vanlig | Klubban: dubbel skada mot den som Försvarar | Markskalv: skada + längst ned på tidslinjen | Krossarens klubba (+50 % mot Försvarar) |
| Brom, broarnas väktare | miniboss | Tull: slår den som skadade honom senast, +50 % mot den som Provocerar | Brotull: tar en Charge + skada | Brospännet (+40 % mot Provocerar) |
| Trollmor Gråluva | elit | Vaggvisa var tredje tur | Gråluvans vaggvisa: den som senast använde en förmåga somnar | Gråluvans sjal (var tredje handling somnar en fiende) |
| Bergakungen | boss | Resistent, Stenhjärta (−60 % skada när sällskapet upprepar samma sorts handling) | Bergets vrede: alla, 20 % Förstenad | Bergakungens kluvna krona |

Ny motor (`CombatSim`): `pick: last_attacker`, effekterna `drain_charge` och `if_target_cast`, villkoren
`source_used_ability` och `source_repeats_team_action`, auraflaggan `no_heal`. Tester: `tests/test_enemies_trolls.gd`.

**Mätt** (`tests/troll_balance.gd`, fyra hjältar på väntad nivå, fulla Charges): alla trollmöten vinns som kapellets,
men de varar längre (vanliga 14–15 turer mot kapellets 10, Bergakungen 78 mot biskopens 71) och sliter alltså mer över
en körning. Riktig balans först med en Realm i grottan.

**Kvar:** egen Realm (efter Lunden, samma sätt att lägga en Realm på kampanjkartan), kampanjkartans vinjett, ljud för vaggvisan.
**Delarna (2026-10-24):** `assets/models/troll_delar.glb` är en givarfil med trollets skelett och fem delar som hängs på med
`parts` (som `kapa.glb`): `Troll_Shawl` (sjal med luva, Gråluva), `Troll_Apron` + `Troll_ApronBand` (förkläde med sotfläckar
vid fållen, Grytmodern), `Troll_Lantern` (järnlykta i vänster hand, `emit` på `Troll_LanternGlow`, Brom) och `Troll_Boulder`
(sten i höger hand, till Kyrkkastaren när han finns i datan). Sjalen och förklädet har vikter från kroppen, lyktan och stenen
sitter på handlederna. Färger per troll med `colors` (`Troll_Shawl`, `Troll_Apron`, `Troll_ApronStain`, `Troll_ApronTie`,
`Troll_LanternIron`). Bilder: `docs/provspel/troll-delar/`.

**Namn** (VD 2026-10-23): allvarliga, inga skämtnamn. Utseendet farligt (stor påk, betar, framåtböjd).

## Roller (2026-10-24, grenen `fiender-roller`)

Underlag: `docs/provspel/provocera-matning.md` (alla troll hade samma kropp, ingen var snabb och skör). VD vill att
WoW-trion (tanken provocerar, helaren helar, de andra slår) ska fungera och att svårigheten kommer av *blandningen*:
vem provocerar man, vem fäller man först. Alla siffror är **VAL**, satta med botarna.

| Troll | Roll | Stats (H / A / I / D / S) förr → nu | Ändring |
|---|---|---|---|
| Stenkrossaren | tung slagare | 58 / 14 / 5 / 2 / 7 → 56 / 16,5 / 5 / 1,5 / 6 | slår hårdast, ska provoceras (Klubban straffar den som Försvarar) |
| Mossrygg | pansar | 60 / 12 / 6 / 2 / 7 → 58 / 10 / 6 / 3,5 / 5 | vill ha förmågor (som också stoppar Mossan) |
| Grytmodern | helare | 52 / 11 / 10 / 1,5 / 8 → 46 / 9 / 12 / 1 / 8 | ny förmåga **Grytans gröt** (`porridge_feed`): helar trollet med lägst liv (140 % Int, nedkylning 2) när någon är under 65 %; ett troll med Svedd hud kan inte helas |
| Avundsjätten | besvärjare | 56 / 12 / 8 / 2 / 8 → 54 / 11 / 13 / 1,5 / 9 | Avundens blick (förbi Provocera, mot den med högst Attack) 40 → 70 % skada |
| **Bortbytingen** (`changeling_troll`) | snabb och skör | ny: 30 / 15 / 6 / 0,5 / 13 → 22 / 13,5 / 6 / 0,5 / 13 (Moderns famn) | se nedan |

**Bortbytingen:** modellen `troll_bortbyting.glb` (skala 0,6). Grundanfallet **Bytingens klor** (`changeling_claw`) går förbi
Provocera och river den hjälte som har lägst liv (100 %). Egen förmåga **Bytingens skrik** (`changeling_wail`, nedkylning 4):
varje hjälte blir Hånad 1 tur med 30 % chans (en besvärjelse; förmågor går fortfarande, och de sveder Trollhud). Egenskaper:
Trollhud och **Smyget** (`changeling_slip`, undviker 25 % av anfallen, besvärjelser och indirekt skada träffar alltid).
Trofé **Stålet ur vaggan** (`cradle_steel`, vanlig, ett föremål ur folktron): när en fiende skadar någon annan i sällskapet
som har under 50 % liv slår bäraren tillbaka för 60 % (en gång per tur). Lärdom: "Stål i vaggan höll bytingarna borta
från barnen. {bärare} har lärt sig att vakta den som är svagast." **Moderns famn** (`mothers_embrace`, byggd på grenen
`strid-justering`): så länge ett större troll lever (mest maximalt liv i familjen) tar det hälften av varje anfall mot
honom; förmågor och indirekt skada träffar honom fullt. "Döda honom först" blir ett val: först trollet, en förmåga på
honom, eller dubbelt så många anfall. För att berget inte skulle bli svårare fick han 22 Health och 13,5 Attack (förr
30 / 15). Botarna (BALANS=grotta GROTTA_FYRA=1 GROTTA_KORT=1, MACRO/TUNED): djup 1 41/66 → 41/62 %, djup 3 32/36 → 33/41 %;
med hälften av all skada och 30 / 15 föll djup 3 till 7/20 %. Ingen elitvariant (inga troll har det än).

**Grupperna** (id:n behållna, två nya): varje vanlig grupp har minst två huvudroller (`tests/test_enemy_roles.gd`).

| id | Namn | Förr | Nu |
|---|---|---|---|
| `troll_1a` | Mossiga backen | Mossrygg ×2 | Mossrygg, Bortbytingen |
| `troll_1b` | Grytans eld | Grytmodern, Mossrygg | samma (helare + pansar) |
| `troll_1c` | Avundens snår | Avundsjätten, Stenkrossaren | samma |
| `troll_1d` | Klubban vid grytan | Stenkrossaren, Grytmodern | samma |
| `troll_1e` *ny* | Vaggan i snåret | – | Bortbytingen, Grytmodern |
| `troll_2b` | Kittelgropen | Grytmodern ×2, Stenkrossaren | Grytmodern, Stenkrossaren, Bortbytingen |
| `troll_2d` | Stenraset | Stenkrossaren ×2, Avundsjätten | Stenkrossaren, Avundsjätten, Bortbytingen |
| `troll_3a` | Hela byn i berget | Grytmodern, Stenkrossaren, Avundsjätten, Mossrygg | Mossrygg → Bortbytingen |
| `troll_3c` *ny* | Bytingarna | – | Bortbytingen ×2, Mossrygg, Grytmodern |
| `troll_3d` | Mossa och sten | Mossrygg ×2, Stenkrossaren, Avundsjätten | en Mossrygg → Bortbytingen |
| `troll_1` | Trollstigen | Mossrygg, Grytmodern, Stenkrossaren, Avundsjätten | Avundsjätten → Bortbytingen |
| `troll_2` | Bergets port | Stenkrossaren, Grytmodern, Avundsjätten, Mossrygg | Mossrygg → Bortbytingen |
| `troll_e3` | Vaggan (elit) | Gråluva, Grytmodern, Mossrygg | Gråluva, Bortbytingen, Grytmodern |

`troll_2a`, `troll_2c`, `troll_3b`, eliterna `troll_e1`, `troll_e2` och bossen är oförändrade (Stenkrossaren i bossmötet har
de nya siffrorna; Attack 18 gjorde Bergakungen för svår och sänktes till 16,5).

**Botarna** (`BALANS=grotta GROTTA_FYRA=1 GROTTA_KORT=1`, 100 körningar, MACRO / TUNED, se `docs/provspel/provocera-matning.md`):
Berget d1 46 / 64 → 41 / 66 %, d3 27 / 36 → 29 / 41 %. Per grupp (`spider_diag.gd`, en strid, fulla Charges) vinns allt till
100 %; bergets vanliga grupper kostar *mindre* liv än förr (tier 2 79–89 → 87–90 %), eftersom startmakrot slår fienden med
lägst liv och då fäller Bortbytingen först. Svårigheten flyttade till elit och boss genom nötningen (Bron 74 → 72 %).
