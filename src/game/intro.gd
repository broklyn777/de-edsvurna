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


## Stationen där personen som ger aktuellt uppdrag står ("yard" för Imma på gården).
static func giver_station(data: Dictionary, profile: Profile) -> String:
	var step := current(data, profile)
	var giver: String = step.get("giver", "")
	if giver == "":
		return ""
	return Dialog.person(data, giver).get("station", step.get("station", "yard"))


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
		return "Prata med %s %s." % [Dialog.display_name(data, giver), Dialog.person(data, giver).get("where", "")]
	return step.get("quest", "")


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
	# Det som redan har gjorts i kedjan går att besöka igen (porten bara efter Gorms ord om klockorna).
	for i in profile.intro_step:
		var done: Dictionary = steps(data)[i]
		if done.station == station:
			return "open"
	if station == "gate" and profile.intro_step > _index(data, "bells"):
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
