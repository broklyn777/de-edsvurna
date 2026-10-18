class_name Sfx
extends Node
## Spelar ljud med lite slumpad tonhöjd, så att upprepade träffar inte låter mekaniska.
##   play("namn") spelar res://assets/audio/namn.wav, eller – om det är en mapp –
##   en slumpad variant ur res://assets/audio/namn/ (samma variant spelas inte två gånger i rad).
## Rösterna (assets/audio/voice/) har en egen kanal och en vilotid så att de inte tjatar.

const VOICES := 24
## Samma ljud spelas inte oftare än så här (t.ex. volley som träffar fyra hjältar samtidigt).
const MIN_GAP_MS := 35
const ROOT := "res://assets/audio/"

var _players: Array[AudioStreamPlayer] = []
var _variants := {}
var _last_variant := {}
var _last_played := {}
var _next := 0
var _voice: AudioStreamPlayer
var _voice_ready_at := {}
var _ambience: AudioStreamPlayer


func _ready() -> void:
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_voice = AudioStreamPlayer.new()
	add_child(_voice)
	_ambience = AudioStreamPlayer.new()
	add_child(_ambience)
	_setup_master_bus()


## Många ljud samtidigt (volley, krit, Bone Crush) får inte slå i taket och spraka:
## en kompressor jämnar ut och en limiter tar topparna.
func _setup_master_bus() -> void:
	var bus := AudioServer.get_bus_index("Master")
	for i in AudioServer.get_bus_effect_count(bus):
		if AudioServer.get_bus_effect(bus, i) is AudioEffectHardLimiter:
			return
	var comp := AudioEffectCompressor.new()
	comp.threshold = -14.0
	comp.ratio = 3.0
	comp.attack_us = 2000.0
	comp.release_ms = 180.0
	AudioServer.add_bus_effect(bus, comp)
	var limiter := AudioEffectHardLimiter.new()
	limiter.pre_gain_db = 4.0
	limiter.ceiling_db = -1.0
	AudioServer.add_bus_effect(bus, limiter)


## Första (eller enda) varianten av ett ljud – används för kastljud som spelas av figurerna.
func stream(sound: String) -> AudioStream:
	var list := _streams(sound)
	return list[0] if not list.is_empty() else null


func play(sound: String, volume_db := 0.0, pitch_jitter := 0.05) -> void:
	var list := _streams(sound)
	if list.is_empty():
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_played.get(sound, -1000)) < MIN_GAP_MS:
		return
	_last_played[sound] = now
	var i := randi() % list.size()
	if list.size() > 1 and i == _last_variant.get(sound, -1):
		i = (i + 1) % list.size()
	_last_variant[sound] = i
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = list[i]
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()


## Spelar en röstreplik (voice/<namn>.mp3) om ingen annan replik hörs och vilotiden gått ut.
func say(line: String, cooldown := 0.0, volume_db := 0.0) -> void:
	var now := Time.get_ticks_msec()
	if _voice.playing or now < int(_voice_ready_at.get(line, 0)):
		return
	var path := ROOT + "voice/%s.mp3" % line
	if not ResourceLoader.exists(path):
		return
	_voice_ready_at[line] = now + int(cooldown * 1000.0)
	_voice.stream = load(path)
	_voice.volume_db = volume_db
	_voice.play()


## Startar en loopande bakgrundsstämning som tonas in.
func start_ambience(sound: String, volume_db := -10.0) -> void:
	var s := stream(sound)
	if s == null:
		return
	if s is AudioStreamWAV:
		var wav := (s as AudioStreamWAV).duplicate() as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.get_length() * wav.mix_rate)
		s = wav
	_ambience.stream = s
	_ambience.volume_db = -40.0
	_ambience.play()
	create_tween().tween_property(_ambience, "volume_db", volume_db, 2.0)


func _streams(sound: String) -> Array:
	if _variants.has(sound):
		return _variants[sound]
	var list := []
	var file := ROOT + sound + ".wav"
	if ResourceLoader.exists(file):
		list.append(load(file))
	else:
		var dir := ROOT + sound
		for f in ResourceLoader.list_directory(dir):
			if not f.ends_with("/"):
				var res := load(dir + "/" + f)
				if res is AudioStream:
					list.append(res)
	_variants[sound] = list
	return list
