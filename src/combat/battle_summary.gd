class_name BattleSummary
extends RefCounted
## "Det här avgjorde striden" (0.30, byggets fingeravtryck): det sällskapets egenskaper och kombinationer faktiskt gjorde,
## sorterat efter betydelse. Varje rad säger var delen kommer ifrån (trofé, kall, artefakt, egen), så att spelaren ser
## vilken del av bygget som bar striden. Ren logik; segerskärmen och kvittot ritar.


## [{name, tag, who, text, score}] för sällskapets egenskaper och kombinationer, högst n rader.
static func deciders(sim: CombatSim, n := 4) -> Array:
	# Samma del av bygget räknas en gång: kallet (som gäller hela sällskapet och har dolda hjälpegenskaper med samma
	# namn) samlas under Paladinen, och delar med samma namn och källa slås ihop.
	var groups := {}
	for trait_id in sim.trait_stats:
		var st: Dictionary = sim.trait_stats[trait_id]
		var u := sim.unit(st.unit)
		var t: Dictionary = sim.data.traits.get(trait_id, {})
		if st.procs == 0 or u == null or u.team != 0 or t.is_empty() or (t.get("hidden", false) and not t.has("name")):
			continue
		var src := tag(sim.data, trait_id)
		var who: String = sim.heroes[0].name if src == "KALL" else u.name
		var key := "%s|%s|%s" % [t.get("name", trait_id), src, who]
		var g: Dictionary = groups.get(key, {"name": String(t.get("name", trait_id)), "tag": src, "who": who,
				"damage": 0.0, "heal": 0.0, "procs": 0, "id": trait_id})
		g.damage += st.damage
		g.heal += st.heal
		g.procs += st.procs
		groups[key] = g
	var rows: Array = []
	for g in groups.values():
		rows.append({"name": g.name, "tag": g.tag, "who": g.who, "id": g.id, "text": _amounts(g.damage, g.heal, g.procs),
				"score": g.damage + g.heal * 1.2 + g.procs * 5.0})
	for ability_id in sim.combo_stats:
		var c: Dictionary = sim.combo_stats[ability_id]
		var u := sim.unit(c.unit)
		rows.append({"name": "%s → %s" % [sim.status_name(u, c.aura) if u else c.aura, sim.data.abilities[ability_id].name],
				"tag": "KOMBINATION", "who": u.name if u else "",
				"text": "+%d skada · %s" % [roundi(c.extra), _times(c.count)],
				"score": c.extra * 1.5 + c.count * 8.0})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.score > b.score)
	return rows.slice(0, n)


## Fingeravtryckets andra halva (0.30.16): troféer man äger som kunde ta en trofés plats, bäst först. Lika roll (skada,
## helning, skydd, kontroll) väger tyngst, sedan samma utlösare och samma sällsynthet. [{id, name, text, wearer}], högst n.
## owned: troféerna man kan byta till (körningens); worn: hero_id -> trophy_id; names: hero_id -> namn.
static func alternatives(data: Dictionary, trait_id: String, owned: Array, worn: Dictionary, names: Dictionary, n := 4) -> Array:
	var t: Dictionary = data.traits.get(trait_id, {})
	var mine := roles(t)
	var scored: Array = []
	for other in owned:
		if other == trait_id or not data.traits.has(other):
			continue
		var o: Dictionary = data.traits[other]
		var score := 0.0
		for r in roles(o):
			if mine.has(r):
				score += 3.0
		if o.get("trigger", "") == t.get("trigger", "-"):
			score += 2.0
		if o.get("rarity", "common") == t.get("rarity", "common"):
			score += 1.0
		var wearer := ""
		for hero_id in worn:
			if worn[hero_id] == other:
				wearer = String(names.get(hero_id, hero_id))
		if wearer == "":
			score += 0.5  # en trofé som ingen bär är lättast att prova
		scored.append({"id": other, "name": String(o.get("name", other)), "text": String(o.get("text", "")),
				"wearer": wearer, "score": score})
	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.score > b.score or (a.score == b.score and a.name < b.name))
	return scored.slice(0, n)


## Vad en egenskap gör, grovt: "skada", "helning", "skydd", "kontroll".
static func roles(t: Dictionary) -> Array:
	var out: Array = []
	var trig := String(t.get("trigger", ""))
	if trig == "modify_damage":
		out.append("skada")
	if trig in ["modify_damage_taken", "convert_damage"]:
		out.append("skydd")
	if t.has("modify_heal"):
		out.append("helning")
	for e in t.get("effects", []):
		match String(e.get("type", "")):
			"damage", "cast":
				out.append("skada")
			"heal", "revive":
				out.append("helning")
			"barrier":
				out.append("skydd")
			"aura":
				out.append("skydd" if String(e.get("target", "")) in ["self", "allies", "weakest_ally"] else "kontroll")
	return out


## Var en egenskap kommer ifrån: TROFÉ, KALL, ARTEFAKT eller EGEN.
static func tag(data: Dictionary, trait_id: String) -> String:
	var t: Dictionary = data.traits.get(trait_id, {})
	if t.get("artifact", false) or trait_id.begins_with("artifact_"):
		return "ARTEFAKT"
	if t.get("trophy", false):
		return "TROFÉ"
	if t.has("oath") or data.get("oaths", {}).keys().any(func(o: String) -> bool: return trait_id.begins_with(o)):
		return "KALL"
	return "EGEN"


static func _amounts(damage: float, heal: float, procs: int) -> String:
	var what: Array[String] = []
	if damage > 0.0:
		what.append("%d skada" % roundi(damage))
	if heal > 0.0:
		what.append("%d helning" % roundi(heal))
	what.append(_times(procs))
	return " · ".join(what)


static func _times(n: int) -> String:
	return "%d %s" % [n, "gång" if n == 1 else "gånger"]
