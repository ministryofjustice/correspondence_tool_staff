class ChangeFOIToFOIStandard < ActiveRecord::Migration[5.0]
  def up
    execute "UPDATE cases SET type = 'Case::FOI::Standard' WHERE type = 'Case::FOI'"
  end

  def down
    execute "UPDATE cases SET type = 'Case::FOI' WHERE type = 'Case::FOI::Standard'"
  end
end
