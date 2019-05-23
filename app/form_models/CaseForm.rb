class CaseForm
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  delegate :id, :name, :email, :message, to: :@case

  #validate :email_addresses_must_match
  attr_reader :case,

  def initialize(case, params, session)


  end

  def save
    return unless valid?

    @case.save
    send_confirmation_instructions
    send_registration_email

    true
  end

  def valid?
    [@case].map(&:valid?).all? && super
  end

  private

end
