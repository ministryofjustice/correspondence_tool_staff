class BaseFormObject
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :record

  # This will allow subclasses to define after_initialize callbacks
  # and is needed for some functionality to work, i.e. acts_as_gov_uk_date
  define_model_callbacks :initialize

  def initialize(*)
    run_callbacks(:initialize) { super }
  end

  def save
    valid? && persist!
  end

  def to_key
    # Intentionally returns nil so the form builder picks up _only_
    # the class name to generate the HTML attributes.
    nil
  end

  def new_record?
    true
  end

  # Add the ability to read/write attributes without calling their accessor methods.
  # Needed to behave more like an ActiveRecord model, where you can manipulate the
  # DB attributes making use of `self[:attribute]`, and for `acts_as_gov_uk_date`.
  def [](attr_name)
    instance_variable_get("@#{attr_name}".to_sym)
  end

  def []=(attr_name, value)
    instance_variable_set("@#{attr_name}".to_sym, value)
  end

  class << self
    # Initialize a new form object given an AR model, setting its attributes
    def build(record)
      attributes = attributes_map(record)

      attributes.merge!(
        record: record
      )

      new(attributes)
    end

    # Iterates through all declared attributes in the form object, retrieving
    # their values from the `record` instance and generating a hash map.
    def attributes_map(record)
      attribute_names.to_h { |attr| [attr, record[attr]] }
    end
  end

  private

  # :nocov:
  def persist!
    raise 'Subclasses of BaseFormObject need to implement #persist!'
  end
  # :nocov:
end
