# == Schema Information
#
# Table name: cases
#
#  id                       :integer          not null, primary key
#  name                     :string
#  email                    :string
#  message                  :text
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  received_date            :date
#  postal_address           :string
#  subject                  :string
#  properties               :jsonb
#  requester_type           :enum
#  number                   :string           not null
#  date_responded           :date
#  outcome_id               :integer
#  refusal_reason_id        :integer
#  current_state            :string
#  last_transitioned_at     :datetime
#  delivery_method          :enum
#  workflow                 :string
#  deleted                  :boolean          default(FALSE)
#  info_held_status_id      :integer
#  type                     :string
#  appeal_outcome_id        :integer
#  dirty                    :boolean          default(FALSE)
#  reason_for_deletion      :string
#  user_id                  :integer          default(-100), not null
#  reason_for_lateness_id   :bigint
#  reason_for_lateness_note :string
#
class Case::SAR::InternalReview < Case::SAR::Standard
  include LinkableOriginalCase

  # override parent class callback behaviour
  # as not required for SAR::InternalReview cases
  skip_callback :save, :before, :use_subject_as_requester

  belongs_to :sar_ir_outcome, class_name: "CaseClosure::AppealOutcome"

  validates :original_case, presence: true
  validates :sar_ir_subtype, presence: true

  validate :validate_other_option_details

  attr_accessor :original_case_number

  jsonb_accessor :properties,
                 sar_ir_subtype: :string,
                 team_responsible_for_outcome_id: :integer,
                 other_option_details: :string

  HUMANIZED_ATTRIBUTES = {
    sar_ir_subtype: "Case type",
    subject: "Case summary",
    message: "Full case details",
    original_case: "The original case",
  }.freeze

  before_save do
    self.workflow = "trigger"
  end

  class << self
    def type_abbreviation
      # This string is used when constructing paths or methods in other parts of
      # the system. Ensure that it does not come from a user-supplied parameter,
      # and does not contain special chars like slashes, etc.
      "SAR_INTERNAL_REVIEW"
    end

    def state_machine_name
      "sar_internal_review"
    end

    def human_attribute_name(attr, options = {})
      HUMANIZED_ATTRIBUTES[attr.to_sym] || super
    end

    def steppable?
      true
    end
  end

  enum :sar_ir_subtype, {
    timeliness: "timeliness",
    compliance: "compliance",
  }

  def sar_ir_outcome
    appeal_outcome&.name
  end

  def sar_internal_review?
    true
  end

  def sar_ir_outcome_abbr
    appeal_outcome&.abbreviation
  end

  def sar_ir_outcome=(name)
    self.appeal_outcome = CaseClosure::AppealOutcome.by_name(name)
  end

  def stoppable?
    false
  end

  def validate_other_option_details
    other_is_selected = outcome_reasons.map(&:abbreviation).include?("other")
    other_not_selected = !other_is_selected

    if other_not_selected && other_option_details.present?
      errors.add(
        :other_option_details,
        message: I18n.t("activerecord.errors.models.case/sar/internal_review.attributes.other_option_details.present"),
      )
    end

    if other_is_selected && other_option_details.blank?
      errors.add(
        :other_option_details,
        message: I18n.t("activerecord.errors.models.case/sar/internal_review.attributes.other_option_details.absent"),
      )
    end
  end

  def validate_case_link(type, linked_case, attribute)
    linkable = CaseLinkTypeValidator.classes_can_be_linked_with_type?(
      klass: self.class.to_s,
      linked_klass: linked_case.class.to_s,
      type:,
    )

    unless linkable
      errors.add(
        attribute,
        :wrong_type,
        message: I18n.t("activerecord.errors.models.case/sar/internal_review.attributes.linked_case.wrong_type"),
      )
    end
  end
end
