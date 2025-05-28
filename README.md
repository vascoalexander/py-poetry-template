# Python Project Template

Dieses Repository stellt ein robustes, modernes Template für neue Python-Projekte bereit.

---

## 🔧 Features

- ⚡️ **Schnelles Setup:** Ein einfaches Skript initialisiert das gesamte Projekt.
- 📦 **Poetry:** Moderne Verwaltung von Abhängigkeiten und Paketierung.
- 🐍 **mise:** Toolchain-Manager für Python, Poetry & mehr.
- 🐳 **Docker-Integration:** Vorkonfiguriertes Development Image für konsistente Umgebungen.
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
- **Docker** – für die Entwicklung in einer konsistenten Container-Umgebung.

---

## 🚀 Schnellstart

1. **Template klonen und Projektverzeichnis anlegen:**

   ```bash
   git clone https://github.com/vascoalexander/py-poetry-template.git my-new-project
   cd my-new-project
   ```

2. **Setup-Skript ausführen:**

   ```bash
   bash setup.sh
   ```

   Das Skript fragt nach Basisinformationen (Projektname, Autor, Python-Version etc.) und passt die pyproject.toml sowie die Verzeichnisstruktur an. Es initialisiert auch mise für das Projekt, installiert Poetry und Python, generiert die poetry.lock Datei basierend auf deiner Konfiguration und baut das Docker Development Image. Zudem werden die Pre-commit Hooks installiert.

3. **mise aktivieren:**

   Damit mise und die von ihm verwalteten Tools (wie poetry und python) direkt in deiner Shell verfügbar sind, füge diese Zeile zu deiner Shell-Konfigurationsdatei hinzu (z.B. ~/.bashrc oder ~/.zshrc):

   ```bash
   eval "$(mise activate bash)"  # oder zsh
   ```

   Danach Terminal neu starten oder `source ~/.bashrc` ausführen.

---

## 🧑‍💻 Entwicklung

Alle gängigen Entwicklungsaufgaben sind im **Makefile** zusammengefasst und können über `make` ausgeführt werden. Die Befehle sind in "Host-seitige Commands" (die `mise` und Poetry direkt auf deinem System nutzen) und "Docker Container Commands" (die innerhalb des Docker Development Containers ausgeführt werden) unterteilt.

### 🛠️ Makefile-Befehle

Eine vollständige Übersicht aller `make`-Befehle erhältst du jederzeit mit:

Bash

```
make help
```

Hier sind die wichtigsten Befehlsgruppen:

#### Host-seitige Commands (Ausführung direkt auf deinem System)

Diese Befehle nutzen die von `mise` bereitgestellten Python- und Poetry-Installationen direkt auf deinem Host.

- **`make lint`**: Führt den Ruff Linter für deinen Quellcode und deine Tests aus.
- **`make format`**: Führt den Ruff Formatter aus, um deinen Quellcode und deine Tests zu formatieren.
- **`make check`**: Kombiniert `make lint` und führt zusätzlich statische Typüberprüfungen mit MyPy für deinen Quellcode und deine Tests aus.
- **`make pre-commit`**: Führt alle in `.pre-commit-config.yaml` definierten Pre-commit Hooks manuell für alle Dateien aus. _Hinweis: Wenn Pre-commit Hooks Dateien modifizieren, schlägt der Lauf fehl. Du musst die geänderten Dateien stagen (`git add .`) und einen neuen Commit (`git commit`) ausführen, um die Korrekturen aufzunehmen._

#### Docker Container Commands (Ausführung im Development Container)

Diese Befehle interagieren mit dem Docker Development Image. Sie stellen sicher, dass alle Operationen in einer konsistenten, isolierten Umgebung stattfinden.

- **`make build`**: Baut das Docker Development Image (`<project_name>:dev`). Das Image wird automatisch mit deiner gewählten Python-Version und deinen Host-Benutzer-IDs erstellt.
- **`make clean`**: Entfernt das gebaute Docker Development Image von deinem System.
- **`make shell`**: Öffnet eine interaktive Bash-Shell direkt im Development Container. Hier kannst du innerhalb der containerisierten Umgebung arbeiten.
- **`make test`**: Führt deine Unit- und Integrationstests mit Pytest innerhalb des Development Containers aus.
- **`make coverage`**: Führt Pytest mit einem Code-Coverage-Report im Terminal innerhalb des Containers aus.
- **`make coverage-html`**: Generiert einen detaillierten HTML-Code-Coverage-Report im Container und kopiert diesen in das `coverage_reports/htmlcov`-Verzeichnis auf deinem Host.
- **`make run`**: Führt das Hauptanwendungsskript (`src/<package_name>/main.py`) innerhalb des Development Containers aus.

---

## 📁 Projektstruktur

```text
.
├── .github/                # GitHub Workflows (optional)
├── .pre-commit-config.yaml # Pre-commit Hook-Definitionen
├── .dockerignore           # Pre-commit Hook-Definitionen
├── .gitignore              # Pre-commit Hook-Definitionen
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
