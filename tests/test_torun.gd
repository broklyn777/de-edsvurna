extends "res://tests/test_case.gd"
## Torun Bergsbrytare, den femte (docs/ideer/chat-femte-foljeslagaren.md): Inte färdigt än avbryter en helning eller en
## varslad attack, det kostar, Tystad behövs ändå; hon kommer med den femte platsen; replikernas villkor.

var _data := GameData.load_all()
var _run: Script = load("res://scripts/game/run.gd")


func _sim(encounter := "troll_1b") -> CombatSim:
	var sim := CombatSim.create(_data, encounter, 3, ["paladin", "torun"], {}, {}, {}, 1, {"elite_chance": 0.0})
	sim.begin()
	sim.drain_events()
	return sim


func _enemy(sim: CombatSim, kind: String) -> CombatUnit:
	for e in sim.enemies:
		if e.kind == kind:
			return e
	return null


func _ready_torun(sim: CombatSim) -> CombatUnit:
	var t := sim.unit("torun")
	sim._add_aura(t, t, "torun_ready")
	sim.drain_events()
	return t


func _types(events: Array) -> Array:
	return events.map(func(e: Dictionary) -> String: return e.type)


func test_interrupt_cancels_an_enemy_heal() -> void:
	var sim := _sim()
	var t := _ready_torun(sim)
	var mother := _enemy(sim, "porridge_troll")
	var other := _enemy(sim, "moss_troll")
	other.hp = other.max_hp * 0.3
	# Grytmodern står på tur och tänker hela.
	sim.order.erase(mother.id)
	sim.current = mother
	mother.intent = {"ability": "porridge_feed", "targets": [other.id]}
	var before := other.hp
	sim.ai_act()
	var ev := sim.drain_events()
	assert_true(_types(ev).has("interrupt"), "avbrottet syns som händelse")
	assert_true(not ev.any(func(e: Dictionary) -> bool: return e.type == "heal" and e.source == mother.id), "ingen helning")
	assert_eq(other.hp, before, "livet är oförändrat")
	assert_true(not t.auras.has("torun_ready"), "beredskapen förbrukades")
	assert_true(ev.any(func(e: Dictionary) -> bool: return e.type == "trait" and e.trait == "torun_not_done"),
			"egenskapen slår till (räknas på segerskärmen)")
	assert_true(BattleLog.line(sim, ev.filter(func(e: Dictionary) -> bool: return e.type == "interrupt")[0]).find("avbryter") >= 0,
			"stridsloggen har raden")


func test_interrupt_breaks_a_released_windup_and_delays_a_boss() -> void:
	var sim := _sim()
	_ready_torun(sim)
	var e := _enemy(sim, "moss_troll")
	e.charging = {"ability": "inquisitor_verdict", "left": 1, "max": 1, "taken": 0.0}
	assert_true(sim._interrupted(e, "inquisitor_verdict", true), "den släppta laddningen avbryts")
	assert_true(e.cooldown_left("inquisitor_verdict") > 0.0, "förmågan får sin nedkylning")
	# En boss tappar inte laddningen, den skjuts upp en tur.
	var sim2 := _sim("crypt_3")
	_ready_torun(sim2)
	var lich := _enemy(sim2, "bone_lich")
	lich.charging = {}
	assert_true(sim2._interrupted(lich, "lich_doom", true))
	assert_eq(sim2.charge_left(lich), 1, "Benfursten laddar en tur till")
	assert_true(sim2.drain_events().any(func(x: Dictionary) -> bool: return x.type == "interrupt" and x.delayed))


func test_interrupt_costs_her_turn_and_has_a_cooldown() -> void:
	assert_true(float(_data.abilities.torun_ready.get("cooldown", 0)) >= 3.0, "nedkylning på minst tre egna turer")
	assert_true(not _data.abilities.torun_ready.effects.any(func(f: Dictionary) -> bool: return f.type == "damage"),
			"att stå beredd gör ingen skada: turen går åt")
	var sim := _sim()
	var t := sim.unit("torun")
	sim.order.erase(t.id)
	sim.current = t
	assert_eq(sim.act("ability", "", "torun_ready"), "")
	assert_true(t.auras.has("torun_ready"), "hon står beredd")
	assert_true(t.auras.has("provoke") and t.auras.has("defend"), "och drar anfallen till sig som andra tank")
	assert_true(sim.can_act(t, "ability", "torun_ready") != "", "inte igen direkt")
	# Utan beredskap avbryter hon ingenting.
	var sim2 := _sim()
	var e := _enemy(sim2, "porridge_troll")
	assert_true(not sim2._interrupted(e, "porridge_feed", false), "inte utan Stå beredd")


func test_silence_still_matters() -> void:
	var sim := _sim()
	var t := _ready_torun(sim)
	var e := _enemy(sim, "porridge_troll")
	# Torun själv Tystad: inget avbrott.
	sim._add_aura(e, t, "silenced")
	assert_true(not sim._interrupted(e, "porridge_feed", false), "en Tystad Torun avbryter inte")
	sim._remove_aura(t, "silenced", "used")
	# Laddningar som bara bryts på annat sätt (Midnatt) går inte att avbryta.
	assert_true(not sim._interrupted(e, "midnight_doom", true), "Midnatt bryts bara när kanalen faller")
	# Vanliga anfall avbryts inte.
	assert_true(not sim._interrupted(e, e.attack_ability, false), "bara helningar och varslade attacker")
	assert_true(t.auras.has("torun_ready"), "beredskapen finns kvar")
	# Tystad hindrar en laddning innan den börjar och ger Vacklande när den bryter en; Torun gör inget av det.
	var m := _enemy(sim, "moss_troll")
	sim._add_aura(t, m, "silenced")
	assert_true(not sim._can_start_windup(m, "inquisitor_verdict"), "en Tystad fiende börjar ingen laddning")
	var auras: Array = _data.abilities.torun_wedge.bonus_vs.map(func(v: Dictionary) -> String: return v.aura)
	assert_true(auras == ["staggered", "troll_scorched"], "Kilslag lönar sig mot Vacklande och mot troll med Svedd hud")


func test_macro_condition_intends_heal() -> void:
	var sim := _sim()
	var e := _enemy(sim, "porridge_troll")
	e.intent = {"ability": "porridge_feed", "targets": [e.id]}
	var line := {"subject": "any_enemy", "cond": "intends_heal", "action": "ability", "ability": "torun_ready"}
	assert_eq(MacroRunner.match_line(sim, sim.unit("torun"), line), e, "makroraden hittar Grytmodern")
	e.intent = {"ability": e.attack_ability, "targets": ["paladin"]}
	assert_true(not sim.intends_heal(e))
	assert_true(MacroRunner.CONDITIONS.has("intends_heal"))
	# Startmakrot: första raden är förslaget (Run.starter_lines tar bort den tills spelaren lär sig den).
	var lines: Array = _data.macros.torun.lines
	assert_eq(lines[0].ability, "torun_ready")
	assert_eq(_data.heroes.torun.macro_hint.line.ability, "torun_ready")


func test_she_arrives_with_the_fifth_slot() -> void:
	var p := Profile.new()
	p.recruit(_data, "imma")
	assert_true(not _run.fifth_arrives(_data, p), "inte före den femte platsen")
	p.realm_depth = {"crypt": 4, "chapel": 4}
	assert_true(_run.fifth_arrives(_data, p), "hon kommer när platsen öppnas")
	assert_true(p.recruited.has("torun"), "och ansluter")
	assert_true(not _run.fifth_arrives(_data, p), "bara en gång")
	var lines: Array = _data.dialog.party_slot.torun
	assert_true(lines.any(func(l: Array) -> bool: return l[0] == "torun") and lines.any(func(l: Array) -> bool: return l[0] == "imma"))
	assert_true(not _data.realms.values().any(func(r: Dictionary) -> bool: return str(r.get("disciples", [])).find("torun") >= 0),
			"hon är ingen fånge i grottan")


func test_lines_follow_their_conditions() -> void:
	var torun: Dictionary = _data.dialog.barks.torun
	var stairs_2: Dictionary = torun.stairs.filter(func(e: Dictionary) -> bool: return e.id == "torun_stairs_2")[0]
	assert_true(not Dialog.present(_data, stairs_2, ["paladin", "torun"]), "Brokk-raden bara med Brokk")
	assert_true(Dialog.present(_data, stairs_2, ["paladin", "torun", "brokk"]))
	var fallen_2: Dictionary = torun.fallen.filter(func(e: Dictionary) -> bool: return e.id == "torun_fallen_2")[0]
	assert_true(fallen_2.text.find("{namn}") < 0, "fungerar också när Paladinen föll")
	var mountain: Array = torun.cave.filter(func(e: Dictionary) -> bool: return e.has("realm"))
	assert_eq(mountain.size(), 4)
	assert_true(mountain.any(func(e: Dictionary) -> bool: return e.text.find("torr ännu") >= 0))
	var rng := RandomNumberGenerator.new()
	for i in 40:
		rng.seed = i
		var b := Dialog.bark(_data, "cave", ["paladin", "torun"], [], rng, null, true, "crypt")
		for l in b.get("lines", []):
			assert_true(not mountain.any(func(e: Dictionary) -> bool: return e.text == l.text), "bergets rader inte i kryptan")
	var heard := false
	for i in 60:
		rng.seed = i
		var b := Dialog.bark(_data, "cave", ["paladin", "torun"], [], rng, null, true, "mountain")
		for l in b.get("lines", []):
			heard = heard or mountain.any(func(e: Dictionary) -> bool: return e.text == l.text)
	assert_true(heard, "i Trollberget hörs de")
	assert_eq(torun.interrupt.size(), 3, "avbrottets rader sägs efter striden")
	assert_true(_data.dialog.inn.torun.has("welcome"))
