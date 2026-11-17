class_name MainGameController
extends Node

## Main Game Entry Point & State Machine (coincides with original 0x401000 loop)

enum GameState {
	SPLASH = 1,
	MAIN_MENU = 2,
	LEVEL_SELECT = 3,
	MATCH_PLAYING = 4,
	GAME_OVER = 5,
	OPTIONS = 6,
	HIGH_SCORES = 7
}

var current_state: GameState = GameState.SPLASH
var active_arena_node: Node2D = null
var selected_level_id: int = 0

@onready var ui_container: Control = $UiContainer
@onready var world_container: Node2D = $WorldContainer

func _ready() -> void:
	print("[Open-HeadOn] Initializing systems...")
	_setup_event_listeners()
	change_state(GameState.SPLASH)

func _setup_event_listeners() -> void:
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_over.connect(_on_game_over)

func change_state(new_state: GameState) -> void:
	current_state = new_state
	print("[Open-HeadOn] Transitioning to state: ", GameState.keys()[current_state - 1])
	match current_state:
		GameState.SPLASH:
			_show_splash()
		GameState.MAIN_MENU:
			_show_main_menu()
		GameState.LEVEL_SELECT:
			_show_level_select()
		GameState.MATCH_PLAYING:
			_start_match(selected_level_id)

func _show_splash() -> void:
	_cleanup_world()
	_cleanup_ui()
	
	var splash_tex = load("res://src/ui/assets/splash.png")
	if splash_tex:
		var tex_rect = TextureRect.new()
		tex_rect.texture = splash_tex
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		ui_container.add_child(tex_rect)
		
		# Transition to main menu after delay
		var timer = get_tree().create_timer(1.8)
		timer.timeout.connect(func():
			if current_state == GameState.SPLASH:
				change_state(GameState.MAIN_MENU)
		)

func _show_main_menu() -> void:
	_cleanup_world()
	_cleanup_ui()
		
	var menu_tex = load("res://src/ui/assets/mainMenu.png")
	if menu_tex:
		var tex_rect = TextureRect.new()
		tex_rect.texture = menu_tex
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		ui_container.add_child(tex_rect)
		
		var label = Label.new()
		label.text = "[ Press SPACE, ENTER or Click to SELECT LEVEL ]"
		label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
		label.position.y = 440
		ui_container.add_child(label)

func _show_level_select() -> void:
	_cleanup_world()
	_cleanup_ui()
	
	var lvl_scene = load("res://src/ui/views/level_select.tscn")
	if lvl_scene:
		var lvl_ctrl = lvl_scene.instantiate() as LevelSelectController
		lvl_ctrl.selected_index = selected_level_id
		lvl_ctrl.level_selected.connect(func(lvl_id: int):
			selected_level_id = lvl_id
			change_state(GameState.MATCH_PLAYING)
		)
		lvl_ctrl.back_requested.connect(func():
			change_state(GameState.MAIN_MENU)
		)
		ui_container.add_child(lvl_ctrl)

func _start_match(level_id: int) -> void:
	_cleanup_ui()
	_cleanup_world()
	
	var arena_scene = load("res://src/environment/views/game_arena.tscn")
	if arena_scene:
		active_arena_node = arena_scene.instantiate() as ArenaController
		active_arena_node.current_level_id = level_id
		world_container.add_child(active_arena_node)

func _cleanup_ui() -> void:
	for child in ui_container.get_children():
		child.queue_free()

func _cleanup_world() -> void:
	for child in world_container.get_children():
		child.queue_free()
	active_arena_node = null

func _on_game_started(mode: int) -> void:
	change_state(GameState.MATCH_PLAYING)

func _on_game_over(_winner_id: int) -> void:
	change_state(GameState.GAME_OVER)

func _unhandled_input(event: InputEvent) -> void:
	if current_state == GameState.SPLASH:
		if event.is_pressed():
			change_state(GameState.MAIN_MENU)
	elif current_state == GameState.MAIN_MENU:
		if event.is_pressed():
			if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
				change_state(GameState.LEVEL_SELECT)
	elif current_state == GameState.MATCH_PLAYING:
		if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.is_pressed()):
			change_state(GameState.LEVEL_SELECT)
