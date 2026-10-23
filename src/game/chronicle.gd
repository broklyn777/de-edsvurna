class_name Chronicle
extends RefCounted
## Krönikan (2026-10-23, VD: "så man känner att man inte är ensam"). Ren logik utan noder.
##
## Tre delar som hänger ihop:
## 1. **Minnet.** Profile.chronicle får en kort post per nedstigning (Realm, djup, utfall, bossar som föll, vem som föll,
##    vem som befriades, sällsynta fynd, nya troféer, löftet och kartans förändringar), och Profile.chron_stats räknar
##    mönster (nedstigningar i rad i samma Realm, segrar i rad, förluster i rad, fall per hjälte, hållna löften …).
##    RunState.chron håller profilen som den var när körningen började (begin) och det som bara striden vet
##    (note_battle, note_finds); end() jämför och skriver posten.
## 2. **Hemkomsten.** Den viktigaste händelsen (PRIO) får en replik av den som det angår (dialog.json "chronicle"):
##    Mor Elin när någon föll, Hedda vid en sällsynt sten, Broder Alrik vid troféer, den befriade första gången hemma,
##    Gorm vid ett nytt djup, Imma vid stora saker och som standard, och följeslagare som var med om varandra. Högst
##    MAX_REMARKS repliker (den andra bara för en viktig händelse), och ingen replik upprepas förrän de andra med samma
##    villkor har sagts (Profile.chron_said). Den levande kartans replik tävlar om samma platser (MAP_PRIO).
## 3. **Titlar** (data/titles.json, vårt val; om Siralim har spelartitlar är okänt). Villkoren läses ur krönikan och
##    profilen; spelaren väljer titel hos Broder Alrik. Den första titeln bärs direkt (vårt val). {titel} i en replik
##    gör att den bara väljs när spelaren har en titel.

const MAX_ENTRIES := 50
## Så många poster visar Broder Alrik.
const SHOWN := 10
## Under så här stor del av livet efter den sista striden räknas en hjälte som svårt skadad.
const HURT_PCT := 0.3
## Så många fall (totalt) innan "faller ofta".
const FELL_OFTEN := 3
## Segrar i rad som räknas som en rad (och en förlust efter den som ett brott).
const STREAK_AT := 3
## Förluster i rad före en seger som räknas som att resa sig.
const COMEBACK_AFTER := 3
const MAX_REMARKS := 2
## Den andra repliken bara för en händelse som är minst så här viktig.
const SECOND_MIN_PRIO := 44
## Folket i borgen talar alltid; följeslagare bara om de var med (eller om händelsen handlar om dem).
const KEEP_PEOPLE := ["gorm", "hedda", "alrik", "elin", "stig", "sven"]

const PRIO := {"twisted_boss": 100, "boss_trophy": 92, "first_boss": 90, "new_depth": 80, "rescued": 75,
		"rare_find": 70, "fell_often": 66, "fell": 62, "streak_broken": 58, "streak": 56, "lost": 54, "comeback": 53,
		"vow_kept": 50, "vow_broken": 46, "nether": 44, "hurt": 42, "same_realm": 38, "boss_again": 36,
		"new_trophy": 34, "new_title": 30, "home_won": 5, "home_left": 5}
## Den levande kartans repliker (LivingMap.news) i samma skala.
const MAP_PRIO := {"wake": 86, "calm_twisted": 60, "warn": 48, "calm": 20, "rise": 15}
## Händelser om samma sak: bara en av dem får en replik.
const FAMILY := {"fell_often": "fell", "boss_trophy": "boss", "first_boss": "boss", "boss_again": "boss",
		"twisted_boss": "boss", "streak_broken": "lost", "home_won": "home", "home_left": "home", "nether": "rare_find"}
const TIMES := ["", "en gång", "två gånger", "tre gånger", "fyra gånger", "fem gånger"]


# --- Under körningen ---------------------------------------------------------------

## När körningen börjar (Run.start_run): det som end() jämför med.
static func begin(profile: Profile, party: Array) -> Dictionary:
	return {"collection": profile.collection.duplicate(), "boss_wins": profile.boss_wins.duplicate(),
			"recruited": profile.recruited.duplicate(), "best_depth": profile.best_depth, "alone": party.size() == 1,
			"fell": {}, "hurt": [], "rare": 0, "legendary": 0, "nether": 0}


## Efter varje strid i körningen: vem som föll (och hur många gånger) och vem som stod kvar med lite liv.
static func note_battle(chron: Dictionary, heroes: Array) -> void:
	if not chron.has("fell"):
		chron.fell = {}
	var hurt: Array = []
	for u in heroes:
		if int(u.deaths) > 0:
			chron.fell[u.id] = int(chron.fell.get(u.id, 0)) + int(u.deaths)
		elif u.alive and float(u.hp) < float(u.max_hp) * HURT_PCT:
			hurt.append(u.id)
	chron.hurt = hurt


## Fynden i körningen: Nether Stones och sällsynta stenar (Forge.is_rare_find).
static func note_finds(chron: Dictionary, finds: Array) -> void:
	for f in finds:
		if f.kind != "nether":
			continue
		chron.nether = int(chron.get("nether", 0)) + 1
		if Forge.is_rare_find(f):
			chron.rare = int(chron.get("rare", 0)) + 1
			if f.stone.rarity == "legendary":
				chron.legendary = int(chron.get("legendary", 0)) + 1


# --- Efter körningen ---------------------------------------------------------------

## Nedstigningen är slut (Run.end_descent). outcome: "boss" (klarad), "loss", "forfeit" (gav upp i striden), "home" (gick
## hem). map_changes = LivingMap.after_descent. Skriver posten, räknarna, titlarna och hemkomstens repliker
## (Profile.homecoming). Returnerar posten.
static func end(profile: Profile, data: Dictionary, state: RunState, outcome: String, map_changes: Array = []) -> Dictionary:
	var c: Dictionary = state.chron
	var before_wins: Dictionary = c.get("boss_wins", profile.boss_wins)
	var before_rec: Array = c.get("recruited", profile.recruited)
	var before_col: Array = c.get("collection", profile.collection)
	var entry := {"n": profile.total_descents(), "realm": state.realm, "depth": state.depth, "outcome": outcome,
			"party": Array(state.party), "wins": state.wins, "quest": state.realm_quest_done,
			"alone": bool(c.get("alone", false)), "fell": (c.get("fell", {}) as Dictionary).duplicate(),
			"hurt": Array(c.get("hurt", [])), "rare": int(c.get("rare", 0)), "legendary": int(c.get("legendary", 0)),
			"nether": int(c.get("nether", 0))}
	var bosses: Array = []
	for kind in profile.boss_wins:
		if int(profile.boss_wins[kind]) > int(before_wins.get(kind, 0)):
			bosses.append(kind)
	entry.bosses = bosses
	entry.first_bosses = bosses.filter(func(k: String) -> bool: return int(before_wins.get(k, 0)) == 0)
	entry.boss_trophies = bosses.filter(func(k: String) -> bool:
			return int(before_wins.get(k, 0)) < RunState.BOSS_WINS_FOR_TROPHY \
					and int(profile.boss_wins[k]) >= RunState.BOSS_WINS_FOR_TROPHY)
	var twisted := LivingMap.twisted_boss(data, state.realm)
	entry.twisted = twisted if twisted != "" and bosses.has(twisted) else ""
	# Imma bor i borgen; att hon smiter efter i introt är ingen befrielse.
	entry.rescued = Array(profile.recruited).filter(func(id: String) -> bool:
			return not before_rec.has(id) and id != Profile.STARTER)
	entry.trophies = Array(profile.collection).filter(func(t: String) -> bool: return not before_col.has(t))
	entry.new_depth = profile.best_depth if profile.best_depth > int(c.get("best_depth", profile.best_depth)) else 0
	entry.vow = state.vow
	entry.vow_result = ""
	if state.vow != "":
		entry.vow_result = "broken" if state.vow_broken else ("kept" if outcome == "boss" else "open")
	entry.map = map_changes.map(func(m: Dictionary) -> Dictionary:
			return {"realm": m.realm, "from": int(m.from), "to": int(m.to), "why": m.why})
	_count(profile, entry)
	entry.titles = unlock_titles(profile, data)
	profile.chronicle.append(entry)
	while profile.chronicle.size() > MAX_ENTRIES:
		profile.chronicle.pop_front()
	profile.homecoming = homecoming(profile, data, entry, profile.growth_news)
	return entry


## Räknarna (Profile.chron_stats) efter posten; posten får de mönster som gäller nu.
static func _count(profile: Profile, entry: Dictionary) -> void:
	var st := profile.chron_stats
	st.descents = int(st.get("descents", 0)) + 1
	if String(st.get("realm_last", "")) == entry.realm:
		st.realm_streak = int(st.get("realm_streak", 0)) + 1
	else:
		st.realm_last = entry.realm
		st.realm_streak = 1
	entry.realm_streak = int(st.realm_streak)
	var won: bool = entry.outcome == "boss"
	var lost: bool = entry.outcome in ["loss", "forfeit"]
	entry.comeback = false
	entry.streak_broken = 0
	if won:
		if int(st.get("loss_streak", 0)) >= COMEBACK_AFTER:
			st.comebacks = int(st.get("comebacks", 0)) + 1
			entry.comeback = true
		st.loss_streak = 0
		st.win_streak = int(st.get("win_streak", 0)) + 1
		st.best_win_streak = maxi(int(st.get("best_win_streak", 0)), int(st.win_streak))
	else:
		if lost:
			if int(st.get("win_streak", 0)) >= STREAK_AT:
				entry.streak_broken = int(st.win_streak)
			st.loss_streak = int(st.get("loss_streak", 0)) + 1
		st.win_streak = 0  # att gå hem bryter raden men räknas inte som en förlust
	entry.win_streak = int(st.win_streak)
	var falls: Dictionary = st.get("falls", {})
	for h in entry.fell:
		falls[h] = int(falls.get(h, 0)) + int(entry.fell[h])
	st.falls = falls
	match entry.vow_result:
		"kept":
			st.vows_kept = int(st.get("vows_kept", 0)) + 1
		"broken":
			st.vows_broken = int(st.get("vows_broken", 0)) + 1
	if entry.alone:
		st.alone_descents = int(st.get("alone_descents", 0)) + 1


# --- Hemkomstens repliker -----------------------------------------------------------

static func _ev(key: String, extra := {}) -> Dictionary:
	var e := {"key": key, "prio": int(PRIO.get(key, 0))}
	e.merge(extra)
	return e


## Det som hände, viktigast först: [{key, prio, subject, boss, antal, djup, ny_titel}].
static func events(profile: Profile, data: Dictionary, entry: Dictionary) -> Array:
	var out: Array = []
	var st := profile.chron_stats
	if entry.get("twisted", "") != "":
		out.append(_ev("twisted_boss", {"boss": entry.twisted}))
	for kind in entry.get("bosses", []):
		if kind == entry.get("twisted", ""):
			continue
		if entry.get("boss_trophies", []).has(kind):
			out.append(_ev("boss_trophy", {"boss": kind}))
		elif entry.get("first_bosses", []).has(kind):
			out.append(_ev("first_boss", {"boss": kind}))
		else:
			out.append(_ev("boss_again", {"boss": kind, "antal": int(profile.boss_wins.get(kind, 0))}))
	if int(entry.get("new_depth", 0)) > 0:
		out.append(_ev("new_depth", {"djup": int(entry.new_depth)}))
	for id in entry.get("rescued", []):
		out.append(_ev("rescued", {"subject": id}))
	if int(entry.get("rare", 0)) > 0:
		out.append(_ev("rare_find"))
	elif int(entry.get("nether", 0)) > 0:
		out.append(_ev("nether"))
	# Den som föll flest gånger nu (sällskapets ordning vid lika); de som faller ofta får en egen händelse.
	var fallen: Array = Array(entry.get("party", [])).filter(func(id: String) -> bool: return entry.fell.has(id))
	for id in entry.fell:
		if not fallen.has(id):
			fallen.append(id)
	var by_count := fallen.duplicate()
	by_count.sort_custom(func(a: String, b: String) -> bool:
			return int(entry.fell[a]) > int(entry.fell[b]) or (int(entry.fell[a]) == int(entry.fell[b]) and fallen.find(a) < fallen.find(b)))
	for id in by_count:
		var total := int(st.get("falls", {}).get(id, 0))
		if total >= FELL_OFTEN:
			out.append(_ev("fell_often", {"subject": id, "antal": total}))
	if not by_count.is_empty():
		out.append(_ev("fell", {"subject": by_count[0], "antal": int(entry.fell[by_count[0]])}))
	if int(entry.get("streak_broken", 0)) > 0:
		out.append(_ev("streak_broken", {"antal": int(entry.streak_broken)}))
	if entry.outcome in ["loss", "forfeit"]:
		out.append(_ev("lost"))
	if entry.get("comeback", false):
		out.append(_ev("comeback"))
	var ws := int(entry.get("win_streak", 0))
	if ws >= STREAK_AT and (ws == STREAK_AT or ws % 5 == 0):
		out.append(_ev("streak", {"antal": ws}))
	match entry.get("vow_result", ""):
		"kept":
			out.append(_ev("vow_kept"))
		"broken":
			out.append(_ev("vow_broken"))
	if by_count.is_empty() and not entry.get("hurt", []).is_empty():
		out.append(_ev("hurt", {"subject": entry.hurt[0]}))
	var rs := int(entry.get("realm_streak", 0))
	if rs >= 3 and rs % 3 == 0:
		out.append(_ev("same_realm", {"antal": rs}))
	if not entry.get("trophies", []).is_empty():
		out.append(_ev("new_trophy", {"antal": entry.trophies.size()}))
	if not entry.get("titles", []).is_empty():
		out.append(_ev("new_title", {"ny_titel": entry.titles[0]}))
	if entry.outcome == "boss":
		out.append(_ev("home_won"))
	elif entry.outcome == "home":
		out.append(_ev("home_left"))
	for i in out.size():
		out[i].realm = entry.realm
		out[i].order = i
	# Stabil sortering: högst prioritet först, annars i den ordning de lades till.
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.prio) > int(b.prio) or (int(a.prio) == int(b.prio) and int(a.order) < int(b.order)))
	return out


## Hemkomstens ruta: {remarks: [{speaker, id, text}], titles: [id], n}. growth_news = den levande kartans nyheter (dess
## replik tävlar med krönikans).
static func homecoming(profile: Profile, data: Dictionary, entry: Dictionary, growth_news := {}) -> Dictionary:
	var map_remark := {}
	if String(growth_news.get("speaker", "")) != "":
		var lid := String(growth_news.get("line_id", ""))
		map_remark = {"speaker": growth_news.speaker, "id": lid, "text": String(growth_news.get("text", "")),
				"prio": int(MAP_PRIO.get(_map_key(lid), 20)), "map": true}
	return {"remarks": pick_remarks(profile, data, entry, map_remark), "titles": Array(entry.get("titles", [])),
			"n": int(entry.get("n", 0))}


## "imma_map_calm_twisted_1" -> "calm_twisted".
static func _map_key(line_id: String) -> String:
	if not line_id.contains("_map_"):
		return ""
	var rest := line_id.get_slice("_map_", 1)
	var tail := rest.get_slice("_", rest.get_slice_count("_") - 1)
	return rest.left(rest.length() - tail.length() - 1) if tail.is_valid_int() else rest


## Väljer 1–MAX_REMARKS repliker: den viktigaste händelsen som någon kan säga något om, och kanske en till om en annan sak
## (av en annan person). map_remark = den levande kartans replik med "prio", eller {}.
static func pick_remarks(profile: Profile, data: Dictionary, entry: Dictionary, map_remark := {}) -> Array:
	var evs := events(profile, data, entry)
	if not map_remark.is_empty():
		var at := 0
		while at < evs.size() and int(evs[at].prio) >= int(map_remark.prio):
			at += 1
		evs.insert(at, {"key": "map", "prio": int(map_remark.prio), "remark": map_remark})
	var out: Array = []
	var families: Array = []
	var speakers: Array = []
	for ev in evs:
		if out.size() >= MAX_REMARKS or (not out.is_empty() and int(ev.prio) < SECOND_MIN_PRIO):
			break
		var fam := String(FAMILY.get(ev.key, ev.key))
		if families.has(fam):
			continue
		var r: Dictionary
		if ev.key == "map":
			r = {"speaker": ev.remark.speaker, "id": ev.remark.id, "text": ev.remark.text, "key": "map"}
			if speakers.has(r.speaker):
				continue
		else:
			r = line_for(profile, data, entry, ev, speakers)
		if r.is_empty():
			continue
		out.append(r)
		families.append(fam)
		speakers.append(r.speaker)
	return out


## Talaren för repliken ("subject" = den händelsen handlar om), eller "" om den inte kan säga den.
static func _speaker(profile: Profile, entry: Dictionary, ev: Dictionary, line: Dictionary) -> String:
	var subject := String(ev.get("subject", ""))
	if line.has("subject") and String(line.subject) != subject:
		return ""
	var who := String(line.get("who", ""))
	if who == "subject":
		return subject if subject != "" and subject != "paladin" and profile.recruited.has(subject) else ""
	if who == subject:
		return ""  # ingen talar om sig själv i tredje person
	if KEEP_PEOPLE.has(who):
		return who
	return who if profile.recruited.has(who) and Array(entry.get("party", [])).has(who) else ""


## En replik för händelsen ur dialog.json "chronicle": de som gäller just den hjälten först, annars de allmänna; ingen
## upprepas förrän de andra har sagts (Profile.chron_said). {speaker, id, text, key} eller {}.
static func line_for(profile: Profile, data: Dictionary, entry: Dictionary, ev: Dictionary, busy := []) -> Dictionary:
	var specific: Array = []
	var plain: Array = []
	for line in data.get("dialog", {}).get("chronicle", {}).get("lines", []):
		if line.get("key", "") != ev.key:
			continue
		if String(line.text).contains("{titel}") and profile.title == "":
			continue
		var who := _speaker(profile, entry, ev, line)
		if who == "" or busy.has(who):
			continue
		(specific if line.has("subject") else plain).append(line)
	var pool := specific if not specific.is_empty() else plain
	if pool.is_empty():
		return {}
	var fresh := pool.filter(func(l: Dictionary) -> bool: return not profile.chron_said.has(l.id))
	if fresh.is_empty():
		for l in pool:
			profile.chron_said.erase(l.id)
		fresh = pool
	var line: Dictionary = fresh[posmod(int(entry.get("n", 0)) * 7 + ev.key.length(), fresh.size())]
	profile.chron_said.append(line.id)
	return {"speaker": _speaker(profile, entry, ev, line), "id": line.id, "key": ev.key,
			"text": fill(String(line.text), profile, data, ev)}


## {namn}, {titel} (titeln, annars namnet), {ny_titel}, {hjälte}, {plats}/{Plats}, {boss}, {antal}, {djup}.
static func fill(text: String, profile: Profile, data: Dictionary, ctx := {}) -> String:
	var short := String(data.realms.get(ctx.get("realm", ""), {}).get("short", ""))
	# "Den fallne biskopen" mitt i en mening blir "den fallne biskopen".
	var boss := String(data.enemies.get(ctx.get("boss", ""), {}).get("name", ""))
	if boss.begins_with("Den ") and not text.begins_with("{boss}"):
		boss = "den " + boss.substr(4)
	text = text.replace("{Plats}", short).replace("{plats}", short.to_lower()) \
			.replace("{hjälte}", hero_name(profile, data, String(ctx.get("subject", "")))) \
			.replace("{boss}", boss) \
			.replace("{antal}", str(ctx.get("antal", 0))).replace("{djup}", str(ctx.get("djup", 0))) \
			.replace("{ny_titel}", title_name(data, String(ctx.get("ny_titel", "")))) \
			.replace("{titel}", title_or_name(profile, data))
	text = Dialog.fill(text, profile.hero_name)
	return text.substr(0, 1).to_upper() + text.substr(1)


static func hero_name(profile: Profile, data: Dictionary, id: String) -> String:
	if id == "paladin" or id == "":
		return profile.hero_name
	var h: Dictionary = data.heroes.get(id, {})
	return String(h.get("short", h.get("name", id)))


# --- Titlar --------------------------------------------------------------------------

static func title_ids(data: Dictionary) -> Array:
	return data.get("titles", {}).keys().filter(func(k: String) -> bool: return not k.begins_with("_"))


static func title_name(data: Dictionary, id: String) -> String:
	return String(data.get("titles", {}).get(id, {}).get("name", ""))


## Den valda titeln, eller namnet om spelaren inte har någon ({titel} faller tillbaka till {namn}).
static func title_or_name(profile: Profile, data: Dictionary) -> String:
	var t := title_name(data, profile.title)
	return t if t != "" else profile.hero_name


static func title_met(profile: Profile, cond: Dictionary) -> bool:
	for key in cond:
		var v: Variant = cond[key]
		match key:
			"boss_wins":
				for kind in v:
					if int(profile.boss_wins.get(kind, 0)) < int(v[kind]):
						return false
			"realm_depth":
				for realm_id in v:
					if int(profile.realm_depth.get(realm_id, 0)) < int(v[realm_id]):
						return false
			"stat":
				for s in v:
					if int(profile.chron_stats.get(s, 0)) < int(v[s]):
						return false
			"best_depth":
				if profile.best_depth < int(v):
					return false
			"rescued":
				if Array(profile.recruited).filter(func(id: String) -> bool: return id != Profile.STARTER).size() < int(v):
					return false
			"descents":
				if profile.total_descents() < int(v):
					return false
			_:
				return false
	return true


## Låser upp de titlar som har förtjänats; den första bärs direkt om spelaren inte har någon. Returnerar de nya.
static func unlock_titles(profile: Profile, data: Dictionary) -> Array:
	var fresh: Array = []
	for id in title_ids(data):
		if not profile.titles.has(id) and title_met(profile, data.titles[id].get("cond", {})):
			profile.titles.append(id)
			fresh.append(id)
	if profile.title == "" and not fresh.is_empty():
		profile.title = fresh[0]
	return fresh


## Väljer titel hos Broder Alrik ("" = ingen). Falskt om den inte är upplåst.
static func choose_title(profile: Profile, id: String) -> bool:
	if id != "" and not profile.titles.has(id):
		return false
	profile.title = id
	return true


# --- Krönikan hos Broder Alrik -----------------------------------------------------

## De senaste posterna, nyast först.
static func recent(profile: Profile, count := SHOWN) -> Array:
	var out: Array = profile.chronicle.slice(maxi(profile.chronicle.size() - count, 0))
	out.reverse()
	return out


const NUMBERS := ["noll", "en", "två", "tre", "fyra", "fem", "sex", "sju", "åtta", "nio", "tio"]


static func number(n: int) -> String:
	return NUMBERS[n] if n >= 0 and n < NUMBERS.size() else str(n)


static func times(n: int) -> String:
	return TIMES[n] if n >= 0 and n < TIMES.size() else "%d gånger" % n


## "12. Kryptan, djup 2 – seger"
static func entry_head(data: Dictionary, entry: Dictionary) -> String:
	var outcome := String({"boss": "seger", "loss": "förlust", "forfeit": "gav upp", "home": "vände hem"}.get(entry.get("outcome", ""), ""))
	var realm := String(data.realms.get(entry.get("realm", ""), {}).get("short", entry.get("realm", "")))
	return "%d. %s, djup %d – %s" % [int(entry.get("n", 0)), realm, int(entry.get("depth", 1)), outcome]


## Postens rader i klartext, korta meningar.
static func entry_body(profile: Profile, data: Dictionary, entry: Dictionary) -> String:
	var parts: Array[String] = []
	var bosses: Array = entry.get("bosses", [])
	if not bosses.is_empty():
		parts.append("%s föll." % " och ".join(bosses.map(func(k: String) -> String: return String(data.enemies.get(k, {}).get("name", k)))))
	if int(entry.get("new_depth", 0)) > 0:
		parts.append("Djup %d klarat för första gången." % int(entry.new_depth))
	if bool(entry.get("alone", false)):
		parts.append("%s gick ned ensam." % profile.hero_name)
	var fallen: Dictionary = entry.get("fell", {})
	for id in fallen:
		var n := int(fallen[id])
		parts.append("%s föll%s." % [hero_name(profile, data, id), "" if n == 1 else " " + times(n)])
	var rescued: Array = entry.get("rescued", [])
	if not rescued.is_empty():
		parts.append("%s befriades." % " och ".join(rescued.map(func(id: String) -> String: return hero_name(profile, data, id))))
	if int(entry.get("legendary", 0)) > 0:
		parts.append("En legendarisk sten hittades.")
	elif int(entry.get("rare", 0)) > 0:
		parts.append("En sällsynt sten hittades.")
	elif int(entry.get("nether", 0)) > 0:
		parts.append("En Nether Stone hittades.")
	var trophies: Array = entry.get("trophies", [])
	if trophies.size() == 1:
		parts.append("Ny trofé: %s." % String(data.traits.get(trophies[0], {}).get("name", trophies[0])))
	elif trophies.size() > 1:
		parts.append("%s nya troféer." % number(trophies.size()).capitalize())
	var vow: Dictionary = data.get("vows", {}).get(entry.get("vow", ""), {})
	match entry.get("vow_result", ""):
		"kept":
			parts.append("Löftet hölls: %s." % vow.get("name", ""))
		"broken":
			parts.append("Löftet brast: %s." % vow.get("name", ""))
	var map: Array[String] = []
	for m in entry.get("map", []):
		var place := String(data.realms.get(m.realm, {}).get("short", m.realm)).to_lower()
		if m.why == "neglect":
			var boss := LivingMap.twisted_boss(data, m.realm)
			if int(m.to) >= LivingMap.GROWTH_MAX and boss != "":
				map.append("%s vaknade i %s" % [data.enemies[boss].name, place])
			else:
				map.append("fördärvet växte i %s" % place)
		elif m.why in ["fought", "quest"]:
			map.append("%s drog sig tillbaka" % LivingMap.folk(data, m.realm))
	if not map.is_empty():
		var line := "; ".join(map) + "."
		parts.append(line.substr(0, 1).to_upper() + line.substr(1))
	var titles: Array = entry.get("titles", []).map(func(t: String) -> String: return title_name(data, t))
	if titles.size() == 1:
		parts.append("Ny titel: %s." % titles[0])
	elif titles.size() > 1:
		parts.append("Nya titlar: %s." % " och ".join(titles))
	if parts.is_empty():
		parts.append({"loss": "Sällskapet bars hem.", "forfeit": "Ni gav upp i striden och tog er hem.",
				"home": "Ni vände hem i tid."}.get(entry.get("outcome", ""), "En lugn nedstigning."))
	return " ".join(parts)


# --- För tester och skärmdumpar --------------------------------------------------

## Spelar upp en nedstigning utan strider (tester och --chronicle-demo): spec = {realm, depth, outcome, party, alone,
## fell {hjälte: gånger}, hurt, rare, legendary, nether, bosses, rescued, trophies, clear (djupet klarat), vow,
## vow_broken, wins, map (kör den levande kartan)}. Returnerar posten.
static func simulate(profile: Profile, data: Dictionary, spec: Dictionary) -> Dictionary:
	var s := RunState.new()
	s.realm = String(spec.get("realm", "crypt"))
	s.depth = int(spec.get("depth", 1))
	s.party.assign(spec.get("party", profile.party))
	profile.descents[s.realm] = int(profile.descents.get(s.realm, 0)) + 1
	profile.growth_news = {}
	s.chron = begin(profile, s.party)
	s.chron.alone = bool(spec.get("alone", s.party.size() == 1))
	s.chron.fell = (spec.get("fell", {}) as Dictionary).duplicate()
	s.chron.hurt = Array(spec.get("hurt", []))
	for k in ["rare", "legendary", "nether"]:
		s.chron[k] = int(spec.get(k, 0))
	var outcome := String(spec.get("outcome", "boss"))
	for kind in spec.get("bosses", []):
		profile.defeat_boss(kind)
	for id in spec.get("rescued", []):
		profile.recruit(data, id)
	for t in spec.get("trophies", []):
		profile.add_trophy(t)
	if spec.get("clear", false):
		profile.clear_depth(s.depth, s.realm)
	s.vow = String(spec.get("vow", ""))
	s.vow_broken = bool(spec.get("vow_broken", false))
	s.wins = int(spec.get("wins", 3))
	s.realm_quest_done = bool(spec.get("quest", false))
	var changes: Array = []
	if spec.get("map", false):
		changes = LivingMap.after_descent(profile, data, s.realm, s.wins, s.realm_quest_done)
	return end(profile, data, s, outcome, changes)


## --chronicle-demo: en påhittad krönika med tolv nedstigningar och några titlar (sparas inte).
static func demo(profile: Profile, data: Dictionary) -> void:
	profile.intro_done = true
	profile.recruited.assign([])
	profile.descents = {}
	var p1 := ["paladin"]
	var p2 := ["paladin", "imma"]
	var p3 := ["paladin", "imma", "alva"]
	var p4 := ["paladin", "imma", "alva", "brokk"]
	simulate(profile, data, {"party": p1, "alone": true, "outcome": "boss", "bosses": ["bone_lich"], "clear": true})
	profile.recruit(data, "imma")
	simulate(profile, data, {"party": p2, "depth": 2, "outcome": "boss", "rescued": ["alva"], "trophies": ["bone_finger"],
			"bosses": ["bone_lich"], "clear": true})
	simulate(profile, data, {"party": p3, "depth": 3, "outcome": "loss", "fell": {"imma": 1, "alva": 1}})
	simulate(profile, data, {"party": p3, "depth": 2, "outcome": "boss", "rescued": ["brokk"], "rare": 1, "map": true})
	simulate(profile, data, {"party": p4, "realm": "chapel", "outcome": "loss", "fell": {"brokk": 2}, "map": true})
	simulate(profile, data, {"party": p4, "realm": "chapel", "outcome": "forfeit", "fell": {"brokk": 1, "paladin": 1}})
	simulate(profile, data, {"party": p4, "realm": "chapel", "outcome": "loss", "fell": {"alva": 1}, "map": true})
	simulate(profile, data, {"party": p4, "realm": "chapel", "outcome": "boss", "bosses": ["fallen_bishop"],
			"vow": "vow_no_fall", "trophies": ["rosary"], "clear": true, "quest": true, "map": true})
	simulate(profile, data, {"party": p4, "depth": 3, "outcome": "boss", "bosses": ["bone_lich"], "clear": true, "map": true})
	simulate(profile, data, {"party": p4, "depth": 3, "outcome": "boss", "bosses": ["bone_lich"], "rescued": ["eira"],
			"nether": 1, "map": true})
	simulate(profile, data, {"party": p4, "realm": "chapel", "depth": 2, "outcome": "boss", "bosses": ["fallen_bishop"],
			"fell": {"brokk": 1}, "map": true})
	simulate(profile, data, {"party": p4, "depth": 3, "outcome": "boss", "bosses": ["bone_lich_black"],
			"trophies": ["mold_jaw", "coffin_nail"], "map": true})
	profile.set_party(["imma", "alva", "brokk"])
	choose_title(profile, "bone_trapper")


## --home=<sort>: som efter en hemkomst, för hemkomstrutan på kampanjkartan (sparas inte). fell: Brokk föll igen och
## sällskapet förlorade; boss3: tredje segern mot Benfursten (bosstrofé och ny titel); rare: Ragnhild befriad och en
## sällsynt sten; depth: ett nytt djup och ett hållet löfte.
static func demo_home(profile: Profile, data: Dictionary, kind: String) -> void:
	profile.intro_done = true
	for id in ["imma", "brokk", "alva"]:
		profile.recruit(data, id)
	profile.set_party(["imma", "brokk", "alva"])
	profile.descents["crypt"] = maxi(int(profile.descents.get("crypt", 0)), 2)
	profile.descents["chapel"] = maxi(int(profile.descents.get("chapel", 0)), 1)
	var party := ["paladin", "imma", "brokk", "alva"]
	match kind:
		"fell":
			profile.chron_stats.falls = {"brokk": 2}
			simulate(profile, data, {"party": party, "depth": 2, "outcome": "loss", "fell": {"brokk": 2, "alva": 1}, "map": true})
		"boss3":
			profile.boss_wins["bone_lich"] = 2
			profile.bosses_defeated.append("bone_lich")
			simulate(profile, data, {"party": party, "outcome": "boss", "bosses": ["bone_lich"], "trophies": ["bone_finger"],
					"quest": true, "map": true})
		"rare":
			simulate(profile, data, {"party": party, "realm": "chapel", "outcome": "home", "rescued": ["ragnhild"],
					"rare": 1, "nether": 1, "map": true})
		_:
			profile.best_depth = maxi(profile.best_depth, 1)
			simulate(profile, data, {"party": party, "depth": profile.best_depth + 1, "outcome": "boss",
					"bosses": ["bone_lich"], "clear": true, "vow": "vow_straight", "map": true})
