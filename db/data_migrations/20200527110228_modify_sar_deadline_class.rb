class ModifySarDeadlineClass < ActiveRecord::DataMigration
  def up
    CorrespondenceType.all.each do |ct|
      byebug
      if ct.abbreviation == 'SAR' || ct.abbreviation == 'OFFENDER_SAR'
        ct.deadline_calculator_class = 'CalendarMonth'
        ct.save!
      end
    end
  end
end