class_name LevelJump
extends RefCounted
## Nivåskalan (VD 2026-10-25, docs/plan/nivaer-och-charges.md §3.1): en nivå visas i det den gör i striden.


## Vad nivån gör i striden, inte bara i stats. Liv, den starkaste skadeförmågan (annars
## Anfall) och en helning, före och efter nivån, mot den första fienden på våning 1 i Realmen på djupet (som hjältebladet,
## CombatSim.expected_damage och expected_heal). Ger [{label, before, after, unit}], tom om något saknas.
static func compute(game_data: Dictionary, prof: Profile, hero_id: String, lv: int, realm_id: String, at_depth: int,
		party: Array, before_carry := 0.0) -> Array:
	var realm: Dictionary = game_data.get("realms", {}).get(realm_id, {})
	if realm.is_empty() or lv < 2 or not game_data.heroes.has(hero_id):
		return []
	var art: Dictionary = prof.artifact(hero_id)
	var arts := {} if art.is_empty() else {hero_id: art}
	var who: Array = party.duplicate() if party.has(hero_id) else [hero_id]
	var traits := {"paladin": [prof.oath] + prof.active_perks(game_data, prof.oath)}
	var at := []
	for level in [lv - 1, lv]:
		var levels := prof.levels_for(game_data, who)
		levels[hero_id] = {"level": level, "personality": prof.hero(game_data, hero_id).personality,
				"carry": before_carry if level < lv else 0.0}
		at.append(CombatSim.create(game_data, String(realm.floors[0]), 1, who, traits, {}, arts, maxi(at_depth, 1),
				{"levels": levels, "elite_chance": 0.0, "floor": 0,
				"depth_offset": RunState.realm_depth_offset(game_data, realm_id)}))
	var out := []
	var h0: CombatUnit = at[0].unit(hero_id)
	var h1: CombatUnit = at[1].unit(hero_id)
	if h0 == null or h1 == null or at[0].enemies.is_empty():
		return []
	out.append({"label": "Liv", "before": roundi(h0.max_hp), "after": roundi(h1.max_hp), "unit": ""})
	var foe0: CombatUnit = at[0].enemies[0]
	var foe1: CombatUnit = at[1].enemies[0]
	var best := h1.attack_ability
	var best_hit: float = at[1].expected_damage(h1, foe1, best)
	var heal := ""
	for ability_id in h1.abilities:
		for eff in game_data.abilities[ability_id].get("effects", []):
			if eff.type == "damage" and eff.has("power"):
				var hit: float = at[1].expected_damage(h1, foe1, ability_id)
				if hit > best_hit:
					best = ability_id
					best_hit = hit
			elif eff.type == "heal" and eff.has("power") and heal == "":
				heal = ability_id
	out.append({"label": String(game_data.abilities[best].name), "before": roundi(at[0].expected_damage(h0, foe0, best)),
			"after": roundi(best_hit), "unit": "skada"})
	if heal != "":
		out.append({"label": String(game_data.abilities[heal].name), "before": roundi(at[0].expected_heal(h0, h0, heal)),
				"after": roundi(at[1].expected_heal(h1, h1, heal)), "unit": "helning"})
	return out


## Raden på segerskärmen: "Liv 120 → 158 · Rättfärdigt slag 14 → 19 skada · Helande ljus 18 → 24 helning".
static func text(jump: Array) -> String:
	var parts := []
	for j in jump:
		parts.append(("%s %d → %d %s" % [j.label, j.before, j.after, j.unit]).strip_edges())
	return " · ".join(parts)
