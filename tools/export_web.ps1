# Exports the web build (build\web) and the preview build (build\web-preview). The preview
# build has the feature tag "preview" and opens one screen from ?screen=<name> (see
# game\tests\preview.gd), for tools\shoot.mjs.
$godot = $env:GODOT
if (-not $godot) { $godot = "C:\Users\User\Tools\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe" }
$project = (Resolve-Path (Join-Path $PSScriptRoot "..\game")).Path
$builds = @{ "Web" = "build\web"; "Web preview" = "build\web-preview" }
foreach ($preset in $builds.Keys) {
	$dir = Join-Path $PSScriptRoot "..\$($builds[$preset])"
	New-Item -ItemType Directory -Force $dir | Out-Null
	$lines = & $godot --headless --path $project --export-release $preset (Join-Path (Resolve-Path $dir).Path "index.html") 2>&1 | ForEach-Object { "$_" }
	# Godot's own error lines only: a file can be called error.wav.
	if ($LASTEXITCODE -ne 0 -or ($lines | Select-String -CaseSensitive -Pattern "^(SCRIPT )?ERROR:")) {
		$lines
		throw "export of '$preset' failed"
	}
	# The loading page (game\web\shell.html) draws the departures board in the game's own font.
	Remove-Item (Join-Path $dir "curtain.webp") -ErrorAction SilentlyContinue
	Copy-Item (Join-Path $project "fonts\outfit-latin.woff2") (Join-Path $dir "outfit.woff2") -Force
	"exported '$preset' to $($builds[$preset])"
}
