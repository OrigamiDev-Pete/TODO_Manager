@tool
extends PanelContainer

var text : String : set = set_text
var index : int

@onready var line_edit := %LineEdit as LineEdit
@onready var remove_button := %RemoveButton as Button

func _ready() -> void:
	line_edit.text = text
	if (Engine.is_editor_hint()):
		remove_button.icon = EditorInterface.get_base_control().get_theme_icon("GuiClose", "EditorIcons")

func set_text(value: String) -> void:
	text = value
	if line_edit:
		line_edit.text = value
