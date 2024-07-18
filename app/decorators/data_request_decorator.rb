class DataRequestDecorator < Draper::Decorator
  delegate_all

  def request_dates
    if request_date_from_only?
      return "from #{date_format(date_from)} to date"
    end

    if request_date_to_only?
      return "up to #{date_format(date_to)}"
    end

    if request_dates_both_present?
      return "from #{date_format(date_from)} to #{date_format(date_to)}"
    end

    ""
  end

  def location
    contact&.name || super
  end

  def data_request_name
    contact&.data_request_name || location
  end

  def data_required
    request_type_note if request_type == "other"
  end

  def display_request_type_note?
    %w[other nomis_other cctv bwcf].include?(request_type) && request_type_note.present?
  end

private

  def date_format(date)
    date.strftime("%d/%m/%Y")
  end
end
