class Case::ICO::Base < Case::Base
  jsonb_accessor :properties,
                 ico_reference_number: :string,
                 internal_deadline: :date,
                 external_deadline: :date

  acts_as_gov_uk_date :received_date, :date_responded, :external_deadline

  validates_presence_of :ico_reference_number

  validates :uploaded_request_files,
            presence: true,
            on: :create

  after_create :process_uploaded_request_files

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
end
