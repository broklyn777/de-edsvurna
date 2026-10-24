extends SceneTree
## Textspelet från kommandoraden (TextPlay i tests/text_play.gd): ett kommando per anrop.
##   godot --headless --path . --script res://tests/textplay_cli.gd -- --dir=<mapp> <kommando …>


func _init() -> void:
	var dir := ""
	var words: Array[String] = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--dir="):
			dir = arg.get_slice("=", 1)
		else:
			words.append(arg)
	if dir == "":
		print("Ange --dir=<mapp>")
		quit(1)
		return
	print(load("res://tests/text_play.gd").new().execute(dir, " ".join(words)))
	quit()
