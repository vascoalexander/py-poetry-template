set dotenv-load

# Dynamische Variablen
SRC_DIR := `pwd`
PYTHON_VERSION := env_var("PYTHON_VERSION")
PACKAGE_NAME := `basename $(find src -maxdepth 1 -mindepth 1 -type d ! -name "__pycache__")`
CONTAINER_IMAGE := "{{PACKAGE_NAME}}:dev"
HOST_UID := `id -u`
HOST_GID := `id -g`

# Listet alle verfügbaren Befehle
list:
    @just --list

# Docker-Image bauen mit User-Mapping
build:
    @echo "Building image: {{CONTAINER_IMAGE}} with Python {{PYTHON_VERSION}} and UID {{HOST_UID}}..."
    docker build \
        -f Dockerfile.dev \
        -t {{CONTAINER_IMAGE}} \
        --build-arg PYTHON_VERSION="{{PYTHON_VERSION}}" \
        --build-arg USER_UID={{HOST_UID}} \
        --build-arg USER_GID={{HOST_GID}} \
        .

# Image entfernen
clean:
    docker rmi {{CONTAINER_IMAGE}} || true

# Shell starten
shell: build
    docker run -it --rm \
        -v {{SRC_DIR}}:/app \
        {{CONTAINER_IMAGE}} \
        bash

# Formatierung
format: build
    docker run --rm \
        -v {{SRC_DIR}}:/app \
        {{CONTAINER_IMAGE}} \
        poetry run ruff format src tests

# Linting
lint: build
    docker run --rm \
        -v {{SRC_DIR}}:/app \
        {{CONTAINER_IMAGE}} \
        poetry run ruff check src tests

# Typprüfung & Tests
check: build
    docker run --rm \
        -v {{SRC_DIR}}:/app \
        {{CONTAINER_IMAGE}} \
        bash -c " \
            poetry run ruff format src tests && \
            poetry run ruff check src tests && \
            poetry run mypy src tests && \
            poetry run pytest src tests \
        "

# Tests
test: build
    docker run --rm \
        -v {{SRC_DIR}}:/app \
        {{CONTAINER_IMAGE}} \
        poetry run pytest tests

# Coverage
coverage: build
    docker run --rm \
        -v {{SRC_DIR}}:/app \
        {{CONTAINER_IMAGE}} \
        poetry run pytest --cov=src --cov-report=term-missing

# Coverage HTML
coverage-html: build
    @mkdir -p coverage_reports/htmlcov

    docker run --rm \
        -v {{SRC_DIR}}:/app \
        -v $(pwd)/coverage_reports/htmlcov:/app/htmlcov \
        {{CONTAINER_IMAGE}} \
        poetry run pytest --cov=src --cov-report=html:/app/htmlcov

    @echo "HTML coverage report in coverage_reports/htmlcov/index.html"

# Pre-commit Hooks
pre-commit: build
    docker run --rm \
        -v {{SRC_DIR}}:/app \
        {{CONTAINER_IMAGE}} \
        poetry run pre-commit run --all-files

# App starten
run: build
    docker run --rm \
        -v {{SRC_DIR}}:/app \
        {{CONTAINER_IMAGE}} \
        poetry run python src/{{PACKAGE_NAME}}/main.py
