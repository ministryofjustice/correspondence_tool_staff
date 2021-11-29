class Case::SAR::InternalReview < Case::SAR::Standard

  include LinkableOriginalCase

  validates_presence_of :original_case

  attr_accessor :original_case_number

  validate :validate_email
  validate :validate_postal_address
  validate :name
  validate :validate_subject
  validate :validate_third_party_relationship

  after_initialize :remove_conditional_validators

  validates_presence_of :sar_ir_subtype

  jsonb_accessor :properties,
                 sar_ir_subtype: :string

  class << self
    def type_abbreviation
      # This string is used when constructing paths or methods in other parts of
      # the system. Ensure that it does not come from a user-supplied parameter,
      # and does not contain special chars like slashes, etc.
      'SAR_INTERNAL_REVIEW'
    end

    def state_machine_name
      'sar'
    end
  end

  enum sar_ir_subtype: {
    timeliness: 'timeliness',
    compliance: 'compliance'
  }

  private

  def validate_email
    if send_by_email? && email.blank?
      errors.add(
        :email,
        :blank
      )
    end
  end

  def validate_name
    if third_party && name.blank?
        errors.add(
          :name,
          :blank
        )
    end
  end

  def validate_postal_address
    if send_by_post? && postal_address.blank?
      errors.add(
        :postal_address,
        :blank
      )
    end
  end

  def validate_subject
    if subject.blank?
      errors.add(
        :subject,
        :blank
      )
    end

    if subject.present? && subject.size > 100
      errors.add(
        :subject,
        message: "Subject must be under 100 characters in length"
      )
    end
  end

  def validate_third_party_relationship
    if third_party && third_party_relationship.blank?
      errors.add(
        :third_party_relationship,
        :blank
      )
    end
  end

  def remove_conditional_validators
    # This method is called in SarInternalReview 
    # due to an issue whereby the inline conditional 
    # validation declarations in the parent class 
    # (Case::SAR::Standard) are not respected by the 
    # .valid_attributes? method in ApplicationRecord.
    #
    # This causes the validations to fire incorrectly.
    # This method removes the inherited validators
    # which are then replaced with validator methods
    # in this class which are respected by
    # .valid_attributes? in ApplicationRecord
    parent_class_validators_to_remove = [
      :name,
      :email,
      :postal_address,
      :third_party_relationship,
      :subject
    ]
    _validators.reject! do |key, _val| 
      parent_class_validators_to_remove.include?(key)
    end
  end

end
