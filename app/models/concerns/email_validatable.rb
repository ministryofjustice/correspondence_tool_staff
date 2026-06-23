# Shared email-format validation for staff-entered addresses.
#
# Provides the `EMAIL_REGEX` constant and a `validates_emails_for` macro so a
# model can validate either a single email attribute or a textarea field
# holding several whitespace/line-break separated addresses.
#
# @example single address
#   validates_emails_for :email
#
# @example multiple addresses (one per line), conditionally
#   validates_emails_for :data_request_emails, multiple: true
#   validates_emails_for :escalation_emails, multiple: true, if: :prison?
module EmailValidatable
  extend ActiveSupport::Concern

  # Pragmatic email validation for staff-entered addresses.
  # Rejects leading/trailing/repeated dots in the local part and invalid domain labels.
  EMAIL_REGEX = /\A(?!\.)(?!.*\.\.)[A-Za-z0-9!#$%&'*+\/=?\^_`{|}~-]+(?:\.[A-Za-z0-9!#$%&'*+\/=?\^_`{|}~-]+)*@(?:[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)+[A-Za-z]{2,}\z/

  class_methods do
    # @param attributes [Array<Symbol>] email attributes to validate
    # @param multiple [Boolean] when true the value is split on whitespace and
    #   each address validated individually (textarea fields)
    # @param options [Hash] standard validation options, e.g. `if:`/`unless:`
    def validates_emails_for(*attributes, multiple: false, **options)
      validate(options) do
        attributes.each do |attribute|
          value = public_send(attribute)
          next if value.blank?

          emails = multiple ? value.split : [value]
          emails.each do |email|
            errors.add(attribute, :invalid) unless email =~ EMAIL_REGEX
          end
        end
      end
    end
  end
end
