tool
extends Control

signal tree_built # used for debugging

const Todo := preload("res://addons/Todo_Manager/todo_class.gd")

var plugin : EditorPlugin

var todo_items : Array
var script_colour := Color("ccced3")
var todo_colour := Color.white
var hack_color := Color("d5bc70")

var full_path := false

onready var tree := $VBoxContainer/Panel/Tree as Tree
onready var settings_panel := $VBoxContainer/Panel/Settings as Panel


func build_tree() -> void:
	tree.clear()
	todo_items.sort_custom(self, "sort_todo_items")
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
			match todo.title:
				"TODO":
					item.set_custom_color(0, todo_colour)
				"HACK":
					item.set_custom_color(0, hack_color)
	emit_signal("tree_built")


func go_to_script(script_path: String, line_number : int = 0) -> void:
	var script := load(script_path)
	plugin.get_editor_interface().edit_resource(script)
	plugin.get_editor_interface().get_script_editor().goto_line(line_number - 1)


func sort_todo_items(a, b) -> bool:
	if a.script_path > b.script_path:
		return true
	else:
		return false


func _on_SettingsButton_toggled(button_pressed: bool) -> void:
	settings_panel.visible = button_pressed
	if button_pressed == false:
		build_tree()

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
	todo_colour = color
