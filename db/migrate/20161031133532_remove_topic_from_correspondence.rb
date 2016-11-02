class RemoveTopicFromCorrespondence < ActiveRecord::Migration[5.0]
  def change
    remove_column :correspondence, :topic, :string
  end
end
