tool
extends Control

const Todo := preload("res://addons/Todo_Manager/todo_class.gd")

var todo_items : Array
var todo_colour := Color.white
var hack_color := Color("d5bc70")

onready var tree := $VBoxContainer/Panel/Tree as Tree
onready var settings_panel := $VBoxContainer/Panel/Settings as Panel

func build_tree() -> void:
	tree.clear()
	var root := tree.create_item()
	root.set_text(0, "Scripts")
	for todo_item in todo_items:
		var branch := tree.create_item(root)
		branch.set_text(0, todo_item.script_path)
		for todo in todo_item.todos:
			var leaf := tree.create_item(branch)
			leaf.set_text(0, "(%0) %1".format([todo.line_number, todo.content], "%_"))
			match todo.title:
				"TODO":
					leaf.set_custom_color(0, todo_colour)
				"HACK":
					leaf.set_custom_color(0, hack_color)


func _on_Tree_item_double_clicked() -> void:
	pass # TODO Replace with function body.


func _on_SettingsButton_toggled(button_pressed: bool) -> void:
	settings_panel.visible = button_pressed
	if button_pressed == false:
		build_tree()


func _on_TODOColourPickerButton_color_changed(color: Color) -> void:
	todo_colour = color
