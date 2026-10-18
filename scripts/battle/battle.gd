extends Node2D
## Den första striden. Kopplar ihop stridslogiken (CombatSim) med grafik, ljud och knappar.
## All "juice" – hitstop, skakningar, siffror, ljud – styrs härifrån utifrån simulatorns händelser.
##
## Utvecklarargument (efter `--`):
##   --demo        en inbyggd bot spelar striden
##   --warp=<s>    spola fram så många sekunder innan bilden visas
##   --seed=<n>    fast slumpfrö

const ENCOUNTER := "bone_lich"
const ERROR_TEXT := {
	"cooldown": "Inte redo än",
	"mana": "Inte tillräckligt med mana",
	"dead": "Hjälten har stupat",
	"nothing_to_interrupt": "Inget att avbryta",
}
const BOT_PATH := "res://tests/combat_bot.gd"
## Förstoring av spelplanen så att figurerna syns ordentligt på en telefon.
const WORLD_SCALE := 1.3

var data: Dictionary
var sim: CombatSim
var sfx: Sfx
var world: Node2D
var units_layer: Node2D
var fx_layer: Node2D
var views := {}
var frames := {}
var buttons: Array[AbilityButton] = []
var boss_frame: BossFrame
var overlay: BattleOverlay
var pause_button: Control
var telegraphs := {}

var paused := false
var started := false
var _countdown := 3.0
var _last_count := 4
var _shake := 0.0
var _hitstop_until := 0
var _slowmo_until := 0
var _last_usec := 0
var _demo := false
var _demo_bot: Script
var _demo_rng := RandomNumberGenerator.new()
var _demo_reacted := {}


func _ready() -> void:
	Engine.time_scale = 1.0
	data = GameData.load_all()
	var seed_value := randi()
	var warp := 0.0
	for arg in OS.get_cmdline_user_args():
		if arg == "--demo":
			_demo = true
		elif arg.begins_with("--warp="):
			warp = float(arg.get_slice("=", 1))
		elif arg.begins_with("--seed="):
			seed_value = int(arg.get_slice("=", 1))
	sim = CombatSim.create(data, ENCOUNTER, seed_value)
	if _demo:
		_demo_bot = load(BOT_PATH)
	_build_scene()
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()
	if warp > 0.0:
		started = true
		_countdown = 0.0
		while sim.time < warp and sim.outcome == "":
			sim.advance(1.0 / 30.0)
			_demo_act()
			sim.drain_events()
	_last_usec = Time.get_ticks_usec()


func _build_scene() -> void:
	sfx = Sfx.new()
	add_child(sfx)
	world = Node2D.new()
	world.scale = Vector2.ONE * WORLD_SCALE
	add_child(world)
	world.add_child(preload("res://scripts/battle/arena.gd").new())
	units_layer = Node2D.new()
	units_layer.y_sort_enabled = true
	world.add_child(units_layer)
	fx_layer = Node2D.new()
	fx_layer.z_index = 10
	world.add_child(fx_layer)
	for u in sim.units:
		var v := UnitView.new()
		v.setup(u, sim)
		units_layer.add_child(v)
		views[u.id] = v


func _build_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	boss_frame = BossFrame.new()
	boss_frame.setup(sim)
	ui.add_child(boss_frame)
	for h in sim.heroes:
		var f := PartyFrame.new()
		f.setup(h)
		f.tapped.connect(_on_frame_tapped)
		ui.add_child(f)
		frames[h.id] = f
	var keys := ["1", "2", "3", "4", "5"]
	var ids: Array = data.encounters[ENCOUNTER].buttons
	for i in ids.size():
		var b := AbilityButton.new()
		var ab := sim.ability(ids[i])
		b.setup(ids[i], ab, sim.unit(ab.owner), keys[i] if i < keys.size() else "")
		b.activated.connect(_on_button)
		b.became_ready.connect(func(_id: String) -> void: sfx.play("ready", -12.0, 0.0))
		ui.add_child(b)
		buttons.append(b)
	pause_button = preload("res://scripts/battle/pause_button.gd").new()
	pause_button.toggled_pause.connect(_toggle_pause)
	ui.add_child(pause_button)
	overlay = BattleOverlay.new()
	overlay.restart_requested.connect(_restart)
	ui.add_child(overlay)
	overlay.mode = "countdown"


func _layout() -> void:
	var vs := get_viewport_rect().size
	boss_frame.position = Vector2((vs.x - boss_frame.size.x) / 2.0, 10)
	var y := 12.0
	for h in sim.heroes:
		frames[h.id].position = Vector2(12, y)
		y += frames[h.id].size.y + 8
	# Två defensiva knappar för vänster tumme, tre för höger.
	var bs := buttons[0].size
	for i in buttons.size():
		var pos: Vector2
		if i < 2:
			pos = Vector2(14 + i * (bs.x + 6), vs.y - bs.y - 12)
		else:
			var j := buttons.size() - 1 - i
			pos = Vector2(vs.x - 14 - (j + 1) * bs.x - j * 6, vs.y - bs.y - 12)
		buttons[i].position = pos
	pause_button.position = Vector2(vs.x - 76, 12)
	overlay.size = vs


# --- Bildruta ---------------------------------------------------------------

func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var real_dt := minf((now - _last_usec) / 1_000_000.0, 0.1)
	_last_usec = now
	var now_ms := now / 1000
	if now_ms < _hitstop_until:
		Engine.time_scale = 0.04
	elif now_ms < _slowmo_until:
		Engine.time_scale = 0.3
	else:
		Engine.time_scale = 1.0

	if not started:
		_tick_countdown(real_dt)
	elif not paused and sim.outcome == "":
		sim.advance(real_dt * Engine.time_scale)
		_demo_act()
	for e in sim.drain_events():
		_handle(e)
	_update_hints()
	_update_telegraphs()

	_shake = maxf(0.0, _shake - real_dt * 40.0)
	var vs := get_viewport_rect().size
	world.position = Vector2(vs.x * 0.5 + 40, vs.y * 0.5 + 35) + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
	queue_redraw()


func _draw() -> void:
	draw_rect(get_viewport_rect(), Color(0.035, 0.03, 0.05))


func _tick_countdown(dt: float) -> void:
	_countdown -= dt
	var n := ceili(_countdown)
	if n != _last_count and n >= 1:
		_last_count = n
		overlay.show_big(str(n))
		sfx.play("count", -4.0, 0.0)
	if _countdown <= 0.0:
		started = true
		overlay.show_big("KÖR!")
		sfx.play("go", -2.0, 0.0)


func _update_hints() -> void:
	var boss := sim.boss
	var casting: String = boss.cast.get("ability", "")
	var crush_on_tank: bool = casting == "bone_crush" and boss.cast.targets.has("warrior")
	var someone_low := sim.heroes.any(func(h: CombatUnit) -> bool: return h.alive and h.hp_pct() < 0.4)
	for b in buttons:
		match b.ability_id:
			"kick":
				b.hint = casting == "shadow_bolt_volley"
			"shield_wall":
				b.hint = crush_on_tank
			"flash_heal":
				b.hint = someone_low
			"bloodlust":
				b.hint = started and sim.time < 15.0


func _update_telegraphs() -> void:
	var boss := sim.boss
	if boss.is_casting() and sim.ability(boss.cast.ability).get("telegraph", false):
		for target_id in boss.cast.targets:
			if not telegraphs.has(target_id):
				var t := Fx.Telegraph.new(78.0)
				world.add_child(t)
				world.move_child(t, 1)
				telegraphs[target_id] = t
	for unit_id in telegraphs.keys():
		var t: Fx.Telegraph = telegraphs[unit_id]
		t.position = views[unit_id].position
		t.progress = sim.boss.cast_progress() if sim.boss.is_casting() else 1.0


# --- Inmatning --------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
				var i: int = event.keycode - KEY_1
				if i < buttons.size():
					buttons[i].press()
			KEY_SPACE:
				_toggle_pause()
			KEY_R:
				_restart()


func _on_button(ability_id: String) -> void:
	_use(ability_id, "")


func _on_frame_tapped(unit_id: String) -> void:
	_use("flash_heal", unit_id)


func _use(ability_id: String, target_id: String) -> void:
	if not started or sim.outcome != "":
		return
	var result := sim.player_use(ability_id, target_id)
	if result == "queued":
		sfx.play("queued", -14.0, 0.0)


func _toggle_pause() -> void:
	if sim.outcome != "":
		return
	paused = not paused
	overlay.paused = paused
	pause_button.paused = paused
	for v in views.values():
		v.process_mode = Node.PROCESS_MODE_DISABLED if paused else Node.PROCESS_MODE_INHERIT
		if paused:
			v.stop_cast_sound()


func _restart() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


# --- Händelser → känsla -----------------------------------------------------

func _handle(e: Dictionary) -> void:
	match e.type:
		"cast_start":
			_on_cast_start(e)
		"cast_end":
			_on_cast_end(e)
		"ability_used":
			_on_ability_used(e)
		"projectile":
			var ab := sim.ability(e.ability)
			var color := UiStyle.school_color(ab.get("school", "physical"))
			var big: bool = e.ability == "pyroblast"
			var p := Fx.Projectile.new(_pos(e.source) + Vector2(0, -10), _pos(e.target), e.travel, color, 14.0 if big else 7.0)
			fx_layer.add_child(p)
		"swing":
			var src: UnitView = views[e.unit]
			src.lunge(_pos(e.target), 26.0 if e.unit == sim.boss.id else 16.0)
		"damage":
			_on_damage(e)
		"heal":
			_on_heal(e)
		"aura_applied":
			if e.aura == "frenzy":
				sfx.play("frenzy", 0.0, 0.0)
				_add_shake(10.0)
		"death":
			sfx.play("death", -2.0)
			_float(e.unit, "DÖD", Color(0.8, 0.8, 0.8), 26, false)
			views[e.unit].stop_cast_sound()
			_hitstop(70)
		"queued":
			pass
		"error":
			for b in buttons:
				if b.ability_id == e.ability:
					b.refuse()
			sfx.play("ui_error", -6.0, 0.0)
			overlay.message(ERROR_TEXT.get(e.reason, e.reason))
		"announce":
			overlay.announce(e.text)
		"outcome":
			_on_outcome(e.result)


func _on_cast_start(e: Dictionary) -> void:
	var ab := sim.ability(e.ability)
	var v: UnitView = views[e.unit]
	v.start_cast_sound(sfx.stream("cast_" + ab.get("school", "physical")))
	if e.unit == sim.boss.id:
		_add_shake(3.0)


func _on_cast_end(e: Dictionary) -> void:
	var v: UnitView = views[e.unit]
	v.stop_cast_sound()
	if e.unit == sim.boss.id and e.result != "success":
		_clear_telegraphs()
	if e.result == "interrupted":
		var ab := sim.ability(e.ability)
		sfx.play("interrupt", 2.0, 0.03)
		boss_frame.on_interrupted(ab.name)
		var p := _pos(e.unit)
		fx_layer.add_child(_at(Fx.Sparks.new(Color("#d6b4ff"), 22, 380.0, 0.5), p))
		fx_layer.add_child(_at(Fx.Ring.new(Color("#ffe066"), 30, 140, 0.4, 8.0), p))
		_float(e.unit, "AVBRUTEN!", Color("#ffe066"), 34, true)
		_hitstop(90)
		_add_shake(6.0)


func _on_ability_used(e: Dictionary) -> void:
	var ab := sim.ability(e.ability)
	var p := _pos(e.unit)
	match e.ability:
		"shield_wall":
			sfx.play("shield_wall", 0.0)
			fx_layer.add_child(_at(Fx.Ring.new(Color("#bcd2ff"), 20, 90, 0.45, 8.0, true), p))
			_add_shake(4.0)
		"bloodlust":
			sfx.play("bloodlust", 0.0, 0.0)
			for h in sim.heroes:
				if h.alive:
					fx_layer.add_child(_at(Fx.Ring.new(Color("#ff5a2a"), 10, 70, 0.6, 7.0, true), _pos(h.id)))
			overlay.announce("BLOODLUST!")
			_add_shake(7.0)
		"kick":
			sfx.play("kick", 0.0)
			views[e.unit].lunge(_pos(e.targets[0]), 22.0)
		"renew":
			sfx.play("renew", -10.0)
			fx_layer.add_child(_at(Fx.Ring.new(UiStyle.school_color("heal"), 8, 40, 0.4, 4.0), _pos(e.targets[0])))
		_:
			if ab.get("melee", false) and not e.targets.is_empty():
				views[e.unit].lunge(_pos(e.targets[0]), 20.0)


func _on_damage(e: Dictionary) -> void:
	var target: UnitView = views[e.target]
	var src_pos := _pos(e.source)
	var p := _pos(e.target)
	var crit: bool = e.crit
	var heavy: bool = e.ability in ["bone_crush", "pyroblast"]
	target.hit(2.0 if heavy else (1.4 if crit else 1.0), src_pos)
	var color := UiStyle.school_color(e.school)
	var on_hero: bool = sim.unit(e.target).team == 0
	if on_hero:
		color = Color("#ff5a4a") if e.school == "physical" else color.lerp(Color("#ff5a4a"), 0.3)
	var size := 34 if heavy else (32 if crit else (20 if on_hero else 24))
	var label := str(int(e.amount)) + ("!" if crit else "")
	_float(e.target, label, color, size, crit or heavy)

	if on_hero:
		frames[e.target].on_damage(e.amount)
	else:
		boss_frame.on_damage()

	match e.ability:
		"melee":
			if e.source == sim.boss.id:
				sfx.play("boss_swing", -3.0)
			else:
				sfx.play("melee_crit" if crit else "melee_hit", -9.0 if not crit else -4.0, 0.1)
		"bone_crush":
			sfx.play("bone_crush", 2.0, 0.0)
			fx_layer.add_child(_at(Fx.Ring.new(Color("#ff3b2e"), 20, 160, 0.5, 12.0, true), p))
			fx_layer.add_child(_at(Fx.Sparks.new(Color("#e8dcc8"), 26, 420.0, 0.55), p))
			_clear_telegraphs()
			_hitstop(130)
			_add_shake(18.0)
		"pyroblast":
			sfx.play("pyro_impact", 1.0)
			fx_layer.add_child(_at(Fx.Ring.new(Color("#ff8a2a"), 20, 150, 0.5, 10.0, true), p))
			fx_layer.add_child(_at(Fx.Sparks.new(Color("#ffb347"), 30, 460.0, 0.6), p))
			_hitstop(110 if crit else 70)
			_add_shake(12.0 if crit else 8.0)
		_:
			var ab := sim.ability(e.ability)
			sfx.play(ab.get("sound", "melee_hit"), -6.0 if not crit else -1.0, 0.08)
			fx_layer.add_child(_at(Fx.Ring.new(color, 6, 46 if crit else 32, 0.3, 5.0), p))
			if ab.get("melee", false):
				fx_layer.add_child(_at(Fx.Sparks.new(color, 8, 220.0, 0.3), p))
	if crit and not heavy:
		_hitstop(45)
		_add_shake(3.0)


func _on_heal(e: Dictionary) -> void:
	var p := _pos(e.target)
	var is_hot: bool = e.ability == "renew"
	if e.effective <= 0.0 and is_hot:
		return
	var size := 18 if is_hot else (30 if e.crit else 24)
	_float(e.target, "+" + str(int(e.effective)) + ("!" if e.crit else ""), UiStyle.school_color("heal"), size, e.crit)
	frames[e.target].on_heal()
	if not is_hot:
		sfx.play("heal", -5.0, 0.03)
		fx_layer.add_child(_at(Fx.Ring.new(UiStyle.school_color("heal"), 10, 60, 0.45, 5.0, true), p))
		fx_layer.add_child(_at(Fx.Sparks.new(Color("#b8ffbf"), 10, 140.0, 0.5), p))


func _on_outcome(result: String) -> void:
	for v in views.values():
		v.stop_cast_sound()
	_clear_telegraphs()
	var alive := sim.heroes.filter(func(h: CombatUnit) -> bool: return h.alive).size()
	if result == "victory":
		_slowmo_until = Time.get_ticks_msec() + 1600
		sfx.play("victory", 0.0, 0.0)
		_add_shake(14.0)
		var p := _pos(sim.boss.id)
		fx_layer.add_child(_at(Fx.Ring.new(Color("#cbbfe6"), 40, 320, 1.2, 14.0, true), p))
		fx_layer.add_child(_at(Fx.Sparks.new(Color("#e8dcc8"), 40, 520.0, 1.0), p))
		overlay.set_result("victory", "Tid %d:%02d   ·   %d av 4 överlevde" % [int(sim.time) / 60, int(sim.time) % 60, alive])
	else:
		sfx.play("defeat", 0.0, 0.0)
		overlay.set_result("defeat", "Bone Lich hade %d%% kvar" % ceili(sim.boss.hp_pct() * 100.0))


# --- Hjälpfunktioner --------------------------------------------------------

func _pos(unit_id: String) -> Vector2:
	return views[unit_id].position


func _at(node: Node2D, p: Vector2) -> Node2D:
	node.position = p
	return node


func _float(unit_id: String, text: String, color: Color, size: int, big: bool) -> void:
	var u := sim.unit(unit_id)
	var p := _pos(unit_id) + Vector2(randf_range(-14, 14), -u.radius - 22)
	fx_layer.add_child(_at(Fx.FloatingText.new(text, color, size, big, 1.1 if big else 0.9), p))


func _hitstop(ms: int) -> void:
	_hitstop_until = maxi(_hitstop_until, Time.get_ticks_msec() + ms)


func _add_shake(amount: float) -> void:
	_shake = minf(24.0, maxf(_shake, amount))


func _clear_telegraphs() -> void:
	for t in telegraphs.values():
		t.queue_free()
	telegraphs.clear()


func _demo_act() -> void:
	if _demo and sim.outcome == "":
		_demo_bot._act(sim, 1, _demo_rng, _demo_reacted)
