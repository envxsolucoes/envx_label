# Instruções para Conectar ao GitHub no AlmaLinux

Este documento contém instruções detalhadas para conectar ao repositório GitHub do Sistema de Rastreabilidade ENVX no servidor AlmaLinux.

## 1. Preparação do Ambiente

Primeiro, certifique-se de que o Git está instalado no servidor:

```bash
# Verificar se o Git está instalado
git --version

# Se não estiver instalado, instale-o
sudo dnf install -y git
```

## 2. Configurar Credenciais do Git

Configure seu nome de usuário e email para o Git:

```bash
# Configurar nome de usuário
git config --global user.name "ENVX Admin"

# Configurar email
git config --global user.email "admin@envx.com.br"
```

## 3. Criar Diretório para o Projeto

```bash
# Criar diretório para o projeto (se ainda não existir)
sudo mkdir -p /opt/rastreabilidade

# Definir permissões para o usuário atual
sudo chown -R $(whoami):$(whoami) /opt/rastreabilidade

# Navegar para o diretório
cd /opt/rastreabilidade
```

## 4. Clonar o Repositório com Autenticação

Existem várias maneiras seguras de autenticar-se no GitHub:

### Opção 1: Usando HTTPS com credenciais

```bash
# Clonar o repositório (será solicitado nome de usuário e senha/token)
git clone https://github.com/envxsolucoes/envx_label.git .
```

### Opção 2: Usando SSH (recomendado para maior segurança)

```bash
# Gerar chave SSH (se ainda não tiver uma)
ssh-keygen -t ed25519 -C "admin@envx.com.br"

# Iniciar o agente SSH
eval "$(ssh-agent -s)"

# Adicionar a chave ao agente
ssh-add ~/.ssh/id_ed25519

# Exibir a chave pública para adicionar ao GitHub
cat ~/.ssh/id_ed25519.pub
```

Adicione a chave pública exibida à sua conta do GitHub em Settings > SSH and GPG keys.

```bash
# Clonar o repositório usando SSH
git clone git@github.com:envxsolucoes/envx_label.git .
```

## 5. Verificar a Conexão

Verifique se a conexão com o GitHub foi estabelecida corretamente:

```bash
# Verificar o status do repositório
git status

# Verificar a configuração do repositório remoto
git remote -v
```

## 6. Configurar Armazenamento de Credenciais (Opcional)

Para evitar digitar o token repetidamente, você pode configurar o Git para armazenar as credenciais temporariamente:

```bash
# Armazenar credenciais por 1 hora (3600 segundos)
git config --global credential.helper 'cache --timeout=3600'
```

Ou para armazenar permanentemente (menos seguro):

```bash
# Armazenar credenciais permanentemente
git config --global credential.helper store
```

## 7. Atualizar o Repositório

Se o repositório já existir e você precisar apenas atualizá-lo:

```bash
# Navegar para o diretório do projeto
cd /opt/rastreabilidade

# Puxar as alterações mais recentes
git pull origin master
```

## 8. Solução de Problemas

### Problema: Erro de autenticação

Se você receber um erro de autenticação, verifique se suas credenciais estão corretas.

```bash
# Verificar se o repositório remoto está configurado corretamente
git remote -v
```

### Problema: Conflitos de mesclagem

Se houver conflitos durante o pull:

```bash
# Verificar os arquivos com conflito
git status

# Resolver os conflitos manualmente e depois adicionar os arquivos
git add .

# Continuar o processo de mesclagem
git commit -m "Resolve conflitos de mesclagem"
```

## 9. Próximos Passos

Após conectar com sucesso ao GitHub, você pode prosseguir com a configuração do Sistema de Rastreabilidade ENVX:

```bash
# Executar o script de configuração
sudo bash scripts/setup_almalinux.sh
```

## Observações de Segurança

1. Nunca armazene tokens de acesso pessoal em arquivos de texto ou scripts que serão compartilhados ou versionados.

2. Considere usar chaves SSH em vez de tokens de acesso pessoal para autenticação mais segura.

3. Se precisar usar tokens, utilize variáveis de ambiente ou gerenciadores de segredos. 