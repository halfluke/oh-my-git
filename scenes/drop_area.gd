extends Node2D

var hovered = false
var highlighted = false: set = _set_highlighted
var _hover_tween: Tween

func _ready():
	_set_highlighted(false)

func _exit_tree():
	_kill_hover_tween()

func _kill_hover_tween() -> void:
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
		_hover_tween = null

func _mouse_entered(_area):
	hovered = true
	var material = $Highlight/Sprite2D.material
	if material == null:
		return
	_kill_hover_tween()
	_hover_tween = create_tween()
	_hover_tween.tween_property(material, "shader_parameter/hovered", 1, 0.1)

func _mouse_exited(_area):
	hovered = false
	var material = $Highlight/Sprite2D.material
	if material == null:
		return
	_kill_hover_tween()
	_hover_tween = create_tween()
	_hover_tween.tween_property(material, "shader_parameter/hovered", 0, 0.1)

	
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and !event.pressed and hovered:
			if highlighted and game.dragged_object:
				game.dragged_object.dropped_on(get_parent_with_type())

func _set_highlighted(new_highlighted):
	highlighted = new_highlighted
	$Highlight.visible = highlighted
	
func get_parent_with_type():
	var parent = get_parent()
	while(!parent.get("type")):
		parent = parent.get_parent()
	return parent

func highlight(type):
	if get_parent_with_type().type == type:
		_set_highlighted(true)
