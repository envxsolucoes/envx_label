const knex = require('knex');
const knexConfig = require('../../knexfile');

// Determina o ambiente atual
const environment = process.env.NODE_ENV || 'development';

// Cria a conexão com o banco de dados
const connection = knex(knexConfig[environment]);

module.exports = connection; 