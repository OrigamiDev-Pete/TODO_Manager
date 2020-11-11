tool
extends Control

const Todo := preload("res://addons/Todo_Manager/todo_class.gd")

var todo_items : Array

onready var tree : Tree = $VBoxContainer/Panel/Tree

func _ready() -> void:
	var root := tree.create_item()
	for todo_item in todo_items:
		var branch := tree.create_item(root)
		for todo in todo_item.todos:
			var leaf := tree.create_item(branch)
			leaf.set_text(0, todo.content)
		


func build_tree() -> void:
	var root := tree.create_item()
	for todo_item in todo_items:
		var branch := tree.create_item(root)
		for todo in todo_item.todos:
			var leaf := tree.create_item(branch)
			leaf.set_text(0, todo.content)
