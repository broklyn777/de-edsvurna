extends Node
## Utvecklarverktyg som styrs via kommandoraden (argument efter `--`).
##   --screenshot=<sökväg>   Sparar en skärmdump efter några bildrutor och avslutar.
##   --frames=<n>            Antal bildrutor att vänta innan skärmdumpen (standard 30).

var _screenshot_path := ""
var _frames_left := 30


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			_screenshot_path = arg.get_slice("=", 1)
		elif arg.begins_with("--frames="):
			_frames_left = int(arg.get_slice("=", 1))
	set_process(_screenshot_path != "")
	process_mode = Node.PROCESS_MODE_ALWAYS  # 0.25: också när en hjälpruta har pausat striden


func _process(_delta: float) -> void:
	_frames_left -= 1
	if _frames_left > 0:
		return
	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(_screenshot_path)
	print("Skärmdump sparad: %s (%s)" % [_screenshot_path, error_string(err)])
	get_tree().quit()
