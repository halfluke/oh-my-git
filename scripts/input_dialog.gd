extends Window

signal entered(text)
signal canceled

func _ready():
	title = "Enter value"
	size = Vector2i(480, 80)
	visibility_changed.connect(_on_visibility_changed)
	close_requested.connect(_on_close_requested)

func _on_visibility_changed():
	if visible:
		$LineEdit.grab_focus()

func _on_close_requested():
	canceled.emit()
	queue_free()

func _text_entered(text):
	entered.emit(text)
	queue_free()
