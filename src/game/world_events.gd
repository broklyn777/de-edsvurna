class_name WorldEvents
extends RefCounted
## Den levande världen (2026-10-23, VD: "att det betyder något är ett måste"). Ren logik utan noder.
##
## **Avvikelse från Siralim:** Siralim har ingen värld som förändras mellan körningarna. Den levande kartan (LivingMap,
## fördärvet 0–4 per Realm) är motorn; här ligger det som märks hemma:
## 1. **Följder** (costs): en Realm på steg COST_AT eller högre kostar något litet i borgen, så länge den står där.
##    Lunden: nät över handelsvägen, smedjans nivåer +15 %. Kryptan: arbetarna vägrar gå ned, Tor skickar ingen bärnsten
##    (annars en per hemkomst). Kapellet: pilgrimerna slutar komma, Mor Elin har ont om förband, helningsförmågorna får en
##    Charge mindre i nästa körning. Allt vänder när Realmen trycks tillbaka.
## 2. **Gåvor** (gifts): en Realm som har stått på steg 2+ och trycks ned till GIFT_AT eller lägre ger något en gång.
##    Lunden: en handelsman kommer med bärnsten och trick. Kryptan: arbetarna hittar bärnsten och silver. Kapellet: en
##    pilgrim med en välsignelse (+1 Charge på helningsförmågorna nästa körning) och ett rykte.
## 3. **Händelser** med tidsgräns (data/world_events.json): ibland, aldrig två samtidigt, startar en händelse i en eller två
##    Realms. Lyckas man (boss, quest eller strider där) ger den något; annars växer Realmen och något blir dyrare en tid.
## Tillståndet ligger i Profile.world (ett lexikon, så att gamla profiler läses som {}).

## Steget där följden börjar, och steget en Realm ska ned till för gåvan.
const COST_AT := 3
const GIFT_AT := 1
## En gåva laddas när Realmen står på minst så här mycket.
const GIFT_ARM := 2
## Smedjans nivåer: lunden på steg 3+, och efter en förlorad karavan.
const SMITH_GROVE := 0.15
const SMITH_EVENT := 0.10
## Kryptans arbetare: bärnsten per hemkomst när kryptan är lugn (steg 0–2).
const TOR_AMBER := 1
## Arbetarnas fynd när kryptan trycks tillbaka.
const WORKERS_AMBER := 3
const WORKERS_SILVER := 30
## Handelsmannen: 5 bärnsten (en färg) eller ett trick för silver; den tacksamma tar halva priset.
const MERCHANT_AMBER := 5
const MERCHANT_AMBER_PRICE := 60
const MERCHANT_TRICK_PRICE := 80
## Den första händelsen tidigast efter så många nedstigningar, och sedan 3–5 nedstigningar mellan starterna.
const FIRST_AT := 4
const GAP_MIN := 3
const GAP_MAX := 5

const COST_IDS := {"grove": "grove_iron", "crypt": "crypt_workers", "chapel": "chapel_bandages"}
const GIFT_IDS := {"grove": "merchant", "crypt": "workers_find", "chapel": "pilgrim"}


# --- Tillståndet ------------------------------------------------------------------

static func state(profile: Profile) -> Dictionary:
	return profile.world


## Den pågående händelsen ({id, left, done, started}) eller {}.
static func active(profile: Profile) -> Dictionary:
	return profile.world.get("event", {})


static func event_data(data: Dictionary, id: String) -> Dictionary:
	return data.get("world_events", {}).get(id, {})


static func event_ids(data: Dictionary) -> Array:
	return data.get("world_events", {}).keys().filter(func(k: String) -> bool: return not k.begins_with("_"))


static func _unlocked(profile: Profile, realm_id: String) -> bool:
	return int(profile.descents.get(realm_id, 0)) > 0


# --- Följder -----------------------------------------------------------------------

## Följderna som gäller nu: [{realm, id}] för varje besökt Realm på steg COST_AT eller högre.
static func costs(profile: Profile, data: Dictionary) -> Array:
	var out := []
	for realm_id in data.realms:
		if COST_IDS.has(realm_id) and _unlocked(profile, realm_id) and LivingMap.growth(profile, realm_id) >= COST_AT:
			out.append({"realm": realm_id, "id": COST_IDS[realm_id]})
	return out


static func has_cost(profile: Profile, realm_id: String) -> bool:
	return COST_IDS.has(realm_id) and _unlocked(profile, realm_id) and LivingMap.growth(profile, realm_id) >= COST_AT


## Smedjans prisfaktor: lunden på steg 3+ och en förlorad karavan (smith_until).
static func smith_mult(profile: Profile) -> float:
	var m := 1.0
	if has_cost(profile, "grove"):
		m += SMITH_GROVE
	if int(profile.world.get("smith_until", 0)) > profile.total_descents():
		m += SMITH_EVENT
	return m


## Smedjan: Hedda förklarar ett högre pris (WorldEvents.smith_mult), eller "".
static func smith_reason(data: Dictionary, profile: Profile) -> String:
	var t: Dictionary = data.get("dialog", {}).get("world", {}).get("smith", {})
	var parts: Array[String] = []
	if WorldEvents.has_cost(profile, "grove"):
		parts.append(String(t.get("grove", "")))
	if int(profile.world.get("smith_until", 0)) > profile.total_descents():
		parts.append(String(t.get("caravan", "")))
	if parts.is_empty():
		return ""
	return "Hedda: " + " ".join(parts) + " (+%d %%)" % roundi((WorldEvents.smith_mult(profile) - 1.0) * 100.0)


## Charges på helningsförmågorna i nästa körning: −1 när kapellet står på 3+, +1 med en pilgrims välsignelse.
static func heal_charge_mod(profile: Profile) -> int:
	var m := 0
	if has_cost(profile, "chapel"):
		m -= 1
	if int(profile.world.get("bless_runs", 0)) > 0:
		m += 1
	return m


## Ger kryptans arbetare bärnsten den här hemkomsten?
static func tor_sends(profile: Profile) -> bool:
	return profile.intro_done and _unlocked(profile, "crypt") and not has_cost(profile, "crypt")


## Kampanjkartans rad om vad Realmen kostar hemma ("" om inget).
static func cost_line(profile: Profile, data: Dictionary, realm_id: String) -> String:
	if not has_cost(profile, realm_id):
		return ""
	return String(data.get("dialog", {}).get("world", {}).get("cost_map", {}).get(realm_id, ""))


# --- En körning --------------------------------------------------------------------

## RunState.new_run: helningsförmågornas Charges och händelsernas styrka för Realmen.
static func apply_to_run(s: RunState, profile: Profile, data: Dictionary) -> void:
	var mod := heal_charge_mod(profile)
	if mod != 0:
		for hero_id in s.charges:
			for ability_id in s.charges[hero_id]:
				if _is_heal(data, ability_id):
					s.charges[hero_id][ability_id] = maxi(1, int(s.charges[hero_id][ability_id]) + mod)
		s.world_heal_mod = mod
	var w := profile.world
	if String(w.get("boss_realm", "")) == s.realm:
		s.world_boss_mult = float(w.get("boss_mult", 1.0))
	if String(w.get("stat_realm", "")) == s.realm:
		s.world_stat_mult = float(w.get("stat_mult", 1.0))


static func _is_heal(data: Dictionary, ability_id: String) -> bool:
	for e in data.abilities.get(ability_id, {}).get("effects", []):
		if e.get("type", "") == "heal":
			return true
	return false


## Run.start_run: välsignelsen och händelsernas styrka förbrukas när körningen börjar.
static func begin_run(profile: Profile, s: RunState) -> void:
	var w := profile.world
	if int(w.get("bless_runs", 0)) > 0:
		w.bless_runs = int(w.bless_runs) - 1
	if String(w.get("boss_realm", "")) == s.realm:
		w.erase("boss_realm")
		w.erase("boss_mult")
	if String(w.get("stat_realm", "")) == s.realm:
		w.erase("stat_realm")
		w.erase("stat_mult")


# --- Efter en nedstigning ----------------------------------------------------------

## Efter en nedstigning (Run.end_descent, efter LivingMap.after_descent). before = fördärvet per Realm före kartans
## ändring. Ändrar profilen och returnerar rapporten:
## {event_end: {id, result, realms, gains}, event_start: {id}, costs_on: [realm], costs_off: [realm],
##  gifts: [{realm, id, ...}], tor: bärnsten-id eller "", lines: [sammanfattning]}.
static func after_descent(profile: Profile, data: Dictionary, realm_id: String, outcome: String, wins: int,
		quest_done: bool, before: Dictionary, boss_beaten := false, n := -1) -> Dictionary:
	if n < 0:
		n = profile.total_descents()
	var w := profile.world
	var rep := {"event_end": {}, "event_start": {}, "costs_on": [], "costs_off": [], "gifts": [], "tor": "", "lines": []}
	if not profile.intro_done:
		return rep
	# 1. Händelsen.
	var ev := active(profile)
	if not ev.is_empty():
		var info := event_data(data, String(ev.id))
		if info.is_empty():
			w.erase("event")
		else:
			var done: Array = ev.get("done", [])
			if Array(info.realms).has(realm_id) and not done.has(realm_id) \
					and _won(String(info.win), outcome, wins, quest_done, boss_beaten):
				done.append(realm_id)
			ev.done = done
			ev.left = int(ev.left) - 1
			if done.size() >= Array(info.realms).size():
				rep.event_end = _finish(profile, data, ev, "won", realm_id)
			elif int(ev.left) <= 0:
				rep.event_end = _finish(profile, data, ev, "half" if not done.is_empty() else "lost", realm_id)
	# 2. Följder och gåvor: jämför fördärvet före och efter.
	var arm: Dictionary = w.get("armed", {})
	for r in data.realms:
		if not _unlocked(profile, r):
			continue
		var g0 := int(before.get(r, LivingMap.growth(profile, r)))
		var g1 := LivingMap.growth(profile, r)
		if COST_IDS.has(r):
			if g0 < COST_AT and g1 >= COST_AT:
				rep.costs_on.append(r)
			elif g0 >= COST_AT and g1 < COST_AT:
				rep.costs_off.append(r)
		if g0 >= GIFT_ARM or g1 >= GIFT_ARM:
			arm[r] = true
		if g1 <= GIFT_AT and g0 > g1 and arm.get(r, false) and GIFT_IDS.has(r):
			arm.erase(r)
			rep.gifts.append(_gift(profile, data, r, n))
	w.armed = arm
	# 3. Kryptans arbetare skickar bärnsten när det är lugnt där.
	if tor_sends(profile):
		var ambers: Array = data.materials.amber.keys()
		var id: String = ambers[posmod(n * 3 + 1, ambers.size())]
		profile.materials[id] = int(profile.materials.get(id, 0)) + TOR_AMBER
		rep.tor = id
	# 4. En ny händelse, aldrig två samtidigt.
	if active(profile).is_empty() and rep.event_end.is_empty():
		var id := pick_event(profile, data, n)
		if id != "":
			rep.event_start = start(profile, data, id, n)
	rep.lines = summary(profile, data, rep)
	return rep


static func _won(win: String, outcome: String, wins: int, quest_done: bool, boss_beaten: bool) -> bool:
	if win == "boss":
		return outcome == "boss" or boss_beaten
	if win == "quest":
		return quest_done
	if win.begins_with("wins:"):
		return wins >= int(win.get_slice(":", 1))
	return false


## Nästa händelse som kan starta efter nedstigning n, eller "". Alla dess Realms måste vara besökta; den som har legat
## längst sedan sist väljs (i datans ordning vid lika).
static func pick_event(profile: Profile, data: Dictionary, n: int) -> String:
	var w := profile.world
	if not profile.intro_done or not active(profile).is_empty():
		return ""
	if n < int(w.get("next", FIRST_AT)):
		return ""
	var best := ""
	var best_last := 1 << 30
	var last: Dictionary = w.get("last", {})
	for id in event_ids(data):
		var info := event_data(data, id)
		var ok := true
		for r in info.get("realms", []):
			if not data.realms.has(r) or not _unlocked(profile, r):
				ok = false
		if not ok:
			continue
		var l := int(last.get(id, -1))
		if best == "" or l < best_last:
			best = id
			best_last = l
	return best


## Startar händelsen (efter nedstigning n). Nästa start tidigast GAP_MIN–GAP_MAX nedstigningar senare.
static func start(profile: Profile, data: Dictionary, id: String, n := -1) -> Dictionary:
	if n < 0:
		n = profile.total_descents()
	var info := event_data(data, id)
	var w := profile.world
	w.event = {"id": id, "left": int(info.get("turns", 2)), "done": [], "started": n}
	var last: Dictionary = w.get("last", {})
	last[id] = n
	w.last = last
	w.next = n + GAP_MIN + posmod(hash(id) + n, GAP_MAX - GAP_MIN + 1)
	return {"id": id, "realms": Array(info.get("realms", []))}


## Händelsen slutar: result won/half/lost. Ger belöningen eller följderna och skriver in den i loggen.
## visited = Realmen man just gick till: den har redan trängts tillbaka och växer inte av händelsen (bara de andra följderna).
static func _finish(profile: Profile, data: Dictionary, ev: Dictionary, result: String, visited := "") -> Dictionary:
	var w := profile.world
	var id := String(ev.id)
	var info := event_data(data, id)
	var gains := {}
	var realms: Array = info.get("realms", [])
	var done: Array = ev.get("done", [])
	if result == "won":
		gains = _gain(profile, data, info.get("on_win", {}), "", profile.total_descents())
	else:
		# Förlorat: varje Realm som inte stoppades får följderna (vid half bara den andra).
		for r in realms:
			if not done.has(r):
				var lose: Dictionary = info.get("on_lose", {}).duplicate()
				if r == visited:
					lose.erase("growth")
				var g := _gain(profile, data, lose, r, profile.total_descents())
				for k in g:
					gains[k] = g[k]
				if g.has("growth"):
					gains["grew"] = Array(gains.get("grew", [])) + [r]
	w.erase("event")
	var log: Array = w.get("log", [])
	log.append({"id": id, "result": result, "n": profile.total_descents()})
	while log.size() > 20:
		log.pop_front()
	w.log = log
	var won: Dictionary = w.get("won", {})
	if result == "won":
		won[id] = int(won.get(id, 0)) + 1
	w.won = won
	return {"id": id, "result": result, "realms": realms, "done": done, "gains": gains}


## Ger en belöning eller en följd (on_win/on_lose); realm = Realmen den gäller (för growth och styrkan).
static func _gain(profile: Profile, data: Dictionary, g: Dictionary, realm_id: String, n: int) -> Dictionary:
	var w := profile.world
	var out := {}
	if g.has("silver"):
		profile.silver += int(g.silver)
		out.silver = int(g.silver)
	if g.has("growth") and realm_id != "":
		profile.growth[realm_id] = mini(LivingMap.growth(profile, realm_id) + int(g.growth), LivingMap.GROWTH_MAX)
		profile.growth_rest.erase(realm_id)
		out.growth = int(g.growth)
	if g.get("stone", false):
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("world_stone") + n
		var stone := Forge.roll_stone(data, maxi(profile.best_depth, 1) + 1, 1, rng, profile.next_stone_id)
		profile.next_stone_id += 1
		profile.stones.append(stone)
		out.stone = stone
	if g.has("merchant"):
		w.merchant = {"grateful": String(g.merchant) == "grateful"}
		out.merchant = true
	if g.has("bless_runs"):
		w.bless_runs = int(w.get("bless_runs", 0)) + int(g.bless_runs)
		out.bless_runs = int(g.bless_runs)
	if g.has("smith_runs"):
		w.smith_until = n + int(g.smith_runs)
		out.smith_runs = int(g.smith_runs)
	if g.has("boss_mult") and realm_id != "":
		w.boss_realm = realm_id
		w.boss_mult = float(g.boss_mult)
		out.boss_mult = float(g.boss_mult)
	if g.has("stat_mult") and realm_id != "":
		w.stat_realm = realm_id
		w.stat_mult = float(g.stat_mult)
		out.stat_mult = float(g.stat_mult)
	return out


## En gåva när Realmen trycks tillbaka.
static func _gift(profile: Profile, data: Dictionary, realm_id: String, n: int) -> Dictionary:
	var w := profile.world
	match realm_id:
		"grove":
			w.merchant = {"grateful": false}
			return {"realm": realm_id, "id": "merchant"}
		"crypt":
			var ambers: Array = data.materials.amber.keys()
			var id: String = ambers[posmod(n * 7 + 2, ambers.size())]
			profile.materials[id] = int(profile.materials.get(id, 0)) + WORKERS_AMBER
			profile.silver += WORKERS_SILVER
			return {"realm": realm_id, "id": "workers_find", "amber": id, "silver": WORKERS_SILVER}
		"chapel":
			w.bless_runs = int(w.get("bless_runs", 0)) + 1
			return {"realm": realm_id, "id": "pilgrim"}
	return {"realm": realm_id, "id": ""}


# --- Handelsmannen -----------------------------------------------------------------

static func merchant_here(profile: Profile) -> bool:
	return not profile.world.get("merchant", {}).is_empty()


static func merchant_price(profile: Profile, what: String) -> int:
	var base := MERCHANT_AMBER_PRICE if what == "amber" else MERCHANT_TRICK_PRICE
	return base / 2 if profile.world.get("merchant", {}).get("grateful", false) else base


## Vad handelsmannen har (samma tills han har gått): {amber, trick}.
static func merchant_goods(profile: Profile, data: Dictionary) -> Dictionary:
	var ambers: Array = data.materials.amber.keys()
	var tricks: Array = data.materials.tricks.keys()
	var n := profile.total_descents()
	return {"amber": ambers[posmod(n * 5 + 3, ambers.size())], "trick": tricks[posmod(n * 3, tricks.size())]}


## Köper av handelsmannen (what = amber eller trick); han går sedan. Falskt om silvret inte räcker.
static func merchant_buy(profile: Profile, data: Dictionary, what: String) -> bool:
	if not merchant_here(profile):
		return false
	var price := merchant_price(profile, what)
	if profile.silver < price:
		return false
	var goods := merchant_goods(profile, data)
	profile.silver -= price
	var id: String = goods[what]
	profile.materials[id] = int(profile.materials.get(id, 0)) + (MERCHANT_AMBER if what == "amber" else 1)
	profile.world.erase("merchant")
	return true


# --- Texter ------------------------------------------------------------------------

static func _w(data: Dictionary) -> Dictionary:
	return data.get("dialog", {}).get("world", {})


## Hemkomstens sammanfattning (utan repliker): händelsen, följderna, gåvorna och arbetarnas bärnsten.
static func summary(profile: Profile, data: Dictionary, rep: Dictionary) -> Array:
	var out: Array = []
	var t := _w(data)
	var end: Dictionary = rep.get("event_end", {})
	if not end.is_empty():
		var info := event_data(data, String(end.id))
		var key := String({"won": "win_text", "half": "half_text", "lost": "lose_text"}.get(String(end.result), "lose_text"))
		out.append("%s: %s" % [info.get("name", ""), info.get(key, info.get("lose_text", ""))])
	for r in rep.get("costs_on", []):
		out.append(String(t.get("cost_on", {}).get(r, "")))
	for r in rep.get("costs_off", []):
		out.append(String(t.get("cost_off", {}).get(r, "")))
	for g in rep.get("gifts", []):
		out.append(String(t.get("gift", {}).get(String(g.realm), "")))
	if String(rep.get("tor", "")) != "":
		out.append(String(t.get("tor", "")).replace("{bärnsten}", String(data.materials.amber[rep.tor].name).to_lower()))
	var start: Dictionary = rep.get("event_start", {})
	if not start.is_empty():
		var info := event_data(data, String(start.id))
		out.append("Nytt: %s. %s" % [info.get("name", ""), info.get("text", "")])
	return out.filter(func(s: String) -> bool: return s != "")


## Kampanjkartans rad om händelsen ("" om ingen): "Kulten samlas till högtid – fäll biskopen (två nedstigningar kvar)".
static func map_line(profile: Profile, data: Dictionary) -> String:
	var ev := active(profile)
	if ev.is_empty():
		return ""
	var info := event_data(data, String(ev.id))
	var left := int(ev.left)
	return "%s (%s kvar)" % [info.get("mark", info.get("name", "")),
			"en nedstigning" if left == 1 else "%s nedstigningar" % Chronicle.number(left)]


## Är Realmen med i den pågående händelsen (och inte redan stoppad)?
static func in_event(profile: Profile, data: Dictionary, realm_id: String) -> bool:
	var ev := active(profile)
	if ev.is_empty():
		return false
	return Array(event_data(data, String(ev.id)).get("realms", [])).has(realm_id) and not Array(ev.get("done", [])).has(realm_id)


## En replik i borgen om det som pågår (händelsen eller en följd) från personen, eller "". dialog.json world.ongoing.
static func ongoing_line(profile: Profile, data: Dictionary, who: String, turn: int) -> String:
	var pool: Array = []
	var ev := active(profile)
	for l in _w(data).get("ongoing", []):
		if String(l.get("who", "")) != who:
			continue
		if l.has("event") and not ev.is_empty() and String(l.event) == String(ev.id):
			pool.append(l)
		elif l.has("cost") and has_cost(profile, String(l.cost)):
			pool.append(l)
		elif l.has("merchant") and merchant_here(profile):
			pool.append(l)
	if pool.is_empty():
		return ""
	return Dialog.line_text(pool[posmod(turn, pool.size())])


# --- För skärmdumpar och tester ----------------------------------------------------

## --event=<id>: en händelse pågår (sparas inte).
static func demo_event(profile: Profile, data: Dictionary, id: String) -> void:
	profile.intro_done = true
	for r in event_data(data, id).get("realms", []):
		profile.descents[r] = maxi(int(profile.descents.get(r, 0)), 1)
	start(profile, data, id, profile.total_descents())
