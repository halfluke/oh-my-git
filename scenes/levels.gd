extends Node

var chapters

func _ready():
	reload()
	
func reload():
	chapters = []
	
	var dir = DirAccess.open("res://levels")
	var chapter_names = []
	for file in dir.get_directories():
		if not file.begins_with(".") and file != "sequence":
			chapter_names.append(file)
	chapter_names.sort()
	
	var final_chapter_sequence = []
	
	var chapter_sequence = Array(helpers.read_file("res://levels/sequence", "").split("\n"))
	
	for chapter in chapter_sequence:
		if chapter == "":
			continue
		if not chapter_names.has(chapter):
			helpers.crash("Chapter '%s' is specified in the sequence, but could not be found" % chapter)
		chapter_names.erase(chapter)
		final_chapter_sequence.push_back(chapter)
	
	#final_chapter_sequence += chapter_names
	
	for c in final_chapter_sequence:
		var chapter = Chapter.new()
		chapter.load("res://levels/%s" % c)
		chapters.push_back(chapter)
