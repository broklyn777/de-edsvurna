extends TapScreen
## Smeden (Siralims Blacksmith): en artefakt per hjälte. Typen höjer en stat och avgör när förmågan
## i den slår till av sig själv (svärd vid Anfall, stav vid Förmåga, sköld vid Försvara, hjälm vid
## Provocera, stövlar i början av turen). Automatiska kast kostar inga Charges.
## Smida eller byta typ kostar Profile.FORGE_COST silver, byta förmåga Profile.RESOCKET_COST.

const TYPES := ["sword", "staff", "shield", "helm", "boots"]

var hero := "paladin"
var type := "sword"
var ability := ""
var _flash := 0.0


func _ready() -> void:
	super()
	_pick_hero(hero)


func _process(delta: float) -> void:
	super(delta)
	_flash = maxf(0.0, _flash - delta * 2.0)


func _pick_hero(hero_id: String) -> void:
	hero = hero_id
	var art: Dictionary = run.profile.artifacts.get(hero, {})
	type = art.get("type", "sword")
	ability = art.get("ability", "")


func _heroes() -> Array:
	return run.data.heroes.keys()


## Förmågor som kan sättas i en artefakt: alla hjältars förmågor.
func _abilities() -> Array:
	var out: Array = [""]
	for hero_id in run.data.heroes:
		for a in run.data.heroes[hero_id].get("abilities", []):
			if not out.has(a):
				out.append(a)
	return out


func _tap(p: Vector2) -> void:
	if back_rect().has_point(p):
		run.go(run.BASE_SCENE)
		return
	var heroes := _heroes()
	for i in heroes.size():
		if _hero_rect(i).has_point(p):
			_pick_hero(heroes[i])
			return
	for i in TYPES.size():
		if _type_rect(i).has_point(p):
			type = TYPES[i]
			return
	var abs := _abilities()
	for i in abs.size():
		if _ability_rect(i).has_point(p):
			ability = abs[i]
			return
	if _forge_rect().has_point(p) and run.profile.forge(hero, type, ability):
		_flash = 1.0
		run.save()


# --- Layout -----------------------------------------------------------------

func _hero_rect(i: int) -> Rect2:
	return Rect2(MARGIN, 104 + i * 98, 300, 88)


func _x0() -> float:
	return MARGIN + 300 + GAP * 2


func _type_rect(i: int) -> Rect2:
	var w := (size.x - MARGIN - _x0() - GAP * 4) / 5.0
	return Rect2(_x0() + i * (w + GAP), 124, w, 128)


func _ability_rect(i: int) -> Rect2:
	var w := (size.x - MARGIN - _x0() - GAP * 3) / 4.0
	return Rect2(_x0() + (i % 4) * (w + GAP), 290 + (i / 4) * 48, w, 40)


func _forge_rect() -> Rect2:
	return Rect2(size.x - MARGIN - 380, size.y - 76, 380, 60)


# --- Ritning ----------------------------------------------------------------

func _draw() -> void:
	var data: Dictionary = run.data
	var profile: Profile = run.profile
	header("SMEDEN", "En artefakt per hjälte. Typen avgör när förmågan i den slår till – utan att kosta Charges.")
	small_button(back_rect(), "‹ BASEN")

	var heroes := _heroes()
	for i in heroes.size():
		var h: Dictionary = data.heroes[heroes[i]]
		var art: Dictionary = profile.artifacts.get(heroes[i], {})
		UiStyle.card(self, _hero_rect(i), h.name, ArtifactText.name_of(data, art), hero == heroes[i],
				Color(h.color), h.title.to_upper(), _flash if hero == heroes[i] else 0.0)

	UiStyle.text(self, Vector2(_x0(), 114), "TYP", 14, Color(1, 1, 1, 0.6))
	for i in TYPES.size():
		var k: Dictionary = data.artifacts[TYPES[i]]
		var r := _type_rect(i)
		UiStyle.card(self, r, k.name, "%s\n%s" % [k.stat_text, k.trigger_text], type == TYPES[i], Color("#b9c4d6"))
		Glyphs.draw(self, k.icon, r.end - Vector2(20, 20), 9.0, Color("#b9c4d6", 0.8))

	UiStyle.text(self, Vector2(_x0(), 280), "FÖRMÅGA I ARTEFAKTEN", 14, Color(1, 1, 1, 0.6))
	var abs := _abilities()
	for i in abs.size():
		var label: String = "Ingen" if abs[i] == "" else data.abilities[abs[i]].name
		chip(_ability_rect(i), label, ability == abs[i], 14)

	var k: Dictionary = data.artifacts[type]
	var y := _ability_rect(abs.size() - 1).end.y + 34
	var what := "%s – %s." % [k.name, k.stat_text]
	if ability != "":
		var ab: Dictionary = data.abilities[ability]
		what = "%s – %s. %s: kastar %s. %s" % [k.name, k.stat_text, k.trigger_text, ab.name, ab.get("text", "")]
	UiStyle.text(self, Vector2(_x0(), y), what, 16, UiStyle.TRAIT_GOLD, HORIZONTAL_ALIGNMENT_LEFT, size.x - MARGIN - _x0(), 3)
	UiStyle.text(self, Vector2(_x0(), y + 24), "Förmågan använder bärarens Attack och Intelligence. Den gamla artefakten smälts ned när typen byts.",
			14, Color(1, 1, 1, 0.55), HORIZONTAL_ALIGNMENT_LEFT, size.x - MARGIN - _x0(), 3)

	var cost := profile.forge_cost(hero, type, ability)
	var label := "SMIDD" if cost == 0 else ("%s – %d SILVER" % ["BYT FÖRMÅGA" if cost == Profile.RESOCKET_COST else "SMID", cost])
	UiStyle.big_button(self, _forge_rect(), label, _t, cost > 0 and profile.silver >= cost)
	if cost > profile.silver:
		UiStyle.text(self, _forge_rect().position + Vector2(0, -10), "För lite silver", 16, Color("#ff8a6a"),
				HORIZONTAL_ALIGNMENT_CENTER, _forge_rect().size.x, 3)
