class CreateCaseNumberCounters < ActiveRecord::Migration[5.0]
  def change
    create_table :case_number_counters do |t|
      t.date :date, null: false
      t.integer :counter, default: 0

      t.index :date, unique: true
    end
  end
end
