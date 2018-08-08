class SetShowOnMenuOnCorrespondenceTypes < ActiveRecord::DataMigration
  def up
    CorrespondenceType.all.each do |ct|
      if ct.abbreviation == 'OVERTURNED_SAR'
        ct.show_on_menu = false
      else
        ct.show_on_menu = true
      end
      ct.save!
    end
  end
end
