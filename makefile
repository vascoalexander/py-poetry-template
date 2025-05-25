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

.PHONY: build clean shell lint check format test coverage coverage-html pre-commit run

build:
	@echo "Building Docker development image: $(IMAGE_TAG) with Python $(PYTHON_VERSION)..."
	docker build \
		-f Dockerfile.dev \
		-t $(IMAGE_TAG) \
		--build-arg PYTHON_VERSION=$(PYTHON_VERSION) \
		--build-arg USER_UID=$(shell id -u) \
		--build-arg USER_GID=$(shell id -g) \
		.

clean:
	@echo "Removing Docker image: $(IMAGE_TAG)"
	docker rmi $(IMAGE_TAG) || true

shell: build
	docker run -it --rm \
		-e PATH=$(CONTAINER_PATH) \
		-u $(HOST_UID):$(HOST_GID) \
		-v $(PWD):/app \
		$(IMAGE_TAG) bash

lint: build
	docker run --rm \
		-e PATH=$(CONTAINER_PATH) \
		-u $(HOST_UID):$(HOST_GID) \
		-v $(PWD):/app \
		$(IMAGE_TAG) \
		poetry run ruff check /app/src /app/tests

check: build
	docker run --rm \
		-e PATH=$(CONTAINER_PATH) \
		-u $(HOST_UID):$(HOST_GID) \
		-v $(PWD):/app \
		$(IMAGE_TAG) \
		bash -c "\
			poetry run ruff format src tests && \
			poetry run ruff check src tests && \
			poetry run mypy src tests && \
			poetry run pytest src tests"

format: build
	docker run --rm \
		-e PATH=$(CONTAINER_PATH) \
		-u $(HOST_UID):$(HOST_GID) \
		-v $(PWD):/app \
		$(IMAGE_TAG) \
		poetry run ruff format /app/src /app/tests

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

pre-commit: build
	docker run --rm \
		-e PATH=$(CONTAINER_PATH) \
		-u $(HOST_UID):$(HOST_GID) \
		-v $(PWD):/app \
		$(IMAGE_TAG) \
		poetry run pre-commit run --all-files

run: build
	docker run --rm \
		-e PATH=$(CONTAINER_PATH) \
		-u $(HOST_UID):$(HOST_GID) \
		-v $(PWD):/app \
		$(IMAGE_TAG) \
		poetry run python /app/src/$(PACKAGE_NAME)/main.py
