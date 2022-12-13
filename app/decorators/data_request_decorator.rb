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

    return ""
  end

  private

  def date_format(date)
    date.strftime('%d/%m/%Y')
  end
end
