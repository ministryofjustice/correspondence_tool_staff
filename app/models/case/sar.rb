class Case::SAR < Case::Base
  class << self
    def type_abbreviation
      # This string is used when constructing paths or methods in other parts of
      # the system. Ensure that it does not come from a user-supplied parameter,
      # and does not contain special chars like slashes, etc.
      'SAR'
    end
  end

  before_save do
    self.workflow = 'standard' if workflow.nil?
  end

  def self.searchable_fields_and_ranks
    super.merge(
        {
            subject_full_name:     'B'
        }
    )
  end

  jsonb_accessor :properties,
                 escalation_deadline: :date,
                 internal_deadline: :date,
                 external_deadline: :date,
                 subject_full_name: :string,
                 subject_type: :string,
                 third_party: :boolean,
                 third_party_relationship: :string,
                 reply_method: :string,
                 late_team_id: :integer

  attr_accessor :missing_info

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
  validates :third_party, inclusion: {in: [ true, false ], message: "Please choose yes or no" }

  validates_presence_of :name, :third_party_relationship, if: -> { third_party }
  validates_presence_of :reply_method
  validates_presence_of :subject_type
  validates_presence_of :email,          if: :send_by_email?
  validates_presence_of :postal_address, if: :send_by_post?
  validates :subject, presence: true, length: { maximum: 100 }
  validate :validate_message_or_uploaded_request_files, on: :create
  validate :validate_message_or_attached_request_files, on: :update

  before_save :use_subject_as_requester,
              if: -> { name.blank? }
  after_create :process_uploaded_request_files,
               if: -> { uploaded_request_files.present? }

  # The method below is overriding the close method in the case_states.rb file.
  # This is so that the case is closed with the responder's team instead of the manager's team

  def respond_and_close(current_user)
    state_machine.respond!(acting_user: current_user, acting_team: self.responding_team)
    state_machine.close!(acting_user: current_user, acting_team: self.responding_team)
  end

  def within_escalation_deadline?
    false
  end

  def sar?
    true
  end

  private

  def use_subject_as_requester
    self.name = self.subject_full_name
  end

  def validate_message_or_uploaded_request_files
    if message.blank? && uploaded_request_files.blank?
      errors.add(:message,
                 :blank,
                 message: "can't be blank if no request files attached")
      errors.add(:uploaded_request_files,
                 :blank,
                 message: "can't be blank if no case details entered")
    end
  end

  def validate_message_or_attached_request_files
    if message.blank? && attachments.request.blank?
      errors.add(:message,
                 :blank,
                 message: "can't be blank if no request files attached")
    end
  end

end
