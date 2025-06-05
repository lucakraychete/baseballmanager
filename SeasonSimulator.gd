extends Node
class_name SeasonSimulator

# ✅ Adjust this to where GameSimulator.gd actually lives in your project
const GameSimulator = preload("res://scripts/GameSimulator.gd")  

var schedule: Array[Dictionary] = []  # Expected format: [{date, home_team, away_team}]
var results: Array = []

func simulate_season() -> Array:
	results.clear()

	for game in schedule:
		var home = load_team(game.home_team)
		var away = load_team(game.away_team)

		if not home or not away:
			push_warning("Skipping game: Missing team '%s' or '%s'" % [game.home_team, game.away_team])
			continue

		for p in home.players:
			p.reset_game_stats()
		for p in away.players:
			p.reset_game_stats()

		var sim = GameSimulator.new()
		var result = sim.simulate_game(home, away)

		for p in home.players:
			p.add_to_season_stats()
		for p in away.players:
			p.add_to_season_stats()

		results.append({
			"date": game.date,
			"home": game.home_team,
			"away": game.away_team,
			"result": result
		})

	return results


func load_team(team_name: String) -> TeamData:
	var path = "user://teams/%s.tres" % team_name
	if not ResourceLoader.exists(path):
		push_error("❌ Team not found: %s" % team_name)
		return null

	var team = ResourceLoader.load(path)
	if team and team is TeamData:
		return team.duplicate()
	else:
		push_error("❌ Invalid TeamData for '%s'" % team_name)
		return null


func save_season_results():
	var file = FileAccess.open("user://season_results.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(results))  # ✅ Correct method for Godot 4.x
		file.close()
		print("✅ Season results saved to: user://season_results.json")
	else:
		push_error("❌ Failed to save season results.")
