#!/bin/bash

# Script para realizar backup do banco de dados
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

# Configurações padrão
DB_NAME="rastreabilidade"
DB_USER="rastreabilidade"
DB_PASSWORD="rastreabilidade"
DB_HOST="localhost"
DB_PORT="5432"
BACKUP_DIR="/var/backups/rastreabilidade"
RETENTION_DAYS=7
ENABLE_COMPRESSION=true
ENABLE_ENCRYPTION=false
ENCRYPTION_PASSWORD=""

# Função para exibir ajuda
show_help() {
  echo "Uso: $0 [opções]"
  echo ""
  echo "Opções:"
  echo "  -h, --help                Exibe esta mensagem de ajuda"
  echo "  -d, --database NOME       Nome do banco de dados (padrão: $DB_NAME)"
  echo "  -u, --user USUÁRIO        Usuário do banco de dados (padrão: $DB_USER)"
  echo "  -p, --password SENHA      Senha do banco de dados"
  echo "  --host HOST               Host do banco de dados (padrão: $DB_HOST)"
  echo "  --port PORTA              Porta do banco de dados (padrão: $DB_PORT)"
  echo "  -o, --output-dir DIR      Diretório de saída para os backups (padrão: $BACKUP_DIR)"
  echo "  -r, --retention DIAS      Número de dias para reter backups (padrão: $RETENTION_DAYS)"
  echo "  -c, --compress            Habilitar compressão (padrão: $ENABLE_COMPRESSION)"
  echo "  -e, --encrypt             Habilitar criptografia"
  echo "  --encrypt-password SENHA  Senha para criptografia (obrigatório se -e for usado)"
  echo ""
  echo "Exemplo:"
  echo "  $0 --database meudb --user meuusuario --password minhasenha --output-dir /backups"
  exit 0
}

# Processar argumentos da linha de comando
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      ;;
    -d|--database)
      DB_NAME="$2"
      shift 2
      ;;
    -u|--user)
      DB_USER="$2"
      shift 2
      ;;
    -p|--password)
      DB_PASSWORD="$2"
      shift 2
      ;;
    --host)
      DB_HOST="$2"
      shift 2
      ;;
    --port)
      DB_PORT="$2"
      shift 2
      ;;
    -o|--output-dir)
      BACKUP_DIR="$2"
      shift 2
      ;;
    -r|--retention)
      RETENTION_DAYS="$2"
      shift 2
      ;;
    -c|--compress)
      ENABLE_COMPRESSION=true
      shift
      ;;
    -e|--encrypt)
      ENABLE_ENCRYPTION=true
      shift
      ;;
    --encrypt-password)
      ENCRYPTION_PASSWORD="$2"
      shift 2
      ;;
    *)
      error "Opção desconhecida: $1"
      show_help
      ;;
  esac
done

# Verificar se o diretório de backup existe, caso contrário, criar
if [ ! -d "$BACKUP_DIR" ]; then
  log "Criando diretório de backup: $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
  if [ $? -ne 0 ]; then
    error "Não foi possível criar o diretório de backup: $BACKUP_DIR"
    exit 1
  fi
fi

# Verificar se o pg_dump está disponível
if ! command -v pg_dump &> /dev/null; then
  error "pg_dump não encontrado. Por favor, instale o cliente PostgreSQL."
  exit 1
fi

# Verificar se a criptografia está habilitada e se a senha foi fornecida
if [ "$ENABLE_ENCRYPTION" = true ] && [ -z "$ENCRYPTION_PASSWORD" ]; then
  error "A criptografia está habilitada, mas nenhuma senha foi fornecida. Use --encrypt-password."
  exit 1
fi

# Verificar se o openssl está disponível para criptografia
if [ "$ENABLE_ENCRYPTION" = true ] && ! command -v openssl &> /dev/null; then
  error "openssl não encontrado. Por favor, instale o openssl para usar a criptografia."
  exit 1
fi

# Gerar nome do arquivo de backup
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILENAME="${DB_NAME}_${TIMESTAMP}.sql"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_FILENAME}"

# Configurar variáveis de ambiente para o pg_dump
export PGPASSWORD="$DB_PASSWORD"

# Realizar o backup
log "Iniciando backup do banco de dados $DB_NAME..."
pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -F p > "$BACKUP_PATH"

# Verificar se o backup foi bem-sucedido
if [ $? -ne 0 ]; then
  error "Falha ao realizar o backup do banco de dados."
  exit 1
fi

log "Backup concluído: $BACKUP_PATH"

# Comprimir o backup se habilitado
if [ "$ENABLE_COMPRESSION" = true ]; then
  log "Comprimindo o backup..."
  gzip -f "$BACKUP_PATH"
  if [ $? -ne 0 ]; then
    error "Falha ao comprimir o backup."
    exit 1
  fi
  BACKUP_PATH="${BACKUP_PATH}.gz"
  log "Backup comprimido: $BACKUP_PATH"
fi

# Criptografar o backup se habilitado
if [ "$ENABLE_ENCRYPTION" = true ]; then
  log "Criptografando o backup..."
  openssl enc -aes-256-cbc -salt -in "$BACKUP_PATH" -out "${BACKUP_PATH}.enc" -pass pass:"$ENCRYPTION_PASSWORD"
  if [ $? -ne 0 ]; then
    error "Falha ao criptografar o backup."
    exit 1
  fi
  # Remover o arquivo original após a criptografia
  rm "$BACKUP_PATH"
  BACKUP_PATH="${BACKUP_PATH}.enc"
  log "Backup criptografado: $BACKUP_PATH"
fi

# Remover backups antigos
if [ "$RETENTION_DAYS" -gt 0 ]; then
  log "Removendo backups com mais de $RETENTION_DAYS dias..."
  find "$BACKUP_DIR" -type f -name "${DB_NAME}_*.sql*" -mtime +$RETENTION_DAYS -delete
  if [ $? -ne 0 ]; then
    warn "Falha ao remover backups antigos."
  else
    log "Backups antigos removidos com sucesso."
  fi
fi

# Exibir informações do backup
BACKUP_SIZE=$(du -h "$BACKUP_PATH" | cut -f1)
log "Backup concluído com sucesso!"
log "Detalhes do backup:"
log "  - Banco de dados: $DB_NAME"
log "  - Arquivo: $(basename "$BACKUP_PATH")"
log "  - Tamanho: $BACKUP_SIZE"
log "  - Diretório: $BACKUP_DIR"
log "  - Compressão: $ENABLE_COMPRESSION"
log "  - Criptografia: $ENABLE_ENCRYPTION"

# Limpar variáveis de ambiente
unset PGPASSWORD

exit 0 