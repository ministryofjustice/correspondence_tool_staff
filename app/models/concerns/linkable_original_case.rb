module LinkableOriginalCase
  extend ActiveSupport::Concern

  included do

    validate :validate_original_case
    validate :validate_original_case_not_already_related

    has_one :original_case_link,
            -> { original },
            class_name: 'LinkedCase',
            foreign_key: :case_id

    has_one :original_case,
            through: :original_case_link,
            source: :linked_case
  end

  def original_case_id=(case_id)
    self.original_case = Case::Base.find(case_id)
  end

  def original_case_id
    self.original_case&.id
  end

  def original_case_number
    self.original_case&.number
  end

  def validate_original_case
    if self.original_case
      validate_case_link(:original, self.original_case, :original_case)
    end
  end

  def validate_original_case_not_already_related
    if original_case.in?(related_cases)
      self.errors.add(:linked_cases, :original_case_already_related)
    end
  end

end
