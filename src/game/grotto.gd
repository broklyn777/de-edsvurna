class_name Grotto
extends RefCounted
## Grottan för en våning (0.27, docs/plan/0.27-grottan.md §1, Siralims Realm som en plats man utforskar). Ren logik.
##
## 8×8 rutor, öppen plan utan klippor. Start vid en kant; trappan (första våningen) eller bossen (den sista) långt bort,
## synlig från start men låst tills våningens quest är klar. Fiendegrupper står på rutorna; en grupp man har sett spärrar
## de obesökta rutorna intill sig tills den är besegrad (Dungelot). Allt slumpas ur ett frö efter reglerna i problems().
##
## En ruta: {kind, encounter?, tier?, elite?, nemesis?, beaten?, done?, hero?, guarded?}. kind är en av KINDS:
##   empty, start, stairs, end (bossen), battle (en grupp), elite, treasure, shrine, campfire, item (quest-föremål), prisoner.
## En ruta med "encounter" har en grupp som måste besegras först (en bevakad skatt, ett föremål, en fånge).
## tier (0–2) är gruppens svårighet: vilken av Realmens pooler den kommer ur, fiendernas nivå och silvret.

const SIZE := 8
const KINDS := ["empty", "start", "stairs", "end", "battle", "elite", "treasure", "shrine", "campfire", "item", "prisoner",
		"object"]
## Realmens föremål per våning (0.28.2, data/objects.json): så många olika ur Realmens lista.
const OBJECTS_MIN := 2
const OBJECTS_MAX := 3
## Hur långt från start målet (trappan, bossen) och eliten minst ligger, och lägereldens avstånd till eliten.
const GOAL_MIN_DIST := 5
const ELITE_MIN_DIST := 4
const CAMPFIRE_NEAR_ELITE := 3
## Grupper så här långt från start (och längre) kommer ur nästa, svårare pool (VAL).
const FAR_TIER_DIST := 7
## Grupper per våning utöver eliten, vakterna inräknade (0.27.0: 5–6, så att en körning blir ~8–10 strider; först 6–8).
const GROUPS_MIN := 5
const GROUPS_MAX := 6

var cells: Array = []
var floor := 0
var last_floor := false
var start := 0
var goal := 0


# --- Rutnätet -------------------------------------------------------------------

static func xy(i: int) -> Vector2i:
	return Vector2i(i % SIZE, i / SIZE)


static func idx(p: Vector2i) -> int:
	return p.y * SIZE + p.x


static func dist(a: int, b: int) -> int:
	var pa := xy(a)
	var pb := xy(b)
	return absi(pa.x - pb.x) + absi(pa.y - pb.y)


## Grannarna i fyra riktningar.
static func neighbors(i: int) -> Array[int]:
	var out: Array[int] = []
	var p := xy(i)
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var q: Vector2i = p + d
		if q.x >= 0 and q.y >= 0 and q.x < SIZE and q.y < SIZE:
			out.append(idx(q))
	return out


func cell(i: int) -> Dictionary:
	return cells[i] if i >= 0 and i < cells.size() else {}


## En grupp som ännu står på rutan.
func has_group(i: int) -> bool:
	var c := cell(i)
	return c.has("encounter") and not c.get("beaten", false)


func indices(kind: String) -> Array[int]:
	var out: Array[int] = []
	for i in cells.size():
		if cells[i].kind == kind:
			out.append(i)
	return out


## Alla rutor med en grupp (vanliga, elit, vakter och bossen).
func group_cells() -> Array[int]:
	var out: Array[int] = []
	for i in cells.size():
		if cells[i].has("encounter"):
			out.append(i)
	return out


# --- Generering --------------------------------------------------------------------

## Slumpar en våning tills reglerna håller. pools: [pool för tier 0, 1, 2] (möten ur realms.json "pools"); boss: bossens
## möte (sista våningen); guard: ett starkare möte för den bevakade skatten; quest: våningens quest ({type, goal});
## prisoner: {hero, first, guarded} eller {}. elite_pools (0.27, realms.json "elite_pools"): elitgrupperna per våning;
## tom = eliten kommer ur den vanliga poolen och får en påtvingad elitvariant som förut.
static func generate(seed_value: int, floor_index: int, is_last: bool, pools: Array, boss: String, guard: String,
		quest: Dictionary, prisoner := {}, elite_pools := [], objects := []) -> Grotto:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for attempt in 400:
		var g := _roll(rng, floor_index, is_last, pools, boss, guard, quest, prisoner, elite_pools)
		if g != null and g.problems(quest).is_empty():
			g._place_objects(seed_value, objects)
			return g
	push_warning("Grotto: inget frö höll reglerna (%d), använder det sista försöket" % seed_value)
	var last := _roll(rng, floor_index, is_last, pools, boss, guard, quest, prisoner, elite_pools)
	last._place_objects(seed_value, objects)
	return last


## 0.28.2: Realmens föremål läggs sist på tomma rutor (minst två steg från start), ur ett eget frö så att resten av
## grottan blir densamma som förut.
func _place_objects(seed_value: int, objects: Array) -> void:
	if objects.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 31 + 7
	var pool := objects.duplicate()
	var n := mini(rng.randi_range(OBJECTS_MIN, OBJECTS_MAX), pool.size())
	for k in n:
		var id: String = pool.pop_at(rng.randi() % pool.size())
		var at := _free_cell(rng, func(i: int) -> bool: return dist(i, start) >= 2)
		if at >= 0:
			cells[at] = {"kind": "object", "obj": id}


static func _roll(rng: RandomNumberGenerator, floor_index: int, is_last: bool, pools: Array, boss: String,
		guard: String, quest: Dictionary, prisoner: Dictionary, elite_pools := []) -> Grotto:
	var g := Grotto.new()
	g.floor = floor_index
	g.last_floor = is_last
	for i in SIZE * SIZE:
		g.cells.append({"kind": "empty"})
	# Start vid en kant, målet långt bort (bland de längsta avstånden, minst GOAL_MIN_DIST).
	var edge: Array[int] = []
	for i in SIZE * SIZE:
		var p := xy(i)
		if p.x == 0 or p.y == 0 or p.x == SIZE - 1 or p.y == SIZE - 1:
			edge.append(i)
	g.start = edge[rng.randi() % edge.size()]
	var far := _cells_where(func(i: int) -> bool: return dist(i, g.start) >= maxi(GOAL_MIN_DIST, _max_dist(g.start) - 3))
	g.goal = far[rng.randi() % far.size()]
	g.cells[g.start] = {"kind": "start"}
	g.cells[g.goal] = {"kind": "end", "encounter": boss, "tier": 2, "boss": true} if is_last else {"kind": "stairs"}
	var base_tier := floor_index  # första våningen tier 0–1, den andra 1–2
	var tier_for := func(i: int) -> int: return mini(base_tier + (1 if dist(i, g.start) >= FAR_TIER_DIST else 0), 2)
	var pick := func(tier: int) -> String:
		var pool: Array = pools[clampi(tier, 0, pools.size() - 1)]
		return pool[rng.randi() % pool.size()]
	# Elit (två om questen är Rensa), minst ELITE_MIN_DIST från start; den första är Nemesis i en Jakt.
	var n_elites := 2 if quest.get("type", "") == "clear" else 1
	var elites: Array[int] = []
	for e in n_elites:
		var at := g._free_cell(rng, func(i: int) -> bool: return dist(i, g.start) >= ELITE_MIN_DIST and dist(i, g.goal) >= 2)
		if at < 0:
			return null
		var tier := mini(base_tier + 1, 2)
		var enc := ""
		if elite_pools.is_empty():
			enc = pick.call(tier)
		else:
			var ep: Array = elite_pools[clampi(floor_index, 0, elite_pools.size() - 1)]
			enc = ep[rng.randi() % ep.size()]
		g.cells[at] = {"kind": "elite", "encounter": enc, "tier": tier, "elite": true}
		if e == 0 and quest.get("type", "") == "hunt":
			g.cells[at].nemesis = true
		elites.append(at)
	# En lägereld inom CAMPFIRE_NEAR_ELITE från den första eliten, och kanske en till någon annanstans.
	var fire := g._free_cell(rng, func(i: int) -> bool: return dist(i, elites[0]) <= CAMPFIRE_NEAR_ELITE and dist(i, elites[0]) >= 1)
	if fire < 0:
		return null
	g.cells[fire] = {"kind": "campfire"}
	if rng.randf() < 0.5:
		var fire2 := g._free_cell(rng, func(i: int) -> bool: return dist(i, fire) >= 4)
		if fire2 >= 0:
			g.cells[fire2] = {"kind": "campfire"}
	# Quest-föremål (Samla): 2–3, i olika fjärdedelar, alltid bevakade av en grupp.
	var guards := 0
	if quest.get("type", "") == "collect":
		var used_quadrants := []
		for n in int(quest.get("goal", 2)):
			var at := g._free_cell(rng, func(i: int) -> bool:
				return not used_quadrants.has(_quadrant(i)) and dist(i, g.start) >= 3)
			if at < 0:
				return null
			used_quadrants.append(_quadrant(at))
			g.cells[at] = {"kind": "item", "encounter": pick.call(tier_for.call(at)), "tier": tier_for.call(at)}
			guards += 1
	# Fången: den första tidigt och obevakad, de andra bevakade av en grupp.
	if not prisoner.is_empty():
		var first: bool = prisoner.get("first", false)
		var at := g._free_cell(rng, func(i: int) -> bool:
			return dist(i, g.start) >= 2 and dist(i, g.start) <= (3 if first else 7) and (first or dist(i, g.start) >= 3))
		if at < 0:
			return null
		g.cells[at] = {"kind": "prisoner", "hero": prisoner.hero, "guarded": prisoner.get("guarded", not first)}
		if g.cells[at].guarded:
			g.cells[at].encounter = pick.call(tier_for.call(at))
			g.cells[at].tier = tier_for.call(at)
			guards += 1
	# Skatter: 1–2 bevakade (en med ett starkare möte, en bit bort) och 3–4 obevakade, spridda.
	var n_guarded := 1 if guards >= 2 else rng.randi_range(1, 2)
	for n in n_guarded:
		var at := g._free_cell(rng, func(i: int) -> bool: return dist(i, g.start) >= 4)
		if at < 0:
			return null
		var tier: int = tier_for.call(at)
		# VAL: vakten är lika svår som området runt den (Realmens starkare "floors"-möte blev för hårt för en ensam
		# paladin på första nedstigningen); skatten bakom den är bättre (Grotto: guarded).
		g.cells[at] = {"kind": "treasure", "guarded": true, "encounter": pick.call(tier), "tier": tier}
		guards += 1
	var treasures: Array[int] = []
	for n in rng.randi_range(3, 4):
		var at := g._free_cell(rng, func(i: int) -> bool:
			return treasures.all(func(t: int) -> bool: return dist(i, t) >= 3) and dist(i, g.start) >= 1)
		if at < 0:
			at = g._free_cell(rng, func(i: int) -> bool: return dist(i, g.start) >= 1)
		if at < 0:
			return null
		g.cells[at] = {"kind": "treasure"}
		treasures.append(at)
	var shrine := g._free_cell(rng, func(i: int) -> bool: return dist(i, g.start) >= 2)
	if shrine < 0:
		return null
	g.cells[shrine] = {"kind": "shrine"}
	# Vanliga grupper tills det finns GROUPS_MIN–GROUPS_MAX grupper utöver eliten (vakterna räknas).
	var want := rng.randi_range(GROUPS_MIN, GROUPS_MAX)
	for n in maxi(want - guards, 0):
		var at := g._free_cell(rng, func(i: int) -> bool: return dist(i, g.start) >= 2)
		if at < 0:
			return null
		g.cells[at] = {"kind": "battle", "encounter": pick.call(tier_for.call(at)), "tier": tier_for.call(at)}
	return g


static func _max_dist(from: int) -> int:
	var m := 0
	for i in SIZE * SIZE:
		m = maxi(m, dist(from, i))
	return m


static func _cells_where(ok: Callable) -> Array[int]:
	var out: Array[int] = []
	for i in SIZE * SIZE:
		if ok.call(i):
			out.append(i)
	return out


static func _quadrant(i: int) -> int:
	var p := xy(i)
	return (1 if p.x >= SIZE / 2 else 0) + (2 if p.y >= SIZE / 2 else 0)


## En tom ruta som uppfyller villkoret (slumpad), eller −1.
func _free_cell(rng: RandomNumberGenerator, ok: Callable) -> int:
	var options: Array[int] = []
	for i in cells.size():
		if cells[i].kind == "empty" and ok.call(i):
			options.append(i)
	return options[rng.randi() % options.size()] if not options.is_empty() else -1


# --- Reglerna --------------------------------------------------------------------

## Vad som bryter mot placeringsreglerna (tom lista = giltig våning).
func problems(quest := {}) -> Array[String]:
	var out: Array[String] = []
	var p := xy(start)
	if not (p.x == 0 or p.y == 0 or p.x == SIZE - 1 or p.y == SIZE - 1):
		out.append("start inte vid en kant")
	if dist(start, goal) < GOAL_MIN_DIST:
		out.append("målet för nära start")
	var groups := group_cells().filter(func(i: int) -> bool: return i != goal)
	var plain := groups.filter(func(i: int) -> bool: return cells[i].kind != "elite")
	if plain.size() < GROUPS_MIN or plain.size() > GROUPS_MAX:
		out.append("%d grupper (%d–%d)" % [plain.size(), GROUPS_MIN, GROUPS_MAX])
	var elites := indices("elite")
	if elites.is_empty():
		out.append("ingen elit")
	for e in elites:
		if dist(e, start) < ELITE_MIN_DIST:
			out.append("eliten för nära start")
	if not elites.is_empty() and not indices("campfire").any(func(f: int) -> bool: return dist(f, elites[0]) <= CAMPFIRE_NEAR_ELITE):
		out.append("ingen lägereld nära eliten")
	for i in groups:
		if dist(i, start) <= 1:
			out.append("en grupp bredvid start")
	# Högst två grupper intill varandra: inga grupper i klungor om tre eller fler.
	for i in groups:
		if _cluster(i, groups).size() > 2:
			out.append("en klunga med fler än två grupper")
			break
	var camps := indices("campfire").size()
	if camps < 1 or camps > 2:
		out.append("%d lägereldar (1–2)" % camps)
	if indices("shrine").size() != 1:
		out.append("inte en helgedom")
	var guarded := indices("treasure").filter(func(i: int) -> bool: return cells[i].has("encounter")).size()
	var open := indices("treasure").size() - guarded
	if guarded < 1 or guarded > 2 or open < 3 or open > 4:
		out.append("skatterna (%d bevakade, %d obevakade)" % [guarded, open])
	if quest.get("type", "") == "collect":
		var items := indices("item")
		if items.size() != int(quest.get("goal", 2)):
			out.append("fel antal föremål")
		var quads := {}
		for i in items:
			quads[_quadrant(i)] = true
			if not cells[i].has("encounter"):
				out.append("ett föremål utan vakt")
		if quads.size() != items.size():
			out.append("föremålen i samma fjärdedel")
	if quest.get("type", "") == "hunt" and not cells.any(func(c: Dictionary) -> bool: return c.get("nemesis", false)):
		out.append("ingen Nemesis")
	if quest.get("type", "") == "clear" and elites.size() < 2:
		out.append("för få elitgrupper för Rensa")
	return out


func _cluster(from: int, groups: Array) -> Array[int]:
	var seen: Array[int] = [from]
	var queue: Array[int] = [from]
	while not queue.is_empty():
		var i: int = queue.pop_front()
		for n in neighbors(i):
			if groups.has(n) and not seen.has(n):
				seen.append(n)
				queue.append(n)
	return seen


# --- Rörelse, dimma och spärrar -----------------------------------------------------

## Spärrad ruta: obesökt och intill en grupp man har sett men inte besegrat (Dungelot). seen: rutor med en sedd grupp.
func blocked(i: int, visited: Array, seen: Array) -> bool:
	if visited.has(i) or has_group(i):
		return false
	for n in neighbors(i):
		if seen.has(n) and has_group(n):
			return true
	return false


## Kortaste vägen från from till to genom besökta rutor (utan obesegrade grupper), utan from; [] om ingen finns.
## to får vara en obesökt granne till en besökt ruta (sista steget).
func path(from: int, to: int, visited: Array) -> Array[int]:
	if from == to:
		return []
	var prev := {from: -1}
	var queue: Array[int] = [from]
	while not queue.is_empty():
		var i: int = queue.pop_front()
		for n in neighbors(i):
			if prev.has(n):
				continue
			if n != to and (not visited.has(n) or has_group(n)):
				continue
			prev[n] = i
			if n == to:
				var out: Array[int] = []
				var c := to
				while c != from:
					out.push_front(c)
					c = prev[c]
				return out
			queue.append(n)
	return []


# --- Sparning ------------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"cells": cells, "floor": floor, "last_floor": last_floor, "start": start, "goal": goal}


static func from_dict(d: Dictionary) -> Grotto:
	var g := Grotto.new()
	g.cells = d.get("cells", [])
	g.floor = int(d.get("floor", 0))
	g.last_floor = d.get("last_floor", false)
	g.start = int(d.get("start", 0))
	g.goal = int(d.get("goal", 0))
	return g
