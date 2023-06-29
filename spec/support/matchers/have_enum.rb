require "rspec/expectations"

RSpec::Matchers.define :have_enum do |name|
  match do
    name = name.to_sym
    defined_enums = subject.defined_enums.keys.map(&:to_sym)
    result = defined_enums.include?(name)
    result &&= @model_values_matched && @db_values_matched unless @expected_values.nil?
    result
  end

  chain :with_values do |expected_values|
    @expected_values = expected_values.sort!
    @actual_values = subject.defined_enums[name.to_s]
    actual_model_values = @actual_values.keys.sort
    actual_db_values = @actual_values.values.sort

    @model_values_matched = (actual_model_values == @expected_values)
    @db_values_matched = (actual_db_values == @expected_values)
  rescue NoMethodError
    # this happens if the name does not correspond to the name of an enum
    @actual_values = false
  end

  description do
    output = "to have enum called #{name}"
    output += " with permitted values #{@expected_values}" if @expected_values.present? && @actual_values
    output
  end

  failure_message do |actual|
    "Expected #{actual.class} " + description
  end
end
