#!/bin/bash

# Script para restaurar o banco de dados a partir de um backup
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
BACKUP_FILE=""
ENCRYPTION_PASSWORD=""
FORCE_RESTORE=false

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
  echo "  -i, --input-dir DIR       Diretório de entrada para os backups (padrão: $BACKUP_DIR)"
  echo "  -f, --file ARQUIVO        Arquivo de backup específico para restaurar"
  echo "  --latest                  Restaurar o backup mais recente (padrão se nenhum arquivo for especificado)"
  echo "  --decrypt-password SENHA  Senha para descriptografia (necessário para backups criptografados)"
  echo "  --force                   Forçar restauração sem confirmação (use com cuidado!)"
  echo ""
  echo "Exemplo:"
  echo "  $0 --database meudb --user meuusuario --password minhasenha --file backup_20240101_120000.sql.gz"
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
    -i|--input-dir)
      BACKUP_DIR="$2"
      shift 2
      ;;
    -f|--file)
      BACKUP_FILE="$2"
      shift 2
      ;;
    --latest)
      BACKUP_FILE="latest"
      shift
      ;;
    --decrypt-password)
      ENCRYPTION_PASSWORD="$2"
      shift 2
      ;;
    --force)
      FORCE_RESTORE=true
      shift
      ;;
    *)
      error "Opção desconhecida: $1"
      show_help
      ;;
  esac
done

# Verificar se o diretório de backup existe
if [ ! -d "$BACKUP_DIR" ]; then
  error "Diretório de backup não encontrado: $BACKUP_DIR"
  exit 1
fi

# Verificar se o psql está disponível
if ! command -v psql &> /dev/null; then
  error "psql não encontrado. Por favor, instale o cliente PostgreSQL."
  exit 1
fi

# Encontrar o arquivo de backup mais recente se não for especificado
if [ -z "$BACKUP_FILE" ] || [ "$BACKUP_FILE" = "latest" ]; then
  log "Procurando o backup mais recente..."
  
  # Procurar por arquivos de backup (não criptografados, comprimidos e criptografados)
  LATEST_BACKUP=$(find "$BACKUP_DIR" -type f -name "${DB_NAME}_*.sql*" | sort -r | head -n 1)
  
  if [ -z "$LATEST_BACKUP" ]; then
    error "Nenhum arquivo de backup encontrado em $BACKUP_DIR"
    exit 1
  fi
  
  BACKUP_FILE=$(basename "$LATEST_BACKUP")
  log "Backup mais recente encontrado: $BACKUP_FILE"
fi

# Caminho completo para o arquivo de backup
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_FILE}"

# Verificar se o arquivo de backup existe
if [ ! -f "$BACKUP_PATH" ]; then
  error "Arquivo de backup não encontrado: $BACKUP_PATH"
  exit 1
fi

# Determinar o tipo de arquivo de backup
IS_ENCRYPTED=false
IS_COMPRESSED=false

if [[ "$BACKUP_PATH" == *.enc ]]; then
  IS_ENCRYPTED=true
  if [ -z "$ENCRYPTION_PASSWORD" ]; then
    error "O backup está criptografado, mas nenhuma senha foi fornecida. Use --decrypt-password."
    exit 1
  fi
fi

if [[ "$BACKUP_PATH" == *.gz ]]; then
  IS_COMPRESSED=true
fi

if [[ "$BACKUP_PATH" == *.gz.enc ]] || [[ "$BACKUP_PATH" == *.sql.enc ]]; then
  IS_ENCRYPTED=true
  if [ -z "$ENCRYPTION_PASSWORD" ]; then
    error "O backup está criptografado, mas nenhuma senha foi fornecida. Use --decrypt-password."
    exit 1
  fi
fi

# Verificar se o openssl está disponível para descriptografia
if [ "$IS_ENCRYPTED" = true ] && ! command -v openssl &> /dev/null; then
  error "openssl não encontrado. Por favor, instale o openssl para descriptografar o backup."
  exit 1
fi

# Confirmar a restauração
if [ "$FORCE_RESTORE" != true ]; then
  echo -e "${YELLOW}ATENÇÃO:${NC} Você está prestes a restaurar o banco de dados '$DB_NAME'."
  echo "Todos os dados existentes serão substituídos pelo conteúdo do backup."
  echo -e "${YELLOW}Esta operação não pode ser desfeita.${NC}"
  echo ""
  echo -n "Deseja continuar? (s/N): "
  read -r CONFIRM
  
  if [[ ! "$CONFIRM" =~ ^[Ss]$ ]]; then
    log "Operação cancelada pelo usuário."
    exit 0
  fi
fi

# Criar diretório temporário
TEMP_DIR=$(mktemp -d)
TEMP_FILE="${TEMP_DIR}/backup.sql"

log "Preparando arquivo de backup para restauração..."

# Processar o arquivo de backup (descriptografar e/ou descomprimir)
if [ "$IS_ENCRYPTED" = true ]; then
  log "Descriptografando o backup..."
  
  # Determinar o nome do arquivo após descriptografia
  if [[ "$BACKUP_PATH" == *.gz.enc ]]; then
    DECRYPTED_FILE="${TEMP_DIR}/backup.sql.gz"
  else
    DECRYPTED_FILE="${TEMP_DIR}/backup.sql"
  fi
  
  # Descriptografar o arquivo
  openssl enc -aes-256-cbc -d -in "$BACKUP_PATH" -out "$DECRYPTED_FILE" -pass pass:"$ENCRYPTION_PASSWORD"
  
  if [ $? -ne 0 ]; then
    error "Falha ao descriptografar o backup. Verifique se a senha está correta."
    rm -rf "$TEMP_DIR"
    exit 1
  fi
  
  # Atualizar o caminho do arquivo para o arquivo descriptografado
  BACKUP_PATH="$DECRYPTED_FILE"
  
  # Atualizar o status de compressão
  if [[ "$BACKUP_PATH" == *.gz ]]; then
    IS_COMPRESSED=true
  else
    IS_COMPRESSED=false
  fi
fi

# Descomprimir o arquivo se necessário
if [ "$IS_COMPRESSED" = true ]; then
  log "Descomprimindo o backup..."
  gunzip -c "$BACKUP_PATH" > "$TEMP_FILE"
  
  if [ $? -ne 0 ]; then
    error "Falha ao descomprimir o backup."
    rm -rf "$TEMP_DIR"
    exit 1
  fi
else
  # Se não estiver comprimido, apenas copiar o arquivo
  cp "$BACKUP_PATH" "$TEMP_FILE"
fi

# Configurar variáveis de ambiente para o psql
export PGPASSWORD="$DB_PASSWORD"

# Verificar se o banco de dados existe
DB_EXISTS=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -lqt | cut -d \| -f 1 | grep -w "$DB_NAME" | wc -l)

if [ "$DB_EXISTS" -eq 0 ]; then
  log "Criando banco de dados $DB_NAME..."
  createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME"
  
  if [ $? -ne 0 ]; then
    error "Falha ao criar o banco de dados."
    rm -rf "$TEMP_DIR"
    exit 1
  fi
else
  log "Banco de dados $DB_NAME já existe. Limpando..."
  
  # Desconectar todos os usuários e dropar o banco de dados
  psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "
    SELECT pg_terminate_backend(pg_stat_activity.pid)
    FROM pg_stat_activity
    WHERE pg_stat_activity.datname = '$DB_NAME'
    AND pid <> pg_backend_pid();"
  
  # Dropar e recriar o banco de dados
  dropdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME"
  createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME"
  
  if [ $? -ne 0 ]; then
    error "Falha ao recriar o banco de dados."
    rm -rf "$TEMP_DIR"
    exit 1
  fi
fi

# Restaurar o banco de dados
log "Restaurando o banco de dados a partir do backup..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$TEMP_FILE"

# Verificar se a restauração foi bem-sucedida
if [ $? -ne 0 ]; then
  error "Falha ao restaurar o banco de dados."
  rm -rf "$TEMP_DIR"
  exit 1
fi

# Limpar arquivos temporários
rm -rf "$TEMP_DIR"

# Limpar variáveis de ambiente
unset PGPASSWORD

log "Restauração concluída com sucesso!"
log "Detalhes da restauração:"
log "  - Banco de dados: $DB_NAME"
log "  - Arquivo de backup: $BACKUP_FILE"
log "  - Host: $DB_HOST:$DB_PORT"

exit 0 