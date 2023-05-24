# frozen_string_literal: true

require "yaml"


module CtsPapertrailSerializer
  extend self # makes all instance methods become module methods as well

  def load(string)
    hash = ::YAML.load(string, permitted_classes: [Time, Date], aliases: true)
    if hash.key?('properties')
      properties_hash = ::JSON.parse(hash['properties'])
      properties_hash.each do | key, value|
        hash[key] = value
      end
    end
    hash
  end

  def dump(object)
    ::YAML.dump object
  end

  # Returns a SQL LIKE condition to be used to match the given field and
  # value in the serialized object.
  def where_object_condition(arel_field, field, value)
    arel_field.matches("%\n#{field}: #{value}\n%")
  end

  # Returns a SQL LIKE condition to be used to match the given field and
  # value in the serialized `object_changes`.
  def where_object_changes_condition(*)
    raise <<-STR.squish.freeze
      where_object_changes no longer supports reading YAML from a text
      column. The old implementation was inaccurate, returning more records
      than you wanted. This feature was deprecated in 8.1.0 and removed in
      9.0.0. The json and jsonb datatypes are still supported. See
      discussion at https://github.com/airblade/paper_trail/pull/997
    STR
  end
end

