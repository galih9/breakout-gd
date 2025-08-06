extends Node

func generate_random_number(min_val: int = 0, max_val: int = 100) -> int:
	if max_val < min_val:
		push_error("generate_random_number: max_val cannot be less than min_val.")
		return min_val
	return randi() % (max_val - min_val + 1) + min_val

enum POWER_TYPES {
	NONE,
	GUN,
	LASER,
	BIG_PAD
}
