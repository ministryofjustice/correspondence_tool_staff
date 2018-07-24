class Case::ICO::Base < Case::Base
  jsonb_accessor :properties,
                 ico_officer_name: :string,
                 ico_reference_number: :string,
                 internal_deadline: :date,
                 external_deadline: :date

  acts_as_gov_uk_date :received_date, :date_responded, :external_deadline

  has_paper_trail only: [
                    :date_responded,
                    :external_deadline,
                    :ico_reference_number,
                    :message,
                    :properties,
                    :received_date,
                    :subject,
                  ]

  has_one :original_case_link,
          -> { original },
          class_name: 'LinkedCase',
          foreign_key: :case_id
  has_one :original_case,
          through: :original_case_link,
          source: :linked_case

  validates :ico_officer_name, presence: true
  validates :ico_reference_number, presence: true
  validates :message, presence: true
  validates :external_deadline, presence: true
  validate :validate_original_case
  validate :validate_original_case_not_already_related
  validates_presence_of :original_case

  before_save do
    self.workflow = 'trigger'
  end

  after_create :process_uploaded_request_files,
               if: -> { uploaded_request_files.present? }

  class << self
    def searchable_fields_and_ranks
      super.merge(
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

  def original_case_id=(case_id)
    self.original_case = Case::Base.find(case_id)
  end

  def original_case_id
    self.original_case&.id
  end

  private

  def default_workflow
    'trigger'
  end

  def validate_original_case
    if self.original_case
      validate_case_link(:original, original_case, :original_case)
    end
  end

  def validate_original_case_not_already_related
    if original_case.in?(related_cases)
      self.errors.add(:linked_cases, :original_case_already_related)
    end
  end
end
