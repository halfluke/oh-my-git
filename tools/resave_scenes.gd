extends SceneTree

const SCENES := [
	"res://scenes/no_git.tscn",
	"res://scenes/node.tscn",
	"res://scenes/notification.tscn",
	"res://scenes/cli_badge.tscn",
	"res://scenes/survey.tscn",
	"res://scenes/arrow.tscn",
	"res://scenes/tcp_server.tscn",
	"res://scenes/card_particles.tscn",
	"res://scenes/tcp_server_shell.tscn",
	"res://scenes/music_button.tscn",
]

func _initialize() -> void:
	var failed: Array[String] = []
	for path in SCENES:
		var packed: PackedScene = load(path)
		if packed == null:
			failed.append("%s: load failed" % path)
			continue
		var err := ResourceSaver.save(packed, path)
		if err != OK:
			failed.append("%s: save failed (%s)" % [path, error_string(err)])
		else:
			print("Resaved ", path)
	if failed.size() > 0:
		for line in failed:
			push_error(line)
		quit(1)
	quit()
