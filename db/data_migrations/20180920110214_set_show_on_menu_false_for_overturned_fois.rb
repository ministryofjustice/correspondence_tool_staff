class SetShowOnMenuFalseForOverturnedFois < ActiveRecord::DataMigration
  def up
    CorrespondenceType.all.find_each do |ct|
      if ct.abbreviation == "OVERTURNED_FOI"
        ct.show_on_menu = false
      end
      ct.save!
    end
  end
end
