# Makes a self-signed certificate in build\cert so tools/serve_web.js also serves HTTPS (on
# its port + 1) for playing the web build on a phone on the same network: Godot's web build
# only starts in a secure context, and plain HTTP to a network address isn't one. The phone
# warns once that the connection isn't private; accept it to play.
#   powershell -File tools\phone_cert.ps1
$ErrorActionPreference = 'Stop'
$openssl = 'C:\Program Files\Git\mingw64\bin\openssl.exe'
$dir = Join-Path $PSScriptRoot '..\build\cert'
New-Item -ItemType Directory -Force $dir | Out-Null

# Every IPv4 address this computer has on a network, so the certificate names the one the phone uses.
$ips = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } | ForEach-Object { "IP:$($_.IPAddress)" }
$names = (@('DNS:localhost', 'IP:127.0.0.1') + $ips) -join ','

# openssl prints key-generation progress on stderr, which PowerShell 5.1 would raise as an error:
# judge it by the exit code instead.
$ErrorActionPreference = 'Continue'
& $openssl req -x509 -newkey rsa:2048 -nodes -days 825 -subj '/CN=Deck of Fools on this network' `
  -addext "subjectAltName=$names" -keyout (Join-Path $dir 'key.pem') -out (Join-Path $dir 'cert.pem') 2>$null
if ($LASTEXITCODE -ne 0) { throw "openssl failed ($LASTEXITCODE)" }
Write-Output "Certificate for $names in $((Resolve-Path $dir).Path)"
