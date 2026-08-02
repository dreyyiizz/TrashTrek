extends Node

const LEGACY_RIVER_TERRAIN := "res://scenes/terrains/RiverTerrain.tscn"
const LEGACY_RESOURCES := ["res://tile_map.tres"]
const AUTHORING_VIEWPORT := Vector2i(1152, 648)
const DEMO_WINDOW := Vector2i(1280, 720)

const REQUIRED_SCENES := [
	"res://scenes/intro/input_name.tscn",
	"res://scenes/intro.tscn",
	"res://scenes/MainMenu.tscn",
	"res://scenes/Main.tscn",
	"res://scenes/shop/shop_interface.tscn",
	"res://scenes/profile/profile.tscn",
	"res://scenes/leaderboards.tscn",
	"res://scenes/terrains/Start.tscn",
	"res://scenes/terrains/Terrain1.tscn",
	"res://scenes/terrains/Terrain2.tscn",
	"res://scenes/terrains/Terrain3.tscn",
	"res://scenes/terrains/Terrain4.tscn",
	"res://scenes/terrains/Terrain5.tscn",
	"res://scenes/terrains/Terrain6.tscn",
	"res://scenes/terrains/Terrain7.tscn",
	"res://scenes/scene_transition.tscn",
	"res://scenes/pause_menu.tscn",
	"res://scenes/game_menu.tscn",
	"res://scenes/ui.tscn",
	"res://audios/audio_manager.tscn"
]

const REQUIRED_RESOURCES := [
	"res://Button.tres",
	"res://scenes/ui.tres"
]

var failures: Array[String] = []
var loaded_paths: Dictionary = {}
var verification_exit_code := 0


func _ready() -> void:
	_verify_display_configuration()

	for path in REQUIRED_SCENES:
		_load_resource_once(path, true)

	for path in REQUIRED_RESOURCES:
		_load_resource_once(path, false)

	for path in _collect_files("res://scenes", ".tscn"):
		if path != LEGACY_RIVER_TERRAIN:
			_load_resource_once(path, true)

	for path in _collect_files("res://resources", ".tres"):
		_load_resource_once(path, false)

	for path in _collect_files("res://", ".tres"):
		if path not in LEGACY_RESOURCES:
			_load_resource_once(path, false)

	for path in _collect_files("res://scripts", ".gd"):
		_load_resource_once(path, false)

	await _verify_offline_api_contract()

	if failures.is_empty():
		print("VERIFY OK")
	else:
		for failure in failures:
			push_error(failure)
		verification_exit_code = 1

	call_deferred("_finish")


func _verify_display_configuration() -> void:
	var viewport := Vector2i(
		int(ProjectSettings.get_setting("display/window/size/viewport_width", -1)),
		int(ProjectSettings.get_setting("display/window/size/viewport_height", -1))
	)
	var window_override := Vector2i(
		int(ProjectSettings.get_setting("display/window/size/window_width_override", -1)),
		int(ProjectSettings.get_setting("display/window/size/window_height_override", -1))
	)
	if viewport != AUTHORING_VIEWPORT:
		failures.append("Viewport is %s; authored game canvas is %s" % [viewport, AUTHORING_VIEWPORT])
	if window_override != DEMO_WINDOW:
		failures.append("Window override is %s; demo window is %s" % [window_override, DEMO_WINDOW])


func _verify_offline_api_contract() -> void:
	var previous_env_data: Dictionary = Env.data.duplicate()
	var previous_base_url: String = PlayerApi.base_url
	var child_count_before := PlayerApi.get_child_count()
	Env.data = {"SERVER_URL": ""}
	PlayerApi.base_url = ""

	var get_user_result: Variant = await PlayerApi.get_user()
	_assert_offline_response("get_user", get_user_result, child_count_before)
	var update_user_result: Variant = await PlayerApi.update_user({})
	_assert_offline_response("update_user", update_user_result, child_count_before)
	var leaderboard_result: Variant = await PlayerApi.get_top_five()
	_assert_offline_response("get_top_five", leaderboard_result, child_count_before)
	var delete_user_result: Variant = await PlayerApi.delete_user()
	_assert_offline_response("delete_user", delete_user_result, child_count_before)

	Env.data = previous_env_data
	PlayerApi.base_url = previous_base_url


func _assert_offline_response(operation: String, response: Variant, child_count_before: int) -> void:
	if not response is Dictionary or not response.get("offline", false) or response.get("code") != "OFFLINE":
		failures.append("%s did not return a structured offline response" % operation)
	if PlayerApi.get_child_count() != child_count_before:
		failures.append("%s created an HTTPRequest while offline" % operation)


func _finish() -> void:
	var game_node := get_tree().root.get_node_or_null("Game")
	if game_node != null:
		var energy_timer = game_node.get("energy_timer")
		if energy_timer is Timer and is_instance_valid(energy_timer):
			energy_timer.stop()
			energy_timer.queue_free()
			game_node.set("energy_timer", null)
	await get_tree().process_frame
	get_tree().quit(verification_exit_code)


func _load_resource_once(path: String, _is_scene: bool) -> void:
	if loaded_paths.has(path):
		return
	loaded_paths[path] = true

	var resource = ResourceLoader.load(path)
	if resource == null:
		failures.append("Could not load %s" % path)
		return


func _collect_files(root_path: String, extension: String) -> Array[String]:
	var paths: Array[String] = []
	var directory := DirAccess.open(root_path)
	if directory == null:
		failures.append("Could not scan %s" % root_path)
		return paths

	directory.list_dir_begin()
	var file_name := directory.get_next()
	while not file_name.is_empty():
		if not file_name.begins_with("."):
			var child_path := root_path.path_join(file_name)
			if directory.current_is_dir():
				paths.append_array(_collect_files(child_path, extension))
			elif file_name.get_extension().to_lower() == extension.trim_prefix(".").to_lower():
				paths.append(child_path)
		file_name = directory.get_next()
	directory.list_dir_end()
	return paths
