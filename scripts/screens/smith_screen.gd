extends TapScreen
## Smeden (Siralims Blacksmith, 0.20): en artefakt per hjälte, med nivå 1–10 och platser för material.
##
## ARTEFAKT: nivåstegen visar vad varje nivå öppnar (Stat 2, Trick 3, Stat 5, Trick 7, Stat 9, Nether 10).
## Tryck på en plats för att se förrådets material och jämföra med det som sitter där; tryck två gånger på
## ett material för att sätta i det (det gamla förstörs, en Nether Stone går tillbaka till förrådet).
## SMIDE: typen höjer en stat och avgör när förmågan slår till (svärd vid Anfall, stav vid Förmåga, sköld vid
## Försvara, hjälm vid Provocera, stövlar i början av turen). Nivån och materialen följer med vid byte.

const TYPES := ["sword", "staff", "shield", "helm", "boots"]
const TABS := ["ARTEFAKT", "SMIDE"]
const SOCKET_R := 30.0
## Hur många alternativ panelen visar (bärnsten och trick i tre kolumner, stenar i två).
const MAX_OPTIONS := 6
const MAX_STONES := 4

var hero := "paladin"
var type := "sword"
var ability := ""
var tab := 0
## Vald plats: {kind: "stat"|"trick"|"nether", i} eller {}.
var slot := {}
## Valt alternativ i panelen (första trycket); det andra trycket sätter i det.
var pending := ""
var _flash := 0.0
## Platser som just öppnats eller fyllts: "kind:i" -> tid kvar av skenet.
var _glow := {}
var _message := ""
var _message_t := 0.0


func _ready() -> void:
	super()
	_pick_hero(hero)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--smith-hero="):
			_pick_hero(arg.get_slice("=", 1))
		elif arg.begins_with("--smith-slot="):
			var parts := arg.get_slice("=", 1).split(":")
			slot = {"kind": parts[0], "i": int(parts[1]) if parts.size() > 1 else 0}
		elif arg.begins_with("--smith-pick="):
			pending = arg.get_slice("=", 1)  # för skärmdumpar: ett valt alternativ med jämförelsen


func _process(delta: float) -> void:
	super(delta)
	_flash = maxf(0.0, _flash - delta * 1.5)
	_message_t = maxf(0.0, _message_t - delta)
	for k in _glow.keys():
		_glow[k] = float(_glow[k]) - delta
		if _glow[k] <= 0.0:
			_glow.erase(k)


func _pick_hero(hero_id: String) -> void:
	hero = hero_id
	var art: Dictionary = run.profile.artifact(hero)
	type = art.get("type", "sword")
	ability = art.get("ability", "")
	tab = 0 if not art.is_empty() else 1
	slot = {}
	pending = ""


## Paladinen och de följeslagare man har (0.23).
func _heroes() -> Array:
	return ["paladin"] + run.profile.recruited


## Introt (0.23): bara svärdet går att smida, som originalets "You must forge a Sword".
func _type_locked(t: String) -> bool:
	return not run.profile.intro_done and t != "sword"


## Förmågor som kan sättas i en artefakt: alla förmågor hos Paladinen och följeslagarna man har.
func _abilities() -> Array:
	var out: Array = [""]
	for hero_id in _heroes():  # 0.23: förmågorna hos de hjältar man har
		for a in run.data.heroes[hero_id].get("abilities", []):
			if not out.has(a):
				out.append(a)
	return out


func _say(text: String) -> void:
	_message = text
	_message_t = 2.5


# --- Inmatning --------------------------------------------------------------

func _tap(p: Vector2) -> void:
	if back_rect().has_point(p):
		run.go(run.BASE_SCENE)
		return
	var heroes := _heroes()
	for i in heroes.size():
		if _hero_rect(i).has_point(p):
			_pick_hero(heroes[i])
			run.ui_tap()
			return
	var art: Dictionary = run.profile.artifact(hero)
	for i in TABS.size():
		if _tab_rect(i).has_point(p) and (i == 1 or not art.is_empty()):
			tab = i
			run.ui_tap()
			return
	if tab == 1:
		_tap_forge(p)
	elif not art.is_empty():
		_tap_artifact(p, art)


func _tap_forge(p: Vector2) -> void:
	for i in TYPES.size():
		if _type_rect(i).has_point(p):
			if _type_locked(TYPES[i]):
				_say("Smeden: Först ett svärd. Resten kommer sedan.")
				run.ui("ui_error", -10.0)
				return
			type = TYPES[i]
			return
	var abs := _abilities()
	for i in abs.size():
		if _ability_rect(i).has_point(p):
			ability = abs[i]
			return
	if _button_rect().has_point(p) and run.profile.forge(hero, type, ability):
		_flash = 1.0
		run.ui("ui_coins", -8.0)
		run.ui("forge_level", -6.0)
		run.save("ui_forge")
		tab = 0
		run.intro("forged")


func _tap_artifact(p: Vector2, art: Dictionary) -> void:
	var level := int(art.level)
	for s in _sockets():
		if _socket_center(s).distance_to(p) < SOCKET_R + 12:
			if not _open(s, level):
				_say("Öppnas på nivå %d" % _open_level(s))
				run.ui("ui_error", -10.0)
				return
			slot = {} if slot == s else s
			pending = ""
			run.ui_tap()
			return
	if not slot.is_empty():
		if _remove_rect().has_point(p) and _current(art, slot) != "":
			_remove(art)
			return
		var opts := _options(art)
		for i in opts.size():
			if _option_rect(i).has_point(p):
				if pending == opts[i]:
					_insert(opts[i])
				else:
					pending = opts[i]
					run.ui_tap()
				return
	if _button_rect().has_point(p):
		var opened: Variant = run.profile.level_artifact(hero)
		if opened == null:
			run.ui("ui_error", -10.0)
			return
		_flash = 1.0
		run.ui("forge_level", -4.0)
		run.ui("ui_coins", -10.0)
		var lv := int(run.profile.artifact(hero).level)
		if hero == "paladin":
			run.intro("sword_level", lv)
		if opened != "":
			for s in _sockets():
				if _open_level(s) == lv:
					_glow[_key(s)] = 2.0
					slot = s
					pending = ""
			_say("NIVÅ %d – %s ÖPPNAD!" % [lv, String(opened).to_upper()])
			_delayed_sound("slot_open", 0.45)
		else:
			_say("NIVÅ %d – allt i artefakten 10 %% starkare" % lv)
		run._save()


func _delayed_sound(sound: String, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	run.ui(sound, -4.0)


func _insert(option: String) -> void:
	var ok: bool = run.profile.socket_stone(hero, option) if slot.kind == "nether" \
			else run.profile.socket(hero, slot.kind, int(slot.i), option)
	if not ok:
		_say("Det räcker inte – en Stat-plats tar %d bärnsten" % Forge.AMBER_PER_SLOT if slot.kind == "stat" else "Det går inte")
		run.ui("ui_error", -10.0)
		return
	pending = ""
	_glow[_key(slot)] = 1.2
	run.ui("socket", -4.0)
	run._save()


func _remove(art: Dictionary) -> void:
	if slot.kind == "nether":
		run.profile.socket_stone(hero, "")
		_say("Stenen ligger i förrådet igen")
	else:
		var name := ArtifactText.material_name(run.data, _current(art, slot))
		run.profile.socket(hero, slot.kind, int(slot.i), "")
		_say("%s förstördes" % name)
	run.ui("ui_back", -8.0)
	run._save()


# --- Platser -----------------------------------------------------------------

func _sockets() -> Array:
	var out := []
	for i in Forge.STAT_SLOT_LEVELS.size():
		out.append({"kind": "stat", "i": i})
	for i in Forge.TRICK_SLOT_LEVELS.size():
		out.append({"kind": "trick", "i": i})
	out.append({"kind": "nether", "i": 0})
	return out


func _key(s: Dictionary) -> String:
	return "%s:%d" % [s.kind, s.i]


func _open_level(s: Dictionary) -> int:
	match s.kind:
		"stat":
			return Forge.STAT_SLOT_LEVELS[s.i]
		"trick":
			return Forge.TRICK_SLOT_LEVELS[s.i]
	return Forge.NETHER_LEVEL


func _open(s: Dictionary, level: int) -> bool:
	return level >= _open_level(s)


## Det som sitter i platsen (material-id, sten-id eller "").
func _current(art: Dictionary, s: Dictionary) -> String:
	match s.kind:
		"stat":
			return art.stat_slots[s.i]
		"trick":
			return art.trick_slots[s.i]
	return art.nether.get("id", "")


## Förrådets alternativ för vald plats: material-id eller sten-id.
func _options(art: Dictionary) -> Array:
	var profile: Profile = run.profile
	var data: Dictionary = run.data
	if slot.kind == "nether":
		var stones := profile.stones.duplicate()
		stones.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.number) > int(b.number))
		return stones.slice(0, MAX_STONES).map(func(s: Dictionary) -> String: return s.id)
	var pool: Dictionary = data.materials.amber if slot.kind == "stat" else data.materials.tricks
	var out := []
	for id in pool:
		if int(profile.materials.get(id, 0)) > 0 and id != _current(art, slot):
			out.append(id)
	out.sort_custom(func(a: String, b: String) -> bool:
		return int(profile.materials[a]) > int(profile.materials[b]))
	return out.slice(0, MAX_OPTIONS)


func _stone(id: String) -> Dictionary:
	for s in run.profile.stones:
		if s.id == id:
			return s
	return {}


# --- Layout -----------------------------------------------------------------

func _hero_rect(i: int) -> Rect2:
	return Rect2(MARGIN, 104 + i * 98, 280, 88)


func _x0() -> float:
	return MARGIN + 280 + GAP * 2


func _w() -> float:
	return size.x - MARGIN - _x0()


func _tab_rect(i: int) -> Rect2:
	return Rect2(_x0() + i * 172, 96, 160, 40)


func _type_rect(i: int) -> Rect2:
	var w := (_w() - GAP * 4) / 5.0
	return Rect2(_x0() + i * (w + GAP), 174, w, 128)


func _ability_rect(i: int) -> Rect2:
	var w := (_w() - GAP * 3) / 4.0
	return Rect2(_x0() + (i % 4) * (w + GAP), 340 + (i / 4) * 48, w, 40)


func _button_rect() -> Rect2:
	return Rect2(size.x - MARGIN - 420, size.y - 76, 420, 60)


func _pip_center(level: int) -> Vector2:
	var step := (_w() - 40.0) / (Forge.LEVEL_MAX - 1)
	return Vector2(_x0() + 20 + (level - 1) * step, 218)


func _socket_center(s: Dictionary) -> Vector2:
	var idx := _sockets().find(s)
	var step := 104.0
	var gap := 40.0 if idx >= 3 else 0.0
	gap += 40.0 if idx >= 5 else 0.0
	return Vector2(_x0() + 50 + idx * step + gap, 362)


func _option_rect(i: int) -> Rect2:
	if slot.get("kind", "") == "nether":
		var w := (_w() - 436 - GAP) / 2.0
		return Rect2(_x0() + (i % 2) * (w + GAP), 476 + (i / 2) * 92, w, 84)
	var w2 := (_w() - 436 - GAP) / 2.0
	return Rect2(_x0() + (i % 2) * (w2 + GAP), 476 + (i / 2) * 60, w2, 54)


func _remove_rect() -> Rect2:
	return Rect2(_x0() + _w() - 450 - 190, 440, 190, 34)


# --- Ritning ----------------------------------------------------------------

func _draw() -> void:
	var data: Dictionary = run.data
	var profile: Profile = run.profile
	header("SMEDEN", "Höj artefakten för silver – varje nivå stärker allt, och vissa öppnar en ny plats för material.")
	small_button(back_rect(), "‹ BASEN")
	silver_label()

	var heroes := _heroes()
	for i in heroes.size():
		var h: Dictionary = data.heroes[heroes[i]]
		var art: Dictionary = profile.artifact(heroes[i])
		UiStyle.card(self, _hero_rect(i), h.name, ArtifactText.name_of(data, art), hero == heroes[i],
				Color(h.color), h.title.to_upper(), _flash if hero == heroes[i] else 0.0)
	_draw_store(data, profile, Vector2(MARGIN, size.y - 70))

	var art: Dictionary = profile.artifact(hero)
	for i in TABS.size():
		if i == 0 and art.is_empty():
			continue
		chip(_tab_rect(i), TABS[i], tab == i, 18)
	if tab == 1 or art.is_empty():
		_draw_forge(data, profile)
	else:
		_draw_artifact(data, profile, art)
	if _message_t > 0.0:
		UiStyle.text(self, Vector2(_x0(), 160), _message, 22, Color(UiStyle.GOLD, minf(1.0, _message_t)),
				HORIZONTAL_ALIGNMENT_RIGHT, _w(), 5)


func _draw_store(data: Dictionary, profile: Profile, at: Vector2) -> void:
	var amber := 0
	var tricks := 0
	for id in profile.materials:
		if data.materials.amber.has(id):
			amber += int(profile.materials[id])
		else:
			tricks += int(profile.materials[id])
	UiStyle.text(self, at - Vector2(0, 8), "FÖRRÅD", 15, Color(1, 1, 1, 0.55))
	UiStyle.text(self, at + Vector2(0, 18), "%d bärnsten · %d trick\n" % [amber, tricks], 17, Color(1, 1, 1, 0.85),
			HORIZONTAL_ALIGNMENT_LEFT, 290, 3)
	UiStyle.text(self, at + Vector2(0, 40), "%d Nether Stones" % profile.stones.size(), 17, Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_LEFT, 290, 3)


func _draw_artifact(data: Dictionary, profile: Profile, art: Dictionary) -> void:
	var level := int(art.level)
	var k: Dictionary = data.artifacts[art.type]
	var x0 := _x0()
	var w := _w()
	# Namn, nivå och vad artefakten ger nu.
	var title: String = k.name + ("" if art.ability == "" else ": " + data.abilities[art.ability].name)
	UiStyle.text(self, Vector2(x0, 176), title.to_upper(), 24, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, w * 0.6, 5)
	var what := ArtifactText.stat_text(data, art)
	if art.ability != "":
		what += " · " + ArtifactText.chance_text(data, art) + ": kastar " + data.abilities[art.ability].name
	# Nivåstegen.
	for l in range(1, Forge.LEVEL_MAX + 1):
		var c := _pip_center(l)
		if l < Forge.LEVEL_MAX:
			draw_line(c + Vector2(13, 0), _pip_center(l + 1) - Vector2(13, 0),
					Color(UiStyle.GOLD, 0.8 if l < level else 0.2), 3.0)
		var done := l <= level
		var unlock := Forge.unlock_text(l)
		var next := l == level + 1
		var r := 13.0 if unlock != "" else 9.0
		if next:
			draw_circle(c, r + 6.0 + 2.0 * sin(_t * 4.0), Color(UiStyle.GOLD, 0.25))
		draw_circle(c, r, UiStyle.GOLD if done else Color(0.12, 0.11, 0.15))
		draw_arc(c, r, 0, TAU, 24, Color(UiStyle.GOLD, 0.9 if done or next else 0.35), 2.0)
		UiStyle.text(self, c + Vector2(-20, 6), str(l), 15, Color(0, 0, 0) if done else Color(1, 1, 1, 0.6),
				HORIZONTAL_ALIGNMENT_CENTER, 40, 0)
		if unlock != "":
			UiStyle.text(self, c + Vector2(-50, 38), unlock.replace("-plats", "").replace(" ", " "), 16,
					Color(UiStyle.TRAIT_GOLD, 1.0 if done else (0.95 if next else 0.5)), HORIZONTAL_ALIGNMENT_CENTER, 100, 2)
	UiStyle.text(self, Vector2(x0, 290), what, 18, UiStyle.TRAIT_GOLD, HORIZONTAL_ALIGNMENT_LEFT, w, 3)
	# Platserna.
	var labels := {"stat": ["STAT", 0], "trick": ["TRICK", 3], "nether": ["NETHER", 5]}
	for kind in labels:
		var s0: Dictionary = _sockets()[labels[kind][1]]
		UiStyle.text(self, _socket_center(s0) + Vector2(-SOCKET_R, -SOCKET_R - 10), labels[kind][0], 15,
				Color(1, 1, 1, 0.5), HORIZONTAL_ALIGNMENT_LEFT, 200, 0)
	for s in _sockets():
		_draw_socket(data, art, s, level)
	# Panelen för vald plats, annars en förklaring.
	if slot.is_empty():
		var hint := "Tryck på en plats för att se förrådet och jämföra."
		var nxt := Forge.next_unlock(level)
		if nxt > 0:
			hint += "  Nästa plats: %s på nivå %d." % [Forge.unlock_text(nxt), nxt]
		UiStyle.para(self, Vector2(x0, 470), hint, 18, Color(1, 1, 1, 0.65), w - 450)
	else:
		_draw_panel(data, profile, art, level)
	# Höj nivån.
	var cost := profile.artifact_level_cost(hero)
	var label := "HÖGSTA NIVÅN" if cost == 0 else "NIVÅ %d – %d SILVER" % [level + 1, cost]
	UiStyle.big_button(self, _button_rect(), label, _t, cost > 0 and profile.silver >= cost)
	if cost > 0:
		var opens := Forge.unlock_text(level + 1)
		var sub := ("Öppnar %s" % opens) if opens != "" else "Stärker allt med 10 %"
		UiStyle.text(self, _button_rect().position + Vector2(0, -10), sub + ("" if profile.silver >= cost else " · för lite silver"),
				17, Color(UiStyle.GOLD) if opens != "" else Color(1, 1, 1, 0.7), HORIZONTAL_ALIGNMENT_CENTER,
				_button_rect().size.x, 3)


func _draw_socket(data: Dictionary, art: Dictionary, s: Dictionary, level: int) -> void:
	var c := _socket_center(s)
	var open := _open(s, level)
	var selected := slot == s
	var glow := float(_glow.get(_key(s), 0.0))
	if glow > 0.0:
		for i in 4:
			draw_circle(c, SOCKET_R + 8.0 + i * 10.0 * (2.0 - glow), Color(UiStyle.GOLD, 0.12 * glow))
	draw_circle(c, SOCKET_R, Color(0.05, 0.045, 0.07) if open else Color(0.03, 0.03, 0.04))
	draw_arc(c, SOCKET_R, 0, TAU, 32, UiStyle.GOLD if selected else Color(UiStyle.GOLD, 0.6 if open else 0.2),
			3.0 if selected else 1.5)
	var cur := _current(art, s)
	var name := ""
	if not open:
		# Ett litet hänglås.
		draw_rect(Rect2(c + Vector2(-8, -2), Vector2(16, 12)), Color(1, 1, 1, 0.25))
		draw_arc(c + Vector2(0, -2), 6.0, PI, TAU, 12, Color(1, 1, 1, 0.25), 2.5)
		name = "nivå %d" % _open_level(s)
	elif cur == "":
		draw_line(c - Vector2(8, 0), c + Vector2(8, 0), Color(1, 1, 1, 0.5), 2.0)
		draw_line(c - Vector2(0, 8), c + Vector2(0, 8), Color(1, 1, 1, 0.5), 2.0)
		name = "tom"
	elif s.kind == "nether":
		GemArt.draw_find(self, data, {"kind": "nether", "stone": art.nether}, c, 20.0, _t)
		name = "%s (%d)" % [Forge.rarity_of(data, art.nether).name, art.nether.number]
	else:
		var kind := "amber" if s.kind == "stat" else "trick"
		GemArt.draw_find(self, data, {"kind": kind, "id": cur, "count": 1}, c, 18.0, _t)
		name = _short(ArtifactText.material_name(data, cur))
	UiStyle.text(self, c + Vector2(-56, SOCKET_R + 20), name, 15, Color(1, 1, 1, 0.85 if open else 0.45),
			HORIZONTAL_ALIGNMENT_CENTER, 112, 2)


func _draw_panel(data: Dictionary, profile: Profile, art: Dictionary, level: int) -> void:
	var x0 := _x0()
	var kind_name: String = {"stat": "BÄRNSTEN FÖR STAT-PLATS %d", "trick": "TRICK FÖR TRICK-PLATS %d",
			"nether": "NETHER STONE"}[slot.kind]
	if "%d" in kind_name:
		kind_name = kind_name % (int(slot.i) + 1)
	UiStyle.text(self, Vector2(x0, 462), kind_name, 16, Color(1, 1, 1, 0.6))
	var cur := _current(art, slot)
	if cur != "":
		small_button(_remove_rect(), "TA UT" if slot.kind == "nether" else "TA UT (förstörs)")
	var opts := _options(art)
	if opts.is_empty():
		UiStyle.text(self, Vector2(x0, 490), "Inget i förrådet än. %s" % ({"stat": "Bärnsten hittas i alla strider och skattkammare.",
				"trick": "Trick hittas i elitstrider, skattkammare, portaler och hos bossar – bara på det djupaste djupet.",
				"nether": "Nether Stones hittas i skattkammare, portaler och hos bossar – bara på det djupaste djupet."}[slot.kind]),
				18, Color(1, 1, 1, 0.65), HORIZONTAL_ALIGNMENT_LEFT, _w() - 460, 3)
	for i in opts.size():
		var r := _option_rect(i)
		var id: String = opts[i]
		var on := pending == id
		draw_rect(r, Color(0.09, 0.08, 0.12, 0.96) if on else Color(0.06, 0.055, 0.08, 0.85))
		draw_rect(r, UiStyle.TRAIT_GOLD if on else Color(1, 1, 1, 0.15), false, 2.0 if on else 1.0)
		if slot.kind == "nether":
			var st := _stone(id)
			var col := Color(Forge.rarity_of(data, st).color)
			GemArt.draw_find(self, data, {"kind": "nether", "stone": st}, r.position + Vector2(22, 28), 14.0, _t)
			UiStyle.text(self, r.position + Vector2(44, 26), "%s (%d)" % [Forge.rarity_of(data, st).name, st.number], 18,
					col, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 50, 2)
			UiStyle.para(self, r.position + Vector2(44, 48), ", ".join(Forge.stone_lines(data, st)), 15, Color(1, 1, 1, 0.75),
					r.size.x - 52, 2)
		else:
			var kind := "amber" if slot.kind == "stat" else "trick"
			var have := int(profile.materials.get(id, 0))
			var need := Forge.AMBER_PER_SLOT if slot.kind == "stat" else 1
			GemArt.draw_find(self, data, {"kind": kind, "id": id, "count": 1}, r.position + Vector2(20, 27), 12.0, _t)
			UiStyle.text(self, r.position + Vector2(40, 24), _short(ArtifactText.material_name(data, id)), 18,
					Color.WHITE if have >= need else Color(1, 1, 1, 0.45), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 90, 2)
			UiStyle.text(self, r.position + Vector2(0, 24), ("%d/%d" % [have, need]) if have < need else "×%d" % have, 17,
					Color(1, 1, 1, 0.6) if have >= need else Color("#ff8a6a"), HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 10, 2)
			UiStyle.text(self, r.position + Vector2(36, 46), ArtifactText.material_text(data, id, level), 15,
					Color(UiStyle.TRAIT_GOLD, 0.9), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 46, 0)
	_draw_compare(data, art, level, cur)


func _short(name: String) -> String:
	return name.replace(" bärnsten", "").replace("bärnsten", "")


## Hjältens stats med artefakten (för jämförelsen).
func _totals(data: Dictionary, art: Dictionary) -> Dictionary:
	var h: Dictionary = run.profile.hero(data, hero)
	var b := HeroStats.breakdown(data, hero, int(h.level), h.personality, art)
	var out := {}
	for s in HeroStats.STATS:
		out[s] = b[s].total
	return out


## Jämförelsen till höger: det som sitter i platsen mot det valda alternativet.
func _draw_compare(data: Dictionary, art: Dictionary, level: int, cur: String) -> void:
	var x := _x0() + _w() - 430
	var w := 430.0
	var y := 456.0
	draw_rect(Rect2(x - 14, y - 22, w + 14, 200), Color(0, 0, 0, 0.35))
	var now_text := "Tom plats"
	var new_text := ""
	if slot.kind == "nether":
		if cur != "":
			now_text = ", ".join(Forge.stone_lines(data, art.nether))
		if pending != "":
			new_text = ", ".join(Forge.stone_lines(data, _stone(pending)))
	else:
		if cur != "":
			now_text = "%s: %s" % [ArtifactText.material_name(data, cur), ArtifactText.material_text(data, cur, level)]
		if pending != "":
			new_text = "%s: %s" % [ArtifactText.material_name(data, pending), ArtifactText.material_text(data, pending, level)]
	UiStyle.text(self, Vector2(x, y), "NU", 15, Color(1, 1, 1, 0.5))
	y += 6 + UiStyle.para(self, Vector2(x + 40, y), now_text, 16, Color(1, 1, 1, 0.85), w - 40, 2)
	UiStyle.text(self, Vector2(x, y + 4), "VALT", 15, Color(1, 1, 1, 0.5))
	if new_text == "":
		UiStyle.text(self, Vector2(x + 52, y + 4), "Tryck på ett alternativ", 16, Color(1, 1, 1, 0.55))
		return
	y += 10 + UiStyle.para(self, Vector2(x + 52, y + 4), new_text, 16, UiStyle.TRAIT_GOLD, w - 52, 3)
	# Vad bytet gör med hjältens stats, i siffror.
	var after := art.duplicate(true)
	match slot.kind:
		"stat":
			after.stat_slots[slot.i] = pending
		"trick":
			after.trick_slots[slot.i] = pending
		"nether":
			after.nether = _stone(pending)
	var before_t := _totals(data, art)
	var after_t := _totals(data, after)
	var changes: Array[String] = []
	for s in HeroStats.STATS:
		var d: float = after_t[s] - before_t[s]
		if absf(d) >= 0.05:
			changes.append("%s %s → %s" % [HeroStats.STAT_NAMES[s], HeroStats.shown(before_t[s]), HeroStats.shown(after_t[s])])
	if not changes.is_empty():
		y += 4 + UiStyle.para(self, Vector2(x, y + 4), ", ".join(changes), 16, Color("#8fd18f"), w, 2)
	var warn := "Tryck igen för att sätta i"
	if cur != "" and slot.kind != "nether":
		warn += " – %s förstörs" % ArtifactText.material_name(data, cur)
	elif cur != "":
		warn += " – den gamla stenen går till förrådet"
	UiStyle.para(self, Vector2(x, y + 6), warn, 16, Color("#ffb070"), w, 2)


func _draw_forge(data: Dictionary, profile: Profile) -> void:
	var x0 := _x0()
	UiStyle.text(self, Vector2(x0, 164), "TYP", 16, Color(1, 1, 1, 0.6))
	for i in TYPES.size():
		var k: Dictionary = data.artifacts[TYPES[i]]
		var r := _type_rect(i)
		UiStyle.card(self, r, k.name, "%s\n%s" % [k.stat_text, k.trigger_text], type == TYPES[i], Color("#b9c4d6"))
		Glyphs.draw(self, k.icon, r.end - Vector2(20, 20), 9.0, Color("#b9c4d6", 0.8))
		if _type_locked(TYPES[i]):
			draw_rect(r, Color(0.02, 0.02, 0.03, 0.72))
	UiStyle.text(self, Vector2(x0, 330), "FÖRMÅGA I ARTEFAKTEN", 16, Color(1, 1, 1, 0.6))
	var abs := _abilities()
	for i in abs.size():
		var label: String = "Ingen" if abs[i] == "" else data.abilities[abs[i]].name
		chip(_ability_rect(i), label, ability == abs[i], 17)
	var k: Dictionary = data.artifacts[type]
	var y := _ability_rect(abs.size() - 1).end.y + 34
	var what := "%s – %s." % [k.name, k.stat_text]
	if ability != "":
		var ab: Dictionary = data.abilities[ability]
		what = "%s – %s. %s: kastar %s. %s" % [k.name, k.stat_text, k.trigger_text, ab.name, ab.get("text", "")]
	var hh := UiStyle.para(self, Vector2(x0, y), what, 18, UiStyle.TRAIT_GOLD, _w(), 3)
	UiStyle.para(self, Vector2(x0, y + hh + 6), "Förmågan använder bärarens Attack och Intelligence. Nivån och materialen följer med när typen byts.",
			16, Color(1, 1, 1, 0.6), _w() - 440, 3)
	var cost := profile.forge_cost(hero, type, ability)
	var label := "SMIDD" if cost == 0 else ("%s – %d SILVER" % ["BYT FÖRMÅGA" if cost == Profile.RESOCKET_COST else "SMID", cost])
	UiStyle.big_button(self, _button_rect(), label, _t, cost > 0 and profile.silver >= cost)
	if cost > profile.silver:
		UiStyle.text(self, _button_rect().position + Vector2(0, -10), "För lite silver", 16, Color("#ff8a6a"),
				HORIZONTAL_ALIGNMENT_CENTER, _button_rect().size.x, 3)
