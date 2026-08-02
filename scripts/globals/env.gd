extends Node

var data: Dictionary = {}


func get_data() -> Dictionary:
	if not data.is_empty():
		return data

	if not FileAccess.file_exists("res://.env"):
		return data

	var file := FileAccess.open("res://.env", FileAccess.READ)
	if file == null:
		return data

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue

		var separator_index := line.find("=")
		if separator_index <= 0:
			continue

		var key := line.substr(0, separator_index).strip_edges()
		if key.is_empty():
			continue

		var value := line.substr(separator_index + 1).strip_edges()
		if value.length() >= 2:
			var is_double_quoted := value.begins_with("\"") and value.ends_with("\"")
			var is_single_quoted := value.begins_with("'") and value.ends_with("'")
			if is_double_quoted or is_single_quoted:
				value = value.substr(1, value.length() - 2)
		data[key] = value

	file.close()
	return data
