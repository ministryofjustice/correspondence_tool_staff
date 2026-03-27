class CreateBankHolidays < ActiveRecord::Migration[7.2]
  def change
    create_table :bank_holidays do |t|
      t.json :data, null: false
      t.string :hash_value, null: false
      t.timestamps
    end
  end
end
