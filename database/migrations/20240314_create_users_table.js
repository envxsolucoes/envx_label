/**
 * Migração para criar a tabela de usuários
 */
exports.up = function(knex) {
  return knex.schema.createTable('users', function(table) {
    table.uuid('id').primary();
    table.string('name').notNullable();
    table.string('email').notNullable().unique();
    table.string('password').nullable();
    table.string('role').notNullable().defaultTo('user');
    table.string('github_id').nullable().unique();
    table.string('avatar_url').nullable();
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
  });
};

/**
 * Migração para remover a tabela de usuários
 */
exports.down = function(knex) {
  return knex.schema.dropTable('users');
}; 