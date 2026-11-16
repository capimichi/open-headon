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
	# Show splash texture from UI module
	var splash_tex = load("res://src/ui/assets/splash.png")
	if splash_tex:
		var tex_rect = TextureRect.new()
		tex_rect.texture = splash_tex
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		ui_container.add_child(tex_rect)
		
		# Fade/transition to main menu after short delay or key press
		var timer = get_tree().create_timer(1.8)
		timer.timeout.connect(func():
			if current_state == GameState.SPLASH:
				change_state(GameState.MAIN_MENU)
		)

func _show_main_menu() -> void:
	# Clean up previous UI
	for child in ui_container.get_children():
		child.queue_free()
		
	var menu_tex = load("res://src/ui/assets/mainMenu.png")
	if menu_tex:
		var tex_rect = TextureRect.new()
		tex_rect.texture = menu_tex
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		ui_container.add_child(tex_rect)

func _start_match() -> void:
	pass

func _on_game_started(_mode: int) -> void:
	change_state(GameState.MATCH_PLAYING)

func _on_game_over(_winner_id: int) -> void:
	change_state(GameState.GAME_OVER)

func _unhandled_input(event: InputEvent) -> void:
	if current_state == GameState.SPLASH and event.is_pressed():
		change_state(GameState.MAIN_MENU)
