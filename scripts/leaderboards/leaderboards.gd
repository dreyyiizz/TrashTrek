extends Control


@onready var display = $Display
@onready var status_label: Label = $Status

func _ready() -> void:
	if not PlayerApi.get_top_five_success.is_connected(_on_get_top_five_success):
		PlayerApi.get_top_five_success.connect(_on_get_top_five_success)
	if not PlayerApi.get_top_five_failed.is_connected(_on_get_top_five_failed):
		PlayerApi.get_top_five_failed.connect(_on_get_top_five_failed)
	PlayerApi.get_top_five()

func _on_get_top_five_success(result: Array) -> void:
	status_label.visible = false
	for player_idx in range(result.size()):
		var rank = preload("res://scenes/rank.tscn")
		var rank_node: LeaderboardRank = rank.instantiate()
		
		rank_node.player_name = result[player_idx].name
		rank_node.player_score = result[player_idx].high_score
		
		display.add_child(rank_node)
		
		
		var texture = load("res://assets/menu/leaderboards/rank%s.png" % (player_idx + 1))
		
		rank_node.rank_texture.texture = texture


func _on_get_top_five_failed(err: Dictionary) -> void:
	status_label.text = "Unavailable offline" if err.get("offline", false) else "Leaderboard unavailable"
	status_label.visible = true


func _on_return_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
