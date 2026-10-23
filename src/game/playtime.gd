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
## De senaste striderna: {sec, realm, depth, floor, kind, won, turns, party_level, enemy_level}. Nivåerna (sällskapets
## snitt och fiendernas väntade nivå, HeroStats.enemy_level) finns sedan 0.31; äldre poster saknar dem.
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


## Stridens första tur. kind: "normal", "elite", "nemesis" eller "boss". party_level: sällskapets snittnivå,
## enemy_level: fiendernas väntade nivå (negativt = okänt, sparas inte).
func start_battle(kind: String, party_level := -1.0, enemy_level := -1.0) -> void:
	if not active():
		return
	var c: Dictionary = current[slot]
	battle = {"sec": 0.0, "realm": c.realm, "depth": c.depth, "floor": c.floors.size() - 1, "kind": kind}
	if party_level >= 0.0 and enemy_level >= 0.0:
		battle.party_level = snappedf(party_level, 0.1)
		battle.enemy_level = snappedf(enemy_level, 0.1)


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
	# 0.31: snitt per djup, och om sällskapet låg över, i nivå med eller under fienderna.
	var per_depth: Array[String] = []
	var levels: Array[String] = []
	for d in depths():
		per_depth.append("Djup %d: %s (%d)" % [d.depth, _minutes(d.sec, d.n, 1), d.n])
		if int(d.leveled) > 0:
			levels.append("djup %d %s (%s)" % [d.depth, level_word(d.diff), _signed(d.diff)])
	if not per_depth.is_empty():
		lines.append(" · ".join(per_depth))
	if not levels.is_empty():
		lines.append("Nivå mot fienderna: " + " · ".join(levels))
	return lines


## Snitten per djup, lägst djup först: [{depth, sec, n, leveled, diff}]. diff = sällskapets nivå minus fiendernas i snitt,
## över de strider som har nivåer (leveled st).
func depths() -> Array:
	var by := {}
	for b in battles:
		var d := int(b.get("depth", 1))
		if not by.has(d):
			by[d] = {"depth": d, "sec": 0.0, "n": 0, "leveled": 0, "diff": 0.0}
		var e: Dictionary = by[d]
		e.sec = float(e.sec) + float(b.sec)
		e.n = int(e.n) + 1
		if b.has("party_level") and b.has("enemy_level"):
			e.leveled = int(e.leveled) + 1
			e.diff = float(e.diff) + float(b.party_level) - float(b.enemy_level)
	var keys := by.keys()
	keys.sort()
	var out := []
	for d in keys:
		var e: Dictionary = by[d]
		e.sec = float(e.sec) / int(e.n)
		if int(e.leveled) > 0:
			e.diff = float(e.diff) / int(e.leveled)
		out.append(e)
	return out


## Inom ±2 nivåer räknas som i nivå (VD 2026-10-23).
const LEVEL_MARGIN := 2.0


static func level_word(diff: float) -> String:
	if diff > LEVEL_MARGIN:
		return "över"
	if diff < -LEVEL_MARGIN:
		return "under"
	return "i nivå"


## "+1,2" / "−2,5" med svensk decimal.
static func _signed(v: float) -> String:
	var s := "%.1f" % absf(v)
	return ("−" if v < -0.05 else "+") + s.replace(".", ",")


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
			p.battles.append({"sec": s, "realm": "crypt", "depth": 1, "floor": 0, "kind": k, "won": true, "turns": 24,
					"party_level": 3.5, "enemy_level": 3.0})
	# 0.31: ett djup till (med nivåer, under fienderna) och en gammal post utan nivå.
	for s in [230.0, 260.0, 250.0]:
		p.battles.append({"sec": s, "realm": "chapel", "depth": 2, "floor": 1, "kind": "normal", "won": true, "turns": 30,
				"party_level": 5.0, "enemy_level": 9.0})
	p.battles.append({"sec": 300.0, "realm": "crypt", "depth": 3, "floor": 0, "kind": "normal", "won": false, "turns": 41})
	for s in [2280.0, 2650.0, 1900.0]:
		p.runs.append({"sec": s, "floors": [s * 0.45, s * 0.55], "battles": 9, "outcome": "boss", "realm": "crypt",
				"depth": 1})
	return p
