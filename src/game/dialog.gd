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
			"seen_realm":
				if int(profile.descents.get(v, 0)) < 1:
					return false
			"min_bosses":
				if profile.bosses_defeated.size() < int(v):
					return false
			"intro_done":
				if profile.intro_done != bool(v):
					return false
	return true


## Vardagsrepliken som personen säger nu (och minns den i profilen, Profile.said).
## Replikminnet (levande repliker steg 2, docs/research/levande-repliker.md §5): en nyhet (en replik med "when") sägs
## högst NEWS_TIMES gånger (eller "times", "once" = 1), sedan vilar den; högst en nyhet per person och hemkomst, och den
## kommer i första samtalet efter hemkomsten. Annars de allmänna: den som vilat längst (aldrig sagd först), aldrig samma
## två gånger i rad; lika gamla turas om efter turn (Profile.talks).
const NEWS_TIMES := 2


static func idle_line(data: Dictionary, profile: Profile, id: String, turn: int) -> String:
	var lines: Array = person(data, id).get("idle", [])
	var n := profile.total_descents()
	var news: Array = []
	var plain: Array = []
	for l in lines:
		var when: Dictionary = l.get("when", {})
		if when.is_empty():
			plain.append(l)
		elif applies(data, profile, when) and profile.times_said(line_key(l)) < line_times(l, NEWS_TIMES):
			news.append(l)
	var news_key := "news:" + id
	if not news.is_empty() and int(profile.said.get(news_key, -1)) != n:
		# Aldrig sagda först, sedan den som sagts färst gånger; datans ordning avgör lika.
		var best: Dictionary = news[0]
		for l in news:
			if profile.times_said(line_key(l)) < profile.times_said(line_key(best)):
				best = l
		profile.said[news_key] = n
		profile.note_said(line_key(best), n)
		profile.last_idle[id] = line_key(best)
		return String(best.text)
	if plain.is_empty():
		return ""
	var last := String(profile.last_idle.get(id, ""))
	var pool := plain.filter(func(l: Dictionary) -> bool: return line_key(l) != last) if plain.size() > 1 else plain
	# Den som vilat längst; bland lika gamla börjar turordningen på turn.
	var best_l: Dictionary = {}
	var best_rest := -INF
	for k in pool.size():
		var l: Dictionary = pool[posmod(turn + k, pool.size())]
		var rest := profile.rest(line_key(l), n)
		if rest > best_rest:
			best_rest = rest
			best_l = l
	profile.note_said(line_key(best_l), n)
	profile.last_idle[id] = line_key(best_l)
	return String(best_l.text)


## Den första hälsningen ("Så du är den nya", "Du måste vara {namn}") gäller bara första mötet (turn 0); sedan
## turas de andra om (0.26.2).
static func greeting(data: Dictionary, id: String, turn: int) -> String:
	var g: Array = person(data, id).get("greet", [])
	if g.is_empty():
		return ""
	if turn <= 0 or g.size() == 1:
		return String(g[0])
	return String(g[1 + posmod(turn - 1, g.size() - 1)])


## 0.29.3: vad en följeslagare i värdshuset säger (dialog.json "inn", ChatGPT:s jobb E). Välkomstrepliken först, en gång
## efter varje nedstigning hen stannade hemma under; efter två nedstigningar hemma vill hen följa med (varannan gång);
## annars turas vardagsreplikerna om. turn = hur många gånger man har pratat med personen. Ger {id, text} eller {}.
static func inn_line(data: Dictionary, profile: Profile, id: String, turn: int) -> Dictionary:
	var d: Dictionary = data.get("dialog", {}).get("inn", {}).get(id, {})
	if d.is_empty():
		return {}
	var home := int(profile.home_runs.get(id, 0))
	var kind := "inn"
	if home >= 1 and int(profile.inn_heard.get(id, -1)) < profile.total_descents():
		kind = "welcome"
	elif home >= 2 and turn % 2 == 0:
		kind = "bored"
	var lines: Array = d.get(kind, d.get("inn", []))
	if lines.is_empty():
		return {}
	var e: Variant = lines[posmod(turn, lines.size())]
	return e if e is Dictionary else {"text": String(e)}


## Svaret från en stängd station under introt (personen vid stationen säger det).
static func reply(data: Dictionary, station_id: String) -> String:
	return data.get("intro", {}).get("replies", {}).get(station_id, "Inte än.")


# --- Under nedstigningen -----------------------------------------------------------

## Lägen för replikerna (plan §3).
## 0.28.1 (grottan): cave (ny våning), elite (ser en elitgrupp), back (backar), treasure, stairs (questen klar, trappan
## öppen), boss (ser bossen), fallen (någon stupade); home finns i datan men visas inte än.
const BARK_KINDS := ["hard_fight", "campfire", "rare_find", "rescue", "new_realm", "alone",
		"cave", "elite", "back", "treasure", "stairs", "boss", "fallen", "home"]


## En replik (eller ett kort samtal mellan två) för läget: {lines: [{who, text}]}, eller {} om ingen passar.
## Imma först om hon är med; samtal mellan två hjältar ibland; inget upprepas samma körning (used, replikernas nycklar).
## 0.28.1: en replik är en text eller {id, text} (fasta id:n för eventuella röster senare).
## Replikminnet (levande repliker steg 1): med en profil minns grottans repliker mellan körningarna (Profile.said, n =
## nedstigningens nummer). En replik som sagts för färre än sin vila sedan hoppas över; vilan är "cooldown" på repliken,
## annars BARK_REST_PER_LINE × poolens storlek (lägets repliker för sällskapet), högst BARK_COOLDOWN. Aldrig sagda
## först, sedan den som vilat längst. Vilar alla: tystnad, utom för starka lägen (fallback), där den som vilat längst sägs.
## Valfria fält på en replik: "once" (en gång per profil), "cooldown" (nedstigningar), "chance" (0–1).
static func line_text(entry: Variant) -> String:
	return String(entry.get("text", "")) if entry is Dictionary else String(entry)


## Replikens nyckel i minnet: id:t, annars en hash av texten (äldre repliker utan id).
static func line_key(entry: Variant) -> String:
	if entry is Dictionary and entry.has("id"):
		return String(entry.id)
	return "t:%d" % line_text(entry).hash()


static func pair_key(pair: Dictionary) -> String:
	if pair.has("id"):
		return String(pair.id)
	return "pair:%d" % (pair.heroes[0] + pair.heroes[1] + String(pair.lines[0][1])).hash()


## Hur många gånger en nyhet får sägas ("once" = 1, "times" = n, annars standard).
static func line_times(entry: Variant, standard: int) -> int:
	if entry is Dictionary:
		if entry.get("once", false):
			return 1
		if entry.has("times"):
			return int(entry.times)
	return standard


const BARK_COOLDOWN := 10
## Vilan efter poolens storlek: en replik vilar så många nedstigningar per replik i läget (för sällskapet), högst
## BARK_COOLDOWN. Två repliker i ett läge ger vila 4: läget hörs ungefär varannan nedstigning, aldrig samma rad två i rad.
const BARK_REST_PER_LINE := 2


## Sant om repliken får sägas nu (chance rullas här).
static func _bark_ok(entry: Variant, key: String, used: Array, profile: Profile, rng: RandomNumberGenerator) -> bool:
	if used.has(key):
		return false
	if entry is Dictionary:
		if entry.get("once", false) and profile != null and profile.said.has(key):
			return false
		if entry.has("chance") and rng.randf() >= float(entry.chance):
			return false
	return true


static func bark(data: Dictionary, kind: String, party: Array, used: Array, rng: RandomNumberGenerator,
		profile: Profile = null, fallback := true) -> Dictionary:
	var d: Dictionary = data.get("dialog", {})
	var n := profile.total_descents() if profile != null else 0
	# Kandidaterna: {key, entry, who, pair, rest}; rest = nedstigningar sedan senast (INF = aldrig).
	var cands: Array = []
	var pool := 0
	for pair in d.get("pairs", []):
		if pair.get("kind", "") == kind and party.has(pair.heroes[0]) and party.has(pair.heroes[1]):
			pool += 1
			var key := pair_key(pair)
			if _bark_ok(pair, key, used, profile, rng):
				cands.append({"key": key, "entry": pair, "who": "", "pair": true})
	for id in party:
		if id == "paladin":
			continue
		for e in d.get("barks", {}).get(id, {}).get(kind, []):
			pool += 1
			var key := line_key(e)
			if _bark_ok(e, key, used, profile, rng):
				cands.append({"key": key, "entry": e, "who": id, "pair": false})
	if cands.is_empty():
		return {}
	var limit := clampi(pool * BARK_REST_PER_LINE, 1, BARK_COOLDOWN)
	var rested: Array = []
	for c in cands:
		c.rest = profile.rest(c.key, n) if profile != null else INF
		var cd: int = int(c.entry.cooldown) if c.entry is Dictionary and c.entry.has("cooldown") else limit
		if c.rest >= cd:
			rested.append(c)
	if rested.is_empty():
		if not fallback:
			return {}  # tystnad hellre än upprepning
		rested = cands
	var pick: Dictionary = {}
	var pairs := rested.filter(func(c: Dictionary) -> bool: return c.pair)
	if not pairs.is_empty() and rng.randf() < 0.5:
		pick = _freshest(pairs, rng)
	else:
		var singles := rested.filter(func(c: Dictionary) -> bool: return not c.pair)
		if singles.is_empty():
			pick = _freshest(pairs, rng) if not pairs.is_empty() else {}
		else:
			var speakers: Array = []
			for c in singles:
				if not speakers.has(c.who):
					speakers.append(c.who)
			# Imma säger det mesta, men de andra får ordet ibland.
			var who: String = speakers[0] if speakers.size() == 1 else ""
			if who == "":
				var others := speakers.filter(func(id: String) -> bool: return id != "imma")
				who = "imma" if speakers.has("imma") and rng.randf() >= 0.3 else String(others[rng.randi() % others.size()])
			pick = _freshest(singles.filter(func(c: Dictionary) -> bool: return c.who == who), rng)
	if pick.is_empty():
		return {}
	used.append(pick.key)
	if profile != null:
		profile.note_said(pick.key, n)
	if pick.pair:
		return {"lines": pick.entry.lines.map(func(l: Array) -> Dictionary: return {"who": l[0], "text": l[1]})}
	return {"lines": [{"who": pick.who, "text": line_text(pick.entry)}]}


## Den som vilat längst (aldrig sagda först); slumpen avgör lika.
static func _freshest(cands: Array, rng: RandomNumberGenerator) -> Dictionary:
	var best_rest := -INF
	var best: Array = []
	for c in cands:
		if c.rest > best_rest:
			best_rest = c.rest
			best = [c]
		elif c.rest == best_rest:
			best.append(c)
	return best[rng.randi() % best.size()] if not best.is_empty() else {}
