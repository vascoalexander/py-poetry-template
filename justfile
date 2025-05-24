# Variablen für den Docker-Container
set dotenv-load

CONTAINER_IMAGE := "py-poetry-app:dev"
SRC_DIR := `pwd`
PYTHON_VERSION := env_var("PYTHON_VERSION")
PACKAGE_NAME := `basename $(find src -maxdepth 1 -mindepth 1 -type d ! -name "__pycache__")`
CONTAINER_PATH := "/opt/poetry/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

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
        --no-cache \
        .

# Löscht das Docker-Image
clean-image:
    @echo "Removing Docker image: {{CONTAINER_IMAGE}}"
    docker rmi {{CONTAINER_IMAGE}} || true

# Startet eine interaktive Shell im Development-Container
# Übergibt den sauberen PATH explizit an docker run
shell: build
    @echo "Starting interactive shell in development container..."
    docker run -it --rm \
        -e PATH="{{CONTAINER_PATH}}" \
        -v {{SRC_DIR}}:/app \
        {{CONTAINER_IMAGE}} \
        bash

# Erweiterte Debug-Shell für pre-commit und Git
# Übergibt den sauberen PATH explizit an docker run
debug-pre-commit: build
    @echo "Starting debug shell in container for pre-commit issues..."
    docker run -it --rm \
        -e PATH="{{CONTAINER_PATH}}" \
        -v {{SRC_DIR}}:/app \
        {{CONTAINER_IMAGE}} \
        bash -c " \
            echo '--- CURRENT CONTAINER PATH ---'; \
            echo \$PATH; \
            cd /app; \
            echo '--- Git Version ---'; \
            git --version; \
            echo '--- Git Status in /app ---'; \
            git status; \
            echo '--- Git is-inside-work-tree ---'; \
            git rev-parse --is-inside-work-tree; \
            echo '--- LS .git ---'; \
            ls -la .git; \
            echo '--- Pre-commit Cache Clean ---'; \
            poetry run pre-commit clean; \
            echo '--- Running pre-commit with verbose output ---'; \
            poetry run pre-commit run --all-files --verbose; \
            echo '--- Starting interactive shell ---'; \
            bash \
        "

# Linting-Checks
# Übergibt den sauberen PATH explizit an docker run
check: build
    @echo "Running linting checks..."
    docker run --rm \
        -e PATH="{{CONTAINER_PATH}}" \
        -v {{SRC_DIR}}:/app \
        {{CONTAINER_IMAGE}} \
        poetry run ruff check /app/src /app/tests

# Code formatieren
# Übergibt den sauberen PATH explizit an docker run
format: build
    @echo "Formatting code..."
    docker run --rm \
        -e PATH="{{CONTAINER_PATH}}" \
        -v {{SRC_DIR}}:/app \
        {{CONTAINER_IMAGE}} \
        poetry run ruff format /app/src /app/tests

# Tests ausführen
# Übergibt den sauberen PATH explizit an docker run
test: build
    @echo "Running tests..."
    docker run --rm \
        -e PATH="{{CONTAINER_PATH}}" \
        -v {{SRC_DIR}}:/app \
        {{CONTAINER_IMAGE}} \
        poetry run pytest /app/tests

# Führt pre-commit Hooks manuell im Container aus
# Übergibt den sauberen PATH explizit an docker run
pre-commit-run: build
    @echo "Running pre-commit hooks in container..."
    docker run --rm \
        -e PATH="{{CONTAINER_PATH}}" \
        -v {{SRC_DIR}}:/app \
        {{CONTAINER_IMAGE}} \
        poetry run pre-commit run --all-files

# Startet die Anwendung (beispielhaft)
# Übergibt den sauberen PATH explizit an docker run
run: build
    @echo "Running the application..."
    docker run --rm \
        -e PATH="{{CONTAINER_PATH}}" \
        -v {{SRC_DIR}}:/app \
        {{CONTAINER_IMAGE}} \
        poetry run python /app/src/{{PACKAGE_NAME}}/main.py