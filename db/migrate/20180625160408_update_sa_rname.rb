class UpdateSaRname < ActiveRecord::Migration[5.0]
  def up
    CorrespondenceType.sar.update!(name: 'Subject access request')
  end

  def down
    CorrespondenceType.sar.update!(name: 'Subject Access Request')
  end
end
