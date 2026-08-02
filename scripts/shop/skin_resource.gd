extends Resource

class_name SkinResource

var player_stats_resource: PlayerStatsResource = PlayerStatsResource.get_instance()

@export var name: String
@export var base_price: int
@export var texture_tilemap: Texture

static func find_instance(skin_name: String) -> SkinResource:
	var file_name := skin_name.strip_edges().to_lower().replace(" ", "_")
	return ResourceLoader.load("res://resources/shop/skins/%s.tres" % file_name)
