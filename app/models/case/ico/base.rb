class Case::ICO::Base < Case::Base
  jsonb_accessor :properties,
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

  # Used by the controller to drive the views which ask the user to select the
  # "original case type"
  attr_accessor :original_case_id

  has_one :original_case_link,
          -> { original },
          class_name: 'LinkedCase',
          foreign_key: :case_id
  has_one :original_case,
          through: :original_case_link,
          source: :linked_case

  has_many :related_case_links,
           -> { related },
           class_name: 'LinkedCase',
           foreign_key: :case_id
  has_many :related_cases,
           through: :related_case_links,
           source: :linked_case


  validates :ico_reference_number, presence: true
  validates :message, presence: true
  validates :external_deadline, presence: true

  before_save do
    self.workflow = 'trigger'
  end

  after_create :process_uploaded_request_files,
               if: -> { uploaded_request_files.present? }
  after_create :link_original_case

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

  def link_original_case
    if original_case_id.present?
      self.original_case = Case::Base.find(original_case_id)
    end
  end
end
