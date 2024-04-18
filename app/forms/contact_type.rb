class ContactType
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  attribute :contact_type_id
  # This contact_type_default_id attribute only exists to be a hidden input in the form.
  # contact_type_id is intended to be a radio button control, and
  # if no value is selected for it then there would be an exception on the controller
  # because the expected form object would not exist in params.
  # Including a hidden value for contact_type_default_id ensures that the form object will
  # be included in the submitted params.
  attribute :contact_type_default_id, default: 1

  validates :contact_type_id, presence: true
end
