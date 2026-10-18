class_name CombatUnit
extends RefCounted
## En deltagare i striden, hjälte eller boss. Bara tillstånd och små hjälpfunktioner;
## reglerna ligger i CombatSim.

var id := ""
var name := ""
var team := 0
var role := ""
var color := Color.WHITE
var max_hp := 1.0
var hp := 1.0
var max_mana := 0.0
var mana := 0.0
var mana_regen := 0.0
var position := Vector2.ZERO
var radius := 26.0
var damage_taken_mult := 1.0
var threat_mult := 1.0
var crit_chance := 0.1
var swing := {}
var swing_timer := 0.0
var rules: Array = []
var alive := true
var gcd := 0.0
## Sant när den pågående GCD:n startades av AI:n; spelarens order får då gå före.
var gcd_from_ai := false
var cooldowns := {}
## {ability, targets, elapsed, duration, by_player} medan enheten kastar, annars tom.
var cast := {}
## aura_id -> {remaining, duration, haste, damage_taken_mult, hot, tick, source}
var auras := {}
## Spelarens köade order: {ability, target}.
var queued := {}


static func from_data(unit_id: String, d: Dictionary, unit_team: int) -> CombatUnit:
	var u := CombatUnit.new()
	u.id = unit_id
	u.name = d.get("name", unit_id)
	u.team = unit_team
	u.role = d.get("role", "")
	u.color = Color(d.get("color", "#ffffff"))
	u.max_hp = d.get("max_hp", 1000.0)
	u.hp = u.max_hp
	u.max_mana = d.get("max_mana", 0.0)
	u.mana = u.max_mana
	u.mana_regen = d.get("mana_regen", 0.0)
	var pos: Array = d.get("pos", [0, 0])
	u.position = Vector2(pos[0], pos[1])
	u.radius = d.get("radius", 26.0)
	u.damage_taken_mult = d.get("damage_taken_mult", 1.0)
	u.threat_mult = d.get("threat_mult", 1.0)
	u.crit_chance = d.get("crit_chance", 0.1)
	u.swing = d.get("swing", {})
	u.swing_timer = u.swing.get("interval", 2.0) * d.get("first_swing", 0.5)
	u.rules = d.get("rules", [])
	return u


func hp_pct() -> float:
	return hp / max_hp


func is_casting() -> bool:
	return not cast.is_empty()


func cast_progress() -> float:
	if cast.is_empty():
		return 0.0
	return clampf(cast.elapsed / cast.duration, 0.0, 1.0)


func haste() -> float:
	var h := 1.0
	for a in auras.values():
		h += a.haste
	return h


func damage_taken() -> float:
	var m := damage_taken_mult
	for a in auras.values():
		m *= a.damage_taken_mult
	return m


func cooldown_left(ability_id: String) -> float:
	return cooldowns.get(ability_id, 0.0)
