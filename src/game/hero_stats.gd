class_name HeroStats
extends RefCounted
## Nivåer, erfarenhet och personlighet (0.19, Siralim). Ren logik.
##
## Varje nivå höjer varje stat med 30 % av basvärdet (nivå 1). Personligheten låter en stat växa 40 %
## och en annan 20 % per nivå; den ändrar tillväxten, inte startvärdet, och ett byte räknas om bakåt.
## Nivåtaket är 5 × (högsta klarade djup + 1) – vårt val, så att nötning på låga djup inte ersätter
## bättre byggen. Fiendernas nivå följer bara djup och våning (enemy_level), som i Siralim.

const STATS := ["health", "attack", "intelligence", "defense", "speed"]
const STAT_NAMES := {"health": "Health", "attack": "Attack", "intelligence": "Intelligence", "defense": "Defense",
		"speed": "Speed"}
const GROWTH := 0.3
const GROWTH_UP := 0.4
const GROWTH_DOWN := 0.2
const LEVELS_PER_DEPTH := 5
## Erfarenhet per vunnen strid: bas × rumstyp × djup² – i kvadrat som kurvan till nästa nivå, så att en
## nivå tar ungefär lika många strider på varje djup (static var: balansrapporten prövar andra värden). Alla i sällskapet får den, även de stupade.
static var XP_BASE := 17
const XP_KIND := {"battle": 1.0, "elite": 1.5, "portal_battle": 1.5, "end": 2.0, "boss": 3.0}
## Hur långt under taket den väntade nivån för ett djup ligger (för rapporten och texterna).
const EXPECTED_BELOW_CAP := 2


## Tillväxten för en stat med personligheten (40 % uppåt, 20 % nedåt, annars 30 %).
static func growth(data: Dictionary, personality: String, stat: String) -> float:
	var p: Dictionary = data.get("personalities", {}).get(personality, {})
	if p.get("up", "") == stat:
		return GROWTH_UP
	if p.get("down", "") == stat:
		return GROWTH_DOWN
	return GROWTH


static func stat_at(base: float, level: int, g: float) -> float:
	return roundf(base * (1.0 + g * (maxi(level, 1) - 1)))


## Hjältens fem stats på nivån med personligheten (utan artefakt).
static func level_stats(data: Dictionary, hero_id: String, level: int, personality: String) -> Dictionary:
	var base: Dictionary = data.heroes[hero_id].stats
	var out := {}
	for stat in STATS:
		out[stat] = stat_at(float(base[stat]), level, growth(data, personality, stat))
	return out


## Vad nivån gav jämfört med nivån innan: stat -> ökning.
static func gains(data: Dictionary, hero_id: String, level: int, personality: String) -> Dictionary:
	var now := level_stats(data, hero_id, level, personality)
	var before := level_stats(data, hero_id, level - 1, personality)
	var out := {}
	for stat in STATS:
		out[stat] = now[stat] - before[stat]
	return out


## Uppdelning per källa: {stat: {base, levels, personality, artifact, total}}. Summan är total.
static func breakdown(data: Dictionary, hero_id: String, level: int, personality: String, artifact := {}) -> Dictionary:
	var base: Dictionary = data.heroes[hero_id].stats
	var out := {}
	for stat in STATS:
		var b := float(base[stat])
		var neutral := stat_at(b, level, GROWTH)
		var with_p := stat_at(b, level, growth(data, personality, stat))
		out[stat] = {"base": b, "levels": neutral - b, "personality": with_p - neutral, "artifact": 0.0}
	var kind: Dictionary = data.artifacts.get(artifact.get("type", ""), {})
	if not kind.is_empty():
		var stat: String = kind.stat
		var v: float = out[stat].base + out[stat].levels + out[stat].personality
		var raised := v * float(kind.get("stat_mult", 1.0)) + float(kind.get("stat_add", 0.0))
		out[stat].artifact = roundf(raised) - v if stat == "health" else raised - v
	for stat in STATS:
		var s: Dictionary = out[stat]
		s.total = s.base + s.levels + s.personality + s.artifact
	return out


## Erfarenhet till nästa nivå: XP_NEED_SQ · L² + XP_NEED_LIN · L + XP_NEED_FLAT (15, 30, 55, 90 …). De låga
## nivåerna är billiga så att en ny profil hinner växa under första körningen; nära taket är de dyra, så
## att ett sällskap två nivåer under taket fortfarande märker skillnaden mot våning 3 och bossen.
static var XP_NEED_SQ := 5
static var XP_NEED_LIN := 0
static var XP_NEED_FLAT := 10


static func xp_to_next(level: int) -> int:
	return XP_NEED_SQ * level * level + XP_NEED_LIN * level + XP_NEED_FLAT


static func level_cap(best_depth: int) -> int:
	return LEVELS_PER_DEPTH * (maxi(best_depth, 0) + 1)


## Nivån fienderna är byggda för på djupet (två under taket när djupet innan är klarat).
static func expected_level(depth: int) -> int:
	return maxi(1, level_cap(maxi(depth, 1) - 1) - EXPECTED_BELOW_CAP)


## Fiendernas nivå (som i Siralim där den följer djupet och inte ens egna varelser): bara djup och
## våning avgör. Varje djup börjar FLOOR_START nivåer över föregående djups tak (5 × (djup − 1)) och varje
## våning lägger på FLOOR_STEP, så att körningen stiger. En ny profil på nivå 1 klarar första våningen på
## djup 1 och växer under körningen; vid taket är djupet lättare, och då är det dags för nästa djup.
## Djup 1: 2,25 / 3,75 / 5,25. Värdena är våra, valda med botarna (tests/balance_report.gd).
static var FLOOR_START := 2.25
static var FLOOR_STEP := 1.5


static func enemy_level(depth: int, floor_index: int) -> float:
	return LEVELS_PER_DEPTH * (maxi(depth, 1) - 1) + FLOOR_START + FLOOR_STEP * clampi(floor_index, 0, 2)


## Sällskapets snittnivå ur opts.levels.
static func party_level(levels: Dictionary) -> float:
	if levels.is_empty():
		return 1.0
	var sum := 0.0
	for id in levels:
		sum += float(levels[id].get("level", 1))
	return sum / levels.size()


## Hur mycket en nivå höjer en stat med vanlig tillväxt (fiender som möter hjältar på väntad nivå).
static func level_mult(level: float) -> float:
	return 1.0 + GROWTH * (maxf(level, 1.0) - 1.0)


static func battle_xp(kind: String, depth: int, boss := false) -> int:
	var k := "boss" if boss else kind
	return roundi(XP_BASE * float(XP_KIND.get(k, 1.0)) * maxi(depth, 1) * maxi(depth, 1))


## Ger erfarenhet och höjer nivån så långt taket tillåter. progress = {level, xp}; ändras på plats.
## Vid taket fylls mätaren men nivån står still. Returnerar de nya nivåerna.
static func add_xp(progress: Dictionary, xp: int, cap: int) -> Array:
	var ups := []
	progress.xp = int(progress.get("xp", 0)) + xp
	while int(progress.level) < cap and int(progress.xp) >= xp_to_next(int(progress.level)):
		progress.xp = int(progress.xp) - xp_to_next(int(progress.level))
		progress.level = int(progress.level) + 1
		ups.append(int(progress.level))
	if int(progress.level) >= cap:
		progress.xp = mini(int(progress.xp), xp_to_next(int(progress.level)))
	return ups
