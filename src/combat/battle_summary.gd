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
				"damage": 0.0, "heal": 0.0, "procs": 0})
		g.damage += st.damage
		g.heal += st.heal
		g.procs += st.procs
		groups[key] = g
	var rows: Array = []
	for g in groups.values():
		rows.append({"name": g.name, "tag": g.tag, "who": g.who, "text": _amounts(g.damage, g.heal, g.procs),
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
