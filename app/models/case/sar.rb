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
                    :email,
                    :postal_address,
                    :properties,
                    :received_date,
                    :subject,
                  ]

  validates_presence_of :subject_full_name
  validates :third_party, inclusion: {in: [ true, false ],
                                      message: "Third party info can't be blank" }
  validates_presence_of :name, if: -> { third_party }
  validates_presence_of :reply_method
  validates_presence_of :subject_type
  validates_presence_of :email,          if: :send_by_email?
  validates_presence_of :postal_address, if: :send_by_post?
  validates_presence_of :message, unless: -> { uploaded_request_files.present? }
  validates_presence_of :uploaded_request_files, unless: -> { message.present? }

  before_save :use_subject_as_requester,
              if: -> { name.blank? }
  after_create :process_uploaded_request_files,
               if: -> { uploaded_request_files.present? }

  private

  def use_subject_as_requester
    self.name = self.subject_full_name
  end
end
