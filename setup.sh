#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Setup Halo per macOS${NC}\n"

# 1. Check Xcode
echo -e "${YELLOW}→ Verifico Xcode...${NC}"
if ! command -v xcode-select &> /dev/null; then
    echo -e "${RED}✗ Xcode non trovato. Installalo dall'App Store.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Xcode trovato${NC}\n"

# 2. Install XcodeGen if needed
echo -e "${YELLOW}→ Verifico XcodeGen...${NC}"
if ! command -v xcodegen &> /dev/null; then
    echo -e "${YELLOW}  → Installando XcodeGen con Homebrew...${NC}"
    if ! command -v brew &> /dev/null; then
        echo -e "${RED}✗ Homebrew non trovato. Installalo da https://brew.sh${NC}"
        exit 1
    fi
    brew install xcodegen
fi
echo -e "${GREEN}✓ XcodeGen pronto${NC}\n"

# 3. Create Secrets.xcconfig if missing
echo -e "${YELLOW}→ Verifico configurazione Secrets...${NC}"
if [ ! -f "Secrets.xcconfig" ]; then
    echo -e "${YELLOW}  → Creando Secrets.xcconfig da template...${NC}"
    cp Secrets.xcconfig.template Secrets.xcconfig
    echo -e "${YELLOW}  ⚠ Modifica Secrets.xcconfig con le tue credenziali Supabase${NC}"
    echo -e "${YELLOW}  → Per sviluppo locale: supabase start${NC}\n"
else
    echo -e "${GREEN}✓ Secrets.xcconfig già configurato${NC}\n"
fi

# 4. Generate Xcode project
echo -e "${YELLOW}→ Genero il progetto Xcode da project.yml...${NC}"
xcodegen generate
echo -e "${GREEN}✓ Progetto Xcode generato${NC}\n"

# 5. Setup git hooks
echo -e "${YELLOW}→ Configuro git hooks...${NC}"
mkdir -p .git/hooks

cat > .git/hooks/post-merge << 'HOOK_END'
#!/bin/bash
# Rigenera il progetto Xcode se project.yml è cambiato
if git diff-tree --no-commit-id --name-only -r HEAD | grep -q "^project.yml$"; then
    echo "project.yml è stato aggiornato. Rigenerando Xcode project..."
    xcodegen generate
    echo "✓ Xcode project rigenerato"
fi
HOOK_END
chmod +x .git/hooks/post-merge

cat > .git/hooks/post-checkout << 'HOOK_END'
#!/bin/bash
# Rigenera il progetto Xcode se project.yml è cambiato
if git diff HEAD@{1}..HEAD --name-only | grep -q "^project.yml$"; then
    echo "project.yml è stato aggiornato. Rigenerando Xcode project..."
    xcodegen generate
    echo "✓ Xcode project rigenerato"
fi
HOOK_END
chmod +x .git/hooks/post-checkout

echo -e "${GREEN}✓ Git hooks configurati${NC}\n"

# 6. Success
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Setup completato!${NC}\n"
echo -e "${YELLOW}Prossimi step:${NC}"
echo -e "  1. Apri Xcode: ${YELLOW}open Halo.xcodeproj${NC}"
echo -e "  2. Seleziona un simulatore (es. iPhone 15 Pro)"
echo -e "  3. Premi ⌘R per build & run\n"
echo -e "${YELLOW}Per sviluppo con Supabase locale:${NC}"
echo -e "  ${YELLOW}cd supabase && supabase start${NC}\n"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
