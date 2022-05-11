class AddMovedToUnitToTeam < ActiveRecord::Migration[5.0]
  def change
    add_reference :teams, :moved_to_unit
  end
end
