class_name NodeMap
extends RefCounted
## Kartprov (prototyp, grenen kartprov): nedstigningen som EN nodkarta i Slay the Spires stil i stället för grottans två
## våningar med 8×8 rutor och dimma. Ren logik.
##
## Båda våningarnas grottor (Grotto) slumpas precis som förut, med samma innehåll och regler; nodkartan slår ihop dem
## till en karta: den första våningens innehåll på de nedre raderna, den andras på de övre, bossen (eller väktaren)
## högst upp. Rutornas index finns kvar, så att striderna, lägret, helgedomen, föremålen, questen, sigillen och
## sparningen fungerar som förut. Allt syns från början: man planerar vägen.
##
##   rad 0            start (en nod)
##   rad 1..MID_ROWS  innehållet, sju kolumner, vägar som delar sig och går ihop (ingen elit på de två första raderna)
##   rad MID_ROWS+1   lägereldar före bossen
##   rad MID_ROWS+2   bossen/väktaren
##
## Vägarna byggs som i Slay the Spire: PATHS stigar börjar i var sin kolumn på rad 1 och går uppåt en kolumn snett
## eller rakt, utan att korsa varandra; noderna är de rutor stigarna passerar. Varje nod har därför 1–3 vägar upp.
## Grotto.nodes = {rows: [[cell]], row: [rad per cell, −1 = ingen nod], col: [kolumn per cell], up: [[cell] per cell]}.

const COLS := 7
const MID_ROWS := 12
const PATHS := 5
## Ingen elit på de första raderna (Slay the Spire: inga eliter på de första våningarna).
const ELITE_MIN_ROW := 3
## Raden där den andra våningens innehåll börjar (överlappar den första lite, så att halvorna flyter ihop).
const SECOND_FROM := 6
const FIRST_TO := 7
## Varje väg har minst så många strider före bossen.
const MIN_PATH_FIGHTS := 5
## Högst så många obevakade skatter och föremål per karta (resten av de två våningarnas tas bort).
const MAX_EXTRA := {"open_treasure": 4, "object": 4}


## Sant när nodkartan ska användas: kartprovets app (funktionstaggen "kartprov" i exporten, eller projektinställningen
## rpg007/prototype/node_map), eller --node-map på kommandoraden. --grid-map stänger av den.
static func enabled() -> bool:
	var args := OS.get_cmdline_user_args()
	if "--grid-map" in args:
		return false
	if "--node-map" in args or OS.has_feature("kartprov"):
		return true
	return bool(ProjectSettings.get_setting("rpg007/prototype/node_map", false))


static func is_node(g: Grotto, i: int) -> bool:
	return g != null and not g.nodes.is_empty() and i >= 0 and i < g.nodes.row.size() and int(g.nodes.row[i]) >= 0


static func row_of(g: Grotto, i: int) -> int:
	return int(g.nodes.row[i]) if is_node(g, i) else -1


static func col_of(g: Grotto, i: int) -> float:
	return float(g.nodes.col[i]) if is_node(g, i) else 3.0


static func up(g: Grotto, i: int) -> Array:
	return g.nodes.up[i] if is_node(g, i) else []


static func rows(g: Grotto) -> Array:
	return g.nodes.get("rows", [])


static func row_count(g: Grotto) -> int:
	return rows(g).size()


## Alla noder (rad för rad nedifrån).
static func all_nodes(g: Grotto) -> Array:
	var out := []
	for r in rows(g):
		out.append_array(r)
	return out


## "?" i Slay the Spire: helgedomar, Realmens föremål och fångar syns som okända tills man kommer dit.
static func is_unknown(c: Dictionary) -> bool:
	return c.get("kind", "") in ["shrine", "object", "prisoner"] and not c.has("encounter")


# --- Generering --------------------------------------------------------------------

## Slår ihop våningarnas grottor (a = första, b = den sista med bossen och questen) till en nedstigningskarta.
## pools: Realmens pooler per tier, för strider som fyller noder utan innehåll. quest: nedstigningens quest.
static func build_descent(a: Grotto, b: Grotto, seed_value: int, quest: Dictionary, pools: Array) -> Grotto:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 53 + 11
	var g := Grotto.new()
	g.floor = b.floor
	g.last_floor = true
	var off := a.cells.size()
	g.cells = a.cells.duplicate(true) + b.cells.duplicate(true)
	g.start = a.start
	g.goal = b.goal + off
	g.cells[a.goal] = {"kind": "empty"}  # trappan behövs inte
	g.cells[b.start + off] = {"kind": "empty"}
	var required: Array = []  # [cell, halva]
	var counts := {}
	for i in g.cells.size():
		if i == g.start or i == g.goal or g.cells[i].kind == "empty":
			continue
		# Två våningars skatter och föremål är för många för en karta där man går en väg: högst MAX_EXTRA av varje.
		var k := "open_treasure" if g.cells[i].kind == "treasure" and not g.cells[i].has("encounter") else String(g.cells[i].kind)
		counts[k] = int(counts.get(k, 0)) + 1
		if MAX_EXTRA.has(k) and counts[k] > int(MAX_EXTRA[k]):
			g.cells[i] = {"kind": "empty"}
			continue
		required.append([i, 0 if i < off else 1])
	var originals := g.cells.duplicate(true)
	var last := {}
	for attempt in 400:
		g.cells = originals.duplicate(true)  # fyllnaden och det som inte fick plats från förra försöket
		var n := _roll(g, rng, required, pools)
		if n.is_empty():
			continue
		g.nodes = n
		last = n
		if problems(g, quest).is_empty():
			return g
	push_warning("NodeMap: ingen karta höll reglerna (%d): %s" % [seed_value, ", ".join(problems(g, quest))])
	if last.is_empty():
		g.cells = originals.duplicate(true)
		g.nodes = _roll(g, rng, required, pools)
	return g


## Raderna en ruta får ligga på: [lägsta, högsta]. half 0 = den första våningens innehåll, 1 = den andras.
static func _row_span(c: Dictionary, half: int) -> Vector2i:
	var lo := 1 if half == 0 else SECOND_FROM
	var hi := FIRST_TO if half == 0 else MID_ROWS
	var tier := int(c.get("tier", half))
	match c.kind:
		"elite":
			return Vector2i(ELITE_MIN_ROW if half == 0 else 7, hi)
		"campfire":
			return Vector2i(maxi(lo, 2), mini(hi, MID_ROWS - 1))  # inte direkt under lägereldarnas rad
		"seal", "item":
			return Vector2i(4, MID_ROWS)
		"prisoner":
			return Vector2i(1, 5) if not c.has("encounter") else Vector2i(maxi(lo, 2), hi)
		"treasure":
			return Vector2i(maxi(lo, 2), hi) if c.has("encounter") else Vector2i(lo, hi)
		"battle":
			if half == 0:
				return Vector2i(3, hi) if tier > 0 else Vector2i(1, hi)
			return Vector2i(8, hi) if tier >= 2 else Vector2i(5, MID_ROWS - 1)
	return Vector2i(lo, hi)


## Fyllnadens tier efter raden (som grottans avstånd): de nedre raderna lätta, de övre svåra.
static func _fill_tier(row: int) -> int:
	return 0 if row <= 5 else (1 if row <= 9 else 2)


static func _roll(g: Grotto, rng: RandomNumberGenerator, required: Array, pools: Array) -> Dictionary:
	# Stigarna (Slay the Spire): PATHS stigar från rad 1 till lägereldarnas rad, utan korsningar.
	var top_row := MID_ROWS + 1
	var at := {}  # Vector2i(rad, kolumn) -> true
	var edges := {}  # Vector2i -> [Vector2i]
	var first_col := -1
	for p in PATHS:
		var col := rng.randi() % COLS
		if p == 1:
			while col == first_col:
				col = rng.randi() % COLS
		if p == 0:
			first_col = col
		for row in range(1, top_row + 1):
			var here := Vector2i(row, col)
			at[here] = true
			if row == top_row:
				break
			var nc := clampi(col + rng.randi_range(-1, 1), 0, COLS - 1)
			# Ingen korsning: finns redan en väg från (rad, nc) till (rad+1, col) går stigen rakt upp.
			if nc != col and edges.get(Vector2i(row, nc), []).has(Vector2i(row + 1, col)):
				nc = col
			var e: Array = edges.get(here, [])
			if not e.has(Vector2i(row + 1, nc)):
				e.append(Vector2i(row + 1, nc))
			edges[here] = e
			col = nc
	# Noder per rad, sorterade efter kolumn.
	var by_row: Array = []
	for r in top_row + 2:
		by_row.append([])
	for k in at:
		by_row[k.x].append(k)
	for r in by_row.size():
		by_row[r].sort_custom(func(x: Vector2i, y: Vector2i) -> bool: return x.y < y.y)
	var slots: Array = []  # mittens noder
	for r in range(1, MID_ROWS + 1):
		slots.append_array(by_row[r])
	# Innehållet ryms? Annars bort med obevakade skatter och föremål (de är flest), annars ett nytt försök.
	var req := required.duplicate()
	var guard := 0
	while req.size() > slots.size() and guard < 20:
		guard += 1
		var drop := -1
		for k in req.size():
			var c: Dictionary = g.cells[req[k][0]]
			if (c.kind == "treasure" and not c.has("encounter")) or c.kind == "object":
				drop = k
		if drop < 0:
			return {}
		req.remove_at(drop)
	# Innehållet till noderna: de snävaste först.
	for k in range(req.size() - 1, 0, -1):
		var j := rng.randi() % (k + 1)
		var t: Array = req[k]
		req[k] = req[j]
		req[j] = t
	req.sort_custom(func(x: Array, y: Array) -> bool:
		var sx := _row_span(g.cells[x[0]], x[1])
		var sy := _row_span(g.cells[y[0]], y[1])
		return (sx.y - sx.x) < (sy.y - sy.x))
	var cell_at := {}  # Vector2i -> cell
	var free := slots.duplicate()
	var down := {}  # Vector2i -> [Vector2i] (vägarna nedåt)
	for v in edges:
		for w in edges[v]:
			var d: Array = down.get(w, [])
			d.append(v)
			down[w] = d
	for item in req:
		var span := _row_span(g.cells[item[0]], item[1])
		var me: Dictionary = g.cells[item[0]]
		var options := free.filter(func(v: Vector2i) -> bool:
			if v.x < span.x or v.x > span.y:
				return false
			# Inte samma slag som en granne längs en väg (skatt–skatt, okänt–okänt, elit–elit, lägereld–lägereld).
			for w in edges.get(v, []) + down.get(v, []):
				if cell_at.has(w) and (_same_kind(me, g.cells[cell_at[w]]) or (me.kind == "campfire" and g.cells[cell_at[w]].kind == "campfire")):
					return false
			return true)
		if options.is_empty():
			return {}
		var pick: Vector2i = options[rng.randi() % options.size()]
		cell_at[pick] = item[0]
		free.erase(pick)
	# Rutor som inte fick plats blir tomma (de finns kvar i datan men inte på kartan).
	var placed := {}
	for v in cell_at:
		placed[cell_at[v]] = true
	for item in required:
		if not placed.has(item[0]):
			g.cells[item[0]] = {"kind": "empty"}
	# Resten: vanliga grupper ur Realmens pooler, tier efter raden.
	for v in free:
		var tier := mini(_fill_tier(v.x), pools.size() - 1)
		var pool: Array = pools[tier]
		g.cells.append({"kind": "battle", "encounter": pool[rng.randi() % pool.size()], "tier": tier, "fill": true})
		cell_at[v] = g.cells.size() - 1
	# Lägereldarna före bossen.
	for v in by_row[top_row]:
		g.cells.append({"kind": "campfire"})
		cell_at[v] = g.cells.size() - 1
	# Tabellerna per cell.
	var size := g.cells.size()
	var row_of_cell: Array = []
	var col_of_cell: Array = []
	var ups: Array = []
	for i in size:
		row_of_cell.append(-1)
		col_of_cell.append(3.0)
		ups.append([])
	var rows_out: Array = [[g.start]]
	row_of_cell[g.start] = 0
	col_of_cell[g.start] = (COLS - 1) / 2.0
	for r in range(1, top_row + 1):
		var row: Array = []
		for v in by_row[r]:
			var i: int = cell_at[v]
			row.append(i)
			row_of_cell[i] = r
			col_of_cell[i] = float(v.y)
			for w in edges.get(v, []):
				if cell_at.has(w):
					ups[i].append(cell_at[w])
		rows_out.append(row)
	for i in rows_out[1]:
		ups[g.start].append(i)
	for i in rows_out[top_row]:
		ups[i].append(g.goal)
	rows_out.append([g.goal])
	row_of_cell[g.goal] = top_row + 1
	col_of_cell[g.goal] = (COLS - 1) / 2.0
	return {"rows": rows_out, "row": row_of_cell, "col": col_of_cell, "up": ups}


# --- Reglerna --------------------------------------------------------------------

## Vad som bryter mot nodkartans regler (tom lista = giltig karta).
static func problems(g: Grotto, quest := {}) -> Array[String]:
	var out: Array[String] = []
	var rs := rows(g)
	if rs.size() != MID_ROWS + 3:
		out.append("%d rader (%d)" % [rs.size(), MID_ROWS + 3])
		return out
	if rs[0] != [g.start] or rs[rs.size() - 1] != [g.goal]:
		out.append("start eller mål fel")
	for r in range(1, MID_ROWS + 2):
		if rs[r].is_empty() or rs[r].size() > COLS:
			out.append("rad %d har %d noder" % [r, rs[r].size()])
	for i in rs[MID_ROWS + 1]:
		if g.cells[i].kind != "campfire":
			out.append("raden före bossen är inte lägereldar")
	var reach_down := {g.start: true}
	for r in rs.size() - 1:
		for i in rs[r]:
			var ups: Array = up(g, i)
			if ups.is_empty():
				out.append("en nod utan väg upp")
			if r > 0 and ups.size() > 3:
				out.append("en nod med fler än 3 vägar upp")
			for j in ups:
				if row_of(g, j) != r + 1:
					out.append("en väg som hoppar över en rad")
				if reach_down.has(i):
					reach_down[j] = true
				if g.cells[i].kind == "campfire" and g.cells[j].kind == "campfire":
					out.append("två lägereldar i rad")
				elif _same_kind(g.cells[i], g.cells[j]):
					out.append("två %s i rad" % g.cells[i].kind)
	for i in all_nodes(g):
		if not reach_down.has(i):
			out.append("en nod som inte går att nå")
			break
	for i in all_nodes(g):
		if i != g.goal and not ahead(g, i).has(g.goal):
			out.append("en nod som inte leder till målet")
			break
	for r in range(1, ELITE_MIN_ROW):
		for i in rs[r]:
			if g.cells[i].kind == "elite":
				out.append("en elit på rad %d" % r)
	if not (rs[1] + rs[2]).any(func(i: int) -> bool: return g.has_group(i)):
		out.append("ingen grupp på de första raderna")
	# Vägarnas innehåll (dynamisk programmering, inga vägar räknas upp: de kan vara tusentals).
	var goal := int(quest.get("goal", 0))
	var table := route_table(g, quest)
	var all_min := 1 << 20
	for gain in table:
		all_min = mini(all_min, int(table[gain][0]))
	if all_min < MIN_PATH_FIGHTS:
		out.append("en väg med färre än %d strider" % MIN_PATH_FIGHTS)
	if not table.has(goal):
		out.append("ingen väg klarar questen")
	else:
		var t: Array = table[goal]
		# Två vägar som skiljer sig på riktigt: olika många strider (minst två) eller olika många eliter.
		if int(t[1]) - int(t[0]) < 2 and int(t[3]) == int(t[2]):
			out.append("inga två olika vägar")
	if quest.get("type", "") == RunState.SEAL_QUEST:
		var seals := g.indices("seal").filter(func(i: int) -> bool: return is_node(g, i))
		var pairs := 0
		for x in seals.size():
			for y in range(x + 1, seals.size()):
				if ahead(g, seals[x]).has(seals[y]) or ahead(g, seals[y]).has(seals[x]):
					pairs += 1
		if pairs < 2:
			out.append("bara ett val av sigill")
	return out


## Två noder av samma slag i rad gör vägen enformig (Slay the Spire: inga två eliter, lägereldar eller affärer i rad):
## skatter, okända och eliter. Vanliga strider får stå i rad.
static func _same_kind(a: Dictionary, b: Dictionary) -> bool:
	if a.get("elite", false) and b.get("elite", false):
		return true
	if is_unknown(a) and is_unknown(b):
		return true
	return a.kind == "treasure" and b.kind == "treasure"


## För vägar från start till målet, per hur mycket de ger questen (högst målet): [minst strider, flest strider,
## minst eliter, flest eliter].
static func route_table(g: Grotto, quest: Dictionary) -> Dictionary:
	return _table(g, g.start, quest, int(quest.get("goal", 0)), {})


static func _table(g: Grotto, i: int, quest: Dictionary, goal: int, memo: Dictionary) -> Dictionary:
	if memo.has(i):
		return memo[i]
	var c: Dictionary = g.cells[i]
	var f := 1 if c.has("encounter") and not c.get("boss", false) else 0
	var e := 1 if c.get("elite", false) else 0
	var q := quest_gain(c, quest)
	var out := {}
	if i == g.goal:
		out[mini(q, goal)] = [0, 0, 0, 0]
	for j in up(g, i):
		var sub := _table(g, j, quest, goal, memo)
		for gain in sub:
			var k := mini(int(gain) + q, goal)
			var v: Array = sub[gain]
			var mine := [int(v[0]) + f, int(v[1]) + f, int(v[2]) + e, int(v[3]) + e]
			if not out.has(k):
				out[k] = mine
			else:
				var o: Array = out[k]
				out[k] = [mini(o[0], mine[0]), maxi(o[1], mine[1]), mini(o[2], mine[2]), maxi(o[3], mine[3])]
	memo[i] = out
	return out


# --- Questen och vägvalet ---------------------------------------------------------

## 1 om noden för questen framåt när man tar den (Nemesis, en elit i Rensa, ett föremål, ett sigill), annars 0.
static func quest_gain(c: Dictionary, quest: Dictionary) -> int:
	match quest.get("type", ""):
		"hunt":
			return 1 if c.get("nemesis", false) and not c.get("beaten", false) else 0
		"clear":
			return 1 if c.get("elite", false) and c.has("encounter") and not c.get("beaten", false) else 0
		"collect":
			return 1 if c.get("kind", "") == "item" and not c.get("done", false) else 0
		RunState.SEAL_QUEST:
			return 1 if c.get("kind", "") == "seal" and not c.get("broken", false) and not c.get("held", false) else 0
	return 0


## Det mesta questen kan få på en väg från noden (noden inräknad) till målet.
static func best_gain(g: Grotto, from: int, quest: Dictionary, memo := {}) -> int:
	if memo.has(from):
		return memo[from]
	var best := 0
	for j in up(g, from):
		best = maxi(best, best_gain(g, j, quest, memo))
	var v := quest_gain(g.cells[from], quest) + best
	memo[from] = v
	return v


## Går questen fortfarande att klara om man går till noden?
static func quest_ok(g: Grotto, to: int, quest: Dictionary) -> bool:
	if quest.get("done", false) or quest.is_empty():
		return true
	return int(quest.get("progress", 0)) + best_gain(g, to, quest) >= int(quest.get("goal", 0))


## Noder man fortfarande kan nå härifrån (framåt), noden själv inräknad.
static func ahead(g: Grotto, from: int) -> Dictionary:
	var out := {from: true}
	var queue: Array = [from]
	while not queue.is_empty():
		var i: int = queue.pop_front()
		for j in up(g, i):
			if not out.has(j):
				out[j] = true
				queue.append(j)
	return out
