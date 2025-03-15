# Scripts de Automação para o Sistema de Rastreabilidade

Este diretório contém scripts para automatizar tarefas relacionadas ao Sistema de Rastreabilidade, incluindo configuração de ambiente, backup e restauração de banco de dados, deploy da aplicação e monitoramento do sistema.

## Visão Geral dos Scripts

| Script | Descrição |
|--------|-----------|
| `setup_almalinux.sh` | Configura o ambiente de produção no AlmaLinux |
| `setup_dev_environment.sh` | Configura o ambiente de desenvolvimento em diferentes sistemas operacionais |
| `backup_database.sh` | Realiza backup do banco de dados PostgreSQL |
| `restore_database.sh` | Restaura o banco de dados a partir de um backup |
| `deploy.sh` | Automatiza o processo de deploy da aplicação |
| `monitor_system.sh` | Monitora o sistema e envia alertas sobre problemas |
| `setup_crontab.sh` | Configura tarefas agendadas para backup e monitoramento |
| `make_executable.sh` | Torna todos os scripts executáveis |

## Requisitos

- Bash (versão 4.0 ou superior)
- Git
- Node.js (versão 18.x ou superior)
- npm
- PostgreSQL (versão 14.x ou superior)

## Primeiros Passos

Antes de usar qualquer script, torne-os executáveis:

```bash
# Opção 1: Manualmente
chmod +x *.sh

# Opção 2: Usando o script auxiliar
bash make_executable.sh
```

## Como Usar

### Configuração do Ambiente de Produção (AlmaLinux)

```bash
sudo ./setup_almalinux.sh
```

Este script configura um servidor AlmaLinux para executar o Sistema de Rastreabilidade, incluindo:
- Instalação de dependências
- Configuração do firewall
- Instalação e configuração do PostgreSQL
- Configuração do Nginx (opcional)
- Criação de serviço systemd (opcional)

### Configuração do Ambiente de Desenvolvimento

```bash
./setup_dev_environment.sh
```

Este script configura o ambiente de desenvolvimento em diferentes sistemas operacionais (Linux, macOS, Windows), incluindo:
- Instalação de Node.js
- Instalação e configuração do PostgreSQL
- Configuração de variáveis de ambiente
- Instalação de dependências do projeto
- Execução de migrações e seeds

### Backup do Banco de Dados

```bash
./backup_database.sh [opções]
```

Opções comuns:
- `-d, --database NOME`: Nome do banco de dados
- `-o, --output-dir DIR`: Diretório de saída para os backups
- `-r, --retention DIAS`: Número de dias para reter backups
- `-e, --encrypt`: Habilitar criptografia
- `--encrypt-password SENHA`: Senha para criptografia

Exemplo:
```bash
./backup_database.sh --database rastreabilidade --output-dir /backups --retention 30
```

### Restauração do Banco de Dados

```bash
./restore_database.sh [opções]
```

Opções comuns:
- `-d, --database NOME`: Nome do banco de dados
- `-f, --file ARQUIVO`: Arquivo de backup específico para restaurar
- `--latest`: Restaurar o backup mais recente
- `--decrypt-password SENHA`: Senha para descriptografia (se necessário)

Exemplo:
```bash
./restore_database.sh --database rastreabilidade --latest
```

### Deploy da Aplicação

```bash
./deploy.sh [opções]
```

Opções comuns:
- `-r, --repo URL`: URL do repositório Git
- `-b, --branch BRANCH`: Branch do Git para deploy
- `-e, --env ENV`: Ambiente (development, staging, production)
- `--skip-backup`: Não realizar backup antes do deploy
- `--skip-migrations`: Não executar migrações do banco de dados

Exemplo:
```bash
./deploy.sh --repo https://github.com/usuario/rastreabilidade.git --branch main --env production
```

### Monitoramento do Sistema

```bash
./monitor_system.sh [opções]
```

Opções comuns:
- `-e, --email EMAIL`: Email para alertas
- `--disk-threshold PERCENT`: Limite de uso de disco para alertas
- `--cpu-threshold PERCENT`: Limite de uso de CPU para alertas
- `--mem-threshold PERCENT`: Limite de uso de memória para alertas
- `--no-services`: Não verificar serviços
- `--no-database`: Não verificar banco de dados
- `-v, --verbose`: Modo verboso
- `--send-email`: Enviar alertas por email

Exemplo:
```bash
./monitor_system.sh --email admin@example.com --disk-threshold 85 --send-email
```

### Configuração de Tarefas Agendadas

```bash
./setup_crontab.sh [opções]
```

Opções comuns:
- `-e, --email EMAIL`: Email para alertas
- `--backup-schedule CRON`: Agendamento para backup (formato crontab)
- `--monitor-schedule CRON`: Agendamento para monitoramento (formato crontab)
- `--backup-retention DAYS`: Dias para reter backups
- `--no-backup`: Não configurar backup automático
- `--no-monitor`: Não configurar monitoramento automático
- `--no-cleanup`: Não configurar limpeza automática de logs

Exemplo:
```bash
./setup_crontab.sh --email admin@example.com --backup-schedule "0 3 * * *" --backup-retention 14
```

Este script configura automaticamente o crontab para executar:
- Backup diário do banco de dados
- Monitoramento periódico do sistema
- Limpeza semanal de logs antigos

## Personalização

Todos os scripts possuem opções de linha de comando que permitem personalizar seu comportamento. Use a opção `-h` ou `--help` para ver todas as opções disponíveis:

```bash
./script_name.sh --help
```

## Segurança

- Os scripts de backup suportam criptografia de arquivos usando AES-256-CBC.
- Senhas e credenciais sensíveis devem ser armazenadas com segurança e não hardcoded nos scripts.
- Recomenda-se revisar e ajustar as permissões dos scripts antes de usá-los em produção.

## Solução de Problemas

Se encontrar problemas ao executar os scripts:

1. Verifique se todos os requisitos estão instalados
2. Verifique as permissões dos scripts (`chmod +x script.sh`)
3. Verifique os logs de erro
4. Execute o script com a opção `--help` para ver todas as opções disponíveis

## Contribuição

Para contribuir com melhorias nos scripts:

1. Faça um fork do repositório
2. Crie uma branch para sua feature (`git checkout -b feature/nova-feature`)
3. Faça commit das suas alterações (`git commit -am 'Adiciona nova feature'`)
4. Faça push para a branch (`git push origin feature/nova-feature`)
5. Crie um novo Pull Request 