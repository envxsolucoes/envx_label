/**
 * Migração para criar a tabela de empresas
 */
exports.up = function(knex) {
  return knex.schema.createTable('companies', function(table) {
    table.uuid('id').primary();
    table.string('name').notNullable();
    table.string('trading_name').nullable();
    table.string('document').notNullable().unique();
    table.string('document_type').notNullable().defaultTo('CNPJ');
    table.string('company_type').notNullable();
    table.string('email').nullable();
    table.string('phone').nullable();
    table.string('website').nullable();
    table.string('logo_url').nullable();
    table.jsonb('address').nullable();
    table.decimal('latitude', 10, 8).nullable();
    table.decimal('longitude', 11, 8).nullable();
    table.boolean('active').notNullable().defaultTo(true);
    table.uuid('created_by').references('id').inTable('users').onDelete('SET NULL');
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
  });
};

/**
 * Migração para remover a tabela de empresas
 */
exports.down = function(knex) {
  return knex.schema.dropTable('companies');
}; 