class AddSubjectToCorrespondence < ActiveRecord::Migration[5.0]
  def change
    add_column :correspondence, :subject, :string
  end
end
