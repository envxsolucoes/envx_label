require('dotenv').config();
require('express-async-errors');

const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const path = require('path');

// Importação de rotas
const authRoutes = require('./routes/auth.routes');
const userRoutes = require('./routes/user.routes');
const productRoutes = require('./routes/product.routes');
const companyRoutes = require('./routes/company.routes');
const labelRoutes = require('./routes/label.routes');
const batchRoutes = require('./routes/batch.routes');
const traceabilityRoutes = require('./routes/traceability.routes');
const reportRoutes = require('./routes/report.routes');

// Importação de middlewares
const errorHandler = require('./middleware/errorHandler');

const app = express();
const PORT = process.env.PORT || 3001;

// Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// Servir arquivos estáticos
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Rotas
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/products', productRoutes);
app.use('/api/companies', companyRoutes);
app.use('/api/labels', labelRoutes);
app.use('/api/batches', batchRoutes);
app.use('/api/traceability', traceabilityRoutes);
app.use('/api/reports', reportRoutes);

// Rota para verificar se a API está funcionando
app.get('/', (req, res) => {
  res.json({ message: 'API de Rastreabilidade funcionando!' });
});

// Middleware de tratamento de erros
app.use(errorHandler);

// Iniciar o servidor
app.listen(PORT, () => {
  console.log(`Servidor rodando na porta ${PORT}`);
});

module.exports = app; 