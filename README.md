# Python Project Template

Dieses Repository stellt ein robustes, modernes Template für neue Python-Projekte bereit.

---

## 🔧 Features

- ⚡️ **Schnelles Setup:** Ein einfaches Skript initialisiert das gesamte Projekt.
- 📦 **Poetry:** Moderne Verwaltung von Abhängigkeiten und Paketierung.
- 🐍 **mise:** Toolchain-Manager für Python, Poetry & mehr.
- ✨ **Ruff:** Linting, Formatierung und einfache Codeanalyse in einem Tool.
- 🔍 **Mypy:** Statische Typüberprüfung für robusten Code.
- 🚫 **Pre-commit Hooks:** Automatische Checks vor jedem Commit.
- ✅ **Pytest:** Test-Framework mit optionalem Code-Coverage.
- 📁 **`src`-Layout:** Empfohlene Struktur für saubere Trennung von Code und Tests.
- 🚀 **Sofort einsatzbereit:** Nach dem Setup direkt startklar für Entwicklung und Tests.
- 🛠️ **Makefile:** Für häufige Aufgaben wie Linting, Testing und Type-Checks.

---


## 🧰 Voraussetzungen

Stelle sicher, dass folgende Tools installiert sind:

- **Git** – zur Versionskontrolle
- **[mise](https://mise.jdx.dev/)** – (empfohlen) verwaltet Python- & Poetry-Versionen lokal

---

## 🚀 Schnellstart

1. **Template klonen und Projektverzeichnis anlegen:**

   ```bash
   git clone https://github.com/DEIN_USERNAME/py-poetry-template.git my-new-project
   cd my-new-project
   ```

*(Optional: `--no-checkout` verwenden, wenn du das Template ohne Git-Verlauf nutzen willst.)*

2. **Setup-Skript ausführen:**

   ```bash
   bash setup.sh
   ```

   Das Skript fragt nach Basisinformationen (Projektname, Autor, etc.) und passt `pyproject.toml` sowie Verzeichnisstruktur an.

3. **mise aktivieren:**

   Ergänze deine Shell-Konfiguration:

   ```bash
   eval "$(mise activate bash)"  # oder zsh
   ```

   Danach Terminal neu starten oder `source ~/.bashrc` ausführen.

---

## 🧑‍💻 Entwicklung

### 🔄 Abhängigkeiten installieren

```bash
poetry install
```

Oder:

```bash
make install # oder make all
```

### 🧪 Tests & Coverage

```bash
make test
make coverage
make coverage-html #(generiert html coverage report)
```

Oder manuell:

```bash
poetry run pytest
poetry run pytest --cov=mein_paketname
```

### 🧹 Linting & Formatierung

```bash
make lint
make format
```

Oder direkt mit Ruff:

```bash
poetry run ruff check src/ tests/
poetry run ruff format src/ tests/
```

### 🔎 Type Checking

```bash
make typecheck
```

Oder:

```bash
poetry run mypy src/
```

### 🔁 Pre-Commit Hooks

Automatisch bei jedem `git commit`, manuell so:

```bash
make precommit
```

---

## 📁 Projektstruktur

```text
.
├── .github/                 # GitHub Workflows (optional)
├── .mise.toml              # Toolchain-Versionen (mise)
├── .pre-commit-config.yaml # Pre-commit Hook-Definitionen
├── pyproject.toml          # Projekt- und Abhängigkeitskonfiguration
├── README.md
├── setup.sh                # Projektinitialisierung
├── Makefile                # Aufgabenautomatisierung
├── src/
│   └── <package>/          # Hauptmodul
│       ├── __init__.py
│       └── main.py
└── tests/
    └── test_main.py        # Beispiel-Test
```

---

## 💬 Feedback oder Beiträge

Pull Requests und Vorschläge sind willkommen! Du kannst dieses Template gerne forken und an deine Bedürfnisse anpassen.
