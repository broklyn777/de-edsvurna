extends CombatSim
## Granskningens simulator (0.23.3): exakt samma strid som CombatSim, men före varje träff och helning sparas
## ett fotografi av alla figurer, och händelsen som träffen gav kopplas till fotografiet. test_numbers_audit.gd
## räknar sedan om siffran med den oberoende formelmodulen (numbers_reference.gd) och jämför.
##
## Skapas med AuditSim.adopt(CombatSim.create(...)): alla fält kopieras över, så att striden blir densamma.

## Färdiga poster: {kind: "damage"|"heal", frame, event, parent}. frame = läget före anropet.
var records: Array = []
var _frames: Array = []


static func adopt(sim: CombatSim) -> CombatSim:
	var out: CombatSim = load("res://tests/audit_sim.gd").new()
	for p in sim.get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and p.name != "records" and p.name != "_frames":
			out.set(p.name, sim.get(p.name))
	return out


static func snap_unit(u: CombatUnit) -> Dictionary:
	return {"id": u.id, "kind": u.kind, "team": u.team, "alive": u.alive, "hp": u.hp, "max_hp": u.max_hp,
			"attack": u.attack, "intelligence": u.intelligence, "defense": u.defense, "speed": u.speed,
			"base_stats": u.base_stats.duplicate(), "crit_chance": u.crit_chance, "barrier": u.barrier,
			"damage_taken_mult": u.damage_taken_mult, "resistant": u.resistant, "auras": u.auras.duplicate(true),
			"traits": u.traits.duplicate(), "attacks_done": u.attacks_done, "ability_uses": u.ability_uses.duplicate(),
			"times_hit": u.times_hit, "attack_ability": u.attack_ability, "name": u.name}


func _snapshot() -> Dictionary:
	var all := {}
	for u in units:
		all[u.id] = snap_unit(u)
	return all


func _deal_damage(src: CombatUnit, tgt: CombatUnit, amount: float, school: String,
		ability_id: String, can_crit: bool, direct := false, kind := "attack", scaled := false) -> void:
	if not tgt.alive:
		return
	var frame := {"kind": "damage", "units": _snapshot(), "source": src.id, "target": tgt.id, "amount": amount,
			"school": school, "ability": ability_id, "can_crit": can_crit, "direct": direct, "kind_in": kind,
			"scaled": scaled, "trait_ctx": _trait_ctx, "origin": _origin.duplicate(),
			"release": _release_bonus.duplicate(), "rules": rules.duplicate(), "event": {},
			"parent": _frames[-1] if not _frames.is_empty() else {}}
	_frames.append(frame)
	super(src, tgt, amount, school, ability_id, can_crit, direct, kind, scaled)
	_frames.pop_back()
	records.append(frame)


func _heal(src: CombatUnit, tgt: CombatUnit, base: float, ability_id: String) -> void:
	if not tgt.alive:
		return
	var frame := {"kind": "heal", "units": _snapshot(), "source": src.id, "target": tgt.id, "base": base,
			"ability": ability_id, "ctx": _heal_ctx.duplicate(), "trait_ctx": _trait_ctx, "origin": _origin.duplicate(),
			"rules": rules.duplicate(), "event": {}, "parent": _frames[-1] if not _frames.is_empty() else {}}
	_frames.append(frame)
	super(src, tgt, base, ability_id)
	_frames.pop_back()
	records.append(frame)


func _emit(e: Dictionary) -> void:
	if not _frames.is_empty():
		var f: Dictionary = _frames[-1]
		var mine: bool = e.get("source", "") == f.source and e.get("target", "") == f.target
		if f.event.is_empty() and mine and ((f.kind == "damage" and e.type in ["damage", "dodge", "immune", "shelled"])
				or (f.kind == "heal" and e.type == "heal")):
			f.event = e
			f.after_hp = unit(f.target).hp
		elif f.event.is_empty() and f.kind == "heal" and e.type == "blighted" and e.unit == f.target:
			f.event = e
	super(e)
