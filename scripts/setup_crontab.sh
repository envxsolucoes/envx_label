#!/bin/bash

# Script para configurar o crontab automaticamente
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
SCRIPTS_DIR="$(dirname "$(readlink -f "$0")")"
APP_DIR="/opt/rastreabilidade"
BACKUP_SCHEDULE="0 2 * * *"  # 2 AM todos os dias
MONITOR_SCHEDULE="0 * * * *" # A cada hora
ALERT_EMAIL=""
BACKUP_RETENTION=7
DISK_THRESHOLD=90
CPU_THRESHOLD=80
MEM_THRESHOLD=80
SETUP_BACKUP=true
SETUP_MONITOR=true
SETUP_CLEANUP=true

# Função para exibir ajuda
show_help() {
  echo "Uso: $0 [opções]"
  echo ""
  echo "Opções:"
  echo "  -h, --help                Exibe esta mensagem de ajuda"
  echo "  -d, --app-dir DIR         Diretório da aplicação (padrão: $APP_DIR)"
  echo "  -e, --email EMAIL         Email para alertas"
  echo "  --backup-schedule CRON    Agendamento para backup (padrão: '$BACKUP_SCHEDULE')"
  echo "  --monitor-schedule CRON   Agendamento para monitoramento (padrão: '$MONITOR_SCHEDULE')"
  echo "  --backup-retention DAYS   Dias para reter backups (padrão: $BACKUP_RETENTION)"
  echo "  --disk-threshold PERCENT  Limite de uso de disco para alertas (padrão: $DISK_THRESHOLD%)"
  echo "  --cpu-threshold PERCENT   Limite de uso de CPU para alertas (padrão: $CPU_THRESHOLD%)"
  echo "  --mem-threshold PERCENT   Limite de uso de memória para alertas (padrão: $MEM_THRESHOLD%)"
  echo "  --no-backup               Não configurar backup automático"
  echo "  --no-monitor              Não configurar monitoramento automático"
  echo "  --no-cleanup              Não configurar limpeza automática de logs"
  echo ""
  echo "Exemplo:"
  echo "  $0 --email admin@example.com --backup-schedule \"0 3 * * *\" --backup-retention 14"
  exit 0
}

# Processar argumentos da linha de comando
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      ;;
    -d|--app-dir)
      APP_DIR="$2"
      shift 2
      ;;
    -e|--email)
      ALERT_EMAIL="$2"
      shift 2
      ;;
    --backup-schedule)
      BACKUP_SCHEDULE="$2"
      shift 2
      ;;
    --monitor-schedule)
      MONITOR_SCHEDULE="$2"
      shift 2
      ;;
    --backup-retention)
      BACKUP_RETENTION="$2"
      shift 2
      ;;
    --disk-threshold)
      DISK_THRESHOLD="$2"
      shift 2
      ;;
    --cpu-threshold)
      CPU_THRESHOLD="$2"
      shift 2
      ;;
    --mem-threshold)
      MEM_THRESHOLD="$2"
      shift 2
      ;;
    --no-backup)
      SETUP_BACKUP=false
      shift
      ;;
    --no-monitor)
      SETUP_MONITOR=false
      shift
      ;;
    --no-cleanup)
      SETUP_CLEANUP=false
      shift
      ;;
    *)
      error "Opção desconhecida: $1"
      show_help
      ;;
  esac
done

# Verificar se o crontab está disponível
if ! command -v crontab &> /dev/null; then
  error "crontab não encontrado. Por favor, instale o cron."
  exit 1
fi

# Verificar se os scripts necessários existem
if [ "$SETUP_BACKUP" = true ] && [ ! -f "${SCRIPTS_DIR}/backup_database.sh" ]; then
  error "Script de backup não encontrado: ${SCRIPTS_DIR}/backup_database.sh"
  exit 1
fi

if [ "$SETUP_MONITOR" = true ] && [ ! -f "${SCRIPTS_DIR}/monitor_system.sh" ]; then
  error "Script de monitoramento não encontrado: ${SCRIPTS_DIR}/monitor_system.sh"
  exit 1
fi

# Criar arquivo temporário para o crontab
TEMP_CRONTAB=$(mktemp)

# Obter crontab atual
crontab -l > "$TEMP_CRONTAB" 2>/dev/null || echo "# Crontab para o Sistema de Rastreabilidade" > "$TEMP_CRONTAB"

# Adicionar comentário de cabeçalho se não existir
if ! grep -q "# Crontab para o Sistema de Rastreabilidade" "$TEMP_CRONTAB"; then
  echo "" >> "$TEMP_CRONTAB"
  echo "# Crontab para o Sistema de Rastreabilidade" >> "$TEMP_CRONTAB"
  echo "# Configurado automaticamente em $(date +'%Y-%m-%d %H:%M:%S')" >> "$TEMP_CRONTAB"
  echo "" >> "$TEMP_CRONTAB"
fi

# Configurar backup automático
if [ "$SETUP_BACKUP" = true ]; then
  log "Configurando backup automático do banco de dados..."
  
  # Remover entradas existentes de backup
  sed -i '/backup_database\.sh/d' "$TEMP_CRONTAB"
  
  # Adicionar nova entrada de backup
  echo "# Backup automático do banco de dados" >> "$TEMP_CRONTAB"
  echo "$BACKUP_SCHEDULE ${SCRIPTS_DIR}/backup_database.sh --retention $BACKUP_RETENTION --output-dir ${APP_DIR}/backups" >> "$TEMP_CRONTAB"
  echo "" >> "$TEMP_CRONTAB"
  
  log "Backup automático configurado para executar: $BACKUP_SCHEDULE"
fi

# Configurar monitoramento automático
if [ "$SETUP_MONITOR" = true ]; then
  log "Configurando monitoramento automático do sistema..."
  
  # Remover entradas existentes de monitoramento
  sed -i '/monitor_system\.sh/d' "$TEMP_CRONTAB"
  
  # Adicionar nova entrada de monitoramento
  echo "# Monitoramento automático do sistema" >> "$TEMP_CRONTAB"
  
  MONITOR_CMD="${SCRIPTS_DIR}/monitor_system.sh --disk-threshold $DISK_THRESHOLD --cpu-threshold $CPU_THRESHOLD --mem-threshold $MEM_THRESHOLD"
  
  # Adicionar email para alertas se fornecido
  if [ -n "$ALERT_EMAIL" ]; then
    MONITOR_CMD="$MONITOR_CMD --email $ALERT_EMAIL --send-email"
  fi
  
  echo "$MONITOR_SCHEDULE $MONITOR_CMD" >> "$TEMP_CRONTAB"
  echo "" >> "$TEMP_CRONTAB"
  
  log "Monitoramento automático configurado para executar: $MONITOR_SCHEDULE"
fi

# Configurar limpeza automática de logs
if [ "$SETUP_CLEANUP" = true ]; then
  log "Configurando limpeza automática de logs..."
  
  # Remover entradas existentes de limpeza
  sed -i '/find.*-delete/d' "$TEMP_CRONTAB"
  
  # Adicionar nova entrada de limpeza
  echo "# Limpeza automática de logs antigos" >> "$TEMP_CRONTAB"
  echo "0 3 * * 0 find /var/log/rastreabilidade -name \"*.log\" -type f -mtime +30 -delete" >> "$TEMP_CRONTAB"
  echo "" >> "$TEMP_CRONTAB"
  
  log "Limpeza automática de logs configurada para executar semanalmente"
fi

# Instalar o novo crontab
crontab "$TEMP_CRONTAB"

if [ $? -ne 0 ]; then
  error "Falha ao instalar o crontab."
  exit 1
fi

# Limpar arquivo temporário
rm "$TEMP_CRONTAB"

log "Crontab configurado com sucesso!"

# Exibir o crontab atual
log "Crontab atual:"
crontab -l

# Verificar se o serviço cron está ativo
if command -v systemctl &> /dev/null; then
  if systemctl is-active --quiet cron || systemctl is-active --quiet crond; then
    log "Serviço cron está ativo."
  else
    warn "Serviço cron não está ativo. Iniciando..."
    systemctl start cron 2>/dev/null || systemctl start crond 2>/dev/null
    
    if [ $? -ne 0 ]; then
      error "Falha ao iniciar o serviço cron."
    else
      log "Serviço cron iniciado com sucesso."
    fi
  fi
fi

log "Configuração do crontab concluída!" 