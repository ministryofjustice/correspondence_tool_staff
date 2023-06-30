# == Schema Information
#
# Table name: cases
#
#  id                   :integer          not null, primary key
#  name                 :string
#  email                :string
#  message              :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  received_date        :date
#  postal_address       :string
#  subject              :string
#  properties           :jsonb
#  requester_type       :enum
#  number               :string           not null
#  date_responded       :date
#  outcome_id           :integer
#  refusal_reason_id    :integer
#  current_state        :string
#  last_transitioned_at :datetime
#  delivery_method      :enum
#  workflow             :string
#  deleted              :boolean          default(FALSE)
#  info_held_status_id  :integer
#  type                 :string
#  appeal_outcome_id    :integer
#  dirty                :boolean          default(FALSE)
#

class Case::FOI::Standard < Case::Base
  class << self
    def decorator_class
      Case::FOI::StandardDecorator
    end

    def type_abbreviation
      # This string is used when constructing paths or methods in other parts of
      # the system. Ensure that it does not come from a user-supplied parameter,
      # and does not contain special chars like slashes, etc.
      "FOI"
    end
  end

  include DraftTimeliness::ResponseAdded

  before_save do
    self.wokflow = "standard" if workflow.nil?
  end

  jsonb_accessor :properties,
                 escalation_deadline: :date,
                 internal_deadline: :date,
                 external_deadline: :date,
                 late_team_id: :integer,
                 date_draft_compliant: :date

  has_paper_trail only: %i[
    name
    email
    postal_address
    properties
    received_date
    requester_type
    subject
  ]

  enum requester_type: {
    academic_business_charity: "academic_business_charity",
    journalist: "journalist",
    member_of_the_public: "member_of_the_public",
    offender: "offender",
    solicitor: "solicitor",
    staff_judiciary: "staff_judiciary",
    what_do_they_know: "what_do_they_know",
  }

  enum delivery_method: {
    sent_by_post: "sent_by_post",
    sent_by_email: "sent_by_email",
  }

  validates :email, presence: true, on: :create, if: -> { postal_address.blank? }
  validates :name, presence: true
  validates :postal_address,
            presence: true,
            on: :create,
            if: -> { email.blank? || sent_by_post? }
  validates :requester_type, :delivery_method, presence: true
  validates :subject, presence: true, length: { maximum: 100 }

  validate :validate_uploaded_request_files, on: :create

  after_create :process_uploaded_request_files, if: -> { uploaded_request_files.present? }

  # determines whether or not the BU responded to flagged cases in time (NOT
  # whether the case was responded to in time!) calculated as the time between
  # the responding BU being assigned the case and the disclosure team approving
  # it.
  def flagged_case_responded_to_in_time_for_stats_purposes?
    responding_team_assignment_date = transitions.where(
      event: "assign_responder",
    ).last.created_at.to_date

    disclosure_approval_date = transitions.where(
      event: "approve",
      acting_team_id: default_clearance_team.id,
    ).last.created_at.to_date

    internal_deadline = @deadline_calculator.internal_deadline_for_date(
      correspondence_type, responding_team_assignment_date
    )

    internal_deadline >= disclosure_approval_date
  end

  def foi?
    true
  end

  def foi_standard?
    true
  end

  def self.factory(type)
    case type&.downcase
    when "standard"
      self
    when "timelinessreview"
      Case::FOI::TimelinessReview
    when "compliancereview"
      Case::FOI::ComplianceReview
    else
      raise ArgumentError, "Invalid FOI type requested: #{type.inspect}"
    end
  end

  def self.ico_model
    Case::ICO::FOI
  end

private

  def validate_uploaded_request_files
    validate_uploaded_request_files_for_sending_by_post
    validate_uploaded_request_files_for_sending_by_email
  end

  def validate_uploaded_request_files_for_sending_by_post
    if sent_by_post? & uploaded_request_files.blank?
      errors.add(
        :uploaded_request_files,
        I18n.t("activerecord.errors.models.case/foi/standard.attributes.uploaded_request_files.optional_blank"),
      )
    end
  end

  def validate_uploaded_request_files_for_sending_by_email
    if sent_by_email? && message.blank? && uploaded_request_files.blank?
      errors.add(
        :message,
        I18n.t("activerecord.errors.models.case/foi/standard.attributes.message.optional_blank"),
      )
      errors.add(
        :uploaded_request_files,
        I18n.t("activerecord.errors.models.case/foi/standard.attributes.uploaded_request_files.optional_blank"),
      )
    end
  end
end
