class CreateBankHolidays < ActiveRecord::Migration[7.2]
  def change
    drop_table :bank_holidays, if_exists: true
    create_table :bank_holidays do |t|
      t.json :data, null: false
      t.string :hash_value , null: false
      t.timestamps
    end

    add_index :bank_holidays, %i[hash_value], unique: true
  end
end
