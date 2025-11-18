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

  def request_document
    comm
    commissioning_document.decorate.request_document
  end

  def location
    data_request_area.contact&.name || data_request_area&.location
  end

  def data_required
    request_type_note if request_type == "other"
  end

  def display_request_type_note?
    request_type_note.present?
  end

  def data_request_status_tag
    case status
    when :completed
      "<strong class='govuk-tag govuk-tag--green'>Completed</strong>".html_safe
    when :in_progress
      "<strong class='govuk-tag govuk-tag--yellow'>In progress</strong>".html_safe
    end
  end

private

  def date_format(date)
    date.strftime("%d/%m/%Y")
  end
end
