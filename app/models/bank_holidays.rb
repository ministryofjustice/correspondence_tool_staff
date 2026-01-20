# == Schema Information
#
# Table name: bank_holidays
#
#  id               :integer          not null, primary key
#  data             :json             not null, default({})
#  hash_value       :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null

class BankHolidays < ApplicationRecord
  validates :data, presence: true
  validates :hash_value, presence: true

  # Public: Return the original ISO 8601 date strings for one or more regions.
  #
  # *regions - One or more Symbols/Strings matching top-level keys in the
  #            stored JSON (e.g. :england_and_wales, :scotland). Underscores
  #            and hyphens are normalised.
  #
  # Returns an Array<String> of unique raw "YYYY-MM-DD" values directly from
  # the stored JSON. Regions that are nil/blank or missing in the payload are
  # simply ignored.
  def dates_for_regions(*regions)
    regions
      .compact
      .map { |r| dates_for(r) } # reuse single-region logic
      .flatten
      .uniq
  end

  # Public: Return the original ISO 8601 date strings for the requested region.
  #
  # region - Symbol or String matching a top-level key in the stored JSON
  #          (e.g. :england_and_wales, "scotland"). Underscores and hyphens
  #          are normalised so callers can use idiomatic Ruby symbols.
  #
  # Returns an Array<String> of raw "YYYY-MM-DD" values directly from the
  # stored JSON. Returns [] when the structure is missing or region is unknown.
  def dates_for(region)
    safe_data = parsed_data
    return [] unless safe_data.is_a?(Hash)

    region_key = normalise_region_key(region)
    region_hash = safe_data[region_key]
    return [] unless region_hash.is_a?(Hash)

    events = region_hash["events"]
    return [] unless events.is_a?(Array)

    events.filter_map do |event|
      next unless event.is_a?(Hash)

      raw_date = event["date"]
      # Keep only non-empty Strings; no parsing/formatting performed here.
      raw_date if raw_date.is_a?(String) && !raw_date.empty?
    end
  end

  private

  # Safely normalise whatever we were given as a region name to the
  # string key used in the stored JSON.
  #
  # Examples:
  #   :england_and_wales -> "england-and-wales"
  #   "england-and-wales" -> "england-and-wales"
  def normalise_region_key(region)
    return nil if region.nil?

    str = region.to_s.strip
    return nil if str.empty?

    # JSON keys in the gov.uk payload use hyphens, so convert any
    # underscores callers might use.
    str.tr("_", "-")
  end

  # Safely access the JSON column as a Hash.
  #
  # The column is declared as :json so in most cases Rails will already
  # give us a Hash. We still guard against nil or unexpected types so
  # callers don't see runtime errors.
  def parsed_data
    raw = self[:data]

    case raw
    when Hash
      raw
    when String
      begin
        JSON.parse(raw)
      rescue JSON::ParserError
        {}
      end
    else
      raw.respond_to?(:to_hash) ? raw.to_hash : {}
    end
  end
end
