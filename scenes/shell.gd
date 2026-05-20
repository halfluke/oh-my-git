extends Node
class_name Shell

var exit_code

var _cwd := ""
var _os = OS.get_name()
var _debug = false

var web_shell = JavaScriptBridge.get_interface("web_shell")

func _game() -> Node:
	return Engine.get_main_loop().root.get_node("game")

func _helpers() -> Node:
	return Engine.get_main_loop().root.get_node("helpers")

func _tmp_prefix() -> String:
	return _game().tmp_prefix

func _ensure_cwd() -> void:
	if _cwd == "":
		_cwd = _tmp_prefix()

func _prepare_shell_command(shell_command: ShellCommand, command: String, crash_on_fail: bool) -> void:
	shell_command.command = command
	shell_command.crash_on_fail = crash_on_fail
	_ensure_cwd()
	shell_command.tmp_prefix = _tmp_prefix()
	shell_command.cwd = _cwd

func cd(dir):
	_cwd = dir

# Run a shell command given as a string. Run this if you're interested in the
# output of the command.
func run(command, crash_on_fail=true):
	var shell_command = ShellCommand.new()
	_prepare_shell_command(shell_command, command, crash_on_fail)

	run_async_thread(shell_command)
	shell_command._emit_done()
	if _debug:
		print("output of (" + command + "): >>" + shell_command.output + "<<")
	exit_code = shell_command.exit_code
	return shell_command.output

func run_async_web(command, crash_on_fail=true):
	var shell_command = ShellCommand.new()
	_prepare_shell_command(shell_command, command, crash_on_fail)
	run_async_thread(shell_command)
	if _os != "Web":
		shell_command._emit_done()
	return shell_command

func run_async(command, crash_on_fail=true):
	var shell_command = ShellCommand.new()
	_prepare_shell_command(shell_command, command, crash_on_fail)
	var thread = Thread.new()
	shell_command.thread = thread
	thread.start(Callable(self, "_run_in_thread").bind(shell_command))
	return shell_command

func _run_in_thread(shell_command):
	run_async_thread(shell_command)
	call_deferred("_complete_async_command", shell_command)

func _complete_async_command(shell_command):
	if shell_command.thread:
		shell_command.thread.wait_to_finish()
		shell_command.thread = null
	shell_command._emit_done()

func run_async_thread(shell_command):
	var command = shell_command.command
	var crash_on_fail = shell_command.crash_on_fail
	var tmp_prefix = shell_command.tmp_prefix
	var cwd = shell_command.cwd

	if _debug:
		print("$ %s" % command)

	var env = {}
	env["HOME"] = tmp_prefix

	var hacky_command = ""
	for variable in env:
		hacky_command += "export %s='%s';" % [variable, env[variable]]

	hacky_command += "export PATH=\'"+tmp_prefix+":'\"$PATH\";"
	hacky_command += "cd '%s' || exit 1;" % cwd
	hacky_command += command

	if _debug:
		print("running >>" + hacky_command + "<<")

	var result
	if _os == "Linux" or _os == "OSX" or _os == "macOS":
		hacky_command = '"\''+hacky_command.replace("'", "'\"'\"'")+'\'"'
		result = _exec_command(_shell_binary(), ["-c",  hacky_command], crash_on_fail)
	elif _os == "Windows":
		var script_path = tmp_prefix + "command" + str(randi())
		_write_file(script_path, hacky_command)
		result = _exec_command(_shell_binary(), [script_path], crash_on_fail)
	elif _os == "Web":
		shell_command.js_callback = JavaScriptBridge.create_callback(Callable(shell_command, "callback"))
		web_shell.run(hacky_command).then(shell_command.js_callback)
	else:
		push_error("Unimplemented OS: %s" % _os)
		result = {"output": "", "exit_code": 1}

	if _os != "Web":
		shell_command.output = result["output"]
		shell_command.exit_code = result["exit_code"]

func _exec_command(command: String, args: Array, crash_on_fail: bool) -> Dictionary:
	var output: Array = []
	var exit_code := OS.execute(command, args, output, true)
	var out_str := ""
	if not output.is_empty():
		out_str = String(output[0])
	if exit_code != 0 and crash_on_fail:
		call_deferred("_fatal_exec_error", command, args, out_str, exit_code)
	return {"output": out_str, "exit_code": exit_code}

func _fatal_exec_error(command: String, args: Array, output: String, exit_code: int) -> void:
	_helpers().crash("OS.execute failed: %s [%s] Output: %s \nExit Code %d" % [command, ", ".join(PackedStringArray(args)), output, exit_code])

func _write_file(path: String, content: String) -> void:
	var parts = Array(path.split("/"))
	parts.pop_back()
	var dirname := "/".join(PackedStringArray(parts))
	if not DirAccess.dir_exists_absolute(dirname):
		DirAccess.make_dir_recursive_absolute(dirname)
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(content)
	file.close()

func _shell_binary():
	if _os == "Linux" or _os == "OSX" or _os == "macOS":
		return "bash"
	elif _os == "Windows":
		return "dependencies\\windows\\git\\bin\\bash.exe"
	else:
		push_error("Unsupported OS: %s" % _os)
		return ""

func read_from(c):
	var total_available = c.get_available_bytes()
	while total_available > 0:
		var available = min(1024, total_available)
		total_available -= available
		var data = c.get_utf8_string(available)
