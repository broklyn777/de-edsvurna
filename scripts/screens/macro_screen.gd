extends Control
## Makroredigeraren, som Siralims Macro Editor men för touch.
##
## Vänster: hjältarna (vilket makro de kör; AUTO eller MANUELL väljs i striden, 0.29.5) och
## listan med makron. Höger: gambitsidan (docs/plan/gambits.md): varje rad är ett stort kort med villkoret till vänster,
## handlingen till höger och en stor PÅ/AV-knapp. Håll kvar tummen så lyfts kortet och kan dras; telefonen vibrerar när
## det släpps. Rader under hjältens sista plats och rader med villkor profilen inte äger körs inte och syns låsta.
## En rad redigeras i fyra kolumner: subjekt | villkor | handling | mål.

const FONT := 19
const SMALL := 15
const ROW_H := 54

## Autoload-noden Run (hämtas via sökväg så att skriptet kompilerar även utan autoloads).
@onready var run: Node = get_node("/root/Run")
## 0.29.5: redigeraren kan ligga ovanpå en pausad strid (embedded); Klar stänger den då och striden fortsätter med de
## ändrade makrona. focus_hero väljer den hjältens makro först.
signal closed
var embedded := false
var focus_hero := ""
var data: Dictionary
var current := ""  # macro_id som redigeras
var _heroes_box: VBoxContainer
var _macro_box: VBoxContainer
var _lines_box: VBoxContainer
var _scroll: ScrollContainer
var _slots_label: Label
## Gambitsidan: kortet som dras (lyft med kvarhållen tumme) och var det hamnar.
var _drag_card: Card = null
var _drag_to := -1
const CARD_GAP := 8
const HOLD_TIME := 0.35
const HOLD_SLOP := 14.0
var _name_edit: LineEdit
var _add_line: Button
var _editor: Control
var _edit_index := -1
var _edit_line := {}
var _lists := {}
var _options := {}
var _preview: Label
var _delete_button: Button
## 0.30.24: sökfältet och villkorens grupper i radeditorn (VD: listan var för lång att rulla i).
var _search: LineEdit
var _group := "common"
var _group_buttons := {}
var _shown := {}  # kolumn → index i _options som syns
const COND_GROUPS := [["common", "Vanliga"], ["hp", "Liv"], ["status", "Status"], ["windup", "Laddning"],
		["trait", "Egenskaper"], ["omen", "Tecken"],
		["charges", "Charges"], ["artifact", "Artefakt"], ["all", "Alla"]]
## Makro-UX förslag 5: förslag som fyller i sökningen med ett tryck. Fältet får fokus av sig självt när villkoren är
## många, men bara utan pekskärm: på telefonen skulle tangentbordet täcka halva skärmen varje gång.
const SEARCH_CHIPS := ["liv", "förgiftad", "Charges", "lägst"]
const AUTO_FOCUS_OVER := 30
var _search_chips := {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	data = run.data
	if not embedded:
		run.base_music()
	HelpBox.offer(self, ["macros"])  # 0.25: hjälprutan första gången
	theme = _make_theme()
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.035, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_build()
	var ids := _macro_ids()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--macro-focus="):  # skärmdumpar: en hjältes makro, t.ex. --macro-focus=brokk
			focus_hero = arg.get_slice("=", 1)
	var own: String = run.assignment.get(focus_hero if focus_hero != "" else "paladin", "")
	if ids.has(own):
		_select(own)
	elif not ids.is_empty():
		_select(ids[0])
	if "--gambit-off" in OS.get_cmdline_user_args() and current != "" and run.macros[current].lines.size() > 1:
		run.macros[current].lines[1].enabled = false  # skärmdumpar: en avstängd rad (sparas inte med en påhittad profil)
	_refresh_all()
	if "--gambit-drag" in OS.get_cmdline_user_args():  # skärmdumpar: det första kortet lyft och draget nedåt
		_demo_drag.call_deferred()
	if "--edit-line" in OS.get_cmdline_user_args():  # utvecklarflagga för skärmdumpar
		_open_editor(0)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--macro-search="):  # 0.30.24: sökningen ifylld (skärmdumpar)
			_open_editor(0)
			_search.text = arg.get_slice("=", 1)
			_apply_filter()


func _done() -> void:
	if not embedded:
		run.close_macros()
		return
	run.save_macros()
	run.ui("ui_back", -12.0)
	closed.emit()
	queue_free()


## Androids bakåtknapp (Run.go_back): stänger radeditorn, annars som Klar.
func go_back() -> bool:
	if _editor != null and _editor.visible:
		_editor.visible = false
	else:
		_done()
	return true


# --- Bygga gränssnittet ---------------------------------------------------------

func _build() -> void:
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		root.add_theme_constant_override("margin_" + side, 16)
	add_child(root)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	root.add_child(col)

	var top := HBoxContainer.new()
	col.add_child(top)
	var title := Label.new()
	title.text = "MAKRON"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", UiStyle.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var hint := Label.new()
	hint.text = "Raderna prövas uppifrån och ned. Första raden som passar och går att utföra blir hjältens handling."
	hint.add_theme_font_size_override("font_size", SMALL)
	hint.modulate = Color(1, 1, 1, 0.65)
	top.add_child(hint)
	var done := _button("Tillbaka till striden" if embedded else "Klar", _done, 240 if embedded else 140)
	top.add_child(done)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	col.add_child(body)

	# Vänster: hjältar och makron.
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(390, 0)
	left.add_theme_constant_override("separation", 8)
	body.add_child(left)
	left.add_child(_header("HJÄLTAR OCH DERAS MAKRO"))
	# 0.23.2: hjältarna i en egen rullista, så att makrolistan och raderna alltid får plats.
	var heroes_scroll := ScrollContainer.new()
	heroes_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	heroes_scroll.custom_minimum_size = Vector2(0, mini(run.macro_heroes().size(), 4) * 52)
	left.add_child(heroes_scroll)
	_heroes_box = VBoxContainer.new()
	_heroes_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heroes_scroll.add_child(_heroes_box)
	left.add_child(_header("MAKRON"))
	var macro_scroll := ScrollContainer.new()
	macro_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(macro_scroll)
	_macro_box = VBoxContainer.new()
	_macro_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	macro_scroll.add_child(_macro_box)
	var macro_tools := HBoxContainer.new()
	left.add_child(macro_tools)
	macro_tools.add_child(_button("+ Nytt", _new_macro))
	macro_tools.add_child(_button("Kopiera", _copy_macro))
	macro_tools.add_child(_button("Ta bort", _delete_macro))

	# Höger: raderna i det valda makrot.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	body.add_child(right)
	var name_row := HBoxContainer.new()
	right.add_child(name_row)
	var name_label := Label.new()
	name_label.text = "Namn:"
	name_row.add_child(name_label)
	_name_edit = LineEdit.new()
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_edit.text_changed.connect(func(t: String) -> void:
		if current != "":
			run.macros[current].name = t
			_refresh_macros()
			_refresh_heroes())
	name_row.add_child(_name_edit)
	_slots_label = Label.new()
	_slots_label.add_theme_font_size_override("font_size", SMALL)
	_slots_label.add_theme_color_override("font_color", Color(UiStyle.TRAIT_GOLD, 0.85))
	name_row.add_child(_slots_label)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.scroll_deadzone = 10
	right.add_child(_scroll)
	_lines_box = VBoxContainer.new()
	_lines_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lines_box.add_theme_constant_override("separation", CARD_GAP)
	_scroll.add_child(_lines_box)
	_add_line = _button("+ Lägg till rad", func() -> void: _open_editor(-1))
	_add_line.custom_minimum_size.y = 56
	right.add_child(_add_line)

	_editor = _build_editor()
	_editor.visible = false
	add_child(_editor)


func _build_editor() -> Control:
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.025, 0.045, 1.0)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	shade.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)
	var title := Label.new()
	title.text = "REDIGERA RAD"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", UiStyle.GOLD)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	col.add_child(top)
	top.add_child(title)
	_search = LineEdit.new()
	_search.placeholder_text = "Sök, t.ex. liv 30 eller mossa …"
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.custom_minimum_size.y = 48
	_search.clear_button_enabled = true
	_search.add_theme_font_size_override("font_size", 20)
	# Makro-UX förslag 5: en ritad lupp i fältet (plats till vänster om texten) och en tydligare ram.
	var field := StyleBoxFlat.new()
	field.bg_color = Color(0.12, 0.105, 0.15)
	field.border_color = Color(UiStyle.TRAIT_GOLD, 0.8)
	field.set_border_width_all(2)
	field.set_corner_radius_all(6)
	field.set_content_margin_all(8)
	field.content_margin_left = 44
	var field_focus := field.duplicate()
	field_focus.border_color = UiStyle.GOLD
	_search.add_theme_stylebox_override("normal", field)
	_search.add_theme_stylebox_override("focus", field_focus)
	_search.add_theme_color_override("font_placeholder_color", Color(1, 1, 1, 0.55))
	var glass := Magnifier.new()
	glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glass.position = Vector2(10, 10)
	glass.size = Vector2(28, 28)
	_search.add_child(glass)
	_search.text_changed.connect(func(_t: String) -> void: _apply_filter())
	top.add_child(_search)
	# Förslagschips: de vanligaste sökningarna med ett tryck, utan tangentbordet (som täcker halva telefonen).
	for word in SEARCH_CHIPS:
		var chip := Button.new()
		chip.text = word
		chip.toggle_mode = true
		chip.custom_minimum_size = Vector2(0, 48)
		chip.add_theme_font_size_override("font_size", 17)
		chip.pressed.connect(_chip_search.bind(word))
		chip.pressed.connect(run.ui_tap)
		top.add_child(chip)
		_search_chips[word] = chip
	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 10)
	col.add_child(cols)
	for key in ["subject", "cond", "action", "target"]:
		var box := VBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.size_flags_stretch_ratio = 1.4 if key == "cond" or key == "action" else 1.0
		cols.add_child(box)
		box.add_child(_header({"subject": "OM …", "cond": "VILLKOR", "action": "HANDLING", "target": "MÅL"}[key]))
		if key == "cond":
			var groups := HFlowContainer.new()
			groups.add_theme_constant_override("h_separation", 4)
			groups.add_theme_constant_override("v_separation", 4)
			box.add_child(groups)
			for g in COND_GROUPS:
				var b := Button.new()
				b.text = g[1]
				b.toggle_mode = true
				b.add_theme_font_size_override("font_size", 15)
				b.pressed.connect(_set_group.bind(g[0]))
				groups.add_child(b)
				_group_buttons[g[0]] = b
		# Listan växer på höjden inuti en ScrollContainer, så att den går att dra med fingret.
		var scroll := ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.scroll_deadzone = 8  # ett drag rullar, ett tryck väljer
		box.add_child(scroll)
		var list := ItemList.new()
		list.add_theme_constant_override("v_separation", 10)  # högre rader, lättare att träffa
		list.auto_height = true
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_theme_font_size_override("font_size", 18)
		list.item_selected.connect(_on_pick.bind(key))
		scroll.add_child(list)
		_lists[key] = list
	_preview = Label.new()
	_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview.add_theme_font_size_override("font_size", 20)
	_preview.add_theme_color_override("font_color", UiStyle.TRAIT_GOLD)
	col.add_child(_preview)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(buttons)
	_delete_button = _button("Ta bort rad", _delete_edited, 180)
	buttons.add_child(_delete_button)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(spacer)
	buttons.add_child(_button("Avbryt", func() -> void: _editor.visible = false, 160))
	buttons.add_child(_button("OK", _save_line, 160))
	return shade


# --- Uppdatera listorna ---------------------------------------------------------

func _refresh_all() -> void:
	_refresh_heroes()
	_refresh_macros()
	_refresh_lines()


func _refresh_heroes() -> void:
	for c in _heroes_box.get_children():
		c.queue_free()
	for hero_id in run.macro_heroes():
		var row := HBoxContainer.new()
		_heroes_box.add_child(row)
		var name := Label.new()
		name.text = data.heroes[hero_id].name
		name.custom_minimum_size = Vector2(130, 0)
		name.add_theme_color_override("font_color", Color(data.heroes[hero_id].color))
		row.add_child(name)
		var assigned: String = run.assignment.get(hero_id, "")
		var macro_name: String = run.macros[assigned].name if run.macros.has(assigned) else "– inget –"
		var pick := _button(macro_name, _cycle_macro.bind(hero_id), 150)
		row.add_child(pick)


func _refresh_macros() -> void:
	for c in _macro_box.get_children():
		c.queue_free()
	for id in _macro_ids():
		var n: int = run.macros[id].lines.size()
		var b := _button("%s  (%d %s)" % [run.macros[id].name, n, "rad" if n == 1 else "rader"], _select.bind(id))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if id == current:
			b.add_theme_color_override("font_color", UiStyle.GOLD)
			b.add_theme_color_override("font_focus_color", UiStyle.GOLD)
		_macro_box.add_child(b)


func _refresh_lines() -> void:
	for c in _lines_box.get_children():
		_lines_box.remove_child(c)
		c.queue_free()
	_drag_card = null
	if current == "" or not run.macros.has(current):
		_name_edit.text = ""
		_slots_label.text = ""
		_add_line.disabled = true
		return
	var macro: Dictionary = run.macros[current]
	if _name_edit.text != macro.name:
		_name_edit.text = macro.name
	var lines: Array = macro.lines
	var slots := _slots()
	var lv_next := _next_slot_level()
	var states := Gambits.line_states(data, lines, run.profile.gambits, slots)
	_slots_label.text = "  PLATSER %d / %d%s" % [mini(Gambits.used_slots(data, lines, run.profile.gambits), slots), slots,
			"  ·  nästa på nivå %d" % lv_next if lv_next > 0 else ""]
	if lines.is_empty():
		_empty_hint()
	for i in lines.size():
		var card := Card.new()
		card.screen = self
		card.index = i
		card.line = lines[i]
		card.locked_id = Gambits.missing(data, lines[i], run.profile.gambits)
		card.beyond = states[i] == "beyond"
		card.custom_minimum_size = Vector2(0, card_height())
		_lines_box.add_child(card)
	_add_line.disabled = lines.size() >= MacroRunner.MAX_LINES
	_add_line.text = "+ Lägg till rad" if not _add_line.disabled else "Max %d rader" % MacroRunner.MAX_LINES


## Kortets höjd: ungefär en sjättedel av skärmen (gambits.md), aldrig under 96 px.
func card_height() -> float:
	return maxf(96.0, get_viewport_rect().size.y / 6.0)


## Platserna för makrot: hjältarna som kör det (den med minst platser avgör), annars Paladinens.
func _slots() -> int:
	var heroes := _runners()
	var n := MacroRunner.MAX_LINES
	for hero_id in heroes:
		n = mini(n, run.profile.gambit_slots(data, hero_id))
	return n if not heroes.is_empty() else run.profile.gambit_slots(data, "paladin")


func _runners() -> Array:
	return run.macro_heroes().filter(func(h: String) -> bool: return run.assignment.get(h, "") == current)


## Nivån då nästa plats öppnas för den som har minst platser, eller 0.
func _next_slot_level() -> int:
	var heroes := _runners()
	if heroes.is_empty():
		heroes = ["paladin"]
	var best := 0
	for hero_id in heroes:
		if run.profile.gambit_slots(data, hero_id) == _slots():
			var lv := Gambits.next_slot_level(data, int(run.profile.hero(data, hero_id).level))
			if lv > 0 and (best == 0 or lv < best):
				best = lv
	return best


func _demo_drag() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var cards := _lines_box.get_children()
	if cards.size() < 2:
		return
	begin_drag(cards[0])
	drag_to(cards[0], _lines_box.get_global_rect().position.y + card_height() * 1.3)


## Slår av eller på en rad (PÅ/AV-knappen på kortet).
func toggle_line(i: int) -> void:
	var line: Dictionary = run.macros[current].lines[i]
	line.enabled = not line.get("enabled", true)
	run.save_macros()
	run.ui("ui_toggle", -10.0)
	_refresh_lines()


## Kvarhållen tumme: kortet lyfts och följer fingret.
func begin_drag(card: Card) -> void:
	_drag_card = card
	_drag_to = card.index
	card.z_index = 10
	card.lifted = true
	card.queue_redraw()
	Input.vibrate_handheld(25)
	run.ui("ui_toggle", -14.0)


## Fingret flyttas med ett lyft kort: de andra korten glider undan, och listan rullar vid kanterna.
func drag_to(card: Card, global_y: float) -> void:
	var lines: Array = run.macros[current].lines
	var pitch := card_height() + CARD_GAP
	var local_y := global_y - _lines_box.get_global_rect().position.y
	_drag_to = clampi(int(floor(local_y / pitch)), 0, lines.size() - 1)
	card.drag_offset = local_y - (card.index + 0.5) * pitch
	for c in _lines_box.get_children():
		var other := c as Card
		if other == null or other == card:
			continue
		var shift := 0.0
		if card.index < _drag_to and other.index > card.index and other.index <= _drag_to:
			shift = -pitch
		elif card.index > _drag_to and other.index < card.index and other.index >= _drag_to:
			shift = pitch
		other.shift = shift
		other.queue_redraw()
	card.queue_redraw()
	var view := _scroll.get_global_rect()
	if global_y < view.position.y + 40.0:
		_scroll.scroll_vertical -= 12
	elif global_y > view.end.y - 40.0:
		_scroll.scroll_vertical += 12


## Kortet släpps: raden flyttas dit och telefonen vibrerar (gambits.md).
func end_drag(card: Card) -> void:
	var lines: Array = run.macros[current].lines
	var to := _drag_to
	_drag_card = null
	if to >= 0 and to != card.index:
		var line: Dictionary = lines[card.index]
		lines.remove_at(card.index)
		lines.insert(to, line)
		run.save_macros()
	Input.vibrate_handheld(40)
	run.ui("ui_confirm", -10.0)
	_refresh_lines.call_deferred()


## Ett tomt makro (0.23.2): vad en rad är, introts uppdrag och en föreslagen rad som läggs till med ett tryck.
func _empty_hint() -> void:
	var info := Label.new()
	info.text = "Makrot har inga rader än. En rad säger: om något stämmer, gör detta. Tryck på \"+ Lägg till rad\" längst ned, eller ta förslaget:"
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_font_size_override("font_size", 17)
	info.modulate = Color(1, 1, 1, 0.8)
	_lines_box.add_child(info)
	if not run.profile.intro_done:
		var quest := Label.new()
		quest.text = "Mäster Gorm: anfall den svagaste fienden."
		quest.add_theme_font_size_override("font_size", 17)
		quest.add_theme_color_override("font_color", UiStyle.GOLD)
		_lines_box.add_child(quest)
	var line: Dictionary = run.FIRST_LINE
	var b := _button("+ Förslag: " + MacroRunner.describe_line(data, line), _add_suggested)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(0, ROW_H)
	b.add_theme_color_override("font_color", UiStyle.GOLD)
	_lines_box.add_child(b)


func _add_suggested() -> void:
	if current == "":
		return
	run.macros[current].lines.append(run.FIRST_LINE.duplicate(true))
	run.save_macros()
	run.ui("ui_confirm", -8.0)
	_refresh_lines()
	_refresh_macros()


## Makrona som listas: alla utom startmakrona för hjältar som inte har anslutit ännu.
func _macro_ids() -> Array:
	var heroes: Array = run.macro_heroes()
	return run.macros.keys().filter(func(id: String) -> bool: return not data.heroes.has(id) or heroes.has(id))


# --- Handlingar -----------------------------------------------------------------

func _select(id: String) -> void:
	current = id
	_refresh_macros()
	_refresh_lines()


func _new_macro() -> void:
	var id: String = run.new_macro_id()
	run.macros[id] = {"name": "Nytt makro", "lines": []}
	_select(id)


func _copy_macro() -> void:
	if current == "":
		return
	var id: String = run.new_macro_id()
	var copy: Dictionary = run.macros[current].duplicate(true)
	copy.name = copy.name + " (kopia)"
	run.macros[id] = copy
	_select(id)


func _delete_macro() -> void:
	if current == "":
		return
	run.macros.erase(current)
	for hero_id in run.assignment:
		if run.assignment[hero_id] == current:
			run.assignment[hero_id] = ""
	var ids := _macro_ids()
	current = ids[0] if not ids.is_empty() else ""
	_refresh_all()


func _cycle_macro(hero_id: String) -> void:
	var ids: Array = [""] + _macro_ids()
	var i := ids.find(run.assignment.get(hero_id, ""))
	run.assignment[hero_id] = ids[(i + 1) % ids.size()]
	_refresh_heroes()


func _toggle_mode(hero_id: String) -> void:
	run.default_action[hero_id] = "manual" if run.uses_macro(hero_id) else "macro"
	_refresh_heroes()


func _delete_line(i: int) -> void:
	run.macros[current].lines.remove_at(i)
	run.save_macros()
	_refresh_lines()
	_refresh_macros()


## Radeditorns "Ta bort rad".
func _delete_edited() -> void:
	if _edit_index >= 0:
		_delete_line(_edit_index)
	_editor.visible = false


# --- Radeditorn -------------------------------------------------------------------

func _open_editor(index: int) -> void:
	if current == "":
		return
	_edit_index = index
	var lines: Array = run.macros[current].lines
	_edit_line = lines[index].duplicate() if index >= 0 else \
			{"subject": "any_enemy", "cond": "is_alive", "value": 0, "action": "attack", "ability": "", "target": "that"}
	_fill_lists()
	_delete_button.visible = index >= 0
	_editor.visible = true


## Fyller kolumnerna. Villkor med värden visas som egna rader ("har liv < 10 %", "< 20 %" …), som i
## Siralims Macro Editor. Förmågor hämtas från hjältarna som kör makrot (annars alla).
func _fill_lists() -> void:
	_options.clear()
	var subjects: Array = []
	for s in MacroRunner.SUBJECTS:
		subjects.append({"label": _cap(MacroRunner.subject_name(s)), "subject": s})
	var conds: Array = []
	var locked: Array = []
	for cond in MacroRunner.CONDITIONS:
		# Gambits: villkor profilen inte äger står sist, låsta och med sitt rykte (de går inte att välja).
		var gid := Gambits.for_cond(data, cond)
		if gid != "" and not run.profile.gambits.has(gid):
			if not locked.any(func(o: Dictionary) -> bool: return o.get("gambit", "") == gid):
				locked.append({"label": "LÅST · %s – %s" % [Gambits.name_of(data, gid), Gambits.clue(data, gid)], "cond": cond,
						"value": _values_for(cond)[0], "locked": true, "gambit": gid})
			continue
		for v in _values_for(cond):
			conds.append({"label": MacroRunner.condition_name(data, cond, v), "cond": cond, "value": v})
	conds.append_array(locked)
	var actions: Array = []
	for a in ["attack", "defend", "provoke", "skip", "test_next"]:
		var gid := Gambits.for_cond(data, a)
		if gid != "" and not run.profile.gambits.has(gid):
			actions.append({"label": "LÅST · %s – %s" % [MacroRunner.action_label(data, a), Gambits.clue(data, gid)], "action": a,
					"ability": "", "locked": true})
			continue
		actions.append({"label": MacroRunner.action_label(data, a), "action": a, "ability": ""})
	for ability_id in _macro_abilities():
		actions.insert(1, {"label": MacroRunner.action_label(data, "ability", ability_id), "action": "ability", "ability": ability_id})
	var targets: Array = []
	for t in MacroRunner.TARGETS:
		targets.append({"label": _cap(MacroRunner.target_name(t)), "target": t})
	_options = {"subject": subjects, "cond": conds, "action": actions, "target": targets}
	_search.text = ""
	if conds.size() > AUTO_FOCUS_OVER and not OS.has_feature("mobile"):
		_search.grab_focus.call_deferred()
	var sel: Dictionary = {}
	for o in conds:
		if _matches_option("cond", o):
			sel = o
	_group = "common" if sel.is_empty() or _cond_group(sel.cond) in ["common", "hp"] else _cond_group(sel.cond)
	_apply_filter()
	_update_preview()


## Villkorets grupp (knapparna ovanför kolumnen). "common" är allt utom de långa listorna med egenskaper och statusar.
static func _cond_group(cond: String) -> String:
	if cond in ["hp_below", "hp_above", "lowest_hp"]:
		return "hp"
	if cond in ["has_status", "lacks_status"]:
		return "status"
	if cond in ["has_trait", "lacks_trait"]:
		return "trait"
	if cond in ["is_charging", "charge_left_at_most", "is_channeling", "is_charge_target", "intends_heal"]:
		return "windup"
	if cond == "has_charges":
		return "charges"
	if cond in ["omen_is", "next_ability_echoes", "free_ability_unused"]:
		return "omen"
	if cond in ["has_artifact", "lacks_artifact"]:
		return "artifact"
	return "common"


func _set_group(group: String) -> void:
	_group = group
	_apply_filter()


## Sökordet för jämförelser: små bokstäver, utan tecken som %, < och >.
static func _norm(text: String) -> String:
	var out := text.to_lower()
	for ch in ["%", "<", ">", "(", ")", ":", "→", ",", "."]:
		out = out.replace(ch, " ")
	return out


## Visar det som passar sökningen (alla ord måste finnas) och, i villkorskolumnen, gruppen. Det valda syns alltid.
## Med en sökning visas villkor ur alla grupper.
func _apply_filter() -> void:
	var words := _norm(_search.text).split(" ", false)
	for w in _search_chips:
		(_search_chips[w] as Button).set_pressed_no_signal(_norm(_search.text).strip_edges() == _norm(w))
	for g in _group_buttons:
		(_group_buttons[g] as Button).set_pressed_no_signal(g == _group and words.is_empty())
	for key in _options:
		var list: ItemList = _lists[key]
		list.clear()
		_shown[key] = []
		for i in _options[key].size():
			var o: Dictionary = _options[key][i]
			var chosen := _matches_option(key, o)
			var ok := true
			if not words.is_empty():
				var label := _norm(o.label)
				for w in words:
					if not label.contains(w):
						ok = false
						break
				# En sökning som inte gäller den här kolumnen (t.ex. "förgiftad" för Handling) lämnar den orörd.
				if not ok and not _options[key].any(func(x: Dictionary) -> bool: return _all_words(_norm(x.label), words)):
					ok = true
			elif key == "cond" and _group != "all":
				var g := _cond_group(o.cond)
				ok = g == _group or (_group == "common" and g == "hp")
			if key == "cond" and o.get("locked", false) and words.is_empty() and _group != "all" \
					and _group != _cond_group(o.cond) and not (_group == "common" and _cond_group(o.cond) == "hp"):
				ok = false
			if ok or chosen:
				_shown[key].append(i)
				list.add_item(o.label)
				if o.get("locked", false):
					list.set_item_disabled(list.item_count - 1, true)
					list.set_item_custom_fg_color(list.item_count - 1, Color("#b8a27a"))
				if chosen:
					list.select(list.item_count - 1)


## Ett förslagschip: fyller i sökningen, eller tömmer den om samma chip redan är valt.
func _chip_search(word: String) -> void:
	_search.text = "" if _norm(_search.text).strip_edges() == _norm(word) else word
	_apply_filter()


## Ett kort på gambitsidan: villkoret till vänster, handlingen till höger, PÅ/AV längst till höger. Ett tryck öppnar
## radeditorn, ett tryck på PÅ/AV slår av eller på raden, och en kvarhållen tumme lyfter kortet så att det kan dras.
class Card extends Control:
	var screen: Node
	var index := 0
	var line := {}
	var locked_id := ""  # villkoret profilen inte äger, eller ""
	var beyond := false  # under hjältens sista plats
	var lifted := false
	var shift := 0.0  # när ett annat kort dras förbi
	var drag_offset := 0.0
	var _press := Vector2.ZERO
	var _held := 0.0
	var _down := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS
		set_process(false)

	func toggle_rect() -> Rect2:
		var w := minf(118.0, size.x * 0.16)
		return Rect2(size.x - w - 10.0, 12.0, w, size.y - 24.0)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_down = true
				_held = 0.0
				_press = event.global_position
				set_process(true)
			else:
				set_process(false)
				_down = false
				if lifted:
					lifted = false
					drag_offset = 0.0
					accept_event()
					screen.end_drag(self)
				elif event.global_position.distance_to(_press) < HOLD_SLOP:
					if toggle_rect().has_point(event.position):
						screen.toggle_line(index)
					else:
						screen.run.ui_tap()
						screen._open_editor(index)
		elif event is InputEventMouseMotion and _down:
			if lifted:
				accept_event()
				screen.drag_to(self, event.global_position.y)
			elif event.global_position.distance_to(_press) >= HOLD_SLOP:
				_down = false  # ett drag: listan rullar
				set_process(false)

	func _process(delta: float) -> void:
		_held += delta
		if _down and not lifted and _held >= HOLD_TIME:
			screen.begin_drag(self)

	func _draw() -> void:
		var data: Dictionary = screen.data
		var on: bool = line.get("enabled", true)
		var live := on and locked_id == "" and not beyond
		var r := Rect2(Vector2(0, shift + drag_offset), size)
		if lifted:
			r = r.grow(4.0)
			draw_rect(Rect2(r.position + Vector2(6, 8), r.size), Color(0, 0, 0, 0.45))
		var bg := Color(0.12, 0.105, 0.15) if live else Color(0.075, 0.07, 0.09)
		draw_rect(r, bg.lightened(0.08) if lifted else bg)
		var edge := Color(UiStyle.TRAIT_GOLD, 0.7 if live else 0.25)
		if lifted:
			edge = UiStyle.GOLD
		draw_rect(r, edge, false, 3.0 if lifted else 1.5)
		var a := 1.0 if live else 0.5
		var y0 := r.position.y
		var tr := toggle_rect()
		tr.position.y += shift + drag_offset
		var text_w := tr.position.x - 64.0
		var half := text_w * 0.5
		# Numret.
		UiStyle.text(self, Vector2(14, y0 + r.size.y * 0.5 + 9), "%d" % (index + 1), 26,
				Color(UiStyle.GOLD, 0.8 * a), HORIZONTAL_ALIGNMENT_LEFT, 40)
		var x := 52.0
		# Villkoret till vänster.
		UiStyle.text(self, Vector2(x, y0 + 26), "OM " + MacroRunner.subject_name(line.subject).to_upper(), 15,
				Color(1, 1, 1, 0.6 * a), HORIZONTAL_ALIGNMENT_LEFT, half - 16)
		var cond_text := MacroRunner.condition_name(data, line.cond, line.get("value", 0))
		UiStyle.para(self, Vector2(x, y0 + 54), cond_text, 21, Color(1, 0.95, 0.82, a), half - 16, 2)
		# Pilen och handlingen till höger.
		var ax := x + half
		UiStyle.text(self, Vector2(ax - 6, y0 + r.size.y * 0.5 + 10), "→", 26, Color(UiStyle.TRAIT_GOLD, 0.8 * a),
				HORIZONTAL_ALIGNMENT_LEFT, 30)
		var act := MacroRunner.action_label(data, line.action, line.get("ability", "")).replace("Förmåga: ", "")
		var tail := ""
		if line.action in ["attack", "ability"]:
			var ab: Dictionary = data.abilities.get(line.get("ability", ""), {}) if line.action == "ability" else {}
			if line.action == "attack" or ab.get("target", "") in ["enemy", "ally"]:
				tail = "PÅ " + MacroRunner.target_name(line.get("target", "that")).to_upper()
		UiStyle.para(self, Vector2(ax + 30, y0 + 54), act, 21, Color(UiStyle.TRAIT_GOLD, a), half - 40, 2)
		if tail != "":
			UiStyle.text(self, Vector2(ax + 30, y0 + 26), tail, 15, Color(1, 1, 1, 0.6 * a), HORIZONTAL_ALIGNMENT_LEFT, half - 40)
		# Låst villkor eller låst plats, längst ned på kortet.
		var note := ""
		if locked_id != "":
			note = "LÅST · " + Gambits.clue(data, locked_id)
		elif beyond:
			var lv: int = screen._next_slot_level()
			note = "LÅST · Platsen öppnas på nivå %d" % lv if lv > 0 else "LÅST · Ingen plats"
		if note != "":
			UiStyle.text(self, Vector2(x, y0 + r.size.y - 12), note, 15, Color("#d9a35a"), HORIZONTAL_ALIGNMENT_LEFT,
					text_w - 8)
		# PÅ/AV.
		var col := Color(0.18, 0.42, 0.2) if on else Color(0.25, 0.18, 0.18)
		draw_rect(tr, col)
		draw_rect(tr, Color(1, 1, 1, 0.35), false, 2.0)
		UiStyle.text(self, Vector2(tr.position.x, tr.get_center().y + 10), "PÅ" if on else "AV", 26,
				Color(1, 1, 1, 0.95 if on else 0.6), HORIZONTAL_ALIGNMENT_CENTER, tr.size.x)


## Luppen i sökfältet, ritad med linjer så att den inte beror på typsnittets tecken.
class Magnifier extends Control:
	func _draw() -> void:
		var c := Vector2(11, 11)
		var col := Color(UiStyle.TRAIT_GOLD, 0.95)
		draw_arc(c, 8.0, 0.0, TAU, 24, col, 2.5, true)
		draw_line(c + Vector2(5.8, 5.8), Vector2(26, 26), col, 3.5, true)


static func _all_words(label: String, words: PackedStringArray) -> bool:
	for w in words:
		if not label.contains(w):
			return false
	return true


func _values_for(cond: String) -> Array:
	match cond:
		"hp_below":
			return [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
		"hp_above":
			return [10, 20, 30, 40, 50, 60, 70, 80, 90]
		"has_status", "lacks_status":
			return data.auras.keys()
		"has_trait", "lacks_trait":
			return data.traits.keys().filter(func(t: String) -> bool: return not data.traits[t].get("hidden", false))
		"deaths_at_least", "revives_at_least":
			return [1, 2, 3]
		"own_turn":
			return [1, 2, 3, 4, 5]
		"charge_left_at_most":
			return [1, 2, 3]
		"has_charges":
			return _macro_abilities()
		"has_artifact", "lacks_artifact":
			return data.artifacts.keys()
		"omen_is":
			return RunState.omen_ids(data)
	return [0]


func _macro_abilities() -> Array:
	var out: Array = []
	for hero_id in data.heroes:
		if run.assignment.get(hero_id, "") == current:
			for a in data.heroes[hero_id].get("abilities", []):
				if not out.has(a):
					out.append(a)
	if out.is_empty():
		for hero_id in data.heroes:
			for a in data.heroes[hero_id].get("abilities", []):
				if not out.has(a):
					out.append(a)
	return out


func _matches_option(key: String, o: Dictionary) -> bool:
	match key:
		"subject":
			return o.subject == _edit_line.subject
		"cond":
			var v: Variant = _edit_line.get("value", 0)
			if (typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_INT) and (typeof(o.value) == TYPE_FLOAT or typeof(o.value) == TYPE_INT):
				return o.cond == _edit_line.cond and is_equal_approx(float(o.value), float(v))  # JSON ger 0.0, listan 0
			return o.cond == _edit_line.cond and str(o.value) == str(v)
		"action":
			return o.action == _edit_line.action and o.ability == _edit_line.get("ability", "")
	return o.target == _edit_line.get("target", "that")


func _on_pick(index: int, key: String) -> void:
	var o: Dictionary = _options[key][_shown[key][index]]
	if o.get("locked", false):
		return
	match key:
		"subject":
			_edit_line.subject = o.subject
		"cond":
			_edit_line.cond = o.cond
			_edit_line.value = o.value
		"action":
			_edit_line.action = o.action
			_edit_line.ability = o.ability
		"target":
			_edit_line.target = o.target
	_update_preview()


func _update_preview() -> void:
	_preview.text = MacroRunner.describe_line(data, _edit_line)
	# 0.30.25: kedjans regel syns där den väljs (MacroRunner.match_line: nästa rad prövas bara mot samma figur).
	if _edit_line.get("action", "") == "test_next":
		_preview.text += "\n" + CHAIN_NOTE


const CHAIN_NOTE := "Kedjan håller fast vid den som den här raden väljer: nästa rad prövas bara mot samma figur och söker inte vidare efter någon annan."


func _save_line() -> void:
	var lines: Array = run.macros[current].lines
	if _edit_index >= 0:
		lines[_edit_index] = _edit_line
	elif lines.size() < MacroRunner.MAX_LINES:
		lines.append(_edit_line)
	_editor.visible = false
	_refresh_lines()
	_refresh_macros()


# --- Hjälp ----------------------------------------------------------------------

func _button(text: String, call: Callable, width := 0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(width, 48)
	b.pressed.connect(call)
	b.pressed.connect(run.ui_tap)
	return b


static func _cap(text: String) -> String:
	return text.substr(0, 1).to_upper() + text.substr(1)


func _header(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", SMALL)
	l.modulate = Color(1, 1, 1, 0.6)
	return l


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = UiStyle.bold()
	t.default_font_size = FONT
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.1, 0.09, 0.13)
	normal.border_color = Color(UiStyle.TRAIT_GOLD, 0.35)
	normal.set_border_width_all(1)
	normal.set_content_margin_all(8)
	var hover := normal.duplicate()
	hover.bg_color = Color(0.16, 0.14, 0.2)
	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.35, 0.25, 0.05)
	for state in ["normal", "focus"]:
		t.set_stylebox(state, "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("disabled", "Button", normal)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.07, 0.065, 0.09)
	panel.set_content_margin_all(6)
	t.set_stylebox("panel", "ItemList", panel)
	t.set_stylebox("normal", "LineEdit", normal)
	t.set_color("font_selected_color", "ItemList", UiStyle.GOLD)
	# 0.30.24: en bred rullningslist som går att dra med tummen.
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.12, 0.11, 0.15)
	track.content_margin_left = 11
	track.content_margin_right = 11
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color(UiStyle.TRAIT_GOLD, 0.55)
	grab.set_corner_radius_all(6)
	grab.content_margin_left = 11
	grab.content_margin_right = 11
	var grab_hi := grab.duplicate()
	grab_hi.bg_color = Color(UiStyle.GOLD, 0.85)
	t.set_stylebox("scroll", "VScrollBar", track)
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab_hi)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab_hi)
	return t
