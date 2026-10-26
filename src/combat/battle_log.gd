class_name BattleLog
extends RefCounted
## Stridsloggen (Siralims stridslogg): en svensk rad för varje händelse som inte bär en uträkning – förmågor som inte
## skadar, buffar och debuffar, Barriär, statusar som tar en tur, flyttar på tidslinjen, avbrott och död. Skador,
## helningar och undvikanden har sin rad och uträkning i DamageExplain. Ren logik: används av DamageLog och testerna.
##
## line() ger "" för händelser som inte loggas (turens början, avsikter, resultatet) och för dem som stridens grafik
## redan skriver en egen rad för (varslade attacker, ärvda egenskaper och statusar, se battle.gd).

const SKIP := ["turn_start", "acted", "intent_chosen", "outcome", "battle_start", "elite", "stack_said", "windup_start",
		"windup_tick", "windup_release", "windup_delayed", "windup_broken", "trait_passed", "aura_passed", "damage",
		"heal", "dodge"]

const AURA_REMOVED := {"expired": "gick ut", "used": "förbrukades", "broken": "bröts", "replaced": "ersattes",
		"dispel": "skingrades", "purge": "rensades bort", "broke_free": "slet sig loss", "stolen": "stals",
		"thawed": "tinade", "woke": "vaknade", "consumed": "förbrukades"}

const TIMELINE := {"top": "överst", "bottom": "längst ned", "up": "uppåt", "down": "nedåt"}

const LIMITS := {"attack": "anfall", "spell": "besvärjelser", "heal": "helningar", "ability": "förmågor"}


## Raden för händelsen, eller "".
static func line(sim: CombatSim, e: Dictionary) -> String:
	var type := String(e.get("type", ""))
	if type in SKIP:
		return ""
	var who := _name(sim, e.get("unit", ""))
	match type:
		"action":
			return _action(sim, e, who)
		"aura_applied":
			var a := _aura(sim, e.aura)
			var from := _name(sim, e.get("source", ""))
			var kind := _kind(e.get("aura_kind", ""))
			if e.get("refreshed", false):
				return "%s: %s förnyas%s." % [who, a, kind]
			if from != "" and e.get("source", "") != e.get("unit", ""):
				return "%s ger %s %s%s." % [from, who, a, kind]
			return "%s får %s%s." % [who, a, kind]
		"aura_removed":
			if e.get("reason", "") == "death":
				return ""
			return "%s: %s %s." % [who, _aura(sim, e.aura), AURA_REMOVED.get(e.get("reason", ""), "upphörde")]
		"status_skip":
			return "%s står över turen (%s)." % [who, _aura(sim, e.get("aura", ""))]
		"status_blocked":
			return "%s kan inte göra det den tänkte (%s)." % [who, _aura(sim, e.get("aura", ""))]
		"status_immune":
			if e.get("unbound", false):
				return "%s är obunden och slipper %s." % [who, _aura(sim, e.aura)]
			return "%s står emot %s." % [who, _aura(sim, e.aura)]
		"immune":
			return "%s är immun mot %s (%s)." % [_name(sim, e.target), _name(sim, e.source), _ability(sim, e.get("ability", ""))]
		"shelled":
			return "%ss skyddsskal tar %s från %s." % [_name(sim, e.target), _ability(sim, e.get("ability", "")), _name(sim, e.source)]
		"guarded":
			return "%s tar %d skada åt %s som livvakt." % [who, int(e.get("amount", 0.0)), _name(sim, e.get("protected", ""))]
		"heal_blocked":
			return "%s kan inte helas (%s)." % [who, _trait(sim, e.trait) if e.has("trait") else _aura(sim, e.get("aura", ""))]
		"blighted":
			return "%s är fördärvad: helningen blir skada." % who
		"revive":
			return "%s reser sig igen." % who
		"revive_blocked":
			return "%s kan inte väckas%s." % [who, " (%s)" % _trait(sim, e.trait) if e.has("trait") else ""]
		"death":
			return "%s föll." % who
		"timeline_move":
			if e.get("pushed", false):
				return "%s trycks längst ned på tidslinjen." % who
			return "%s flyttas %s på tidslinjen." % [who, TIMELINE.get(e.get("dir", ""), "")]
		"timeline_blocked":
			var why := {"snared": "Snärjd", "boss_battle": "en boss rubbas inte", "limit": "en gång per runda"}
			return "%s rubbas inte på tidslinjen (%s)." % [who, why.get(e.get("reason", ""), e.get("reason", ""))]
		"confused":
			return "%s är förvirrad och anfaller fel." % who
		"buff_stolen":
			return "%s stjäl %s från %s åt %s." % [who, _aura(sim, e.aura), _name(sim, e.from), _name(sim, e.to)]
		"charge_drained":
			return "%s tappar en Charge på %s." % [who, _ability(sim, e.get("ability", ""))]
		"charge_restored":
			return "%s får tillbaka Charges på %s." % [who, _ability(sim, e.get("ability", ""))]
		"stat_raised":
			return "%s: %s höjs till %s." % [who, HeroStats.STAT_NAMES.get(e.stat, e.stat), HeroStats.shown(float(e.value))]
		"corpse_consumed":
			return "%s äter upp liket efter %s." % [_name(sim, e.get("by", "")), who]
		"self_damage":
			return "%s offrar %d liv (%s)." % [who, int(e.get("amount", 0.0)), _ability(sim, e.get("ability", ""))]
		"limit":
			return "%s har nått gränsen för %s den här turen." % [who, LIMITS.get(e.get("kind", ""), e.get("kind", ""))]
		"trait":
			return "%s: %s slår till." % [who, _trait(sim, e.trait)]
		"release":
			return "%s släpper loss %s." % [who, _trait(sim, e.get("trait", ""))]
		"rule":
			return "Våningsregel: %s." % String(sim.data.get("floor_rules", {}).get(e.rule, {}).get("name", e.rule))
		"exhaustion_start":
			return "Facklorna falnar: utmattningen börjar."
		"exhaustion":
			return "%s tappar %d liv av utmattning." % [who, int(e.get("amount", 0.0))]
		"chaos_calm":
			return "Kaosvinden lägger sig kring %s." % who
		"interrupt":
			return "%s avbryter %s: %s blir inte av." % [who, _name(sim, e.target), _ability(sim, e.get("ability", ""))]
	return ""


static func _action(sim: CombatSim, e: Dictionary, who: String) -> String:
	var action := String(e.get("action", ""))
	var ab := String(e.get("ability", ""))
	var u := sim.unit(e.get("unit", ""))
	match action:
		"skip":
			return "%s väntar." % who
		"defend":
			return "%s försvarar sig." % who
		"provoke":
			return "%s provocerar." % who
	if ab in ["defend", "provoke"]:
		return "%s %s." % [who, "försvarar sig" if ab == "defend" else "provocerar"]
	# Grundanfallet syns i skaderaden (eller som undvikande), så det får ingen egen rad.
	if action == "attack" or (u != null and ab == u.attack_ability):
		return ""
	var targets: Array = e.get("targets", [])
	var names: Array = []
	for id in targets:
		if id != e.get("unit", ""):
			names.append(_name(sim, id))
	var via := " (artefakt)" if action == "artifact" else ""
	if names.is_empty():
		return "%s använder %s%s." % [who, _ability(sim, ab), via]
	return "%s använder %s%s mot %s." % [who, _ability(sim, ab), via, _join(names)]


static func _join(names: Array) -> String:
	if names.size() <= 1:
		return "".join(names)
	if names.size() > 3:
		return "%d mål" % names.size()
	return ", ".join(names.slice(0, names.size() - 1)) + " och " + String(names[-1])


static func _name(sim: CombatSim, id: Variant) -> String:
	var u := sim.unit(String(id)) if String(id) != "" else null
	return u.name if u != null else ""


static func _aura(sim: CombatSim, id: Variant) -> String:
	return String(sim.data.get("auras", {}).get(String(id), {}).get("name", String(id)))


static func _trait(sim: CombatSim, id: Variant) -> String:
	return String(sim.data.get("traits", {}).get(String(id), {}).get("name", String(id)))


static func _ability(sim: CombatSim, id: String) -> String:
	return String(sim.ability(id).get("name", id))


static func _kind(kind: String) -> String:
	return {"buff": " (buff)", "debuff": " (debuff)"}.get(kind, "")
