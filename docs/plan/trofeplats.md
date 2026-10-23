# Troféplatsen (grenen trofeplats, 2026-10-22)

Siralims Artifact Trait Slot (Tier 15 av 50 i originalet): artefakten får en plats för en egenskap till. Hos oss tar platsen
en **trofé ur samlingen**, så att varje hjälte till slut har tre egenskaper: egen, buren trofé och artefaktens trofé.
Underlag: `docs/ideer/chat-egenskaper-kombinationer.md` (ChatGPT:s jobb H, "Andra trofé-platsen").

## Regler

- Öppnas på artefaktnivå **6** (`Forge.TROPHY_LEVEL`, VAL: Tier 15 av 50 ≈ nivå 3 av 10, men vi lägger den efter Stat 2
  så att den kostar något; nivå 2–6 kostar 60 + 80 + 110 + 140 + 180 = 570 silver plus smidet 160).
- Trofén **förstörs inte** när den tas ut; den ligger kvar i samlingen (som Nether Stones, till skillnad från bärnsten och trick).
- **En plats åt gången**, som `worn`: sätts trofén i en artefakt tas den av den som bar den och ur en annan artefakt; att bära
  den tar den ur artefakten (`Profile.set_artifact_trophy`, `_free_trophy`, `wear`). Därmed kan en hjälte aldrig ha samma
  egenskap två gånger (Siralim: "samma egenskap räknas inte två gånger"). Striden lägger dessutom aldrig till en egenskap
  hjälten redan har (`CombatSim.equip_artifact`), och `RunState.equip` vägrar en trofé som sitter i en artefakt.
- Striden: `Forge.effect_traits` ger trofén i `trait_ids` när platsen är öppen, samma väg som en Nether Stones troféegenskap.
- **Byts hos Smeden** (VAL, det enklaste): lägret visar artefaktens trofé på hjältens kort men byter bara den burna.

## Var den syns

- Smeden, fliken ARTEFAKT: platsen TROFÉ efter Nether; panelen visar samlingens troféer (de som ingen har först, "Hos X nu"
  annars), NU/VALT och "X tappar den". `--forge-demo --smith --smith-hero=brokk --smith-slot=trophy:0 --smith-pick=mold_jaw`.
- Hjältebladet: trofén bland egenskaperna med etiketten ARTEFAKTENS TROFÉ, och raden "Troféplats" i artefaktens lista.
- Inspect i striden: egenskapen står bland enhetens egenskaper som de andra.

## Tak

Siralim 2.0: enskild skadereduktion högst 80 %, stats ändras högst 15 gånger per tur. Vi har redan:
`REDUCTION_CAP` 0,2 per faktor (= 80 %), stats högst ×3 av startvärdet (`_raise_stat`) och egenskapernas `max_times`,
kedjor högst 4 steg, `TURN_PROC_LIMIT` 60 och `TURN_LIMIT`. Botarna visade ingen loop med två troféer, så inget nytt tak byggdes.

## combo i traits.json

Varje trofé har `"combo": {"needs", "creates", "scope"}` (jobb H:s "behöver/skapar/vem"). Underlag för "Passar ihop med"
senare; inget i spelet läser det än. `scope`: self, party, enemy, enemies. Ordförråd för `needs`/`creates` (stridens händelser
och statusar): crit, attack_hit, spell_hit, direct_hit, holy_damage, follow_up, first_attack, hit_taken, attacked, turn_start,
battle_start, ally_death, poisoned_enemy_death, ally_healed, heal_cast, defend_or_provoke, provoke, ability_used,
new_ability, repeat_ability, enemy_repeat, enemy_timeline_top, not_acted, marked, allies_alive, family_alive; skapar också
damage, damage_bonus, heal, barrier, revive, dodge, immune, stat_gain, timeline_top, ignore_defense, defense_down, purge,
ability_cast och statusarna (poisoned, vulnerable, silenced, sleeping, blind, defensive, agile, mending, savage, protected).
Exempel på kedjor där det ena skapar det andra behöver: Den kapade bågsträngen (needs marked, creates crit) + Det andra hugget eller
Bödelns huva (needs crit); Den möglade klingan (creates poisoned) + Smittans väg (needs poisoned_enemy_death).

## Botarna (BALANS=trofeplats, djup 1, 100 körningar, MACRO/TUNED)

Troféer per hjälte (`TROPHY_PAIRS`): Paladinen Gravprästens radband + Det andra hugget, Brokk Den tystade skramlan + Väktarens hjälm, Alva Det brustna bönebandet +
Diakonens stola, Eira Den kapade bågsträngen + Snabbt tag, Imma Den möglade klingan + Askurnan (buren + artefakt). Artefakter på nivå 6 utan förmåga.

| | inga troféer | 1 trofé + artefakt 6 | 2 troféer + artefakt 6 |
|---|---|---|---|
| Kryptan, 4 hjältar | 32 / 45 | 91 / 91 | 100 / 100 |
| Kryptan, P+I | 58 / 39 | 96 / 74 | 97 / 74 |
| Kapellet, 4 hjältar | 36 / 45 | 80 / 79 | 98 / 99 |
| Kapellet, P+I | 70 / 57 | 85 / 76 | 93 / 76 |

Den andra trofén ger +9–19 procentenheter för fyra hjältar och +0–8 för P+I på djup 1, där en artefakt på nivå 6 redan gör
körningen lätt. Nivå 6 för fyra hjältar kostar ~2 900 silver (en klarad körning på djup 1 ger ~65–100), så platsen kommer
först när spelaren går djupare; mät där innan nivån ändras.
