extends Node
class_name SeasonScheduler

const TOTAL_GAMES_PER_TEAM := 162

func generate_schedule(teams: Array[String]) -> Array[ScheduledGame]:
	var schedule: Array[ScheduledGame] = []
	var matchups := _generate_balanced_matchups(teams)

	var day := 1
	for match in matchups:
		var game := ScheduledGame.new()
		game.date = day
		game.home_team = match[0]
		game.away_team = match[1]
		schedule.append(game)

		day += 1
		if day > 180:  # Simulated 6-month season
			day = 1

	return schedule


func _generate_balanced_matchups(teams: Array[String]) -> Array:
	var games_per_pair := int(TOTAL_GAMES_PER_TEAM * teams.size() / (teams.size() * (teams.size() - 1)))
	var all_games: Array = []

	for i in range(teams.size()):
		for j in range(i + 1, teams.size()):
			var t1 = teams[i]
			var t2 = teams[j]

			for k in range(games_per_pair):
				if randf() < 0.5:
					all_games.append([t1, t2])
				else:
					all_games.append([t2, t1])

	return all_games
