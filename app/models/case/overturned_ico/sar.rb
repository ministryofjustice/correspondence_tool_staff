class Case::OverturnedICO::SAR < Case::OverturnedICO::Base

  has_paper_trail only: [
      :ico_reference,
      :escalation_deadline,
      :external_deadline,
      :internal_deadline,
      :reply_method,
      :email,
      :post_address,
      :original_ico_appeal,
      :original_case,
      :date_received
  ]

  def self.type_abbreviation
    # This string is used when constructing paths or methods in other parts of
    # the system. Ensure that it does not come from a user-supplied parameter,
    # and does not contain special chars like slashes, etc.
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
