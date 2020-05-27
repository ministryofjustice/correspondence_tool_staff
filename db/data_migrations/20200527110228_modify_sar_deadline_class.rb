class ModifySarDeadlineClass < ActiveRecord::DataMigration
  def up
    CorrespondenceType.all.each do |ct|
      if ct.abbreviation == 'SAR' || ct.abbreviation == 'OFFENDER_SAR'
        ct.deadline_calculator_class = 'CalendarMonth'
        ct.save!
      end
    end
  end

  def down
    CorrespondenceType.all.each do |ct|
      if ct.abbreviation == 'SAR' || ct.abbreviation == 'OFFENDER_SAR'
        ct.deadline_calculator_class = 'CalendarDays'
        ct.save!
      end
    end
  end
end
