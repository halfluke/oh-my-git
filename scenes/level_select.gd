extends Control

# Section title, then slug prefix for chapters in that section (order preserved when listing).
const PLATFORM_GROUPS = [
	["Beyond Git: GitHub", "github-"],
	["Beyond Git: GitLab", "gitlab-"],
	["Beyond Git: Gitea", "gitea-"],
	["Beyond Git: Bitbucket (+ Jira)", "bitbucket-"],
	["Beyond Git: Azure DevOps", "azure-devops-"],
]

@onready var level_list = $ScrollContainer/MarginContainer/Levels
@onready var scroll = $ScrollContainer

var _reload_running := false

func _ready():
	call_deferred("_populate")

func _populate():
	await reload()

func load(chapter_id, level_id):
	game.current_chapter = chapter_id
	game.current_level = level_id
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func back():
	get_tree().change_scene_to_file("res://scenes/title.tscn")


func _platform_prefix_for_slug(slug: String) -> String:
	for group in PLATFORM_GROUPS:
		var pfx: String = group[1]
		if slug.begins_with(pfx):
			return pfx
	return ""


func _platform_chapter_display_name(slug: String) -> String:
	var pfx = _platform_prefix_for_slug(slug)
	if pfx == "":
		return slug
	var rest = slug.substr(pfx.length())
	return rest.replace("-", " ").capitalize()


func _append_levels_for_chapter(chapter, chapter_id: int) -> void:
	var level_id = 0
	for level in chapter.levels:
		var hb = HBoxContainer.new()

		var b = Button.new()
		b.text = level.title
		b.size_flags_horizontal = SIZE_EXPAND_FILL

		b.connect("pressed", Callable(self, "load").bind(chapter_id, level_id))
		var slug = chapter.slug + "/" + level.slug
		if slug in game.state["solved_levels"]:
			b.set("theme_override_colors/font_color", Color(0.1, 0.8, 0.1, 1))
			b.set("theme_override_colors/font_hover_color", Color(0.1, 0.8, 0.1, 1))
			b.set("theme_override_colors/font_pressed_color", Color(0.1, 0.8, 0.1, 1))

		hb.add_child(b)

		var badge = preload("res://scenes/cli_badge.tscn").instantiate()
		hb.add_child(badge)
		var read = game.state.get("freeroam_read", [])
		badge.active = slug in game.state["cli_badge"] or slug in read
		badge.sparkling = slug in game.state["cli_badge"]

		level_list.add_child(hb)

		if slug in game.state["cli_badge"]:
			game.notify("You get a golden badge for each level you solve without using the playing cards! Can you solve them all using the command line?", badge, "cli-badge")
		level_id += 1


func reload():
	if _reload_running:
		return
	_reload_running = true

	for child in level_list.get_children():
		level_list.remove_child(child)
		child.free()

	levels.reload()

	var big_font = preload("res://fonts/big.tres")
	var sub_font = preload("res://fonts/default.tres")
	var n = levels.chapters.size()
	var i = 0

	while i < n:
		var chapter = levels.chapters[i]
		if _platform_prefix_for_slug(chapter.slug) != "":
			break
		var l = Label.new()
		l.text = chapter.slug
		l.set("theme_override_fonts/font", big_font)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_list.add_child(l)
		_append_levels_for_chapter(chapter, i)
		i += 1

	if i < n:
		var by_prefix = {}
		for j in range(i, n):
			var ch = levels.chapters[j]
			var pfx = _platform_prefix_for_slug(ch.slug)
			if pfx == "":
				continue
			if not by_prefix.has(pfx):
				by_prefix[pfx] = []
			by_prefix[pfx].append({"chapter_id": j, "chapter": ch})

		for group in PLATFORM_GROUPS:
			var section_title: String = group[0]
			var pfx: String = group[1]
			if not by_prefix.has(pfx):
				continue
			var sec = Label.new()
			sec.text = section_title
			sec.set("theme_override_fonts/font", big_font)
			sec.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			level_list.add_child(sec)
			for item in by_prefix[pfx]:
				var sub = Label.new()
				sub.text = _platform_chapter_display_name(item.chapter.slug)
				sub.set("theme_override_fonts/font", sub_font)
				sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				level_list.add_child(sub)
				_append_levels_for_chapter(item.chapter, item.chapter_id)

	await get_tree().process_frame
	level_list.update_minimum_size()
	scroll.update_minimum_size()
	scroll.scroll_vertical = 0
	_reload_running = false
