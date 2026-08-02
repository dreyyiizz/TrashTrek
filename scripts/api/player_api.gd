extends ApiService

var player_stats: PlayerStatsResource = PlayerStatsResource.get_instance()

#region Get User

func get_user() -> Dictionary:
	var endpoint: String = "/player/" + player_stats.get_device_id()
	if not is_configured():
		return _emit_failure("get_user", ApiService.offline_error(endpoint))
	return await _make_request(endpoint, HTTPClient.METHOD_GET, default_headers, null, _on_get_user)

signal get_user_success(result: Dictionary)
signal get_user_failed(err: Dictionary)

func _on_get_user(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, endpoint: String):
	var res = handle_data_complete(result, response_code, headers, body, endpoint)
	_handle_and_emit("get_user", res)

#endregion


#region Create User

func create_user(new_player_stats: Dictionary) -> Dictionary:
	var endpoint: String = "/player"
	if not is_configured():
		return _emit_failure("create_user", ApiService.offline_error(endpoint))
	return await _make_request(endpoint, HTTPClient.METHOD_POST, default_headers, new_player_stats, _on_create_user)

signal create_user_success(result: Dictionary)
signal create_user_failed(err: Dictionary)

func _on_create_user(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, endpoint: String):
	var res = handle_data_complete(result, response_code, headers, body, endpoint)
	_handle_and_emit("create_user", res)

#endregion


#region Update User

func update_user(new_player_stats: Dictionary) -> Dictionary:
	var endpoint: String = "/player/" + player_stats.get_device_id()
	if not is_configured():
		return _emit_failure("update_user", ApiService.offline_error(endpoint))
	return await _make_request(
		endpoint,
		HTTPClient.METHOD_PATCH,
		default_headers,
		new_player_stats,
		_on_update_user
	)

signal update_user_success(result: Dictionary)
signal update_user_failed(err: Dictionary)

func _on_update_user(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, endpoint: String):
	var res = handle_data_complete(result, response_code, headers, body, endpoint)
	_handle_and_emit("update_user", res)

#endregion


#region Get Top Five

func get_top_five() -> Dictionary:
	var endpoint: String = "/top-five"
	if not is_configured():
		return _emit_failure("get_top_five", ApiService.offline_error(endpoint))
	return await _make_request(
		endpoint,
		HTTPClient.METHOD_GET,
		default_headers,
		null,
		_on_get_top_five
	)

signal get_top_five_success(result: Array)
signal get_top_five_failed(err: Dictionary)

func _on_get_top_five(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, endpoint: String):
	var res = handle_data_complete(result, response_code, headers, body, endpoint)
	_handle_and_emit("get_top_five", res)

#endregion


#region Delete User

func delete_user() -> Dictionary:
	var endpoint: String = "/player/" + player_stats.get_device_id()
	if not is_configured():
		return _emit_failure("delete_user", ApiService.offline_error(endpoint))
	return await _make_request(
		endpoint,
		HTTPClient.METHOD_DELETE,
		default_headers,
		null,
		_on_delete_user
	)

signal delete_user_success(is_success: bool)
signal delete_user_failed(err: Dictionary)

func _on_delete_user(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, endpoint: String):
	var res = handle_data_complete(result, response_code, headers, body, endpoint)
	_handle_and_emit("delete_user", res)

#endregion


# Shared handler to keep structure consistent across API classes
func _handle_and_emit(op: String, res: Variant, update_local: bool = true) -> void:
	print(op)
	if res.get("ok", false):
		if update_local:
			_apply_to_resource(op, res.get("data", {}))
		match op:
			"get_user":
				get_user_success.emit(res.get("data", {}))
			"create_user":
				create_user_success.emit(res.get("data", {}))
			"update_user":
				update_user_success.emit(res.get("data", {}))
			"get_top_five":
				get_top_five_success.emit(res.get("data", []))
			"delete_user":
				delete_user_success.emit(bool(res.get("data", true)))
			_:
				# For future operations, default to base signal if added
				pass
	else:
		var error_data: Dictionary = res.get("data", {})
		match op:
			"get_user":
				get_user_failed.emit(error_data)
			"create_user":
				create_user_failed.emit(error_data)
			"update_user":
				update_user_failed.emit(error_data)
			"get_top_five":
				get_top_five_failed.emit(error_data)
			"delete_user":
				delete_user_failed.emit(error_data)
			_:
				pass


# Apply successful responses to the bound resource
func _apply_to_resource(op: String, data: Variant) -> void:
	if player_stats == null or not data is Dictionary:
		return
	print_debug("Applying to resource: " + op)
	match op:
		"get_user", "create_user":
			# Both endpoints return a full player payload
			player_stats.compare_to_resource(data)
		_:
			pass


func _emit_failure(op: String, error: Dictionary) -> Dictionary:
	match op:
		"get_user":
			get_user_failed.emit(error)
		"create_user":
			create_user_failed.emit(error)
		"update_user":
			update_user_failed.emit(error)
		"get_top_five":
			get_top_five_failed.emit(error)
		"delete_user":
			delete_user_failed.emit(error)
	return error
