extends Control

func quit():
	get_tree().quit()

func levels():
	get_tree().change_scene("res://scenes/level_select.tscn")


func on_survey_pressed():
	game.open_survey()


func sandbox():
	game.current_chapter = levels.chapters.size() - 1
	game.current_level = 0
	get_tree().change_scene("res://scenes/main.tscn")


func _on_reset_progress_pressed():
	$ResetConfirm.popup_centered()


func _on_reset_confirm_confirmed():
	game.reset_progress()
	game.notify("All progress has been reset.", self)
