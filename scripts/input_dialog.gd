extends Window

signal entered(text)

func _ready():
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed():
	if visible:
		$LineEdit.grab_focus()

func _text_entered(text):
	entered.emit(text)
	queue_free()
