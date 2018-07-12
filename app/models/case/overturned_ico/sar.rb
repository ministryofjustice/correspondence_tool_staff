class Case::OverturnedICO::SAR < Case::OverturnedICO::Base

  def self.type_abbreviation
    'OVERTURNED_SAR'
  end

  def validate_original_ico_appeal
    if original_ico_appeal.blank?
      errors.add(:original_ico_appeal, :blank)
    else
      unless original_ico_appeal.is_a?(Case::ICO::SAR)
        errors.add(:original_ico_appeal, :not_ico_sar)
      end
    end
  end

end
