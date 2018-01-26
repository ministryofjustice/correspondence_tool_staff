class Case::FOI::Standard < Case::Base
  class << self
    def decorator_class
      Case::FOI::StandardDecorator
    end

    def type_abbreviation
      'FOI'
    end
  end


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
  validates :postal_address,
            presence: true,
            on: :create,
            if: -> { email.blank? || sent_by_post? }
  validates_presence_of :requester_type, :delivery_method
  validates :subject_full_name, :subject_type, absence: true
  validates :third_party, exclusion: { in: [true, false], message: 'must be blank' }
  validates :uploaded_request_files,
            presence: true,
            on: :create,
            if: -> { sent_by_post? }

  after_create :process_uploaded_request_files, if: :sent_by_post?
end
