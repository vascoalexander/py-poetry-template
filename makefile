# Lade Umgebungsvariablen aus .env (optional, mit export)
ifneq (,$(wildcard .env))
  include .env
  export
endif

PYTHON_VERSION ?= 3.12
PACKAGE_NAME := $(shell basename $(shell find src -maxdepth 1 -mindepth 1 -type d ! -name "__pycache__"))
IMAGE_TAG := $(PACKAGE_NAME):dev
HOST_UID := $(shell id -u)
HOST_GID := $(shell id -g)
CONTAINER_PATH := "/opt/poetry/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

.PHONY: build clean shell lint check format test coverage coverage-html pre-commit run help

default: help

help:
	@echo "---------------------------------------------------------"
	@echo "                  Python Project Makefile                "
	@echo "---------------------------------------------------------"
	@echo ""
	@echo "Host-side Commands (using mise to provide Poetry, then Poetry for tools):"
	@echo "  make lint               : Run Ruff linter on source and tests."
	@echo "  make format             : Run Ruff formatter on source and tests."
	@echo "  make check              : Run Ruff lint and MyPy type checks on source and tests."
	@echo "  make pre-commit         : Manually run all pre-commit hooks."
	@echo ""
	@echo "Docker Container Commands:"
	@echo "  make build              : Build the Docker development image."
	@echo "  make clean              : Remove the Docker development image."
	@echo "  make shell              : Open an interactive shell inside the development container."
	@echo "  make test               : Run Pytest for unit and integration tests inside container."
	@echo "  make coverage           : Run Pytest with coverage report (terminal) inside container."
	@echo "  make coverage-html      : Generate HTML coverage report inside container and copy to host."
	@echo "  make run                : Run the main application script inside container."
	@echo ""
	@echo "To use host-side commands, ensure 'mise' and 'poetry' are installed and configured via mise."
	@echo "The Docker image also uses 'mise' internally for Python and Poetry."
	@echo "---------------------------------------------------------"

build:
	@echo "Building Docker development image: $(IMAGE_TAG) with Python $(PYTHON_VERSION)..."
	docker build \
		-f Dockerfile.dev \
		-t $(IMAGE_TAG) \
		--build-arg PYTHON_VERSION=$(PYTHON_VERSION) \
		--build-arg USER_UID=$(shell id -u) \
		--build-arg USER_GID=$(shell id -g) \
		.
# Tasks that run INSIDE the Docker Container

shell: build
	docker run -it --rm \
		-e PATH=$(CONTAINER_PATH) \
		-u $(HOST_UID):$(HOST_GID) \
		-v $(PWD):/app \
		$(IMAGE_TAG) bash

test: build
	docker run --rm \
		-e PATH=$(CONTAINER_PATH) \
		-u $(HOST_UID):$(HOST_GID) \
		-v $(PWD):/app \
		$(IMAGE_TAG) \
		poetry run pytest /app/tests

coverage: build
	docker run --rm \
		-e PATH=$(CONTAINER_PATH) \
		-u $(HOST_UID):$(HOST_GID) \
		-v $(PWD):/app \
		$(IMAGE_TAG) \
		poetry run pytest --cov=src --cov-report=term-missing

coverage-html: build
	mkdir -p coverage_reports/htmlcov
	chown $(shell id -u):$(shell id -g) coverage_reports/htmlcov

	docker run --rm \
		-e PATH=$(CONTAINER_PATH) \
		-u $(shell id -u):$(shell id -g) \
		-v $(PWD):/app \
		$(IMAGE_TAG) \
		bash -c "\
			rm -rf /tmp/htmlcov && \
			poetry run pytest --cov=src --cov-report=html:/tmp/htmlcov && \
			rm -rf /app/coverage_reports/htmlcov/* && \
			cp -a /tmp/htmlcov/. /app/coverage_reports/htmlcov && \
			chown -R $(shell id -u):$(shell id -g) /app/coverage_reports/htmlcov"

run: build
	docker run --rm \
		-e PATH=$(CONTAINER_PATH) \
		-u $(HOST_UID):$(HOST_GID) \
		-v $(PWD):/app \
		$(IMAGE_TAG) \
		poetry run python /app/src/$(PACKAGE_NAME)/main.py

## Host-seitige Tasks

clean:
	@echo "Removing Docker image: $(IMAGE_TAG)"
	docker rmi $(IMAGE_TAG) || true

lint:
	@echo "Running Ruff linter on host via poetry..."
	poetry run ruff check src tests

format:
	@echo "Running Ruff formatter on host via poetry..."
	poetry run ruff format src tests

check: lint
	@echo "Running MyPy type checks on host via poetry..."
	poetry run mypy src tests

pre-commit:
    @echo "Running pre-commit hooks on host via poetry..."
	poetry run pre-commit run --all-files


