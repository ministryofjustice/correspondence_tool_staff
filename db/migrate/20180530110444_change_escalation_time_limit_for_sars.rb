class ChangeEscalationTimeLimitForSars < ActiveRecord::Migration[5.0]
  def up
    sar = CorrespondenceType.find_by(abbreviation: 'SAR')
    if sar.present?
      sar.escalation_time_limit = -1
      sar.save!
    end
  end

  def down
    sar = CorrespondenceType.find_by(abbreviation: 'SAR')
    if sar.present?
      sar.escalation_time_limit = 0
      sar.save!
    end
  end
end
