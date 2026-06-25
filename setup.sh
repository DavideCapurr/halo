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

# 2. Success
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Setup completato!${NC}\n"
echo -e "${YELLOW}Prossimi step:${NC}"
echo -e "  1. Apri Xcode: ${YELLOW}open Halo.xcodeproj${NC}"
echo -e "  2. Config build in ${YELLOW}Config/*.xcconfig${NC} (SUPABASE_URL/ANON_KEY"
echo -e "     condivise app+widget via Config/Shared.xcconfig)"
echo -e "  3. Seleziona un simulatore (es. iPhone 15 Pro)"
echo -e "  4. Premi ⌘R per build & run\n"
echo -e "${YELLOW}Per sviluppo con Supabase locale:${NC}"
echo -e "  ${YELLOW}cd supabase && supabase start${NC}\n"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
