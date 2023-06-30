class UpdateExternalTimeLimitOnSarCases < ActiveRecord::Migration[5.0]
  def up
    CorrespondenceType.find_by(abbreviation: "SAR")
                      &.update deadline_calculator_class: "CalendarDays",
                               external_time_limit: 30
  end

  def down
    CorrespondenceType.find_by(abbreviation: "SAR")
                      &.update external_time_limit: 40
  end
end
