extends Control


@onready var delete_dialog = $"%DeleteDialog"
@onready var restart_dialog = $"%RestartDialog"
@onready var retry_dialog = $%DeleteRetryDialog
@onready var dialog = $%Dialog

@onready var name_label: Label = $%Name
@onready var name_edit: TextEdit = $%NameEdit
@onready var edit_button: Button = $EditButton
var editing = false

var player_stats_resource: PlayerStatsResource = PlayerStatsResource.get_instance()

func _ready() -> void:
	restart_dialog.add_button("Quit", true, "quit_game")
	retry_dialog.add_button("Restart Game", true, "restart_game")

	PlayerApi.update_user_success.connect(_on_update_user_success)
	PlayerApi.update_user_failed.connect(_on_update_user_failed)

	PlayerApi.delete_user_failed.connect(show_delete_error)
	PlayerApi.delete_user_success.connect(open_restart_dialog)
	reset_name_display()
	reset_name_edit_placeholder_text()


func _on_return_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_delete_pressed() -> void:
	delete_dialog.visible = true

func _on_delete_dialog_confirmed() -> void:
	player_stats_resource.delete_account()

func show_delete_error(err: Dictionary):
	var message = ApiService.parse_error_message(err)
	retry_dialog.dialog_text = "%s. Restart game?" % message
	retry_dialog.visible = true

func _on_delete_retry_dialog_confirmed() -> void:
	get_tree().change_scene_to_file("res://scenes/intro/input_name.tscn")

func _on_retry_dialog_custom_action(action: StringName) -> void:
	if action == "restart_game":
		_restart_game()
	
func open_restart_dialog(_is_success: bool):
	restart_dialog.visible = true

func _on_restart_dialog_custom_action(action: StringName) -> void:
	if action == "quit_game":
		get_tree().quit()

func _on_restart_dialog_confirmed() -> void:
	_restart_game()

func _restart_game():
	get_tree().change_scene_to_file("res://scenes/intro/input_name.tscn")
	

func _on_edit_button_pressed() -> void:
	if editing:
		var new_name: String = name_edit.text.strip_edges()
		if new_name.is_empty():
			dialog.dialog_text = "Error: Name must be at least 1 character long"
			dialog.visible = true
			return

		player_stats_resource.update_name(new_name)
		if not PlayerApi.is_configured():
			dialog.dialog_text = "Name changed to: %s" % player_stats_resource.name
			_finish_local_name_update()
			dialog.visible = true
			return

		edit_button.text = "Loading"
		return
	
	toggle_edit_name()

func toggle_edit_name():
	editing = !editing
	name_label.visible = !editing
	name_edit.visible = editing
	$%CancelEditButton.visible = editing
	edit_button.text = "Save" if editing else "Edit"

func _on_update_user_success(result: Dictionary) -> void:
	print_debug("Update user success: %s" % result)
	dialog.dialog_text = "Name changed to: %s" % result.get("name", player_stats_resource.name)
	_finish_local_name_update()
	dialog.visible = true


func _finish_local_name_update() -> void:
	reset_name_display()
	reset_name_edit_placeholder_text()
	if editing:
		toggle_edit_name()

func _on_update_user_failed(err: Dictionary) -> void:
	var message = ApiService.parse_error_message(err)
	print_debug("❌ Parsed error message: %s" % message)
	if message.contains("string_too_short"):
		dialog.dialog_text = "Error: Name must be at least 1 character long"
	else:
		dialog.dialog_text = message
	reset_name_edit_placeholder_text()
	dialog.visible = true
	toggle_edit_name()

func _on_cancel_edit_button_pressed() -> void:
	toggle_edit_name()
	reset_name_edit_placeholder_text()

func reset_name_display():
	name_label.text = player_stats_resource.name

func reset_name_edit_placeholder_text():
	$%NameEdit.placeholder_text = player_stats_resource.name
