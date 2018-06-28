class Case::ICO::Base < Case::Base
  jsonb_accessor :properties,
                 ico_reference_number: :string,
                 internal_deadline: :date,
                 external_deadline: :date

  acts_as_gov_uk_date :received_date, :date_responded, :external_deadline

  # Used by the controller to drive the views which ask the user to select the
  # "original case type"
  attr_accessor :original_case_type

  validates :ico_reference_number, presence: true
  validates :message, presence: true
  validates :external_deadline, presence: true

  before_save do
    self.workflow = 'trigger'
  end

  after_create :process_uploaded_request_files,
               if: -> { uploaded_request_files.present? }

  class << self
    def type_abbreviation
      'ICO'
    end
  end

  def sent_by_email?
    true
  end

  def requires_flag_for_disclosure_specialists?
    false
  end

  def set_deadlines
    days = correspondence_type.internal_time_limit.business_days
    self.internal_deadline = days.before(self.external_deadline)
  end

  def closed_for_reporting_purposes?
    closed? || responded?
  end

  private

  def default_workflow
    'trigger'
  end
end
