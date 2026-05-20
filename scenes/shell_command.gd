extends Node
class_name ShellCommand

signal done

var command
var output
var exit_code
var crash_on_fail = true
var thread
var js_callback # For JavaScriptBridge
var tmp_prefix := ""
var cwd := ""

func _emit_done():
	emit_signal("done")

func callback(_output):
	#print(_output)
	output = _output[0]
	print("output of async command (" + command + "): >>"+output+"<<" )
	exit_code = 0
	emit_signal("done")
