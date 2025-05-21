#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}--- Python Project Setup ---${NC}"
echo "Dieses Skript hilft Ihnen, Ihr neues Python-Projekt einzurichten."
echo ""

# --- 1. Projektinformationen abfragen ---
echo -e "${YELLOW}Schritt 1: Projektinformationen${NC}"

# Projektname
read -p "Geben Sie den Namen Ihres Projekts ein (z.B. my_awesome_project): " PROJECT_NAME
while [[ -z "$PROJECT_NAME" ]]; do
    echo -e "${YELLOW}Projektname darf nicht leer sein!${NC}"
    read -p "Geben Sie den Namen Ihres Projekts ein: " PROJECT_NAME
done

# Funktion zur Konvertierung des Projektnamens in einen gültigen Python-Paketnamen
# - Alles in Kleinbuchstaben
# - Leerzeichen und Bindestriche durch Unterstriche ersetzen
# - Ungültige Zeichen entfernen (nur Alphanumerisch und Unterstrich erlauben)
# - Mehrere Unterstriche in einen reduzieren
# - Führende/Endende Unterstriche entfernen
normalize_package_name() {
    local name="$1"
    # 1. Alles in Kleinbuchstaben
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]')
    # 2. Leerzeichen, Bindestriche, Punkte durch Unterstriche ersetzen
    name=$(echo "$name" | sed -E 's/[[:space:]\.-]/_/g')
    # 3. Alle Zeichen, die keine alphanumerischen Zeichen oder Unterstriche sind, entfernen
    name=$(echo "$name" | sed -E 's/[^a-z0-9_]//g')
    # 4. Mehrere Unterstriche in einen reduzieren
    name=$(echo "$name" | sed -E 's/__+/_/g')
    # 5. Führende/Endende Unterstriche entfernen
    name=$(echo "$name" | sed -E 's/^_|_$//g')
    echo "$name"
}

PACKAGE_NAME=$(normalize_package_name "$PROJECT_NAME")

# Ersetze Leerzeichen und Sonderzeichen für Paketnamen
if [ "$PROJECT_NAME" != "$PACKAGE_NAME" ]; then
    echo -e "${YELLOW}Der eingegebene Projektname '$PROJECT_NAME' wurde für den Paketnamen in '$PACKAGE_NAME' konvertiert, um Python-Konventionen zu entsprechen.${NC}"
fi

# Beschreibung
read -p "Geben Sie eine kurze Beschreibung Ihres Projekts ein: " PROJECT_DESCRIPTION
PROJECT_DESCRIPTION=${PROJECT_DESCRIPTION:-"A new Python project."} # Standardwert

# Autor
read -p "Geben Sie Ihren Namen ein (z.B. Max Mustermann): " AUTHOR_NAME
AUTHOR_NAME=${AUTHOR_NAME:-"Your Name"}

# Email
read -p "Geben Sie Ihre E-Mail-Adresse ein (z.g. max@example.com): " AUTHOR_EMAIL
AUTHOR_EMAIL=${AUTHOR_EMAIL:-"you@example.com"}

# Python-Version
MIN_PYTHON_MAJOR=3
MIN_PYTHON_MINOR=9
PYTHON_VERSION_VALID=false

while [ "$PYTHON_VERSION_VALID" = false ]; do
    read -p "Geben Sie die gewünschte Python-Version an (mindestens ${MIN_PYTHON_MAJOR}.${MIN_PYTHON_MINOR}, z.B. 3.10, 3.11, 3.12, 3.13): " PYTHON_VERSION

    # Extrahiere Major- und Minor-Version
    # Trennen des Strings bei '.'
    PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | cut -d'.' -f1)
    PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d'.' -f2)

    # Prüfen, ob die extrahierten Teile gültige Zahlen sind
    if ! [[ "$PYTHON_MAJOR" =~ ^[0-9]+$ ]] || ! [[ "$PYTHON_MINOR" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Ungültiges Python-Versionsformat: '$PYTHON_VERSION'. Bitte geben Sie die Version im Format 'X.Y' ein (z.B. 3.10).${NC}"
        continue
    fi

    # Numerischen Vergleich durchführen
    if (( PYTHON_MAJOR < MIN_PYTHON_MAJOR )) || ( (( PYTHON_MAJOR == MIN_PYTHON_MAJOR )) && (( PYTHON_MINOR < MIN_PYTHON_MINOR )) ); then
        echo -e "${RED}Fehler: Python-Version $PYTHON_VERSION ist älter als das erforderliche Minimum ${MIN_PYTHON_MAJOR}.${MIN_PYTHON_MINOR}.${NC}"
        echo -e "${YELLOW}Bitte wählen Sie eine Version von ${MIN_PYTHON_MAJOR}.${MIN_PYTHON_MINOR} oder neuer.${NC}"
        continue
    else
        PYTHON_VERSION_VALID=true
    fi
done

echo ""

# --- 2. pyproject.toml anpassen ---
echo -e "${YELLOW}Schritt 2: pyproject.toml anpassen...${NC}"

sed -i.bak "s/^name = \".*\"/name = \"$PROJECT_NAME\"/" pyproject.toml
sed -i.bak "s/^version = \".*\"/version = \"0.1.0\"/" pyproject.toml
sed -i.bak "s/^description = \".*\"/description = \"$PROJECT_DESCRIPTION\"/" pyproject.toml
sed -i.bak "s/^authors = \[.*\]/authors = [\"$AUTHOR_NAME <$AUTHOR_EMAIL>\"]/" pyproject.toml
sed -i.bak "s/^python = \"\^.*\"/python = \"^$PYTHON_VERSION\"/" pyproject.toml
rm -f pyproject.toml.bak
echo "pyproject.toml wurde aktualisiert."

# --- 3. Ordnerstruktur und __init__.py anpassen ---
echo -e "${YELLOW}Schritt 3: Ordnerstruktur und Python-Dateien anpassen...${NC}"
OLD_PACKAGE_NAME="my_project_name"

if [ -d "src/$OLD_PACKAGE_NAME" ]; then
    mv "src/$OLD_PACKAGE_NAME" "src/$PACKAGE_NAME"
    echo "src/$OLD_PACKAGE_NAME in src/$PACKAGE_NAME umbenannt."
else
    echo "src/$OLD_PACKAGE_NAME nicht gefunden, überspringe Umbenennung."
fi

# Erstelle oder aktualisiere __init__.py
INIT_PY_CONTENT="from importlib.metadata import PackageNotFoundError, version\n\ntry:\n    __version__ = version(\"$PACKAGE_NAME\")\nexcept PackageNotFoundError:\n    __version__ = \"unknown\"\n"
mkdir -p "src/$PACKAGE_NAME"
echo -e "$INIT_PY_CONTENT" > "src/$PACKAGE_NAME/__init__.py"
echo "src/$PACKAGE_NAME/__init__.py wurde erstellt/aktualisiert."


# main.py aktualisieren
MAIN_PY_CONTENT="import sys\n\ndef main() -> None:\n    print(\"Hello, world from your new Python project!\")\n    print(f\"Python version: {sys.version}\")\n\nif __name__ == '__main__':\n    main()\n"
echo -e "$MAIN_PY_CONTENT" > "src/$PACKAGE_NAME/main.py"
echo "src/$PACKAGE_NAME/main.py wurde erstellt/aktualisiert mit statischem Gruß."

# --- NEU: test_main.py Import anpassen (Inhalt bleibt statisch) ---
echo -e "${YELLOW}Schritt 3.5: Tests anpassen...${NC}"
TEST_FILE="tests/test_main.py"
if [ -f "$TEST_FILE" ]; then
    # Das Suchmuster muss "from $OLD_PACKAGE_NAME.main" finden
    # und ersetzen durch "from $PACKAGE_NAME.main"
    # Wichtig: KEIN "src." im Suchmuster, da es im Template-Test nicht vorhanden sein sollte.
    sed -i.bak "s/from $OLD_PACKAGE_NAME\.main/from $PACKAGE_NAME\.main/" "$TEST_FILE"
    rm -f "${TEST_FILE}.bak" # Backup-Datei entfernen
    echo "$TEST_FILE wurde aktualisiert (Importpfad)."
else
    echo "Warnung: $TEST_FILE nicht gefunden. Tests könnten nicht korrekt funktionieren."
fi
echo "" # Eine Leerzeile für Lesbarkeit

# --- 4. Mise Konfiguration und Installation ---
echo -e "${YELLOW}Schritt 4: Mise-Konfiguration und Installation...${NC}"
if command -v mise &> /dev/null; then
    echo "Mise gefunden. Konfiguriere .mise.toml und installiere Tools..."

    # Erstelle/Aktualisiere .mise.toml für zukünftige manuelle Nutzung (optional, aber gut)
    echo "[tools]" > .mise.toml
    echo "python = \"$PYTHON_VERSION\"" >> .mise.toml
    echo "poetry = \"latest\"" >> .mise.toml
    echo ".mise.toml erstellt/aktualisiert mit Python $PYTHON_VERSION und Poetry."

    echo ""
    echo -e "${GREEN}Mise installiert Python und Poetry...${NC}"
    # Explizite Installation/Aktivierung der Tools im Skriptkontext
    mise use python@$PYTHON_VERSION
    if [ $? -ne 0 ]; then
        echo -e "${RED}Fehler beim Installieren/Aktivieren von Python $PYTHON_VERSION mit mise.${NC}"
        exit 1
    fi

    mise use poetry@latest
    if [ $? -ne 0 ]; then
        echo -e "${RED}Fehler beim Installieren/Aktivieren von Poetry mit mise.${NC}"
        exit 1
    fi

    echo -e "${GREEN}Stellen Sie sicher, dass mise in Ihrer Shell aktiviert ist:${NC}"
    echo "  eval \"\$(mise activate bash)\"  # Für Bash"
    echo "  eval \"\$(mise activate zsh)\"   # Für Zsh"
    echo "  (Fügen Sie dies zu Ihrer .bashrc oder .zshrc hinzu für automatische Aktivierung)"
else
    echo -e "${RED}Mise nicht gefunden. Bitte installieren Sie mise oder passen Sie das Skript an, um Poetry und Python manuell zu verwalten.${NC}"
    echo "   (z.B. pip install poetry und eine manuelle Python-Installation)"
    exit 1
fi

# --- 5. Poetry Abhängigkeiten installieren ---
echo -e "${YELLOW}Schritt 5: Poetry-Abhängigkeiten initialisieren...${NC}"

# Poetry sollte jetzt im PATH sein, da es über mise aktiviert wurde
echo "Installiere Poetry Projekt-Abhängigkeiten (inklusive dev-Abhängigkeiten)..."
poetry install
if [ $? -ne 0 ]; then
    echo -e "${RED}Fehler beim Installieren der Poetry-Abhängigkeiten. Überprüfen Sie Ihre pyproject.toml.${NC}"
    exit 1
fi
echo "Poetry-Abhängigkeiten installiert."

# --- Neu: 5.5 Git-Initialisierung und erster Commit ---
echo -e "${YELLOW}Schritt 5.5: Git-Repository initialisieren und erster Commit...${NC}"
if [ ! -d ".git" ]; then
    git init
    if [ $? -ne 0 ]; then
        echo -e "${RED}Fehler beim Initialisieren des Git-Repositorys. Stellen Sie sicher, dass Git installiert ist.${NC}"
        exit 1
    fi
    echo "Git-Repository initialisiert."

    # Initialer Commit
    git add .
    git commit -m "feat: Initial project setup from template"
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}Warnung: Konnte keinen initialen Git-Commit erstellen. Möglicherweise sind keine Änderungen vorhanden oder Git ist nicht richtig konfiguriert.${NC}"
        echo -e "${YELLOW}Bitte führen Sie nach dem Skript manuell 'git config --global user.email \"you@example.com\"' und 'git config --global user.name \"Your Name\"' aus und committen Sie dann.${NC}"
    else
        echo "Initialer Git-Commit erstellt."
    fi
else
    echo "Git-Repository ist bereits initialisiert, überspringe Initialisierung und Initial-Commit."
fi
echo ""

# --- 6. Pre-commit Hooks installieren ---
echo -e "${YELLOW}Schritt 6: Pre-commit Hooks installieren...${NC}"
echo "Installiere Pre-commit Hooks in das Git Repository..."
poetry run pre-commit install
if [ $? -ne 0 ]; then
    echo -e "${RED}Fehler beim Installieren der pre-commit Hooks. Überprüfen Sie Ihre .pre-commit-config.yaml.${NC}"
    exit 1
fi
echo "Pre-commit Hooks installiert."

echo ""
echo -e "${GREEN}--- Setup Abgeschlossen! ---${NC}"
echo "Ihr Projekt '$PROJECT_NAME' ($PACKAGE_NAME) wurde erfolgreich eingerichtet."
echo "Sie können jetzt mit der Entwicklung beginnen."
echo ""
echo "Um Ihre Umgebung zu aktivieren (falls Sie mise verwenden):"
echo "  Stellen Sie sicher, dass 'eval \"\$(mise activate <your_shell>)\"' in Ihrer Shell-Konfiguration ist."
echo "  Wechseln Sie in das Projektverzeichnis und die mise-Hooks sollten die Umgebung aktivieren."
echo ""
echo "Um Abhängigkeiten zu aktualisieren:"
echo "  poetry update"
echo ""
echo "Um Tests auszuführen:"
echo "  poetry run pytest"
echo ""
echo "Viel Spaß beim Codieren!"
