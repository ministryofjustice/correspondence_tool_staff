class CreateCommissioningDocument < ActiveRecord::Migration[6.1]
  def change
    execute <<-SQL
      CREATE TYPE template_name AS ENUM ('template_name', 'cat_a', 'cctv', 'cross_border', 'mappa', 'pdp', 'prison', 'probation', 'security', 'telephone');
    SQL

    create_table :commissioning_documents do |t|
      t.references :data_request
      t.column :template_name, :template_name, index: true
      t.boolean :sent, default: false
      t.timestamps
    end
  end
end
