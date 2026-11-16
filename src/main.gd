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
		GameState.MATCH_PLAYING:
			_start_match()

func _show_splash() -> void:
	_cleanup_world()
	var splash_tex = load("res://src/ui/assets/splash.png")
	if splash_tex:
		var tex_rect = TextureRect.new()
		tex_rect.texture = splash_tex
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		ui_container.add_child(tex_rect)
		
		# Fade/transition to main menu after delay
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
		
		# Prompt overlay
		var label = Label.new()
		label.text = "[ Press SPACE, ENTER or Click to START TEST FLIGHT ]"
		label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
		label.position.y = 440
		ui_container.add_child(label)

func _start_match() -> void:
	_cleanup_ui()
	_cleanup_world()
	
	var arena_scene = load("res://src/environment/views/test_arena.tscn")
	if arena_scene:
		active_arena_node = arena_scene.instantiate()
		world_container.add_child(active_arena_node)

func _cleanup_ui() -> void:
	for child in ui_container.get_children():
		child.queue_free()

func _cleanup_world() -> void:
	for child in world_container.get_children():
		child.queue_free()
	active_arena_node = null

func _on_game_started(_mode: int) -> void:
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
				change_state(GameState.MATCH_PLAYING)
	elif current_state == GameState.MATCH_PLAYING:
		if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.is_pressed()):
			change_state(GameState.MAIN_MENU)
