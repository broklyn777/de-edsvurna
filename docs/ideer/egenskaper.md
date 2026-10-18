# Idé: Egenskaper (traits) – djup à la Siralim

> **Status: sparad idé, inte påbörjad.** Ledstjärnan gäller fortfarande:
> första striden ska kännas skön först. Det här är vad som kan komma *efter*.

## Kärnan i en mening

En **egenskap** är en regel som lyssnar på en händelse i striden och svarar med en effekt.
Djupet uppstår när en egenskaps effekt blir en annan egenskaps händelse – kedjor som
spelaren själv upptäcker.

## Varför det passar motorn vi redan har

`CombatSim` skickar redan ut händelser (`damage`, `heal`, `aura_applied`, `cast_end`,
`death` …) och förmågor beskriver redan sina effekter som data (`damage`, `heal`, `aura`).
En egenskap är alltså bara: **"när händelse X sker och villkor Y gäller → kör effekt Z"**,
där Z använder samma effektformat som `abilities.json`. Inget nytt språk behövs.

## Föreslaget format: `data/traits.json`

```json
{
	"bulwark_echo": {
		"name": "Ekande bålverk",
		"text": "När en allierad tar skada får hjälten 40 i sköld (högst en gång per 2 s).",
		"trigger": "damage",
		"when": {"target": "ally", "not_self": true},
		"internal_cooldown": 2,
		"effects": [
			{"type": "shield", "amount": 40, "target": "self"}
		]
	},
	"spiked_ward": {
		"name": "Taggigt värn",
		"text": "Varje gång hjälten får en sköld slår den närmaste fiende för 30 skada.",
		"trigger": "shield_gained",
		"when": {"target": "self"},
		"effects": [
			{"type": "damage", "min": 30, "max": 30, "school": "physical", "target": "enemy"}
		]
	},
	"martyr": {
		"name": "Martyr",
		"text": "Helningar hjälten gör på andra kostar 10 % av hjältens eget liv men helar 40 % mer.",
		"trigger": "modify_heal",
		"when": {"source": "self", "not_self": true},
		"modify": {"amount_mult": 1.4, "self_cost_hp_pct": 0.10}
	},
	"last_stand": {
		"name": "Sista striden",
		"text": "Under 30 % liv: +25 % skada.",
		"trigger": "passive",
		"when": {"self_hp_below": 0.30},
		"stats": {"damage_mult": 1.25}
	}
}
```

`bulwark_echo` + `spiked_ward` på samma hjälte = varje träff på partyt slår tillbaka mot bossen.
Det är den sortens "aha" som gör Siralim beroendeframkallande.

### Fyra sorters egenskaper

| Sort | Exempel | Hur simulatorn kör den |
|---|---|---|
| `trigger` på händelse | "När X skadas …" | Efter varje händelse: hitta egenskaper som lyssnar på den typen |
| `modify_*` | "Helningar helar 40 % mer" | Körs *innan* händelsen skapas, ändrar siffror |
| `passive` med villkor | "Under 30 % liv …" | Räknas in i statistik varje tick |
| `aura`-givande | "Start: alla får Bloodlust 5 s" | Trigger `fight_start` + befintlig aura-effekt |

## Säkerhetsräcken (lärdom från Siralim)

- **Oändliga kedjor:** en egenskap får inte trigga på händelser den själv orsakat
  (varje händelse bär `origin_trait`), och kedjedjupet kapas vid t.ex. 5.
- **Inre nedkylning** (`internal_cooldown`) på allt som triggar ofta.
- **Läsbarhet först (WoW-pelaren):** varje egenskap som triggar ger en liten synlig
  signal i `battle.gd` – en ikon som blinkar över hjälten – så att spelaren *ser* kombon.
- **Botarna testar:** `tests/combat_bot.gd` kan köra alla par av egenskaper och flagga
  kombinationer som gör striden trivial eller omöjlig.

## Hur hjältar får egenskaper (senare)

- Varje hjälte har 1 medfödd egenskap (i `heroes.json`: `"traits": ["bulwark_echo"]`).
- Plats för 1–2 till som spelaren väljer – från bossbyten, eller genom att "lära sig"
  en egenskap från en besegrad fiende (Siralims smältning, i vår tappning).
- Bossar kan ha egenskaper i samma format – då kan spelaren stjäla dem.

## Ordning om/när vi börjar

1. `traits.json` + koppling i `CombatSim`, bara `trigger`-sorten, 3–4 egenskaper.
2. Synlig signal i striden när en egenskap triggar.
3. Bot-test som kör alla kombinationer mot Bone Lich.
4. Först därefter: val av egenskaper mellan strider.
