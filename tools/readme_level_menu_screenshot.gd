extends Control

# One-off helper: run with
#   xvfb-run -a godot3 --path . res://tools/readme_level_menu_screenshot.tscn
# Writes images/readme-beyond-git-level-menu.png (scrolls to show "Beyond Git" sections).

func _ready():
	OS.window_fullscreen = false
	OS.window_size = Vector2(1200, 800)

	var ls = preload("res://scenes/level_select.tscn").instance()
	ls.anchor_left = 0
	ls.anchor_top = 0
	ls.anchor_right = 1
	ls.anchor_bottom = 1
	ls.margin_left = 0
	ls.margin_top = 0
	ls.margin_right = 0
	ls.margin_bottom = 0
	add_child(ls)

	call_deferred("_scroll_and_shoot", ls)


func _scroll_and_shoot(ls):
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")

	var scroll = ls.get_node("ScrollContainer")
	scroll.scroll_vertical = int(scroll.get_v_scrollbar().max_value)
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")

	var img = get_viewport().get_texture().get_data()
	img.flip_y()
	var rel = "res://images/readme-beyond-git-level-menu.png"
	var path = ProjectSettings.globalize_path(rel)
	var err = img.save_png(path)
	print("readme_level_menu_screenshot: save_png err=", err, " path=", path)
	get_tree().quit()
