class_name BossFrame
extends Control
## Bossens ram högst upp: hälsa och en tydlig kastmätare som säger vad du ska göra.

var sim: CombatSim
var boss: CombatUnit
var _ghost := 1.0
var _ghost_hold := 0.0
var _t := 0.0
var _interrupted_t := 0.0
var _interrupted_name := ""
var _hit := 0.0


func setup(s: CombatSim) -> void:
	sim = s
	boss = s.boss
	size = Vector2(580, 96)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func on_damage() -> void:
	_ghost_hold = 0.3
	_hit = 1.0


func on_interrupted(ability_name: String) -> void:
	_interrupted_t = 1.0
	_interrupted_name = ability_name


func _process(delta: float) -> void:
	_t += delta
	_interrupted_t = maxf(0.0, _interrupted_t - delta * 1.2)
	_hit = maxf(0.0, _hit - delta * 8.0)
	var pct := boss.hp_pct()
	if pct >= _ghost:
		_ghost = pct
	elif _ghost_hold > 0.0:
		_ghost_hold -= delta
	else:
		_ghost = maxf(pct, _ghost - delta * 0.25)
	queue_redraw()


func _draw() -> void:
	var w := size.x
	draw_rect(Rect2(0, 0, w, 58), UiStyle.PANEL)
	var frenzy := boss.auras.has("frenzy")
	var border := Color(1, 0.25, 0.2, 0.6 + 0.4 * sin(_t * 8.0)) if frenzy else Color(boss.color, 0.45)
	draw_rect(Rect2(0, 0, w, 58), border, false, 2.0)
	UiStyle.text(self, Vector2(12, 22), boss.name.to_upper(), 18, boss.color)
	UiStyle.text(self, Vector2(12, 22), "%d%%" % ceili(boss.hp_pct() * 100.0), 18, Color.WHITE,
			HORIZONTAL_ALIGNMENT_RIGHT, w - 24)
	if boss.auras.has("exposed"):
		var name_w := UiStyle.bold().get_string_size(boss.name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		var left: float = boss.auras.exposed.remaining
		UiStyle.text(self, Vector2(24 + name_w, 22), "BLOTTAD %.0f s" % ceilf(left), 16,
				Color(UiStyle.TRAIT_GOLD, 0.75 + 0.25 * sin(_t * 10.0)))
	var hp_color := Color("#a3304e").lerp(Color("#ff3b2e"), 0.5 + 0.5 * sin(_t * 8.0)) if frenzy else Color("#a3304e")
	var hp_rect := Rect2(12, 30, w - 24, 20)
	UiStyle.bar(self, hp_rect, boss.hp_pct(), hp_color.lerp(Color.WHITE, _hit * 0.35), _ghost)

	var cast_rect := Rect2(60, 64, w - 120, 26)
	if boss.is_casting():
		var ab := sim.ability(boss.cast.ability)
		var interruptible: bool = ab.get("interruptible", false)
		var c := UiStyle.CAST_INTERRUPTIBLE if interruptible else UiStyle.CAST_UNSTOPPABLE
		draw_rect(cast_rect.grow(3), Color(0, 0, 0, 0.7))
		UiStyle.bar(self, cast_rect, boss.cast_progress(), c)
		var left: float = boss.cast.duration - boss.cast.elapsed
		var label: String = ab.name
		if ab.target == "threat_target" and not boss.cast.targets.is_empty():
			label += "  →  " + sim.unit(boss.cast.targets[0]).name
		UiStyle.text(self, cast_rect.position + Vector2(8, 19), label, 16, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, -1, 4)
		UiStyle.text(self, cast_rect.position + Vector2(0, 19), "%.1f" % left, 16, Color.WHITE,
				HORIZONTAL_ALIGNMENT_RIGHT, cast_rect.size.x - 8, 4)
		var hint := "AVBRYT!" if interruptible else "SKYDDA!"
		var blink := 0.55 + 0.45 * sin(_t * 16.0)
		UiStyle.text(self, Vector2(cast_rect.end.x + 6, cast_rect.position.y + 20), hint, 17,
				Color(c.lightened(0.3), blink), HORIZONTAL_ALIGNMENT_LEFT, -1, 4)
	elif _interrupted_t > 0.0:
		var a := minf(1.0, _interrupted_t * 2.0)
		draw_rect(cast_rect, Color(0.4, 0.4, 0.45, 0.8 * a))
		UiStyle.text(self, cast_rect.position + Vector2(0, 19), "%s  –  AVBRUTEN" % _interrupted_name, 16,
				Color(1, 0.9, 0.4, a), HORIZONTAL_ALIGNMENT_CENTER, cast_rect.size.x, 4)
