class Case::FOI::Standard < Case::Base
  class << self
    def decorator_class
      Case::FOI::StandardDecorator
    end

    def type_abbreviation
      'FOI'
    end
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
    responding_team_acceptance_date = transitions.where(
        event: 'assign_responder'
    ).last.created_at.to_date

    disclosure_approval_date = transitions.where(
        event: 'approve',
        acting_team_id: default_clearance_team.id
    ).last.created_at.to_date

    internal_deadline = deadline_calculator.internal_deadline_for_date(
        correspondence_type, responding_team_acceptance_date
    )

    internal_deadline >= disclosure_approval_date
  end


  # determines whether or not an individual BU responded to a case in time, measured
  # from the date the case was assigned to the business unit to the time the case was marked as responded.
  # Note that the time limit is different for trigger cases (the internal time limit) than for non trigger
  # (the external time limit)
  #
  def business_unit_responded_in_time?
    responding_transitions = transitions.where(event: 'respond')
    if responding_transitions.any?
      responding_team_acceptance_date = transitions.where(event: 'assign_responder').last.created_at.to_date
      responding_transition = responding_transitions.last
      responding_date = responding_transition.created_at.to_date
      internal_deadline = deadline_calculator
            .internal_deadline_for_date(correspondence_type, responding_team_acceptance_date)
      internal_deadline >= responding_date
    else
      raise ArgumentError.new("Cannot call ##{__method__} on a case without a response (Case #{number})")
    end
  end

  def business_unit_already_late?
    if transitions.where(event: 'respond').any?
      raise ArgumentError.new("Cannot call ##{__method__} on a case for which the response has been sent")
    else
      responding_team_acceptance_date = transitions.where(event: 'assign_responder').last.created_at.to_date
      internal_deadline = deadline_calculator.business_unit_deadline_for_date(responding_team_acceptance_date)
      internal_deadline < Date.today
    end
  end
end
