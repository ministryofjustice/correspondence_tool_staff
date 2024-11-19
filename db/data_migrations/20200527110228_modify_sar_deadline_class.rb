class ModifySARDeadlineClass < ActiveRecord::DataMigration
  def up
    CorrespondenceType.all.find_each do |ct|
      next unless ct.abbreviation == "SAR" || ct.abbreviation == "OFFENDER_SAR"

      ct.update!(
        deadline_calculator_class: "CalendarMonths",
        external_time_limit: 1,
        extension_time_limit: 2,
        extension_time_default: 1,
      )
    end
  end

  def down
    CorrespondenceType.all.find_each do |ct|
      next unless ct.abbreviation == "SAR" || ct.abbreviation == "OFFENDER_SAR"

      ct.update!(
        deadline_calculator_class: "CalendarDays",
        external_time_limit: 30,
      )
    end
  end
end
