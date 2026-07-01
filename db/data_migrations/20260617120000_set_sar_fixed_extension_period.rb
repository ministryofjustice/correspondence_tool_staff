class SetSARFixedExtensionPeriod < ActiveRecord::DataMigration
  # Legislation requires a single extension period of 2 months only
  APPLICABLE_CORRESPONDENCE_TYPES = %w[SAR OFFENDER_SAR].freeze

  def up
    CorrespondenceType.where(abbreviation: APPLICABLE_CORRESPONDENCE_TYPES).find_each do |ct|
      ct.update!(
        extension_fixed_period: 2,
        extension_time_limit: nil,
        extension_time_default: nil,
      )
    end
  end

  def down
    CorrespondenceType.where(abbreviation: APPLICABLE_CORRESPONDENCE_TYPES).find_each do |ct|
      ct.update!(
        extension_fixed_period: nil,
        extension_time_limit: 2,
        extension_time_default: 1,
      )
    end
  end
end
