class_name CombatUnit
extends RefCounted
## En deltagare i striden, hjälte eller fiende. Bara tillstånd och små hjälpfunktioner;
## reglerna ligger i CombatSim.

var id := ""
## Fiendetyp i enemies.json (hjältar: samma som id).
var kind := ""
var name := ""
var title := ""
var team := 0
var role := ""
var color := Color.WHITE
var max_hp := 1.0
var hp := 1.0
var speed := 10.0
var attack_min := 10.0
var attack_max := 12.0
var crit_chance := 0.1
var damage_taken_mult := 1.0
var attack_ability := "attack"
## Hjältens förmågor (motsvarar Siralims Spell Gems) och hur många Charges som är kvar på var.
var abilities: Array = []
var charges := {}
var position := Vector2.ZERO
## Fiender: [{ability, if}] för att välja avsikt (hjältar styrs av makron).
var rules: Array = []
var traits: Array = []
## Artefakten hjälten bär: {type, ability} (tom = ingen). Se CombatSim.equip_artifact.
var artifact := {}
## trait_id -> {turn, count, ready_at} då egenskapen senast slog till.
var trait_ready := {}
## Uppladdade staplar från egenskaper: stack -> mängd, och räknare för "var n:e"-staplar.
var stacks := {}
var stack_progress := {}
var deaths := 0
var revives := 0
## Hur många egna turer figuren har fått i striden.
var turns_taken := 0
var alive := true
## ability_id -> egna turer kvar.
var cooldowns := {}
## aura_id -> {remaining, duration, haste, damage_taken_mult, hot, dot, school, source}
var auras := {}
## Fiender: {ability, targets} – vad den tänker göra när det blir dess tur.
var intent := {}


static func from_data(unit_id: String, d: Dictionary, unit_team: int) -> CombatUnit:
	var u := CombatUnit.new()
	u.id = unit_id
	u.kind = unit_id
	u.name = d.get("name", unit_id)
	u.title = d.get("title", "")
	u.team = unit_team
	u.role = d.get("role", "")
	u.color = Color(d.get("color", "#ffffff"))
	u.max_hp = d.get("max_hp", 100.0)
	u.hp = u.max_hp
	u.speed = d.get("speed", 10.0)
	var atk: Array = d.get("attack", [10, 12])
	u.attack_min = atk[0]
	u.attack_max = atk[1]
	u.crit_chance = d.get("crit_chance", 0.1)
	u.damage_taken_mult = d.get("damage_taken_mult", 1.0)
	u.attack_ability = d.get("attack_ability", "attack")
	u.abilities = d.get("abilities", []).duplicate()
	u.rules = d.get("rules", [])
	u.traits = d.get("traits", []).duplicate()
	return u


func hp_pct() -> float:
	return hp / max_hp


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
