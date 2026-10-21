extends SceneTree
## Headless test runner: runs every test_* method in res://tests/test_*.gd, each on fresh
## test content. Use tools/test.ps1, which imports the project first.

const TEST_DIR := "res://tests/"


func _initialize() -> void:
	var files: Array[String] = []
	for f in DirAccess.get_files_at(TEST_DIR):
		if f.begins_with("test_") and f.ends_with(".gd"):
			files.append(f)
	files.sort()
	var passed := 0
	var failed := 0
	for f in files:
		var script: GDScript = load(TEST_DIR + f)
		for m in script.get_script_method_list():
			var method: String = m["name"]
			if not method.begins_with("test_"):
				continue
			TestContent.register_all()
			var tc: TestCase = script.new()
			tc.call(method)
			if tc.checks == 0:
				tc.failures.append("no checks ran (did it crash?)")
			if tc.failures.is_empty():
				passed += 1
			else:
				failed += 1
				print("FAIL %s :: %s" % [f, method])
				for msg in tc.failures:
					print("    " + msg)
	print("%d passed, %d failed" % [passed, failed])
	# Drop the content callbacks before the engine unloads their scripts.
	ContentDB.reset()
	quit(1 if failed > 0 else 0)
