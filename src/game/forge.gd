class_name Forge
extends RefCounted
## Artefakternas nivåer, platser, material och Nether Stones (0.20, Siralims Artifacts). Ren logik.
##
## En artefakt: {type, ability, level, stat_slots: [amber_id …], trick_slots: [trick_id …], nether: {sten}}.
## Nivå 1–10 hos Smeden för silver (Siralim: 1–50 för Brimstone). Varje nivå stärker typens stat, materialen
## och trickens effekter med 10 % (originalet: nivån stärker allt). Platserna öppnas i originalets ordning:
## Stat 2, Trick 3, Stat 5, Trick 7, Stat 9 och Nether 10 (förmågan finns från nivå 1; ingen Trait-plats,
## trofén är den). Ett material som tas ut förstörs; en Nether Stone överlever.

const LEVEL_MAX := 10
const STAT_SLOT_LEVELS := [2, 5, 9]
const TRICK_SLOT_LEVELS := [3, 7]
const NETHER_LEVEL := 10
## Bärnsten per Stat-plats, som i originalet.
const AMBER_PER_SLOT := 5
## Silver för att gå från nivå n till n + 1 (index n). Brant som originalet, men i vår valuta.
const LEVEL_COST := [0, 60, 80, 110, 140, 180, 230, 290, 370, 470]
## Stat-ökning per bärnsten på nivå 1 (en färg; tvåfärgade delar 60 % var).
const AMBER_PCT := 0.06
## Chansen för en artefaktförmåga blir aldrig högre än så här, hur hög nivån än är.
const CHANCE_MAX := 0.9

## Fynd: chans per rumstyp. "frontier" = djupaste djupet man nått (bara där finns trick och Nether Stones,
## som originalets bonus på det djupaste djupet). Mängden bärnsten är [min, max].
const FINDS := {
	"battle": {"amber_chance": 0.35, "amber": [1, 1], "trick": 0.0, "nether": 0.0},
	"elite": {"amber_chance": 1.0, "amber": [2, 3], "trick": 0.4, "nether": 0.08},
	"treasure": {"amber_chance": 1.0, "amber": [2, 4], "trick": 0.5, "nether": 0.12},
	"portal_battle": {"amber_chance": 1.0, "amber": [2, 3], "trick": 0.6, "nether": 0.25},
	"end": {"amber_chance": 1.0, "amber": [1, 2], "trick": 0.25, "nether": 0.05},
	"boss": {"amber_chance": 1.0, "amber": [3, 4], "trick": 1.0, "nether": 0.5},
}
## På lägre djup än det djupaste: bara bärnsten, och lite mer av den (det vanliga, men värt att hämta).
const BELOW_FRONTIER_AMBER := 1


static func level_mult(level: int) -> float:
	return 1.0 + 0.1 * (clampi(level, 1, LEVEL_MAX) - 1)


## Fyller i det som saknas (äldre profiler hade bara typ och förmåga).
static func normalize(art: Dictionary) -> Dictionary:
	if art.is_empty():
		return art
	var out := art.duplicate(true)
	out["level"] = clampi(int(out.get("level", 1)), 1, LEVEL_MAX)
	var stats: Array = out.get("stat_slots", [])
	var tricks: Array = out.get("trick_slots", [])
	stats.resize(STAT_SLOT_LEVELS.size())
	tricks.resize(TRICK_SLOT_LEVELS.size())
	out["stat_slots"] = stats.map(func(x: Variant) -> String: return "" if x == null else String(x))
	out["trick_slots"] = tricks.map(func(x: Variant) -> String: return "" if x == null else String(x))
	out["nether"] = out.get("nether", {})
	out["ability"] = out.get("ability", "")
	return out


static func stat_slot_open(level: int, i: int) -> bool:
	return i < STAT_SLOT_LEVELS.size() and level >= STAT_SLOT_LEVELS[i]


static func trick_slot_open(level: int, i: int) -> bool:
	return i < TRICK_SLOT_LEVELS.size() and level >= TRICK_SLOT_LEVELS[i]


static func nether_open(level: int) -> bool:
	return level >= NETHER_LEVEL


## Vad nivån öppnar ("Stat-plats 2"), eller "" om den bara stärker.
static func unlock_text(level: int) -> String:
	var i := STAT_SLOT_LEVELS.find(level)
	if i >= 0:
		return "Stat-plats %d" % (i + 1)
	i = TRICK_SLOT_LEVELS.find(level)
	if i >= 0:
		return "Trick-plats %d" % (i + 1)
	if level == NETHER_LEVEL:
		return "Nether-plats"
	return ""


## Nästa nivå som öppnar något, från nivån (0 = inget kvar).
static func next_unlock(level: int) -> int:
	for l in range(level + 1, LEVEL_MAX + 1):
		if unlock_text(l) != "":
			return l
	return 0


static func level_cost(level: int) -> int:
	return LEVEL_COST[level] if level >= 1 and level < LEVEL_MAX else 0


# --- Stats -------------------------------------------------------------------

## Vad artefakten lägger till per källa, utifrån statsen före artefakten (values: stat -> värde):
## {"artifact": {stat: tillägg}, "material": {...}, "nether": {...}}. Health avrundas per källa.
static func stat_parts(data: Dictionary, art: Dictionary, values: Dictionary) -> Dictionary:
	var out := {"artifact": {}, "material": {}, "nether": {}}
	var kind: Dictionary = data.artifacts.get(art.get("type", ""), {})
	if kind.is_empty():
		return out
	var a := normalize(art)
	var m := level_mult(a.level)
	var stat: String = kind.stat
	var v := float(values[stat])
	var raised := v * (1.0 + (float(kind.get("stat_mult", 1.0)) - 1.0) * m) + float(kind.get("stat_add", 0.0)) * m
	_add(out.artifact, stat, raised - v)
	for amber_id in a.stat_slots:
		var amber: Dictionary = data.materials.amber.get(amber_id, {})
		for s in amber.get("stats", {}):
			_add(out.material, s, float(values[s]) * AMBER_PCT * float(amber.stats[s]) * m)
	for affix in a.nether.get("affixes", []):
		if affix.kind == "stat":
			_add(out.nether, affix.stat, float(values[affix.stat]) * float(affix.pct))
	for part in out:
		if out[part].has("health"):
			out[part].health = roundf(out[part].health)
	return out


static func _add(d: Dictionary, stat: String, v: float) -> void:
	d[stat] = float(d.get(stat, 0.0)) + v


# --- Trick och Nether-effekter ----------------------------------------------

static func trick_value(data: Dictionary, trick_id: String, level: int, quality := 1.0) -> float:
	var t: Dictionary = data.materials.tricks.get(trick_id, {})
	return float(t.get("value", 0.0)) * level_mult(level) * quality


static func trick_text(data: Dictionary, trick_id: String, level: int, quality := 1.0) -> String:
	var t: Dictionary = data.materials.tricks.get(trick_id, {})
	if t.is_empty():
		return ""
	return String(t.text) % ("%d %%" % roundi(100.0 * minf(trick_value(data, trick_id, level, quality), CHANCE_MAX)))


## Egenskaperna som artefaktens trick och Nether Stone ger: trait_id -> egenskap (genereras per strid).
## Nether-affix med en trofés egenskap ger dess id direkt i "trait_ids".
static func effect_traits(data: Dictionary, art: Dictionary, hero_id: String) -> Dictionary:
	var a := normalize(art)
	var out := {"traits": {}, "trait_ids": []}
	var n := 0
	for trick_id in a.trick_slots:
		if trick_id != "":
			out.traits["artifact_%s_t%d" % [hero_id, n]] = _trick_trait(data, trick_id, trick_value(data, trick_id, a.level))
			n += 1
	for affix in a.nether.get("affixes", []):
		match affix.kind:
			"trick":
				out.traits["artifact_%s_t%d" % [hero_id, n]] = _trick_trait(data, affix.trick,
						trick_value(data, affix.trick, 1, float(affix.q)))
				n += 1
			"trait":
				if data.traits.has(affix.trait):
					out.trait_ids.append(affix.trait)
	return out


static func _trick_trait(data: Dictionary, trick_id: String, v: float) -> Dictionary:
	var t: Dictionary = data.materials.tricks[trick_id]
	var base := {"name": t.name, "hidden": true, "artifact": true}
	match t.kind:
		"attack_damage":
			base.merge({"trigger": "modify_damage", "when": {"kind": "attack"}, "modify": {"damage_mult": 1.0 + v}})
		"spell_damage":
			base.merge({"trigger": "modify_damage", "when": {"kind": "spell"}, "modify": {"damage_mult": 1.0 + v}})
		"crit":
			base.merge({"trigger": "modify_damage", "when": {"kind": "attack"}, "modify": {"crit_add": v}})
		"damage_taken":
			base.merge({"trigger": "modify_damage_taken", "modify": {"damage_taken_mult": maxf(0.3, 1.0 - v)}})
		"dodge":
			base.merge({"trigger": "modify_damage_taken", "when": {"kind": "attack"}, "modify": {"dodge_add": v}})
		"buff_on_hit":
			base.merge({"trigger": "damage", "chance": minf(v, CHANCE_MAX), "when": {"source": "self", "direct": true},
					"effects": [{"type": "aura", "aura": t.aura, "target": "self"}]})
		"debuff_on_hit":
			base.merge({"trigger": "damage", "chance": minf(v, CHANCE_MAX), "when": {"source": "self", "direct": true},
					"effects": [{"type": "aura", "aura": t.aura, "target": "target"}]})
	return base


# --- Fynd --------------------------------------------------------------------

## Fynden från ett rum: [{kind: "amber"|"trick", id, count} | {kind: "nether", stone}].
## kind: battle, elite, treasure, portal_battle, end eller boss. next_id numrerar nya stenar.
static func roll_finds(data: Dictionary, kind: String, depth: int, frontier: bool, instability: int,
		rng: RandomNumberGenerator, next_id := 0) -> Array:
	var f: Dictionary = FINDS.get(kind, FINDS.battle)
	var out := []
	var ambers: Array = data.materials.amber.keys()
	if rng.randf() < float(f.amber_chance):
		var count := rng.randi_range(int(f.amber[0]), int(f.amber[1])) + (0 if frontier else BELOW_FRONTIER_AMBER)
		var by_color := {}
		for i in count:
			var id: String = ambers[rng.randi() % ambers.size()]
			by_color[id] = int(by_color.get(id, 0)) + 1
		for id in by_color:
			out.append({"kind": "amber", "id": id, "count": by_color[id]})
	if not frontier:
		return out
	var bonus := 1.0 + 0.5 * instability
	if rng.randf() < float(f.trick) * minf(bonus, 2.0):
		var tricks: Array = data.materials.tricks.keys()
		out.append({"kind": "trick", "id": tricks[rng.randi() % tricks.size()], "count": 1})
	if rng.randf() < float(f.nether) * bonus:
		out.append({"kind": "nether", "stone": roll_stone(data, depth, instability, rng, next_id)})
	return out


## En slumpad Nether Stone (Diablo-liknande): sällsyntheten avgör antalet egenskaper, kvaliteten deras värden.
## Djup och instabilitet ger sällsyntare stenar och högre kvalitet.
static func roll_stone(data: Dictionary, depth: int, instability: int, rng: RandomNumberGenerator, id: int) -> Dictionary:
	var rarities: Array = data.materials.nether.rarities
	var shift := 0.06 * (maxi(depth, 1) - 1) + 0.08 * instability
	var weights := [maxf(0.1, 0.55 - shift), 0.28, 0.13 + shift * 0.6, 0.04 + shift * 0.4]
	var r: float = rng.randf() * weights.reduce(func(a: float, b: float) -> float: return a + b, 0.0)
	var tier := 0
	while tier < weights.size() - 1 and r >= weights[tier]:
		r -= weights[tier]
		tier += 1
	var rarity: Dictionary = rarities[tier]
	var affixes := []
	var used := {}
	var trophies := []
	for t in data.traits:
		if data.traits[t].get("trophy", false) and data.traits[t].get("rarity", "") == "common":
			trophies.append(t)
	var number := 0.0
	for i in int(rarity.affixes):
		var q := minf(1.6, rng.randf_range(0.6, 1.4) + 0.04 * (maxi(depth, 1) - 1))
		var roll := rng.randf()
		# Den legendariska stenen har alltid en troféegenskap som sista egenskap.
		if (tier == 3 and i == int(rarity.affixes) - 1) or (tier >= 2 and roll < 0.12):
			var t: String = trophies[rng.randi() % trophies.size()]
			if not used.has(t):
				used[t] = true
				affixes.append({"kind": "trait", "trait": t, "q": 1.0})
				number += 150.0
				continue
		if roll < 0.55:
			var stats: Array = HeroStats.STATS.filter(func(s: String) -> bool: return not used.has(s))
			var s: String = stats[rng.randi() % stats.size()]
			used[s] = true
			affixes.append({"kind": "stat", "stat": s, "pct": snappedf(float(data.materials.nether.stat_pct) * q, 0.005),
					"q": q})
		else:
			var tricks: Array = data.materials.tricks.keys().filter(func(t: String) -> bool: return not used.has(t))
			var tr: String = tricks[rng.randi() % tricks.size()]
			used[tr] = true
			affixes.append({"kind": "trick", "trick": tr, "q": snappedf(q, 0.01)})
		number += 100.0 * q
	return {"id": "n%d" % id, "rarity": rarity.id, "affixes": affixes, "number": roundi(number),
			"depth": depth}


static func rarity_of(data: Dictionary, stone: Dictionary) -> Dictionary:
	for r: Dictionary in data.materials.nether.rarities:
		if r.id == stone.get("rarity", ""):
			return r
	return data.materials.nether.rarities[0]


## En rad per egenskap hos stenen, i spelets svenska.
static func stone_lines(data: Dictionary, stone: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for affix in stone.get("affixes", []):
		match affix.kind:
			"stat":
				out.append("+%s %% %s" % [_pct(float(affix.pct)), HeroStats.STAT_NAMES[affix.stat]])
			"trick":
				out.append(trick_text(data, affix.trick, 1, float(affix.q)))
			"trait":
				out.append("%s: %s" % [data.traits[affix.trait].name, data.traits[affix.trait].get("text", "")])
	return out


static func _pct(v: float) -> String:
	var p := v * 100.0
	return ("%d" % roundi(p)) if is_equal_approx(p, roundf(p)) else ("%.1f" % p).replace(".", ",")


## Ett fynds namn för listor ("3 × Röd bärnsten", "Brynsten", "Sällsynt Nether Stone (287)").
static func find_text(data: Dictionary, find: Dictionary) -> String:
	match find.kind:
		"amber":
			return "%d × %s" % [find.count, data.materials.amber[find.id].name]
		"trick":
			return data.materials.tricks[find.id].name
		"nether":
			return "%s Nether Stone (%d)" % [rarity_of(data, find.stone).name, find.stone.number]
	return ""


## Färgen för ett fynd (bärnstenens, trickets eller sällsynthetens).
static func find_color(data: Dictionary, find: Dictionary) -> Color:
	match find.kind:
		"amber":
			return Color(data.materials.amber[find.id].color)
		"trick":
			return Color(data.materials.tricks[find.id].color)
		"nether":
			return Color(rarity_of(data, find.stone).color)
	return Color.WHITE


## Är fyndet så ovanligt att det får en egen liten scen (sällsynt eller legendarisk sten)?
static func is_rare_find(find: Dictionary) -> bool:
	return find.kind == "nether" and find.stone.rarity in ["rare", "legendary"]
