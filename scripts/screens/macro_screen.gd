extends Control
## Makroredigeraren, som Siralims Macro Editor men för touch.
##
## Vänster: hjältarna (vilket makro de kör och om standardhandlingen är Makro eller Manuell) och
## listan med makron. Höger: det valda makrots rader (upp till 20), som flyttas, ändras och tas bort.
## En rad redigeras i fyra kolumner: subjekt | villkor | handling | mål.

const FONT := 19
const SMALL := 15
const ROW_H := 54

## Autoload-noden Run (hämtas via sökväg så att skriptet kompilerar även utan autoloads).
@onready var run: Node = get_node("/root/Run")
var data: Dictionary
var current := ""  # macro_id som redigeras
var _heroes_box: VBoxContainer
var _macro_box: VBoxContainer
var _lines_box: VBoxContainer
var _name_edit: LineEdit
var _add_line: Button
var _editor: Control
var _edit_index := -1
var _edit_line := {}
var _lists := {}
var _options := {}
var _preview: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	data = run.data
	run.base_music()
	theme = _make_theme()
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.035, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_build()
	var ids := _macro_ids()
	var own: String = run.assignment.get("paladin", "")
	if ids.has(own):
		_select(own)
	elif not ids.is_empty():
		_select(ids[0])
	_refresh_all()
	if "--edit-line" in OS.get_cmdline_user_args():  # utvecklarflagga för skärmdumpar
		_open_editor(0)


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
	var done := _button("Klar", func() -> void: run.close_macros(), 140)
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
	left.add_child(_header("HJÄLTAR – MAKRO OCH STANDARDHANDLING"))
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
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(scroll)
	_lines_box = VBoxContainer.new()
	_lines_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lines_box.add_theme_constant_override("separation", 6)
	scroll.add_child(_lines_box)
	_add_line = _button("+ Lägg till rad", func() -> void: _open_editor(-1))
	right.add_child(_add_line)

	_editor = _build_editor()
	_editor.visible = false
	add_child(_editor)


func _build_editor() -> Control:
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.025, 0.045, 0.98)
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
	col.add_child(title)
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
		# Listan växer på höjden inuti en ScrollContainer, så att den går att dra med fingret.
		var scroll := ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		box.add_child(scroll)
		var list := ItemList.new()
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
		var mode := _button("Makro" if run.uses_macro(hero_id) else "Manuell", _toggle_mode.bind(hero_id), 100)
		row.add_child(mode)


func _refresh_macros() -> void:
	for c in _macro_box.get_children():
		c.queue_free()
	for id in _macro_ids():
		var b := _button("%s  (%d rader)" % [run.macros[id].name, run.macros[id].lines.size()], _select.bind(id))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if id == current:
			b.add_theme_color_override("font_color", UiStyle.GOLD)
			b.add_theme_color_override("font_focus_color", UiStyle.GOLD)
		_macro_box.add_child(b)


func _refresh_lines() -> void:
	for c in _lines_box.get_children():
		c.queue_free()
	if current == "" or not run.macros.has(current):
		_name_edit.text = ""
		_add_line.disabled = true
		return
	var macro: Dictionary = run.macros[current]
	if _name_edit.text != macro.name:
		_name_edit.text = macro.name
	var lines: Array = macro.lines
	if lines.is_empty():
		_empty_hint()
	for i in lines.size():
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, ROW_H)
		_lines_box.add_child(row)
		var num := Label.new()
		num.text = "%d." % (i + 1)
		num.custom_minimum_size = Vector2(36, 0)
		row.add_child(num)
		var text := _button(MacroRunner.describe_line(data, lines[i]), _open_editor.bind(i))
		text.alignment = HORIZONTAL_ALIGNMENT_LEFT
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.add_theme_font_size_override("font_size", 16)
		row.add_child(text)
		row.add_child(_button("↑", _move_line.bind(i, -1), 52))
		row.add_child(_button("↓", _move_line.bind(i, 1), 52))
		row.add_child(_button("✕", _delete_line.bind(i), 52))
	_add_line.disabled = lines.size() >= MacroRunner.MAX_LINES
	_add_line.text = "+ Lägg till rad" if not _add_line.disabled else "Max %d rader" % MacroRunner.MAX_LINES


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


func _move_line(i: int, step: int) -> void:
	var lines: Array = run.macros[current].lines
	var j := i + step
	if j < 0 or j >= lines.size():
		return
	var tmp: Dictionary = lines[i]
	lines[i] = lines[j]
	lines[j] = tmp
	_refresh_lines()


func _delete_line(i: int) -> void:
	run.macros[current].lines.remove_at(i)
	_refresh_lines()
	_refresh_macros()


# --- Radeditorn -------------------------------------------------------------------

func _open_editor(index: int) -> void:
	if current == "":
		return
	_edit_index = index
	var lines: Array = run.macros[current].lines
	_edit_line = lines[index].duplicate() if index >= 0 else \
			{"subject": "any_enemy", "cond": "is_alive", "value": 0, "action": "attack", "ability": "", "target": "that"}
	_fill_lists()
	_editor.visible = true


## Fyller kolumnerna. Villkor med värden visas som egna rader ("har liv < 10 %", "< 20 %" …), som i
## Siralims Macro Editor. Förmågor hämtas från hjältarna som kör makrot (annars alla).
func _fill_lists() -> void:
	_options.clear()
	var subjects: Array = []
	for s in MacroRunner.SUBJECTS:
		subjects.append({"label": _cap(MacroRunner.subject_name(s)), "subject": s})
	var conds: Array = []
	for cond in MacroRunner.CONDITIONS:
		for v in _values_for(cond):
			conds.append({"label": MacroRunner.condition_name(data, cond, v), "cond": cond, "value": v})
	var actions: Array = []
	for a in ["attack", "defend", "provoke", "skip", "test_next"]:
		actions.append({"label": MacroRunner.action_label(data, a), "action": a, "ability": ""})
	for ability_id in _macro_abilities():
		actions.insert(1, {"label": MacroRunner.action_label(data, "ability", ability_id), "action": "ability", "ability": ability_id})
	var targets: Array = []
	for t in MacroRunner.TARGETS:
		targets.append({"label": _cap(MacroRunner.target_name(t)), "target": t})
	_options = {"subject": subjects, "cond": conds, "action": actions, "target": targets}
	for key in _options:
		var list: ItemList = _lists[key]
		list.clear()
		var selected := -1
		for i in _options[key].size():
			var o: Dictionary = _options[key][i]
			list.add_item(o.label)
			if _matches_option(key, o):
				selected = i
		if selected >= 0:
			list.select(selected)
	_update_preview()


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
		"has_charges":
			return _macro_abilities()
		"has_artifact", "lacks_artifact":
			return data.artifacts.keys()
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
			return o.cond == _edit_line.cond and str(o.value) == str(_edit_line.get("value", 0))
		"action":
			return o.action == _edit_line.action and o.ability == _edit_line.get("ability", "")
	return o.target == _edit_line.get("target", "that")


func _on_pick(index: int, key: String) -> void:
	var o: Dictionary = _options[key][index]
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
	return t
