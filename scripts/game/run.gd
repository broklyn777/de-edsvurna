extends Node
## Autoload "Run": håller den pågående körningen mellan scenerna och sparar vilka troféer
## spelaren någonsin har hittat (samlingen).

const PROGRESS_PATH := "user://progress.cfg"
const MACROS_PATH := "user://macros.json"
const START_SCENE := "res://scenes/start.tscn"
const BATTLE_SCENE := "res://scenes/main.tscn"
const CAMP_SCENE := "res://scenes/camp.tscn"
const MACRO_SCENE := "res://scenes/macros.tscn"

var data: Dictionary
var state := RunState.new()
## Senast vunna stridens kvitto och troféerbjudande (visas i lägret).
var last_receipt: Array[String] = []
var offer: Array[String] = []
var rng := RandomNumberGenerator.new()
var collection: Array[String] = []
## Spelarens makron: macro_id -> {name, lines}. Sparas mellan körningar.
var macros := {}
## hero_id -> macro_id, och hero_id -> "macro" eller "manual" (standardhandling).
var assignment := {}
var default_action := {}
## Scenen makroredigeraren går tillbaka till.
var macro_return := START_SCENE
## Trofén som är vald i lägret (finns kvar om man går till makroredigeraren och tillbaka).
var camp_chosen := ""


func _ready() -> void:
	data = GameData.load_all()
	rng.randomize()
	_load()
	_load_macros()
	_dev_args()


## Utvecklarargument (efter `--`): --floor=<n> startar striden på våning n (0–2),
## --camp visar lägret efter första striden.
func _dev_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--floor="):
			state.floor = int(arg.get_slice("=", 1))
			state.fill_charges(data)
			get_tree().change_scene_to_file.call_deferred(BATTLE_SCENE)
		elif arg == "--macros":
			get_tree().change_scene_to_file.call_deferred(MACRO_SCENE)
		elif arg == "--camp":
			offer = state.trophy_offer(data, rng)
			last_receipt = ["Hämndens ed (Paladinen): slog till 7 gånger – 312 skada"]
			get_tree().change_scene_to_file.call_deferred(CAMP_SCENE)


func start_run(oath: String, party: Array[String]) -> void:
	state = RunState.new()
	state.oath = oath
	state.party = party
	state.fill_charges(data)
	get_tree().change_scene_to_file(BATTLE_SCENE)


## Anropas av striden när spelaren trycker vidare efter resultatet.
func battle_finished(victory: bool, receipt: Array[String]) -> void:
	if not victory:
		get_tree().change_scene_to_file(START_SCENE)
		return
	last_receipt = receipt
	offer = state.trophy_offer(data, rng)
	camp_chosen = ""
	for t in offer:
		if not collection.has(t):
			collection.append(t)
	_save()
	if state.is_last_floor():
		get_tree().change_scene_to_file(START_SCENE)
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
	var cfg := ConfigFile.new()
	if cfg.load(PROGRESS_PATH) == OK:
		for t in cfg.get_value("progress", "collection", []):
			collection.append(t)


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "collection", collection)
	cfg.save(PROGRESS_PATH)
