class_name RoomMap
extends RefCounted
## Rumskartan för en våning (0.18, Siralims Realm-karta som en 2D-karta med vägval). Ren logik.
##
## En våning har 3–4 steg med 2–3 rum var och sedan våningens slut (bossen på sista våningen, annars
## våningens svåraste strid). Varje rum leder till 1–2 rum i nästa steg, och alla rum i nästa steg
## går att nå. Krav som testas: minst 2 strider, högst 1 elit, minst 1 helgedom eller skattkammare,
## en lägereld i steget före slutet och minst en väg utan elit.
##
## Rum: {id, kind, step, slot, next: [id], encounter, nemesis}. kind är en av KINDS. Portalen har
## dessutom "side": [rum], en kort sidodel som spelas i ordning (svårare strid, sedan skatt).

const KINDS := ["battle", "elite", "treasure", "shrine", "campfire", "portal", "end"]
const MIN_STEPS := 3
const MAX_STEPS := 4
const MIN_ROOMS := 2
const MAX_ROOMS := 3
## Hur ofta varje rumstyp slumpas i ett vanligt steg (lägerelden sätts i steget före slutet).
const WEIGHTS := {"battle": 6, "elite": 1, "treasure": 2, "shrine": 2, "portal": 1}

## steps[i] = [rum]; slutet ligger i end.
var steps: Array = []
var end := {}
var floor := 0
var last_floor := false


## Slumpar en våning tills kraven håller. pool: möten för vanliga strider; end_encounter: slutets
## möte. want_shrines: minsta antal helgedomar (för questen Rening).
static func generate(seed_value: int, floor_index: int, is_last: bool, pool: Array, end_encounter: String,
		want_shrines := 0) -> RoomMap:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for attempt in 200:
		var m := _roll(rng, floor_index, is_last, pool, end_encounter)
		if m.problems(want_shrines).is_empty():
			return m
	# Säkerhetsnät: en enkel våning som alltid håller kraven.
	return _fallback(floor_index, is_last, pool, end_encounter)


static func _roll(rng: RandomNumberGenerator, floor_index: int, is_last: bool, pool: Array,
		end_encounter: String) -> RoomMap:
	var m := RoomMap.new()
	m.floor = floor_index
	m.last_floor = is_last
	var n_steps := rng.randi_range(MIN_STEPS, MAX_STEPS)
	for s in n_steps:
		var row := []
		var n := rng.randi_range(MIN_ROOMS, MAX_ROOMS)
		for i in n:
			var kind := _weighted(rng)
			if s == n_steps - 1 and i == 0:
				kind = "campfire"
			row.append(_room("f%d_s%d_r%d" % [floor_index, s, i], kind, s, i, pool, rng))
		if s == n_steps - 1:
			# Lägerelden ligger inte alltid först (blandas med fröets slump, inte den globala).
			for i in range(row.size() - 1, 0, -1):
				var j := rng.randi() % (i + 1)
				var tmp: Dictionary = row[i]
				row[i] = row[j]
				row[j] = tmp
			for i in row.size():
				row[i].slot = i
				row[i].id = "f%d_s%d_r%d" % [floor_index, s, i]
		m.steps.append(row)
	m.end = {"id": "f%d_end" % floor_index, "kind": "end", "step": n_steps, "slot": 0, "next": [],
			"encounter": end_encounter, "boss": is_last}
	m._link(rng)
	return m


static func _weighted(rng: RandomNumberGenerator) -> String:
	var total := 0
	for k in WEIGHTS:
		total += WEIGHTS[k]
	var r := rng.randi() % total
	for k in WEIGHTS:
		r -= WEIGHTS[k]
		if r < 0:
			return k
	return "battle"


static func _room(id: String, kind: String, step: int, slot: int, pool: Array, rng: RandomNumberGenerator) -> Dictionary:
	var r := {"id": id, "kind": kind, "step": step, "slot": slot, "next": []}
	if kind in ["battle", "elite"]:
		r.encounter = pool[rng.randi() % pool.size()]
	elif kind == "portal":
		r.side = [{"id": id + "_p0", "kind": "portal_battle", "encounter": pool[rng.randi() % pool.size()]},
				{"id": id + "_p1", "kind": "treasure"}]
	return r


## Stigar: varje rum leder till ett eller två närliggande rum i nästa steg, och alla rum nås.
func _link(rng: RandomNumberGenerator) -> void:
	for s in steps.size():
		var row: Array = steps[s]
		if s == steps.size() - 1:
			for r in row:
				r.next = [end.id]
			continue
		var nxt: Array = steps[s + 1]
		for i in row.size():
			var j := roundi(float(i) * (nxt.size() - 1) / maxf(row.size() - 1, 1))
			row[i].next = [nxt[j].id]
			var k := j + (1 if rng.randf() < 0.5 else -1)
			if k >= 0 and k < nxt.size() and rng.randf() < 0.6:
				row[i].next.append(nxt[k].id)
		for room in nxt:
			if not row.any(func(r: Dictionary) -> bool: return r.next.has(room.id)):
				var closest: Dictionary = row[mini(room.slot, row.size() - 1)]
				closest.next.append(room.id)


static func _fallback(floor_index: int, is_last: bool, pool: Array, end_encounter: String) -> RoomMap:
	var m := RoomMap.new()
	m.floor = floor_index
	m.last_floor = is_last
	var kinds := [["battle", "treasure"], ["battle", "shrine"], ["campfire", "battle"]]
	for s in kinds.size():
		var row := []
		for i in kinds[s].size():
			var r := {"id": "f%d_s%d_r%d" % [floor_index, s, i], "kind": kinds[s][i], "step": s, "slot": i, "next": []}
			if r.kind == "battle":
				r.encounter = pool[0]
			row.append(r)
		m.steps.append(row)
	m.end = {"id": "f%d_end" % floor_index, "kind": "end", "step": kinds.size(), "slot": 0, "next": [],
			"encounter": end_encounter, "boss": is_last}
	for s in m.steps.size():
		for i in m.steps[s].size():
			m.steps[s][i].next = [m.end.id] if s == m.steps.size() - 1 else [m.steps[s + 1][0].id, m.steps[s + 1][1].id]
	return m


# --- Frågor -------------------------------------------------------------------

func all_rooms() -> Array:
	var out := []
	for row in steps:
		out.append_array(row)
	out.append(end)
	return out


func room(room_id: String) -> Dictionary:
	for r in all_rooms():
		if r.id == room_id:
			return r
	return {}


## Rummen man kan gå till härnäst: första steget om man inte har börjat, annars rummets stigar.
func choices(current_id: String) -> Array:
	if current_id == "":
		return steps[0].map(func(r: Dictionary) -> String: return r.id)
	return room(current_id).get("next", [])


func count(kind: String) -> int:
	return all_rooms().filter(func(r: Dictionary) -> bool: return r.kind == kind).size()


## Vad som bryter mot kraven (tom lista = giltig våning).
func problems(want_shrines := 0) -> Array[String]:
	var out: Array[String] = []
	if count("battle") + count("elite") < 2:
		out.append("för få strider")
	if count("elite") > 1:
		out.append("mer än en elit")
	if count("shrine") + count("treasure") < 1:
		out.append("ingen helgedom eller skattkammare")
	if count("shrine") < want_shrines:
		out.append("för få helgedomar")
	if not steps[steps.size() - 1].any(func(r: Dictionary) -> bool: return r.kind == "campfire"):
		out.append("ingen lägereld före slutet")
	if not _path_without_elite():
		out.append("ingen väg utan elit")
	for s in range(1, steps.size()):
		for r in steps[s]:
			if not steps[s - 1].any(func(p: Dictionary) -> bool: return p.next.has(r.id)):
				out.append("rummet %s går inte att nå" % r.id)
	return out


func _path_without_elite() -> bool:
	var reach: Array = steps[0].filter(func(r: Dictionary) -> bool: return r.kind != "elite")
	for s in range(1, steps.size()):
		reach = steps[s].filter(func(r: Dictionary) -> bool:
			return r.kind != "elite" and reach.any(func(p: Dictionary) -> bool: return p.next.has(r.id)))
	return not reach.is_empty()


## Kartan som en Dictionary (för run.cfg) och tillbaka.
func to_dict() -> Dictionary:
	return {"steps": steps, "end": end, "floor": floor, "last_floor": last_floor}


static func from_dict(d: Dictionary) -> RoomMap:
	var m := RoomMap.new()
	m.steps = d.get("steps", [])
	m.end = d.get("end", {})
	m.floor = int(d.get("floor", 0))
	m.last_floor = d.get("last_floor", false)
	return m
