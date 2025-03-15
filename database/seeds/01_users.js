const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

/**
 * Seed para criar usuários iniciais
 */
exports.seed = async function(knex) {
  // Limpar a tabela de usuários
  await knex('users').del();
  
  // Criar senha hash para o admin
  const salt = await bcrypt.genSalt(10);
  const adminPassword = await bcrypt.hash('admin123', salt);
  
  // Inserir usuários
  return knex('users').insert([
    {
      id: uuidv4(),
      name: 'Administrador',
      email: 'admin@rastreabilidade.com',
      password: adminPassword,
      role: 'admin',
      created_at: new Date(),
      updated_at: new Date()
    },
    {
      id: uuidv4(),
      name: 'Usuário Teste',
      email: 'usuario@rastreabilidade.com',
      password: await bcrypt.hash('usuario123', salt),
      role: 'user',
      created_at: new Date(),
      updated_at: new Date()
    }
  ]);
}; 