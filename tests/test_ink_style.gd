extends "res://tests/test_case.gd"
## Tuschstilen i striden (prototyp, ink-proto): färgerna följer reglerna (guld bara för val, rött bara för fara, inga
## neonfärger), stilen påverkar inget när den är av, och arenan går fram och tillbaka mellan stilarna.


func test_colors_are_unchanged_without_ink() -> void:
	UiStyle.ink = false
	assert_eq(UiStyle.inked(Color("#5dff73")), Color("#5dff73"), "3D-stilen behåller sina färger")
	assert_eq(UiStyle.panel(), UiStyle.PANEL)


func test_ink_palette_keeps_danger_and_gold_only() -> void:
	UiStyle.ink = true
	assert_eq(UiStyle.inked(Color("#ff5a4a")), UiStyle.INK_DANGER, "rött är fara")
	assert_eq(UiStyle.inked(Color(UiStyle.GOLD, 0.5)), Color(UiStyle.INK_GOLD, 0.5), "guld är val, alfa står kvar")
	assert_eq(UiStyle.inked(Color("#5dff73")), UiStyle.INK_HERO, "neongrönt blir olivgrönt bläck")
	for c in [Color.WHITE, Color("#86d8ff"), Color("#b47cff")]:
		var out := UiStyle.inked(c)
		assert_true(out.s < 0.6 and out.v < 0.6, "%s blir bläck eller sepia, inte en lysande färg" % c.to_html())
	UiStyle.ink = false


func test_arena_switches_back_and_forth() -> void:
	# Utan scenträd: miljön, golvet och efterbehandlingen byggs för sig (det kameran behöver kräver ett träd).
	var w := CryptWorld.new()
	w._build_environment()
	w._build_floor()
	w._ink_post = InkPost.new()
	var normal_bg := w._env.background_color
	w.set_ink(true)
	assert_true(w._ink_post.visible, "efterbehandlingen syns i tuschstilen")
	assert_true(not w._env.glow_enabled, "ingen glöd i tusch")
	assert_true(w._env.background_color != normal_bg, "bakgrunden byter färg")
	w.set_ink(false)
	assert_true(not w._ink_post.visible)
	assert_true(w._env.glow_enabled, "3D-stilen får tillbaka sin glöd")
	assert_eq(w._env.background_color, normal_bg, "och sin bakgrund")
	w._ink_post.free()
	w.free()
