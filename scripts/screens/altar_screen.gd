extends TapScreen
## Kallets altare (Siralims Enchanted Wardrobe): välj Paladinens kall (Siralims Specialization) och köp
## perks för perk-poäng (Siralims Perk Points, Profile.perk_points). Kallet gäller hela sällskapet; kärnan
## verkar alltid och de köpta perkarna i den valda kallet verkar. Perks som är rena siffror har 2–3
## nivåer. En besegrad boss låser upp en lånad perk (Siralims Anointment) från ett annat kall. Att
## återställa är gratis – poängen kommer tillbaka (Profile.reset_perks).

var selected_perk := ""
## Sant när rutnätet visar de andra Kallens perks att låna.
var anoint_mode := false
var _flash := 0.0


func _ready() -> void:
	super()
	HelpBox.offer(self, ["perks"])  # 0.25: hjälprutan första gången
	anoint_mode = OS.get_cmdline_user_args().has("--anoint")


func _process(delta: float) -> void:
	super(delta)
	_flash = maxf(0.0, _flash - delta * 2.0)


func _oaths() -> Array:
	return run.data.oaths.keys()


## Perkarna i rutnätet: Kallets egna, eller de andra Kallens när man väljer vad man lånar.
func _perks() -> Array:
	var profile: Profile = run.profile
	if not anoint_mode:
		return run.data.oaths[profile.oath].perks
	var out := []
	for oath_id in run.data.oaths:
		if oath_id != profile.oath:
			out.append_array(run.data.oaths[oath_id].perks)
	return out


func _tap(p: Vector2) -> void:
	var profile: Profile = run.profile
	var data: Dictionary = run.data
	if back_rect().has_point(p):
		run.go(run.BASE_SCENE)
		return
	var oaths := _oaths()
	for i in oaths.size():
		if _oath_rect(i).has_point(p):
			profile.choose_oath(oaths[i])
			selected_perk = ""
			anoint_mode = false
			run.save("ui_confirm")
			run.intro("oath_chosen")  # 0.23: att välja kall är edsceremonin
			return
	var perks := _perks()
	for i in perks.size():
		if _perk_rect(i).has_point(p):
			selected_perk = perks[i].id
			return
	if _anoint_rect().has_point(p) and profile.anointment_slots() > 0:
		anoint_mode = not anoint_mode
		selected_perk = ""
		return
	if _buy_rect().has_point(p) and selected_perk != "":
		var ok: bool = profile.anoint(data, profile.oath, selected_perk) if anoint_mode \
				else profile.buy_perk(data, profile.oath, selected_perk)
		if ok:
			_flash = 1.0
			run.save("ui_confirm")
		return
	if _reset_rect().has_point(p) and profile.points_used(data, profile.oath) > 0:
		profile.reset_perks(data, profile.oath)
		run.save("ui_back")


# --- Layout -----------------------------------------------------------------

func _oath_rect(i: int) -> Rect2:
	return Rect2(MARGIN, 104 + i * 160, 380, 148)


func _x0() -> float:
	return MARGIN + 380 + GAP * 2


func _perk_rect(i: int) -> Rect2:
	var cols := 3 if anoint_mode else 2
	var h := 84.0 if anoint_mode else 108.0
	var w := (size.x - MARGIN - _x0() - GAP * (cols - 1)) / cols
	return Rect2(_x0() + (i % cols) * (w + GAP), 124 + (i / cols) * (h + 8 if anoint_mode else 120), w, h)


func _anoint_rect() -> Rect2:
	return Rect2(_x0(), 492, size.x - MARGIN - _x0(), 92)


func _buy_rect() -> Rect2:
	return Rect2(size.x - MARGIN - 380, size.y - 76, 380, 60)


func _reset_rect() -> Rect2:
	return Rect2(_x0(), size.y - 70, 300, 50)


# --- Ritning ----------------------------------------------------------------

func _draw() -> void:
	var data: Dictionary = run.data
	var profile: Profile = run.profile
	header("KALLETS ALTARE", "Paladinens kall gäller hela sällskapet. Kärnan verkar alltid; perks kostar perk-poäng och kan återställas gratis.")
	small_button(back_rect(), "‹ BASEN")

	var oaths := _oaths()
	for i in oaths.size():
		var t: Dictionary = data.traits[oaths[i]]
		var on: bool = profile.oath == oaths[i]
		var tag := "%s · %d POÄNG" % [data.oaths[oaths[i]].specialization.to_upper(), profile.points_used(data, oaths[i])]
		UiStyle.card(self, _oath_rect(i), t.name, t.text, on, UiStyle.GOLD, tag)

	var used := profile.points_used(data, profile.oath)
	var points := profile.perk_points()
	var heading := "LÅNA EN PERK FRÅN EN ANNAN ED" if anoint_mode else "PERKS I %s" % data.traits[profile.oath].name.to_upper()
	UiStyle.text(self, Vector2(_x0(), 114), "%s – PERK-POÄNG %d/%d (EN PER NY KLARAD QUEST)" % [heading, used, points],
			14, Color(1, 1, 1, 0.6))
	var perks := _perks()
	var borrowed: String = profile.anointed.get(profile.oath, "")
	for i in perks.size():
		var entry: Dictionary = perks[i]
		var t: Dictionary = data.traits[entry.id]
		var ranks := int(entry.get("ranks", 1))
		var rank := profile.perk_rank(profile.oath, entry.id)
		var owned: bool = (borrowed == entry.id) if anoint_mode else rank > 0
		var tag := "%d POÄNG" % int(entry.cost)
		if anoint_mode:
			tag = "LÅNAD" if owned else tag
		elif owned:
			tag = "NIVÅ %d/%d" % [rank, ranks] if ranks > 1 else "VERKAR"
		elif ranks > 1:
			tag += " · %d NIVÅER" % ranks
		var body: String = t.text + (" Per nivå." if ranks > 1 and not anoint_mode else "")
		var sel: bool = selected_perk == entry.id
		UiStyle.card(self, _perk_rect(i), t.name, body, owned or sel, UiStyle.TRAIT_GOLD if owned else Color("#8a93a6"),
				tag, _flash if sel and owned else 0.0)
		if sel and not owned:
			draw_rect(_perk_rect(i).grow(3), Color(UiStyle.GOLD, 0.8), false, 2.0)

	_draw_anointment(data, profile, borrowed)

	var cost := 0
	var label := "VÄLJ EN PERK"
	var enabled := false
	if selected_perk != "":
		var entry := Profile.perk_entry(data, selected_perk)
		cost = int(entry.cost)
		if anoint_mode:
			var freed := int(Profile.perk_entry(data, borrowed).get("cost", 0)) if borrowed != "" else 0
			enabled = borrowed != selected_perk and used - freed + cost <= points
			label = "LÅNAD" if borrowed == selected_perk else "LÅNA – %d POÄNG" % cost
		else:
			var rank := profile.perk_rank(profile.oath, selected_perk)
			var ranks := int(entry.get("ranks", 1))
			enabled = rank < ranks and used + cost <= points
			if rank >= ranks:
				label = "ALLA NIVÅER" if ranks > 1 else "VERKAR"
			elif rank > 0:
				label = "NIVÅ %d – %d POÄNG" % [rank + 1, cost]
			else:
				label = "VÄLJ – %d POÄNG" % cost
		UiStyle.text(self, Vector2(_x0(), _buy_rect().position.y - 22), "Siralim: %s" % data.traits[selected_perk].get("original", ""),
				14, Color(1, 1, 1, 0.5), HORIZONTAL_ALIGNMENT_LEFT, size.x - _x0() - MARGIN, 3)
		if not enabled and not label in ["LÅNAD", "VERKAR", "ALLA NIVÅER"]:
			UiStyle.text(self, _buy_rect().position + Vector2(0, -10), "För få perk-poäng – återställ eller klara en ny quest", 16,
					Color("#ff8a6a"), HORIZONTAL_ALIGNMENT_CENTER, _buy_rect().size.x, 3)
	UiStyle.big_button(self, _buy_rect(), label, _t, enabled)
	small_button(_reset_rect(), "ÅTERSTÄLL (+%d POÄNG)" % used, used > 0)


## Platsen för den lånade perken (Siralims Anointment): låst tills en boss är besegrad.
func _draw_anointment(data: Dictionary, profile: Profile, borrowed: String) -> void:
	var r := _anoint_rect()
	if profile.anointment_slots() <= 0:
		UiStyle.card(self, r, "Lånad perk", "Låst. Besegra Benfursten för att få låna en perk från ett annat kall.",
				false, Color("#8a93a6"), "ANOINTMENT")
		return
	var body := "Tryck för att välja en perk från ett annat kall. Den kostar poäng ur det här kallets pott."
	var title := "Lånad perk"
	if borrowed != "":
		var t: Dictionary = data.traits[borrowed]
		title = "Lånad: %s" % t.name
		body = "%s (från %s)" % [t.text, data.traits[Profile.perk_entry(data, borrowed).oath].name]
	if anoint_mode:
		body = "Välj en perk ovan och tryck LÅNA. Tryck här för att gå tillbaka till kallets egna perks."
	UiStyle.card(self, r, title, body, anoint_mode or borrowed != "", UiStyle.GOLD, "ANOINTMENT")
