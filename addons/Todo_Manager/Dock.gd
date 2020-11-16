tool
extends Control

signal tree_built # used for debugging

const Todo := preload("res://addons/Todo_Manager/todo_class.gd")
const ColourPicker := preload("res://addons/Todo_Manager/ColourPicker.tscn")
const Pattern := preload("res://addons/Todo_Manager/Pattern.tscn")
const DEFAULT_PATTERNS := [["\\bTODO\\b", Color("96f1ad")], ["\\bHACK\\b", Color("d5bc70")], ["\\bFIXME\\b", Color("d57070")]]
const DEFAULT_SCRIPT_COLOUR := Color("ccced3")
const DEFAULT_SCRIPT_NAME := false
const DEFAULT_SORT := true

var plugin : EditorPlugin

var todo_items : Array

var script_colour := Color("ccced3")
var full_path := false
var sort_alphabetical := true

var patterns := [["\\bTODO\\b", Color("96f1ad")], ["\\bHACK\\b", Color("d5bc70")], ["\\bFIXME\\b", Color("d57070")]]

onready var tree := $VBoxContainer/Panel/Tree as Tree
onready var settings_panel := $VBoxContainer/Panel/Settings as Panel
onready var colours_container := $VBoxContainer/Panel/Settings/ScrollContainer/MarginContainer/VBoxContainer/HBoxContainer3/Colours as VBoxContainer
onready var pattern_container := $VBoxContainer/Panel/Settings/ScrollContainer/MarginContainer/VBoxContainer/HBoxContainer4/Patterns as VBoxContainer

func _ready() -> void:
	load_config()
	populate_settings()


func build_tree() -> void:
	tree.clear()
	if sort_alphabetical:
		todo_items.sort_custom(self, "sort_alphabetical")
	else:
		todo_items.sort_custom(self, "sort_backwards")
	var root := tree.create_item()
	root.set_text(0, "Scripts")
	for todo_item in todo_items:
		var script := tree.create_item(root)
		if full_path:
			script.set_text(0, todo_item.script_path + " -------")
		else:
			script.set_text(0, todo_item.get_short_path() + " -------")
		script.set_metadata(0, todo_item)
		for todo in todo_item.todos:
			var item := tree.create_item(script)
			item.set_text(0, "(%0) - %1".format([todo.line_number, todo.content], "%_"))
			item.set_metadata(0, todo)
			for pattern in patterns:
				if pattern[0] == todo.pattern:
					item.set_custom_color(0, pattern[1])
	emit_signal("tree_built")


func go_to_script(script_path: String, line_number : int = 0) -> void:
	var script := load(script_path)
	plugin.get_editor_interface().edit_resource(script)
	plugin.get_editor_interface().get_script_editor().goto_line(line_number - 1)


func sort_alphabetical(a, b) -> bool:
	if a.script_path > b.script_path:
		return true
	else:
		return false

func sort_backwards(a, b) -> bool:
	if a.script_path < b.script_path:
		return true
	else:
		return false


func populate_settings() -> void:
	for i in patterns.size():
		## Create Colour Pickers
		var colour_picker := ColourPicker.instance()
		colour_picker.colour = patterns[i][1]
		colour_picker.title = patterns[i][0]
		colour_picker.index = i
		colours_container.add_child(colour_picker)
		colour_picker.colour_picker.connect("color_changed", self, "change_colour", [i])
		
		## Create Patterns
		var pattern_edit := Pattern.instance()
		pattern_edit.text = patterns[i][0]
		pattern_edit.index = i
		pattern_container.add_child(pattern_edit)
		pattern_edit.line_edit.connect("text_changed", self, "change_pattern", [i, colour_picker])
		pattern_edit.remove_button.connect("pressed", self, "remove_pattern", [i, pattern_edit, colour_picker])
	$VBoxContainer/Panel/Settings/ScrollContainer/MarginContainer/VBoxContainer/HBoxContainer4/Patterns/AddPatternButton.raise()


func rebuild_settings() -> void:
	for node in colours_container.get_children():
		node.queue_free()
	for node in pattern_container.get_children():
		if node is Button:
			continue
		node.queue_free()
	populate_settings()


#### CONFIG FILE ####
func create_config_file() -> void:
	var config = ConfigFile.new()
	config.set_value("scripts", "full_path", full_path)
	config.set_value("scripts", "sort_alphabetical", sort_alphabetical)
	config.set_value("scripts", "script_colour", script_colour)
	
	config.set_value("patterns", "patterns", patterns)
	
	var err = config.save("res://addons/Todo_Manager/todo.cfg")


func load_config() -> void:
	var config := ConfigFile.new()
	if config.load("res://addons/Todo_Manager/todo.cfg") == OK:
		full_path = config.get_value("scripts", "full_path", DEFAULT_SCRIPT_NAME)
		sort_alphabetical = config.get_value("scripts", "sort_alphabetical", DEFAULT_SORT)
		script_colour = config.get_value("scripts", "script_colour", DEFAULT_SCRIPT_COLOUR)
		patterns = config.get_value("patterns", "patterns", DEFAULT_PATTERNS)
	else:
		create_config_file()


#### Events ####
func _on_SettingsButton_toggled(button_pressed: bool) -> void:
	settings_panel.visible = button_pressed
	if button_pressed == false:
		create_config_file()
#		plugin.find_tokens_from_path(plugin.script_cache)
		plugin.rescan_files()

func _on_Tree_item_activated() -> void:
	var item := tree.get_selected()
	if item.get_metadata(0) is Todo:
		var todo : Todo = item.get_metadata(0)
		call_deferred("go_to_script", todo.script_path, todo.line_number)
	else:
		var todo_item = item.get_metadata(0)
		call_deferred("go_to_script", todo_item.script_path)

func _on_FullPathCheckBox_toggled(button_pressed: bool) -> void:
	full_path = button_pressed

func _on_ScriptColourPickerButton_color_changed(color: Color) -> void:
	script_colour = color

func _on_TODOColourPickerButton_color_changed(color: Color) -> void:
	patterns[0][1] = color

func _on_RescanButton_pressed() -> void:
	plugin.rescan_files()

func change_colour(colour: Color, index: int) -> void:
	patterns[index][1] = colour

func change_pattern(value: String, index: int, this_colour: Node) -> void:
	patterns[index][0] = value
	this_colour.title = value

func remove_pattern(index: int, this: Node, this_colour: Node) -> void:
	patterns.remove(index)
	this.queue_free()
	this_colour.queue_free()

func _on_DefaultButton_pressed() -> void:
	patterns = DEFAULT_PATTERNS.duplicate(true)
	sort_alphabetical = DEFAULT_SORT
	script_colour = DEFAULT_SCRIPT_COLOUR
	full_path = DEFAULT_SCRIPT_NAME
	rebuild_settings()


func _on_AlphSortCheckBox_toggled(button_pressed: bool) -> void:
	sort_alphabetical = button_pressed

func _on_AddPatternButton_pressed() -> void:
	patterns.append(["\\bplaceholder\\b", Color.white])
	rebuild_settings()
