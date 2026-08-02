extends Resource

class_name PlayerStatsResource

@export var device_id: String
@export var name: String
@export var coins: int
@export var high_score: float
@export var upgrades: Dictionary = {}
@export var skins: Array = ["Default"]
@export var current_skin: String = "Default"
@export var lastModified: String

const SAVE_PATH = "user://device_id.save"
const PLAYER_STATS_SAVE_PATH = "user://player_stats.tres"

signal coins_updated(value: int)

static func get_instance() -> PlayerStatsResource:
	if not ResourceLoader.exists(PLAYER_STATS_SAVE_PATH):
		ResourceSaver.save(PlayerStatsResource.new(), PLAYER_STATS_SAVE_PATH)
	return ResourceLoader.load(PLAYER_STATS_SAVE_PATH)

func _ready() -> void:
	pass

#region Information
func to_dict() -> Dictionary:
	return {
		"device_id": device_id,
		"name": name,
		"coins": coins,
		"high_score": high_score,
		"upgrades": upgrades,
		"skins": skins,
		"current_skin": current_skin,
		"lastModified": lastModified
	}

func get_device_id():
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var saved_id = file.get_line()
		file.close()
		return saved_id
	else:
		var new_id = str(OS.get_unique_id())
		var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		save_file.store_line(new_id)
		save_file.close()
		return new_id

#endregion

#region Saving
func _update_last_modified() -> void:
	lastModified = Time.get_datetime_string_from_datetime_dict(Time.get_datetime_dict_from_system(true), false)
	_save()

func _save() -> void:
	var save_error := ResourceSaver.save(self, PLAYER_STATS_SAVE_PATH)
	if save_error != OK:
		push_error("Failed to save player stats: %s" % save_error)

func compare_to_resource(player_stats: Dictionary) -> void:
	var db_last_modified = Time.get_unix_time_from_datetime_string(player_stats.get("lastModified"))
	var local_last_modified = Time.get_unix_time_from_datetime_string(lastModified)

	print_debug("%s\n%s" % [db_last_modified, local_last_modified])
	print_debug("DB last modified >= local last modified: %s" % (db_last_modified >= local_last_modified))
	if db_last_modified >= local_last_modified:
		save_stats(player_stats)
	else:
		save_to_database()

func save_stats(player_stats: Dictionary) -> void:
	device_id = player_stats.get("device_id", device_id)
	name = player_stats.get("name", name)
	coins = player_stats.get("coins", coins)
	high_score = player_stats.get("high_score", high_score)
	upgrades = player_stats.get("upgrades", upgrades)
	skins = player_stats.get("skins", skins)
	current_skin = player_stats.get("current_skin", current_skin)
	lastModified = player_stats.get("lastModified", lastModified)
	_save()

func save_name(new_name: String) -> void:
	name = new_name.strip_edges()
	_update_last_modified()

func update_name(new_name: String):
	save_name(new_name)
	save_to_database()

func increment_coins(increment: int) -> void:
	coins += increment
	coins_updated.emit(coins)
	_update_last_modified()

func decrement_coins(decrement: int) -> void:
	coins -= decrement
	coins_updated.emit(coins)
	_update_last_modified()

func update_high_score(new_high_score: float) -> void:
	high_score = max(high_score, new_high_score)
	_update_last_modified()

#endregion

#region Upgrades
func get_upgrades() -> Dictionary:
	return upgrades

func upgrade_stat(upgrade: UpgradeResource) -> String:
	var player_upgrade = upgrades.get(upgrade.name)
	
	if not player_upgrade:
		if coins < upgrade.base_price:
			return "Not enough coins"
		decrement_coins(upgrade.base_price)
		upgrades[upgrade.name] = {
			"level": 2,
		}
		save_to_database()
		return ""
	
	var cost = upgrade.base_price * upgrade.price_per_level_multiplier * player_upgrade.level
	
	if coins < cost:
		return "Not enough coins"

	if player_upgrade.level >= upgrade.max_level:
		printerr("Upgrade %s is already at max level" % upgrade.name)
		return "Max level upgrade"
	
	decrement_coins(cost)
	upgrades[upgrade.name]["level"] += 1
	save_to_database()
	return ""

func find_upgrade(upgrade_name: String) -> Dictionary:
	for upgrade in upgrades:
		if upgrade == upgrade_name:
			return upgrades[upgrade]
	return {}
#endregion

#region skins
func get_skins() -> Array:
	return skins

func buy_skin(skin_resource: SkinResource) -> String:
	if coins < skin_resource.base_price:
		return "Not enough coins"
	
	skins.append(skin_resource.name)
	decrement_coins(skin_resource.base_price)
	save_to_database()
	return ""

func find_skin(skin_name: String) -> int:
	return skins.find(skin_name)

signal equipped_skin_changed()
func equip_skin(skin_name: String) -> String:
	current_skin = skin_name
	equipped_skin_changed.emit()
	save_to_database()
	return ""

func get_equipped_skin() -> String:
	return current_skin
#endregion

#region creating user
func create_user(new_name: String) -> void:
	name = new_name.strip_edges()
	device_id = get_device_id()
	lastModified = Time.get_datetime_string_from_datetime_dict(Time.get_datetime_dict_from_system(true), false)
	_save()

	if not PlayerApi.is_configured():
		return

	print_debug("Creating player resource: %s" % to_dict())
	if not PlayerApi.create_user_success.is_connected(_on_create_user_success):
		PlayerApi.create_user_success.connect(_on_create_user_success)
	PlayerApi.create_user(to_dict())

func _on_create_user_success(result: Dictionary) -> void:
	print_debug("Create user success: %s" % result)
	save_stats(result)
#endregion


#region Saving to Database
func save_to_database() -> void:
	var final_dict = self.to_dict().duplicate()
	print_debug("Saving to database: %s" % final_dict)
	_save()

	if not PlayerApi.is_configured():
		return

	final_dict.erase("lastModified")
	final_dict.erase("device_id")
	
	if not PlayerApi.update_user_success.is_connected(_on_update_user_success):
		PlayerApi.update_user_success.connect(_on_update_user_success)
	PlayerApi.update_user(final_dict)

func _on_update_user_success(result: Dictionary) -> void:
	print_debug("Update user success: %s" % result)
	var new_last_modified := str(result.get("lastModified", ""))
	if not new_last_modified.is_empty() and (lastModified.is_empty() or new_last_modified > lastModified):
		lastModified = new_last_modified
		_save()

#endregion

#region Delete Account
func delete_account() -> void:
	if not PlayerApi.is_configured():
		_reset_local_profile()
		PlayerApi.delete_user_success.emit(true)
		return

	if not PlayerApi.delete_user_success.is_connected(_on_delete_user_success):
		PlayerApi.delete_user_success.connect(_on_delete_user_success)
	PlayerApi.delete_user()

func _on_delete_user_success(_is_success: bool) -> void:
	_reset_local_profile()


func _reset_local_profile() -> void:
	device_id = get_device_id()
	name = ""
	coins = 0
	high_score = 0.0
	upgrades = {}
	skins = ["Default"]
	current_skin = "Default"
	lastModified = ""
	_save()
#endregion
