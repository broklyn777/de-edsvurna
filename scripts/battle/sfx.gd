class_name Sfx
extends Node
## Spelar ljud från res://assets/audio/<namn>.wav med lite slumpad tonhöjd,
## så att upprepade träffar inte låter mekaniska.

const VOICES := 20
## Samma ljud spelas inte oftare än så här (t.ex. volley som träffar fyra hjältar samtidigt).
const MIN_GAP_MS := 35

var _players: Array[AudioStreamPlayer] = []
var _streams := {}
var _last_played := {}
var _next := 0


func _ready() -> void:
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func stream(sound: String) -> AudioStream:
	if not _streams.has(sound):
		var path := "res://assets/audio/%s.wav" % sound
		_streams[sound] = load(path) if ResourceLoader.exists(path) else null
	return _streams[sound]


func play(sound: String, volume_db := 0.0, pitch_jitter := 0.05) -> void:
	var s := stream(sound)
	if s == null:
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_played.get(sound, -1000)) < MIN_GAP_MS:
		return
	_last_played[sound] = now
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = s
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()
