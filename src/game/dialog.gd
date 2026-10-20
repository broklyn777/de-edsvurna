class_name Dialog
extends RefCounted
## Samtalen i borgen och replikerna under nedstigningen (0.24, docs/plan/0.24-hemmet.md §2–3), som Siralims
## dialogruta. Allt står i data/dialog.json: personerna (namn, titel, station, hälsningar och vardagsrepliker med
## villkor), stationernas val (tjänsterna, sist "Ingenting just nu") och replikerna i kryptan ("barks" och "pairs").
## Ren logik; borgen och rumskartan ritar.


## 0.24.2: {namn} i en replik blir paladinens namn.
static func fill(text: String, hero_name: String) -> String:
	return text.replace("{namn}", hero_name)


## 0.24.3: {namn}, {svärdsnivå} och {nästa_nivå} (svärdets nästa nivå i silver) ur profilen.
static func fill_for(text: String, profile: Profile) -> String:
	var lv := int(profile.artifact("paladin").get("level", 0))
	var cost := Forge.level_cost(lv)
	return fill(text, profile.hero_name).replace("{svärdsnivå}", str(lv)).replace("{nästa_nivå}", str(cost)) \
			.replace("{silver}", str(profile.silver)).replace("{fattas}", str(maxi(cost - profile.silver, 0)))


static func person(data: Dictionary, id: String) -> Dictionary:
	return data.get("dialog", {}).get("people", {}).get(id, {})


static func station(data: Dictionary, station_id: String) -> Dictionary:
	return data.get("dialog", {}).get("stations", {}).get(station_id, {})


## Personen vid stationen ("" om ingen står där).
static func station_person(data: Dictionary, station_id: String) -> String:
	return station(data, station_id).get("person", "")


static func display_name(data: Dictionary, id: String) -> String:
	var p := person(data, id)
	if p.is_empty():
		return data.get("heroes", {}).get(id, {}).get("short", data.get("heroes", {}).get(id, {}).get("name", id))
	return p.get("name", id)


## Stationens val: tjänsterna och sist "Ingenting just nu" ({label, open}; open "" stänger samtalet).
static func options(data: Dictionary, station_id: String) -> Array:
	var out: Array = station(data, station_id).get("options", []).duplicate(true)
	out.append({"label": data.get("dialog", {}).get("nothing", "Ingenting just nu"), "open": ""})
	return out


## Sant om villkoren ("when") gäller för profilen.
static func applies(data: Dictionary, profile: Profile, when: Dictionary) -> bool:
	for key in when:
		var v: Variant = when[key]
		match key:
			"recruited":
				if not profile.recruited.has(v):
					return false
			"not_recruited":
				if profile.recruited.has(v):
					return false
			"min_recruited":
				if profile.recruited.size() < int(v):
					return false
			"min_descents":
				if profile.total_descents() < int(v):
					return false
			"min_best_depth":
				if profile.best_depth < int(v):
					return false
			"boss":
				if not profile.bosses_defeated.has(v):
					return false
			"intro_done":
				if profile.intro_done != bool(v):
					return false
	return true


## Vardagsrepliken som personen säger nu. Repliker med villkor (det som har hänt) kommer först; sedan växlar
## de allmänna. turn = hur många gånger man har pratat med personen (Profile.talks).
static func idle_line(data: Dictionary, profile: Profile, id: String, turn: int) -> String:
	var lines: Array = person(data, id).get("idle", [])
	var news: Array = []
	var plain: Array = []
	for l in lines:
		var when: Dictionary = l.get("when", {})
		if when.is_empty():
			plain.append(l.text)
		elif applies(data, profile, when):
			news.append(l.text)
	var all := news + plain
	if all.is_empty():
		return ""
	# En ny händelse sägs först (de två första gångerna efter att den hänt), sedan blandas den in.
	return all[posmod(turn, all.size())]


## Den första hälsningen ("Så du är den nya", "Du måste vara {namn}") gäller bara första mötet (turn 0); sedan
## turas de andra om (0.26.2).
static func greeting(data: Dictionary, id: String, turn: int) -> String:
	var g: Array = person(data, id).get("greet", [])
	if g.is_empty():
		return ""
	if turn <= 0 or g.size() == 1:
		return String(g[0])
	return String(g[1 + posmod(turn - 1, g.size() - 1)])


## Svaret från en stängd station under introt (personen vid stationen säger det).
static func reply(data: Dictionary, station_id: String) -> String:
	return data.get("intro", {}).get("replies", {}).get(station_id, "Inte än.")


# --- Under nedstigningen -----------------------------------------------------------

## Lägen för replikerna (plan §3).
const BARK_KINDS := ["hard_fight", "campfire", "rare_find", "rescue", "new_realm", "alone"]


## En replik (eller ett kort samtal mellan två) för läget: {lines: [{who, text}]}, eller {} om ingen passar.
## Imma först om hon är med; samtal mellan två hjältar ibland; inget upprepas samma körning (used).
static func bark(data: Dictionary, kind: String, party: Array, used: Array, rng: RandomNumberGenerator) -> Dictionary:
	var d: Dictionary = data.get("dialog", {})
	for pair in d.get("pairs", []):
		var key := "pair:%s:%s" % [pair.heroes[0], pair.heroes[1]]
		if pair.get("kind", "") == kind and party.has(pair.heroes[0]) and party.has(pair.heroes[1]) \
				and not used.has(key) and rng.randf() < 0.5:
			used.append(key)
			return {"lines": pair.lines.map(func(l: Array) -> Dictionary: return {"who": l[0], "text": l[1]})}
	var speakers: Array = []
	for id in party:
		if id == "paladin":
			continue
		var lines: Array = d.get("barks", {}).get(id, {}).get(kind, [])
		if lines.any(func(t: String) -> bool: return not used.has(t)):
			speakers.append(id)
	if speakers.is_empty():
		return {}
	# Imma säger det mesta, men de andra får ordet ibland.
	var who: String = speakers[0] if speakers.size() == 1 else ""
	if who == "":
		var others := speakers.filter(func(id: String) -> bool: return id != "imma")
		who = "imma" if speakers.has("imma") and rng.randf() >= 0.3 else String(others[rng.randi() % others.size()])
	var fresh: Array = d.barks[who][kind].filter(func(t: String) -> bool: return not used.has(t))
	var text: String = fresh[rng.randi() % fresh.size()]
	used.append(text)
	return {"lines": [{"who": who, "text": text}]}
