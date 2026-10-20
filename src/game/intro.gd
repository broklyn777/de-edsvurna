class_name Intro
extends RefCounted
## Introduktionen för en ny profil (0.23, docs/plan/0.23-vardshuset.md §4): småuppdrag i borgen, sedan Imma och
## kryptan. Kedjan ligger i data/intro.json så att den kan ändras utan kod. Profile.intro_step pekar på aktuellt
## steg; steget är klart när dess händelse ("event") inträffar. Befintliga profiler har intro_done = true.
## Stationerna: gate (porten/kampanjkartan), practice, altar, smith, macros, library, inn och base (borgen själv).


static func steps(data: Dictionary) -> Array:
	return data.get("intro", {}).get("steps", [])


static func current(data: Dictionary, profile: Profile) -> Dictionary:
	if profile.intro_done:
		return {}
	var s := steps(data)
	return s[profile.intro_step] if profile.intro_step < s.size() else {}


## 0.24: ett steg med "giver" börjar med ett samtal. Tills man har pratat med personen är det hennes station som
## gäller; sedan stationen där uppdraget görs. Steg vars händelse är "talked" är bara samtalet.
static func needs_talk(data: Dictionary, profile: Profile) -> bool:
	var step := current(data, profile)
	return step.has("giver") and (not profile.intro_talked or step.get("event", "") == "talked")


## 0.25: ett steg med "auto" spelar sitt samtal direkt i borgen (natten när arbetarna kommer, hemkomsten).
static func auto_talk(data: Dictionary, profile: Profile) -> bool:
	return current(data, profile).get("auto", false) and needs_talk(data, profile)


## 0.25: samtalets rader som {who, text}. En rad är en text (den som ger uppdraget säger den) eller [talare, text];
## talaren "narrator" är berättarens ruta på svart (Siralims kursiva rader).
static func lines(step: Dictionary, key := "talk") -> Array:
	return speech(step.get(key, []), step.get("giver", ""))


static func speech(raw: Array, default_who := "") -> Array:
	var out := []
	for l in raw:
		if l is Dictionary:
			out.append({"who": String(l.get("who", default_who)), "text": String(l.text)})
		elif l is Array:
			out.append({"who": String(l[0]), "text": String(l[1])})
		else:
			out.append({"who": default_who, "text": String(l)})
	return out


## 0.25: introts scen på gården (arbetarna från kryptan) gäller under stegen med "scene".
static func scene(data: Dictionary, profile: Profile) -> bool:
	return current(data, profile).get("scene", false)


## Stationen där personen som ger aktuellt uppdrag står ("yard" för Imma på gården).
static func giver_station(data: Dictionary, profile: Profile) -> String:
	var step := current(data, profile)
	var giver: String = step.get("giver", "")
	if giver == "":
		return ""
	return person_station(data, profile, giver, step.get("station", "yard"))


## 0.24.3: var en person står just nu. Ett introsteg kan flytta någon ("where", t.ex. Gorm vid altaret under eden);
## annars står personen på sin vanliga plats (Gorm i sin kammare).
static func person_station(data: Dictionary, profile: Profile, who: String, fallback := "") -> String:
	if not profile.intro_done:
		var where: Dictionary = current(data, profile).get("where", {})
		if where.has(who):
			return where[who]
	return Dialog.person(data, who).get("station", fallback)


## Vem som står vid stationen just nu ("" om ingen).
static func who_at(data: Dictionary, profile: Profile, station: String) -> String:
	for who in data.get("dialog", {}).get("people", {}):
		if person_station(data, profile, who) == station:
			return who
	return ""


## Vad personen vid stationen säger under steget ("at"). I svärdssteget säger "at_short" hur mycket silver som
## fattas när det inte räcker till nästa nivå (0.26.1). null om personen inte har någon replik för steget.
static func at_lines(data: Dictionary, profile: Profile, who: String) -> Variant:
	var step := current(data, profile)
	# 0.26.2: ingen "nästa nivå"-replik när svärdet redan har nått stegets nivå.
	if step.get("event", "") == "sword_level" \
			and int(profile.artifact("paladin").get("level", 0)) >= int(step.get("level", 3)):
		return null
	if step.get("event", "") == "sword_level" and silver_short(profile) > 0 and step.get("at_short", {}).has(who):
		return step.at_short[who]
	return step.get("at", {}).get(who, null)


## Hur mycket silver som fattas till svärdets nästa nivå (0 om det räcker).
static func silver_short(profile: Profile) -> int:
	var lv := int(profile.artifact("paladin").get("level", 0))
	return maxi(Forge.level_cost(lv) - profile.silver, 0)


## Personen har pratat klart. Ett samtalssteg ("talked") avslutas av händelsen (Run.intro); annars får man uppdraget.
static func talked(data: Dictionary, profile: Profile) -> void:
	var step := current(data, profile)
	if step.get("event", "") != "talked":
		profile.intro_talked = true


## Texten i uppdragshörnet: vem man ska prata med, eller uppdraget.
static func quest_text(data: Dictionary, profile: Profile) -> String:
	var step := current(data, profile)
	if step.is_empty():
		return ""
	if needs_talk(data, profile) and step.get("event", "") != "talked":
		var giver: String = step.giver
		return "Prata med %s %s." % [Dialog.display_name(data, giver), _where(data, profile, giver)]
	var q: String = step.get("quest", "")
	if step.get("event", "") == "sword_level":
		# 0.24.3: hur långt svärdet har kommit, och vad nästa nivå kostar.
		var lv := int(profile.artifact("paladin").get("level", 0))
		# 0.26.1: räcker inte silvret står det hur mycket som fattas (Hedda säger att kryptan har mer), kort nog för 1280.
		if silver_short(profile) > 0:
			q += " Nivå %d av %d – det fattas %d silver." % [lv, int(step.get("level", 3)), silver_short(profile)]
		else:
			q += " Nu nivå %d av %d – nästa nivå %d silver." % [lv, int(step.get("level", 3)), Forge.level_cost(lv)]
	return q


## Var personen står, i ord ("i sin kammare", "vid altaret").
static func _where(data: Dictionary, profile: Profile, who: String) -> String:
	var at := person_station(data, profile, who)
	if at != Dialog.person(data, who).get("station", at):
		return {"altar": "vid altaret i kapellet"}.get(at, "i " + String(Dialog.station(data, at).get("name", at)).to_lower())
	return Dialog.person(data, who).get("where", "")


## En station är "current" (uppdraget gäller den), "open" eller låst (en replik i stället). Under introt är bara den
## aktuella stationen öppen, och de stationer som redan har använts i kedjan. Efter introt öppnas Värdshuset när man
## har räddat någon (vårt val: Siralims byggnader låses upp efter hand).
static func station_state(data: Dictionary, profile: Profile, station: String) -> String:
	if profile.intro_done:
		if station == "inn" and profile.recruited.size() < 2:
			return "locked"
		return "open"
	var step := current(data, profile)
	var target: String = giver_station(data, profile) if needs_talk(data, profile) else step.get("station", "")
	if target == station:
		return "current"
	# Det som redan har gjorts i kedjan går att besöka igen (porten bara efter arbetarnas berättelse).
	for i in profile.intro_step:
		var done: Dictionary = steps(data)[i]
		if done.station == station:
			return "open"
	if station == "gate" and profile.intro_step > _index(data, "workers"):
		return "open"
	return "locked"


static func _index(data: Dictionary, id: String) -> int:
	var s := steps(data)
	for i in s.size():
		if s[i].id == id:
			return i
	return 999


## En händelse i spelet. Om den avslutar aktuellt steg går kedjan vidare. Returnerar steget som blev klart, eller {}.
static func notify(data: Dictionary, profile: Profile, event: String, value := 0) -> Dictionary:
	var step := current(data, profile)
	if step.is_empty() or step.get("event", "") != event:
		return {}
	if step.has("giver") and event != "talked" and not profile.intro_talked:
		return {}  # 0.24: uppdraget har inte getts än
	if event == "sword_level" and value < int(step.get("level", 3)):
		return {}
	profile.silver += int(step.get("silver", 0))
	if step.has("recruit"):
		profile.recruit(data, step.recruit, 1.0)
		profile.set_party([step.recruit])
	profile.intro_step += 1
	profile.intro_talked = false
	if profile.intro_step >= steps(data).size():
		profile.intro_done = true
	return step
