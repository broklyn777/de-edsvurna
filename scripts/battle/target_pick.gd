class_name TargetPick
extends RefCounted
## Träffytorna i striden (polering fynd 6): ren skärmgeometri utan noder, så att den går att testa. En figur träffas på
## kroppen (från fötterna till huvudet) och på skylten ovanför huvudet (namn, livmätare och avsikt, Fx.Overheads).
## Träffar ett tryck flera ytor vinner den vars mitt är närmast. spread_step() skjuter isär fiender vars ytor överlappar.

## Skylten relativt huvudets punkt på skärmen: namnet, livmätaren och avsiktens ring.
const PLATE := Rect2(-75, -62, 150, 66)
## Kroppens bredd åt varje håll från linjen mellan fötterna och huvudet.
const BODY_RADIUS := 40.0
## Utan träff på någon yta: närmaste kropp inom så här många pixlar (som förut).
const FALLBACK := 80.0
## Det som inte får överlappa mellan två fiender: skylten och överkroppen under den.
const AREA := Rect2(-75, -62, 150, 122)
const AREA_GAP := 6.0


static func plate_rect(head: Vector2) -> Rect2:
	return Rect2(head + PLATE.position, PLATE.size)


static func dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := 0.0 if ab.length_squared() < 0.001 else clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)


## Figuren som trycket gäller bland units = {id: [fötter, huvud]} (skärmpunkter), eller "".
static func pick(pos: Vector2, units: Dictionary) -> String:
	var best := ""
	var best_d := INF
	for id in units:
		var feet: Vector2 = units[id][0]
		var head: Vector2 = units[id][1]
		var plate := plate_rect(head)
		if plate.has_point(pos):
			var d := pos.distance_to(plate.get_center())
			if d < best_d:
				best_d = d
				best = id
		if dist_to_segment(pos, feet, head) <= BODY_RADIUS:
			var d2 := pos.distance_to((feet + head) / 2.0)
			if d2 < best_d:
				best_d = d2
				best = id
	if best != "":
		return best
	best_d = FALLBACK
	for id in units:
		var d3 := dist_to_segment(pos, units[id][0], units[id][1])
		if d3 < best_d:
			best_d = d3
			best = id
	return best


## Ett steg isär: för varje par vars ytor (skylt och överkropp) överlappar, en knuff åt var och en i sidled, eller i
## höjdled när det överlappet är mindre än hälften (då står de nästan rakt ovanför varandra). Sidled behåller raderna i
## djupet. Ger {id: förflyttning på skärmen}; tomt när inget överlappar.
static func spread_step(heads: Dictionary) -> Dictionary:
	var out := {}
	var ids := heads.keys()
	ids.sort()
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var a: Vector2 = heads[ids[i]]
			var b: Vector2 = heads[ids[j]]
			var ra := Rect2(a + AREA.position, AREA.size).grow(AREA_GAP / 2.0)
			var rb := Rect2(b + AREA.position, AREA.size).grow(AREA_GAP / 2.0)
			if not ra.intersects(rb):
				continue
			var inter := ra.intersection(rb)
			var push := Vector2.ZERO
			if inter.size.y < inter.size.x * 0.5:
				push.y = (inter.size.y / 2.0 + 1.0) * (1.0 if b.y >= a.y else -1.0)
			else:
				push.x = (inter.size.x / 2.0 + 1.0) * (1.0 if b.x >= a.x else -1.0)
			out[ids[j]] = out.get(ids[j], Vector2.ZERO) + push
			out[ids[i]] = out.get(ids[i], Vector2.ZERO) - push
	return out
