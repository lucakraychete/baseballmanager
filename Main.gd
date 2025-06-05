extends Control

@onready var name_field    = $VBoxContainer/TeamNameField
@onready var btn_new_team  = $VBoxContainer/NewTeamButton
@onready var btn_save_team = $VBoxContainer/SaveTeamButton
@onready var team_select_a = $VBoxContainer/TeamSelectA
@onready var team_select_b = $VBoxContainer/TeamSelectB
@onready var btn_load      = $VBoxContainer/LoadTeamButton
@onready var btn_sim       = $VBoxContainer/SimGameButton
@onready var output        = $VBoxContainer/Output
@onready var btn_generate_season = $VBoxContainer/GenerateSeasonButton
@onready var btn_sim_season = $VBoxContainer/SimSeasonButton

@export var roster_size: int = 26
@export var num_hitters: int = 13

var scheduler = SeasonScheduler.new()
var current_roster: Array[PlayerData] = []

func _ready():
	btn_generate_season.pressed.connect(_on_generate_season_pressed)
	btn_sim_season.pressed.connect(_on_sim_season_pressed)
	btn_new_team.pressed.connect(_on_new_team_pressed)
	btn_save_team.pressed.connect(_on_save_team_pressed)
	btn_load.pressed.connect(_on_load_team_pressed)
	btn_sim.pressed.connect(_on_sim_game_pressed)
	refresh_team_dropdown()

func _on_generate_season_pressed():
	var teams := get_team_list()
	var schedule := scheduler.generate_schedule(teams)

	output.text = "[b]Season Schedule Generated[/b]\n[code]"
	for game in schedule:
		output.text += "\nGame Day %d: %s vs %s" % [game.date, game.away_team, game.home_team]
	output.text += "[/code]"

func _on_sim_season_pressed():
	var teams := get_team_list()
	var scheduled_games := scheduler.generate_schedule(teams)

	# Convert ScheduledGame objects to dictionaries
	var converted_schedule: Array[Dictionary] = []
	for game in scheduled_games:
		converted_schedule.append({
			"date": game.date,
			"home_team": game.home_team,
			"away_team": game.away_team
		})

	var season_sim = SeasonSimulator.new()
	season_sim.schedule = converted_schedule
	var results = season_sim.simulate_season()

	season_sim.save_season_results()  # Optional

	output.text = "[b]Season Simulated[/b]\nTotal games: %d" % results.size()


func save_team(team: TeamData):
	var dir_path = "user://teams"
	var file_path = "%s/%s.tres" % [dir_path, team.name]
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_absolute(dir_path)
	var err = ResourceSaver.save(team, file_path)
	if err != OK:
		push_error("❌ Failed to save team %s: %s" % [team.name, error_string(err)])
	else:
		print("✅ Saved team: ", file_path)

func load_team(team_name: String) -> TeamData:
	var path = "user://teams/%s.tres" % team_name
	var loaded = ResourceLoader.load(path)
	if loaded and loaded is TeamData:
		return loaded
	else:
		push_error("❌ Could not load team %s" % team_name)
		return null

func get_team_list() -> Array[String]:
	var team_names: Array[String] = []
	var dir = DirAccess.open("user://teams")
	if dir:
		dir.list_dir_begin()
		var file = dir.get_next()
		while file != "":
			if file.ends_with(".tres"):
				team_names.append(file.get_basename())
			file = dir.get_next()
	return team_names

func refresh_team_dropdown():
	team_select_a.clear()
	team_select_b.clear()
	var team_names = get_team_list()
	for name in team_names:
		team_select_a.add_item(name)
		team_select_b.add_item(name)

func _on_new_team_pressed():
	var lines := ["[b]New Team Roster[/b]"]
	var hitting_positions := ["C", "1B", "2B", "3B", "SS", "LF", "CF", "RF", "DH", "UTIL"]
	var pos_idx := 0
	current_roster.clear()

	var hitters: Array[PlayerData] = []
	var pitchers: Array[PlayerData] = []

	lines.append("\n[u]Hitters[/u]")
	lines.append("[code]")
	lines.append("Name           Pos  Contact  Precision  Power  Vision")
	for i in range(num_hitters):
		var name = "Hitter %02d" % (i + 1)
		var position = hitting_positions[pos_idx % hitting_positions.size()]
		pos_idx += 1
		var pd = PlayerGenerator.create_player(name, position)
		hitters.append(pd)
		lines.append("%-14s %-4s %-8d %-9d %-6d %-6d" % [
			pd.name, pd.position,
			pd.stats.contact, pd.stats.precision, pd.stats.power, pd.stats.vision
		])
	lines.append("[/code]")

	var num_pitchers = roster_size - num_hitters
	lines.append("\n[u]Pitchers[/u]")
	lines.append("[code]")
	lines.append("Name           Pos  Velocity  Stuff  Movement  Control")
	for j in range(num_pitchers):
		var name = "Pitcher %02d" % (j + 1)
		var pd = PlayerGenerator.create_player(name, "P")
		pitchers.append(pd)
		lines.append("%-14s %-4s %-9d %-6d %-9d %-6d" % [
			pd.name, pd.position,
			pd.stats.velocity, pd.stats.stuff, pd.stats.movement, pd.stats.control
		])
	lines.append("[/code]")

	current_roster = hitters + pitchers
	output.text = lines.reduce(func(accum, line): return accum + "\n" + line)

func _on_save_team_pressed():
	var team_name = name_field.text.strip_edges()
	if team_name == "":
		output.text = "[color=red]Please enter a team name before saving.[/color]"
		return
	if current_roster.size() == 0:
		output.text = "[color=red]Generate a team first.[/color]"
		return
	var team = TeamData.new()
	team.name = team_name
	team.players = current_roster.duplicate()
	save_team(team)
	refresh_team_dropdown()
	output.text = "[color=green]Saved team: %s[/color]" % team_name

func _on_load_team_pressed():
	if team_select_a.item_count == 0:
		output.text = "[color=red]No teams to load.[/color]"
		return
	var name = team_select_a.get_item_text(team_select_a.selected)
	var team = load_team(name)
	if team == null:
		output.text = "[color=red]Failed to load team.[/color]"
		return
	var lines := ["[b]Team: %s[/b]" % team.name]

	lines.append("[u]Hitters[/u]")
	lines.append("[code]")
	lines.append("Name           Pos  Contact  Precision  Power  Vision")
	for p in team.players:
		if p.position != "P":
			lines.append("%-14s %-4s %-8d %-9d %-6d %-6d" % [
				p.name, p.position,
				p.stats.contact, p.stats.precision, p.stats.power, p.stats.vision
			])
	lines.append("[/code]")

	lines.append("[u]Pitchers[/u]")
	lines.append("[code]")
	lines.append("Name           Pos  Velocity  Stuff  Movement  Control")
	for p in team.players:
		if p.position == "P":
			lines.append("%-14s %-4s %-9d %-6d %-9d %-6d" % [
				p.name, p.position,
				p.stats.velocity, p.stats.stuff, p.stats.movement, p.stats.control
			])
	lines.append("[/code]")

	output.text = lines.reduce(func(accum, line): return accum + "\n" + line)

func _on_sim_game_pressed():
	if team_select_a.selected == -1 or team_select_b.selected == -1:
		output.text = "[color=red]Select two teams to simulate.[/color]"
		return
	var name1 = team_select_a.get_item_text(team_select_a.selected)
	var name2 = team_select_b.get_item_text(team_select_b.selected)
	if name1 == name2:
		output.text = "[color=orange]Cannot simulate a team against itself.[/color]"
		return
	var team1 = load_team(name1)
	var team2 = load_team(name2)
	if team1 == null or team2 == null:
		output.text = "[color=red]Failed to load one or both teams.[/color]"
		return
	var sim = GameSimulator.new()
	var result = sim.simulate_game(team1, team2)

	var lines := []
	lines.append("[b]Simulated Game Result[/b]")
	lines.append("[i]%s vs %s[/i]" % [team1.name, team2.name])
	lines.append("[code]")
	lines.append("%-20s  Runs  Hits" % "Team")
	lines.append("%-20s  %-5d %-5d" % [team1.name, result["team1"]["runs"], result["team1"]["hits"]])
	lines.append("%-20s  %-5d %-5d" % [team2.name, result["team2"]["runs"], result["team2"]["hits"]])
	lines.append("[/code]")

	output.text = lines.reduce(func(accum, line): return accum + "\n" + line)
