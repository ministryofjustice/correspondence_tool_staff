class AddContactEscalation < ActiveRecord::Migration[6.1]
  def change
    change_table :contacts, bulk: true do |t|
      t.column :escalation_name, :string
      t.column :escalation_emails, :string
    end
  end
end
