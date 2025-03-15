/**
 * Migração para criar a tabela de produtos
 */
exports.up = function(knex) {
  return knex.schema.createTable('products', function(table) {
    table.uuid('id').primary();
    table.string('name').notNullable();
    table.string('description').nullable();
    table.string('sku').nullable();
    table.string('barcode').nullable();
    table.string('category').nullable();
    table.string('brand').nullable();
    table.string('unit').notNullable().defaultTo('un');
    table.decimal('weight', 10, 3).nullable();
    table.string('weight_unit').nullable();
    table.jsonb('nutritional_info').nullable();
    table.string('variety').nullable();
    table.string('cultivar').nullable();
    table.string('origin').nullable();
    table.string('image_url').nullable();
    table.boolean('active').notNullable().defaultTo(true);
    table.uuid('created_by').references('id').inTable('users').onDelete('SET NULL');
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
  });
};

/**
 * Migração para remover a tabela de produtos
 */
exports.down = function(knex) {
  return knex.schema.dropTable('products');
}; 