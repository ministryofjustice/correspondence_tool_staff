class ProbationCommissioningDocumentEmail
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  attribute :email_branston_archives
  attribute :probation, default: 1

  validates :email_branston_archives, presence: true
end
