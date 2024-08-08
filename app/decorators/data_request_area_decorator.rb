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
end
