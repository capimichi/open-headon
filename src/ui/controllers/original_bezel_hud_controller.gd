class_name OriginalBezelHudController
extends Control

## Authentic Head-On HUD controller that operates directly inside the framev640 bezel.
## Animates the original CRT meters by adjusting dark depleted covers over the slot gradients.

const BAR_WIDTH: float = 82.0
const EMPTY_COLOR: Color = Color(0.0, 0.22, 0.184, 1.0) # Authentic dark slot color

# P1 Bezel Nodes
@onready var p1_shield_cover: ColorRect = $P1_ShieldCover
@onready var p1_fuel_cover: ColorRect = $P1_FuelCover
@onready var p1_gun_cover: ColorRect = $P1_GunCover
@onready var p1_special_cover: ColorRect = $P1_SpecialCover
@onready var p1_lives_label: Label = $P1_LivesLabel
@onready var p1_score_label: Label = $P1_ScoreLabel

# P2 Bezel Nodes
@onready var p2_shield_cover: ColorRect = $P2_ShieldCover
@onready var p2_fuel_cover: ColorRect = $P2_FuelCover
@onready var p2_gun_cover: ColorRect = $P2_GunCover
@onready var p2_special_cover: ColorRect = $P2_SpecialCover
@onready var p2_lives_label: Label = $P2_LivesLabel
@onready var p2_score_label: Label = $P2_ScoreLabel

func _ready() -> void:
	EventBus.ship_shield_changed.connect(_on_shield_changed)
	EventBus.ship_fuel_changed.connect(_on_fuel_changed)
	EventBus.ship_ammo_changed.connect(_on_ammo_changed)
	EventBus.score_updated.connect(_on_score_updated)
	EventBus.ship_destroyed.connect(_on_ship_destroyed)
	
	# Start with full meters (cover width = 0)
	_set_cover(p1_shield_cover, 18.0, 1.0)
	_set_cover(p1_fuel_cover, 18.0, 1.0)
	_set_cover(p1_gun_cover, 119.0, 1.0)
	_set_cover(p1_special_cover, 119.0, 1.0)
	
	_set_cover(p2_shield_cover, 338.0, 1.0)
	_set_cover(p2_fuel_cover, 338.0, 1.0)
	_set_cover(p2_gun_cover, 439.0, 1.0)
	_set_cover(p2_special_cover, 439.0, 1.0)

func _on_shield_changed(p_id: int, current: int, max_val: int) -> void:
	var pct = clampf(float(current) / float(max_val), 0.0, 1.0)
	if p_id == 1:
		_set_cover(p1_shield_cover, 18.0, pct)
	elif p_id == 2:
		_set_cover(p2_shield_cover, 338.0, pct)

func _on_fuel_changed(p_id: int, current: int, max_val: int) -> void:
	var pct = clampf(float(current) / float(max_val), 0.0, 1.0)
	if p_id == 1:
		_set_cover(p1_fuel_cover, 18.0, pct)
	elif p_id == 2:
		_set_cover(p2_fuel_cover, 338.0, pct)

func _on_ammo_changed(p_id: int, weapon_slot: int, current: int) -> void:
	var pct = clampf(float(current) / float(ShipState.MAX_RESOURCE_VALUE), 0.0, 1.0)
	if p_id == 1:
		if weapon_slot == 1:
			_set_cover(p1_gun_cover, 119.0, pct)
		elif weapon_slot == 2:
			_set_cover(p1_special_cover, 119.0, pct)
	elif p_id == 2:
		if weapon_slot == 1:
			_set_cover(p2_gun_cover, 439.0, pct)
		elif weapon_slot == 2:
			_set_cover(p2_special_cover, 439.0, pct)

func _on_score_updated(p_id: int, new_score: int) -> void:
	if p_id == 1 and p1_score_label:
		p1_score_label.text = "%05d" % new_score
	elif p_id == 2 and p2_score_label:
		p2_score_label.text = "%05d" % new_score

func _on_ship_destroyed(victim_id: int, _killer_id: int) -> void:
	if victim_id == 1 and p1_lives_label:
		var txt = p1_lives_label.text
		if txt.length() > 0:
			p1_lives_label.text = txt.substr(0, txt.length() - 1)
	elif victim_id == 2 and p2_lives_label:
		var txt = p2_lives_label.text
		if txt.length() > 0:
			p2_lives_label.text = txt.substr(0, txt.length() - 1)

## Positions and sizes the dark cover from right-to-left over the depleted fraction
func _set_cover(cover: ColorRect, slot_x: float, pct: float) -> void:
	if not cover:
		return
	var fill_w = BAR_WIDTH * pct
	var depleted_w = BAR_WIDTH - fill_w
	cover.position.x = slot_x + fill_w
	cover.size.x = depleted_w
