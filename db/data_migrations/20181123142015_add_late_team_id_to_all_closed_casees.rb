class AddLateTeamIdToAllClosedCasees < ActiveRecord::DataMigration
  def up
    Case::Base.unscoped.closed.in_batches(of: 100) do |arel|
      arel.each do |rec|
        rec.late_team_id = rec.responding_team&.id if rec.responded_late?
      end
    end
  end
end
