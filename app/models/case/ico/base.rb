class Case::ICO::Base < Case::Base

  include LinkableOriginalCase

  jsonb_accessor :properties,
                 ico_officer_name: :string,
                 ico_reference_number: :string,
                 internal_deadline: :date,
                 external_deadline: :date


  acts_as_gov_uk_date :received_date, :date_responded, :external_deadline

  has_paper_trail only: [
                    :date_responded,
                    :external_deadline,
                    :ico_officer_name,
                    :ico_reference_number,
                    :message,
                    :properties,
                    :received_date,
                  ]

  validates :ico_officer_name, presence: true
  validates :ico_reference_number, presence: true
  validates :message, presence: true
  validates :external_deadline, presence: true
  validates_presence_of :original_case

  validates_with ::RespondedCaseValidator

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

  def set_deadlines
    days = correspondence_type.internal_time_limit.business_days
    self.internal_deadline = days.before(self.external_deadline)
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

  private

  def default_workflow
    'trigger'
  end

end
