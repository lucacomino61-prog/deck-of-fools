extends TestCase
## Coming back (Luca, 2026-10-22): the tour diary, the welcome-back gift, today's card, the
## best score of each show (the goal bar's ghost), a played run always paying a scudo, and
## the station board's lines.


func _real() -> void:
	ContentPacks.register_all()
	TestContent.add_test_defs()


func test_diary_and_welcome_back() -> void:
	var p := Profile.new()
	ok(p.visit("2026-10-01"), "a first visit is noted")
	ok(p.welcome.is_empty() and p.scudi == 0, "no gift on a first visit")
	ok(not p.visit("2026-10-01"), "the same day again changes nothing")
	p.visit("2026-10-02")
	ok(p.welcome.is_empty(), "back the next day: no gift needed")
	p.visit("2026-10-05")
	eq(p.scudi, Profile.WELCOME_SCUDI, "back after 3 days: a gift of scudi")
	eq(p.welcome, {"date": "2026-10-05", "scudi": Profile.WELCOME_SCUDI, "away": 3}, "the board can say so")
	eq(p.days_this_week("2026-10-05"), 3, "three days played in the week up to today")
	eq(p.days, ["2026-10-01", "2026-10-02", "2026-10-05"], "a missed day takes nothing away")
	eq(Profile.days_between("2026-10-30", "2026-11-02"), 3, "days count across months")
	var again := Profile.from_dict(p.to_dict())
	eq(again.days, p.days, "the diary is saved")
	eq(again.welcome, p.welcome, "so is the gift")


func test_card_of_the_day() -> void:
	_real()
	var today := Profile.card_of_the_day("2026-10-22")
	ok(ContentDB.get_def(today) != null and ContentDB.get_def(today).kind == "prop", "today's card is a Wagon prop")
	eq(Profile.card_of_the_day("2026-10-22"), today, "the same all day, for everyone")
	ok(Profile.card_of_the_day("2026-10-23") != today, "a new card tomorrow")
	var p := Profile.new()
	var extras := p.extras_for("", today)
	eq(extras["props"], [today], "it comes along free")
	eq(extras["day_card"], today, "and the run knows it's today's card")
	p.carried.assign([today])
	ok(not p.extras_for("", today).has("day_card"), "not twice when it's carried anyway")
	var run := RunState.create("DAY", "standard", 1, "", [], Profile.new().extras_for("", today))
	eq(run.props, [today], "the run has it")
	ok(run.assisted(), "a helped run, off the leaderboards like any prop")


func test_show_best() -> void:
	var run := RunState.new()
	run.stake = 2
	run.town = 3
	run.show_index = 1
	run.show_score = 900.0
	var p := Profile.new()
	eq(p.note_show(run), 0.0, "no best before the first time")
	eq(p.best_for(run), 900.0, "the score is kept")
	run.show_score = 700.0
	eq(p.note_show(run), 900.0, "the best before")
	eq(p.best_for(run), 900.0, "a lower score doesn't replace it")
	run.show_index = 2
	eq(p.best_for(run), 0.0, "each show has its own")
	eq(Profile.from_dict(p.to_dict()).show_best, {"2/3/1": 900.0}, "records are saved")


func test_a_played_run_pays() -> void:
	_real()
	var run := RunState.new()
	run.counters = {"hands_played": 2}
	eq(WagonCards.scudi_for(run), [{"src": "bow", "v": WagonCards.PER_RUN}] as Array[Dictionary], "a run lost early still pays a scudo")
	run.counters = {}
	ok(WagonCards.scudi_for(run).is_empty(), "a run never played pays nothing")


func test_board_lines() -> void:
	_real()
	var p := Profile.new()
	var first := TitleScreen.greeting(p, "2026-10-22", null)
	eq(first.size(), TitleScreen.INFO_ROWS, "four lines")
	eq(first[0], TitleScreen.line("WELCOME", "TO THE TOUR OF ITALY", ""), "a first visit's lines match the loading page's")
	eq(first[1], TitleScreen.line("FIRST", "BERGAMO, MATINEE", ""), "the first show")
	ok(first.all(func(l: String) -> bool: return l.length() == TitleScreen.INFO_COLS), "every line fills the row")
	p.total_wins = 1
	p.welcome = {"date": "2026-10-22", "scudi": 5}
	p.nemesis = {"patron": "pt_badessa", "town": 3}
	var lines := TitleScreen.greeting(p, "2026-10-22", null)
	ok(lines[0].begins_with("WELCOME BACK"), "a gift for coming back comes first")
	ok(lines[1].begins_with("TODAY"), "then today's card")
	ok(lines[2].begins_with("NEMESIS ") and lines[2].ends_with("TOWN 3"), "then the nemesis and where it waits")
	ok(lines.all(func(l: String) -> bool: return l.length() == TitleScreen.INFO_COLS), "all fill the row")
	eq(TitleScreen.line("TODAY", "BAULE DEI COSTUMI", "FREE"), "TODAY   BAULE DEI COSTUMI   FREE", "label, value, and the short note on the right")
