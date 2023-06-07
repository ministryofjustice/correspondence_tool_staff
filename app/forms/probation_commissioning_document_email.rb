class ProbationCommissioningDocumentEmail
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  attribute :email_branston_archives
  attribute :probation

  validates :email_branston_archives, presence: true

  def initialize(*)
    @probation = 1
    super
  end
end
