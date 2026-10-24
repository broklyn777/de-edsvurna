class_name LossTips
extends RefCounted
## Ett konkret råd efter en förlorad nedstigning (tydliga-val): Mäster Gorm säger en eller två sanna saker om läget,
## med siffror ur spelets egna system (HeroStats.enemy_level, Forge-kostnaderna, förrådet, körningens Charges).
## Ren logik: pick() tar profilen, datan och ett sammandrag av körningen (context()), så att testerna kan bygga läget.
##
## Reglerna i ordning (de första som passar, högst MAX_TIPS):
##   charges  – en hjälte i sällskapet hade 0 Charges kvar på en förmåga (lägereld kvar på våningen nämns)
##   depth    – fiendernas nivå var minst LEVEL_GAP över sällskapets snitt och det finns ett lägre djup
##   level    – en artefakt i sällskapet kan höjas en nivå för silvret man har (billigast först)
##   forge    – någon i sällskapet saknar artefakt och silvret räcker till en
##   material – bärnsten eller trick i förrådet passar en tom, öppen plats i en artefakt

const MAX_TIPS := 2
## Så många nivåer under fiendernas som gör att Gorm föreslår ett lägre djup.
const LEVEL_GAP := 2.0


## Körningens läge för pick(): {party, depth, floor, charges, lost_to, campfire_left}.
static func context(state: RunState) -> Dictionary:
	var left := false
	if state.map != null:
		for i in state.map.indices("campfire"):
			if not state.map.cell(i).get("done", false):
				left = true
	return {"party": Array(state.party), "depth": state.depth, "floor": state.floor,
			"charges": state.charges.duplicate(true), "lost_to": String(state.chron.get("lost_to", "")),
			"campfire_left": left}


## Råden som text, viktigast först: [{kind, text}].
static func pick(profile: Profile, data: Dictionary, ctx: Dictionary) -> Array:
	var out: Array = []
	for f in [_charges_tip, _depth_tip, _level_tip, _forge_tip, _material_tip]:
		if out.size() >= MAX_TIPS:
			break
		var tip: Dictionary = f.call(profile, data, ctx)
		if not tip.is_empty():
			out.append(tip)
	return out


static func _name(data: Dictionary, hero_id: String) -> String:
	return String(data.heroes.get(hero_id, {}).get("name", hero_id))


## "Brokks", "Sefirs" – men "Jonas" blir "Jonas".
static func genitive(name: String) -> String:
	return name if name.ends_with("s") or name.ends_with("x") or name.ends_with("z") else name + "s"


static func _lost_to_boss(data: Dictionary, enc_id: String) -> bool:
	if data.encounters.get(enc_id, {}).get("guardian", false):
		return true  # en roterande väktare leder bossstriden
	for kind in data.encounters.get(enc_id, {}).get("enemies", []):
		if data.enemies.get(kind, {}).get("boss", false):
			return true
	return false


static func _charges_tip(_profile: Profile, data: Dictionary, ctx: Dictionary) -> Dictionary:
	var charges: Dictionary = ctx.get("charges", {})
	var best := ""
	var empty: Array = []
	for hero_id in ctx.get("party", []):
		var zero: Array = []
		for ability_id in charges.get(hero_id, {}):
			if int(charges[hero_id][ability_id]) <= 0 and int(data.abilities.get(ability_id, {}).get("charges", 0)) > 0:
				zero.append(String(data.abilities[ability_id].name))
		if zero.size() > empty.size():
			best = hero_id
			empty = zero
	if best == "":
		return {}
	var what: String = empty[0] if empty.size() == 1 else "%s och %s" % [empty[0], empty[1]]
	var when := "bossen" if _lost_to_boss(data, String(ctx.get("lost_to", ""))) else "nästa svåra grupp"
	var text := "%s hade 0 Charges kvar på %s. " % [_name(data, best), what]
	if ctx.get("campfire_left", false):
		text += "Det fanns en lägereld kvar på våningen – vila där innan %s (+%d Charges per förmåga)." % [
				when, RunState.CAMPFIRE_CHARGES]
	else:
		text += "Spara lägerelden till innan %s (+%d Charges per förmåga)." % [when, RunState.CAMPFIRE_CHARGES]
	return {"kind": "charges", "hero": best, "text": text}


static func _depth_tip(profile: Profile, data: Dictionary, ctx: Dictionary) -> Dictionary:
	var depth := int(ctx.get("depth", 1))
	var fl := int(ctx.get("floor", 0))
	var avg := HeroStats.party_level(profile.levels_for(data, ctx.get("party", [])))
	var foe := HeroStats.enemy_level(depth, fl)
	if depth <= 1 or foe - avg < LEVEL_GAP:
		return {}
	var lower := HeroStats.enemy_level(depth - 1, fl)
	return {"kind": "depth", "text": "Gå tillbaka till djup %d och träna. Fiendernas nivå var %s här och är %s där; ert snitt är %s." % [
			depth - 1, HeroStats.shown(foe), HeroStats.shown(lower), HeroStats.shown(avg)]}


static func _level_tip(profile: Profile, data: Dictionary, ctx: Dictionary) -> Dictionary:
	var best := ""
	var best_cost := 0
	for hero_id in ctx.get("party", []):
		var cost := profile.artifact_level_cost(hero_id)
		if cost > 0 and cost <= profile.silver and (best == "" or cost < best_cost):
			best = hero_id
			best_cost = cost
	if best == "":
		return {}
	var art := profile.artifact(best)
	var lv := int(art.level) + 1
	var opens := Forge.unlock_text(lv)
	var type_name := String(data.artifacts.get(art.type, {}).get("name", art.type)).to_lower()
	return {"kind": "level", "hero": best, "text": "Smid %s %s till nivå %d hos Hedda%s. Det kostar %d silver, ni har %d." % [
			genitive(_name(data, best)), type_name, lv, (" (öppnar " + opens.to_lower() + ")") if opens != "" else "",
			best_cost, profile.silver]}


static func _forge_tip(profile: Profile, data: Dictionary, ctx: Dictionary) -> Dictionary:
	if profile.silver < Profile.FORGE_COST:
		return {}
	for hero_id in ctx.get("party", []):
		if profile.artifact(hero_id).is_empty():
			return {"kind": "forge", "hero": hero_id, "text": "%s har ingen artefakt. Hedda smider en för %d silver, ni har %d." % [
					_name(data, hero_id), Profile.FORGE_COST, profile.silver]}
	return {}


static func _material_tip(profile: Profile, data: Dictionary, ctx: Dictionary) -> Dictionary:
	var ambers := 0
	var tricks := 0
	var full_amber := false
	for id in profile.materials:
		var n := int(profile.materials[id])
		if data.materials.amber.has(id):
			ambers += n
			full_amber = full_amber or n >= Forge.AMBER_PER_SLOT
		elif data.materials.tricks.has(id):
			tricks += n
	for hero_id in ctx.get("party", []):
		var art := profile.artifact(hero_id)
		if art.is_empty():
			continue
		var lv := int(art.level)
		var fits := false
		for i in art.stat_slots.size():
			fits = fits or (full_amber and Forge.stat_slot_open(lv, i) and String(art.stat_slots[i]) == "")
		for i in art.trick_slots.size():
			fits = fits or (tricks > 0 and Forge.trick_slot_open(lv, i) and String(art.trick_slots[i]) == "")
		if fits:
			var type_name := String(data.artifacts.get(art.type, {}).get("name", art.type)).to_lower()
			return {"kind": "material", "hero": hero_id,
					"text": "Ni har %d material i förrådet som inte sitter i någon artefakt, och %s %s har en tom plats. Hedda sätter in dem." % [
							ambers + tricks, genitive(_name(data, hero_id)), type_name]}
	return {}
