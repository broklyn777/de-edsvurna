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

**Kvar:** egen Realm (efter Lunden, samma sätt att lägga en Realm på kampanjkartan), kampanjkartans vinjett, Grytmoderns
förkläde, Gråluvans sjal och Broms lykta som delar, ljud för vaggvisan.

**Namn** (VD 2026-10-23): allvarliga, inga skämtnamn. Utseendet farligt (stor påk, betar, framåtböjd).
