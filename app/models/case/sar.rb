class Case::SAR < Case::Base
  class << self
    def type_abbreviation
      'SAR'
    end
  end

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
                    :properties,
                    :received_date,
                    :requester_email,
                    :requester_postal_address,
                    :subject
                  ]

  validates :subject_full_name, presence: true
  validates :third_party, inclusion: {in: [ true, false ],
                                      message: "can't be blank" }
  validates_presence_of :reply_method
  validates_presence_of :subject_type

  before_save :use_subject_as_requester,
              if: -> { name.blank? }
  after_create :process_uploaded_request_files,
               if: -> { uploaded_request_files.present? }

  private

  def use_subject_as_requester
    self.name = self.subject_full_name
  end
end
