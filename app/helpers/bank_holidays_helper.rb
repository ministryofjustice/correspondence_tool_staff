module BankHolidaysHelper
  def bank_holidays_summary(rec)
    data = rec[:data].is_a?(Hash) ? rec[:data] : {}
    regions = data.keys
    events_count = regions.sum { |r| data[r].is_a?(Hash) && data[r]['events'].is_a?(Array) ? data[r]['events'].size : 0 }
    [regions, events_count]
  end
end
