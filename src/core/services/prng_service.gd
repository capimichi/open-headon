class_name PrngService
extends RefCounted

## Deterministic Pseudo-Random Number Generator extracted from HEAD-ON binary (0x4086f0).
## Formula: seed = (seed - rotate_right_32(seed, 7)) mod 2^32

const DEFAULT_SEED: int = 0x2dcd74e7
const HIGH_SCORE_SEED: int = 0x9ad85

var current_seed: int = DEFAULT_SEED

func _init(seed_val: int = DEFAULT_SEED) -> void:
	set_seed(seed_val)

func set_seed(new_seed: int) -> void:
	if new_seed == 0:
		current_seed = DEFAULT_SEED
	else:
		current_seed = new_seed & 0xFFFFFFFF

func next_u32() -> int:
	var ror7 = ((current_seed >> 7) | ((current_seed << 25) & 0xFFFFFFFF)) & 0xFFFFFFFF
	current_seed = (current_seed - ror7) & 0xFFFFFFFF
	return current_seed

func next_range(min_val: int, max_val: int) -> int:
	if min_val >= max_val:
		return min_val
	var span = (max_val - min_val) + 1
	return min_val + (next_u32() % span)
