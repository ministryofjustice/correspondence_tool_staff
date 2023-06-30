class RenameCategoriesToCorrespondenceTypes < ActiveRecord::Migration[5.0]
  def up
    add_column :categories, :properties, :jsonb, default: {}
    migrate_integer_column_to_json :categories, :internal_time_limit
    migrate_integer_column_to_json :categories, :external_time_limit
    migrate_integer_column_to_json :categories, :escalation_time_limit
    rename_table :categories, :correspondence_types
  end

  def down
    rename_table :correspondence_types, :categories
    migrate_integer_column_from_json :categories, :escalation_time_limit
    migrate_integer_column_from_json :categories, :external_time_limit
    migrate_integer_column_from_json :categories, :internal_time_limit
    remove_column :categories, :properties
  end

  class Category < ApplicationRecord
  end

  def migrate_integer_column_to_json(table, column)
    # To migrate string/text values, the SQL below would have to quote the
    # value of column that is being concated into JSON. This is why the method
    # is specialized for integers at this time.
    Category.connection.execute(<<~EOSQL)
      UPDATE #{table} SET properties=properties || concat('{"#{column}":', #{column}, '}')::jsonb
    EOSQL
    remove_column :categories, column, :integer
  end

  def migrate_integer_column_from_json(table, column)
    add_column :categories, column, :integer
    Category.connection.execute(<<~EOSQL)
      UPDATE #{table} SET #{column}=(properties->>'#{column}')::text::integer, properties=properties - '#{column}'
    EOSQL
  end
end
