module BankHolidaysHelper
  def bank_holidays_summary(bank_holiday)
    regions = bank_holiday.data.keys
    num_holidays = regions.sum { |region| bank_holiday.data.dig(region, "events")&.size.to_i }

    [regions, num_holidays]
  end

  # Invalid/missing dates sink to bottom of sorted events list
  def bank_holidays_for_region(bank_holiday, region)
    events = bank_holiday.data.dig(region, "events")
    return [] unless events

    events
      .sort_by { |ev| Date.parse(ev["date"].to_s) rescue Date.new(0) } # rubocop:disable Style/RescueModifier
  end
end
