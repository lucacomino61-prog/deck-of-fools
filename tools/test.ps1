# Runs the Deck of Fools rules tests headless.
#   powershell -ExecutionPolicy Bypass -File tools\test.ps1
# Set $env:GODOT to use a different Godot 4 console binary.

$godot = $env:GODOT
if (-not $godot) { $godot = "C:\Users\User\Tools\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe" }
$project = Join-Path $PSScriptRoot "..\game"

# Import first so class_name scripts are registered.
& $godot --headless --path $project --import *> $null

$lines = & $godot --headless --path $project -s res://tests/run_tests.gd 2>&1 | ForEach-Object { "$_" }
$code = $LASTEXITCODE
$lines | ForEach-Object { Write-Output $_ }

# The fuzz bot plays random runs (every deck, stake and challenge) and checks the run still
# adds up after every action; a longer sweep: -s res://tests/fuzz.gd -- --runs=500 --steps=2200
$fuzz = & $godot --headless --path $project -s res://tests/fuzz.gd -- --runs=60 --steps=900 --seed=11 2>&1 | ForEach-Object { "$_" }
$fuzz | Select-String -Pattern "FUZZ (FAIL|DONE)|ERROR" | ForEach-Object { Write-Output $_ }
if (-not ($fuzz -match "FUZZ DONE .* 0 problems")) {
    Write-Output "The fuzz bot found problems."
    $code = 1
}
$lines += $fuzz

# The UI smoke test drives the real screens through a run (it needs the Game autoload,
# so it runs as a scene rather than a -s script).
$smoke = & $godot --headless --path $project res://tests/ui_smoke.tscn 2>&1 | ForEach-Object { "$_" }
$smoke | Select-String -Pattern "UI SMOKE|ERROR" | ForEach-Object { Write-Output $_ }
if (-not ($smoke -match "UI SMOKE OK")) {
    Write-Output "UI smoke test did not finish."
    $code = 1
}

# The online smoke test runs the game's Online code against the local API, when it's up
# (start it with: npm run dev, in server\).
$online = @()
$api = "http://127.0.0.1:8787"
$up = $false
try { $up = (Invoke-WebRequest "$api/v1/health" -UseBasicParsing -TimeoutSec 2).StatusCode -eq 200 } catch { }
if ($up) {
    $online = & $godot --headless --path $project res://tests/online_smoke.tscn -- --online "--api=$api" "--account-file=user://online_smoke.json" 2>&1 | ForEach-Object { "$_" }
    $online | Select-String -Pattern "ONLINE SMOKE|ERROR" | ForEach-Object { Write-Output $_ }
    if (-not ($online -match "ONLINE SMOKE OK")) {
        Write-Output "Online smoke test did not pass."
        $code = 1
    }
} else {
    Write-Output "Online smoke test skipped: the local API isn't running (npm run dev, in server\)."
}

# A GDScript runtime error doesn't stop the runner, so treat any engine error line as a failure.
$errors = ($lines + $smoke + $online) | Select-String -Pattern "SCRIPT ERROR|Parse Error|^ERROR:"
if ($errors) {
    Write-Output "Engine errors were printed during the run."
    exit 1
}
exit $code
