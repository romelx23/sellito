#!/usr/bin/env bash
# Compila la app Flutter Web y la deja dentro del backend para servirla en el mismo puerto.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT/app"
flutter build web --release --dart-define=SAME_ORIGIN=true --base-href /

rm -rf "$ROOT/backend/public/app"
mkdir -p "$ROOT/backend/public/app"
cp -R "$ROOT/app/build/web/." "$ROOT/backend/public/app/"

echo "Listo: backend/public/app"
echo "Ahora: cd backend && npm start"
