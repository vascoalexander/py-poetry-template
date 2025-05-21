# Python Project Template

Dieses Repository bietet ein robustes und modernes Template für neue Python-Projekte. Es ist vorkonfiguriert mit den neuesten Best Practices für Dependency Management, Code-Qualität und Automatisierung, damit du sofort mit der Entwicklung beginnen kannst.

---

## Features

* **⚡️ Schnelles Setup:** Ein einfaches Skript richtet alles ein.
* **📦 Poetry:** Modernes Dependency Management und Paketierung.
* **🐍 mise:** Lokales Toolchain-Management für Python-Versionen und Poetry (früher `rtx`).
* **✨ Ruff:** Schnelles Linting und Code-Formatierung.
* **🔍 Mypy:** Statische Typ-Überprüfung für robuste Codebases.
* **🚫 Pre-commit Hooks:** Automatische Code-Qualitäts-Checks vor jedem Commit.
* **✅ Pytest:** Test-Framework mit Code-Coverage-Berichten.
* **📁 `src`-Layout:** Best Practice für die Projektstruktur.
* **🚀 Sofort startklar:** Nach dem Setup kannst du direkt Tests ausführen und Code schreiben.

---

## Voraussetzungen

Bevor du das Template verwendest, stelle sicher, dass du folgende Tools auf deinem System installiert hast:

* **Git:** Für die Versionskontrolle.
* **mise:** (Empfohlen) Ein polyglotter Tool-Manager, der Python und Poetry für dein Projekt verwaltet. Du kannst mise hier installieren: [https://mise.jdx.dev/](https://mise.jdx.dev/)

---

## Erste Schritte

Folge diesen Schritten, um ein neues Projekt basierend auf diesem Template einzurichten:

1.  **Repository klonen:**
    Klone dieses Template-Repository und benenne es direkt um in dein neues Projekt:
    ```bash
    git clone https://github.com/DEIN_USERNAME/my-python-template.git my-new-project
    cd my-new-project
    # Oder:
    # Wenn du ein neues Projekt direkt aus diesem Template erstellen möchtest (ohne den Template-Verlauf):
    # git clone https://github.com/DEIN_USERNAME/my-python-template.git my-new-project --no-checkout
    # cd my-new-project
    # git checkout main # Oder den gewünschten Branch
    ```
    *Hinweis:* Ersetze `DEIN_USERNAME/my-python-template` durch den tatsächlichen Pfad zu deinem Template-Repository und `my-new-project` durch den Namen deines neuen Projekts.

2.  **Setup-Skript ausführen:**
    Führe das Setup-Skript aus, um das Projekt zu initialisieren und die Umgebung einzurichten:
    ```bash
    bash setup.sh
    ```
    Das Skript wird dich nach einigen Projektinformationen fragen (Name, Beschreibung, Autor, Python-Version) und die `pyproject.toml`, die Ordnerstruktur und die Entwicklungsumgebung automatisch anpassen.

3.  **Mise in der Shell aktivieren:**
    `mise` muss in deiner Shell aktiviert sein, damit es die Umgebung für dein Projekt automatisch verwaltet. Füge die folgende Zeile zu deiner Shell-Konfigurationsdatei (`~/.bashrc`, `~/.zshrc` etc.) hinzu:
    ```bash
    eval "$(mise activate bash)" # Für Bash
    # Oder
    eval "$(mise activate zsh)"  # Für Zsh
    ```
    Nach dem Hinzufügen, starte dein Terminal neu oder führe `source ~/.bashrc` (oder entsprechend) aus.

---

## Entwicklung

Nach dem Setup und der Aktivierung von `mise` kannst du sofort loslegen:

### Abhängigkeiten installieren/aktualisieren

Um Python-Abhängigkeiten (aus `pyproject.toml`) zu installieren oder zu aktualisieren:

```bash
poetry install
```

### Code formatieren und Linting ausführen

Dieses Template verwendet **Ruff** für Code-Formatierung und Linting. Diese Checks werden automatisch durch Pre-commit-Hooks ausgeführt. Du kannst sie aber auch manuell starten:

```bash
poetry run ruff format src/ tests/
poetry run ruff check src/ tests/
```

### Typ-Prüfung ausführen

**Mypy** überprüft deinen Code auf Typfehler. Auch dieser Check ist Teil der Pre-commit-Hooks, kann aber manuell ausgeführt werden:

```bash
poetry run mypy src/
```

### Tests ausführen

Das Template ist vorkonfiguriert mit **Pytest**. Führe alle Tests aus:

```bash
poetry run pytest
```

Um Tests mit Code-Coverage-Bericht auszuführen:

```bash
poetry run pytest --cov=my_project_name # Ersetze my_project_name durch deinen Paketnamen
```

### Pre-commit Hooks

Die `.pre-commit-config.yaml` definiert eine Reihe von Hooks, die bei jedem `git commit` automatisch ausgeführt werden. Um sie manuell auszuführen (z.B. nach Änderungen an der Konfiguration):

```bash
poetry run pre-commit run --all-files
```

---

## Projektstruktur

```
.
├── .github/              # GitHub Actions Workflows (optional)
├── .pre-commit-config.yaml # Konfiguration für Pre-commit Hooks
├── .mise.toml            # mise-Konfiguration für Python- und Poetry-Version
├── pyproject.toml        # Poetry-Konfiguration für das Projekt
├── README.md             # Diese Datei
├── src/
│   └── YOUR_PACKAGE_NAME/ # Dein Haupt-Python-Paket (wird durch Setup.sh umbenannt)
│       ├── __init__.py
│       └── main.py
├── tests/
│   └── test_main.py      # Beispiel-Testdateien
└── setup.sh              # Skript zur Initialisierung des Projekts
```

---
