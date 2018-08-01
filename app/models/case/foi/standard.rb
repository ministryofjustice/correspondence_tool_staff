class Case::FOI::Standard < Case::Base
  class << self
    def decorator_class
      Case::FOI::StandardDecorator
    end

    def type_abbreviation
      'FOI'
    end
  end

  before_save do
    self.wokflow = 'standard' if workflow.nil?
  end


  jsonb_accessor :properties,
                 escalation_deadline: :date,
                 internal_deadline: :date,
                 external_deadline: :date

  has_paper_trail only: [
                    :name,
                    :email,
                    :postal_address,
                    :properties,
                    :received_date,
                    :requester_type,
                    :subject,
                  ]


  enum requester_type: {
         academic_business_charity: 'academic_business_charity',
         journalist: 'journalist',
         member_of_the_public: 'member_of_the_public',
         offender: 'offender',
         solicitor: 'solicitor',
         staff_judiciary: 'staff_judiciary',
         what_do_they_know: 'what_do_they_know'
       }
  enum delivery_method: {
         sent_by_post: 'sent_by_post',
         sent_by_email: 'sent_by_email',
       }

  validates :email, presence: true, on: :create, if: -> { postal_address.blank? }
  validates :message, presence: true, if: -> { sent_by_email? }
  validates_presence_of :name
  validates :postal_address,
            presence: true,
            on: :create,
            if: -> { email.blank? || sent_by_post? }
  validates_presence_of :requester_type, :delivery_method
  validates :subject, presence: true, length: { maximum: 100 }
  validates :uploaded_request_files,
            presence: true,
            on: :create,
            if: -> { sent_by_post? }

  after_create :process_uploaded_request_files, if: :sent_by_post?

  # determines whether or not the BU responded to flagged cases in time (NOT
  # whether the case was responded to in time!) calculated as the time between
  # the responding BU being assigned the case and the disclosure team approving
  # it.
  def flagged_case_responded_to_in_time_for_stats_purposes?
    responding_team_assignment_date = transitions.where(
        event: 'assign_responder'
    ).last.created_at.to_date

    disclosure_approval_date = transitions.where(
        event: 'approve',
        acting_team_id: default_clearance_team.id
    ).last.created_at.to_date

    internal_deadline = deadline_calculator.internal_deadline_for_date(
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
end
