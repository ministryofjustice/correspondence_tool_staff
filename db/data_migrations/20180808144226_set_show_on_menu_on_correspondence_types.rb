class SetShowOnMenuOnCorrespondenceTypes < ActiveRecord::DataMigration
  def up
    CorrespondenceType.all.each do |ct|
      ct.show_on_menu = ct.abbreviation != "OVERTURNED_SAR"
      ct.save!
    end
  end
end
