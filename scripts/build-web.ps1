# Compila la app Flutter Web y la deja dentro del backend para servirla en el mismo puerto.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

Push-Location (Join-Path $root "app")
try {
    flutter build web --release --dart-define=SAME_ORIGIN=true --base-href /
}
finally {
    Pop-Location
}

$dst = Join-Path $root "backend/public/app"
if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
New-Item -ItemType Directory -Path $dst | Out-Null
Copy-Item (Join-Path $root "app/build/web/*") $dst -Recurse

Write-Host "Listo: backend/public/app"
Write-Host "Ahora: cd backend; npm start"
