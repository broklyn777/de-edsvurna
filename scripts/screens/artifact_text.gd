class_name ArtifactText
extends RefCounted
## Text för en artefakt i basen ("Sköld: Helande ljus").


static func name_of(data: Dictionary, art: Dictionary) -> String:
	if art.is_empty():
		return "Ingen artefakt"
	var name: String = data.artifacts[art.type].name
	if art.get("ability", "") != "":
		name += ": " + data.abilities[art.ability].name
	return name
