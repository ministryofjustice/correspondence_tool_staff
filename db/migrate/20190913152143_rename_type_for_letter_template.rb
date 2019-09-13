class RenameTypeForLetterTemplate < ActiveRecord::Migration[5.0]
  def change
    rename_column :letter_templates, :type, :template_type
  end
end
