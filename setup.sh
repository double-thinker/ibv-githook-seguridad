#!/usr/bin/env bash
# Prepara el entorno: crea .venv con pip-audit y activa los hooks versionados.
set -euo pipefail
cd "$(dirname "$0")"

rm -rf .venv
if python3 -m venv .venv >/dev/null 2>&1; then
  .venv/bin/python -m pip install --quiet --upgrade pip
  .venv/bin/python -m pip install --quiet pip-audit
elif command -v uv >/dev/null 2>&1 || [ -x "$HOME/.local/bin/uv" ]; then
  # Sin el módulo venv (p. ej. Ubuntu sin python3-venv): usamos uv.
  UV="$(command -v uv || echo "$HOME/.local/bin/uv")"
  rm -rf .venv
  "$UV" venv --quiet --seed --managed-python .venv
  "$UV" pip install --quiet --python .venv pip-audit
else
  echo "ERROR: no puedo crear el entorno virtual."
  echo "Instala python3-venv (sudo apt install python3-venv) o uv (https://docs.astral.sh/uv/)."
  exit 1
fi

git config core.hooksPath .githooks
chmod +x .githooks/pre-commit

echo "Listo. pip-audit instalado en .venv y hooks activados (core.hooksPath=.githooks)."
echo "Prueba ahora a hacer un commit: el hook revisará las dependencias."
