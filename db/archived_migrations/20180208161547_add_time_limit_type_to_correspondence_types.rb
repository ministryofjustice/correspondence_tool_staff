class AddTimeLimitTypeToCorrespondenceTypes < ActiveRecord::Migration[5.0]
  def up
    CorrespondenceType.find_by(abbreviation: 'FOI')
                      &.update deadline_calculator_class: 'BusinessDays'
    CorrespondenceType.find_by(abbreviation: 'GQ')
                      &.update deadline_calculator_class: 'BusinessDays'
    CorrespondenceType.find_by(abbreviation: 'SAR')
                      &.update deadline_calculator_class: 'CalendarDays',
                               external_time_limit: 40
  end

  def down
  end
end
