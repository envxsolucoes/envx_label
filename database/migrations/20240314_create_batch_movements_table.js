/**
 * Migração para criar a tabela de movimentações de lotes
 */
exports.up = function(knex) {
  return knex.schema.createTable('batch_movements', function(table) {
    table.uuid('id').primary();
    table.uuid('batch_id').references('id').inTable('batches').onDelete('CASCADE').notNullable();
    table.uuid('origin_company_id').references('id').inTable('companies').onDelete('SET NULL');
    table.uuid('destination_company_id').references('id').inTable('companies').onDelete('SET NULL');
    table.decimal('quantity', 15, 3).notNullable();
    table.string('unit').notNullable();
    table.string('movement_type').notNullable();
    table.string('status').notNullable();
    table.timestamp('movement_date').notNullable();
    table.jsonb('additional_info').nullable();
    table.decimal('latitude', 10, 8).nullable();
    table.decimal('longitude', 11, 8).nullable();
    table.uuid('created_by').references('id').inTable('users').onDelete('SET NULL');
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
  });
};

/**
 * Migração para remover a tabela de movimentações de lotes
 */
exports.down = function(knex) {
  return knex.schema.dropTable('batch_movements');
}; 