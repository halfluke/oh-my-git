class_name FileBrowserItem 
extends Control

signal clicked(what)
signal deleted(what)

@export var label: String: set = _set_label
var type = "file"
var repository
var file_status = {}

@onready var label_node = $VBoxContainer/Label

func _ready():
	_set_label(label)
	_apply_status()

func _apply_status():
	var exists_in_wd = file_status.get("exists_in_wd", false)
	var exists_in_index = file_status.get("exists_in_index", false)
	var exists_in_head = file_status.get("exists_in_head", false)
	var wd_hash = file_status.get("wd_hash", "")
	var index_hash = file_status.get("index_hash", "")
	var head_hash = file_status.get("head_hash", "")
	var conflict = file_status.get("conflict", false)

	var offset_index = 0
	var offset_wd = 0
	var offset = 10

	if exists_in_index and exists_in_head and index_hash != head_hash:
		offset_index += 1

	if exists_in_wd and exists_in_head and wd_hash != head_hash:
		offset_wd += 1

	if exists_in_wd and exists_in_index and wd_hash != index_hash and offset_index == offset_wd:
		offset_wd += 1

	$VBoxContainer/Control/Index.position.x += offset_index*offset
	$VBoxContainer/Control/Index.position.y -= offset_index*offset

	$VBoxContainer/Control/WD.position.x += offset_wd*offset
	$VBoxContainer/Control/WD.position.y -= offset_wd*offset

	if conflict:
		$VBoxContainer/Control/Index.self_modulate = Color(1, 0.2, 0.2, 0.5)

	$VBoxContainer/Control/HEAD.visible = exists_in_head
	$VBoxContainer/Control/Index.visible = exists_in_index
	$VBoxContainer/Control/WD.visible = exists_in_wd

func _set_label(new_label):
	label = new_label
	if label_node:
		label_node.text = helpers.abbreviate(new_label, 30)

func _gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("clicked", self)

func _popup_menu_pressed(_id):
	emit_signal("deleted", self)
