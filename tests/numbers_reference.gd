extends RefCounted
## En oberoende omskrivning av formlerna i docs/formler.md (granskningen 0.23.3). Den anropar inget i
## CombatSim, HeroStats eller Forge och har egna konstanter, skrivna ur dokumentet och ur Siralims
## publicerade formler (docs/research/siralim.md §12 och §17). Om spelet och den här filen säger olika
## är det antingen en bugg i spelet eller ett fel i dokumentet: testerna i test_numbers_audit.gd jämför dem.

# --- §2 Skadan ---------------------------------------------------------------

## Variationen: ±10 % (vårt val).
const ROLL_MIN := 0.9
const ROLL_MAX := 1.1
## Spellnivåerna: [potency i % av Int, andel av Defense som ignoreras] (Siralim, Codex).
const TIERS := {"small": [0.90, 0.0], "moderate": [1.10, 0.10], "large": [1.20, 0.20],
		"massive": [1.30, 0.30], "devastating": [1.50, 0.40]}


## Anfall: (max(Attack × variation − Defense, 0) + 1 % av Attack × variation) × styrka.
static func attack(atk: float, roll: float, def: float, power: float) -> float:
	var a := atk * roll
	return (maxf(a - def, 0.0) + a / 100.0) * power


## Besvärjelse: max(Int × nivå × variation − Defense × (1 − genomslag), 0) × styrka.
static func spell(intel: float, tier: String, roll: float, def: float, power: float) -> float:
	var t: Array = TIERS.get(tier, [1.0, 0.0])
	var potency := intel * float(t[0]) * roll
	return maxf(potency - def * (1.0 - float(t[1])), 0.0) * power


## Indirekt (före Defense): Attack × variation × styrka. Defense dras av sist, se indirect_after().
static func indirect_raw(atk: float, roll: float, power: float) -> float:
	return atk * roll * power


## Indirekt: efter modifierarna dras 20 % av Defense av.
static func indirect_after(amount: float, def: float) -> float:
	return maxf(amount - def / 5.0, 0.0)


# --- §3 Modifierarna ---------------------------------------------------------

## Ökningar adderas, minskningar multipliceras och varje minskning stannar vid −80 %.
static func mods(factors: Array) -> float:
	var up := 0.0
	var down := 1.0
	for f in factors:
		var x := float(f)
		if x > 1.0:
			up += x - 1.0
		elif x < 1.0:
			down *= 0.2 if x < 0.2 else x
	return (1.0 + up) * down


# --- §4 Krit och undvikande --------------------------------------------------

## Krit-chans: grundchans + 10 procentenheter per fördubbling av fartkvoten, 0–50 %.
static func crit_chance(base: float, my_speed: float, their_speed: float) -> float:
	var r := my_speed / maxf(their_speed, 1.0)
	return clampf(base + 0.1 * log(maxf(r, 0.01)) / log(2.0), 0.0, 0.5)


## Krit-skada: +75 % + 125 % · log₃(kvot), minst +50 %.
static func crit_bonus(my_speed: float, their_speed: float) -> float:
	var r := my_speed / maxf(their_speed, 1.0)
	return maxf(0.5, 0.75 + 1.25 * log(maxf(r, 0.01)) / log(3.0))


## Undvikande: bara ett snabbare mål, 10 % per fördubbling av målets fart mot anfallarens, högst 30 %.
static func dodge(attacker_speed: float, target_speed: float) -> float:
	var r := maxf(target_speed, 1.0) / attacker_speed
	if r <= 1.0:
		return 0.0
	return minf(0.1 * log(r) / log(2.0), 0.3)


## Med egenskaper (Hal sten, Eterisk): adderas, högst 75 % (eller fartens om den är högre).
static func dodge_with_traits(base: float, adds: float) -> float:
	return minf(base + adds, maxf(0.75, base))


# --- §1 Defense ----------------------------------------------------------------

## Defense just nu: Defense × aurornas faktorer, aldrig under 20 % av startvärdet.
static func defense_now(def: float, start_def: float, factors: Array) -> float:
	var m := 1.0
	for f in factors:
		m *= float(f)
	return maxf(def * m, start_def / 5.0)


# --- §7 Helning ----------------------------------------------------------------

## Helning: Int × styrka × variation, sedan modifierarna, avrundat.
static func heal(intel: float, power: float, roll: float, factors: Array) -> float:
	return roundf(intel * power * roll * mods(factors))


## strid-langd: en fiendes n:te helning med samma förmåga (n = tidigare helningar) helar 1 − fade · n, minst min.
static func heal_fade(n: int, fade: float, min_mult: float) -> float:
	if fade <= 0.0 or n <= 0:
		return 1.0
	return maxf(min_mult, 1.0 - fade * n)


# --- §1 Stats -------------------------------------------------------------------

## 0.26: stats avrundas till en decimal (talen delades med 10), Speed till heltal.
static func stat_round(v: float, stat := "") -> float:
	return roundf(v) if stat == "speed" else roundf(v * 10.0) / 10.0


## Nivåns takt (VD 2026-10-25, variant C): nivå L är tillväxtnivån g(L) = L upp till 5, sedan 5 + 2,34 · (L − 5)^1,4.
## Den styr erfarenheten och fiendernas nivå, inte längre styrkan.
static func growth_level(level: float) -> float:
	var l := maxf(level, 1.0)
	return l if l <= 5.0 else 5.0 + 2.34 * pow(l - 5.0, 1.4)


## Styrkan per nivå (balans v1): +20 % mot nivån innan för nivå 2–10, sedan 13 % + 7 % · e^(−(n − 10)/10); mellan två
## nivåer geometriskt.
static func level_step(n: int) -> float:
	return 0.20 if n <= 10 else 0.13 + 0.07 * exp(-(n - 10) / 10.0)


static func strength(level: float) -> float:
	var l := maxf(level, 1.0)
	var lo := int(floor(l))
	var m := 1.0
	for k in range(2, lo + 1):
		m *= 1.0 + level_step(k)
	return m * pow(1.0 + level_step(lo + 1), l - lo)


## En stat på en nivå: bas × (1 + tillväxt / 30 % × (styrkan − 1)), tillväxt 30 % (personlighet 40/20 %), avrundat.
static func level_stat(base: float, level: int, growth: float, stat := "") -> float:
	return stat_round(base * (1.0 + growth / 0.3 * (strength(level) - 1.0)), stat)


## Artefaktnivåns styrka: +10 % per nivå över 1 (nivå 1–10).
static func art_level_mult(level: int) -> float:
	return 1.0 + 0.1 * (clampi(level, 1, 10) - 1)


# --- §9 Fiender ---------------------------------------------------------------

## Djupet: +15 % per djup över 1 (Health, Attack, Intelligence, Defense; inte Speed; balans v1).
static func depth_mult(depth: int) -> float:
	return 1.0 + 0.15 * (maxi(depth, 1) - 1)


## Fiendernas tillväxtnivå: 5 × (djup − 1) + 2,25 + 1,5 per våning (stats växer med den, som förut).
static func enemy_growth_level(depth: int, floor_i: int) -> float:
	return 5.0 * (maxi(depth, 1) - 1) + 2.25 + 1.5 * clampi(floor_i, 0, 2)


## Fiendernas nivå som den visas: omvändningen av growth_level.
static func enemy_level(depth: int, floor_i: int) -> float:
	var x := enemy_growth_level(depth, floor_i)
	return x if x <= 5.0 else 5.0 + pow((x - 5.0) / 2.34, 1.0 / 1.4)


## Sällskapets storlek (0.23.3, vårt val): 1–4 hjältar.
static func party_scale(n: int) -> float:
	return [0.45, 0.45, 0.54, 0.64, 1.0][clampi(n, 1, 4)]


## Portalens strid (×1,15) och profilens första nedstigning (0.24.1, vårt val: en trappa per våning, ×0,70 / ×0,88 /
## ×0,83 för Benfursten); båda kan gälla.
static func battle_bonus(portal: bool, first_descent: bool, floor_i := 0, alone := false) -> float:
	var ramp: float = [0.70, 0.88, 0.83][clampi(floor_i, 0, 2)] * (0.80 if alone else 1.0) if first_descent else 1.0
	return (1.15 if portal else 1.0) * ramp


## Fienderna som möter ett sällskap (0.23.3, vårt val): högst en fler än hjältarna. Först försvinner dubbletter, sedan
## andra, alltid den sista som får försvinna. Kvar blir alltid den första (våningens ledare), bossar och en fiende som
## en annan i mötet behöver för att vara immun.
static func lineup(enemies: Dictionary, traits: Dictionary, kinds: Array, party: int) -> Array:
	var out := kinds.duplicate()
	var cap := maxi(party, 1) + 1
	for dupes_only in [true, false]:
		while out.size() > cap:
			var gone := -1
			for i in range(out.size() - 1, 0, -1):
				var k: String = out[i]
				if enemies[k].get("boss", false):
					continue
				if out.count(k) > 1:
					gone = i
					break
				if dupes_only:
					continue
				var needed := false
				for j in out.size():
					for t in enemies[out[j]].get("traits", []):
						if j != i and traits.get(t, {}).get("modify", {}).get("immune_while_ally_kind", "") == k:
							needed = true
				if not needed:
					gone = i
					break
			if gone < 0:
				break
			out.remove_at(gone)
	return out


## En fiendes stats steg för steg, i samma ordning som dokumentet: bas × möte × djup × Portal/första nedstigningen
## (avrundat), × sällskapets
## storlek (avrundat, inte Defense), × nivå (avrundat, även Speed), elit +25 % Health och +10 % Attack och Int.
static func enemy_stats(base: Dictionary, stat_mult: float, depth: int, party: int, level: float, elite: bool,
		with_level: bool, bonus := 1.0) -> Dictionary:
	var s := {"health": float(base.health), "attack": float(base.attack),
			"intelligence": float(base.get("intelligence", base.attack)), "defense": float(base.get("defense", 0.0)),
			"speed": float(base.get("speed", 10.0))}
	var m := stat_mult * depth_mult(depth) * bonus
	if absf(m - 1.0) > 1e-9:
		for k in ["health", "attack", "intelligence", "defense"]:
			s[k] = stat_round(s[k] * m)
	var p := party_scale(party)
	if p != 1.0:
		for k in ["health", "attack", "intelligence"]:
			s[k] = stat_round(s[k] * p)
	if with_level:
		var lm := strength(level)
		if absf(lm - 1.0) > 1e-9:
			for k in ["health", "attack", "intelligence", "defense"]:
				s[k] = stat_round(s[k] * lm)
		s.speed = roundf(s.speed * lm)
	if elite:
		s.health = stat_round(s.health * 1.25)
		s.attack = stat_round(s.attack * 1.1)
		s.intelligence = stat_round(s.intelligence * 1.1)
	return s
