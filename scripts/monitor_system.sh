#!/bin/bash

# Script para monitoramento do sistema
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

header() {
  echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Configurações padrão
APP_DIR="/opt/rastreabilidade"
LOG_DIR="/var/log/rastreabilidade"
ALERT_EMAIL=""
DISK_THRESHOLD=90
CPU_THRESHOLD=80
MEM_THRESHOLD=80
DB_NAME="rastreabilidade"
DB_USER="rastreabilidade"
DB_PASSWORD="rastreabilidade"
DB_HOST="localhost"
DB_PORT="5432"
CHECK_SERVICES=true
CHECK_LOGS=true
CHECK_RESOURCES=true
CHECK_DATABASE=true
VERBOSE=false
SEND_EMAIL=false

# Função para exibir ajuda
show_help() {
  echo "Uso: $0 [opções]"
  echo ""
  echo "Opções:"
  echo "  -h, --help                Exibe esta mensagem de ajuda"
  echo "  -d, --app-dir DIR         Diretório da aplicação (padrão: $APP_DIR)"
  echo "  -l, --log-dir DIR         Diretório de logs (padrão: $LOG_DIR)"
  echo "  -e, --email EMAIL         Email para alertas"
  echo "  --disk-threshold PERCENT  Limite de uso de disco para alertas (padrão: $DISK_THRESHOLD%)"
  echo "  --cpu-threshold PERCENT   Limite de uso de CPU para alertas (padrão: $CPU_THRESHOLD%)"
  echo "  --mem-threshold PERCENT   Limite de uso de memória para alertas (padrão: $MEM_THRESHOLD%)"
  echo "  --db-name NAME            Nome do banco de dados (padrão: $DB_NAME)"
  echo "  --db-user USER            Usuário do banco de dados (padrão: $DB_USER)"
  echo "  --db-password PASSWORD    Senha do banco de dados"
  echo "  --db-host HOST            Host do banco de dados (padrão: $DB_HOST)"
  echo "  --db-port PORT            Porta do banco de dados (padrão: $DB_PORT)"
  echo "  --no-services             Não verificar serviços"
  echo "  --no-logs                 Não verificar logs"
  echo "  --no-resources            Não verificar recursos do sistema"
  echo "  --no-database             Não verificar banco de dados"
  echo "  -v, --verbose             Modo verboso"
  echo "  --send-email              Enviar alertas por email"
  echo ""
  echo "Exemplo:"
  echo "  $0 --email admin@example.com --disk-threshold 85 --send-email"
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
    -l|--log-dir)
      LOG_DIR="$2"
      shift 2
      ;;
    -e|--email)
      ALERT_EMAIL="$2"
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
    --db-name)
      DB_NAME="$2"
      shift 2
      ;;
    --db-user)
      DB_USER="$2"
      shift 2
      ;;
    --db-password)
      DB_PASSWORD="$2"
      shift 2
      ;;
    --db-host)
      DB_HOST="$2"
      shift 2
      ;;
    --db-port)
      DB_PORT="$2"
      shift 2
      ;;
    --no-services)
      CHECK_SERVICES=false
      shift
      ;;
    --no-logs)
      CHECK_LOGS=false
      shift
      ;;
    --no-resources)
      CHECK_RESOURCES=false
      shift
      ;;
    --no-database)
      CHECK_DATABASE=false
      shift
      ;;
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    --send-email)
      SEND_EMAIL=true
      shift
      ;;
    *)
      error "Opção desconhecida: $1"
      show_help
      ;;
  esac
done

# Verificar se o email foi fornecido quando --send-email está ativado
if [ "$SEND_EMAIL" = true ] && [ -z "$ALERT_EMAIL" ]; then
  error "A opção --send-email requer um email para alertas. Use --email EMAIL."
  exit 1
fi

# Criar diretório de logs se não existir
if [ ! -d "$LOG_DIR" ]; then
  log "Criando diretório de logs: $LOG_DIR"
  mkdir -p "$LOG_DIR"
  
  if [ $? -ne 0 ]; then
    error "Não foi possível criar o diretório de logs: $LOG_DIR"
    exit 1
  fi
fi

# Arquivo de log para este monitoramento
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
MONITOR_LOG="${LOG_DIR}/monitor_${TIMESTAMP}.log"
ALERT_LOG="${LOG_DIR}/alerts_${TIMESTAMP}.log"

# Função para registrar mensagens no log
log_message() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$MONITOR_LOG"
  
  if [ "$VERBOSE" = true ]; then
    echo "$1"
  fi
}

# Função para registrar alertas
log_alert() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - ALERTA: $1" >> "$ALERT_LOG"
  echo "$(date +'%Y-%m-%d %H:%M:%S') - ALERTA: $1" >> "$MONITOR_LOG"
  
  warn "$1"
}

# Função para enviar email de alerta
send_alert_email() {
  if [ "$SEND_EMAIL" = true ] && [ -n "$ALERT_EMAIL" ]; then
    log_message "Enviando email de alerta para $ALERT_EMAIL"
    
    HOSTNAME=$(hostname)
    SUBJECT="[ALERTA] Monitoramento do Sistema - $HOSTNAME - $(date +'%Y-%m-%d %H:%M:%S')"
    
    if [ -f "$ALERT_LOG" ]; then
      mail -s "$SUBJECT" "$ALERT_EMAIL" < "$ALERT_LOG"
      
      if [ $? -ne 0 ]; then
        error "Falha ao enviar email de alerta."
      else
        log_message "Email de alerta enviado com sucesso."
      fi
    else
      log_message "Nenhum alerta para enviar por email."
    fi
  fi
}

# Função para verificar serviços
check_services() {
  if [ "$CHECK_SERVICES" = true ]; then
    header "Verificação de Serviços"
    log_message "Verificando status dos serviços..."
    
    # Verificar serviço da aplicação
    if systemctl is-active --quiet rastreabilidade.service; then
      log_message "Serviço rastreabilidade está ativo"
    else
      log_alert "Serviço rastreabilidade não está ativo"
    fi
    
    # Verificar PostgreSQL
    if systemctl is-active --quiet postgresql; then
      log_message "Serviço PostgreSQL está ativo"
    else
      log_alert "Serviço PostgreSQL não está ativo"
    fi
    
    # Verificar Nginx (se instalado)
    if command -v nginx &> /dev/null; then
      if systemctl is-active --quiet nginx; then
        log_message "Serviço Nginx está ativo"
      else
        log_alert "Serviço Nginx não está ativo"
      fi
    fi
    
    # Verificar portas
    log_message "Verificando portas abertas..."
    
    # Verificar porta do backend (3001)
    if netstat -tuln | grep -q ":3001 "; then
      log_message "Porta 3001 (backend) está aberta"
    else
      log_alert "Porta 3001 (backend) não está aberta"
    fi
    
    # Verificar porta do PostgreSQL (5432)
    if netstat -tuln | grep -q ":5432 "; then
      log_message "Porta 5432 (PostgreSQL) está aberta"
    else
      log_alert "Porta 5432 (PostgreSQL) não está aberta"
    fi
    
    # Verificar porta HTTP (80)
    if netstat -tuln | grep -q ":80 "; then
      log_message "Porta 80 (HTTP) está aberta"
    else
      log_alert "Porta 80 (HTTP) não está aberta"
    fi
  fi
}

# Função para verificar logs
check_logs() {
  if [ "$CHECK_LOGS" = true ]; then
    header "Verificação de Logs"
    log_message "Verificando logs da aplicação..."
    
    # Verificar logs de erro no backend
    BACKEND_LOG="${APP_DIR}/backend/logs/error.log"
    if [ -f "$BACKEND_LOG" ]; then
      ERROR_COUNT=$(grep -c "ERROR" "$BACKEND_LOG" 2>/dev/null || echo "0")
      RECENT_ERRORS=$(grep "ERROR" "$BACKEND_LOG" 2>/dev/null | tail -n 5)
      
      log_message "Encontrados $ERROR_COUNT erros no log do backend"
      
      if [ "$ERROR_COUNT" -gt 0 ]; then
        log_alert "Erros recentes no backend:"
        echo "$RECENT_ERRORS" >> "$ALERT_LOG"
        
        if [ "$VERBOSE" = true ]; then
          echo "Erros recentes no backend:"
          echo "$RECENT_ERRORS"
        fi
      fi
    else
      log_message "Arquivo de log do backend não encontrado: $BACKEND_LOG"
    fi
    
    # Verificar logs do sistema
    if [ -f "/var/log/syslog" ]; then
      SYSLOG_ERRORS=$(grep "rastreabilidade.*error" /var/log/syslog 2>/dev/null | tail -n 5)
      
      if [ -n "$SYSLOG_ERRORS" ]; then
        log_alert "Erros relacionados à aplicação encontrados no syslog:"
        echo "$SYSLOG_ERRORS" >> "$ALERT_LOG"
        
        if [ "$VERBOSE" = true ]; then
          echo "Erros no syslog:"
          echo "$SYSLOG_ERRORS"
        fi
      else
        log_message "Nenhum erro relacionado à aplicação encontrado no syslog"
      fi
    fi
    
    # Verificar logs do Nginx (se existirem)
    NGINX_ERROR_LOG="/var/log/nginx/error.log"
    if [ -f "$NGINX_ERROR_LOG" ]; then
      NGINX_ERRORS=$(grep "error" "$NGINX_ERROR_LOG" 2>/dev/null | tail -n 5)
      
      if [ -n "$NGINX_ERRORS" ]; then
        log_alert "Erros encontrados no log do Nginx:"
        echo "$NGINX_ERRORS" >> "$ALERT_LOG"
        
        if [ "$VERBOSE" = true ]; then
          echo "Erros no Nginx:"
          echo "$NGINX_ERRORS"
        fi
      else
        log_message "Nenhum erro encontrado no log do Nginx"
      fi
    fi
  fi
}

# Função para verificar recursos do sistema
check_resources() {
  if [ "$CHECK_RESOURCES" = true ]; then
    header "Verificação de Recursos do Sistema"
    log_message "Verificando recursos do sistema..."
    
    # Verificar uso de disco
    log_message "Verificando uso de disco..."
    DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    log_message "Uso de disco: $DISK_USAGE%"
    
    if [ "$DISK_USAGE" -ge "$DISK_THRESHOLD" ]; then
      log_alert "Uso de disco acima do limite: $DISK_USAGE% (limite: $DISK_THRESHOLD%)"
    fi
    
    # Verificar uso de CPU
    log_message "Verificando uso de CPU..."
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    CPU_USAGE_INT=${CPU_USAGE%.*}
    
    log_message "Uso de CPU: $CPU_USAGE_INT%"
    
    if [ "$CPU_USAGE_INT" -ge "$CPU_THRESHOLD" ]; then
      log_alert "Uso de CPU acima do limite: $CPU_USAGE_INT% (limite: $CPU_THRESHOLD%)"
    fi
    
    # Verificar uso de memória
    log_message "Verificando uso de memória..."
    MEM_USAGE=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
    MEM_USAGE_INT=${MEM_USAGE%.*}
    
    log_message "Uso de memória: $MEM_USAGE_INT%"
    
    if [ "$MEM_USAGE_INT" -ge "$MEM_THRESHOLD" ]; then
      log_alert "Uso de memória acima do limite: $MEM_USAGE_INT% (limite: $MEM_THRESHOLD%)"
    fi
    
    # Verificar processos da aplicação
    log_message "Verificando processos da aplicação..."
    NODE_PROCESSES=$(ps aux | grep node | grep -v grep | wc -l)
    
    log_message "Processos Node.js em execução: $NODE_PROCESSES"
    
    if [ "$NODE_PROCESSES" -eq 0 ]; then
      log_alert "Nenhum processo Node.js em execução"
    fi
    
    # Verificar carga do sistema
    log_message "Verificando carga do sistema..."
    LOAD_AVG=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
    
    log_message "Carga média do sistema (1, 5, 15 min): $LOAD_AVG"
  fi
}

# Função para verificar banco de dados
check_database() {
  if [ "$CHECK_DATABASE" = true ]; then
    header "Verificação do Banco de Dados"
    log_message "Verificando banco de dados PostgreSQL..."
    
    # Verificar se o psql está disponível
    if ! command -v psql &> /dev/null; then
      log_alert "psql não encontrado. Não é possível verificar o banco de dados."
      return
    fi
    
    # Configurar variáveis de ambiente para o psql
    export PGPASSWORD="$DB_PASSWORD"
    
    # Verificar conexão com o banco de dados
    log_message "Verificando conexão com o banco de dados..."
    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1" &> /dev/null; then
      log_message "Conexão com o banco de dados estabelecida com sucesso"
    else
      log_alert "Não foi possível conectar ao banco de dados"
      unset PGPASSWORD
      return
    fi
    
    # Verificar tamanho do banco de dados
    log_message "Verificando tamanho do banco de dados..."
    DB_SIZE=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT pg_size_pretty(pg_database_size('$DB_NAME'))")
    
    log_message "Tamanho do banco de dados: $DB_SIZE"
    
    # Verificar número de conexões ativas
    log_message "Verificando conexões ativas..."
    ACTIVE_CONNECTIONS=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT count(*) FROM pg_stat_activity WHERE datname = '$DB_NAME'")
    
    log_message "Conexões ativas: $ACTIVE_CONNECTIONS"
    
    # Verificar tabelas mais grandes
    log_message "Verificando tabelas mais grandes..."
    LARGEST_TABLES=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
      SELECT table_name, pg_size_pretty(pg_total_relation_size(quote_ident(table_name)))
      FROM information_schema.tables
      WHERE table_schema = 'public'
      ORDER BY pg_total_relation_size(quote_ident(table_name)) DESC
      LIMIT 5;
    ")
    
    log_message "Tabelas mais grandes:"
    echo "$LARGEST_TABLES" >> "$MONITOR_LOG"
    
    if [ "$VERBOSE" = true ]; then
      echo "Tabelas mais grandes:"
      echo "$LARGEST_TABLES"
    fi
    
    # Verificar transações longas
    log_message "Verificando transações longas..."
    LONG_TRANSACTIONS=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
      SELECT pid, now() - xact_start AS duration, query
      FROM pg_stat_activity
      WHERE state = 'active' AND now() - xact_start > '30 seconds'::interval
      ORDER BY duration DESC;
    ")
    
    if [ -n "$LONG_TRANSACTIONS" ]; then
      log_alert "Transações longas detectadas:"
      echo "$LONG_TRANSACTIONS" >> "$ALERT_LOG"
      
      if [ "$VERBOSE" = true ]; then
        echo "Transações longas:"
        echo "$LONG_TRANSACTIONS"
      fi
    else
      log_message "Nenhuma transação longa detectada"
    fi
    
    # Limpar variáveis de ambiente
    unset PGPASSWORD
  fi
}

# Função para gerar relatório
generate_report() {
  header "Relatório de Monitoramento"
  log_message "Gerando relatório de monitoramento..."
  
  # Contar alertas
  ALERT_COUNT=0
  if [ -f "$ALERT_LOG" ]; then
    ALERT_COUNT=$(grep -c "ALERTA" "$ALERT_LOG")
  fi
  
  log_message "Total de alertas: $ALERT_COUNT"
  
  # Resumo do sistema
  HOSTNAME=$(hostname)
  KERNEL=$(uname -r)
  UPTIME=$(uptime -p)
  
  log_message "Resumo do sistema:"
  log_message "  - Hostname: $HOSTNAME"
  log_message "  - Kernel: $KERNEL"
  log_message "  - Uptime: $UPTIME"
  
  # Exibir resumo
  if [ "$VERBOSE" = true ]; then
    echo ""
    echo "=== Resumo do Monitoramento ==="
    echo "Hostname: $HOSTNAME"
    echo "Data e hora: $(date +'%Y-%m-%d %H:%M:%S')"
    echo "Total de alertas: $ALERT_COUNT"
    
    if [ "$ALERT_COUNT" -gt 0 ] && [ -f "$ALERT_LOG" ]; then
      echo ""
      echo "=== Alertas Detectados ==="
      cat "$ALERT_LOG"
    fi
    
    echo ""
    echo "Log completo: $MONITOR_LOG"
  fi
  
  # Enviar email de alerta se houver alertas
  if [ "$ALERT_COUNT" -gt 0 ]; then
    send_alert_email
  fi
}

# Função principal
main() {
  log_message "=== Iniciando monitoramento do sistema ==="
  log_message "Data e hora: $(date +'%Y-%m-%d %H:%M:%S')"
  
  # Verificar serviços
  check_services
  
  # Verificar logs
  check_logs
  
  # Verificar recursos do sistema
  check_resources
  
  # Verificar banco de dados
  check_database
  
  # Gerar relatório
  generate_report
  
  log_message "=== Monitoramento concluído ==="
}

# Executar o script
main 