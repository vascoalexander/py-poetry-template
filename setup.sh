#!/bin/bash

set -e

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

cleanup() {
    echo -e "${RED}Ein Fehler ist aufgetreten. Räume auf...${NC}"
    # Check if files/directories exist before attempting to remove them
    [ -d "src" ] && rm -rf src
    [ -f ".env" ] && rm -f .env
    [ -f ".tool-versions" ] && rm -f .tool-versions
}

trap 'cleanup' ERR

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
sed -i.bak "s|^packages = .*|packages = [{include = \"${PACKAGE_NAME}\", from = \"src\"}]|" pyproject.toml
rm -f pyproject.toml.bak
echo "pyproject.toml wurde aktualisiert."

# Erstelle oder aktualisiere __init__.py
INIT_PY_CONTENT="from importlib.metadata import PackageNotFoundError, version\n\ntry:\n    __version__ = version(\"$PACKAGE_NAME\")\nexcept PackageNotFoundError:\n    __version__ = \"unknown\"\n"
mkdir -p "src/$PACKAGE_NAME"
echo -e "$INIT_PY_CONTENT" > "src/$PACKAGE_NAME/__init__.py"
echo "src/$PACKAGE_NAME/__init__.py wurde erstellt/aktualisiert."

# main.py aktualisieren
MAIN_PY_CONTENT="import sys\n\n\ndef main() -> None:\n    print(\"Hello, world from your new Python project!\")\n    print(f\"Python version: {sys.version}\")\n\nif __name__ == '__main__':\n    main()\n"
echo -e "$MAIN_PY_CONTENT" > "src/$PACKAGE_NAME/main.py"
echo "src/$PACKAGE_NAME/main.py wurde erstellt/aktualisiert mit statischem Gruß."

# --- 4: Mise Konfiguration erstellen ---
# Erstelle .tool-versions für mise
echo -e "${YELLOW}Schritt 2.5: Mise Konfiguration (.tool-versions und mise.toml) erstellen...${NC}"
echo "python $PYTHON_VERSION" > .tool-versions
echo "poetry 1.8.2" >> .tool-versions
echo ".tool-versions für mise erstellt."

# --- 4.1: Mise und Poetry auf dem Host installieren und Abhängigkeiten synchronisieren ---
echo -e "${YELLOW}Schritt 2.6: Mise und Poetry auf dem Host installieren und Abhängigkeiten synchronisieren...${NC}"

# Überprüfe, ob mise auf dem Host installiert ist
if ! command -v mise &> /dev/null; then
    echo -e "${YELLOW}mise wurde auf Ihrem Host nicht gefunden. Versuche, mise zu installieren...${NC}"
    curl https://mise.run | sh
    echo -e "${GREEN}mise wurde installiert und zum PATH hinzugefügt.${NC}"
else
    echo -e "${GREEN}mise ist bereits auf Ihrem Host installiert.${NC}"
fi

export PATH="$HOME/.local/share/mise/shims:$HOME/.local/share/mise/bin:$HOME/.local/bin:$PATH"

# Installiere die im .tool-versions definierten Tools (Python, Poetry) mit mise
echo "Installiere Python und Poetry über mise auf dem Host..."
mise install || { echo -e "${RED}Fehler: Konnte Python und/oder Poetry nicht mit mise installieren. Bitte prüfen Sie Ihre mise-Installation und .tool-versions.${NC}"; false; }
echo "Python und Poetry über mise erfolgreich installiert."

# Installiere Poetry-Abhängigkeiten auf dem Host
export PATH="$HOME/.local/share/mise/shims:$PATH"
echo "Installiere Poetry-Abhängigkeiten (einschließlich dev-Dependencies) auf dem Host..."
poetry install --with dev || { echo -e "${RED}Fehler beim Installieren der Poetry-Abhängigkeiten auf dem Host. Überprüfen Sie Ihre pyproject.toml.${NC}"; false; }
echo "Poetry-Abhängigkeiten auf dem Host erfolgreich installiert."

echo "Generiere oder aktualisiere poetry.lock mit mise poetry..."
# Korrektur: Auch hier eine Unter-Shell nutzen
poetry lock || { echo -e "${RED}Fehler beim Generieren/Aktualisieren der poetry.lock Datei via mise. Überprüfen Sie Ihre Poetry-Installation und pyproject.toml.${NC}"; false; }
echo "poetry.lock erfolgreich generiert/aktualisiert."
echo ""

# --- 5. Git-Initialisierung und erster Commit ---
echo -e "${YELLOW}Schritt 5.5: Git-Repository initialisieren und erster Commit...${NC}"
if [ ! -d ".git" ]; then
    git init || { echo -e "${RED}Fehler beim Initialisieren des Git-Repositorys. Stellen Sie sicher, dass Git installiert ist.${NC}"; false; }
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

# --- 6. Schritt zur Prüfung der Docker-Berechtigungen ---
echo -e "${YELLOW}Schritt 6: Prüfe Docker-Berechtigungen und baue Docker Development Image...${NC}"

# Teste, ob der Benutzer Docker-Befehle ohne sudo ausführen kann
# 'docker info' ist ein guter, harmloser Befehl, der die Berechtigungen prüft.
if ! docker info &> /dev/null; then
    echo -e "${RED}Fehler: Ihr Benutzer hat keine Berechtigung, Docker-Befehle auszuführen (ohne sudo). Ist Docker installiert?${NC}"
    echo -e "${YELLOW}Bitte fügen Sie Ihren Benutzer zur 'docker'-Gruppe hinzu, indem Sie diesen Befehl ausführen:${NC}"
    echo -e "${YELLOW}   sudo usermod -aG docker $USER${NC}"
    echo -e "${YELLOW}Nachdem Sie diesen Befehl ausgeführt haben, melden Sie sich BITTE VOLLSTÄNDIG AB und wieder AN (oder starten Sie Ihren Computer neu), damit die Änderungen wirksam werden.${NC}"
    echo -e "${YELLOW}Versuchen Sie dann, das Setup-Skript erneut auszuführen.${NC}"
    false # Skript abbrechen, da Docker-Build ohne Berechtigungen nicht funktionieren wird.
fi

# --- 6.1 Sicherstellen, dass Docker Buildx installiert und aktuell ist ---
echo -e "${YELLOW}Schritt 6a: Prüfe und installiere/aktualisiere Docker Buildx...${NC}"
if ! docker buildx version &> /dev/null; then
    echo -e "${RED}Docker Buildx wurde nicht gefunden. Versuche, es zu installieren.${NC}"
    docker buildx install || { echo -e "${RED}Fehler: Konnte Docker Buildx nicht installieren. Bitte installieren Sie Buildx manuell (${YELLOW}https://docs.docker.com/buildx/install/${RED}) und versuchen Sie es erneut.${NC}"; false; }
    echo -e "${GREEN}Docker Buildx erfolgreich installiert.${NC}"
else
    # Prüfe die Buildx-Version auf Kompatibilität mit --load (hinzugefügt in v0.6.0)
    BUILDX_VERSION_RAW=$(docker buildx version 2>&1 | grep -oP 'v\d+\.\d+\.\d+' | head -1)
    # Extrahiere Major, Minor, Patch für numerischen Vergleich
    BUILDX_MAJOR=$(echo "$BUILDX_VERSION_RAW" | cut -d'.' -f1 | tr -d 'v')
    BUILDX_MINOR=$(echo "$BUILDX_VERSION_RAW" | cut -d'.' -f2)
    BUILDX_PATCH=$(echo "$BUILDX_VERSION_RAW" | cut -d'.' -f3)

    # Konvertiere in ein vergleichbares Zahlenformat (z.B. v0.6.0 -> 000006000)
    BUILDX_VER_NUM=$(printf "%03d%03d%03d" "$BUILDX_MAJOR" "$BUILDX_MINOR" "$BUILDX_PATCH")

    # Prüfe, ob die Version kleiner als 0.6.0 ist
    if [ "$BUILDX_VER_NUM" -lt "000006000" ]; then
        echo -e "${RED}Ihre Docker Buildx-Version ($BUILDX_VERSION_RAW) ist veraltet und unterstützt die '--load'-Option möglicherweise nicht.${NC}"
        echo -e "${YELLOW}Versuche, Buildx zu aktualisieren...${NC}"
        docker buildx install || { echo -e "${RED}Fehler: Konnte Docker Buildx nicht aktualisieren. Bitte aktualisieren Sie Buildx manuell (${YELLOW}https://docs.docker.com/buildx/install/${RED}) und versuchen Sie es erneut.${NC}"; false; }
        echo -e "${GREEN}Docker Buildx erfolgreich aktualisiert.${NC}"
    else
        echo -e "${GREEN}Docker Buildx ist bereits installiert und aktuell (${BUILDX_VERSION_RAW}).${NC}"
    fi
fi

# --- 6.2 Docker Image bauen ---
echo -e "${YELLOW}Schritt 7: Docker Development Image bauen...${NC}"
echo "Starte den Build des Docker-Images (dies kann einen Moment dauern)..."
if ! command -v make &> /dev/null; then
    echo -e "${RED}Fehler: 'make' Befehl nicht gefunden. Bitte installieren Sie 'make' (z.B. sudo apt install make).${NC}"
    false
fi

PYTHON_VERSION="$PYTHON_VERSION" make build

if [ $? -ne 0 ]; then
    echo -e "${RED}Fehler beim Bauen des Docker-Images. Überprüfen Sie Ihr Dockerfile.dev und die 'make' Ausgabe.${NC}"
    false
fi
echo "Docker Development Image erfolgreich gebaut!"
echo ""

# --- 7. Pre-commit Hooks installieren (Host-seitig) ---
echo -e "${YELLOW}Schritt 7: Pre-commit Hooks installieren (Host-seitig und via Docker)...${NC}"
# Dieser Befehl installiert die Git-Hooks (.git/hooks/pre-commit)
poetry run pre-commit install
if [ $? -ne 0 ]; then
    echo -e "${RED}Fehler beim Installieren der host-seitigen pre-commit Hooks.${NC}"
fi
echo "Host-seitige Pre-commit Hooks installiert."

# Optional: Führe einen ersten Lauf der pre-commit Hooks direkt nach der Installation aus
# Dies stellt sicher, dass alle initialen Formatierungen und Checks angewendet werden
echo "Führe erste Pre-commit Checks aus (dies kann Dateien ändern)..."
poetry run pre-commit run --all-files || true
echo "Initialer Pre-commit-Lauf abgeschlossen."
echo ""

# --- Abschließende Meldungen ---
echo -e "${GREEN}--- Setup Abgeschlossen! ---${NC}"
echo "Ihr Projekt '$PROJECT_NAME' ($PACKAGE_NAME) wurde erfolgreich eingerichtet."
echo ""
echo "Nächste Schritte:"
echo "1. Öffnen Sie Ihr Projekt in Ihrem Code-Editor."
echo "2. Verwenden Sie 'make' für alle Entwicklungsaufgaben:"
echo ""
echo "Host-side Commands (using mise to provide Poetry, then Poetry for tools):"
echo "  make lint               : Run Ruff linter on source and tests."
echo "  make format             : Run Ruff formatter on source and tests."
echo "  make check              : Run Ruff lint and MyPy type checks on source and tests."
echo "  make pre-commit         : Manually run all pre-commit hooks."
echo ""
echo "Docker Container Commands:"
echo "  make build              : Build the Docker development image."
echo "  make clean              : Remove the Docker development image."
echo "  make shell              : Open an interactive shell inside the development container."
echo "  make test               : Run Pytest for unit and integration tests inside container."
echo "  make coverage           : Run Pytest with coverage report (terminal) inside container."
echo "  make coverage-html      : Generate HTML coverage report inside container and copy to host."
echo "  make run                : Run the main application script inside container."
echo ""
echo "3. Bitte beachten Sie, dass 'pre-commit' beim Committen automatisch läuft."
echo "   Falls es Fehler gibt, beheben Sie diese und committen Sie erneut."
echo ""
echo "Viel Spaß beim Codieren!"