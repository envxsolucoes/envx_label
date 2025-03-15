/**
 * Migração para criar a tabela de modelos de etiquetas
 */
exports.up = function(knex) {
  return knex.schema.createTable('label_templates', function(table) {
    table.uuid('id').primary();
    table.string('name').notNullable();
    table.string('description').nullable();
    table.integer('width').notNullable();
    table.integer('height').notNullable();
    table.string('unit').notNullable().defaultTo('mm');
    table.jsonb('fields').notNullable();
    table.text('zpl_template').notNullable();
    table.string('preview_url').nullable();
    table.boolean('active').notNullable().defaultTo(true);
    table.uuid('created_by').references('id').inTable('users').onDelete('SET NULL');
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
  });
};

/**
 * Migração para remover a tabela de modelos de etiquetas
 */
exports.down = function(knex) {
  return knex.schema.dropTable('label_templates');
}; 