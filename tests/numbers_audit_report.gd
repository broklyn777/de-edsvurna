extends SceneTree
## Granskningen av siffrorna (0.23.3) i stor skala: många seedade strider i kryptan och kapellet, djup 1–3, med
## artefakter, material, statusar och våningsregler. Skriver hur många händelser som räknades om och varje sorts
## avvikelse med ett exempel.
##   godot --headless --path . --script res://tests/numbers_audit_report.gd
## AUDIT_SEEDS=n ändrar antalet frön per uppställning (standard 6).

const Audit := preload("res://tests/numbers_audit.gd")


func _init() -> void:
	var data := GameData.load_all()
	var audit := Audit.new(data)
	var seeds := int(OS.get_environment("AUDIT_SEEDS")) if OS.get_environment("AUDIT_SEEDS") != "" else 6
	for setup in Audit.setups(data):
		for s in seeds:
			audit.run_battle(setup.encounter, setup.floor, setup.depth, 1000 + s * 17 + setup.i, setup.party,
					setup.artifacts, setup.statuses, setup.rules, setup.level, setup.traits, setup.bonus)
	print("Strider: %d" % audit.counts.battles)
	print("Händelser: %s" % str(audit.counts))
	print("Modifierare som förekom: %s" % str(audit.mods_seen))
	print("Fasta belopp som inte räknades om: %s" % str(audit.unchecked))
	print("Avvikelser: %d sorter" % audit.mismatches.size())
	for key in audit.by_key:
		print("  [%s] ×%d: %s" % [key, audit.by_key[key].n, audit.by_key[key].example])
	quit(1 if not audit.mismatches.is_empty() else 0)
