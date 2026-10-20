class_name Help
extends RefCounted
## Hjälprutorna (0.25, docs/plan/0.25-berattelsen.md §3, Siralims "?"-rutor): första gången man möter ett system
## visas en ruta som förklarar det, en gång per profil (Profile.help_seen). Texterna står i data/help.json; alla går
## att läsa igen i Broder Alriks handbok. Ren logik; HelpBox ritar.


static func entry(data: Dictionary, id: String) -> Dictionary:
	return data.get("help", {}).get("entries", {}).get(id, {})


## Handbokens ordning.
static func order(data: Dictionary) -> Array:
	return data.get("help", {}).get("order", [])


## Rutorna av ids som profilen inte har sett än (i den ordningen). Markerar dem som sedda.
static func take(data: Dictionary, profile: Profile, ids: Array) -> Array:
	var out := []
	for id in ids:
		if not entry(data, id).is_empty() and not profile.help_seen.has(id):
			profile.help_seen.append(id)
			out.append(id)
	return out
