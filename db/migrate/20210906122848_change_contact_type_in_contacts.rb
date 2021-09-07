class ChangeContactTypeInContacts < ActiveRecord::Migration[5.2]
  def change
    change_column :contacts, :contact_type, :string
  end
end
