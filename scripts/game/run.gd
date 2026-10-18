extends Node
## Autoload "Run": håller den pågående körningen mellan scenerna och sparar vilka troféer
## spelaren någonsin har hittat (samlingen).

const PROGRESS_PATH := "user://progress.cfg"
const START_SCENE := "res://scenes/start.tscn"
const BATTLE_SCENE := "res://scenes/main.tscn"
const CAMP_SCENE := "res://scenes/camp.tscn"

var data: Dictionary
var state := RunState.new()
## Senast vunna stridens kvitto och troféerbjudande (visas i lägret).
var last_receipt: Array[String] = []
var offer: Array[String] = []
var rng := RandomNumberGenerator.new()
var collection: Array[String] = []


func _ready() -> void:
	data = GameData.load_all()
	rng.randomize()
	_load()
	_dev_args()


## Utvecklarargument (efter `--`): --floor=<n> startar striden på våning n (0–2),
## --camp visar lägret efter första striden.
func _dev_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--floor="):
			state.floor = int(arg.get_slice("=", 1))
			get_tree().change_scene_to_file.call_deferred(BATTLE_SCENE)
		elif arg == "--camp":
			offer = state.trophy_offer(data, rng)
			last_receipt = ["Hämndens ed (Paladinen): slog till 7 gånger – 312 skada"]
			get_tree().change_scene_to_file.call_deferred(CAMP_SCENE)


func start_run(oath: String, party: Array[String]) -> void:
	state = RunState.new()
	state.oath = oath
	state.party = party
	get_tree().change_scene_to_file(BATTLE_SCENE)


## Anropas av striden när spelaren trycker vidare efter resultatet.
func battle_finished(victory: bool, receipt: Array[String]) -> void:
	if not victory:
		get_tree().change_scene_to_file(START_SCENE)
		return
	last_receipt = receipt
	offer = state.trophy_offer(data, rng)
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


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PROGRESS_PATH) == OK:
		for t in cfg.get_value("progress", "collection", []):
			collection.append(t)


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "collection", collection)
	cfg.save(PROGRESS_PATH)
