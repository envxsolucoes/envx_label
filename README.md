# Sistema de Rastreabilidade ENVX

Sistema completo para rastreabilidade de produtos, desde a produção até o consumidor final.

## Funcionalidades

1. **Autenticação e Controle de Acesso**
   * Login/Logout
   * Gerenciamento de permissões
   * Dashboard personalizado
   * Autenticação via GitHub

2. **Cadastros Básicos**
   * Produtos (informações básicas, dados nutricionais, variedades/cultivares)
   * Empresas/ELOs (dados cadastrais, tipo, endereços)
   * Modelos de Etiquetas (dimensões, layout, campos personalizados, template ZPL)

3. **Gestão de Lotes**
   * Criação de lotes (associação com produto, quantidade, datas)
   * Geração de códigos (rastreabilidade, QR Code, código de barras)
   * Impressão de etiquetas (preview, configuração de impressora, histórico)

4. **Rastreabilidade**
   * Movimentação de lotes (origem/destino, data/hora, quantidade)
   * Histórico completo (timeline de movimentações, status em cada etapa)
   * Consulta pública (interface web, leitura de QR Code)

5. **Relatórios e Análises**
   * Estatísticas de produção
   * Histórico de movimentações
   * Rastreabilidade completa
   * Indicadores de qualidade

## Tecnologias Utilizadas

### Frontend
- React
- Tailwind CSS
- React Router
- Axios
- React Query
- Context API

### Backend
- Node.js
- Express
- PostgreSQL
- Knex.js (Query Builder)
- JWT para autenticação
- Integração com GitHub OAuth
- ZPL para impressão de etiquetas

## Scripts de Automação

O sistema inclui diversos scripts para automação de tarefas:

- Configuração de ambiente (desenvolvimento e produção)
- Backup e restauração de banco de dados
- Deploy automatizado
- Monitoramento do sistema

## Requisitos

- Node.js >= 18.0.0
- PostgreSQL >= 14
- AlmaLinux (para ambiente de produção)

## Instalação

### Backend

```bash
cd backend
npm install
cp .env.example .env
# Configure as variáveis de ambiente no arquivo .env
npm run migrate
npm run seed
npm run dev
```

### Frontend

```bash
cd frontend
npm install
cp .env.example .env
# Configure as variáveis de ambiente no arquivo .env
npm start
```

## Estrutura do Projeto

```
.
├── backend/                  # Código do servidor
│   ├── src/
│   │   ├── config/           # Configurações
│   │   ├── controllers/      # Controladores
│   │   ├── middleware/       # Middlewares
│   │   ├── models/           # Modelos
│   │   ├── routes/           # Rotas
│   │   ├── services/         # Serviços
│   │   ├── utils/            # Utilitários
│   │   └── server.js         # Ponto de entrada
│   ├── .env                  # Variáveis de ambiente
│   └── package.json          # Dependências
├── frontend/                 # Código do cliente
│   ├── public/               # Arquivos estáticos
│   ├── src/
│   │   ├── assets/           # Recursos (imagens, etc.)
│   │   ├── components/       # Componentes reutilizáveis
│   │   ├── context/          # Contextos React
│   │   ├── hooks/            # Hooks personalizados
│   │   ├── pages/            # Páginas da aplicação
│   │   ├── services/         # Serviços (API, etc.)
│   │   ├── utils/            # Utilitários
│   │   ├── App.js            # Componente principal
│   │   └── index.js          # Ponto de entrada
│   ├── .env                  # Variáveis de ambiente
│   └── package.json          # Dependências
└── database/                 # Scripts de banco de dados
    └── migrations/           # Migrações do banco
```

## Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo LICENSE para detalhes. 