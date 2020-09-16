class AddAddressForLetterTemplates < ActiveRecord::Migration[5.2]
  def change
    add_column :letter_templates, :letter_address, :string,  null: true, default: ''
  end
end
