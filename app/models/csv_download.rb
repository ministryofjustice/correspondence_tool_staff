class CsvDownload

  include ActiveModel::Model
  attr_accessor :period_start
  attr_accessor :period_end

  attr_accessor :period_start_dd
  attr_accessor :period_start_mm
  attr_accessor :period_start_yyyy
  attr_accessor :period_end_dd
  attr_accessor :period_end_mm
  attr_accessor :period_end_yyyy
end
