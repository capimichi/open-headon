class_name PlayerHudController
extends Control

## Displays live Shield, Fuel, Gun Ammo, Special Ammo, Lives, and Score for one player.

@export var target_player_id: int = 1
@export var player_label_text: String = "P1"
@export var player_theme_color: Color = Color(0.3, 1.0, 0.4)

@onready var title_label: Label = $VBox/Header/TitleLabel
@onready var score_label: Label = $VBox/Header/ScoreLabel
@onready var lives_label: Label = $VBox/Header/LivesLabel

@onready var shield_bar: ProgressBar = $VBox/Bars/ShieldRow/ShieldBar
@onready var fuel_bar: ProgressBar = $VBox/Bars/FuelRow/FuelBar
@onready var gun_bar: ProgressBar = $VBox/Bars/GunRow/GunBar
@onready var gun_badge: Label = $VBox/Bars/GunRow/GunBadge
@onready var special_bar: ProgressBar = $VBox/Bars/SpecialRow/SpecialBar
@onready var special_badge: Label = $VBox/Bars/SpecialRow/SpecialBadge

const SPECIAL_NAMES: Array[String] = ["BOMB", "MSL", "WAVE", "BOOST"]

func _ready() -> void:
	if title_label:
		title_label.text = player_label_text
		title_label.modulate = player_theme_color
		
	EventBus.ship_shield_changed.connect(_on_shield_changed)
	EventBus.ship_fuel_changed.connect(_on_fuel_changed)
	EventBus.ship_ammo_changed.connect(_on_ammo_changed)
	EventBus.score_updated.connect(_on_score_updated)
	EventBus.ship_destroyed.connect(_on_ship_destroyed)
	
	# Initial full bars
	_update_bar(shield_bar, 1.0, Color(0.2, 0.9, 0.3))
	_update_bar(fuel_bar, 1.0, Color(0.1, 0.7, 1.0))
	_update_bar(gun_bar, 1.0, Color(1.0, 0.85, 0.2))
	_update_bar(special_bar, 1.0, Color(0.9, 0.3, 1.0))

func _on_shield_changed(p_id: int, current: int, max_val: int) -> void:
	if p_id != target_player_id:
		return
	var pct = clampf(float(current) / float(max_val), 0.0, 1.0)
	var col = Color(0.2, 0.9, 0.3) # Green
	if pct < 0.25:
		col = Color(1.0, 0.2, 0.2) # Red
	elif pct < 0.50:
		col = Color(1.0, 0.75, 0.1) # Orange/Yellow
	_update_bar(shield_bar, pct, col)

func _on_fuel_changed(p_id: int, current: int, max_val: int) -> void:
	if p_id != target_player_id:
		return
	var pct = clampf(float(current) / float(max_val), 0.0, 1.0)
	var col = Color(0.1, 0.7, 1.0) if pct > 0.2 else Color(1.0, 0.3, 0.1)
	_update_bar(fuel_bar, pct, col)

func _on_ammo_changed(p_id: int, weapon_slot: int, current: int) -> void:
	if p_id != target_player_id:
		return
	var pct = clampf(float(current) / float(ShipState.MAX_RESOURCE_VALUE), 0.0, 1.0)
	if weapon_slot == 1:
		_update_bar(gun_bar, pct, Color(1.0, 0.85, 0.2))
	elif weapon_slot == 2:
		_update_bar(special_bar, pct, Color(0.9, 0.3, 1.0))

func update_weapon_selection(gun_idx: int, special_idx: int) -> void:
	if gun_badge:
		gun_badge.text = "G%d" % gun_idx
	if special_badge:
		var s_name = SPECIAL_NAMES[clampi(special_idx - 1, 0, 3)]
		special_badge.text = s_name

func _on_score_updated(p_id: int, new_score: int) -> void:
	if p_id == target_player_id and score_label:
		score_label.text = "%05d" % new_score

func _on_ship_destroyed(victim_id: int, _killer_id: int) -> void:
	if victim_id == target_player_id and lives_label:
		# Update lives display
		var cur_text = lives_label.text
		if cur_text.length() > 0:
			lives_label.text = cur_text.substr(0, cur_text.length() - 1)

func _update_bar(bar: ProgressBar, pct: float, col: Color) -> void:
	if not bar:
		return
	bar.value = pct * 100.0
	var style = bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	if not style:
		style = StyleBoxFlat.new()
	style.bg_color = col
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	bar.add_theme_stylebox_override("fill", style)
