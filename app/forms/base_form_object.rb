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

  # Initialize a new form object given an AR model, setting its attributes
  def self.build(record)
    attributes = attributes_map(record)

    attributes.merge!(
      record: record
    )

    new(attributes)
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
  # database attributes making use of `self[:attribute]`
  def [](attr_name)
    instance_variable_get("@#{attr_name}".to_sym)
  end

  def []=(attr_name, value)
    instance_variable_set("@#{attr_name}".to_sym, value)
  end

  def attributes_map
    self.class.attributes_map(self)
  end

  # Iterates through all declared attributes in the form object, mapping its values
  def self.attributes_map(origin)
    attribute_names.to_h { |attr| [attr, origin[attr]] }
  end

  private

  # :nocov:
  def persist!
    raise 'Subclasses of BaseForm need to implement #persist!'
  end
  # :nocov:
end
