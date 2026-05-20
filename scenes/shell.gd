extends Node
class_name Shell

var exit_code

var _cwd
var _os = OS.get_name()
var _debug = false

var web_shell = JavaScriptBridge.get_interface("web_shell")

func _init():
	_cwd = game.tmp_prefix

func cd(dir):
	_cwd = dir

# Run a shell command given as a string. Run this if you're interested in the
# output of the command.
func run(command, crash_on_fail=true):
	var shell_command = ShellCommand.new()
	shell_command.command = command
	shell_command.crash_on_fail = crash_on_fail

	run_async_thread(shell_command)
	shell_command._emit_done()
	if _debug:
		print("output of (" + command + "): >>" + shell_command.output + "<<")
	exit_code = shell_command.exit_code
	return shell_command.output

func run_async_web(command, crash_on_fail=true):
	var shell_command = ShellCommand.new()
	shell_command.command = command
	shell_command.crash_on_fail = crash_on_fail
	run_async_thread(shell_command)
	if _os != "Web":
		shell_command._emit_done()
	return shell_command

func run_async(command, crash_on_fail=true):
	var shell_command = ShellCommand.new()
	shell_command.command = command
	shell_command.crash_on_fail = crash_on_fail
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

	if _debug:
		print("$ %s" % command)

	var env = {}
	env["HOME"] = game.tmp_prefix

	var hacky_command = ""
	for variable in env:
		hacky_command += "export %s='%s';" % [variable, env[variable]]

	hacky_command += "export PATH=\'"+game.tmp_prefix+":'\"$PATH\";"
	hacky_command += "cd '%s' || exit 1;" % _cwd
	hacky_command += command

	if _debug:
		print("running >>" + hacky_command + "<<")

	var result
	if _os == "Linux" or _os == "OSX":
		hacky_command = '"\''+hacky_command.replace("'", "'\"'\"'")+'\'"'
		result = helpers.exec(_shell_binary(), ["-c",  hacky_command], crash_on_fail)
	elif _os == "Windows":
		var script_path = game.tmp_prefix + "command" + str(randi())
		helpers.write_file(script_path, hacky_command)
		result = helpers.exec(_shell_binary(), [script_path], crash_on_fail)
	elif _os == "Web":
		shell_command.js_callback = JavaScriptBridge.create_callback(Callable(shell_command, "callback"))
		web_shell.run(hacky_command).then(shell_command.js_callback)
	else:
		helpers.crash("Unimplemented OS: %s" % _os)

	if _os != "Web":
		shell_command.output = result["output"]
		shell_command.exit_code = result["exit_code"]

func _shell_binary():
	if _os == "Linux" or _os == "OSX":
		return "bash"
	elif _os == "Windows":
		return "dependencies\\windows\\git\\bin\\bash.exe"
	else:
		helpers.crash("Unsupported OS: %s" % _os)

func read_from(c):
	var total_available = c.get_available_bytes()
	while total_available > 0:
		var available = min(1024, total_available)
		total_available -= available
		var data = c.get_utf8_string(available)
