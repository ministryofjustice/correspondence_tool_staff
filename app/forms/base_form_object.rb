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

  # Initialize a new form object given an AR model, reading and setting
  # the attributes declared in the form object.
  def self.build(record)
    attrs = record.slice(
      attribute_names
    ).merge!(record: record)

    new(attrs)
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

  private

  # If the logic is any more complex than this, override in subclasses
  def persist!
    record.update(
      attributes
    )
  end
end
