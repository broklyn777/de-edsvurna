extends "res://tests/test_case.gd"
## 0.30: inställningarna – musik och ljudeffekter på var sin kanal, 0 stänger av, sparas för hela spelet.


func test_volume_goes_to_its_own_bus_and_zero_mutes() -> void:
	var keep := [GameSettings.music, GameSettings.sfx]
	GameSettings.music = 0.5
	GameSettings.sfx = 0.0
	GameSettings.apply()
	var m := AudioServer.get_bus_index(GameSettings.MUSIC_BUS)
	var s := AudioServer.get_bus_index(GameSettings.SFX_BUS)
	assert_true(m >= 0 and s >= 0, "kanalerna finns")
	assert_near(AudioServer.get_bus_volume_db(m), linear_to_db(0.5), 0.01, "halva volymen")
	assert_true(not AudioServer.is_bus_mute(m))
	assert_true(AudioServer.is_bus_mute(s), "0 % stänger av")
	assert_eq(AudioServer.get_bus_send(m), "Master")
	GameSettings.music = keep[0]
	GameSettings.sfx = keep[1]
	GameSettings.apply()


func test_sfx_players_use_the_buses() -> void:
	var sfx := Sfx.new()
	sfx._ready()
	assert_eq(String(sfx._players[0].bus), GameSettings.SFX_BUS)
	assert_eq(String(sfx._music[0].bus), GameSettings.MUSIC_BUS)
	sfx.free()
