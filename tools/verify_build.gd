extends SceneTree


func _init() -> void:
	var output: Array[String] = []
	var project_root := ProjectSettings.globalize_path("res://")
	var arguments := PackedStringArray([
		"--headless",
		"--path",
		project_root,
		"--scene",
		"res://tools/verify_scene.tscn",
		"--quit-after",
		"1"
	])
	var exit_code: int = OS.execute(OS.get_executable_path(), arguments, output, true)
	var saw_success := false
	var child_reported_failure := exit_code != 0

	var child_report := "\n".join(output)
	for raw_line in child_report.split("\n"):
		var line := raw_line.strip_edges()
		if line.is_empty():
			continue
		print(line)
		if line == "VERIFY OK":
			saw_success = true
		if line.contains("SCRIPT ERROR") or line.contains("ERROR:") or line.contains("WARNING:"):
			child_reported_failure = true

	if not saw_success:
		child_reported_failure = true

	quit(1 if child_reported_failure else 0)
