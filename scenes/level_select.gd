extends Control

# Section title, then slug prefix for chapters in that section (order preserved when listing).
const PLATFORM_GROUPS = [
	["Beyond Git: GitHub", "github-"],
	["Beyond Git: GitLab", "gitlab-"],
	["Beyond Git: Gitea", "gitea-"],
	["Beyond Git: Bitbucket (+ Jira)", "bitbucket-"],
	["Beyond Git: Azure DevOps", "azure-devops-"],
]

onready var level_list = $ScrollContainer/MarginContainer/Levels

func _ready():
	reload()

func load(chapter_id, level_id):
	game.current_chapter = chapter_id
	game.current_level = level_id
	get_tree().change_scene("res://scenes/main.tscn")

func back():
	get_tree().change_scene("res://scenes/title.tscn")


func _platform_prefix_for_slug(slug):
	for g in range(PLATFORM_GROUPS.size()):
		var pfx = PLATFORM_GROUPS[g][1]
		if slug.begins_with(pfx):
			return pfx
	return ""


func _platform_chapter_display_name(slug):
	var pfx = _platform_prefix_for_slug(slug)
	if pfx == "":
		return slug
	var rest = slug.substr(pfx.length())
	return rest.replace("-", " ").capitalize()


func _append_levels_for_chapter(chapter, chapter_id):
	var level_id = 0
	for level in chapter.levels:
		var hb = HBoxContainer.new()
		
		var b = Button.new()
		b.text = level.title
		b.align = HALIGN_LEFT
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		
		b.connect("pressed", self, "load", [chapter_id, level_id])
		var slug = chapter.slug + "/" + level.slug
		if slug in game.state["solved_levels"]:
			b.set("custom_colors/font_color", Color(0.1, 0.8, 0.1, 1))
			b.set("custom_colors/font_color_hover", Color(0.1, 0.8, 0.1, 1))
			b.set("custom_colors/font_color_pressed", Color(0.1, 0.8, 0.1, 1))
			
		hb.add_child(b)
		
		var badge = preload("res://scenes/cli_badge.tscn").instance()
		hb.add_child(badge)
		badge.active = slug in game.state["cli_badge"]
		badge.sparkling = false
			
		level_list.add_child(hb)
		
		if badge.active:
			game.notify("You get a golden badge for each level you solve without using the playing cards! Can you solve them all using the command line?", badge, "cli-badge")
		level_id += 1


func reload():
	for child in level_list.get_children():
		child.queue_free()
	
	levels.reload()
	
	var big_font = preload("res://fonts/big.tres")
	var sub_font = preload("res://fonts/default.tres")
	var n = levels.chapters.size()
	var i = 0
	var chapter
	
	while i < n:
		chapter = levels.chapters[i]
		if _platform_prefix_for_slug(chapter.slug) != "":
			break
		var l = Label.new()
		l.text = chapter.slug
		l.set("custom_fonts/font", big_font)
		l.align = HALIGN_CENTER
		level_list.add_child(l)
		_append_levels_for_chapter(chapter, i)
		i += 1
	
	if i >= n:
		return
	
	var by_prefix = {}
	for j in range(i, n):
		var ch = levels.chapters[j]
		var pfx = _platform_prefix_for_slug(ch.slug)
		if pfx == "":
			continue
		if not by_prefix.has(pfx):
			by_prefix[pfx] = []
		by_prefix[pfx].append({"chapter_id": j, "chapter": ch})
	
	for g in range(PLATFORM_GROUPS.size()):
		var section_title = PLATFORM_GROUPS[g][0]
		var pfx = PLATFORM_GROUPS[g][1]
		if not by_prefix.has(pfx):
			continue
		var sec = Label.new()
		sec.text = section_title
		sec.set("custom_fonts/font", big_font)
		sec.align = HALIGN_CENTER
		level_list.add_child(sec)
		for item in by_prefix[pfx]:
			var sub = Label.new()
			sub.text = _platform_chapter_display_name(item.chapter.slug)
			sub.set("custom_fonts/font", sub_font)
			sub.align = HALIGN_CENTER
			level_list.add_child(sub)
			_append_levels_for_chapter(item.chapter, item.chapter_id)
