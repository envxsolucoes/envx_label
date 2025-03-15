#!/bin/bash

# Script para automatizar o deploy da aplicação
# Autor: Sistema de Rastreabilidade
# Data: 2024

# Cores para saída
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
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

step() {
  echo -e "${BLUE}[STEP]${NC} $1"
}

# Configurações padrão
APP_DIR="/opt/rastreabilidade"
GIT_REPO=""
GIT_BRANCH="main"
BACKUP_BEFORE_DEPLOY=true
RESTART_SERVICES=true
ENVIRONMENT="production"
SKIP_BUILD=false
SKIP_MIGRATIONS=false
SKIP_FRONTEND=false
SKIP_BACKEND=false

# Função para exibir ajuda
show_help() {
  echo "Uso: $0 [opções]"
  echo ""
  echo "Opções:"
  echo "  -h, --help                Exibe esta mensagem de ajuda"
  echo "  -d, --directory DIR       Diretório da aplicação (padrão: $APP_DIR)"
  echo "  -r, --repo URL            URL do repositório Git"
  echo "  -b, --branch BRANCH       Branch do Git para deploy (padrão: $GIT_BRANCH)"
  echo "  -e, --env ENV             Ambiente (development, staging, production) (padrão: $ENVIRONMENT)"
  echo "  --skip-backup             Não realizar backup antes do deploy"
  echo "  --skip-restart            Não reiniciar serviços após o deploy"
  echo "  --skip-build              Não realizar build da aplicação"
  echo "  --skip-migrations         Não executar migrações do banco de dados"
  echo "  --skip-frontend           Pular deploy do frontend"
  echo "  --skip-backend            Pular deploy do backend"
  echo ""
  echo "Exemplo:"
  echo "  $0 --repo https://github.com/usuario/rastreabilidade.git --branch develop --env staging"
  exit 0
}

# Processar argumentos da linha de comando
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      ;;
    -d|--directory)
      APP_DIR="$2"
      shift 2
      ;;
    -r|--repo)
      GIT_REPO="$2"
      shift 2
      ;;
    -b|--branch)
      GIT_BRANCH="$2"
      shift 2
      ;;
    -e|--env)
      ENVIRONMENT="$2"
      shift 2
      ;;
    --skip-backup)
      BACKUP_BEFORE_DEPLOY=false
      shift
      ;;
    --skip-restart)
      RESTART_SERVICES=false
      shift
      ;;
    --skip-build)
      SKIP_BUILD=true
      shift
      ;;
    --skip-migrations)
      SKIP_MIGRATIONS=true
      shift
      ;;
    --skip-frontend)
      SKIP_FRONTEND=true
      shift
      ;;
    --skip-backend)
      SKIP_BACKEND=true
      shift
      ;;
    *)
      error "Opção desconhecida: $1"
      show_help
      ;;
  esac
done

# Verificar se o diretório da aplicação existe
if [ ! -d "$APP_DIR" ]; then
  warn "Diretório da aplicação não encontrado: $APP_DIR"
  
  if [ -z "$GIT_REPO" ]; then
    error "Diretório da aplicação não existe e nenhum repositório Git foi especificado."
    exit 1
  fi
  
  log "Criando diretório da aplicação: $APP_DIR"
  mkdir -p "$APP_DIR"
  
  if [ $? -ne 0 ]; then
    error "Não foi possível criar o diretório da aplicação: $APP_DIR"
    exit 1
  fi
fi

# Verificar se o Git está instalado
if ! command -v git &> /dev/null; then
  error "Git não encontrado. Por favor, instale o Git."
  exit 1
fi

# Verificar se o Node.js está instalado
if ! command -v node &> /dev/null; then
  error "Node.js não encontrado. Por favor, instale o Node.js."
  exit 1
fi

# Verificar se o npm está instalado
if ! command -v npm &> /dev/null; then
  error "npm não encontrado. Por favor, instale o npm."
  exit 1
fi

# Função para realizar backup do banco de dados
backup_database() {
  if [ "$BACKUP_BEFORE_DEPLOY" = true ]; then
    step "Realizando backup do banco de dados antes do deploy..."
    
    # Verificar se o script de backup existe
    BACKUP_SCRIPT="$(dirname "$0")/backup_database.sh"
    
    if [ -f "$BACKUP_SCRIPT" ]; then
      log "Executando script de backup: $BACKUP_SCRIPT"
      bash "$BACKUP_SCRIPT" --output-dir "${APP_DIR}/backups/pre_deploy_$(date +%Y%m%d_%H%M%S)"
      
      if [ $? -ne 0 ]; then
        warn "Falha ao realizar backup do banco de dados. Continuando com o deploy..."
      else
        log "Backup do banco de dados concluído com sucesso."
      fi
    else
      warn "Script de backup não encontrado: $BACKUP_SCRIPT. Pulando backup."
    fi
  else
    log "Backup antes do deploy desativado. Pulando..."
  fi
}

# Função para clonar ou atualizar o repositório
update_repository() {
  step "Atualizando código-fonte..."
  
  # Verificar se já existe um repositório Git
  if [ -d "${APP_DIR}/.git" ]; then
    log "Repositório Git encontrado. Atualizando..."
    
    # Salvar o diretório atual
    CURRENT_DIR=$(pwd)
    
    # Mudar para o diretório da aplicação
    cd "$APP_DIR"
    
    # Verificar se há alterações locais
    if [ -n "$(git status --porcelain)" ]; then
      warn "Existem alterações locais não commitadas. Fazendo backup..."
      git stash
    fi
    
    # Atualizar o repositório
    log "Atualizando para a branch $GIT_BRANCH..."
    git fetch --all
    git checkout "$GIT_BRANCH"
    git pull origin "$GIT_BRANCH"
    
    # Voltar para o diretório original
    cd "$CURRENT_DIR"
  else
    # Se não existe um repositório Git e uma URL foi fornecida, clonar
    if [ -n "$GIT_REPO" ]; then
      log "Clonando repositório: $GIT_REPO (branch: $GIT_BRANCH)..."
      git clone -b "$GIT_BRANCH" "$GIT_REPO" "$APP_DIR"
      
      if [ $? -ne 0 ]; then
        error "Falha ao clonar o repositório."
        exit 1
      fi
    else
      warn "Nenhum repositório Git encontrado e nenhuma URL fornecida. Pulando atualização do código-fonte."
    fi
  fi
  
  log "Código-fonte atualizado com sucesso."
}

# Função para instalar dependências e construir o backend
deploy_backend() {
  if [ "$SKIP_BACKEND" = true ]; then
    log "Deploy do backend desativado. Pulando..."
    return
  fi
  
  step "Implantando backend..."
  
  # Verificar se o diretório backend existe
  if [ ! -d "${APP_DIR}/backend" ]; then
    error "Diretório backend não encontrado: ${APP_DIR}/backend"
    exit 1
  fi
  
  # Salvar o diretório atual
  CURRENT_DIR=$(pwd)
  
  # Mudar para o diretório backend
  cd "${APP_DIR}/backend"
  
  # Instalar dependências
  log "Instalando dependências do backend..."
  npm ci
  
  if [ $? -ne 0 ]; then
    error "Falha ao instalar dependências do backend."
    cd "$CURRENT_DIR"
    exit 1
  fi
  
  # Configurar variáveis de ambiente
  if [ ! -f ".env" ]; then
    warn "Arquivo .env não encontrado. Criando a partir do exemplo..."
    
    if [ -f ".env.example" ]; then
      cp .env.example .env
      log "Arquivo .env criado. Por favor, edite-o com as configurações corretas."
    else
      warn "Arquivo .env.example não encontrado. Pulando criação do .env."
    fi
  fi
  
  # Executar migrações do banco de dados
  if [ "$SKIP_MIGRATIONS" = false ]; then
    log "Executando migrações do banco de dados..."
    NODE_ENV="$ENVIRONMENT" npm run migrate
    
    if [ $? -ne 0 ]; then
      error "Falha ao executar migrações do banco de dados."
      cd "$CURRENT_DIR"
      exit 1
    fi
  else
    log "Migrações do banco de dados desativadas. Pulando..."
  fi
  
  # Construir a aplicação
  if [ "$SKIP_BUILD" = false ]; then
    log "Construindo backend..."
    NODE_ENV="$ENVIRONMENT" npm run build
    
    if [ $? -ne 0 ]; then
      error "Falha ao construir o backend."
      cd "$CURRENT_DIR"
      exit 1
    fi
  else
    log "Build do backend desativado. Pulando..."
  fi
  
  # Voltar para o diretório original
  cd "$CURRENT_DIR"
  
  log "Backend implantado com sucesso."
}

# Função para instalar dependências e construir o frontend
deploy_frontend() {
  if [ "$SKIP_FRONTEND" = true ]; then
    log "Deploy do frontend desativado. Pulando..."
    return
  fi
  
  step "Implantando frontend..."
  
  # Verificar se o diretório frontend existe
  if [ ! -d "${APP_DIR}/frontend" ]; then
    error "Diretório frontend não encontrado: ${APP_DIR}/frontend"
    exit 1
  fi
  
  # Salvar o diretório atual
  CURRENT_DIR=$(pwd)
  
  # Mudar para o diretório frontend
  cd "${APP_DIR}/frontend"
  
  # Instalar dependências
  log "Instalando dependências do frontend..."
  npm ci
  
  if [ $? -ne 0 ]; then
    error "Falha ao instalar dependências do frontend."
    cd "$CURRENT_DIR"
    exit 1
  fi
  
  # Configurar variáveis de ambiente
  if [ ! -f ".env" ]; then
    warn "Arquivo .env não encontrado. Criando a partir do exemplo..."
    
    if [ -f ".env.example" ]; then
      cp .env.example .env
      log "Arquivo .env criado. Por favor, edite-o com as configurações corretas."
    else
      warn "Arquivo .env.example não encontrado. Pulando criação do .env."
    fi
  fi
  
  # Construir a aplicação
  if [ "$SKIP_BUILD" = false ]; then
    log "Construindo frontend..."
    REACT_APP_ENV="$ENVIRONMENT" npm run build
    
    if [ $? -ne 0 ]; then
      error "Falha ao construir o frontend."
      cd "$CURRENT_DIR"
      exit 1
    fi
  else
    log "Build do frontend desativado. Pulando..."
  fi
  
  # Voltar para o diretório original
  cd "$CURRENT_DIR"
  
  log "Frontend implantado com sucesso."
}

# Função para reiniciar serviços
restart_services() {
  if [ "$RESTART_SERVICES" = true ]; then
    step "Reiniciando serviços..."
    
    # Verificar se o serviço systemd existe
    if systemctl is-active --quiet rastreabilidade.service; then
      log "Reiniciando serviço rastreabilidade..."
      sudo systemctl restart rastreabilidade.service
      
      if [ $? -ne 0 ]; then
        error "Falha ao reiniciar o serviço rastreabilidade."
        exit 1
      fi
    else
      warn "Serviço rastreabilidade não encontrado. Pulando reinicialização."
    fi
    
    # Verificar se o Nginx está instalado e ativo
    if command -v nginx &> /dev/null && systemctl is-active --quiet nginx; then
      log "Reiniciando Nginx..."
      sudo systemctl restart nginx
      
      if [ $? -ne 0 ]; then
        error "Falha ao reiniciar o Nginx."
        exit 1
      fi
    fi
    
    log "Serviços reiniciados com sucesso."
  else
    log "Reinicialização de serviços desativada. Pulando..."
  fi
}

# Função principal
main() {
  log "=== Iniciando deploy da aplicação ==="
  log "Ambiente: $ENVIRONMENT"
  log "Diretório: $APP_DIR"
  log "Branch: $GIT_BRANCH"
  
  # Realizar backup do banco de dados
  backup_database
  
  # Atualizar repositório
  update_repository
  
  # Implantar backend
  deploy_backend
  
  # Implantar frontend
  deploy_frontend
  
  # Reiniciar serviços
  restart_services
  
  log "=== Deploy concluído com sucesso! ==="
}

# Executar o script
main 