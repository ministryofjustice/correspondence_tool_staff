class AddContactEscalation < ActiveRecord::Migration[6.1]
  def change
    change_table :contacts, bulk: true do |t|
      t.column :escalation_name, :string
      t.column :escalation_email, :string
    end
  end
end
