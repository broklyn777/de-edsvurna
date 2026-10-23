class_name LivingMap
extends RefCounted
## Den levande kartan (prov, docs/plan/levande-karta.md). Ren logik utan noder.
##
## **Avvikelse från Siralim:** Siralim har ingen värld som förändras mellan körningarna. Varje Realm som man har gått
## ned i har ett fördärv, `growth` 0–4 (Profile.growth, start GROWTH_START). Efter varje nedstigning med minst en
## vunnen strid (aldrig i verklig tid) sjunker den Realm man gick till (2 steg om dess Realm Quest klarades, annars 1)
## och en annan upplåst Realm växer ett steg. En Realm som når 0 vilar nästa nedstigning (växer inte). En Realm på 4
## står still tills man går dit; där har en förvriden boss vaknat (realms.json "growth": "twisted").
##
## Vårt val (mätt med botarna, docs/plan/levande-karta.md "Resultat"):
## - "Upplåst" = man har gått ned där minst en gång (Profile.descents). En Realm man aldrig har sett växer inte.
## - Med tre Realms växer bara den som har legat orörd längst (Profile.growth_last). Planens regel (alla andra växer)
##   drev med tre Realms upp den Realm man förlorade i: karriärbotarna hade kryptan på 3–4 efter tolv nedstigningar och
##   mötte den förvridna bossen 2,4 gånger per profil fast de växlade Realm varje gång. Med två Realms är det samma regel.
## - Steg 0 och 1 är dagens strider (inget blir lättare än balansen); styrkan och bytet kommer från steg 2.

const GROWTH_MAX := 4
const GROWTH_START := 1
## Fiendernas stats per steg över STRENGTH_FROM (steg 4: ×1,06). Botarna: +6 % per steg fällde kryptans körningar från
## 35 % till 12/5/0 % (steg 2/3/4); +2 % ger 28/21 % (BALANS=levande, docs/plan/levande-karta.md).
const STAT_PER_STEP := 0.02
## Samma värde, men botarna kan pröva andra (BALANS=levande LEVANDE_STAT=0.02).
static var stat_per_step := STAT_PER_STEP
## Troféchans och fynd per steg över STRENGTH_FROM.
const TROPHY_PER_STEP := 0.05
const AMBER_CHANCE_PER_STEP := 0.10
const RARE_FIND_PER_STEP := 0.25
## Steg som är dagens strider (0 och 1).
const STRENGTH_FROM := 1
## Steget där varningen ges före avfärd, och där den förvridna bossen vaknar.
const WARN_AT := 3


## Realms som kan växa: de man har gått ned i minst en gång.
static func unlocked(profile: Profile, data: Dictionary) -> Array:
	var out := []
	for realm_id in data.realms:
		if int(profile.descents.get(realm_id, 0)) > 0:
			out.append(realm_id)
	return out


static func growth(profile: Profile, realm_id: String) -> int:
	return clampi(int(profile.growth.get(realm_id, GROWTH_START)), 0, GROWTH_MAX)


## Stegen över dagens strider (0 för steg 0 och 1).
static func extra_steps(g: int) -> int:
	return maxi(g - STRENGTH_FROM, 0)


## Fiendernas skalning på steget (1,0 för steg 0–1). Steg 4 är lika starkt som steg 3 (vårt val): där är det den
## förvridna bossen som är hotet, och med båda tappade botarna nästan alla körningar.
static func stat_mult(g: int) -> float:
	return 1.0 + stat_per_step * extra_steps(mini(g, WARN_AT))


static func trophy_bonus(g: int) -> float:
	return TROPHY_PER_STEP * extra_steps(g)


## Den förvridna bossens möte i Realmen ("" om Realmen saknar en).
static func twisted_encounter(data: Dictionary, realm_id: String) -> String:
	return String(data.realms.get(realm_id, {}).get("growth", {}).get("twisted", ""))


## Den förvridna bossen (fiendens id) i Realmen, eller "".
static func twisted_boss(data: Dictionary, realm_id: String) -> String:
	var enc := twisted_encounter(data, realm_id)
	if enc == "" or not data.encounters.has(enc):
		return ""
	for kind in data.encounters[enc].enemies:
		if data.enemies[kind].get("boss", false):
			return kind
	return ""


## Har den förvridna bossen vaknat i Realmen?
static func awake(profile: Profile, data: Dictionary, realm_id: String) -> bool:
	return growth(profile, realm_id) >= GROWTH_MAX and twisted_boss(data, realm_id) != ""


## Folket i Realmen, för texten ("Benfolket").
static func folk(data: Dictionary, realm_id: String) -> String:
	return String(data.realms.get(realm_id, {}).get("growth", {}).get("folk", data.realms.get(realm_id, {}).get("short", realm_id)))


## Vad som ändras efter en nedstigning i realm_id (utan att ändra profilen): [{realm, from, to, why}].
## why: "fought" (man gick dit), "quest" (och klarade questen), "neglect" (växer), "rest" (vilar på 0).
static func changes(profile: Profile, data: Dictionary, realm_id: String, quest_done: bool) -> Array:
	var out := []
	var g := growth(profile, realm_id)
	var to := maxi(g - (2 if quest_done else 1), 0)
	if to != g:
		out.append({"realm": realm_id, "from": g, "to": to, "why": "quest" if quest_done else "fought"})
	var open := unlocked(profile, data)
	if not open.has(realm_id):
		open.append(realm_id)
	# Den som har legat orörd längst växer (inte den som vilar eller redan står på 4).
	var oldest := ""
	for other in open:
		if other == realm_id:
			continue
		var og := growth(profile, other)
		if og >= GROWTH_MAX:
			continue  # står still tills man går dit
		if profile.growth_rest.has(other):
			out.append({"realm": other, "from": og, "to": og, "why": "rest"})
			continue
		if oldest == "" or int(profile.growth_last.get(other, -1)) < int(profile.growth_last.get(oldest, -1)):
			oldest = other
	if oldest != "":
		var og := growth(profile, oldest)
		out.append({"realm": oldest, "from": og, "to": og + 1, "why": "neglect"})
	return out


## Efter en nedstigning: ändrar profilens fördärv och sparar vad som hände (Profile.growth_news, visas på kampanjkartan).
## Inget händer utan en vunnen strid. Returnerar ändringarna.
static func after_descent(profile: Profile, data: Dictionary, realm_id: String, wins: int, quest_done: bool) -> Array:
	if wins <= 0 or not data.realms.has(realm_id):
		return []
	var list := changes(profile, data, realm_id, quest_done)
	var rest := {}
	for c in list:
		profile.growth[c.realm] = int(c.to)
		if int(c.to) == 0 and c.why != "rest":
			rest[c.realm] = true
	profile.growth_rest = rest
	profile.growth_last[realm_id] = profile.total_descents()
	if not profile.growth.has(realm_id):
		profile.growth[realm_id] = growth(profile, realm_id)
	profile.growth_news = news(profile, data, realm_id, list)
	return list


## Raden före avfärd för vald Realm, utan siffror.
static func departure_line(profile: Profile, data: Dictionary, realm_id: String) -> String:
	var here := String(data.realms[realm_id].short)
	var parts: Array[String] = []
	if awake(profile, data, realm_id):
		parts.append("%s har vaknat här." % data.enemies[twisted_boss(data, realm_id)].name)
	elif growth(profile, realm_id) >= 2:
		parts.append("Går ni hit trängs %s tillbaka." % folk(data, realm_id))
	else:
		parts.append("Det är lugnt i %s." % _in(here))
	var grows: Array[String] = []
	var warn := ""
	for c in changes(profile, data, realm_id, false):
		if c.why == "neglect":
			grows.append(_in(String(data.realms[c.realm].short)))
			if int(c.to) >= GROWTH_MAX and twisted_boss(data, c.realm) != "":
				warn = " Nästa gång kan något vakna i %s." % _in(String(data.realms[c.realm].short))
	if not grows.is_empty():
		parts.append("Under tiden växer fördärvet i %s.%s" % [" och ".join(grows), warn])
	return " ".join(parts)


## "kryptan", "kapellet", "lunden" (för "i …").
static func _in(short: String) -> String:
	return short.to_lower()


## Texten efter hemkomsten: vad som ändrades och varför, och högst en replik (Imma eller Gorm) för den viktigaste ändringen.
## {lines: [text], speaker, line_id, text}
static func news(profile: Profile, data: Dictionary, realm_id: String, list: Array) -> Dictionary:
	var lines: Array = []
	var top := {}
	var top_rank := -1
	for c in list:
		var name := String(data.realms[c.realm].short)
		var f := folk(data, c.realm)
		var rank := 0
		var key := ""
		match c.why:
			"quest", "fought":
				if int(c.from) >= GROWTH_MAX and twisted_boss(data, c.realm) != "":
					lines.append("Ni gick till %s. Det som vaknade där har fått ett slag, och %s drar sig undan." % [_in(name), f])
					key = "calm_twisted"
					rank = 3
				elif c.why == "quest":
					lines.append("Ni klarade questen i %s. %s drar sig långt tillbaka." % [_in(name), f])
					key = "calm"
					rank = 1
				else:
					lines.append("Ni slogs i %s. %s drar sig lite tillbaka." % [_in(name), f])
					key = "calm"
					rank = 1
				if int(c.to) == 0:
					lines[-1] += " Där är det nu stilla en tid."
			"neglect":
				if int(c.to) >= GROWTH_MAX and twisted_boss(data, c.realm) != "":
					lines.append("Ingen gick till %s. Där nere har %s vaknat." % [_in(name), data.enemies[twisted_boss(data, c.realm)].name])
					key = "wake"
					rank = 4
				elif int(c.to) == WARN_AT and twisted_boss(data, c.realm) != "":
					lines.append("Ingen gick till %s. %s blir djärvare; nästa gång kan något vakna där nere." % [_in(name), f])
					key = "warn"
					rank = 2
				else:
					lines.append("Ingen gick till %s, och %s andas ut. Fördärvet växer där." % [_in(name), f])
					key = "rise"
					rank = 0 if int(c.to) < 2 else 1
			"rest":
				lines.append("I %s är det fortfarande stilla." % _in(name))
		if key != "" and rank > top_rank:
			top_rank = rank
			top = {"key": key, "realm": c.realm}
	var out := {"lines": lines, "realm": realm_id}
	if not top.is_empty():
		var said := _line(profile, data, String(top.key), String(top.realm))
		out.merge(said)
	return out


## En replik ur dialog.json "living_map" (Imma om hon är med i profilen, annars Gorm): {speaker, line_id, text}.
static func _line(profile: Profile, data: Dictionary, key: String, realm_id: String) -> Dictionary:
	var d: Dictionary = data.get("dialog", {}).get("living_map", {})
	for speaker in (["imma", "gorm"] if profile.recruited.has("imma") else ["gorm"]):
		var pool: Array = d.get(speaker, {}).get(key, [])
		pool = pool.filter(func(e: Variant) -> bool:
				return not (e is Dictionary) or String(e.get("realm", realm_id)) == realm_id)
		if pool.is_empty():
			continue
		var e: Variant = pool[(profile.total_descents() + key.length()) % pool.size()]
		var text := Dialog.line_text(e).replace("{plats}", _in(String(data.realms[realm_id].short))) \
				.replace("{folk}", folk(data, realm_id))
		text = Dialog.fill(text.substr(0, 1).to_upper() + text.substr(1), profile.hero_name)
		return {"speaker": speaker, "line_id": String(e.get("id", "")) if e is Dictionary else "", "text": text}
	return {}
