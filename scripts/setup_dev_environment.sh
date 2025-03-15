#!/bin/bash

# Script para configurar o ambiente de desenvolvimento
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

# Detectar sistema operacional
detect_os() {
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [ -f /etc/debian_version ]; then
      echo "debian"
    elif [ -f /etc/redhat-release ]; then
      echo "redhat"
    else
      echo "linux-other"
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macos"
  elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    echo "windows"
  else
    echo "unknown"
  fi
}

OS=$(detect_os)
log "Sistema operacional detectado: $OS"

# Verificar dependências
check_dependency() {
  if command -v $1 &> /dev/null; then
    log "$1 já está instalado"
    return 0
  else
    warn "$1 não está instalado"
    return 1
  fi
}

# Instalar Node.js
install_nodejs() {
  if check_dependency "node"; then
    NODE_VERSION=$(node -v)
    log "Node.js $NODE_VERSION já está instalado"
  else
    log "Instalando Node.js..."
    
    case $OS in
      debian)
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
        ;;
      redhat)
        curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
        sudo yum install -y nodejs
        ;;
      macos)
        if check_dependency "brew"; then
          brew install node@18
        else
          error "Homebrew não está instalado. Por favor, instale o Homebrew primeiro."
          exit 1
        fi
        ;;
      windows)
        warn "Por favor, instale o Node.js manualmente a partir de https://nodejs.org/"
        ;;
      *)
        error "Sistema operacional não suportado para instalação automática do Node.js"
        exit 1
        ;;
    esac
    
    if check_dependency "node"; then
      NODE_VERSION=$(node -v)
      log "Node.js $NODE_VERSION instalado com sucesso"
    else
      error "Falha ao instalar Node.js"
      exit 1
    fi
  fi
}

# Instalar PostgreSQL
install_postgres() {
  if check_dependency "psql"; then
    PSQL_VERSION=$(psql --version)
    log "PostgreSQL já está instalado: $PSQL_VERSION"
  else
    log "Instalando PostgreSQL..."
    
    case $OS in
      debian)
        sudo apt-get update
        sudo apt-get install -y postgresql postgresql-contrib
        ;;
      redhat)
        sudo yum install -y postgresql-server postgresql-contrib
        sudo postgresql-setup --initdb
        sudo systemctl start postgresql
        sudo systemctl enable postgresql
        ;;
      macos)
        if check_dependency "brew"; then
          brew install postgresql@14
          brew services start postgresql@14
        else
          error "Homebrew não está instalado. Por favor, instale o Homebrew primeiro."
          exit 1
        fi
        ;;
      windows)
        warn "Por favor, instale o PostgreSQL manualmente a partir de https://www.postgresql.org/download/windows/"
        ;;
      *)
        error "Sistema operacional não suportado para instalação automática do PostgreSQL"
        exit 1
        ;;
    esac
    
    if check_dependency "psql"; then
      PSQL_VERSION=$(psql --version)
      log "PostgreSQL instalado com sucesso: $PSQL_VERSION"
    else
      error "Falha ao instalar PostgreSQL"
      exit 1
    fi
  fi
}

# Configurar banco de dados
setup_database() {
  log "Configurando banco de dados PostgreSQL..."
  
  if [[ "$OS" == "windows" ]]; then
    warn "No Windows, configure o banco de dados manualmente usando pgAdmin ou SQL Shell (psql)"
    return
  fi
  
  # Verificar se o PostgreSQL está em execução
  if [[ "$OS" == "macos" ]]; then
    if ! brew services list | grep postgresql | grep started > /dev/null; then
      log "Iniciando PostgreSQL..."
      brew services start postgresql@14
    fi
  elif [[ "$OS" == "debian" || "$OS" == "redhat" ]]; then
    if ! systemctl is-active --quiet postgresql; then
      log "Iniciando PostgreSQL..."
      sudo systemctl start postgresql
    fi
  fi
  
  # Criar usuário e banco de dados
  log "Criando usuário e banco de dados..."
  
  if [[ "$OS" == "macos" ]]; then
    createuser -s rastreabilidade 2>/dev/null || log "Usuário já existe"
    createdb -O rastreabilidade rastreabilidade 2>/dev/null || log "Banco de dados já existe"
    psql -c "ALTER USER rastreabilidade WITH PASSWORD 'rastreabilidade';" postgres
  else
    sudo -u postgres psql -c "CREATE USER rastreabilidade WITH PASSWORD 'rastreabilidade';" 2>/dev/null || log "Usuário já existe"
    sudo -u postgres psql -c "CREATE DATABASE rastreabilidade OWNER rastreabilidade;" 2>/dev/null || log "Banco de dados já existe"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE rastreabilidade TO rastreabilidade;" 2>/dev/null
  fi
  
  log "Banco de dados configurado com sucesso"
}

# Instalar dependências do projeto
install_dependencies() {
  log "Instalando dependências do projeto..."
  
  # Backend
  if [ -d "backend" ]; then
    log "Instalando dependências do backend..."
    cd backend
    npm install
    cd ..
  else
    warn "Diretório 'backend' não encontrado"
  fi
  
  # Frontend
  if [ -d "frontend" ]; then
    log "Instalando dependências do frontend..."
    cd frontend
    npm install
    cd ..
  else
    warn "Diretório 'frontend' não encontrado"
  fi
}

# Configurar variáveis de ambiente
setup_env() {
  log "Configurando variáveis de ambiente..."
  
  # Backend .env
  if [ -d "backend" ]; then
    if [ ! -f "backend/.env" ]; then
      log "Criando arquivo .env para o backend..."
      cat > backend/.env << EOF
# Configurações do Banco de Dados
DB_HOST=localhost
DB_PORT=5432
DB_NAME=rastreabilidade
DB_USER=rastreabilidade
DB_PASSWORD=rastreabilidade

# Configurações da API
PORT=3001
NODE_ENV=development
JWT_SECRET=seu_jwt_secret_aqui
JWT_EXPIRATION=24h

# Configurações de Email (opcional)
# SMTP_HOST=smtp.example.com
# SMTP_PORT=587
# SMTP_USER=user@example.com
# SMTP_PASS=password
EOF
      log "Arquivo .env criado para o backend"
    else
      log "Arquivo .env já existe para o backend"
    fi
  fi
  
  # Frontend .env
  if [ -d "frontend" ]; then
    if [ ! -f "frontend/.env" ]; then
      log "Criando arquivo .env para o frontend..."
      cat > frontend/.env << EOF
REACT_APP_API_URL=http://localhost:3001
REACT_APP_ENV=development
EOF
      log "Arquivo .env criado para o frontend"
    else
      log "Arquivo .env já existe para o frontend"
    fi
  fi
}

# Executar migrações e seeds
run_migrations() {
  if [ -d "backend" ]; then
    log "Executando migrações do banco de dados..."
    cd backend
    npm run migrate || error "Falha ao executar migrações"
    
    log "Executando seeds do banco de dados..."
    npm run seed || error "Falha ao executar seeds"
    cd ..
  else
    warn "Diretório 'backend' não encontrado, não foi possível executar migrações"
  fi
}

# Menu principal
main() {
  log "=== Configuração do Ambiente de Desenvolvimento ==="
  log "Este script irá configurar seu ambiente de desenvolvimento para o Sistema de Rastreabilidade."
  
  # Instalar Node.js
  install_nodejs
  
  # Instalar PostgreSQL
  install_postgres
  
  # Configurar banco de dados
  setup_database
  
  # Configurar variáveis de ambiente
  setup_env
  
  # Instalar dependências do projeto
  install_dependencies
  
  # Executar migrações e seeds
  run_migrations
  
  log "=== Configuração concluída com sucesso! ==="
  log "Para iniciar o backend: cd backend && npm run dev"
  log "Para iniciar o frontend: cd frontend && npm start"
}

# Executar o script
main 