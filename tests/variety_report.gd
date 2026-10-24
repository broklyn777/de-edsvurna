extends SceneTree
## Variation (mot upprepning, docs/plan/mot-upprepning.md): hur många olika vanliga grupper och våning 1-eliter en spelare
## möter över sex nedstigningar på djup 2–5 (VARIATION_DJUP ändrar, t.ex. "2,3,4,5,3,5"). Räknar alla grupper på båda
## våningarnas kartor (övre gräns: spelaren slåss mot allt), i genomsnitt över VARIATION_N spelare (förval 40).
## En grupp räknas efter namn, djupets prägel (twist) och om den är en inkräktare.
##   godot --headless --path . --script res://tests/variety_report.gd

func _init() -> void:
	var data := GameData.load_all()
	var depths := [2, 3, 4, 5, 3, 5]
	if OS.get_environment("VARIATION_DJUP") != "":
		depths = Array(OS.get_environment("VARIATION_DJUP").split(",")).map(func(s: String) -> int: return int(s))
	var n := int(OS.get_environment("VARIATION_N")) if OS.get_environment("VARIATION_N") != "" else 40
	var realms := ["crypt", "chapel", "mountain"]
	if OS.get_environment("NIVA_REALM") != "":
		realms = [OS.get_environment("NIVA_REALM")]
	print("=== Variation: %d nedstigningar på djup %s, %d spelare ===" % [depths.size(), str(depths), n])
	for realm_id in realms:
		var sum_common := 0.0
		var sum_groups := 0.0
		var sum_max := 0.0
		var sum_elite := 0.0
		var sum_nem := 0.0
		for p in n:
			var seen := {}
			var elites := {}
			var nems := {}
			var groups := 0
			for k in depths.size():
				var s := RunState.new()
				s.set_realm(data, realm_id)
				s.depth = depths[k]
				s.fill_charges(data)
				s.start_expedition(data, 1000 + p * 37 + k * 7919)
				for f in RunState.FLOORS_PER_RUN:
					if f > 0:
						s.floor = f
						s.start_floor(data)
					for c in s.map.cells:
						if not c.has("encounter") or c.get("boss", false):
							continue
						var enc: Dictionary = data.encounters[c.encounter]
						if c.get("elite", false) or c.get("nemesis", false):
							if f == 0:
								elites[enc.name] = true
							if c.get("nemesis", false):
								nems[enc.name] = true
							continue
						var key := String(enc.name)
						if enc.has("twist"):
							key += " / " + String(enc.twist.get("name", ""))
						if c.has("intruder"):
							key += " (inkräktare)"
						seen[key] = int(seen.get(key, 0)) + 1
						groups += 1
			sum_common += seen.size()
			sum_groups += groups
			sum_max += seen.values().max() if not seen.is_empty() else 0
			sum_elite += elites.size()
			sum_nem += nems.size()
		print("  %-10s vanliga grupper: %.1f olika av %.1f mötta (vanligaste %.1f gånger) · våning 1-elit: %.2f olika · Nemesis: %.2f olika" % [
				data.realms[realm_id].short, sum_common / n, sum_groups / n, sum_max / n, sum_elite / n, sum_nem / n])
	quit()
