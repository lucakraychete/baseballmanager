extends Node

const STAT_MIN: int = 1
const STAT_MAX: int = 13

func _rand_gauss(mean: float, stddev: float) -> float:
	var u1 = randf()
	var u2 = randf()
	var z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2)
	return z0 * stddev + mean

func generate_overall_rating() -> int:
	var val = int(round(_rand_gauss(26, 5)))
	if val < 26:
		val = int(round((26 - val) * (2.0 / 5.0) + val))
	elif val > 52:
		val = 52
	return val

func generate_sub_ratings(target_sum: int) -> PlayerStats:
	var combos: Array = []

	for c in range(STAT_MIN, STAT_MAX + 1):
		for p in range(STAT_MIN, STAT_MAX + 1):
			for pw in range(STAT_MIN, STAT_MAX + 1):
				for v in range(STAT_MIN, STAT_MAX + 1):
					if c + p + pw + v == target_sum:
						combos.append([c, p, pw, v])

	if combos.is_empty():
		var avg = clamp(int(target_sum / 4.0), STAT_MIN, STAT_MAX)
		var fallback = [avg, avg, avg, clamp(target_sum - 3 * avg, STAT_MIN, STAT_MAX)]
		return _array_to_stats(fallback)

	var tries = 20
	while tries > 0:
		var choice = combos[randi() % combos.size()]
		if 13 in choice and randf() >= 0.9:
			return _array_to_stats(choice)
		elif 12 in choice and randf() >= 0.75:
			return _array_to_stats(choice)
		elif not (12 in choice or 13 in choice):
			return _array_to_stats(choice)
		tries -= 1

	return _array_to_stats(combos[randi() % combos.size()])


func _array_to_stats(arr: Array) -> PlayerStats:
	var s = PlayerStats.new()
	s.contact   = arr[0]
	s.precision = arr[1]
	s.power     = arr[2]
	s.vision    = arr[3]
	return s

func generate_pitcher_stats() -> PlayerStats:
	var s = PlayerStats.new()
	s.velocity = randi_range(STAT_MIN, STAT_MAX)
	s.stuff    = randi_range(STAT_MIN, STAT_MAX)
	s.movement = randi_range(STAT_MIN, STAT_MAX)
	s.control  = randi_range(STAT_MIN, STAT_MAX)
	s.contact = 0
	s.precision = 0
	s.power = 0
	s.vision = 0
	return s

func create_player(name: String = "Player", position: String = "?") -> PlayerData:
	var pd = PlayerData.new()
	pd.name = name
	pd.position = position

	if position == "P":
		pd.stats = generate_pitcher_stats()
	else:
		var overall = generate_overall_rating()
		pd.stats = generate_sub_ratings(overall)

	return pd
