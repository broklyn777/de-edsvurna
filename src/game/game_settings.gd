class_name GameSettings
extends RefCounted
## Inställningar för hela spelet (0.30), inte per sparplats: musikens och ljudeffekternas volym. Sparas i
## user://settings.cfg. Musiken och effekterna har var sin ljudkanal ("Music", "Sfx") som går till Master.

const PATH := "user://settings.cfg"
const MUSIC_BUS := "Music"
const SFX_BUS := "Sfx"

static var music := 1.0
static var sfx := 1.0


## Skapar kanalerna om de saknas (Sfx anropar detta innan spelarna får sin kanal).
static func ensure_buses() -> void:
	for bus_name in [MUSIC_BUS, SFX_BUS]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus_name)
			AudioServer.set_bus_send(i, "Master")


static func load_and_apply() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		music = clampf(float(cfg.get_value("audio", "music", 1.0)), 0.0, 1.0)
		sfx = clampf(float(cfg.get_value("audio", "sfx", 1.0)), 0.0, 1.0)
	apply()


static func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music)
	cfg.set_value("audio", "sfx", sfx)
	cfg.save(PATH)


## Volymen som andel (0–1) blir decibel på kanalen; 0 stänger av den helt.
static func apply() -> void:
	ensure_buses()
	for pair in [[MUSIC_BUS, music], [SFX_BUS, sfx]]:
		var i := AudioServer.get_bus_index(pair[0])
		AudioServer.set_bus_mute(i, pair[1] <= 0.0)
		AudioServer.set_bus_volume_db(i, linear_to_db(maxf(pair[1], 0.001)))
