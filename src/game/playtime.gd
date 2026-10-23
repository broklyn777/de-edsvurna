class_name Playtime
extends RefCounted
## Speltidsmätningen: hur lång tid en strid, en våning och en nedstigning tar när man spelar på riktigt. Bara aktiv tid:
## Run räknar med verklig tid (inte Engine.time_scale) och stannar klockan när appen ligger i bakgrunden, när spelet är
## pausat och när en hjälpruta eller inställningsrutan är öppen. Övningsgården räknas inte alls.
## Sparas i user://playtime.cfg, utanför sparplatserna, så att alla profiler räknas. Inget skickas någonstans.
## Ren logik utan noder: Run och striden anropar start_run/next_floor/start_battle/end_battle/finish_run och tick.

const PATH := "user://playtime.cfg"
const MAX_BATTLES := 200
const MAX_RUNS := 50
const KINDS := ["normal", "elite", "nemesis", "boss"]
const KIND_NAMES := {"normal": "Vanlig", "elite": "Elit", "nemesis": "Nemesis", "boss": "Boss"}
## Hur ofta löptiden skrivs till filen under en körning (aktiva sekunder), så att den överlever att appen dödas.
const SAVE_EVERY := 15.0

var path := PATH
## De senaste striderna: {sec, realm, depth, floor, kind, won, turns}.
var battles: Array = []
## De senaste körningarna: {sec, floors: [sek per våning], battles, outcome, realm, depth}.
## outcome: "boss" (klarad), "loss" (sällskapet föll), "forfeit" (GE UPP i striden), "home" (GÅ HEM).
var runs: Array = []
## Pågående körningar per sparplats ("1"–"3"): {sec, floors, battles, realm, depth}. En körning som fortsätter efter att
## spelet stängts räknar vidare härifrån.
var current := {}
## Sparplatsen vars körning klockan räknar just nu ("" = ingen).
var slot := ""
## Den pågående striden: {sec, realm, depth, floor, kind}, tom om ingen.
var battle := {}
## Sant om den senaste striden slutade med GE UPP (Run avgör då körningens utfall).
var last_forfeit := false
## --playtime-demo: påhittade siffror som aldrig sparas.
var demo := false
var _unsaved := 0.0


## Startar en ny nedstigning för sparplatsen (en tidigare oavslutad körning på samma plats skrivs över).
func start_run(slot_id: int, realm: String, depth: int) -> void:
	slot = str(slot_id)
	current[slot] = {"sec": 0.0, "floors": [0.0], "battles": 0, "realm": realm, "depth": depth}
	battle = {}
	save()


## Fortsätter sparplatsens körning efter en omstart. Falskt om ingen fanns (körningen började före mätningen).
func resume_run(slot_id: int, floor := 0) -> bool:
	var key := str(slot_id)
	battle = {}
	if not current.has(key):
		slot = ""
		return false
	slot = key
	var floors: Array = current[key].floors
	while floors.size() < floor + 1:
		floors.append(0.0)
	return true


## Klockan släpper körningen utan att avsluta den (byte av sparplats); den ligger kvar i current.
func suspend() -> void:
	slot = ""
	battle = {}
	save()


func active() -> bool:
	return slot != "" and current.has(slot)


## Trappan ned: nästa våning får egen tid.
func next_floor() -> void:
	if active():
		current[slot].floors.append(0.0)


## Stridens första tur. kind: "normal", "elite", "nemesis" eller "boss".
func start_battle(kind: String) -> void:
	if not active():
		return
	var c: Dictionary = current[slot]
	battle = {"sec": 0.0, "realm": c.realm, "depth": c.depth, "floor": c.floors.size() - 1, "kind": kind}


## Segerskärmen eller förlusten: striden sparas.
func end_battle(won: bool, turns: int, forfeit := false) -> void:
	last_forfeit = forfeit
	if battle.is_empty():
		return
	var b := battle.duplicate()
	b.sec = snappedf(float(b.sec), 0.1)
	b.won = won
	b.turns = turns
	battles.append(b)
	while battles.size() > MAX_BATTLES:
		battles.pop_front()
	if active():
		current[slot].battles = int(current[slot].battles) + 1
	battle = {}
	save()


## Nedstigningen är slut (hemma igen): körningen sparas och sparplatsens pågående körning tas bort.
func finish_run(outcome: String) -> void:
	battle = {}
	if not active():
		return
	var c: Dictionary = current[slot]
	var floors: Array = c.floors.map(func(s) -> float: return snappedf(float(s), 0.1))
	runs.append({"sec": snappedf(float(c.sec), 0.1), "floors": floors, "battles": int(c.battles), "outcome": outcome,
			"realm": c.realm, "depth": c.depth})
	while runs.size() > MAX_RUNS:
		runs.pop_front()
	current.erase(slot)
	slot = ""
	save()


## Aktiv tid som gått (sekunder i verklig tid). Run anropar bara när klockan ska gå.
func tick(dt: float) -> void:
	if dt <= 0.0 or not active():
		return
	var c: Dictionary = current[slot]
	c.sec = float(c.sec) + dt
	c.floors[c.floors.size() - 1] = float(c.floors[-1]) + dt
	if not battle.is_empty():
		battle.sec = float(battle.sec) + dt
	_unsaved += dt
	if _unsaved >= SAVE_EVERY:
		save()


## Snitten: {battle: [snitt sek, antal], run: [snitt sek, antal], kinds: {kind: [snitt sek, antal]}}.
## Körningarnas snitt räknar alla utfall (även förlust, GE UPP och GÅ HEM): det är så länge en nedstigning varar.
func averages() -> Dictionary:
	var kinds := {}
	for k in KINDS:
		kinds[k] = _avg(battles.filter(func(b) -> bool: return b.kind == k))
	return {"battle": _avg(battles), "run": _avg(runs), "kinds": kinds}


static func _avg(list: Array) -> Array:
	if list.is_empty():
		return [0.0, 0]
	var total := 0.0
	for e in list:
		total += float(e.sec)
	return [total / list.size(), list.size()]


## Raderna i inställningsrutan.
func summary_lines() -> Array[String]:
	var a := averages()
	var lines: Array[String] = []
	lines.append("Strid: snitt %s (%d st)  ·  Körning: snitt %s (%d st)" % [
			_minutes(a.battle[0], a.battle[1], 1), a.battle[1], _minutes(a.run[0], a.run[1], 0), a.run[1]])
	var parts: Array[String] = []
	for k in KINDS:
		if int(a.kinds[k][1]) > 0:
			parts.append("%s %s" % [KIND_NAMES[k], _minutes(a.kinds[k][0], a.kinds[k][1], 1)])
	lines.append("  ·  ".join(parts) if not parts.is_empty() else "Inga strider mätta än.")
	return lines


## Minuter med svensk decimal ("3,4 min"); "–" när inget är mätt.
static func _minutes(sec: float, n: int, decimals: int) -> String:
	if n <= 0:
		return "–"
	var s := ("%." + str(decimals) + "f") % (sec / 60.0)
	return s.replace(".", ",") + " min"


## Vilken sorts strid rutan är (för snitten per typ).
static func battle_kind(room: Dictionary, last_floor: bool) -> String:
	if room.get("boss", false) or (last_floor and room.get("kind", "") == "end"):
		return "boss"
	if room.get("nemesis", false):
		return "nemesis"
	if room.get("elite", false) or room.get("kind", "") == "elite":
		return "elite"
	return "normal"


func reset() -> void:
	battles = []
	runs = []
	# Den pågående körningen nollställs också, men fortsätter räkna från noll.
	for key in current:
		current[key].sec = 0.0
		current[key].floors = [0.0]
		current[key].battles = 0
	battle = {}
	save()


func save() -> void:
	_unsaved = 0.0
	if demo:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("playtime", "battles", battles)
	cfg.set_value("playtime", "runs", runs)
	cfg.set_value("playtime", "current", current)
	cfg.save(path)


static func load_from(file := PATH) -> Playtime:
	var p := Playtime.new()
	p.path = file
	var cfg := ConfigFile.new()
	if cfg.load(file) == OK:
		p.battles = cfg.get_value("playtime", "battles", [])
		p.runs = cfg.get_value("playtime", "runs", [])
		p.current = cfg.get_value("playtime", "current", {})
	return p


## --playtime-demo: påhittade siffror för skärmdumpar (sparas aldrig).
static func make_demo() -> Playtime:
	var p := Playtime.new()
	p.demo = true
	var secs := {"normal": [150.0, 190.0, 120.0, 210.0, 170.0], "elite": [290.0, 340.0], "nemesis": [260.0],
			"boss": [460.0]}
	for k in secs:
		for s in secs[k]:
			p.battles.append({"sec": s, "realm": "crypt", "depth": 1, "floor": 0, "kind": k, "won": true, "turns": 24})
	for s in [2280.0, 2650.0, 1900.0]:
		p.runs.append({"sec": s, "floors": [s * 0.45, s * 0.55], "battles": 9, "outcome": "boss", "realm": "crypt",
				"depth": 1})
	return p
