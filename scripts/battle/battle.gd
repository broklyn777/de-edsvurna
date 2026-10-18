extends Node
## Den första striden. Kopplar ihop stridslogiken (CombatSim) med 3D-scenen, ljud och knappar.
## All "juice" – animationer, hitstop, skakningar, siffror, ljud – styrs härifrån utifrån
## simulatorns händelser.
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
## Spelarens senaste egenskapsval sparas här mellan försök och appstarter.
const CHOICES_PATH := "user://choices.cfg"

var data: Dictionary
var sim: CombatSim
var sfx: Sfx
var world: CryptWorld
var fx_layer: Node2D
var models := {}
var frames := {}
var buttons: Array[AbilityButton] = []
var boss_frame: BossFrame
var overlay: BattleOverlay
var pause_button: Control
var picker: TraitPicker
var telegraphs := {}
## Effekter som väntar på att vapnet ska träffa: [{left, call}].
var _later: Array[Dictionary] = []

var paused := false
var started := false
var _countdown := 3.0
var _last_count := 4
var _hitstop_until := 0
var _slowmo_until := 0
var _last_usec := 0
var _demo := false
var _demo_bot: Script
var _demo_rng := RandomNumberGenerator.new()
var _demo_reacted := {}
var _homes := {}
var _ran_in := false
var _shuffle_left := {}

## Partyt springer in från kameran när nedräkningen närmar sig noll.
const RUN_IN_FROM := Vector3(0.0, 0.0, 4.5)
const RUN_IN_TIME := 1.5
## Närstridshjältarna byter plats runt bossen med några sekunders mellanrum.
const SHUFFLE_HEROES := ["warrior", "rogue"]


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
	sfx.start_ambience("ambience_crypt", -11.0)
	_layout()
	if warp <= 0.0 and not _demo:
		_open_picker()
	if warp <= 0.0:
		for h in sim.heroes:
			models[h.id].position = _homes[h.id] + RUN_IN_FROM + Vector3(randf_range(-0.6, 0.6), 0, randf_range(0, 1.0))
	else:
		_ran_in = true
		started = true
		_countdown = 0.0
		while sim.time < warp and sim.outcome == "":
			sim.advance(1.0 / 30.0)
			_demo_act()
			sim.drain_events()
		_sync_models_after_warp()
	_last_usec = Time.get_ticks_usec()


func _build_scene() -> void:
	sfx = Sfx.new()
	add_child(sfx)
	world = CryptWorld.new()
	add_child(world)
	for u in sim.units:
		var vis: Dictionary = (data.heroes if u.team == 0 else data.bosses)[u.id].visual
		var m := UnitModel.new()
		world.add_child(m)
		m.setup(u, sim, vis)
		m.sfx = sfx
		models[u.id] = m
	for u in sim.units:
		var target := sim.boss if u.team == 0 else sim.threat_target()
		models[u.id].face(models[target.id].global_position)
		_homes[u.id] = models[u.id].position
	for hero_id in SHUFFLE_HEROES:
		_shuffle_left[hero_id] = randf_range(4.0, 7.0)

	var fx_canvas := CanvasLayer.new()
	fx_canvas.layer = 0
	add_child(fx_canvas)
	fx_layer = Node2D.new()
	fx_canvas.add_child(fx_layer)
	fx_layer.add_child(Fx.Overheads.new(sim, world, models))
	fx_layer.add_child(Fx.HealBeams.new(sim, world, models))


func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 1
	add_child(ui)
	boss_frame = BossFrame.new()
	boss_frame.setup(sim)
	ui.add_child(boss_frame)
	for h in sim.heroes:
		var f := PartyFrame.new()
		f.setup(h, sim)
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
		b.became_ready.connect(func(_id: String) -> void: sfx.play("k_ready", -9.0, 0.0))
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
	var vs := get_viewport().get_visible_rect().size
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
	if picker:
		picker.size = vs


# --- Bildruta ---------------------------------------------------------------

func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var real_dt := minf((now - _last_usec) / 1_000_000.0, 0.1)
	_last_usec = now
	if Engine.get_write_movie_path() != "":
		real_dt = _delta / maxf(Engine.time_scale, 0.0001)  # inspelning: fast bildtakt, inte väggklocka
	var now_ms := now / 1000
	if now_ms < _hitstop_until:
		Engine.time_scale = 0.04
	elif now_ms < _slowmo_until:
		Engine.time_scale = 0.3
	else:
		Engine.time_scale = 1.0

	if not started and picker == null:
		_tick_countdown(real_dt)
	elif not paused and sim.outcome == "":
		sim.advance(real_dt * Engine.time_scale)
		_demo_act()
	for e in sim.drain_events():
		_handle(e)
	_tick_later(_delta)
	_update_facing()
	_update_shuffle(_delta)
	_update_hints()
	_update_telegraphs()


func _tick_countdown(dt: float) -> void:
	_countdown -= dt
	if _countdown > 2.9 and _last_count == 4:
		sfx.say("fighter-in", 0.0, -3.0)
	if not _ran_in and _countdown <= RUN_IN_TIME + 0.1:
		_ran_in = true
		for h in sim.heroes:
			models[h.id].move_to(_homes[h.id], RUN_IN_TIME * randf_range(0.85, 1.0), true)
	var n := ceili(_countdown)
	if n != _last_count and n >= 1:
		_last_count = n
		overlay.show_big(str(n))
		sfx.play("count", -4.0, 0.0)
	if _countdown <= 0.0:
		started = true
		overlay.show_big("KÖR!")
		sfx.play("go", -2.0, 0.0)


func _update_facing() -> void:
	var tank := sim.threat_target()
	if tank:
		models[sim.boss.id].face(models[tank.id].global_position)
	for h in sim.heroes:
		if h.is_casting() and not h.cast.targets.is_empty():
			models[h.id].face(models[h.cast.targets[0]].global_position)
		else:
			models[h.id].face(models[sim.boss.id].global_position)


func _update_shuffle(delta: float) -> void:
	if not started or paused or sim.outcome != "":
		return
	var boss_pos: Vector3 = _homes[sim.boss.id]
	for hero_id in SHUFFLE_HEROES:
		var u := sim.unit(hero_id)
		var m: UnitModel = models[hero_id]
		_shuffle_left[hero_id] -= delta
		if _shuffle_left[hero_id] > 0.0 or not u.alive or u.is_casting() or m.is_moving():
			continue
		_shuffle_left[hero_id] = randf_range(5.0, 9.0)
		# Ny plats på samma avstånd från bossen, högst ~25° från startplatsen.
		var home_offset: Vector3 = _homes[hero_id] - boss_pos
		var spot := boss_pos + home_offset.rotated(Vector3.UP, randf_range(-0.45, 0.45))
		var dist := m.position.distance_to(spot)
		if dist > 0.25:
			m.move_to(spot, clampf(dist / 1.4, 0.5, 1.4), false)


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
			"pyroblast":
				b.hint = boss.auras.has("exposed")


func _update_telegraphs() -> void:
	var boss := sim.boss
	if boss.is_casting() and sim.ability(boss.cast.ability).get("telegraph", false):
		for target_id in boss.cast.targets:
			if not telegraphs.has(target_id):
				telegraphs[target_id] = world.make_telegraph(1.1)
	for unit_id in telegraphs.keys():
		var t: Node3D = telegraphs[unit_id]
		t.position = Vector3(models[unit_id].global_position.x, 0.03, models[unit_id].global_position.z)
		var k := boss.cast_progress() if boss.is_casting() else 1.0
		var fill: Node3D = t.get_node("Fill")
		fill.scale = Vector3(maxf(k, 0.02), 1, maxf(k, 0.02))


func _sync_models_after_warp() -> void:
	for u in sim.units:
		var m: UnitModel = models[u.id]
		if not u.alive:
			m.die()
		elif u.is_casting():
			m.start_cast(sim.ability(u.cast.ability).get("school", "physical"), sim.ability(u.cast.ability).get("melee", false))
		m.set_blocking(u.auras.has("shield_wall"))


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


# --- Egenskapsval före striden ------------------------------------------------

func _open_picker() -> void:
	picker = TraitPicker.new()
	picker.setup(data, data.encounters[ENCOUNTER].party, _load_choices("traits"), _load_choices("artifacts"))
	picker.tapped.connect(func() -> void: sfx.play("k_click", -8.0, 0.05))
	picker.confirmed.connect(_on_traits_chosen)
	overlay.get_parent().add_child(picker)
	picker.size = get_viewport().get_visible_rect().size


func _on_traits_chosen(traits: Dictionary, artifacts: Dictionary) -> void:
	for hero_id in traits:
		sim.unit(hero_id).traits = [traits[hero_id]]
		if artifacts.has(hero_id):
			sim.unit(hero_id).traits.append(artifacts[hero_id])
	_save_choices(traits, artifacts)
	picker.queue_free()
	picker = null
	sfx.play("k_ready", -4.0, 0.0)


func _load_choices(section: String) -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(CHOICES_PATH) != OK or not cfg.has_section(section):
		return {}
	var out := {}
	for hero_id in cfg.get_section_keys(section):
		out[hero_id] = cfg.get_value(section, hero_id, "")
	return out


func _save_choices(traits: Dictionary, artifacts: Dictionary) -> void:
	var cfg := ConfigFile.new()
	for hero_id in traits:
		cfg.set_value("traits", hero_id, traits[hero_id])
	for hero_id in artifacts:
		cfg.set_value("artifacts", hero_id, artifacts[hero_id])
	cfg.save(CHOICES_PATH)


func _on_button(ability_id: String) -> void:
	_use(ability_id, "")


func _on_frame_tapped(unit_id: String) -> void:
	_use("flash_heal", unit_id)


func _use(ability_id: String, target_id: String) -> void:
	if not started or sim.outcome != "":
		return
	var result := sim.player_use(ability_id, target_id)
	if result == "used" or result == "queued":
		sfx.play("k_click", -12.0, 0.05)
	if result == "queued":
		sfx.play("k_queued", -10.0, 0.0)


func _toggle_pause() -> void:
	if sim.outcome != "" or picker:
		return
	paused = not paused
	overlay.paused = paused
	pause_button.paused = paused
	world.process_mode = Node.PROCESS_MODE_DISABLED if paused else Node.PROCESS_MODE_INHERIT
	if paused:
		for m in models.values():
			m.stop_cast_sound()


func _exit_tree() -> void:
	UnitModel.free_shared()


func _restart() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


# --- Händelser → känsla -----------------------------------------------------

func _handle(e: Dictionary) -> void:
	match e.type:
		"cast_start":
			_on_cast_start(e)
		"cast_end":
			if e.result == "interrupted" and e.has("by"):
				_after(models[e.by].last_impact_delay, _on_cast_end.bind(e))
			else:
				_on_cast_end(e)
		"ability_used":
			_on_ability_used(e)
		"projectile":
			var ab := sim.ability(e.ability)
			var color := UiStyle.school_color(ab.get("school", "physical"))
			var big: bool = e.ability == "pyroblast"
			fx_layer.add_child(Fx.Projectile.new(_pos(e.source), _pos(e.target), e.travel, color, 14.0 if big else 7.0))
		"swing":
			models[e.unit].attack(models[e.target].global_position, 0.35 if e.unit == sim.boss.id else 0.25)
		"damage":
			_after(_impact_delay(e), _on_damage.bind(e))
		"heal":
			_on_heal(e)
		"aura_applied":
			if e.aura == "shield_wall":
				models[e.unit].set_blocking(true)
			elif e.aura == "exposed":
				_after(_pending_delay() + 0.1, _on_exposed.bind(e.unit))
			elif e.aura == "frenzy":
				sfx.play("frenzy", 0.0, 0.0)
				world.add_shake(10.0)
		"aura_removed":
			if e.aura == "shield_wall":
				models[e.unit].set_blocking(false)
		"death":
			_after(_pending_delay(), _on_death.bind(e.unit))
		"error":
			for b in buttons:
				if b.ability_id == e.ability:
					b.refuse()
			sfx.play("k_error", -6.0, 0.0)
			overlay.message(ERROR_TEXT.get(e.reason, e.reason))
		"announce":
			overlay.announce(e.text)
		"trait":
			# Efter vapenträffen som satte igång egenskapen, inte före.
			_after(_pending_delay(), _on_trait.bind(e))
		"outcome":
			_after(_pending_delay(), _on_outcome.bind(e.result))


func _on_cast_start(e: Dictionary) -> void:
	var ab := sim.ability(e.ability)
	var m: UnitModel = models[e.unit]
	var school: String = ab.get("school", "physical")
	m.start_cast(school, ab.get("melee", false))
	m.start_cast_sound(sfx.stream("cast_" + school))
	if e.ability == "pyroblast" and e.by_player:
		sfx.say("wizard-eld", 30.0, -2.0)
	if e.unit == sim.boss.id:
		world.add_shake(3.0)


func _on_cast_end(e: Dictionary) -> void:
	var m: UnitModel = models[e.unit]
	m.stop_cast_sound()
	m.end_cast(e.result == "success")
	if e.unit == sim.boss.id and e.result != "success":
		_clear_telegraphs()
	if e.result == "interrupted":
		var ab := sim.ability(e.ability)
		sfx.play("k_interrupt", 0.0, 0.05)
		sfx.play("k_kick", -2.0, 0.05)
		sfx.play("interrupt", -6.0, 0.03)
		boss_frame.on_interrupted(ab.name)
		var p := _pos(e.unit)
		fx_layer.add_child(_at(Fx.Sparks.new(Color("#d6b4ff"), 22, 380.0, 0.5), p))
		fx_layer.add_child(_at(Fx.Ring.new(Color("#ffe066"), 30, 140, 0.4, 8.0), p))
		_float(e.unit, "AVBRUTEN!", Color("#ffe066"), 34, true)
		m.hit(1.5)
		_hitstop(90)
		world.add_shake(6.0)


func _on_ability_used(e: Dictionary) -> void:
	var ab := sim.ability(e.ability)
	var p := _pos(e.unit)
	match e.ability:
		"shield_wall":
			sfx.play("k_shield_wall", -1.0, 0.03)
			sfx.play("shield_wall", -8.0)
			fx_layer.add_child(_at(Fx.Ring.new(Color("#bcd2ff"), 20, 110, 0.45, 8.0, true), p))
			world.add_shake(4.0)
		"bloodlust":
			sfx.play("bloodlust", 0.0, 0.0)
			for h in sim.heroes:
				if h.alive:
					fx_layer.add_child(_at(Fx.Ring.new(Color("#ff5a2a"), 10, 80, 0.6, 7.0, true), _pos(h.id)))
			overlay.announce("BLOODLUST!")
			world.add_shake(7.0)
		"kick":
			sfx.play("kick", -4.0)
			models[e.unit].kick(models[e.targets[0]].global_position)
		"renew":
			sfx.play("renew", -10.0)
			fx_layer.add_child(_at(Fx.Ring.new(UiStyle.school_color("heal"), 8, 46, 0.4, 4.0), _pos(e.targets[0])))
		_:
			if ab.get("melee", false) and not e.targets.is_empty():
				models[e.unit].attack(models[e.targets[0]].global_position, 0.3)


func _on_damage(e: Dictionary) -> void:
	if data.auras.has(e.ability):  # skada över tid (gift, eld): små siffror, ingen träffreaktion
		_float(e.target, str(int(e.amount)), UiStyle.school_color(e.school), 17, false)
		if sim.unit(e.target).team != 0:
			boss_frame.on_damage()
		return
	var target: UnitModel = models[e.target]
	var p := _pos(e.target)
	var crit: bool = e.crit
	var heavy: bool = e.ability in ["bone_crush", "pyroblast"]
	target.hit(2.0 if heavy else (1.4 if crit else 1.0), models[e.source].global_position)
	var color := UiStyle.school_color(e.school)
	var on_hero: bool = sim.unit(e.target).team == 0
	if on_hero:
		color = Color("#ff5a4a") if e.school == "physical" else color.lerp(Color("#ff5a4a"), 0.3)
	var size := 34 if heavy else (32 if crit else (20 if on_hero else 24))
	_float(e.target, str(int(e.amount)) + ("!" if crit else ""), color, size, crit or heavy)

	if on_hero:
		frames[e.target].on_damage(e.amount)
	else:
		boss_frame.on_damage()

	match e.ability:
		"melee":
			if e.source == sim.boss.id:
				sfx.play("k_boss_hit", -2.0, 0.08)
				sfx.play("boss_swing", -10.0)
				world.add_shake(2.0)
			else:
				sfx.play("k_hero_crit" if crit else "k_hero_hit", -3.0 if crit else -8.0, 0.1)
		"bone_crush":
			sfx.play("bone_crush", 0.0, 0.0)
			sfx.play("k_bone_crack", 2.0, 0.04)
			if e.target == "warrior" and not sim.unit("warrior").auras.has("shield_wall"):
				sfx.say("fighter-traff", 15.0)
			fx_layer.add_child(_at(Fx.Ring.new(Color("#ff3b2e"), 20, 170, 0.5, 12.0, true), p))
			fx_layer.add_child(_at(Fx.Sparks.new(Color("#e8dcc8"), 26, 420.0, 0.55), p))
			_clear_telegraphs()
			_hitstop(130)
			world.add_shake(18.0)
		"pyroblast":
			sfx.play("pyro_impact", 1.0)
			fx_layer.add_child(_at(Fx.Ring.new(Color("#ff8a2a"), 20, 160, 0.5, 10.0, true), p))
			fx_layer.add_child(_at(Fx.Sparks.new(Color("#ffb347"), 30, 460.0, 0.6), p))
			_hitstop(110 if crit else 70)
			world.add_shake(12.0 if crit else 8.0)
		_:
			var ab: Dictionary = data.abilities.get(e.ability, {})
			sfx.play(ab.get("sound", "k_hero_hit"), -6.0 if not crit else -1.0, 0.08)
			fx_layer.add_child(_at(Fx.Ring.new(color, 6, 46 if crit else 32, 0.3, 5.0), p))
			if ab.get("melee", false):
				fx_layer.add_child(_at(Fx.Sparks.new(color, 8, 220.0, 0.3), p))
	if crit and not heavy:
		_hitstop(45)
		world.add_shake(3.0)


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
		models[e.target].flash_color(UiStyle.school_color("heal"))
		fx_layer.add_child(_at(Fx.Ring.new(UiStyle.school_color("heal"), 10, 70, 0.45, 5.0, true), p))
		fx_layer.add_child(_at(Fx.Sparks.new(Color("#b8ffbf"), 10, 140.0, 0.5), p))


## En egenskap slog till: namnet lyser upp över hjälten och i raidramen.
func _on_trait(e: Dictionary) -> void:
	var t: Dictionary = data.traits[e.trait]
	frames[e.unit].on_trait()
	if t.get("quiet", false):
		return
	_float(e.unit, t.name.to_upper(), UiStyle.TRAIT_GOLD, 22, true)
	sfx.play("k_ready", -4.0, 0.1)
	fx_layer.add_child(_at(Fx.Ring.new(UiStyle.TRAIT_GOLD, 12, 70, 0.4, 5.0), _pos(e.unit)))


func _on_exposed(unit_id: String) -> void:
	var p := _pos(unit_id)
	fx_layer.add_child(_at(Fx.Ring.new(UiStyle.TRAIT_GOLD, 30, 190, 0.55, 9.0), p))
	fx_layer.add_child(_at(Fx.Sparks.new(UiStyle.TRAIT_GOLD, 18, 320.0, 0.5), p))
	_after(0.6, _float.bind(unit_id, "BLOTTAD!", UiStyle.TRAIT_GOLD, 30, true))


func _on_death(unit_id: String) -> void:
	sfx.play("death", -2.0)
	_float(unit_id, "DÖD", Color(0.8, 0.8, 0.8), 26, false)
	models[unit_id].die()
	_hitstop(70)


func _on_outcome(result: String) -> void:
	for m in models.values():
		m.stop_cast_sound()
		m.end_cast(false)
	_clear_telegraphs()
	var alive := sim.heroes.filter(func(h: CombatUnit) -> bool: return h.alive).size()
	if result == "victory":
		_slowmo_until = Time.get_ticks_msec() + 1600
		sfx.play("victory", 0.0, 0.0)
		get_tree().create_timer(1.6, true, false, true).timeout.connect(sfx.say.bind("fighter-seger"))
		world.add_shake(14.0)
		var p := _pos(sim.boss.id)
		fx_layer.add_child(_at(Fx.Ring.new(Color("#cbbfe6"), 40, 320, 1.2, 14.0, true), p))
		fx_layer.add_child(_at(Fx.Sparks.new(Color("#e8dcc8"), 40, 520.0, 1.0), p))
		overlay.set_result("victory", "Tid %d:%02d   ·   %d av 4 överlevde" % [int(sim.time) / 60, int(sim.time) % 60, alive])
	else:
		sfx.play("defeat", 0.0, 0.0)
		overlay.set_result("defeat", "Bone Lich hade %d%% kvar" % ceili(sim.boss.hp_pct() * 100.0))


# --- Hjälpfunktioner --------------------------------------------------------

## Skärmposition för en enhets bröst (där siffror, projektiler och ringar utgår).
func _pos(unit_id: String) -> Vector2:
	return world.project(models[unit_id].chest_position())


func _at(node: Node2D, p: Vector2) -> Node2D:
	node.position = p
	return node


func _float(unit_id: String, text: String, color: Color, size: int, big: bool) -> void:
	# Bossen är så lång att huvudet hamnar vid bossramen – siffrorna utgår från bröstet i stället.
	var anchor: Vector3 = models[unit_id].chest_position() if unit_id == sim.boss.id else models[unit_id].head_position()
	var p := world.project(anchor) + Vector2(randf_range(-14, 14), -30)
	fx_layer.add_child(_at(Fx.FloatingText.new(text, color, size, big, 1.1 if big else 0.9), p))


## Hur länge träffeffekterna ska vänta så att de sammanfaller med att vapnet når fram.
func _impact_delay(e: Dictionary) -> float:
	if e.ability == "bone_crush":
		return 0.08
	var melee: bool = e.ability == "melee" or data.abilities.get(e.ability, {}).get("melee", false)
	return models[e.source].last_impact_delay if melee else 0.0


func _after(delay: float, call: Callable) -> void:
	if delay <= 0.0:
		call.call()
	else:
		_later.append({"left": delay, "call": call})


func _pending_delay() -> float:
	var longest := 0.0
	for item in _later:
		longest = maxf(longest, item.left)
	return longest + (0.01 if longest > 0.0 else 0.0)


func _tick_later(delta: float) -> void:
	if paused or _later.is_empty():
		return
	for item in _later.duplicate():
		item.left -= delta
		if item.left <= 0.0:
			_later.erase(item)
			item.call.call()


func _hitstop(ms: int) -> void:
	_hitstop_until = maxi(_hitstop_until, Time.get_ticks_msec() + ms)


func _clear_telegraphs() -> void:
	for t in telegraphs.values():
		t.queue_free()
	telegraphs.clear()


func _demo_act() -> void:
	if _demo and sim.outcome == "":
		_demo_bot._act(sim, 1, _demo_rng, _demo_reacted)
