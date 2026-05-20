extends SceneTree

class MockFileItem:
	var file_status := {}

const SCENE_PATHS := [
	"res://scenes/title.tscn",
	"res://scenes/main.tscn",
	"res://scenes/game.tscn",
	"res://scenes/file_browser.tscn",
	"res://scenes/terminal.tscn",
	"res://scenes/card.tscn",
]

var _failures: Array[String] = []
var _passes := 0
var _cleanup_nodes: Array[Node] = []

func _initialize() -> void:
	call_deferred("_run_all")

func _run_all() -> void:
	print("=== Oh My Git automated tests ===")
	await _wait_for_game()
	await _test_build_config()
	await _test_project_and_scenes()
	await _test_cards_json()
	await _test_levels_parse()
	if _git_available():
		await _test_shell()
		await _test_file_browser()
	else:
		_skip("git not available; skipping shell and file browser integration tests")
	await _cleanup()
	_report_and_quit()

func _game() -> Node:
	return Engine.get_main_loop().root.get_node("game")

func _helpers() -> Node:
	return Engine.get_main_loop().root.get_node("helpers")

func _wait_for_game() -> void:
	var deadline := Time.get_ticks_msec() + 30000
	while Time.get_ticks_msec() < deadline:
		if _game().shell_environment_ready and _game().global_shell != null:
			return
		await create_timer(0.05).timeout
	_fail("game autoload did not become ready within 30s")

func _git_available() -> bool:
	var output: Array = []
	OS.execute("bash", ["-c", "command -v git >/dev/null && echo yes || echo no"], output, true)
	if output.is_empty():
		return false
	return String(output[0]).strip_edges() == "yes"

func _test_build_config() -> void:
	print("-- build config --")
	var workflow: String = _helpers().read_file("res://.github/workflows/build.yml")
	_assert(workflow.find("GODOT_VERSION: 4.3") != -1, "build.yml should target Godot 4.3")
	_assert(workflow.find("barichello/godot-ci:4.3") != -1, "build.yml should use godot-ci 4.3 image")

	var presets: String = _helpers().read_file("res://export_presets.cfg")
	for needle in [
		'name="Linux"',
		'platform="Linux"',
		'name="Windows"',
		'name="Mac OS"',
		'platform="macOS"',
		"script_export_mode=2",
	]:
		_assert(presets.find(needle) != -1, "export_presets.cfg missing %s" % needle)

	var makefile: String = _helpers().read_file("res://Makefile")
	_assert(makefile.find("GODOT ?= godot4") != -1, "Makefile should default to godot4")

func _test_project_and_scenes() -> void:
	print("-- project and scenes --")
	var features: PackedStringArray = ProjectSettings.get_setting("application/config/features")
	_assert(features is PackedStringArray, "project features should be PackedStringArray")
	_assert("4.3" in features, "project should declare Godot 4.3 feature")

	for path in SCENE_PATHS:
		var packed: PackedScene = load(path)
		_assert(packed != null, "scene should load: %s" % path)

	var dir := DirAccess.open("res://scenes")
	_assert(dir != null, "scenes directory should exist")
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tscn"):
			var scene_path := "res://scenes/%s" % file_name
			var text: String = _helpers().read_file(scene_path)
			_assert(text.begins_with("[gd_scene load_steps="), "scene should be text format: %s" % scene_path)
			_assert(text.find("format=3") != -1, "scene should be Godot 4 format 3: %s" % scene_path)
		file_name = dir.get_next()
	dir.list_dir_end()

func _test_cards_json() -> void:
	print("-- cards.json --")
	var json := JSON.new()
	var err := json.parse(_helpers().read_file("res://resources/cards.json"))
	_assert(err == OK, "cards.json should parse")
	_assert(json.data is Array, "cards.json root should be an array")

	for card in json.data:
		if not (card is Dictionary):
			continue
		var command: String = str(card.get("command", ""))
		if not command.begins_with("git commit"):
			continue
		_assert(
			command.find("-m") != -1 or command.find("[string]") != -1,
			"commit card should use -m or [string]: %s" % str(card.get("id", command))
		)

func _test_levels_parse() -> void:
	print("-- levels --")
	var chapters_dir := DirAccess.open("res://levels")
	_assert(chapters_dir != null, "levels directory should exist")
	chapters_dir.list_dir_begin()
	var chapter := chapters_dir.get_next()
	var level_count := 0
	while chapter != "":
		if chapters_dir.current_is_dir() and chapter != "." and chapter != "..":
			var chapter_dir := DirAccess.open("res://levels/%s" % chapter)
			chapter_dir.list_dir_begin()
			var level_name := chapter_dir.get_next()
			while level_name != "":
				if not chapter_dir.current_is_dir() and level_name != "sequence":
					var level_path := "res://levels/%s/%s" % [chapter, level_name]
					var parsed: Dictionary = _helpers().parse(level_path)
					_assert(parsed.has("description"), "level should have description: %s" % level_path)
					var has_setup := false
					var has_win := false
					for key in parsed.keys():
						var k := str(key)
						if k.begins_with("setup"):
							has_setup = true
						if k.begins_with("win"):
							has_win = true
					_assert(has_setup, "level should have a setup section: %s" % level_path)
					var optional_win := chapter in ["sandbox", "unused"] or level_name in [
						"pushed-something-broken",
						"pr",
						"gitignore",
						"three-commits",
						"empty",
						"remote",
					]
					if not optional_win:
						_assert(has_win, "level should have a win section: %s" % level_path)
					level_count += 1
				level_name = chapter_dir.get_next()
			chapter_dir.list_dir_end()
		chapter = chapters_dir.get_next()
	chapters_dir.list_dir_end()
	_assert(level_count > 0, "should parse at least one level file")

func _track_cleanup(node: Node) -> void:
	_cleanup_nodes.append(node)

func _cleanup() -> void:
	for node in _cleanup_nodes:
		if is_instance_valid(node):
			node.free()
	_cleanup_nodes.clear()
	await create_timer(0.05).timeout

func _test_shell() -> void:
	print("-- shell --")
	var shell := Shell.new()
	_track_cleanup(shell)
	var test_dir := "%stest-repos/shell-%d/" % [_game().tmp_prefix, randi()]
	DirAccess.make_dir_recursive_absolute(test_dir)
	shell.cd(test_dir)

	var sync_out: String = await shell.run("echo sync-ok")
	_assert(sync_out.strip_edges() == "sync-ok", "shell.run should execute commands")

	var async_cmd: ShellCommand = shell.run_async("echo async-ok")
	_track_cleanup(async_cmd)
	await async_cmd.done
	_assert(async_cmd.output != null, "shell.run_async should produce output")
	_assert(String(async_cmd.output).strip_edges() == "async-ok", "shell.run_async should execute commands")

	var os_name := OS.get_name()
	if os_name in ["Linux", "macOS", "OSX"]:
		var bash_check: String = await shell.run("echo $0")
		_assert(bash_check.find("bash") != -1, "shell should use bash on Unix (got %s on %s)" % [bash_check.strip_edges(), os_name])

func _test_file_browser() -> void:
	print("-- file browser --")
	var browser: Control = load("res://scenes/file_browser.tscn").instantiate()
	_track_cleanup(browser)
	var repo_dir := "%stest-repos/file-browser-%d/" % [_game().tmp_prefix, randi()]
	DirAccess.make_dir_recursive_absolute(repo_dir)

	var shell := Shell.new()
	_track_cleanup(shell)
	shell.cd(repo_dir)
	await shell.run("git init -b main")
	await shell.run("echo base > food.txt")
	await shell.run("git add food.txt")
	await shell.run("git commit -m base")
	await shell.run("git checkout -b other")
	await shell.run("echo branch-other > food.txt")
	await shell.run("git add food.txt")
	await shell.run("git commit -m other")
	await shell.run("git checkout main")
	await shell.run("echo branch-main > food.txt")
	await shell.run("git add food.txt")
	await shell.run("git commit -m main")
	await shell.run("git merge other || true")

	browser.repository = {
		"shell": shell,
		"there_is_a_git_cache": true,
	}
	browser.mode = browser.FileBrowserMode.WORKING_DIRECTORY

	var wd_files := ["food.txt"]
	var statuses: Dictionary = await browser._collect_file_statuses(["food.txt"], wd_files)
	_assert(statuses["food.txt"]["exists_in_wd"], "conflicted file should exist in working directory")
	_assert(statuses["food.txt"]["conflict"], "merge conflict should set conflict=true")

	var fake_item := MockFileItem.new()
	fake_item.file_status = statuses["food.txt"]
	browser.mode = browser.FileBrowserMode.WORKING_DIRECTORY
	_assert(browser.file_click_allowed(fake_item), "WD file should be clickable in working directory mode")

	browser.mode = browser.FileBrowserMode.INDEX
	_assert(not browser.file_click_allowed(fake_item), "conflicted file should not be clickable in index mode")

	browser.mode = browser.FileBrowserMode.COMMIT
	_assert(browser.file_click_allowed(fake_item), "commit mode should allow clicks")

	# HEAD-only file (deleted from WD) should not open in WD mode.
	await shell.run("git rm food.txt")
	statuses = await browser._collect_file_statuses(["food.txt"], [])
	browser.mode = browser.FileBrowserMode.WORKING_DIRECTORY
	fake_item = MockFileItem.new()
	fake_item.file_status = statuses["food.txt"]
	_assert(not browser.file_click_allowed(fake_item), "HEAD-only file should not be clickable in WD mode")

func _assert(condition: bool, message: String) -> void:
	if condition:
		_passes += 1
	else:
		_fail(message)

func _fail(message: String) -> void:
	_failures.append(message)
	push_error("FAIL: " + message)

func _skip(message: String) -> void:
	print("SKIP: ", message)

func _report_and_quit() -> void:
	print("=== Results: %d passed, %d failed ===" % [_passes, _failures.size()])
	for message in _failures:
		print("  FAIL: ", message)
	if _failures.is_empty():
		print("(Godot may still log RID/resource warnings at exit from autoloads and headless rendering — harmless.)")
	quit(1 if _failures.size() > 0 else 0)
