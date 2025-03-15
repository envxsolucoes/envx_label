#!/bin/bash

# Script para tornar todos os scripts executáveis
# Autor: Sistema de Rastreabilidade
# Data: 2024

# Cores para saída
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Função para exibir mensagens
log() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Diretório atual (onde este script está localizado)
SCRIPTS_DIR="$(dirname "$(readlink -f "$0")")"

log "Tornando todos os scripts executáveis no diretório: $SCRIPTS_DIR"

# Contar scripts
SCRIPT_COUNT=$(find "$SCRIPTS_DIR" -name "*.sh" | wc -l)
log "Encontrados $SCRIPT_COUNT scripts"

# Tornar todos os scripts executáveis
find "$SCRIPTS_DIR" -name "*.sh" -type f -exec chmod +x {} \;

if [ $? -ne 0 ]; then
  error "Falha ao tornar os scripts executáveis"
  exit 1
fi

# Listar scripts e seus status
log "Scripts executáveis:"
echo ""
echo "| Script | Status |"
echo "|--------|--------|"

for script in $(find "$SCRIPTS_DIR" -name "*.sh" -type f | sort); do
  SCRIPT_NAME=$(basename "$script")
  
  if [ -x "$script" ]; then
    echo "| $SCRIPT_NAME | ✅ Executável |"
  else
    echo "| $SCRIPT_NAME | ❌ Não executável |"
    warn "Não foi possível tornar $SCRIPT_NAME executável"
  fi
done

echo ""
log "Processo concluído!"
log "Para executar qualquer script, use: ./<nome_do_script>.sh" 