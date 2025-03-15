/**
 * Migração para criar a tabela de lotes
 */
exports.up = function(knex) {
  return knex.schema.createTable('batches', function(table) {
    table.uuid('id').primary();
    table.string('batch_number').notNullable().unique();
    table.uuid('product_id').references('id').inTable('products').onDelete('CASCADE').notNullable();
    table.uuid('company_id').references('id').inTable('companies').onDelete('CASCADE').notNullable();
    table.decimal('quantity', 15, 3).notNullable();
    table.string('unit').notNullable();
    table.date('production_date').notNullable();
    table.date('expiration_date').nullable();
    table.string('status').notNullable().defaultTo('created');
    table.string('qr_code').nullable();
    table.string('barcode').nullable();
    table.jsonb('additional_info').nullable();
    table.uuid('created_by').references('id').inTable('users').onDelete('SET NULL');
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
  });
};

/**
 * Migração para remover a tabela de lotes
 */
exports.down = function(knex) {
  return knex.schema.dropTable('batches');
}; 