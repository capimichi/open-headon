class_name LevelSelectController
extends Control

## Level Selection Screen matching original state 3 (0x40e180).

signal level_selected(level_id: int)
signal back_requested()

var selected_index: int = 0
const MAX_LEVELS: int = 9

@onready var level_name_label: Label = $LevelNameLabel
@onready var thumbnail_rect: TextureRect = $ThumbnailRect
@onready var level_index_label: Label = $LevelIndexLabel

func _ready() -> void:
	_update_display()

func _update_display() -> void:
	var data = LevelLoaderService.get_level_data(selected_index)
	if not data.is_empty():
		level_name_label.text = data["name"]
		level_index_label.text = "LEVEL %02d / 08" % selected_index
		var thumb_tex = load(data["thumbnail"])
		if thumb_tex:
			thumbnail_rect.texture = thumb_tex

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
		
	if event.is_action_pressed("p1_right") or event.is_action_pressed("p2_right") or event.is_action_pressed("ui_right"):
		selected_index = (selected_index + 1) % MAX_LEVELS
		_update_display()
	elif event.is_action_pressed("p1_left") or event.is_action_pressed("p2_left") or event.is_action_pressed("ui_left"):
		selected_index = (selected_index - 1 + MAX_LEVELS) % MAX_LEVELS
		_update_display()
	elif event.is_action_pressed("ui_accept") or (event is InputEventKey and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER) and event.is_pressed()):
		level_selected.emit(selected_index)
	elif event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.is_pressed()):
		back_requested.emit()
