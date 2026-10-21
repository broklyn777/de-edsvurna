extends Node
## Autoload "Run": håller den pågående körningen mellan scenerna och profilen som varar mellan
## körningarna (silver, samlingen, artefakter – se Profile).
##
## Flöde: basen → Kryptporten → strid → läger → … → basen (förlust eller sista våningen).
## Övningsgården: basen → övning → strid → övningen (med makrologgen kvar).

## 0.23.1: sökvägarna gäller vald sparplats (SaveSlots). Platserna väljs på sparplatsskärmen.
var PROGRESS_PATH := "user://slot1/progress.cfg"
var MACROS_PATH := "user://slot1/macros.json"
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
var RUN_PATH := "user://slot1/run.cfg"
var slot := 1
const SLOTS_SCENE := "res://scenes/slots.tscn"
const HERO_SCENE := "res://scenes/hero.tscn"
const INN_SCENE := "res://scenes/inn.tscn"
const HANDBOOK_SCENE := "res://scenes/handbook.tscn"

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
## Hjältebladet (0.19): vem, vilka man kan bläddra mellan, vart man går tillbaka och om
## personligheten får bytas (bara från Biblioteket).
var sheet_hero := "paladin"
var sheet_heroes: Array = []
var sheet_return := BASE_SCENE
var sheet_can_change_personality := false
## Questens belöning om den blev klar i senaste rummet: {silver, point} (visas i lägret).
var quest_reward := {}
## Erfarenhet från senaste vunna striden (visas i lägret).
## Fynden från senaste striden (0.20).
var last_finds: Array = []
var last_xp := 0
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
	SaveSlots.migrate()
	_use_slot(maxi(SaveSlots.last(), 1))
	_load()
	_load_macros()
	roll_rules()
	_dev_args()
	apply_name()  # en påhittad profil från en utvecklarflagga


## Byter till sparplatsen: sökvägarna pekar dit (mappen skapas vid behov).
func _use_slot(i: int) -> void:
	slot = i
	PROGRESS_PATH = SaveSlots.progress_path(i)
	RUN_PATH = SaveSlots.run_path(i)
	MACROS_PATH = SaveSlots.macros_path(i)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SaveSlots.dir(i)))


## Sparplatsskärmen väljer en plats: profilen, makrona och körningen laddas därifrån, och spelet fortsätter som
## förut (en pågående körning återupptas). En tom plats börjar introt.
func choose_slot(i: int, new_name := "") -> void:
	_use_slot(i)
	SaveSlots.set_last(i)
	state = RunState.new()
	macros = {}
	assignment = {}
	default_action = {}
	intro_lines = {}
	pending_story = []
	last_silver = 0
	_load()
	_load_macros()
	roll_rules()
	if SaveSlots.is_empty(i):
		profile.set_hero_name(new_name)
		apply_name()
		_save()
		save_macros()
	ui("ui_confirm", -8.0)
	get_tree().change_scene_to_file(BASE_SCENE)
	_resume_run()


## 0.24.2: paladinens namn syns där hjälten visas (stridens ram, hjältebladet, makroskärmen, korten): datan för
## "paladin" får profilens namn. Rollen ("Paladinen", titeln "Edsvuren") står kvar där den beskriver klassen.
func apply_name() -> void:
	data.heroes.paladin.name = profile.hero_name
	data.heroes.paladin.short = profile.hero_name


func rename(n: String) -> void:
	profile.set_hero_name(n)
	apply_name()
	_save()


## Introduktionen (0.23, Intro): en händelse som kan avsluta aktuellt uppdrag. Repliker för nästa steg visas i borgen.
var intro_lines := {}
## 0.25: berättelsens rader som nästa skärm visar ({who, text}; "narrator" är berättarens ruta på svart): den första
## porten, Imma som smiter efter och den första bossen.
var pending_story: Array = []
const INTRO_PRACTICE := "intro_yard"


func intro(event: String, value := 0) -> void:
	var done := Intro.notify(data, profile, event, value)
	if done.is_empty():
		return
	ui("trophy_common", -6.0)
	# 0.24: nästa uppdrag kommer först när man har pratat med den som ger det; bara slutet sägs direkt.
	if profile.intro_done:
		intro_lines = {"speaker": "gorm", "lines": [data.intro.get("done", "")]}
	else:
		intro_lines = {}
	_save()


## Sant när introts övningsstrid gäller (ensam paladin, Övningsgårdens docka).
func intro_practice() -> bool:
	return Intro.current(data, profile).get("id", "") == "practice"


## Sant när profilen är påhittad för en skärmdump (--forge-demo): då sparas den inte.
var dev_profile := false


func _forge_demo() -> void:
	dev_profile = true
	profile.silver = 640
	profile.forge("paladin", "sword", "holy_smite")
	profile.forge("brokk", "shield", "healing_light")
	profile.artifacts.brokk = Forge.normalize({"type": "shield", "ability": "healing_light", "level": 7,
			"stat_slots": ["amber_grey", "amber_teal", ""], "trick_slots": ["armor_scrap", ""]})
	profile.artifacts.paladin.level = 3
	profile.silver = 640
	profile.materials = {"amber_red": 6, "amber_grey": 3, "amber_green": 8, "amber_yellow": 5, "amber_teal": 2,
			"amber_orange": 5, "whetstone": 1, "slippery_stone": 2, "curio_vulnerable": 1}
	var r := RandomNumberGenerator.new()
	r.seed = 12
	for d in [1, 2, 3, 4, 2]:
		profile.stones.append(Forge.roll_stone(data, d, 1, r, profile.next_stone_id))
		profile.next_stone_id += 1


func _find_demo() -> void:
	await get_tree().create_timer(0.3).timeout
	var r := RandomNumberGenerator.new()
	r.seed = 5
	var stone := {}
	for i in 200:
		stone = Forge.roll_stone(data, 3, 2, r, 99)
		if stone.rarity == "legendary":
			break
	ui("find_rare", -2.0)
	show_rare_finds([{"kind": "nether", "stone": stone}])


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
		elif arg == "--all-companions":
			# --all-companions: en påhittad profil (sparas inte) som har befriat alla lärjungar
			dev_profile = true
			for id in data.heroes:
				if id != "paladin":
					profile.recruit(data, id, 3.0)
			profile.intro_done = true
			profile.set_party(["imma", "alva", "brokk"])
			# och några troféer, en av dem på Imma (0.26.3, för skärmdumpar av Förberedelser)
			for kind in ["skeleton_warrior", "skeleton_archer", "ember_skeleton", "grave_guard"]:
				if data.enemies.has(kind) and data.enemies[kind].has("trophy"):
					profile.add_trophy(data.enemies[kind].trophy)
			if not profile.collection.is_empty():
				profile.wear("imma", profile.collection[0])
		elif arg == "--new-profile":
			# --new-profile: börja som en ny spelare (sparas inte): Paladinen och Brokk
			dev_profile = true
			profile = Profile.new()
			state = RunState.new_run(profile, data)
			_load_macros(true)
		elif arg == "--rescue-demo":
			# --rescue-demo: rumskartan med befrielsedialogen för Alva och hennes makroförslag (sparas inte)
			dev_profile = true
			profile = Profile.new()
			profile.recruit(data, "imma")
			profile.set_party(["imma"])
			state = RunState.new_run(profile, data)
			state.start_expedition(data, 3)
			profile.recruit(data, "alva")
			state.party.append("alva")
			state.add_charges_for(data, "alva")
			last_recruit = "alva"
			# Som i en ny profil: Alvas startrader utan den rad som förslaget lär ut (sparas inte, dev_profile).
			var alva_id: String = assignment.get("alva", "alva")
			if macros.has(alva_id):
				macros[alva_id].lines = starter_lines(data, "alva", data.macros.get("alva", {}).get("lines", []))
			pending_rescue = "Syster Alva befrias! Präst, Klok. Följer med direkt (nivå 1)."
			get_tree().change_scene_to_file.call_deferred(ROOM_MAP_SCENE)
		elif arg == "--forge-demo":
			# --forge-demo: en påhittad profil för Smeden (sparas inte): Brokks sköld på nivå 7 med material,
			# ett förråd och några Nether Stones. Med --smith öppnas Smeden direkt.
			_forge_demo()
		elif arg == "--find-demo":
			# --find-demo visar scenen för ett legendariskt fynd
			_find_demo.call_deferred()
		elif arg == "--anoint":
			# --anoint låser upp den lånade perken (som om Benfursten var besegrad) och visar valet
			profile.defeat_boss("bone_lich")
			get_tree().change_scene_to_file.call_deferred(ALTAR_SCENE)
		elif arg.begins_with("--xp="):
			# --xp=<n> ger sällskapet n erfarenhet direkt (för att se nivåuppgångar på segerskärmen)
			profile.grant_xp(data, state.party, int(arg.get_slice("=", 1)))
		elif arg.begins_with("--xp-bar="):
			# --xp-bar=<n> fyller mätaren till n utan att höja nivån (nästa seger ger en nivå)
			for hero_id in state.party:
				profile.hero(data, hero_id).xp = int(arg.get_slice("=", 1))
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
		elif arg.begins_with("--encounter="):
			# --encounter=<möte> (0.27): en övningsstrid mot det mötet, t.ex. crypt_e5 (Klockstapeln)
			state = RunState.new_practice(profile, data, arg.get_slice("=", 1))
			get_tree().change_scene_to_file.call_deferred(BATTLE_SCENE)
		elif arg == "--macros":
			get_tree().change_scene_to_file.call_deferred(MACRO_SCENE)
		elif arg.begins_with("--oath="):
			# --oath=<kall> väljer kall för den här körningen; med --all-perks får den alla perks (bara för test)
			state.oath = arg.get_slice("=", 1)
			state.perks = []
			if OS.get_cmdline_user_args().has("--all-perks"):
				for p in data.oaths[state.oath].perks:
					state.perks.append(p.id)
		elif arg.begins_with("--hero="):
			# --hero=<id> öppnar hjältebladet (--tab=0–2 väljer flik)
			sheet_hero = arg.get_slice("=", 1)
			sheet_heroes = profile.party.duplicate()
			sheet_can_change_personality = true
			get_tree().change_scene_to_file.call_deferred(HERO_SCENE)
		elif arg.begins_with("--name="):
			profile.set_hero_name(arg.get_slice("=", 1))  # paladinens namn (0.24.2), sparas inte av sig självt
		elif arg.begins_with("--silver="):
			profile.silver = int(arg.get_slice("=", 1))  # för skärmdumpar (sparas inte om profilen är påhittad)
		elif arg == "--keep":
			get_tree().change_scene_to_file.call_deferred(BASE_SCENE)  # borgen direkt (0.24)
		elif arg.begins_with("--intro-step="):
			# --intro-step=<id>: en ny profil (sparas inte) på introts steg, t.ex. imma; med --talked är uppdraget givet
			dev_profile = true
			profile = Profile.new()
			while Intro.current(data, profile).get("id", "") not in ["", arg.get_slice("=", 1)]:
				Intro.talked(data, profile)
				Intro.notify(data, profile, Intro.current(data, profile).get("event", ""), 3)
			profile.intro_talked = "--talked" in OS.get_cmdline_user_args()
			if profile.intro_step > 2 and profile.artifact("paladin").is_empty():
				var keep_silver := profile.silver
				profile.silver = Profile.FORGE_COST
				profile.forge("paladin", "sword", "")  # svärdet som smiddes i introt
				profile.silver = keep_silver - Profile.FORGE_COST + 77 if profile.intro_step >= 7 else 0
		elif arg.begins_with("--bark="):
			pending_bark = Dialog.bark(data, arg.get_slice("=", 1), state.party, state.barks_used, rng)  # replik på rumskartan
		elif arg.begins_with("--story="):
			# 0.25: --story=imma_joins | first_gate | first_boss visar berättelsen på nästa skärm (rumskartan, borgen)
			var kind := arg.get_slice("=", 1)
			if kind == "imma_joins":
				pending_story = Intro.speech(data.intro.imma_joins.lines)
			else:
				profile.narrated.erase(kind)
				narrate(kind)
		elif arg == "--descents":
			profile.descents = {"crypt": 1}  # som efter första nedstigningen (sparas inte om profilen är påhittad)
		elif arg in ["--practice", "--smith", "--library", "--gate", "--altar", "--prep", "--inn", "--handbook"]:
			var scene: String = {"--practice": PRACTICE_SCENE, "--smith": SMITH_SCENE, "--inn": INN_SCENE,
					"--library": LIBRARY_SCENE, "--gate": CAMPAIGN_SCENE, "--altar": ALTAR_SCENE, "--prep": START_SCENE,
					"--handbook": HANDBOOK_SCENE}[arg]
			get_tree().change_scene_to_file.call_deferred(scene)
		elif arg == "--campfire-camp":
			# 0.27: trofébytet vid en lägereld (lägret utan erbjudande)
			state.take_trophy("bone_finger")
			state.take_trophy("quick_shot")
			camp_mode = "campfire"
			get_tree().change_scene_to_file.call_deferred(CAMP_SCENE)
		elif arg == "--camp":
			offer = state.trophy_offer(data, rng)
			last_receipt = ["Domens kall (Paladinen): slog till 7 gånger – 31 skada"]
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
	# 0.24: nedstigningarna räknas per Realm; första gången i en Realm säger någon något om den.
	state.first_descent = profile.total_descents() == 0
	var seen := int(profile.descents.get(state.realm, 0))
	profile.descents[state.realm] = seen + 1
	pending_bark = {}
	narrate("first_gate")
	if seen == 0:
		bark("new_realm")
	_save()
	quest_reward = {}
	room_result = ""
	save_run()
	get_tree().change_scene_to_file(ROOM_MAP_SCENE)


## Sparar den pågående körningen (user://run.cfg).
func open_sheet(hero_id: String, heroes: Array, return_scene: String, can_change := false) -> void:
	sheet_hero = hero_id
	sheet_heroes = heroes
	sheet_return = return_scene
	sheet_can_change_personality = can_change
	go(HERO_SCENE)


func save_run() -> void:
	if not state.practice:
		state.save(RUN_PATH)


func _clear_run() -> void:
	RunState.delete_saved(RUN_PATH)


## Vid start: en sparad körning fortsätter på rumskartan.
func _resume_run() -> void:
	var saved := RunState.load_from(RUN_PATH)
	if saved == null or saved.map == null or saved.finished:
		return
	state = saved
	if state.battle_pending:
		# Appen stängdes under en strid: striden börjar om, som om man just gått in i rummet.
		get_tree().change_scene_to_file.call_deferred(BATTLE_SCENE)
	elif state.floor_cleared():
		after_camp.call_deferred()  # vunnet våningens slut, men appen stängdes i lägret: vidare
	else:
		get_tree().change_scene_to_file.call_deferred(ROOM_MAP_SCENE)


## 0.27: spelaren går till en ruta i grottan. Returnerar rutorna pjäsen passerar ([] om det inte går).
func step_to(i: int) -> Array[int]:
	var was_new := not state.visited.has(i)
	var walk := state.step(i)
	if walk.is_empty():
		return walk
	if was_new:
		room_result = ""
		pending_bark = {}  # högst en replik per ny ruta
	save_run()
	return walk


## Backar från en grupp (den står kvar och spärrar rutorna intill).
func back_off() -> void:
	if state.back():
		ui("ui_back", -12.0)
		save_run()


## Striden mot gruppen på rutan (efter knappen ANFALL på gruppens kort).
func fight_here() -> void:
	state.fight()
	if not state.battle_pending:
		return
	room_result = ""
	pending_bark = {}
	save_run()
	get_tree().change_scene_to_file(BATTLE_SCENE)


## Trappan ned till nästa våning (när questen är klar).
func descend() -> void:
	if not state.floor_cleared() or state.is_last_floor():
		return
	ui("room_door", -6.0)
	state.next_floor(data)
	room_result = "Ni går ned till våning %d." % (state.floor + 1)
	save_run()


## Lägereldens trofébyte (0.27, VAL: troféer byts bara vid en lägereld): lägret öppnas utan nytt erbjudande.
var camp_mode := "victory"


func open_campfire_camp() -> void:
	camp_mode = "campfire"
	offer = []
	last_receipt = []
	quest_reward = {}
	get_tree().change_scene_to_file(CAMP_SCENE)


## Fynd (0.20, Forge): slår fram rummets fynd och lägger dem i förrådet. Bara det djupaste djupet man nått
## ger trick och Nether Stones (originalets bonus). Returnerar fynden.
func roll_finds(kind: String) -> Array:
	if kind == "portal_treasure":
		kind = "portal_battle"
	if "--find-luck" in OS.get_cmdline_user_args():
		kind = "boss"  # för skärmdumpar: fynden som efter en boss
	var frontier := state.depth > profile.best_depth
	var finds := Forge.roll_finds(data, kind, state.depth, frontier, state.instability, rng, profile.next_stone_id)
	for f in finds:
		if f.kind == "nether":
			profile.next_stone_id += 1
		state.found[f.kind] = int(state.found.get(f.kind, 0)) + int(f.get("count", 1))
	profile.add_finds(finds)
	return finds


## Ljudet för det finaste fyndet, efter delay sekunder.
func play_find_sound(finds: Array, delay := 0.0) -> void:
	var best := ""
	for f in finds:
		if Forge.is_rare_find(f):
			best = "find_rare"
		elif f.kind == "nether" and best != "find_rare":
			best = "find_nether"
		elif f.kind == "trick" and best in ["", "find_amber"]:
			best = "find_trick"
		elif best == "":
			best = "find_amber"
	if best == "":
		return
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	ui(best, -2.0)


## Ett sällsynt fynd får en egen liten scen (FindReveal) ovanpå skärmen.
func show_rare_finds(finds: Array, delay := 0.0) -> void:
	var rare := finds.filter(func(f: Dictionary) -> bool: return Forge.is_rare_find(f))
	if rare.is_empty():
		return
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	for f in rare:
		var layer := CanvasLayer.new()
		layer.layer = 60
		var reveal: Control = load("res://scripts/screens/find_reveal.gd").new()
		reveal.find = f
		layer.add_child(reveal)
		get_tree().current_scene.add_child(layer)


## Lägereld, skattkammare och helgedom (anropas av rumskartan). Returnerar texten om vad som hände.
func campfire() -> String:
	var fresh: bool = not state.current_room().get("done", false)
	var gained := state.campfire(data)
	if fresh:
		bark("campfire")
		room_result = "Lägerelden: +%d Charges. Här kan ni byta troféer." % gained
	else:
		room_result = "Elden brinner fortfarande. Här kan ni byta troféer."
	save_run()
	return room_result


## Befriar fången i rummet (0.23, Siralims rekrytering): lärjungen ansluter direkt på svag nivå om det finns plats,
## annars väntar hen i Värdshuset. Returnerar texten om vad som hände.
var last_recruit := ""
## En befrielse efter en strid visas som en ruta när man kommer tillbaka till rumskartan.
var pending_rescue := ""


## Makroförslaget för en hjälte som just anslöt (0.23): {line, text}, eller {} om raden redan finns.
func macro_hint(hero_id: String) -> Dictionary:
	var hint: Dictionary = data.heroes.get(hero_id, {}).get("macro_hint", {})
	if hint.is_empty():
		return {}
	var m: Dictionary = macros.get(assignment.get(hero_id, hero_id), {})
	for line in m.get("lines", []):
		if line.get("cond", "") == hint.line.cond and line.get("action", "") == hint.line.action \
				and line.get("ability", "") == hint.line.get("ability", ""):
			return {}
	return hint


## En ny profils startrader för en följeslagare (0.23, 0.24.1): de två första, men inte raden som makroförslaget
## lär ut (som Alvas "hela den som har lågt liv"), så att förslaget visas när hen ansluter.
static func starter_lines(game_data: Dictionary, hero_id: String, lines: Array) -> Array:
	var hint: Dictionary = game_data.heroes.get(hero_id, {}).get("macro_hint", {}).get("line", {})
	var rest := lines.filter(func(l: Dictionary) -> bool: return hint.is_empty() or l.get("cond", "") != hint.cond \
			or l.get("action", "") != hint.action or l.get("ability", "") != hint.get("ability", ""))
	return rest.slice(0, 2)


## Hjältarna som makroskärmen visar (0.23.2): Paladinen och de som har anslutit.
func macro_heroes() -> Array:
	return (["paladin"] + Array(profile.recruited)).filter(func(id: String) -> bool: return data.heroes.has(id))


## Raden som föreslås i ett tomt makro (0.23.2), som introts "anfall den svagaste fienden".
const FIRST_LINE := {"subject": "any_enemy", "cond": "lowest_hp", "value": 0, "action": "attack", "ability": "", "target": "that"}


## Lägger förslagets rad först i hjältens makro.
func add_macro_hint(hero_id: String) -> void:
	var hint := macro_hint(hero_id)
	if hint.is_empty():
		return
	var id: String = assignment.get(hero_id, hero_id)
	if not macros.has(id):
		macros[id] = {"name": data.heroes[hero_id].name, "lines": []}
		assignment[hero_id] = id
	macros[id].lines.insert(0, hint.line.duplicate(true))
	save_macros()
	ui("ui_confirm", -8.0)


func rescue_prisoner() -> String:
	var r := state.current_room()
	var hero_id: String = r.get("hero", "")
	if hero_id == "" or r.get("rescued", false):
		return ""
	r.rescued = true
	state.prisoners.erase(str(state.floor))
	var avg := 0.0
	for id in state.party:
		avg += float(profile.hero(data, id).level)
	avg /= maxi(state.party.size(), 1)
	profile.recruit(data, hero_id, avg)
	last_recruit = hero_id
	var h: Dictionary = data.heroes[hero_id]
	var p: Dictionary = data.personalities.get(profile.hero(data, hero_id).personality, {})
	var text := "%s befrias! %s, %s." % [h.name, h.get("title", ""), p.get("name", "")]
	if state.party.size() <= Profile.MAX_COMPANIONS:
		state.party.append(hero_id)
		state.add_charges_for(data, hero_id)
		profile.set_party(state.party.slice(1))
		text += " Följer med direkt (nivå %d)." % int(profile.hero(data, hero_id).level)
	else:
		text += " Sällskapet är fullt – väntar i Värdshuset."
	ui("room_lock", -4.0)
	bark("rescue")
	_save()
	save_run()
	return text


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
	var finds := roll_finds("treasure" if not state.current_room().get("guarded", false) else "portal_battle")
	if not finds.is_empty():
		room_result += "\nFynd: " + ", ".join(finds.map(func(f: Dictionary) -> String: return Forge.find_text(data, f)))
		play_find_sound(finds, 0.4)
		show_rare_finds(finds, 0.9)
		if finds.any(func(f: Dictionary) -> bool: return Forge.is_rare_find(f)):
			bark("rare_find")
	_save()
	save_run()
	return room_result


func shrine(option: Dictionary) -> String:
	room_result = state.apply_shrine(data, rng, option)
	_after_quest_check(false)
	save_run()
	return room_result


## Efter en strid (0.19): räkna strider, segrar, stupade och väckta per hjälte och egenskapernas
## statistik för körningen, och ge erfarenhet efter en vunnen strid (inte i Övningsgården).
## Returnerar nivåuppgångarna: [{hero, name, level, gains}].
func award_battle(sim: CombatSim, victory: bool) -> Array:
	for u in sim.heroes:
		var h := profile.hero(data, u.id)
		h.battles = int(h.battles) + 1
		h.wins = int(h.wins) + (1 if victory else 0)
		h.deaths = int(h.deaths) + u.deaths
		h.revives = int(h.revives) + u.revives
	for trait_id in sim.trait_stats:
		var st: Dictionary = sim.trait_stats[trait_id]
		var tot: Dictionary = state.trait_totals.get(trait_id, {"procs": 0, "damage": 0.0, "heal": 0.0, "unit": st.unit})
		tot.procs = int(tot.procs) + int(st.procs)
		tot.damage = float(tot.damage) + float(st.damage)
		tot.heal = float(tot.heal) + float(st.heal)
		state.trait_totals[trait_id] = tot
	var out := []
	last_finds = []
	if victory and not state.practice:
		var r := state.current_room()
		last_finds = roll_finds("boss" if r.get("boss", false) else RunState.fight_kind(r))
		var xp := HeroStats.battle_xp(RunState.fight_kind(r), state.depth, r.get("boss", false))
		last_xp = xp
		var ups := profile.grant_xp(data, state.party, xp)
		_bark_after_battle(sim)
		for hero_id in state.party:
			for lv in ups.get(hero_id, []):
				var p: String = profile.hero(data, hero_id).personality
				out.append({"hero": hero_id, "name": data.heroes[hero_id].name, "level": lv,
						"gains": HeroStats.gains(data, hero_id, lv, p)})
	_save()
	return out


## 0.24 (plan §3): en kort replik från sällskapet efter striden, som visas på rumskartan.
func _bark_after_battle(sim: CombatSim) -> void:
	var standing := sim.heroes.filter(func(h: CombatUnit) -> bool: return h.alive)
	if sim.heroes.size() > 1 and standing.size() == 1 and standing[0].id == "paladin":
		bark("alone")
	elif last_finds.any(func(f: Dictionary) -> bool: return Forge.is_rare_find(f)):
		bark("rare_find")
	elif standing.size() < sim.heroes.size() or standing.any(func(h: CombatUnit) -> bool: return h.hp < h.max_hp * 0.3):
		bark("hard_fight")


## Replikerna under nedstigningen (0.24, Dialog.bark): högst en per rum, aldrig i striden, inget upprepas samma
## körning. Den väntar i pending_bark tills rumskartan visar den.
var pending_bark := {}


func bark(kind: String) -> void:
	if not pending_bark.is_empty() or state.practice:
		return
	pending_bark = Dialog.bark(data, kind, state.party, state.barks_used, rng)


## Efter lägret: tillbaka till grottan, eller hem när bossen är besegrad.
func after_camp() -> void:
	ui("ui_confirm", -8.0)
	profile.keep_worn(state.equipped, state.party)  # 0.26.3: bytena vid lägerelden varar
	camp_mode = "victory"
	_save()
	if state.floor_cleared():
		if state.is_last_floor():
			profile.clear_depth(state.depth, state.realm)
			state.finished = true
			_clear_run()
			_save()
			get_tree().change_scene_to_file(BASE_SCENE)
			return
	save_run()
	get_tree().change_scene_to_file(ROOM_MAP_SCENE)


## Questen blev klar: silver och kanske en perk-poäng.
func _after_quest_check(just_done: bool) -> void:
	if just_done or (state.quest.get("done", false) and not state.quest.get("rewarded", false)):
		state.quest.rewarded = true
		# 0.27: en quest per våning låser trappan eller bossen. Den första ger halva silvret (0.27.0); perk-poängen
		# och hela belöningen kommer med den sista våningens quest (en Realm Quest per körning, som förut).
		if not state.is_last_floor():
			room_result += " Questen är klar: +%d silver, och trappan är öppen!" % profile.floor_quest_silver(state.depth)
			_save()
			return
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
		if victory and state.practice_encounter == INTRO_PRACTICE:
			intro("practice_won")
			get_tree().change_scene_to_file(BASE_SCENE)
			return
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
				narrate("first_boss")
	mark_sneak(data, profile, state)
	offer = state.trophy_offer(data, rng, state.last_elites, profile.unlocked_boss_trophies())
	quest_reward = {}
	room_result = ""
	var done_now := state.battle_won()
	# 0.27: det gruppen vaktade (en fånge, en skatt, ett quest-föremål) tas när den är besegrad.
	match state.current_room().get("kind", ""):
		"prisoner":
			room_result = rescue_prisoner()  # 0.23: vakterna är besegrade, fången befrias
			pending_rescue = room_result
		"treasure":
			treasure()
		"item":
			done_now = state.collect_item() or done_now
			room_result = "Föremålet är ert. " + RunState.quest_text(state.quest)
	_after_quest_check(done_now)
	camp_mode = "victory"
	_trophy_sound()
	camp_chosen = ""
	for t in offer:
		profile.add_trophy(t)
	_save()
	save_run()
	get_tree().change_scene_to_file(CAMP_SCENE)


## 0.25 (plan §2): berättarens rader för ett tillfälle som bara händer en gång per profil (Profile.narrated).
func narrate(kind: String) -> void:
	if profile.narrated.has(kind):
		return
	var lines: Array = data.dialog.get("narrator", {}).get(kind, [])
	if lines.is_empty():
		return
	profile.narrated.append(kind)
	for l in lines:
		pending_story.append({"who": StoryBox.NARRATOR, "text": String(l)})


## 0.25 (plan §1.5): under introts första nedstigning går paladinen ned ensam, och direkt efter den första striden dyker
## Imma upp. 0.25.1: striden bara märker att hon väntar (segerskärmen och trofén gäller dem som var med); hon ansluter
## när sällskapet är tillbaka på rumskartan (imma_sneaks, anropas därifrån).
static func mark_sneak(game_data: Dictionary, prof: Profile, run_state: RunState) -> void:
	if Intro.current(game_data, prof).get("id", "") == "descent" and not run_state.party.has("imma") \
			and not run_state.practice:
		run_state.joins_next = "imma"


func imma_sneaks() -> void:
	if state.join_waiting(data, profile) == "":
		return
	pending_story += Intro.speech(data.intro.get("imma_joins", {}).get("lines", []))
	pending_bark = {}
	_save()
	save_run()


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
	var f: FileAccess = null if dev_profile else FileAccess.open(MACROS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"macros": macros, "assignment": assignment, "default_action": default_action}, "\t"))
	# Introt: Paladinens första makrorad.
	if not macros.get(assignment.get("paladin", "paladin"), {}).get("lines", []).is_empty():
		intro("macro_line")


## Startmakron från data/macros.json första gången; sedan spelarens egna. fresh = som en ny profil (--new-profile).
func _load_macros(fresh := false) -> void:
	var parsed: Variant = null
	if fresh:
		macros = {}
		assignment = {}
		default_action = {}
	elif FileAccess.file_exists(MACROS_PATH):
		parsed = JSON.parse_string(FileAccess.get_file_as_string(MACROS_PATH))
	if parsed is Dictionary and parsed.has("macros"):
		macros = parsed.macros
		assignment = parsed.get("assignment", {})
		default_action = parsed.get("default_action", {})
	else:
		macros = data.macros.duplicate(true)
		for hero_id in data.macros:
			assignment[hero_id] = hero_id
		# 0.23: en ny profil börjar med få rader (VD:n: "inte många makron i början"). Paladinens första rad skriver
		# man själv i introt; följeslagarna har en eller två, och spelet föreslår fler när nya sorters hjältar kommer.
		if not profile.intro_done:
			macros.paladin.lines = []
			for hero_id in macros:
				if hero_id != "paladin":
					macros[hero_id].lines = starter_lines(data, hero_id, macros[hero_id].lines)
	# 0.23: nya följeslagare får sina startmakron även i en sparad makrofil.
	for hero_id in data.macros:
		if not macros.has(hero_id):
			macros[hero_id] = data.macros[hero_id].duplicate(true)
	# 0.22: Förnyelse blev Läkning och Helig sköld blev Beskyddad; sparade makron frågar efter de nya.
	const RENAMED := {"renew": "mending", "holy_shield": "protected"}
	for m in macros.values():
		for line in m.get("lines", []):
			if line.get("cond", "") in ["has_status", "lacks_status"] and RENAMED.has(line.get("value", "")):
				line.value = RENAMED[line.value]
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
	apply_name()


## Sparar efter ett val i basen; sound är menyljudet för valet.
func save(sound := "ui_toggle") -> void:
	ui(sound, -10.0)
	_save()


func _save() -> void:
	if dev_profile:
		return
	profile.save(PROGRESS_PATH)
