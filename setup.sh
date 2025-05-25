#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Defaultwerte ---
DEFAULT_PROJECT_DESCRIPTION="A new Python project."
DEFAULT_AUTHOR_NAME="Your Name"
DEFAULT_AUTHOR_EMAIL="you@example.com"
DEFAULT_PYTHON_VERSION="3.12"
MIN_PYTHON_MAJOR=3
MIN_PYTHON_MINOR=9

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
read -p "Geben Sie eine kurze Beschreibung Ihres Projekts ein [${DEFAULT_PROJECT_DESCRIPTION}]: " PROJECT_DESCRIPTION
PROJECT_DESCRIPTION=${PROJECT_DESCRIPTION:-$DEFAULT_PROJECT_DESCRIPTION}

# Autor
read -p "Geben Sie Ihren Namen ein [${DEFAULT_AUTHOR_NAME}]: " AUTHOR_NAME
AUTHOR_NAME=${AUTHOR_NAME:-$DEFAULT_AUTHOR_NAME}

# Email
read -p "Geben Sie Ihre E-Mail-Adresse ein [${DEFAULT_AUTHOR_EMAIL}]: " AUTHOR_EMAIL
AUTHOR_EMAIL=${AUTHOR_EMAIL:-$DEFAULT_AUTHOR_EMAIL}

# Python-Version
PYTHON_VERSION_VALID=false

while [ "$PYTHON_VERSION_VALID" = false ]; do
    read -p "Geben Sie die gewünschte Python-Version an (mindestens ${MIN_PYTHON_MAJOR}.${MIN_PYTHON_MINOR}) [${DEFAULT_PYTHON_VERSION}]: " PYTHON_VERSION
    PYTHON_VERSION=${PYTHON_VERSION:-$DEFAULT_PYTHON_VERSION}

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
echo "Verwende Python-Version: $PYTHON_VERSION"
echo ""

# --- .env Datei erstellen/aktualisieren ---
echo -e "${YELLOW}Erstelle/Aktualisiere .env Datei mit Python-Version...${NC}"
echo "PYTHON_VERSION=$PYTHON_VERSION" > .env
echo ".env Datei mit PYTHON_VERSION=$PYTHON_VERSION erstellt/aktualisiert."
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

# --- NEU: 2.5: Poetry.lock Datei generieren (auf dem Host) ---
# Dies ist notwendig, damit Docker die poetry.lock beim Build kopieren kann.
echo -e "${YELLOW}Schritt 2.5: poetry.lock Datei generieren...${NC}"

# Überprüfe, ob Poetry auf dem Host installiert ist
if ! command -v poetry &> /dev/null; then
    echo -e "${YELLOW}Poetry wurde auf Ihrem Host nicht gefunden. Versuche, Poetry zu installieren...${NC}"

    # Versuche, pipx zu installieren
    if ! command -v pipx &> /dev/null; then
        echo -e "${YELLOW}pipx wurde nicht gefunden. Versuche, pipx zu installieren...${NC}"
        # --break-system-packages wird manchmal unter bestimmten Linux-Distributionen benötigt,
        # wenn pipx ansonsten Probleme mit dem System-Python hat.
        python3 -m pip install --user pipx || { echo -e "${RED}Fehler: Konnte pipx nicht installieren. Bitte installieren Sie pipx manuell (z.B. 'pip install --user pipx') und versuchen Sie es erneut.${NC}"; exit 1; }
        python3 -m pipx ensurepath || { echo -e "${RED}Fehler: Konnte pipx Pfad nicht zur PATH-Umgebungsvariable hinzufügen. Bitte prüfen Sie Ihre Installation.${NC}"; }
        # Hinweis, dass der Benutzer das Terminal ggfs neu starten muss
        echo -e "${YELLOW}Hinweis: Möglicherweise müssen Sie dieses Terminal schließen und ein neues öffnen, damit 'pipx' und 'poetry' im PATH verfügbar sind.${NC}"
        echo -e "${GREEN}pipx wurde installiert und zum PATH hinzugefügt.${NC}"
    fi

    # Installiere Poetry mit pipx
    pipx install poetry || { echo -e "${RED}Fehler: Konnte Poetry nicht mit pipx installieren. Bitte versuchen Sie es manuell: 'pipx install poetry'${NC}"; exit 1; }
    echo -e "${GREEN}Poetry wurde erfolgreich installiert.${NC}"
else
    echo -e "${GREEN}Poetry ist bereits auf Ihrem Host installiert.${NC}"
fi

echo "Generiere poetry.lock..."
poetry lock
if [ $? -ne 0 ]; then
    echo -e "${RED}Fehler beim Generieren der poetry.lock Datei. Überprüfen Sie Ihre Poetry-Installation und pyproject.toml.${NC}"
    exit 1
fi
echo "poetry.lock erfolgreich generiert."
echo ""

# --- 3. Ordnerstruktur und __init__.py anpassen ---
echo -e "${YELLOW}Schritt 3: Ordnerstruktur und Python-Dateien anpassen...${NC}"
OLD_PACKAGE_NAME="my_project_name"

if [ -d "src/$OLD_PACKAGE_NAME" ]; then
    mv "src/$OLD_PACKAGE_NAME" "src/$PACKAGE_NAME"
    echo "src/$OLD_PACKAGE_NAME in src/$PACKAGE_NAME umbenannt."
else
    echo -e "${YELLOW}Warnung: Alter Paketordner 'src/$OLD_PACKAGE_NAME' nicht gefunden. Überspringe Umbenennung.${NC}"
    if [ ! -d "src/$PACKAGE_NAME" ]; then
        echo -e "${RED}Fehler: Weder alter noch neuer Paketordner in 'src/' gefunden. Bitte manuell anlegen oder umbenennen.${NC}"
        exit 1
    fi
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

# --- 4. Git-Initialisierung und erster Commit ---
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

# --- 5. Docker Image bauen ---
echo -e "${YELLOW}Schritt 7: Docker Development Image bauen...${NC}"
echo "Starte den Build des Docker-Images (dies kann einen Moment dauern)..."
if ! command -v just &> /dev/null; then
    echo -e "${RED}Fehler: 'just' Befehl nicht gefunden. Bitte installieren Sie 'just' (z.B. brew install just / sudo apt install just).${NC}"
    exit 1
fi

PYTHON_VERSION="$PYTHON_VERSION" just build
if [ $? -ne 0 ]; then
    echo -e "${RED}Fehler beim Bauen des Docker-Images. Überprüfen Sie Ihr Dockerfile.dev und die 'just' Ausgabe.${NC}"
    exit 1
fi
echo "Docker Development Image erfolgreich gebaut!"
echo ""

# --- 6. Pre-commit Hooks installieren (Host-seitig) ---
echo -e "${YELLOW}Schritt 7: Pre-commit Hooks installieren (Host-seitig und via Docker)...${NC}"
# Installiere den Pre-commit Client auf dem Host, damit die Git-Hooks funktionieren
echo "Installiere 'pre-commit' Tool auf dem Host (falls noch nicht vorhanden)..."
pip install pre-commit || { echo "Warnung: Konnte 'pre-commit' nicht auf dem Host installieren. Bitte manuell installieren: pip install pre-commit"; }

echo "Installiere Pre-commit Hooks in das Git Repository (host-seitig)..."
# Dieser Befehl installiert die Git-Hooks (.git/hooks/pre-commit)
pre-commit install
if [ $? -ne 0 ]; then
    echo -e "${RED}Fehler beim Installieren der host-seitigen pre-commit Hooks.${NC}"
    exit 1
fi
echo "Host-seitige Pre-commit Hooks installiert."

# Optional: Führe einen ersten Lauf der pre-commit Hooks direkt nach der Installation aus
# Dies stellt sicher, dass alle initialen Formatierungen und Checks angewendet werden
echo "Führe erste Pre-commit Checks aus (dies kann Dateien ändern)..."
# Hier rufen wir das 'just' Kommando auf, um die Checks IM CONTAINER auszuführen
just pre-commit-run || { echo -e "${YELLOW}Warnung: Initialer 'pre-commit-run' über Docker fehlgeschlagen. Überprüfen Sie die Ausgabe.${NC}"; }
echo "Initialer Pre-commit-Lauf abgeschlossen."
echo ""

# --- Abschließende Meldungen ---
echo -e "${GREEN}--- Setup Abgeschlossen! ---${NC}"
echo "Ihr Projekt '$PROJECT_NAME' ($PACKAGE_NAME) wurde erfolgreich eingerichtet."
echo ""
echo "Nächste Schritte:"
echo "1. Öffnen Sie Ihr Projekt in Ihrem Code-Editor."
echo "2. Verwenden Sie 'just' für alle Entwicklungsaufgaben:"
echo "   - just shell: Startet eine interaktive Shell im Development-Container."
echo "   - just check: Führt Linting-Checks aus (Ruff)."
echo "   - just format: Formatiert Ihren Code (Ruff)."
echo "   - just test: Führt Tests aus (Pytest)."
echo "   - just --list: Zeigt alle verfügbaren Befehle an."
echo "3. Bitte beachten Sie, dass 'pre-commit' beim Committen automatisch läuft."
echo "   Falls es Fehler gibt, beheben Sie diese und committen Sie erneut."
echo ""
echo "Viel Spaß beim Codieren!"
