extends Resource
class_name PlayerData

@export var name: String = "Unnamed"
@export var position: String = "UTIL"
@export var stats: PlayerStats = PlayerStats.new()

# Game stats
var game_stats := {
	"AB": 0, "H": 0, "BB": 0, "HR": 0, "K": 0, "R": 0, "RBI": 0,
	"PA": 0, "2B": 0, "3B": 0, "HBP": 0, "SF": 0
}

# Pitcher stats
var pitching_stats := {
	"IP": 0.0, "H": 0, "R": 0, "ER": 0, "BB": 0, "K": 0, "HR": 0
}

func reset_game_stats():
	for key in game_stats.keys():
		game_stats[key] = 0
	for key in pitching_stats.keys():
		pitching_stats[key] = 0.0 if typeof(pitching_stats[key]) == TYPE_FLOAT else 0

func calc_avg() -> float:
	return game_stats["H"] / max(game_stats["AB"], 1)

func calc_obp() -> float:
	var num = game_stats["H"] + game_stats["BB"] + game_stats["HBP"]
	var den = game_stats["AB"] + game_stats["BB"] + game_stats["HBP"] + game_stats["SF"]
	return num / max(den, 1)

func calc_slg() -> float:
	var total_bases = (game_stats["H"] - game_stats["2B"] - game_stats["3B"] - game_stats["HR"]) \
		+ 2 * game_stats["2B"] + 3 * game_stats["3B"] + 4 * game_stats["HR"]
	return total_bases / max(game_stats["AB"], 1)

func calc_ops() -> float:
	return calc_obp() + calc_slg()


var season_stats := {
	"AB": 0, "H": 0, "BB": 0, "HR": 0, "K": 0, "R": 0, "RBI": 0,
	"PA": 0, "2B": 0, "3B": 0, "HBP": 0, "SF": 0
}

func add_to_season_stats():
	for stat in game_stats.keys():
		season_stats[stat] += game_stats[stat]

func reset_season_stats():
	for key in season_stats.keys():
		season_stats[key] = 0
