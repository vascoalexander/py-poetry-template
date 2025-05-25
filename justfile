# Variablen für den Docker-Container
set dotenv-load

SRC_DIR := `pwd`
PYTHON_VERSION := env_var("PYTHON_VERSION")
PACKAGE_NAME := `basename $(find src -maxdepth 1 -mindepth 1 -type d ! -name "__pycache__")`
CONTAINER_PATH := "/opt/poetry/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
CONTAINER_IMAGE := PACKAGE_NAME + ":dev"

# -- HELFER --
# Zeigt alle verfügbaren Rezepte an
list:
    @just --list

# Build Docker Image
build:
    @echo "Building Docker development image: {{CONTAINER_IMAGE}} with Python ${PYTHON_VERSION}..."
    docker build \
        -f Dockerfile.dev \
        -t {{CONTAINER_IMAGE}} \
        --build-arg PYTHON_VERSION="{{PYTHON_VERSION}}" \
        .

# Löscht das Docker-Image
clean:
    @echo "Removing Docker image: {{CONTAINER_IMAGE}}"
    docker rmi {{CONTAINER_IMAGE}} || true

# Startet eine interaktive Shell im Development-Container
shell: build
    @echo "Starting interactive shell in development container..."
    docker run -it --rm \
        -e PATH="{{CONTAINER_PATH}}" \
        -v {{SRC_DIR}}:/app \
        {{CONTAINER_IMAGE}} \
        bash

# Linting-Checks
lint: build
    @echo "Running linting checks..."
    docker run --rm \
        -e PATH="{{CONTAINER_PATH}}" \
        -v {{SRC_DIR}}:/app \
        {{CONTAINER_IMAGE}} \
        poetry run ruff check /app/src /app/tests

# Checks: Formatierung, Linting, Type-Checking, Tests
check: build
    @echo "Running all checks: Formatting, Linting, Type Checking, Tests..."
    docker run --rm \
        -e PATH="{{CONTAINER_PATH}}" \
        -v {{SRC_DIR}}:/app \
        {{CONTAINER_IMAGE}} \
        bash -c " \
            poetry run ruff format src tests && \
            poetry run ruff check src tests && \
            poetry run mypy src tests && \
            poetry run pytest src tests \
        "

# Code formatieren
format: build
    @echo "Formatting code..."
    docker run --rm \
        -e PATH="{{CONTAINER_PATH}}" \
        -v {{SRC_DIR}}:/app \
        {{CONTAINER_IMAGE}} \
        poetry run ruff format /app/src /app/tests

# Tests ausführen
test: build
    @echo "Running tests..."
    docker run --rm \
        -e PATH="{{CONTAINER_PATH}}" \
        -v {{SRC_DIR}}:/app \
        {{CONTAINER_IMAGE}} \
        poetry run pytest /app/tests

# Test Coverage
coverage: build
    @echo "Running pytest coverage..."
    docker run --rm \
        -e PATH="{{CONTAINER_PATH}}" \
        -v {{SRC_DIR}}:/app \
        {{CONTAINER_IMAGE}} \
        poetry run pytest --cov=src --cov-report=term-missing

# HTML Coverage Report generieren und direkt auf den Host speichern
coverage-html: build
    @echo "Generating HTML coverage report..."
    @mkdir -p coverage_reports/htmlcov
    docker run --rm \
        -e PATH="{{CONTAINER_PATH}}" \
        -v {{SRC_DIR}}:/app \
        -v $(pwd)/coverage_reports/htmlcov:/app/htmlcov \
        {{CONTAINER_IMAGE}} \
        poetry run pytest --cov=src --cov-report=html:/app/htmlcov

    @echo "HTML coverage report generated in coverage_reports/htmlcov/ (on your host)."
    @echo "You can open coverage_reports/htmlcov/index.html in your browser."

# Führt pre-commit Hooks manuell im Container aus
pre-commit: build
    @echo "Running pre-commit hooks in container..."
    docker run --rm \
        -e PATH="{{CONTAINER_PATH}}" \
        -v {{SRC_DIR}}:/app \
        {{CONTAINER_IMAGE}} \
        poetry run pre-commit run --all-files

# Startet die Anwendung
run: build
    @echo "Running the application..."
    docker run --rm \
        -e PATH="{{CONTAINER_PATH}}" \
        -v {{SRC_DIR}}:/app \
        {{CONTAINER_IMAGE}} \
        poetry run python /app/src/{{PACKAGE_NAME}}/main.py