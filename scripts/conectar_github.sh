#!/bin/bash

# Script para conectar ao GitHub no AlmaLinux
# Autor: ENVX Solutions
# Data: 14/03/2025

# Cores para saída
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para exibir mensagens
log() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# IMPORTANTE: Nunca compartilhe seu token em repositórios públicos
# Use variáveis de ambiente ou arquivos de configuração seguros
# Solicite o token como entrada do usuário em vez de codificá-lo
log "Por favor, insira seu token de acesso pessoal do GitHub:"
read -s GITHUB_TOKEN

if [ -z "$GITHUB_TOKEN" ]; then
  error "Token não fornecido. Abortando."
  exit 1
fi

# Diretório de instalação
INSTALL_DIR="/opt/rastreabilidade"

log "Iniciando configuração da conexão com o GitHub..."

# Verificar se o Git está instalado
if ! command -v git &> /dev/null; then
  warning "Git não está instalado. Instalando..."
  sudo dnf install -y git
else
  log "Git já está instalado: $(git --version)"
fi

# Configurar Git (se necessário)
if [ -z "$(git config --global user.name)" ]; then
  log "Configurando nome de usuário do Git..."
  git config --global user.name "ENVX Admin"
fi

if [ -z "$(git config --global user.email)" ]; then
  log "Configurando email do Git..."
  git config --global user.email "admin@envx.com.br"
fi

# Criar diretório para o projeto (se necessário)
if [ ! -d "$INSTALL_DIR" ]; then
  log "Criando diretório para o projeto..."
  sudo mkdir -p $INSTALL_DIR
  sudo chown -R $(whoami):$(whoami) $INSTALL_DIR
else
  log "Diretório do projeto já existe: $INSTALL_DIR"
fi

# Navegar para o diretório
cd $INSTALL_DIR
log "Diretório atual: $(pwd)"

# Verificar se já é um repositório Git
if [ -d ".git" ]; then
  warning "Já existe um repositório Git neste diretório."
  
  # Verificar se o repositório remoto é o correto
  CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null || echo "")
  
  if [ "$CURRENT_REMOTE" != "$GITHUB_REPO" ] && [ "$CURRENT_REMOTE" != "$GITHUB_REPO_WITH_TOKEN" ]; then
    log "Configurando repositório remoto com o token de acesso..."
    git remote set-url origin $GITHUB_REPO_WITH_TOKEN || git remote add origin $GITHUB_REPO_WITH_TOKEN
  else
    log "Repositório remoto já está configurado corretamente."
  fi
  
  # Atualizar o repositório
  log "Atualizando o repositório..."
  git pull origin master
else
  # Clonar o repositório
  log "Clonando o repositório com o token de acesso..."
  git clone https://${GITHUB_TOKEN}@github.com/envxsolucoes/envx_label.git .
fi

# Verificar se a conexão foi estabelecida corretamente
if [ $? -eq 0 ]; then
  success "Conexão com o GitHub estabelecida com sucesso!"
  log "Configuração do repositório:"
  git remote -v
  log "Status do repositório:"
  git status
else
  error "Falha ao conectar com o GitHub. Verifique o token de acesso e tente novamente."
  exit 1
fi

# Configurar armazenamento de credenciais (opcional)
log "Configurando armazenamento de credenciais temporário (1 hora)..."
git config --global credential.helper 'cache --timeout=3600'

log "Próximos passos:"
echo "1. Para configurar o ambiente, execute: sudo bash scripts/setup_almalinux.sh"
echo "2. Para mais informações, consulte o arquivo README.md"

success "Configuração concluída com sucesso!" 