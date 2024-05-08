class PopulateTeamsForOverturnedSars < ActiveRecord::DataMigration
  def up
    overturned_sar_ct = CorrespondenceType.overturned_sar
    sar_ct = CorrespondenceType.sar

    teams = BusinessUnit.all
    teams.each do |bu|
      if bu.correspondence_types.include?(sar_ct) && !bu.correspondence_types.include?(overturned_sar_ct)
        bu.correspondence_types << overturned_sar_ct
        bu.save!
      end
    end
  end
end
