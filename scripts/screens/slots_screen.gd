extends TapScreen
## Sparplatserna (0.23.1, som Siralims flera sparfiler): visas när appen startar. Tre platser med kall, högsta
## hjältenivå, silver, djupaste djup och om en körning pågår. En tom plats börjar introduktionen. Senast använda
## plats är markerad; ett tryck fortsätter spelet som förut. Att radera kräver en tydlig bekräftelse och är aldrig
## förvalt.

const BACKDROP := preload("res://assets/illustrations/basen.webp")

## Platsen som ska raderas (bekräftelsen visas), 0 = ingen.
var confirm_delete := 0
var _summaries := {}


func _ready() -> void:
	super()
	_refresh()
	# Utvecklarflagga för skärmdumpar: --confirm-delete=N visar bekräftelsen.
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--confirm-delete="):
			confirm_delete = int(a.get_slice("=", 1))
		elif a.begins_with("--ask-name="):
			_ask_name(int(a.get_slice("=", 1)))  # utvecklarflagga för skärmdumpar


func _refresh() -> void:
	for i in range(1, SaveSlots.COUNT + 1):
		_summaries[i] = SaveSlots.summary(i, run.data)


func _card_rect(i: int) -> Rect2:
	var w := (size.x - MARGIN * 2 - GAP * 2) / 3.0
	return Rect2(MARGIN + (i - 1) * (w + GAP), 150, w, 380)


func _delete_rect(i: int) -> Rect2:
	var r := _card_rect(i)
	return Rect2(r.position.x + (r.size.x - 160) / 2.0, r.end.y + 18, 160, 44)


func _yes_rect() -> Rect2:
	return Rect2(size.x / 2 + 20, size.y / 2 + 50, 240, 60)


func _no_rect() -> Rect2:
	return Rect2(size.x / 2 - 260, size.y / 2 + 50, 240, 60)


func _ask_name(i: int) -> void:
	var entry := NameEntry.new()
	entry.chosen.connect(func(n: String) -> void: run.choose_slot(i, n))
	add_child(entry)
	run.ui("ui_page", -10.0)


func _tap(p: Vector2) -> void:
	if confirm_delete > 0:
		if _yes_rect().has_point(p):
			SaveSlots.delete(confirm_delete)
			run.ui("ui_back", -8.0)
			confirm_delete = 0
			_refresh()
		elif _no_rect().has_point(p) or not Rect2(size.x / 2 - 320, size.y / 2 - 120, 640, 260).has_point(p):
			confirm_delete = 0
		return
	for i in range(1, SaveSlots.COUNT + 1):
		if not _summaries[i].empty and _delete_rect(i).has_point(p):
			confirm_delete = i
			run.ui("ui_error", -10.0)
			return
		if _card_rect(i).has_point(p):
			if _summaries[i].empty:
				_ask_name(i)  # 0.24.2: en ny profil börjar med paladinens namn
			else:
				run.choose_slot(i)
			return


func _draw() -> void:
	header("DE EDSVURNA", "Välj profil. Varje profil har sin egen borg, sina hjältar och sina makron.", BACKDROP)
	var last := SaveSlots.last()
	for i in range(1, SaveSlots.COUNT + 1):
		var s: Dictionary = _summaries[i]
		var r := _card_rect(i)
		var is_last: bool = i == last and not s.empty
		draw_rect(r, Color(0.06, 0.05, 0.08, 0.92))
		draw_rect(r, Color(UiStyle.GOLD, 0.95) if is_last else Color(UiStyle.GOLD, 0.35), false, 3.0 if is_last else 1.5)
		UiStyle.text(self, r.position + Vector2(0, 48), "PROFIL %d" % i, 28, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 5)
		# 0.27.2: huvudhandlingen som en tydlig knapp längst ned i kortet (hela kortet går fortfarande att trycka på).
		var act := Rect2(r.position.x + 28, r.end.y - 62, r.size.x - 56, 46)
		draw_rect(act, Color(0.35, 0.25, 0.05, 0.92) if is_last or s.empty else Color(0, 0, 0, 0.6))
		draw_rect(act, Color(UiStyle.GOLD, 0.9), false, 2.0)
		UiStyle.text(self, act.position + Vector2(0, 31), "SKAPA PROFIL" if s.empty else "FORTSÄTT", 20, Color.WHITE,
				HORIZONTAL_ALIGNMENT_CENTER, act.size.x, 4)
		if s.empty:
			UiStyle.text(self, r.position + Vector2(0, 190), "Ny profil", 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 4)
			UiStyle.para(self, r.position + Vector2(28, 230), "Börjar från början: eden, borgen och kryptan under den.", 18,
					Color(1, 1, 1, 0.7), r.size.x - 56, 3)
			continue
		var rows := [
			["Namn", String(s.name)],
			["Kall", String(s.oath)],
			["Högsta hjältenivå", str(s.level)],
			["Hjältar", str(s.heroes)],
			["Silver", str(s.silver)],
			["Djupaste djup", "inget än" if int(s.depth) == 0 else str(s.depth)],
		]
		for j in rows.size():
			var y := r.position.y + 126 + j * 36
			UiStyle.text(self, Vector2(r.position.x + 28, y), rows[j][0], 18, Color(1, 1, 1, 0.65))
			UiStyle.text(self, Vector2(r.position.x, y), rows[j][1], 20, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 28, 3)
		var status := "Introduktionen pågår" if s.intro else ("Körning pågår" if s.run else "I borgen")
		UiStyle.text(self, r.position + Vector2(0, 80), ("SENAST · " if is_last else "") + status.to_upper(), 15,
				UiStyle.GOLD if s.run or s.intro else Color(1, 1, 1, 0.7), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 3)
		var d := _delete_rect(i)
		draw_rect(d, Color(0, 0, 0, 0.6))
		draw_rect(d, Color("#e0412e", 0.6), false, 1.5)
		UiStyle.text(self, d.position + Vector2(0, 29), "Radera", 17, Color("#ff9a8a"), HORIZONTAL_ALIGNMENT_CENTER, d.size.x, 3)
	if confirm_delete > 0:
		_draw_confirm()


func _draw_confirm() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.72))
	var panel := Rect2(size.x / 2 - 320, size.y / 2 - 120, 640, 260)
	draw_rect(panel, Color(0.07, 0.06, 0.09, 0.97))
	draw_rect(panel, Color("#e0412e", 0.8), false, 2.0)
	UiStyle.text(self, Vector2(0, size.y / 2 - 60), "Radera profil %d?" % confirm_delete, 32, Color("#ff7a6a"),
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 6)
	UiStyle.text(self, Vector2(0, size.y / 2 - 14), "Det går inte att ångra. Hjältar, silver, makron och körningen försvinner.", 18,
			Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, size.x, 4)
	var no := _no_rect()
	draw_rect(no, Color(0, 0, 0, 0.7))
	draw_rect(no, Color(UiStyle.GOLD, 0.9), false, 2.0)
	UiStyle.text(self, no.position + Vector2(0, 39), "BEHÅLL", 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, no.size.x, 4)
	var yes := _yes_rect()
	draw_rect(yes, Color(0.45, 0.08, 0.06, 0.95))
	draw_rect(yes, Color("#e0412e"), false, 2.0)
	UiStyle.text(self, yes.position + Vector2(0, 39), "RADERA", 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, yes.size.x, 4)


## Sparplatsskärmen visar ingen profils silver i hörnet.
func silver_label() -> void:
	pass
