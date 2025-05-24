# Variablen für den Docker-Container
set dotenv-load

CONTAINER_IMAGE := "py-poetry-app:dev"
SRC_DIR := `pwd`

PACKAGE_NAME := `basename $(find src -maxdepth 1 -mindepth 1 -type d ! -name "__pycache__")`

# -- HELFER --
# Zeigt alle verfügbaren Rezepte an
list:
    @just --list

# -- DOCKER MANAGEMENT --

build:
    @echo "Building Docker development image: {{CONTAINER_IMAGE}} with Python ${PYTHON_VERSION}..."
    # Die Änderungen hier sind, dass der Punkt als letztes Argument direkt auf der gleichen Zeile
    # oder mit einem korrekten Zeilenumbruch mit Backslash steht.
    docker build \
        -f Dockerfile.dev \
        -t {{CONTAINER_IMAGE}} \
        --build-arg PYTHON_VERSION="{{PYTHON_VERSION}}" \
        .

# Löscht das Docker-Image
clean-image:
    @echo "Removing Docker image: {{CONTAINER_IMAGE}}"
    docker rmi {{CONTAINER_IMAGE}} || true # '|| true' verhindert Fehler, wenn Image nicht existiert

# Startet eine interaktive Shell im Development-Container
# Dein lokaler Code wird unter /app gemountet.
shell: build
    @echo "Starting interactive shell in development container..."
    docker run -it --rm \
        -v {{SRC_DIR}}:/app \
        {{CONTAINER_IMAGE}} \
        bash

# -- PROJEKT-SPEZIFISCHE AUFGABEN (IM CONTAINER AUSGEFÜHRT) --

# Führt den Ruff Linter/Formatter im Container aus
check: build
    @echo "Running Ruff checks in container..."
    docker run --rm \
        -v {{SRC_DIR}}:/app \
        {{CONTAINER_IMAGE}} \
        poetry run ruff check .

# Führt den Ruff Formatter im Container aus
format: build
    @echo "Running Ruff formatter in container..."
    docker run --rm \
        -v {{SRC_DIR}}:/app \
        {{CONTAINER_IMAGE}} \
        poetry run ruff format .

# Führt die Pytest Tests im Container aus
test: build
    @echo "Running Pytest tests in container..."
    docker run --rm \
        -v {{SRC_DIR}}:/app \
        {{CONTAINER_IMAGE}} \
        poetry run pytest

# Führt pre-commit Hooks aus.
pre-commit-run: build
    @echo "Running pre-commit hooks in container..."
    docker run --rm \
        -v {{SRC_DIR}}:/app \
        {{CONTAINER_IMAGE}} \
        poetry run pre-commit run --all-files

# Beispiel: Projekt starten (wenn es eine ausführbare Komponente hat)
# Ersetze <package> durch den tatsächlichen Namen deines Python-Pakets, z.B. "my_app"
run: build
    @echo "Running main application ({{PACKAGE_NAME}}) in container..."
    docker run --rm \
        -v {{SRC_DIR}}:/app \
        {{CONTAINER_IMAGE}} \
        poetry run python src/{{PACKAGE_NAME}}/main.py