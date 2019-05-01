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

class Case::Offender_SAR < Case::Base
  class << self
    def type_abbreviation
      # This string is used when constructing paths or methods in other parts of
      # the system. Ensure that it does not come from a user-supplied parameter,
      # and does not contain special chars like slashes, etc.
      'OFFENDER_SAR'
    end
  end

  include DraftTimeliness::ProgressedForClearance

  before_save do
    self.workflow = 'standard' if workflow.nil?
  end

  def self.searchable_fields_and_ranks
    super.merge(
        {
            subject_full_name:     'B'
        }
    )
  end

  jsonb_accessor :properties,
                 escalation_deadline: :date,
                 internal_deadline: :date,
                 external_deadline: :date,
                 subject_full_name: :string,
                 subject_type: :string,
                 third_party: :boolean,
                 third_party_relationship: :string,
                 reply_method: :string,
                 late_team_id: :integer,
                 date_draft_compliant: :date,
                 deadline_extended: [:boolean, default: false]

  attr_accessor :missing_info

  enum subject_type: {
         offender:             'offender',
         staff:                'staff',
         member_of_the_public: 'member_of_the_public'
       }
  enum reply_method: {
         send_by_post:  'send_by_post',
         send_by_email: 'send_by_email',
       }

  has_paper_trail only: [
                    :name,
                    :email,
                    :postal_address,
                    :properties,
                    :received_date,
                    :subject,
                  ]

  validates_presence_of :subject_full_name
  validates :third_party, inclusion: {in: [ true, false ], message: "Please choose yes or no" }

  validates_presence_of :name, :third_party_relationship, if: -> { third_party }
  validates_presence_of :reply_method
  validates_presence_of :subject_type
  validates_presence_of :email,          if: :send_by_email?
  validates_presence_of :postal_address, if: :send_by_post?
  validates :subject, presence: true, length: { maximum: 100 }
  validate :validate_message_or_uploaded_request_files, on: :create
  validate :validate_message_or_attached_request_files, on: :update


end
