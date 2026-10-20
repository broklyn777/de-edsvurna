class_name SaveSlots
extends RefCounted
## Sparplatser (0.23.1, som Siralims flera sparfiler). Varje plats har en egen mapp med progress.cfg, run.cfg och
## macros.json: user://slot1/, user://slot2/ och user://slot3/. Senast använda plats står i user://slots.cfg.
## Data från före 0.23.1 (filerna direkt i user://) flyttas orörda till plats 1. Ren logik med en rot som
## testerna kan byta.

const COUNT := 3
const FILES := ["progress.cfg", "run.cfg", "macros.json"]


static func dir(slot: int, root := "user://") -> String:
	return "%sslot%d/" % [root, slot]


static func progress_path(slot: int, root := "user://") -> String:
	return dir(slot, root) + "progress.cfg"


static func run_path(slot: int, root := "user://") -> String:
	return dir(slot, root) + "run.cfg"


static func macros_path(slot: int, root := "user://") -> String:
	return dir(slot, root) + "macros.json"


static func is_empty(slot: int, root := "user://") -> bool:
	return not FileAccess.file_exists(progress_path(slot, root))


## Flyttar sparfilerna från före sparplatserna till plats 1, orörda. Gör inget om plats 1 redan finns eller om
## det inte finns något gammalt. Returnerar sant om något flyttades.
static func migrate(root := "user://") -> bool:
	var old := FILES.filter(func(f: String) -> bool: return FileAccess.file_exists(root + f))
	if old.is_empty() or not is_empty(1, root):
		return false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir(1, root)))
	for f in old:
		DirAccess.rename_absolute(ProjectSettings.globalize_path(root + f), ProjectSettings.globalize_path(dir(1, root) + f))
	set_last(1, root)
	return true


static func last(root := "user://") -> int:
	var cfg := ConfigFile.new()
	if cfg.load(root + "slots.cfg") != OK:
		return 0
	return clampi(int(cfg.get_value("slots", "last", 0)), 0, COUNT)


static func set_last(slot: int, root := "user://") -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("slots", "last", slot)
	cfg.save(root + "slots.cfg")


## Raderar platsens filer (bekräftelsen görs av skärmen). Senast använda nollställs om det var den.
static func delete(slot: int, root := "user://") -> void:
	for f in FILES:
		var p: String = dir(slot, root) + f
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	if last(root) == slot:
		set_last(0, root)


## Vad sparplatsens kort visar: {empty, oath, level, silver, depth, run, intro}.
static func summary(slot: int, data: Dictionary, root := "user://") -> Dictionary:
	if is_empty(slot, root):
		return {"empty": true}
	var p := Profile.load_from(progress_path(slot, root))
	var level := 1
	for id in ["paladin"] + Array(p.recruited):
		level = maxi(level, int(p.hero(data, id).level))
	var saved := RunState.load_from(run_path(slot, root))
	return {"empty": false, "oath": data.traits.get(p.oath, {}).get("name", p.oath), "level": level, "silver": p.silver,
			"depth": p.best_depth, "run": saved != null and saved.map != null and not saved.finished,
			"intro": not p.intro_done, "heroes": p.recruited.size() + 1, "name": p.hero_name}
