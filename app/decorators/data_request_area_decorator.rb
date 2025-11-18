class DataRequestAreaDecorator < Draper::Decorator
  delegate_all

  def num_of_requests
    data_requests.count
  end

  def cached_num_pages
    data_requests.sum(:cached_num_pages)
  end

  def date_requested
    data_requests.order(:date_requested).first&.date_requested
  end

  def date_completed
    data_requests.completed.all? ? data_requests.order(:cached_date_received).last&.cached_date_received : ""
  end

  def location
    contact&.name || super
  end

  # def request_document
  #   commissioning_document.decorate.request_document
  # end

  def request_dates
    data_requests.in_progress.map { |request|
      request.decorate.request_dates
    }.join("\n")
  end

  def data_request_area_status_tag(status)
    case status
    when :completed
      "<strong class='govuk-tag govuk-tag--green'>Completed</strong>".html_safe
    when :in_progress
      "<strong class='govuk-tag govuk-tag--yellow'>In progress</strong>".html_safe
    when :not_started
      "<strong class='govuk-tag govuk-tag--red'>Not started</strong>".html_safe
    end
  end

  def next_chase_description
    type = {
      DataRequestChase::ESCALATION_CHASE => "escalated ",
      DataRequestChase::OVERDUE_CHASE => "overdue ",
      DataRequestChase::STANDARD_CHASE => "",
    }[next_chase_type]

    chase_date = I18n.l(next_chase_date.to_date, format: :default)

    "Chase #{next_chase_number} #{type}will be sent on #{chase_date}"
  end
end
