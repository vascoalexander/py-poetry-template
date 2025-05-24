# Makefile für ein Python-Projekt mit Poetry und pre-commit

# Variablen
POETRY := poetry
PYTHON := $(poetry) run Python
RUFF := $(POETRY) run ruff
PYTEST := $(POETRY) run pytest
PRECOMMIT := $(POETRY) run pre-commit

.PHONY: install format lint test check precommit clean all coverage coverage-html

install:
	$(POETRY) install

format:
	$(RUFF) format .

lint:
	$(RUFF) check .

test:
	$(PYTEST)

coverage:
	$(PYTEST) --cov=src --cov-report=term-missing

coverage-html:
	$(PYTEST) --cov=src --cov-report=html && echo "HTML report: file://$(CURDIR)/htmlcov/index.html"

typecheck:
	poetry run mypy src/

check: format lint test typecheck

precommit:
	$(PRECOMMIT) run --all-files

clean:
	find . -type d -name "__pychache__" -exec rm -rf {} +
	find . -type d -name ".pytest_cache" -exec rm -rf {} +
	rm -rf .mypy_cache .ruff_cache

all: install check
