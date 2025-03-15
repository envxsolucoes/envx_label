#!/bin/bash

# Script para configurar o ambiente de produção no AlmaLinux
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

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then
  error "Este script precisa ser executado como root"
  exit 1
fi

# Verificar se é AlmaLinux
if [ ! -f /etc/almalinux-release ]; then
  error "Este script foi projetado para AlmaLinux"
  exit 1
fi

log "Iniciando configuração do ambiente de produção..."

# Atualizar o sistema
log "Atualizando o sistema..."
dnf update -y

# Instalar dependências
log "Instalando dependências..."
dnf install -y epel-release
dnf install -y curl wget git vim unzip zip tar htop net-tools firewalld

# Configurar firewall
log "Configurando firewall..."
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-port=3001/tcp # Backend
firewall-cmd --permanent --add-port=5432/tcp # PostgreSQL
firewall-cmd --reload

# Instalar Node.js
log "Instalando Node.js..."
dnf module install -y nodejs:18

# Instalar PostgreSQL
log "Instalando PostgreSQL..."
dnf install -y postgresql-server postgresql-contrib

# Inicializar o banco de dados PostgreSQL
log "Inicializando o banco de dados PostgreSQL..."
postgresql-setup --initdb

# Configurar PostgreSQL para aceitar conexões remotas
log "Configurando PostgreSQL..."
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /var/lib/pgsql/data/postgresql.conf
echo "host    all             all             0.0.0.0/0               md5" >> /var/lib/pgsql/data/pg_hba.conf

# Iniciar e habilitar PostgreSQL
log "Iniciando PostgreSQL..."
systemctl enable postgresql
systemctl start postgresql

# Criar usuário e banco de dados
log "Criando usuário e banco de dados..."
su - postgres -c "psql -c \"CREATE USER rastreabilidade WITH PASSWORD 'rastreabilidade';\""
su - postgres -c "psql -c \"CREATE DATABASE rastreabilidade OWNER rastreabilidade;\""
su - postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE rastreabilidade TO rastreabilidade;\""

# Criar diretório para a aplicação
log "Criando diretório para a aplicação..."
mkdir -p /opt/rastreabilidade
chown -R $(logname):$(logname) /opt/rastreabilidade

# Configurar o Nginx (opcional)
log "Deseja instalar e configurar o Nginx como proxy reverso? (s/n)"
read -r install_nginx

if [[ "$install_nginx" =~ ^[Ss]$ ]]; then
  log "Instalando Nginx..."
  dnf install -y nginx
  
  # Configurar Nginx
  cat > /etc/nginx/conf.d/rastreabilidade.conf << EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

  # Iniciar e habilitar Nginx
  systemctl enable nginx
  systemctl start nginx
  
  log "Nginx configurado com sucesso!"
fi

# Instruções finais
log "Configuração concluída com sucesso!"
log "Para completar a instalação, siga os passos abaixo:"
log "1. Clone o repositório: git clone <url-do-repositorio> /opt/rastreabilidade"
log "2. Configure o arquivo .env no backend"
log "3. Execute 'npm install' no diretório backend"
log "4. Execute 'npm run migrate' para criar as tabelas do banco de dados"
log "5. Execute 'npm run seed' para popular o banco de dados com dados iniciais"
log "6. Execute 'npm start' para iniciar o servidor"

# Configurar serviço systemd (opcional)
log "Deseja configurar um serviço systemd para a aplicação? (s/n)"
read -r install_service

if [[ "$install_service" =~ ^[Ss]$ ]]; then
  cat > /etc/systemd/system/rastreabilidade.service << EOF
[Unit]
Description=Sistema de Rastreabilidade
After=network.target postgresql.service

[Service]
Type=simple
User=$(logname)
WorkingDirectory=/opt/rastreabilidade/backend
ExecStart=/usr/bin/npm start
Restart=on-failure
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

  log "Serviço systemd criado. Para iniciar a aplicação, execute:"
  log "systemctl enable rastreabilidade"
  log "systemctl start rastreabilidade"
fi

log "Configuração do ambiente concluída!" 