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


func _ready() -> void:
	data = GameData.load_all()
	rng.randomize()
	_load()
	_load_macros()
	_dev_args()


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
		elif arg.begins_with("--depth="):
			# --depth=<n> spelar på djup n (bara den här körningen)
			state.depth = maxi(1, int(arg.get_slice("=", 1)))
		elif arg == "--macros":
			get_tree().change_scene_to_file.call_deferred(MACRO_SCENE)
		elif arg.begins_with("--oath="):
			# --oath=<ed> väljer Ed för den här körningen; med --all-perks får den alla perks (bara för test)
			state.oath = arg.get_slice("=", 1)
			state.perks = []
			if OS.get_cmdline_user_args().has("--all-perks"):
				for p in data.oaths[state.oath].perks:
					state.perks.append(p.id)
		elif arg in ["--practice", "--smith", "--library", "--gate", "--altar"]:
			var scene: String = {"--practice": PRACTICE_SCENE, "--smith": SMITH_SCENE,
					"--library": LIBRARY_SCENE, "--gate": START_SCENE, "--altar": ALTAR_SCENE}[arg]
			get_tree().change_scene_to_file.call_deferred(scene)
		elif arg == "--camp":
			offer = state.trophy_offer(data, rng)
			last_receipt = ["Hämndens ed (Paladinen): slog till 7 gånger – 312 skada"]
			get_tree().change_scene_to_file.call_deferred(CAMP_SCENE)


## Eden väljs vid Edsaltaret (profile.oath), sällskapet vid Kryptporten.
func start_run(party: Array[String]) -> void:
	profile.party = party
	_save()
	state = RunState.new_run(profile, data)
	get_tree().change_scene_to_file(BATTLE_SCENE)


func start_practice(encounter_id: String) -> void:
	practice_encounter = encounter_id
	state = RunState.new_practice(profile, data, encounter_id)
	get_tree().change_scene_to_file(BATTLE_SCENE)


func go(scene: String) -> void:
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
		get_tree().change_scene_to_file(BASE_SCENE)
		return
	last_receipt = receipt
	last_silver = profile.win_battle(state.floor, state.depth)
	offer = state.trophy_offer(data, rng)
	camp_chosen = ""
	for t in offer:
		profile.add_trophy(t)
	if state.is_last_floor():
		profile.clear_depth(state.depth)
		for kind in data.encounters[state.encounter()].enemies:
			if data.enemies[kind].get("boss", false):
				profile.defeat_boss(kind)
	_save()
	if state.is_last_floor():
		get_tree().change_scene_to_file(BASE_SCENE)
	else:
		get_tree().change_scene_to_file(CAMP_SCENE)


func next_floor() -> void:
	state.floor += 1
	get_tree().change_scene_to_file(BATTLE_SCENE)


## Makrot som hjälten kör, eller ett tomt makro.
func macro_for(hero_id: String) -> Dictionary:
	return macros.get(assignment.get(hero_id, ""), {"name": "", "lines": []})


func uses_macro(hero_id: String) -> bool:
	return default_action.get(hero_id, "macro") == "macro"


func open_macros(return_scene: String) -> void:
	macro_return = return_scene
	get_tree().change_scene_to_file(MACRO_SCENE)


func close_macros() -> void:
	save_macros()
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


func save() -> void:
	_save()


func _save() -> void:
	profile.save(PROGRESS_PATH)
