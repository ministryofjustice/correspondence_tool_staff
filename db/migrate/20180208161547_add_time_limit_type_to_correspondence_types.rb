class AddTimeLimitTypeToCorrespondenceTypes < ActiveRecord::Migration[5.0]
  def up
    CorrespondenceType.find_by(abbreviation: 'FOI')
                      &.update time_limit_type: 'business_days'
    CorrespondenceType.find_by(abbreviation: 'GQ')
                      &.update time_limit_type: 'business_days'
    CorrespondenceType.find_by(abbreviation: 'SAR')
                      &.update time_limit_type: 'calendar_days',
                               external_time_limit: 40
  end

  def down
  end
end
