extends Node
## Autoload "Run": håller den pågående körningen mellan scenerna och profilen som varar mellan
## körningarna (silver, samlingen, artefakter – se Profile).
##
## Flöde: basen → Kryptporten → strid → läger → … → basen (förlust eller sista våningen).
## Övningsgården: basen → övning → strid → övningen (med makrologgen kvar).

const PROGRESS_PATH := "user://progress.cfg"
const MACROS_PATH := "user://macros.json"
const BASE_SCENE := "res://scenes/base.tscn"
const START_SCENE := "res://scenes/start.tscn"
const PRACTICE_SCENE := "res://scenes/practice.tscn"
const SMITH_SCENE := "res://scenes/smith.tscn"
const LIBRARY_SCENE := "res://scenes/library.tscn"
const ALTAR_SCENE := "res://scenes/altar.tscn"
const BATTLE_SCENE := "res://scenes/main.tscn"
const CAMP_SCENE := "res://scenes/camp.tscn"
const MACRO_SCENE := "res://scenes/macros.tscn"
const CAMPAIGN_SCENE := "res://scenes/campaign.tscn"
const ROOM_MAP_SCENE := "res://scenes/room_map.tscn"
## Den pågående körningen sparas efter varje rum, så att den överlever att appen stängs (0.18).
const RUN_PATH := "user://run.cfg"

var data: Dictionary
var state := RunState.new()
## Senast vunna stridens kvitto och troféerbjudande (visas i lägret).
var last_receipt: Array[String] = []
var offer: Array[String] = []
var rng := RandomNumberGenerator.new()
var profile := Profile.new()
## Samma lista som profile.collection.
var collection: Array[String] = []
## Silver från senaste striden (visas i lägret och i basen).
var last_silver := 0
## Makrologgen från senaste övningsstriden: [{text, ok, skipped}].
var practice_log: Array[Dictionary] = []
var practice_encounter := "crypt_1"
## Spelarens makron: macro_id -> {name, lines}. Sparas mellan körningar.
var macros := {}
## hero_id -> macro_id, och hero_id -> "macro" eller "manual" (standardhandling).
var assignment := {}
var default_action := {}
## Scenen makroredigeraren går tillbaka till.
var macro_return := BASE_SCENE
## Trofén som är vald i lägret (finns kvar om man går till makroredigeraren och tillbaka).
var camp_chosen := ""
## Våningsreglerna för nästa körning, slumpade vid Kryptporten när instabiliteten väljs:
## {visible: [regel], hidden: [regel]}.
var pending_rules := {"visible": [], "hidden": []}
## Trofén som tas med från samlingen in i nästa körning (Förberedelser): {trophy, wearer}.
var pending_trophy := {}
## Questens belöning om den blev klar i senaste rummet: {silver, point} (visas i lägret).
var quest_reward := {}
## Text om vad som hände i senaste rummet utanför striderna (visas på rumskartan).
var room_result := ""
## Musik och menyljud, som fortsätter mellan scenerna (striden har egna effektljud).
var audio: Sfx
var _ui_frame := -1


func _ready() -> void:
	data = GameData.load_all()
	rng.randomize()
	audio = Sfx.new()
	add_child(audio)
	_load()
	_load_macros()
	roll_rules()
	_dev_args()
	if OS.get_cmdline_user_args().is_empty():
		_resume_run()


## Utvecklarargument (efter `--`): --floor=<n> startar striden på våning n (0–2), --depth=<n> väljer
## djup, --camp visar lägret efter första striden.
func _dev_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--floor="):
			state.floor = int(arg.get_slice("=", 1))
			state.fill_charges(data)
			get_tree().change_scene_to_file.call_deferred(BATTLE_SCENE)
		elif arg.begins_with("--artifact="):
			# --artifact=<hjälte>:<typ>:<förmåga>, t.ex. brokk:shield:healing_light (bara den här körningen)
			var parts := arg.get_slice("=", 1).split(":")
			state.artifacts[parts[0]] = {"type": parts[1], "ability": parts[2] if parts.size() > 2 else ""}
		elif arg == "--anoint":
			# --anoint låser upp den lånade perken (som om Benfursten var besegrad) och visar valet
			profile.defeat_boss("bone_lich")
			get_tree().change_scene_to_file.call_deferred(ALTAR_SCENE)
		elif arg.begins_with("--instability="):
			# --instability=<n> slumpar n synliga och n dolda våningsregler (bara den här körningen)
			state.instability = clampi(int(arg.get_slice("=", 1)), 0, RunState.MAX_INSTABILITY)
			var rolled := RunState.roll_rules(data, state.instability, rng)
			state.rules_visible = rolled.visible
			state.rules_hidden = rolled.hidden
			profile.instability = state.instability
			pending_rules = rolled
		elif arg.begins_with("--rules="):
			# --rules=a,b gör reglerna synliga i den här körningen (för test)
			state.rules_visible = Array(arg.get_slice("=", 1).split(","))
		elif arg.begins_with("--realm="):
			# --realm=chapel spelar i Det fördärvade kapellet (bara den här körningen)
			state.set_realm(data, arg.get_slice("=", 1))
			profile.realm = state.realm
		elif arg.begins_with("--depth="):
			# --depth=<n> spelar på djup n (bara den här körningen)
			state.depth = maxi(1, int(arg.get_slice("=", 1)))
		elif arg == "--map":
			# --map startar en ny körning och visar rumskartan (med --realm, --depth, --instability före)
			var keep_realm := state.realm
			state = RunState.new_run(profile, data)
			state.set_realm(data, keep_realm)
			state.start_expedition(data, 7)
			get_tree().change_scene_to_file.call_deferred(ROOM_MAP_SCENE)
		elif arg == "--macros":
			get_tree().change_scene_to_file.call_deferred(MACRO_SCENE)
		elif arg.begins_with("--oath="):
			# --oath=<kall> väljer kall för den här körningen; med --all-perks får den alla perks (bara för test)
			state.oath = arg.get_slice("=", 1)
			state.perks = []
			if OS.get_cmdline_user_args().has("--all-perks"):
				for p in data.oaths[state.oath].perks:
					state.perks.append(p.id)
		elif arg in ["--practice", "--smith", "--library", "--gate", "--altar", "--prep"]:
			var scene: String = {"--practice": PRACTICE_SCENE, "--smith": SMITH_SCENE,
					"--library": LIBRARY_SCENE, "--gate": CAMPAIGN_SCENE, "--altar": ALTAR_SCENE, "--prep": START_SCENE}[arg]
			get_tree().change_scene_to_file.call_deferred(scene)
		elif arg == "--camp":
			offer = state.trophy_offer(data, rng)
			last_receipt = ["Domens kall (Paladinen): slog till 7 gånger – 312 skada"]
			get_tree().change_scene_to_file.call_deferred(CAMP_SCENE)


## Kallet väljs vid Kallets altare (profile.oath), sällskapet vid Kryptporten.
## Slumpar nya våningsregler för vald instabilitet (visas vid Kryptporten).
func roll_rules() -> void:
	pending_rules = RunState.roll_rules(data, profile.instability, rng)


## Menyljud (assets/audio/ui_*). Ett tryck som inte gav något eget ljud får ui_tap (se ui_tap()).
func ui(sound: String, volume_db := -10.0) -> void:
	audio.play(sound, volume_db, 0.04)
	_ui_frame = Engine.get_process_frames()


## Anropas efter varje tryck i basens skärmar: ett mjukt klick om trycket inte redan lät.
func ui_tap() -> void:
	if _ui_frame != Engine.get_process_frames():
		ui("ui_tap", -14.0)


## Basens musik (alla platser i basen och lägret).
func base_music() -> void:
	audio.play_music("music_base", -17.0)


func start_run(party: Array[String]) -> void:
	ui("ui_confirm", -8.0)
	profile.party = party
	_save()
	state = RunState.new_run(profile, data)
	state.instability = profile.instability
	state.rules_visible = pending_rules.visible.duplicate()
	state.rules_hidden = pending_rules.hidden.duplicate()
	roll_rules()  # nästa körning får nya regler
	state.start_expedition(data, rng.randi() % 1000000 + 1)
	if not pending_trophy.is_empty() and profile.collection.has(pending_trophy.trophy):
		state.take_trophy(pending_trophy.trophy)
		state.equip(pending_trophy.wearer, pending_trophy.trophy)
	quest_reward = {}
	room_result = ""
	save_run()
	get_tree().change_scene_to_file(ROOM_MAP_SCENE)


## Sparar den pågående körningen (user://run.cfg).
func save_run() -> void:
	if not state.practice:
		state.save(RUN_PATH)


func _clear_run() -> void:
	if FileAccess.file_exists(RUN_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUN_PATH))


## Vid start: en sparad körning fortsätter på rumskartan.
func _resume_run() -> void:
	var saved := RunState.load_from(RUN_PATH)
	if saved == null or saved.map == null or saved.finished:
		return
	state = saved
	get_tree().change_scene_to_file.call_deferred(ROOM_MAP_SCENE)


## Spelaren går in i ett rum på rumskartan. Strider går till striden; andra rum avgörs på kartan.
func enter_room(room_id: String) -> Dictionary:
	var r := state.enter(room_id)
	room_result = ""
	if RunState.is_battle(r):
		save_run()
		get_tree().change_scene_to_file(BATTLE_SCENE)
	return r


## Lägereld, skattkammare och helgedom (anropas av rumskartan). Returnerar texten om vad som hände.
func campfire() -> String:
	var gained := state.campfire(data)
	room_result = "Lägerelden: +%d Charges" % gained
	save_run()
	return room_result


func treasure() -> String:
	var t := state.treasure(data, rng)
	var amount := roundi(t.silver * state.silver_mult(data))
	profile.silver += amount
	room_result = "Skattkammaren: +%d silver" % amount
	if t.trophy != "":
		profile.add_trophy(t.trophy)
		state.take_trophy(t.trophy)
		room_result += " och trofén %s!" % data.traits[t.trophy].name
		_trophy_sound_for([t.trophy])
	_save()
	save_run()
	return room_result


func shrine(option: Dictionary) -> String:
	room_result = state.apply_shrine(data, rng, option)
	_after_quest_check(false)
	save_run()
	return room_result


## Efter lägret: tillbaka till rumskartan, nästa våning, eller hem när körningen är klar.
func after_camp() -> void:
	ui("ui_confirm", -8.0)
	if state.floor_cleared():
		if state.is_last_floor():
			profile.clear_depth(state.depth, state.realm)
			state.finished = true
			_clear_run()
			_save()
			get_tree().change_scene_to_file(BASE_SCENE)
			return
		state.next_floor(data)
	save_run()
	get_tree().change_scene_to_file(ROOM_MAP_SCENE)


## Questen blev klar: silver och kanske en perk-poäng.
func _after_quest_check(just_done: bool) -> void:
	if just_done or (state.quest.get("done", false) and not state.quest.get("rewarded", false)):
		state.quest.rewarded = true
		quest_reward = profile.complete_quest(state.realm, state.depth)
		room_result += " Questen är klar: +%d silver%s" % [quest_reward.silver, " och en perk-poäng!" if quest_reward.point else "!"]
		_save()


func start_practice(encounter_id: String) -> void:
	practice_encounter = encounter_id
	ui("ui_confirm", -8.0)
	state = RunState.new_practice(profile, data, encounter_id)
	get_tree().change_scene_to_file(BATTLE_SCENE)


func go(scene: String) -> void:
	ui({BASE_SCENE: "ui_back", LIBRARY_SCENE: "ui_page"}.get(scene, "ui_door"), -12.0)
	get_tree().change_scene_to_file(scene)


## Anropas av striden när spelaren trycker vidare efter resultatet.
func battle_finished(victory: bool, receipt: Array[String], log: Array[Dictionary] = []) -> void:
	if state.practice:
		practice_log = log
		last_receipt = receipt
		get_tree().change_scene_to_file(PRACTICE_SCENE)
		return
	if not victory:
		last_silver = 0
		_clear_run()
		get_tree().change_scene_to_file(BASE_SCENE)
		return
	last_receipt = receipt
	last_silver = roundi(state.battle_silver(state.depth) * state.silver_mult(data))
	profile.silver += last_silver
	if state.current_room().get("kind", "") == "end" and state.is_last_floor():
		for kind in data.encounters[state.encounter()].enemies:
			if data.enemies[kind].get("boss", false):
				profile.defeat_boss(kind)
	offer = state.trophy_offer(data, rng, state.last_elites, profile.unlocked_boss_trophies())
	quest_reward = {}
	room_result = ""
	_after_quest_check(state.battle_won())
	_trophy_sound()
	camp_chosen = ""
	for t in offer:
		profile.add_trophy(t)
	_save()
	save_run()
	get_tree().change_scene_to_file(CAMP_SCENE)


## Troféfynd: ljudet efter den finaste trofén i erbjudandet.
func _trophy_sound() -> void:
	_trophy_sound_for(offer)


func _trophy_sound_for(list: Array) -> void:
	var best := ""
	for t in list:
		var r: String = data.traits.get(t, {}).get("rarity", "common")
		if best == "" or ["common", "elite", "boss"].find(r) > ["common", "elite", "boss"].find(best):
			best = r
	if best != "":
		get_tree().create_timer(0.5).timeout.connect(audio.play.bind("trophy_" + best, -4.0, 0.0))


## Makrot som hjälten kör, eller ett tomt makro.
func macro_for(hero_id: String) -> Dictionary:
	return macros.get(assignment.get(hero_id, ""), {"name": "", "lines": []})


func uses_macro(hero_id: String) -> bool:
	return default_action.get(hero_id, "macro") == "macro"


func open_macros(return_scene: String) -> void:
	ui("ui_page", -10.0)
	macro_return = return_scene
	get_tree().change_scene_to_file(MACRO_SCENE)


func close_macros() -> void:
	save_macros()
	ui("ui_back", -12.0)
	get_tree().change_scene_to_file(macro_return)


func new_macro_id() -> String:
	var n := 1
	while macros.has("m%d" % n):
		n += 1
	return "m%d" % n


func save_macros() -> void:
	var f := FileAccess.open(MACROS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"macros": macros, "assignment": assignment, "default_action": default_action}, "\t"))


## Startmakron från data/macros.json första gången; sedan spelarens egna.
func _load_macros() -> void:
	var parsed: Variant = null
	if FileAccess.file_exists(MACROS_PATH):
		parsed = JSON.parse_string(FileAccess.get_file_as_string(MACROS_PATH))
	if parsed is Dictionary and parsed.has("macros"):
		macros = parsed.macros
		assignment = parsed.get("assignment", {})
		default_action = parsed.get("default_action", {})
	else:
		macros = data.macros.duplicate(true)
		for hero_id in data.macros:
			assignment[hero_id] = hero_id
	for hero_id in data.heroes:
		if not assignment.has(hero_id) or not macros.has(assignment[hero_id]):
			assignment[hero_id] = hero_id if macros.has(hero_id) else ""
		if not default_action.has(hero_id):
			default_action[hero_id] = "macro"


func _load() -> void:
	profile = Profile.load_from(PROGRESS_PATH)
	collection = profile.collection
	state.oath = profile.oath
	state.perks = profile.active_perks(data, profile.oath)
	state.party = profile.party.duplicate()
	state.artifacts = profile.artifacts.duplicate(true)


## Sparar efter ett val i basen; sound är menyljudet för valet.
func save(sound := "ui_toggle") -> void:
	ui(sound, -10.0)
	_save()


func _save() -> void:
	profile.save(PROGRESS_PATH)
