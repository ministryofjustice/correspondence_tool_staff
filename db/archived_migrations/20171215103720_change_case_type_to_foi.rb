class ChangeCaseTypeToFOI < ActiveRecord::Migration[5.0]
  def up
    execute "UPDATE cases SET type = 'Case::FOI' WHERE type = 'Case'"
  end

  def down
    execute "UPDATE cases SET type = 'Case' WHERE type = 'Case::FOI'"
  end
end
