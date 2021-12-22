class ModifySarDeadlineClass < ActiveRecord::DataMigration
  def up
    CorrespondenceType.all.each do |ct|
      if ct.abbreviation == 'SAR' || ct.abbreviation == 'OFFENDER_SAR'
        ct.update(
          deadline_calculator_class: "CalendarMonths", 
          external_time_limit: 1, 
          extension_time_limit: 2, 
          extension_time_default: 1)
      end
    end
  end

  def down
    CorrespondenceType.all.each do |ct|
      if ct.abbreviation == 'SAR' || ct.abbreviation == 'OFFENDER_SAR'
        ct.update(
          deadline_calculator_class: "CalendarDays", 
          external_time_limit: 30)
      end
    end
  end
end
