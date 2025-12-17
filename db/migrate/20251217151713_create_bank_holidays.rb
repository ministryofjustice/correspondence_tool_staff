class CreateBankHolidays < ActiveRecord::Migration[7.2]
  def change
    create_table :bank_holidays do |t|
      t.string :division
      t.date :date
      t.string :title
      t.timestamps
    end

    add_index :bank_holidays, %i[division date], unique: true
  end
end
