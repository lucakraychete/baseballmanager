extends Node
class_name GameSimulator

const STAT_TABLE = {
	"contact":   [.27, .25, .23, .21, .19, .17, .14, .13, .12, .11, .10, .09, .08],
	"precision": [.240, .250, .260, .270, .280, .290, .300, .310, .320, .330, .340, .350, .360],
	"power":     [.015, .02 , .025, .03 , .035, .04 , .045, .050, .055, .061, .068, .076, .085],
	"vision":    [.032, .035, .040, .047, .056, .067, .08 , .091, .104, .119, .136, .155, .176],
	"velocity":  [.08, .09, .10, .11, .12, .13, .14, .17, .19, .21, .23, .25, .27],
	"stuff":     [.360, .350, .340, .330, .320, .310, .300, .290, .280, .270, .260, .250, .240],
	"movement":  [.085, .076, .068, .061, .055, .050, .045, .040, .035, .030, .025, .020, .015],
	"control":   [.176, .155, .136, .119, .104, .091, .08 , .067, .056, .047, .040, .035, .032]
}

func log5(p1: float, p2: float, constant: float) -> float:
	return (p1 * p2 * (1.0 - constant)) / ((p1 * p2) - (p1 * constant) - (p2 * constant) + constant)

func plate_appearance(hitter: PlayerData, pitcher: PlayerData) -> String:
	var h = hitter.stats
	var p = pitcher.stats
	var r = randf()

	if r < log5(STAT_TABLE["vision"][h.vision - 1], STAT_TABLE["control"][p.vision - 1], STAT_TABLE["vision"][6]):
		hitter.game_stats["BB"] += 1
		hitter.game_stats["PA"] += 1
		pitcher.pitching_stats["BB"] += 1
		return "Walk"

	r = randf()
	if r < (13 - h.vision) / 100 + log5(STAT_TABLE["contact"][h.contact - 1], STAT_TABLE["velocity"][p.contact - 1], STAT_TABLE["contact"][6]):
		hitter.game_stats["K"] += 1
		hitter.game_stats["AB"] += 1
		hitter.game_stats["PA"] += 1
		pitcher.pitching_stats["K"] += 1
		return "Strikeout"

	r = randf()
	if r < log5(STAT_TABLE["power"][h.power - 1], STAT_TABLE["movement"][p.power - 1], STAT_TABLE["power"][6]):
		hitter.game_stats["HR"] += 1
		hitter.game_stats["H"] += 1
		hitter.game_stats["AB"] += 1
		hitter.game_stats["PA"] += 1
		pitcher.pitching_stats["HR"] += 1
		pitcher.pitching_stats["H"] += 1
		return "Homerun"

	r = randf()
	if r < log5(STAT_TABLE["precision"][h.precision - 1], STAT_TABLE["stuff"][p.precision - 1], STAT_TABLE["stuff"][6]):
		hitter.game_stats["H"] += 1
		hitter.game_stats["AB"] += 1
		hitter.game_stats["PA"] += 1
		pitcher.pitching_stats["H"] += 1

		var roll = randf()
		if roll < 0.05:
			hitter.game_stats["3B"] += 1
			return "Triple"
		elif roll < 0.15:
			hitter.game_stats["2B"] += 1
			return "Double"
		else:
			return "Single"

	hitter.game_stats["AB"] += 1
	hitter.game_stats["PA"] += 1
	return "Out"

func simulate_game(team1: TeamData, team2: TeamData) -> Dictionary:
	var results = {
		"team1": {"runs": 0, "hits": 0, "players": team1.players, "name": team1.name},
		"team2": {"runs": 0, "hits": 0, "players": team2.players, "name": team2.name}
	}

	for p in team1.players: p.reset_game_stats()
	for p in team2.players: p.reset_game_stats()

	var batting_order_t1: Array[PlayerData] = team1.players.slice(0, 9)
	var batting_order_t2: Array[PlayerData] = team2.players.slice(0, 9)

	var order_index = {"team1": 0, "team2": 0}

	for inning in range(9):
		for side in ["team1", "team2"]:
			var lineup = batting_order_t1 if side == "team1" else batting_order_t2
			var pitcher_pool = team2.players if side == "team1" else team1.players
			var pitcher = pitcher_pool[randi() % pitcher_pool.size()]

			var outs = 0
			var bases = [null, null, null]
			var runs = 0
			var hits = 0
			var idx = order_index[side]

			while outs < 3:
				var batter = lineup[idx % 9]
				var result = plate_appearance(batter, pitcher)

				if result in ["Single", "Double", "Triple", "Homerun"]:
					hits += 1

				var runners_scored = 0
				if result == "Walk":
					if bases[2]: runners_scored += 1
					bases = [batter, bases[0], bases[1]]
				elif result == "Single":
					if bases[2]: runners_scored += 1
					if bases[1]: runners_scored += 1
					bases = [batter, bases[0], null]
				elif result == "Double":
					for b in [bases[2], bases[1], bases[0]]:
						if b: runners_scored += 1
					bases = [null, batter, null]
				elif result == "Triple":
					for b in bases:
						if b: runners_scored += 1
					bases = [null, null, batter]
				elif result == "Homerun":
					runners_scored += 1
					for b in bases:
						if b: runners_scored += 1
					bases = [null, null, null]
				elif result in ["Strikeout", "Out"]:
					outs += 1

				batter.game_stats["RBI"] += runners_scored
				runs += runners_scored
				idx += 1

			order_index[side] = idx
			results[side]["runs"] += runs
			results[side]["hits"] += hits
			pitcher.pitching_stats["IP"] += 1.0

	return results
