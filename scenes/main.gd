extends Control

var dragged = null

var _update_repos_busy = false
var _update_repos_again = false
var _load_level_busy = false
var _load_level_pending = false

@onready var terminal = $Rows/Controls/Terminal
@onready var input = terminal.input
@onready var output = terminal.output
@onready var repositories_node = $Rows/Columns/Repositories
@onready var platform_theory_panel = $Rows/Columns/Repositories/PlatformTheoryPanel
@onready var diagram_body = $Rows/Columns/Repositories/PlatformTheoryPanel/DiagramTopMargin/DiagramBody
var repositories = {}
@onready var next_level_button = $Menu/NextLevelButton
@onready var sandbox_prev_button = $Menu/SandboxPrevButton
@onready var sandbox_next_button = $Menu/SandboxNextButton
@onready var level_name = $Rows/Columns/RightSide/LevelInfo/LevelPanel/LevelName
@onready var level_description = $Rows/Columns/RightSide/LevelInfo/LevelPanel/Text/LevelDescription
@onready var level_congrats = $Rows/Columns/RightSide/LevelInfo/LevelPanel/Text/LevelCongrats
@onready var cards = $Rows/Controls/Cards
@onready var file_browser = $Rows/Columns/RightSide/FileBrowser
@onready var goals = $Rows/Columns/RightSide/LevelInfo/LevelPanel/Goals

#var _hint_server
#var _hint_client_connection

func _ready():
	#_hint_server = TCPServer.new()
	#_hint_server.listen(1235)
	
	var args = helpers.parse_args()
	
	if args.has("sandbox"):
		var err = get_tree().change_scene_to_file("res://scenes/sandbox.tscn")
		if err != OK:
			helpers.crash("Could not change to sandbox scene")
		return
	
	# Initialize level select.
#	level_select.connect("item_selected", self, "load_level")
#	repopulate_levels()
#	level_select.select(game.current_level)
	
#	# Initialize chapter select.
#	chapter_select.connect("item_selected", self, "load_chapter")
#	repopulate_chapters()
#	chapter_select.select(game.current_chapter)
	
	# Load current level.
	load_level(game.current_level)
	input.grab_focus()

func load_chapter(id):
	game.current_chapter = id
	load_level(0)

func load_level(level_id):
	game.current_level = level_id
	if _load_level_busy:
		_load_level_pending = true
		return
	_load_level_busy = true
	while true:
		_load_level_pending = false
		await _load_level_impl()
		if not _load_level_pending:
			break
	_load_level_busy = false

func _load_level_impl():
	var level_id = game.current_level
	next_level_button.hide()
	level_congrats.hide()
	level_description.show()
	game.used_cards = false
	
	_set_sfx_muted(true)
	
	await levels.chapters[game.current_chapter].levels[game.current_level].construct()

	var level = levels.chapters[game.current_chapter].levels[game.current_level]
	var pt = level.mode == "platform_theory"
	platform_theory_panel.visible = pt
	diagram_body.text = level.diagram_bbcode if pt else ""
	file_browser.visible = not pt
	level_description.scroll_active = pt
	goals.visible = not pt
	
	level_description.text = level.description[0]
	level_congrats.text = level.congrats
	level_name.text = level.title
	
	var slug = levels.chapters[game.current_chapter].slug + "/" + level.slug
	_record_freeroam_visit_if_spine(slug)
	var read = game.state.get("freeroam_read", [])
	var cli_golden = slug in game.state["cli_badge"] or slug in read
	$Menu/CLIBadge.active = cli_golden
	$Menu/CLIBadge.sparkling = slug in game.state["cli_badge"]
	
	#if levels.chapters[game.current_chapter].levels[game.current_level].cards.size() == 0:
	#	cards.redraw_all_cards()
	#else:
	cards.draw(levels.chapters[game.current_chapter].levels[game.current_level].cards)
	
	for r in repositories_node.get_children():
		if r.name == "PlatformTheoryPanel":
			continue
		r.queue_free()
	repositories = {}
	
	var repo_names = level.repos.keys()
	repo_names.reverse()
	
	for r in repo_names:
		var repo = level.repos[r]
		var new_repo = preload("res://scenes/repository.tscn").instantiate()
		new_repo.path = repo.path
		new_repo.label = repo.slug
		new_repo.size_flags_horizontal = SIZE_EXPAND_FILL
		new_repo.size_flags_vertical = SIZE_EXPAND_FILL
		if pt:
			new_repo.visible = false
		if new_repo.label == "yours":
			file_browser.repository = new_repo
		repositories_node.add_child(new_repo)
		repositories[r] = new_repo
	
	terminal.repository = repositories[repo_names[repo_names.size()-1]] if repo_names.size() > 0 else null
	terminal.clear()
	terminal.find_child("TextEditor").close()
	
	await update_repos()
	_update_freeroam_nav()
	
	# Unmute the audio after a while, so that player can hear pop sounds for
	# nodes they create.
	var t = Timer.new()
	t.wait_time = 1
	t.one_shot = true
	add_child(t)
	t.start()
	await t.timeout
	t.queue_free()
	_set_sfx_muted(false)
	
#	chapter_select.select(game.current_chapter)
#	level_select.select(game.current_level)
	#game.notify("These are your cards!", cards)

func reload_level():
	cards.load_card_store()
	levels.reload()
	load_level(game.current_level)

func load_next_level():
	game.current_level += 1
	if game.current_level >= levels.chapters[game.current_chapter].levels.size():
		
		back()
	else:
		load_level(game.current_level)
	
	
func show_win_status(win_states):
	var all_won = true
	var win_text = "\n\n"
	for child in goals.get_children():
		child.queue_free()
	await get_tree().process_frame
	for state in win_states:
		var b = Label.new()
		b.text = state
		#b.align = HALIGN_LEFT   ToDo align fix
		var bg = StyleBoxFlat.new()
		if win_states[state]:
			bg.bg_color = Color(0.1, 0.5, 0.1)
		else:
			bg.bg_color = Color(0.5, 0.1, 0.1)
		bg.corner_radius_bottom_left = 8
		bg.corner_radius_bottom_right = 8
		bg.corner_radius_top_left = 8
		bg.corner_radius_top_right = 8
		bg.content_margin_bottom = 8
		bg.content_margin_top = 8
		bg.content_margin_left = 8
		bg.content_margin_right = 8
		b.set("theme_override_styles/normal", bg)
		#b.connect("pressed", self, "load", [chapter_id, level_id])
		#var slug = chapter.slug + "/" + level.slug
		
		goals.add_child(b)
		b.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		if not win_states[state]:
			all_won = false
	var level = levels.chapters[game.current_chapter].levels[game.current_level]
	level_description.text = level.description[0] + win_text
	for i in range(1,level.tipp_level+1):
		level_description.text += level.description[i]
			
	if not level_congrats.visible and all_won and win_states.size() > 0:
		next_level_button.show()
		level_description.hide()
		level_congrats.show()
		$SuccessSound.play()
		var slug = levels.chapters[game.current_chapter].slug + "/" + level.slug
		if not slug in game.state["solved_levels"]:
			game.state["solved_levels"].push_back(slug)
			game.save_state()
		if not game.used_cards and not slug in game.state["cli_badge"]:
			game.state["cli_badge"].push_back(slug)
			game.save_state()
			$Menu/CLIBadge.active = true
			$Menu/CLIBadge.sparkling = true

#func repopulate_levels():
#	levels.reload()
#	level_select.clear()
#	for level in levels.chapters[game.current_chapter].levels:
#		level_select.add_item(level.title)
#	level_select.select(game.current_level)

#func repopulate_chapters():
#	levels.reload()
#	chapter_select.clear()
#	for c in levels.chapters:
#		chapter_select.add_item(c.slug)
#	chapter_select.select(game.current_chapter)

func update_repos():
	if _update_repos_busy:
		_update_repos_again = true
		return
	_update_repos_busy = true
	while true:
		_update_repos_again = false
		await _update_repos_impl()
		if not _update_repos_again:
			break
	_update_repos_busy = false

func _update_repos_impl():
	var win_states = await levels.chapters[game.current_chapter].levels[game.current_level].check_win()
	await show_win_status(win_states)

	for r in repositories:
		var repo = repositories[r]
		await repo.update_everything()
	await file_browser.update()

	input.grab_focus()

func toggle_cards():
	cards.visible = not cards.visible
	
func new_tip():
	var level = levels.chapters[game.current_chapter].levels[game.current_level]
	if level.description.size() - 1 > level.tipp_level :
		level.tipp_level += 1
		level_description.text += level.description[level.tipp_level]

func back():
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")


const PLATFORM_THEORY_PREFIXES = ["github-", "gitlab-", "gitea-", "bitbucket-", "azure-devops-"]


func _chapter_on_freeroam_spine(chapter):
	if chapter.slug == "sandbox":
		return true
	for prefix in PLATFORM_THEORY_PREFIXES:
		if chapter.slug.begins_with(prefix):
			return true
	return false


func _freeroam_spine():
	var spine = []
	for ci in range(levels.chapters.size()):
		var ch = levels.chapters[ci]
		if not _chapter_on_freeroam_spine(ch):
			continue
		for li in range(ch.levels.size()):
			spine.append({"c": ci, "l": li})
	return spine


func _freeroam_spine_index():
	var spine = _freeroam_spine()
	var cc = game.current_chapter
	var ll = game.current_level
	for i in range(spine.size()):
		if spine[i].c == cc and spine[i].l == ll:
			return i
	return -1


func _record_freeroam_visit_if_spine(slug):
	if _freeroam_spine_index() < 0:
		return
	if not game.state.has("freeroam_read"):
		game.state["freeroam_read"] = []
	if slug in game.state["freeroam_read"]:
		return
	game.state["freeroam_read"].append(slug)
	game.save_state()


func uses_freeroam_nav():
	return _freeroam_spine_index() >= 0


func _update_freeroam_nav():
	if uses_freeroam_nav():
		sandbox_prev_button.visible = true
		sandbox_next_button.visible = true
		var spine = _freeroam_spine()
		var idx = _freeroam_spine_index()
		sandbox_prev_button.disabled = idx <= 0
		sandbox_next_button.disabled = idx < 0 or idx >= spine.size() - 1
		sandbox_prev_button.tooltip_text = "Previous: sandbox & reading trail"
		sandbox_next_button.tooltip_text = "Next: sandbox & reading trail"
	else:
		sandbox_prev_button.visible = false
		sandbox_next_button.visible = false


func sandbox_prev():
	if not uses_freeroam_nav():
		return
	var spine = _freeroam_spine()
	var idx = _freeroam_spine_index()
	if idx <= 0:
		return
	var prev = spine[idx - 1]
	game.current_chapter = prev.c
	load_level(prev.l)


func sandbox_next():
	if not uses_freeroam_nav():
		return
	var spine = _freeroam_spine()
	var idx = _freeroam_spine_index()
	if idx < 0 or idx >= spine.size() - 1:
		return
	var nxt = spine[idx + 1]
	game.current_chapter = nxt.c
	load_level(nxt.l)

func _sfx_bus_index() -> int:
	return AudioServer.get_bus_index("SFX")

func _set_sfx_muted(muted: bool) -> void:
	var idx = _sfx_bus_index()
	if idx >= 0:
		AudioServer.set_bus_mute(idx, muted)
