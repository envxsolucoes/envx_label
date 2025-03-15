# Instruções para Configuração do Sistema de Rastreabilidade ENVX no AlmaLinux

Este documento fornece instruções detalhadas para configurar o Sistema de Rastreabilidade ENVX no AlmaLinux.

## Pré-requisitos

- Servidor AlmaLinux 8 ou 9
- Acesso root ou sudo
- Conexão à internet

## 1. Clonar o Repositório

```bash
# Instalar o Git
sudo dnf install -y git

# Criar diretório para o projeto
sudo mkdir -p /opt/rastreabilidade
sudo chown -R $(whoami):$(whoami) /opt/rastreabilidade
cd /opt/rastreabilidade

# Clonar o repositório (será solicitado nome de usuário e senha/token)
git clone https://github.com/envxsolucoes/envx_label.git .
```

Para métodos de autenticação mais seguros, consulte o arquivo `scripts/conectar_github_almalinux.md`.

## 2. Atualizar o Sistema

```bash
# Atualizar o sistema
sudo dnf update -y
```

## 3. Instalar Dependências Básicas

```bash
# Instalar dependências básicas
sudo dnf install -y git curl wget nano unzip
```

## 4. Configurar o Git

```bash
# Configurar o Git
git config --global user.name "ENVX Admin"
git config --global user.email "admin@envx.com.br"
```

## 5. Instalar Node.js

```bash
# Instalar Node.js 18.x
sudo dnf module reset nodejs -y
sudo dnf module enable nodejs:18 -y
sudo dnf install -y nodejs

# Verificar a instalação
node --version
npm --version
```

## 6. Instalar Docker e Docker Compose

```bash
# Instalar Docker
sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io

# Iniciar e habilitar o Docker
sudo systemctl start docker
sudo systemctl enable docker

# Adicionar usuário ao grupo docker
sudo usermod -aG docker $(whoami)

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verificar a instalação
docker --version
docker-compose --version
```

## 7. Configurar Variáveis de Ambiente

```bash
# Copiar arquivos de exemplo
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env

# Editar as configurações conforme necessário
nano backend/.env
nano frontend/.env
```

## 8. Iniciar o Sistema com Docker Compose

```bash
# Navegar para o diretório do projeto
cd /opt/rastreabilidade

# Iniciar os serviços
docker-compose up -d

# Verificar os logs
docker-compose logs -f
```

## 9. Configurar o Nginx (Opcional para Produção)

```bash
# Instalar o Nginx
sudo dnf install -y nginx

# Iniciar e habilitar o Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Configurar o firewall
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

# Criar configuração do Nginx
sudo nano /etc/nginx/conf.d/rastreabilidade.conf
```

Adicione o seguinte conteúdo ao arquivo de configuração:

```nginx
server {
    listen 80;
    server_name rastreabilidade.envx.com.br;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    location /api {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

```bash
# Verificar a configuração do Nginx
sudo nginx -t

# Reiniciar o Nginx
sudo systemctl restart nginx
```

## 10. Configurar SSL com Certbot (Opcional para Produção)

```bash
# Instalar Certbot
sudo dnf install -y certbot python3-certbot-nginx

# Obter certificado SSL
sudo certbot --nginx -d rastreabilidade.envx.com.br

# Configurar renovação automática
sudo systemctl status certbot-renew.timer
```

## 11. Configurar Backup Automático

```bash
# Criar diretório para backups
sudo mkdir -p /opt/backups/rastreabilidade

# Definir permissões
sudo chown -R $(whoami):$(whoami) /opt/backups/rastreabilidade

# Criar script de backup
nano /opt/rastreabilidade/scripts/backup.sh
```

Adicione o seguinte conteúdo ao script de backup:

```bash
#!/bin/bash

# Definir variáveis
BACKUP_DIR="/opt/backups/rastreabilidade"
DATE=$(date +%Y%m%d_%H%M%S)
PROJECT_DIR="/opt/rastreabilidade"

# Criar backup do banco de dados
docker exec envx-mongodb mongodump --username envx --password envxpassword --authenticationDatabase admin --out /dump

# Copiar o dump para o diretório de backup
docker cp envx-mongodb:/dump $BACKUP_DIR/mongodb_$DATE

# Comprimir o backup
tar -czf $BACKUP_DIR/mongodb_$DATE.tar.gz -C $BACKUP_DIR mongodb_$DATE
rm -rf $BACKUP_DIR/mongodb_$DATE

# Backup dos arquivos de configuração
tar -czf $BACKUP_DIR/config_$DATE.tar.gz -C $PROJECT_DIR .env* docker-compose.yml

# Manter apenas os últimos 7 backups
find $BACKUP_DIR -name "mongodb_*.tar.gz" -type f -mtime +7 -delete
find $BACKUP_DIR -name "config_*.tar.gz" -type f -mtime +7 -delete

echo "Backup concluído em $DATE"
```

```bash
# Tornar o script executável
chmod +x /opt/rastreabilidade/scripts/backup.sh

# Configurar cron para executar o backup diariamente
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/rastreabilidade/scripts/backup.sh >> /opt/rastreabilidade/logs/backup.log 2>&1") | crontab -
```

## 12. Monitoramento (Opcional)

```bash
# Instalar ferramentas de monitoramento
sudo dnf install -y htop iotop nmon

# Monitorar logs do Docker
docker-compose logs -f

# Monitorar contêineres
watch docker ps

# Monitorar uso de recursos
htop
```

## 13. Atualização do Sistema

Para atualizar o sistema quando houver novas versões:

```bash
# Navegar para o diretório do projeto
cd /opt/rastreabilidade

# Puxar as alterações mais recentes
git pull

# Reconstruir e reiniciar os contêineres
docker-compose down
docker-compose build
docker-compose up -d
```

## Solução de Problemas

### Problema: Contêineres não iniciam

```bash
# Verificar logs
docker-compose logs

# Verificar status dos contêineres
docker ps -a
```

### Problema: Erro de conexão com o banco de dados

```bash
# Verificar se o MongoDB está rodando
docker ps | grep mongodb

# Verificar logs do MongoDB
docker logs envx-mongodb
```

### Problema: Erro de permissão

```bash
# Verificar permissões do diretório
ls -la /opt/rastreabilidade

# Corrigir permissões
sudo chown -R $(whoami):$(whoami) /opt/rastreabilidade
```

## Contato para Suporte

Em caso de problemas, entre em contato com o suporte técnico:

- Email: suporte@envx.com.br
- Telefone: (XX) XXXX-XXXX 