class_name DamageExplain
extends RefCounted
## Uträkningen bakom en skade- eller helningssiffra i klartext (0.21, vårt tillägg i samma anda som
## makroförklaringen). Läser "calc" som CombatSim lägger i händelserna damage, heal och dodge.
## Ren logik: används av stridens skadelogg och av testerna.


static func title(data: Dictionary, e: Dictionary) -> String:
	var c: Dictionary = e.get("calc", {})
	var what := _source_name(data, String(e.get("ability", "")))
	match e.type:
		"heal":
			return "%s helar %s: +%d (%s)" % [c.get("source_name", "?"), c.get("target_name", "?"), int(e.effective), what]
		"dodge":
			return "%s undvek %s (%s)" % [c.get("target_name", "?"), c.get("source_name", "?"), what]
	var crit := "!" if e.get("crit", false) else ""
	return "%s → %s: %d%s (%s)" % [c.get("source_name", "?"), c.get("target_name", "?"), int(e.amount), crit, what]


## Raderna i uträkningen, uppifrån och ned. Sista raden är resultatet.
static func lines(data: Dictionary, e: Dictionary) -> Array[String]:
	var c: Dictionary = e.get("calc", {})
	var out: Array[String] = []
	if c.is_empty():
		return out
	match e.type:
		"heal":
			return _heal_lines(data, c)
		"dodge":
			out.append("Chans att undvika: %s (fart %s mot %s; snabbare mål undviker oftare, egenskaper adderas)" % [
					pct(c.get("dodge_chance", 0.0)), HeroStats.shown(c.target_speed), HeroStats.shown(c.source_speed)])
			return out
	var kind: String = c.get("kind", "attack")
	if c.get("scaled", false):
		var stat_name: String = HeroStats.STAT_NAMES.get(c.get("stat", "attack"), "Attack")
		var sv := float(c.get("stat_value", 0.0))
		var roll := float(c.get("roll", 1.0))
		match kind:
			"spell":
				var tier_mult := float(c.get("tier_mult", 1.0))
				var potency := sv * tier_mult * roll
				out.append("Potency: %s %s × nivå %s × variation %s = %s" % [num(sv), stat_name, pct(tier_mult), dec(roll), num(potency)])
				out.append(_defense_line(c, float(c.get("ignore", 0.0))))
				var d := float(c.defense) * (1.0 - float(c.get("ignore", 0.0)))
				out.append("%s × förmågans styrka %s = %s" % [_minus(potency, d), dec(c.power), num(c.raw)])
			"indirect":
				out.append("%s %s × variation %s × förmågans styrka %s = %s (indirekt: Defense dras av sist)" % [num(sv), stat_name,
						dec(roll), dec(c.power), num(c.raw)])
			_:
				var atk := sv * roll
				out.append("%s %s × variation %s = %s" % [num(sv), stat_name, dec(roll), num(atk)])
				out.append(_defense_line(c, 0.0))
				out.append("%s + 1 %% av %s (%s) = %s × förmågans styrka %s = %s" % [_minus(atk, float(c.defense)), num(atk),
						num(CombatSim.ATTACK_FLOOR * atk), num(maxf(atk - float(c.defense), 0.0) + CombatSim.ATTACK_FLOOR * atk),
						dec(c.power), num(c.raw)])
	else:
		out.append("Grundbelopp %s (%s)" % [num(c.get("amount_in", c.get("raw", 0.0))), _fixed_reason(data, c)])
	var mods: Array = c.get("mods", [])
	if not mods.is_empty():
		var parts: Array[String] = []
		for m in mods:
			parts.append("%s %s" % [m.name, signed_pct(float(m.f))])
		out.append("Modifierare: %s → ×%s (ökningar adderas, minskningar multipliceras)" % [", ".join(parts), dec(c.mod_total)])
	if kind == "attack" and c.has("crit_chance"):
		if c.get("crit", false):
			out.append("Krit! +%s (fart %s mot %s; chansen var %s)" % [pct(c.crit_bonus), HeroStats.shown(c.source_speed), HeroStats.shown(c.target_speed),
					pct(c.crit_chance)])
		else:
			out.append("Ingen krit (chans %s vid fart %s mot %s)" % [pct(c.crit_chance), HeroStats.shown(c.source_speed), HeroStats.shown(c.target_speed)])
	if c.has("dodge_chance") and float(c.dodge_chance) > 0.0:
		out.append("Träffade trots %s chans att undvika" % pct(c.dodge_chance))
	if kind == "indirect":
		out.append("%s − 20 %% av Defense %s (%s) = %s" % [num(c.before_defense), num(c.defense), num(c.indirect_defense),
				num(maxf(float(c.before_defense) - float(c.indirect_defense), 0.0))])
	if float(c.get("additional", 0.0)) > 0.0:
		out.append("+ %s extra (%s)" % [num(c.additional), c.get("additional_name", "egenskap")])
	if float(c.get("absorbed", 0.0)) > 0.0:
		out.append("Barriären tog %s av %s" % [num(c.absorbed), num(c.total)])
	out.append("= %s skada" % num(c.get("lost", 0.0)))
	return out


static func _heal_lines(data: Dictionary, c: Dictionary) -> Array[String]:
	var out: Array[String] = []
	if c.get("leech", false):
		out.append("%s av skadan %s (%s) = %s" % [pct(c.leech_pct), num(c.from_damage),
				_source_name(data, String(c.get("ability", ""))), num(c.base)])
	elif c.has("roll"):
		out.append("%s Intelligence × %s × variation %s = %s" % [num(c.stat_value), dec(c.power), dec(c.roll), num(c.base)])
	elif c.get("hot", false):
		out.append("Grundbelopp %s per tur (%s)" % [num(c.base), _source_name(data, String(c.get("ability", "")))])
	elif String(c.get("stat", "")) != "":
		out.append("%s av %s %s = %s" % [pct(c.pct), num(c.stat_value), HeroStats.STAT_NAMES.get(c.stat, c.stat), num(c.base)])
	else:
		out.append("Grundbelopp %s" % num(c.base))
	var mods: Array = c.get("mods", [])
	if not mods.is_empty():
		var parts: Array[String] = []
		for m in mods:
			parts.append("%s %s" % [m.name, signed_pct(float(m.f))])
		out.append("Modifierare: %s → ×%s" % [", ".join(parts), dec(c.mod_total)])
	var over := float(c.amount) - float(c.effective)
	out.append("= %s helat%s" % [num(c.effective), "" if over < 1.0 else " (%s över fullt liv)" % num(over)])
	return out


## "(a − b)", eller "(a − b → 0)" när Defense är större: skillnaden blir aldrig negativ (0.23.3).
static func _minus(a: float, b: float) -> String:
	if roundi(a) < roundi(b) or a < b:
		return "(%s − %s → 0)" % [num(a), num(b)]
	return "(%s − %s)" % [num(a), num(b)]


static func _defense_line(c: Dictionary, ignore: float) -> String:
	var line := "Defense %s" % num(c.defense)
	var parts: Array = c.get("defense_parts", [])
	if not parts.is_empty():
		var bits: Array[String] = []
		for p in parts:
			bits.append("%s %s" % [p.name, signed_pct(float(p.mult))])
		line += " (%s, %s)" % [num(c.defense_base), ", ".join(bits)]
	if ignore > 0.0:
		line += ", nivån bortser från %s → %s" % [pct(ignore), num(float(c.defense) * (1.0 - ignore))]
	return line


static func _fixed_reason(data: Dictionary, c: Dictionary) -> String:
	var id: String = c.get("ability", "")
	if data.auras.has(id):
		return "%s, varje tur" % data.auras[id].get("name", id)
	if data.traits.has(id):
		return data.traits[id].get("name", id)
	return "fast belopp"


static func _source_name(data: Dictionary, id: String) -> String:
	if data.abilities.has(id):
		return data.abilities[id].get("name", id)
	if data.auras.has(id):
		return data.auras[id].get("name", id)
	if data.traits.has(id):
		return data.traits[id].get("name", id)
	if data.get("floor_rules", {}).has(id):
		return data.floor_rules[id].get("name", id)
	return id


static func num(v: Variant) -> String:
	return "%d" % roundi(float(v))


static func dec(v: Variant) -> String:
	return ("%.2f" % float(v)).replace(".", ",")


static func pct(v: Variant) -> String:
	return "%d %%" % roundi(float(v) * 100.0)


static func signed_pct(f: float) -> String:
	var p := roundi((f - 1.0) * 100.0)
	return ("+%d %%" % p) if p >= 0 else ("−%d %%" % -p)
