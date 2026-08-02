extends Node

class_name ApiService

var base_url: String = ""
@export var default_headers = PackedStringArray(["Content-Type: application/json"])

signal request_complete(endpoint: String, data: Dictionary)

func _ready() -> void:
	base_url = _read_server_url()


func _read_server_url() -> String:
	return str(Env.get_data().get("SERVER_URL", "")).strip_edges().trim_suffix("/")


func is_configured() -> bool:
	if base_url.is_empty():
		base_url = _read_server_url()
	return not base_url.is_empty()


static func offline_error(endpoint: String = "") -> Dictionary:
	return {
		"code": "OFFLINE",
		"offline": true,
		"endpoint": endpoint,
		"detail": {
			"type": "offline",
			"message": "Unavailable offline"
		}
	}


static func network_error(endpoint: String, error_code: int = -1) -> Dictionary:
	return {
		"code": "NETWORK_ERROR",
		"offline": false,
		"endpoint": endpoint,
		"error_code": error_code,
		"detail": {
			"type": "network_error",
			"message": "The server could not be reached"
		}
	}

func _handle_and_emit(op: String, res: Dictionary):
	printerr("Not implemented")

func _make_request(
	endpoint: String,
	method: HTTPClient.Method,
	headers: PackedStringArray,
	body: Variant,
	on_request_complete: Callable
) -> Dictionary:
	if not is_configured():
		return offline_error(endpoint)

	var http_request := HTTPRequest.new()
	http_request.request_completed.connect(on_request_complete.bind(endpoint))
	add_child(http_request)

	var final_headers = []
	for k in default_headers:
		final_headers.append(k)
	for k in headers:
		final_headers.append(k)

	var url = "%s%s" % [base_url, endpoint]
	var body_str: String = JSON.stringify(body) if typeof(body) == TYPE_DICTIONARY or typeof(body) == TYPE_ARRAY else ""

	var err = http_request.request(url, final_headers, method, body_str)
	if err != OK:
		var result := network_error(endpoint, err)
		on_request_complete.call(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray(), endpoint)
		http_request.queue_free()
		return result

	return {}

func handle_data_complete(
	_result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	endpoint: String
):
	var result = {"ok": false, "code": response_code, "data": {}}

	if _result != HTTPRequest.RESULT_SUCCESS:
		result.code = "NETWORK_ERROR"
		result.data = network_error(endpoint, _result)
		request_complete.emit(endpoint, result)
		return result

	var json = JSON.new()
	var response_is_valid := true
	if not body.is_empty():
		var parse_error := json.parse(body.get_string_from_utf8())
		if parse_error != OK:
			response_is_valid = false
			result.code = "INVALID_RESPONSE"
			result.data = {
				"detail": {
					"type": "invalid_response",
					"message": "The server returned an invalid response"
				}
			}
		else:
			result.data = json.data

	result.ok = response_is_valid and response_code >= 200 and response_code < 300
	if result.ok:
		print_debug("🌐 %s Success Response from %s: %s" % [response_code, endpoint, JSON.stringify(result.data, "\t")])
	else:
		print_debug("🌐 %s Error Response from %s: %s" % [response_code, endpoint, JSON.stringify(result.data, "\t")])

	request_complete.emit(endpoint, result)
	return result

static func parse_error_message(err: Dictionary, prefix: String = "Error") -> String:
	if not err.has("detail"):
		return "%s: Unknown error" % prefix
	
	var detail = err["detail"]
	
	if detail is Array:
		return _parse_array_error(detail, prefix)
	elif detail is Dictionary:
		return _parse_dictionary_error(detail, prefix)
	elif detail is String:
		return "%s: %s" % [prefix, detail]
	else:
		return "%s: Unknown error" % prefix

static func _parse_array_error(detail_array: Array, prefix: String) -> String:
	if detail_array.is_empty():
		return "%s: Unknown error" % prefix

	var first_error = detail_array[0]
	if not first_error is Dictionary:
		return "%s: Unknown error" % prefix

	if first_error.has("type"):
		return "%s: %s" % [prefix, str(first_error["type"])]
	elif first_error.has("message"):
		return "%s: %s" % [prefix, str(first_error["message"])]
	else:
		return "%s: Unknown error" % prefix

static func _parse_dictionary_error(detail_dict: Dictionary, prefix: String) -> String:
	if detail_dict.has("message"):
		return "%s: %s" % [prefix, str(detail_dict["message"])]
	else:
		return "%s: Unknown error" % prefix
