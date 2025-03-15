/**
 * Migração para criar a tabela de impressões de etiquetas
 */
exports.up = function(knex) {
  return knex.schema.createTable('label_prints', function(table) {
    table.uuid('id').primary();
    table.uuid('batch_id').references('id').inTable('batches').onDelete('CASCADE').notNullable();
    table.uuid('label_template_id').references('id').inTable('label_templates').onDelete('SET NULL');
    table.integer('quantity').notNullable();
    table.text('zpl_data').notNullable();
    table.string('printer_name').nullable();
    table.string('printer_ip').nullable();
    table.integer('printer_port').nullable();
    table.string('status').notNullable();
    table.timestamp('print_date').notNullable();
    table.uuid('created_by').references('id').inTable('users').onDelete('SET NULL');
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
  });
};

/**
 * Migração para remover a tabela de impressões de etiquetas
 */
exports.down = function(knex) {
  return knex.schema.dropTable('label_prints');
}; 