extends SceneTree
## Balanssimuleringen (docs/plan/balanssimulering.md): en tunn ingång till BALANS=sim i tests/balance_report.gd, som kör
## hela nedstigningar (huvudmålen) och varje möte för sig (diagnostik, fulla och tömda Charges) på väntad nivå, en under
## och en över, med fyra hjältar och fem där platsen finns. Skriver en CSV och en sammanfattning med bara det som ligger
## utanför målen. Ändrar ingenting i spelet.
##   godot --headless --path . --script res://tests/balance_sim.gd -- --out=docs/balans/balans.csv
## Flaggor:
##   --realm=crypt,chapel   Realms (förval alla)          --depth=1,2      djup (förval 1–3)
##   --enc=<möte>           bara det mötet                 --party=paladin,brokk,alva,eira   standardlaget
##   --fifth=imma           den femte ("" = bara fyra)     --n=200          strider per möte på väntad nivå
##   --n-side=100           strider per möte på ±1 nivå    --runs=100       nedstigningar per nivå och lag
##   --side-full            också fulla Charges på ±1      --no-descents    bara möten med fulla Charges
##   --fifth-fights         varje möte också med fem i Realms byggda för fyra (förval: bara nedstigningarna)
##   --levels=0             nedstigningarnas nivåer kring väntad nivå (förval -1,0,1; möten kräver 0)
##   --out=<csv>            CSV:n (förval user://balans.csv)
##   --summary=<md>         sammanfattningen till en fil   --merge=a.csv,b.csv  slå ihop delkörningar (ingen simulering)

const Report := preload("res://tests/balance_report.gd")


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var s := String(a).trim_prefix("--")
		args[s.get_slice("=", 0)] = s.get_slice("=", 1) if s.contains("=") else "1"
	var data := GameData.load_all()
	if OS.get_environment("DJUPSTEG") != "":
		CombatSim.depth_step = float(OS.get_environment("DJUPSTEG"))  # prov: djupsteget utan att ändra spelets värde
		print("Djupsteg: +%.1f %% per djup" % (CombatSim.depth_step * 100.0))
	if OS.get_environment("BERGSTEG") != "":
		data.realms.mountain.depth_step = float(OS.get_environment("BERGSTEG"))  # prov: Trollbergets eget djupsteg
	if OS.get_environment("MOTE_MULT") != "":
		for pair in OS.get_environment("MOTE_MULT").split(","):  # prov: mötets stat_mult, "crypt_3=1.2,troll_g1=1.5"
			data.encounters[pair.get_slice("=", 0)].stat_mult = float(pair.get_slice("=", 1))
			print("Prov: %s stat_mult %s" % [pair.get_slice("=", 0), pair.get_slice("=", 1)])
	if OS.get_environment("FEM_I_FYRA") != "":
		CombatSim.five_in_four = float(OS.get_environment("FEM_I_FYRA"))
	var out := String(args.get("out", "user://balans.csv"))
	var rows: Array
	var t0 := Time.get_ticks_msec()
	if args.has("merge"):
		rows = []
		for path in String(args.merge).split(","):
			rows.append_array(Report.sim_read_csv(path))
	else:
		var cfg := Report.sim_default_cfg(data)
		if args.has("realm"):
			cfg.realms = Array(String(args.realm).split(","))
		if args.has("depth"):
			cfg.depths = Array(String(args.depth).split(",")).map(func(d: String) -> int: return int(d))
		for k in ["n", "runs"]:
			if args.has(k):
				cfg[k] = int(args[k])
		if args.has("n-side"):
			cfg.n_side = int(args["n-side"])
		if args.has("enc"):
			cfg.enc = String(args.enc)
		if args.has("party"):
			cfg.party = Array(String(args.party).split(","))
		if args.has("fifth"):
			cfg.fifth = "" if args.fifth == "1" else String(args.fifth)
		if args.has("levels"):
			cfg.level_offsets = Array(String(args.levels).split(",")).map(func(d: String) -> int: return int(d))
		cfg.side_full = args.has("side-full")
		cfg.no_descents = args.has("no-descents")
		cfg.fifth_fights = args.has("fifth-fights")
		for r in cfg.realms:
			if not data.realms.has(r):
				push_error("Okänd Realm: %s" % r)
				quit(1)
				return
		print("=== Balanssimulering: %s, djup %s, lag %s (+%s), n %d / ±1 %d, nedstigningar %d ===" % [",".join(cfg.realms),
				",".join(cfg.depths.map(func(d: int) -> String: return str(d))), ",".join(cfg.party), cfg.fifth, cfg.n,
				cfg.n_side, cfg.runs])
		print("Väntad nivå (HeroStats.expected_level på fiendernas djup):")
		for r in cfg.realms:
			print("  %-9s %s" % [r, "  ".join(cfg.depths.map(func(d: int) -> String:
					return "d%d %d" % [d, Report.sim_expected_level(data, r, d)]))])
		rows = Report.sim_run(data, cfg)
	Report.sim_write_csv(rows, out)
	var summary := Report.sim_summary(rows)
	print(summary)
	if args.has("summary"):
		var f := FileAccess.open(String(args.summary), FileAccess.WRITE)
		f.store_string(summary + "\n")
		f.close()
	print("\n%d rader till %s (%.0f s)" % [rows.size(), out, (Time.get_ticks_msec() - t0) / 1000.0])
	quit()
