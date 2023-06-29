class RenameCorrespondenceToCase < ActiveRecord::Migration[5.0]
  def change
    rename_table "correspondence", "cases"
    rename_column :assignments, :correspondence_id, :case_id
  end
end
