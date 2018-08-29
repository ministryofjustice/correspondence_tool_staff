require './lib/translate_for_case'

class Case::ICO::Base < Case::Base

  include LinkableOriginalCase

  attr_accessor :uploaded_ico_decision_files

  jsonb_accessor :properties,
                 ico_officer_name: :string,
                 ico_reference_number: :string,
                 internal_deadline: :date,
                 external_deadline: :date,
                 date_ico_decision_received: :date,
                 ico_decision: :string,
                 ico_decision_comment: :string

  acts_as_gov_uk_date :date_ico_decision_received,
                      :date_responded,
                      :external_deadline,
                      :internal_deadline,
                      :received_date

  has_paper_trail only: [
                    :date_responded,
                    :external_deadline,
                    :internal_deadline,
                    :ico_officer_name,
                    :ico_reference_number,
                    :message,
                    :properties,
                    :received_date,
                    :date_closed
                  ]

  enum ico_decision: {
      upheld: 'upheld',
      overturned: 'overturned'
  }

  validates :ico_officer_name, presence: true
  validates :ico_reference_number, presence: true
  validates :message, presence: true
  validates :external_deadline, presence: true
  validate :external_deadline_within_limits?,
           if: -> { external_deadline.present? }
  validates :internal_deadline, presence: true, on: :update
  validate :internal_deadline_within_limits?,
           if: -> { internal_deadline.present? },
           on: :update
  validates_presence_of :original_case
  validates :received_date, presence: true
  validate :received_date_within_limits?,
           if: -> { received_date.present? }

  before_save do
    self.workflow = 'trigger'
  end

  after_create :process_uploaded_request_files,
               if: -> { uploaded_request_files.present? }

  class << self
    def searchable_fields_and_ranks
      super.except(:name).merge(
        {
          ico_officer_name:     'C',
          ico_reference_number: 'B',
        }
      )
    end

    def type_abbreviation
      # This string is used when constructing paths or methods in other parts of
      # the system. Ensure that it does not come from a user-supplied parameter,
      # and does not contain special chars like slashes, etc.
      'ICO'
    end
  end

  def closed_for_reporting_purposes?
    closed? || responded?
  end

  def name=(_new_name)
    raise StandardError.new(
            'name attribute is read-only for ICO cases'
      )
  end

  def requires_flag_for_disclosure_specialists?
    false
  end

  def sent_by_email?
    true
  end

  delegate :subject, to: :original_case

  def subject=(_new_subject)
    raise StandardError.new(
            'subject attribute is read-only for ICO cases'
          )
  end

  def ico?
    true
  end

  def current_team_and_user_resolver
    CurrentTeamAndUser::ICO::Trigger.new(self)
  end

  private

  def default_workflow
    'trigger'
  end

  def external_deadline_within_limits?
    if received_date.present?
      if external_deadline < received_date
        errors.add(
          :external_deadline,
          I18n.t('activerecord.errors.models.case.attributes.external_deadline.before_received')
        )
      elsif external_deadline > received_date + 1.year
        errors.add(
          :external_deadline,
          I18n.t('activerecord.errors.models.case.attributes.external_deadline.too_far_past_received')
        )
      end
    end
  end

  def internal_deadline_within_limits?
    if received_date.present? && internal_deadline < received_date
      errors.add(
        :internal_deadline,
        TranslateForCase.t(self,
                           'activerecord.errors.models',
                           'attributes.internal_deadline.before_received')
      )
    end
    if external_deadline.present? && internal_deadline > external_deadline
      errors.add(
        :internal_deadline,
        I18n.t('activerecord.errors.models.case.attributes.internal_deadline.after_external')
      )
    end
  end

  def received_date_within_limits?
    if received_date < Date.today - 10.years
      errors.add(
        :received_date,
        TranslateForCase.t(self,
                           'activerecord.errors.models',
                           'attributes.received_date.past')
      )
    elsif received_date > Date.today
      errors.add(
        :received_date,
        TranslateForCase.t(self,
                           'activerecord.errors.models',
                           'attributes.received_date.not_in_future')
      )
    end
  end

  def set_deadlines
    # For ICOs deadlines are manually set and don't need to be automatically
    # calculated. So this method called by a before_update hook in Case::Base
    # becomes a nop.
    self.internal_deadline ||= deadline_calculator.internal_deadline
  end

  def update_deadlines
    # For ICOs deadlines are manually set and don't need to be automatically
    # calculated. So this method called by a before_update hook in Case::Base
    # becomes a nop.
    nil
  end
end
