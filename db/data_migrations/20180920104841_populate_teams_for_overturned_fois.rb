class PopulateTeamsForOverturnedFois < ActiveRecord::DataMigration
  def up
    overturned_foi_ct = CorrespondenceType.overturned_foi
    foi_ct = CorrespondenceType.foi

    teams = BusinessUnit.all
    teams.each do |bu|
      if bu.correspondence_types.include?(foi_ct)
        unless bu.correspondence_types.include?(overturned_foi_ct)
          bu.correspondence_types << overturned_foi_ct
          bu.save!
        end
      end
    end
  end
end
