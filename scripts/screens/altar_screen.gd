extends TapScreen
## Edsaltaret (Siralims Enchanted Wardrobe): välj Paladinens Ed (Siralims Specialization) och köp
## perks för perk-poäng (Siralims Perk Points, Profile.perk_points). Eden gäller hela sällskapet; kärnan
## verkar alltid och de köpta perkarna i den valda Eden verkar. Att återställa är gratis – poängen
## kommer tillbaka (Profile.reset_perks).

var selected_perk := ""
var _flash := 0.0


func _process(delta: float) -> void:
	super(delta)
	_flash = maxf(0.0, _flash - delta * 2.0)


func _oaths() -> Array:
	return run.data.oaths.keys()


func _perks() -> Array:
	return run.data.oaths[run.profile.oath].perks


func _tap(p: Vector2) -> void:
	var profile: Profile = run.profile
	if back_rect().has_point(p):
		run.go(run.BASE_SCENE)
		return
	var oaths := _oaths()
	for i in oaths.size():
		if _oath_rect(i).has_point(p):
			profile.choose_oath(oaths[i])
			selected_perk = ""
			run.save()
			return
	var perks := _perks()
	for i in perks.size():
		if _perk_rect(i).has_point(p):
			selected_perk = perks[i].id
			return
	if _buy_rect().has_point(p) and selected_perk != "":
		if profile.buy_perk(run.data, profile.oath, selected_perk):
			_flash = 1.0
			run.save()
		return
	if _reset_rect().has_point(p) and not profile.owned_perks(profile.oath).is_empty():
		profile.reset_perks(run.data, profile.oath)
		run.save()


# --- Layout -----------------------------------------------------------------

func _oath_rect(i: int) -> Rect2:
	return Rect2(MARGIN, 104 + i * 160, 380, 148)


func _x0() -> float:
	return MARGIN + 380 + GAP * 2


func _perk_rect(i: int) -> Rect2:
	var w := (size.x - MARGIN - _x0() - GAP) / 2.0
	return Rect2(_x0() + (i % 2) * (w + GAP), 124 + (i / 2) * 120, w, 108)


func _buy_rect() -> Rect2:
	return Rect2(size.x - MARGIN - 380, size.y - 76, 380, 60)


func _reset_rect() -> Rect2:
	return Rect2(_x0(), size.y - 70, 300, 50)


# --- Ritning ----------------------------------------------------------------

func _draw() -> void:
	var data: Dictionary = run.data
	var profile: Profile = run.profile
	header("EDSALTARET", "Paladinens Ed gäller hela sällskapet. Kärnan verkar alltid; perks kostar perk-poäng och kan återställas gratis.")
	small_button(back_rect(), "‹ BASEN")

	var oaths := _oaths()
	for i in oaths.size():
		var t: Dictionary = data.traits[oaths[i]]
		var on: bool = profile.oath == oaths[i]
		var owned := profile.owned_perks(oaths[i]).size()
		var tag := "%s · %d/%d PERKS" % [data.oaths[oaths[i]].specialization.to_upper(), owned, data.oaths[oaths[i]].perks.size()]
		UiStyle.card(self, _oath_rect(i), t.name, t.text, on, UiStyle.GOLD, tag)

	var used := profile.points_used(data, profile.oath)
	var points := profile.perk_points()
	UiStyle.text(self, Vector2(_x0(), 114), "PERKS I %s – PERK-POÄNG %d/%d (FLER FÖR VARANNAT KLARAT DJUP)" % [
			data.traits[profile.oath].name.to_upper(), used, points], 14, Color(1, 1, 1, 0.6))
	var perks := _perks()
	var owned_list := profile.owned_perks(profile.oath)
	for i in perks.size():
		var t: Dictionary = data.traits[perks[i].id]
		var owned := owned_list.has(perks[i].id)
		var tag := "VERKAR" if owned else "%d POÄNG" % int(perks[i].cost)
		var sel: bool = selected_perk == perks[i].id
		UiStyle.card(self, _perk_rect(i), t.name, t.text, owned or sel, UiStyle.TRAIT_GOLD if owned else Color("#8a93a6"),
				tag, _flash if sel and owned else 0.0)
		if sel and not owned:
			draw_rect(_perk_rect(i).grow(3), Color(UiStyle.GOLD, 0.8), false, 2.0)

	if selected_perk != "":
		var t: Dictionary = data.traits[selected_perk]
		UiStyle.text(self, Vector2(_x0(), _buy_rect().position.y - 22), "Siralim: %s" % t.get("original", ""), 14,
				Color(1, 1, 1, 0.5), HORIZONTAL_ALIGNMENT_LEFT, size.x - _x0() - MARGIN, 3)
	var cost := Profile.perk_cost(data, profile.oath, selected_perk) if selected_perk != "" else 0
	var owned_sel := owned_list.has(selected_perk)
	var label := "VÄLJ EN PERK"
	if selected_perk != "":
		label = "VERKAR" if owned_sel else "VÄLJ – %d POÄNG" % cost
	var affordable := used + cost <= points
	UiStyle.big_button(self, _buy_rect(), label, _t, selected_perk != "" and not owned_sel and affordable)
	if selected_perk != "" and not owned_sel and not affordable:
		UiStyle.text(self, _buy_rect().position + Vector2(0, -10), "För få perk-poäng – återställ eller klara djupare", 16,
				Color("#ff8a6a"), HORIZONTAL_ALIGNMENT_CENTER, _buy_rect().size.x, 3)
	small_button(_reset_rect(), "ÅTERSTÄLL (+%d POÄNG)" % used, used > 0)
