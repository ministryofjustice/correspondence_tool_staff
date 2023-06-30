class AddBaseTemplateFileRefToLetterTemplate < ActiveRecord::Migration[5.2]
  def change
    add_column :letter_templates, :base_template_file_ref, :string, null: true, default: "ims001.docx"
  end
end
