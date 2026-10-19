class_name ArtifactText
extends RefCounted
## Text för en artefakt i basen ("Sköld: Helande ljus · nivå 4").


static func name_of(data: Dictionary, art: Dictionary) -> String:
	if art.is_empty():
		return "Ingen artefakt"
	var name: String = data.artifacts[art.type].name
	if art.get("ability", "") != "":
		name += ": " + data.abilities[art.ability].name
	if int(art.get("level", 1)) > 1:
		name += " · nivå %d" % int(art.level)
	return name


## Typens stat på artefaktens nivå ("+7 % Attack", "+13 Defense").
static func stat_text(data: Dictionary, art: Dictionary) -> String:
	var k: Dictionary = data.artifacts[art.type]
	var m := Forge.level_mult(int(art.get("level", 1)))
	if k.has("stat_add"):
		return "+%s %s" % [_num(float(k.stat_add) * m), HeroStats.STAT_NAMES[k.stat]]
	return "+%s %% %s" % [_num((float(k.get("stat_mult", 1.0)) - 1.0) * 100.0 * m), HeroStats.STAT_NAMES[k.stat]]


## Förmågans chans på artefaktens nivå ("38 % chans vid Anfall").
static func chance_text(data: Dictionary, art: Dictionary) -> String:
	var k: Dictionary = data.artifacts[art.type]
	var c := minf(Forge.CHANCE_MAX, float(k.chance) * Forge.level_mult(int(art.get("level", 1))))
	return String(k.trigger_text).replace("%d %%" % roundi(float(k.chance) * 100.0), "%d %%" % roundi(c * 100.0))


## Vad en bärnsten ger på nivån ("+6,6 % Attack", "+4 % Attack, +4 % Health").
static func amber_text(data: Dictionary, amber_id: String, level: int) -> String:
	var a: Dictionary = data.materials.amber.get(amber_id, {})
	var parts: Array[String] = []
	var pct := ""
	for s in a.get("stats", {}):
		pct = _num(Forge.AMBER_PCT * float(a.stats[s]) * Forge.level_mult(level) * 100.0)
		parts.append(HeroStats.STAT_NAMES[s])
	# Tvåfärgad bärnsten ger lika mycket till båda: "+5,8 % Attack och Health".
	return "+%s %% %s" % [pct, " och ".join(parts)]


## Vad ett material i en plats ger på nivån (bärnsten eller trick).
static func material_text(data: Dictionary, material_id: String, level: int) -> String:
	if data.materials.amber.has(material_id):
		return amber_text(data, material_id, level)
	return Forge.trick_text(data, material_id, level)


static func material_name(data: Dictionary, material_id: String) -> String:
	if data.materials.amber.has(material_id):
		return data.materials.amber[material_id].name
	return data.materials.tricks.get(material_id, {}).get("name", material_id)


static func _num(v: float) -> String:
	return ("%d" % roundi(v)) if absf(v - roundf(v)) < 0.05 else ("%.1f" % v).replace(".", ",")
