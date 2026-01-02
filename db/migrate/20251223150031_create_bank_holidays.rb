class CreateBankHolidays < ActiveRecord::Migration[7.2]
  def change
    create_table :bank_holidays do |t|
      t.json :data
      t.string :hash_value
      t.timestamps
    end
  end
end
