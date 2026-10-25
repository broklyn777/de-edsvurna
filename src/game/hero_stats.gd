class_name HeroStats
extends RefCounted
## Nivåer, erfarenhet och personlighet (0.19, Siralim). Ren logik.
##
## Varje nivå höjer varje stat med ungefär 20 % mot nivån innan (strength, balans v1). Personligheten låter en stat växa
## en tredjedel snabbare (40 i stället för 30) och en annan en tredjedel långsammare (20); den ändrar tillväxten, inte startvärdet, och ett byte räknas om bakåt.
## Inget nivåtak, som i Siralim: den som kör fast kan gå tillbaka till ett lägre djup, träna upp sig, hitta
## bättre troféer och komma tillbaka rustad. Fiendernas nivå följer bara djup och våning (enemy_level).

const STATS := ["health", "attack", "intelligence", "defense", "speed"]
const STAT_NAMES := {"health": "Health", "attack": "Attack", "intelligence": "Intelligence", "defense": "Defense",
		"speed": "Speed"}
const GROWTH := 0.3
const GROWTH_UP := 0.4
const GROWTH_DOWN := 0.2
const LEVELS_PER_DEPTH := 5
## Edsgrader (VD 2026-10-25, VAL): var tredje nivå ger Paladinen en titel (Dialog.oath_rank_title), inga siffror.
const OATH_RANK_EVERY := 3


## Edsgraden på nivån: 0 på nivå 1–2, 1 på nivå 3–5, 2 på 6–8 …
static func oath_rank(level: int) -> int:
	return maxi(level, 0) / OATH_RANK_EVERY


## Erfarenhet per vunnen strid: bas × rumstyp × djup² – i kvadrat som kurvan till nästa nivå, så att en
## nivå tar ungefär lika många strider på varje djup (static var: balansrapporten prövar andra värden). Alla i sällskapet får den, även de stupade.
static var XP_BASE := 17
const XP_KIND := {"battle": 1.0, "elite": 1.5, "portal_battle": 1.5, "end": 2.0, "boss": 3.0}
## Varifrån en stat kommer, i bladets ordning. Nya källor (material, Nether Stone i 0.20) läggs till här och
## i breakdown(); bladet visar alla som inte är noll.
const SOURCES := ["base", "levels", "personality", "artifact", "material", "nether"]
const SOURCE_NAMES := {"base": "bas", "levels": "nivåer", "personality": "personlighet", "artifact": "artefakt",
		"material": "material", "nether": "Nether Stone"}


## Tillväxten för en stat med personligheten (40 % uppåt, 20 % nedåt, annars 30 %).
static func growth(data: Dictionary, personality: String, stat: String) -> float:
	var p: Dictionary = data.get("personalities", {}).get(personality, {})
	if p.get("up", "") == stat:
		return GROWTH_UP
	if p.get("down", "") == stat:
		return GROWTH_DOWN
	return GROWTH


## 0.26: Health, Attack, Intelligence och Defense med en decimal (CombatSim.STAT_STEP), Speed i heltal.
## carry: tillväxt kvar från omräkningen av en gammal profil (convert_legacy), i 0.19:s skala.
static func stat_at(base: float, level: int, g: float, stat := "", carry := 0.0) -> float:
	var v := base * (1.0 + g * (growth_level(level, carry) - 1.0))
	return roundf(v) if stat == "speed" else CombatSim.snap_stat(v)


## Hjältens fem stats på nivån med personligheten (utan artefakt).
static func level_stats(data: Dictionary, hero_id: String, level: int, personality: String, carry := 0.0) -> Dictionary:
	var base: Dictionary = data.heroes[hero_id].stats
	var out := {}
	for stat in STATS:
		out[stat] = stat_at(float(base[stat]), level, growth(data, personality, stat), stat, carry)
	return out


## Vad nivån gav jämfört med nivån innan: stat -> ökning. before_carry: omräkningens tillväxt på nivån innan.
static func gains(data: Dictionary, hero_id: String, level: int, personality: String, before_carry := 0.0) -> Dictionary:
	var now := level_stats(data, hero_id, level, personality)
	var before := level_stats(data, hero_id, level - 1, personality, before_carry)
	var out := {}
	for stat in STATS:
		out[stat] = now[stat] - before[stat]
	return out


## Uppdelning per källa: {stat: {<SOURCES>…, total}}. Summan av källorna är total.
static func breakdown(data: Dictionary, hero_id: String, level: int, personality: String, artifact := {},
		carry := 0.0) -> Dictionary:
	var base: Dictionary = data.heroes[hero_id].stats
	var out := {}
	for stat in STATS:
		var b := float(base[stat])
		var neutral := stat_at(b, level, GROWTH, stat, carry)
		var with_p := stat_at(b, level, growth(data, personality, stat), stat, carry)
		out[stat] = {"base": b, "levels": neutral - b, "personality": with_p - neutral, "artifact": 0.0}
	var values := {}
	for stat in STATS:
		out[stat].material = 0.0
		out[stat].nether = 0.0
		values[stat] = out[stat].base + out[stat].levels + out[stat].personality
	var parts := Forge.stat_parts(data, artifact, values)
	for part in parts:
		for stat in parts[part]:
			out[stat][part] = float(parts[part][stat])
	for stat in STATS:
		var s: Dictionary = out[stat]
		s.total = 0.0
		for source in SOURCES:
			s.total += float(s.get(source, 0.0))
	return out


## Ett stat-värde som det visas (0.23.3): heltal när det är ett heltal, annars en decimal ("7,5"). Artefaktens stat,
## bärnstenen och Nether Stone ger inte alltid heltal, och striden räknar med det exakta värdet. Förut visades talet
## avkortat ("%d"), så att bladets delar inte blev summan och en liten bärnsten på Speed syntes som ingenting.
static func shown(v: float) -> String:
	var t := roundi(v * 10.0)
	if t % 10 == 0:
		return "%d" % (t / 10)
	return ("%.1f" % (t / 10.0)).replace(".", ",")


## Källorna i en breakdown()-rad som de visas: på en decimal, så att de visade delarna blir exakt den visade
## summan (största resten får tiondelarna som blir över). {<SOURCES>…, total}.
static func shown_parts(s: Dictionary) -> Dictionary:
	var total := roundi(float(s.total) * 10.0)
	var tenths := {}
	var rest := []
	var sum := 0
	for source in SOURCES:
		var x := float(s.get(source, 0.0)) * 10.0
		var f := floori(x + 1e-6)
		tenths[source] = f
		sum += f
		rest.append([x - f, source])
	rest.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var i := 0
	while sum < total and i < rest.size():
		tenths[rest[i][1]] += 1
		sum += 1
		i += 1
	var out := {"total": total / 10.0}
	for source in SOURCES:
		out[source] = tenths[source] / 10.0
	return out


## Erfarenhet till nästa nivå: XP_NEED_SQ · L² + XP_NEED_LIN · L + XP_NEED_FLAT (15, 30, 55, 90 …). De låga
## nivåerna är billiga så att en ny profil hinner växa under första körningen; högre upp tar varje nivå fler
## strider, så att träning på ett lägre djup lönar sig men går långsammare än att klara nästa (vårt val).
static var XP_NEED_SQ := 5
static var XP_NEED_LIN := 0
static var XP_NEED_FLAT := 10


static func xp_to_next(level: int) -> int:
	if legacy or level + 1 <= KNEE:
		return XP_NEED_SQ * level * level + XP_NEED_LIN * level + XP_NEED_FLAT
	return roundi(_threshold_xp(level + 1) - _threshold_xp(level))


## Den väntade nivån för ett djup (3, 8, 13 …): ungefär fiendernas nivå mellan våning 1 och 2. Ett sällskap
## här klarar djupet ungefär som i 0.18; två nivåer över är det rustat. Bara för rapporten och texterna.
static func expected_level(depth: int) -> int:
	return roundi(new_level(LEVELS_PER_DEPTH * (maxi(depth, 1) - 1) + 3))


## Fiendernas nivå (som i Siralim där den följer djupet och inte ens egna varelser): bara djup och
## våning avgör. Varje djup ligger LEVELS_PER_DEPTH nivåer över det förra och varje våning lägger på
## FLOOR_STEP, så att körningen stiger. En ny profil på nivå 1 klarar första våningen på djup 1 och växer
## under körningen.
## Djup 1: 2,25 / 3,75 / 5,25. Värdena är våra, valda med botarna (tests/balance_report.gd).
static var FLOOR_START := 2.25
static var FLOOR_STEP := 1.5


static func enemy_level(depth: int, floor_index: int) -> float:
	return new_level(enemy_growth_level(depth, floor_index))


## Fiendernas nivå i 0.19:s skala (tillväxtnivån, old_level): 5 × (djup − 1) + 2,25 + 1,5 per våning.
static func enemy_growth_level(depth: int, floor_index: int) -> float:
	return LEVELS_PER_DEPTH * (maxi(depth, 1) - 1) + FLOOR_START + FLOOR_STEP * clampi(floor_index, 0, 2)


## Fiendernas multiplikator på djupet och våningen: samma styrkekurva som hjältarna (strength) på fiendernas nivå.
static func enemy_level_mult(depth: int, floor_index: int) -> float:
	return strength(enemy_level(depth, floor_index))


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
	return strength(level)


static func battle_xp(kind: String, depth: int, boss := false) -> int:
	var k := "boss" if boss else kind
	return roundi(XP_BASE * float(XP_KIND.get(k, 1.0)) * maxi(depth, 1) * maxi(depth, 1))


## Ger erfarenhet och höjer nivån. progress = {level, xp}; ändras på plats. Returnerar de nya nivåerna.
static func add_xp(progress: Dictionary, xp: int) -> Array:
	var ups := []
	progress.xp = int(progress.get("xp", 0)) + xp
	while int(progress.xp) >= xp_to_next(int(progress.level)):
		progress.xp = int(progress.xp) - xp_to_next(int(progress.level))
		progress.level = int(progress.level) + 1
		ups.append(int(progress.level))
	return ups


# --- Nivåskalan (VD 2026-10-25, variant C "kurva" i docs/plan/nivaer-och-charges.md) -------------------------------
# En nivå L motsvarar "tillväxtnivån" g(L) i 0.19:s skala: stats, fiendernas multiplikator och den samlade erfarenheten
# följer 0.19:s kurva i g(L), så striderna är lika starka som förut och bara antalet nivåer (och hoppet per nivå) ändras.
#   g(L) = L upp till KNEE (de fyra första nivåerna kommer lika tätt som förut, första nedstigningen är finjusterad för det),
#   sedan KNEE + CURVE_A · (L − KNEE)^CURVE_P: allt glesare uppåt och varje nivå större (+32–40 % på djup 2–3, +17 % på
#   djup 10, förr +3 %). Djup 10 är ungefär nivå 13 (förr 48).
# VAL: Siralim ger +30 % av basen per nivå och har ingen sådan skala; styrkan på ett givet djup är densamma.
# legacy = true är 0.19:s skala (g(L) = L), bara för botarnas jämförelser (NIVAER=idag i soak.gd och balance_report.gd).
const KNEE := 5.0
const CURVE_A := 2.34
const CURVE_P := 1.4
static var legacy := false


## Botarnas jämförelse: "idag" = 0.19:s skala, allt annat = spelets.
static func set_variant(name: String) -> void:
	legacy = name == "idag"


## Nivån L som tillväxtnivå i 0.19:s skala (kontinuerlig).
static func old_level(level: float) -> float:
	var l := maxf(level, 1.0)
	if legacy or l <= KNEE:
		return l
	return KNEE + CURVE_A * pow(l - KNEE, CURVE_P)


## Tillväxtnivån som stat_at räknar med (1 + 0,3 · (g − 1) = strength): nivåns styrka, med omräkningens rest (Profile.heroes
## "carry", convert_legacy, i 0.19:s skala) som en del av en nivå på takten (old_level).
static func growth_level(level: float, carry := 0.0) -> float:
	var l := maxf(level, 1.0)
	if carry > 0.0:
		l = new_level(old_level(l) + carry)
	return 1.0 + (strength(l) - 1.0) / GROWTH


# --- Styrkan per nivå (balans v1, VD 2026-10-25) -----------------------------------------------------------------------
# Takten (nivåer mot erfarenhet, fiendernas nivå per djup och våning, väntad nivå) är kurvan ovan (variant C). Styrkan
# per nivå är en egen kurva som hjältar och fiender delar: +20 % per nivå (mot förra nivån) för nivå 2–10, sedan ett steg
# som krymper långsamt mot +13 % (+19 % nivå 11, +16 % nivå 20, +14 % nivå 30). Förr gav kurvan 1 + 0,3 · (g(L) − 1)
# +30 / 23 / 19 / 16 % för nivå 2–5 och +32–40 % för nivå 6–9. VAL: Siralim ger +30 % av basen per nivå.
const STEP_LOW := 0.20
const STEP_LOW_UNTIL := 10
const STEP_FAR := 0.13
const STEP_FADE := 10.0
## Botarnas jämförelse: true = styrkan som förut (1 + 0,3 · (old_level − 1), balans v0).
static var strength_v0 := false
static var _strength_cache: PackedFloat64Array = PackedFloat64Array()


## Steget till nivå n (n ≥ 2): andelen nivån lägger på nivån innan.
static func strength_step(n: int) -> float:
	if n <= STEP_LOW_UNTIL:
		return STEP_LOW
	return STEP_FAR + (STEP_LOW - STEP_FAR) * exp(-float(n - STEP_LOW_UNTIL) / STEP_FADE)


## Styrkan på nivån (multiplikatorn på basen med vanlig tillväxt, nivå 1 = 1). Kontinuerlig: mellan två nivåer
## geometriskt (fiendernas nivåer är inte heltal).
static func strength(level: float) -> float:
	var l := maxf(level, 1.0)
	if legacy:
		return 1.0 + GROWTH * (l - 1.0)
	if strength_v0:
		return 1.0 + GROWTH * (old_level(l) - 1.0)
	var lo := int(floor(l))
	if _strength_cache.size() < lo + 2:
		var n := maxi(lo + 2, 64)
		_strength_cache.resize(n + 1)
		_strength_cache[0] = 1.0
		_strength_cache[1] = 1.0
		for k in range(2, n + 1):
			_strength_cache[k] = _strength_cache[k - 1] * (1.0 + strength_step(k))
	var a := _strength_cache[lo]
	var b := _strength_cache[lo + 1]
	return a * pow(b / a, l - lo)


## En tillväxtnivå i 0.19:s skala som nivå (omvändningen av old_level, kontinuerlig).
static func new_level(old: float) -> float:
	var x := maxf(old, 1.0)
	if legacy or x <= KNEE:
		return x
	return KNEE + pow((x - KNEE) / CURVE_A, 1.0 / CURVE_P)


## Erfarenheten (räknad från nivå 1) där nivå L nås: när 0.19:s kurva når tillväxtnivån mitt emellan g(L − 1) och g(L).
## Då ligger hjälten (räknat i strider, viktat med erfarenheten) lika mycket före som efter 0.19:s kurva. Prototypens
## tröskel (mitt emellan g(L − 1) + 1 och g(L) i erfarenhet) låg 0,6 gamla nivåer för sent, och karriärbotarna kom ett djup
## kortare efter 18 nedstigningar (6,8 → 5,8). Upp till KNEE är det precis 0.19:s kurva.
static func _threshold_xp(level: int) -> float:
	if level <= 1:
		return 0.0
	if legacy or level <= KNEE:
		return _cum_xp(float(level))
	return _cum_xp((old_level(level - 1) + old_level(level)) / 2.0)


## 0.19:s samlade erfarenhet från nivå 1 till nivå x (summan av 5 · l² + 10 för l = 1 … x − 1, kontinuerlig).
static func _cum_xp(x: float) -> float:
	var n := x - 1.0
	return XP_NEED_SQ * n * (n + 1.0) * (2.0 * n + 1.0) / 6.0 + XP_NEED_LIN * n * (n + 1.0) / 2.0 + XP_NEED_FLAT * n


## Samlad erfarenhet för nivå och erfarenhet mot nästa (heltal, som add_xp räknar).
static func total_xp(level: int, xp: int) -> int:
	var sum := xp
	for l in range(1, maxi(level, 1)):
		sum += xp_to_next(l)
	return sum


## Omräkningen av en profil från 0.19:s skala (sparad före 0.31, Profile.LEVEL_SCALE): VD 2026-10-25, exakt lika stark
## som förut. Den högsta nya nivån vars tillväxt är högst den gamla, och resten (carry, gammal tillväxt − old_level(nivån),
## i 0.19:s skala) bärs tills nästa nivå nås (den nivåns tillväxt är minst den gamla). Förr avrundades uppåt, och gamla
## profiler blev 24–30 % starkare. Erfarenheten mot nästa nivå så att den samlade erfarenheten blir densamma när det går
## (aldrig en hel nivå eller mer). Ger {level, xp, carry}.
static func convert_legacy(old_level_value: int, old_xp: int) -> Dictionary:
	var old_lv := maxi(old_level_value, 1)
	var best := 1
	while old_level(best + 1) <= old_lv + 0.000001:
		best += 1
	var carry := maxf(float(old_lv) - old_level(best), 0.0)
	if carry < 0.000001:
		carry = 0.0
	var legacy_total := 0.0
	for k in range(1, old_lv):
		legacy_total += XP_NEED_SQ * k * k + XP_NEED_LIN * k + XP_NEED_FLAT
	legacy_total += old_xp
	var xp := clampi(roundi(legacy_total - total_xp(best, 0)), 0, maxi(xp_to_next(best) - 1, 0))
	return {"level": best, "xp": xp, "carry": carry}
