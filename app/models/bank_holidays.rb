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
  self.table_name = "bank_holidays"

  validates :data, presence: true
  validates :hash_value, presence: true

  # Class: Check if a given date is a bank holiday in any of the specified regions.
  #
  # date    - Date, Time, DateTime, or String ("YYYY-MM-DD").
  # regions - One or more region identifiers (Symbols/Strings). Defaults to :all,
  #           which means all available regions present in the stored payload
  #           (e.g. england-and-wales, scotland, northern-ireland). Underscores
  #           and hyphens are accepted for explicit regions.
  #
  # Returns true if the date matches a bank holiday in any provided region
  # using the latest BankHolidays record, otherwise false. Returns false when
  # there is no stored data or the input cannot be coerced to a date.
  def self.bank_holiday?(date, regions: :all)
    return false if date.nil?

    record = BankHolidays.last
    return false unless record

    iso = coerce_to_iso(date)
    return false unless iso

    # Resolve the list of regions. :all means include all regions in the payload.
    region_list =
      if regions == :all || (regions.respond_to?(:include?) && regions.include?(:all))
        record.available_regions
      else
        Array(regions).compact
      end

    return false if region_list.empty?

    record.dates_for_regions(*region_list).include?(iso)
  end

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

  # Public: List all available region keys present in the stored payload.
  #
  # Returns an Array<String> of region keys (e.g. ["england-and-wales", "scotland"]).
  # Only includes keys that look like valid region objects with an events array.
  def available_regions
    safe_data = parsed_data
    return [] unless safe_data.is_a?(Hash)

    safe_data.keys.grep(String).select do |key|
      region_hash = safe_data[key]
      region_hash.is_a?(Hash) && region_hash["events"].is_a?(Array)
    end
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

  # Coerce various date/time inputs to an ISO8601 date string (YYYY-MM-DD).
  # Returns nil when coercion is not possible.
  def self.coerce_to_iso(value)
    case value
    when Date
      value.iso8601
    when Time, DateTime, ActiveSupport::TimeWithZone
      value.to_date.iso8601
    when String
      begin
        Date.parse(value).iso8601
      rescue ArgumentError
        nil
      end
    else
      if value.respond_to?(:to_date)
        begin
          value.to_date.iso8601
        rescue StandardError
          nil
        end
      end
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
